# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-16, session 208 (the monkey's lure and the toy car) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- F-G1b3a done (D-233): wound, the cymbal monkey clangs on every clash and every monster on the
  floor hears it every 2 s until it stalls (`Use.lureUntil`, `FindUses`'s `lure`); pushed, the
  toy car is set down in front of you and rolls about 7 studs, stopping short of a wall, laid by
  the server where it ends and rolled there on every screen (`UseFrom`, `Finds.joints`'s `from`).
  Seen in Studio Play: the monkey lured 11 times over its play (no monster near, so 0 heard);
  the car rolled 1.6 to 9.1 studs ahead, client and server within 0.01 studs. The wall stop and
  the sounds by ear are the owner's (`OWNER.md`). The RC car has no press (catalog: at home).
- Find art (`art/finds/WAVES.md`): the wind-up mouse built by the art run (Nov 16, F-04d, D-232),
  uploaded and in the place; next the clockwork tin bird (F-04d2). The run commits its own files
  by path; a shared doc holding its lines and yours: stage HEAD plus your own lines only.

## Next task: F-G1b3b A lit find on the floor holds a Mannequin (D-188)
The moment: chased down a hall, you drop your lit lantern behind you and the Mannequin freezes in
its pool, as it does under a hall light or your torch; the tea light buys a few seconds, the
lantern a minute and a half.
1. Read how a light freezes it: `Keeper.luau`'s `lightOn` (grep "local function lightOn") and
   where `Keepers.luau` feeds it torches and hall pools (grep "hallLit", "freezesInLight").
2. A lit find lying loose counts as a light where its lit frame says (`Use.frame(...).lit`, not
   `spent`, state not "Off"): the server reads each `FindUsed` model's stamp (`Use.read` on its
   attributes) and its place; a lit find in a hand counts as a torch-like light only if the
   GDD says so (default: floor only, as D-188 says "found lights").
3. Its reach from the find's art light (`Finds.art(key).Lights`: Range) or a Config number with
   a comment; a unit's walls shade it as they shade hall light.
4. A Lune spec for the pure part (which stamps count as lit at a time), then Studio: GiveFind
   "CampLantern", Switch, drop it, wake a Mannequin (`DevFloorNumber` 1, its post) and read
   `Keepers: the Mannequin` lines in Output (a LogService listener into a StringValue).
**Acceptance:** checks green; a lit find on the floor freezes a Mannequin in its reach and
lets it go as it runs down or is switched off; `OWNER.md` says how to try it (numbered steps).
**Read first:** `src/shared/Keeper.luau` (`lightOn`, grep only); `src/server/Keepers.luau`
(grep "hallLit", "lit ="); `src/shared/Finds/Use.luau` (`frame`, `read`); D-188's found-lights
line (grep "found lights" docs/DECISIONS.md); ROADMAP F-G1b3b.

## Queue (next sessions, the owner's ticket order)
1. **S3-05a, then S3-05b: caught players each in an empty unit of their own** (the owner's
   playtest bugs, Nov 15), before the run ends. Then S4-02 to S4-05 (5 coins a trapped monster).
2. F-G1b3c the RC car drives off its transmitter, if the owner says so (`OWNER.md`).
3. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
4. A Studio hook to catch yourself for real (CatchTest finds no keeper even after WakeSleepers
   and 24 s, Nov 15; a Workspace attribute that catches by the nearest sleeper would do).
5. Small (ROADMAP lists them): the finds' press sounds and hand (F-G1b2 polish), the monkey and
   toy car's polish (F-G1b3a); B-05b2b's box round the bend; L-08e3c, L-14b2d wait; S3-04b's
   polish; Free Everyone's swap sound; `sell*` Config warnings, a dropped find bumps a walker
   (D-182), the save's "best floor" still 0 after a ride, S1-07a to S2-07b2 leftovers, box
   words (D-215).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
