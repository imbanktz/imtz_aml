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

class GeneratePmWorkOrdersJob < ApplicationJob
  queue_as :default

  def perform
    PmSchedule.where(active: true).each do |schedule|
      assets = if schedule.equipment_category == 'All'
        Asset.active.operational
      else
        Asset.active.operational.where("make ILIKE ?", "%#{schedule.equipment_category}%")
      end
      
      assets.each do |asset|
        last_pm = asset.work_orders.where(wo_type: 'preventive')
                      .where("reported_at > ?", 30.days.ago)
                      .order(reported_at: :desc).first
        
        # Check if due based on hours
        hours_since_last_pm = asset.current_hour_meter - (last_pm&.meter_at_report || 0)
        
        if hours_since_last_pm >= schedule.trigger_hours
          WorkOrder.find_or_create_by!(
            asset: asset,
            wo_type: 'preventive',
            status: 'scheduled',
            defect_description: "Auto-generated: #{schedule.name} service due at #{asset.current_hour_meter} hours",
            reported_at: Time.current,
            reported_by: User.find_by(email: 'system@fleet.com')
          )
        end
      end
    end
  end
end
