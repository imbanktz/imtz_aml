ActiveAdmin.register User do
  permit_params :employee_id, :name, :email, :user_type, :role, :is_creator, :is_approver,
                :approval_limit, :primary_workshop_id, :pin_code, :active, :password, :password_confirmation

  # Customize the page title and menu
  menu label: "Users", priority: 6, parent: "Administration"
  
  # Enhanced Index Page
  index title: "Team Members", download_links: [:csv, :pdf] do
    selectable_column
    id_column
    column :employee_id do |u|
      strong u.employee_id
    end
    column :name do |u|
      div class: "user-info" do
        strong link_to u.name, admin_user_path(u)
        small u.email, class: "email-sub"
      end
    end
    column :user_type do |u|
      badge_class = case u.user_type
                    when 'imtz_aml' then 'primary'
                    when 'supervisor' then 'info'
                    when 'mechanic' then 'warning'
                    when 'maintenance_planner' then 'success'
                    when 'engineer' then 'blue'
                    else 'default'
                    end
      span u.user_type.humanize, class: "status_tag #{badge_class}"
    end
    column :role do |u|
      if u.role
        role_class = case u.role
                     when 'admin' then 'danger'
                     when 'manager' then 'warning'
                     when 'planner' then 'info'
                     else 'default'
                     end
        span u.role.humanize, class: "status_tag #{role_class}"
      else
        span "No Role", class: "status_tag default"
      end
    end
    column "Permissions" do |u|
      div class: "permission-badges" do
        span "Creator", class: "badge #{'active' if u.is_creator}" if u.is_creator
        span "Approver", class: "badge #{'active' if u.is_approver}" if u.is_approver
      end
    end
    column :active do |u|
      status_tag u.active ? 'Active' : 'Inactive', class: u.active ? :green : :red
    end
    column "Work Orders" do |u|
      link_to u.reported_work_orders.count, admin_work_orders_path(q: { reported_by_id_eq: u.id }), class: "count-badge"
    end
    actions defaults: true do |u|
      item "Reset PIN", reset_pin_admin_user_path(u), class: "member_link reset-pin-link", 
           data: { confirm: "Reset PIN for #{u.name}?" }
    end
  end

  filter :employee_id, as: :string, label: "Employee ID", input_html: { placeholder: "e.g., EMP001" }
  filter :name, as: :string, input_html: { placeholder: "Search by name..." }
  filter :email, as: :string, input_html: { placeholder: "email@example.com" }
  filter :user_type, as: :select, collection: User.user_types.keys.map { |t| [t.humanize, t] }, 
         input_html: { class: "select2" }
  # TEMPORARILY REMOVED - filter :role, as: :select, collection: User.roles.keys.map { |r| [r.humanize, r] }, 
  #        input_html: { class: "select2" }
  filter :active, as: :select, collection: [['Active', true], ['Inactive', false]]
  # filter :primary_workshop, as: :select, collection: -> { Workshop.active.map { |w| [w.name, w.id] } }
  filter :created_at, as: :date_range

  # Enhanced Form with better organization
  form html: { class: "user-form", multipart: true } do |f|
    f.semantic_errors *f.object.errors.attribute_names
    
    columns do
      column span: 2 do
        f.inputs "Personal Information", class: "panel" do
          f.input :employee_id, input_html: { placeholder: "e.g., EMP001" }, hint: "Unique employee identifier"
          f.input :name, input_html: { placeholder: "Full name" }, hint: "Employee's full name"
          f.input :email, input_html: { placeholder: "employee@company.com" }, hint: "Work email address"
          f.input :user_type, as: :select, 
                  collection: User.user_types.keys.map { |t| [t.humanize, t] },
                  required: true, input_html: { class: "select2" }, hint: "Job function"
          f.input :primary_workshop, as: :select, 
                  collection: Workshop.active.map { |w| [w.name, w.id] }, 
                  include_blank: 'None', input_html: { class: "select2" }, 
                  hint: "Main workshop assignment"
        end
      end
      
      column span: 1 do
        f.inputs "Security & Access", class: "panel" do
          f.input :pin_code, input_html: { placeholder: "4-6 digit PIN", maxlength: 6 }, 
                  hint: "4-6 digit PIN for mobile app login"
          f.input :password, input_html: { placeholder: "Leave blank to keep unchanged" },
                  hint: "Minimum 6 characters"
          f.input :password_confirmation, input_html: { placeholder: "Confirm new password" },
                  hint: "Re-enter password to confirm"
          f.input :active, as: :boolean, hint: "Inactive users cannot login"
        end
      end
    end
    
    columns do
      column span: 1 do
        f.inputs "System Role & Permissions", class: "panel" do
          f.input :role, as: :select,
                  collection: User.roles.keys.map { |r| [r.humanize, r] },
                  include_blank: 'No role assigned',
                  input_html: { class: "select2" },
                  hint: "System-wide access level"
          
          div class: "role-description" do
            content_tag :div, class: "help-text" do
              concat content_tag(:strong, "Role Descriptions:")
              concat tag(:br)
              concat "• Admin: Full system access"
              concat tag(:br)
              concat "• Manager: Can manage users and view all"
              concat tag(:br)
              concat "• Planner: Can create schedules and work orders"
              concat tag(:br)
              concat "• Viewer: Read-only access"
            end
          end
        end
      end
      
      column span: 1 do
        f.inputs "Additional Permissions", class: "panel" do
          f.input :is_creator, as: :boolean, 
                  label: "Can create work orders",
                  hint: "Allow user to create new work orders"
          f.input :is_approver, as: :boolean, 
                  label: "Can approve requests",
                  hint: "Allow user to approve purchase requests"
          f.input :approval_limit, as: :number, 
                  label: "Approval Limit ($)", 
                  hint: "Maximum amount user can approve without escalation",
                  input_html: { step: "1000", placeholder: "e.g., 5000" }
        end
      end
    end
    
    f.actions do
      f.action :submit, as: :button, button_html: { class: "primary" }
      f.cancel_link
      if f.object.persisted?
        link_to "Reset PIN", reset_pin_admin_user_path(f.object), 
                class: "button alert", style: "margin-left: 10px",
                data: { confirm: "Reset PIN for #{f.object.name}?" }
      end
    end
  end

  # Enhanced Show Page
  show title: ->(user) { "#{user.name} (#{user.employee_id})" } do
    columns do
      column span: 2 do
        panel "User Profile", class: "info-panel" do
          attributes_table_for user do
            row :employee_id do
              strong user.employee_id
            end
            row :name do
              user.name
            end
            row :email do
              link_to user.email, "mailto:#{user.email}"
            end
            row :user_type do
              badge_class = case user.user_type
                            when 'imtz_aml' then 'primary'
                            when 'supervisor' then 'info'
                            when 'mechanic' then 'warning'
                            when 'maintenance_planner' then 'success'
                            when 'engineer' then 'blue'
                            else 'default'
                            end
              span user.user_type.humanize, class: "status_tag #{badge_class}"
            end
            row :role do
              if user.role
                role_class = case user.role
                             when 'admin' then 'danger'
                             when 'manager' then 'warning'
                             when 'planner' then 'info'
                             else 'default'
                             end
                span user.role.humanize, class: "status_tag #{role_class}"
              else
                "-"
              end
            end
            row :primary_workshop do
              link_to user.primary_workshop.name, admin_workshop_path(user.primary_workshop) if user.primary_workshop
            end
          end
        end
        
        columns do
          column span: 1 do
            panel "Permissions", class: "info-panel" do
              attributes_table_for user do
                row :is_creator do
                  status_tag user.is_creator ? "Yes" : "No", class: user.is_creator ? :green : :red
                end
                row :is_approver do
                  status_tag user.is_approver ? "Yes" : "No", class: user.is_approver ? :green : :red
                end
                row :approval_limit do
                  number_to_currency(user.approval_limit) if user.approval_limit
                end
              end
            end
          end
          
          column span: 1 do
            panel "Account Status", class: "info-panel" do
              attributes_table_for user do
                row :active do
                  status_tag user.active ? "Active" : "Inactive", class: user.active ? :green : :red
                end
                row :pin_code do
                  div class: "pin-code" do
                    code "••••••"
                    link_to "Reset PIN", reset_pin_admin_user_path(user), method: :post, 
                            style: "margin-left: 10px", data: { confirm: "Reset PIN for this user?" }
                  end
                end
                if user.respond_to?(:sign_in_count)
                  row "Sign in count" do
                    user.sign_in_count || 0
                  end
                  row "Current sign in" do
                    user.current_sign_in_at&.strftime("%Y-%m-%d %H:%M") || "Never"
                  end
                  row "Last sign in" do
                    user.last_sign_in_at&.strftime("%Y-%m-%d %H:%M") || "Never"
                  end
                end
                row :created_at do
                  user.created_at.strftime("%B %d, %Y at %H:%M")
                end
                row :updated_at do
                  user.updated_at.strftime("%B %d, %Y at %H:%M")
                end
              end
            end
          end
        end
      end
      
      column span: 1 do
        panel "Statistics", class: "stats-panel" do
          div class: "stats-grid" do
            div class: "stat-card" do
              h3 "Work Orders"
              p class: "stat-number" do
                link_to user.reported_work_orders.count, admin_work_orders_path(q: { reported_by_id_eq: user.id })
              end
              small "Reported"
            end
            
            div class: "stat-card" do
              h3 "Assigned Jobs"
              p class: "stat-number" do
                link_to user.assigned_work_orders.count, admin_work_orders_path(q: { assigned_mechanic_id_eq: user.id })
              end
              small "As Mechanic"
            end
            
            div class: "stat-card" do
              h3 "Hour Readings"
              p class: "stat-number" do
                user.hour_meter_readings.count
              end
              small "Recorded"
            end
          end
        end
      end
    end
    
    if user.reported_work_orders.any?
      panel "Recent Work Orders Reported", class: "work-orders-panel" do
        table_for user.reported_work_orders.order(created_at: :desc).limit(10) do
          column :wo_number do |wo|
            link_to wo.wo_number, admin_work_order_path(wo)
          end
          column :asset do |wo|
            link_to wo.asset.fleet_number, admin_asset_path(wo.asset) if wo.asset
          end
          column :wo_type do |wo|
            span wo.wo_type.humanize, class: "status_tag #{wo.wo_type}"
          end
          column :priority do |wo|
            priority_class = case wo.priority
                             when 'emergency' then 'danger'
                             when 'high' then 'warning'
                             else 'info'
                             end
            span wo.priority.upcase, class: "status_tag #{priority_class}"
          end
          column :status do |wo|
            status_class = case wo.status
                           when 'completed' then 'success'
                           when 'in_progress' then 'warning'
                           else 'info'
                           end
            span wo.status.humanize, class: "status_tag #{status_class}"
          end
          column :reported_at do |wo|
            wo.reported_at&.strftime("%Y-%m-%d")
          end
        end
        
        if user.reported_work_orders.count > 10
          div class: "view-all" do
            link_to "View all #{user.reported_work_orders.count} work orders", 
                    admin_work_orders_path(q: { reported_by_id_eq: user.id })
          end
        end
      end
    end
    
    if user.assigned_work_orders.where(status: ['assigned', 'in_progress']).any?
      panel "Current Assignments", class: "assignments-panel" do
        table_for user.assigned_work_orders.where(status: ['assigned', 'in_progress']).order(priority: :asc) do
          column :wo_number do |wo|
            link_to wo.wo_number, admin_work_order_path(wo)
          end
          column :asset do |wo|
            link_to wo.asset.fleet_number, admin_asset_path(wo.asset) if wo.asset
          end
          column :priority do |wo|
            priority_class = case wo.priority
                             when 'emergency' then 'danger'
                             when 'high' then 'warning'
                             else 'info'
                             end
            span wo.priority.upcase, class: "status_tag #{priority_class}"
          end
          column :status do |wo|
            span wo.status.humanize, class: "status_tag info"
          end
          column "Time in Status" do |wo|
            if wo.started_at
              hours = ((Time.current - wo.started_at) / 3600).round(1)
              "#{hours} hours"
            else
              "Not started"
            end
          end
        end
      end
    end
    
    active_admin_comments
  end

  # Batch actions
  batch_action :activate do |ids|
    User.find(ids).each { |user| user.update(active: true) }
    redirect_to collection_path, notice: "#{ids.count} users activated"
  end
  
  batch_action :deactivate do |ids|
    User.find(ids).each { |user| user.update(active: false) }
    redirect_to collection_path, notice: "#{ids.count} users deactivated"
  end
  
  batch_action :reset_pins do |ids|
    User.find(ids).each do |user|
      new_pin = rand(100000..999999).to_s
      user.update(pin_code: new_pin)
    end
    redirect_to collection_path, notice: "PINs reset for #{ids.count} users"
  end
  
  batch_action :assign_role, form: {
                 role: User.roles.keys.map { |r| [r.humanize, r] }
               } do |ids, inputs|
    User.find(ids).each { |user| user.update(role: inputs[:role]) }
    redirect_to collection_path, notice: "Role assigned to #{ids.count} users"
  end

  # Actions
  member_action :reset_pin, method: :post do
    new_pin = rand(100000..999999).to_s
    resource.update(pin_code: new_pin)
    redirect_to admin_user_path(resource), notice: "PIN reset successfully. New PIN: #{new_pin}"
  end
  
  action_item :reset_pin, only: :show do
    link_to "Reset PIN", reset_pin_admin_user_path(user), method: :post, 
            data: { confirm: "Reset PIN for #{user.name}?" }
  end
  
  # Collection actions for reports
  collection_action :export_mechanics, method: :get do
    mechanics = User.mechanics.active
    send_data mechanics.to_csv, filename: "mechanics-#{Date.current}.csv"
  end
  
  action_item :export_mechanics, only: :index do
    link_to "Export Mechanics", export_mechanics_admin_users_path
  end
end
