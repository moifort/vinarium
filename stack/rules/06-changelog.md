# Changelog

## Two files in lockstep

`CHANGELOG.md` in `English` is the source of truth; one translation per served
language (`CHANGELOG.<lang>.md`), kept in lockstep. Newest first. Each version carries the store
version and its release date: `## 1.0 (2026.10.01)`.

Under a version, at most three subsections, only those with content: new, fixes, performance. If
the parser serving the content ignores them, the app shows a flat list, and that is fine.

## Written at release time, never before

A feature, a fix or a push leaves both files untouched: no `## Unreleased` section, not even as a
placeholder. The entries are written when a store release is cut, from the commits since the
previous one, under that release's version and date.

## What to write

The reader is not technical. An entry says what changed **for them**, in their words, and nothing
else. Two tests before writing a line: does the person notice it while using the app, and would
they understand the sentence without knowing how the app is built. No on both, no entry.

What goes in:

- a new feature or a new capability the person can use, named where it is in the interface;
- a problem they could meet, now fixed, described by its effect;
- a change in speed or behaviour they will feel.

What stays out, whatever the effort behind it:

- infrastructure, deployment, CI, scripts, README, dependencies, refactors: invisible, so absent;
- micro changes: a corrected label, a reworded sentence, a replaced image, a moved button;
- anything the person does not know exists (a cache, a quota mechanism, a model switch).

How to write it:

- the visible effect, never the mechanism. Raising the number of concurrent reads on the
  database becomes "Performance: the library and the series now open faster";
- a fix is one short sentence saying what now works. No cause, no frequency ("one time in
  three"), no model, call, search or API named. The technical story is in the commit message;
- never the app's name in an entry; never a line about which languages the app is available in;
- the tone of [08-copy.md](08-copy.md) applies in every language.

## Approval

The `French` entry is shown in the conversation and approved before the commit and
the tag. See [05-release.md](05-release.md).
