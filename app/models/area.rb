# Ett livsområde (Hälsa, Kost, Sinne …) ur config/lumia/areas.yml.
# Användarens egen relation till området ligger i LifeArea.
class Area
  include YamlCatalog
  catalog_file :areas

  def name = I18n.t("lumia.areas.#{key}.name")
  def description = I18n.t("lumia.areas.#{key}.description")
  def topics = I18n.t("lumia.areas.#{key}.topics")
  def icon = attributes[:icon]
  def color = attributes[:color]
  def metrics = Array(attributes[:metrics]).filter_map { |k| Metric.find(k) }
  def approaches = Approach.all.select { |a| a.area_key == key }
end
