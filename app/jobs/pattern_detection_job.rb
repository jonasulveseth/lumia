# Körs varje måndag för alla användare (config/recurring.yml) och på begäran
# från /insights.
class PatternDetectionJob < ApplicationJob
  queue_as :default

  def perform(user = nil)
    users = user ? [ user ] : User.where.not(onboarded_at: nil)
    users.each do |u|
      PatternFinder.new(u).call
      Turbo::StreamsChannel.broadcast_refresh_to [ u, :insights ]
    rescue StandardError => e
      Rails.logger.error "[PatternDetectionJob] user #{u.id}: #{e.class}: #{e.message}"
    end
  end
end
