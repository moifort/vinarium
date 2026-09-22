// Boundary converter: GraphQL nullability → domain "absent key" convention.
//
// Pothos optional input fields are typed as `T | null | undefined`; at runtime
// graphql-js omits absent fields entirely, so the only variant to erase is an
// explicit `null` sent by the client. Domain types use `T?` (a key is present
// with a value, or not present at all) and Firestore rejects `undefined`
// values — dropping the null KEYS (not nulling them) keeps both invariants.
//
// Not recursive: every mutation input in the schema is flat.
type StripNulls<T> = { [K in keyof T]: Exclude<T[K], null> }

export const stripNulls = <T extends Record<string, unknown>>(obj: T): StripNulls<T> => {
  const out: Record<string, unknown> = {}
  for (const key of Object.keys(obj)) {
    const value = (obj as Record<string, unknown>)[key]
    if (value !== null) out[key] = value
  }
  return out as StripNulls<T>
}

// A page size asked by a client, brought within [1, max]. Clamped rather than
// rejected: an app already published keeps working whatever it asks, and no
// request can make a list read more documents than the page allows.
export const pageLimit = (requested: number | null | undefined, fallback: number, max: number) =>
  Math.min(Math.max(requested ?? fallback, 1), max)
