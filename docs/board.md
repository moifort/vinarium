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
- **Outside the prototyping zone** (`Zone-Prototypage.dc.html`, page "App"): the change goes to
  iOS in two validations. First the board edit and its capture, and the user validates the
  design; only on that yes, SwiftUI, simulator screenshot, commit, and the user validates the
  simulator capture. No code before the board is validated.
- **Inside the prototyping zone**: board-only loops (edit, show, ask again), never iOS until the
  user says to build it.
- Every child's brief names the zone of the anchored artboard, and so where the child stops.
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

Comments sent from the board always land in the parent, never in a child. The parent forwards
each one on an active child's theme to that child (`SendMessage`, with the thread id, the
anchored artboard and the comment's exact words) and starts a new child only when no active one
covers the theme. A child rereads the board's open threads (`ArtifactComments`, `read`) before
every validation request and whenever a message wakes it, handles those on its theme and leaves
the rest.

Why a child does not always start at once: a comment sent from the board reaches the parent as
an automated turn, not as the user's own message, and the app refuses to start a session
(`user_asked`) on such a turn. The parent proposes it instead (`own_initiative`, a card the user
clicks). Over Remote Control the cards do not show and the app refuses the proposal too: the
parent then says in one line which thread is waiting. Either way, the user's next message in the
parent, whatever it says, is the go-ahead: the parent starts every waiting child first
(`proposal_id`, or `user_asked` with the same brief when nothing could be proposed), then answers
the message. It never asks for a keyword. After a clear, the waiting threads are the open ones
sent to Claude with no child (`ArtifactComments`, `read`).

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
