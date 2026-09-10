class Institution < ApplicationRecord
  belongs_to :country
  has_many :public_services, dependent: :restrict_with_error

  validates :name, :official_url, :description, presence: true
  validates :name, uniqueness: { scope: :country_id }
  validates :official_url, format: URI::DEFAULT_PARSER.make_regexp(%w[http https])
end
