require "digest"

def ensure_catalog_translation(record, locale: "en", attributes: {})
  translation = record.catalog_translations.find_or_initialize_by(locale: locale)
  translation.update!(attributes)
end

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
  client_charter: {
    publisher: "Ghana Lands Commission",
    title: "Lands Commission Client Service Charter",
    url: "https://www.lc.gov.gh/",
    authority_type: :official_service,
    authority_level: "official",
    summary: "Client Service Charter publishing service targets for Lands Commission registration services."
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
    review_due_at: verified_at + 6.months,
    review_required: false,
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
  [ "GENERAL", "General Services" ],
  [ "SMD", "Survey & Mapping Division" ],
  [ "LVD", "Land Valuation Division" ],
  [ "PVLMD", "Public & Vested Lands Management Division" ],
  [ "LRD", "Land Registration Division" ]
].each_with_index.to_h do |(code, name), position|
  unit = OrganizationalUnit.find_or_initialize_by(institution: lands_commission, code: code)
  unit.update!(name: name, description: "Lands Commission organizational unit.", position: position + 1, active: true)
  ensure_catalog_translation(unit, attributes: { name: unit.name, description: unit.description })
  [ code, unit ]
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
  [ "registration-of-title", "Registration of Title", "LC-TITLE-REG", "LRD", "Registration of land title through the Lands Commission." ],
  [ "deed-registration", "Deed Registration", "LC-DEED-REG", "LRD", "Registration of a deed through the Lands Commission." ],
  [ "plan-approval", "Plan Approval", "LC-PLAN-APPROVAL", "SMD", "Plan approval service provided by the Survey & Mapping Division." ],
  [ "stamping-guidance", "Stamping / Stamp-Duty Guidance", "LC-STAMPING", "LVD", "Official service information relating to valuation and stamp-duty processes." ]
].each do |slug, name, code, unit_code, description|
  service = PublicService.find_or_initialize_by(slug: slug)
  service.update!(
    institution: lands_commission,
    organizational_unit: units.fetch(unit_code),
    name: (slug == "registration-of-title" ? "First Registration of Title to Land" : name),
    description: description,
    service_category: "land_services",
    service_code: code,
    support_level: :directory,
    case_enabled: false,
    tracks_portal_milestones: false,
    requires_region: false,
    active: true
  )
  ensure_catalog_translation(service, attributes: { name: service.name, description: service.description })
  french_names = {
    "registration-of-title" => "Première immatriculation d'un titre foncier",
    "deed-registration" => "Enregistrement d'un acte",
    "plan-approval" => "Approbation de plan",
    "stamping-guidance" => "Guide sur le timbre et les droits de timbre"
  }
  french_descriptions = {
    "registration-of-title" => "Service d'enregistrement d'un titre foncier auprès de la Commission des terres.",
    "deed-registration" => "Service d'enregistrement d'un acte auprès de la Commission des terres.",
    "plan-approval" => "Service d'approbation des plans assuré par la Division de l'arpentage et de la cartographie.",
    "stamping-guidance" => "Informations officielles sur l'évaluation et les procédures de timbre."
  }
  ensure_catalog_translation(service, locale: "fr", attributes: { name: french_names.fetch(slug), description: french_descriptions.fetch(slug) })
  twi_names = {
    "registration-of-title" => "Asase Title a Wɔde Di Kan Kyerɛw Din",
    "deed-registration" => "Deed Kyerɛw Din",
    "plan-approval" => "Plan Ho Mpene",
    "stamping-guidance" => "Stamp ne Stamp-Duty Akwankyerɛ"
  }
  twi_descriptions = {
    "registration-of-title" => "Ghana Lands Commission asase title kyerɛw din adwuma.",
    "deed-registration" => "Ghana Lands Commission deed kyerɛw din adwuma.",
    "plan-approval" => "Survey ne Mapping Division plan ho mpene adwuma.",
    "stamping-guidance" => "Aban akwankyerɛ a ɛfa valuation ne stamp-duty ho."
  }
  ensure_catalog_translation(service, locale: "tw", attributes: { name: twi_names.fetch(slug), description: twi_descriptions.fetch(slug) })
  link = ServiceSource.find_or_initialize_by(public_service: service, source: sources.fetch(:lands_contact))
  link.update!(purpose: "Official Lands Commission service information", primary: true)
end

ensure_catalog_translation(lands_commission, attributes: { name: lands_commission.name, description: lands_commission.description })
ensure_catalog_translation(official_search, attributes: { name: official_search.name, description: official_search.description })

# Curated French labels for the catalogue's primary public entry points. Legal
# source wording remains in its authoritative form.
ensure_catalog_translation(lands_commission, locale: "fr", attributes: { name: "Commission des terres du Ghana" })
ensure_catalog_translation(lands_commission, locale: "tw", attributes: { name: "Ghana Asase Boayikuo", description: "Aban adwumakuo a ɛhwɛ Ghana asase so." })
units.each_value do |unit|
  french_name = {
    "General Services" => "Services généraux",
    "Survey & Mapping Division" => "Division de l'arpentage et de la cartographie",
    "Land Valuation Division" => "Division de l'évaluation foncière",
    "Public & Vested Lands Management Division" => "Division de la gestion des terres publiques et dévolues",
    "Land Registration Division" => "Division de l'enregistrement foncier"
  }[unit.name] || unit.name
  ensure_catalog_translation(unit, locale: "fr", attributes: { name: french_name })
end
ensure_catalog_translation(official_search, locale: "fr", attributes: { name: "Recherche officielle / consolidée", description: "Demandez une recherche officielle pour vérifier les informations enregistrées sur une parcelle." })
ensure_catalog_translation(official_search, locale: "tw", attributes: { name: "Aban / Consolidated Search", description: "Fa Lands Commission official search hwɛ asase ho nsɛm a wɔakyerɛw na te bere a wɔatintim no ase." })

# The catalogue entries above remain directory-only until authoritative,
# service-specific requirements or fees have been curated. Seeds deliberately
# avoid turning broad institutional descriptions into invented guidance.

CivicRoute::REGIONS.each do |name|
  Region.find_or_create_by!(country: ghana, code: name.parameterize, name: name) { |r| r.active = true }
end

[ [ "pending", "Pending" ], [ "completed", "Completed" ], [ "not-completed", "Not Completed" ] ].each_with_index do |(code, name), index|
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
  [ 1, "Submit and pay", "Submit the official-search request and pay the prescribed fees.", sources.fetch(:land_act) ],
  [ 2, "Track the public status", "Use the Lands Commission application-status page to observe the milestone currently visible to you.", sources.fetch(:status_portal) ],
  [ 3, "Receive the search result", "The published rule says the official-search result should be issued within fourteen days after payment.", sources.fetch(:land_act) ]
].each do |position, name, description, source|
  step = ProcessStep.find_or_initialize_by(public_service: official_search, position: position)
  step.update!({ name: name, description: description, source: source, active: false })
  ensure_catalog_translation(step, attributes: { name: step.name, description: step.description })
  ensure_catalog_translation(step, locale: "tw", attributes: { name: { "Submit and pay" => "Mane na tua", "Track the public status" => "Hwɛ ɔmanfoɔ tebea", "Receive the search result" => "Nya search mmuaeɛ" }.fetch(step.name), description: step.description })
end

[
  [ 1, "Quality Control and Coordinate Entry", "First tracking milestone shown on the public portal.", sources.fetch(:status_portal) ],
  [ 2, "Records Verification", "Second tracking milestone shown on the public portal.", sources.fetch(:status_portal) ],
  [ 3, "Report Preparation", "Third tracking milestone shown on the public portal.", sources.fetch(:status_portal) ],
  [ 4, "Vetting and Final Approval", "Fourth tracking milestone shown on the public portal.", sources.fetch(:status_portal) ]
].each do |position, name, description, source|
  step = ProcessStep.find_or_initialize_by(public_service: official_search, position: position + 3)
  step.update!({ name: name, description: description, source: source, active: true })
  ensure_catalog_translation(step, attributes: { name: step.name, description: step.description })
  ensure_catalog_translation(step, locale: "tw", attributes: { name: { "Quality Control and Coordinate Entry" => "Quality Control ne Coordinate Entry", "Records Verification" => "Nkrataa mu nhwehwɛmu", "Report Preparation" => "Report siesie", "Vetting and Final Approval" => "Nhwehwɛmu ne Mpene a Etwa To" }.fetch(step.name), description: step.description })
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

# These two services are enabled for the same public tracking experience while
# their catalogue configuration is being expanded. Their records remain
# separate so they can be curated independently later.
[ "registration-of-title", "deed-registration" ].each do |slug|
  service = PublicService.find_by!(slug: slug)
  service.service_rules.where(rule_type: :expected_duration_days).delete_all
  service.update!(support_level: :trackable, case_enabled: true, tracks_portal_milestones: false, requires_region: true)
  journey = if slug == "deed-registration"
    [ "Prepare the registrable instrument", "Ensure the instrument is stamped and plotted", "Submit through the Client Service Access Unit", "Pay the applicable service bill", "Instrument presented to the Registry", "Registration processing", "Instrument entered and registered", "Certificate or registration endorsement", "Registered instrument available" ]
  else
    [ "Purchase and complete the appropriate registration forms", "Submit land documents to CSAU for vetting", "Pay the service bill", "Submit completed forms and payment evidence", "Records verification", "Vetting of application", "Site inspection where necessary", "Title plan preparation", "Publication in the daily newspapers", "Statutory 14-day objection period", "Preparation and issuance of Land Certificate", "Plotting of certificate" ]
  end
  journey.each_with_index do |step_name, index|
    source_step = official_search.process_steps.active[index % official_search.process_steps.active.length]
    step = ProcessStep.find_or_initialize_by(public_service: service, position: index + 1)
    step.update!(name: step_name, description: "Public journey step; this does not expose internal institutional workflow.", source: sources.fetch(:client_charter), active: true, position: index + 1)
  end
  rule = ServiceRule.find_or_initialize_by(public_service: service, rule_type: :service_charter_turnaround, effective_from: duration_rule.effective_from)
  rule.update!(source: sources.fetch(:client_charter), value: slug == "deed-registration" ? 10 : 65, unit: "working_days", name: "Published service target", description: "Published service target from the Lands Commission Client Service Charter.", verified_at: verified_at, active: true, anchor_event: :completed_application)
end

[
  [ 1, :check, "Check the official rule", "Compare the date of payment with the verified official-search duration.", sources.fetch(:land_act) ],
  [ 2, :verify, "Verify the visible status", "Check the milestone currently shown on the official application-status page.", sources.fetch(:status_portal) ],
  [ 3, :agency_follow_up, "Contact the Lands Commission", "Use the official feedback and complaints channel for a neutral follow-up.", sources.fetch(:complaints) ],
  [ 4, :information_request, "Learn about an information request", "Use RTI guidance when you need specific information held by the institution.", sources.fetch(:rti) ],
  [ 5, :external_escalation, "Review administrative-justice guidance", "Consider CHRAJ guidance after reasonable attempts to resolve the issue with the institution.", sources.fetch(:chraj) ]
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
  ensure_catalog_translation(path, attributes: { title: path.title, instructions: path.instructions })
end

[
  [ :contact, "Lands Commission — Contact & Enquiries", "Request status clarification or an update on your application.", "https://www.lc.gov.gh/", sources.fetch(:lands_contact) ],
  [ :complaint, "Lands Commission — Feedback & Complaints", "Formally report an unresolved service issue or delay.", "https://onlineservices.lc.gov.gh/pt886_oXS", sources.fetch(:complaints) ],
  [ :rti, "Right to Information Commission", "Request access to information or records held by a public institution.", "https://rtic.gov.gh/about/", sources.fetch(:rti) ],
  [ :administrative_redress, "CHRAJ — Administrative Justice", "Seek administrative-justice guidance after unsuccessful attempts to resolve with the institution.", "https://chraj.gov.gh/administrative-justice-mandate/", sources.fetch(:chraj) ]
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
  ensure_catalog_translation(resource, attributes: { name: resource.name, description: resource.purpose, instructions: resource.instructions })
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

deed_service = PublicService.find_by!(slug: "deed-registration")
title_service = PublicService.find_by!(slug: "registration-of-title")

# Production curation from the Lands Commission Deed & Title pack.
curated_sources = {
  deed_guide: [ "Lands Commission — Deed Registration", "https://www.lc.gov.gh/services/deed-registration/", "Official Deed Registration requirements and service information." ],
  title_guide: [ "Lands Commission — Registration (Title)", "https://www.lc.gov.gh/services/registration-title/", "Official title-registration requirements and conditional guidance." ],
  charter: [ "Lands Commission — Client Service Charter", "https://www.lc.gov.gh/storage/2023/12/CLIENT-SERVICE-CHARTER.pdf", "Published service targets and public journeys for Lands Commission services." ],
  fees: [ "Lands Commission — Fees & Charges", "https://www.lc.gov.gh/fees-charges/", "Current published Lands Commission fees and charges." ],
  contact: [ "Lands Commission — Contact Us", "https://www.lc.gov.gh/contact-us/", "Official Lands Commission contact information." ],
  payment: [ "Lands Commission Online Payment", "https://onlineservices.lc.gov.gh/tFSa_908", "Official payment page for bills generated by Lands Commission." ],
  deed_notice: [ "Lands Commission — Notice of Application for Registration of Deed", "https://www.lc.gov.gh/2025/11/07/land-act-2020-act-1036-notice-of-application-for-registration-of-deed-to-land-10/", "Notice explaining acknowledgement slips, priority and deed registration context." ]
}
curated_sources = curated_sources.each_with_object({}) do |(key, (title, url, summary)), memo|
  source = Source.find_or_initialize_by(url: url)
  source.update!(publisher: "Ghana Lands Commission", title: title, url: url, source_type: "official_service", authority_level: "official", summary: summary, last_verified_at: verified_at, review_due_at: verified_at + 6.months, review_required: false, content_hash: Digest::SHA256.hexdigest(summary), active: true)
  memo[key] = source
end

{ deed: deed_service, title: title_service }.each do |kind, service|
  source = kind == :deed ? curated_sources[:deed_guide] : curated_sources[:title_guide]
  ServiceSource.find_or_initialize_by(public_service: service, source: source).update!(purpose: "Official service requirements", primary: true)
  ServiceSource.find_or_initialize_by(public_service: service, source: curated_sources[:charter]).update!(purpose: "Published service target and journey", primary: false)
  ServiceSource.find_or_initialize_by(public_service: service, source: curated_sources[:fees]).update!(purpose: "Current fees and charges", primary: false)
  ServiceSource.find_or_initialize_by(public_service: service, source: curated_sources[:contact]).update!(purpose: "Official contact route", primary: false)
end

def ensure_requirement(service, source, position, category, title, mandatory)
  record = Requirement.find_or_initialize_by(public_service: service, position: position)
  record.update!(source: source, category: category, title: title, mandatory: mandatory, active: true, description: nil)
end

deed_requirements = [
  [ "information", "Date of instrument", true ], [ "information", "Nature/title of instrument", true ], [ "information", "Names and addresses of the parties", true ], [ "document", "Signatures of the parties", true ], [ "information", "Names and addresses of witnesses", true ], [ "document", "Signatures of witnesses", true ], [ "document", "Solicitor's stamp/seal", true ], [ "survey", "Approved plan", true ], [ "survey", "Owner name, land size and land location must correspond between the site plan and instrument", true ], [ "survey", "Required Licensed Surveyor and Survey and Mapping Division signatures and dates", true ], [ "document", "Back of the site plan signed by the parties", true ], [ "document", "Jurat where the document is thumb-printed or otherwise requires it", false ], [ "document", "Oath of Proof executed", true ], [ "document", "Deponent section completed by the grantor's witness", true ], [ "approval", "Planning comments/approval and layout extract for Stool Land", false ], [ "document", "Ghana Revenue Authority Tax Clearance Certificate", true ], [ "supporting_document", "Supporting/recited documents attached", true ], [ "payment", "Evidence of payment of ground rent where the transaction is not a first registration", false ], [ "document", "Instrument must be stamped and plotted before submission", true ]
]
deed_requirements.each_with_index { |(category, title, mandatory), i| ensure_requirement(deed_service, curated_sources[:deed_guide], i + 1, category, title, mandatory) }

title_requirements = deed_requirements[0, 14] + [ [ "approval", "Planning comments/approval with layout extract for Stool Land", false ], [ "supporting_document", "Supporting/recited documents attached", true ], [ "approval", "Evidence of concurrence/consent for relevant Stool Land or State Land subsequent transactions", false ], [ "supporting_document", "Transferor/grantor Land Certificate where applicable", false ], [ "supporting_document", "Certificate of Incorporation or statutory instrument establishing the corporate body", false ], [ "supporting_document", "Stamped Power of Attorney", false ], [ "supporting_document", "Notarization of Power of Attorney executed outside Ghana", false ] ]
title_requirements.each_with_index { |(category, title, mandatory), i| ensure_requirement(title_service, curated_sources[:title_guide], i + 1, category, title, mandatory) }

fees = [
  [ deed_service, curated_sources[:fees], "Application for deed registration for residential/commercial/civic/cultural/industrial land", 283.0, "published_schedule" ],
  [ title_service, curated_sources[:fees], "Application for First Registration", nil, "published_schedule" ],
  [ title_service, curated_sources[:fees], "Inspection within district or regional capital", 75.0, "published_schedule" ],
  [ title_service, curated_sources[:fees], "Inspection outside district or regional capital", 150.0, "published_schedule" ]
]
fees.each do |service, source, name, amount, calculation_type|
  fee = ServiceFee.find_or_initialize_by(public_service: service, source: source, name: name)
  fee.update!(amount: amount, currency: "GHS", calculation_type: calculation_type, description: amount ? "Published rate; transaction-specific charges may also apply." : "Published range; view the current official fees page for the applicable amount.", effective_from: verified_at.to_date, active: true)
end

resources = [
  [ "View official Deed Registration guide", "service_information", "https://www.lc.gov.gh/services/deed-registration/", nil, nil, 10 ], [ "View official Title Registration guide", "service_information", "https://www.lc.gov.gh/services/registration-title/", nil, nil, 10 ], [ "Check application status", "tracking", "https://onlineservices.lc.gov.gh/vDW0_zcD", nil, nil, 20 ], [ "View current fees and charges", "fee_reference", "https://www.lc.gov.gh/fees-charges/", nil, nil, 30 ], [ "Make payment", "payment", "https://onlineservices.lc.gov.gh/tFSa_908", nil, nil, 40 ], [ "Contact Lands Commission", "contact", "https://www.lc.gov.gh/contact-us/", "info@lc.gov.gh", "+233302429760", 50 ], [ "Submit feedback or complaint", "complaint", "https://onlineservices.lc.gov.gh/pt886_oXS", "complaints@lc.gov.gh", "0505578100", 60 ]
]
[ deed_service, title_service ].each do |service|
  resources.each do |name, type, url, email, phone, position|
    next if service == deed_service && name == "View official Title Registration guide"
    next if service == title_service && name == "View official Deed Registration guide"
    source = curated_sources.values.find { |s| s.url == url }
    resource = ActionResource.find_or_initialize_by(public_service: service, name: name)
    resource.update!(institution: lands_commission, source: source, resource_type: type, purpose: "Official action resource", url: url, email: email, phone: phone, instructions: (type == "tracking" ? "Use the Lands Commission Job Number. CivicRoute does not submit or scrape this tracker." : nil), position: position, last_verified_at: verified_at, active: true)
  end
end

chunks = [
  [ deed_service, curated_sources[:charter], "Published turnaround — Deed Registration", "The Lands Commission Client Service Charter publishes a service duration of 10 working days for Deed Registration under the Land Registration Division. CivicRoute treats this as a published service target, not an automatically inferred statutory deadline." ],
  [ deed_service, curated_sources[:charter], "Published journey — Deed Registration", "The Client Service Charter lists submission of the stamped and plotted document and payment of the service bill as the published public steps for Deed Registration. CivicRoute does not treat these as live internal workflow stages." ],
  [ deed_service, curated_sources[:deed_guide], "Instrument requirements — Deed Registration", "The official Deed Registration guide requires the instrument to identify its date and nature, the parties and witnesses with their signatures, include the solicitor's stamp or seal, an approved plan, required survey approvals, and supporting or recited documents. The site-plan owner name, land size and location must correspond with the instrument." ],
  [ deed_service, curated_sources[:deed_guide], "Conditional requirements — Deed Registration", "The official guide identifies requirements that depend on the transaction, including planning comments for Stool Land, a jurat where applicable, and evidence of ground-rent payment where the transaction is not a first registration. The guide also lists a Ghana Revenue Authority Tax Clearance Certificate." ],
  [ deed_service, curated_sources[:deed_notice], "Acknowledgement slip — Deed Registration", "A Lands Commission deed-registration notice states that an acknowledgement slip does not itself mean that the deed has been registered. Priority follows the order of presentation." ],
  [ title_service, curated_sources[:charter], "Published turnaround — First Registration of Title", "The Lands Commission Client Service Charter publishes a service duration of 65 working days for First Registration of Title to Land. CivicRoute must not apply this target to every type of title transaction." ],
  [ title_service, curated_sources[:charter], "Published journey — Application and payment", "The published First Registration journey begins with obtaining and completing the appropriate registration forms, submitting land documents to the Client Service Access Unit for vetting, paying the service bill, and submitting the completed form, documents and evidence of payment." ],
  [ title_service, curated_sources[:charter], "Published journey — Verification to certificate", "The Client Service Charter lists records verification, application vetting with site inspection where necessary, title-plan preparation, newspaper publication with an objection period, preparation and issuance of the Land Certificate, and plotting of the certificate." ],
  [ title_service, curated_sources[:charter], "Statutory objection period", "The published First Registration journey includes publication in the daily newspapers followed by a statutory 14-day period for objections. This step is part of the overall 65-working-day published service duration; CivicRoute must not add another 14 days." ],
  [ title_service, curated_sources[:title_guide], "Instrument requirements — Title Registration", "The official Registration (Title) guide requires a stamped instrument, date and nature of instrument, party and witness details and signatures, solicitor's stamp or seal, an approved plan, required survey signatures, and supporting or recited documents. Site-plan ownership, land size and location must correspond with the instrument." ],
  [ title_service, curated_sources[:title_guide], "Conditional requirements — Title Registration", "Depending on the transaction, official guidance may require planning approval, concurrence or consent, an existing Land Certificate, corporate-establishment documents, a stamped Power of Attorney, and notarization where a Power of Attorney was executed outside Ghana." ],
  [ nil, sources.fetch(:status_portal), "Official application tracker", "Lands Commission provides an online Check Application Status facility where a citizen can search using a Job Number. CivicRoute does not scrape this portal and relies only on information the citizen records from it." ],
  [ nil, sources.fetch(:complaints), "Official feedback and complaints channel", "Lands Commission provides an online Feedback & Complaints form requesting contact details, purpose, subject, description, region, related service and reference number." ]
]
chunks.each_with_index do |(service, source, section, content), index|
  next unless service
  chunk = SourceChunk.find_or_initialize_by(public_service: service, source: source, section_label: section)
  chunk.update!(content: content, position: index + 1, active: true)
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
