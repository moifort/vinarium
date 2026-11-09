# The Vinarium Board

How the design board and the iOS app stay in sync, and how a comment on the board is handled.
The comment workflow itself is in [CLAUDE.md](../CLAUDE.md#board); this page is the rest of the
board's working rules. They are the Shiori Board's, carried over as they are.

## What the board is

"The board" / "the canvas" is the **Vinarium Board**, a Design (canvas) artifact:
https://claude.ai/artifact/A2GU9AgwrjxJM1c8Nb6jGA. It is not the SwiftUI previews.

- One `project/<Name>.dc.html` artboard per screen, in rows by feature on the page "App":
  opening (`Ouverture`, `Connexion`), onboarding (`Onboarding-*`), home (`Main`, `Accueil-*`),
  cellar (`Cave-*`, `Journal*`, `Nouvelle-cave-*`), wines (`Vins-*`), wine sheet (`Fiche-*`,
  `Deplacer*`), scan (`Scan-*`), search (`Recherche*`), settings, Premium (`Premium-*`), admin
  (`Admin*`).
- Layout lives in `project/canvas.json` (`boards`, `order`). A new artboard sits 80 px from its
  siblings in the same row, with its `boards` entry and `order` slot.
- Every screen carries a `mode` tweak, `Clair` by default or `Sombre`: `renderVals()` turns it into
  `themeClass` on the root, and `.ph.dark` swaps the CSS colour tokens. A new artboard takes the
  same tweak and uses the tokens, never a raw colour for anything that changes with the theme.

## Board first, then code

SwiftUI and the board are always in sync.

- A requested UI change is drawn on the board first, then sent as a capture.
- **Outside the prototyping zone** (`Zone-Prototypage.dc.html`, page "App"): the change goes all
  the way to iOS in the same task — board edit, capture, SwiftUI, simulator screenshot, commit.
- **Inside the prototyping zone**: board-only exploration until the user says to build it.
- A change that lands in code by another route (a fix, a refactor) is mirrored on the board in
  the same task.
- **One element, every screen**: changing a badge, label, button or component on one artboard
  means changing it on every artboard that shows it.
- A rail holding a single card draws it full width (353 px on a 393 px phone), as iOS does.
- A prod component is drawn from its SwiftUI source and a real capture, never copied from an
  older artboard, which may lag.

## Validated prototype = production screen

Once the user validates a prototype and it is built on iOS, it leaves the prototyping zone in the
same task:

- the retained design becomes a production artboard on the page "App", next to its sibling
  screens (as a full screen, not cropped), drawn from the SwiftUI source and a real capture;
- every other variant of that prototype moves to the Variants page, marked as in the
  "Variants" section below, and is never touched again;
- the prototyping zone keeps only what is still being explored.

## Variants

- New variants and explorations go in the prototyping zone. The "Variants" page only archives
  shipped work: once built, a prototype's variants move there and are never touched again.
- A variant artboard shows only the part that varies (the hero, the card), cropped in root
  height, `$preview` and its `boards` `h`. Alternatives to one question stack in a column,
  80 px apart.
- Variants of a component are ONE artboard: a plain ground, a title, one section per option, the
  current one first, no phone mock. A phone mock only for page variants.
- Once the user picks a variant, mark it (3 px `#30d158` ring and a green "✓ Retenue" pill), then
  apply it to every artboard showing that element.

## Comment sessions

The comment rules of CLAUDE.md: one child session per comment, started without asking (a card
when the app refuses the start from an automated turn), the child resolves each thread it
handles as soon as the change is made and archives itself on the user's validation, the parent
resolves the thread of a child the user closed themself, and a new comment goes to the child
working on its theme, or to the parent when no child is.

The parent stays light (it only dispatches, one line per comment) and is cleared every morning
at 6:00: the scheduled task `vinarium-clear-parent` sends it "Clear du matin", and it calls
`clear_session` on itself (CLAUDE.md, Board, rule 6).

## Capturing artboards

Artboards reference images by a relative path (`./img/…`) or as `/_blob/<id>`, served only by the
board's frame origin.

1. In the built-in browser open the board, read `document.querySelector('iframe').src`.
2. In a second tab open that `_t` URL, then `https://<id>.frame.claudeusercontent.com/x`.
3. There, `fetch('/_f/<version>/project/<Name>.dc.html')`, drop the `support.js` line, put each
   file in an `iframe.srcdoc` sized to its `$preview`, and screenshot.

Every publish makes a new version and invalidates the token: repeat steps 1–2. Fresh PNG uploads
can answer 404 on the frame origin; publish them as support files under `project/` instead.
