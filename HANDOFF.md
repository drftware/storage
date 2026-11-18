# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-18, S5-03a2d (D-359) · **Checks:** green · **Git:** `main`, not pushed; Brix `7f25310`.

## State
- S5-03a2d (the cars' hidden triangles) is done, seen in Studio Play on the A16 (D-359). Each
  car part was measured, then settled by pixels (Studio's window captured with and without it,
  STUDIO.md): only the lamps' wire cages are unseen from afar, hidden behind the fascia. A lobby
  car's cage is now drawn only within 60 studs of it (`LobbyCarsNear`, `Lobby.CarNear`): the
  spawn view 174,404 down to 167,420, not a pixel different. The folded gates (29k) are seen;
  drawing them simply from afar waits on the owner's phone walk (OWNER.md). Climb untouched.
- S5-03g3c (choosing a card's style, D-357) and h6's other grows are still unseen in Studio:
  OWNER.md. This session ran out of room for them.
- Studio hooks: `ShelfTest` "take"; `ArrangeTest` "take", "own", "place", "rows", "fromShelf",
  "shelfAway", "size"; Trips' `DevTripFinds`. Home doc:
  https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww. Test save: Medium, card Stencil (Unit1),
  Boombox 10, Skates 1.
- **Climb run:** done: the fix pass (D-400), S4-02, S4-04, S4-03 the next-floor cards (D-403
  to D-413), S4-05a the jukebox's art (D-414), S4-05b1 its deal and door (D-415: imported, the
  code rolls up a unit with it inside). Next: F-G1b4a the hard hat's beam; S4-05b2 the map's
  mark and the haul (its hold, a walk under every monster's), then b3 its pay at the gate.

## Next task: S5-03g3d The other card styles sold at the counter
The last open piece of S5-03 (every other S5-03 ticket is done).
The moment: you see a friend's neon card glowing over their door, walk to the counter, buy one,
and the next time you open Arrange its chip is yours and picks with the plate swinging down.
1. First see S5-03g3c in Studio Play at A16 size (OWNER.md's "Choosing your name card's style"):
   Arrange's front tab, the second row of style chips, the camera dipping out to the hall, the
   plate swinging down. The MCP's click on Arrange's button didn't open it last time (STUDIO.md):
   try `ArrangeTest` or the button's own `Activated` path. Fix only what's wrong.
2. Sell the painted board and the chalk for cash and the neon for Robux at the counter, the way
   the furniture tab sells (S5-03g4b, D-334; Shop's rules), granted only after the save writes.
3. Save owned styles with a migration; `Looks.cardLock` reads them, so a bought style's mark
   goes and its chip picks. Prices: a default, and an OWNER.md line.
4. Every action answers: the buy's sound and toast, the chip's mark leaving.
**Acceptance:** a cash style bought in Studio Play saves, survives a rejoin and picks; a Robux
one is offered through the store's prompt (its grant waits on the owner's real purchase); a new
decision (D-360, below D-400); check green.
**Read first:** ROADMAP S5-03g3c and g3d; D-357; D-334; `src/shared/Home/Looks.luau`
(`cardLock`); `src/shared/Shop.luau`; `src/client/LooksTab.luau`.

## Queue (next sessions, the owner's ticket order)
1. Small's doorway's inside boards are oak, not the
   picked paint (D-355, my call). Sitting's leftovers (D-353): cross-legged on the blanket needs
   an animation of our own; lying on the bed.
2. Home leftovers: a lamp left on kept through a rejoin (D-351); a lit find taken comes unlit
   (on a trip too: the trip carries no lit state); the cubby finds' own buttons; a friend's take
   shows before the flying copy lands; the steel shelf's lower tiers; Arrange shows the job box's
   "Open" and the door's buttons; a lifted lit piece's light; a grow while Arrange is open closes
   it (D-356); Robux unit and gift cards unseen; the XL limit bar; Take through a wall; a refused
   cubby place (D-352). A taken-out find comes out whole even when the save has it cracked.
3. The home's warm fill (D-290): faces turned from the bulb go near black. Brix (in
   `../engine`): ENG-25b's two-client run; Driving's stick read (D-254); a PlayerSaves hook
   before a leaving save's last write.
4. The item catalog and design docs' finds need D-250, D-251, D-259, D-277, D-297, D-299 to 358.
5. Once the owner's real purchase passes, mark Brix's ENG-23e done. A spare home unpadlocked
   (D-275); the hat's first-Wear dark screen; the body after a respawn (D-282); late arrivals
   off `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error. Counter and job
   box cash isn't sent to analytics. One `CaughtSeized` string. Lobby sheets: no plates.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
