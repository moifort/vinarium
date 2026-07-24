// The languages the app is localized into: French is the source, the rest are the
// added App Store markets. Used to pick the language of anything the backend
// renders for the client (AI scan text, the served changelog), driven by the
// request's `Accept-Language`.
export const SUPPORTED_LANGUAGES = ['fr', 'en', 'de', 'es', 'it', 'pt', 'ja'] as const

export type Language = (typeof SUPPORTED_LANGUAGES)[number]

// Resolve an `Accept-Language` header to a supported language. Reads only the
// primary subtag of the first listed language (`de-CH,de;q=0.9` -> `de`) and falls
// back to English for anything unsupported, so an untranslatable locale still gets
// a widely readable result rather than French.
export const languageFrom = (acceptLanguage: string | undefined): Language => {
  const primary = acceptLanguage?.split(',')[0]?.trim().split('-')[0]?.toLowerCase()
  return SUPPORTED_LANGUAGES.includes(primary as Language) ? (primary as Language) : 'en'
}
