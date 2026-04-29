class WoLubricant < ApplicationRecord
  belongs_to :work_order
  belongs_to :lubricant
end
