# app/jobs/generate_pm_work_orders_job.rb
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
