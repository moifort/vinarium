import { describe, expect, mock, test } from 'bun:test'

// A tiny per-language asset stands in for the generated changelog content, so the
// test asserts the language dispatch, not the real release notes.
mock.module('~/system/changelog-content', () => ({
  changelogMarkdownByLanguage: {
    en: '## 1.0 (2026.01.01)\n- English note',
    fr: '## 1.0 (2026.01.01)\n- Note française',
    de: '## 1.0 (2026.01.01)\n- Deutsche Notiz',
  },
}))

const { ChangelogQuery } = await import('~/domain/changelog/query')

describe('ChangelogQuery.list', () => {
  test('serves the notes in the requested language', async () => {
    expect((await ChangelogQuery.list('de'))[0]?.notes).toEqual(['Deutsche Notiz'])
    expect((await ChangelogQuery.list('fr'))[0]?.notes).toEqual(['Note française'])
  })

  test('falls back to English for a language with no asset', async () => {
    expect((await ChangelogQuery.list('ja'))[0]?.notes).toEqual(['English note'])
  })
})
