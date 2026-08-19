# app/services/remote_file_service.rb
#
# Copyright (c) 2025 
#
# @package  MX to MT converter project
# @author abdimuna, abdillah.muna@imbank.co.tz | abdimuna1@gmail.com
# @Company  I&M BANK 
# @description SFT file handler, upload and download remote files
# @license  private
# @version  0.0.1:
# @usage  Use ruby convention, when handling this code
##/
class RemoteFileService
  def initialize(host: nil, username: nil, password: nil)
    @host = host || AMLOCK_SERVER_IP
    @username = username || AMLOCK_USER_NAME
    @password = password || AMLOCK_PASSWORD
  end

  def list_rtgs_files(remote_path = nil)
    remote_path ||= AMLOCK_SOURCE_FILES
    
    Net::SFTP.start(@host, @username, password: @password) do |sftp|
      entries = sftp.dir.entries(remote_path)
      entries.select do |entry|
        entry.file? && entry.name.match?(/\.(TXT|txt|mt103|rtgs)$/i)
      end
    end
  rescue Net::SFTP::StatusException => e
    Rails.logger.error "Failed to list files from #{remote_path}: #{e.message}"
    []
  rescue => e
    Rails.logger.error "SFTP connection error: #{e.message}"
    []
  end

  def download_file(remote_path, local_path)
    Net::SFTP.start(@host, @username, password: @password) do |sftp|
      sftp.download!(remote_path, local_path)
      true
    end
  rescue => e
    Rails.logger.error "Failed to download #{remote_path}: #{e.message}"
    false
  end

  def delete_remote_file(remote_path)
    Net::SFTP.start(@host, @username, password: @password) do |sftp|
      sftp.remove!(remote_path)
      true
    end
  rescue => e
    Rails.logger.error "Failed to delete #{remote_path}: #{e.message}"
    false
  end

  def move_file(remote_path, destination_path)
    Net::SFTP.start(@host, @username, password: @password) do |sftp|
      sftp.rename!(remote_path, destination_path)
      true
    end
  rescue => e
    Rails.logger.error "Failed to move #{remote_path}: #{e.message}"
    false
  end
end
