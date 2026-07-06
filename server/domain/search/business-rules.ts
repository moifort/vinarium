import { wineDetails } from '~/domain/beverage/business-rules'
import type { SearchableWine, SearchFilters, SearchHit, SearchMatchedField } from './types'

// Accent-, case- and separator-insensitive canonical form: "Château" matches
// "chateau", and the "vin-jaune"/"eau-de-vie" subtype codes match "vin jaune".
export const normalizedForSearch = (text: string) =>
  text
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/-/g, ' ')
    .trim()

// How strongly a candidate text matches the query: an exact match beats a
// prefix match, which beats a mere substring. Zero means no match.
export const matchStrength = (candidate: string | undefined, query: string) => {
  if (!candidate || !query) return 0
  const normalizedCandidate = normalizedForSearch(candidate)
  const normalizedQuery = normalizedForSearch(query)
  if (normalizedCandidate === normalizedQuery) return 3
  if (normalizedCandidate.startsWith(normalizedQuery)) return 2
  if (normalizedCandidate.includes(normalizedQuery)) return 1
  return 0
}

// A vintage only matches a numeric query, by year prefix ("20" finds 2015 and
// 2020, "bordeaux" never does). Substring matches would be noise ("015" → 2015).
export const vintageStrength = (vintage: number | undefined, query: string) => {
  if (vintage === undefined || !/^\d+$/.test(query)) return 0
  const year = String(vintage)
  if (year === query) return 3
  if (year.startsWith(query)) return 2
  return 0
}

// What the search result should surface first: the wine itself (name), then who
// makes it, what it is, where it comes from, when, and finally who it relates to.
const FIELD_WEIGHTS: Record<SearchMatchedField, number> = {
  name: 100,
  producer: 80,
  subtype: 70,
  appellation: 60,
  region: 60,
  vintage: 50,
  'gifted-by': 40,
  'gift-recipient': 40,
  recommender: 40,
  'tasting-contact': 40,
}

// Every field of the wine (and its satellites) the query is matched against,
// with the strength of that match. Contacts keep their best match only.
const fieldStrengths = (item: SearchableWine, query: string) => {
  const contacts = item.consumption?.contacts ?? []
  const details = wineDetails(item)
  const strengths: [SearchMatchedField, number][] = [
    ['name', matchStrength(item.name, query)],
    ['producer', matchStrength(item.producer, query)],
    ['subtype', matchStrength(item.subtype, query)],
    ['appellation', matchStrength(details?.appellation, query)],
    ['region', matchStrength(item.region, query)],
    ['vintage', vintageStrength(details?.vintage, query)],
    ['gifted-by', matchStrength(item.gift?.received?.from, query)],
    ['gift-recipient', matchStrength(item.gift?.given?.recipientName, query)],
    ['recommender', matchStrength(item.recommendation?.recommenderName, query)],
    ['tasting-contact', Math.max(0, ...contacts.map((contact) => matchStrength(contact, query)))],
  ]
  return strengths.filter(([, strength]) => strength > 0)
}

// The hit a wine scores for a query: which fields matched and how well, or null
// when nothing matched. The score is the single best field match — a wine named
// exactly like the query outranks one that merely contains it in a contact.
export const searchHit = (item: SearchableWine, query: string): SearchHit | null => {
  const matched = fieldStrengths(item, query)
  if (matched.length === 0) return null
  return {
    item,
    matchedFields: matched.map(([field]) => field),
    score: Math.max(...matched.map(([field, strength]) => FIELD_WEIGHTS[field] * strength)),
  }
}

export const passesFilters = (item: SearchableWine, filters: SearchFilters) => {
  const color = wineDetails(item)?.color
  if (filters.colors?.length && (!color || !filters.colors.includes(color))) return false
  if (filters.beverageTypes?.length && !filters.beverageTypes.includes(item.beverageType))
    return false
  if (filters.favorite === true && item.consumption?.favorite !== true) return false
  if (filters.status === 'in-cellar' && item.cellar === undefined) return false
  if (filters.status === 'consumed' && item.consumption?.consumedDate == null) return false
  if (filters.gifted === true && item.gift === undefined) return false
  return true
}

export const hasActiveFilters = (filters: SearchFilters) =>
  Boolean(filters.colors?.length) ||
  Boolean(filters.beverageTypes?.length) ||
  filters.favorite === true ||
  filters.status === 'in-cellar' ||
  filters.status === 'consumed' ||
  filters.gifted === true

// The full search: filter by facets, match the query, rank by relevance
// (score, then name for a stable order). An empty query browses by filters
// alone (name order, no matched fields); with no filter either, nothing is
// searched — the client shows its suggestions instead.
export const rankedHits = (
  items: SearchableWine[],
  query: string,
  filters: SearchFilters,
): SearchHit[] => {
  const normalizedQuery = normalizedForSearch(query)
  const filtered = items.filter((item) => passesFilters(item, filters))
  const byName = (a: SearchableWine, b: SearchableWine) => a.name.localeCompare(b.name)
  if (!normalizedQuery) {
    if (!hasActiveFilters(filters)) return []
    return filtered
      .toSorted(byName)
      .map((item) => ({ item, matchedFields: [] as SearchMatchedField[], score: 0 }))
  }
  return filtered
    .map((item) => searchHit(item, normalizedQuery))
    .filter((hit): hit is SearchHit => hit !== null)
    .toSorted((a, b) => b.score - a.score || byName(a.item, b.item))
}
