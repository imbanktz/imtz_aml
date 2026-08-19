class RtgsProcessingJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform
    RtgsSchedulerService.process_rtgs_files
  end
end
