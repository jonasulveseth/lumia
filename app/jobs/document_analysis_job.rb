class DocumentAnalysisJob < ApplicationJob
  queue_as :default

  def perform(document)
    DocumentAnalyzer.new(document).call
  rescue StandardError => e
    Rails.logger.error "[DocumentAnalysisJob] #{document.id}: #{e.class}: #{e.message}"
  end
end
