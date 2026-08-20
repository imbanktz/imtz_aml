namespace :rtgs do
  desc "Process RTGS files using manual parser"
  task process_manual: :environment do
    puts "🚀 Starting RTGS manual processing..."
    result = ProcessRtgsWithManualParserJob.perform_now
    puts "✅ Processing completed: #{result.inspect}"
  end

  desc "Process RTGS files using manual parser with limit"
  task :process_manual_limit, [:limit] => :environment do |t, args|
    limit = args[:limit].to_i || 5
    puts "🚀 Starting RTGS manual processing with limit #{limit}..."
    
    remote_path = "/amlock/Tanzania/RMS/mxt_to_mt/rtgs_source_only"
    remote_service = RemoteFileService.new(
      host: AMLOCK_SERVER_IP,
      username: AMLOCK_USER_NAME,
      password: AMLOCK_PASSWORD
    )
    
    all_files = remote_service.list_rtgs_files(remote_path) || []
    files_to_process = all_files.first(limit)
    
    puts "Processing #{files_to_process.count} files..."
    
    files_to_process.each do |file|
      puts "  Processing: #{file.name}"
      # Process each file...
    end
  end

  desc "Check RTGS processing status"
  task status: :environment do
    puts "📊 RTGS Processing Status:"
    puts "  Total Transactions: #{Transaction.count}"
    puts "  Pending Screening: #{Transaction.where(screening_status: 'pending').count}"
    puts "  Processing: #{Transaction.where(screening_status: 'processing').count}"
    puts "  Completed: #{Transaction.where(screening_status: 'completed').count}"
    puts "  Failed: #{Transaction.where(screening_status: 'failed').count}"
    
    if Redis.current.get('rtgs_processor:last_run')
      puts "  Last run: #{Redis.current.get('rtgs_processor:last_run')}"
    end
    
    if Redis.current.get('rtgs_processor:last_result')
      puts "  Last result: #{Redis.current.get('rtgs_processor:last_result')}"
    end
  end
end
