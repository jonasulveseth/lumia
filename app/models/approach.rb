# En skola, strategi eller ett ramverk (medelhavskost, stoicism, Deep Work …)
# ur config/lumia/approaches.yml. Ramverket i Lumia är detsamma för alla;
# det här är innehållet användaren väljer att luta sig mot.
class Approach
  include YamlCatalog
  catalog_file :approaches

  def name = I18n.t("lumia.approaches.#{key}.name")
  def description = I18n.t("lumia.approaches.#{key}.description")
  def area_key = attributes[:area].presence
  def area = area_key && Area.find(area_key)
  def general? = area_key.nil?
  def principles = attributes[:principles]

  def self.general = all.select(&:general?)
end
