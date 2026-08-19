class Api::V1::RtgsSchedulerController < ApplicationController
  def trigger
    if params[:async] == 'true'
      RtgsProcessingJob.perform_later
      render json: { message: "RTGS processing job queued", async: true }
    else
      result = RtgsSchedulerService.process_rtgs_files
      render json: { 
               message: "RTGS processing completed",
               result: result
             }
    end
  end

  def status
    render json: {
             running: Redis.current.get('rtgs_processor:running') == 'true',
             last_run: Redis.current.get('rtgs_processor:last_run') || 'never',
             last_result: JSON.parse(Redis.current.get('rtgs_processor:last_result') || '{}'),
             pending_transactions: Transaction.where(screening_status: 'pending').count,
             processing_transactions: Transaction.where(screening_status: 'processing').count,
             failed_transactions: Transaction.where(screening_status: 'failed').count,
             completed_transactions: Transaction.where(screening_status: 'completed').count,
             total_transactions: Transaction.count
           }
  end

  def history
    transactions = Transaction.order(created_at: :desc).limit(20)
    
    render json: {
             transactions: transactions.map do |t|
               {
                 id: t.id,
                 reference: t.rtgs_reference || t.reference,
                 amount: t.transaction_amount,
                 currency: t.transaction_currency,
                 direction: t.transaction_direction,
                 screening_status: t.screening_status,
                 created_at: t.created_at,
                 screening_result: t.screening_result.present? ? {
                   status: t.screening_result['status'],
                   check_result: t.screening_result['checkResult']
                 } : nil
               }
             end
           }
  end
end 
