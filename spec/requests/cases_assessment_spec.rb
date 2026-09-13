require "rails_helper"

RSpec.describe "Cases", type: :request do
  before { Rails.application.load_seed }

  let(:service) { PublicService.find_by!(slug: "official-consolidated-search") }
  let(:tracking_steps) { service.process_steps.where("sequence >= 4").order(:sequence) }

  describe "GET /cases/new" do
    it "loads successfully" do
      get new_case_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Check your application")
      expect(response.body).to include("Assess my application")
    end

    it "displays all tracking milestones" do
      get new_case_path

      tracking_steps.each do |step|
        expect(response.body).to include(step.name)
      end
    end
  end

  describe "POST /cases" do
    let(:milestone_params) do
      tracking_steps.to_h { |step| [ step.id.to_s, "Pending" ] }
    end

    let(:valid_params) do
      {
        case: {
          public_service_id: service.id,
          application_completed_on: "2026-07-30",
          payment_date: "2026-07-27",
          portal_created_on: "2026-07-27",
          region: "Greater Accra"
        },
        case_observation: {
          observed_on: "2026-09-10",
          overall_status: ""
        },
        milestones: milestone_params
      }
    end

    it "creates a case and redirects to show" do
      post cases_path, params: valid_params

      expect(response).to redirect_to(case_path(Case.order(:created_at).last))
      follow_redirect!
      expect(response.body).to include("Application assessment")
    end

    it "creates a case with correct attributes" do
      expect {
        post cases_path, params: valid_params
      }.to change(Case, :count).by(1)

      kase = Case.order(:created_at).last
      expect(kase.public_service).to eq(service)
      expect(kase.application_completed_on).to eq(Date.new(2026, 7, 30))
      expect(kase.payment_date).to eq(Date.new(2026, 7, 27))
      expect(kase.portal_created_on).to eq(Date.new(2026, 7, 27))
      expect(kase.region).to eq("Greater Accra")
    end

    it "creates a portal observation with milestones" do
      expect {
        post cases_path, params: valid_params
      }.to change(CaseObservation, :count).by(1)
        .and change(CaseMilestoneObservation, :count).by(4)

      observation = CaseObservation.order(:created_at).last
      expect(observation.observation_type).to eq("portal")
      expect(observation.observed_on).to eq(Date.new(2026, 9, 10))
      expect(observation.case_milestone_observations.count).to eq(4)
    end

    it "stores all milestone statuses" do
      post cases_path, params: valid_params

      observation = CaseObservation.order(:created_at).last
      milestones = observation.case_milestone_observations.includes(:process_step).sort_by { |m| m.process_step.sequence }

      expect(milestones[0].process_step.name).to eq("Quality Control and Coordinate Entry")
      expect(milestones[0].status).to eq("Pending")
      expect(milestones[1].process_step.name).to eq("Records Verification")
      expect(milestones[1].status).to eq("Pending")
      expect(milestones[2].process_step.name).to eq("Report Preparation")
      expect(milestones[2].status).to eq("Pending")
      expect(milestones[3].process_step.name).to eq("Vetting and Final Approval")
      expect(milestones[3].status).to eq("Pending")
    end

    it "re-renders form with validation errors for invalid input" do
      post cases_path, params: {
        case: {
          public_service_id: service.id,
          application_completed_on: "",
          region: ""
        },
        case_observation: {
          observed_on: ""
        },
        milestones: {}
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /cases/:id" do
    it "displays the full assessment" do
      kase = create(:case,
        public_service: service,
        application_completed_on: Date.new(2026, 7, 30),
        payment_date: Date.new(2026, 7, 27),
        portal_created_on: Date.new(2026, 7, 27),
        region: "Greater Accra")

      observation = create(:case_observation, case: kase, observed_on: Date.new(2026, 9, 10))

      tracking_steps.each do |step|
        create(:case_milestone_observation,
          case_observation: observation,
          process_step: step,
          status: step.name == "Quality Control and Coordinate Entry" ? "Pending" : "Not Completed")
      end

      get case_path(kase)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Application assessment")
      expect(response.body).to include("Published timeframe exceeded")
      expect(response.body).to include("Land Act, 2020 (Act 1036)")
      expect(response.body).to include("Section 222")
      expect(response.body).to include("Quality Control and Coordinate Entry")
      expect(response.body).to include("Records Verification")
      expect(response.body).to include("Report Preparation")
      expect(response.body).to include("Vetting and Final Approval")
      expect(response.body).to include("42 days")
      expect(response.body).to include("31 days")
    end
  end
end
