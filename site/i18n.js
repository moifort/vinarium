/* Vinarium landing page: English for every browser that is not set to French.
 * The page is written in French; elements carrying data-i18n get their English
 * HTML from here before the first paint (the head script hides the page until
 * then). data-i18n-aria translates an aria-label, data-i18n-alt an image's alt. */
;(() => {
  const root = document.documentElement
  if (!root.classList.contains('i18n-en')) return

  const EN = {
    'meta.title': 'Vinarium · Snap a label, your cellar sorts itself',
    'nav.tour': 'Tour',
    'nav.features': 'Features',
    'nav.pricing': 'Pricing',
    'nav.faq': 'FAQ',
    'nav.download': 'App Store',
    'hero.title': '<span class="gradient-text">Your cellar<br>in your pocket.</span>',
    'hero.subtitle':
      'One photo of the label is enough. The record fills itself in, every bottle finds its slot, and the cellar is shared with the household.',
    'aria.store': 'Download on the App Store',
    'store.small': 'Download on the',
    'hero.meta': 'iPhone · iOS 26',
    'alt.cellar': 'The cellar: the bottles row by row, each in its slot',
    'alt.dashboard':
      "Home: the bottles in the cellar, the cellar's value and the wines ready to drink",
    'alt.wines': 'My wines: the collection month by month, with estate, vintage, region and price',

    'tour.title': 'Your whole cellar.<br>In one app.',
    'tour.lead': 'The essentials, screen by screen.',
    'tour.scan.title': 'One photo, the record fills itself in.',
    'tour.scan.text':
      'The label is enough: name, estate, cuvée, vintage, appellation, region. The record arrives ready to check, and every field can be corrected with a tap.',
    'tour.scan.alt': 'Review the bottle: the photo of the label and the record filled in from it',
    'tour.cellar.title': 'Every bottle in its slot.',
    'tour.cellar.text':
      'The cellar is laid out by row and column, like the real rack. A1, B3: the bottle is found without opening the door.',
    'tour.cellar.alt': 'My cellar: row A and row B, each bottle in its slot',
    'tour.wines.title': 'The whole collection.',
    'tour.wines.text':
      'The wines added, month by month, with their estate, vintage, region and price. Favorites, gifts and recommendations one tap away.',
    'tour.wines.alt':
      'My wines: Pavillon Rouge du Château Margaux, Priorat Clos Mogador, Meursault Les Charmes',
    'tour.detail.title': 'Every wine, its full record.',
    'tour.detail.text':
      'Its slot in the cellar, its estate, cuvée, vintage, appellation and region. And on the map, the place where the bottle was discovered.',
    'tour.detail.alt': 'The record of the Pavillon Rouge du Château Margaux 2015, in slot A1',
    'tour.home.title': 'The cellar at a glance.',
    'tour.home.text':
      'The bottles in the cellar, their value, the wines ready to drink, the favorites and the latest moves.',
    'tour.home.alt': "Home: 18 bottles out of 48, the cellar's value and five wines ready to drink",
    'tour.journal.title': "The cellar's journal.",
    'tour.journal.text':
      'Every bottle in and every bottle out, dated, with its slot. Nothing gets lost between two dinners.',
    'tour.journal.alt': 'The journal: the bottles in on October 4, each with its slot',

    'feat.title': 'Everything a cellar asks for.',
    'feat.lead': 'Every bottle finds its place, the rest takes care of itself.',
    'rack.name': 'Living room cellar',
    'rack.title': 'The cellar, slot by slot',
    'rack.text':
      'The grid mirrors the rack: rows, columns, capacity. A bottle is placed with a tap, moves from one slot to another, and the home screen shows how full the cellar is.',
    'ready.head': 'Ready to drink',
    'ready.tag': 'Before 2027',
    'ready.title': 'Ready to drink',
    'ready.text':
      'From their drinking window, the home screen brings up the bottles to open soon, before they pass their peak.',
    'kinds.aria': 'Wine, champagne, port, whisky, rum, sake, beer and cider',
    'kinds.red': 'Red wine',
    'kinds.champagne': 'Champagne',
    'kinds.port': 'Port',
    'kinds.whisky': 'Whisky',
    'kinds.rum': 'Rum',
    'kinds.sake': 'Sake',
    'kinds.beer': 'IPA beer',
    'kinds.cider': 'Cider',
    'kinds.title': 'Not just wine',
    'kinds.text':
      'Champagne, port, whisky, rum, sake, beer or cider: every drink has its place in the cellar, with the details that belong to its kind.',
    'search.head': '1 result',
    'search.region': 'Burgundy',
    'search.title': 'Search that understands',
    'search.text':
      'Name, estate, cuvée, region, vintage or person. “pucelles” finds a Puligny-Montrachet Les Pucelles, “champagne” finds the sparkling wines, forgotten accents included.',
    'describe.region': 'Burgundy',
    'describe.title': 'No photo, one sentence',
    'describe.text':
      'No label at hand? A description is enough, for example “William Fèvre Chablis 2019”, and the record fills itself in the same way.',
    'note.sample': 'Black olive and violet, still tight. Open again in five years.',
    'note.people': 'With Lamia and Guillaume',
    'note.title': 'Tasting notes',
    'note.text':
      'Stars, a comment, the date and who was there. A heart marks the wines that left a mark. Every bottle opened leaves a memory.',
    'household.code': 'Invitation code',
    'household.you': 'You',
    'household.shared': 'Shared cellar',
    'household.private': 'Notes, favorites and journal kept private',
    'household.title': 'One cellar for the whole household',
    'household.text':
      'An invitation code is all it takes. Everyone stores, moves or tastes the bottles of the shared cellar, and keeps their own notes, favorites and journal.',
    'gift.by': 'Gift from',
    'gift.name': 'Camille',
    'rec.by': 'Recommended by',
    'rec.name': 'Hugo',
    'gift.title': 'Given, received, recommended',
    'gift.text':
      'A record of the wines given, received or recommended by a friend, with each name. The day the bottle is opened, everyone knows whom to thank.',
    'place.title': 'Where the wine was discovered',
    'place.text':
      'The place can be saved at scan time: the record shows on the map the restaurant or the estate where the bottle was tasted.',
    'files.head': 'Attachments',
    'files.invoice': 'Invoice',
    'files.sheet': 'Tech sheet',
    'files.photo': 'Back label',
    'files.title': 'Invoices and tech sheets',
    'files.text':
      "Up to five photos or documents per wine, under “Attachments”: the invoice, the producer's tech sheet, the back label.",
    'estimate.price': 'Estimated price',
    'estimate.window': 'Drink',
    'estimate.years': '2024 to 2040',
    'estimate.region': 'Region',
    'estimate.title': 'Price and drinking window',
    'estimate.text':
      'With Premium, every scanned bottle gets an estimate of its price, its drinking window and its region.',
    'cellars.one': 'Living room cellar',
    'cellars.two': 'Cellar room',
    'cellars.three': 'Serving fridge',
    'cellars.title': 'Several cellars',
    'cellars.text':
      'One cellar per rack or per room, each with its name and its grid, and a bottle moves from one to another. With Premium.',
    'export.wines': 'wines',
    'export.notes': 'notes',
    'export.moves': 'moves',
    'export.action': 'Export',
    'export.title': 'Your data stays yours',
    'export.text':
      'No ads, no tracking. The whole cellar exports and imports back from Settings, under “Profile”.',

    'dl.title': 'Free, or Premium without limits',
    'dl.lead':
      'The cellar, the journal and sharing are free and unlimited. Only the scan is counted.',
    'plan.free.name': 'Free',
    'plan.free.price': '€0',
    'plan.free.lead': 'No time limit.',
    'plan.premium.tag': '7-day trial on the yearly plan',
    'plan.premium.price': '€2.99&nbsp;/&nbsp;month',
    'plan.premium.lead': 'or €24.99 a year',
    'plan.row.scan': 'Label scan',
    'plan.row.scan.free': '20 included, then 5&nbsp;/&nbsp;month',
    'plan.row.scan.premium': 'Unlimited*',
    'plan.row.estimate': 'Estimated price, window and region',
    'plan.row.cellars': 'Several cellars',
    'plan.row.cellar': 'Cellar grid and journal',
    'plan.row.notes': 'Tastings, favorites and gifts',
    'plan.row.household': 'Household sharing',
    'plan.row.manual': 'Adding by hand',
    'plan.unlimited': 'Unlimited',
    'plan.row.ads': 'Ads',
    'plan.none': 'None',
    'plan.note':
      '*&nbsp;Fair use: 100 scans a month. The subscription is managed and cancelled in the App Store.',
    'dl.code': 'View the code',
    'dl.meta': 'iPhone · iOS 26 · Seven languages',

    'faq.title': 'Frequently asked questions',
    'faq.q1': 'How is the label read?',
    'faq.a1':
      'The photo is read by an artificial intelligence that pulls out the name, estate, cuvée, vintage, appellation and region. The record arrives to be checked before it enters the cellar, and every field can be corrected. An unreadable label? One sentence is enough, or typing it in by hand.',
    'faq.q2': 'How much does it cost?',
    'faq.a2':
      'Free, with 20 scans included when the account is opened, then 5 a month. The cellar, the journal, search and household sharing are free and unlimited, and a bottle can always be added by hand. Premium, €2.99 a month or €24.99 a year with a 7-day trial, lifts the scan limit, estimates the price and the drinking window, and opens several cellars.',
    'faq.q3': 'How does household sharing work?',
    'faq.a3':
      'Sharing starts from Settings, with an invitation code to pass on. Every member of the household stores, moves or tastes the bottles of the shared cellar, from their own iPhone and their own account.',
    'faq.q4': 'What do the other members of the household see?',
    'faq.a4':
      "The bottles placed in the shared cellar, with the name of whoever stored them. Everyone's tasting notes, journal and favorites stay private.",
    'faq.q5': 'Where does my data go?',
    'faq.a5':
      'Sign in with an Apple account, email can be hidden. The cellar is hosted on Google Cloud, in Europe. The photo of a label is used to read it, and stays cached with no link to whoever took it. No ads, no tracking, and the whole cellar exports from the app. The details are in the <a href="privacy.html">privacy policy</a> (in French).',
    'faq.q6': 'Which devices, which languages?',
    'faq.a6':
      "iPhone, iOS 26. In English, French, German, Spanish, Italian, Japanese or Portuguese, following the phone's language. Labels are read in every language.",

    'footer.credit':
      'Vinarium is an app by <a href="https://github.com/moifort" rel="noopener">Polyforms</a>.',
    'footer.source': 'Source code',
    'footer.issues': 'Report an issue',
    'footer.privacy': 'Privacy',
  }

  for (const el of document.querySelectorAll('[data-i18n]')) {
    const text = EN[el.dataset.i18n]
    if (text !== undefined) el.innerHTML = text
  }
  for (const el of document.querySelectorAll('[data-i18n-alt]')) {
    const text = EN[el.dataset.i18nAlt]
    if (text !== undefined) el.alt = text
  }
  for (const el of document.querySelectorAll('[data-i18n-aria]')) {
    const text = EN[el.dataset.i18nAria]
    if (text !== undefined) el.setAttribute('aria-label', text)
  }
  document
    .querySelector('meta[name=description]')
    ?.setAttribute(
      'content',
      'Snap a label: the estate, cuvée, vintage, appellation and region are filled in. Every bottle finds its slot in the cellar grid, and the cellar is shared with the household. Free on iPhone.',
    )
  root.lang = 'en'
  root.classList.remove('i18n-pending')
})()
