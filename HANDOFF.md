# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-18, S5-03i1b (D-347) · **Checks:** green for the home · **Git:** `main`, not
pushed; Brix `7f25310`. Uncommitted CoinView, GatePay, Keepers, Keeper, Pay: the climb run's.

## State
- Nov 18, the owner (D-345): everything in a home moves, lifts and works (ROADMAP S5-03i, ahead
  of h5 and h6). i1a (the rules, D-346) and i1b (the server lays them, D-347) done; i1c next.
- i1b, passes checks, untested in Studio (Studio was in another session's Play): `Arranging`
  adopts a home's pieces once (`starterLaid` written true), grows them on a resize, loads the job
  box first, draws them by their spec box (`Arrange.starterPivot`; the mirror via `mirrorAt`,
  upright pivot at its foot), refuses "kept" for the job box and "full" past the finds' limit;
  `Arrange.room` holds only the ceiling lamp; a spare home shows Small's layout (`Lobby.front`,
  hidden while held). `Arranging.drawn` + `pieceOf` feed Shelves (finds are the shelf's
  children), JobBoxes (button follows the box), Rails; JobBoxView's lid riders are on
  "JobBox:Furniture#1"; HomeLights takes a lamp drawn later. `Home.mirror`/`Home.rail` removed.
- Studio hooks: `GrowTest`, `ArrangeTest` "size"/"rows"/"relay", `DevReceipt`. Test save: Small,
  cash 188 (adopts its set on its next load). Home doc (D-259), docs tools only:
  https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww
- **Climb run:** items 1 (F-G1e6q2, D-400) and 2 done: S4-02 (D-401) mixes each floor's
  monsters from the climb's seed (`KeeperMix`; the Packrat from floor 3 on about three in five),
  leanable by a floor version. Next: S4-04 Trapping pays (5 coins each to everyone aboard per
  monster shut in a unit as the gate shuts; a trapped one counts toward the awake limit).
  Uncommitted `ArrangeView`, `Home/*` and `layout.spec` are the home chain's work in progress.

## Next task: S5-03i1c Lift the starter pieces in Arrange, seen in Studio
The moment: you lift your shelf, finds and all, slide it to the side wall and set it down; the
mirror leans on its new wall and still shows you; you rejoin and it's all where you left it.
1. Studio Play i1b first (`get_studio_state`; one Play at a time; stop after): a Small home's
   shelf on the back wall, box left, mirror right; `ArrangeTest "rows"` shows the test save
   adopted; shelf finds stand in the shelf; the job box opens; the mirror reflects; "size" XL
   and back; "relay". Fix what's off before step 2.
2. `ArrangeView`: lift, move, turn and put away a starter piece (the shelf's finds are its
   children, so a tap on one lifts the shelf for now); the mirror sets only with its back to a
   wall (a pure rule with a spec, the server's refusal too); the job box's Put away does nothing.
3. The views follow a moved piece: the rail's press spots (`Rails` re-poses on `drawn`), the job
   box's lid and riders (`JobBoxView`), the lamp's light and `floorAt` (`HomeLights`).
4. Studio Play at Galaxy A16 size: move the shelf with finds, the mirror and the box; rejoin;
   change size. Captures into `docs/art/`. Split if it won't fit.
**Acceptance:** check green for the home's files; a spec for the mirror's wall rule; in Studio
the moves hold through a rejoin and a resize, with captures.
**Read first:** D-347; `src/client/ArrangeView.luau` (build, lift, put away);
`src/server/Arranging.luau` (drawPiece, draw, place); `src/server/Rails.luau` (lay, placeAt);
`src/client/JobBoxView.luau` (gather, the lid); `src/shared/Home/Layout.luau`.

## Queue (next sessions, the owner's ticket order)
1. S5-03i2 take anything, i3 every find's button, i4 sit
   (D-345); then S5-03h5, h6; S5-03g3c a card's style; S5-03d4; S5-03a2d the cars' triangles.
2. The steel shelf's lower tiers. In Arrange the job box's "Open" shows over the room. A lifted
   lit piece's light stays where it was until it's set down. The looks' polish (g2b2, g2b3,
   g3b). A size change while Arrange is open doesn't rebuild the screen's judge (h6 should).
   Units: plans small; Robux cards unseen. A gift buyer's `bought` counts only a spare's gift
   (D-343); the Gift cards unseen (D-344). The mirror leans on nothing if set mid-room (i1c).
3. The home's warm fill (D-290): faces turned from the bulb go near black. Brix (in
   `../engine`): ENG-25b's two-client run; Driving's stick read (D-254); a PlayerSaves hook
   before a leaving save's last write.
4. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277,
   D-297, D-299 to D-302, D-304, D-305, D-308, D-309, D-311 to D-346.
5. Once the owner's real purchase passes, mark Brix's ENG-23e done. A spare home unpadlocked
   (D-275); the hat's first-Wear dark screen; the body after a respawn (D-282); late arrivals
   off `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error. Counter and job
   box cash isn't sent to analytics. One `CaughtSeized` string. Lobby sheets: no plates.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
