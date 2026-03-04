import { make } from 'ts-brand'
import type { CellarBottle, CellarCol, CellarRow } from '~/domain/cellar/types'
import type { Gift } from '~/domain/gift/types'
import type { JournalEntryIn, JournalEntryOut } from '~/domain/journal/types'
import type { Recommendation } from '~/domain/recommendation/types'
import type { PersonName } from '~/domain/shared/types'
import type { Rating, TastingNote } from '~/domain/tasting/types'
import type { Wine, WineColor, WineId, WineName } from '~/domain/wine/types'

const wineId = (id?: string) => make<WineId>()(id ?? crypto.randomUUID())
const wineName = (name?: string) => make<WineName>()(name ?? 'Château Margaux')

export const aWine = (overrides?: Partial<Wine>): Wine => ({
  id: wineId(),
  name: wineName(),
  color: 'red' as WineColor,
  createdAt: new Date('2024-01-01'),
  updatedAt: new Date('2024-01-01'),
  ...overrides,
})

export const aCellarBottle = (overrides?: Partial<CellarBottle>): CellarBottle => ({
  wineId: wineId(),
  row: make<CellarRow>()(0),
  col: make<CellarCol>()(0),
  createdAt: new Date('2024-01-01'),
  updatedAt: new Date('2024-01-01'),
  ...overrides,
})

export const aJournalEntryIn = (overrides?: Partial<JournalEntryIn>): JournalEntryIn => ({
  type: 'in',
  wineId: wineId(),
  rowLabel: make<JournalEntryIn['rowLabel']>()('A'),
  colLabel: make<JournalEntryIn['colLabel']>()(1),
  dateIn: new Date('2024-01-01'),
  ...overrides,
})

export const aJournalEntryOut = (overrides?: Partial<JournalEntryOut>): JournalEntryOut => ({
  type: 'out',
  wineId: wineId(),
  rowLabel: make<JournalEntryOut['rowLabel']>()('A'),
  colLabel: make<JournalEntryOut['colLabel']>()(1),
  dateOut: new Date('2024-06-01'),
  ...overrides,
})

export const aTastingNote = (overrides?: Partial<TastingNote>): TastingNote => ({
  wineId: wineId(),
  rating: make<Rating>()(4),
  consumedDate: new Date('2024-03-01'),
  ...overrides,
})

export const aGift = (overrides?: Partial<Gift>): Gift => ({
  wineId: wineId(),
  giftedDate: new Date('2024-02-14'),
  recipientName: make<PersonName>()('Jean Dupont'),
  ...overrides,
})

export const aRecommendation = (overrides?: Partial<Recommendation>): Recommendation => ({
  wineId: wineId(),
  recommenderName: make<PersonName>()('Marie Martin'),
  comment: 'Excellent rapport qualité-prix',
  ...overrides,
})
