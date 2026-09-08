# Rescu — Solution

For AI tool, I used free tier chatGPT from chatgpt.com for this project.

## Part A — Bug tickets

### RES-101 · Search shows results for the wrong query

#### Problem

Type a word quickly in search — for example "sushi", letter by letter.
Frequently the final results do not match what is in the text box: correct
results appear briefly, then get replaced by results for an earlier, shorter
query. Team reproduces this most attempts. Users report "search is drunk".

#### Root cause

Function ```Future<void> _search(String query)``` in lib/feature/search/search_deals_controller.dart returns the query with the slowest response time, caused by multiple async searches at the same time.

#### Solution

This can be fixed with adding a string variable `lastQuery` and compare if the current query and lastQuery is the same, it will trigger api call, otherwise it will not, which will ignore response if a newer search has happened.

But with this implementation, every time a character entered in the search bar, it triggers an api fetch which might not be intended and causes the root cause stated above, adding debouncer will avoid all of those problems.

### RES-102 · Crash after leaving My orders

#### Problem

Open **My orders** while there is an order with an upcoming pickup, then
navigate back. Within a couple of seconds the app crashes in debug builds with
`setState() called after dispose()`.

#### Solution

### RES-103 · Requests pile up the longer you browse

#### Problem

After opening several deal pages, every tap on "Add to bag" triggers a burst
of `GET /deals/:id` requests — one for _each deal viewed earlier in the
session_, even for screens that were closed long ago. The app gets slower
and chattier the longer the session. Watch the console logs while browsing
to see it (every simulated request is logged).

#### Solution

### RES-104 · Duplicate deals in the home feed

#### Problem

Scroll to the bottom of the home feed so the next page starts loading, then
quickly pull down to refresh while it is still loading. Intermittently the
feed ends up with duplicated cards, or more items than the catalog contains.

#### Solution

### RES-105 · Home feed is janky and memory keeps climbing

#### Problem

On mid-range Android devices the home feed drops frames noticeably while
scrolling, and memory grows the further you scroll until the OS kills the app.
DevTools shows the entire feed rebuilding continuously during scroll, and the
image cache ballooning. There is more than one contributing cause — we expect
you to find and explain them, with before/after evidence from DevTools
(screenshots or numbers in `solutions.md`).

#### Solution

### RES-106 · Wrong pickup times; "Pickup today" filter misses deals

#### Problem

Multiple user complaints: a bakery that opens **06:00–09:30** shows
"Pick up 23:00 – 02:30" on its cards, and several stores with pickup slots
today never appear when the **Pickup today** filter is on. Some users showed
up at closed stores. The backend team insists their data is correct and
points out the API sends standard ISO-8601 UTC instants, like every API we
integrate with.

#### Solution

### RES-107 · Deep link opens to a crash

#### Problem

Marketing sends push notifications that deep-link to deals, e.g.
`rescu://open/deal?id=42&source=push`. Opening such a link crashes with
`type 'Null' is not a subtype of type 'DealModel'`. Opening the same deal
from the home feed works fine.

Requirement: the link must land the user on a fully working deal page (deal
42 exists in the catalog). Showing an error/fallback screen instead is not an
acceptable resolution for this ticket.

#### Solution

---

## Part B — Features

### F-1 · Live flash-sale countdowns

Flash deals (`flashSaleEndsAt` on the model) currently show a static
"Ends soon" badge. Replace it with a **live countdown** (`mm:ss`, or
`hh:mm:ss` above an hour) everywhere the deal appears: flash rail, home feed
cards, and the details screen.

Requirements:

- When a countdown reaches zero: the card switches to a disabled "Expired"
  state, the deal can no longer be added to the bag, and if it is already in
  the bag it is removed with a visible notice.
- The home feed must stay smooth with 100+ visible countdowns. We will
  profile your implementation with DevTools; per-second rebuilds must be
  scoped to the text that actually changes — not whole cards, not the whole
  list.

#### Solution

### F-2 · Impression tracking

Product wants view analytics on deal cards. Using `AnalyticsService`:

- Log a `deal_impression` event when a deal card has been **≥50% visible for
  at least 1 continuous second**. Properties: `deal_id`, `source`
  (`home_feed`, `flash_rail`, or `search`), `position` (index in its list).
- At most **once per deal per app session**, across all screens.
- Do not send events one by one: batch them and deliver via
  `FakeApiService.sendAnalyticsBatch` when either 10 events have accumulated
  or 15 seconds have passed since the first unsent event — whichever comes
  first.
- Scrolling performance must not regress.
- The `visibility_detector` package is already in `pubspec.yaml`; using it is
  allowed but not required.

#### Solution

### F-3 · Stock reservations with optimistic UI

Right now the bag is purely local, so two users can "add" the last bag and
one of them finds out only at pickup. The backend already exposes
reservations (see `FakeApiService.reserveDeal` / `releaseReservation`, and
`reservationId` on checkout): a reservation holds stock for **5 minutes** and
intermittently fails with a 409 when stock is contended.

Build reservation support into the bag:

- Adding to the bag reserves stock. The UI must respond **optimistically**
  (instant feedback), then reconcile: if the reservation fails, the item is
  rolled back out of the bag with a clear, non-technical message.
- Each bag line shows how long its reservation has left.
- Removing a line (or reducing quantity) releases/adjusts the hold.
- Checkout passes reservation ids; handle the `410 reservation expired`
  rejection gracefully.
- **Deliberately underspecified:** what should happen when a reservation
  expires while the user is still in the app (or mid-checkout)? Decide the
  product behaviour yourself, implement it, and justify the decision in
  `solutions.md`. There is no single right answer — there are wrong ones.

#### Solution
