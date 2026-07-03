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
  user.employee_id = '6xmuna7'
  user.name = 'System Administrator'
  user.user_type = 'admin'
  user.is_creator = true
  user.is_approver = true
  user.active = true
  user.password = 'Password123!' # Devise will handle encryption
end

# Assign super admin role
super_admin_role = Role.find_by(code: 'SUPER_ADMIN')
UserRole.find_or_create_by!(user: admin_user, role: super_admin_role)

puts "Seed data created successfully!"
puts "Admin user: abdillah.muna@imbank.co.tz"
puts "Password: Password123!"
