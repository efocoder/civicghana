# CivicRoute Ghana

> **Trust · Understand · Act**

CivicRoute helps Ghanaian citizens understand public-service processes using verified, sourced official rules. Citizens can compare what the public portal shows with verified rules and institutional updates, detect discrepancies, and find verified next steps — all without guessing what is happening inside an institution.

## The Problem

When a citizen applies for an official land search through the Lands Commission, the published rule says results should be issued within 14 days after payment. In practice, citizens often wait much longer with no clear understanding of:

- What the published rule actually says
- Whether their case has exceeded the official timeframe
- Whether the public portal reflects the institution's actual progress
- What verified steps they can take next

## Why It Matters

Ghanaian citizens deserve to understand their rights and the processes of public institutions without needing a lawyer or insider access. CivicRoute bridges the gap between official rules and citizen understanding.

## How CivicRoute Works

```
Verified Public Information
          ↓
Citizen Case (anonymous, UUID-based)
          ↓
Deterministic Timeline Assessment (14-day rule)
          ↓
Multi-Source Evidence (portal snapshots, phone updates)
          ↓
Discrepancy Detection (stale portal, possible discrepancy)
          ↓
Verified Next Action (clarification, complaint, RTI, CHRAJ)
          ↓
Source-Grounded AI Explanation (optional, verified sources only)
```

## Trust Model

CivicRoute distinguishes:

1. **Verified public rules** — from legislation, official services, regulators
2. **Citizen-provided case facts** — dates, region
3. **Citizen-observed portal evidence** — milestone statuses
4. **Citizen-recorded institutional communication** — phone, email, in-person updates
5. **CivicRoute deterministic assessments** — deadline calculations, discrepancy detection
6. **Verified external action channels** — official contact, complaint, RTI, CHRAJ resources

**AI may explain, summarize and help draft, but it must not decide facts, deadlines, case status, evidence discrepancies, or escalation paths.**

## Demo

### Seeded Demo Scenario

```
Service: Official / Consolidated Search
Payment: 27 July 2026
Application completed: 30 July 2026
Published rule: 14 days after payment
Published deadline: 10 August 2026

Portal snapshot — 20 August:
  Quality Control and Coordinate Entry: Pending
  Records Verification: Not Completed
  Report Preparation: Not Completed
  Vetting and Final Approval: Not Completed

Phone update — 5 September: Near completion

Portal snapshot — 10 September: unchanged

Expected:
  - Published timeframe exceeded
  - Possible stale public status
  - Recommended next action: Request written clarification
```

## Architecture

```
Citizen
  ↓
Rails 8 / Hotwire / PWA
  ↓
Deterministic CivicRoute Core
  ├── Service Rule Engine (14-day rule from Land Act §222)
  ├── Case Assessment (deadline, days remaining/overdue)
  ├── Evidence Comparison (portal vs institutional updates)
  └── Action Recommendation (progressive action ladder)
  ↓
PostgreSQL
  ├── Sources (verified, with provenance)
  ├── Cases (anonymous, UUID)
  ├── Evidence (portal snapshots, institutional updates)
  └── Actions (clarification, complaint, RTI, CHRAJ)

Optional AI Layer
  ↓
Verified Retrieval (PostgreSQL full-text search)
  ↓
LLM Provider (provider-neutral abstraction)
```

## Technology Stack

- **Backend**: Ruby on Rails 8.1
- **Database**: PostgreSQL 17
- **Frontend**: Hotwire (Turbo + Stimulus), DaisyUI + Tailwind CSS
- **Asset Pipeline**: Propshaft, Importmap
- **AI**: ruby-openai (provider-neutral), PostgreSQL full-text search
- **Containerization**: Docker Compose (Podman)
- **Testing**: RSpec, FactoryBot, Shoulda-Matchers, Capybara

## AI Usage

AI in CivicRoute **explains and refines drafts**. Deterministic application code remains authoritative for:

- Deadlines and days remaining/overdue
- Case assessment status
- Evidence discrepancy classification
- Action recommendations
- Official source selection

AI features:
- **Explain my assessment** — plain-language case explanation
- **Explain this recommendation** — why a specific action was recommended
- **Ask about this service** — civic Q&A using verified sources only
- **Improve wording** — draft refinement (clearer, shorter, more formal, plain language)
- **Listen** — browser text-to-speech for AI explanations

## Privacy

- Anonymous cases with UUID primary keys — no PII, no authentication
- No citizen accounts, phone numbers, emails, or Ghana Card numbers collected
- Portal credentials are never requested
- Free-text evidence is not automatically sent to AI
- Secure cookie settings in production
- Filtered parameter logging

## Offline / Low-Bandwidth Design

- PWA manifest and service worker
- Cache-first strategy for static assets
- Network-first with cached fallback for public reference pages
- Network-only for AI requests and sensitive mutations
- Intentional offline fallback page
- Server-rendered Rails/Hotwire — no heavy SPA
- No external fonts or unnecessary third-party scripts

## Accessibility

- Semantic HTML with ARIA landmarks
- Keyboard navigation with visible focus states
- Explicit form labels with linked helper text
- Status communicated via badges (not color alone)
- Screen reader friendly with proper heading hierarchy
- Mobile-responsive layouts

## Verified Sources

Every factual claim in CivicRoute has a `Source` record with:
- Publisher
- Title and URL
- Authority type (legislation, official service, regulator guidance, oversight body)
- Verification timestamp
- Content hash for integrity

Current sources:
- Land Act, 2020 (Act 1036), Section 222
- Lands Commission Online Services
- Right to Information Commission
- Commission on Human Rights and Administrative Justice (CHRAJ)

## Getting Started

### Prerequisites

- Docker/Podman with Compose
- Ruby 3.4+
- PostgreSQL 17

### Setup

```bash
# Clone the repository
git clone <repository-url>
cd civicroute

# Start services
podman compose up -d

# Install dependencies
podman compose exec web bundle install

# Setup database
podman compose exec web bin/rails db:prepare
podman compose exec web bin/rails db:seed

# Run tests
podman compose exec web bundle exec rspec
```

### Environment Variables

```text
DATABASE_URL          — PostgreSQL connection string
RAILS_MASTER_KEY      — Rails encrypted credentials key
OPENAI_API_KEY        — OpenAI API key (optional, for AI features)
OPENAI_MODEL          — Model name (default: gpt-4o-mini)
AI_MAX_TOKENS         — Max tokens per AI response (default: 1000)
AI_TIMEOUT            — AI request timeout in seconds (default: 30)
APP_HOST              — Production hostname
```

### Running Tests

```bash
podman compose exec web bundle exec rspec
```

## Limitations

- Single workflow (Lands Commission Official/Consolidated Search) for hackathon scope
- English and Twi only (Twi is machine-assisted, not legally authoritative)
- No offline case editing or synchronization
- No push notifications or SMS
- AI explanations depend on external provider availability
- Source chunks are manually curated, not automatically extracted

## Future Work

- Additional public services and institutions
- Full Twi legal review by native speakers
- SMS/WhatsApp notification support
- RTI request tracking integration
- Community-sourced complaint statistics
- Multilingual AI support

## Hackathon Track

CivicRoute addresses the challenge of making public-service information **trustworthy, accessible, and actionable** for Ghanaian citizens — particularly those dealing with delays, unclear processes, and limited recourse options.
