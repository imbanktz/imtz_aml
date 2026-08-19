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
# @description Screening controller
# @license  private
# @version  0.0.1:
# @usage  Use ruby convention, when handling this code
##/

class Api::V1::ScreeningController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  def test_screening
    # Use the sample payload from the curl command
    payload = {
      requestId: "IMTZTRX10765367800987532223",
      transactionDirection: "OUT",
      transactionAmount: 19760000,
      transactionCurrency: "TZS",
      transactionDate: "2026-08-18",
      clearingSystemRef: "TZIMBAN",
      parties: [
        {
          partyId: "1333300",
          partyType: "Debtor",
          fullName: "Kasilda Jeremia Mgeni",
          nationalities: ["TZ"],
          addressLine: "Dar Es Salaam, TZ",
          typeValue: "Debtor"
        },
        {
          partyId: "662662626",
          partyType: "Creditor",
          fullName: "Ezekiel Paulin Masawe",
          nationalities: ["TZ"],
          addressLine: "Arusha, TZ",
          typeValue: "Creditor"
        }
      ],
      agents: [
        {
          agentId: "IMTZ",
          agentType: "InstructingAgent",
          bic: "IMBLTZTZ",
          typeValue: "InstructingAgent"
        },
        {
          agentId: "CRDBTZTZ",
          agentType: "InstructedAgent",
          bic: "CRDBTZTZ",
          typeValue: "InstructedAgent"
        }
      ],
      narratives: {
        remittanceInfo: "Sender TEST ONE",
        all: ["Sender TEST ONE"]
      },
      forensicData: {},
      processingType: "CHECK",
      profile: "Tanzania",
      profileName: "Tanzania"
    }
    
    service = TransactionScreeningService.new
    result = service.screen_payload(payload)
    
    render json: result
  end
  
  def test_rtgs
    rtgs_message = params[:message] || '{1:F01IMBLTZTZXXX0623162310}{2:O1031623260623NLCBTZTXFIN06231623102606231623N}{3:{103:TIS}{113:NNNN}{108:001FTOL261740709}{119:STP}{111:001}{121:e0fa079a-08d4-4785-827c-517df485e1ef}}{4::20:001FTOL261740709:23B:CRED:32A:260623TZS174308602,00:33B:TZS174308602,00:50F:/041103002729 1/REDINGTON TANZANIA LIMITED 2/ 3/TZ/DAR ES SALAAM/:52A:NLCBTZTXFIN:57A:IMBLTZTZXXX:59:/30021830001 Liveal Limited Dar Es Salaam Tanzania:70:Payment to LIVEAL LIMITED:71A:OUR:72:Payment to LIVEAL LIMITED-}'
    
    service = TransactionScreeningService.new
    result = service.screen_rtgs_message(rtgs_message)
    
    render json: result
  end
end
