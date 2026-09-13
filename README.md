# CivicRoute Ghana

> **Trust · Understand · Act**

**OSF × Andela Hackathon — Transparency & Accountability**

CivicRoute is an independent civic-tech tool that helps people understand public-service processes using verified official information.

It started from a simple frustration: a citizen can submit an application, keep checking a public portal, and still have no clear idea whether the process is on time, whether the portal reflects the latest information, or what to do next.

CivicRoute brings those pieces together. It helps a citizen understand the published rule, compare it with what they can actually observe, record updates they receive from an institution, and find a verified next step.

It does **not** claim access to internal government systems, and it does not let AI decide civic facts.

---

## The problem

Public-service information is often available, but not always easy to use.

A citizen may still struggle to answer questions like:

- What does the official rule actually say?
- What documents do I need?
- How long should this service take?
- Has the published timeframe been exceeded?
- Does the public portal match an update I received by phone or in person?
- What should I do next?
- Which complaint, contact, payment, RTI, or redress channel is official?

The first CivicRoute use case came from a real Lands Commission experience: the public tracker appeared unchanged for a long period, while a later phone inquiry suggested the application had progressed further than the portal showed.

That gap between **published information**, **public status information**, and **what a citizen is later told** is the problem CivicRoute is designed to address.

---

## What CivicRoute does

CivicRoute combines:

- verified official rules and service guidance;
- citizen-provided application facts;
- citizen-observed public portal information;
- citizen-recorded updates from the institution;
- deterministic deadline and evidence comparison;
- verified action channels; and
- optional AI explanations grounded in approved sources.

In practical terms, CivicRoute tries to answer four questions:

> **What does the official information say?**  
> **What does the public system show?**  
> **Do those pieces of information appear to agree?**  
> **What can I do next?**

---

## Why CivicRoute is different

CivicRoute is not just a service directory, and it is not a government chatbot.

It separates information by where it came from:

```text
Verified official information
        ↓
Citizen-provided facts
        ↓
Citizen-observed portal information
        ↓
Citizen-recorded institutional updates
        ↓
Deterministic CivicRoute assessment
        ↓
Verified next action
        ↓
Optional source-grounded AI explanation
```

That separation matters.

If a citizen records that an officer said an application is “near completion,” CivicRoute does not turn that into an official fact. If the public portal still shows an earlier status, CivicRoute can flag a **possible discrepancy**, but it still cannot claim to know the institution's true internal state.

Where the evidence is uncertain, CivicRoute says so.

---

## Current Lands Commission coverage

The hackathon version focuses on Ghana's Lands Commission, but the application is built so other public institutions can be added through configuration and curated data.

### Official / Consolidated Search

- Published rule: **14 days after payment**
- Assessment is anchored to payment because the verified rule explicitly refers to payment
- Anonymous case assessment
- Portal snapshots
- Institutional updates
- Possible discrepancy / possible stale-public-status detection
- Verified next-action recommendations

### Deed Registration

- Published service target: **10 working days**
- Source: Lands Commission Client Service Charter
- Verified requirements and published journey
- CivicRoute estimates the target date from the citizen's completed-application date
- Official Search milestones are not reused for this service

### First Registration of Title to Land

- Published service target: **65 working days**
- Source: Lands Commission Client Service Charter
- Includes the published **14-day objection period within the 65-working-day journey**
- The 65-day target is not applied to every type of Title Registration transaction
- Verified requirements and published journey
- Official Search milestones are not reused for this service

> CivicRoute distinguishes a **published service target** from a **statutory deadline**. It only uses stronger legal wording where the source supports it.

---

## A typical CivicRoute journey

```text
Choose a public service
        ↓
Read verified requirements, rules and sources
        ↓
Create an anonymous case
        ↓
Get a deterministic service assessment
        ↓
Record what the public portal shows
        ↓
Record an update received from the institution
        ↓
Compare the evidence
        ↓
Identify a possible discrepancy
        ↓
See a verified recommended next action
        ↓
Ask CivicRoute for a plain-language explanation
```

---

## Demo scenario

The seeded demo is based on an Official / Consolidated Search case.

```text
Payment:
27 July 2026

Application completed:
30 July 2026

Published rule:
14 days after payment

Published deadline:
10 August 2026
```

### Portal snapshot — 20 August

```text
Quality Control and Coordinate Entry: Pending
Records Verification: Not Completed
Report Preparation: Not Completed
Vetting and Final Approval: Not Completed
```

### Phone update — 5 September

```text
Near completion
```

### Portal snapshot — 10 September

```text
Unchanged
```

### CivicRoute result

```text
Published timeframe exceeded

Possible stale public status

Recommended next action:
Request written clarification
```

CivicRoute does not claim that the phone update is the institution's true internal status. It only shows that the citizen-recorded update appears to indicate later progress than the latest citizen-observed portal snapshot.

---

## From information to action

One of the main goals of CivicRoute is to avoid leaving a citizen with a warning and no practical next step.

The recommendation engine follows a progressive path.

```text
Within published timeframe
        ↓
Continue monitoring

Timeframe exceeded
        ↓
Request written clarification

Institution responds
        ↓
Record the response

Issue remains unresolved
        ↓
Use a verified complaint channel

Need access to institutional records
        ↓
Consider Right to Information guidance

Earlier administrative steps remain unresolved
        ↓
Consider an appropriate redress option
```

Depending on the service and situation, CivicRoute can point to verified resources such as:

- the official application tracker;
- official service guidance;
- current fee information;
- the Lands Commission payment portal;
- contact details;
- complaint channels;
- Right to Information guidance; and
- CHRAJ information where appropriate.

Complaint, RTI, and CHRAJ are not presented as equal first steps.

---

## Trust model

CivicRoute deliberately keeps six kinds of information separate:

1. **Verified official information**  
   Legislation, service guidance, client service charters, fees, regulators, and official action channels.

2. **Citizen-provided facts**  
   Dates, region, and other case details entered by the citizen.

3. **Citizen-observed public information**  
   What the citizen reports seeing on a public tracker.

4. **Citizen-recorded institutional communication**  
   Phone, email, in-person, letter, SMS, or other updates.

5. **CivicRoute calculations**  
   Timeframe calculations, evidence comparison, and action recommendation.

6. **AI-generated explanation**  
   Plain-language explanation of results that CivicRoute has already determined.

AI may explain, summarize, translate, or improve wording.

It may **not** decide:

- deadlines;
- days remaining or overdue;
- the institution's true internal status;
- discrepancy classification;
- recommended action;
- official source selection; or
- official contact destination.

---

## Architecture

```text
Citizen
  ↓
Rails 8 / Hotwire / PWA
  ↓
Data-driven civic domain
  ├── Agency
  ├── Organizational Unit
  ├── Public Service
  ├── Service Variant
  ├── Requirements
  ├── Fees
  ├── Process Steps
  ├── Service Rules
  ├── Sources
  └── Action Resources
  ↓
Deterministic CivicRoute core
  ├── Service Rule Engine
  ├── Business-Day Calculation
  ├── Case Assessment
  ├── Evidence Comparison
  └── Action Recommendation
  ↓
PostgreSQL
  ├── Verified Sources
  ├── Source Chunks
  ├── Anonymous Cases
  ├── Portal Observations
  ├── Institutional Updates
  └── Actions

Optional AI layer
  ↓
Service-scoped retrieval
  ↓
Xiaomi MiMo
  ↓
CivicRoute validation
  ↓
Explanation + verified citations
```

Current deterministic rules include:

- Official Search — **14 days after payment**
- Deed Registration — **10 working days**
- First Registration of Title to Land — **65 working days**

---

## Built to scale beyond one service

CivicRoute keeps reusable civic logic in code and institution-specific content in the database.

```text
Agency
  ↓
Organizational Unit
  ↓
Public Service
  ↓
Service Variant
  ├── Requirements
  ├── Fees
  ├── Published Rules
  ├── Process Steps
  ├── Verified Sources
  ├── Action Resources
  └── AI Knowledge
```

Services move through three levels of support:

- **Directory** — verified service identity and basic information
- **Guided** — requirements, fees, rules, journey, sources, and official action channels
- **Trackable** — deterministic case assessment and evidence comparison where enough verified information exists

This means another institution can be added mainly by curating trustworthy local information rather than rewriting the application.

It also means CivicRoute does not pretend every service is trackable. If the necessary service-specific evidence does not exist, the service remains Directory or Guided.

---

## AI in the application

CivicRoute uses a provider-neutral AI layer for optional plain-language interactions. Xiaomi MiMo is the current default provider, while OpenAI compatibility is also represented in the configuration for future provider choice.

It is used for:

- **Explain my assessment**
- **Explain this recommendation**
- **Ask CivicRoute**
- **Improve wording**
- plain-language explanation and translation

Retrieval is scoped to the selected service and uses curated CivicRoute source chunks.

Citations shown to the citizen come from CivicRoute's own verified `Source` records rather than URLs invented by the model.

If the AI provider is unavailable, the core application still works: verified service guidance, case assessment, evidence comparison, and next-action recommendations do not depend on AI.

---

## How AI helped build CivicRoute

The project idea came from a real civic problem, not from an AI-generated hackathon concept.

OpenAI Codex was used as an engineering collaborator during development. It helped with:

- reviewing the Rails architecture;
- refactoring hard-coded civic information into database-backed models;
- implementing service-specific rules;
- expanding automated test coverage;
- debugging Rails, Hotwire, and Stimulus behavior;
- reviewing localization;
- reviewing responsive UI and accessibility;
- reviewing source-grounded AI integration; and
- identifying regression risks during refactoring.

AI-generated code and suggestions were reviewed before being accepted.

Civic and legal information was curated separately from official sources before it was treated as trusted CivicRoute data.

```text
OpenAI Codex
→ helped build and review CivicRoute

Xiaomi MiMo
→ current default runtime provider for optional explanations

OpenAI
→ planned alternative runtime provider for plain-language interactions
```

---

## Source verification

Every trusted civic claim is linked to a `Source` record.

A source can include:

- publisher;
- title;
- official URL;
- authority type;
- legal provision or section;
- effective dates;
- last verified date;
- content hash;
- review status.

A working URL is not treated as proof that the information is still correct.

The intended review flow is:

```text
Source checked
      ↓
Unavailable or possibly changed?
      ↓
Flag for review
      ↓
Human curator checks the authoritative source
      ↓
Update last_verified_at
```

---

## Key authoritative sources

Current source material includes:

- **Land Act, 2020 (Act 1036)**
- **Ghana Lands Commission Client Service Charter**
- **Lands Commission — Deed Registration**
- **Lands Commission — Registration (Title)**
- **Lands Commission — Fees & Charges**
- **Lands Commission Online Services / Application Tracker**
- **Lands Commission Feedback & Complaints**
- **Right to Information Commission**
- **Commission on Human Rights and Administrative Justice (CHRAJ)**

Useful Lands Commission links:

- Client Service Charter  
  `https://www.lc.gov.gh/storage/2023/12/CLIENT-SERVICE-CHARTER.pdf`

- Deed Registration  
  `https://www.lc.gov.gh/services/deed-registration/`

- Registration (Title)  
  `https://www.lc.gov.gh/services/registration-title/`

- Fees & Charges  
  `https://www.lc.gov.gh/fees-charges/`

- Online Services  
  `https://onlineservices.lc.gov.gh/`

Source URLs are stored in the database rather than embedded throughout citizen-facing business logic.

---

## Privacy and security

CivicRoute is designed so a citizen can use the core service without creating an account or giving up unnecessary personal information.

Current protections include:

- anonymous case creation;
- UUID / unguessable public case identifiers;
- no mandatory account;
- no Ghana Card number;
- no mandatory email or phone number;
- no government portal credentials;
- server-side AI credentials;
- filtered sensitive parameters in logs;
- no public index of anonymous cases;
- free-text evidence is not automatically sent to AI.

### Saving something for later

A user can save a case or service reference on the current device without signing up.

Only minimal metadata is kept in browser storage, such as:

- an opaque case/service reference;
- display label;
- saved timestamp.

Sensitive evidence and application details are not stored there.

Anonymous case URLs behave like private bearer links, so CivicRoute tells users to keep those links private.

---

## Low-bandwidth and offline use

CivicRoute is designed to remain useful when internet access is unreliable.

The application uses:

- server-rendered Rails/Hotwire instead of a heavy SPA;
- a PWA manifest and service worker;
- cache-first static assets;
- cached fallback for previously visited public guidance;
- an intentional offline page;
- network-only handling for AI and sensitive mutations;
- few client-side dependencies;
- no external font dependency for core use.

Public guidance is still useful without AI.

Offline support does **not** currently include full offline case editing or synchronization.

---

## Accessibility and inclusion

CivicRoute aims for a WCAG 2.2 AA-oriented experience.

The interface includes:

- semantic HTML;
- skip navigation;
- keyboard-friendly controls;
- visible focus states;
- explicit form labels;
- linked helper and validation text;
- status text that does not rely on color alone;
- logical headings;
- mobile-responsive layouts;
- touch-friendly controls;
- plain-language explanations; and
- optional browser text-to-speech for supported explanations.

The main citizen journey is designed to remain usable on small screens and without a mouse.

---

## Languages

CivicRoute currently supports:

- English
- Twi
- French

The selected locale is carried through normal navigation and form flows.

Localization covers the interface and database-backed civic content where translations are available, including:

- navigation;
- service pages;
- buttons;
- forms;
- helper text;
- statuses;
- assessment results;
- recommended actions;
- AI controls; and
- AI response language.

Official legal wording remains separate from CivicRoute translations. A translated explanation is an accessibility aid, not a replacement for the authoritative source.

---

## How CivicRoute addresses the hackathon operating constraints

| Operating constraint | CivicRoute response |
|---|---|
| **Trust and verification** | Official sources, provenance, last-verified dates, deterministic logic, service-scoped AI retrieval, CivicRoute-rendered citations |
| **Low bandwidth and limited access** | Server-rendered Hotwire, cached public guidance, PWA/offline fallback, graceful AI/network failure |
| **Accessibility and inclusion** | Keyboard-friendly UI, visible focus, labelled forms, plain language, responsive layouts, text-based status indicators |
| **Privacy and security** | Anonymous cases, unguessable identifiers, no required PII, minimal device-local saved references, server-side AI credentials |
| **Multilingual access** | English, Twi and French, locale-preserving navigation, translated database content, locale-aware AI responses |
| **Local relevance** | Ghana Lands Commission rules, requirements, timelines, journeys, fees and official action channels |
| **Clear next steps** | Deterministic recommendations, reasons for the recommendation, a primary action, and verified alternatives |

---

## Technology stack

- **Backend:** Ruby on Rails 8.1
- **Database:** PostgreSQL 17
- **Frontend:** Hotwire — Turbo + Stimulus
- **Styling:** Tailwind CSS + DaisyUI
- **Asset Pipeline:** Propshaft + Importmap
- **PWA:** Service worker + web app manifest
- **AI:** Xiaomi MiMo
- **Retrieval:** PostgreSQL full-text search
- **Containerization:** Docker Compose / Podman
- **Testing:** RSpec, FactoryBot, Shoulda-Matchers, Capybara

---

## Getting started

### Prerequisites

For the recommended container-based setup:

- Docker or Podman with Compose

Ruby 3.4+ and PostgreSQL 17 are part of the application stack. You only need local installations of them if you choose to run CivicRoute outside the provided container setup.

### Clone and start

```bash
git clone https://github.com/efocoder/civicghana.git civicroute
cd civicroute

podman compose up -d
podman compose exec web bundle install
podman compose exec web bin/rails db:prepare
podman compose exec web bin/rails db:seed
```

### Run the test suite

```bash
podman compose exec web bundle exec rspec
```

---

## Configuration

CivicRoute uses environment variables from `.env` together with the Compose configuration. A separate `DATABASE_URL` is **not required** for the normal local container setup.

Create your local environment file from the repository example if available:

```bash
cp .env.example .env
```

Then configure the values below:

```env
# Database
DB_HOST=127.0.0.1
DB_PORT=5432
DB_USERNAME=civicroute
DB_PASSWORD=civicroute
DB_NAME=civicroute_development
TEST_DB_NAME=civicroute_test

# Rails
RAILS_ENV=development
RAILS_MASTER_KEY=
APP_HOST=localhost

# Xiaomi MiMo
# Server-side only; never expose these values to the browser.
MIMO_API_KEY=
MIMO_MODEL=mimo-v2.5
MIMO_BASE_URL=https://api.xiaomimimo.com/v1
AI_MAX_TOKENS=1000
AI_TIMEOUT=30
AI_DEFAULT_PROVIDER=mimo

# Optional OpenAI compatibility settings for local integrations
OPENAI_API_KEY=
OPENAI_MODEL=gpt-4o-mini
```

Most service and container wiring remains in the Compose file, while `.env` holds local values, secrets, and environment-specific overrides.

Do not commit a populated `.env` file containing real credentials.

### AI provider configuration

Xiaomi MiMo is currently the default provider for CivicRoute's optional plain-language AI features:

```env
AI_DEFAULT_PROVIDER=mimo
```

OpenAI settings are already represented in the environment configuration so the application can support a provider-neutral AI layer.

The planned user experience is to allow a citizen to choose between **Xiaomi MiMo** and **OpenAI** for plain-language interactions from an advanced/assistant setting, while keeping MiMo as the default.

Provider selection will apply only to features such as:

- Ask CivicRoute;
- Explain my assessment;
- Explain this recommendation;
- plain-language rewriting or draft improvement; and
- translated/plain-language explanations where AI is used.

Changing the AI provider must **never** change CivicRoute's deterministic behavior. Deadlines, working-day calculations, evidence comparison, source selection, discrepancy classification, and recommended actions remain controlled by application logic and verified data.

API keys remain server-side. Citizens will never be asked to enter provider credentials.

If no AI provider is available, CivicRoute's core civic features still work. Only the optional AI explanations become unavailable.

---

## Testing and release gate

Important test areas include:

- service-rule calculations;
- business-day calculations;
- case assessment;
- evidence comparison;
- action recommendation;
- service-scoped source retrieval;
- AI failure behavior;
- locale persistence;
- translated UI;
- saved-on-device behavior;
- responsive/system flows; and
- source configuration.

The submission checklist is in:

```text
docs/submission-checklist.md
```

The target end-to-end demo is:

```text
Service discovery
        ↓
Verified service guide
        ↓
Authoritative source
        ↓
Anonymous case
        ↓
Deterministic assessment
        ↓
Portal observation
        ↓
Institutional update
        ↓
Possible discrepancy
        ↓
Verified next action
        ↓
Ask CivicRoute
        ↓
Grounded MiMo explanation + citations
        ↓
Switch language
        ↓
Save case on this device
        ↓
Reopen saved case
        ↓
Use previously visited public guidance offline
```

---

## Current limitations

CivicRoute is a hackathon proof of concept, not a production government platform.

Current limitations include:

- the main institutional focus is still the Ghana Lands Commission;
- not every Lands Commission service has enough verified information to be Trackable;
- service-specific portal milestones are only enabled when independently verified;
- offline mode does not support full case editing or synchronization;
- AI explanations require an external AI provider;
- source chunks are manually curated;
- changes to authoritative sources still require human review;
- Twi legal wording needs continued native-speaker/legal review;
- translated explanations do not replace official legal wording;
- there is no cross-device account synchronization yet; and
- there are no SMS or push notifications yet.

Some of these limitations are deliberate. CivicRoute prefers to show less information rather than make a claim it cannot support.

---

## Where CivicRoute can go next

Possible next steps include:

- more Ghanaian public institutions;
- more Lands Commission services;
- optional accounts for cross-device saved activity;
- claiming existing anonymous cases after registration;
- saved assistant conversations;
- user-selectable AI provider for plain-language interactions;
- SMS / WhatsApp notifications;
- more native-speaker translation review;
- more Ghanaian and OSF-region languages;
- source-change detection with human verification;
- a richer curator workflow;
- RTI request tracking; and
- privacy-preserving aggregate insights about service delays.

---

## Principles we do not compromise on

CivicRoute should:

- never claim privileged access to a government system;
- never present citizen-reported evidence as an official fact;
- never let AI change a deterministic civic result;
- never invent a deadline;
- never fabricate a source or official contact;
- never reuse another service's portal milestones without verification;
- never describe a published service journey as live internal workflow; and
- prefer uncertainty over unsupported certainty.

---

## Hackathon fit

CivicRoute is submitted under **Transparency & Accountability** and supports the wider theme of **Information you can trust**.

The project focuses on making public-service processes easier to understand, verify, and act on — especially when information is fragmented or when what a citizen sees publicly does not appear to match what they are later told.

---

## Disclaimer

CivicRoute is an independent civic information tool.

It is **not affiliated with the Ghana Lands Commission, Government of Ghana, CHRAJ, the Right to Information Commission, Open Society Foundations, Andela, or any other public institution or hackathon partner**.

CivicRoute does not provide legal representation and does not claim access to any institution's internal systems.

Where official wording matters, users should consult the linked authoritative source.
