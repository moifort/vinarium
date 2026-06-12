/**
 * In-memory Firestore fake for unit tests. Records every created batch and every
 * direct (non-batched) write so tests can assert the atomicity contract: all
 * writes of an operation enlisted into one batch, committed exactly once, and
 * nothing applied when the commit fails.
 *
 * Test files mock the firebase module with the shared holder so file ordering
 * does not matter:
 *   mock.module('~/system/firebase', () => ({ db: fakeDb }))
 */
import type { Firestore } from 'firebase-admin/firestore'

type Doc = Record<string, unknown>

export type FakeRef = {
  collection: string
  id: string
  get: () => Promise<{ data: () => Doc | undefined }>
  set: (data: Doc) => Promise<void>
  delete: () => Promise<void>
}

export type BatchOp = { type: 'set'; ref: FakeRef; data: Doc } | { type: 'delete'; ref: FakeRef }

export type FakeBatch = {
  ops: BatchOp[]
  commits: number
  set: (ref: FakeRef, data: Doc) => FakeBatch
  delete: (ref: FakeRef) => FakeBatch
  commit: () => Promise<void>
}

export type DirectWrite = { type: 'set' | 'delete'; collection: string; id: string }

type FakeQuery = {
  where: (field: string, op: string, value: unknown) => FakeQuery
  orderBy: (field: string, direction?: 'asc' | 'desc') => FakeQuery
  get: () => Promise<{ docs: Array<{ data: () => Doc; ref: FakeRef }> }>
}

type FakeCollection = {
  withConverter: (converter: unknown) => FakeCollection
  doc: (id?: string) => FakeRef
  add: (data: Doc) => Promise<FakeRef>
  where: FakeQuery['where']
}

export const createFakeFirestore = () => {
  const store = new Map<string, Map<string, Doc>>()
  const batches: FakeBatch[] = []
  const directWrites: DirectWrite[] = []
  let commitError: Error | undefined
  let generatedIds = 0

  const docsOf = (collection: string) => {
    const existing = store.get(collection)
    if (existing) return existing
    const created = new Map<string, Doc>()
    store.set(collection, created)
    return created
  }

  const makeRef = (collection: string, id: string): FakeRef => ({
    collection,
    id,
    get: async () => ({ data: () => docsOf(collection).get(id) }),
    set: async (data) => {
      directWrites.push({ type: 'set', collection, id })
      docsOf(collection).set(id, data)
    },
    delete: async () => {
      directWrites.push({ type: 'delete', collection, id })
      docsOf(collection).delete(id)
    },
  })

  const sortValue = (value: unknown) =>
    value instanceof Date ? value.getTime() : (value as number | string)

  // The fake only implements equality filtering — fail loudly rather than
  // silently return wrong results if production code starts using other operators.
  const assertEqualityOperator = (op: string) => {
    if (op !== '==') throw new Error(`fake-firestore only supports '==' queries, got '${op}'`)
  }

  const makeQuery = (
    collection: string,
    filters: Array<[string, unknown]>,
    order?: { field: string; direction: 'asc' | 'desc' },
  ): FakeQuery => ({
    where: (field, op, value) => {
      assertEqualityOperator(op)
      return makeQuery(collection, [...filters, [field, value]], order)
    },
    orderBy: (field, direction = 'asc') => makeQuery(collection, filters, { field, direction }),
    get: async () => {
      const matching = [...docsOf(collection).entries()].filter(([, data]) =>
        filters.every(([field, value]) => data[field] === value),
      )
      if (order) {
        const { field, direction } = order
        matching.sort(([, a], [, b]) => {
          const left = sortValue(a[field])
          const right = sortValue(b[field])
          const comparison = left < right ? -1 : left > right ? 1 : 0
          return direction === 'desc' ? -comparison : comparison
        })
      }
      return {
        docs: matching.map(([id, data]) => ({ data: () => data, ref: makeRef(collection, id) })),
      }
    },
  })

  const makeCollection = (name: string): FakeCollection => ({
    withConverter: () => makeCollection(name),
    doc: (id) => makeRef(name, id ?? `generated-${++generatedIds}`),
    add: async (data) => {
      const ref = makeRef(name, `generated-${++generatedIds}`)
      await ref.set(data)
      return ref
    },
    where: (field, op, value) => {
      assertEqualityOperator(op)
      return makeQuery(name, [[field, value]])
    },
  })

  const makeBatch = (): FakeBatch => {
    const ops: BatchOp[] = []
    const batch: FakeBatch = {
      ops,
      commits: 0,
      set: (ref, data) => {
        ops.push({ type: 'set', ref, data })
        return batch
      },
      delete: (ref) => {
        ops.push({ type: 'delete', ref })
        return batch
      },
      commit: async () => {
        if (commitError) throw commitError
        for (const op of ops) {
          if (op.type === 'set') docsOf(op.ref.collection).set(op.ref.id, op.data)
          else docsOf(op.ref.collection).delete(op.ref.id)
        }
        batch.commits += 1
      },
    }
    batches.push(batch)
    return batch
  }

  return {
    db: { collection: makeCollection, batch: makeBatch } as unknown as Firestore,
    seed: (collection: string, id: string, data: Doc) => {
      docsOf(collection).set(id, { ...data })
    },
    snapshot: (collection: string) => new Map(docsOf(collection)),
    batches,
    directWrites,
    failCommitsWith: (error: Error) => {
      commitError = error
    },
  }
}

export type FakeFirestore = ReturnType<typeof createFakeFirestore>

const holder = { current: createFakeFirestore() }

export const resetFakeFirestore = () => {
  holder.current = createFakeFirestore()
  return holder.current
}

export const fakeDb = () => holder.current.db
