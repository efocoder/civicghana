class Country < ApplicationRecord
  has_many :institutions, dependent: :restrict_with_error

  normalizes :code, with: ->(code) { code.strip.upcase }

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true, length: { is: 2 }
end
