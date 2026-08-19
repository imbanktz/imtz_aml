class Api::V1::RtgsController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  # Sync
  def process_sync
    rtgs_message = params[:message] || request.raw_post
    
    if rtgs_message.blank?
      render json: { success: false, error: "No RTGS message provided" }, status: :bad_request
      return
    end
    
    begin
      processor = RtgsTransactionProcessor.new(rtgs_message)
      result = processor.process
      
      render json: {
               success: true,
               transaction: {
                 id: result[:transaction].id,
                 request_id: result[:transaction].request_id,
                 amount: result[:transaction].transaction_amount,
                 currency: result[:transaction].transaction_currency,
                 reference: result[:transaction].rtgs_reference,
                 screening_status: result[:transaction].screening_status
               },
               screening: result[:screening]
             }, status: :ok
      
    rescue StandardError => e
      render json: { success: false, error: e.message }, status: :unprocessable_entity
    end
  end
  
  # Async
  def process_async
    rtgs_message = params[:message] || request.raw_post
    
    if rtgs_message.blank?
      render json: { success: false, error: "No RTGS message provided" }, status: :bad_request
      return
    end
    
    # Create a placeholder transaction
    parser = RtgsParserService.new(rtgs_message)
    parsed_data = parser.call
    
    transaction = Transaction.create(
      request_id: parsed_data[:requestId],
      transaction_direction: parsed_data[:transactionDirection],
      transaction_amount: parsed_data[:transactionAmount].to_d / 100.0,
      transaction_currency: parsed_data[:transactionCurrency],
      transaction_date: parsed_data[:transactionDate],
      clearing_system_ref: parsed_data[:clearingSystemRef],
      parties: parsed_data[:parties],
      agents: parsed_data[:agents],
      narratives: parsed_data[:narratives],
      processing_type: parsed_data[:processingType] || 'CHECK',
      profile: parsed_data[:profile] || 'Tanzania',
      profile_name: parsed_data[:profileName] || 'Tanzania',
      raw_rtgs_message: rtgs_message,
      rtgs_reference: extract_rtgs_reference(rtgs_message),
      screening_status: 'pending'
    )
    
    # Enqueue the job
    RtgsScreeningJob.perform_later(rtgs_message, transaction.id)
    
    render json: {
             success: true,
             message: "Transaction queued for screening",
             transaction_id: transaction.id,
             request_id: transaction.request_id,
             status_url: api_rtgs_status_url(transaction.id)
           }, status: :accepted
  end
  
  # Check status of async processing
  def status
    transaction = Transaction.find(params[:id])
    
    render json: {
             id: transaction.id,
             request_id: transaction.request_id,
             status: transaction.screening_status,
             screening_result: transaction.screening_result,
             created_at: transaction.created_at,
             updated_at: transaction.updated_at
           }
  end
  
  # Re-process a failed transaction
  def reprocess
    transaction = Transaction.find(params[:id])
    
    if transaction.raw_rtgs_message.blank?
      render json: { success: false, error: "No RTGS message found for this transaction" }, status: :unprocessable_entity
      return
    end
    
    # Reset screening status and queue for reprocessing
    transaction.update(screening_status: 'pending')
    RtgsScreeningJob.perform_later(transaction.raw_rtgs_message, transaction.id)
    
    render json: {
             success: true,
             message: "Transaction requeued for screening",
             transaction_id: transaction.id
           }, status: :accepted
  end
  
  private
  
  def extract_rtgs_reference(message)
    if message =~ /:20:([^\n:]+)/
      $1.strip
    else
      nil
    end
  end
end
