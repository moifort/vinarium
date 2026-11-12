# Landing page

Every product gets a page that sells it. It lives in the project's repository (`site/`), static,
no build step, published by the Pages workflow on the project's domain
(`<app>.polyforms.co`), next to the privacy policy and the support page the store requires.
Shiori's page is the reference.

## What it is for

One job: a person who does not know the product understands in ten seconds what it does for
them, and in two minutes wants to install it. Everything on the page serves that; nothing explains
how the product is built.

## Structure

In this order, each section one screen tall at most:

1. **Hero.** A title of a few words that says the benefit, not the feature ("Your library in your
   pocket."), a subtitle of two or three short sentences, the store badge, the platform line. The
   product's own home screen beside it.
2. **Tour.** The product screen by screen: for each, a title that is a promise ("One photo, the
   rest follows."), two sentences of what happens, the real screen. The essentials only, in the
   order a new user meets them.
3. **Features.** Everything else the product does, as cards with the app's own icons and one
   sentence each. The section lead does not repeat the hero.
4. **Compare.** Free against paid, as a feature table, the way the store's paywall presents it.
   The paid plan's name and prices are the store's.
5. **FAQ.** The questions a careful buyer asks: price, data, privacy, deletion, what happens
   offline, what the AI does with a photo. Short answers.
6. **Download.** The free plan set beside the paid one, the store badge again.

Then a footer: privacy policy, support, the company.

## Copy

The tone of [08-copy.md](08-copy.md) applies in full, plus:

- **Benefit first.** Every title says what the person gets; the feature is in the sentence
  under it.
- **Short.** A title under eight words, a paragraph under three sentences. The whole page reads
  in two minutes.
- **The product's name is not in the copy.** It is in the logo and the title tag; the sentences
  talk to the reader about their life, not about the app.
- **Concrete.** Numbers and examples over adjectives: "thirty books without pulling out a single
  one", not "fast and powerful".
- **Honest.** Nothing the shipped product does not do. A feature that is coming is not on the
  page.

## Screens and images

- **Real screens only**, from the showcase captures ([07-appstore.md](07-appstore.md)), never a
  mock-up drawn by hand or by a model. Each image has an `alt` that says what the screen shows.
- **The app's own icons** (its SF Symbols) for every card, so the page and the app share a
  visual language.
- **Real people's data** on the screens is shown with their agreement, and reads as real (a
  friend's actual reading), never as lorem ipsum.
- An Open Graph image and a favicon derived from the app icon.

## Languages

The page is written in the source language in the HTML; `i18n.js` carries the translation for
every element marked `data-i18n` (text), `data-i18n-alt` (image alt), `data-i18n-aria`,
`data-i18n-src` (a screen or a cover swapped for its edition in that language), applied before the
first paint from the browser's language. Every screen and mock is translated, down to the spines
on a shelf: a French screen on an English page breaks the illusion. A language switch is visible
in the nav.

## Publishing and checks

- `site/**` triggers the Pages workflow and nothing else; never `[skip ci]` on a site commit
  ([04-push.md](04-push.md)).
- Before pushing, open the page in the built-in browser in both languages, at phone and desktop
  widths, and send a screenshot: the page is a UI change like any other
  ([01-workflow.md](01-workflow.md#screenshot-after-every-ui-change)).
- The privacy policy page states what is collected, by whom, for how long, and how to delete the
  account, in the source language and in English; the store listing links to it.
