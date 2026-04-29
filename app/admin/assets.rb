# app/admin/assets.rb

ActiveAdmin.register Asset do
  permit_params :fleet_number, :serial_number, :asset_model_id, :current_status, 
                :current_location_type, :current_location_id, :current_hour_meter,
                :acquisition_date, :acquisition_cost, :primary_operator_id, :active

  includes :model, :primary_operator

  # Custom menu label
  menu label: "Fleet Assets", priority: 1, parent: "Fleet Management"
  
  # Enhanced Index Page
  index title: "Fleet Assets", download_links: [:csv, :pdf] do
    selectable_column
    id_column
    column :fleet_number do |a|
      div class: "asset-fleet" do
        strong link_to a.fleet_number, admin_asset_path(a)
        small a.serial_number, class: "serial-sub"
      end
    end
    column "Asset Details", :model do |a|
      div class: "asset-details" do
        div class: "model-name" do
          a.model&.model_name || "No Model Assigned"
        end
        if a.model&.manufacturer
          small a.model.manufacturer, class: "manufacturer"
        end
      end
    end
    column "Status", :current_status do |a|
      status_class = case a.current_status
                     when 'operational' then 'success'
                     when 'maintenance' then 'warning'
                     when 'repair' then 'danger'
                     when 'standby' then 'info'
                     else 'default'
                     end
      span a.current_status.humanize, class: "status_tag #{status_class}"
    end
    column "Hours", :current_hour_meter do |a|
      strong "#{number_with_delimiter(a.current_hour_meter.to_i)} hrs"
    end
    column "Primary Operator", :primary_operator do |a|
      if a.primary_operator
        link_to a.primary_operator.name, admin_user_path(a.primary_operator)
      else
        span "Unassigned", class: "empty-text"
      end
    end
    column "Active", :active do |a|
      status_tag a.active ? "Active" : "Inactive", class: a.active ? :green : :red
    end
    column "Last 30 Days", :recent_availability do |a|
      if a.respond_to?(:recent_availability)
        progress = a.recent_availability
        div class: "availability-progress" do
          div class: "progress-bar", style: "width: #{progress}%; background: #{progress > 90 ? '#28a745' : progress > 70 ? '#ffc107' : '#dc3545'}"
          span "#{progress}%"
        end
      else
        "-"
      end
    end
    actions defaults: true do |a|
      item "Record Meter", record_hour_meter_admin_asset_path(a), class: "member_link meter-link"
    end
  end

  # Enhanced Filters
  filter :fleet_number, as: :string, label: "Fleet Number", input_html: { placeholder: "e.g., TR-001" }
  filter :serial_number, as: :string, input_html: { placeholder: "Search by VIN/Serial..." }
  filter :model, as: :select, collection: -> { AssetModel.active.map { |m| [m.model_name, m.id] } }, input_html: { class: "select2" }
  filter :current_status, as: :select, collection: Asset.current_statuses.keys.map { |s| [s.humanize, s] }, input_html: { class: "select2" }
  filter :primary_operator, as: :select, collection: -> { User.operator.active.map { |u| [u.name, u.id] } }
  filter :active, as: :select, collection: [['Active', true], ['Inactive', false]]
  filter :acquisition_date, as: :date_range
  # filter :current_hour_meter, as: :numeric_range

  # Enhanced Form
  # app/admin/assets.rb - Enhanced Form Section

  form html: { class: "asset-form", multipart: true, autocomplete: "off" } do |f|
    f.semantic_errors *f.object.errors.attribute_names
    
    # Custom styling wrapper
    div class: "form-wrapper" do
      # Header with asset info
      div class: "form-header" do
        h2 class: "form-title" do
          if f.object.persisted?
            "Edit Asset: #{f.object.fleet_number}"
          else
            "Register New Asset"
          end
        end
        p class: "form-subtitle" do
          "Complete the form below to #{f.object.persisted? ? 'update' : 'register'} fleet asset information"
        end
      end
      
      # Enhanced tabs with icons
      f.tabs do
        f.tab "📋 Basic Information" do
          div class: "tab-content-inner" do
            columns do
              column span: 2 do
                div class: "input-group modern-input" do
                  f.input :fleet_number, 
                          input_html: { placeholder: "e.g., TR-001, F201", class: "large-input" }, 
                          hint: "Unique fleet identification number",
                          wrapper_html: { class: "fancy-input" }
                end
                
                div class: "input-group modern-input" do
                  f.input :serial_number, 
                          input_html: { placeholder: "VIN or Serial Number" }, 
                          hint: "Manufacturer's serial number",
                          wrapper_html: { class: "fancy-input" }
                end
                
                div class: "input-group modern-input" do
                  f.input :asset_model_id, as: :select, 
                          collection: AssetModel.active.map { |m| ["#{m.manufacturer} #{m.model_name}", m.id] }, 
                          include_blank: 'Select Model', label: "Model",
                          input_html: { class: "select2 fancy-select" },
                          hint: "Select asset model from catalog"
                end
              end
              
              column span: 1 do
                div class: "info-card" do
                  h3 "Quick Tips"
                  ul class: "tips-list" do
                    li "• Fleet number should be unique"
                    li "• Keep serial number accurate for warranty"
                    li "• Model determines maintenance schedule"
                  end
                end
              end
            end
          end
        end
        
        f.tab "📍 Status & Location" do
          div class: "tab-content-inner" do
            columns do
              column span: 1 do
                div class: "status-card" do
                  h3 "Current Status"
                  div class: "input-group modern-input" do
                    f.input :current_status, as: :select, 
                            collection: Asset.current_statuses.keys.map { |s| [s.humanize, s] },
                            input_html: { class: "select2", id: "asset-status-select" },
                            hint: "Current operational status"
                  end
                  
                  div class: "status-indicator" do
                    span "Status Preview: ", class: "preview-label"
                    span id: "status-preview", class: "status-badge" do
                      f.object.current_status&.humanize || "Not Set"
                    end
                  end
                end
                
                div class: "input-group modern-input" do
                  f.input :current_hour_meter, as: :number, 
                          input_html: { step: "0.1", placeholder: "0.0", class: "meter-input" }, 
                          hint: "Current hour meter reading",
                          wrapper_html: { class: "fancy-input" }
                end
              end
              
              column span: 1 do
                div class: "location-card" do
                  h3 "Location Details"
                  div class: "input-group modern-input" do
                    f.input :current_location_type, as: :select, 
                            collection: Asset.current_location_types.keys.map { |l| [l.humanize, l] },
                            input_html: { class: "select2" }, 
                            hint: "Type of location"
                  end
                  
                  div class: "input-group modern-input" do
                    f.input :current_location_id, 
                            input_html: { placeholder: "Enter location ID", class: "location-id-input" }, 
                            hint: "Workshop ID or Farm Location ID"
                  end
                end
              end
            end
          end
        end
        
        f.tab "👤 Assignment" do
          div class: "tab-content-inner" do
            columns do
              column span: 2 do
                div class: "assignment-card" do
                  h3 "Operator Assignment"
                  div class: "input-group modern-input" do
                    f.input :primary_operator, as: :select, 
                            collection: User.operator.active.map { |u| ["#{u.name} (#{u.employee_id})", u.id] }, 
                            include_blank: 'Unassigned', label: "Primary Operator",
                            input_html: { class: "select2" }, 
                            hint: "Main operator assigned to this asset"
                  end
                  
                  div class: "operator-info" do
                    p class: "info-text" do
                      "💡 Tip: Assigning an operator helps track asset usage and responsibility"
                    end
                  end
                end
              end
              
              column span: 1 do
                div class: "assignment-stats" do
                  h3 "Current Assignments"
                  div class: "stat-item" do
                    span class: "stat-label" do
                      "Active Work Orders"
                    end
                    span class: "stat-value" do
                      f.object.work_orders&.where(status: ['assigned', 'in_progress'])&.count || 0
                    end
                  end
                  div class: "stat-item" do
                    span class: "stat-label" do
                      "Open Issues"
                    end
                    span class: "stat-value" do
                      f.object.work_orders&.where(status: ['reported', 'pending_parts'])&.count || 0
                    end
                  end
                end
              end
            end
          end
        end
        
        f.tab "💰 Financial" do
          div class: "tab-content-inner" do
            columns do
              column span: 1 do
                div class: "financial-card" do
                  h3 "Acquisition Details"
                  div class: "input-group modern-input" do
                    f.input :acquisition_date, as: :datepicker, 
                            input_html: { class: "datepicker date-input" }, 
                            hint: "Date asset was acquired"
                  end
                  
                  div class: "input-group modern-input" do
                    f.input :acquisition_cost, as: :number, 
                            input_html: { step: "0.01", placeholder: "0.00", class: "cost-input" }, 
                            hint: "Purchase or acquisition cost"
                  end
                end
              end
              
              column span: 1 do
                div class: "value-card" do
                  h3 "Estimated Values"
                  div class: "value-item" do
                    span class: "value-label" do
                      "Current Value"
                    end
                    span class: "value-amount", id: "current-value" do
                      if f.object.acquisition_cost && f.object.current_hour_meter
                        depreciation = (f.object.current_hour_meter / 10000.0) * f.object.acquisition_cost
                        remaining = f.object.acquisition_cost - depreciation
                        number_to_currency(remaining > 0 ? remaining : 0)
                      else
                        "N/A"
                      end
                    end
                  end
                  div class: "value-item" do
                    span class: "value-label" do
                      "Depreciation"
                    end
                    span class: "value-amount" do
                      "20% / year"
                    end
                  end
                end
              end
            end
            
            div class: "active-toggle" do
              f.input :active, as: :boolean, 
                      label: "✅ Asset Active", 
                      hint: "Inactive assets won't appear in work orders",
                      wrapper_html: { class: "toggle-switch" }
            end
          end
        end
      end
      
      # Enhanced action buttons
      div class: "form-actions-modern" do
        f.actions do
          f.action :submit, as: :button, 
                   label: f.object.persisted? ? "Update Asset" : "Create Asset",
                   button_html: { class: "primary-button" }
          
          f.cancel_link class: "cancel-button"
          
          if f.object.persisted?
            link_to "Delete Asset", admin_asset_path(f.object), 
                    method: :delete,
                    class: "delete-button",
                    data: { confirm: "Are you sure you want to delete this asset?" }
          end
        end
      end
    end
  end
  # form html: { class: "asset-form", multipart: true } do |f|
  #   f.semantic_errors *f.object.errors.attribute_names
  
  #   # Tabs for better organization
  #   f.tabs do
  #     f.tab "Basic Information" do
  #       columns do
  #         column span: 2 do
  #           div class: "info-section" do
  #             f.input :fleet_number, input_html: { placeholder: "e.g., TR-001", class: "large-input" }, 
  #                     hint: "Unique fleet identification number"
  #             f.input :serial_number, input_html: { placeholder: "VIN or Serial Number" }, 
  #                     hint: "Manufacturer's serial number"
  #             f.input :asset_model_id, as: :select, 
  #                     collection: AssetModel.active.map { |m| ["#{m.manufacturer} #{m.model_name}", m.id] }, 
  #                     include_blank: 'Select Model', label: "Model",
  #                     input_html: { class: "select2" }
  #           end
  #         end
  #         column span: 1 do
  #           div class: "info-section" do
  #             f.input :acquisition_date, as: :datepicker, 
  #                     input_html: { class: "datepicker" }, hint: "Date asset was acquired"
  #             f.input :acquisition_cost, as: :number, 
  #                     input_html: { step: "0.01", placeholder: "0.00" }, 
  #                     hint: "Purchase or acquisition cost"
  #             f.input :active, as: :boolean, label: "Asset Active", 
  #                     hint: "Inactive assets won't appear in work orders"
  #           end
  #         end
  #       end
  #     end
  
  #     f.tab "Status & Location" do
  #       columns do
  #         column span: 1 do
  #           div class: "info-section" do
  #             f.input :current_status, as: :select, 
  #                     collection: Asset.current_statuses.keys.map { |s| [s.humanize, s] },
  #                     input_html: { class: "select2" }, hint: "Current operational status"
  
  #             f.input :current_hour_meter, as: :number, 
  #                     input_html: { step: "0.1", placeholder: "0.0" }, 
  #                     hint: "Current hour meter reading"
  #           end
  #         end
  #         column span: 1 do
  #           div class: "info-section" do
  #             f.input :current_location_type, as: :select, 
  #                     collection: Asset.current_location_types.keys.map { |l| [l.humanize, l] },
  #                     input_html: { class: "select2" }, hint: "Type of location"
  
  #             f.input :current_location_id, input_html: { placeholder: "Location ID" }, 
  #                     hint: "Workshop ID or Farm Location ID"
  #           end
  #         end
  #       end
  #     end
  
  #     f.tab "Assignment" do
  #       div class: "info-section" do
  #         f.input :primary_operator, as: :select, 
  #                 collection: User.operator.active.map { |u| ["#{u.name} (#{u.employee_id})", u.id] }, 
  #                 include_blank: 'Unassigned', label: "Primary Operator",
  #                 input_html: { class: "select2" }, hint: "Main operator assigned to this asset"
  #       end
  #     end
  #   end
  
  #   f.actions do
  #     f.action :submit, as: :button, button_html: { class: "primary" }
  #     f.cancel_link
  #     if f.object.persisted?
  #       link_to "Record Hour Meter", record_hour_meter_admin_asset_path(f.object), 
  #               class: "button", style: "margin-left: 10px"
  #     end
  #   end
  # end

  # Enhanced Show Page
  show title: ->(asset) { "#{asset.fleet_number} - #{asset.model&.model_name}" } do
    # Hero section with key metrics
    div class: "asset-hero" do
      columns do
        column span: 1 do
          panel "Asset Information", class: "info-panel" do
            attributes_table_for asset do
              row :fleet_number do
                strong asset.fleet_number
              end
              row :serial_number do
                code asset.serial_number
              end
              row :model do
                if asset.model
                  link_to "#{asset.model.manufacturer} #{asset.model.model_name}", admin_asset_model_path(asset.model)
                else
                  "Not assigned"
                end
              end
            end
          end
        end
        
        column span: 1 do
          panel "Status Metrics", class: "metrics-panel" do
            div class: "metrics-grid" do
              div class: "metric-card" do
                h3 "Current Hours"
                p class: "metric-value large" do
                  "#{number_with_delimiter(asset.current_hour_meter.to_i)} hrs"
                end
                small "Total operating hours"
              end
              
              div class: "metric-card" do
                h3 "Status"
                p class: "metric-value" do
                  status_class = case asset.current_status
                                 when 'operational' then 'success'
                                 when 'maintenance' then 'warning'
                                 when 'repair' then 'danger'
                                 else 'info'
                                 end
                  span asset.current_status.humanize, class: "status_tag #{status_class} large"
                end
              end
              
              div class: "metric-card" do
                h3 "Availability"
                p class: "metric-value" do
                  if asset.respond_to?(:availability_30_days)
                    "#{asset.availability_30_days}%"
                  else
                    "N/A"
                  end
                end
                small "Last 30 days"
              end
            end
          end
        end
      end
    end
    
    # Two column layout for details
    columns do
      column span: 1 do
        panel "Operational Details", class: "details-panel" do
          attributes_table_for asset do
            row "Primary Operator" do
              if asset.primary_operator
                link_to asset.primary_operator.full_name, admin_user_path(asset.primary_operator)
              else
                span "Not assigned", class: "empty-text"
              end
            end
            row :current_location_type do
              asset.current_location_type&.humanize || "Not specified"
            end
            row :current_location_id do
              asset.current_location_id || "-"
            end
          end
        end
        
        panel "Financial Information", class: "financial-panel" do
          attributes_table_for asset do
            row :acquisition_date do
              asset.acquisition_date&.strftime("%B %d, %Y") || "Not recorded"
            end
            row :acquisition_cost do
              if asset.acquisition_cost
                strong number_to_currency(asset.acquisition_cost)
              else
                "Not recorded"
              end
            end
            row "Current Value" do
              if asset.acquisition_cost && asset.current_hour_meter
                depreciation = (asset.current_hour_meter / 10000.0) * asset.acquisition_cost
                remaining = asset.acquisition_cost - depreciation
                number_to_currency(remaining > 0 ? remaining : 0)
              else
                "N/A"
              end
            end
          end
        end
      end
      
      column span: 1 do
        panel "Maintenance Schedule", class: "maintenance-panel" do
          if asset.respond_to?(:next_maintenance_due)
            attributes_table_for asset do
              row "Next Service Due" do
                next_due = asset.next_maintenance_due
                if next_due
                  due_in = next_due - asset.current_hour_meter
                  if due_in > 0
                    span "#{due_in.to_i} hours", class: "due-future"
                  else
                    span "Overdue by #{-due_in.to_i} hours", class: "due-overdue"
                  end
                else
                  "Not scheduled"
                end
              end
            end
          else
            para "Maintenance schedule not configured", class: "empty-message"
          end
        end
        
        panel "Recent Meter Readings", class: "readings-panel" do
          if asset.hour_meter_readings.any?
            table_for asset.hour_meter_readings.order(reading_date: :desc).limit(5) do
              column "Reading" do |r|
                "#{number_with_delimiter(r.reading_value.to_i)} hrs"
              end
              column "Date" do |r|
                r.reading_date&.strftime("%Y-%m-%d")
              end
              column "Recorded By" do |r|
                r.recorded_by&.name
              end
            end
            div class: "view-all" do
              link_to "View All Readings", admin_hour_meter_readings_path(q: { asset_id_eq: asset.id })
            end
          else
            para "No meter readings recorded", class: "empty-message"
          end
        end
      end
    end
    
    # Work Orders Section
    if asset.work_orders.any?
      panel "Recent Work Orders", class: "work-orders-panel" do
        table_for asset.work_orders.order(created_at: :desc).limit(10) do
          column :wo_number do |wo|
            link_to wo.wo_number, admin_work_order_path(wo)
          end
          column "Type", :wo_type do |wo|
            span wo.wo_type.humanize, class: "status_tag #{wo.wo_type}"
          end
          column "Priority", :priority do |wo|
            priority_class = case wo.priority
                             when 'emergency' then 'danger'
                             when 'high' then 'warning'
                             when 'medium' then 'info'
                             else 'default'
                             end
            span wo.priority.upcase, class: "status_tag #{priority_class}"
          end
          column "Status", :status do |wo|
            status_class = case wo.status
                           when 'completed' then 'success'
                           when 'in_progress' then 'warning'
                           when 'pending_parts' then 'danger'
                           else 'info'
                           end
            span wo.status.humanize, class: "status_tag #{status_class}"
          end
          column "Reported" do |wo|
            wo.reported_at&.strftime("%Y-%m-%d")
          end
        end
        
        if asset.work_orders.count > 10
          div class: "view-all" do
            link_to "View All Work Orders (#{asset.work_orders.count})", admin_work_orders_path(q: { asset_id_eq: asset.id })
          end
        end
      end
    end
    
    # Availability History Chart (if you have the data)
    if asset.monthly_availabilities.any?
      panel "Availability Trend", class: "availability-panel" do
        div class: "chart-container" do
          table_for asset.monthly_availabilities.order(month: :desc).limit(6) do
            column "Month", :month do |m|
              m.month.strftime("%B %Y")
            end
            column "Availability", :availability_percentage do |m|
              if m.respond_to?(:availability_percentage)
                progress = m.availability_percentage
                div class: "availability-progress" do
                  div class: "progress-bar", style: "width: #{progress}%"
                  span "#{progress}%"
                end
              else
                "-"
              end
            end
            column "Downtime", :downtime_hours
            column "Breakdowns", :breakdown_hours
            column "PM Hours", :pm_hours
          end
        end
      end
    end
    
    active_admin_comments
  end

  # Custom actions
  action_item :record_meter, only: :show do
    link_to 'Record Hour Meter', record_hour_meter_admin_asset_path(asset), 
            class: "action-item-button", 
            data: { modal: true }
  end

  member_action :record_hour_meter, method: :get do
    @asset = resource
    render partial: 'record_hour_meter_modal', layout: false
  end

  member_action :save_hour_meter, method: :post do
    @asset = resource
    if @asset.update(current_hour_meter: params[:reading_value])
      if defined?(HourMeterReading)
        @asset.hour_meter_readings.create(
          reading_value: params[:reading_value],
          reading_date: Time.current,
          recorded_by: current_user,
          notes: params[:notes]
        )
      end
      redirect_to admin_asset_path(@asset), notice: "Hour meter reading recorded successfully"
    else
      redirect_to admin_asset_path(@asset), alert: "Failed to record hour meter reading"
    end
  end

  # Batch actions
  batch_action :change_status, form: {
                 status: Asset.current_statuses.keys.map { |s| [s.humanize, s] }
               } do |ids, inputs|
    Asset.find(ids).each { |asset| asset.update(current_status: inputs[:status]) }
    redirect_to collection_path, notice: "#{ids.count} assets updated"
  end

  batch_action :assign_operator, form: {
                 operator: -> { User.operator.active.map { |u| [u.name, u.id] } }
               } do |ids, inputs|
    Asset.find(ids).each { |asset| asset.update(primary_operator_id: inputs[:operator]) }
    redirect_to collection_path, notice: "#{ids.count} assets assigned"
  end
  
  # Collection actions for exports
  collection_action :export_maintenance_schedule, method: :get do
    assets = Asset.active.includes(:model, :primary_operator)
    send_data generate_maintenance_csv(assets), filename: "maintenance-schedule-#{Date.current}.csv"
  end
  
  action_item :export_schedule, only: :index do
    link_to "Export Maintenance Schedule", export_maintenance_schedule_admin_assets_path
  end
end

# Move helper methods outside the ActiveAdmin.register block
def generate_maintenance_csv(assets)
  CSV.generate(headers: true) do |csv|
    csv << ["Fleet Number", "Model", "Current Hours", "Next Service Due", "Status", "Operator"]
    assets.each do |asset|
      csv << [
        asset.fleet_number,
        asset.model&.model_name,
        asset.current_hour_meter,
        asset.respond_to?(:next_maintenance_due) ? asset.next_maintenance_due : "N/A",
        asset.current_status,
        asset.primary_operator&.name
      ]
    end
  end
end
