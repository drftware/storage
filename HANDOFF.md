# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 121 (S1-04a2 Coins: on screen) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **S1-04 coins are whole** (D-132, D-133). The coin is in the place (`ReplicatedStorage.Props.Coin`,
  asset 88101556754832). `src/client/CoinView.luau`: a taken pile's coins jump, spin on edge and
  shrink away with a chink; on the taker's screen each flies to the count at the right end of the
  top bar, which ticks up and swells. **Verified in Studio Play** (Nov 14): Unit301 on floor 3 laid
  a pile of 2, Take pressed, both coins flew, `Coins` read 2, the HUD read 2, the pile was gone
  at 0.9 s. The sounds weren't heard by ear (`OWNER.md`).
- Studio syncs (Rojo connected). A Brix session may run in `../engine` with a second Studio open:
  target only "Storage (placeId: 113250085204323)" by its `studio_id`. Left in Edit.
- The GDD (D-127, D-128) is the newer word; ROADMAP Phase 2 is its build order. The GDD says
  "monsters"; the code says keepers.

## Next task: S1-01 Saving
The moment: none on screen yet. Everything after it (cash, finds, the collection book, your best
floor) has a place to live that survives leaving, so a climb's earnings are real. Brix built it:
ENG-10a-c (`SaveFormat`, `Saves`, `Roblox.SaveStore.dataStore`, `Roblox.PlayerSaves`), run in
Studio at Brix `e8397ff`. ENG-10d (a real DataStore in the published place) is this ticket's check.
1. Move `vendor/brix` from `4c21b5f` to `e8397ff` (35 commits). Read Brix's `CHANGELOG.md` for
   that range and fix any break; `scripts/check.sh` green before anything else. Update the pin
   line and what the game uses in `docs/FRAMEWORK.md`.
2. The save's shape, version 1, pure in `src/shared/` with a Lune spec: cash, the finds you own,
   the collection book's stamps, your best floor (GDD "Saving"); defaults for a new player.
3. A server system on `Roblox.PlayerSaves`: load on join (session-locked), autosave, flush on
   leave and shutdown; a player's save readable by later systems (no other system writes yet).
   Studio prints one line per load and save. Nothing on screen.
4. Verify in Studio Play: a load line on join, a save line on stop. If Studio has no API access,
   say so and put the switch (Game Settings > Security) in `OWNER.md`.
**Acceptance:** checks green; Brix moved and every system still starts in Play (no new errors in
Output); a save loads and saves in Studio Play, or exact steps in `OWNER.md`.
**Read first:** ROADMAP S1-01; GDD "Saving" (docs tools); `../engine/docs/modules/PlayerSaves.md`
and `Saves.md`; `docs/FRAMEWORK.md`; `src/server/init.server.luau`.

## Queue (the overnight run, owner Nov 13: sessions until 8:30am, the updated plan)
1. S1-01 (next), then ROADMAP Phase 2 in order: S1-04b Things to look at, S1-05 Finds you carry.
   S1-02 Recording waits on Brix ENG-12. S2-06 and L-08e3c wait on `OWNER.md`. Lobby polish
   ("The ride's finish", "The dials' finish") waits.
2. Found S1-03: Deal's padlock count is a share of the units, so floors now get about half as
   many padlocks. S1-07 ("What a door holds") sets padlocks afresh, and whether a padlocked door
   pays more coins; leave both till then.
3. Found L-08e3b: a lobby car's `far` (the group it sent) isn't cleared when that group's trip
   fails and they're back in the car; it just ages out after `Trip.WordStale`. Harmless.
4. Found L-08e4b1: no PlayerModule in PlayerScripts in Play (STUDIO.md), so WatchView's
   `controls` lookup fails quietly (controls may stay on while you watch; untested).
5. Seen (owner, Nov 12, "fix them later"): lobby car floors go splotchy inside; a sawn side or
   top flashes see-through as its panel drops (`TopHole.saw`, `CrawlHole.saw`). The lobby car's
   lamp burns very dim. Older, see git log of HANDOFF (session 116): the gate cache, ladder and
   tool edge cases, the rbxassethash lines at Play, the flashlight out in the lobby and riding.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
