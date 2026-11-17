# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 238 (the job box seen in Studio, D-290) · **Checks:** green ·
**Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage); Brix pinned at
`482368f`, NOT on Brix's `origin` yet (push Brix first, OWNER.md).

## State
- The home (D-259; the Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools
  only) is built a ROADMAP piece a session (S5-03): ground floor, fronts, starter sets, switch,
  a home each (D-275), the hard hat (D-277, D-283), the mirror (D-280), the oak shelf with finds
  (D-284, D-285), and the job box (D-287), now in the place and seen working (D-290).
- S5-03c2a2: Home.fbx uploaded (same asset id) and imported into `ReplicatedStorage.Props.Home`
  in Edit, not saved by me. Verified in Studio Play: the lid twinkles for a find the full shelf
  can't hold; Open eases it to 88 degrees with the creak and burst; Close drops it with the clunk;
  walking 14 studs off shuts it; a rejoin finds it quiet. The ceiling reads warm past the lamp.
  Captures: `docs/art/S5-03c2a-from-door.jpg`, `-open.jpg`. The sounds are the owner's to hear.
- Import gotcha: the MCP's Edit `require` keeps its first copy of a module all session; prepare
  from a fresh clone (`art/home/README.md` "Into Studio", `docs/STUDIO.md`).
- Dev path: `ServerStorage.ShelfTest:Invoke(player, key)` (Studio) keeps a find as a gate does;
  with the shelf full it goes in the box. The owner's save has six on the shelf already.
- Find art: V5d seen in Play (D-289, the Old lamp holds a Mannequin); next V5b (`art/finds/WAVES.md`).

## Next task: S5-03c2b1 The job box's panel, to look through
The moment: you open the job box and, as the lid lifts, a panel slides up with everything you
own, each kind once with its count; you type or tap a rarity and it narrows at once; Close, or
walking off, slams it away as the lid drops.
1. Read the home doc's job box idea (9) and "What you decided (Nov 16)" with the docs tools, by
   heading only. Settle the card's look (the find's model in a ViewportFrame as ShopView does,
   or a still), counts, the search and the rarity chips. Defaults go in OWNER.md.
2. Pure rules in `Home.JobBox` (or a sibling module): group owned finds into one card a kind with
   its count, the search match, the rarity filter, the sort; Lune specs first.
3. Server (`JobBoxes`): on Open, send the holder their list (from the save's `finds`), once; any
   ask from the client is validated (type, holder, rate-limited). Nothing to take out yet (c2b2).
4. Client panel (new, ShopView's pattern): slides up over the lid's 1.1 s lift, cards dealt in,
   x2 badges, a search box, rarity chips with a tap sound; slams down over the 0.42 s drop on
   Close, walking off, or the lid shutting for any reason. Phone first: judge at Galaxy A16 size.
5. Studio Play: keep a few finds with ShelfTest, open the box, search, filter, close, capture.
**Acceptance:** check green; specs cover grouping, search and filter; in Studio Play the panel
rides the lid in and out, lists every find you own a kind a card with its count, search and
filters narrow it, and it reads at phone size.
**Read first:** ROADMAP S5-03c2b1; the home doc's idea 9 and "What you decided (Nov 16)"; D-287
and D-290; `src/server/JobBoxes.luau`; `src/client/ShopView.luau`; `src/shared/Save.luau` (`finds`).

## Queue (next sessions, the owner's ticket order)
1. S5-03c2b2 taking a find out (hands or a free shelf spot), c3 selling; S5-03d-h; S5-03a2d the
   cars' hidden triangles; F-G1b4a2 the headlamp's beam (ROADMAP Step 4); F-G1b4b the hat spent
   (start its minute when a hat worn at home leaves the ground floor).
2. The home's warm fill (D-290): faces turned from the bulb go near black (the shelf's end and
   back, seen from the box); D-263 wants the room calm and warm all round. A dim warm fill or the
   lobby's ambient, judged from the box and the door at phone size.
3. F-G1b5 waits for its art. Brix: ENG-25b's two-client run (OWNER.md's home test covers it).
4. Brix ticket: Driving's stick read needs `PlayerScripts.PlayerModule`; fall back to the
   camera-turned `Humanoid.MoveDirection` as `input` does (D-254). Built in `../engine`.
5. S4-02 monsters by lowest floor, S4-03 the elevator's choice, S4-04 trapping pays, S4-05.
6. The item catalog doc and the design doc's finds section need D-250, D-251, D-259 and D-277.
7. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
8. Spread late arrivals off `ClimbEnd.spot`; the driving torch's rules vs what's seen (D-257);
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
