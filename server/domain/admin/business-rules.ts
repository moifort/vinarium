import type { AiStepUsage, AiUsage, PremiumBreakdown } from '~/domain/admin/types'
import { isActive } from '~/domain/entitlement/business-rules'
import type { Entitlement } from '~/domain/entitlement/types'
import { Count, Eur, Month } from '~/domain/shared/primitives'
import type { Eur as EurType, Month as MonthType } from '~/domain/shared/types'

// Gemini 2.5 Flash list prices (docs/freemium-economics.md): $0.30 per million
// input tokens, $2.50 per million output tokens — and thinking tokens bill at
// the output rate, which is why they are tracked apart.
const INPUT_USD_PER_TOKEN = 0.3 / 1_000_000
const OUTPUT_USD_PER_TOKEN = 2.5 / 1_000_000

// A fixed conversion, not a live rate: the cost figure steers decisions, it does
// not close books. Revised by hand when the rate drifts far enough to matter.
const USD_TO_EUR = 0.91

// The one infrastructure line no API measures: the Apple Developer Program at
// $99/year. Everything GCP (Firestore, Cloud Functions, Secret Manager) is
// measured for real from the billing export instead — see infraEur below.
export const APPLE_DEVELOPER_EUR_PER_MONTH: EurType = Eur(7.7)

// The month a moment belongs to, `"2026-07"`, also the ai-usage document id.
// UTC on purpose, mirroring the quota month: the window must not move with
// anyone's timezone.
export const monthOf = (moment: Date): MonthType =>
  Month(`${moment.getUTCFullYear()}-${String(moment.getUTCMonth() + 1).padStart(2, '0')}`)

// A month nothing has been spent in yet — what an absent ai-usage document means.
export const freshUsage = (month: MonthType): AiUsage => ({
  month,
  scans: Count(0),
  cacheHits: Count(0),
  vision: freshStep(),
  enrichment: freshStep(),
})

const freshStep = (): AiStepUsage => ({
  promptTokens: Count(0),
  outputTokens: Count(0),
  thinkingTokens: Count(0),
})

// What the month's measured tokens cost in euros, both Gemini calls combined.
export const aiCostEur = (usage: AiUsage): EurType => {
  const promptTokens = usage.vision.promptTokens + usage.enrichment.promptTokens
  const billedAsOutput =
    usage.vision.outputTokens +
    usage.vision.thinkingTokens +
    usage.enrichment.outputTokens +
    usage.enrichment.thinkingTokens
  const usd = promptTokens * INPUT_USD_PER_TOKEN + billedAsOutput * OUTPUT_USD_PER_TOKEN
  return Eur(usd * USD_TO_EUR)
}

// The month's infrastructure bill: the fixed Apple line plus whatever GCP
// measured, when the billing export has answered at least once.
export const infraEur = (gcpCostEur: EurType | undefined): EurType =>
  Eur(APPLE_DEVELOPER_EUR_PER_MONTH + (gcpCostEur ?? 0))

// Who is Premium right now, split by the billing period the product id names.
// `total` counts every active entitlement, so an unexpected product id still
// shows up there even if it lands in neither split.
export const premiumBreakdown = (entitlements: Entitlement[], now: Date): PremiumBreakdown => {
  const active = entitlements.filter((entitlement) => isActive(entitlement, now))
  const of = (suffix: string) =>
    Count(active.filter(({ productId }) => (productId as string).endsWith(suffix)).length)
  return { total: Count(active.length), monthly: of('.monthly'), yearly: of('.yearly') }
}
