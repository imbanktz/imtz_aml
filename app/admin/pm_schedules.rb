ActiveAdmin.register PmSchedule do
  permit_params :name, :equipment_category, :trigger_hours, :checklist_template,
                :estimated_hours, :active

  index do
    selectable_column
    column :name
    column :equipment_category
    column :trigger_hours do |s|
      "#{s.trigger_hours} hours"
    end
    column :estimated_hours
    column :active do |s|
      status_tag s.active ? 'Active' : 'Inactive'
    end
    actions
  end

  form do |f|
    f.inputs 'Schedule Details' do
      f.input :name
      f.input :equipment_category, as: :select, collection: ['Excavator', 'Wheel Tractor', 'Truck', 'Loader', 'All']
      f.input :trigger_hours, label: 'Trigger Interval (hours)'
      f.input :estimated_hours
      f.input :active
    end

    f.inputs 'Checklist Template' do
      f.input :checklist_template, as: :jsonb, 
              hint: 'JSON format: [{"item": "Check oil", "required": true, "lubricant": "15W40", "quantity_liters": 15}]'
    end

    f.actions
  end

  member_action :generate_work_orders, method: :post do
    schedule = PmSchedule.find(params[:id])
    
    # Find eligible assets
    assets = if schedule.equipment_category == 'All'
               Asset.active.operational
             else
               Asset.active.operational.joins(:model).where(asset_models: { category: schedule.equipment_category })
             end
    
    generated_count = 0
    assets.each do |asset|
      # Check if work order already exists for this schedule recently
      last_wo = asset.work_orders.where(wo_type: 'preventive')
                  .where("reported_at > ?", 30.days.ago).last
      
      next if last_wo && last_wo.reported_at > 14.days.ago
      
      WorkOrder.create!(
        asset: asset,
        wo_type: 'preventive',
        priority: 'medium',
        defect_description: "PM Service: #{schedule.name} - #{schedule.trigger_hours}h interval",
        meter_at_report: asset.current_hour_meter,
        reported_by: current_admin_user,
        reported_at: Time.current,
        status: 'scheduled'
      )
      generated_count += 1
    end
    
    redirect_to admin_pm_schedule_path(schedule), notice: "Generated #{generated_count} work orders"
  end

  action_item :generate, only: :show do
    link_to 'Generate Work Orders', generate_work_orders_admin_pm_schedule_path(pm_schedule), 
            method: :post, data: { confirm: 'Generate PM work orders for eligible assets?' }
  end
end
