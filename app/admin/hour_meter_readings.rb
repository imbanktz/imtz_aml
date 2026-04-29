# app/admin/hour_meter_readings.rb

ActiveAdmin.register HourMeterReading do
  permit_params :asset_id, :reading_date, :hour_meter, :recorded_by_id, :verified, :notes, :reading_type

  menu label: "Hour Meter Readings", parent: "Fleet Management", priority: 3
  
  actions :all, except: [:edit]
  
  # Scopes as colorful badges
  scope :all, default: true
  scope :verified, group: :status
  scope :unverified, group: :status
  # scope :last_30_days, group: :time
  # scope :current_month, group: :time

  # Enhanced Index Page
  index title: "Hour Meter Readings", download_links: [:csv, :pdf] do
    selectable_column
    id_column
    
    column "Asset", :asset do |reading|
      if reading.asset
        div class: "asset-cell" do
          div class: "asset-icon" do
            "🚛"
          end
          div class: "asset-details" do
            strong link_to reading.asset.fleet_number, admin_asset_path(reading.asset), class: "asset-link"
            small reading.asset.model&.model_name, class: "asset-model"
          end
        end
      else
        span "Deleted Asset", class: "empty-text"
      end
    end
    
    column "Meter Reading", :hour_meter do |reading|
      div class: "meter-cell" do
        div class: "meter-value" do
          strong "#{number_with_delimiter(reading.hour_meter.to_i)}"
          span "hours", class: "meter-unit"
        end
        if reading.previous_reading
          diff = reading.hour_meter - reading.previous_reading.hour_meter
          span class: "diff-badge #{diff > 0 ? 'positive' : 'negative'}" do
            "#{diff > 0 ? '▲' : '▼'} #{diff.abs.to_i} hrs"
          end
        end
      end
    end
    
    column "Recorded", :reading_date do |reading|
      div class: "date-cell" do
        div class: "date-main" do
          reading.reading_date.strftime("%b %d, %Y")
        end
        div class: "date-time" do
          reading.reading_date.strftime("%I:%M %p")
        end
      end
    end
    
    column "Type", :reading_type do |reading|
      type_config = {
        'regular' => { icon: '📊', class: 'regular', text: 'Regular' },
        'maintenance' => { icon: '🔧', class: 'maintenance', text: 'Maintenance' },
        'repair' => { icon: '⚡', class: 'repair', text: 'Repair' },
        'inspection' => { icon: '🔍', class: 'inspection', text: 'Inspection' }
      }
      config = type_config[reading.reading_type] || type_config['regular']
      div class: "type-badge #{config[:class]}" do
        span config[:icon]
        span config[:text]
      end
    end
    
    column "Recorded By", :recorded_by do |reading|
      if reading.recorded_by
        div class: "user-cell" do
          div class: "user-avatar" do
            reading.recorded_by.name[0].upcase
          end
          span reading.recorded_by.name, class: "user-name"
        end
      else
        span "System", class: "system-badge"
      end
    end
    
    column "Status", :verified do |reading|
      if reading.verified
        div class: "status-badge verified" do
          span "✓"
          span "Verified"
        end
      else
        div class: "status-badge pending" do
          span "⏳"
          span "Pending"
        end
      end
    end
    
    actions defaults: true do |reading|
      unless reading.verified
        item "Verify", verify_admin_hour_meter_reading_path(reading), 
             class: "member_link verify-action",
             data: { confirm: "Verify this reading?" }
      end
    end
  end

  # Enhanced Filters
  filter :asset, as: :select, collection: -> { Asset.active.map { |a| [a.fleet_number, a.id] } }, 
         input_html: { class: "select2-filter" }
  filter :hour_meter, as: :numeric, label: "Hour Meter"
  filter :reading_date, as: :date_range, datepicker_options: { format: 'yyyy-mm-dd' }
  filter :recorded_by, as: :select, collection: -> { User.active.map { |u| [u.name, u.id] } }
  filter :reading_type, as: :select, collection: ['regular', 'maintenance', 'repair', 'inspection'].map { |t| [t.humanize, t] }
  filter :verified, as: :select, collection: [['Verified', true], ['Unverified', false]]
  filter :created_at, as: :date_range

  # Beautiful Form
  form html: { class: "beautiful-form", multipart: true } do |f|
    f.semantic_errors *f.object.errors.attribute_names
    
    div class: "form-container" do
      div class: "form-header" do
        h1 do
          if f.object.persisted?
            "✏️ Edit Hour Meter Reading"
          else
            "📝 New Hour Meter Reading"
          end
        end
        p "Record accurate hour meter readings for maintenance tracking"
      end
      
      div class: "form-card" do
        div class: "card-body" do
          div class: "form-grid-2" do
            # Asset Selection
            div class: "input-group" do
              label "Asset *"
              div class: "asset-selector" do
                f.input :asset_id, as: :select,
                        collection: Asset.active.order(:fleet_number).map { |a| ["#{a.fleet_number} - #{a.model&.model_name}", a.id] },
                        include_blank: 'Select Asset',
                        label: false,
                        input_html: { class: "asset-select", id: "asset-select", required: true }
              end
              small class: "input-hint" do
                "Select the asset to record reading for"
              end
            end
            
            # Reading Type
            div class: "input-group" do
              label "Reading Type"
              div class: "type-selector" do
                f.input :reading_type, as: :select,
                        collection: [
                          ['📊 Regular', 'regular'],
                          ['🔧 Maintenance', 'maintenance'],
                          ['⚡ Repair', 'repair'],
                          ['🔍 Inspection', 'inspection']
                        ],
                        include_blank: 'Select Type',
                        label: false,
                        input_html: { class: "type-select" }
              end
              small class: "input-hint" do
                "Type of meter reading being recorded"
              end
            end
          end
          
          div class: "form-grid-2" do
            # Hour Meter
            div class: "input-group meter-input-group" do
              label "Hour Meter Reading *"
              div class: "meter-input-wrapper" do
                f.input :hour_meter, as: :number,
                        input_html: { step: "0.1", class: "meter-input", id: "hour-meter-input", placeholder: "0.0" },
                        label: false
                span class: "meter-unit-label" do
                  "hours"
                end
              end
              small class: "input-hint" do
                "Current hour meter reading"
              end
            end
            
            # Reading Date
            div class: "input-group" do
              label "Reading Date & Time *"
              f.input :reading_date, as: :datetime_picker,
                      input_html: { class: "datetime-input", value: Time.current.strftime("%Y-%m-%d %H:%M") },
                      label: false
              small class: "input-hint" do
                "Date and time when reading was taken"
              end
            end
          end
          
          # Notes
          div class: "input-group full-width" do
            label "Notes"
            f.input :notes, as: :text,
                    input_html: { rows: 3, class: "notes-input", placeholder: "Add any relevant notes about this reading..." },
                    label: false
            small class: "input-hint" do
              "Additional information about the reading (optional)"
            end
          end
          
          # Verification
          div class: "verification-checkbox" do
            f.input :verified, as: :boolean,
                    label: "Mark as Verified",
                    wrapper_html: { class: "checkbox-wrapper" }
            small class: "input-hint" do
              "Check if this reading has been verified"
            end
          end
        end
      end
      
      # Live Preview Card
      div class: "preview-card", id: "reading-preview" do
        h3 "📊 Reading Preview"
        div class: "preview-content" do
          div class: "preview-item" do
            span "Asset:"
            strong id: "preview-asset" do
              "Not selected"
            end
          end
          div class: "preview-item" do
            span "Reading:"
            strong id: "preview-reading" do
              "0 hours"
            end
          end
          div class: "preview-item" do
            span "Type:"
            strong id: "preview-type" do
              "Regular"
            end
          end
        end
      end
      
      # Action Buttons
      div class: "form-actions" do
        f.actions do
          f.action :submit, as: :button,
                   label: f.object.persisted? ? "💾 Update Reading" : "✨ Save Reading",
                   button_html: { class: "btn-save" }
          
          f.cancel_link class: "btn-cancel"
        end
      end
    end
  end

  # Beautiful Show Page
  # app/admin/hour_meter_readings.rb - Fixed show section

  # Beautiful Show Page - Fixed
  show title: ->(h) { "Reading ##{h.id}" } do |reading|
    div class: "show-container" do
      div class: "show-header" do
        h1 "📊 Hour Meter Reading Details"
        p "Recorded on #{reading.created_at.strftime('%B %d, %Y at %I:%M %p')}"
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
              if reading.asset
                link_to reading.asset.fleet_number, admin_asset_path(reading.asset)
              else
                "Deleted"
              end
            end
          end
        end
        
        div class: "stat-card" do
          div class: "stat-icon" do
            "⏱️"
          end
          div class: "stat-info" do
            span class: "stat-label" do
              "Meter Reading"
            end
            span class: "stat-value large" do
              "#{number_with_delimiter(reading.hour_meter.to_i)} hrs"
            end
          end
        end
        
        div class: "stat-card" do
          div class: "stat-icon" do
            "📅"
          end
          div class: "stat-info" do
            span class: "stat-label" do
              "Reading Date"
            end
            span class: "stat-value" do
              reading.reading_date.strftime("%B %d, %Y")
            end
            small reading.reading_date.strftime("%I:%M %p")
          end
        end
        
        div class: "stat-card" do
          div class: "stat-icon" do
            reading.verified ? "✓" : "⏳"
          end
          div class: "stat-info" do
            span class: "stat-label" do
              "Status"
            end
            span class: "status-badge #{reading.verified ? 'verified' : 'pending'}" do
              reading.verified ? "Verified" : "Pending Verification"
            end
          end
        end
      end
      
      columns do
        column span: 2 do
          panel "Reading Information", class: "details-panel" do
            attributes_table_for reading do
              row "Asset" do
                if reading.asset
                  link_to "#{reading.asset.fleet_number} - #{reading.asset.model&.model_name}", admin_asset_path(reading.asset)
                else
                  "Deleted Asset"
                end
              end
              row "Hour Meter" do
                strong "#{number_with_delimiter(reading.hour_meter.to_i)} hours"
              end
              row "Reading Type" do
                type_config = {
                  'regular' => { icon: '📊', text: 'Regular Reading' },
                  'maintenance' => { icon: '🔧', text: 'Maintenance Reading' },
                  'repair' => { icon: '⚡', text: 'Repair Reading' },
                  'inspection' => { icon: '🔍', text: 'Inspection Reading' }
                }
                config = type_config[reading.reading_type] || type_config['regular']
                span "#{config[:icon]} #{config[:text]}"
              end
              row "Reading Date" do
                reading.reading_date.strftime("%B %d, %Y at %I:%M %p")
              end
              row "Notes" do
                simple_format(reading.notes) if reading.notes.present?
              end
            end
          end
        end
        
        column span: 1 do
          panel "Recording Information", class: "details-panel" do
            attributes_table_for reading do
              row "Recorded By" do
                if reading.recorded_by
                  div class: "user-info" do
                    div class: "avatar" do
                      reading.recorded_by.name[0].upcase
                    end
                    span reading.recorded_by.name
                  end
                else
                  "System"
                end
              end
              row "Recorded At" do
                reading.created_at.strftime("%B %d, %Y at %I:%M %p")
              end
              row "Last Updated" do
                reading.updated_at.strftime("%B %d, %Y at %I:%M %p")
              end
            end
          end
          
          if reading.respond_to?(:previous_reading) && reading.previous_reading
            panel "Comparison with Previous Reading", class: "comparison-panel" do
              div class: "comparison-card" do
                div class: "comparison-row" do
                  span "Previous Reading:"
                  strong "#{number_with_delimiter(reading.previous_reading.hour_meter.to_i)} hrs"
                  small reading.previous_reading.reading_date.strftime("%b %d")
                end
                div class: "comparison-row" do
                  span "Difference:"
                  diff = reading.hour_meter - reading.previous_reading.hour_meter
                  span class: "diff-value #{diff > 0 ? 'positive' : 'negative'}" do
                    "#{diff > 0 ? '+' : ''}#{diff.to_i} hours"
                  end
                end
                if reading.respond_to?(:daily_average) && reading.daily_average
                  div class: "comparison-row" do
                    span "Daily Average:"
                    strong "#{reading.daily_average} hrs/day"
                  end
                end
              end
            end
          end
        end
      end
    end
    # active_admin_comments
  end

  # Custom actions (keep from previous version)
  member_action :verify, method: :post do
    reading = HourMeterReading.find(params[:id])
    if reading.update(verified: true)
      redirect_to admin_hour_meter_reading_path(reading), notice: "✓ Reading verified successfully"
    else
      redirect_to admin_hour_meter_reading_path(reading), alert: "Failed to verify reading"
    end
  end
  
  member_action :revert_verification, method: :post do
    reading = HourMeterReading.find(params[:id])
    if reading.update(verified: false)
      redirect_to admin_hour_meter_reading_path(reading), notice: "Verification reverted"
    else
      redirect_to admin_hour_meter_reading_path(reading), alert: "Failed to revert verification"
    end
  end

  action_item :verify, only: :show do
    unless hour_meter_reading.verified
      link_to "✓ Verify Reading", verify_admin_hour_meter_reading_path(hour_meter_reading), 
              method: :post, class: "verify-action-item",
              data: { confirm: "Verify this hour meter reading?" }
    end
  end
  
  action_item :revert_verification, only: :show do
    if hour_meter_reading.verified
      link_to "↺ Revert Verification", revert_verification_admin_hour_meter_reading_path(hour_meter_reading), 
              method: :post, class: "revert-action-item",
              data: { confirm: "Revert verification of this reading?" }
    end
  end

  batch_action :verify do |ids|
    HourMeterReading.find(ids).each { |reading| reading.update(verified: true) }
    redirect_to collection_path, notice: "✓ #{ids.count} readings verified"
  end
  
  batch_action :mark_as_regular do |ids|
    HourMeterReading.find(ids).each { |reading| reading.update(reading_type: 'regular') }
    redirect_to collection_path, notice: "#{ids.count} readings marked as regular"
  end

  csv do
    column :id
    column(:asset) { |reading| reading.asset&.fleet_number }
    column :hour_meter
    column :reading_date
    column(:recorded_by) { |reading| reading.recorded_by&.name }
    column :reading_type
    column :verified
    column :notes
    column :created_at
  end

  before_create do |reading|
    reading.recorded_by = current_user
    reading.reading_date ||= Time.current
  end
end
