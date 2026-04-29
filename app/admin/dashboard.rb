ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: "Fleet Dashboard", parent: "Fleet Management"
  
  content title: "Fleet Maintenance Dashboard" do
    div class: "modern-dashboard" do
      
      # Welcome Section
      div class: "welcome-section" do
        div class: "welcome-content" do
          h1 "Welcome back, #{current_user.name}!"
          p "Here's what's happening with your fleet today"
        end
        div class: "welcome-stats" do
          div class: "stat-chip" do
            span class: "chip-icon" do
              "📅"
            end
            span Date.today.strftime("%A, %B %d, %Y")
          end
        end
      end
      
      # KPI Cards
      div class: "kpi-grid" do
        # Total Assets
        div class: "kpi-card" do
          div class: "kpi-icon blue" do
            "🚛"
          end
          div class: "kpi-info" do
            span class: "kpi-label" do
              "Total Assets"
            end
            span class: "kpi-value" do
              Asset.active.count
            end
            span class: "kpi-trend positive" do
              "↑ +12% this month"
            end
          end
        end
        
        # Active Work Orders
        div class: "kpi-card" do
          div class: "kpi-icon orange" do
            "🔧"
          end
          div class: "kpi-info" do
            span class: "kpi-label" do
              "Active Work Orders"
            end
            span class: "kpi-value" do
              WorkOrder.active.count
            end
            span class: "kpi-trend warning" do
              "⚠️ #{WorkOrder.where(status: 'emergency').count} emergency"
            end
          end
        end
        
        # Assets in Maintenance
        div class: "kpi-card" do
          div class: "kpi-icon red" do
            "⚠️"
          end
          div class: "kpi-info" do
            span class: "kpi-label" do
              "Assets in Maintenance"
            end
            span class: "kpi-value" do
              Asset.where(current_status: ['maintenance', 'repair']).count
            end
            span class: "kpi-trend negative" do
              "↓ -5% from last week"
            end
          end
        end
        
        # Monthly Consumption
        div class: "kpi-card" do
          div class: "kpi-icon green" do
            "🛢️"
          end
          div class: "kpi-info" do
            span class: "kpi-label" do
              "Lubricant Used (MTD)"
            end
            span class: "kpi-value" do
              consumption = LubricantConsumption.where(transaction_date: Date.today.beginning_of_month..Date.today.end_of_month).sum(:quantity)
              "#{consumption.round(1)} L"
            end
            span class: "kpi-trend" do
              "Last 30 days"
            end
          end
        end
      end
      
      # Charts Row
      div class: "charts-row" do
        # Work Orders Chart
        div class: "chart-card" do
          h3 "Work Orders Overview"
          div class: "chart-container" do
            # Status distribution
            div class: "status-distribution" do
              statuses = WorkOrder.group(:status).count
              total = statuses.values.sum
              
              statuses.each do |status, count|
                percentage = (count.to_f / total * 100).round(1)
                div class: "status-item" do
                  span class: "status-label" do
                    span class: "status-dot #{status}"
                    status.humanize
                  end
                  div class: "status-bar-container" do
                    div class: "status-bar", style: "width: #{percentage}%"
                  end
                  span class: "status-count" do
                    "#{count} (#{percentage}%)"
                  end
                end
              end
            end
          end
        end
        
        # Lubricant Usage Chart
        div class: "chart-card" do
          h3 "Top Lubricants Used"
          div class: "chart-container" do
            top_lubricants = LubricantConsumption
                               .where(transaction_date: Date.today.beginning_of_month..Date.today.end_of_month)
                               .group(:lubricant_type)
                               .sum(:quantity)
                               .sort_by { |_, q| -q }
                               .first(5)
            
            if top_lubricants.any?
              top_lubricants.each do |lubricant, quantity|
                div class: "lubricant-item" do
                  span class: "lubricant-name" do
                    lubricant
                  end
                  div class: "lubricant-bar-container" do
                    max = top_lubricants.first[1]
                    percentage = (quantity.to_f / max * 100).round(1)
                    div class: "lubricant-bar", style: "width: #{percentage}%"
                  end
                  span class: "lubricant-quantity" do
                    "#{quantity.round(1)} L"
                  end
                end
              end
            else
              p "No lubricant data for this month", class: "empty-chart"
            end
          end
        end
      end
      
      # Recent Activity Section
      div class: "activity-section" do
        div class: "section-header" do
          h2 "Recent Activity"
          link_to "View All", admin_work_orders_path, class: "view-all-link"
        end
        
        div class: "activity-timeline" do
          # Recent Work Orders
          recent_work_orders = WorkOrder.order(created_at: :desc).limit(5)
          
          if recent_work_orders.any?
            recent_work_orders.each do |wo|
              div class: "activity-item" do
                div class: "activity-icon #{wo.status}" do
                  case wo.status
                  when 'completed'
                    "✅"
                  when 'in_progress'
                    "🔄"
                  when 'reported'
                    "📝"
                  else
                    "🔧"
                  end
                end
                div class: "activity-content" do
                  div class: "activity-title" do
                    link_to wo.wo_number, admin_work_order_path(wo)
                    span class: "activity-status #{wo.status}" do
                      wo.status.humanize
                    end
                  end
                  div class: "activity-details" do
                    span "Asset: #{wo.asset&.fleet_number}"
                    span "Type: #{wo.wo_type&.humanize}"
                    span "Priority: #{wo.priority&.upcase}"
                  end
                  div class: "activity-time" do
                    time_ago_in_words(wo.created_at) + " ago"
                  end
                end
              end
            end
          else
            div class: "empty-state" do
              span "📭"
              p "No recent work orders"
            end
          end
        end
      end
      
      # Quick Actions
      div class: "quick-actions" do
        h3 "Quick Actions"
        div class: "actions-grid" do
          link_to new_admin_work_order_path, class: "action-card" do
            span class: "action-icon" do
              "➕"
            end
            span class: "action-label" do
              "New Work Order"
            end
            span class: "action-desc" do
              "Create a new work order"
            end
          end
          
          link_to new_admin_hour_meter_reading_path, class: "action-card" do
            span class: "action-icon" do
              "⏱️"
            end
            span class: "action-label" do
              "Record Meter"
            end
            span class: "action-desc" do
              "Record hour meter reading"
            end
          end
          
          link_to new_admin_lubricant_consumption_path, class: "action-card" do
            span class: "action-icon" do
              "🛢️"
            end
            span class: "action-label" do
              "Add Lubricant"
            end
            span class: "action-desc" do
              "Record lubricant usage"
            end
          end
          
          link_to admin_assets_path, class: "action-card" do
            span class: "action-icon" do
              "🔍"
            end
            span class: "action-label" do
              "Fleet Status"
            end
            span class: "action-desc" do
              "View asset conditions"
            end
          end
        end
      end
    end
  end
end
