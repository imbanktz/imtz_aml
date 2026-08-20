# config/initializers/console_helpers.rb
if Rails.env.development? || Rails.env.production?
  module ConsoleHelpers
    def process_rtgs_files
      puts "🔄 Processing RTGS files..."
      ProcessRemoteFilesJob.perform_now
      puts "✅ Processing completed"
    end

    def screen_transaction(id)
      transaction = Transaction.find(id)
      puts "🔍 Screening transaction #{id}..."
      
      service = TransactionScreeningService.new
      result = service.screen_transaction(transaction)
      
      transaction.update(
        screening_status: result['status'] || 'completed',
        screening_result: result
      )
      
      puts "✅ Screening completed: #{result['status']}"
      result
    end

    def rtgs_stats
      puts "📊 RTGS Statistics:"
      puts "  Total: #{Transaction.count}"
      puts "  Pending: #{Transaction.where(screening_status: 'pending').count}"
      puts "  Processing: #{Transaction.where(screening_status: 'processing').count}"
      puts "  Failed: #{Transaction.where(screening_status: 'failed').count}"
      puts "  Completed: #{Transaction.where(screening_status: 'completed').count}"
      
      if Redis.current.get('rtgs_processor:last_run')
        puts "  Last run: #{Redis.current.get('rtgs_processor:last_run')}"
      end
    end
  end

  def process_rtgs_manual(limit = nil)
    remote_path = AMLOCK_SOURCE_FILES
    remote_service = RemoteFileService.new(
      host: AMLOCK_SERVER_IP,
      username: AMLOCK_USER_NAME,
      password: AMLOCK_PASSWORD
    )
    
    all_files = remote_service.list_rtgs_files(remote_path) || []
    files_to_process = limit ? all_files.first(limit) : all_files
    
    puts "📥 Processing #{files_to_process.count} files with manual parser"
    
    results = { processed: 0, failed: 0, skipped: 0 }
    
    files_to_process.each do |file|
      file_name = file.is_a?(String) ? file : file.name
      puts "\n📄 #{file_name}"
      
      # Use the job to process
      job = ProcessRtgsWithManualParserJob.new
      result = job.send(:process_file, remote_service, file, remote_path)
      
      case result
      when :processed
        results[:processed] += 1
      when :skipped
        results[:skipped] += 1
      else
        results[:failed] += 1
      end
    end
    
    puts "\n" + "=" * 60
    puts "📊 Summary:"
    puts "  Processed: #{results[:processed]}"
    puts "  Failed: #{results[:failed]}"
    puts "  Skipped: #{results[:skipped]}"
    puts "  Total: #{results.values.sum}"
    
    results
  end

  def process_rtgs_batch(count = 5)
    process_rtgs_manual(count)
  end

  def check_screening_results
    puts "📊 Screening Results:"
    completed = Transaction.where(screening_status: 'completed')
    failed = Transaction.where(screening_status: 'failed')
    pending = Transaction.where(screening_status: 'pending')
    
    puts "  Completed: #{completed.count}"
    puts "  Failed: #{failed.count}"
    puts "  Pending: #{pending.count}"
    
    if completed.any?
      puts "\n📋 Latest results:"
      completed.order(updated_at: :desc).limit(5).each do |t|
        result = t.screening_result.is_a?(Hash) ? t.screening_result['result'] || t.screening_result : t.screening_result
        check_result = result.is_a?(Hash) ? result['checkResult'] : 'N/A'
        puts "  #{t.rtgs_reference}: #{check_result}"
      end
    end
  end

  include ConsoleHelpers
end
