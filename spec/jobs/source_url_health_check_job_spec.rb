require "rails_helper"

RSpec.describe SourceUrlHealthCheckJob, type: :job do
  it "records an unavailable URL for human review without deactivating or re-verifying the source" do
    source = create(:source, active: true, last_verified_at: 1.month.ago, review_required: false)
    verified_at = source.last_verified_at
    response = Net::HTTPServiceUnavailable.new("1.1", "503", "Unavailable")
    allow(Net::HTTP).to receive(:start).and_yield(double(head: response))

    described_class.perform_now

    source.reload
    expect(source).to be_active
    expect(source).to be_review_required
    expect(source.http_status).to eq(503)
    expect(source.last_checked_at).to be_present
    expect(source.last_verified_at).to be_within(1.second).of(verified_at)
  end
end
