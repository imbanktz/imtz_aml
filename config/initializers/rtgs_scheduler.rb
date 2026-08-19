# require 'rufus-scheduler'

# if Rails.env.production? || Rails.env.development?
#   # Create a global scheduler instance
#   $rtgs_scheduler = Rufus::Scheduler.new

#   # Schedule RTGS file processing every 3 minutes
#   $rtgs_scheduler.every '3m' do
#     begin
#       # Only run if the previous run is finished
#       if Redis.current.get('rtgs_processor:running') != 'true'
#         Redis.current.set('rtgs_processor:running', 'true')
#         Redis.current.expire('rtgs_processor:running', 180) # Expire after 3 minutes
        
#         Rails.logger.info "⏰ Scheduled RTGS processing triggered at #{Time.current}"
        
#         result = RtgsSchedulerService.process_rtgs_files
        
#         # Store result in Redis
#         Redis.current.set('rtgs_processor:last_result', result.to_json)
#         Redis.current.set('rtgs_processor:last_run', Time.current.to_s)
        
#         Rails.logger.info "✅ Scheduled RTGS processing completed: #{result[:processed]} processed, #{result[:failed]} failed"
#       else
#         Rails.logger.info "⏭️ Skipping RTGS processing - previous run still in progress"
#       end
#     rescue => e
#       Rails.logger.error "❌ Scheduled RTGS processing failed: #{e.message}"
#       Rails.logger.error e.backtrace.join("\n")
#     ensure
#       Redis.current.set('rtgs_processor:running', 'false')
#     end
#   end

#   # Optional: Schedule a cleanup job daily at midnight
#   $rtgs_scheduler.cron '0 0 * * *' do
#     Rails.logger.info "🧹 Running RTGS file cleanup"
#     cleanup_rtgs_files
#   end

#   Rails.logger.info "✅ RTGS Scheduler initialized - processing every 3 minutes"
# end

# def cleanup_rtgs_files
#   # Clean up processed files older than 30 days
#   processed_dir = Rails.root.join('tmp', 'rtgs_processed')
#   if processed_dir.exist?
#     processed_dir.children.each do |file|
#       if file.mtime < 30.days.ago
#         File.delete(file)
#         Rails.logger.info "Deleted old processed file: #{file.basename}"
#       end
#     end
#   end
  
#   # Clean up error files older than 30 days
#   error_dir = Rails.root.join('tmp', 'rtgs_errors')
#   if error_dir.exist?
#     error_dir.children.each do |file|
#       if file.mtime < 30.days.ago
#         File.delete(file)
#         Rails.logger.info "Deleted old error file: #{file.basename}"
#       end
#     end
#   end
  
#   # Clean up downloads older than 7 days
#   download_dir = Rails.root.join('tmp', 'rtgs_downloads')
#   if download_dir.exist?
#     download_dir.children.each do |file|
#       if file.mtime < 7.days.ago
#         File.delete(file)
#         Rails.logger.info "Deleted old download file: #{file.basename}"
#       end
#     end
#   end
# end
