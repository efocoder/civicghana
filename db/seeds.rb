require "digest"

verified_at = Time.zone.local(2026, 9, 10, 12)

source_attributes = {
  land_act: {
    publisher: "Republic of Ghana",
    title: "Land Act, 2020 (Act 1036)",
    url: "https://oasl.gov.gh/wp-content/uploads/2023/07/LAND-ACT-2020-ACT-1036.pdf",
    authority_type: :legislation,
    section_label: "Section 222",
    summary: "The Lands Commission shall issue the result of an official search within fourteen days after payment of the prescribed fees.",
    effective_from: Date.new(2020, 12, 23)
  },
  status_portal: {
    publisher: "Ghana Lands Commission",
    title: "Online Services - Application Status",
    url: "https://onlineservices.lc.gov.gh/vDW0_zcD",
    authority_type: :official_service,
    summary: "Official public page for checking an application's visible status using its job number."
  },
  lands_contact: {
    publisher: "Ghana Lands Commission",
    title: "Lands Commission Official Website",
    url: "https://www.lc.gov.gh/",
    authority_type: :official_service,
    summary: "Official Lands Commission website for general institutional information and contact routes."
  },
  complaints: {
    publisher: "Ghana Lands Commission",
    title: "Online Services - Feedback & Complaints",
    url: "https://onlineservices.lc.gov.gh/pt886_oXS",
    authority_type: :official_service,
    summary: "Official channel for feedback and complaints about Lands Commission services."
  },
  rti: {
    publisher: "Right to Information Commission",
    title: "About the Right to Information Commission",
    url: "https://rtic.gov.gh/about/",
    authority_type: :regulator_guidance,
    summary: "Official information about Ghana's access-to-information oversight body and mandate."
  },
  chraj: {
    publisher: "Commission on Human Rights and Administrative Justice",
    title: "Administrative Justice Mandate",
    url: "https://chraj.gov.gh/administrative-justice-mandate/",
    authority_type: :oversight_body,
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
  official_url: "https://www.lc.gov.gh/",
  description: "The public institution responsible for managing and regulating interests in land in Ghana.",
  active: true
})

official_search = PublicService.find_or_initialize_by(slug: "official-consolidated-search")
official_search.update!({
  institution: lands_commission,
  name: "Official / Consolidated Search",
  description: "Check registered land information through the Lands Commission's official search service and understand the published timeframe for receiving a result.",
  service_category: "land_services",
  active: true
})

def ensure_catalog_translation(record, locale: "en", attributes: {})
  translation = record.catalog_translations.find_or_initialize_by(locale: locale)
  translation.update!(attributes)
end

ensure_catalog_translation(lands_commission, attributes: { name: lands_commission.name, description: lands_commission.description })
ensure_catalog_translation(official_search, attributes: { name: official_search.name, description: official_search.description })

CivicRoute::REGIONS.each do |name|
  Region.find_or_create_by!(country: ghana, code: name.parameterize, name: name) { |r| r.active = true }
end

CivicRoute::PORTAL_STATUSES.each_with_index do |name, index|
  PortalStatus.find_or_create_by!(public_service: official_search, code: name.parameterize, name: name) do |s|
    s.position = index
    s.active = true
  end
end

CivicRoute::EVIDENCE_SOURCES.each do |code, name|
  EvidenceSource.find_or_create_by!(code: code.to_s, name: name) { |e| e.active = true }
end

CivicRoute::PROGRESS_CLAIMS.each do |code, name|
  ProgressClaim.find_or_create_by!(code: code.to_s, name: name) { |p| p.active = true }
end

[
  [1, "Submit and pay", "Submit the official-search request and pay the prescribed fees.", sources.fetch(:land_act)],
  [2, "Track the public status", "Use the Lands Commission application-status page to observe the milestone currently visible to you.", sources.fetch(:status_portal)],
  [3, "Receive the search result", "The published rule says the official-search result should be issued within fourteen days after payment.", sources.fetch(:land_act)]
].each do |sequence, name, description, source|
  step = ProcessStep.find_or_initialize_by(public_service: official_search, sequence: sequence)
  step.update!({ name: name, description: description, source: source })
end

[
  [1, "Quality Control and Coordinate Entry", "First tracking milestone shown on the public portal.", sources.fetch(:status_portal)],
  [2, "Records Verification", "Second tracking milestone shown on the public portal.", sources.fetch(:status_portal)],
  [3, "Report Preparation", "Third tracking milestone shown on the public portal.", sources.fetch(:status_portal)],
  [4, "Vetting and Final Approval", "Fourth tracking milestone shown on the public portal.", sources.fetch(:status_portal)]
].each do |sequence, name, description, source|
  step = ProcessStep.find_or_initialize_by(public_service: official_search, sequence: sequence + 3)
  step.update!({ name: name, description: description, source: source })
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
  resource = ActionResource.find_or_initialize_by(institution: lands_commission, resource_type: resource_type)
  resource.update!({
    name: name,
    purpose: purpose,
    url: url,
    source: source,
    last_verified_at: verified_at,
    active: true
  })
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
  SourceChunk.find_or_create_by!(source: source, position: position) do |chunk|
    chunk.content = content
    chunk.section_label = section_label
    chunk.heading = heading
    chunk.page_number = page_number
    chunk.provision = provision
  end
end

tracking_steps = official_search.process_steps.where("sequence >= 4").order(:sequence)

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

ActionResource.find_or_create_by!(institution: lands_commission, resource_type: :contact) do |r|
  r.name = "Lands Commission — Contact & Enquiries"
  r.purpose = "Request status clarification or an update on your application."
  r.url = "https://www.lc.gov.gh/"
  r.source = sources.fetch(:lands_contact)
  r.last_verified_at = verified_at
  r.active = true
end
