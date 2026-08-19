# app/jobs/process_remote_files_job.rb
class ProcessRemoteFilesJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Starting remote RTGS file processing job"

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
    files_to_process = remote_service.list_rtgs_files
    Rails.logger.info "Found #{files_to_process.count} RTGS files to process"

    processed_count = 0
    failed_count = 0

    files_to_process.each do |file|
      if process_file(remote_service, file, download_dir, processed_dir, error_dir)
        processed_count += 1
      else
        failed_count += 1
      end
    end

    Rails.logger.info "Completed: #{processed_count} processed, #{failed_count} failed"
  end

  private

  def required_env_variables_present?
    required_vars = ['AMLOCK_SERVER_IP', 'AMLOCK_USER_NAME', 'AMLOCK_PASSWORD', 'AMLOCK_SOURCE_FILES']
    required_vars.all? { |var| ENV[var].present? }
  end

  def process_file(remote_service, file, download_dir, processed_dir, error_dir)
    remote_path = File.join(AMLOCK_SOURCE_FILES, file.name)
    local_path = download_dir.join(file.name)

    begin
      # Download the file
      Rails.logger.info "Downloading #{file.name}..."
      unless remote_service.download_file(remote_path, local_path)
        Rails.logger.error "Failed to download #{file.name}"
        return false
      end

      # Process the RTGS message
      if process_rtgs_content(local_path, file.name)
        # Move to processed directory
        FileUtils.mv(local_path, processed_dir.join(file.name))
        
        # Delete from remote server
        remote_service.delete_remote_file(remote_path)
        
        Rails.logger.info "✅ Successfully processed #{file.name}"
        return true
      else
        # Move to error directory
        FileUtils.mv(local_path, error_dir.join(file.name))
        Rails.logger.error "❌ Failed to process #{file.name}, moved to errors"
        return false
      end

    rescue => e
      Rails.logger.error "Error processing #{file.name}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      # Move to error directory if file exists locally
      if File.exist?(local_path)
        FileUtils.mv(local_path, error_dir.join(file.name))
      end
      return false
    end
  end

  def process_rtgs_content(file_path, filename)
    rtgs_message = File.read(file_path)

    # Parse the RTGS message
    parser = RtgsParserService.new(rtgs_message)
    parsed_data = parser.call

    unless parsed_data
      Rails.logger.error "Failed to parse RTGS message from #{filename}"
      return false
    end

    # Create or update transaction
    transaction = nil
    Transaction.transaction do
      transaction = Transaction.find_or_initialize_by(
        rtgs_reference: parsed_data['reference']
      )

      # Skip if already processed successfully
      if transaction.persisted? && transaction.screening_status == 'completed'
        Rails.logger.info "⏭️ Transaction #{parsed_data['reference']} already processed"
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
        
        # Trigger screening asynchronously
        RtgsScreeningJob.perform_later(rtgs_message, transaction.id)
        return true
      else
        Rails.logger.error "Failed to save transaction: #{transaction.errors.full_messages.join(', ')}"
        return false
      end
    end

  rescue => e
    Rails.logger.error "Error processing RTGS content: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    false
  end
end
