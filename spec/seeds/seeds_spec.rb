require "rails_helper"

RSpec.describe "Seed data", type: :model do
  before { Rails.application.load_seed }

  describe "Ghana and Lands Commission" do
    it "creates Ghana as an active country" do
      ghana = Country.find_by!(code: "GH")
      expect(ghana).to be_active
      expect(ghana.name).to eq("Ghana")
    end

    it "creates Lands Commission under Ghana" do
      lc = Institution.find_by!(name: "Lands Commission")
      expect(lc.country.code).to eq("GH")
      expect(lc).to be_active
      expect(lc.official_url).to be_present
    end
  end

  describe "Official / Consolidated Search service" do
    let(:service) { PublicService.find_by!(slug: "official-consolidated-search") }

    it "creates the service under Lands Commission" do
      expect(service.institution.name).to eq("Lands Commission")
      expect(service).to be_active
    end

    it "has three published process steps" do
      steps = service.process_steps.order(:sequence)
      expect(steps.count).to eq(3)
      expect(steps.map(&:sequence)).to eq([ 1, 2, 3 ])
      steps.each do |step|
        expect(step.source).to be_present
      end
    end

    it "has a verified 14-day expected_duration_days rule" do
      rule = ServiceRules::Resolver.call(
        public_service: service,
        rule_type: :expected_duration_days,
        on: Date.current
      )
      expect(rule.value).to eq(14)
      expect(rule.unit).to eq("days after payment")
      expect(rule.source).to be_present
    end

    it "has five action paths with source provenance" do
      paths = service.action_paths.order(:sequence)
      expect(paths.count).to eq(5)
      paths.each do |path|
        expect(path.source).to be_present
        expect(path).to be_active
      end
    end
  end

  describe "Sources" do
    it "creates the Land Act 2020 source" do
      source = Source.find_by!(url: "https://oasl.gov.gh/wp-content/uploads/2023/07/LAND-ACT-2020-ACT-1036.pdf")
      expect(source.title).to eq("Land Act, 2020 (Act 1036)")
      expect(source.authority_type).to eq("legislation")
      expect(source.section_label).to eq("Section 222")
      expect(source.publisher).to eq("Republic of Ghana")
      expect(source.effective_from).to eq(Date.new(2020, 12, 23))
      expect(source).to be_active
    end

    it "creates the application-status portal source" do
      source = Source.find_by!(url: "https://onlineservices.lc.gov.gh/vDW0_zcD")
      expect(source.authority_type).to eq("official_service")
    end

    it "creates the complaints portal source" do
      source = Source.find_by!(url: "https://onlineservices.lc.gov.gh/pt886_oXS")
      expect(source.authority_type).to eq("official_service")
    end

    it "creates the RTI source" do
      source = Source.find_by!(url: "https://rtic.gov.gh/about/")
      expect(source.authority_type).to eq("regulator_guidance")
    end

    it "creates the CHRAJ source" do
      source = Source.find_by!(url: "https://chraj.gov.gh/administrative-justice-mandate/")
      expect(source.authority_type).to eq("oversight_body")
    end
  end
end
