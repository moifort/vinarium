// Pothos optional input fields are typed as `T | null | undefined`. Domain
// types use `T?` (undefined only). This helper drops the null variant so a
// GraphQL input can be spread directly into a domain command argument.
type StripNulls<T> = { [K in keyof T]: Exclude<T[K], null> }

export const stripNulls = <T extends Record<string, unknown>>(obj: T): StripNulls<T> => {
  const out: Record<string, unknown> = {}
  for (const key of Object.keys(obj)) {
    const value = (obj as Record<string, unknown>)[key]
    if (value !== null) out[key] = value
  }
  return out as StripNulls<T>
}
