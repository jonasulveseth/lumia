class EntryProcessingJob < ApplicationJob
  queue_as :default
  retry_on Ai::Error, Net::ReadTimeout, Errno::ECONNREFUSED, wait: 30.seconds, attempts: 3

  def perform(entry)
    EntryAnalyzer.new(entry).call
    entry.broadcast_replace_to [ entry.user, :entries ], partial: "entries/entry", locals: { entry: entry.reload }
  end
end
