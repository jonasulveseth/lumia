# Samma idé som i reemove: vilken modell/leverantör AI:n använder styrs från
# databasen och kan bytas utan deploy. Saknas en standardprovider faller
# InferenceConfig tillbaka på credentials och sist på lokal Ollama.
class AiProvider < ApplicationRecord
  TYPES = %w[ollama openai_compatible].freeze

  encrypts :api_key

  validates :name, :api_base_url, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :provider_type, inclusion: { in: TYPES }

  scope :active, -> { where(active: true) }

  before_save :ensure_single_default

  def self.default = find_by(is_default: true, active: true)

  def ollama? = provider_type == "ollama"
  def openai_compatible? = provider_type == "openai_compatible"

  private

  def ensure_single_default
    self.class.where.not(id: id).update_all(is_default: false) if is_default? && is_default_changed?
  end
end
