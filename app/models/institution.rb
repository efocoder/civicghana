class Institution < ApplicationRecord
  include CatalogTranslatable
  belongs_to :country
  has_many :public_services, dependent: :restrict_with_error
  has_many :organizational_units, dependent: :restrict_with_error

  scope :active, -> { where(active: true) }

  alias_attribute :official_url, :website_url

  normalizes :slug, with: ->(slug) { slug.to_s.strip.downcase.presence }

  validates :name, :official_url, :description, presence: true
  validates :name, uniqueness: { scope: :country_id }
  validates :slug, uniqueness: true, allow_blank: true,
    format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/ }
  validates :official_url, format: URI::DEFAULT_PARSER.make_regexp(%w[http https])
end
