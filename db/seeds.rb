# db/seeds.rb
# Create default roles
roles = [
  { name: 'Super Admin', code: 'SUPER_ADMIN', description: 'Full system access' },
  { name: 'Admin', code: 'ADMIN', description: 'Administrative access' },
  { name: 'Screener', code: 'SCREENER', description: 'Can screen transactions' },
  { name: 'Approver', code: 'APPROVER', description: 'Can approve transactions' },
  { name: 'Viewer', code: 'VIEWER', description: 'Read-only access' }
]

roles.each do |role_attrs|
  Role.find_or_create_by!(code: role_attrs[:code]) do |role|
    role.name = role_attrs[:name]
    role.description = role_attrs[:description]
    role.active = true
  end
end

# Create default admin user
admin_user = User.find_or_create_by!(email: 'abdillah.muna@imbank.co.tz') do |user|
  user.employee_id = 'ADMIN001'
  user.name = 'System Administrator'
  user.user_type = 'admin'
  user.is_creator = true
  user.is_approver = true
  user.active = true
  user.password = '6xmuna7'
  user.password_confirmation = '6xmuna7'
end

# Assign super admin role
super_admin_role = Role.find_by(code: 'SUPER_ADMIN')
UserRole.find_or_create_by!(user: admin_user, role: super_admin_role)

# Create test screener user
screener_user = User.find_or_create_by!(email: 'screener@imbank.co.tz') do |user|
  user.employee_id = 'SCR001'
  user.name = 'Transaction Screener'
  user.user_type = 'screener'
  user.is_creator = false
  user.is_approver = false
  user.active = true
  user.password = '6xmuna7'
  user.password_confirmation = '6xmuna7'
end

# Assign screener role
screener_role = Role.find_by(code: 'SCREENER')
UserRole.find_or_create_by!(user: screener_user, role: screener_role)

# Create test approver user
approver_user = User.find_or_create_by!(email: 'approver@imbank.co.tz') do |user|
  user.employee_id = 'APP001'
  user.name = 'Transaction Approver'
  user.user_type = 'approver'
  user.is_creator = false
  user.is_approver = true
  user.active = true
  user.password = '6xmuna7'
  user.password_confirmation = '6xmuna7'
end

# Assign approver role
approver_role = Role.find_by(code: 'APPROVER')
UserRole.find_or_create_by!(user: approver_user, role: approver_role)

# Create test viewer user
viewer_user = User.find_or_create_by!(email: 'viewer@imbank.co.tz') do |user|
  user.employee_id = 'VIEW001'
  user.name = 'Transaction Viewer'
  user.user_type = 'viewer'
  user.is_creator = false
  user.is_approver = false
  user.active = true
  user.password = '6xmuna7'
  user.password_confirmation = '6xmuna7'
end

# Assign viewer role
viewer_role = Role.find_by(code: 'VIEWER')
UserRole.find_or_create_by!(user: viewer_user, role: viewer_role)

puts "Seed data created successfully!"
puts "Admin user: abdillah.muna@imbank.co.tz"
puts "Screener user: screener@imbank.co.tz"
puts "Approver user: approver@imbank.co.tz"
puts "Viewer user: viewer@imbank.co.tz"
puts "Password for all: 6xmuna7"
