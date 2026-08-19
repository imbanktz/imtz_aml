# app/services/rtgs_scheduler_service.rb
class RtgsSchedulerService
  def self.process_rtgs_files
    new.process
  end

  def process
    Rails.logger.info "🔄 Starting RTGS scheduled processing at #{Time.current}"
    puts "🔄 Starting RTGS scheduled processing at #{Time.current}"
    
    remote_service = RemoteFileService.new
    remote_path = AMLOCK_SOURCE_FILES
    
    puts "📂 Remote path: #{remote_path}"
    files = remote_service.list_rtgs_files(remote_path)
    
    if files.empty?
      Rails.logger.info "No RTGS files found to process"
      puts "No RTGS files found to process"
      return { processed: 0, failed: 0, message: "No files found" }
    end
    
    Rails.logger.info "Found #{files.count} RTGS files to process"
    puts "Found #{files.count} RTGS files to process"
    
    processed_count = 0
    failed_count = 0
    
    files.each do |file|
      if process_single_file(remote_service, file, remote_path)
        processed_count += 1
      else
        failed_count += 1
      end
    end
    
    Rails.logger.info "✅ RTGS processing completed: #{processed_count} processed, #{failed_count} failed"
    puts "✅ RTGS processing completed: #{processed_count} processed, #{failed_count} failed"
    
    { processed: processed_count, failed: failed_count, total: files.count }
  rescue => e
    Rails.logger.error "❌ RTGS processing failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    puts "❌ RTGS processing failed: #{e.message}"
    { processed: 0, failed: 0, error: e.message }
  end

  private

  def process_single_file(remote_service, file, remote_path)
    download_dir = Rails.root.join('tmp', 'rtgs_downloads')
    processed_dir = Rails.root.join('tmp', 'rtgs_processed')
    error_dir = Rails.root.join('tmp', 'rtgs_errors')
    
    FileUtils.mkdir_p(download_dir)
    FileUtils.mkdir_p(processed_dir)
    FileUtils.mkdir_p(error_dir)
    
    # Convert Pathname to string - THIS IS THE FIX
    local_path = download_dir.join(file.name).to_s
    remote_full_path = File.join(remote_path, file.name)
    
    begin
      # Download the file
      Rails.logger.info "📥 Downloading #{file.name}..."
      puts "📥 Downloading #{file.name}..."
      
      unless remote_service.download_file(remote_full_path, local_path)
        Rails.logger.error "Failed to download #{file.name}"
        puts "❌ Failed to download #{file.name}"
        return false
      end
      
      # Check if file was downloaded
      unless File.exist?(local_path) && File.size(local_path) > 0
        Rails.logger.error "File downloaded but empty or missing: #{local_path}"
        puts "❌ File downloaded but empty or missing"
        return false
      end
      
      puts "✅ Downloaded: #{File.size(local_path)} bytes"
      
      # Process the RTGS message
      success = process_rtgs_message(local_path, file.name)
      
      if success
        # Move to processed directory
        processed_path = processed_dir.join(file.name).to_s
        FileUtils.mv(local_path, processed_path)
        
        # Delete from remote server
        remote_service.delete_remote_file(remote_full_path)
        Rails.logger.info "✅ Successfully processed and removed #{file.name}"
        puts "✅ Successfully processed and removed #{file.name}"
        return true
      else
        # Move to error directory
        error_path = error_dir.join(file.name).to_s
        FileUtils.mv(local_path, error_path)
        Rails.logger.error "❌ Failed to process #{file.name}, moved to errors"
        puts "❌ Failed to process #{file.name}, moved to errors"
        return false
      end
      
    rescue => e
      Rails.logger.error "Error processing #{file.name}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      puts "❌ Error processing #{file.name}: #{e.message}"
      
      # Move to error if file exists
      if File.exist?(local_path)
        error_path = error_dir.join(file.name).to_s
        FileUtils.mv(local_path, error_path)
        puts "  Moved to errors"
      end
      return false
    end
  end

  def process_rtgs_message(file_path, filename)
    rtgs_message = File.read(file_path)
    
    # Parse the RTGS message
    parser = RtgsParserService.new(rtgs_message)
    parsed_data = parser.call
    
    unless parsed_data
      Rails.logger.error "Failed to parse RTGS message from #{filename}"
      puts "❌ Failed to parse RTGS message from #{filename}"
      return false
    end
    
    puts "✅ Parsed: Reference #{parsed_data['reference']}"
    
    # Find or create transaction
    transaction = nil
    Transaction.transaction do
      transaction = Transaction.find_or_initialize_by(
        rtgs_reference: parsed_data['reference']
      )
      
      # Skip if already processed
      if transaction.persisted? && transaction.screening_status != 'pending'
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
    Rails.logger.error "Error processing RTGS message: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    puts "❌ Error processing RTGS message: #{e.message}"
    false
  end
end

# class RtgsSchedulerService
#   def self.process_rtgs_files
#     new.process
#   end

#   def process
#     Rails.logger.info "🔄 Starting RTGS scheduled processing at #{Time.current}"
#     remote_service = RemoteFileService.new
#     remote_path = AMLOCK_SOURCE_FILES
#     files = remote_service.list_rtgs_files(remote_path)
#     if files.empty?
#       Rails.logger.info "No RTGS files found to process"
#       return { processed: 0, failed: 0, message: "No files found" }
#     end

#     Rails.logger.info "Found #{files.count} RTGS files to process"
#     processed_count = 0
#     failed_count = 0
#     files.each do |file|
#       if process_single_file(remote_service, file, remote_path)
#         processed_count += 1
#       else
#         failed_count += 1
#       end
#     end

#     Rails.logger.info "✅ RTGS processing completed: #{processed_count} processed, #{failed_count} failed"
#     { processed: processed_count, failed: failed_count, total: files.count }
#   rescue => e
#     Rails.logger.error "❌ RTGS processing failed: #{e.message}"
#     Rails.logger.error e.backtrace.join("\n")
#     { processed: 0, failed: 0, error: e.message }
#   end

#   private

#   def process_single_file(remote_service, file, remote_path)
#     download_dir = Rails.root.join('tmp', 'rtgs_downloads')
#     processed_dir = Rails.root.join('tmp', 'rtgs_processed')
#     error_dir = Rails.root.join('tmp', 'rtgs_errors')

#     FileUtils.mkdir_p(download_dir)
#     FileUtils.mkdir_p(processed_dir)
#     FileUtils.mkdir_p(error_dir)

#     local_path = download_dir.join(file.name)
#     remote_full_path = File.join(remote_path, file.name)

#     begin
#       # Download the file
#       Rails.logger.info "📥 Downloading #{file.name}..."
#       unless remote_service.download_file(remote_full_path, local_path)
#         Rails.logger.error "Failed to download #{file.name}"
#         return false
#       end

#       # Process the RTGS message
#       success = process_rtgs_message(local_path, file.name)

#       if success
#         # Move to processed directory
#         FileUtils.mv(local_path, processed_dir.join(file.name))

#         # Delete from remote server
#         remote_service.delete_remote_file(remote_full_path)
#         Rails.logger.info "✅ Successfully processed and removed #{file.name}"
#         return true
#       else
#         # Move to error directory
#         FileUtils.mv(local_path, error_dir.join(file.name))
#         Rails.logger.error "❌ Failed to process #{file.name}, moved to errors"
#         return false
#       end

#     rescue => e
#       Rails.logger.error "Error processing #{file.name}: #{e.message}"
#       FileUtils.mv(local_path, error_dir.join(file.name)) if File.exist?(local_path)
#       return false
#     end
#   end

#   def process_rtgs_message(file_path, filename)
#     rtgs_message = File.read(file_path)

#     # Parse the RTGS message
#     parser = RtgsParserService.new(rtgs_message)
#     parsed_data = parser.call

#     unless parsed_data
#       Rails.logger.error "Failed to parse RTGS message from #{filename}"
#       return false
#     end

#     # Find or create transaction
#     transaction = nil
#     Transaction.transaction do
#       transaction = Transaction.find_or_initialize_by(
#         rtgs_reference: parsed_data['reference']
#       )

#       # Skip if already processed
#       if transaction.persisted? && transaction.screening_status != 'pending'
#         Rails.logger.info "⏭️ Transaction #{parsed_data['reference']} already processed"
#         return true
#       end

#       # Update transaction with parsed data
#       transaction.assign_attributes(
#         request_id: parsed_data['requestId'],
#         transaction_direction: parsed_data['transactionDirection'],
#         transaction_type: parsed_data['transactionType'],
#         transaction_amount: parsed_data['transactionAmount'],
#         transaction_currency: parsed_data['transactionCurrency'],
#         transaction_date: parsed_data['transactionDate'],
#         reference: parsed_data['reference'],
#         narrative: parsed_data['narrative'],
#         bank_code: parsed_data['bankCode'],
#         parties: parsed_data['parties'],
#         raw_fields: parsed_data['rawFields'],
#         raw_rtgs_message: rtgs_message,
#         screening_status: 'pending'
#       )

#       if transaction.save
#         Rails.logger.info "💾 Transaction saved with ID: #{transaction.id}"

#         # Trigger screening asynchronously
#         RtgsScreeningJob.perform_later(rtgs_message, transaction.id)
#         return true
#       else
#         Rails.logger.error "Failed to save transaction: #{transaction.errors.full_messages.join(', ')}"
#         return false
#       end
#     end
#   rescue => e
#     Rails.logger.error "Error processing RTGS message: #{e.message}"
#     false
#   end
# end
