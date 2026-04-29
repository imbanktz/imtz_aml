
ActiveAdmin.register WorkOrder do
  permit_params :asset_id, :wo_type, :priority, :breakdown_reason_id, :defect_description,
                :meter_at_report, :assigned_mechanic_id, :status, :reported_by_id, :reported_at

  includes :asset, :breakdown_reason, :reported_by, :assigned_mechanic

  # Customize the page title
  title = "Work Orders"
  
  # Enhanced Index Page
  index title: "Work Orders", download_links: [:csv, :pdf] do
    selectable_column
    id_column
    column :wo_number, sortable: :wo_number do |wo|
      strong link_to wo.wo_number, admin_work_order_path(wo)
    end
    column :asset do |wo|
      if wo.asset
        div class: "asset-info" do
          strong wo.asset.fleet_number
          small "(#{wo.asset.model&.model_name})"
        end
      end
    end
    column :wo_type do |wo|
      if wo.wo_type
        badge_class = case wo.wo_type
        when 'breakdown' then 'danger'
        when 'preventive' then 'success'
        when 'inspection' then 'info'
        else 'default'
        end
        span wo.wo_type.humanize, class: "status_tag #{badge_class}"
      end
    end
    column :priority do |wo|
      if wo.priority
        priority_class = case wo.priority
        when 'emergency' then 'danger'
        when 'high' then 'warning'
        when 'medium' then 'info'
        else 'default'
        end
        span wo.priority.upcase, class: "status_tag #{priority_class}"
      end
    end
    column :status do |wo|
      if wo.status
        status_class = case wo.status
        when 'completed', 'verified', 'closed' then 'success'
        when 'in_progress' then 'warning'
        when 'pending_parts', 'on_hold' then 'danger'
        else 'info'
        end
        span wo.status.humanize, class: "status_tag #{status_class}"
      end
    end
    column "SLA", :sla_status do |wo|
      if wo.respond_to?(:sla_status)
        sla_class = wo.sla_status == 'OVERDUE' ? 'danger' : 'success'
        span wo.sla_status, class: "status_tag #{sla_class}"
      end
    end
    column :reported_at do |wo|
      if wo.reported_at
        div class: "date-info" do
          strong wo.reported_at.strftime("%Y-%m-%d")
          small wo.reported_at.strftime("%H:%M")
        end
      end
    end
    column "Hours", :hours_down do |wo|
      if wo.respond_to?(:hours_since_report) && wo.hours_since_report > 0
        span "#{wo.hours_since_report}h", class: "hours-badge"
      else
        "-"
      end
    end
    actions defaults: true do |wo|
      if wo.status != 'completed'
        item "Complete", complete_admin_work_order_path(wo), class: "member_link complete-link", 
             data: { confirm: "Complete this work order?" }
      end
    end
  end

  # Enhanced Filters
  filter :wo_number, as: :string, label: "WO Number", input_html: { placeholder: "WO-2026-xxxxx" }
  filter :asset, as: :select, collection: -> { Asset.active.map { |a| [a.fleet_number, a.id] } }, 
         input_html: { class: "select2" }
  filter :wo_type, as: :select, collection: WorkOrder.wo_types.keys.map { |t| [t.humanize, t] }, 
         input_html: { class: "select2" }
  filter :priority, as: :select, collection: WorkOrder.priorities.keys.map { |p| [p.upcase, p] },
         input_html: { class: "select2" }
  filter :status, as: :select, collection: WorkOrder.statuses.keys.map { |s| [s.humanize, s] },
         input_html: { class: "select2" }
  filter :reported_by, as: :select, collection: -> { User.active.map { |u| ["#{u.name} (#{u.employee_id})", u.id] } }
  filter :assigned_mechanic, as: :select, collection: -> { User.mechanic.active.map { |u| [u.name, u.id] } }
  filter :reported_at, as: :date_range, datepicker_options: { format: 'yyyy-mm-dd' }
  filter :created_at, as: :date_range

  # Enhanced Form with better organization and styling
  form html: { class: "work-order-form", multipart: true } do |f|
    f.semantic_errors *f.object.errors.attribute_names
    
    columns do
      column span: 2 do
        f.inputs "Basic Information", class: "panel" do
          f.input :wo_number, input_html: { readonly: true, class: "readonly-field" }, 
                  hint: "Auto-generated" if f.object.persisted?
          f.input :asset, as: :select, 
                  collection: Asset.active.map { |a| [a.full_description || a.fleet_number, a.id] },
                  required: true, include_blank: 'Select Asset', input_html: { class: "select2" }
          f.input :wo_type, as: :select, 
                  collection: WorkOrder.wo_types.keys.map { |t| [t.humanize, t] },
                  required: true, include_blank: 'Select Type', input_html: { class: "select2" }
          f.input :priority, as: :select, 
                  collection: WorkOrder.priorities.keys.map { |p| [p.upcase, p] },
                  required: true, include_blank: 'Select Priority', input_html: { class: "select2" }
        end
      end
      
      column span: 1 do
        f.inputs "Reporting Information", class: "panel" do
          f.input :reported_by_id, as: :select, 
                  collection: User.active.map { |u| ["#{u.name} (#{u.employee_id})", u.id] },
                  required: true, include_blank: 'Select Reporter', label: "Reported By",
                  input_html: { class: "select2" }
          f.input :reported_at, as: :datetime_picker,
                  hint: "When was this work order reported?", required: true
        end
      end
      
      column span: 1 do
        f.inputs "Assignment", class: "panel" do
          f.input :assigned_mechanic_id, as: :select, 
                  collection: User.mechanic.active.map { |u| [u.name, u.id] }, 
                  include_blank: 'Unassigned', label: "Assigned Mechanic",
                  input_html: { class: "select2" }
          f.input :status, as: :select, 
                  collection: WorkOrder.statuses.keys.map { |s| [s.humanize, s] },
                  input_html: { class: "select2", data: { status: f.object.status } }
        end
      end
    end
    
    columns do
      column span: 2 do
        f.inputs "Defect Details", class: "panel" do
          f.input :breakdown_reason_id, as: :select, 
                  collection: BreakdownReason.all.map { |r| [r.reason_name, r.id] }, 
                  include_blank: 'Select Reason (if applicable)', label: "Defect Reason",
                  input_html: { class: "select2" }
          f.input :defect_description, as: :text, 
                  input_html: { rows: 5, placeholder: "Describe the issue in detail..." }
        end
      end
      
      column span: 1 do
        f.inputs "Meter Reading", class: "panel" do
          f.input :meter_at_report, as: :number, 
                  hint: "Current hour meter reading when issue was reported",
                  input_html: { step: "0.1", placeholder: "e.g., 1250.5" }
        end
      end
    end
    
    f.actions do
      f.action :submit, as: :button, button_html: { class: "primary" }
      f.cancel_link
    end
  end

  # Enhanced Show Page
  show title: ->(wo) { "Work Order: #{wo.wo_number}" } do
    columns do
      column span: 2 do
        panel "Work Order Information", class: "info-panel" do
          attributes_table_for work_order do
            row :wo_number do
              strong work_order.wo_number
            end
            row :asset do
              link_to work_order.asset.full_description || work_order.asset.fleet_number, admin_asset_path(work_order.asset) if work_order.asset
            end
            row :wo_type do
              span work_order.wo_type.humanize, class: "status_tag #{work_order.wo_type}"
            end
            row :priority do
              priority_class = case work_order.priority
              when 'emergency' then 'danger'
              when 'high' then 'warning'
              else 'info'
              end
              span work_order.priority.upcase, class: "status_tag #{priority_class}"
            end
            row :status do
              status_class = case work_order.status
              when 'completed' then 'success'
              when 'in_progress' then 'warning'
              when 'pending_parts', 'on_hold' then 'danger'
              else 'info'
              end
              span work_order.status.humanize, class: "status_tag #{status_class}"
            end
          end
        end
        
        panel "Defect Information", class: "info-panel" do
          attributes_table_for work_order do
            row :defect_reason do
              work_order.breakdown_reason&.reason_name || "Not specified"
            end
            row :defect_description do
              simple_format work_order.defect_description if work_order.defect_description
            end
            row :meter_at_report do
              "#{work_order.meter_at_report} hours" if work_order.meter_at_report
            end
          end
        end
      end
      
      column span: 1 do
        panel "Timeline", class: "info-panel" do
          attributes_table_for work_order do
            row :reported_by do
              work_order.reported_by&.name || "Unknown"
            end
            row :reported_at do
              work_order.reported_at&.strftime("%Y-%m-%d %H:%M:%S") if work_order.reported_at
            end
            row :assigned_mechanic do
              work_order.assigned_mechanic&.name || "Not assigned"
            end
            row :started_at do
              work_order.started_at&.strftime("%Y-%m-%d %H:%M:%S") if work_order.started_at
            end
            row :completed_at do
              work_order.completed_at&.strftime("%Y-%m-%d %H:%M:%S") if work_order.completed_at
            end
            row "Total Hours" do
              if work_order.started_at && work_order.completed_at
                hours = ((work_order.completed_at - work_order.started_at) / 3600).round(1)
                "#{hours} hours"
              else
                "In progress"
              end
            end
          end
        end
        
        panel "Financials", class: "info-panel" do
          attributes_table_for work_order do
            row :total_cost do
              strong number_to_currency(work_order.total_cost) if work_order.total_cost
            end
          end
        end
      end
    end
    
    if work_order.respond_to?(:wo_parts)
      panel "Parts Used", class: "parts-panel" do
        if work_order.wo_parts.any?
          table_for work_order.wo_parts, class: "parts-table" do
            column "Part", :part do |wp|
              link_to wp.part&.part_name, admin_part_path(wp.part) if wp.part
            end
            column "Quantity", :quantity_used, class: "text-right" do |wp|
              strong wp.quantity_used
            end
            column "Unit Cost", :unit_cost, class: "text-right" do |wp|
              number_to_currency(wp.unit_cost) if wp.unit_cost
            end
            column "Total", :total_cost, class: "text-right" do |wp|
              strong number_to_currency(wp.total_cost) if wp.total_cost
            end
          end
          div class: "total-cost" do
            strong "Total: #{number_to_currency(work_order.wo_parts.sum(:total_cost))}"
          end
        else
          para "No parts recorded for this work order.", class: "empty-message"
        end
      end
    end

    if work_order.respond_to?(:wo_lubricants)
      panel "Lubricants Used", class: "lubricants-panel" do
        if work_order.wo_lubricants.any?
          table_for work_order.wo_lubricants, class: "lubricants-table" do
            column "Lubricant", :lubricant do |wl|
              wl.lubricant&.name if wl.lubricant
            end
            column "Quantity", :quantity_used, class: "text-right" do |wl|
              strong "#{wl.quantity_used} L"
            end
            column "Unit Cost", :unit_cost, class: "text-right" do |wl|
              number_to_currency(wl.unit_cost) if wl.unit_cost
            end
            column "Total", :total_cost, class: "text-right" do |wl|
              strong number_to_currency(wl.total_cost) if wl.total_cost
            end
          end
        else
          para "No lubricants recorded for this work order.", class: "empty-message"
        end
      end
    end
    # active_admin_comments
  end

  # Keep the existing actions unchanged
  member_action :complete, method: :post do
    work_order = WorkOrder.find(params[:id])
    if work_order.update(
         status: 'completed',
         completed_at: Time.current,
         meter_at_completion: params[:final_meter]
       )
      redirect_to admin_work_order_path(work_order), notice: "Work Order completed successfully"
    else
      redirect_to admin_work_order_path(work_order), alert: "Failed to complete work order"
    end
  end

  action_item :complete_wo, only: :show do
    if work_order.status != 'completed'
      link_to 'Complete Work Order', complete_admin_work_order_path(work_order), 
              method: :post, data: { confirm: 'Are you sure you want to mark this work order as completed?' },
              class: "action-item-button"
    end
  end

  collection_action :breakdown_dashboard do
    @breakdowns = WorkOrder.breakdowns.active.by_priority if WorkOrder.respond_to?(:breakdowns)
    render 'admin/work_orders/breakdown_dashboard'
  rescue ActionView::MissingTemplate
    redirect_to admin_work_orders_path, alert: "Breakdown dashboard template not found"
  end
  
  # Batch actions for efficiency
  batch_action :mark_completed do |ids|
    WorkOrder.find(ids).each do |work_order|
      work_order.update(status: 'completed', completed_at: Time.current)
    end
    redirect_to collection_path, notice: "#{ids.count} work orders marked as completed"
  end
  
  batch_action :assign_mechanic, form: {
    mechanic: -> { User.mechanic.active.map { |u| [u.name, u.id] } }
  } do |ids, inputs|
    mechanic = User.find(inputs[:mechanic])
    WorkOrder.find(ids).each do |work_order|
      work_order.update(assigned_mechanic: mechanic, status: 'assigned')
    end
    redirect_to collection_path, notice: "#{ids.count} work orders assigned to #{mechanic.name}"
  end
end
