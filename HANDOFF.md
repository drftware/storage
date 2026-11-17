# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 231 (the hard hat on your head, F-G1b4a1) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage); Brix pinned at `482368f`, NOT on Brix's `origin` yet (push Brix first, OWNER.md).

## State
- The home (D-259; the Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools
  only) is built a ROADMAP piece a session (S5-03): ground floor, fronts, starter sets, switch,
  a home each handed out as you join (D-275).
- F-G1b4a1 (D-277): the hard hat's word is Wear. Pressed in hand it goes onto your head
  (`Slots:toHead`, `Finds/Head`'s fit: 1.4 times, battery hidden), its slot freed, the shell's
  knock then the lamp's click; lit with the hat's own warm lamp for everyone; a lit worn hat holds
  a Mannequin from your head (Keepers' glows); caught it drops, at the gate it's kept, on the
  ground floor (`Head.home`) its light never runs down. Seen in Studio Play with one player
  (worn, slot freed, lit, forever at home); its look on a head and the two-client view wait on
  OWNER.md. Once, the first Wear after starting Play stayed dark on the wearer's screen
  (`docs/STUDIO.md`); a restart lit at once.
- F-G1b4a2 (the headlamp's own beam, following your look and bobbing) is split off, queued.
- Still over the triangle default: the cars' 51k, ticketed as S5-03a2d.
- Find art (third find run): V3c done (D-278: a find's own tip and lift move the grip that holds
  it; the kazoo tips to your lips, seen in Play). Next: V3d, the spinner lands on any animal
  (ROADMAP F-G1e3d), then V4 the siren car (`art/finds/WAVES.md`).

## Next task: S5-03b The mirror test (the owner's order, D-259)
The moment: you walk into your home, see yourself in a real mirror, the hard hat on your head
lit, and turn to look at it. Precedent: Animal Crossing's mirrors. The owner judges it in Studio
before S5-03f is built, so this is a test piece, built to the home's calm look (D-263).
1. Read ROADMAP S5-03b (grep "S5-03b The mirror test") and D-259's mirror line (grep -n
   "The mirror\*\*" docs/DECISIONS.md). Read the plan doc's ideas 21 and 22 only (docs tools,
   search by heading; its "What you decided (Nov 16)" wins).
2. Build one mirror in your home (FrontOffice's homes, `Lobby.front`): a ViewportFrame on the
   glass with a back-to-front copy of the room and of every character near, posed from theirs
   each frame (only while you're near and facing it; one live mirror at a time). Real frame art
   the unit's way (`art/unit/README.md`) if it needs a model.
3. Judge it at Galaxy A16 size in Studio Play: you, a worn hat (`GiveFind` "HardHat", Wear),
   the room behind. Write what Roblox draws and doesn't (lights, glow, LocalTransparency of your
   own head in first person) in `docs/STUDIO.md`.
4. OWNER.md: the owner's look at it, exact steps; defaults you picked.
**Acceptance:** check green; in Studio Play you see yourself and the room back to front in the
mirror, it follows you as you move, nothing costs frames on a phone when you're away from it.
**Read first:** ROADMAP S5-03b; D-259's mirror line and D-263 (the home's look); the plan doc's
ideas 21 and 22; `src/server/FrontOffice.luau` (the homes); `src/shared/Lobby/init.luau`
(grep "function Lobby.front"); `art/unit/README.md`.

## Queue (next sessions, the owner's ticket order)
1. S5-03c-h; S5-03a2d the cars' hidden triangles; F-G1b4a2 the headlamp's beam (ROADMAP Step 4);
   F-G1b4b the hat spent (also: start its minute when a hat worn at home leaves the ground floor).
2. F-G1b5 waits for its art. Brix: ENG-25b's two-client run (OWNER.md's home test covers it).
3. Brix ticket: Driving's stick read needs `PlayerScripts.PlayerModule`; fall back to the
   camera-turned `Humanoid.MoveDirection` as `input` does (D-254). Built in `../engine`.
4. S4-02 monsters by lowest floor, S4-03 the elevator's choice, S4-04 trapping pays, S4-05.
5. The item catalog doc and the design doc's finds section need D-250, D-251, D-259 and D-277.
6. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
7. Spread late arrivals off `ClimbEnd.spot`; the driving torch's rules vs what's seen (D-257);
   Play logs assets 92259888500166 and 203785492. The front office's counter and shelves are
   still the climb's steel. The lobby's cart seats (`Cart1.RideSeat`) didn't seat a server
   `Seat:Sit` in a quick try (S5-03a2b4). A spare home lifted from inside stays unpadlocked
   until someone holds it and leaves (D-275). The worn hat's first-Wear dark screen (STUDIO.md):
   if it comes back, make `FindUseView` re-read a tagged model whose key arrives late.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
