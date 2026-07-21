import type { Brand } from 'ts-brand'

export type UserId = Brand<string, 'UserId'>
/** What an account is entitled to. `free` is everyone's starting point and the
 *  only state that needs no proof; `premium` is a verified App Store purchase. */
export type Plan = 'free' | 'premium'
export type Eur = Brand<number, 'Eur'>
export type Year = Brand<number, 'Year'>
export type Country = Brand<string, 'Country'>
export type Region = Brand<string, 'Region'>
export type Month = Brand<string, 'Month'>
export type Count = Brand<number, 'Count'>
export type PersonName = Brand<string, 'PersonName'>
export type Latitude = Brand<number, 'Latitude'>
export type Longitude = Brand<number, 'Longitude'>
export type PlaceName = Brand<string, 'PlaceName'>
export type Percentage = Brand<number, 'Percentage'>
