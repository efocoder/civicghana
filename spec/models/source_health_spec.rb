require "rails_helper"

RSpec.describe Source, type: :model do
  it "flags overdue and unavailable sources without conflating availability with verification" do
    source = build(:source, active: true, last_checked_at: Time.current, http_status: 503,
      review_due_at: 1.day.ago, review_required: true)

    expect(source).to be_url_unavailable
    expect(source).to be_verification_overdue
    expect(source).to be_review_required
    expect(source).to be_active
  end
end
