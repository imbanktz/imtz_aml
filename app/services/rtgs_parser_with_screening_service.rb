class RtgsParserWithScreeningService
  attr_reader :raw_message, :parsed_result, :screening_result, :transaction

  def initialize(raw_message)
    @raw_message = raw_message
    @parsed_result = nil
    @screening_result = nil
    @transaction = nil
  end

  def call
    # Step 1: Parse the transaction
    parser = RtgsParserService.new(raw_message)
    @parsed_result = parser.call
    
    if @parsed_result.nil?
      return { success: false, error: 'Failed to parse RTGS message', step: 'parsing' }
    end

    # Step 2: Create transaction record
    @transaction = create_transaction_record(@parsed_result)
    
    # Step 3: Perform screening
    @screening_result = perform_screening(@parsed_result)
    
    # Step 4: Update transaction with screening results
    update_transaction_with_screening(@transaction, @screening_result)
    
    {
      success: true,
      transaction: @transaction,
      parsed_data: @parsed_result,
      screening: @screening_result
    }
  rescue StandardError => e
    Rails.logger.error "RTGS Processing Error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    {
      success: false,
      error: e.message,
      step: 'processing',
      transaction: @transaction
    }
  end

  private

  def create_transaction_record(parsed_data)
    Transaction.create!(
      request_id: parsed_data["requestId"],
      transaction_direction: parsed_data["transactionDirection"],
      transaction_type: parsed_data["transactionType"],
      transaction_amount: parsed_data["transactionAmount"],
      transaction_currency: parsed_data["transactionCurrency"],
      transaction_date: parsed_data["transactionDate"],
      reference: parsed_data["reference"],
      narrative: parsed_data["narrative"],
      bank_code: parsed_data["bankCode"],
      parties: parsed_data["parties"],
      raw_data: parsed_data,
      raw_fields: parsed_data["rawFields"],
      raw_message: raw_message,
      status: 'PENDING_SCREENING'
    )
  end

  def perform_screening(parsed_data)
    screening_service = ScreeningService.new(parsed_data)
    screening_service.call
  end

  def update_transaction_with_screening(transaction, screening_result)
    if screening_result[:success]
      transaction.update(
        status: 'SCREENED',
        screening_result: screening_result[:result],
        screening_status: 'SCREENING_PASSED',  # Updated
        screened_at: Time.current
      )
    else
      transaction.update(
        status: 'SCREENING_FAILED',
        screening_error: screening_result[:error],
        screening_status: 'SCREENING_ERROR',   # Updated
        screened_at: Time.current
      )
    end
  end
end
