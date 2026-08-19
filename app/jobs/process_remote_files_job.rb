class ProcessRemoteFilesJob < ApplicationJob
  queue_as :default

  def perform(remote_path = nil)
    Rails.logger.info "Starting remote RTGS file processing job"
    # Use provided path or default
    remote_path ||= ENV['REMOTE_RTGS_PATH'] || AMLOCK_SOURCE_FILES
    # Check if all required environment variables are set
    unless required_env_variables_present?
      Rails.logger.error "Missing required environment variables"
      return
    end

    remote_service = RemoteFileService.new(
      host: ENV['REMOTE_HOST'] || AMLOCK_SERVER_IP,
      username: ENV['REMOTE_USERNAME'] || AMLOCK_USER_NAME,
      password: ENV['REMOTE_PASSWORD'] || AMLOCK_PASSWORD
    )

    download_dir = Rails.root.join('tmp', 'rtgs_downloads')
    processed_dir = Rails.root.join('tmp', 'rtgs_processed')
    error_dir = Rails.root.join('tmp', 'rtgs_errors')

    FileUtils.mkdir_p(download_dir)
    FileUtils.mkdir_p(processed_dir)
    FileUtils.mkdir_p(error_dir)

    # List RTGS files from remote server
    files_to_process = remote_service.list_rtgs_files(remote_path)
    
    if files_to_process.empty?
      Rails.logger.info "No RTGS files found to process in #{remote_path}"
      puts "No RTGS files found to process in #{remote_path}"
      return
    end
    
    Rails.logger.info "Found #{files_to_process.count} RTGS files to process"
    puts "Found #{files_to_process.count} RTGS files to process"

    processed_count = 0
    failed_count = 0

    files_to_process.each do |file|
      if process_file(remote_service, file, remote_path, download_dir, processed_dir, error_dir)
        processed_count += 1
      else
        failed_count += 1
      end
    end

    Rails.logger.info "Completed: #{processed_count} processed, #{failed_count} failed"
    puts "✅ Completed: #{processed_count} processed, #{failed_count} failed"
    
    { processed: processed_count, failed: failed_count, total: files_to_process.count }
  end

  private

  def required_env_variables_present?
    # Check if constants are defined (they're set in your environment)
    defined?(AMLOCK_SERVER_IP) && defined?(AMLOCK_USER_NAME) && defined?(AMLOCK_PASSWORD)
  end

  def process_file(remote_service, file, remote_path, download_dir, processed_dir, error_dir)
    # Use to_s to convert Pathname to string
    local_path = download_dir.join(file.name).to_s
    remote_full_path = File.join(remote_path, file.name)
    
    begin
      # Download the file
      puts "📥 Downloading #{file.name}..."
      unless remote_service.download_file(remote_full_path, local_path)
        puts "❌ Failed to download #{file.name}"
        return false
      end
      
      # Check if file was actually downloaded
      unless File.exist?(local_path) && File.size(local_path) > 0
        puts "❌ File downloaded but empty or missing: #{local_path}"
        return false
      end
      
      puts "✅ File downloaded: #{File.size(local_path)} bytes"
      
      # Read and process the file
      rtgs_message = File.read(local_path)
      success = process_rtgs_content(rtgs_message, file.name)
      
      if success
        # Move to processed
        processed_path = processed_dir.join(file.name).to_s
        FileUtils.mv(local_path, processed_path)
        puts "✅ Processed and moved #{file.name} to processed"
        
        # Delete from remote server
        remote_service.delete_remote_file(remote_full_path)
        return true
      else
        # Move to error
        error_path = error_dir.join(file.name).to_s
        FileUtils.mv(local_path, error_path)
        puts "❌ Failed to process #{file.name}, moved to errors"
        return false
      end
      
    rescue => e
      puts "❌ Error processing #{file.name}: #{e.message}"
      puts "  Backtrace: #{e.backtrace.first(3).join("\n  ")}"
      
      # Move to error if file exists
      if File.exist?(local_path)
        error_path = error_dir.join(file.name).to_s
        FileUtils.mv(local_path, error_path)
        puts "  Moved to errors"
      end
      false
    end
  end
  
  def process_rtgs_content(rtgs_message, filename)
    # Parse the RTGS message
    parser = RtgsParserService.new(rtgs_message)
    parsed_data = parser.call

    unless parsed_data
      Rails.logger.error "Failed to parse RTGS message from #{filename}"
      puts "❌ Failed to parse RTGS message from #{filename}"
      return false
    end

    puts "✅ Parsed #{filename}: Reference #{parsed_data['reference']}"

    # Create or update transaction
    transaction = nil
    Transaction.transaction do
      transaction = Transaction.find_or_initialize_by(
        rtgs_reference: parsed_data['reference']
      )

      # Skip if already processed successfully
      if transaction.persisted? && transaction.screening_status == 'completed'
        Rails.logger.info "⏭️ Transaction #{parsed_data['reference']} already processed"
        puts "⏭️ Transaction #{parsed_data['reference']} already processed"
        return true
      end

      # Update transaction with parsed data
      transaction.assign_attributes(
        request_id: parsed_data['requestId'],
        transaction_direction: parsed_data['transactionDirection'],
        transaction_type: parsed_data['transactionType'],
        transaction_amount: parsed_data['transactionAmount'],
        transaction_currency: parsed_data['transactionCurrency'],
        transaction_date: parsed_data['transactionDate'],
        reference: parsed_data['reference'],
        narrative: parsed_data['narrative'],
        bank_code: parsed_data['bankCode'],
        parties: parsed_data['parties'],
        raw_fields: parsed_data['rawFields'],
        raw_rtgs_message: rtgs_message,
        screening_status: 'pending'
      )

      if transaction.save
        Rails.logger.info "💾 Transaction saved with ID: #{transaction.id}"
        puts "💾 Transaction saved with ID: #{transaction.id}"
        
        # Trigger screening asynchronously
        RtgsScreeningJob.perform_later(rtgs_message, transaction.id)
        puts "🔍 Screening job queued for transaction #{transaction.id}"
        return true
      else
        Rails.logger.error "Failed to save transaction: #{transaction.errors.full_messages.join(', ')}"
        puts "❌ Failed to save transaction: #{transaction.errors.full_messages.join(', ')}"
        return false
      end
    end
  rescue => e
    Rails.logger.error "Error processing RTGS content: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    puts "❌ Error processing RTGS content: #{e.message}"
    false
  end
end
