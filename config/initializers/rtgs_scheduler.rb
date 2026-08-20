# # config/schedule.rb
# require 'whenever'

# set :environment, Rails.env

# # Process RTGS files every 3 minutes
# every 3.minutes do
#   runner "ProcessRtgsWithManualParserJob.perform_now"
#   command "echo 'RTGS processing triggered at $(date)' >> log/rtgs_scheduler.log"
# end

# # For testing, run every minute
# # every 1.minute do
# #   runner "ProcessRtgsWithManualParserJob.perform_now"
# # end
