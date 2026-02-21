import type { Brand } from 'ts-brand'
import type { WineId } from '~/domain/wine/types'

export type RecommenderName = Brand<string, 'RecommenderName'>

export type Recommendation = {
  wineId: WineId
  recommenderName?: RecommenderName
  comment?: string
}
