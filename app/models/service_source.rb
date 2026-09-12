class ServiceSource < ApplicationRecord
  belongs_to :public_service
  belongs_to :source

  validates :purpose, presence: true
  validates :source_id, uniqueness: { scope: :public_service_id }
end
