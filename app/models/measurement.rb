class Measurement < ApplicationRecord
  belongs_to :user
  belongs_to :source, polymorphic: true, optional: true

  validates :metric_key, :value, :measured_at, presence: true

  before_validation :fill_from_catalog

  scope :recent, -> { order(measured_at: :desc) }
  scope :chronological, -> { order(:measured_at) }

  def metric = Metric.find(metric_key)
  def display_label = label.presence || metric&.name || metric_key.humanize

  def out_of_range?
    (reference_low && value < reference_low) || (reference_high && value > reference_high)
  end

  def self.series(user, metric_key, since: 90.days.ago)
    user.measurements.where(metric_key: metric_key).where(measured_at: since..).chronological
  end

  private

  def fill_from_catalog
    return unless (m = metric)

    self.unit ||= m.unit
    self.area_key ||= m.area_key
  end
end
