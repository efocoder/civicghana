require "rails_helper"

RSpec.describe "Evidence recording", type: :request do
  before { Rails.application.load_seed }

  let(:service) { PublicService.find_by!(slug: "official-consolidated-search") }
  let(:tracking_steps) { service.process_steps.where("sequence >= 4").order(:sequence) }
  let(:kase) do
    create(:case,
      public_service: service,
      application_completed_on: Date.new(2026, 7, 30),
      payment_date: Date.new(2026, 7, 27),
      portal_created_on: Date.new(2026, 7, 27),
      region: "Greater Accra")
  end

  before do
    observation = create(:case_observation, :portal, case: kase, observed_on: Date.new(2026, 8, 20))
    tracking_steps.each do |step|
      create(:case_milestone_observation,
        case_observation: observation,
        process_step: step,
        status: "Pending")
    end
  end

  describe "GET /cases/:case_id/observations/new" do
    it "loads successfully" do
      get new_case_observation_path(kase)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Record an update")
    end

    it "displays all evidence source options" do
      get new_case_observation_path(kase)

      expect(response.body).to include("Public service portal")
      expect(response.body).to include("Phone call")
      expect(response.body).to include("In-person conversation")
      expect(response.body).to include("Email")
      expect(response.body).to include("Letter")
      expect(response.body).to include("SMS notification")
    end
  end

  describe "POST /cases/:case_id/observations" do
    it "creates a phone observation" do
      expect {
        post case_observations_path(kase), params: {
          case_observation: {
            observation_type: "phone",
            observed_on: "2026-09-05",
            progress_claim: "near_completion",
            summary: "The officer said the application is at the final stage"
          }
        }
      }.to change(CaseObservation, :count).by(1)

      observation = CaseObservation.order(:created_at).last
      expect(observation.observation_type).to eq("phone")
      expect(observation.progress_claim).to eq("near_completion")
      expect(observation.summary).to include("final stage")
    end

    it "creates a new portal snapshot with milestones" do
      expect {
        post case_observations_path(kase), params: {
          case_observation: {
            observation_type: "portal",
            observed_on: "2026-09-10"
          },
          milestones: tracking_steps.to_h { |s| [ s.id.to_s, "Completed" ] }
        }
      }.to change(CaseObservation, :count).by(1)
        .and change(CaseMilestoneObservation, :count).by(4)

      observation = CaseObservation.order(:created_at).last
      expect(observation).to be_portal
      expect(observation.case_milestone_observations.count).to eq(4)
    end

    it "validates required fields" do
      post case_observations_path(kase), params: {
        case_observation: {
          observation_type: "phone",
          observed_on: "",
          progress_claim: "",
          summary: ""
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
