# Ett känt mätvärde ur config/lumia/metrics.yml. Provsvar som inte finns i
# katalogen sparas ändå som Measurement med egen etikett.
class Metric
  include YamlCatalog
  catalog_file :metrics

  def name = I18n.t("lumia.metrics.#{key}", default: key.humanize)
  def area_key = attributes[:area]
  def unit = attributes[:unit]
  def min = attributes[:min]
  def max = attributes[:max]
  def better = attributes[:better]
  def target = attributes[:target]
end
