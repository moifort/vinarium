---
name: ai-calls
description: Use when building, debugging or pricing a feature that calls a paid AI API (Gemini, Claude) in a Polyforms backend, or choosing or changing its model. The long form of stack rule 13-ai.
---

# Paid AI calls

The rule (stack rule 13-ai) says to state the cost before building, to bench before changing a
model, and to cap every paid call per day. This is the detail behind it.

## Gemini

- A grounded call bills about **four searches**, not one; the logged search count undercounts
  them. Searches are billed from the first one on a project that has spent its monthly free
  allowance (5,000 per GCP project).
- One API key per GCP project, on the project's own prepaid billing account, carried GitHub
  secret → Terraform → Secret Manager. Never a key shared between apps: one app's burst cuts
  every other.
- A local key, distinct from production's, set for every Claude session on the machine; before
  blaming production for a bill, compare fingerprints.
- Two limits, two errors: 402 when the prepaid balance is spent, 429 when the monthly cap is
  reached. The logged error says which.
- The invoice is the truth: read spend from the billing export in BigQuery, grouped by day and
  SKU; the grounded-search SKU is the one that costs. Structured logs (`jsonPayload.message`)
  with the step and the search count let a spike be attributed to a device and an hour.
- Past the free searches, grounded steps switch to Claude Haiku with web search capped at two
  searches per call; a monthly counter decides.
- Image generation for store panels: prototype at 1K or 2K, 4K only for a kept scene; the model
  draws dividing lines when asked for several panels in one image.

## Model choices

Choices as of 2026-10-21:

| Need | Model | Why |
|---|---|---|
| Structured extraction from a photo or a page | Gemini Flash-Lite | Cheapest with vision, good enough for fields |
| Edition data with web grounding | Gemini grounded, then Claude Haiku + web search past the free tier | Cost of searches |
| Editorial recommendation from the person's own data | Claude Sonnet | Blind test won against Haiku, Opus and Gemini Pro; about 0.035 euro per generation |
| Choosing a month's picks, text only | Claude Sonnet | Same |

Google Books and Open Library are not edition sources (503 on most calls, wrong ISBNs, no French
editions); BnF's SRU serves French named books for free.
