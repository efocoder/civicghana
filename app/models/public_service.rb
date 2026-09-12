class PublicService < ApplicationRecord
  include CatalogTranslatable
  belongs_to :institution
  belongs_to :organizational_unit, optional: true
  has_many :process_steps, -> { order(:position) }, dependent: :restrict_with_error
  has_many :service_rules, dependent: :restrict_with_error
  has_many :action_paths, -> { order(:sequence) }, dependent: :restrict_with_error
  has_many :portal_statuses, dependent: :restrict_with_error
  has_many :service_sources, dependent: :destroy
  has_many :sources, through: :service_sources
  has_many :action_resources, dependent: :restrict_with_error
  has_many :source_chunks, dependent: :destroy
  has_many :service_variants, -> { order(:position) }, dependent: :restrict_with_error
  has_many :requirements, -> { order(:position) }, dependent: :restrict_with_error
  has_many :service_fees, dependent: :restrict_with_error

  enum :support_level, { directory: "directory", guided: "guided", trackable: "trackable" }, validate: true

  normalizes :slug, with: ->(slug) { slug.strip.downcase }

  validates :name, :slug, :description, :service_category, presence: true
  validates :name, uniqueness: { scope: :institution_id }
  validates :slug, uniqueness: true, format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/ }
  validates :service_code, uniqueness: true, allow_blank: true
  validate :organizational_unit_belongs_to_agency
  validate :tracking_capabilities_are_consistent

  scope :available, -> { where(active: true) }

  alias_attribute :agency_id, :institution_id
  alias_method :agency, :institution
  alias_method :agency=, :institution=

  def tracking_available?
    trackable? && case_enabled?
  end

  private

  def organizational_unit_belongs_to_agency
    return unless organizational_unit && institution && organizational_unit.institution_id != institution_id

    errors.add(:organizational_unit, "must belong to the selected agency")
  end

  def tracking_capabilities_are_consistent
    errors.add(:case_enabled, "requires trackable support") if case_enabled? && !trackable?
    errors.add(:tracks_portal_milestones, "requires trackable support") if tracks_portal_milestones? && !trackable?
  end
end
