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

[
  [1, "Submit and pay", "Submit the official-search request and pay the prescribed fees.", sources.fetch(:land_act)],
  [2, "Track the public status", "Use the Lands Commission application-status page to observe the milestone currently visible to you.", sources.fetch(:status_portal)],
  [3, "Receive the search result", "The published rule says the official-search result should be issued within fourteen days after payment.", sources.fetch(:land_act)]
].each do |sequence, name, description, source|
  step = ProcessStep.find_or_initialize_by(public_service: official_search, sequence: sequence)
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
  active: true
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
