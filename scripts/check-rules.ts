#!/usr/bin/env bun
/**
 * The rules of the stack that a search can settle, checked on every preflight and in
 * the unit workflow. Each check names its rule; one that fails lists the lines.
 *
 *   bun scripts/check-rules.ts               # every check
 *   bun scripts/check-rules.ts warm-instance # the ones named
 *
 * `console.*` under server/ is refused by Biome (`noConsole`), not here.
 */
import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs'
import { join, relative } from 'node:path'

const root = join(import.meta.dir, '..')

type Check = {
  name: string
  rule: string
  /** Folders or files, from the project root; a missing one is skipped. */
  paths: string[]
  extensions: string[]
  /** Matched against the whole file, so a call chained over several lines is caught. */
  pattern: RegExp
}

const CHECKS: Check[] = [
  {
    name: 'flat-collections',
    rule: 'stack/rules/09-backend.md#storage: collections are flat, never a subcollection',
    paths: ['server'],
    extensions: ['.ts'],
    pattern:
      /\.doc\([^()]*\)\s*\.collection\(|collectionGroup\(|listCollections\(|\.collection\(\s*['"`][^'"`]*\//g,
  },
  {
    name: 'warm-instance',
    rule: 'stack/rules/11-ops.md#scale-to-zero: never a warm instance',
    paths: ['infra', 'nitro.config.ts'],
    extensions: ['.tf', '.ts'],
    pattern: /min_instance_count\s*=\s*[1-9]|minInstances\s*:\s*[1-9]/g,
  },
  {
    name: 'derived-data',
    rule: 'stack/rules/15-tooling.md#derived-data-and-disk: never a derived data path under /tmp',
    paths: ['scripts', 'package.json'],
    extensions: ['.ts', '.sh', '.json'],
    pattern: /derivedDataPath.{0,3}(\/private)?\/tmp/g,
  },
]

const SKIPPED = new Set(['node_modules', 'test', '.output', '.nitro'])
const SELF = relative(root, import.meta.path)

const filesUnder = (path: string, extensions: string[]): string[] => {
  const full = join(root, path)
  if (!existsSync(full)) return []
  if (statSync(full).isFile()) return [path]
  return readdirSync(full, { withFileTypes: true }).flatMap((entry) => {
    const child = join(path, entry.name)
    if (entry.isDirectory()) return SKIPPED.has(entry.name) ? [] : filesUnder(child, extensions)
    return extensions.some((ext) => entry.name.endsWith(ext)) &&
      !/\.(unit|int|feat)\.test\.ts$/.test(entry.name) &&
      child !== SELF
      ? [child]
      : []
  })
}

const lineOf = (text: string, index: number) => text.slice(0, index).split('\n').length

const asked = process.argv.slice(2)
const unknown = asked.filter((name) => !CHECKS.some((check) => check.name === name))
if (unknown.length > 0) {
  console.error(`unknown check: ${unknown.join(', ')}`)
  process.exit(2)
}

let failures = 0
for (const check of CHECKS) {
  if (asked.length > 0 && !asked.includes(check.name)) continue
  const found: string[] = []
  for (const file of check.paths.flatMap((path) => filesUnder(path, check.extensions))) {
    const text = readFileSync(join(root, file), 'utf8')
    for (const match of text.matchAll(check.pattern))
      found.push(`  ${file}:${lineOf(text, match.index)}: ${match[0].replace(/\s+/g, ' ')}`)
  }
  if (found.length === 0) continue
  failures += found.length
  console.error(`${check.name} (${check.rule})\n${found.join('\n')}`)
}
console.log(failures === 0 ? 'rules hold' : `${failures} line(s) break a rule`)
process.exit(failures === 0 ? 0 : 1)
