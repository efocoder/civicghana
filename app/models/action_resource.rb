class ActionResource < ApplicationRecord
  include CatalogTranslatable
  belongs_to :institution
  belongs_to :source, optional: true
  belongs_to :public_service, optional: true

  enum :resource_type, {
    contact: "contact",
    complaint: "complaint",
    rti: "rti",
    administrative_redress: "administrative_redress"
  }, validate: true

  validates :name, :purpose, presence: true
  validates :url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }, allow_blank: true

  scope :active, -> { where(active: true) }
  scope :verified, -> { where.not(last_verified_at: nil) }
  scope :for_type, ->(type) { where(resource_type: type) }
  scope :ordered, -> { order(:position, :name) }

  alias_attribute :agency_id, :institution_id
  alias_method :agency, :institution
  alias_method :agency=, :institution=
end
