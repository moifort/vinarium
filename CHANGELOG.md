# Changelog

## 2026.07.15

### New
- First-launch onboarding: a setup flow greets you — enter your first name, then size your cellar (A→Z rows and slots per row). Pick your model from a catalog of retail wine coolers (search by brand or model, grouped by brand) for automatic sizing, or enter custom dimensions; the number of temperature zones is saved too.
- Cellar size is no longer fixed: it matches the dimensions chosen during setup, and both the placement grid and the displayed capacity adapt to them.
- Tab bar: it collapses automatically on scroll to enlarge the content area, and the Scan button stays pinned and separated on the right.
- Login screen: the logo animates on open — a mosaic of caps in the app's colors cascades in.
- Invitation links: opening a share link now launches the app straight onto the screen to join the household; if the app isn't installed, the page offers to download it from the App Store.
- Sharing: each invitation code shows a "Pending" badge.

### Fixes
- Sharing: the Copy link, Email and Revoke actions now trigger independently — one tap no longer fires all three at once.

## 2026.07.11

### New
- Cellar sharing: invite the people in your household with a code and share a single common cellar. Everyone keeps their own library, tasting notes and journal; only the bottles in the cellar are pooled.
- Shared cellar: every household bottle appears in the same grid, with the owner's name on other people's bottles. Any member can place, move, consume or gift any bottle; the removal is recorded in the wine owner's journal, and your tasting note stays yours.
- Another member's wine detail: the owner's name is shown and the reserved actions (edit, delete, recommend) are hidden.
- Global search: a magnifier in the toolbar opens a full-screen search. Type a wine name, producer, vintage or person — results are ranked by relevance and clearly grouped (in cellar, already drunk, gifts, recommended…). Combinable filters (color, type, favorite, in cellar, gifts) are offered above the results.
- Lists flag at a glance the bottles that are in the cellar (cabinet icon).
- Gifted and Recommended views: a new "By person" sort that groups the list by giver or recommender.
- Scan: the add popup now offers only "Store in cellar" and "Just record" — favorite and recommendation are set directly in the wine detail.
- Structured subtypes for every beverage (rum, port, blonde beer, sparkling sake…), offered in the forms and filled in by the AI analysis.
- A wine's color is once again its robe (red, white or rosé): Sparkling and Sweet become wine subtypes.
- Dashboard: the "In cellar" widget shows cellar occupancy — placed bottles over total capacity (e.g. 41/48), the total in smaller type.
- Settings screen reachable from the dashboard (top-left icon).
- User profile with sign-out.
- App version and changelog history.
- Cellar information (dimensions and number of placed bottles).
- JSON data export and import.

### Fixes
- The "My Wines" list shows again instead of an error message.

### Performance
- Faster lists, search and dashboard: the server batches and shares its reads, never loading the same wines several times nor scanning the whole cellar for a filter.
- Much faster detail view: the server now reads only the consulted wine's information instead of scanning the whole cellar.
