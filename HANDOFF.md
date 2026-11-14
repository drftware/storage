# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-13, session 119 (S1-03 Half the units) · **Checks:** green ·
**Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **S1-03 built (D-131), passes checks, untested in Studio** (wrapped at the context cap before
  the look). `Floor`'s step 5b walls whole hall sides to about 30 units on floors 1 and 2 and 40
  above; a side kept in every wing; the first 8 doors past the lobby stay on floors 1 and 2; no
  more than 4 bare hall pieces in a row. Lune floor.spec covers counts, wings, bare stretches.
  `holetrap.spec` now lays seed 7 with every unit (it replays an old Studio run by number).
- **Studio syncs again** (owner clicked Connect, Nov 13 23:30). L-08e4b2 Home again is verified
  in Studio Play, and a bug found there is fixed (`Carts.inWay`: a rider put off at the stripes
  held their own cart). L-08e3b: the panel's Invite, Share, Go seen; Share gets HTTP 403 in
  Studio (live only). Details in ROADMAP and `OWNER.md`.
- A Brix session may run in `../engine` with a second Studio open on its own place: target
  only the Studio named "Storage (placeId: 113250085204323)" by its `studio_id`.
- The GDD (D-127, D-128) is the newer word; ROADMAP Phase 2 is its build order. The GDD says
  "monsters"; the code says keepers.

## Next task: S1-04a Coins
The moment: you roll a door up and there's a glint of coins on the concrete; a tap and they're
yours with a chink, a little count ticking up. Most doors pay something, so every door is worth
the noise (the GDD's loop and "Doors"). S1-01 waits on Brix ENG-10c, S1-02 on Brix ENG-12: skipped.
1. First, in Edit, check Studio has the code (`ReplicatedStorage.Shared.Floor.Source` contains
   `BareMost`). If it does, do S1-03's look (`OWNER.md` "judge S1-03": count floor 1 and floor
   3 from Output; a hall at phone size) and fix what fails first.
2. Read only the GDD's lines on coins (docs tools, never WebFetch: a `search` read for
   "coin") and ROADMAP S1-04a.
3. Art first, the unit's way (`art/unit/README.md`): `art/coin/` builds a coin (and a small
   scatter of one to three) in Blender headless, its Specs module, the FBX, look sheets.
4. The deal (`Deal`) picks about seven units in ten and how many coins each (1 to 3), a Config
   feel number with a comment; Lune specs for the share and the spread.
5. Server owns the coins and the count (validated, rate-limited pick-up); each player's count
   is their own, for this climb only. A tap: the coin lifts and is gone with a chink, the count
   pops. Every action answers; nothing saved yet (S1-01).
**Acceptance:** checks green; Lune specs for the deal's coins; verified in Studio Play (coins in
an opened unit, a pick-up, the count) or "untested in Studio" with steps in `OWNER.md`.
**Read first:** ROADMAP S1-04a; the GDD's lines on coins; `art/unit/README.md`;
`src/shared/Deal.luau`; CODEMAP rows for Deal, DealSpot and FloorBuilder; `tests/deal.spec.luau`.

## Queue (the overnight run, owner Nov 13: sessions until 8:30am, the updated plan)
1. S1-04a (next), then ROADMAP Phase 2 in order. S1-01 Saving waits on Brix ENG-10c (ENG-10b
   is done); S1-02 Recording waits on Brix ENG-12. Take them when Brix ticks them. S2-06 waits
   on `OWNER.md`. Lobby polish ("The ride's finish", "The dials' finish") waits. L-08e3c waits
   on `OWNER.md`.
2. Found S1-03: Deal's padlock count is a share of the units, so floors now get about half as
   many padlocks. S1-07 ("What a door holds") sets padlocks afresh; leave it till then.
3. Found L-08e3b: a lobby car's `far` (the group it sent) isn't cleared when that group's trip
   fails and they're back in the car; it just ages out after `Trip.WordStale`. Harmless.
4. Found L-08e4b1: no PlayerModule in PlayerScripts in Play (STUDIO.md), so WatchView's
   `controls` lookup fails quietly (controls may stay on while you watch; untested).
5. Seen (owner, Nov 12, "fix them later"): lobby car floors go splotchy inside; a sawn side or
   top flashes see-through as its panel drops (`TopHole.saw`, `CrawlHole.saw`). The lobby car's
   lamp burns very dim (its walls read black round the panel in Play, seen again Nov 13). Older,
   see git log of HANDOFF (session 116): the gate cache, ladder and tool edge cases, the
   rbxassethash lines at Play, the flashlight out in the lobby and while riding.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
