# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 230 (your home, claimed as you join, S5-03a3b) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage); Brix pinned at `482368f`, NOT on Brix's `origin` yet (push Brix first, OWNER.md). Brix also has `6574e0c` (ENG-25b's one-player log), docs only.

## State
- The home (D-259; the Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools
  only) is built a ROADMAP piece a session (S5-03). Ground floor, fronts, starter sets, switch
  (D-268, D-271) and now a home each (D-274).
- S5-03a3b (D-274): FrontOffice hands each joiner a home with Brix's `Plots`/`PlayerPlots`, nearest
  the spawn first (`Home.Holding`). 1.5 s after you stand there your name sprays onto its card
  (HomeCards, with a hiss) and its padlock comes off as the door rolls up. A held door
  (`Door.decideHeld`, `Door.HolderAttribute` on the unit) opens from the hall only for its holder;
  anyone else's Open or Peek rattles it, wordless; from inside it always lifts. Spare homes are
  shut and padlocked; leaving blanks the card, drops the door, padlocks it. The switch is the
  holder's (button hidden for others). A home's room is 20 by 30 for ShutIn (`RollUpDoor.room`).
- Seen in Studio Play with one player (Unit1 claimed, named, opened; Unit7 spare). The pull-down
  and the stranger's rattle are Lune-tested only; the two-player test is in OWNER.md. Brix's
  ENG-25b is logged as a one-player run, not ticked (two clients and a leave still to see).
- Still over the triangle default: the cars' 51k, ticketed as S5-03a2d.
- Find art (third find run): V2 done (D-272). Next: V3 (ROADMAP F-G1e3; `art/finds/WAVES.md`).

## Next task: F-G1b4a The hard hat on your head, lit (the owner's order, D-259)
The moment: you pull the hard hat on with the shell's knock and the lamp's click, and a tight,
white beam goes where you look, bobbing as you walk, your hands free; friends see the light on
your forehead. At home it doesn't run down ("At home nothing runs down", D-259). Precedent: Lethal
Company's and Phasmophobia's head torches.
1. Read ROADMAP F-G1b4a (grep "F-G1b4a On your head") and D-196 (the hat brings its battery).
   Find the hat's row and light (`src/shared/Finds/Sets/Lights.luau`, grep "HardHat") and how
   the ladder welds to the character (grep "weld" in `src/server/Ladders.luau`).
2. A head place apart from the two slots: Wear (the hat's one word, replacing its Switch) welds
   it to the head, lit, and frees its slot; the server owns it and checks every press.
3. The beam (tighter and whiter than the torch's) follows the look, bobbing with the walk; other
   screens draw it from the forehead. It holds a Mannequin as any found light does (its stamp in
   `Slots:finds`' place, from your head); caught, it drops with the rest.
4. At home (on the ground floor, D-259) its minute doesn't run; F-G1b4b does the running down.
5. Run it in Studio Play: wear it, look about, see the beam; log in `docs/STUDIO.md`.
**Acceptance:** check green; in Studio Play the hat goes on with its sounds, lit, its slot freed;
the beam follows the look; on the ground floor it doesn't run down; two-client view in OWNER.md.
**Read first:** ROADMAP F-G1b4a; D-196 and D-141 (grep "^## D-196\|^## D-141" docs/DECISIONS.md);
`src/shared/Finds/Sets/Lights.luau` (grep "HardHat"); `src/server/Ladders.luau` (grep "weld");
`src/client/FlashlightView.luau` (the torch's beam); `src/server/Wearing.luau`.

## Queue (next sessions, the owner's ticket order)
1. S5-03b the mirror, S5-03c-h; S5-03a2d the cars' hidden triangles; F-G1b4b the hat spent.
2. F-G1b5 waits for its art. Brix: ENG-25b's two-client run (OWNER.md's home test covers it).
3. Brix ticket: Driving's stick read needs `PlayerScripts.PlayerModule`; fall back to the
   camera-turned `Humanoid.MoveDirection` as `input` does (D-254). Built in `../engine`.
4. S4-02 monsters by lowest floor, S4-03 the elevator's choice, S4-04 trapping pays, S4-05.
5. The item catalog doc and the design doc's finds section need D-250, D-251 and D-259.
6. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
7. Spread late arrivals off `ClimbEnd.spot`; the driving torch's rules vs what's seen (D-257);
   Play logs assets 92259888500166 and 203785492. The front office's counter and shelves are
   still the climb's steel. The lobby's cart seats (`Cart1.RideSeat`) didn't seat a server
   `Seat:Sit` in a quick try (S5-03a2b4); look before blaming them. A spare home lifted from
   inside stays unpadlocked until someone holds it and leaves (D-274); fine for now.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
