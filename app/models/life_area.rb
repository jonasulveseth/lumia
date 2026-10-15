# Användarens relation till ett livsområde: nulägesbild, fokusmål och skattning.
class LifeArea < ApplicationRecord
  belongs_to :user

  validates :area_key, inclusion: { in: -> (_) { Area.keys } }, uniqueness: { scope: :user_id }
  validates :rating, numericality: { in: 1..10 }, allow_nil: true

  def area = Area.find!(area_key)
  delegate :name, :icon, :color, :description, to: :area
  def to_param = area_key
end
