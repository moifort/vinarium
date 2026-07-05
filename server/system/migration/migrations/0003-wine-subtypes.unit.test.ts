import { beforeEach, describe, expect, test } from 'bun:test'
import { createFakeFirestore, type FakeFirestore } from '~/test/fake-firestore'
import { migration0003 } from './0003-wine-subtypes'

let fake: FakeFirestore

beforeEach(() => {
  fake = createFakeFirestore()
})

describe('migration 0003 wine-subtypes', () => {
  test('moves the sparkling pseudo-color to a subtype with a white robe', async () => {
    fake.seed('wines', 'w1', { name: 'Crémant', beverageType: 'wine', color: 'sparkling' })

    const result = await migration0003.migrate({ db: fake.db })

    expect(result).toEqual({ ok: true, transformed: 1 })
    expect(fake.snapshot('wines').get('w1')).toEqual({
      name: 'Crémant',
      beverageType: 'wine',
      color: 'white',
      subtype: 'sparkling',
    })
  })

  test('moves the sweet pseudo-color to a subtype with a white robe', async () => {
    fake.seed('wines', 'w1', { name: 'Sauternes', beverageType: 'wine', color: 'sweet' })

    await migration0003.migrate({ db: fake.db })

    expect(fake.snapshot('wines').get('w1')).toEqual({
      name: 'Sauternes',
      beverageType: 'wine',
      color: 'white',
      subtype: 'sweet',
    })
  })

  test('maps a recognizable free-text style to its subtype and removes style', async () => {
    fake.seed('wines', 'w1', { name: 'Punk IPA', beverageType: 'beer', style: 'IPA' })

    await migration0003.migrate({ db: fake.db })

    expect(fake.snapshot('wines').get('w1')).toEqual({
      name: 'Punk IPA',
      beverageType: 'beer',
      subtype: 'ipa',
    })
  })

  test('falls back to other for an unmapped style rather than dropping the fact', async () => {
    fake.seed('wines', 'w1', { name: 'Cidre', beverageType: 'cider', style: 'Fermier' })

    await migration0003.migrate({ db: fake.db })

    expect(fake.snapshot('wines').get('w1')).toEqual({
      name: 'Cidre',
      beverageType: 'cider',
      subtype: 'other',
    })
  })

  test('drops a null style without inventing an other subtype', async () => {
    fake.seed('wines', 'w1', { name: 'Margaux', beverageType: 'wine', color: 'red', style: null })

    await migration0003.migrate({ db: fake.db })

    expect(fake.snapshot('wines').get('w1')).toEqual({
      name: 'Margaux',
      beverageType: 'wine',
      color: 'red',
    })
  })

  test('leaves healthy documents untouched', async () => {
    fake.seed('wines', 'w1', { name: 'Margaux', beverageType: 'wine', color: 'red' })
    fake.seed('wines', 'w2', { name: 'Chouffe', beverageType: 'beer', subtype: 'blonde' })

    const result = await migration0003.migrate({ db: fake.db })

    expect(result).toEqual({ ok: true, transformed: 0 })
    expect(fake.snapshot('wines').get('w1')).toEqual({
      name: 'Margaux',
      beverageType: 'wine',
      color: 'red',
    })
    expect(fake.batches).toHaveLength(0)
  })

  test('does not overwrite an already-set subtype when clearing style', async () => {
    fake.seed('wines', 'w1', {
      name: 'Chouffe',
      beverageType: 'beer',
      subtype: 'triple',
      style: 'Blonde forte',
    })

    await migration0003.migrate({ db: fake.db })

    expect(fake.snapshot('wines').get('w1')).toEqual({
      name: 'Chouffe',
      beverageType: 'beer',
      subtype: 'triple',
    })
  })

  test('splits writes into several batches beyond the Firestore 500-op limit', async () => {
    for (let i = 0; i < 501; i++) {
      fake.seed('wines', `w${i}`, { name: `Beer ${i}`, beverageType: 'beer', style: 'IPA' })
    }

    const result = await migration0003.migrate({ db: fake.db })

    expect(result).toEqual({ ok: true, transformed: 501 })
    expect(fake.batches).toHaveLength(2)
    expect(fake.batches.every((batch) => batch.ops.length <= 500)).toBe(true)
    expect(fake.batches.every((batch) => batch.commits === 1)).toBe(true)
  })
})
