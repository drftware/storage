# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-18, S5-03i1a (D-346) · **Checks:** green · **Git:** `main`, committed, not
pushed (`origin` drftware/storage); Brix pinned at `7f25310`, NOT on Brix's `origin` yet.

## State
- Nov 18, the owner (D-345): everything in a home moves, lifts and works. ROADMAP's S5-03i, ahead
  of h5 and h6. S5-03i1 is split: i1a (the rules) done, i1b (the server lays them), i1c (lift
  them in Arrange, the views follow, Studio).
- i1a done (D-346), pure only, nothing wired: the starter pieces are furniture rows
  (`Furniture.Starter`, "Shelf:Furniture#1", never sold, free of the limit, the job box `kept`);
  `Home/Layout.luau` lays them by size (`default`; Small: shelf, box, mirror), adopts a home laid
  before (`adopt`: where they stood, ShelfTop/JobBoxTop finds moved onto the pieces) and lets a
  growing home's pieces ride their walls (`grow`); the shelf, box and rug have piece tops (the
  rug's is floor-kind); save v14 adds `starterLaid` (false until the server lays them).
  `tests/layout.spec.luau` judges every size's layout whole with Brix. The home doc (D-259):
  https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools only.
- Studio hooks: `GrowTest` (a size; "cash"/"price", n; "gift", size, friendPlayer; "friend",
  name, size), `ArrangeTest` "size", `DevReceipt`. Test save: Small, cash 188 (v13 till loaded).
- **Climb run:** items 1 (F-G1e6q2, D-400) and 2 done: S4-02 (D-401) mixes each floor's
  monsters from the climb's seed (`KeeperMix`; the Packrat from floor 3 on about three in five),
  leanable by a floor version. Next: S4-04 Trapping pays (5 coins each to everyone aboard per
  monster shut in a unit as the gate shuts; a trapped one counts toward the awake limit).

## Next task: S5-03i1b The server lays the starter pieces as rows
The moment: your Small unit's shelf stands on the back wall, not mid-room; an XL home laid
before keeps its set where it stood, with the finds on its shelf and box.
1. `Arranging`: as a home is laid, `Layout.adopt` while `starterLaid` is false (then write it
   true), `Layout.grow` instead of `Spots.carry` on a size change; the starter rows settable at
   one each (`Furniture.Starter`) and boxed when put away; refuse putting the job box away (a
   new refusal, the screen's press does nothing); draw them as bought pieces are drawn.
2. `Arrange.room`: no fixed set's blocks or ShelfTop/JobBoxTop areas for a held home (the
   mirror's and rail's `Fixed` rows go too; the ceiling lamp stays). `Lobby.front` lays a spare
   home's set by `Layout.default` at Small; the held home's `Starter` folder is cleared.
3. Each piece keeps working by its row: `Shelves` (the shelf's spots), `JobBoxes` and
   `JobBoxView` (the lid, the panel), `Home.mirror`/`MirrorView` (the glass), `Rails`. Find the
   drawn model by `Layout.id(kind)`; follow its pivot when it moves (i1c moves it).
4. Studio Play at Galaxy A16 size: Small (shelf on the back wall), "size" to XL and back, a
   rejoin; the job box opens, the mirror reflects, the rail hangs. Split if it won't fit.
**Acceptance:** check green; a spec for any new pure rule; in Studio a Small home's set stands
by the walls and works, and the test save's finds come through.
**Read first:** D-346; `src/shared/Home/Layout.luau`; `src/server/Arranging.luau` (lay, draw,
putAway); `src/shared/Home/Arrange.luau` (room); `src/server/Shelves.luau` (grep Starter);
`src/shared/Lobby/init.luau` (Lobby.front).

## Queue (next sessions, the owner's ticket order)
1. S5-03i1c lift them in Arrange; S5-03i2 take anything, i3 every find's button, i4 sit
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
