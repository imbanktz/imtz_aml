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


# app/services/remote_file_service.rb
class RemoteFileService
  def initialize(host: nil, username: nil, password: nil)
    @host = host || ENV['REMOTE_HOST'] || AMLOCK_SERVER_IP
    @username = username || ENV['REMOTE_USERNAME'] || AMLOCK_USER_NAME
    @password = password || ENV['REMOTE_PASSWORD'] || AMLOCK_PASSWORD
  end

  def list_rtgs_files(remote_path = nil)
    remote_path ||= ENV['REMOTE_RTGS_PATH'] || '/incoming/rtgs'
    
    begin
      Net::SFTP.start(@host, @username, password: @password) do |sftp|
        puts "🔍 Listing files in: #{remote_path}"
        entries = sftp.dir.entries(remote_path)
        
        # Filter for RTGS files
        files = entries.select do |entry|
          entry.file? && entry.name.match?(/\.(txt|mt103|rtgs|dat)$/i)
        end
        
        puts "Found #{files.count} RTGS files"
        return files
      end
    rescue Net::SFTP::StatusException => e
      Rails.logger.error "Failed to list files from #{remote_path}: #{e.message}"
      puts "❌ SFTP error: #{e.message}"
      return []  # Return empty array
    rescue => e
      Rails.logger.error "SFTP connection error: #{e.message}"
      puts "❌ Connection error: #{e.message}"
      return []  # Return empty array
    end
  end

  def download_file(remote_path, local_path)
    begin
      Net::SFTP.start(@host, @username, password: @password) do |sftp|
        puts "📥 Downloading: #{remote_path} -> #{local_path}"
        sftp.download!(remote_path, local_path)
        puts "✅ Download complete"
        true
      end
    rescue => e
      Rails.logger.error "Failed to download #{remote_path}: #{e.message}"
      puts "❌ Download failed: #{e.message}"
      false
    end
  end

  def delete_remote_file(remote_path)
    begin
      Net::SFTP.start(@host, @username, password: @password) do |sftp|
        sftp.remove!(remote_path)
        puts "🗑️ Deleted: #{remote_path}"
        true
      end
    rescue => e
      Rails.logger.error "Failed to delete #{remote_path}: #{e.message}"
      false
    end
  end

  def list_all_files(remote_path = nil)
    remote_path ||= ENV['REMOTE_RTGS_PATH'] || '/incoming/rtgs'
    
    begin
      Net::SFTP.start(@host, @username, password: @password) do |sftp|
        entries = sftp.dir.entries(remote_path)
        files = entries.select(&:file?)
        puts "Total files in #{remote_path}: #{files.count}"
        files.each { |f| puts "  #{f.name} (#{f.size} bytes)" }
        files
      end
    rescue => e
      puts "❌ Error listing all files: #{e.message}"
      []
    end
  end
end
