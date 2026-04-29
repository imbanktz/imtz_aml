# app/admin/lubricant_consumptions.rb

ActiveAdmin.register LubricantConsumption do
  permit_params :transaction_date, :asset_id, :work_order_id, :job_card_number,
                :lubricant_type, :quantity, :remark, :reason, :recorded_by_id

  menu label: "Lubricant Consumptions", parent: "Fleet Management", priority: 4

  # Scopes
  scope :all, default: true
  scope :this_month do |scope|
    scope.where(transaction_date: Date.today.beginning_of_month..Date.today.end_of_month)
  end
  scope :last_month do |scope|
    scope.where(transaction_date: Date.today.last_month.beginning_of_month..Date.today.last_month.end_of_month)
  end

  # Enhanced Index Page
  index title: "Lubricant Consumption Records", download_links: [:csv, :xlsx] do
    selectable_column
    id_column
    
    column "Date", :transaction_date do |consumption|
      div class: "date-cell" do
        div class: "date-main" do
          consumption.transaction_date.strftime("%b %d, %Y")
        end
      end
    end
    
    column "Asset", :asset do |consumption|
      if consumption.asset
        div class: "asset-cell" do
          div class: "asset-icon" do
            "🚛"
          end
          div class: "asset-details" do
            strong link_to consumption.asset.fleet_number, admin_asset_path(consumption.asset), class: "asset-link"
            small consumption.asset.model&.model_name, class: "asset-model"
          end
        end
      else
        span "Deleted Asset", class: "empty-text"
      end
    end
    
    column "Job Card", :job_card_number do |consumption|
      if consumption.job_card_number.present?
        div class: "job-card-badge" do
          span "📋 #{consumption.job_card_number}"
        end
      else
        span "-", class: "empty-text"
      end
    end
    
    column "Lubricant", :lubricant_type do |consumption|
      lubricant_config = {
        'ATF' => { icon: '🛢️', class: 'atf', label: 'ATF Fluid' },
        '10W' => { icon: '🔧', class: 'oil', label: '10W Oil' },
        'ISO_68' => { icon: '⚙️', class: 'hydraulic', label: 'ISO 68' },
        'SAE_50' => { icon: '🔧', class: 'oil', label: 'SAE 50' },
        '80W90' => { icon: '🔧', class: 'gear', label: '80W90' },
        'TDH_MVP' => { icon: '💧', class: 'special', label: 'TDH MVP' },
        '15W40' => { icon: '🔧', class: 'oil', label: '15W40' },
        '10W30' => { icon: '🔧', class: 'oil', label: '10W30' },
        'FLUIDE' => { icon: '💧', class: 'special', label: 'Fluid' },
        'COOLANT' => { icon: '❄️', class: 'coolant', label: 'Coolant' },
        'GREASE' => { icon: '🧴', class: 'grease', label: 'Grease' },
        'DECREASE' => { icon: '🧼', class: 'special', label: 'Decrease' },
        '85W140' => { icon: '🔧', class: 'gear', label: '85W140' }
      }
      config = lubricant_config[consumption.lubricant_type] || { icon: '🛢️', class: 'default', label: consumption.lubricant_type }
      div class: "lubricant-badge #{config[:class]}" do
        span config[:icon]
        span config[:label]
      end
    end
    
    column "Quantity", :quantity do |consumption|
      div class: "quantity-cell" do
        strong "#{consumption.quantity} L"
      end
    end
    
    column "Reason", :reason do |consumption|
      if consumption.reason.present?
        reason_config = {
          'leakage' => { icon: '💧', class: 'danger' },
          'min level' => { icon: '⚠️', class: 'warning' },
          'PM' => { icon: '🔧', class: 'success' }
        }
        config = reason_config[consumption.reason] || { icon: '📝', class: 'info' }
        div class: "reason-badge #{config[:class]}" do
          span config[:icon]
          span consumption.reason
        end
      else
        span "-", class: "empty-text"
      end
    end
    
    column "Recorded By", :recorded_by do |consumption|
      if consumption.recorded_by
        div class: "user-cell" do
          div class: "user-avatar" do
            consumption.recorded_by.name[0].upcase
          end
          span consumption.recorded_by.name, class: "user-name"
        end
      else
        span "System", class: "system-badge"
      end
    end
    
    actions defaults: true
  end

  # Enhanced Filters
  filter :transaction_date, as: :date_range, datepicker_options: { format: 'yyyy-mm-dd' }
  filter :asset, as: :select, collection: -> { Asset.active.map { |a| [a.fleet_number, a.id] } }, 
         input_html: { class: "select2-filter" }
  filter :lubricant_type, as: :select, collection: LubricantConsumption::LUBRICANT_TYPES.map { |l| [l.humanize, l] }
  filter :job_card_number, as: :string
  filter :reason, as: :select, collection: ['leakage', 'min level', 'PM'].map { |r| [r.humanize, r] }
  filter :recorded_by, as: :select, collection: -> { User.where(user_type: ['mechanic', 'maintenance_planner']).map { |u| [u.name, u.id] } }

  # Beautiful Form
  form html: { class: "beautiful-form", multipart: true } do |f|
    f.semantic_errors *f.object.errors.attribute_names
    
    div class: "form-container" do
      div class: "form-header" do
        h1 do
          if f.object.persisted?
            "✏️ Edit Lubricant Consumption"
          else
            "🛢️ Record Lubricant Consumption"
          end
        end
        p "Track lubricant usage for fleet assets"
      end
      
      div class: "form-card" do
        div class: "card-body" do
          div class: "form-grid-2" do
            # Transaction Date
            div class: "input-group" do
              label "Transaction Date *"
              f.input :transaction_date, as: :datepicker, 
                      input_html: { class: "date-input", value: Date.today },
                      label: false
              small class: "input-hint" do
                "📅 Date when lubricant was consumed"
              end
            end
            
            # Asset
            div class: "input-group" do
              label "Asset *"
              f.input :asset, as: :select, 
                      collection: Asset.active.map { |a| ["#{a.fleet_number} - #{a.model&.model_name}", a.id] },
                      include_blank: 'Select Asset',
                      label: false,
                      input_html: { class: "asset-select" }
              small class: "input-hint" do
                "🚛 Select the asset that consumed lubricant"
              end
            end
          end
          
          div class: "form-grid-2" do
            # Work Order
            div class: "input-group" do
              label "Work Order"
              f.input :work_order, as: :select, 
                      collection: WorkOrder.where(status: ['in_progress', 'assigned']).map { |wo| [wo.wo_number, wo.id] }, 
                      include_blank: 'Not associated with work order',
                      label: false,
                      input_html: { class: "work-order-select" }
              small class: "input-hint" do
                "🔧 Associated work order (optional)"
              end
            end
            
            # Job Card Number
            div class: "input-group" do
              label "Job Card Number"
              f.input :job_card_number, 
                      input_html: { class: "text-input", placeholder: "e.g., JC-2024-001" },
                      label: false
              small class: "input-hint" do
                "📋 Job card number for tracking"
              end
            end
          end
          
          div class: "form-grid-2" do
            # Lubricant Type
            div class: "input-group" do
              label "Lubricant Type *"
              div class: "lubricant-selector" do
                f.input :lubricant_type, as: :select, 
                        collection: LubricantConsumption::LUBRICANT_TYPES.map { |l| [l, l] },
                        include_blank: 'Select Lubricant',
                        label: false,
                        input_html: { class: "lubricant-select" }
              end
              small class: "input-hint" do
                "🛢️ Type of lubricant used"
              end
            end
            
            # Quantity (Fixed validation error)
            div class: "input-group" do
              label "Quantity (Litres) *"
              div class: "quantity-input-wrapper" do
                f.input :quantity, as: :number,
                        input_html: { step: "0.1", min: "0.01", class: "quantity-input", placeholder: "0.0" },
                        label: false
                span class: "quantity-unit" do
                  "L"
                end
              end
              small class: "input-hint" do
                "🔢 Amount of lubricant consumed (must be greater than 0)"
              end
            end
          end
          
          div class: "form-grid-2" do
            # Reason
            div class: "input-group" do
              label "Reason"
              f.input :reason, as: :select,
                      collection: [
                        ['💧 Leakage', 'leakage'],
                        ['⚠️ Minimum Level', 'min level'],
                        ['🔧 Preventive Maintenance', 'PM']
                      ],
                      include_blank: 'Select reason',
                      label: false,
                      input_html: { class: "reason-select" }
              small class: "input-hint" do
                "Why was lubricant added?"
              end
            end
            
            # Recorded By
            div class: "input-group" do
              label "Recorded By *"
              f.input :recorded_by_id, as: :select,
                      collection: User.where(user_type: ['mechanic', 'maintenance_planner']).map { |u| [u.name, u.id] },
                      include_blank: 'Select person',
                      label: false,
                      input_html: { class: "user-select" }
              small class: "input-hint" do
                "👤 Who recorded this consumption"
              end
            end
          end
          
          # Remark
          div class: "input-group full-width" do
            label "Remark"
            f.input :remark,
                    input_html: { rows: 3, class: "remark-input", placeholder: "Additional notes about this lubricant consumption..." },
                    label: false
            small class: "input-hint" do
              "📝 Any additional information (e.g., Oil top up, greasing)"
            end
          end
        end
      end
      
      # Summary Card
      div class: "summary-card" do
        h3 "📊 Quick Summary"
        div class: "summary-stats" do
          div class: "stat" do
            span "Today's Total:"
            strong do
              consumption = LubricantConsumption.where(transaction_date: Date.today)
              "#{consumption.sum(:quantity)} L"
            end
          end
          div class: "stat" do
            span "This Month:"
            strong do
              consumption = LubricantConsumption.where(transaction_date: Date.today.beginning_of_month..Date.today.end_of_month)
              "#{consumption.sum(:quantity)} L"
            end
          end
          div class: "stat" do
            span "Most Used:"
            strong do
              most_used = LubricantConsumption.group(:lubricant_type).count.max_by { |k, v| v }
              most_used ? most_used[0] : "N/A"
            end
          end
        end
      end
      
      # Action Buttons
      div class: "form-actions" do
        f.actions do
          f.action :submit, as: :button,
                   label: f.object.persisted? ? "💾 Update Record" : "✨ Save Record",
                   button_html: { class: "btn-save" }
          
          f.cancel_link class: "btn-cancel"
        end
      end
    end
  end

  # Enhanced Show Page
  show title: ->(c) { "Lubricant Consumption ##{c.id}" } do |consumption|
    div class: "show-container" do
      div class: "show-header" do
        h1 "🛢️ Lubricant Consumption Details"
        p "Recorded on #{consumption.created_at.strftime('%B %d, %Y at %I:%M %p')}"
      end
      
      div class: "stats-grid" do
        div class: "stat-card" do
          div class: "stat-icon" do
            "🚛"
          end
          div class: "stat-info" do
            span class: "stat-label" do
              "Asset"
            end
            span class: "stat-value" do
              if consumption.asset
                link_to "#{consumption.asset.fleet_number} - #{consumption.asset.model&.model_name}", admin_asset_path(consumption.asset)
              else
                "Deleted"
              end
            end
          end
        end
        
        div class: "stat-card" do
          div class: "stat-icon" do
            "🛢️"
          end
          div class: "stat-info" do
            span class: "stat-label" do
              "Lubricant Type"
            end
            span class: "stat-value" do
              consumption.lubricant_type
            end
          end
        end
        
        div class: "stat-card" do
          div class: "stat-icon" do
            "🔢"
          end
          div class: "stat-info" do
            span class: "stat-label" do
              "Quantity Consumed"
            end
            span class: "stat-value large" do
              "#{consumption.quantity} L"
            end
          end
        end
        
        div class: "stat-card" do
          div class: "stat-icon" do
            "📅"
          end
          div class: "stat-info" do
            span class: "stat-label" do
              "Transaction Date"
            end
            span class: "stat-value" do
              consumption.transaction_date.strftime("%B %d, %Y")
            end
          end
        end
      end
      
      columns do
        column span: 2 do
          panel "Consumption Information", class: "details-panel" do
            attributes_table_for consumption do
              row "Transaction Date" do
                consumption.transaction_date.strftime("%B %d, %Y")
              end
              row "Asset" do
                link_to consumption.asset.fleet_number, admin_asset_path(consumption.asset) if consumption.asset
              end
              row "Work Order" do
                if consumption.work_order
                  link_to consumption.work_order.wo_number, admin_work_order_path(consumption.work_order)
                else
                  "Not associated"
                end
              end
              row "Job Card Number" do
                consumption.job_card_number || "-"
              end
              row "Lubricant Type" do
                consumption.lubricant_type
              end
              row "Quantity" do
                strong "#{consumption.quantity} Litres"
              end
              row "Reason" do
                consumption.reason || "-"
              end
              row "Remark" do
                consumption.remark || "-"
              end
            end
          end
        end
        
        column span: 1 do
          panel "Recording Information", class: "details-panel" do
            attributes_table_for consumption do
              row "Recorded By" do
                if consumption.recorded_by
                  div class: "user-info" do
                    div class: "avatar" do
                      consumption.recorded_by.name[0].upcase
                    end
                    span consumption.recorded_by.name
                  end
                end
              end
              row "Created At" do
                consumption.created_at.strftime("%B %d, %Y at %I:%M %p")
              end
              row "Last Updated" do
                consumption.updated_at.strftime("%B %d, %Y at %I:%M %p")
              end
            end
          end
        end
      end
    end
    # active_admin_comments
  end

  # Collection actions
  collection_action :monthly_summary do
    @summary = LubricantConsumption.for_month(params[:month] || Date.today)
                                   .summary_for_month(params[:month] || Date.today)
    render 'admin/lubricant_consumptions/monthly_summary'
  end

  action_item :monthly_report, only: :index do
    link_to "📊 Monthly Summary", monthly_summary_admin_lubricant_consumptions_path, class: "action-item-button"
  end

  # Excel Export
  collection_action :export_monthly, method: :get do
    @consumptions = LubricantConsumption.where(transaction_date: params[:month].to_date.all_month)
    
    respond_to do |format|
      format.xlsx do
        response.headers['Content-Disposition'] = "attachment; filename=lubricants_#{params[:month]}.xlsx"
        render xlsx: 'export_monthly', layout: false
      end
    end
  end

  action_item :export_monthly, only: :index do
    link_to "📎 Export Monthly", "#", class: "action-item-button", onclick: "$('#month-selector').toggle(); return false;"
  end

  # Batch actions
  batch_action :destroy, false
end
