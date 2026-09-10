class PublicService < ApplicationRecord
  belongs_to :institution
  has_many :process_steps, -> { order(:sequence) }, dependent: :restrict_with_error
  has_many :service_rules, dependent: :restrict_with_error
  has_many :action_paths, -> { order(:sequence) }, dependent: :restrict_with_error

  normalizes :slug, with: ->(slug) { slug.strip.downcase }

  validates :name, :slug, :description, :service_category, presence: true
  validates :name, uniqueness: { scope: :institution_id }
  validates :slug, uniqueness: true, format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/ }
end
