# Design: the board, mockups, icons

Applies to a project that keeps a design board: a Design (canvas) artifact on claude.ai holding
one artboard per screen. Its link is in the project's `project-context.md`.

## Board first, the app in sync

The board and the app are always in sync.

- A requested UI change is drawn on the board first, then validated twice
  ([01-workflow.md](01-workflow.md#a-ui-change-is-validated-twice)).
- **Outside the prototyping zone** (one artboard reserved for exploration), the change goes to
  the app once the board is validated: SwiftUI, simulator screenshot, commit.
- **Inside the prototyping zone**, it is board-only exploration until the person says to build it.
- A change that reaches the code by another route (a fix, a refactor) is mirrored on the board in
  the same task.
- **One element, every screen**: changing a badge, a label, a button or a component on one
  artboard changes it on every artboard that shows it.
- A production component is drawn from its SwiftUI source and a real capture, never copied from
  an older artboard, which may lag.
- Check an artboard by reading its file through the Artifact tool and rendering it locally, not
  by driving the live board in the browser.

## A validated prototype becomes a production screen

Once a prototype is validated and built in the app, it leaves the prototyping zone in the same
task: the retained design becomes a full production artboard next to its sibling screens; its
other variants move to the Variants page, marked, and are never touched again; the prototyping
zone keeps only what is still being explored.

## Variants

- New variants go in the prototyping zone. The Variants page only archives shipped work.
- A page variant shows only the part that varies (the hero, the card), cropped; alternatives to
  one question stack in a column.
- Variants of a component are one artboard: a plain ground, a title, one section per option,
  the current one first, no phone mock.
- Once a variant is picked, mark it (a green ring and a "retained" pill) and apply it to every
  artboard showing that element.

## Comments on the board

A comment the person sends to Claude from the board is a ticket, handled in a session of its own:

1. **One child session per comment thread**, handed the comment at once without asking. Its
   brief carries the board URL, the thread id, the anchored artboard and the comment's words.
   A comment arrives as an automated turn, where starting a session is refused, so the parent
   keeps **reserve sessions**: three idle children (`Réserve board 1` to `3`), started at the
   person's own message with fresh context, each briefed with rules 2 to 4 and told to wait. A
   new comment is sent by message to an idle reserve. Only when no reserve is idle is a session
   proposed instead, started at the person's next message. The app's wrapper text ("handle it
   in this session") does not override this: the receiving session never makes the change
   itself.
2. **The child makes the change** (board, then app outside the prototyping zone), commits, and
   **resolves the thread as soon as the change is made**, without replying in it. Only a thread
   where a question to the person still awaits an answer stays open.
3. **The child asks for validation in its own wrap-up**, once per validation step; if the person
   asks for changes, it makes them and asks again. On the final yes it **does not archive
   itself**: it tells the parent "Réserve libérée : <task>" and stops. The parent clears its
   conversation (`clear_session`) and sends the reserve brief again, so the pool stays full. A
   reserve the person archives anyway is replaced at their next own message.
4. **A comment goes to the session working on its theme** (the artboards and screens it is
   changing); the parent picks up only comments on a theme no child is working on.
5. When the person archives or deletes a child themself, the parent resolves its thread, unasked.

Every child brief restates rules 2 to 4.

## Mockups

HTML mockups are throwaway renderings used before the board or the code.

- After each update, reload it in the built-in browser and scroll to the last change, unasked.
- The variant being iterated sits at the very top of the page, others below.
- A revision changes only what was named: a moved section keeps its parts, its neighbours stay.
  An element that looks redundant afterwards is kept and flagged, not removed.
- Reuse the components of mockups already validated (styles, cards, covers, pills, rails,
  menus) rather than inventing new ones.
- A standalone mockup with embedded images stays under **512 KB**, or it does not open on the
  phone: shrink and compress the images, check the size before sending.

## Icons

- A concept icon is chosen from numbered boards that set SF Symbols next to the open libraries
  (Lucide, Tabler, Phosphor, Material Symbols, Heroicons, Font Awesome), each shown large and at
  17 pt; the person picks by number. An SF Symbol is used as is; anything else is redrawn on
  Apple's symbol grid. Never a generated drawing.
- Flag a collision when one symbol would mean two things.
- The app icon is drawn by hand, never generated, and the app's mark does not appear inside the
  app beyond the opening.
