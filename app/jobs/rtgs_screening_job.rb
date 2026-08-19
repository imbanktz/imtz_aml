class RtgsScreeningJob < ApplicationJob
  queue_as :default
  
  # Retry on failure
  retry_on StandardError, wait: :exponentially_longer, attempts: 3
  

  def perform(rtgs_message, transaction_id = nil)
    # Store the job ID for tracking
    if transaction_id.present?
      transaction = Transaction.find(transaction_id)
      transaction.update(job_id: job_id, screening_status: 'processing')
    end
    
    begin
      if transaction_id.present?
        transaction = Transaction.find(transaction_id)
        process_existing_transaction(transaction, rtgs_message)
      else
        process_new_rtgs(rtgs_message)
      end
    rescue StandardError => e
      # Update status on failure
      if transaction_id.present?
        Transaction.find(transaction_id).update(
          screening_status: 'FAILED',
          screening_attempts: (Transaction.find(transaction_id).screening_attempts || []) << {
            timestamp: Time.current.iso8601,
            status: 'FAILED',
            error: e.message,
            job_id: job_id
          }
        )
      end
      raise e
    end
  end
  
  private
  
  def process_transaction(transaction, rtgs_message)
    Rails.logger.info("🔄 Re-processing transaction #{transaction.id}")
    
    # Update the raw message if provided
    transaction.update(raw_rtgs_message: rtgs_message) if rtgs_message.present?
    
    # Re-parse and screen
    parser = RtgsParserService.new(rtgs_message || transaction.raw_rtgs_message)
    parsed_data = parser.call
    
    # Send for screening
    screening_service = TransactionScreeningService.new
    screening_result = screening_service.screen_payload(parsed_data)
    
    # Update transaction with results
    update_transaction_with_screening(transaction, screening_result)
    
    # Notify about completion
    notify_completion(transaction, screening_result)
  end

  def process_existing_transaction(transaction, rtgs_message)
    Rails.logger.info("🔄 Processing transaction #{transaction.id}")
    
    # Update the raw message if provided
    transaction.update(raw_rtgs_message: rtgs_message) if rtgs_message.present?
    
    # Re-parse and screen
    parser = RtgsParserService.new(rtgs_message || transaction.raw_rtgs_message)
    parsed_data = parser.call
    
    # Send for screening
    screening_service = TransactionScreeningService.new
    screening_result = screening_service.screen_payload(parsed_data)
    
    # Update transaction with results
    update_transaction_with_screening(transaction, screening_result)
    
    # Notify about completion
    notify_completion(transaction, screening_result)
    
    # Clear job_id after completion
    transaction.update(job_id: nil)
  end
  
  def process_new_rtgs(rtgs_message)
    Rails.logger.info("📨 Processing new RTGS message")
    
    processor = RtgsTransactionProcessor.new(rtgs_message)
    result = processor.process
    
    # Notify about completion
    notify_completion(result[:transaction], result[:screening])
    
    result
  end
  
  def update_transaction_with_screening(transaction, screening_result)
    attempts = transaction.screening_attempts || []
    
    if screening_result[:success]
      transaction.update(
        screening_status: 'PASSED',
        screening_result: screening_result[:result],
        screening_attempts: attempts << {
          timestamp: Time.current.iso8601,
          status: 'success',
          result: screening_result[:result]
        }
      )
    else
      transaction.update(
        screening_status: 'FAILED',
        screening_attempts: attempts << {
          timestamp: Time.current.iso8601,
          status: 'FAILED',
          error: screening_result[:error]
        }
      )
    end
  end
  
  def notify_completion(transaction, screening_result)
    # You can implement notifications here
    # Examples: WebSocket, Email, Slack, etc.
    
    if screening_result[:success]
      Rails.logger.info("✅ Transaction #{transaction.id} screened successfully")
    # TransactionScreeningChannel.broadcast_to(transaction, screening_result)
    else
      Rails.logger.error("❌ Transaction #{transaction.id} screening FAILED: #{screening_result[:error]}")
    end
  end
end
