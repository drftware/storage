# Owner

Everything waiting on you, in order. Work down and tick boxes. Agents add new items here and
nowhere else.

## Now

- [ ] **Save Studio's place.** It's still "Place1", unsaved and unpublished, and it now holds the
  unit template at `ReplicatedStorage.Units.M`. File → Save to File as `storage.rbxl` in this
  folder (git ignores it), or publish it to a new experience if you'd rather. If it's ever lost,
  a session rebuilds the template from asset 135739386247346 in a minute.
- [ ] **Two settings the session can't reach.** In Properties: Lighting → Technology = **Future**
  (Rojo's live sync can't write it). Then check Workspace: StreamingMinRadius 64,
  StreamingTargetRadius 256, StreamOutBehavior Opportunistic (Rojo should have set these; the
  session's tools can't read them).
- [ ] **Each session: click Connect** in Studio's Rojo plugin when it says `rojo serve` is running.
- [ ] **Judge the storage unit's look.** Open `art/sheets/unit-contact-sheet.png`, then
  `art/sheets/door-hall.mp4` and `door-mechanism.mp4`, and now `docs/art/P0-02-hall.jpg` and
  `P0-02-open-101.jpg` (the real unit in Studio). Say yes, or what to change. It sets the look for
  every asset after it: worn, real materials under cold corridor light (D-007).
- [ ] **Branches:** everything so far is on `storage-unit`; `main` has no commits yet. Say if you
  want `storage-unit` to become `main`.

## After P0-02b (the next session says when)

- [ ] **Two-player door test.** Test tab → Clients and Servers → 2 players → Start. In both
  windows walk to the same door (spawn is at the hall's west end; units 101 to 108).
  - Player 1 presses E (Open) at 101: both windows see it roll up in about 2 s, matching.
  - Player 2 stands in 101's doorway; player 1 presses G (Slam): the door lands in a blink on
    both screens and pushes player 2 out or stops just above them, never through them.
  - Player 2 walks into 101, player 1 presses F (Close): player 2 is shut in and can't walk out;
    player 2 presses T (Lift) inside and it heaves up slowly.
  - At 105 (padlocked) press E: "Padlocked" flashes. Shut a door, press R: the bolt and padlock
    appear for both; R again takes them off. R on an open door flashes "Shut it first".
  - One player presses E on the post by the spawn ("Go far"), waits 10 s, then "Come back": every
    door is still where it was left.
  - Look for: doors out of step between windows, a door you can walk through, a stutter when
    many doors move at once.
