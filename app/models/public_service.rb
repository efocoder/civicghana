class PublicService < ApplicationRecord
  include CatalogTranslatable
  belongs_to :institution
  has_many :process_steps, -> { order(:position) }, dependent: :restrict_with_error
  has_many :service_rules, dependent: :restrict_with_error
  has_many :action_paths, -> { order(:sequence) }, dependent: :restrict_with_error
  has_many :portal_statuses, dependent: :restrict_with_error
  has_many :service_sources, dependent: :destroy
  has_many :sources, through: :service_sources
  has_many :action_resources, dependent: :restrict_with_error
  has_many :source_chunks, dependent: :destroy

  normalizes :slug, with: ->(slug) { slug.strip.downcase }

  validates :name, :slug, :description, :service_category, presence: true
  validates :name, uniqueness: { scope: :institution_id }
  validates :slug, uniqueness: true, format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/ }
  validates :service_code, uniqueness: true, allow_blank: true

  scope :available, -> { where(active: true) }

  alias_attribute :agency_id, :institution_id
  alias_method :agency, :institution
  alias_method :agency=, :institution=
end
