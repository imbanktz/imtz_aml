# # config/initializers/rtgs_scheduler.rb
# require 'rufus-scheduler'

# if defined?(Rails::Server) || Rails.env.production?
#   # Create a global scheduler instance
#   $rtgs_scheduler = Rufus::Scheduler.new

#   # Schedule RTGS file processing every 3 minutes
#   $rtgs_scheduler.every '3m' do
#     begin
#       # Check if the job is already running
#       if Redis.current.get('rtgs_processor:running') != 'true'
#         Redis.current.set('rtgs_processor:running', 'true')
#         Redis.current.expire('rtgs_processor:running', 180)
        
#         Rails.logger.info "⏰ Scheduled RTGS processing triggered at #{Time.current}"
        
#         # Process files using your existing job
#         ProcessRemoteFilesJob.perform_now
        
#         Redis.current.set('rtgs_processor:last_run', Time.current.to_s)
#         Rails.logger.info "✅ Scheduled RTGS processing completed"
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

#   Rails.logger.info "✅ RTGS Scheduler initialized - processing every 3 minutes"
# end
