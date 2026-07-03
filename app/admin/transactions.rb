ActiveAdmin.register Transaction do
  permit_params :request_id, :transaction_direction, :transaction_type,
                :transaction_amount, :transaction_currency, :transaction_date,
                :reference, :narrative, :bank_code, :status, :screening_status,
                :parties, :raw_data, :raw_fields, :raw_message

  index do
    selectable_column
    id_column
    column :request_id
    column :transaction_direction
    column :transaction_type
    column :transaction_amount
    column :transaction_currency
    column :transaction_date
    column :reference
    column :status
    column :screening_status
    column :created_at
    actions
  end

  filter :request_id
  filter :transaction_direction, as: :select, collection: Transaction.transaction_directions.keys.map { |dir| [dir.humanize, dir] }
  filter :transaction_type, as: :select, collection: Transaction.transaction_types.keys.map { |type| [type.humanize, type] }
  filter :transaction_currency
  filter :transaction_date
  filter :reference
  filter :status, as: :select, collection: Transaction.statuses.keys.map { |status| [status.humanize, status] }
  filter :screening_status, as: :select, collection: Transaction.screening_statuses.keys.map { |status| [status.humanize, status] }
  filter :created_at

  show do
    attributes_table do
      row :id
      row :request_id
      row :transaction_direction
      row :transaction_type
      row :transaction_amount
      row :transaction_currency
      row :transaction_date
      row :reference
      row :narrative
      row :bank_code
      row :status
      row :screening_status
      row :screening_result
      row :screening_error
      row :screened_at
      row :error_message
      row :processed_at
      row :created_at
      row :updated_at
    end
    
    panel "Parties" do
      if transaction.parties.present?
        table_for transaction.parties do
          column "Party Type" do |party|
            party["partyType"]
          end
          column "Party ID" do |party|
            party["partyId"]
          end
          column "Full Name" do |party|
            party["fullName"]
          end
          column "Nationalities" do |party|
            party["nationalities"]&.join(', ')
          end
          column "Address" do |party|
            party["addressLine"]
          end
        end
      else
        div "No parties found"
      end
    end
    
    panel "Raw Data" do
      pre do
        JSON.pretty_generate(transaction.raw_data) if transaction.raw_data.present?
      end
    end
  end

  form do |f|
    f.inputs 'Transaction Details' do
      f.input :request_id
      f.input :transaction_direction, as: :select, collection: Transaction.transaction_directions.keys.map { |dir| [dir.humanize, dir] }
      f.input :transaction_type, as: :select, collection: Transaction.transaction_types.keys.map { |type| [type.humanize, type] }
      f.input :transaction_amount
      f.input :transaction_currency
      f.input :transaction_date, as: :datepicker
      f.input :reference
      f.input :narrative
      f.input :bank_code
      f.input :status, as: :select, collection: Transaction.statuses.keys.map { |status| [status.humanize, status] }
      f.input :screening_status, as: :select, collection: Transaction.screening_statuses.keys.map { |status| [status.humanize, status] }
    end
    
    f.actions
  end

  member_action :approve, method: :post do
    transaction = Transaction.find(params[:id])
    if transaction.update(status: 'APPROVED')
      redirect_to admin_transaction_path(transaction), notice: "Transaction approved!"
    else
      redirect_to admin_transaction_path(transaction), alert: "Failed to approve transaction"
    end
  end

  member_action :reject, method: :post do
    transaction = Transaction.find(params[:id])
    if transaction.update(status: 'REJECTED')
      redirect_to admin_transaction_path(transaction), notice: "Transaction rejected!"
    else
      redirect_to admin_transaction_path(transaction), alert: "Failed to reject transaction"
    end
  end

  action_item :approve, only: :show do
    if transaction.status == 'PENDING_SCREENING' || transaction.status == 'SCREENED'
      link_to "Approve", approve_admin_transaction_path(transaction), method: :post, data: { confirm: "Are you sure?" }
    end
  end

  action_item :reject, only: :show do
    if transaction.status == 'PENDING_SCREENING' || transaction.status == 'SCREENED'
      link_to "Reject", reject_admin_transaction_path(transaction), method: :post, data: { confirm: "Are you sure?" }
    end
  end
end
