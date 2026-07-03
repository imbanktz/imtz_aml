ActiveAdmin.register User do
  permit_params :employee_id, :name, :email, :user_type, :active, 
                :password, :password_confirmation, role_ids: []

  index do
    selectable_column
    id_column
    column :employee_id
    column :name
    column :email
    column :user_type
    column :active
    column :created_at
    actions
  end

  filter :employee_id
  filter :name
  filter :email
  filter :user_type, as: :select, collection: User.user_types.keys.map { |type| [type.humanize, type] }
  filter :active
  filter :created_at

  form do |f|
    f.inputs 'User Details' do
      f.input :employee_id
      f.input :name
      f.input :email
      f.input :user_type, as: :select, collection: User.user_types.keys.map { |type| [type.humanize, type] }
      f.input :active
      f.input :roles, as: :check_boxes, collection: Role.all.map { |role| [role.name, role.id] }
    end
    
    f.inputs 'Password' do
      f.input :password
      f.input :password_confirmation
    end
    
    f.actions
  end

  show do
    attributes_table do
      row :id
      row :employee_id
      row :name
      row :email
      row :user_type
      row :active
      row :roles do |user|
        user.roles.map(&:name).join(', ')
      end
      row :created_at
      row :updated_at
      row :sign_in_count
      row :current_sign_in_at
      row :last_sign_in_at
      row :current_sign_in_ip
      row :last_sign_in_ip
    end
  end
end
