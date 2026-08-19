class ProcessRemoteFilesJob < ApplicationJob
  queue_as :default
  
  def perform
    Rails.logger.info "Starting remote file processing job"
    
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
    
    download_dir = Rails.root.join('tmp', 'downloads')
    upload_dir = Rails.root.join('tmp', 'uploads')
    
    FileUtils.mkdir_p(download_dir)
    FileUtils.mkdir_p(upload_dir)
    
    files_to_process = remote_service.list_files_to_convert
    Rails.logger.info "Found #{files_to_process.count} files to process"
    
    processed_count = 0
    failed_count = 0
    
    files_to_process.each do |file_info|
      if process_file(remote_service, file_info, download_dir, upload_dir)
        processed_count += 1
      else
        failed_count += 1
      end
    end
    
    Rails.logger.info "Completed: #{processed_count} processed, #{failed_count} failed"
  end
  
  private
  
  def required_env_variables_present?
    required_vars = ['AMLOCK_SERVER_IP', 'AMLOCK_USER_NAME', 'AMLOCK_PASSWORD', 
                     'AMLOCK_DESTINATION_FILES', 'AMLOCK_DESTINATION_FILES_ORIGINAL',
                     'AMLOCK_DESTINATION_FILES_FAILED']
    
    missing_vars = required_vars.select { |var| ENV[var].blank? }
    
    if missing_vars.any?
      Rails.logger.error "Missing environment variables: #{missing_vars.join(', ')}"
      return false
    end
    
    true
  end
  
  def process_file(remote_service, file_info, download_dir, upload_dir)
    filename = file_info[:name]
    remote_file_path = file_info[:path]
    
    Rails.logger.info "Processing file: #{filename}"
    
    begin
      # 1. Download file
      local_file_path = download_dir.join(filename)
      
      Rails.logger.info "Downloading #{filename} from #{remote_file_path} to #{local_file_path}"
      
      unless remote_service.download_file(remote_file_path, local_file_path.to_s)
        Rails.logger.error "Failed to download #{filename}"
        create_failed_record(filename, "Failed to download file", nil)
        return false
      end
      
      unless File.exist?(local_file_path)
        Rails.logger.error "Local file not found after download: #{local_file_path}"
        create_failed_record(filename, "File not found after download", nil)
        return false
      end
      
      # 2. Read and convert file
      Rails.logger.info "Reading file content"
      xml_content = File.read(local_file_path)
      
      if xml_content.blank?
        Rails.logger.error "Empty file content for #{filename}"
        create_failed_record(filename, "Empty file content", "")
        return false
      end
      
      Rails.logger.info "Converting XML to MT"
      result = SwiftConversionService.convert(xml_content, filename)
      
      if result[:success] && result[:mt_message].present?
        Rails.logger.info "Conversion successful for #{filename}"
        
        # 3. Save conversion to database
        begin
          swift_message = SwiftMessage.create!(
            file_name: filename,
            original_xml: xml_content,
            converted_mt: result[:mt_message],
            status: 'completed',
            # source: 'remote_auto',
            processing_completed_at: Time.current
          )
          
          Rails.logger.info "Created SwiftMessage record ##{swift_message.id}"
          
        rescue ActiveRecord::RecordInvalid => e
          Rails.logger.error "Failed to save SwiftMessage: #{e.message}"
          return false
        end
        
        # 4. Create MT file locally
        # mt_filename = filename.gsub(/\.xml$/i, '.TXT')
        # mt_file_path = upload_dir.join(mt_filename)
        ####
        datetime_str = Time.now.strftime("%y%m%d%H%M%S")  # Example: 251212143015 for Dec 12, 2025 14:30:15
        mt_filename = "MX#{datetime_str}BRI_103.TXT"
        mt_file_path = upload_dir.join(mt_filename)
        #### 
        Rails.logger.info "Creating MT file: #{mt_file_path}"
        File.write(mt_file_path, result[:mt_message])
        # 5. Upload converted file back to remote
        remote_mt_path = File.join(AMLOCK_DESTINATION_FILES, mt_filename)
        
        Rails.logger.info "Uploading MT file to #{remote_mt_path}"
        if remote_service.upload_file(mt_file_path.to_s, remote_mt_path)
          Rails.logger.info "Successfully uploaded converted file: #{mt_filename}"
          
          # 6. Move original XML to processed directory
          processed_dir = AMLOCK_DESTINATION_FILES_ORIGINAL
          remote_processed_path = File.join(processed_dir, filename)
          
          Rails.logger.info "Moving original to processed directory"
          if remote_service.move_file(remote_file_path, remote_processed_path)
            Rails.logger.info "Moved original file to processed directory"
          else
            Rails.logger.warn "Failed to move original file, creating backup"
            backup_path = remote_service.create_backup(remote_file_path)
            Rails.logger.info "Created backup: #{backup_path}" if backup_path
          end
          
        else
          Rails.logger.error "Failed to upload converted file: #{mt_filename}"
          
          # Update the record to indicate upload failure
          swift_message.update!(
            status: 'failed', 
            error_message: 'Failed to upload converted file'
          )
          
          return false
        end
        
      else
        error_msg = result[:error] || "Conversion failed or empty MT message"
        Rails.logger.error "Conversion failed for #{filename}: #{error_msg}"
        
        # Save failed conversion
        create_failed_record(filename, error_msg, xml_content)
        
        # Move failed file to error directory
        error_dir = AMLOCK_DESTINATION_FILES_FAILED
        remote_error_path = File.join(error_dir, filename)
        
        Rails.logger.info "Moving failed file to error directory"
        if remote_service.move_file(remote_file_path, remote_error_path)
          Rails.logger.info "Moved failed file to error directory"
        else
          Rails.logger.warn "Failed to move failed file, creating backup"
          backup_path = remote_service.create_backup(remote_file_path)
          Rails.logger.info "Created backup for failed file: #{backup_path}" if backup_path
        end
        
        return false
      end
      
      # 7. Clean up local files
      cleanup_local_files(local_file_path, mt_file_path)
      
      return true
      
    rescue => e
      Rails.logger.error "Error processing #{filename}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      create_failed_record(filename, "Processing error: #{e.message}", nil)
      return false
    end
  end
  
  def create_failed_record(filename, error_message, xml_content)
    begin
      SwiftMessage.create!(
        file_name: filename,
        original_xml: xml_content || "",
        status: 'failed',
        error_message: error_message,
        # source: 'remote_auto',
        processing_completed_at: Time.current
      )
    rescue => e
      Rails.logger.error "Failed to create failed record: #{e.message}"
    end
  end
  
  def cleanup_local_files(*file_paths)
    file_paths.each do |file_path|
      next unless file_path && File.exist?(file_path)
      
      begin
        File.delete(file_path)
        Rails.logger.debug "Cleaned up local file: #{file_path}"
      rescue => e
        Rails.logger.warn "Failed to cleanup #{file_path}: #{e.message}"
      end
    end
  end
end
