require "digest"

verified_at = Time.zone.local(2026, 9, 10, 12)

source_attributes = {
  land_act: {
    publisher: "Republic of Ghana",
    title: "Land Act, 2020 (Act 1036)",
    url: "https://oasl.gov.gh/wp-content/uploads/2023/07/LAND-ACT-2020-ACT-1036.pdf",
    authority_type: :legislation,
    authority_level: "primary",
    section_label: "Section 222",
    summary: "The Lands Commission shall issue the result of an official search within fourteen days after payment of the prescribed fees.",
    effective_from: Date.new(2020, 12, 23)
  },
  status_portal: {
    publisher: "Ghana Lands Commission",
    title: "Online Services - Application Status",
    url: "https://onlineservices.lc.gov.gh/vDW0_zcD",
    authority_type: :official_service,
    authority_level: "official",
    summary: "Official public page for checking an application's visible status using its job number."
  },
  lands_contact: {
    publisher: "Ghana Lands Commission",
    title: "Lands Commission Official Website",
    url: "https://www.lc.gov.gh/",
    authority_type: :official_service,
    authority_level: "official",
    summary: "Official Lands Commission website for general institutional information and contact routes."
  },
  complaints: {
    publisher: "Ghana Lands Commission",
    title: "Online Services - Feedback & Complaints",
    url: "https://onlineservices.lc.gov.gh/pt886_oXS",
    authority_type: :official_service,
    authority_level: "official",
    summary: "Official channel for feedback and complaints about Lands Commission services."
  },
  rti: {
    publisher: "Right to Information Commission",
    title: "About the Right to Information Commission",
    url: "https://rtic.gov.gh/about/",
    authority_type: :regulator_guidance,
    authority_level: "regulatory",
    summary: "Official information about Ghana's access-to-information oversight body and mandate."
  },
  chraj: {
    publisher: "Commission on Human Rights and Administrative Justice",
    title: "Administrative Justice Mandate",
    url: "https://chraj.gov.gh/administrative-justice-mandate/",
    authority_type: :oversight_body,
    authority_level: "oversight",
    summary: "Official guidance about CHRAJ's administrative-justice mandate."
  }
}

sources = source_attributes.transform_values do |attributes|
  source = Source.find_or_initialize_by(url: attributes.fetch(:url))
  source.update!({
    **attributes,
    verified_at: verified_at,
    content_hash: Digest::SHA256.hexdigest(attributes.fetch(:summary)),
    active: true
  })
  source
end

ghana = Country.find_or_initialize_by(code: "GH")
ghana.update!({ name: "Ghana", active: true })

lands_commission = Institution.find_or_initialize_by(country: ghana, name: "Lands Commission")
lands_commission.update!({
  slug: "lands-commission",
  short_name: "LC",
  official_url: "https://www.lc.gov.gh/",
  description: "The public institution responsible for managing and regulating interests in land in Ghana.",
  active: true
})

units = [
  ["GENERAL", "General Services"],
  ["SMD", "Survey & Mapping Division"],
  ["LVD", "Land Valuation Division"],
  ["PVLMD", "Public & Vested Lands Management Division"],
  ["LRD", "Land Registration Division"]
].each_with_index.to_h do |(code, name), position|
  unit = OrganizationalUnit.find_or_initialize_by(institution: lands_commission, code: code)
  unit.update!(name: name, description: "Lands Commission organizational unit.", position: position + 1, active: true)
  [code, unit]
end

official_search = PublicService.find_or_initialize_by(slug: "official-consolidated-search")
official_search.update!({
  institution: lands_commission,
  organizational_unit: units.fetch("GENERAL"),
  name: "Official / Consolidated Search",
  description: "Check registered land information through the Lands Commission's official search service and understand the published timeframe for receiving a result.",
  service_category: "land_services",
  service_code: "LC-OFFICIAL-SEARCH",
  support_level: :trackable,
  case_enabled: true,
  tracks_portal_milestones: true,
  requires_region: true,
  active: true
})

[
  ["registration-of-title", "Registration of Title", "LC-TITLE-REG", "LRD", "Registration of land title through the Lands Commission."],
  ["deed-registration", "Deed Registration", "LC-DEED-REG", "LRD", "Registration of a deed through the Lands Commission."],
  ["plan-approval", "Plan Approval", "LC-PLAN-APPROVAL", "SMD", "Plan approval service provided by the Survey & Mapping Division."],
  ["stamping-guidance", "Stamping / Stamp-Duty Guidance", "LC-STAMPING", "LVD", "Official service information relating to valuation and stamp-duty processes."]
].each do |slug, name, code, unit_code, description|
  service = PublicService.find_or_initialize_by(slug: slug)
  service.update!(
    institution: lands_commission,
    organizational_unit: units.fetch(unit_code),
    name: name,
    description: description,
    service_category: "land_services",
    service_code: code,
    support_level: :directory,
    case_enabled: false,
    tracks_portal_milestones: false,
    requires_region: false,
    active: true
  )
  ensure_catalog_translation(service, attributes: { name: service.name, description: service.description }) if defined?(ensure_catalog_translation)
  link = ServiceSource.find_or_initialize_by(public_service: service, source: sources.fetch(:lands_contact))
  link.update!(purpose: "Official Lands Commission service information", primary: true)
end

def ensure_catalog_translation(record, locale: "en", attributes: {})
  translation = record.catalog_translations.find_or_initialize_by(locale: locale)
  translation.update!(attributes)
end

ensure_catalog_translation(lands_commission, attributes: { name: lands_commission.name, description: lands_commission.description })
ensure_catalog_translation(official_search, attributes: { name: official_search.name, description: official_search.description })

# The catalogue entries above remain directory-only until authoritative,
# service-specific requirements or fees have been curated. Seeds deliberately
# avoid turning broad institutional descriptions into invented guidance.

CivicRoute::REGIONS.each do |name|
  Region.find_or_create_by!(country: ghana, code: name.parameterize, name: name) { |r| r.active = true }
end

[["pending", "Pending"], ["completed", "Completed"], ["not-completed", "Not Completed"]].each_with_index do |(code, name), index|
  status = PortalStatus.find_or_initialize_by(public_service: official_search, code: code)
  status.update!(name: name, position: index, active: true)
end

CivicRoute::EVIDENCE_SOURCES.each do |code, name|
  evidence_source = EvidenceSource.find_or_initialize_by(code: code.to_s)
  evidence_source.update!(name: name, active: true)
end

CivicRoute::PROGRESS_CLAIMS.each do |code, name|
  progress_claim = ProgressClaim.find_or_initialize_by(code: code.to_s)
  progress_claim.update!(name: name, active: true)
end

[
  [1, "Submit and pay", "Submit the official-search request and pay the prescribed fees.", sources.fetch(:land_act)],
  [2, "Track the public status", "Use the Lands Commission application-status page to observe the milestone currently visible to you.", sources.fetch(:status_portal)],
  [3, "Receive the search result", "The published rule says the official-search result should be issued within fourteen days after payment.", sources.fetch(:land_act)]
].each do |position, name, description, source|
  step = ProcessStep.find_or_initialize_by(public_service: official_search, position: position)
  step.update!({ name: name, description: description, source: source, active: false })
end

[
  [1, "Quality Control and Coordinate Entry", "First tracking milestone shown on the public portal.", sources.fetch(:status_portal)],
  [2, "Records Verification", "Second tracking milestone shown on the public portal.", sources.fetch(:status_portal)],
  [3, "Report Preparation", "Third tracking milestone shown on the public portal.", sources.fetch(:status_portal)],
  [4, "Vetting and Final Approval", "Fourth tracking milestone shown on the public portal.", sources.fetch(:status_portal)]
].each do |position, name, description, source|
  step = ProcessStep.find_or_initialize_by(public_service: official_search, position: position + 3)
  step.update!({ name: name, description: description, source: source, active: true })
end

duration_rule = ServiceRule.find_or_initialize_by(
  public_service: official_search,
  rule_type: :expected_duration_days,
  effective_from: Date.new(2020, 12, 23)
)
duration_rule.update!({
  source: sources.fetch(:land_act),
  value: 14,
  unit: "days after payment",
  name: "Official search result",
  description: "Published duration for issuing an official search result after the prescribed fees are paid.",
  verified_at: verified_at,
  active: true,
  anchor_event: :payment
})

[
  [1, :check, "Check the official rule", "Compare the date of payment with the verified official-search duration.", sources.fetch(:land_act)],
  [2, :verify, "Verify the visible status", "Check the milestone currently shown on the official application-status page.", sources.fetch(:status_portal)],
  [3, :agency_follow_up, "Contact the Lands Commission", "Use the official feedback and complaints channel for a neutral follow-up.", sources.fetch(:complaints)],
  [4, :information_request, "Learn about an information request", "Use RTI guidance when you need specific information held by the institution.", sources.fetch(:rti)],
  [5, :external_escalation, "Review administrative-justice guidance", "Consider CHRAJ guidance after reasonable attempts to resolve the issue with the institution.", sources.fetch(:chraj)]
].each do |sequence, action_type, title, instructions, source|
  path = ActionPath.find_or_initialize_by(public_service: official_search, sequence: sequence)
  path.attributes = {
    action_type: action_type,
    title: title,
    instructions: instructions,
    source: source,
    conditions: {},
    active: true
  }
  path.save!
end

[
  [:contact, "Lands Commission — Contact & Enquiries", "Request status clarification or an update on your application.", "https://www.lc.gov.gh/", sources.fetch(:lands_contact)],
  [:complaint, "Lands Commission — Feedback & Complaints", "Formally report an unresolved service issue or delay.", "https://onlineservices.lc.gov.gh/pt886_oXS", sources.fetch(:complaints)],
  [:rti, "Right to Information Commission", "Request access to information or records held by a public institution.", "https://rtic.gov.gh/about/", sources.fetch(:rti)],
  [:administrative_redress, "CHRAJ — Administrative Justice", "Seek administrative-justice guidance after unsuccessful attempts to resolve with the institution.", "https://chraj.gov.gh/administrative-justice-mandate/", sources.fetch(:chraj)]
].each do |resource_type, name, purpose, url, source|
  resource = ActionResource.find_or_initialize_by(public_service: official_search, resource_type: resource_type)
  resource.update!({
    institution: lands_commission,
    name: name,
    purpose: purpose,
    url: url,
    source: source,
    last_verified_at: verified_at,
    instructions: purpose,
    position: %i[contact complaint rti administrative_redress].index(resource_type) + 1,
    active: true
  })
end

sources.each do |key, source|
  link = ServiceSource.find_or_initialize_by(public_service: official_search, source: source)
  link.update!(purpose: key.to_s.humanize, primary: key == :land_act)
end

[
  [
    sources.fetch(:land_act),
    "The Lands Commission shall issue the result of an official search within fourteen days after payment of the prescribed fees.",
    "Section 222",
    1,
    "Official Search Duration",
    nil,
    "Section 222"
  ],
  [
    sources.fetch(:land_act),
    "The Land Act, 2020 (Act 1036) governs land administration in Ghana. It establishes the Lands Commission's responsibilities for land registration, survey, valuation, and the resolution of land disputes. The Act sets out the procedures for conducting official searches of registered land.",
    nil,
    2,
    "Land Administration Overview",
    nil,
    nil
  ],
  [
    sources.fetch(:land_act),
    "An official search is a request to the Lands Commission to verify the recorded ownership, encumbrances, and legal status of a parcel of registered land. The search result is a formal document issued by the Commission.",
    nil,
    3,
    "What Is an Official Search",
    nil,
    nil
  ],
  [
    sources.fetch(:status_portal),
    "The Lands Commission Online Services portal allows applicants to check the current status of their application using the assigned job number. The portal displays milestone stages including Quality Control and Coordinate Entry, Records Verification, Report Preparation, and Vetting and Final Approval.",
    nil,
    1,
    "Portal Application Tracking",
    nil,
    nil
  ],
  [
    sources.fetch(:status_portal),
    "The public portal displays milestone statuses such as Pending, Completed, and Not Completed. These statuses reflect what is publicly visible and may not represent the institution's actual internal processing status.",
    nil,
    2,
    "Understanding Portal Statuses",
    nil,
    nil
  ],
  [
    sources.fetch(:complaints),
    "The Lands Commission provides an official Feedback & Complaints channel through its Online Services platform. Citizens can use this channel to report service issues, request clarification on application status, or formally document delays in processing.",
    nil,
    1,
    "Filing a Complaint",
    nil,
    nil
  ],
  [
    sources.fetch(:complaints),
    "When filing a complaint with the Lands Commission, include your application details, relevant dates, and a clear description of the issue. The Commission may request your name, phone number, region, and reference number.",
    nil,
    2,
    "Complaint Requirements",
    nil,
    nil
  ],
  [
    sources.fetch(:rti),
    "The Right to Information Act, 2019 (Act 989) gives citizens the right to access information held by public institutions. The Right to Information Commission oversees compliance and can assist when information requests are denied or delayed.",
    nil,
    1,
    "RTI Overview",
    nil,
    nil
  ],
  [
    sources.fetch(:rti),
    "An RTI request is appropriate when you need access to specific recorded information held by a public institution, such as the current recorded status of your application, what administrative step remains outstanding, or what record explains a delay. RTI is not a complaint mechanism.",
    nil,
    2,
    "When to Use RTI",
    nil,
    nil
  ],
  [
    sources.fetch(:chraj),
    "The Commission on Human Rights and Administrative Justice (CHRAJ) has a mandate to investigate complaints about the administrative actions of public institutions. Citizens can approach CHRAJ when attempts to resolve issues directly with the institution have been unsuccessful.",
    nil,
    1,
    "CHRAJ Mandate",
    nil,
    nil
  ],
  [
    sources.fetch(:chraj),
    "CHRAJ handles complaints about administrative injustice, unfair treatment, delay, omission, or abuse of power by public institutions. Before approaching CHRAJ, citizens are generally expected to have first attempted resolution through the institution's own channels.",
    nil,
    2,
    "When to Approach CHRAJ",
    nil,
    nil
  ]
].each do |source, content, section_label, position, heading, page_number, provision|
  chunk = SourceChunk.find_or_initialize_by(source: source, position: position)
  chunk.update!(public_service: official_search, content: content, section_label: section_label,
    heading: heading, page_number: page_number, provision: provision, active: true)
end

tracking_steps = official_search.process_steps.active

demo_case = Case.find_or_create_by!(
  public_service: official_search,
  application_completed_on: Date.new(2026, 7, 30)
) do |c|
  c.region = "Greater Accra"
  c.payment_date = Date.new(2026, 7, 27)
  c.portal_created_on = Date.new(2026, 7, 27)
end

unless demo_case.case_observations.any?
  obs1 = demo_case.case_observations.create!(
    observation_type: :portal,
    observed_on: Date.new(2026, 8, 20),
    overall_status: "In Progress"
  )
  tracking_steps.each_with_index do |step, i|
    obs1.case_milestone_observations.create!(
      process_step: step,
      status: i == 0 ? "Pending" : "Not Completed"
    )
  end

  demo_case.case_observations.create!(
    observation_type: :phone,
    observed_on: Date.new(2026, 9, 5),
    progress_claim: :near_completion,
    summary: "Institutional phone update indicates near completion"
  )

  obs2 = demo_case.case_observations.create!(
    observation_type: :portal,
    observed_on: Date.new(2026, 9, 10),
    overall_status: "In Progress"
  )
  tracking_steps.each_with_index do |step, i|
    obs2.case_milestone_observations.create!(
      process_step: step,
      status: i == 0 ? "Pending" : "Not Completed"
    )
  end
end
