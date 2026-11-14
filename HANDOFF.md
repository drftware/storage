# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 127 (S1-02 Recording) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **S1-02 is built** (D-139); Brix moved to `6717740` (Analytics). `Record` (shared, pure) is the
  plan and a book with one method per moment; `Recording` (server, last in the Host's list)
  sends each through Brix's Analytics to AnalyticsService, listening to new signals: Coins'
  `earned` (pile, gate), Deals' `dealt` now naming who opened the unit, GatePay's `kept`,
  KeptPlayers' `freed`, ClimbEnds' `ended` and `again`, LobbyCars' `departed`. Spec:
  `tests/record.spec` (168 checks: every record in order, the funnel once a climb, labels, refusals).
- **Seen in Studio Play** (lobby Car3, Go, floor 1 of `LobbyClimb`): `carLeft 16.6 (team 1)`, floor
  1 started, funnel began; Unit102 `doorOpened (gave nothing)`, `firstDoor 71`; Unit101 `gave
  coins`, `earned 2 Coins (pile), now 2`; code 9463, aboard: `earned 10 Coins (gate), now 12`,
  floor 1 completed, funnel rode, floor 2 started; kept set by hand: `climbEnded 2 (fate kept,
  team 1)`, floor 2 failed; Again: `again 1`. Each with AnalyticsService's "event fired" line; no
  record dropped. **Not seen in Play:** `caught`, `freed`, `findKept` (the spec covers them).
- Studio left in Edit, `DevFloorSeed` untouched (7); the place isn't saved by me.
- The GDD (D-127, D-128) is the newer word; ROADMAP Phase 2 is its build order.

## Next task: S1-07 What a door holds
The moment: you cut a padlock and the unit behind it is always worth it, sometimes great, and
sometimes a monster wakes in it. Tools rarer (about one unit in twelve, from one in five).
1. Read ROADMAP S1-07 and the GDD on padlocked doors and what units hold (docs tools, search
   "padlock" and "battery"). Note Queue 6: Deal's padlock count is a share of the units today.
2. A battery in about one unit in ten needs the battery's art (the unit's way, `art/`) and the
   flashlight running down (S1-09). If no battery art exists, split S1-07 in ROADMAP first:
   S1-07a padlocked doors and the tool odds now; S1-07b batteries with S1-09.
3. In `Deal` (pure): a padlocked unit never deals Nothing; it draws from a better table (a find
   or a tool, the best chance of a great find and of a keeper). Tools at about 1 in 12. Keep
   every seed's other draws where they are if you can (coins were drawn last for that, D-132).
4. Lune: deal.spec over many seeds (padlocked always hold something; the shares within bounds).
5. Studio Play: cut a padlock (dev floor, seed 7) and say what Output's `Deals:` line shows;
   `Recording` prints `doorOpened (gave ...)` for it.
**Acceptance:** checks green; the spec proves the odds; what's seen in Play said.
**Read first:** ROADMAP S1-07; GDD (search "padlock"); `src/shared/Deal.luau`;
`tests/deal.spec.luau`; `src/server/Deals.luau` (how a padlocked unit is set); D-131 and D-132 in
`docs/DECISIONS.md`.

## Queue (the overnight run, owner Nov 13: sessions until 8:30am, the updated plan)
1. S1-07 (next), then ROADMAP Phase 2 in order (S1-08 Tools wear out). S2-06 and L-08e3c wait
   on `OWNER.md`. Lobby polish waits.
2. Found S1-02: in Studio the test hall begins a climb on floor 3 as the server starts, so Studio
   records "climb floor 3 started" before any lobby car (Studio only). An onboarding funnel and
   the trip carrying the lobby join time are listed under S1-02 in ROADMAP.
3. Found S1-06: a kept find's save write and the friends' spark are unseen in Play (a real
   ride's pay is now seen); a "New" mark on a find kept the first time is polish (ROADMAP).
4. Found S1-05: the finds' places in your view (moved after one look) are unseen in Play; a find
   standing in a unit can be walked through (inert, as a lying tool; polish list).
5. Found S1-04b2: keepers move on their own map and don't know about stuff, so one could walk
   through it; the heap's front reaches 7.2 into an M unit. A player can likely jump onto it.
6. Found S1-03: Deal's padlock count is a share of the units; S1-07 sets padlocks afresh.
7. Found S1-04b1: the stacks' boxes all wear the same few marker words (polish list).
8. Found S1-01: arriving on another server, the save claim may wait up to 5 s if the lobby's
   let-go lands after you. If too slow, a Brix ticket in neutral terms.
9. Found L-08e3b: a lobby car's `far` isn't cleared when its group's trip fails; it ages out.
10. Found L-08e4b1: no PlayerModule in PlayerScripts in Play, so WatchView's `controls` lookup
   fails quietly (untested).
11. Seen (owner, Nov 12, "fix them later"): lobby car floors splotchy inside; a sawn side or top
   flashes see-through as its panel drops; the lobby car's lamp very dim.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
