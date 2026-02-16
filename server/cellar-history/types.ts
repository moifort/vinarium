import type { WineColor } from '~/wine/types'

export type CellarHistoryEvent = {
  type: 'entry' | 'exit'
  date: Date
  wineId: string
  wineName: string
  wineColor: WineColor
  position: string
  rating?: number
  tastingNotes?: string
}
