# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-13, session 118 (L-08e3b Share and follow) · **Checks:** green ·
**Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **L-08e3b built (D-130), passes checks, untested in Studio.** Trip data v3 names the group's
  own server and the lobby it left. On a group's own server Invite shows again and names it; the
  public lobby an invited friend lands in sends them on ("Joining Sam" under the black,
  `Trips:follow`), and they open in the group's front office. The group's server tells its
  lobby its floor (MessagingService) and the car they left from says "Floor N". A Share key sits
  between Invite and Go (`PromptLinkSharingAsync`, server side). Lune: `trip.spec`, 139 checks.
- **Studio still isn't getting Rojo's syncs** (checked at start and end: Edit's `Carts` has no
  `goHome`, `Trips` no `follow`). L-08e4b2 and L-08e3b are both untested there. The owner's
  Connect click is `OWNER.md`'s first line. Never stop or restart `rojo serve` yourself.
- A Brix session may run in `../engine` with a second Studio open on its own place: target
  only the Studio named "Storage (placeId: 113250085204323)" by its `studio_id`.
- The GDD (D-127, D-128) is the newer word; ROADMAP Phase 2 is its build order. The GDD says
  "monsters"; the code says keepers.

## Next task: S1-03 Half the units
The moment: a hall you walk down has fewer, more meaningful doors, blank wall between them, so
each roll-up door you pick is a choice (GDD "Doors": "Fewer units"). About 30 units on floors 1
and 2, about 40 above; halls stay as long as they are. S1-01 (Brix ENG-10b profiles) and S1-02
(Brix ENG-12 telemetry) wait on Brix: skipped, see Queue.
1. First, in Edit, check Studio has the code (`Carts.Source` contains `goHome`). If it does,
   run L-08e4b2's checks (ROADMAP L-08e4b2; STUDIO.md "Testing a cart ride from the MCP"), and
   what Studio can show of L-08e3b (a lobby car's panel: Invite, Share, Go across the bottom;
   tap Share and read Output). Fix what fails first.
2. Read the GDD's "Doors" section only (docs tools, never WebFetch) and ROADMAP S1-03.
3. Find where `Floor` places units along a hall (`src/shared/Floor.luau`, CODEMAP) and how
   the unit count follows from the hall's length; make the count a Config feel number per floor
   band with a comment, blank wall where a unit was (the corridor kit's wall piece).
4. Keep the floor's code, keeper and find placement working with fewer units (Lune specs for
   counts per floor band and that codes still land in reachable units).
**Acceptance:** checks green; Lune specs for the counts and placement; verified in Studio Play
if Rojo syncs (floor 1 and floor 3 counted from the server, a hall looked at from a phone-size
view), else "untested in Studio" and steps in `OWNER.md`.
**Read first:** ROADMAP S1-03; the GDD's "Doors" section; `src/shared/Floor.luau`;
`docs/CODEMAP.md` rows for Floor and CorridorKit; `tests/floor.spec.luau`.

## Queue (the overnight run, owner Nov 13: sessions until 8:30am, the updated plan)
1. S1-03 (next), then ROADMAP Phase 2 in order. S1-01 Saving waits on Brix ENG-10b/c (the Brix
   chain is building it tonight); S1-02 Recording waits on Brix ENG-12 Telemetry. Both are named
   in `../engine/docs/ROADMAP.md`. Take them when Brix ticks them. S2-06 waits on `OWNER.md`.
   Lobby polish ("The ride's finish", "The dials' finish") waits. L-08e3c waits on `OWNER.md`.
2. Untested in Studio until Rojo syncs: L-08e4b2, L-08e3b, and anything built after them.
3. Found L-08e3b: a lobby car's `far` (the group it sent) isn't cleared when that group's trip
   fails and they're back in the car; it just ages out after `Trip.WordStale`. Harmless.
4. Found L-08e4b1: no PlayerModule in PlayerScripts in Play (STUDIO.md), so WatchView's
   `controls` lookup fails quietly (controls may stay on while you watch; untested).
5. Seen (owner, Nov 12, "fix them later"): lobby car floors go splotchy inside; a sawn side or
   top flashes see-through as its panel drops (`TopHole.saw`, `CrawlHole.saw`). Older, see git
   log of HANDOFF (session 116): a lobby car's dim lamp, the gate cache, ladder and tool edge
   cases, the rbxassethash lines at Play, the flashlight out in the lobby and while riding.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
