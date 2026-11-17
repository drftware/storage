# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 237 (the job box built, D-287) · **Checks:** green · **Git:**
`main`, committed, not pushed (`origin` is github.com/drftware/storage); Brix pinned at `482368f`,
NOT on Brix's `origin` yet (push Brix first, OWNER.md).

## State
- The home (D-259; the Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools
  only) is built a ROADMAP piece a session (S5-03): ground floor, fronts, starter sets, switch,
  a home each (D-275), the hard hat (D-277, D-283), the mirror (D-280), the oak shelf with finds
  standing on it (D-284, D-285), and now the job box, built but not yet in the place (D-287).
- S5-03c2a1 (D-287), passes checks, untested in Studio: `art/home/furnish.py` builds the box
  (JobBox, JobBoxLid, JobBoxFittings, JobBoxRunners; `Specs.JobBox.Hinge`), in the Starter set
  against the left wall by the shelf (look sheet `art/sheets/lobby-inside.png`). Home.fbx is
  exported, NOT uploaded or imported: until it is, `Home.has` skips the box with one warning and
  `JobBoxes` wires none. Save version 6 adds `boxFresh` (`Save.keep` raises it with the shelf
  full; `Save.open` clears it). `JobBoxes` (server: Open/Close on E for the holder, `Lid` and
  `Fresh` attributes, shuts on walking 14 studs off) follows Shelves' new `laid` signal;
  `JobBoxView` (client) swings the lid by `JobBox.angle`, creaks, clunks, sparkles.
- The ceiling: the home bulb's light now hangs 3 studs under the lamp (`UnitLight.Home.Drop`) so
  the plaster ceiling catches it; nothing re-captured yet (the old dark one is
  `docs/art/S5-03c1b-from-door.jpg`).
- Dev path: `ServerStorage.ShelfTest:Invoke(player, key)` (Studio) keeps a find as a gate does;
  the seventh with a six-spot shelf goes in the box.
- Find art (third find run): the carousel's tune slows with its top, pitch held (V5f, D-288),
  seen in Play. Next there: V5d, the Old lamp holding a Mannequin (`art/finds/WAVES.md`).

## Next task: S5-03c2a2 The job box, in Studio
The moment: the shelf's full, you keep one more, and when you come home the job box's lid
sparkles; press Open and the lid swings up with a soft steel creak.
1. Upload and import: `lune run scripts/upload_art Home` (same asset id), then in Edit LoadAsset,
   `Home.prepare`, replace `ReplicatedStorage.Props.Home` (art/home/README.md "Into Studio"; c1b
   did it). Check Output for the `Home:` warning gone.
2. Play: ShelfTest six finds, then a seventh. From the doorway the lid twinkles. Open: the lid
   swings up eased (88 degrees, clear of the wall), creak, twinkle bursts off. Close: it falls
   with a clunk. Open and walk away: it shuts. Stop and Play: the box is quiet.
3. Capture at half scale: `docs/art/S5-03c2a-from-door.jpg` (the ceiling: warm past the lamp now?)
   and `-open.jpg`. If the ceiling is still dark, tune `UnitLight.Home.Drop` and `Range`, then the
   UnitTops paint (`Lobby.Paint.UnitTops`); if the sounds are wrong, swap them in `Home/JobBox`.
4. Tick it in ROADMAP, update OWNER.md's "Open your job box" to what was seen.
**Acceptance:** check green; in Studio Play the seventh find makes the lid twinkle; Open lifts it
and the twinkle stops; Close drops it; after a rejoin the box is quiet; the ceiling reads warm.
**Read first:** ROADMAP S5-03c2a2; D-287; art/home/README.md "Into Studio";
`src/server/JobBoxes.luau`; `src/client/JobBoxView.luau`; `src/shared/Home/JobBox.luau`.

## Queue (next sessions, the owner's ticket order)
1. S5-03c2b the panel (the lid lifts as it slides in, the slam as it closes), c3 selling; S5-03d-h; S5-03a2d the cars' hidden triangles; F-G1b4a2 the
   headlamp's beam (ROADMAP Step 4); F-G1b4b the hat spent (start its minute when a hat worn at
   home leaves the ground floor).
2. F-G1b5 waits for its art. Brix: ENG-25b's two-client run (OWNER.md's home test covers it).
3. Brix ticket: Driving's stick read needs `PlayerScripts.PlayerModule`; fall back to the
   camera-turned `Humanoid.MoveDirection` as `input` does (D-254). Built in `../engine`.
4. S4-02 monsters by lowest floor, S4-03 the elevator's choice, S4-04 trapping pays, S4-05.
5. The item catalog doc and the design doc's finds section need D-250, D-251, D-259 and D-277.
6. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
7. Spread late arrivals off `ClimbEnd.spot`; the driving torch's rules vs what's seen (D-257);
   Play logs asset 203785492 ("asset type does not match"). The front office's counter and
   shelves are still the climb's steel. The lobby's cart seats didn't seat a server `Seat:Sit`
   (S5-03a2b4). A spare home lifted from inside stays unpadlocked until held and left (D-275).
   The worn hat's first-Wear dark screen (STUDIO.md). After a respawn under a held camera,
   Roblox never re-hid your body in first person (D-282).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
