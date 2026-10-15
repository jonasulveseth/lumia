# Gemensam grund för katalogerna i config/lumia/*.yml (områden, ramverk,
# mätvärden). Posterna är vanliga Ruby-objekt, inte databasrader: strukturen
# är densamma för alla användare och versioneras med koden.
module YamlCatalog
  extend ActiveSupport::Concern

  included do
    attr_reader :key, :attributes
  end

  class_methods do
    def catalog_file(name)
      @catalog_file = Rails.root.join("config/lumia/#{name}.yml")
    end

    def all
      @all = nil if Rails.env.development?
      @all ||= YAML.load_file(@catalog_file).map { |key, attrs| new(key, attrs || {}) }.freeze
    end

    def keys = all.map(&:key)

    def find(key)
      all.find { |item| item.key == key.to_s }
    end

    def find!(key)
      find(key) || raise(ActiveRecord::RecordNotFound, "#{name} #{key} saknas i katalogen")
    end
  end

  def initialize(key, attributes)
    @key = key.to_s
    @attributes = attributes.with_indifferent_access
  end

  def to_param = key
  def ==(other) = other.class == self.class && other.key == key
end
