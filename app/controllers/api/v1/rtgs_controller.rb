class Api::V1::RtgsController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  def process
    rtgs_message = params[:message] || request.raw_post
    
    if rtgs_message.blank?
      render json: { 
        success: false, 
        error: "No RTGS message provided" 
      }, status: :bad_request
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
      Rails.logger.error("RTGS Processing Error: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      
      render json: {
        success: false,
        error: e.message
      }, status: :unprocessable_entity
    end
  end
end
