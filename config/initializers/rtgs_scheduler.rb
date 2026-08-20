require 'rufus-scheduler'

if Rails.env.production? || Rails.env.development?
  # Use the manual parser for all processing
  $rtgs_scheduler = Rufus::Scheduler.new

  $rtgs_scheduler.every '3m' do
    begin
      if Redis.current.get('rtgs_processor:running') != 'true'
        Redis.current.set('rtgs_processor:running', 'true')
        Redis.current.expire('rtgs_processor:running', 180)
        
        Rails.logger.info "⏰ Scheduled RTGS processing triggered at #{Time.current}"
        puts "⏰ Scheduled RTGS processing triggered at #{Time.current}"
        
        result = ProcessRtgsWithManualParserJob.perform_now
        
        Redis.current.set('rtgs_processor:last_result', result.to_json)
        Redis.current.set('rtgs_processor:last_run', Time.current.to_s)
        
        Rails.logger.info "✅ Scheduled RTGS processing completed: #{result.inspect}"
        puts "✅ Scheduled RTGS processing completed: #{result.inspect}"
      else
        Rails.logger.info "⏭️ Skipping RTGS processing - previous run still in progress"
        puts "⏭️ Skipping RTGS processing - previous run still in progress"
      end
    rescue => e
      Rails.logger.error "❌ Scheduled RTGS processing failed: #{e.message}"
      puts "❌ Scheduled RTGS processing failed: #{e.message}"
    ensure
      Redis.current.set('rtgs_processor:running', 'false')
    end
  end

  Rails.logger.info "✅ RTGS Scheduler initialized with manual parser - processing every 3 minutes"
  puts "✅ RTGS Scheduler initialized with manual parser - processing every 3 minutes"
end
