#
#
# Copyright (c) 2026 
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# @package  RTGS screening
# @author abdimuna, abdillah.muna@imbank.co.tz | abdimuna1@gmail.com
# @Company  I&M BANK 
# @description SFT file handler, upload and download remote files
# @license  private
# @version  0.0.1:
# @usage  Use ruby convention, when handling this code
##/

class RtgsScreeningJob < ApplicationJob
  queue_as :screening
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(rtgs_message, transaction_id = nil)
    @transaction = transaction_id ? Transaction.find(transaction_id) : nil
    
    if @transaction
      @transaction.update(screening_status: 'processing', job_id: job_id)
    end
    
    begin
      # Parse if we have a raw message
      if rtgs_message.present?
        parser = RtgsParserService.new(rtgs_message)
        parsed_data = parser.call
        
        if parsed_data && !@transaction
          # Create transaction if it doesn't exist
          create_transaction(parsed_data, rtgs_message)
        end
      end
      
      # Perform screening
      if @transaction
        perform_screening
      else
        Rails.logger.error "No transaction found to screen"
        return false
      end
      
    rescue => e
      Rails.logger.error "❌ Screening job failed: #{e.message}"
      @transaction&.update(
        screening_status: 'failed',
        screening_result: { error: e.message, timestamp: Time.current }
      )
      raise
    end
  end

  private

  def create_transaction(parsed_data, rtgs_message)
    @transaction = Transaction.find_or_initialize_by(
      rtgs_reference: parsed_data['reference']
    )
    
    @transaction.assign_attributes(
      request_id: parsed_data['requestId'],
      transaction_direction: parsed_data['transactionDirection'],
      transaction_type: parsed_data['transactionType'],
      transaction_amount: parsed_data['transactionAmount'],
      transaction_currency: parsed_data['transactionCurrency'],
      transaction_date: parsed_data['transactionDate'],
      reference: parsed_data['reference'],
      narrative: parsed_data['narrative'],
      bank_code: parsed_data['bankCode'],
      parties: parsed_data['parties'],
      raw_fields: parsed_data['rawFields'],
      raw_rtgs_message: rtgs_message,
      screening_status: 'pending'
    )
    
    @transaction.save!
    Rails.logger.info "💾 Transaction created with ID: #{@transaction.id}"
  end

  def perform_screening
    Rails.logger.info "🔍 Starting screening for transaction #{@transaction.id}"
    
    screening_service = TransactionScreeningService.new
    result = screening_service.screen_transaction(@transaction)
    
    @transaction.update!(
      screening_status: result['status'] || 'completed',
      screening_result: result
    )
    
    Rails.logger.info "✅ Screening completed for transaction #{@transaction.id}: #{result['status']}"
    
    # Handle screening results
    if result['checkResult'] == 'MATCH'
      handle_match_result(result)
    end
  end

  def handle_match_result(result)
    Rails.logger.warn "⚠️ Match found for transaction #{@transaction.id}"
    # Add notification logic here
  end
end
