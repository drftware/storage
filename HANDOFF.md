# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-13, session 120 (S1-04a1 Coins: the coin, the deal, the server) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **S1-04a split** (context cap): S1-04a1 is built (D-132), passes checks, untested in Studio.
  `art/coin/` builds a worn gold coin with a keyhole stamped through it (512 triangles; sheets
  `art/sheets/coin-*.png`); `Deal` gives about 7 units in 10 one to three coins, drawn last (no
  seed's other draws moved); `DealSpot` lays a pile in the bulb's pool clear of the unit's tool,
  find or keeper (`taken`, `around`); the server's `Coins` system lays each pile with a glint and
  a "Take" button, checks takes, keeps each player's count (`Coins` attribute), zeroed on the new
  `Climbs.began`. The coin isn't in the place yet, so Play shows no coins (one warning line).
- **S1-03's counts verified in Studio Play:** floor 1 laid 29 units, floor 3 laid 40.
- Studio syncs (Rojo connected, Nov 13 23:30). A Brix session may run in `../engine` with a
  second Studio open: target only "Storage (placeId: 113250085204323)" by its `studio_id`.
- The GDD (D-127, D-128) is the newer word; ROADMAP Phase 2 is its build order. The GDD says
  "monsters"; the code says keepers.

## Next task: S1-04a2 Coins: on screen
The moment: the door goes up, a glint on the concrete; a tap, the coins jump and spin and are
gone with a chink, and on your screen a coin flies to the little count in the corner, which
pops. Every action answers: until this lands, the take has no motion or sound.
1. In Edit, check Studio has the code (`ReplicatedStorage.Shared.Coins` exists).
2. Bring the coin in (`art/coin/README.md` "In the place"): `lune run scripts/upload_art Coin`,
   insert the asset with the MCP, take its MeshPart out (SurfaceAppearance kept), name it
   `Coin`, anchored, into `ReplicatedStorage.Props`; Play once: no "Coins: no ..." warning.
3. `src/client/CoinView.luau`, a client system in `init.client.luau`, numbers from `Coins`:
   piles tagged `CoinPile`; when `TakenBy` is set, each coin (anchored: a local move stays
   local) jumps `Lift`, spinning, and shrinks away (`LiftTime`, `Vanish`, `Stagger` between
   coins), its glint off; `Coins.Chink` at the pile (`Coins.Heard`), plus `Jingle` for 2 or 3.
   A pile already taken as it streams in is hidden at once.
4. The count: a small coin and a number top right (under Roblox's buttons, clear of the corner
   map: see where `MinimapView` sits), shown while the `Coins` attribute is a number, sliding in
   (`Show`). On the taker's screen one coin per coin flies from the pile's screen point to it
   (`Fly`), and each landing ticks the number up with `Tick` and a `Pop`. Phone size first.
5. Verify in Studio Play: open units (Output "Deals: UnitN held ... and 2 coins"), see a pile
   and its glint (one small screenshot), take it (`InputHoldBegin`/`End` on its prompt from the
   Client), read the count attribute and the HUD text.
**Acceptance:** checks green; the take verified in Studio Play (pile laid, taken, count up, the
coins gone) or "untested in Studio" with exact steps in `OWNER.md`; a judge S1-04a item in
`OWNER.md` (the look at phone size, the chink, the count's place).
**Read first:** ROADMAP S1-04a2; `src/shared/Coins/init.luau`; `src/server/Coins.luau`;
`art/coin/README.md`; CODEMAP rows for ToolView and MinimapView; D-132.

## Queue (the overnight run, owner Nov 13: sessions until 8:30am, the updated plan)
1. S1-04a2 (next), then ROADMAP Phase 2 in order (S1-04b Things to look at next). S1-01 Saving
   waits on Brix ENG-10c; S1-02 Recording on Brix ENG-12: take them when Brix ticks them. S2-06
   waits on `OWNER.md`. Lobby polish ("The ride's finish", "The dials' finish") waits. L-08e3c
   waits on `OWNER.md`.
2. Found S1-03: Deal's padlock count is a share of the units, so floors now get about half as
   many padlocks. S1-07 ("What a door holds") sets padlocks afresh, and whether a padlocked door
   pays more coins; leave both till then.
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
