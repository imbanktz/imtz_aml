class ProcessRtgsWithManualParserJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(remote_path = nil)
    remote_path ||= ENV['REMOTE_RTGS_PATH'] || "/amlock/Tanzania/RMS/mxt_to_mt/rtgs_source_only"
    
    Rails.logger.info "Starting RTGS processing with manual parser"
    puts "🔄 Starting RTGS processing with manual parser"
    
    remote_service = RemoteFileService.new(
      host: ENV['REMOTE_HOST'] || AMLOCK_SERVER_IP,
      username: ENV['REMOTE_USERNAME'] || AMLOCK_USER_NAME,
      password: ENV['REMOTE_PASSWORD'] || AMLOCK_PASSWORD
    )
    
    files = remote_service.list_rtgs_files(remote_path) || []
    
    if files.empty?
      Rails.logger.info "No RTGS files found"
      puts "No RTGS files found"
      return { processed: 0, failed: 0, message: "No files found" }
    end
    
    Rails.logger.info "Found #{files.count} files to process"
    puts "Found #{files.count} files to process"
    
    processed = 0
    failed = 0
    skipped = 0
    
    files.each do |file|
      result = process_file(remote_service, file, remote_path)
      
      case result
      when :processed
        processed += 1
      when :skipped
        skipped += 1
      else
        failed += 1
      end
    end
    
    summary = { processed: processed, failed: failed, skipped: skipped, total: files.count }
    Rails.logger.info "✅ Processing completed: #{summary.inspect}"
    puts "✅ Processing completed: #{summary.inspect}"
    
    summary
  end

  private

  def process_file(remote_service, file, remote_path)
    download_dir = Rails.root.join('tmp', 'rtgs_downloads')
    processed_dir = Rails.root.join('tmp', 'rtgs_processed')
    error_dir = Rails.root.join('tmp', 'rtgs_errors')
    
    FileUtils.mkdir_p(download_dir)
    FileUtils.mkdir_p(processed_dir)
    FileUtils.mkdir_p(error_dir)
    
    local_path = download_dir.join(file.name).to_s
    remote_full_path = File.join(remote_path, file.name)
    
    begin
      # Download
      puts "📥 Downloading #{file.name}..."
      unless remote_service.download_file(remote_full_path, local_path)
        Rails.logger.error "Failed to download #{file.name}"
        return :failed
      end
      
      # Parse
      content = File.read(local_path)
      parser = ManualRtgsParserService.new(content)
      parsed = parser.call
      
      unless parsed && parsed['reference'].present?
        Rails.logger.error "Failed to parse #{file.name}"
        FileUtils.mv(local_path, error_dir.join(file.name).to_s)
        return :failed
      end
      
      puts "  ✅ Parsed: #{parsed['reference']} - Amount: #{parsed['transactionAmount']} #{parsed['transactionCurrency']}"
      
      # Find or create transaction
      transaction = Transaction.find_or_initialize_by(rtgs_reference: parsed['reference'])
      
      if transaction.persisted?
        puts "  ⏭️ Already exists (ID: #{transaction.id})"
        FileUtils.mv(local_path, processed_dir.join(file.name).to_s)
        return :skipped
      end
      
      # Build transaction
      transaction.request_id = parsed['requestId']
      transaction.transaction_direction = parsed['transactionDirection']
      transaction.transaction_amount = parsed['transactionAmount']
      transaction.transaction_currency = parsed['transactionCurrency']
      transaction.transaction_date = parsed['transactionDate']
      transaction.rtgs_reference = parsed['reference']
      transaction.parties = parsed['parties']
      transaction.raw_rtgs_message = content
      transaction.screening_status = 'pending'
      
      # Optional fields
      if Transaction.column_names.include?('narrative') && parsed['narrative'].present?
        transaction.narrative = parsed['narrative']
      end
      
      if Transaction.column_names.include?('bank_code') && parsed['bankCode'].present?
        transaction.bank_code = parsed['bankCode']
      end
      
      if Transaction.column_names.include?('transaction_type') && parsed['transactionType'].present?
        transaction.transaction_type = parsed['transactionType']
      end
      
      if Transaction.column_names.include?('raw_fields')
        transaction.raw_fields = parsed['rawFields']
      end
      
      if transaction.save
        puts "  ✅ Transaction created (ID: #{transaction.id})"
        RtgsScreeningJob.perform_later(content, transaction.id)
        puts "  🔍 Screening queued"
        FileUtils.mv(local_path, processed_dir.join(file.name).to_s)
        return :processed
      else
        Rails.logger.error "Save failed: #{transaction.errors.full_messages.join(', ')}"
        FileUtils.mv(local_path, error_dir.join(file.name).to_s)
        return :failed
      end
      
    rescue => e
      Rails.logger.error "Error processing #{file.name}: #{e.message}"
      puts "  ❌ Error: #{e.message}"
      FileUtils.mv(local_path, error_dir.join(file.name).to_s) if File.exist?(local_path)
      return :failed
    end
  end
end
