# CivicRoute architecture

```text
Citizen
  ↓
Rails 8 / Hotwire / PWA
  ↓
Deterministic CivicRoute Core
  ├── Service Rule Engine
  ├── Case Assessment
  ├── Evidence Comparison
  └── Action Recommendation
  ↓
PostgreSQL
  ├── Sources and curated chunks
  ├── Anonymous UUID cases
  ├── Evidence observations
  └── Recommended actions

Optional AI Layer
  ↓
Verified PostgreSQL retrieval
  ↓
Configured LLM provider
```

The AI layer explains and refines content only. Deterministic application code remains authoritative for deadlines, classifications, and recommendations.
