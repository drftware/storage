# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 239 (the job box's panel, D-291) · **Checks:** green ·
**Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage); Brix pinned at
`482368f`, NOT on Brix's `origin` yet (push Brix first, OWNER.md).

## State
- The home (D-259; the Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools
  only) is built a ROADMAP piece a session (S5-03): ground floor, fronts, starter sets, switch,
  a home each (D-275), the hard hat (D-277, D-283), the mirror (D-280), the oak shelf with finds
  (D-284, D-285), the job box (D-287, D-290), and now its panel (D-291).
- S5-03c2b1: open the box and the panel rises with the lid on the lid's curve, every find you own
  a kind a card (picture as the slots draw it, rarity rim, x2), rarest first; a search box and
  chips for the rarities you own narrow it with a quick re-deal; Close, the X, a tap outside or
  walking off and it falls with the lid. `Home/BoxPanel` (pure, `tests/boxpanel.spec`),
  `client/BoxPanelView`, `JobBoxes`' two remotes (`JobBoxList`, `JobBoxClose`).
- Verified in Studio Play at 1380x761: 18 kinds and four chips, "lamp" left two lamps, the X
  dropped it with the lid. Captures `docs/art/S5-03c2b1-open.jpg`, `-search.jpg`. Not checked at
  Galaxy A16 size or chip taps by hand (OWNER.md). `screen_capture` timed out; the macOS window
  capture works (STUDIO.md). Dev path: `ServerStorage.ShelfTest:Invoke(player, key)` keeps a find;
  open the box from a Client with the prompt's `InputHoldBegin`/`End`, a Scriptable camera on it.
- Find art: V5b seen in Play (D-292, the glow sticks crack one stick a press, three to a bundle);
  next V5c, the fairy lights laid along a hall (`art/finds/WAVES.md`).

## Next task: S5-03c2b2 Taking a find out of the job box
The moment: in the open panel you tap the Boombox card, it lifts and glows, Take; it flies out of
the panel into your hand with its pick-up sound and the card's count drops by one (or Shelf: it
flies to a free cubby and lands on the shelf with the shelf's tink).
1. Read the home doc's ideas 9 and 10 by heading (docs tools). Settle: tap a card to pick it, one
   verb button on it (Take; Shelf when a cubby is free); what a find in your hand at home is in the
   save (still owned; never more out than you own). Defaults go in OWNER.md.
2. Pure rules (BoxPanel or Save): what may come out (owned, not all already out), the count left;
   Lune specs first.
3. Server: one remote, checked (type, the box open and yours, a known find you own, a free slot in
   `Slots` or a free shelf spot), rate-limited; gives it into a slot or shelves it (`Save.shelve`).
4. Client (`BoxPanelView`): the picked card's lift and glow, the button, the picture flying to the
   slot or cubby (world to screen), the count ticking down, refused presses ignored, never worded.
5. Studio Play: keep finds, open the box, take one to hand, shelve one, capture half scale.
**Acceptance:** check green; specs cover what may come out; in Studio Play a find goes from the
panel into your hand and onto the shelf with its motion and sound, the count updates, and nothing
more than you own ever comes out.
**Read first:** ROADMAP S5-03c2b2 and S5-03d; the home doc's ideas 9 and 10; D-291 and D-284;
`src/client/BoxPanelView.luau`; `src/server/Slots.luau` (how a find goes into a hand);
`src/shared/Save.luau` (`shelve`, `keep`).

## Queue (next sessions, the owner's ticket order)
1. S5-03c3 selling and Gold; S5-03d-h; S5-03a2d the cars' hidden triangles; F-G1b4a2 the
   headlamp's beam (ROADMAP Step 4); F-G1b4b the hat spent (its minute starts when a hat worn at
   home leaves the ground floor).
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
