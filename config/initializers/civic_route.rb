module CivicRoute
  REGIONS = [
    "Ahafo",
    "Ashanti",
    "Bono",
    "Bono East",
    "Central",
    "Eastern",
    "Greater Accra",
    "North East",
    "Northern",
    "Oti",
    "Savannah",
    "Upper East",
    "Upper West",
    "Volta",
    "Western",
    "Western North"
  ].freeze

  PORTAL_STATUSES = [
    "Pending",
    "Completed",
    "Not Completed"
  ].freeze

  EVIDENCE_SOURCES = {
    portal: "Lands Commission portal",
    phone: "Phone call",
    in_person: "In-person conversation",
    email: "Email",
    letter: "Letter",
    sms: "SMS notification",
    other: "Other"
  }.freeze

  PROGRESS_CLAIMS = {
    unspecified: "No specific progress stage was given",
    public_milestone: "At one of the public portal milestones",
    near_completion: "Near completion / final stage",
    completed: "Completed / ready",
    other_claim: "Other"
  }.freeze

  EVIDENCE_PROVENANCE_LABELS = {
    portal: "Citizen-observed public portal",
    phone: "Citizen-recorded phone update",
    in_person: "Citizen-recorded in-person update",
    email: "Citizen-recorded email update",
    letter: "Citizen-recorded letter update",
    sms: "Citizen-recorded SMS notification",
    other: "Citizen-recorded update"
  }.freeze
end
