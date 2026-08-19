class RtgsTransactionProcessor
  def initialize(rtgs_message)
    @rtgs_message = rtgs_message
    @parser = RtgsParserService.new(rtgs_message)
  end

  def process
    # Parse the RTGS message
    parsed_data = @parser.call
    
    # Create or find the transaction
    transaction = find_or_create_transaction(parsed_data)
    
    # Send for screening
    screening_service = TransactionScreeningService.new
    screening_result = screening_service.screen_payload(parsed_data)
    
    # Update transaction with screening results
    update_transaction_with_screening(transaction, screening_result)
    
    # Return the transaction with screening results
    {
      transaction: transaction,
      screening: screening_result
    }
  end

  private

  def find_or_create_transaction(parsed_data)
    Transaction.find_or_initialize_by(
      request_id: parsed_data[:requestId]
    ) do |transaction|
      transaction.attributes = map_to_transaction_attributes(parsed_data)
      transaction.screening_status = 'pending'
    end
  end

  def map_to_transaction_attributes(parsed_data)
    {
      date: Time.current,
      request_id: parsed_data[:requestId],
      transaction_direction: parsed_data[:transactionDirection],
      transaction_amount: parsed_data[:transactionAmount].to_d / 100.0, # Convert from cents
      transaction_currency: parsed_data[:transactionCurrency],
      transaction_date: parsed_data[:transactionDate],
      clearing_system_ref: parsed_data[:clearingSystemRef],
      parties: parsed_data[:parties],
      agents: parsed_data[:agents],
      narratives: parsed_data[:narratives],
      forensic_data: parsed_data[:forensicData] || {},
      processing_type: parsed_data[:processingType] || 'CHECK',
      profile: parsed_data[:profile] || 'Tanzania',
      profile_name: parsed_data[:profileName] || 'Tanzania',
      raw_rtgs_message: @rtgs_message,
      rtgs_reference: extract_rtgs_reference
    }
  end

  def extract_rtgs_reference
    if @rtgs_message =~ /:20:([^\n:]+)/
      $1.strip
    else
      nil
    end
  end

  def update_transaction_with_screening(transaction, screening_result)
    if screening_result[:success]
      transaction.update(
        screening_status: 'PASSED',
        screening_result: screening_result[:result],
        screening_attempts: (transaction.screening_attempts || []) << {
          timestamp: Time.current.iso8601,
          status: 'success',
          result: screening_result[:result]
        }
      )
    else
      transaction.update(
        screening_status: 'FAILED',
        screening_attempts: (transaction.screening_attempts || []) << {
          timestamp: Time.current.iso8601,
          status: 'failed',
          error: screening_result[:error]
        }
      )
    end
  end
end
