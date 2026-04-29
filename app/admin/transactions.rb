ActiveAdmin.register Transaction do
  permit_params :date, :request_id, :transaction_direction, :transaction_amount,
                :transaction_currency, :transaction_date, :clearing_system_ref,
                :parties, :agents, :narratives, :forensic_data, :processing_type,
                :profile, :profile_name

  # Index page
  index do
    selectable_column
    id_column
    column :date
    column :request_id
    column :transaction_direction
    column :transaction_amount
    column :transaction_currency
    column :transaction_date
    column :clearing_system_ref
    column :processing_type
    column :profile
    actions
  end

  # Filters
  filter :request_id
  filter :transaction_direction, as: :select, collection: ['IN', 'OUT']
  filter :transaction_amount
  filter :transaction_currency, as: :select, collection: -> { Transaction.pluck(:transaction_currency).uniq }
  filter :transaction_date
  filter :clearing_system_ref
  filter :processing_type, as: :select, collection: -> { Transaction.pluck(:processing_type).uniq }
  filter :profile
  filter :created_at
  filter :updated_at

  # Show page
  show do
    attributes_table do
      row :id
      row :date
      row :request_id
      row :transaction_direction
      row :transaction_amount
      row :transaction_currency
      row :transaction_date
      row :clearing_system_ref
      row :processing_type
      row :profile
      row :profile_name
      row :created_at
      row :updated_at
      
      # Custom rows for JSON data
      row :parties do |transaction|
        if transaction.parties.present?
          panel "Parties" do
            table_for transaction.parties do
              column "Party ID", :partyId
              column "Party Type", :partyType
              column "Full Name", :fullName
              column "Nationalities", :nationalities
              column "Address", :addressLine
            end
          end
        end
      end
      
      row :agents do |transaction|
        if transaction.agents.present?
          panel "Agents" do
            table_for transaction.agents do
              column "Agent ID", :agentId
              column "Agent Type", :agentType
              column "BIC", :bic
            end
          end
        end
      end
      
      row :narratives do |transaction|
        if transaction.narratives.present?
          panel "Narratives" do
            attributes_table_for transaction.narratives do
              row :remittanceInfo
              row :all
            end
          end
        end
      end
    end
  end

  # Form
  form do |f|
    f.inputs "Transaction Details" do
      f.input :date, as: :datetime_picker
      f.input :request_id
      f.input :transaction_direction, as: :select, collection: ['IN', 'OUT']
      f.input :transaction_amount
      f.input :transaction_currency
      f.input :transaction_date, as: :datepicker
      f.input :clearing_system_ref
      f.input :processing_type
      f.input :profile
      f.input :profile_name
    end
    
    f.inputs "Parties (JSON)" do
      f.input :parties, as: :jsonb, input_html: { rows: 10 }
    end
    
    f.inputs "Agents (JSON)" do
      f.input :agents, as: :jsonb, input_html: { rows: 10 }
    end
    
    f.inputs "Narratives (JSON)" do
      f.input :narratives, as: :jsonb, input_html: { rows: 5 }
    end
    
    f.inputs "Forensic Data (JSON)" do
      f.input :forensic_data, as: :jsonb, input_html: { rows: 5 }
    end
    
    f.actions
  end

  # Custom actions
  member_action :view_json, method: :get do
    render json: resource
  end

  action_item :view_json, only: :show do
    link_to "View JSON", view_json_admin_transaction_path(resource)
  end
  
  # CSV Export customization
  csv do
    column :id
    column :date
    column :request_id
    column :transaction_direction
    column :transaction_amount
    column :transaction_currency
    column :transaction_date
    column :clearing_system_ref
    column :parties do |transaction|
      transaction.parties.to_json
    end
    column :agents do |transaction|
      transaction.agents.to_json
    end
    column :narratives do |transaction|
      transaction.narratives.to_json
    end
    column :processing_type
    column :profile
    column :profile_name
  end
end
