#
#
# Copyright (c) 2025 
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
# @package AML project
# @author abdimuna, abdillah.muna@imbank.co.tz | abdimuna1@gmail.com
# @Company  I&M BANK 
# @description SFT file handler, upload and download remote files
# @license  private
# @version  0.0.1:
# @usage  Use ruby convention, when handling this code
##/


class RtgsDownloadProcessorJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(remote_path = nil)
    remote_path ||= ENV['REMOTE_RTGS_PATH'] || '/incoming/rtgs'
    download_dir = Rails.root.join('tmp', 'rtgs_downloads')
    processed_dir = Rails.root.join('tmp', 'rtgs_processed')

    FileUtils.mkdir_p(download_dir)
    FileUtils.mkdir_p(processed_dir)

    remote_service = RemoteFileService.new
    files = remote_service.list_rtgs_files(remote_path)

    Rails.logger.info "Found #{files.count} RTGS files to process"

    files.each do |file|
      process_rtgs_file(remote_service, file, remote_path, download_dir, processed_dir)
    end
  end

  private

  def process_rtgs_file(remote_service, file, remote_path, download_dir, processed_dir)
    local_path = download_dir.join(file.name)
    remote_full_path = File.join(remote_path, file.name)

    # Download the file
    Rails.logger.info "Downloading #{file.name}..."
    unless remote_service.download_file(remote_full_path, local_path)
      Rails.logger.error "Failed to download #{file.name}"
      return
    end

    # Process the RTGS message
    process_rtgs_content(local_path, file.name)

    # Move processed file
    processed_path = processed_dir.join(file.name)
    FileUtils.mv(local_path, processed_path)

    # Optionally delete from remote server after successful processing
    remote_service.delete_remote_file(remote_full_path)

    Rails.logger.info "✅ Successfully processed #{file.name}"
  rescue StandardError => e
    Rails.logger.error "Error processing #{file.name}: #{e.message}"
    # Move to error directory for manual review
    error_dir = Rails.root.join('tmp', 'rtgs_errors')
    FileUtils.mkdir_p(error_dir)
    FileUtils.mv(local_path, error_dir.join(file.name)) if File.exist?(local_path)
  end

  def process_rtgs_content(file_path, filename)
    rtgs_message = File.read(file_path)

    # Parse the RTGS message
    parser = RtgsParserService.new(rtgs_message)
    parsed_data = parser.call

    unless parsed_data
      Rails.logger.error "Failed to parse RTGS message from #{filename}"
      return
    end

    # Find or create transaction
    transaction = Transaction.find_or_initialize_by(
      rtgs_reference: parsed_data['reference']
    )

    # Update transaction with parsed data
    transaction.assign_attributes(
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
      screening_status: 'PENDING'
    )

    if transaction.save
      Rails.logger.info "✅ Transaction saved with ID: #{transaction.id}"
      
      # Trigger screening
      screen_transaction(transaction)
    else
      Rails.logger.error "Failed to save transaction: #{transaction.errors.full_messages.join(', ')}"
    end
  end

  def screen_transaction(transaction)
    screening_service = TransactionScreeningService.new
    result = screening_service.screen_transaction(transaction)

    transaction.update(
      screening_status: result['status'] || 'PROCESSED',
      screening_result: result
    )

    Rails.logger.info "Screening PROCESSED for transaction #{transaction.id}: #{result['status']}"
  rescue => e
    Rails.logger.error "Screening FAILED for transaction #{transaction.id}: #{e.message}"
    transaction.update(
      screening_status: 'FAILED',
      screening_result: { error: e.message }
    )
  end
end
