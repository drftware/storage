# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 126 (S1-06 Pay and keeping at the gate) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **S1-06 is built** (D-138). The instant a floor's gate hits its post with friends aboard,
  Climbs fires `shut`; `GatePay` pays each rider who is alive and not wrapped `Pay.owed` (10 on
  floor 1, 2 more a floor, once a floor a climb) through `Coins:pay`, and keeps their finds
  (`Slots:keep` takes them out of the slots, a gold spark where the one in hand was;
  `Save.keep` adds them to the save and stamps the book; written at once). The rider's screen
  hears first on the `GatePay` remote: CoinView bursts the coins into a ring and pours them into
  the count with climbing ticks, the "Coin Throws 3" clatter and a gold "+N"; KeepView lifts each
  kept find from the slot box on a gold-rimmed disc with a ring, sparks and its own sound, then
  flies it off the top. Specs: `tests/pay.spec` (pay, split, `Carry.keep`, `Save.keep`).
- **Seen in Studio Play, the screen only:** `GatePay:FireClient(player, 22, {Teddy, Boombox})`
  from the Server: 12 coins burst at about (650, 300), the count went 34 to 56 as they landed,
  "+22" in at 0.6 s and gone by 3.6 s; the teddy rose from the box (70 points) to 147 at (498,
  412) with the boombox beside it, two rings, 7 sparks each, both gone by 2.4 s.
  **Not seen:** a real ride paying (Climbs `shut` to GatePay to the save), the friends' spark.
- Studio left in Edit, `DevFloorSeed` untouched (7); the place isn't saved by me.
- The GDD (D-127, D-128) is the newer word; ROADMAP Phase 2 is its build order.

## Next task: S1-02 Recording
The moment: none on screen. Every coin earned and spent, every find kept, every floor reached
is recorded, so things have a known worth before anything is priced (the ride's machine, S1-10).
1. Read ROADMAP S1-02 and the GDD "What the game needs to record" (docs tools, search "record").
2. Brix ENG-12a and 12b are on Brix `main` (`6717740`, in `../engine`, never edit it): bump the
   pinned Brix the way S1-01 did for Saves (docs/FRAMEWORK.md), and list what's adopted there.
3. Write the game's plan as a pure shared module (fields, events, economy: currency "Coins",
   reasons such as pile and gate; funnels; progress paths), names and labels short (under 50
   bytes), with a Lune spec against `Brix.AnalyticsSink.recorder()`.
4. A server `Recording` system holding `Brix.Analytics.new({ plan, sink })` with
   `Brix.Roblox.AnalyticsSink.analyticsService()`, and a gentle `onProblem` (Brix warns per
   record past 120 + 20 a player a minute). Record from where things happen: Coins' take
   (earned, pile), GatePay (earned, gate; finds kept), floors reached (Climbs), climb ends.
5. Studio Play: take a pile, ride once; say what Output shows (Studio prints AnalyticsService's
   own lines) and what the recorder spec proves.
**Acceptance:** checks green; specs prove the plan and each record; what's seen in Play said.
**Read first:** ROADMAP S1-02; GDD "What the game needs to record"; `docs/FRAMEWORK.md`;
`../engine` Analytics' README or init (`Brix.Analytics`, `AnalyticsSink`); `src/server/Saving.luau`
(how S1-01 adopted Brix); `src/server/GatePay.luau`.

## Queue (the overnight run, owner Nov 13: sessions until 8:30am, the updated plan)
1. S1-02 (next), then ROADMAP Phase 2 in order (S1-07 What a door holds). S2-06 and L-08e3c
   wait on `OWNER.md`. Lobby polish waits.
2. Found S1-06: a real ride's pay, the save write and the friends' spark are unseen in Play
   (`OWNER.md` has the steps); a "New" mark on a find kept the first time is polish (ROADMAP).
3. Found S1-05: the finds' places in your view (moved after one look) are unseen in Play; a find
   standing in a unit can be walked through (inert, as a lying tool; polish list).
4. Found S1-04b2: keepers move on their own map and don't know about stuff, so one could walk
   through it; the heap's front reaches 7.2 into an M unit. A player can likely jump onto it.
5. Found S1-04b1: the stacks' boxes all wear the same few marker words (polish list).
6. Found S1-01: arriving on another server, the save claim may wait up to 5 s if the lobby's
   let-go lands after you. If too slow, a Brix ticket in neutral terms.
7. Found S1-03: Deal's padlock count is a share of the units; S1-07 sets padlocks afresh.
8. Found L-08e3b: a lobby car's `far` isn't cleared when its group's trip fails; it ages out.
9. Found L-08e4b1: no PlayerModule in PlayerScripts in Play, so WatchView's `controls` lookup
   fails quietly (untested).
10. Seen (owner, Nov 12, "fix them later"): lobby car floors splotchy inside; a sawn side or top
   flashes see-through as its panel drops; the lobby car's lamp very dim.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
