# Owner

Everything waiting on you, in order. Work down and tick boxes. Agents add new items here and
nowhere else.

## Now

- [ ] **Check the streaming settings** (the session's tools can't read them). In the Explorer click
  Workspace, then type `Stream` in the Properties filter box: StreamingEnabled ticked,
  StreamingMinRadius 64, StreamingTargetRadius 256, StreamOutBehavior Opportunistic. Change any
  that differ.
- [ ] **Each session: click Connect** in Studio's Rojo plugin when it says `rojo serve` is running.
- [ ] **Judge the storage unit's look.** Open `art/sheets/unit-contact-sheet.png`, then
  `art/sheets/door-hall.mp4` and `door-mechanism.mp4`, and now `docs/art/P0-02-hall.jpg` and
  `P0-02-open-101.jpg` (the real unit in Studio). Say yes, or what to change. It sets the look for
  every asset after it: worn, real materials under cold corridor light (D-007).
- [ ] **Branches:** everything so far is on `storage-unit`; `main` has no commits yet. Say if you
  want `storage-unit` to become `main`. Also `third-person-walls` (local): session 5 built third
  person with solid unit walls before your first-person call reached it. You confirmed first
  person on Nov 6 and it's built, so that branch is unused: keep it parked (say if a spectator
  camera ever wants it) or say "delete it".
- [ ] **Two-player door test, in first person.** Test tab → Clients and Servers → 2 players →
  Start. In both windows walk to the same door (spawn is at the hall's west end; units 101 to 108).
  Use the keys: the five prompts on a door draw on top of each other for now (fixed in L-02).
  - Walk right up to 101: its prompts stay in view with your nose to the door.
  - Player 1 presses E (Open) at 101: both windows see it roll up in about 2 s, matching.
  - Player 2 stands in 101's doorway; player 1 presses G (Slam): the door lands in a blink on
    both screens. Player 2 ends up shut inside or pushed out into the hall, and the door never
    passes through their eyes.
  - Player 2 walks into 101, player 1 presses F (Close): player 2 is shut in and can't walk out;
    player 2 faces the door, sees Lift, presses T and it heaves up slowly.
  - At 105 (padlocked) press E: "Padlocked" flashes. Shut a door, press R: the bolt and padlock
    appear for both; R again takes them off. R on an open door flashes "Shut it first".
  - One player presses E on the post by the spawn ("Go far"), waits 10 s, then "Come back": every
    door is still where it was left.
  - Look for: doors out of step between windows, a door you can walk through, a stutter when
    many doors move at once, and whether first person feels right in the hall.
