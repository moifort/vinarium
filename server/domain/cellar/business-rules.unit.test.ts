import { describe, expect, test } from 'bun:test'
import { effectiveCellarId, firstFreeSlot, isOutsideGrid } from '~/domain/cellar/business-rules'
import type { CellarBottle, CellarCol, CellarId, CellarRow } from '~/domain/cellar/types'

const id = (value: string) => value as CellarId
const bottle = (cellarId?: string) =>
  ({ ...(cellarId === undefined ? {} : { cellarId: id(cellarId) }) }) as CellarBottle

describe('effectiveCellarId', () => {
  const household = new Set([id('hh_1'), id('garage')])

  test('a bottle naming a cellar of the household stands in it', () => {
    expect(effectiveCellarId(bottle('garage'), household, id('hh_1'))).toBe(id('garage'))
  })

  test('a bottle naming no cellar stands in the primary one', () => {
    expect(effectiveCellarId(bottle(), household, id('hh_1'))).toBe(id('hh_1'))
  })

  test('a bottle naming a cellar the household does not hold stands in the primary one', () => {
    expect(effectiveCellarId(bottle('usr_left-behind'), household, id('hh_1'))).toBe(id('hh_1'))
  })
})

describe('firstFreeSlot', () => {
  test('reads row by row from the top left', () => {
    expect(firstFreeSlot([{ row: 0, col: 0 } as CellarBottle], 2, 2)).toEqual({ row: 0, col: 1 })
  })

  test('finds nothing in a full grid', () => {
    const full = [0, 1].flatMap((row) => [0, 1].map((col) => ({ row, col }) as CellarBottle))
    expect(firstFreeSlot(full, 2, 2)).toBeUndefined()
  })
})

describe('isOutsideGrid', () => {
  const grid = { rows: 2, cols: 3 }
  test('the last slot is inside, one further is out', () => {
    expect(isOutsideGrid(grid, 1 as CellarRow, 2 as CellarCol)).toBe(false)
    expect(isOutsideGrid(grid, 2 as CellarRow, 0 as CellarCol)).toBe(true)
    expect(isOutsideGrid(grid, 0 as CellarRow, 3 as CellarCol)).toBe(true)
  })
})
