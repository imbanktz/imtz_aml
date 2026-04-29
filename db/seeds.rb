
# puts "🌱 Seeding database..."

# # Clear existing data (optional - be careful in production)
# if Rails.env.production?
#   puts "Clearing existing data..."
#   WorkOrder.delete_all if defined?(WorkOrder)
#   Asset.delete_all if defined?(Asset)
#   User.delete_all if defined?(User)
#   Part.delete_all if defined?(Part)
#   Lubricant.delete_all if defined?(Lubricant)
#   BreakdownReason.delete_all if defined?(BreakdownReason)
#   Workshop.delete_all if defined?(Workshop)
#   Farm.delete_all if defined?(Farm)
#   AssetCategory.delete_all if defined?(AssetCategory)
#   AssetType.delete_all if defined?(AssetType)
#   AssetMake.delete_all if defined?(AssetMake)
#   AssetModel.delete_all if defined?(AssetModel)
#   PmSchedule.delete_all if defined?(PmSchedule)
# end

# # ============================================
# # 1. CREATE ADMIN USER (using User model)
# # ============================================
# puts "Creating admin user..."

# admin_user = User.find_or_initialize_by(email: 'abdimuna1@gmail.com')
# admin_user.assign_attributes(
#   employee_id: 'ADMIN001',
#   name: 'System Admin',
#   user_type: 'imtz_aml',  # Using imtz_aml as admin role
#   role: 'admin',
#   active: true,
#   password: '6xmuna7',
#   password_confirmation: '6xmuna7'
# )
# admin_user.save!
# puts "  ✅ Admin user: abdimuna1@gmail.com / 6xmuna7 (imtz_aml)"

# # ============================================
# # 2. CREATE REGULAR USERS
# # ============================================
# puts "Creating regular users..."

# users = [
#   { employee_id: "DRV001", name: "John Driver", email: "driver@fleet.com", user_type: "driver", role: "viewer", active: true, password: "password123", password_confirmation: "password123" },
#   { employee_id: "OPR001", name: "Sarah Operator", email: "operator@fleet.com", user_type: "operator", role: "viewer", active: true, password: "password123", password_confirmation: "password123" },
#   { employee_id: "MEC001", name: "James Mechanic", email: "mechanic@fleet.com", user_type: "mechanic", role: "viewer", active: true, password: "password123", password_confirmation: "password123" },
#   { employee_id: "ENG001", name: "Peter Engineer", email: "engineer@fleet.com", user_type: "engineer", role: "planner", active: true, password: "password123", password_confirmation: "password123" },
#   { employee_id: "PLN001", name: "Sarah Planner", email: "planner@fleet.com", user_type: "maintenance_planner", role: "planner", active: true, password: "password123", password_confirmation: "password123" },
#   { employee_id: "STK001", name: "Grace Storekeeper", email: "storekeeper@fleet.com", user_type: "storekeeper", role: "viewer", active: true, password: "password123", password_confirmation: "password123" },
#   { employee_id: "SUP001", name: "John Supervisor", email: "supervisor@fleet.com", user_type: "supervisor", role: "manager", active: true, password: "password123", password_confirmation: "password123" },
#   { employee_id: "MGR001", name: "Mary Manager", email: "manager@fleet.com", user_type: "imtz_aml", role: "admin", active: true, password: "password123", password_confirmation: "password123" }
# ]

# users.each do |user_attrs|
#   user = User.find_or_initialize_by(employee_id: user_attrs[:employee_id])
#   user.update!(user_attrs)
#   puts "  ✅ User: #{user.name} (#{user.user_type}) - #{user.email}"
# end

# # ============================================
# # 3. CREATE WORKSHOPS
# # ============================================
# puts "Creating workshops..."

# workshops = [
#   { code: "WSH-NRB", name: "Nairobi Main Workshop", address: "Industrial Area, Nairobi", active: true },
#   { code: "WSH-KSM", name: "Kisumu Workshop", address: "Kisumu Industrial Area", active: true },
#   { code: "WSH-MBS", name: "Mombasa Workshop", address: "Mombasa Port Area", active: true }
# ]

# workshops.each do |ws_attrs|
#   workshop = Workshop.find_or_initialize_by(code: ws_attrs[:code])
#   workshop.update!(ws_attrs)
#   puts "  ✅ Workshop: #{workshop.name}"
# end

# # ============================================
# # 4. CREATE WORKSHOP SECTIONS
# # ============================================
# puts "Creating workshop sections..."

# nrb_workshop = Workshop.find_by(code: "WSH-NRB")
# ksm_workshop = Workshop.find_by(code: "WSH-KSM")

# if nrb_workshop
#   sections = [
#     { workshop: nrb_workshop, section_code: "H-BAY1", section_name: "Heavy Equipment Bay 1", section_type: "Heavy Bay", capacity: 3, active: true },
#     { workshop: nrb_workshop, section_code: "H-BAY2", section_name: "Heavy Equipment Bay 2", section_type: "Heavy Bay", capacity: 3, active: true },
#     { workshop: nrb_workshop, section_code: "ENG-REB", section_name: "Engine Rebuild Section", section_type: "Engine Rebuild", capacity: 2, active: true },
#   ]
  
#   sections.each do |section_attrs|
#     section = WorkshopSection.find_or_initialize_by(section_code: section_attrs[:section_code])
#     section.update!(section_attrs)
#     puts "  ✅ Section: #{section.section_name}"
#   end
# end

# if ksm_workshop
#   section = WorkshopSection.find_or_initialize_by(section_code: "LIGHT")
#   section.update!(
#     workshop: ksm_workshop,
#     section_name: "Light Vehicle Bay",
#     section_type: "Light Vehicle Bay",
#     capacity: 4,
#     active: true
#   )
#   puts "  ✅ Section: #{section.section_name}"
# end

# # ============================================
# # 5. CREATE FARMS
# # ============================================
# puts "Creating farms..."

# farms = [
#   { farm_code: "FARM-MUM", farm_name: "Mumias Sugar Estate", farm_category: "Sugar", region: "Western", area_hectares: 5000 },
#   { farm_code: "FARM-NZO", farm_name: "Nzola Sugar Plantation", farm_category: "Sugar", region: "Western", area_hectares: 3200 },
#   { farm_code: "FARM-OL", farm_name: "Ol Kalou Farm", farm_category: "Mixed Crop", region: "Central", area_hectares: 800 }
# ]

# farms.each do |farm_attrs|
#   farm = Farm.find_or_initialize_by(farm_code: farm_attrs[:farm_code])
#   farm.update!(farm_attrs)
#   puts "  ✅ Farm: #{farm.farm_name}"
# end

# # ============================================
# # 6. CREATE ASSET CATEGORIES
# # ============================================
# puts "Creating asset categories..."

# categories = [
#   { code: "EARTH", name: "Earthmoving"},
#   { code: "HAUL", name: "Haulage & Transport"},
#   { code: "HARV", name: "Harvesting"},
#   { code: "TILL", name: "Tillage"}
# ]

# categories.each do |cat_attrs|
#   category = AssetCategory.find_or_initialize_by(code: cat_attrs[:code])
#   category.update!(cat_attrs)
#   puts "  ✅ Category: #{category.name}"
# end

# # ============================================
# # 7. CREATE ASSET TYPES


# puts "Creating asset types..."

# earth_category = AssetCategory.find_by(code: "EARTH")

# if earth_category.nil?
#   puts "  ❌ AssetCategory with code 'EARTH' not found. Please create it first."
# else
#   asset_types_data = [
#     { type_code: "EXC", type_name: "Excavator", typical_lifespan_hours: 12000, active: true },
#     { type_code: "DOZ", type_name: "Dozer", typical_lifespan_hours: 15000, active: true },
#     { type_code: "LOAD", type_name: "Wheel Loader", typical_lifespan_hours: 10000, active: true }
#   ]

#   asset_types_data.each do |type_attrs|
#     # Find or initialize by type_code
#     asset_type = AssetType.find_or_initialize_by(type_code: type_attrs[:type_code])
    
#     # Set all attributes including the category association
#     asset_type.type_name = type_attrs[:type_name]
#     asset_type.typical_lifespan_hours = type_attrs[:typical_lifespan_hours]
#     asset_type.active = type_attrs[:active]
#     asset_type.asset_category = earth_category  # Use the association
    
#     if asset_type.save
#       puts "  ✅ Asset Type: #{asset_type.type_name} (Category: #{earth_category.code})"
#     else
#       puts "  ❌ Error creating #{type_attrs[:type_name]}: #{asset_type.errors.full_messages.join(', ')}"
#     end
#   end
# end

# # ============================================
# # 8. CREATE ASSET MAKES
# # ============================================
# puts "Creating asset makes..."

# makes = ["Caterpillar", "Komatsu", "John Deere", "Volvo", "TATA", "HOWO", "BELL", "NEW HOLLAND"]

# makes.each do |make_name|
#   make = AssetMake.find_or_initialize_by(name: make_name)
#   puts "  ✅ Make: #{make.name}"
# end

# # ============================================
# # 9. CREATE BREAKDOWN REASONS
# # ============================================
# puts "Creating breakdown reasons..."

# reasons = [
#   { reason_code: "LEAK_HYD", reason_name: "Hydraulic Leakage", category: "hydraulic", average_repair_hours: 4.0 },
#   { reason_code: "LEAK_ENG", reason_name: "Engine Oil Leak", category: "engine", average_repair_hours: 3.0 },
#   { reason_code: "LEAK_DIFF", reason_name: "Differential Seal Leak", category: "transmission", average_repair_hours: 5.0 },
#   { reason_code: "NO_POWER", reason_name: "Engine No Power", category: "engine", average_repair_hours: 8.0 },
#   { reason_code: "STRANGE_NOISE", reason_name: "Strange Noise", category: "other", average_repair_hours: 2.0 }
# ]

# reasons.each do |reason_attrs|
#   reason = BreakdownReason.find_or_initialize_by(reason_code: reason_attrs[:reason_code])
#   reason.update!(reason_attrs)
#   puts "  ✅ Reason: #{reason.reason_name}"
# end

# # ============================================
# # 10. CREATE SAMPLE ASSETS
# # ============================================
# puts "Creating sample assets..."

# assets = [
#   { fleet_number: "PD318", serial_number: "CAT336DL001", current_status: "operational", current_location_type: "workshop", current_hour_meter: 4250.5, active: true },
#   { fleet_number: "CL006", serial_number: "BELL125F001", current_status: "operational", current_location_type: "farm", current_hour_meter: 3100.0, active: true },
#   { fleet_number: "PV491", serial_number: "TATA2528001", current_status: "operational", current_location_type: "yard", current_hour_meter: 15000.5, active: true }
# ]

# assets.each do |asset_attrs|
#   asset = Asset.find_or_initialize_by(fleet_number: asset_attrs[:fleet_number])
#   asset.update!(asset_attrs)
#   puts "  ✅ Asset: #{asset.fleet_number}"
# end

# # ============================================
# # 11. CREATE PARTS
# # ============================================
# puts "Creating spare parts..."

# parts = [
#   { part_number: "284633206701", part_name: "KING-PIN", applicable_make: "TATA", minimum_stock: 4, current_stock: 6, reorder_level: 2, unit_cost: 150.00 },
#   { part_number: "281946600101", part_name: "POWER STEERING", applicable_make: "TATA", minimum_stock: 2, current_stock: 3, reorder_level: 1, unit_cost: 450.00 },
#   { part_number: "284633403101", part_name: "TAPPER ROLLER BEARING INNER", applicable_make: "TATA", minimum_stock: 8, current_stock: 10, reorder_level: 4, unit_cost: 35.00 },
#   { part_number: "267-3361", part_name: "FUEL INJECTION PUMP", applicable_make: "Caterpillar", minimum_stock: 1, current_stock: 2, reorder_level: 1, unit_cost: 21099.00 },
#   { part_number: "FILT-101", part_name: "Oil Filter", minimum_stock: 20, current_stock: 15, reorder_level: 10, unit_cost: 12.50 }
# ]

# parts.each do |part_attrs|
#   part = Part.find_or_initialize_by(part_number: part_attrs[:part_number])
#   part.update!(part_attrs)
#   puts "  ✅ Part: #{part.part_name}"
# end

# # ============================================
# # 12. CREATE LUBRICANTS
# # ============================================
# puts "Creating lubricants..."

# lubricants = [
#   { code: "15W40", name: "Engine Oil 15W40", unit: "litres", current_stock: 500, min_stock_level: 200, unit_cost: 8.00 },
#   { code: "10W", name: "Hydraulic Oil 10W", unit: "litres", current_stock: 300, min_stock_level: 150, unit_cost: 7.50 },
#   { code: "ISO68", name: "Hydraulic Oil ISO 68", unit: "litres", current_stock: 250, min_stock_level: 100, unit_cost: 8.00 },
#   { code: "GREASE", name: "Lithium Grease", unit: "kg", current_stock: 100, min_stock_level: 50, unit_cost: 5.00 }
# ]

# lubricants.each do |lube_attrs|
#   lubricant = Lubricant.find_or_initialize_by(code: lube_attrs[:code])
#   lubricant.update!(lube_attrs)
#   puts "  ✅ Lubricant: #{lubricant.name}"
# end

# # ============================================
# # 13. CREATE PM SCHEDULES
# # ============================================
# puts "Creating PM schedules..."

# schedules = [
#   { name: "Daily Pre-op Inspection", equipment_category: "All", trigger_hours: 8, estimated_hours: 0.5, active: true },
#   { name: "250 Hour Service", equipment_category: "Excavator", trigger_hours: 250, estimated_hours: 6.0, active: true },
#   { name: "500 Hour Service", equipment_category: "Excavator", trigger_hours: 500, estimated_hours: 10.0, active: true },
#   { name: "1000 Hour Service", equipment_category: "Excavator", trigger_hours: 1000, estimated_hours: 16.0, active: true }
# ]

# schedules.each do |schedule_attrs|
#   schedule = PmSchedule.find_or_initialize_by(name: schedule_attrs[:name])
#   schedule.update!(schedule_attrs)
#   puts "  ✅ PM Schedule: #{schedule.name}"
# end

# puts ""
# puts "🌱 Seeding complete!"
# puts "📊 Summary:"
# puts "   - Users: #{User.count}"
# puts "   - Assets: #{Asset.count}"
# puts "   - Parts: #{Part.count}"
# puts "   - Lubricants: #{Lubricant.count}"
# puts "   - Workshops: #{Workshop.count}"
# puts "   - Farms: #{Farm.count}"
# puts "   - Asset Categories: #{AssetCategory.count}"
# puts "   - Asset Types: #{AssetType.count}"
# puts "   - Asset Makes: #{AssetMake.count}"
# puts "   - Breakdown Reasons: #{BreakdownReason.count}"
# puts "   - PM Schedules: #{PmSchedule.count}"
# puts ""
# puts "🔐 Login credentials:"
# puts "   Admin (Fleet Manager): abdimuna1@gmail.com / 6xmuna7"
# puts "   Regular User: driver@fleet.com / password123"
# puts ""
# puts "🚀 Access the admin panel at: http://localhost:7080/admin"
