# lib/tasks/import_transactions.rake
namespace :import do
  desc "Import transactions from CSV file"
  task transactions: :environment do
    require 'csv'
    require 'json'
    
    file_path = ENV['FILE_PATH'] || 'full_transactions.csv'
    success_count = 0
    error_count = 0
    
    CSV.foreach(file_path, headers: true) do |row|
      begin
        request_data = JSON.parse(row['request_data'])
        
        transaction = Transaction.find_or_initialize_by(request_id: request_data['requestId'])
        
        transaction.attributes = {
          date: row['date'],
          request_id: request_data['requestId'],
          transaction_direction: request_data['transactionDirection'],
          transaction_amount: request_data['transactionAmount'],
          transaction_currency: request_data['transactionCurrency'],
          transaction_date: request_data['transactionDate'],
          clearing_system_ref: request_data['clearingSystemRef'],
          parties: request_data['parties'],
          agents: request_data['agents'],
          narratives: request_data['narratives'],
          forensic_data: request_data['forensicData'],
          processing_type: request_data['processingType'],
          profile: request_data['profile'],
          profile_name: request_data['profileName']
        }
        
        if transaction.save
          success_count += 1
          print "."
        else
          error_count += 1
          puts "\nError saving transaction #{request_data['requestId']}: #{transaction.errors.full_messages.join(', ')}"
        end
      rescue JSON::ParserError => e
        error_count += 1
        puts "\nJSON parsing error for row: #{e.message}"
      rescue StandardError => e
        error_count += 1
        puts "\nUnexpected error: #{e.message}"
      end
    end
    
    puts "\n\nImport completed!"
    puts "Successfully imported: #{success_count} transactions"
    puts "Failed: #{error_count} transactions"
  end
end
