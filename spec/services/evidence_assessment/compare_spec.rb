require "rails_helper"

RSpec.describe EvidenceAssessment::Compare do
  before { Rails.application.load_seed }

  let(:service) { PublicService.find_by!(slug: "official-consolidated-search") }
  let(:tracking_steps) { service.process_steps.where("sequence >= 4").order(:sequence) }

  def create_portal_snapshot(kase, date, statuses)
    observation = create(:case_observation, :portal, case: kase, observed_on: date)
    tracking_steps.each_with_index do |step, i|
      create(:case_milestone_observation,
        case_observation: observation,
        process_step: step,
        status: statuses[i] || "Not Completed")
    end
    observation
  end

  describe "no comparison" do
    it "returns no_comparison when only one portal observation exists" do
      kase = create(:case, public_service: service, application_completed_on: Date.new(2026, 7, 30))
      create_portal_snapshot(kase, Date.new(2026, 8, 20), [ "Pending", "Not Completed", "Not Completed", "Not Completed" ])

      result = described_class.call(case_record: kase)

      expect(result.status).to eq(:no_comparison)
    end
  end

  describe "portal unchanged" do
    it "returns portal_unchanged when two portal snapshots are identical" do
      kase = create(:case, public_service: service, application_completed_on: Date.new(2026, 7, 30))
      create_portal_snapshot(kase, Date.new(2026, 8, 20), [ "Pending", "Not Completed", "Not Completed", "Not Completed" ])
      create_portal_snapshot(kase, Date.new(2026, 9, 10), [ "Pending", "Not Completed", "Not Completed", "Not Completed" ])

      result = described_class.call(case_record: kase)

      expect(result.status).to eq(:portal_unchanged)
      expect(result.portal_changed).to be false
    end
  end

  describe "consistent" do
    it "returns consistent when portal and phone update agree" do
      kase = create(:case, public_service: service, application_completed_on: Date.new(2026, 7, 30))
      create_portal_snapshot(kase, Date.new(2026, 8, 20), [ "Pending", "Not Completed", "Not Completed", "Not Completed" ])
      create(:case_observation, :at_milestone,
        case: kase,
        observed_on: Date.new(2026, 8, 25),
        reported_process_step: tracking_steps.first)

      result = described_class.call(case_record: kase)

      expect(result.status).to eq(:consistent)
    end
  end

  describe "possible discrepancy" do
    it "returns possible_discrepancy when phone indicates later progress" do
      kase = create(:case, public_service: service, application_completed_on: Date.new(2026, 7, 30))
      create_portal_snapshot(kase, Date.new(2026, 8, 20), [ "Pending", "Not Completed", "Not Completed", "Not Completed" ])
      create(:case_observation, :near_completion,
        case: kase,
        observed_on: Date.new(2026, 9, 5))

      result = described_class.call(case_record: kase)

      expect(result.status).to eq(:possible_discrepancy)
    end

    it "returns possible_discrepancy when completed but portal shows incomplete" do
      kase = create(:case, public_service: service, application_completed_on: Date.new(2026, 7, 30))
      create_portal_snapshot(kase, Date.new(2026, 8, 20), [ "Pending", "Not Completed", "Not Completed", "Not Completed" ])
      create(:case_observation,
        observation_type: :phone,
        case: kase,
        observed_on: Date.new(2026, 8, 25),
        progress_claim: :completed,
        summary: "Done")

      result = described_class.call(case_record: kase)

      expect(result.status).to eq(:possible_discrepancy)
    end
  end

  describe "possible stale public status" do
    it "returns possible_stale_public_status when portal unchanged after later update" do
      kase = create(:case, public_service: service, application_completed_on: Date.new(2026, 7, 30))
      create_portal_snapshot(kase, Date.new(2026, 8, 20), [ "Pending", "Not Completed", "Not Completed", "Not Completed" ])
      create(:case_observation, :near_completion,
        case: kase,
        observed_on: Date.new(2026, 9, 5))
      create_portal_snapshot(kase, Date.new(2026, 9, 10), [ "Pending", "Not Completed", "Not Completed", "Not Completed" ])

      result = described_class.call(case_record: kase)

      expect(result.status).to eq(:possible_stale_public_status)
    end
  end

  describe "insufficient information" do
    it "returns insufficient_information when progress_claim is unspecified" do
      kase = create(:case, public_service: service, application_completed_on: Date.new(2026, 7, 30))
      create_portal_snapshot(kase, Date.new(2026, 8, 20), [ "Pending", "Not Completed", "Not Completed", "Not Completed" ])
      create(:case_observation, :phone,
        case: kase,
        observed_on: Date.new(2026, 8, 25),
        progress_claim: :unspecified,
        summary: "They said they are working on it")

      result = described_class.call(case_record: kase)

      expect(result.status).to eq(:insufficient_information)
    end
  end
end
