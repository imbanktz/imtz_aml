class WoPart < ApplicationRecord
  belongs_to :work_order
  belongs_to :part
end
