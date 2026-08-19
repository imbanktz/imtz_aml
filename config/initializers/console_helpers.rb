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

  include ConsoleHelpers
end
