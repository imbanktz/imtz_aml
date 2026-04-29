# coding: utf-8
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
# @package  iPG
# @author abdimuna, abdillah.muna@imbank.co.tz | abdimuna1@gmail.com
# @Company  I&M Bank (T)
# @description  Transaction screening
# @license  private
# @version  0.0.1:
# @usage  Use ruby convention, when handling this code
##/


class Api::V1::TransactionScreeningController < ApplicationController

  
  include HTTParty
  base_uri THETARAY_BASE_URL
  default_timeout 90 #seconds
  skip_before_action :verify_authenticity_token

  # POST /transaction_screening/:id
  def txn_screen
    transaction = Transaction.find(params[:id])

    token = fetch_token
    return render json: { error: 'Token fetch failed' }, status: :unauthorized unless token
    response = send_screening_request(transaction, token)
    parsed = parse_screening_response(response)
    render json: parsed, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Transaction not found' }, status: :not_found
  rescue => e
    Rails.logger.error("Screening error: #{e.message}")
    render json: { error: e.message }, status: :internal_server_error
  end

  private

  # 🔐 TOKEN (CACHED - expires in 5 minutes)
  def fetch_token
    Rails.cache.fetch("thetaray_token", expires_in: 4.minutes) do
      response = self.class.post(
        API_TOKEN,
        headers: { 'Content-Type' => 'application/json' },
        body: { clientSecret: 'thetaray' }.to_json
      )

      raise "Token request failed: #{response.body}" unless response.success?
      parsed = JSON.parse(response.body)
      # ✅ IMPORTANT: your API returns "token", not "access_token"
      parsed['token']
    end
  rescue => e
    Rails.logger.error("Token error: #{e.message}")
    nil
  end

  # 🚀 SEND REQUEST
  def send_screening_request(transaction, token)
    self.class.post(
      API_TRANSACTION_SCREENING,
      headers: {
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{token}"
      },
      body: build_payload(transaction).to_json
    )
  end

  # 🧱 BUILD PAYLOAD FROM YOUR MODEL
  def build_payload(transaction)
    {
      requestId: transaction.request_id,
      transactionDirection: transaction.transaction_direction,
      transactionAmount: transaction.transaction_amount.to_s,
      transactionCurrency: transaction.transaction_currency,
      transactionDate: transaction.transaction_date.to_s,
      parties: format_parties(transaction.parties)
    }
  end

  def format_parties(parties)
    parties.map do |p|
      {
        partyId: p['partyId'],
        partyType: p['partyType'],
        fullName: p['fullName'],
        nationalities: p['nationalities'] || [],
        addressLine: p['addressLine'] || ""
      }
    end
  end

  # 🧠 PARSE RESPONSE INTO USEFUL STRUCTURE
  def parse_screening_response(response)
    body = JSON.parse(response.body)
    result = body['result'] || {}
    {
      status: response.code,
      check_result: result['checkResult'], # MATCH / NO_MATCH
      status_polling_url: result['statusPollingUrl'],
      matches: format_matches(result['matchResults'] || []),
      high_risk: high_risk?(result['matchResults']),
      total_matches: (result['matchResults'] || []).size
    }
  rescue => e
    {
      status: response.code,
      error: "Failed to parse response",
      raw_body: response.body
    }
  end

  # 🎯 CLEAN MATCH STRUCTURE
  def format_matches(matches)
    matches.map do |m|
      {
        entity_type: m['entityType'],
        score: m['score'].to_f,
        list: m['list'],
        published_at: m['dateOfPublication']
      }
    end
  end

  # 🚨 RISK LOGIC (CUSTOMIZABLE)
  def high_risk?(matches)
    return false if matches.blank?
    matches.any? { |m| m['score'].to_f >= 0.95 }
  end
  
end
