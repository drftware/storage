# Decisions

Durable choices and why, newest last. Add one when a choice would surprise a future session.
Design detail lives in the GDD; this log records the calls that shape the build.

## D-001 · 2026-11-05 · Art is code, built in Blender headless
Every model is a Python script run in Blender 5.2, so an asset can be rebuilt, resized and
re-textured by changing numbers, and the game reads those same numbers from a generated `Specs`
module. Studio's 3D Importer brings the FBX in with its textures as SurfaceAppearances. The
sibling fight project proved the approach (its D-054), with vertex colours for a toy look; this
game's horror wants worn, grounded PBR materials instead (D-007).

## D-002 · 2026-11-05 · The unit's numbers
A 10x10 unit is 12 x 12 studs wall to wall with 10-stud walls and an 8 x 8 doorway, sized so an
R15 avatar (about 5.3 studs) reads like a person (a stud is about 0.28 m). A peek lifts the
door 1.15 studs, the GDD's "a foot". The shut door leaves a 0.06-stud gap for the GDD's line of
hall light. Three sizes come from one spec: S 8x8, M 12x12, L 16x20.

## D-003 · 2026-11-05 · The door is a chain of rigid ribs on a solved coil
38 slats, one corrugation rib each, hinge at the rib valleys and wind onto an Archimedean coil
behind the header, so the door is real from the hallway, from inside and from the wire tops. One
number (rise) poses everything. A skinned mesh was rejected (bounds and culling risk, harder to
pose from code); a sliding slab was rejected (it would poke through the unit's top and look fake
from inside, where kept players watch it).

## D-004 · 2026-11-05 · Paint is the part's Color, through Overlay alpha
The door and corridor-wall colour maps carry alpha: 0 where paint shows, so SurfaceAppearance's
Overlay mode shows MeshPart.Color there. One texture set paints any door colour, so a floor can
repaint its doors for free. `UnitKit.prepare` forces Overlay in case the importer picks another
alpha mode.

## D-005 · 2026-11-05 · The server sends one motion; clients animate
A door move replicates as one string attribute (action, from, to, server start time). Every
client samples the same curve from `Motion`; the server moves only an invisible DoorCollider.
Slats are cloned on each client and never replicated. The GDD's timings live in `Motion`: peek
1 s, open 2 s, close 1.6 s, slam lands in 0.28 s, lift from inside 6 s.

## D-006 · 2026-11-05 · A shut door is one merged mesh
Most doors on a floor are shut, so a shut door shows `CurtainClosed`, the whole curtain merged
into one part, and its client builds the 38-slat chain only while it moves or stands open (from a
code review for low-end Android). A padlocked door refuses to lift, and the bolt only shoots on a
shut door.

## D-007 · 2026-11-05 · The look: after-hours self storage, worn and real
Galvanized partitions with spangle and white rust, enamel doors chalky and chipped, rust from
chips and rib valleys, kick marks and dolly scuffs where people actually hit things, oily concrete
with saw-cut joints, under cold corridor light. Detail stays where it wouldn't repeat visibly
every rib. The owner approved the unit's look on 2026-11-06 (see D-012 for its light).

## D-008 · 2026-11-05 · Systems come from Brix first
Brix, the shared library in `../engine`, is further along than this game, so the game leans on it
for as many components as it can: the lifecycle and clock, Schema, Signal, seeded Random and Zones
now; the keepers' chase (Pursuit) as soon as its system lands; remotes, save data, live config,
telemetry and the round loop as Brix releases them (owner). This game keeps only its policies,
adapters, data and art; `docs/FRAMEWORK.md` maps each need to its Brix piece. A ticket that can't
wait for a planned piece builds the smallest stand-in behind Brix's shape and swaps it out later.
(Amended Nov 9 by D-064: the keepers' brain is built in this game, not on Pursuit.)

## D-009 · 2026-11-05 · The unit template lives in the place, not in Rojo's tree
Rojo's live sync can't set the mesh on an imported MeshPart (Studio won't let plugins write it),
so a unit model synced from a file would arrive in Studio with blank parts. The prepared unit
therefore lives in the place itself at `ReplicatedStorage.Units.<Size>`, where Rojo leaves it
alone (ReplicatedStorage has no `$path`, so Rojo keeps children it didn't make). A fresh place gets
the template back from its asset ID (D-010 replaced the saved `.rbxm` copy planned here).

## D-010 · 2026-11-05 · Art goes up through Open Cloud, not the 3D Importer
The owner's porch-pirates ships every model this way, so no art waits on someone clicking a
dialog. `scripts/upload_art.luau` (with `scripts/lib/OpenCloud.luau`, taken from porch-pirates)
sends each changed FBX as a Model asset, updating the same ID in place after the first upload, and
records the hash and ID in `art/unit/assets.json`. The key lives in the git-ignored `.config/.env`.
A session then inserts the asset through Studio's MCP and prepares it (art/unit/README.md, "Into
Studio"). The asset ID is the durable record, so the planned `assets/units/<Size>.rbxm` copy is
dropped. Not taken: building meshes from repo data at run time, as the owner's fight game does,
because a game script can't set SurfaceAppearance's normal and roughness maps and the unit's look
depends on them.


## D-011 · 2026-11-05 · First-person camera
The owner's call: players see the building through their own eyes, as in Pressure. It keeps the
dark close and a keeper's arrival sudden, and it fixes what P0-02b found: Roblox's third-person
camera backed through the shut door behind you into the unit across the 8-stud hall, because a
unit has no part that stops it (docs/STUDIO.md, "Camera and prompts"). With the camera locked at
the head, the units keep their invisible box colliders as the only collision and need no
camera-blocking walls. Not taken: third person with solid unit walls, which would also need the
facade remodelled in three pieces so the doorway stays open. The owner confirmed first person
again on 2026-11-06, and it was built that day (P0-02c).

## D-012 · 2026-11-06 · The game is lit like the look sheets
The owner's call after the two-player test: the storage units look right, and the light in the look
sheets (`art/sheets/unit-hall.png`, `unit-hero.png`, `unit-inside.png`, the door videos) is the
light the game should have. The MCP's captures show the game as it really renders (the owner's
darker shot was dimmed by the pause menu), and today the hall and units read flat and near white
next to the sheets. P0-02d does it.

## D-013 · 2026-11-06 · A shut door hides whoever is behind it
Measured in Play (P0-02e): Roblox's run animation keeps playing while you push into a wall, so a
hand swings up to 1.25 studs through a 0.4-deep door collider and still 0.8 through a 1.2-deep one.
Hiding it with collision alone takes a collider about 3 deep, which would stand an invisible bump a
full stud out from every door in the hall. Instead the collider is 1.2 deep (a hall player stops
flush with the facade) and each client stops drawing anyone a shut door stands between it and
(`BehindDoors`, rule in `ShutIn`): the door is solid metal, so that is what you'd see anyway, and it
covers every avatar, accessory and tool. Footsteps still play. Not taken: a client guard that stops
your walk into a door (Roblox's control script moves the character through flag-gated internal
paths, so it would be fragile, and the swing on the last stride still crosses), or a custom run
animation (feel the owner hasn't asked for).

## D-014 · 2026-11-06 · Left Alt frees the mouse, through a Modal button
First person pins the mouse to the middle of the screen, so a computer player couldn't take a
screenshot or reach another window. Left Alt (Option on a Mac) toggles a free cursor for mouse
players; phones and gamepads get no key and no hint. It works the way Roblox documents: a visible
GuiButton with `Modal` set leaves the mouse unlocked, and the right mouse button still looks around
while it's free. The mouse is either the view or a cursor, never both (owner, Nov 6): no cursor is
drawn while it turns the view, the way first-person shooters hide theirs. Not taken: writing `MouseBehavior` ourselves (the camera script puts LockCenter back
every frame), or a fork of the PlayerModule. The key is a default the owner can change (`OWNER.md`).

## D-015 · 2026-11-06 · The hall's light: fixtures every two units, tuned at full quality
The look sheets' light comes from a few fixtures, one every 24 studs, hanging 2 studs over the
wire tops, each pooling hard cold light on the doors below with the dark between; the stairwell's
exit sign tints the far end red. `HallLight` holds those numbers for the corridor kit (P0-03) and
the motion lights (L-03). Tuned where Roblox draws its full lighting (graphics quality about 11 and
up in Studio's levels): there the hall, the hero door and a shut unit's dark inside match the
sheets. D-012's "captures are accurate" was wrong in one way: Studio on Automatic quality, like a
low-end phone, falls back to coarse lighting that ignores a light's cone and shines through thin
walls, which is where the flat, near-white facades came from. P0-02g takes on that fallback. A
default until the owner says otherwise: at most 6 real lights awake on one client at once; the
test hall uses 3. Not taken: matching the sheets' haze with Atmosphere (it stays black indoors at
midnight) or classic fog (barely shows in a dark hall).

## D-016 · 2026-11-06 · Shut in, the client keeps the hall's light out
Below graphics quality about 10 (Studio's levels; a low-graphics phone), the hall's lights cast no
shadows at all: a 2-stud concrete roof and a 2-stud block in front of the door changed nothing
inside a shut unit, and range barely matters there. So no wall thickness keeps a unit dark. The
door does it on the shut-in player's own screen instead: `BehindDoors` scales every light tagged
`HallLight.Tag` by `ShutIn.light` (6% while shut, about half at a friend's peek, full when open,
cut as fast as a slam falls) and draws the line under the door as a thin glowing strip on the hall
floor. Full quality gets the same treatment, so the moment looks the same on every device; its
real shadows already kept the room dark. Not taken: thicker walls or a unit roof (no effect),
guessing the device's quality (Roblox doesn't say on Automatic), a light under the door (one more
real light, and it would leak in too). The hall's own low-graphics look is P0-02h.

## D-017 · 2026-11-07 · A fixture is two lights: a short tube and a fill at door height
Studio's Automatic quality (and a phone's) switches between low graphics and full quality
mid-play. Measured from the spawn: floors came out the same at both, but low graphics lit upright
walls, facades and an open unit's insides 2 to 3 times brighter, so the hall flickered between
two looks and an open unit between lit and black. Neither exposure nor brightness separates the
two (both move together; low graphics doesn't cap a light). Range does: low graphics ignores
shadows, so a 22-stud tube flooded the units, while 14 reaches only the floor and doors under it.
So each fixture is now the tube, shadowed, 14 studs, for the pool on the floor, plus a
shadowless PointLight 5 studs up (`HallLight.FillHeight`) standing in for light bounced off that
pool: level with the walls, it lights them at full quality as low graphics does, and it reaches
into an open unit at both. Result: low graphics about 1.7x full quality, an open unit dimly
readable at both (the owner's pick, Nov 6). Cost: two real lights per lit fixture, so the 6-light
budget (D-015) holds three lit fixtures; the fill is tagged like the tube, so `BehindDoors` dims
it for a player shut in. Not taken: a fill at the tube's height (lit the units' tops, closed less
of the gap), guessing the device's quality (Roblox doesn't say on Automatic).

## D-018 · 2026-11-07 · The haze is a few dust puffs under each lit tube, mostly self-lit
The look sheets show grey air glowing around a lit fixture. Roblox has no light shafts or
volumetric fog indoors, so each lit tube carries a ParticleEmitter with Roblox's built-in smoke
texture: about six slow puffs, 4 to 6 studs wide, gathered 2.5 studs under the tube
(`HallLight.HazeHeight`). Measured in Play: low graphics draws a hard line where a puff cuts into
the ceiling (full quality softens it), so the puffs hang low enough to miss it, and spread in a
flat fan along the hall. A puff fully lit by the hall (LightInfluence 1) dims with its fixture but
reads about twice as bright at low graphics as at full quality, like the walls (D-017), and faint
at full quality; at 0.4 the two looks sit within about 1.3x from the spawn. The self-lit part
can't dim with the light, so a fixture's level scales the puffs' colour, a dead fixture hides
them at once (transparency is read live), and a fixture coming on throws a burst of five
(`Emit` on the server reaches players already watching). Shut in a unit you can't see the hall's
air, so `BehindDoors` needn't dim it (checked at Level08). Not tried, since the puffs did it: a
glow part, more bloom (it already smears bright neon into blobs at low graphics), a thicker
Atmosphere (it would fog dead stretches as much as lit ones).

## D-019 · 2026-11-07 · Each player's screen emits the haze's puffs
Measured in Play (P0-02j): Roblox thins a ParticleEmitter's steady puffs with graphics quality,
to about (level ÷ 21) of its Rate: 7% at Level01, 35% at Level08, all of it at Level21. The haze
held about six puffs per lit tube at full quality, two at Level08, and under one at the levels a
cheap phone plays at, where the look sheets' grey air simply wasn't there. The P0-02i shots hid
it: each was taken on a fresh burst, and `Emit` is never thinned. So the server leaves each haze
emitter's Rate at 0 and tags it `HallLight.HazeTag`, and the client system `HallHaze` emits one
puff at a time at `HallLight.HazeRate` (`Pace` carries the timing between frames, and a hitch
never dumps a cloud). Now about eleven puffs hang under the two lit tubes at Level01, Level08 and
Level21 alike. The cost of keeping them on weak phones is small: the puffs add 24 triangles and
3 draw calls. The haze is only for looks, so the client owning its timing breaks nothing the
server must own. The same client bursts a tube already lit when it first gets it (joining late,
or the tube streaming in), which fixes the haze starting clear for a late joiner. Not chosen:
raising Rate to match the player's quality level, which Automatic changes mid-play; emitting
directly needs no level at all.

## D-020 · 2026-11-07 · The corridor kit: 24-stud pieces on the unit's textures, a steel ceiling
The hall becomes pieces a floor is laid from (GDD tech plan: one tile graph). The straight piece
is 24 studs: two M units a side, three S, and one hall light's stretch. Its length is set by the
floor's texture: the unit's Concrete set repeats every 8 studs with a saw-cut joint on its edge,
so a piece a multiple of 8 long, with UVs starting on that edge, meets the next on a joint and
never shows a seam (12-stud pieces would land mid-texture). The ceiling is a corrugated steel deck
on open-web joists, the look of a real storage building and of the look sheets, reaching over
the hall and a row of units each side (32 across), so back-to-back unit rows between two halls
meet under one continuous ceiling. Its deck sits at 14 (was 13.4) so the joists can be 1.2 deep
and still stop at 12.8, clear of the haze's 12.6. The kit bakes nothing: the floor wears the
unit's Concrete and the ceiling its TrimSheet (painted and raw-steel strips), and a piece is two
MeshParts, so a hall of identical pieces draws in two calls. Templates live in the place at
`ReplicatedStorage.Corridor.<Piece>`, beside the units' (D-009). Not chosen: a MaterialVariant
floor on plain parts (seamless at any length, but a second way of shipping art, outside the
Blender pipeline); I-beams (cheaper, but read as a parking garage, not a storage building).

## D-021 The hall light is a hung strip light whose sensor dome is the building's eye (P0-03b, 2026-11-07)

The fixture is a steel strip light on two jack chains from the deck, midway between two joists,
with an occupancy sensor on one end: the GDD's "motion lights are its eyes" made literal. Its own
FBX and template (`ReplicatedStorage.Corridor.Fixture`), not part of the straight piece, so the
floor generator places lights through L-03's system rather than every 24 studs by default. Three
MeshParts: the Housing (TrimSheet: painted channel, galvanized chain, clips and junction box, a
rubber cord) and two untextured parts the game colours, the Diffuser (the lens `HallLight.light`
lights, its place and size read from `HallLight.Height` and `TubeSize`, so the art follows the
tuned light) and the Eye. The eye has three looks: Watching (a red glow, so a dark hall is dotted
with eyes), Seen (full red, the flare L-03 shows when it trips) and Blind (dead plastic, the
breaker room's zone). Its dome is a half-sphere 0.36 across, about twice a real sensor's, because
at 0.26 only the nearest eye in a dark hall read on a phone. Neon only, no light of its own: the
light budget stays at two per lit fixture (D-017). Not chosen: a separate pinprick LED beside a
white dome (real, but a pixel or two on a phone); the sensor mid-lens (it would split the tube
the light was tuned on).

## D-022 · 2026-11-07 · The hall's walls are a unit's front without the door
Where no unit stands, and at a hall's dead end, the wall is the corridor wall the units' fronts
are: the same painted Facade panels (painted per floor, like the units), posts, diamond kick plate
and cap at 10, so the hall reads as one building and a stretch with no doors reads as a blank wall,
nothing to hide behind. Above the cap an R-panel (the units' Partition set) rises to the deck: a
unit is open over its wire top, a wall isn't, which is what a real building has where a room or the
outside lies behind. The plain wall is one M unit wide (12) and its frame is a unit's door face, so
a hall side is a row of 12-stud slots, each a unit or a plain wall (L-01). The dead end is a wall
placed at a piece's open end, not a piece of its own: it spans the whole deck (32), so any hall end
can be closed, and a dead-end tile is a straight piece plus one. Its panel's valleys sit flush with
the deck's end, so no gap opens where the flutes stop. Three MeshParts each (Facade, Trim, Panel);
a wall's frame is found from its flat Facade and the Panel behind it. Not chosen: concrete block
walls (a second material the building doesn't otherwise have); a plain wall full height in the
facade paint (its texture is drawn for a 10-stud wall); a dead end with its own floor and ceiling
(a second straight piece's worth of mesh for one wall).

## D-023 · 2026-11-07 · Junctions: 24-stud squares, the deck turns on a girder
The corner, T and cross are 24-stud squares, a straight's length, so they sit on the straights'
grid (D-020): a junction's floor is the whole square mapped like a straight's, so every arm meets
it on a saw-cut joint, and its joists keep the 6-stud beat along its X arms. Halls stay on 24-stud
centres; a turned straight's floor meets a junction rotated, on a joint. Every straight keeps its
deck running along its own hall (option b of the ticket); a junction's deck continues its X arms
and a joist girder, as deep as a joist (clear of the haze) with heavier chords and a closure plate
on top, carries the seam across each Z arm's mouth. Not chosen: one deck direction for the whole
floor (option a), which needed a second straight for halls along Z, joists running along those
halls instead of across, junction ceilings that can't turn with their floors, and joists 2 studs
apart over the back-to-back rows of parallel Z halls (32 apart, not a multiple of 6). Not chosen
either: 32-stud junctions covering the whole span, which break the floor joints (16 is not 4 off a
joint) and the 24-stud grid. What a junction leaves of a hall side is whole slots: 8 (the new
short wall, an S unit's width) beside its blocks of wall and along a corner's outer sides, and two
12s across a T's stub. A steel column covers each corner where two walls meet (the posts' notch,
the caps' overlap that would flicker, the R-panels' slit). A junction's frame is its floor part's
own: Roblox's importer keeps each part's FBX axes (docs/STUDIO.md), so a square floor still knows
its turn.


## D-024 · 2026-11-07 · Motion lights: the server keeps state, each screen draws it
Every hall fixture is a motion light the server owns (L-03, GDD "Lights"). Ten times a second the
server hands a pure watch (`MotionLight`, Lune-tested) where every body that trips lights is; it
wakes the fixtures whose watch area someone moved in and darkens those that saw nothing move for
5 s, and only those changes reach players, as a string attribute on the fixture's model. A body
"moves" at 1 stud a second or more, so holding still under a light puts you in the dark (the GDD's
"hold still and you go dark to it"). A watch area is a Brix box zone under the fixture: 32 studs
down the hall (the next light wakes about 16 studs before you reach it), 10 across (the hall and a
stud into each doorway, so a unit's inside is unseen), floor to deck. Fixtures sit in a spatial
hash on the 24-stud grid. A fixture is a motion light by its tag; players' root parts trip lights
by theirs, which keepers will carry too, all but the Mannequin's. Each screen draws the state
(HallLights): the eye flares hot and settles red, the sensor's relay clicks (Pro Sound Effects,
from Roblox's audio library), the tube flickers twice and holds; falling dark, it cuts out with a
softer click and the eye sinks back; cut by the breaker, tube and eye die silently. Real light only
for the three lit fixtures nearest the camera (two lights each, D-017), with 8 studs of
stickiness against swapping; the rest glow, with no dust. Not chosen: the server lighting fixtures
itself (every Light instance replicated, and a client couldn't budget or flicker them without
fighting the server), and a fixture staying lit while anyone stands in it (a real sensor, but it
would kill the freeze). The hold, the speed and the areas are first guesses for the owner to tune.

## D-025 · 2026-11-07 · The lights follow you: your screen predicts your own
The owner played L-03: right, but the light lagged, so you could step into the dark before it
came on, and it went out too soon. A real storage hall's lights follow you. So: each screen runs
the same pure watch on its own character and shows a light lit the moment either it or the
server says so; the server's word alone puts it dark or blind, and only the server's state is what
the building sees (keepers, the light board). Other players' and keepers' lights still wait for
the server, now ticking at 20 a second (was 10). The watch area is 40 studs long (was 32), so the
light ahead wakes as you pass under the one you're at; the hold is 7.5 s (was 5; the owner said
7 to 8); the tube lights at once and holds within a tenth of a second (one stutter, was 0.3 s).
Real light goes to the lit fixtures nearest a point 12 studs ahead of the camera, so the light
you walk into wins over the one behind you. Every stretch of the test hall now has a fixture
watching it, junctions included: a junction's middle is midway between its joists, so L-01 can
hang one there. Not chosen: the server alone with a longer reach (your own first step after a
freeze would still wait a round trip).

## D-026 · 2026-11-07 · A door sounds like its motion: a rattle that follows its speed, hits on its strikes
Each player's screen plays a door's sounds from the motion the server already replicates, so no new
traffic. While it moves, one looping roll-up door rattle (Pro Sound Effects' truck rear door)
takes its volume and pitch from the door's speed every frame: the curve can't drift from the
sound, and a lift from inside's three heaves surge on their own. Hits are one-shots timed off
`Motion.strikes` (when a slam lands and bounces, a close settles, a lift meets the stop bolts), on
the server's clock, so every player hears the slam when they see it. Loudness and reach per
action follow the GDD's noise column and live in `DoorSound` for keepers to share. The slam
shakes the camera with trauma that drains (squared on screen, smooth noise), layered on Roblox's
camera by taking last frame's offset off before it updates, so aim never drifts; a stand-in for
Brix's ENG-15. Recordings are Pro Sound Effects only (licensed, load in any game); their stretches
were found by measuring loudness in Studio, since no one here can listen. Not chosen: one recorded
open and close per action (its timing would fight the curve, and Peek and LiftInside have none).

## D-027 · 2026-11-07 · The floor: halls grown from the lobby on a grid of junction points
A floor is pure data from a seed (`Floor`, L-01a). Junctions and the lobby stand only on every
other point of the 24-stud grid, 48 studs apart, with one straight on each link between two: the
D-023 rule (a straight between two junctions) holds by construction, and parallel halls stand 48
apart with both rows of units. A point with two arms in line is a straight; one with a single arm
is a straight closed by a dead end. The halls grow from the lobby as a tree (from the newest point
half the time, otherwise any; carrying straight on 60% of the time, for long aisles), so every
hall is reachable, then loops join near halls, closing a dead end first. The lobby is the grid's
first row's middle, at the origin, its one hall leading into the floor (-Z) and the elevator
behind it, so every floor's elevator stands in the same spot. Each straight's side is two M slots
or three S (25%); the kit fixes a junction's (two M across a T's stub, two S on each outer side of
a corner). Where two halls leave one junction side by side, an M slot at that end is always a plain
wall: both of them, not one, since either unit's wire top would show the decks' overlap; half such
sides are three S instead, which stop short of it, so a hall between two junctions isn't all
wall. Units are numbered floor then two digits in the order you meet them walking out (left, ahead,
right at each fork), units across the hall back to back, your left first; a floor holds at most
99, and past that units picked at random become walls (1 floor in 1,000 at today's sizes). Each
floor's doors wear one colour, in turn. A light hangs over every hall piece's middle; with the
40-stud watch every stud of hall is watched (the spec checks each one). Power zones: "Lobby" to
the first fork, then a letter per wing. Short floors (1, 2): 5 by 3 points, 8 halls and a loop,
about 60 units; full ones: 5 by 4, 11 halls and two loops, about 80. The module takes Brix's Random
through its call (the contract's rule) and stays free of Roblox paths; Brix Schema checks the
plans in the spec, and moves to their loader when live config (ENG-11) can change them. Not chosen:
junctions on every grid point (two could touch and parallel halls collide, needing a repair pass);
odd numbers on one side and even on the other, as the test hall does (with mixed S and M rows the
sides don't pair up, and gaps would run a floor past 99); numbering by distance from the lobby
(numbers would hop between wings).

## D-028 · 2026-11-07 · The small unit wears the M's textures, cropped, not squashed
The S (8 by 8, a 6-wide door) is built from the same scripts as the M and wears the same five
texture sets (L-01b). Two things made that true, and neither was before. The slats, the bottom
bar and the drum span the door's width, and their texture was laid across the whole M door, so a
narrower door squashed the paint's grain to 77%; a narrower door now shows the middle of the
texture at the M's grain (`Spec.u_across`). And Blender's smart project packs the small hardware
(the padlock, latch, plates, drum ends) differently once a part moves, so the S's pack sampled
the wrong texels of the M's bake; another size now copies the M's pack face for face from the M's
scene (`bake.copy_atlas`), and the build stops if any of those faces differs in shape from the M's.
`art.sh` never bakes for another size and rebuilds its scene before every stage, so an export
never ships stale geometry. The curtain is identical at every size (the door height is common), so
the rig, the motion and every sound cue are the M's. In the test hall the short hall past the
corner holds three S a side, numbered 109 to 114, 112 padlocked: the cramped part of the building,
apart from the M rows the owner's earlier tests use. Not chosen: baking a texture set per size
(five more sets to stream and keep in step); the S door squashing the M's texture (the grain reads
finer than the M's beside it); the S row replacing two M units in the main hall (it would move
units the open tests in `OWNER.md` name).

## D-029 · 2026-11-07 · Laying a floor: piece by piece from the lobby, inside a frame's share
`FloorBuilder.lay` (server) turns `Floor` data into the building (L-01c). It lays the lobby, then
the hall pieces nearest the lobby first, each piece with everything on it (the kit's straight or
junction, its units and plain walls, a dead end, its light) dressed in an unparented folder and
parented once; between units, and after each piece, it waits a frame once 4 ms of that frame are
spent. Floor 3 of seed 7 (67 units) took 65 ms of work over 15 frames, at most 6.2 ms in one, so
L-08 can lay the next floor while the elevator rides without a stutter. A junction is laid with
its own walls except where a unit stands (`CorridorKit.junction`'s `units`, faces in the
junction's frame), so the unit's door is the hall's side; a junction's plain-wall slots keep the
kit's wall. A unit's `drops` (floor Dirs) pick WallLeft or WallRight by whichever stands toward
that way, so it holds at any turn of the floor. Each light's power zone is named for its floor
(`Floor3.A`), so two floors laid at once never share a breaker. The lobby is a stand-in until
L-05: one plain room, its square and the elevator's space behind it, lit only by a warm lamp in
the car, the one light on a floor that is always on, so you arrive in a glow and the hall's mouth
stays dark. The door's test prompts moved from the test hall to `DoorPrompts`, for any laid unit,
until L-02 replaces them. In Studio the test hall lays floor 3 of seed 7 (Workspace's
`DevFloorSeed` and `DevFloorNumber` change it) 600 studs off, and prints its map; "Walk a floor"
by the spawn goes there. Not chosen: the floor replacing the test hall (the owner's open tests in
`OWNER.md` name its units); a fixed count of pieces a frame (a piece holds none to six units, and
six can take a whole frame); padlocks on a laid floor (L-04 deals those).

## D-030 · 2026-11-07 · The door as a state machine: buttons for its state, each in a fixed place
The door is the GDD's state machine in a pure module (`Door`), read from what it's doing (its
Motion) and its padlock: closed, peeking, opening, lifting (from inside), open, closing, slamming,
locked. The GDD's list had no closing or lifting; both are needed, closing because a door pulled
down by hand can be turned back, lifting so nobody outside can shut a door while a friend heaves it
up from inside (the GDD: lifting from inside is always possible, a clip and never griefing). The
server's `Doors` system (on the Host clock, only doors in motion stepped) shows only the buttons
the state allows, each in a fixed place on screen (`Door.Slots`, `UIOffset` 150 px apart): Peek
left, Open middle, Slam right; Close shares the left spot with Peek as a toggle, so after any tap
the spot it hit holds nothing else and a double tap can't misfire. A press is checked for reach
(plus 4 studs of lag), side (Lift only from inside the unit's doorway, Peek and Open only from the
hall while the door is down), tools and rate (0.3 s a player), then decided by `Door`. A padlocked
door tried from either side rattles: a new door motion (`Rattle`, three jerks of a few
centimetres against the bolt, the light under the door flickering) whose sound is Pro Sound
Effects "Door Shake 4" (its first shake, 0.14 to 0.9 s), so motion and sound ride one attribute
and keepers hear it as far as players (`DoorSound.Actions.Rattle`). Every door event fires the
system's `acted` signal with that reach. Not chosen: a Lock button on every door (server prompts
show to everyone, so a padlock button would sit on every shut door for a tool few carry; the
padlock tool will call `Doors:lock`); hiding Cut from players without bolt cutters (no per-player
prompts without a client-side layer; "Need bolt cutters" teaches the tool exists); buttons stacked
vertically (a landscape phone has room across, not down); Lift on T (inside, Lift is the only
button, so it takes E). Tools are a stand-in: a player's `Carries<Tool>` attribute until Phase 2.


## D-031 · 2026-11-07 · Crawl holes between side-by-side units; tops run along a row, plain walls lidded
Built on the owner's default (their choice is still open in `OWNER.md`): a saw's crawl hole goes
only into the unit beside you, as the GDD's hole trap, and a ladder's tops run along a row. Rows
stay where L-01a put them, 16 studs apart back to back, so no unit backs onto another. The pure
`Floor` records, for every slot, what shares each of its walls (left and right as you face the
door from the hall, and back): the slot sharing the most of that wall, if at least 4 studs
(`CrawlWidth`: a 3-stud hole and a stud of wall each side). A run is a row's slots side by side,
facing the same way; every plain wall in a run that has a unit gets a lid, the unit's own wire top
and floor (`FloorBuilder`), so a friend running the tops never drops into the empty slot behind a
plain wall, and looking down through the wires shows an empty unit, not the sky under the building.
Two rules came from measuring 400 seeds (`scripts/floor-survey`): up to 11 units on a short floor
had no neighbour to crawl to and 1 short floor in 10 had at most one crawl pair before the first
fork. So a plain wall picked at random stays a unit if it would strand a unit beside it, and on
floors 1 and 2 (the plan's `teachHoles`) the hall from the lobby to the first fork has no plain
walls but a back corner's, and a back-cornered side there is three S units: at least 4 crawl pairs
on the way out of the lobby, none cut off anywhere on those floors. The random draws are made as
before even where their answer is ignored, so every other choice of a seed stays the same. Not
chosen: closing a run's back and its ends at a junction's hollow block (needed before the ladder,
ROADMAP Phase 2; the deck's 2.8 studs over the tops may make them crawl-only anyway); one lid of the
two that cross at a back corner where both halls' slots are M walls (the other slot would stay an
open drop; the two wire grids cross unseen from any hall).

## D-032 · 2026-11-07 · The moving boxes: real sizes, one Cardboard atlas, faces shared in pairs
L-04 split in three (boxes, the first finds, the director's dealing) because each prop set is a
session of its own, built the unit's way. The boxes come first: every unit is full of them, the
Stack keeper is a pile of them (GDD), and a unit dealt "nothing" is boxes alone. Five boxes at
U-Haul's real sizes, 10 inches a stud (the unit's 10 feet are 12 studs), so a large box comes to an
avatar's chest and a wardrobe box looms. Each box is one MeshPart sharing one 1024² Cardboard set
(colour, normal, roughness; no metalness map). Its faces are packed whole into the atlas, and a
face's opposite twin wears the same texels seen from outside, so the atlas holds half of each box at
97 texels a stud, near the unit's walls (128) and door (118); the cost is a box showing the same
label on both long sides, as people label boxes anyway. The recipe paints in each box's own studs
and each face's, so the tape, holes and labels sit where they would on that box, and words come
from a label sheet rendered from Studio's own fonts. Not chosen: a second texture set (twice the
memory for boxes alone); SurfaceGui labels (one draw call each, on every box of every open unit);
corrugation at the cut edges (2 texels a flute at this density). Every box of a size looks alike;
a second set of labels is in ROADMAP's polish list.

## D-033 · 2026-11-07 · Each unit has its own dim bulb; players carry no torch
The owner's call, after L-04a found the hall light stops at an open unit's doorway: "a small light
in each unit, dim", and players don't need a torch. So what's behind a door is seen by the unit's
own bulb, not by a beam the player aims. Default for the gap (`OWNER.md`): the bulb comes on as the
door rises and goes out when it's shut, keeping a shut unit the GDD's blind spot and P0-02g's dark
with a line under the door. On a phone only the nearest lit bulbs throw light, as the hall lights
do. Not chosen: a torch every player carries (R.E.P.O.'s head lamp), which would make the dark
something you push back yourself rather than the building's.

## D-034 · 2026-11-07 · The unit's bulb: wired to its door, drawn by each screen from the door
L-04b builds D-033. Each unit hangs a caged bulb on a short cord from the middle of its wire top, a
piece of the corridor kit (`Bulb`: a galvanized guard and a bakelite socket on the TrimSheet, a
plain glass the game lights), hung by `FloorBuilder.unit` from the wire top's own box, so every
size gets one. It's wired to the door like a fridge's light (`ShutIn.bulb`): on as the door starts
up, a peek's included, out the frame a closing door lands, and out through a slam's bounce; a
padlocked door's rattle never lights it. Each screen draws it from the door's replicated motion, as
it draws the door, so the server sends nothing new and the bulb can never disagree with the door.
Warm amber (the hall is cold white), 0.6 strong with an 11-stud reach, tuned at Level21 on the
Galaxy A16 view: at 1 and 12 an M unit read as a lit room to its corners. The guard casts no
shadow: from a point light its wires threw hard black bands across the whole unit. Real light and
the hum go only to the 3 lit bulbs nearest a point ahead of the camera, as the hall's fixtures do.
The light carries HallLight's tag, so BehindDoors dims a lit neighbour's bulb for whoever is shut
in (low graphics lights through walls), but leaves the bulb of the unit you're shut in whole. Not
chosen: a server-owned bulb state (one more replicated value that can only echo the door); the
bulb as part of the unit's own model (the unit's FBX and bake are the unit pipeline's, and a
lamp is a kit piece the lobby can reuse).

## D-035 · 2026-11-07 · The bedroom set's first finds: four real things, one atlas, unwrapped one by one
L-04c builds the GDD's 1980s bedroom set first, four pieces chosen to read from a doorway at phone
size in a dim unit: shape first (two round speakers and a handle; a screen and rabbit ears; a
bear's round ears; four pink wheels) and colours apart from the boxes' kraft (chrome and black;
walnut and silver; cream; white and pink). Real sizes at the boxes' 10 inches a stud. One texture
set per set (Bedroom: colour, normal, roughness and metalness, which the chrome needs), so a
floor's finds cost one set of maps. Dust is baked in on whatever faces up; a mimic will wear the
same atlas baked clean, not a second mesh. The GDD names no look for rarity, so there's none.
The pipeline differs from the boxes' in three places, each a Blender trap met here: each find is
smart-projected alone into its own square sized by its surface (unwrapped together, the teddy's
islands folded over one another); the bake runs with no margin and pads the gutter afterwards from
a coverage pass (each object's margin painted over its neighbours' island edges); and the bake's
unwrap is saved and worn by the later stages, with spheres built point by point (smart project
packs differently each run, and bmesh's `create_uvsphere` numbers its points differently). The
import into Studio was split off to L-04c2. Not chosen: the boxes' face-by-face atlas (curved
things have no flat faces to pack); printed words now (unreadable at phone size, in polish);
a rarity glint.

## D-036 · 2026-11-07 · Finds stand behind the unit's bulb; the skates lie wheels to the door
L-04c2 judged the four finds in unit 101 from its doorway on the Galaxy A16 view. Staged between
the bulb (at the unit's middle) and the door, each showed the doorway its unlit side: the TV a
black box, the boombox a dark lump, at Level21 with or without its metalness. A step deeper, behind
the bulb, all four read at Level01 and 21. So the director deals a find deeper than the bulb,
facing the door within a small turn, among the boxes in the back half, which is also where a real
unit's things end up. The skates' pair was re-posed in `art/finds/spec.py`: the fallen skate lay
behind with its wheels away, hiding the standing one's; it now lies in front with its row of pink
wheels to the door, the shape that says roller skate at 30 pixels. The pair is placed after the
bake, so the atlas didn't change. Not chosen: a brighter bulb (L-04b tuned it for dread, and the
owner judges it); a glint or rim light on finds (no hit-game precedent named; a mimic's clean look
is the tell, D-035); bigger-than-life finds (they match the boxes' real sizes).

## D-037 · 2026-11-08 · The loop first: every tool that works on any keeper moves into Phase 1
The owner judged the finds and boxes good, and set the order: an entity on the floor and the loop
proved fun (being chased, finding the code and tools, trapping keepers, slipping between units
from inside) before more polish. The props only dress a unit; finds are the run's payout and the
collection (GDD "Meta"), which the GDD's own build order already left to its second step. So
Phase 1 now holds the flashlight, the saw and the hole trap, the ladder (with closing the tops'
edges), bolt cutters, the padlock, bubble wrap, the air horn, the moving blanket and glow sticks
(L-11 to L-14), and the GDD's build order says the same (edited that day). Keeper-specific tools
(mothballs, the box cutter) stay with their keepers, the dolly with the finds. The Mannequin
splits: its art (L-06a) goes now, its chase (L-06b) waits on Brix's ENG-06 and ENG-07 and moves up
when they land. Where a unit's boxes and find stand, and carrying finds out, moved to Phase 2.

## D-039 · 2026-11-08 · The Mannequin: rigid R15 parts, posed by code, a stop-motion walk
The Mannequin is a shop mannequin cut at every joint into R15's fifteen body parts, each a rigid
MeshPart (no skinning), each end a dome that shows as a ball when bent, 6.3 studs tall (a head
over a player). `Mannequin.prepare` joins them as `Humanoid:BuildRigFromAttachments` would: a
RigAttachment pair at each pivot and a Motor6D named for the joint, under an anchored, invisible
HumanoidRootPart; no Humanoid yet (L-06b adds one only if Brix's `MoveTo` driver is chosen).
Poses are code, not uploaded animations (`Mannequin/Pose.luau`, pure, Lune-checked): its joints'
turns in degrees within each joint's limits, solved through the joints so every pose is checked
standing on the floor with no part through another, applied as `C0 = RigAttachment * turn`. Its
walk is four held keys with a snap between (stop-motion), and a light freezes it on a key, never
between two: it moves only unseen (GDD), so the keys are what players see, as Five Nights at
Freddy's animatronics are seen only where they stopped and SCP-173 moves only while unseen.
Uploading animations was possible but would put the poses beyond Lune's reach.

## D-038 · 2026-11-08 · The deal: notes and padlocks when the floor is laid, the rest on the first lift
`Deal` splits the GDD's "What's behind the door" in two. When a floor is laid: the code, its notes
(two with two digits each on floors 1 and 2, four with one above), placed one to each wing in turn
(the zones past the first fork) so a team splits up, at least 48 studs apart where any room
allows (it held on all 600 test floors), as DOORS spreads its door-50 code through the library;
the padlocked doors (6 in 100 units on floors 1 and 2, 12 above), never in the lobby's hall, and
from floor 6 the first note behind one. When a door first lifts (a peek or an open), the director
deals: nothing, a find, a tool, or a keeper asleep or awake, by its mood (Build 40/25/20/10/5,
Peak and Relief wake nothing), times the padlock's (more finds and keepers, rarely empty, as
Escape from Tarkov's locked rooms hold its best loot), the awake share turning asleep at the
floor's cap (1 on floors 1 and 2, 2 on 3 and 4, 3 above, as Left 4 Dead caps its specials). Each
unit's roll is drawn when the floor is laid, so a seed deals a unit the same kind of thing in the
same mood whatever order doors open in. Tools come out of a shuffled bag of 11 (two saws, bolt
cutters and padlocks, one of each other tool), as Tetris deals its pieces, so none goes missing
for long. Floors 1 and 2 teach: the bag's first tool is a saw and the lobby's hall deals no
keepers. A floor with no fork (about 1 in 50) counts its first 8 doors as the lobby's hall. Not
chosen: one random stream for everything (the order of opens would change every kind); notes at
random with spacing alone (all four could land in one wing); a cap on sleeping keepers (the GDD
caps only awake ones; the owner judges the count from `scripts/floor-deal`). Fake notes wait for
Phase 2's floors.

## D-040 · 2026-11-08 · The elevator: the car's own lattice gate, notes written by the game
The way up is a freight car behind a steel frame in the lobby's back wall (a 12.4 x 9.2 hole),
12.5 x 11 x 9.6 inside: room for the GDD's six to stand clear of the gate and for the Mannequin
to walk under its track. There is one gate, the car's own, a collapsible lattice gate as old
freight cars have, so it rides up with the car and you watch the lobby through it while the
timer runs (the gate shutting on its own timer is Dandy's World's). It folds to the left post as
you face the car and closes toward the keypad on the right; its pickets and 72 straps are cloned
from three meshes and posed by code (`Elevator/Gate.luau`, pure: a strap's angle is
acos(pitch / its length), so its pins stay on the pickets at any spread). Its sills are striped:
the line to be over when it shuts. The notes' digits aren't baked: a note shows one or two
digits in four slots (`_ 7 _ _`, GDD), too many ways to bake, so the game writes them with a
SurfaceGui in Kalam (Roblox's pen hand, Bold), as the units' numbers are written; the sheets use
the same font. Notes are a big pad's (0.7 studs) so they're spotted from a doorway. Three
texture sets: the car's walls and floor tile (80 texels a stud), the big trim is baked (41), the
small fittings (gate, lamp, keypad, keys, note) are baked at 133. Not chosen: a landing gate as
well (two gates to read, and the car's is the one players watch); baked note faces; vertical
bi-parting doors (solid, so you couldn't see what's coming while you wait).


## D-041 · 2026-11-08 · The elevator in the place: one template, its lamp casting shadows
The elevator is one template at `ReplicatedStorage.Props.Elevator` and the note another at
`Props.Note` (D-009), both made by `Elevator.prepare` from the Open Cloud import. The lobby's back
wall is three blocks round `Specs.Opening`, its face on the threshold, and the lobby is now just
its square: the car fills the floor's elevator space alone. The car's lamp is the stand-in's
light moved into the jelly jar (warm, 1.2, range 22) with shadows on, so it reaches the lobby only
through the opening and prints the gate's lattice on the lobby floor, the strongest "elevator"
read from across the room; the lamp, its glass and the keypad's small parts cast none. The whole
elevator streams as one piece (`ModelStreamingMode` Atomic), so a phone never shows half a gate.
`setGate` moves the gate's 85 parts in one `BulkMoveTo`. A note's digits are written on an
invisible card over the paper's flat writing area, not on the curled paper's box, at 400 pixels
a stud, with no padding top or bottom: Kalam's line is tall, so the width sets the size, as on
the sheets. Not chosen: a light without shadows (it lit the lobby through the car's walls);
writing on the paper's own face (its box stands 0.12 proud where the foot curls). The keypad
lights itself (owner's test, Nov 8): it hangs on the lobby's side of the wall, so once the lamp's
shadows settle no light reaches it and it went black; a small red light just in front of the
panel (`Elevator.KeypadGlow`, 1.6 studs) makes it the keypad's own glow, the sheets' "red glow"
seen across the lobby. Not chosen: a landing light (the lobby stays lit only by the car).

## D-042 The keypad is shared, checks on the fourth digit, and the server owns it (L-05b1a, Nov 8)

One keypad per floor and one readout for the team, as a real keypad is: you can punch the first
three digits while a friend runs back with the last (the GDD's co-op moment). There's no enter
key: the fourth digit is checked at once, as door keypads do, so a fat thumb costs a wrong code.
A Clear key, on the on-screen keypad only (owner, Nov 8; the wall's keypad has none), takes
back a mistyped digit before the fourth, so the alarm punishes guesses, not thumbs. Every
player types on that on-screen keypad, opened by the wall keypad's own prompt (owner, Nov 8),
as DOORS' padlock at door 50 opens: the wall's keys are a fifth of a stud across, and on a
phone the jump button sits over them. A wrong
code rings the alarm, lights every powered light on the floor at once (`MotionLights.flash`,
which lights them without `woke`: the building didn't see anything there, the keepers come to
the lobby instead, L-06b) and leaves the keypad dead for 3.5 s, its readout blinking the wrong
digits, then clears it. The code never leaves the server; the keypad's state crosses as one
counted value (`Keypad.Attribute`), so the same press twice still shows. The remote is the
smallest stand-in for Brix's typed remotes (ENG-09), its checks in their order: types, range,
rate, state. The gate's motion is one value too (`Gate.Attribute`: from, to, start), which every
screen folds the gate from and the server sizes the collider from, so the gap you see is the gap
there is; the gate gathers speed into its slam (ease-in) and recoils 2.5% for 0.22 s, as a
yanked lattice gate does, and its fold sound builds to the same slam. Not chosen: 85 parts moved
by the server; a ProximityPrompt per key (ten prompts on a panel a thumb wide); an idle timeout
on the readout (it would wipe the first three digits while you wait for a friend).

Settled (owner, Nov 8, after playing L-05b1c: "looks good"): all three rules stay as built.

## D-043 The keypad answers on every screen: LED digits, a pad by your thumb, sounds on the gate's clock (L-05b1c, Nov 8)

The readout is four seven-segment LEDs drawn as segments (`LedReadout`), not a font: no Roblox
font looks like a keypad's LEDs, and a dash at rest is then exactly the middle bar lit low, with
the unlit segments faint under the glass as a real one's are. One pure rule set
(`Elevator/Readout.luau`) feeds the wall and the screen, so they never disagree; the wrong code
blinks 0.2 s on, 0.2 s off with the status light, and green holds once the code is right.

The on-screen keypad (`KeypadPad`) opens from the keypad's own "Use" prompt (owner, Nov 8). Its
left edge sits 58% across the screen so the wall's keypad stays in view and you see its keys
sink; it fills 92% of the height under the top bar, which on the Galaxy A16 makes a key 44 by
41 points (at 72% they were 36 and hard to hit) and still leaves 22 points to the jump button.
A press dips the key and beeps and sinks the wall's key at once; the readout waits for the
server (one ping), so it never shows a digit the server dropped. The server's echo names who
pressed (`by`, now on a clear too), so your own press never beeps twice. Dead keys dim during the
alarm; the right code shows green for 0.9 s, then the pad slides away as the gate folds.

The sounds are timed off the server's clock (`Elevator/Sounds.luau`): the beep at once, the
buzzer 0.12 s after the last beep and the bell 0.4 s after, ringing exactly as long as the keypad
is dead; the ding 0.12 s after the right code, the latch 0.3 s before the gate moves, and the
fold started where its recording's slam lands the instant the gate hits, for any distance it
travels. A recording's first play in a session starts 0.26 to 0.35 s late even preloaded, which
would put the slam after the gate; `SoundPrimer` plays each once silently at start. The slam
jolts anyone within 5 studs (trauma 0.5, gone by 24), on the frame the gate hits.

Not chosen: a font for the digits; showing a pressed digit before the server accepts it; the pad
centred over the wall's keypad (it hid the keys you'd want to watch sink).


## D-044 The code's notes on the units' back walls, read from a few steps in (L-05b1b, Nov 8)

Each note the deal hands a unit (`Deal.new`, two notes on floors 1 and 2, four above) is stuck as
FloorBuilder lays that unit: always on the back wall, facing the door, at first person's eye
height (4.5 studs), on a crest of the corrugated wall, a little off the middle and up to 4
degrees crooked, varied by the unit's number (`Elevator/NoteSpot.luau`, pure, Lune-checked). One
place to look, learned on floor 1, so the search is about which door, never where in the unit.
The door lifts, the unit's bulb comes on, and the note is the one yellow thing in the box.

Measured on the Galaxy A16: the writing's digits stand 0.107 studs tall on the art's 0.7-stud
note, about 5 rows of the phone's view from a small unit's doorway, so nobody reads a digit from
there. The note is drawn at 1.6 times the art's size (`NoteSpot.Scale`, a 1.1-stud note): a
plain square from any doorway, its digit about 30 rows tall (2 mm on the phone) from 5 studs.
So you see a note from the hall and read it two steps into a small unit, five into a big one.
Reading from the doorway itself needs the writing laid out larger, four slots across with each
digit as tall as the note allows (about twice today's), or the note held up to the screen as
DOORS shows its library hints: the owner's choice (`OWNER.md`).

The text is written on the server and replicates with the unit, so an exploiter can read every
note on the floor; the hunt's honesty rests on the keypad's server check, not on hiding the
notes. Clients load Kalam as they start (`NoteView`, by measuring text in it) and redraw any
note that arrived first, since a note can stay blank until its writing is redrawn.

Not chosen: notes on a box (units hold no boxes until L-04e, and boxes move); notes anywhere in
the unit (a hunt inside the hunt, on a phone, in the dark); the note at the art's size.

Settled (owner, Nov 8): a "Read" button on each note holds it up on your screen, big, as DOORS
shows the hint in a library book (L-05b1d). The note stays on the wall at 1.6 so it's spotted
from the doorway; the button is how its digit gets read on a phone.

## D-045 Reading a note: the real note held up on the screen (L-05b1d, Nov 8)

Two steps into a note's unit (within 6 studs of the button, `NoteCard.Reach`) a "Read" button
shows under the note, never over it and never from the hall: you go in to read it, as DOORS makes
you walk to the library book. A tap lifts the note into the middle of the screen, as big as a
phone held sideways allows (84% of the height under Roblox's bar, at most 48% of the width, so the
thumbstick and jump button stay clear and stay usable). It rises from below, a little smaller
and more crooked, and settles with a small overshoot at the same tilt it hangs at on the wall, to
a paper flap; the world behind dims to 55% so the note stands out and you still see what's coming.

The card is the note itself: its own paper mesh, drawn face on in a ViewportFrame under a warm
light so it's the wall's yellow, brighter, with its thumb smudge and curled foot. A SurfaceGui
draws nothing inside a ViewportFrame (seen in Studio), so the four slots are TextLabels laid over
the paper's writing area (`Specs.Note.Write`, the wall's 4% margins), each a quarter of it, all
at one TextSize, so a blank and a digit are written alike. On the Galaxy A16 that's TextSize 94
and a digit 7.7 mm tall; on the wall from 5 studs it's 2 mm.

It drops on a tap on it, Read again (E, gamepad X), B, a click (mouse), walking back out to about
the doorway (8 studs, `NoteCard.LetGo`), dying, or the note leaving. For 0.3 s after it lifts,
taps and keys are ignored, so the tap that pressed Read or an impatient second one can't throw it
away. You can walk and look while it's up: the keepers don't wait while you read. The mouse isn't
freed for it: a click anywhere drops it.

The sound is Pro Sound Effects' "File Folder Movement 5" (9114409576), its one sharp flap at 0.78
to 0.88 s; the drop plays it lower and softer. All on the client: the note's writing already
replicates (D-044), so nothing new goes over the wire.

Not chosen: the note's texture cropped from the Fittings atlas as a flat image (the UVs are packed
and may turn, and it's the same 130 texels as the mesh); a plain yellow square (not the real art);
the digits laid larger than the wall's writing area (the card should be the note you saw); freeing
the cursor with FreeCursor (nothing to click but the note itself).

## D-046 The gate's clock: 30 s from the slam, felt everywhere on the floor (L-05b2, Nov 8)

The clock starts when the right code's gate has slammed open (the chime, the latch, the 1.6 s
fold), not at the code itself, so the 30 s are 30 s of open gate. It's the server's: one
replicated value on the elevator (`Departs`, the server time the gate starts to shut) that every
screen counts from, so friends count the same seconds; the server shuts the gate at zero with the
gate's own 1.2 s slam (`Gate.ShutSeconds`), and nobody can send it early (GDD). The instant the
shut gate hits its post, a Brix Zone box over the car (wall to wall, the gate's pickets to the back
wall, floor to ceiling) says who rode: their UserIds go out as one value (`Aboard`) and the server
fires `departed`. A player diving through the narrowing gap makes it if their middle is inside the
pickets when the gate hits (verified: crossed at 28% shut).

Everyone within 240 studs of the elevator is on its floor (a floor's farthest hall is 195 studs
away, measured over 300 seeds); they see the clock and hear the PA. What they get, by the GDD's
Dandy's World line (an alarm and a heartbeat over its elevator timer):
- The clock: the elevator's own seven-segment LEDs on a dark plate, in the middle of Roblox's top
  bar row (clear of its buttons, `GuiService.TopbarInset`), so it never covers the play or a held
  note. Green while there's time, red from 10 s; it jumps each second of the warning.
- The PA's chime as it starts (Pro Sound Effects' synth elevator chime, heard alike across the
  floor), so a friend at the far end knows to run before they see anything.
- From 10 s: the car's lamp blinks, slowly then ever faster (0.9 s blinks down to 0.16 s), and a
  heartbeat (APM's, 78 a minute) swells from 0.2 to 0.6 volume and quickens to 1.45 times its pace.
- The last five seconds: the elevator's bell (the right code's double-ding) once a second, each a
  little higher.
- Leaving: "Going up" in the lamp's warm colour for those aboard, a lurch 0.7 s after the slam;
  "Left behind" in a cold red for the rest, and the car's light draws away over 1.6 s, leaving the
  lobby dark. The stand-in ride (until L-08): 4 s, fading to black over its last 0.6 s while the
  dev floor moves those aboard back to the spawn and re-arms the elevator.

Not chosen: the clock started at the code (the gate isn't open yet); a timer label in the play
area (it covered the held note and the keypad's pad on a phone); a client deciding who's aboard
(the server owns it); positional countdown sounds (a friend at the far end must hear them);
a PA voice now (no recording yet: ROADMAP polish).

## D-047 The flashlight: yours drawn on your screen, the server owns on and off (L-11a, Nov 8)
Everyone carries the torch from spawn, in the right hand, as the GDD's tools table says; it is no
slot's tool. Your own is a copy on your screen only, held to the camera (`Torch.Hold`) in a local
Workspace folder and stepped after the camera and its shake; the one in your character's hand is
hidden from you by Roblox's first-person camera and drawn for friends. Each screen lights a torch
itself: yours the moment you click (the click, the lens, the beam, the button), friends' from the
`On` attribute the server writes. The client sends the state it wants, not a toggle, and sends it
again if the server disagrees for 0.4 s, so a refused or lost message can't leave it inverted; the
server takes a burst of four switches, then one each 0.08 s, so three blinks ("it's me", GDD) go
through and mashing doesn't. While it's on, your look's pitch goes to the server (unreliable, at
most ten a second, only when it moves 1.5 degrees); friends' screens raise your arm to it after
your animation (the shoulder's Transform), and keepers will read it (L-06b). Keys: a right click
(Lethal Company uses its mouse buttons for the held item) and R1, because F already closes a door;
a phone button above the jump button. No battery and no flicker: the GDD gives the torch neither.
Light budget: your beam and the nearest three friends' (within 140 studs) are shadowed spotlights;
past that a friend's torch shows its lit lens only. A soft PointLight just above your torch's head
throws the spill ring round the pool and lights your torch in a dead hall; it also lights a wall
close in front of you at low graphics, where a spotlight lights nothing nearer than about 3 studs.
Not chosen: F (the door's Close); the server switching lights (your own would show twice and lag a
round trip); the torch as a Tool (Roblox's backpack and its arm pose); a battery (not in the GDD).


## D-048 Two tool slots, Lethal Company's way; the tool in your left hand (L-11b, Nov 8)
You carry two tools besides the torch (GDD: "two tools plus whatever's in your hands"), as Lethal
Company's slots: one slot is in your hand, and an empty slot is an empty hand. Picking up or being
handed a tool puts it in your hand if it's empty, otherwise in the other slot and into your hand
(you see what you took); both refuse when both slots are full ("Hands full" on the prompt). Drop
and Give take what's in your hand and leave that hand empty. Rules are pure (`Tools.Carry`); the
server owns every tool (`Slots`): a tool lies on a floor with a "Pick up" prompt (E, X on a pad)
until taken; carried, the one in hand is welded in the left hand for everyone, the rest are out of
the world. A tool is one row in `Tools.Catalog`, keyed by `Deal.Tool`, as keepers are rows.
The left hand, because the torch has the right (D-047); your own is drawn on your screen, low on the
left with the torch's sway, swinging up as it arrives and down as it goes. Switching answers at
once on your screen (a soft clank; the server is told and has the last word after 0.6 s); a pick-up,
drop and handover wait for the server, whose clanks everyone near hears. A drop lands crosswise
2.2 studs ahead of you, its middle on the floor a ray finds (short of a wall), falling 0.32 s.
The bar: two squares at the bottom middle with a real 3D picture of each tool, tap or 1/2 or the
d-pad; Drop beside it (G, d-pad down) while you hold something; the tool's name above the bar for a
moment, as Minecraft's hotbar names what you switch to. Handing over is a local "Give" prompt on
each friend within 10 studs while you hold a tool: Lethal Company has no handover (you drop it at
their feet), so this one-press shortcut is an untested bet in `OWNER.md`. Brix has no carried-items
piece (FRAMEWORK); `Carry` and `Slots` are the stand-in behind that shape. Until L-11c reads the
slots, `Slots` keeps the old test attribute `CarriesBoltCutters` true while either slot holds
cutters, so Cut still works; the test hall's "Bolt cutters" post is gone, two pairs lie on floors.
Not chosen: Roblox's Tool and Backpack (its arm pose, its own hotbar and keys; the Backpack core UI
is now off); the server drawing your own held tool (a round trip late, and it can't sway).

## D-049 Tools work in your hand; the padlock goes on and the cutters snap it off (L-11c, Nov 8)
A tool works only in your hand, as Lethal Company's do: Cut needs the cutters in your hand, Lock a
padlock in your hand. One in your other slot gets "Hold the cutters" or "Hold the padlock"; none at
all gets "Need bolt cutters" or "Need a padlock" (`Door.decide` takes where each tool is: hand,
slot or none; `Doors` reads it from `Slots:carried`). The `CarriesBoltCutters` stand-in is gone.
Lock is a door button like Cut, in the same right-hand spot (they never show together), both held
(Cut 1 s, the GDD's; Lock 0.5 s so nobody padlocks a friend in by a slip; `Door.Holds`), keys R
and R2 (R1 is the torch's, D-047; Cut moved off R1). The server shows Lock on every shut door; each
screen hides it unless a padlock is in that player's hand (ToolView sets the button's reach to 0:
the server never changes a button's reach, so it stays). The padlock that goes on a door leaves
your slots for good (`Slots:spend`); on the door the building's own padlock part shows.
"One padlock per use" (GDD, the cutters' row) is read as: a cut padlock is spent, the cutters last;
the owner may mean the cutters break instead (`OWNER.md`). The cut answers in three ways: the jaw's
snap (Pro Sound Effects' "Scissors Snap 28" at half speed, loud, heard 40 studs: keepers hear a cut)
with a jolt for whoever's at the door; a copy of the padlock thrown off the latch on every screen,
tumbling about 1.5 studs out onto the hall floor, lying 20 s, then fading (`DoorView`); and its
clatter as it lands. While you hold Cut or Lock with the right tool, your view brings it out to the
door (the row's `use` pose), and it jerks as it works. The padlock you carry is the doors' laminated
padlock, open, at twice their size so it reads on a phone (`art/padlock`).
Not chosen: a brass padlock of the players' own (it would change look on the door unless the door
drew it too); a per-player Lock prompt made on each client (the server owns the door's buttons).

## D-050 The deal laid on the floor: padlocks as the floor is laid, the rest on a door's first lift (L-04e, Nov 9)
The doors a floor's deck padlocks arrive padlocked: FloorBuilder sets each one's padlock as it
lays the unit, before it reaches Workspace, so no padlock sound plays and every screen gets the
unit already locked (`Doors:lock` with no player would fire a padlock's sound for each door).
Everything else is dealt when a door first lifts, a peek, an open or a lift from inside, by the
new `Deals` system listening to `Doors.acted`, as Left 4 Dead's director deals as the team moves:
`Deal.open` in the Build mood (the director is Phase 2), the keepers awake counted from those dealt
awake on the floor so far. What's laid goes down at the start of the lift, so a peek's foot of gap
shows it on the floor. A tool lies to be picked up (`Slots:lay`); a find stands as a prop (carrying
finds out is Phase 2, "Finds in a run"), which find picked by the unit's own roll from `Deal.Finds`
(the bedroom set, equal odds until rarity); a keeper's place is handed on by `Deals.dealt` for
L-06b to stand the keeper there. A tool with no art yet (the saw, the ladder, bubble wrap, the air
horn, the moving blanket, glow sticks) is dealt but lies nowhere: about 6 dealt tools in 11 show
nothing until L-12 to L-14 build them; Output in Studio says so per door.
Where in the unit is `DealSpot`, pure and Lune-checked: on the floor, 0.4 studs off the walls'
middle lines, 2.5 studs clear of the door's line; finds and keepers wholly behind the bulb, facing
the doorway's middle within 8 degrees (D-036); tools in the bulb's pool (their footprint between a
quarter and 70% of the depth: at the back wall of an M unit the bolt cutters read as a red smear
on the Galaxy A16, `docs/art/L-04e-cutters-301.jpg`), at one of six careless turns; the spot picked
by the unit's number. The note's sight line (D-044) is kept as a real line, not a floor plan: the
eye looks at the note from 4.5 studs up or higher, so a thing under 3.5 studs (every tool and find)
may stand under the note, and anything taller (a keeper) keeps 0.3 studs off the whole floor
between the doorway's width and the note's. A small unit's 6-stud door in its 8-stud box leaves a
keeper only the back corner beside the note's line, too tight to turn in, so there a keeper faces
straight out (then square on) instead of at the doorway.
Not chosen: dealing every unit when the floor is laid (the deal is the director's to pace, and a
peek should be a gamble, D-038); keeping finds out of the whole floor fan in front of the note (in
an S unit it left a boombox nowhere to stand, and nothing that short can hide the note); a glint or
highlight on tools (no precedent named, D-036's reasoning); laying a stand-in for unbuilt tools.

## D-051 The saw: a green cordless reciprocating saw, standing on its battery (L-12a, Nov 9)
The GDD's saw ("cuts a crawl hole into the next unit; keepers can't fit through; loud") is a
cordless reciprocating saw, the tool a real crew would cut drywall and sheet metal with, built
from code the cutters' way (`art/saw/`): one MeshPart, one baked 1024² set, no brand. Green,
because the torch is yellow and the cutters red, so the three never blur at a glance, and green
stays green under a unit's warm bulb where blue goes grey. Sized about 1.3 times life (2.9 studs
blade to tail), a little under the cutters' scale but a bigger thing, so it reads on a phone from
a doorway as a green power tool with a blade. It's laid standing on its battery (every tool is
laid with its lowest point on the floor and its own up kept up, `Slots`), its side profile the
most readable thing in the unit. In your view it sits low on the left by its rear handle, turned
in 26° so you see its side, sticker and blade reaching to the middle; far enough out and left
that the slots' bar clears it on the Galaxy A16. A friend sees it carried upright by the rear
handle at your side, blade forward (`inHand` 0, 0, 0), as you'd carry a drill at the ready; the
honest carry (hanging nose-down from a relaxed hand) reads less as a saw, and is the owner's call
(`OWNER.md`). Its `use` pose (out in front, blade level) is a placeholder for L-12b. Picking it up
plays Pro Sound Effects' "Plastic Ice Chest 25" (a hollow plastic knock, 0 to 0.42 s); dropping
it, "Chair Drop 3" from its first hard hit (0.22 s, 0.9 s long, a little higher pitched), both
measured by loudness since nobody here can listen. The saw is the first tool out of the bag on
floors 1 and 2 (D-038's teaching floors), so it now lies there; `Specs/Saw` carries its blade's
tip and the shoe's face for L-12b.
Not chosen: a hand saw or a drywall jab saw (quiet, and the GDD says loud); a chainsaw (a horror
villain's weapon, not a crew's, and too crude for a neat hole through a unit's wall); lying the saw
on its side (its profile foreshortens from a doorway and its battery hides).

## D-052 The crawl hole: one fixed spot per wall, its own kit swapped in (L-12b1, Nov 9)
A saw's crawl hole opens at the same place in every unit's side wall: 3.75 to 6.75 studs along
from the corridor wall's outer face, 0.3 to 2.9 up (`crawl_*` in `art/unit/spec.py`). Players
learn where to look and where to crawl, the "Crawl through" button and keepers (L-12b2, L-12c)
have one spot per wall, and the art is built once rather than cut anywhere at runtime. The spot is
past the door's guides and in the bulb's light, and a stud short of a small unit's back wall, so
it fits whichever neighbour stands the shared wall (D-031): two units side by side in a row share
at least a small unit's whole side. It is 3 wide and 2.6 tall: a player ducks through on hands and
knees, a standing body (4 studs to the top of its root) can't walk it, and the Mannequin (6.3 tall,
and stiff: it can't bend) never fits. The hole is a kit of its own (`art/hole/`, asset
`Props.CrawlHole`), not parts in the unit's FBX: the unit and its prepared templates stay as they
are, and only a cut wall pays the hole's triangles (2,532 against the plain wall's 336). The holed
walls and the fallen panel wear the unit's own Partition texture (`prepare` copies it from
`Units.M`), so the swap changes nothing but the hole; the bright strips, cut faces and tongues are
a small Hole set. Its pieces come both ways round (Pos and Neg): the tongues bend and the panel
falls away from whoever sawed. The wall's one collision box becomes four round the hole
(`CrawlHole.Boxes`). Not chosen: a hole cut wherever the saw meets the wall (runtime geometry, or
many prebuilt walls, for no gain in play); a hole down to the floor (the bottom track would have
to be cut, and a saw cuts the sheet above it); a corner pair's two walls (a side against another
unit's back wall) holed: those stay unsawable, the rarer case, until a floor needs them.

## D-053 Sawing the hole: a four-second hold, loud the whole time, lost if you let go (L-12b2, Nov 9)
Every two units side by side in a row get a Saw button each side of the wall they share, at the
hole's front third (`Saws`). It shows only on the screen of someone carrying a saw (either slot):
a saw in your other slot gets "Hold the saw", as the cutters' "Hold the cutters". Hold it 4 s (R,
R2 on a pad, the cutters' keys): a held, noisy job, as Dead by Daylight's generators are worked by
holding and Granny hears every sound you make. The motor (a grinder's whine) and the blade (a cold
saw grinding pipe) are heard 200 studs off, further than any door (110), and `Saws.sawing` tells
keepers the same as the motor starts and as the panel falls (L-06b). A bright orange-hot line
crawls round the cut from its top front corner at one speed (`Sawing.line`, pure, 3,248 Lune
checks), sparks fly on the sawer's side, the sawer's view buzzes and their saw shakes out at the
wall. Through, the panel tips over from the hole and slaps flat on the far side with a sheet-metal
clang that jolts anyone within 30 studs. The server checks the press as Cut's (inside the unit you
saw from, in reach, the saw in hand, rate) and again before the hole goes through: the hold must
have run its time (a faked press can't cut early); walk off, switch tools or die and the cut
stops. Let go early and the cut is lost: the next try starts over (the prompt's own ring restarts,
and a half-cut wall would need art of its own). The deal keeps tools off both side walls' hole
spots, and finds and keepers too unless they'd have to stand in front of the bulb (D-036 first):
in a small unit the hole's stretch is most of the back half, so its finds and keepers mostly
stand on a spot anyway. Not chosen: progress kept between holds (no partial-cut art; a timer
restarting is honest); the button shown to everyone (a Saw button in every unit's walls, for a
tool most players don't carry); a hold under 3 s (the floor barely hears it) or over 5 s (too
slow to cut one mid-chase for the hole trap).

## D-054 Crawling through: a pressed button, a short move the game makes, your screen moving you (L-12b3, Nov 9)
Every holed wall gets a Crawl button each side at the hole (`Crawls`), E (X on a pad), the door's
key: a verb you press, not hold, because it's the escape with a keeper on your heels. The game
then takes you through in about 1.4 s, as DOORS' and Pressure's vents take you low through a gap:
0.3 s down onto your belly at the hole's mouth (from wherever you pressed), 0.75 s in two pulls
that surge in their middle, 0.35 s up on your feet a step past the hole (`Crawling.pose`, pure,
Lune-checked: always forward, flat at the hole's height wherever any of you is in the wall's
plane, both ends fitting a small unit). Your own screen moves your body (Roblox gives each screen
its own player's body, so friends see it move smoothly; a server-moved body steps at the network's
rate), with PlatformStand on and your parts in a collision group that touches nothing, so the
hole's edges and the floor can't snag it; the server checks the press (inside the unit you crawl
from, within reach, rate, not crawling already, the hole free) and, if you're still in that unit
once the move is over, puts you through itself. Your view rides with your head: low, looking at
the hole, rocking toward each hauling arm, then rising, handed back exactly where Roblox's
first-person camera sits (1.5 up, 0.5 back) so nothing jumps. Every screen poses a crawler's arms
up past the head, tucked in so they fit the hole, the hauling hand planting on the floor; plays a
body's thud as you land, a drag on each pull and a steel scrape as your shoulders reach the cut,
heard 35 studs (`Crawls.crawled` tells keepers the same). One body in a hole at a time: a second
press gets "Wait for them". A Crawl button shows only on your own side of its wall (through the
hole you'd see the far one) and none while you crawl. A keeper (6.3 tall) never gets the button
and can't fit the 2.6 hole. Not chosen: a crawl you steer yourself (a crouch mode and its camera
for one gap; the ticket's moment is the escape, not the steering); holding the button (slow when
it's the escape); a longer move (reads as a cutscene) or under a second (reads as a teleport); a
wider hole (the default avatar fits with its arms tucked; OWNER.md asks).

## D-055 The tops closed: lids round the junctions, a panel at every drop (L-13a, Nov 9)
Before the ladder, the tops had to be a place you can't fall off the world from. A floor's pure
`Floor` now says where everything goes, so Lune checks it over 400 floors on a 2-stud raster: no
edge of the tops is open except a unit's front onto its hall (the way down), a wall a junction or
the lobby already stands to the deck, or a dead end; no panel stands across the tops' way, hangs
in a hall or turns its bare sheet into a unit. **Lids:** of a junction's four corner squares,
those no slot stands in (its blocks of wall, and a corner's outside square behind both its rows)
get an S unit's wire top (its floor is the junction's) wherever a run reaches them, so a run goes
on round the corner instead of dropping into a floored pit with no way out; each run lists the
lids it reaches (`Run.lids`) for L-13b's ladder and for keepers to know where the tops lead.
**Panels:** every other open edge, found as 4-stud stretches and closed line by line, is the plain
wall's panel above its cap (an M's 12 or an S's 8, the kit's own `Panel` mesh, `CorridorKit.panel`)
with a collider from the cap to the deck: the rows' backs over the 16-stud gap, the 4-stud step
where a 12-deep unit stands beside an 8-deep one (about ten a floor), a run's end beside the
lobby, a lid's side over an empty slot. A lone 4 studs takes an 8 that reaches on into the dark
behind the tops, which nobody can see once the backs are closed. Every panel's sheet stands on its
line, so panels meet flush along a line and at corners, and over a unit it goes on up from the
unit's own wall (whose sheet is on that line too). Where the tops have no wall of their own below
(a plain wall's lid, a junction's square), the panel turns its bare sheet to them down to the floor
and brings the wall's trim, whose cap closes the seam: looking down through the wires shows a wall,
not the night sky under the building (Studio showed the sky there before). Up to 120 panels and 22
lids a floor. Not chosen: a new 4-stud panel built in Blender (the 8 hides its spare 4 in the dark);
a panel per slot side (back corners and two extensions meeting left gaps or overlaps on 9 floors
in 400); the deck's edge for the backs of 8-deep units (leaves a 4-stud slot behind them to fall
into); the whole plain wall for the pits (its painted face and kick plate inside an empty unit).

## D-056 The ladder: a two-part aluminium extension ladder, on your shoulder, both hands (L-13b1, Nov 9)
The GDD's ladder ("gets you onto open unit tops") is an aluminium extension ladder built from code
the saw's way (`art/ladder/`), at the building's scale, not enlarged to a hand: 6.8 studs
collapsed, so it lies across a small unit (7.2 inside) and turns a hall's corner, and two parts,
the base (the tool's body) and the fly welded on it, so L-13b2 can run the fly out 5 studs when
it's leaned (11.8 long, reaching 11.4 up at the 4-to-1 rule, past the 10-stud wire top), as
Lethal Company's extension ladder shoots up when placed. Pale, mostly diffuse aluminium (shiny, it
lay on a unit's floor as a black shape); a yellow rope and orange and yellow labels for detail,
no colour of its own: its shape is the read. **Carrying:** friends see it on your left shoulder on
its edge, top leading, welded to your upper torso (`Catalog` row `shoulder`): from the hand it
would see-saw with the walk's arm swing and drag the floor. It takes both hands, as Lethal
Company's two-handed items: while it's in your hand you can't switch slots or pick anything up
("Drop the ladder first", said on your screen and refused by the server), and nobody can hand you
a tool ("Their hands are full"); your torch stays in your other hand. It slows your walk to 12
(Roblox's is 16), as Lethal Company's weight slows a carrier: the one with the ladder is the one
the team waits for. In your view it sits low on the left on its edge, rolled to show its rungs,
its top end reaching across the bottom of the view. Picking it up plays Pro Sound Effects' "Metal
Ladder Bang Slams Against Body 1" (a bang and its rattle, 0.85 s); dropping it, "Metal Ladder
Impact 1" from 0.62 s (a creak, the hard hit on concrete at 0.70 s, rattling bounces), both picked
by loudness. **Where it lies:** by its whole collapsed box (`Tools.bounds`, both parts), at
DealSpot's dropped turns; it can't keep off the crawl-hole strips in a small unit (wall to wall
there, one place) or fit the bulb's pool beside them in a big one (it lies deeper), DealSpot's own
fallbacks, and big enough to read anywhere.
Not chosen: a one-piece ladder (L-13b2 couldn't extend it); a fixed 11-stud ladder (through every
wall as you carry it, and no small unit holds it); carried hanging from the hand (swings, drags);
posing both arms on it (the torch has the right hand; a friend's raised arm is in the polish list);
leaning the dealt ladder on a unit's wall (a new resting pose; listed as polish for after L-13b2's
lean).

## D-057 The ladder leaned and climbed: a pressed Lean, a pressed Climb the game makes, a spot each on the top (L-13b2a, Nov 9)
**Leaning:** a Lean button (R, R2 on a pad: the hold verbs' key, a tap here, so it never fights a
door's E) sits up by each unit's top edge on the left of the door as you face the unit, shown
only to whoever has the ladder in hand (ToolView, as the saw's button). Pressed, the ladder leaves
your hand (`Slots:place`; Slots still owns it) and stands at the 4-to-1 rule (feet a quarter of
the height out, about 2.7 studs into the 8-stud hall), its back resting on the front's top edge
beside the door, so most of the doorway stays open; one ladder per front. Every screen plays it
going up from the server's start time (`Leaning.raise`): a 0.4 s swing off the shoulder that
settles, a bang as its top lands, then the fly runs out its 5 studs accelerating, rattling, and
stops dead with its locks' clack at 0.85 s, as Lethal Company's extension ladder shoots up when
placed. Collapsed it doesn't reach the edge; run out, its caps are 1.4 studs past it, under the
deck. Its parts stay inert: nothing collides with it. **Climbing:** a pressed Climb (E) at its
foot, and the game moves you, as the crawl does (D-054; DOORS' and Pressure's vents): onto it,
up it at 7 studs a second in surges a step every two rungs, then over the edge in an arc onto
your belly on the wire top, about 2 s in all, your screen moving your body (PlatformStand, the
crawl's collision group) and playing Roblox's own climb animation from your character's Animate
while you're on the rungs, so friends see a climber, not a sliding body. Your view stays yours to
turn and rides with your head (Roblox's camera follows the root turned with it, so lying flat it
sits at your head, 0.85 above the wire). Each climber lies in a spot of their own along the
front, 2.2 apart (three on a small unit, four on a big one: "No room up there" after); one on
the rungs at a time ("Wait for them"), the next free once the one before starts rolling over.
**Down:** a Climb down button (E) just ahead of each spot, out of reach from the hall; the game
slides you back onto the ladder, down it and a step back into the hall. **Take** (F, beside
Climb) puts it back on your shoulder (`Slots:handBack`), refused while anyone's on it ("Someone's
on it") or up there ("Someone's up there"): until L-13b2b's drop off a front exists, taking the
ladder would strand them. Every press is checked on the server (reach plus lag, rate, the ladder
in hand to lean it and not to climb, your spot to come down) and if your screen never moved you
the server puts you at the move's end. Keepers never get these buttons; `Ladders.climbed` tells
L-06b's keepers about the bang going up (60 studs) and each climb (30). Not chosen: Roblox's own
truss climbing on an invisible TrussPart along the ladder (tried in Studio: a truss leaned 14
degrees off vertical flicked the climber between Climbing, Running and Freefall, and a vertical
one leaves a friend climbing a stud off the ladder); a climb you steer (stopping halfway is no use
on an escape, and the crawl already set the pressed move); Climb down as a screen button (the
prompt keeps every verb the same on phone, pad and keyboard); leaning in front of the door's
middle (it would block the doorway).

## D-058 The tops closed in steel: nobody sees into a unit from above (L-13b2b, Nov 9)
Owner, Nov 9: with open wire tops, a player up there could shine a torch down into every unit,
find the floor's code and see which units to avoid without opening one. That kills the slow, loud
open the game is built on. So every unit's top, and every lid round a junction, is now the walls'
ribbed R-panel steel laid flat: two sheets running front to back, the back one lapped over the
front one on the middle of the three channels (the unit's bulb still hangs from that one), the
rib ends closed at the front edge and at the lap as a roof's closure strips close them, so
nobody looks down a rib into a unit. One part, `Top` (was `WireTop`), in the walls' Partition
set, wearing its clean upper band (no new texture set); 860 triangles on an M (the wire was 696);
the same collider, so the ladder's spots didn't move. From the tops you now see only into the
halls, over a unit's front edge: you scout where the keepers walk, not what the units hold.
Landing on it is Pro Sound Effects' "Metal File Cabinet Body Impact Ringy Resonance 11", a body
against thin steel that rings (measured in Studio: hit at 0.15 s, settles at 0.65 s, gone by
1.6 s; unheard), and its tail as you slide off; the fence rattle went with the wire. Also decided
(owner, Nov 9), for the tickets after: the crawl along the tops is steered, as Outlast's crawl
spaces are, kept on the run so nobody slides off or clips (L-13b2c), and steel is loud under you,
heard below as Alien: Isolation's vents are; and the saw can cut down through a top so you drop
into a unit blind, as Rainbow Six Siege's floor hatches, one-way with no ladder inside (L-13b2d).
Not chosen: leaving some tops as mesh (those units are scoutable again), a mesh kept dark (a
torch defeats it), a texture set of the top's own (the walls' steel already is one).

## D-059 Along the tops: a steered crawl held on the map, a drop off any front (L-13b2c, Nov 9)
Once you're up a ladder, the stick steers your lying body over the steel, as Outlast's crawl
spaces: slow (4.5 studs a second, about a quarter of a walk, so being up there is a commitment and
a unit's width takes a few seconds), each 2.2-stud pull surging as an arm hauls, backward at half
speed with your head still the way you look, and your body turning toward where you crawl at 200
degrees a second (it barely moves until it faces about the way, so it turns before it slides).
Your screen moves your body (PlatformStand, the crawl's collision group, D-054) and nothing
physical holds you: the pure `Tops` map does. Each floor publishes its tops as rectangles on its
model (`Floor`'s run slots and lids, D-055, plus a 1.4-stud lip over each unit's hall), the test
hall from its units; a lying body is three squares along it (head, middle, feet) that must lie on
the steel, only the head may go out over a front's lip, so you can push your view about half a
stud past the edge and look straight down into the hall, and never through a panel, a junction's
wall or a dead end. Wedged by an edge while turning round, the body turns the long way or squirms
off the edge (the first lying spot by a run's end is too near it to swing a 5-stud body round).
The server checks your claimed place five times a second (on the map within 1.5 studs, at lying
height, no faster than the crawl's surge allows plus lag) and puts you back where you last were,
telling your screen. Push comes from `Humanoid.MoveDirection` (Roblox keeps it current while you
lie PlatformStand; the PlayerModule no longer hands out its move vector, docs/STUDIO.md). Your view sways and dips a few
hundredths of a stud with each pull (`CameraOffset`). Every screen hears each crawler's pulls from
how far their body moves: a soft low boom of the steel (the landing's recording, pitched down and
quiet), every other one higher, with a quiet drag; every other pull is a `Ladders.climbed` "Crawl"
heard 30 studs, for keepers. **Off the tops:** once up you're off the ladder (your spot free once
you crawl from it), so Take is refused only while someone's on the rungs. Climb down sits over the
ladder's top just past the edge, from wherever you crawled to (you slide over onto it). Drop down
(F, pad B; G is already Slam and Drop) sits over the middle of every unit's front, just past the
edge and a little above the steel, so it's on screen whether you look along the top or down over
the edge (back on the steel it was behind your view as you looked down; Studio). Pressed lying by
the front, the game takes you over the edge (0.3 s), down feet first (0.3 s, about Roblox's
gravity over 8 studs) and into a crouch as you land (0.3 s), standing 1.8 studs out facing the
hall, with the steel's tail as you slide off and a body's thud and a jolt as you land, heard 45
studs (`climbed` "Drop"). Up there only you see these two buttons. Not chosen: real physics on the
steel (a body slides and clips at the panels' seams, and the server couldn't hold anyone to the
tops); a disc for the body (the head would poke through panels); the body turning with your view
(the view, at your head, would swing round your hips whenever you looked about); a drop without a
button (G clashes, and walking off an edge by accident on a phone is an instant, unwanted escape).

## D-060 What you hold is drawn small and near your eye (L-13b2c2, Nov 9)
The owner saw the torch and tools go through the roof and doors. Roblox draws held things in the
world with everything else (no layer on top, as shooters draw your gun), and the full-size torch
reached 2 studs from your eye. Each is now drawn at a third of its size a third as far away
(`Hands.Scale`, scaled once with `Model:ScaleTo`): every point lies on the same line from your eye,
so the screen shows exactly the same thing, but the torch reaches 0.61 from your eye, and standing
flush to a wall your eye is 1.45 from it. Where even that touches (lying on a top looking down),
a spherecast from behind your eye along your view finds the nearest solid surface and the thing
pulls back at once and ducks under your view, easing back out (Ready or Not, Escape from Tarkov).
The beam keeps its full-size spot so the light and its shadows fall as the owner approved, but
reaches there from the drawn lens only as far as it's clear: never past a lid or a door (looking
down over a front it still lights the hall; a lens spot behind your eye would have lit the steel).
A friend's beam is checked from their head. Not chosen: a ViewportFrame overlay (its own lighting,
so the torch wouldn't sit in the dark hall); pull-back alone at full size (the torch would duck
whenever you came within 2 studs of a wall: in every tight spot); the third of size smaller (the
torch's tail would cross the camera's 0.1-stud near plane). Friends' tools and the ladder on a
friend's shoulder still pass through doors in third person, as nearly every Roblox game allows.

## D-061 The sawn top: one spot per unit, behind the drum across the first channel (L-13b2d1, Nov 9)
A saw's way down into a unit from the tops (Rainbow Six Siege's floor hatches) opens at one spot
in every unit, as the wall hole does (D-052): in the middle of its width, from half a stud in front
of the first of the three channels the steel rests on to 1.55 behind it, 2.8 across and 2.05 front
to back. A body drops through that feet first, shoulders across and arms up; the drop is a move the
game makes (as `Tops.drop`), so its size is for the eye, not for collision. The spot lands you in
the clear part of a unit, between the door and the bulb (finds stand behind the bulb, D-036),
facing the room with the door at your back, the way out if it's unlocked. It clears the door's drum
(open, its coil reaches about 1.65 back on every size) and, on a small unit, the two sheets' lap
(3.975), with the bulb hanging just behind it. No hole that size fits between two channels on a
small unit (1.8 apart), so the saw cuts the first channel too: the hole is measured from that
channel, the same in every size, so one cut edge and one panel serve both (an M's is a stud further
back, as its channel is). The cut-out panel falls with the channel's stub still screwed under it and
lies tilted on it, slid 1.7 aside and turned, so whoever drops after it lands mostly beside it, not
on a slope. The kit is its own (`art/tophole/`, asset `Props.TopHole`), the wall hole's build loaded
as a library with the top's spec, so the drawing, strips, cut faces, packing and recipe are one
code; its pieces are the holed tops in their units' frames and the edge, the panel's edge and the
panel in the hole's (`Specs.Channel[size]` along the unit). From along the tops the cut is only a
glint (the tongues bend down); a lit unit's bulb shining up through it is what gives a sawn top
away. Not chosen: the back half (you'd land among the boxes, behind the finds' unlit sides); a hole
between channels on an M only (two hole sizes, and a small unit could never be sawn); cutting
anywhere you lie (runtime geometry for no gain, as D-052); the channel left across the hole (it
would bar the drop); the panel landing flat on its face (the stub under it makes that impossible).

## D-062 The sawn top in the place: swapped at the top's own CFrame, the panel one model (L-13b2d2a, Nov 9)
`TopHole.saw(unit, at?)` cuts a unit's top as `CrawlHole.saw` cuts a wall: the unit's `Top` is
swapped for the kit's `Top_<size>` at the same CFrame (the two meshes share their box and axes),
keeping the old top's shadow, collision, query, touch and collision group, so the bulb, the
torch's room and anything reading the top see the same part. The hole's frame is read from the
unit's own top and the generated Specs alone (`TopHole.frame`), so the server can place the Saw
button and the map can cut the hole out of the tops before or after a cut, with or without the
kit in the place. The top's collision box is split round the hole by `Boxes.around` (the wall
hole's), measured in the box's own frame from the hole's corners, so it holds whichever way the
box's axes run. The fallen panel and its bright rim are two parts in two texture sets, so they
are one Model (`TopPanel`, primary part the panel) that a screen moves as one when it falls. The
tops and panel take their look from `Units.M.Top` (the top they replace), not the wall. Not
chosen: one part for the panel (two texture sets can't share a MeshPart); placing the holed top
from the unit's pivot (the pivot's axes are Blender's, the top's are the game's).

## D-063 Sawing a top: the wall's saw on the tops, a thin line on the steel, the panel dropped (L-13b2d2b, Nov 9)
A top is sawn by the same `Saws` system and rules as a wall (D-053): a held Saw button (R, R2 on a
pad, 4 s), loud the whole time (the motor heard 200 studs off), lost if you let go, checked as you
press and again before it goes through. A wall and a top differ only in where the button is, the
frame the line is drawn in and what happens at the end, so each place a saw can cut is a job of
one of two kinds in that system. The top's button sits over the middle of its hole's spot, a
little above the steel, and only someone lying up on the tops with a saw sees it (the tops'
buttons tag and the saw's). The server also checks you're crawling (`Ladders:crawling`), over this
unit's top and above its steel, and not lying on the hole: your middle within 0.6 studs of it gets
"Move off it" (you can't saw the steel you lie on). The line runs round from the front edge's end,
the edge nearest the hall, through `Sawing.line` on the hole laid flat (`Sawing.flat`, a frame
turned so the wall's maths holds). It's a thin bar on the ribs' face, not through the steel as a
wall's is: lying beside it you look almost along the top, and a line through the steel showed its
depth as a thick yellow band (Studio). Through, the panel hangs 0.1 s in the hole, drops at the
game's gravity (about a third of a second for its ten studs), hops a tenth of a stud and settles,
with the wall's clang pitched lower and heard floor-wide (a sheet with its channel's stub, falling
ten studs, as loud as the saw) and the same jolt nearby. Where it was in the hole comes from the
art's own fall exported as `TopHole/Specs.Fall` (`TopHole.unfallen`), so it leaves the hole exactly
where it was cut and turns into its tilted rest as it nears the floor. `sawing` fires for keepers
with the kind. Not chosen: a second system for tops (the hold, checks, rate and sounds would be
copies); starting the drop flat and guessing the turn (the exported fall is exact); the line
through the steel (the band); the clang at the wall's 110 studs; refusing a cut while a friend
lies across the hole (L-13b2d2c slides them off instead).

## D-064 The keepers' brain lives in this game; Brix keeps the core and the shared spine (owner, Nov 9)
The keepers' brain is built in this game, not on Brix's Pursuit system. The brain is everything
that decides what a keeper does: the halls as a map it walks (shortest trips over the floor's
graph, the GDD's tech plan, with a doorway shut while its door is down), going to a place (a lit
fixture, a door's noise, the air horn, the lobby on a wrong code), what it hears and sees, its
states (asleep, roaming, going to look, hunting, frozen, blinded, trapped), the catch, and the
director's orders to it. It is one system on the Host's clock with each keeper a data row (the
GDD's "one chase engine, keepers as data"), so a new keeper is still a model, animations and a row.

It is written against Brix's contracts and parts wherever they fit, so it can move later: the hall
map keeps Brix's Pathing contract (`length`, `advance`, `route`), the catch is a Brix Reach (the
cone), areas are Brix Zones, its events Brix Signals, its dice Brix's seeded Random. It does not
run on `Brix.Pursuit` unless the session that builds the hunt (L-06b3) finds that the chase and
the catch fit it with no new Brix work. Once the brain has shipped and been tuned with players,
and if it still makes sense for another game, a Brix session lifts it into Brix in neutral terms
and this game swaps to it. Until then it is the one named exception to D-008 and to FRAMEWORK's
"never a parallel system that lives on".

Everything else stays Brix first (D-008): the lifecycle, signals, zones and seeded random the game
uses now, and remotes, save data, live config, telemetry, the round loop, the presentation kit, UI
and developer tooling as Brix builds them. `docs/FRAMEWORK.md` lists each with its Brix ticket and
what stands in until then.

Why: Brix's Pursuit was shaped by another game's chase, a runner heading for a safe zone and a
catch on a schedule. A keeper here spends most of its time not chasing, and that is what Pursuit
lacks. As of Brix `3aee79e` its hunters travel in straight lines with no way round a wall, stand
still unless they are chasing a player, and are taken once as the frame driver starts, and a caught
player only comes back as a runner by respawning. Brix's roadmap after ENG-07b goes to that other
game's swap (ENG-08), then remotes and saves. So every keeper need would be a ticket in neutral
terms, a Brix session, an owner's Studio run, a new pin and then a session here: about double the
sessions and the owner's testing, for a design only one game has shaped. This game has to earn and
the keeper is its core, so the game shapes the brain first and Brix takes it once it's proven.

Not chosen: waiting on Brix (about five Brix sessions before the first keeper walks); building on
Pursuit and filing each gap as it's met; a brain with shapes of its own (it couldn't move later).

## D-065 A sawn top on the map: its hole air the head may go over, a body on it slid off (L-13b2d2c, Nov 9)
A sawn top's hole joins the tops' map as a third list (`Tops.Map.holes`, the attribute's text
`tops|lips|holes`): a point strictly inside a hole is off the steel, but, as a front's lip
(D-059), your head may go out over it. So crawling at a hole you stop at its edge with your view
about half a stud past it, looking straight down into the unit, and you can't cross it: your
middle and feet never go over (Outlast's crawl spaces' ledges). The whole hole is the head's: the
body itself keeps the head within about 1.3 studs of the edge, short of the far side (the hole is
2.05 by 2.8). Every hole is bigger than any of the body's squares (1.8 at most), so the map's
corner checks can't miss one a square straddles. The server cuts the hole in the moment a top goes
through (`Ladders:holed`, called by Saws): it decodes the floor's (or test hall's) map, adds the
hole's rectangle read off `TopHole.frame` (the same numbers as the art's hole; Studio matched it to
the thousandth), publishes it, and hands every crawler the new map; each screen looks for a newer
map every 0.4 s while crawling.

Anyone lying across it then, the sawer too if their feet or side were over its spot (the saw only
refuses your middle within 0.6 of it), slides off its edge to the nearest place the whole body lies
on the steel (`Tops.settle`: rings a quarter stud apart, 32 ways round, at most 5 studs, the same
heading). The server moves you and tells your screen through `FixAttribute` as any put-back; your
screen glides you there in a quarter second (any put-back within 6 studs now glides, not jumps),
and when the place you were in doesn't fit the new map it's the steel giving: its ring as you slide
off a front (`Tops.Sounds.Shift`) and a small jolt. A climber still on the rungs as it goes through
is slid off it the moment they're up.

The ladder offers only the lying spots whose body clears every hole and whose roll from the ladder
onto them never passes over one, brushing its edge by 0.3 at most (the roll is 0.6 s, a brush is
never seen). The first spot, by the ladder, always clears it: it lies at least the hole's half
width, the body's widest half and a hair (2.35) out from the unit's middle, which moves a small
unit's first spot a quarter stud out from the ladder's middle (2.1) on every small unit, sawn or
not. So a sawn top of either size has one spot, the ladder's own: a team climbs one at a time,
each crawling off before the next ("No room up there" until they do). Not chosen: moving the spots
behind the hole (a small unit has no room behind it for a five-stud body); refusing the ladder on a
sawn small unit (the unit you just sawed is the one you most want to climb back onto); punching the
hole out of the top rectangles (more rectangles, and "over a hole" has to be asked anyway for the
slide and the spots); refusing the cut while a friend lies across it (the slide is the answer the
GDD's co-op wants: no one is kept off a hole by a friend lying there).

## D-066 Dropping in through a sawn top: tipped in under the ceiling, landed facing the door (L-13b2d3a, Nov 9)
Drop in is Rainbow Six Siege's drop through a hatch, played by the game as the drop off a front is
(D-059), in the hole's own frame (`TopHole.frame`, which the server puts in the climber's front
attribute for this move, "In"). **Offered** only lying at the hole's edge with your head out over
it (`Tops.atHole`: your head's point within 0.3 of the hole, the server allowing 1.5 more for lag),
and while it's offered that unit's Drop down is hidden on your screen: both are F, Roblox shows one
button per key, and at a hole's edge looking down it you mean the hole. The button sits three studs
down the hole's middle: at the steel's face, or a stud under it, it was off the top of the screen
as you looked at the floor below (Studio).

**The move.** The halls' ceiling is 3.86 studs over a unit's top, so nobody can stand up there:
the first build, springing upright over the hole and dropping straight, put the view 1.07 studs
through the ceiling (Studio). And a stiff 5-stud body can't go through a 2.05-stud hole until it's
steep. So you tip up about a point over the hole's middle, head toward the door, your body's line
always meeting the steel's face mid-hole: your feet stay over the steel to about 33 degrees, then
your legs slide down the hole as your head comes up to 3.6 over the steel, you hang upright in it a
beat, and fall the last 8.5 studs at Roblox's gravity (0.36 s in, 0.3 falling, 0.3 landing crouch).
Your arms keep the crawl's reach until you fall, then go up over your head. Lune holds it to: head
under the ceiling, your body's middle line 0.3 inside the hole front and back through the steel's
0.4 thickness, its belly and heels clear of the cut edge, shoulders 0.4 clear each side. You land
under the hole's middle **facing the door**: the body has to face along the hole's short way to
fit its 2.8 width, the door is your way out, and in first person your view stays your own.

Not chosen: landing facing the back of the unit (the handoff's sketch said both; the owner can
swap it); a rise to standing over the hole (the ceiling); offering Drop in from anywhere near the
hole (it would take F from Drop down along the whole front of a sawn unit); its own key (one verb,
one key for leaving the tops by dropping). Left for L-13b2d3b: the floor under the hole kept clear
by the deal, and every way out.

## D-067 The floor under a top's hole kept clear, and a saw's hole deals the unit (L-13b2d3b, Nov 9)
**A unit is dealt the first time anyone can see into it**, which is now also a saw's hole going
through: the unit a wall's hole leads into, or the unit whose top was cut (`Deals` listens to
`Saws.sawing`, the event that says the panel fell). Before this only a lifting door dealt, so you
looked down a sawn top into an empty unit, dropped in, and what it held appeared round you when you
lifted the door. It is D-050's rule (Left 4 Dead's director dealing as the team moves) with one
more way to see in. Not at the saw's start: a short hold would deal units nobody opened.

**Kept clear by the deal** (`DealSpot`, in the door's frame): the landing, 1.5 studs either side of
the point under the hole's middle and 0.9 behind it, and on to the doorway's face, so a body 2
across lands on concrete with its step to the door free; and the box the top's cut-out panel falls
in, 0.2 bigger all round (`TopHole`'s Specs, read by `Deals`). A thing that fits nowhere gives up
the crawl hole spots first, then the top's panel, then being behind the bulb, and the landing
last. A tool's search now tries every dropped turn anywhere past the door before giving a zone up
(it tried only its unit's own turn, so a ladder in a small unit lay on the landing in 200 units of
300). **A small unit is tight**: its pool is mostly landing, panel and crawl spots, so the bolt
cutters lie in a strip up its middle, deeper than the pool (6 studs in, nearer than a medium
unit's pool reaches) and in one of four places, where they had eight or more.

**Out again.** Lift from inside was already there and reaches from where you land (2.7 studs). A
padlocked door's Lift now says "Saw a wall" as it rattles: the button already reads "Padlocked",
the padlock is on the hall side, and the way out that is yours is a side wall (three words, as
the door's test holds refusals to). Not chosen: "Padlocked" again (nothing on screen changed).

## D-068 The keepers' map: places and passages, each keeper walking it with its own abilities (L-06b1, owner, Nov 9)
The floor is a map of places and passages (`src/shared/KeeperMap.luau`). A place is floor a keeper
crosses in a straight line, a plain rectangle: each straight hall piece, a junction's middle and
each of its arms, the lobby, each unit. A passage joins two places: the joint between two hall
pieces, and each unit's doorway. A keeper's shortest trip is A* over the passages (the GDD's tech
plan), so it walks down the middle of the halls and turns at the middle of each joint: deliberate
and stiff, as a mannequin should move. If that reads as robotic on screen, L-06b4 can cut corners
tighter without touching the map.

Keepers differ in what they can do (the GDD's row: "turning, climbing, senses"; owner, Nov 9: a
later keeper may climb ladders, another crawl through cut-outs, each with different abilities). So
a passage may need an ability (`"Climb"`, `"Crawl"`), each keeper's row lists its abilities, and
the brain walks each keeper through `KeeperMap.pathing(map, row.abilities)`, a pathing that uses
only the passages those abilities open (keepers with the same abilities share one). The floor's
own passages need nothing. Raised places (the tops) and new passages (a leaned ladder, a sawn
hole) can be added while a floor runs (`addPlace`, `connect`, `setOpen`); a point belongs to the
highest place whose floor is at or under it, so someone up on the tops is on the tops, not in the
unit below. A keeper that climbs or crawls is then its row plus the calls that add those, never a
new map or a new brain. A new ability is a name in `KeeperMap.Ability` and the passages that need
it. The Mannequin has none.

Defaults the owner accepted (Nov 9): a keeper goes through a doorway only while its door is all the
way up (`KeeperMap.letsThrough`: peeking, rising, coming down and locked are all shut, so pulling a
door down is always safety); the lobby is on the map and the elevator car isn't (the GDD: keepers
can't ride it), so a keeper hunting someone in the car stops at the lobby's edge nearest them.

Each pathing keeps Brix's Pathing contract, checked by Lune over 60 seeded floors. Two things follow
from it. A passage goes both ways at the same cost, because the contract measures every trip the
same both ways: a one-way drop (down a top's hole) can't be a passage, and a keeper that drops in
would need a contract question taken to Brix first. And a point off every place (inside the
elevator, inside a wall) is measured from the nearest place's edge, the way out to it counted in;
two such points that meet the map at the same spot measure straight between them. A trip with no
way through is `math.huge` long and nothing moves along it. Heights: within a place height counts
for nothing (as Brix's floor pathing), and a traveller keeps its height over its place's floor.

Not chosen: a grid of nodes (thousands of points where a few hundred passages say the same);
Roblox's PathfindingService (the GDD: per-keeper calls cost more, are less predictable, and the
director can't read dead ends from them); abilities as separate maps per keeper (one map, one set
of doors to keep in step, filtered per keeper instead).

## D-069 A keeper goes to look: Granny's walk to a noise, heard along the halls (L-06b2a, Nov 9)
The first thing a keeper does is go and look at a noise, the way Granny walks to any sound you
make, stands there looking, then wanders off. You open or slam a door and, two halls off, the
Mannequin walks the halls to stand square in front of that door, three studs out, facing it, for
its row's `linger` (5 s); then it walks back to where it woke and goes still, facing as it was. A
newer sound it hears takes it there instead, as Granny turns to the latest noise, and where it goes
back to stays where it first woke. A door coming down across its way stops it where it is (it
waits there, or, with no way home, sleeps where it stands), so no keeper is ever stuck walking.

What it hears: a door's open, slam and lift from inside (`Keeper.Hears`, the GDD's door table's
loud rows), each as far as DoorSound's reach for that action, the one players hear by, times the
row's `hearing` (1 for the Mannequin). The distance is the trip along the halls (`length` on the
keeper's own pathing), so a door 86 studs off in a straight line but 116 round the walls is out of
an open's 110-stud reach. A peek is quiet on purpose; a close, a rattle at a padlock, a padlock
going on and the cutters' snap aren't in the GDD's list, so keepers don't hear them for now
(`OWNER.md` asks). Asleep means still and listening. A keeper inside a unit hears nothing while
its door is down, its own door rising included (a doorway counts as shut until its door is all the
way up, D-068), so how a keeper dealt behind a door wakes is L-06b2b's to decide.

How it's built: the brain is the pure `Keeper` (one keeper's states and hearing, Lune-tested) and
its numbers a row in `KeeperRows`, so a new keeper is a model, its animations and a row (the
GDD's "one chase engine, keepers as data"). The server's `Keepers` system runs every keeper on
the Host's clock: a floor joins with `add` as it's laid (its map built once, each door's state
fed in from the new `Doors.changed` signal through `letsThrough`), `stand` puts a keeper on it,
and the brain works in the floor's own coordinates. Speeds are shares of a player's full run,
`StarterPlayer.CharacterWalkSpeed` (there is no sprint): the Mannequin's top speed is 0.9 of it
(its hunt, L-06b3) and it looks at half that, about 7 studs a second, so a slam two halls off
gives you about seven seconds to get behind a door. The body is an anchored `Mannequin.clone`
moved by its root part, streamed whole (Atomic), posed on the server at most 20 times a second
while it walks and holding the key it stopped on (`Pose.freeze`) when it stops, so it stands
mid-stride; L-06b4 moves posing to each screen.

Not chosen: going into the unit whose door it heard (that's the hole trap's job, L-12c, and would
make every open a death; it stands at the door instead); hearing measured in a straight line (it
would hear through walls, and the map exists so it doesn't); a hearing radius per keeper separate
from the sound's reach (players and keepers would hear different worlds); PathfindingService
(D-068).

## D-070 A keeper behind a door: the Witch asleep, the one turning to you awake (L-06b2b, Nov 9)
The deal can put a keeper behind a door asleep or awake (GDD: "a dormant Kept Thing or an awake
one"), and now it stands where the deal laid it as the door first lifts, so even a peek shows its
feet. Asleep, it stands slack in its shop pose, facing as laid, still and listening, the way Left
4 Dead's Witch sits until a noise startles her: the first loud sound that reaches it along the
halls (an open, a slam, a lift from inside; later the air horn, which the GDD says "wakes dormant
things") wakes it, and it goes to look as Granny does (D-069). Woken, it never sleeps again.
Awake, it stands on its walk's first stride, square to the doorway, reaching at whoever lifts the
door; the moment its door is all the way up it walks out to the door's front and stands facing
out into the hall for its linger, then goes back in and stands watching its doorway. Each time its
door gets all the way up again it steps out again. Looking out is its stand-in for sight until
L-06b3 lets it notice the player standing there.

Its own door's open doesn't wake a sleeping one: the open's rattle sounds as the door starts up,
while the doorway still counts as shut (D-069), so only the next loud sound wakes it. That keeps
the peek meaningful (see the feet, close it quietly, padlock it, or open it and keep the noise
down) and keeps the deal's cap honest: past the cap a keeper is dealt asleep so the halls aren't
flooded (D-050), which would mean nothing if every open woke the one inside. A slam on its own
door does wake it, shut in: the bang sounds before the door comes down (`Doors.acted` fires before
`Doors.changed`). The cap now counts the brain's keepers awake on the floor (`Keepers:awakeOn`),
dealt awake or woken, in place of the deal's tally of those dealt awake.

How it's built: the brain gains two states, Asleep (dealt asleep, not yet woken) and Watching
(awake and standing), in place of the old Asleep that meant both; `Keeper.awake` says which, and
`Keeper.lookOut` sends an awake keeper standing in a unit out to look when that unit's door is
up. `Keepers` takes `Deals.dealt` and stands the keeper; `Deals` asks `Keepers` for the count
through the registry, since Keepers already requires Deals. Verified in Studio on seed 7, floor 1.

Not chosen: waking on its own door's open (the cap's point, above); waking on a peek's light (the
Mannequin's own rule is that light stops it, GDD Keepers); an awake one walking out on a peek (the
doorway is shut until the door is all the way up, D-068); a new "awake" pose (its walk's first
stride already reads as caught moving, the Mannequin's language, D-039).

## D-071 A keeper out roams, a trapped one breaks out, and a slam only buys time (owner, Nov 9)
Playing L-06b2b, the owner found the keepers too easy to put away: open a unit, see an awake
Mannequin, slam the door and it was gone for good; or stay quiet while it walked back into its unit
after looking, and shut it in there. The GDD means the slam to be how you trap a keeper, but as a
way to buy time, never to end the threat. Four changes, agreed with the owner:

1. **Once out, never home.** A keeper that has left its unit roams the halls between noises, the
   way Granny walks the house room to room after checking a sound, and never goes back to stand in
   its unit. This replaces D-069's walk back to where it woke, D-070's step back into its unit
   after looking out, and D-069's sleeping where it stands when its way home is shut. Until the
   director steers it (Phase 2, as Alien: Isolation's director keeps the alien near you and pulls
   it back after a close call), it picks hall places some way off that it hasn't visited lately.
   Built in L-06b3a1, before the hunt, so the hunt's give-up is simply "roam again".
2. **The break-out comes forward** from the hole trap (L-12c) to its own ticket after the catch
   (L-06b3d), so every trap is a clock from the start. Trapped means its doorway was open and the
   door came down on it awake inside; a peek lowered over an awake one isn't a trap, since it
   never had a way out. It bangs, dents the door and bursts out at about 90 s going after the last
   thing it heard, as Amnesia's monsters batter down a door you shut. A padlock keeps it in.
3. **A trapped keeper takes no place in the cap.** D-070 counted one shut in toward the floor's
   cap of awake keepers, so on floor 1 (one place) slamming the awake one in made every later deal
   a sleeper: trapping made the floor safe. Now a keeper trapped or padlocked frees its place, so
   the next door can hold a fresh one, and takes it back when it breaks out.
4. **No bonus for trapping.** The GDD's "trapping a keeper pays the team a bonus" was drafted early
   and never decided; the owner dropped it. The trap pays for itself in time. The first trap of
   each keeper type still goes in the Catalog.

The owner also judged the walk jerky, which makes it less scary: the smoothing on every screen
moves up from L-06b4 to its own ticket (L-06b4a) right after the hunt, so the chase and the freeze
are judged on smooth movement.

Not chosen: keepers lifting doors themselves at will (the break-out does that job with a clock
players can read); counting a trapped keeper toward the cap until it breaks out (it rewards the
cheapest play); a bonus kept only for keepers you lured in (no precedent named, and the owner
dropped the bonus outright).

## D-072 The guarded note: every floor has a chase, and the peek finds it (owner, Nov 9)
The owner saw that the peek did nothing as a mechanic: the notes are stuck when the floor is laid
and keepers dealt at random as doors first lift, so on most floors you could peek, skip every unit
with feet in it, and still find the whole code without letting one keeper out. A peek is only worth
something when you might have to go in anyway.

So one note on every floor sits in a guarded unit that always holds an awake keeper, as DOORS puts
the library's code hints in the room Figure walks (the GDD already does it once, with Dale's digit
on floor 5). The floor's build picks the guarded unit from the notes' units, seeded; the deal
always deals it an awake keeper. The guard holds one of the floor's awake places from the start,
so on floors 1 and 2 (one place) every other keeper is dealt asleep until the guard is trapped:
those floors are one keeper that comes for you and sleepers you stay quiet around. A peek can't
show the note (it's high on the back wall), so the team knows which units hold keepers and which
stand awake, not which one has the code.

The peek becomes scouting before you commit: it tells you, without the open's noise, which units
need a plan. Every plan uses pieces built or planned: a friend's torch freezing the Mannequin while
the other takes the note (the Mannequin's GDD rule), a slam elsewhere drawing it out of its doorway
while you slip in behind (Granny going to a thrown vase), a sleeper passed quietly (Left 4 Dead's
Witch), or a hole sawn in from next door. Built in L-06b5, after the break-out, since a guaranteed
chase means nothing until a keeper can catch you.

Left open: units the peek showed safe are still risk-free to open until you take on the guard, so
the floor stays calm until you choose the fight. The planned answer is the Phase 2 director waking
keepers while you search (GDD "Build wakes a keeper"); judged after the owner plays a floor with a
guard and roaming keepers. One guarded note per floor is a default.

Not chosen: the peek showing the note (it would make the peek a free answer key); a tool rather
than a note as the guarded thing (tools are optional until floor 6's padlocked note; the note is
the one thing every floor needs); the guard asleep on some floors (the owner wants a chase on
every floor).

## D-073 How a keeper roams: hall pieces some way off, never its last few (L-06b3a1, Nov 9)
D-071 says a keeper out of its unit roams the halls between noises and never goes home. As built:
after looking at a noise, or out of its own doorway, it picks the middle of a hall piece (a
straight, a junction's middle square or the lobby: one stop per piece, so junctions with four arms
aren't picked four times as often) whose trip along the halls is 40 to 120 studs, that it hasn't
stood in among its last four stops, walks there at its looking pace (about 7 studs a second),
stands 3 s holding the stride it stopped on, and picks again: Granny's walk from room to room.
With nothing in that band it takes any piece it can reach and hasn't stood in lately, then any it
can reach. A newer sound still takes it to look, from a roam as from anything else. Each pick is
one draw from the floor's own seeded Random, a fresh Brix Random from the floor's seed handed to
`Keepers:add` (not the deal's, whose later draws at a door's first lift would shift with every
roam and change what a unit holds), so a seed roams the same way for the same play. Those numbers
are row data (`roamNear`, `roamFar`, `roamLinger`, `roamMemory`); the owner tunes them (OWNER.md).

It never walks into a unit: every goal it ever has is in the halls (a door's front, a hall
piece's middle), and a trip between two hall places never passes a doorway, as each unit has only
the one. So its own door shut behind it changes nothing, and D-069's "no way home, it sleeps where
it stands" is gone with the walk home. A door coming down across its way makes it pick again; one
that came down before it got out of its unit leaves it nowhere to go, so it stands watching there
until its door is all the way up and it steps out again (the break-out, L-06b3d, gives it a clock).
The brain's Returning state is replaced by Roaming, and Waiting now covers both its stops (at a
sound, facing it, for `linger`; on a roam, for `roamLinger`). Verified in Studio on seed 7,
floor 1.

Not chosen: roaming toward players (Phase 2's director steers picks, as Alien: Isolation's keeps
the alien near you; until then it would be a hunt with no sight); picking any map place (a
junction's arms would weigh junctions four times over, and units are never goals); a turn to look
down the hall at each stop (no precedent named and its stopped stride already reads as caught
moving; OWNER.md asks); the deal's Random for picks (above).

## D-074 How a keeper sees and hunts, in its own brain, not on Pursuit (L-06b3a2, Nov 9)
Brix's Pursuit doesn't run the chase. A hunter the game places (`moveHunter`) is never moved by
Pursuit again, so a keeper couldn't hand back from the chase to its own roam and search; its
runners all head for a safe zone this game doesn't have; and its `Reach` and targeting measure
straight lines with no walls or sight. Fitting it would be new Brix work, which D-064 rules out.

As built: a keeper awake in any state (watching, going to look, waiting, roaming, searching) sees
a player within its row's `sight` (48 studs) and `sightAngle` (60 degrees either side of the way
it faces), along a straight line `KeeperMap.clear` passes: on the floor all the way, crossing from
place to place only at a joint between halls or a doorway whose door is all the way up, and there
only within the door's opening (`Floor.Sizes`' `door`), so never through a wall, a shut or
peeking door, or the posts beside a door. Feet more than 8 studs over or under its own are out
of sight: up on the tops (10 up) or another floor; a jump isn't. Off the map (the elevator car)
is out of sight. It hunts the nearest it sees, turning to them at once (Granny's chase on sight),
at its top speed (`speed`, 0.9 of a run) along the halls, stopping 2.5 studs off (`Keeper.Close`,
where L-06b3c's catch will land). Hunting, it keeps them while it sees them any way it faces, and
no sound calls it off, so a slammed door is no free escape mid-chase. Lost, it rushes at its top
speed to where it last saw them (Searching), stands its `linger` facing on, then roams (D-073):
Granny's search. A sound heard while searching takes it to look, so a friend can draw it off.
The server feeds each living player's feet (floor coordinates, reused lists) to a floor's
keepers each step, only while one there is awake. Verified in Studio on seed 7, floor 1.

Not chosen: a noticing build-up before the hunt (Alien: Isolation's; OWNER.md asks); sight that
needs light (the Mannequin's light rule is L-06b3b's, and keepers seeing in the dark is Granny's);
a small all-round sense of someone touching close behind (the catch covers contact); seeing by
sampling points along the line (it can miss a wall's corner; `clear` follows the line place by
place exactly).

## D-075 How keepers move on every screen: motion records, followed per screen (L-06b4a, Nov 9)
The server moved each keeper's root every step and turned its fifteen joints (Motor6D C0) up to
20 times a second, all replicated, and a phone drew the body hopping between updates: Roblox
doesn't smooth an anchored part's moves, and nothing smooths a C0.

As built: the brain stays on the server (`Keeper` is the truth). The server sends each keeper's
motion as one short line of text on its body's `KeeperMotion` attribute: where its feet are (the
world's), the way it faces and walks, its pace, how far it walks before it stops (`Keeper.left`:
its trip along the halls, short of arm's length if it hunts), how far it has walked (its pose),
its state and the server's time. It's dead reckoning, the way shooters move other players: the
server keeps the last record as screens read it (rounding and all), works out each step where
they show it, and sends a new one only when that drifts a quarter stud, or it starts, stops,
turns 4 degrees, changes pace or state, or is about to walk past where the last one stops it;
never more than one each 0.08 s in one state, while a new state goes at once. A straight walk is
its start, its stop and one or two records as it nears the stop; a close chase about 6 a second.
The server leaves the joints at rest and moves the root only with each record, or once it has
walked 8 studs from the last: that's what streams the body (Atomic, as before) to whoever is near.

Each screen's `KeeperView` follows the records (`KeeperMotion.follow`, `receive`, `update`): it
shows the keeper 0.1 s behind the server's time, so a turn or stop that arrives in time is shown
exactly (each record bent onto the next), never walked past (`left`); a late record's difference
eases out over 0.12 s (more than 4 studs snaps); turns ease over 0.06 s; its pose follows how far
it has walked, never backward. It's posed through each joint's `Transform` (C0 at rest) in one of
33 fixed frames of the walk (`Pose.frame`: Still, each key, seven steps of each snap), each
frame's turns worked out once per screen, so a joint is written only when the frame changes. Only
bodies moving on that screen are stepped, in the Host's RenderStepped step (after replication
lands, before the frame draws). Verified in Studio: the chase drew at its pace with no stalls.

Not chosen: unanchored bodies moved by constraints so Roblox interpolates them (a fight with
physics, at rates Roblox picks); replicating the root every step and posing only on screens (half
the cost, still hops); sending every step for screens to buffer (60 records a second each); a
delay fitted to each screen's lag (ROADMAP polish); a client copy of each body (two bodies, and a
torch's ray would hit the wrong one).

## D-076 How light freezes the Mannequin, decided in its brain (L-06b3b, Nov 9)
The GDD's Mannequin moves only while no light is on it and never trips a light; you stop it by
keeping a light on it, moving under the hall's lights or pointing your torch at it. It's
SCP-173's rule in SCP: Containment Breach, and Five Nights at Freddy's animatronics never moving
while the camera is on them.

As built: a row says whether light freezes it (`freezesInLight`) and how tall it is (`height`).
Each step the server tells its brain whether a lit hall light's pool is where it stands
(`MotionLights.lightOn`) and each living player's torch: from their head, along the way their
root faces (the first-person camera's), tipped by their aim, or none while it's off. The brain
(`Keeper.step`) decides: a hall light counts only while it stands in a hall, since a unit's walls
shade its inside from the tube; a torch counts when a point up its middle (seven, feet to head)
is within the beam's 42 studs and 27 degrees of its middle (Torch's numbers, the cone players
see) along a line `KeeperMap.clear` passes from the player's feet, so never through a wall, a
shut door or round a corner. Who lit it is `lit` (Output names them). Lit, it holds where it
stands, as it stands: no step, no turn, its state, trip and clocks kept, so the light gone, it
carries on exactly as if no time had passed. It still sees and hears while frozen, so it can
start hunting you while your light is on it, without turning, and comes the moment the light
leaves. A freeze or a let-go goes to screens at once, not after the records' 0.08 s gap
(D-075), so screens stop it on the stride it was on; in Studio it drew 0.07 studs past and eased
back.

A lit fixture's pool is round, 13 studs across the floor from it: the tube reaches about 12 at a
body's height and fixtures hang 24 apart, so two lit ones leave no gap, junction arms included.
The watch box (40 by 10, what the light sees) was not used: a junction's side arms would have
been lit but not freezing, and players would see it walk in the light.

Not chosen: the light decided on the server outside the brain (Lune couldn't check a whole
freeze); a beat of hold after the light leaves (the GDD says the moment); a frozen keeper that
turns to face you (it reads as moving; OWNER.md asks); its clocks running while frozen (a light
on a waiting one would cut its wait short); the beam's edge measured against its width (a stud
either side, ignored for now).

## D-077 How a keeper catches you: Brix's cone, in its brain, and a stand-in in the black (L-06b3c, Nov 10)
The moment: you stood still too long in the dark, and it's there; its hand closes on you. A
hunting keeper that reaches you catches you, as Granny's grab or Piggy's swing ends the chase the
moment she reaches you. The GDD's "Getting kept" then wraps you and stores you (L-07).

As built: each row has a grasp, `reach` (studs, feet to feet along the halls) and `reachAngle`
(degrees either side of the way it faces); the Mannequin's is 3.5 studs, a stud past arm's length
(`Keeper.Close`, where its hunt stops), and 45 degrees. The brain makes its grasp with Brix's
cone reach (`Reach.cone`) over its own map's pathing, handed in by the server
(`Keeper.new(..., cone)`), since the pure brain requires no Brix. `Keeper.catches` asks: is it
hunting, are the feet of the one it hunts within the cone (measured along the halls, so the way
round a wall is the walk, not the straight line), along a line `KeeperMap.clear` passes (never
through a wall, a shut door or a door's posts, never from up on the tops) and no higher or lower
than its height (a jump at its face is caught; the tops are not). `step` checks it after the
keeper moves, so never while a light holds it (it returns first) and never asleep (it only hunts
awake). Caught, it stands over the spot its linger and roams, the one it hunted let go; `caught`
names whom for that step. A straight-line check comes first, so most steps never ask the map.

The server then: tells the caught player's screen (Remotes.Caught, to them alone; nothing goes
client to server), says it in Output, fires `Keepers.caught` (body, player, floor) for L-07, and
leaves that player out of every keeper's sight for `Caught.Out` (2 s, the GDD's wrap), so the one
that caught you can't catch you again before you're moved; a second hand on the same step is
ignored. The screen (`CaughtView`): the view jerks (CameraShake 0.85), the screen drops to 55%
dark at once and closes to black over 0.4 s, "Caught" in the dark for 0.9 s, then it opens over
0.7 s; you're held still the whole time (walk and jump 0 on your own screen, which owns your
movement). The stand-in until L-07 (DevCorridor, like the stand-in ride): once the screen is
black, the server puts you in the floor's lobby, facing the hall. Verified in Studio on seed 7,
floor 1: it came out of 126 and caught me at arm's length; with my torch on it, it hunted frozen
for 12 s and never came; torch off, it came and caught me.

Not chosen: Pursuit's catch (D-074: Pursuit doesn't run keepers); a wind-up before the grab (the
GDD says it catches you; a speed under your run already gives the chance to flee); the cone alone
without the clear line (measured along the halls it already won't go through a shut door, but a
thin wall between two halls is long to walk round and short to the eye; the line keeps "never
through a wall" plain); the PlayerModule's control switches to hold you (they don't hold
movement any more, see docs/STUDIO.md); turning your view to its face as the dark closes (a
strong grab, but it fights Roblox's camera; ROADMAP's polish list).

## D-078 A trapped keeper bangs on its door, then bursts out; a padlock holds it (L-06b3d1, Nov 10)
The moment: you led it into a unit and slammed the door on it. A breath later it hits the door
from inside; the door jumps on its rail with each blow and the blows come faster; at about 90 s it
throws the door up and comes out (the GDD's hole trap; Amnesia's battered doors). A slam buys
time; it never ends the threat. A padlock does, for the floor.

As built: a door that comes down from all the way up (a close or a slam, the only ways down from
Open) traps an awake keeper standing in its unit (`Keeper.trap`, called by the server when a
doorway that let keepers through stops). A peek lowered over one isn't a trap. The slam is heard
before the door's state changes, so a sleeper woken by the slam it hears is awake inside and is
trapped too: slam a door on a sleeping one and it wakes banging; close it quietly and it sleeps.
Trapped, it walks to stand 1.2 studs inside the door, facing it (a peek shows its feet there),
and bangs: the first blow 1.2 s after the door came down, then gaps from 5 s closing to 2 s as its
time runs out, each a quarter longer or shorter from the floor's Random, none within a second of
its burst (row numbers). Each blow is a door motion, `Bang`, played by `Doors.move`, so the door's
one replicated motion carries it to every screen: the door jumps about 0.2 studs on its rail and
drops back (0.5 s), the slam's boom at 0.55 and pitched down with a thump under it, and a camera
jolt (0.45, about a third of a slam's on screen) for anyone within 6 studs, fading by 30. Keepers
hear a blow to 70 studs (a rattle's reach), so others come to look at the door. At 90 s it bursts
it: a `Burst` motion (a full stroke in 0.6 s, fastest at the start; the door reads Lifting, so
nobody outside can pull it back down), a slam's full boom and jolt as it tears free and a boom at
the stop bolts, heard 130 studs. Once the door is all the way up it goes after the last thing it
heard while trapped, or steps out to look and roams. Lift the door yourself and it's just out.
Trapped, it hears only through its own door: its way to the door plus the trip from the door's
front along the halls (D-069's rule still holds: never through a wall); its own door's sounds it
doesn't count. A padlock: it bangs on until its time, gives one last blow, then stands quiet for
the floor; cut the padlock and it bursts out at once. While shut in it takes no place in the
floor's cap (`Keeper.loose`, which `awakeOn` counts). Someone shut in with it gets hunted; after,
with nowhere to roam, it goes back to its door, trapped, its clock carrying on. Verified in Studio
on seed 7, floor 1: slammed as 126 got up, it was trapped, banged 28 times and burst out 90.25 s
later; padlocked, it gave its last blow at 90 s and was still in at 103 s.

Not chosen: the blows as their own remote (the door's motion attribute already reaches every
screen in step, one path for every door sound); the burst as a lift from inside (6 s of heaving
reads as a struggle, not a burst); banging forever behind a padlock (it would call every keeper on
the floor to that door every few seconds for the rest of the floor, a lure the GDD doesn't give);
its blow clock keyed to the last sound it heard (the GDD gives a fixed "about 90 seconds").

## D-079 The dent: each blow bows the door out, in three baked steps (L-06b3d2, Nov 10)
The moment: the door you slammed on it starts to bow out toward you, worse with each blow, so from
the hall you can see how close it is to coming through (Amnesia's battered doors).

As built: the server keeps one number on the unit, `DoorDent`, the share of the keeper's break-out
time gone at its latest blow that landed (a `Bang` or the `Burst` that `Doors.move` played), and
never lowers it (`Dent.raise`). Every screen turns it into one of three baked steps
(`Dent.step`; `Dent.Lands` 0, 0.4, 0.75): dented from the first blow (a fist-sized pocket at chest
height, 0.34 out), bowed from about 36 s of 90 (the ribs bowed guide to guide with a first fold,
0.66 out, level with the wall's face), buckling from about 68 s (1 stud out, proud of the wall,
the fold sharp, a third blow high). A door keeps its dent for the floor, lifted or burst (a
default, OWNER.md). The rigid hinged ribs can't bend, so each step is bowed copies of the ribs it
reaches, every one read from one displacement field at its place on the shut door, so they meet
each other and the plain ribs exactly (`art/unit/dent.py`). They ship as their own small FBX per
size, `Props.DoorDent_M` and `_S`, not in the unit (dozens of units a floor would each carry 39
parts), dressed in the unit's own slat texture at prepare time and its paint at runtime. A dented
door keeps its slat chain; `RollUpDoor`'s rig swaps a step's bowed ribs in while each hangs below
the doorway's top and drops one flat as it rolls up behind the header, so the coil stays round
and nothing pokes through the header. The collider and what keepers see are unchanged. Roblox's
lighting is flatter than Blender's renders: at first the dent (0.2 to 0.55 out) barely showed in
Studio, so the steps are deep enough that the ribs above the fold tip up into the hall's light
and those below into shadow. Its worst passes the collider by about 0.4, so a player pressed to
the door can clip it.

With it: the trapped keeper stands 3.4 studs inside its doorway, not 1.2 (`Keeper.Against`). The
Mannequin's walk holds an arm out level about 2.7 ahead of its feet, and at 1.2 its hand stood 2
studs out in the hall through the shut door (`docs/art/L-06b3d2-arm-through-door-before.jpg`).

Not chosen: a shape key or bones (Roblox's importer keeps neither for a plain mesh); merged dented
curtains only (a blow's jolt and a peek pose the chain, where the dent would vanish); bowed ribs
riding up onto the coil (lumps through the header and the unit's top); the dent counted per blow
rather than by its time (a jittered clock would show different steps for the same wait).

## D-080 The guard on the deal (L-06b5a, Nov 10)
D-072 built as the deck's rule, pure in `Deal`: `Deal.new` marks one note's unit guarded
(`deck.guarded`) and `Deal.odds` deals it a keeper awake whatever the mood, the padlock or the cap.
- **Which note.** One of the floor's notes, picked from the floor's Random, behind an unlocked door
  wherever a note is: a padlocked door can't be peeked, and the peek is how D-072 has you find
  the guard. With every note locked (17 floors in 4,000 of the spec's) the guard takes a locked
  one. Notes already lie past the lobby's hall, so the guard never stands in the first doors.
- **Drawn last.** The pick is the deck's last draw, so every seed lays and deals all else as
  before: the code, notes, padlocks, each unit's roll and the bag. (Since D-098 it's drawn just
  before the bag instead, so a change to the bag never moves it.)
- **Its place under the cap.** Until the guard's unit is dealt, every other door counts it among
  those awake (`awake + 1` against `Deal.awakeCap`); once dealt it's counted with the rest by
  `Keepers:awakeOn`, and trapped it takes no place (`Keeper.loose`), so the place frees as D-072
  says. On floors 1 and 2 every other keeper is dealt asleep until then. A keeper woken by a
  noise isn't the deal's doing, so the guard can still make two loose on floor 1 after a slam
  has woken a sleeper: the cap governs what the deal deals.
- **Where it stands.** As every dealt keeper: `DealSpot` keeps it out of the note's sight line,
  awake on its walk's first stride, square to the doorway (D-070).
- **Output.** In Studio the dev floor's notes line marks the guarded one, and `Deals` says
  "guarding its note" as it deals it.
- **Found in Studio:** the built peek has no crouch, so a standing eye sees only a stud or two in
  under the foot of gap and no keeper's feet. The GDD's peek crouches; that's L-06b5b.

Not chosen: the guard as a separate kind in `Deal.Kinds` (it's an awake keeper like any other,
only certain); the guard's place kept by `Deals` rather than the deck (it's the deal's rule, so
Lune proves it); a fixed guarded note (the first, say), which a team would learn.

## D-081 The peek's kneel (L-06b5b, Nov 10)
The GDD's peek crouches; as built it only lifted the door, and a standing eye 4.5 up sees a stud
or two in under the foot of gap. Rainbow Six Siege's players drop to look under a door; this drop
is quick and automatic, part of the Peek.
- **Your view, not your body.** Your screen eases `Humanoid.CameraOffset` down over 0.35 s to an
  eye 1.0 off the floor, just under the gap's top (1.15). Tried in Studio: at 1.2 to 1.3 only the
  feet show; at 1.0 the feet and shins, so a guard's stride and a sleeper's square stance read
  from the doorway (`docs/art/L-06b5b-peek-*.jpg`). Your root stays standing: the server's checks
  on reach, the keepers' sight of your feet and the door buttons' reach are unchanged.
- **Your screen first.** The drop starts the moment you tap (`PromptTriggered`), not when the
  server answers; if the door hasn't started lifting within a second (a refused press) you stand.
  Your Open, Close or Slam stands you as you press it; any other move of the door stands you when
  it reaches your screen.
- **Staying down.** While the door holds its peek and you stay within a stud of where you knelt
  (1.5 up or down: a jump). A climb, crawl or catch taking your body (PlatformStand) stands you
  at once. One pure rule (`Kneel.holds`, `doorMoved`) runs on your screen and on the server.
- **The buttons come down with you,** on your screen only: at the door's standing height (4) they
  sit above a low gaze and a prompt shows only while its spot is in view. They sit 16 degrees
  over a level gaze, never lower than 1.8 so they don't hide the gap, and go home as you stand.
  The server's reach check uses its own copy of the spot, a couple of studs higher: well inside
  its slack.
- **A friend sees you kneel.** The server tags your character (`Kneeling`) once it lifts the door
  for you and keeps the same hold; every screen eases that body into the pose by its joints'
  `Transform` before physics, from whatever its animation says (or rest, for a joint none
  drives). Animations would replicate on their own, but need an uploaded asset; this needs none
  and fits any R15 avatar (the drop and shift are shares of the hip height). The pose: both knees
  down, chest to the floor, forearms out to the door, head up, tuned in Studio to within a tenth
  of a stud of the floor. Your own body isn't posed on your screen: you never see it in first
  person, and a torso leant into the door would push your character off its spot.
- **The rustle.** Pro Sound Effects' "Cloth Rub Soft Rustle 3", 0.45 s from 0.55 s, as you drop
  and stand, heard to 24 studs. Keepers don't hear it; the peek's latch is the door's noise.

Not chosen: a prone body flat on the floor (Siege's): the GDD says crouch, and it would lay the
feet five studs back into the hall; taking over the camera (Scriptable), which
would fight Roblox's first-person turn; a new remote for the kneel (the server already knows who
peeked and where they stand).

## D-082 The sting and the chase bed, heard by the hunted player alone (L-06b4b1, Nov 10)
A keeper seeing you had only its turn and its run to say so. Granny's chase music cuts in the
instant she sees you and runs under the chase; that's the precedent.
- **Who hears it.** Only the hunted player: it's your music, not a sound in the hall, so it plays
  from SoundService, the same wherever you stand. Friends hear the keeper itself (its tell is
  L-06b4b2), never your music.
- **How the screen knows.** No screen knew whom a keeper hunts (`KeeperState` says only
  Hunting). The server counts, after any step in which a keeper's quarry changed (it saw, lost or
  caught someone, or was trapped), how many keepers hunt each player, and tells a player's screen
  that number (`Remotes.Hunted`, to them alone) only when it changes: one message per sighting
  or loss, never per step. A count rather than a yes or no, so a second keeper joining a chase
  is a rise the screen can hear.
- **The rule (`Chase`, pure, 46 Lune checks).** A rise is a sighting. It stings only if it's a
  fresh one: not within 4 s of a keeper losing you (`Regain`: ducking out of sight for a moment
  and being seen again is a glance back, and the bed just comes back up) and not within 8 s of the
  last sting (`StingGap`: a second keeper right behind the first only adds to the chase). The bed
  rises over 0.8 s (`BedIn`, under the sting's hit) while any keeper hunts you and fades over 4 s
  (`BedOut`) once none does; the level moves evenly and its square is what's heard, so a fade
  dies away. A catch cuts the sting and the bed at once and holds silence through the blackout
  (`Hush` = `Caught.Out`); the first sighting after it is fresh.
- **The sounds** (APM, Roblox's licensed library, each loaded and measured in Studio, none
  judged by ear yet). The sting is "Rising Fear Hit 1" (1841353894): full by 0.1 s, loud for
  0.8 s, rings down by 7 s, a boom with a bright edge (a third of it 500 Hz to 2 kHz). The bed is
  "Tension Repeat Drones 39" (1843739491), looped over its first 118 s: of eight beds measured it
  alone had most of its sound (82%) between 150 and 500 Hz; the rest sat under 150 Hz, where a
  phone's speaker barely plays, and phone is first. Volumes 0.8 and 0.45 (`Chase.Sting`, `Bed`).
- **Verified in Studio** on seed 7, floor 1: opening 157 in front of the guard, the server's
  word came 2.07 s after the tap and the sting started that frame; the bed rose, and the catch
  0.5 s later cut both. Escaping 0.3 s after the sighting, the loss reached the screen 0.2 s
  later and the bed fell evenly to silence and stopped. A 34-stud sighting in the halls held the
  bed full for 1.3 s until the catch cut it. No sound errors in Output.

Not chosen: the server deciding when to sting (the rule is presentation, the screen's to keep;
the server only says how many hunt you); a sting per keeper's own sighting by its id (more to
send, and the gap would swallow most); music that swells with distance (Alien: Isolation's) or
the bed's own loudness telling you how near it is: the bed only says "hunted"; the keeper's tell
(L-06b4b2) says where.

## D-083 Its tell: the walk each screen shows, heard from the body (L-06b4b2, Nov 10)
The moment: in the dark you hear it before you see it, as Five Nights at Freddy's footsteps say
an animatronic moved. Its walk is stop-motion (D-074's keys: it holds each, then snaps to the
next), so the sound is the snap landing: a stiff clack of its foot as a step key lands and a
hollow knock of its joints as a pass key lands, alternating; a jerk from its slack shop pose
into a stride knocks too.

As built: nothing new crosses the network. Each screen's KeeperView already poses the body from
its records, so it asks `Pose.tell` each time it poses one: the key it shows, counted from its
first and never going back, against the last one heard. Each key is heard once, the moment that
screen shows it landing; a late record jumping several keys makes one sound (the last key's); a
snap a light froze early isn't heard again as it walks on; its first pose on a screen (it
streamed in) is silent. KeeperSounds plays it from the body's root: two takes of each sound, in
turn, at a random pitch in the row's range, cut to one hit with a short fade (one reusable fade
per take), footfalls heard to 70 studs (past the 48 it sees: you hear it coming first), knocks to
40 and 6 dB under (the knocking means it's near), never two from one body within 0.08 s, never
played from past its reach. Every number is on the keeper's row (`tell`).

The reveal: as a lift (Peek, Open, or a Lift from inside) first takes a door's curtain 0.4 up
(its feet), a keeper standing in that unit, asleep or watching, knocks once, deeper and louder
(1.5 times, pitch 0.85); not again within 3 s. It's timed off the door's own motion on the
server's clock (`KeeperTell.reveal`), so it lands as the screen shows the gap open (0.10 s into
a peek). The deal stands a keeper as its door first lifts, so its body reaches a screen just after
that lift began: KeeperSounds checks the lift it arrived in. Everyone near hears it, as a door.

The sounds, by measurement (docs/STUDIO.md): Pro Sound Effects' "Wood Drop Light" 4 and 2 (a
light board dropped flat on concrete, about 860 Hz, where a phone speaker plays) for the foot;
"Knock Slap Plastic" 9 and 7 (a hand knocking a thin plastic shell, about 700 Hz) for the joints.

Not chosen: the server sending each footfall (it doesn't pose the body, and every screen would
hear its own walk out of step with the one it shows); a sound per frame change (a snap is eight
frames); a footfall per key (every key a clack reads as a machine, not a walk); the reveal from
the server's deal (the screen knows when its curtain clears the feet); sounds at the feet (a stud
or two truer up close: ROADMAP polish).

## D-084 Your torch's freeze lands at once: the server takes your look, your screen holds it (L-06b4b3, Nov 10)
The moment: you swing your torch onto it mid-stride and it stops dead that instant, as SCP-173
and FNAF's animatronics hold the moment you look. Measured first in Studio (seed 7, floor 1,
157's guard hunting at 14.4 studs a second): the server tested your beam along your character's
facing as the server sees it, and the server sees a player's turn 0.06 to 0.13 s late and then
eases it in over another 0.15 to 0.4 s (Roblox smooths a client's character on the server). Your
screen showed it walk on under your light, and the server never froze it: it caught me with my
beam on it for a quarter of a second.

As built, three parts. The torch's aim (`Remotes.FlashlightAim`) carries its heading with its
pitch, whole degrees (`Torch.heading`: a real number, brought round to -180..180), sent each
0.1 s on a 1.5 degree move, after only 0.05 s on a 10 degree swing or the moment your screen sees
your beam land on a keeper (`Torch.shouldSend`); the server takes one no sooner than 0.025 s
after the last and forgets the heading as the torch switches. Keepers test your beam along it
(`Torch.look`), your character's facing only until the first one. Trusting it gives a cheat
nothing new: a client already turns its own character however it likes. One beam test serves
both sides (`Torch.lights` at each `Keeper.beamPoint`): the brain's line is `KeeperMap.clear`,
your screen's a raycast that respects CanCollide. They can disagree: a ray reaches a keeper's
feet under a door that isn't all the way up, where the map says shut (the screen holds, no stop
comes, it walks on after its patience); a friend or a box in the way stops the screen's ray and
not the map's (the screen doesn't hold; the server's stop lands as before). And your screen holds
it (`KeeperMotion.hold`, from `KeeperView`): exactly where and as it was shown, posed on the key
the light freezes it on, until a stop record after the hold answers it within its patience (0.15 s
plus two pings, at most 0.5), then until the screen reaches the server letting it go. The server's
stop lies a little further on (the screen's 0.1 s `Delay` plus your aim's trip): the screen never
slides there while the light holds it, and makes the gap up as it walks again, about two thirds
of it within a stride (5.4 studs) or all of it by the stop its record walks to, so it never stands
short and never steps back. A stop more than 4 studs off lets go at once and jumps. A walk going
on from a stop that landed mid-snap holds the key it froze on until its walk reaches it
(`Pose.along`, the furthest shown), never flicking back into the snap.

Verified in Studio: the frame the camera turned onto it, it stopped (drawn at the same place
every frame after, on its pass-right key); the server froze it 0.03 s later, 1.66 studs on; the
light leaving, the server let go 0.03 s after the turn, and it closed on me about half again its
pace for two frames. A beam on the trapped guard through 157's shut door hit `DoorCollider` with
all seven points in the cone: no hold, no freeze.

Not chosen: holding on your screen alone (the server's keeper walked on under your light and
caught you); rewinding the server's keeper to where your screen held it (friends would see it
step back); the server testing your beam against where your screen showed it, as shooters favour
the shooter (the beam is 54 degrees wide; ROADMAP polish if edges miss); sliding the held body to
the server's stop (it moves while lit); predicting the let-go too (its records still say it
stands, so it would slide). Known: a hunter that catches you right after the light leaves stops
short of its record, so your screen shows it up to a stud short; the catch's blackout hides it.

## D-085 The hole trap lands: neighbours paired right, a press on arrival counts, it searches off the walls (L-12c, Nov 10)
The moment: it's on you, you dive into a unit, squeeze out through the hole you sawed, sprint
round and slam its door on it while it stands staring at where you vanished (GDD "The hole trap";
the crawl is DOORS' and Pressure's vents, D-054; the slam buys time, as Amnesia's battered doors,
D-078). Played end to end in Studio first, on seed 7, floor 1: 155 and 153 open, a hole sawed
between them, 157's guard let out and walked to the junction by 133's door, then up the hall by
156's, so it saw me at 155's front from 24 studs. Three things broke it.

1. **The wrong neighbour.** `CrawlHole.between` took any unit whose door face lines up along the
   wall within 20 studs, so 157 and 153 (155 between them) matched 153's wall with 155. `Saws`
   and `Crawls` pair every two units near each other and keep the first match, so on this floor
   the 155|153 wall's Saw buttons went to 157 and 153 (nobody in 155 could saw it), and once
   sawed, its Crawl button on 155's side belonged to 157: the server refused a crawl from 155
   because you weren't in 157. Now each door face must stand within half its own unit's width
   (plus half a stud) of the wall, so the unit two along never matches.
2. **A press lost to the server's late view.** The server sees your run late (D-084's
   measurement: 0.06 to 0.13 s, eased in over another 0.15 to 0.4 s). Run into the unit and
   press Crawl as you reach the hole, and the server, 4 studs behind, still saw you in the
   doorway: not inside the unit, so the press was dropped without a word and the keeper caught
   me at the hole. Now a press counts if you're inside the unit and within reach of the button
   where the server sees you, or where you'll be `Crawling.Lag` (0.4 s) on at the speed it sees
   you moving (`Crawling.counts`, pure). In Studio the press then came with the server seeing me
   on the door line, running in at 15.5: counted. It gives a cheat nothing: the client already
   moves its own character. The door's Slam, pressed the same way on arrival, already landed.
3. **It searched inside the wall.** Lost, it rushes to where it last saw you; mid-crawl that's
   your feet on the wall's own line, so it stood half in the wall, its reaching arm through the
   hole. Now in a unit the spot is kept `Keeper.Against` (3.4 studs, its arm's room, as the
   trapped stand) off the unit's walls (`KeeperMap.offWalls`; a unit too small for that, its
   middle), and on arriving it turns to where it last saw you: from 153 you see its legs
   through the hole, standing back in 155, facing it. Halls keep the exact spot: nobody's feet
   are ever in a hall's wall.

What already held: it loses you through the wall (the hole is on no keeper's map, so no line of
sight and no way through, D-068); it never follows; it stands its linger (5 s) where it lost you,
and the run round took 0.9 s from the crawl's end to the slam, which traps it.

Verified in Studio: the guard saw me from 24 studs at the junction, I reached the hole and pressed
at once, crawled, it lost me, stood at 3.4 studs off both walls facing the hole, my slam came
0.9 s after the crawl ("the Mannequin is trapped in Unit 155"), and it banged.

Known, left to the owner (`OWNER.md`): the trap needs a lead. You're lost only once your body is
through the wall (about 0.65 s into the crawl, plus the server's lag), and a hunter closes at its
top speed while you lie at the mouth, so it must be about 16 studs behind as you press Crawl, a
little over a second at its hunt; a keeper a few steps behind catches you at the mouth. The trap
is something you set up and lure it into from afar, not a panic escape.

Not chosen: making the server wait for its view to catch up before judging a press (sound, but
it delays a crawl that must start at once); trusting a position sent by your screen (a prompt's
press carries none; the velocity the server already has is enough); pulling every search spot
off the walls, halls too (it changes where a keeper stops after a corner, for no gain); the
keeper hearing the crawl (queued with the other quiet sounds, D-059, D-066).

## D-086 The air horn: a white can with an orange trumpet standing up (L-14a1, Nov 10)
The GDD's air horn ("Lures keepers to a spot", its risk "Wakes dormant things nearby") comes from
Lethal Company, whose air horn draws the monsters that hunt by sound. It's a marine air horn, the
kind boats and stadiums use, built from code the saw's way (`art/airhorn/`): one MeshPart, one
baked 1024² set, 6,000 triangles, no brand. A white steel can with a black band, a black collar,
and a safety-orange trumpet standing straight up out of it, pressed down to blow, as the common
canned horns are. White because the torch is yellow, the cutters red and the saw green: the can is
the one white tool, and the flared trumpet is its outline from a doorway. The band carries an
orange sound-wave mark (a dot and three arcs), the one picture on it, so it says "loud" at a glance
without words. Sized about 1.6 times life (0.15 studs to the inch, 1.86 studs tall), more than the
saw's 1.3 because it's a small thing, less than the padlock's two. It's laid standing on its foot.
In your view it's held low on your left, the trumpet standing up beside the hall and the mark
turned to you (`hold` -1.2, -1.15, -2.2, turned 205, 4, 10); a friend sees it in your fist,
trumpet up, the mark out to your side (`inHand` 0, 90, 0: at -90 the mark faced your body,
measured in Studio). Picking it up plays Pro Sound Effects' "Metal Hit Steel Plate Hit Slapped 2"
(its one slap, a little faster); dropping it, "Metal Container 2" from just before its hard hit
(0.36 s) at 1.3 times speed, an empty can landing and bouncing, both measured by AudioAnalyzer
since nobody here can listen. Its `use` pose is its hold: L-14a2 raises it to blow. `Specs/AirHorn`
carries the bell's mouth for the blast. The test hall lays one beside the spawn's bolt cutters.
Not chosen: a trumpet bent forward (a sport horn's; harder to read standing on a floor, and the
straight one is the familiar shape); a red can (the cutters are red); a brand or words on the band.

## D-087 Blowing the air horn: a blast keepers hear as they hear doors (L-14a2, Nov 10)
Lethal Company's air horn draws the monsters that hunt by sound; ours does the same through the
keepers' own hearing (D-069), so nothing new decides who hears it. You press Blow with the horn in
your hand (a left click as Lethal Company's use, a gamepad's L2, since R1, R2, L1, X, Y and B are
taken, or a round button left of a phone's jump button, under the right thumb that turns and
jumps, so you can blow and run). Every keeper on that floor whose trip along the halls to you is
inside 130 studs comes to where you blew it and looks, as for a door; a sleeper in an open unit
that near wakes and comes (the GDD's "wakes dormant things nearby"); a hunting one keeps its eyes
on you; nothing hears it through a shut door. 130 is a door bursting open, the loudest door
sound, past an open's or a slam's 110: the horn is the loudest thing a player makes, and players
hear it to the same distance (D-069: players and keepers hear one world). The sound is placed
where you stand, dropped to the floor of the place you're in, and the keeper's spot kept off a
unit's walls, as a search's is (`Horn.where`). One blow every 2.5 s, kept by the server per player
(a press up to 0.15 s early is taken), with no count: Lethal Company's never runs out and the GDD
gives none (`OWNER.md` asks).
How it's built: a tool whose catalog row has a `verb` ("Blow") has a press of its own, so bubble
wrap, the blanket and glow sticks reuse it: `Tools.UseRemote` ("ToolUse"), taken by `Slots`
(a living player with such a tool in hand, then its own rate, never the hand's) and fired as
`Slots.used`. `Horns` (server) keeps the horn's gap, stamps the carried horn's model with the
server's clock (`Blown`) and tells `Keepers:hearHorn` the bell's mouth; `Keepers` finds the floor
the point is on (`Horn.onFloor`, by `KeeperMap.off`) and hands each keeper `Horn.heard`. On your
screen (`HornView`) the blast plays at once, ToolView brings the horn up into the row's `use`
pose for the 1.1 s blast with its jerk (`Hand.use`), and CameraShake kicks 0.32; the button dims
until the gap is up. Friends' screens play the stamped blast at its bell (skipped if over 0.5 s
old) and lift the blower's left arm to 135 degrees after their animation. The blast is Pro Sound
Effects' "Air Horn Various Lengths 4" from 0.92 s (one 1.1 s stadium blast, then its echo).
Not chosen: a separate wake radius for sleepers (keepers and players would hear different worlds,
D-069); the 60 studs the last handoff suggested (quieter than a door, so the horn would lure less
than opening one); the horn heard from the tops by keepers below (the map puts a blast up there
in the unit under you, so a shut door muffles it: the same open question as sight between the
tops and the halls, `OWNER.md`); a client-only sound for friends (the server's stamp keeps one
truth, and a late screen skips a stale blast).

## D-088 Bubble wrap: a roll you carry, a sheet it lays (L-14b1, Nov 10)
The GDD's bubble wrap ("Laid across a hall, it pops when anything crosses", its catch "Friends pop
it too") is a tripwire alarm, and its precedent is Minecraft's tripwire, which any mob or player
walking through sets off. Lethal Company's whoopie cushion sounds when stepped on too, but whether
its monsters hear it is only anecdote, so it isn't the precedent. Built from code the air horn's
way (`art/bubblewrap/`): one baked 1024² set and two MeshParts in one FBX. The roll is a 12-inch
household roll of large-bubble wrap at 0.15 studs to the inch (1.6 times life, the horn's scale):
1.8 studs long, 0.78 across, on a brown cardboard core that stands a little proud of each wound
end, its loose end high on the front held down by a strip of brown packing tape. The sheet is that
wrap unrolled across the 8-stud hall: 7.35 studs across (short of each door face), 1.8 deep, its
ends curled up as a roll's wrap does, rippling a little, sitting just off the floor. Bubbles are a
fat inch across in staggered rows ("large bubble" wrap), because half-inch bubbles are under four
pixels a few studs off on a phone; each is painted as a clear dome with a white rim, which reads in
Roblox as rings (the owner judges, `OWNER.md`). Clear film with a cool tint, milky where it's
wound thick; on the floor the film is painted grey, as if over concrete. The sheet is its own
template, `ReplicatedStorage.Props.BubbleSheet` (pivot: the middle of the floor under it), not a
second part of the tool: the tool's template is what's carried, dropped and handed over, while a
laid sheet stays where it was laid, and several may be down at once. The sheet is its top surface
only: it lies on a floor and curls up towards the hall, so nothing sees its underside. The atlas is
laid out by hand, the sheet a strip along the bottom at 137 texels a stud and the roll
smart-projected into the square above it at 240, since packing a 4-to-1 strip into a square tile
wastes most of it. Held low on your left, its axis reaching in from the bottom corner, the taped
end up (`hold` -1.3, -1.2, -2.6, turned 240, -8, 0); a friend carries it by its middle along the
forearm (`inHand` 0, 90, 0). Picking it up plays Pro Sound Effects' "Plastic Bubble Wrap Short
Fluttering Movements 12" from its first crinkle; dropping it, "11" from just before its sharp
crackle, a little lower; both measured by AudioAnalyzer. No `verb` yet: a Lay button that did
nothing until L-14b2 would be a silent action, so the row gains `verb = "Lay"` there. Not chosen:
pink anti-static wrap (reads as a toy); a 24-inch roll (3.6 studs in your hand covers the hall);
a loose tail flapping off the roll (harder to read on a floor than the tape); real see-through film
(`AlphaMode` Transparency, in ROADMAP's polish list).

## D-089 Owner calls, Nov 10: a corner minimap, two tools parked, the Moth out
- **The map is a small corner minimap, always on, for now** (L-10). The owner may later make it a
  map you stop to open, so you're exposed while you read it; the drawing stays apart from its frame
  so that's a small change. Friends as dots stays the default, and moving it up the queue is the
  owner's call (`OWNER.md`).
- **Only the bubble wrap of the tools left:** the moving blanket and glow sticks are parked, not
  cut (L-14c, L-14d); the owner isn't sure we need them (`OWNER.md`).
- **The Moth and its mothballs are out:** "taking the whole storage unit thing too literally".
  Beyond the Mannequin, the GDD's roster was never the owner's pick; it waits on a rework from the
  loop, each monster with a hit game's rule and storage only as its look (`OWNER.md`). The GDD
  still lists them until then; build none of them.
- **"Keepers" was never agreed as their name.** It's our working word in the docs and code only;
  nothing on screen says it. The code keeps `Keepers` until a name is picked and reaches the screen.
- **The air horn's controls pass** (the round Blow button left of a phone's jump button; a left
  click): tweak if playtesters ask.

## D-090 Laying the bubble wrap: one sheet across the hall at your toes (L-14b2a, Nov 10)
Minecraft's tripwire is strung where you want the alarm; ours is laid where you stand. With the
roll in your hand you press Lay (the same round button, click or L2 as the horn's Blow: HornView's
button now takes any tool with a verb, each tool's view answering its own press), and the whole
roll unrolls into one sheet square across the hall, its near edge just in front of your toes
along the hall the way you face, on the hall's centreline (`Wrap.place`). Facing a dead end's
wall it lies under your feet, or backed off the wall. Ahead, not under you, so you watch it go
down and the natural move is to face the way the threat will come, lay it, turn and run; the
layer is never standing on it. At a junction's middle it lies across whichever way you face
more. Only in a hall: the straights and the junctions (`Wrap.halls`), never a unit, the tops
(your middle over 6 studs up), the lobby (a room, and the car opens off it) or the car; refused,
your screen says "Lay it in a hall" on Slots' short line. One sheet a roll, the roll spent
(`Slots:spend`): the GDD gives no count (`OWNER.md`). The server facing is the character's as
the client holds it, a moment late (D-084); the sheet is square to the hall either way.
On every screen (`WrapView`) a sheet stamped within the last second unrolls from the layer's
left to their right in 0.55 s, eased out like a pushed roll: a loose copy of the roll's body
rolls over the floor along the hall's axis, turning by the distance over its radius and thinning
to 0.4 of its girth, the sheet's part grown behind it from the left edge (a MeshPart's size
scales its mesh; at this speed the stretch reads as wrap laid out), then the core sinks and
fades in 0.18 s. A crinkle plays at the sheet (the pick-up's, slowed to 0.85: a real unroll
rustle is in ROADMAP's polish list). Your view brings the roll out and down (the row's `use`).
The test hall gives `Wraps` its own list of halls (DevCorridor's `TEST_HALLS`).
Not chosen: under your feet (you'd stand on your own trap and not see it go down); a sheet as
long as you like or two a roll (no precedent or GDD number); a client-side check of where you
stand (screens don't have the floor's layout; the server's refusal is one short line away).

## D-091 Owner calls, Nov 10: softer bubbles, two tools cut, the minimap's friends and slot
- **The bubbles are softer** (L-14b1's look): each bubble now goes gently milky from a third of
  its radius to its edge at half strength, with a soft glint high on one side (`MILK`, `GLINT`
  in `art/bubblewrap/spec.py`), instead of a white ring. Re-uploaded in place; the new textures
  have new IDs, so the templates' SurfaceAppearances were swapped in Studio (docs/STUDIO.md).
- **The moving blanket and glow sticks are cut**, not parked (L-14c, L-14d gone). Bubble wrap
  is the last of the GDD's tools. The deal still deals them as unbuilt tools until a session
  takes them out of `Deal.Tools` and its bag (it reshuffles every seed: Queue).
- **The minimap shows friends as dots**, behind one Config switch so they can come off in a line.
- **The minimap comes straight after the bubble wrap**, before getting kept (L-07).

## D-092 The pops: a tripwire anyone treads on, heard as far as an opened door (L-14b2b, Nov 10)
A laid sheet is Minecraft's tripwire: anything that walks into it sets it off, a keeper, a
friend or you. A foot entering the sheet (its 7.35 by 1.8 studs, plus 0.4 round its edges for a
foot reaching past your middle, which covers the hall wall to wall) pops it, once (`Wrap.crosses`,
Lune-tested). So does a step passing clean over it between two server steps. Stepping off it or
shuffling on it doesn't (a sheet laid under you at a dead end stays quiet as you leave it), nor
does walking beside it. Feet more than 1.2 studs over it are in the air, so a jump clears it, as
you can hop a tripwire: a skill for you and your friends, never for a keeper, which doesn't
jump. Feet read up to 3 below it while crawling. A move longer than 8 studs in one step (caught,
respawned) pops nothing on the way. The server (`Wraps`) checks only while a sheet lies unpopped,
each step, from where each foot was last step: players' feet from their root down to the floor,
keepers' from `Keepers:feet` (a read, so `Wraps` never reaches into the brain). A pop stamps the
sheet `Popped` (the server's clock) and tells `Keepers:hear(at, reach, what)`, the general hearing
the horn now uses too (`hearHorn` is `hear` at the horn's reach; the pure rule moved from `Horn`
to `Keeper.onFloor`, `soundAt`, `heardAt`). Its reach is an opened door's, 110 studs along the
halls (D-069): laid two halls back, it brings a keeper as a door opened there would. The keypad,
a dropped tool, the saw and the rest can use `hear` later (Queue).
On every screen (`WrapView`) the pops play at the sheet, heard as far as keepers hear them: Pro
Sound Effects' "Plastic Bubble Wrap Short Fluttering Movements 2" from 3.34 s for 1.05 s, a
crackle building to one sharp pop at -6 dB, at volume 2 (measured, docs/STUDIO.md). The sheet goes
flat over 0.6 s, fast then settling: its bubbles squash to 0.35 of their height (the part's size
scales its mesh, the bubbles are geometry) and its film dulls (`SurfaceAppearance.Color` to 0.72
grey). Popped while still unrolling, it flattens as it unrolls. Under your feet, your view jolts
(0.16, half the horn's). A sheet seen long after it popped just lies flat. Default (`OWNER.md`):
a popped sheet stays, flat and silent; one roll, one alarm.
Not chosen: popping as you walk on it (the layer at a dead end would set off their own);
counting a jump (no skill, and a tripwire doesn't); a chain of pops per foot (one alarm reads
cleaner, and the GDD names one).

## D-093 Three pops, then spent; laid sheets stream whole (L-14b2c, Nov 10)
The owner, Nov 10: a sheet should pop three times as it's walked over, then lie visibly spent
and do nothing. It wears through in stages you can see, as Minecraft's anvil goes chipped, then
damaged, then breaks. Each walk across (D-092's crossing) pops it while it has pops left and the
last one is 0.8 s gone (`Wrap.ready`): a friend on your heels or a foot dithering at its edge
doesn't spend a pop, and pops never blur into one crackle. Every pop is heard by keepers as the
first was. On screens each pop plays the same measured crackle at its own pitch (1, 1.1, 0.9) and
wears the sheet a third of the way (`Wrap.worn`): squashed toward 0.3 of its height, tinted grey
and turned up to 0.35 see-through, the air gone out of it. The server stamps the count (`Pops`)
before the time (`Popped`); screens act on the time and read the count.
The owner's "only heard it once" was mostly a bug: `WrapView` dropped any sheet whose part
reached the screen after its model, so it never played, popped or wore there. Laid sheets now
stream `Atomic`, and `WrapView` waits for a late part (docs/STUDIO.md).
Not chosen: a baked burst-bubble texture for the spent sheet now (an art session: L-14b2d, if the
owner finds the grey, flat, clear look doesn't read as popped); clearing it away when spent (the
owner wants it seen); a rest per walker rather than per sheet (more state, and one alarm a moment
reads cleaner).

## D-094 The corner map: a window that follows you, filled in as you walk (L-10, Nov 10)
The map sits top right under the top bar, a square about a third of the screen's height (104 to
176 points), showing 112 studs of floor round you: halls at least 7 points wide on a phone. It
fills in each hall piece you stand on (a straight, or a junction's middle and arms; standing in a
unit or on its top fills in the hall it opens onto), as R.E.P.O.'s map fills in rooms as you find
them; the lobby and the car are drawn from the start. While the car is off the window an amber
mark waits on the edge the way it lies, as GTA's radar holds a waypoint on its rim, so the way
back is always on screen. North stays up, the lobby and the gate at the bottom ("the way back is
always down"); your dot turns with your view. Friends are blue dots, held on the edge, paler, when
off the window (D-091). A unit is ticked once the deal has shown its inside (a peek, an open, a
lift from inside, a saw's hole: `Deals.dealt`), for everyone on the floor, so friends see what's
been searched; it goes green (the sign that reads at 6 points) with a tick on it. What you walked
stays yours: a friend's walking draws nothing on your map. Roblox's player list is off: it would
open over the map on a computer.
**The layout reaches screens as shapes, never the seed.** `Floor.generate` would rebuild the floor
from its seed on a screen, but the deal is drawn from the same seed, so a screen holding the seed
holds the code, the notes and every unit's contents. `Minimaps` sends the drawn rectangles
(`Minimap.encode`, about 2 KB a floor) and the opened list; the server owns both.
Not chosen: the whole floor fitted in the corner (halls 4 points wide on a phone, too small to
tick a unit); turning the map with you (a full map later would have to turn too, and "down" stops
meaning the way out); drawing the doors' own state from each unit (far units aren't streamed to
your screen, so a friend's opened unit wouldn't show).


## D-095 Getting kept: stored in a shut unit away from you, let out as its door goes up (L-07a, Nov 10)
The moment: the keeper's hands close, the screen goes black through the 2-second wrap, and you
wake in the dark inside a unit somewhere on the floor, facing its door, until a friend opens it.
Dead by Daylight's hook and Flee the Facility's freeze pods are the precedent (caught, stored, a
teammate frees you). Stored at random and never the nearest is the GDD's own twist on the hook,
an untested bet in `OWNER.md`.

As built: Keepers marks the caught player kept (`Kept.Attribute`, a player attribute only the
server sets) at the catch and skips them while it's on, so no keeper sees or catches them twice;
`Caught.Out`'s 2-second spare became "while kept", and its length is now `Caught.Wrap`.
`KeptPlayers` takes `Keepers.caught`: everything carried drops (`Slots:dropAll`, as dying does),
the root is anchored (only the server moves a kept player; nothing to fall through while the far
unit streams in), and `Kept.choose` picks the unit: its door all the way down (not padlocked, not
open), no keeper dealt there nor the guard's place, no keeper's feet inside, nobody kept in it;
never the nearest of those while another will do; an unopened one ahead of one already seen into,
at random. That unit is never dealt (`Deals:hold`), so the friend who opens it finds only you,
never a keeper beside you; a note already stuck there stays. At `Caught.Dark` (the screen black)
the server pivots you 62% of the way in, facing the door. You're let out when its door's state
reaches Open (`Doors.changed`): any friend's Open, the stand-in until L-07d's Cut free. Dying,
leaving, a new character or the floor going lets you go too; no unit free holds you through the
wrap and lets you go where you stand.

Refused while kept, on the server: every prompt in the world (`Prompts.wrapped`: doors, the lift
from inside, crawl holes, ladders, the saw's cut) and Slots' pick-up and hand-over either way.
The screen (`CaughtView`): the catch's blackout as before; in the black the camera turns the way
the server stood you and the body stops turning with the camera (`Humanoid.AutoRotate` off while
held: the game is always first person, and the body turned to the old camera otherwise, so you
woke facing the back wall); the prompts hidden (`ProximityPromptService.Enabled`); "Wait for a
friend" comes up over 1 s; all of it undone as the attribute clears.

Not chosen: only units already opened (few early in a floor, and a friend's map already ticks
them); dealing the unit as usual when it's opened (a keeper could be dealt in beside you); the
building rolling an open door down on you (needs a door motion the building doesn't have, and a
shut door is the GDD's picture); a dev command to get out (Reset already does, alone); waiting on
the stream before the move (an anchored root can't fall, and the screen is black anyway).

## D-096 The wrap you can see and hear: fitted film the server welds on, a squeal each screen plays (L-07b, Nov 10)
The moment: a friend lifts the door and there you are in the dark, shrink-wrapped head to foot in
cloudy film; as the keeper wraps you, the film screeches in the black. The film is real art
(`art/keptwrap`, the unit's way): a cocoon lofted round Roblox's default blocky R15 body at rest,
bands of film in a spiral, each over the last, a bright cord along every edge, the film twisted
shut over the crown; its alpha in the colour map (AlphaMode Transparency).

As built: at the move (`Caught.Dark`) `KeptPlayers` clones `Props.KeptWrap`, sizes it with the
pure `Kept.fit` to the kept body's rest box (each body part placed by its joints' rest offsets,
Motor6D or AnimationConstraint, so a mid-swing arm or a hat doesn't size it; clamped to 0.5-2.5x
per axis), welds it to the root (massless, no collision, touch, query or shadow) and parents it
in the character, so it streams and goes with the body; it's destroyed as they're let out. Its
part Transparency is 0.02 (`Kept.WrapBlend`): at 0 Roblox cuts the alpha into shreds instead of
blending it. `CaughtView` keeps it undrawn on the kept player's own screen. The squeal needs no
network of its own: every screen watches each player's `Kept` attribute (only the server sets
it) and plays Pro Sound Effects' duct tape peel 2, 0.6 to 2.5 s at 0.92 speed (about the whole
2-second wrap): close for the caught player, from where they stood for everyone else (45 studs).

Not chosen: the wrap at the catch rather than the move (seen for 0.4 s, then gone with the body;
the catch's own look is L-06c2's); a server-played squeal (it moves with the body into the unit
and would tell friends where you're kept, which is L-07c's bang to tell); sizing by
`GetExtentsSize` (hats, wings and a walk's swing would size it); hiding hats and hair while
wrapped (a roomy head holds most hair; a big hat pokes out).


## D-097 Banging: the door's own thud, a mark friends see through walls, the hall's light under the door (L-07c, Nov 10)
The moment: alone in the dark, wrapped, you hammer on your door; down the hall your friends hear
it thud and see which door, and so might a keeper. Dead by Daylight's hook is the precedent:
everyone sees where you hang, and a teammate comes.

As built: once you're inside your unit a round Bang button comes up (`CaughtView`), under the
right thumb on a phone and low in the middle elsewhere with its key under it (a click, Space, a
gamepad's A or R2). Each press jolts your view at once (`Kept.BangKick`) and fires
`Remotes.Bang`, which carries nothing. Presses come no faster than `Kept.BangEvery` (0.55 s, so
the door's 0.5 s jolt plays out whole); one press made too soon is held for the next bang, as a
fighting game buffers an input, so mashing hammers at the door's pace. The server
(`KeptPlayers`) takes a bang only from someone kept and already inside, at most one per
`BangEvery` less `BangSlack` (0.15 s for a jittery connection): a spam of 362 presses in 3 s
landed 8. A bang is the building's own `Doors:move(unit, "Bang")`, the trapped keeper's blow, so
the door's thud and shake play on every screen near it and keepers hear it as they hear that
(DoorSound's Bang, 70 studs along the halls): no second call to `Keepers:hear`, which would
double it. It never dents the door.

The mark: each bang stamps the floor's model (`Kept.BangsAttribute`: slot, who, when, the door's
foot), the model the corner map already reads, so every screen marks it however far off the unit
is and whether or not it has streamed in. On friends' screens (`BangMarks`) a blue dot with the
kept friend's name stands over the door, drawn through walls, a ring going out at each bang; on
the corner map the unit gets a bigger blue dot with a ring, held on the window's edge when off it.
Both fade `Kept.BangMark` (8 s) after the last bang, the last 2 s fading, and go at once when the
friend is let out. Never on your own screen, nor while you're kept. A kept friend's own map dot
is hidden (`MinimapView`): the GDD stores you at random so friends have to look, and a dot that
shows where you're kept would make the banging pointless (`OWNER.md` asks).

The light under the door (`UnderDoor`): while you're kept the server names your unit
(`Kept.InsideValue`, an ObjectValue under you) and your screen alone draws a thin warm Neon strip
against the inside of the door's bottom bar, with a SurfaceGui spill fading 1.6 studs across the
floor, lit only while the nearest motion light outside is Lit, flickering on with the tube
(`HallLight.Flicker`). Motion lights trip for players and keepers but never the Mannequin, so the
line coming on means someone walked by. No real light (the GDD's cap).

Your torch keeps working while you're wrapped (the default the ticket named; `OWNER.md` asks).

Not chosen: a mark on the unit itself (a far unit isn't streamed to a friend's screen, D-094's
reason); a remote event to friends for each bang (a screen that streams in or joins late would
miss a mark still showing); a quieter or shorter-reaching kept bang (it's the same door's thud);
a sound for a far friend as the mark appears (polish, ROADMAP); a real light under the door (a
light instance per kept player, against the phone budget).

## D-098 The deal hands out only built tools; the guard drawn before the bag; the deal script deals what Studio deals (L-14e, Nov 10)
The moment it fixes: a door rolled for a tool always has one behind it. With the moving blanket
and glow sticks cut (D-091) but still in the bag, about one tool unit in five opened on nothing,
a lie about what the deal promised.

As built: `Deal.Tools` and `Deal.Bag` hold the six built tools (two saws, two bolt cutters, two
padlocks, a ladder, bubble wrap, an air horn: nine to a bag, as Tetris's bag deals). The rule
that keeps it true is a test, not a habit: `tests/carry.spec` fails if any tool the deal hands
out lacks its `Tools.Catalog` row or its generated Specs, so a future tool joins the bag in the
ticket that builds it. `Deals`' "no art yet" path stays as a guard and no longer fires.

The guarded note (D-072) is now drawn before the bag is filled, still after everything the floor
lays. Drawn after the bag, as it was, it moved with any change to the bag's tools or counts, and
with it the floor's one awake keeper on floors 1 and 2, which the Studio recipes and the owner's
test steps lean on (seed 7, floor 1: Unit 157). Every seed's bag order moved anyway in this
change, so this was the free moment. What it moved: each seed keeps its layout, code, padlocks,
notes and every unit's kind (all drawn earlier); the bag's order changed, and the guard on
about half of floors (138 of 300 kept theirs over seeds 1 to 100, floors 1 to 3). Seed 7 keeps
its guard on floors 1, 2 and 6 to 10 (157 on floor 1); floors 3 to 5 moved (377 to 367 on 3).
`tests/guard.spec` holds it: a bigger bag moves no guard over 300 floors (it fails with the old
order).

`scripts/floor-deal` now carries on the layout's own Random into the deal, as `DevCorridor` lays
the Studio floor, and names the guarded note. Before, it seeded the deal apart (seed + 1000000,
as `tests/deal.spec` still does), so it never showed what Play deals (L-13b1 saw the gap and put
it down to the order doors open). Verified: on seed 7, floor 1, 26 units opened in Play dealt
door for door what the script prints. Only which tool lands where depends on the order doors
first lift.

Not chosen: leaving the guard after the bag (seed 7, floor 1's guard went to Unit 124 that way,
and every recipe naming 157 would have needed rewriting, and again at the next bag change); the
specs dealing from the layout's Random too (they check rules over 200 seeds, which holds either
way).

## D-099 Cut free: a friend's one-second hold at your open door, a rip, the film slumping off you (L-07d, Nov 10)
The moment: you're wrapped in the dark, the door goes up, a friend steps in and grabs the film;
it strains round you for a second, then rips. Strips of film fly at them, the wrap drops down
your body into a heap round your ankles, and you're on your feet. Dead by Daylight's unhook is
the precedent (a teammate at your hook holds a button and you're down and running), as Flee the
Facility's freeze pods are for a teammate letting you out. It replaces L-07a's stand-in: the door
going all the way up no longer lets anyone out.

As built: once you're inside, `KeptPlayers` puts a `CutFree` Attachment on your root, a little
up and 1.2 studs out in front of the chest toward the door (`Kept.CutUp`, `CutAhead`), so the
button sits on the film where hands would grab it and its line of sight clears the body. The
prompt (`Prompts.make`): "Cut free" over your name, E or X (Open's keys, and Open never shows on
a door that's all the way up), held `Kept.CutHold` (1 s), shown within `Kept.CutReach` (7 studs:
from a big unit's doorway, a step out of a small one), enabled only while your door's state is
Open (`Doors.changed`). Your own screen hides prompts, so you never see it, nor any of a
friend's hold but its sound.

The server judges each trigger with the pure `Kept.cut`, in the unit's frame: never yourself,
never a friend who's kept or down; you must be inside and your door up; the hold must have
begun on the server's clock (`PromptButtonHoldBegan`) at least `CutHold - CutSlack` (0.75 s)
before the trigger, so a trigger with no hold does nothing; and the cutter must stand between the
unit's side walls, from `CutOut` (3 studs) into the hall to the back wall, and within `CutReach`
plus `CutReachSlack` (2) of the cut point. That refuses a cut through a side or back wall, from
across the hall or from up on the tops. A refusal a friend can fix flashes on the button ("Get
closer", "Hold to cut"); the rest can't come from a real button.

The strain: each friend holding is counted onto the wrap (`Kept.PullAttribute`), and every
screen plays the wrap's own peel there (`Kept.Pull`: the squeal's recording at 0.74 speed),
swelling from a third to full over the hold (`Kept.pull`), so the rip lands on a peak.

The rip: the wrap is unwelded and left anchored where you stood, parented to Workspace with when
it tore (the server's clock), who it freed, who cut and which way it lists, then destroyed after
`Kept.tearLength()` (2.1 s) and a half. Every screen that has it (`CutFreeView`, from the tag
`Kept.WrapTag`) plays the rest itself: Pro Sound Effects' "Plastic Sheet Impacts Rips Paper
Tears 9" from 0.31 s (a sheet torn hard, bursts to 1.1 s), 18 strips of film flung toward the
door (a ParticleEmitter with the film's own colour map, squashed into strips), and the slump
(`Kept.tearPose`): a bulge as it's torn, a fall down the body gathering speed, its foot held on
the floor, listing toward the door, to a heap 0.16 of its height, 0.8 as wide and 1.6 as deep
(round your ankles, not the shoulders), a squash as it lands with "Plastic Bag Handling Crunchy
Cellophane 8", lying 0.75 s, fading 0.6 s. A screen that streams it in late joins the beat where
it is, silent past 0.3 s. The freed player's view jolts (`Kept.FreedKick`, 0.5, softer than the
catch) and widens 7 degrees and back over 0.8 s (`Kept.widen`); the film is drawn on their own
screen again, so it drops away past their eyes; their Bang button fades over 0.3 s. The
cutter's view jolts a little (`Kept.CutterKick`, 0.2).

Not chosen: a remote event for the tear (a late screen would miss it, and the wrap already
carries everything); the server playing the sounds (one more thing to stream, and no say over a
late screen); the wrap vanishing, or tweened on the server (every screen's own steps are smoother
and cost the server nothing); a torn-open wrap mesh (a squashed cocoon reads as film dropping off
at the speed it moves; the torn mesh is polish in ROADMAP); hold progress on the kept player's
screen (the ticket: they get only the sound); a grace after you're free and keepers hearing the
rip (both `OWNER.md`); reading the colour map's `ColorMap` (game scripts can't; its
`ColorMapContent` they can, docs/STUDIO.md).

## D-100 The padlock: a clock on your door, a hand working keys at it, the click shut (L-07e, Nov 10)
The moment: you've been kept a while. In the dark you hear keys worked in a padlock right outside
your door, and a countdown comes up; down the hall your friends see your name counting down, and
one of them sprints. Then the bolt shoots and the shackle clicks: now only bolt cutters get you
out. Dead by Daylight's hook stages are the precedent (wait too long and it gets worse, and the
whole team sees the clock); the GDD's "Left too long" is the rule ("after a few minutes the
building padlocks your unit, so freeing you needs bolt cutters").

As built: the clock is the server's (`KeptPlayers`), one a keep, started as you're put inside:
`Kept.PadlockAfter` (150 s) of time that counts, the warning its last `Kept.PadlockWarn` (20 s).
Time counts only while your door is down (`Kept.counts`: shut, open a crack, coming down); going
up or up, a friend has come and Cut free is on offer, so it stops. Run out, the padlock goes on
the moment the door is down and still (`Kept.lockable`, `Kept.tick`): with it held a crack open
the hand keeps working every `HandleAgain` (3 s) until it drops. The padlock is the game's own
(`Doors:lock(unit, true)`), so its bolt and click play on every screen near (DoorSounds), its
buttons read Padlocked with Open and Cut, keepers hear it as any padlock, and Cut free can't show
until a friend's bolt cutters take it off and the door goes all the way up (the door's own rules).
A door padlocked by a friend's hand first counts the same. One padlock a keep: once it's been on,
the clock is done, so a friend who spent bolt cutters never faces a second. Let out, dying or
leaving stops the clock; a padlock still on stays on the empty unit (it's the building's, and
taking it off unseen would be a silent change).

The wire: two attributes on the kept player, which every screen has however far off: the server
time the padlock goes on while the warning runs (`Kept.WarnAttribute`, set as it starts and as
the door comes back down, cleared while it's up) and `Kept.PadlockedAttribute` while it's on.
Every screen plays the rest itself (`PadlockView`). The hand: Pro Sound Effects' "Keys In
Padlock" 4, 5 and 2 (`Kept.Handle`, slowed to 0.85, turned up: the takes sit at -24 to -36 dB),
at the hall side of the door 1.5 studs up, heard to 40 studs, five times (`Kept.Handlings`: 19.5,
14, 9.5, 6 and 3 s left), closer and louder to the end, the last over 1.4 s before the bolt; each
trembles the kept player's view (`HandleKick`). Your line, high in the middle at the Caught
headline's size: "Padlock in 20", beating each second, red for the last five. Friends' lines
under the top bar: "Sam: padlock in 12", the name in the map's friend blue. The click (as
DoorSound's PadlockShut lands, 0.32 s after the bolt): your view jolts (`ClickKick`), APM's "Evil
Mind 9" hits (dark, most of it above 150 Hz so a phone plays it) and "Padlocked" slams in red and
stays while it's on; friends get "Sam: padlocked" in red and the hit at `DreadFriends` (0.35)
wherever they are, as DbD sounds a hook for everyone. Cut off or let out, the lines fade.

Studio: Workspace's `DevPadlockSeconds` (read in Studio only, `Kept.DevPadlock`) shortens the
clock for each keep that starts after it's set, the warning kept whole unless the clock is
shorter.

Not chosen: a clock that runs with the door up (a friend at your open door would race a padlock
they can't stop); a peeked door stopping it (a crack is still a shut door, and a friend who peeks
and walks off shouldn't freeze it); the building pulling a peeked door down to lock it (the ticket
waits for it to come down; a door moving by itself in a friend's face is a new mechanic); a timer
on screen the whole keep (the warning is the clock you feel; the dark before it stays yours);
the line naming the unit or marking it on the map (banging is how friends find you, D-097); a
second padlock after one's cut; a remote event for the warning (a screen that joins or streams in
late would miss it); the server playing the hand (one more thing to stream, and no say over a
late screen); the chase's sting for the click ("Rising Fear Hit 1" is the chase's own).

## D-101 A walk that frightens: it limps, its head lags, its steps get heavier as it nears (L-06c1, Nov 10)
The moment: you hear it before you see it, and what you see moves wrong. The owner, Nov 10
night: its steps "sound like fucking pinnoccio walking around". The light wooden clack each step
and the plastic knocks between (D-083) were a puppet's sounds, so both went.

The walk (`Mannequin/Pose`, every screen's own, the server's motion untouched): it limps on a
stiff left leg, as Silent Hill's mannequins and Doors' Figure move like things that shouldn't
walk. The left keys are no longer the right ones mirrored: the left knee stays all but straight,
and on the pass the left hip hitches up to swing the stiff leg round on its toe. Each key carries
it its own distance (`Walk.Spans`, shares of the 2.7-stud step: 0.8 for the plant, 1.4 for the
drag, 0.7 for the stiff heel, 1.1 for the swing through) and holds its own share before snapping
on (`Walk.Holds`: 0.7, 0.15, 0.55, 0.5): the plant held long and then a jerk, the drag starting
at once and sliding slowly, the one smooth thing it does. Its head lolls hard to one side on the
plant and the other on the heel, and lands a beat late: over the first half of each key's span
(`Walk.Lag`, never past the hold) it swings from the last key's place into this one's, so it
bobbles after every step. A light still freezes it on a key, head settled (a small snap of the
head as the light lands). Each key's frames are now 3 of the head settling, the key held and 9
of the snap (`Walk.Settle`, `Walk.Snaps` 10), still worked out once per screen and cached.

Its sounds (`KeeperTell`, `KeeperRows`, `KeeperSounds`): each beat is layers, recordings played
at once. The plant is a hollow fibreglass thunk (four Pro Sound Effects planter drops on
asphalt, pitched to 0.74 to 0.86, heard to 70 studs, past the 48 it sees) with a body's weight
under it (a plastic cooler's hit, a body's thump and a railroad tie on pavement, mostly 190 to
470 Hz so a phone still plays it). Nearer is heavier, as Five Nights at Freddy's footsteps swell
as an animatronic comes: `heft` eases from 1 within 10 studs to 0 at 40, and each sound's
`farGain` and `farPitch` say what's left of it far off (the weight: a tenth, 15% higher), so a
tap down the hall becomes a thud in yours. The drag is a rock scraping concrete (SCP-173's
grind), raised to 1.1 to 1.3 for a phone, heard to 45. The heel is the thunk lighter and a
little higher with a third of the weight; the swing through is silent, so you hear the limp:
thump, scrape, tock, nothing. Its body creaks (a rubber pedal's ratchet and a tire's rub pitched
down) as it jerks out of its shop pose and each time its facing turns 40 degrees (`turned`,
tested on every screen as KeeperView moves it, no more than one a 0.9 s), so it creaks at
corners and as it turns to you. A door lifted on one standing in a unit answers with a deep
thunk and a creak. Standing or held in light: nothing, as before. Every take is cut to one hit
and measured (docs/STUDIO.md, "Sounds measured for the keeper's walk"); three or four takes a
sound, never the last again, each at a random pitch, so no two steps sound alike.

Not chosen: the dead-still-then-rush (SCP-173, Doors' Seek), which needs the server to move it
faster than its walk for a moment, against the GDD's "nothing outruns you" (ROADMAP polish, the
owner's call); one heavier recording in place of the clack (one sound can't be both a far knock
and a close thud); an equaliser for heaviness (layers do it with no effect per sound, and what
a phone can't play an equaliser can't add); its head turning to follow you (it would say it had
seen you when it hadn't); sounds at the feet (still ROADMAP polish).

## D-102 The catch as a jump scare: silence, its face rushing your eye, the cut, a slow wake (L-06c2, Nov 11)
The moment: the worst thing that can happen to you. The owner, Nov 10 night: getting caught
"doesn't seem like a big deal"; it has to land. Five Nights at Freddy's and Piggy end a run with
the face rushing the camera and a scream, no blood; this overrides the GDD's "no screamer" line
(owner, Nov 10). D-077's jerk, half-dark and fade is replaced on the caught screen; the server's
catch is unchanged but for the timing below.

As built, on the caught player's screen only (CaughtLunge, run by CaughtView; every number in
`Caught`): its hand closes and the hall goes silent (SoundService's listener moved a million studs
off, so only your own sounds play; the chase music already cuts itself), every other screen is put
away, and your view is taken (Scriptable) and wrenched round to its face in 0.12 s with a kick
(0.55). The real body is hidden on your screen and a copy from the template stands in its place in
the same stride (its joints' `Transform`s copied), lit faintly by a light hung before its face.
It holds still for the dread (to 0.48 s) while your view tunnels in to 86% of its width. Then it
snaps into a lunge pose (arms out wide and low, clawing in from either side, head cocked over) and
its head flies at your eye, a twitch back and then ever faster (0.32 s, `reach`: u²((k+1)u − k),
k 0.8), the body hanging off it (`Mannequin.head`), while the view crash-zooms to 48% of its width
and the light on its face comes up. On that first frame of the rush: the scream (Pro Sound
Effects' "Creature Screech Pterodactyl Vocals Screams 1" at 0.8 pitch, volume 2.4, the loudest
thing on a phone), APM's "Razormorph K" (a huge hit, mostly for headphones, ringing into the black)
and "Whoosh Fast Swish By 5" (rising to its peak as the face lands), with its own body's groan and
scrape (the row's new Lunge beat). It lands 1.5 studs from your eye, taller than the screen, with
its hollow thunk and weight (the Catch beat) and the hardest kick (1.0) plus a knock that yanks
your view toward it, tips it and rolls it; it presses in to 0.85 studs for 0.16 s, your torch out
of sight; then the screen is cut to black at 0.96 s (`Dark`, when the server moves you; was 0.4),
the copy gone and the view yours again. "Caught" comes up a beat into the black while the film
screeches round you (your own squeal now waits for the black, so the dread is silent), 1.25 s.
You come to over 2.2 s: your eyes crack half open, drop shut, then open, the view blurred (22) and
grey (−0.75) clearing evenly, the hall's sound back as they first open. The whole wrap is 4.4 s
(was 2.1).

Friends see the film go on: the server now wraps you at the catch where you stand (stamped
`Kept.WoundAttribute`), not in the black, and every other screen hides the real film and winds a
copy on from the feet, clouding in, while your body turns once round on that screen only, as a
pallet wrapper's turntable spins a load (`Kept.wind`, KeptWrapOn); the moment the server moves you
it stops and the real film shows.

Not chosen: the stock chase sting (already "it sees you"; the catch has its own); "Shock Chord",
"DS Horror Stinger" (their attacks ramp over 0.2 to 0.6 s, no startle), the other APM stings
(mostly under 190 Hz, silent on a phone); the face at 0.7 studs (only its dark surface showed,
read as the screen going black); raised arms (they covered its face mid-rush); a knock that shoves
your view back (its face shrank just as it should press in); fading to black (a cut is the blow);
the wake's haze clearing as a square (gone before the eyes opened). A Studio-only hold
(`DevCatchHold`) stops the catch's clock on every screen to look at one frame; it's how the frames
were judged (docs/STUDIO.md, "Testing the catch from the MCP").

## D-103 The ride: a still car, a sliding shaft, the counter turning over (L-08a, Nov 11)
The moment: the breath between floors, as Dandy's World's elevator carries the team between its
floors. Relief as the car takes you, then dread as the readout turns over to the floor you're
about to face and the next landing's dark mouth slides down level with you.

It runs on the server's clock, as the gate's does (D-046). The instant the shut gate hits its post
the server writes one replicated value on the elevator (`Ride.Attribute`: that moment, the floors
from and to), just before who rode (`Aboard`); every rider's screen draws the whole ride from it,
and the server folds the gate open on its own clock (`Ride.opens`), firing `arrived` as the car
levels. Timeline (seconds after the gate hits its post; every number in `Ride`): the car sits 0.8
s, its brakes let go, it gathers speed over 1.8 s on a cosine S-curve, climbs 4.6 s at full speed
(2.4 studs a second), slows over 2.4 s and is level at 9.6 s; the gate starts to fold at 10.3 s
(open at about 11.9 s). One floor is 16 studs.

The car never moves. Moving a car with characters in it jitters on Roblox and the owner's line is
that the ride never jitters the camera. Instead each rider's screen lays a thin sleeve of shaft in
the 0.09-stud gap between the landing's frame and the car's front (`Ride.Shaft`, RideView) and
slides it down past the gate: the hall you left goes black over 0.3 s as the brakes let go (under
the lamp's dip, so you see the light fail, not a fade), its header beam, lamp-lit concrete with
two formwork seams and the next floor's number painted on it, the next landing's apron and bright
sill, then its black mouth, level with you; that black lifts off the real hall over the 0.7 s
before the gate folds. The car's lamp prints the gate's lattice on the sliding wall.

The motion is held on the camera (CameraShake's new `hold`, read each frame under any shake): the
lurch (the car drops 0.08 studs on its cables and springs back at 1.8 Hz, eased out of rest over
0.05 s so it's a shove, never a snap), your weight sinking as it pulls and floating as it slows
(0.03 studs per stud/s²), two cable clanks (0.02 studs, a single damped knock each), a slow roll
and nod at full speed (0.12° and 0.07°), the bob as it levels. No noise is ever added. Lune holds
it to 0.15 studs and 0.6° at most, and no frame (at 60 a second) moves more than 0.012 studs or
tips more than 0.05°.

The counter: an amber LED readout over the gate inside the car (two digits and a stepped arrow,
drawn on a card on the fascia like the keypad's), lit at rest with the floor the car stands at
(`Ride.FloorAttribute`), the arrow lit while it climbs; and the gate clock's plate in the top bar,
which turns from the clock's 0 to the floor in the same amber for riders. Both tick over to the
next floor as the brakes start to bite (7.2 s), with a relay's click, so the new number is the
first sign of what's coming.

Sounds, on riders' screens only, flat (you're inside the box), from Pro Sound Effects and measured
(docs/STUDIO.md): "Freight Elevator 3"'s brake release (its clunk at 1.13 s lands as the brakes
let go) and stop clunk (15.15 s, lands as it levels); "Conveyor Belt 5"'s clanky motor, the part a
phone plays (nine tenths of it 190 Hz to 2 kHz), its pitch 0.82 to 1 and volume following the
speed, handing over to its own winding-down (its stop at 13 s lands as it levels); "Freight
Elevator 2"'s deep run under it for headphones; the motor's start knock pitched down for the
clanks; the unit lights' toggle for the relay; the elevator's own bell (the right code's
double-ding) at 0.84 pitch as it levels. The car's lamp dips to 0.3 as the brakes let go with one
more flicker, a little at each clank, to 0.6 as they bite at the top (ElevatorView, riders only).

Until L-08b lays the next floor, the car arrives back at the same lobby, its number one higher;
`Ride.Linger` (6 s) after the gate opens, DevCorridor arms it again with the same code, the gate
shutting behind the team. The stand-in ride's fade to black and teleport (D-046) are gone. L-08b
hands riders over mid-ride: it writes the same ride on the next floor's car and moves them; a
rider's screen follows whichever riding car holds them.

Not chosen: moving the car and its riders (physics jitter); a fade to black (the old stand-in, a
cut, not a ride); a landing door that parts (no art for it, and the lobby has none); camera noise
for the shudder (the owner's jitter line: the clanks and the sound carry it); counting through
several floors (one floor per ride); a second plate for the counter (the clock's plate is where
eyes already are). A Studio-only hold (`Ride.Hold`, Workspace's `DevRideHold`) stops every ride
where it is, on the server and every screen, to look at one frame.

## D-104 The climb: the next floor laid ahead, riders moved on the cable's knock (L-08b, Nov 11)
The moment: the gate opens on a floor nobody has seen, and the one below is gone, as each of
Dandy's World's elevator stops opens on a new floor. A server system, `Climbs`, runs it: the
smallest stand-in for Brix's round loop (ENG-13, unbuilt), floors only, no lobby or results.

Each floor has its own seed (`Climb.seedOf`: floor 1's is the climb's, each one above the seed
plus a large stride), because one seed for every floor laid floor 2 as floor 1 again, its units
numbered 2xx. `scripts/floor-map` and `floor-deal` use the same rule, so `floor-map 7 2` prints
the floor 2 the game lays. Floor 1 of every seed is unchanged; floors above 1 of a seed differ
from what those scripts printed before today.

Each floor is laid at its own spot, 1000 studs on from the last along -Z (`Climb.Spacing`): two
floors' nearest halls stand at least 792 studs apart over 600 Lune-checked floors, far past the
256-stud streaming radius, so a phone near one never holds the other, and nothing left on a
cleared floor can show up on a later one. The next floor is dealt and laid as the right code
opens the gate (30 s before the car can leave), not as the car leaves: laying took 0.3 to 5 s in
Studio, and the hand-off can't wait past `Climb.Latest`. It waits there with nobody on it;
keepers wake only as its doors open. Laid during play, a floor once held the server 160 ms in one
frame because a hall piece entered the game with all its units at once; each unit now joins its
placed hall piece as it's dressed (peaks of 5 to 9 ms).

The hand-off. The car never moves (D-103), so riders change cars. `Climb.Lead` (0.5 s) before
the move the new floor's car takes the ride over (`Elevators:takeOver`: the same `Ride` and
`Aboard` values, the old car marked done), after the server asks each rider's screen again to
stream the new lobby (`RequestStreamAroundAsync`, waited on: a long hold let it go once). Every
rider's screen lays a second shaft outside the new car, sliding in step (RideView), so whichever
car a frame draws you in, the gate shows the shaft; the older one goes once you've stood in the
new car 0.3 s, and a ride with no shaft at all is let go after 1.5 s. On the cable's second knock
(6.1 s, `Climb.HandOff`) the server moves every rider to the same spot in the new car (turned with
it if it faced another way) in one frame, so friends arrive together, and clears the floor below
in the same frame: whoever's still on it goes to the spawn (L-08c makes them watch), its tools go
with it. The move costs a screen a long frame (0.16 to 0.4 s in Studio at 15 frames a second);
on the knock, under the clank, it reads as the jolt (cut on the bump, as film cuts on action).
Measured in Studio across the hand-off: the camera moved 0.006 to 0.008 studs and turned 0° in
the car's frame on the switch frame, the shaft never jumped, no frame lacked a shaft.

The car leaving empty, from the top floor, or before the next floor is ready comes back to its
own lobby and is armed again for the same floor; a next floor already laid waits for the next
time it leaves. The new car's gate shuts `Ride.Linger` after it opens, armed with its floor's code.

Not chosen: laying as the car leaves (the ticket's first plan; too tight when Studio took 5 s);
one seed for every floor (the same layout); floors stacked up the Y axis (they'd stream
together); the client moving its own character (no snap if walking, but a friend would vanish
from your car for a round trip); clearing the floor below a second after the move (a second
long frame, uncovered); a fade to hide the move (D-103's line: the ride never cuts).

## D-105 Left behind: the sting, then a friend's shoulder until you're back in (L-08c, Nov 11)

The GDD's "Left behind": when the gate shuts, anyone still kept or still on the floor is out of
the climb, and watches the team until they finish, or Cut Free back in on the next floor (DOORS'
rule: death ends your run unless you revive). Watching is Lethal Company's: the dead crew watch
the living from behind them.

Who's left. As the car leaves with someone aboard (a player, or in Studio a stand-in friend),
everyone else whose feet are on that floor, in the halls or kept in a unit, however far from the
car, is marked (`Left.Attribute`, the server time the car left). `Elevators.departed`'s `left`
only names those within the clock's 240 studs, so Climbs checks the whole floor itself. A ride
that comes back after all (the next floor late, the takeover refused) un-marks them. The car
leaving empty, or from the top, leaves nobody behind: it comes back (L-08d's to end).

The sting, on their screen, timed off the ride's clock: "Left behind" slams up in a cold red with
the gate's clang (it was GateClock's headline; one place owns the moment now), the screen dims
behind it and its top and bottom darken over the HUD like a cutscene's bars; the car's lamp draws
away up the shaft (ElevatorView, unchanged) while its motor groans and fades above, muffled by
the building; as the light goes (1.6 s) a low hit lands with a jolt and the controls go, the play
HUD with them; the black comes down whole by 5.5 s, before the floor is cleared under you at 6.1
s; the bell rings far above under the black at 9.75 s; the black lifts on a friend's shoulder as
their car levels, and the gate folds open on the new floor without you (10.3 s).

Watching. At the hand-off your character is taken away (`Player.Character = nil`, destroyed; no
respawn follows) after what you carried drops with the floor, so nothing can hurt, see or prompt
you and the play HUD has nothing to show. Not parking the body somewhere: every system would
have to learn to skip it, and a parked body still streams, shows on maps and can be reached. The
server streams the world around the friend you watch (`ReplicationFocus`), and names them in a
`Watching` ObjectValue (nil on your screen until they stream in; the name rides as an attribute so
it shows at once). The camera is the game's own: behind the friend's head and over their right
shoulder, looking a little down, its spot and heading eased toward theirs at any frame rate (so
steps and network jitter never shake it), pulled in short of any wall behind them at once and
easing back out, a cut when they jump more than 25 studs (the move into the next car); drag, the
right mouse button or the right stick swings it round them. Not Roblox's own camera on their
humanoid: the place is locked to first person, and that would put you inside their head. While
you watch, every car is drawn as its riders see it (the lamp the ride's, not drawing away), so
the friend's car is lit as you arrive on it. The bar at the bottom (in the phone's safe area, big
round arrows) says who, how you get back in ("Back in when they finish"), and switches with a
tick, a dip to black, and a lift once the next friend has streamed in (0.08 s for the server's
answer in Studio). The server checks each watcher four times a second: a friend gone, left or
respawned is followed to the next.

Back in. Cut Free is a developer product in the GDD (40 to 55 Robux, DOORS' revive). The product
doesn't exist yet and there are no saved profiles to grant it after, so only Studio takes the ask
(a "Cut Free" button over the bar); `OWNER.md` has the product and price to decide. A let-in
waits for a floor to stand on (not between two floors mid-ride), loads a new character in the
lobby in front of the car facing the hall (`Climbs.Arrival`, where "Walk a floor" put you), and
the black lifts on it with the film's rip and "Back in" in the lamp's warm light. With nobody
left climbing to watch for 3 s, everyone watching is let back in the same way: a stand-in until
L-08d ends the climb.

Verified in Studio (seed 7, two stand-in friends in the car, the player left in the lobby): three
rides (1 to 2 twice, 2 to 3), held frames and real time; the sting's log matched its timeline (hit
at 1.64 s, character gone on the move frame at 6.1 to 6.6 s, camera on the friend at 9.12, clear
at 10.18, bell 9.79 to 12.59); the camera moved at most 0.003 studs a frame on a still friend;
switching, Cut Free into floor 2's lobby, a friend removed (followed to the other) and both
removed (let back in after 3 s) all worked; Output clean but the known asset line. Captures:
`docs/art/L-08c-*.jpg`.

Not chosen: the default camera on the friend's humanoid (first person inside their head); parking
the body under the floor (every system would need to skip it); fading to the friend at the move
(6.1 s: their car would stand shut and still for 4 s); a free Cut Free in live games before the
product and profiles exist.

## D-106 The climb ends: a wipe, the top, one screen and "Again" (L-08d, Nov 11)

The GDD's "Whole team kept": the climb ends. Gate 1 is friends asking for another run, so the end
is one screen saying how far you got and one button, "Again", as DOORS' Play Again does.

When it ends. **Kept** (a loss): nobody left climbing, every player kept in a unit or left behind
watching (`ClimbEnd.over`; in Studio a stand-in friend counts as climbing, so the L-08c recipe
still works). The server looks ten times a second and ends it `Caught.Dark` (0.96 s) after it
first sees nobody climbing, so the end lands on the last catch's cut to black. A watcher's Cut
Free can't save a wipe: with nobody left to watch, there's nothing to cut back into (`OWNER.md`).
**Top** (an escape): the car leaving the top floor with friends aboard (`Climbs.topped`). The top
is a stand-in, floor 3 (`Climb.Top`; `Climb.Building` stays 10), so a run is short enough to play
again; Phase 2's top floor replaces it. Everyone left on the floor is left behind as at any floor
and loses their character on the cable's second knock, as at a hand-off. The empty car still
comes back; the "Alone" let-in of D-105 is gone (the end replaces it).

On every screen, from one server time (`ClimbEnd` on Workspace, each player's `ClimbFate` written
first): a wipe's black comes down over 1.2 s (no later than the caught friend's eyes would open in
the unit); at 1.3 s the server clears the climb (`Climbs:finish`: threads, the tools lying on its
floors, the floors; `Watching:release`; every character taken away, so nothing reaches anyone
behind the screen) and every screen goes quiet: the listener is taken far away, as the catch
silences the hall, and held there each frame (the catch's wake would put it back); a beat of
nothing; two doors come down far off in the building (the roll-up door's bang and thump, pitched
low, the top end cut, a long reverb tail); "Kept" slams down in the cold red of "Left behind" from
1.28 times its size with the dread hit and a jolt; the photos drop in one by one, greyed and
pinned askew, each with the floor it was lost on; "Floor 2 · 6:42"; then the warm "Again". An
escape plays the ride untouched until the cable's second knock (where any other ride hands over),
then light floods in, slow and then all at once, whole by 7.4 s, when the climb is cleared and the
motor goes with it; the bell rings clear in the white; it settles into a warm dark and "Made it"
rises in the lamp's light, the riders' photos in colour. The photos are the GDD's Missing board in
small (avatar headshots, preloaded as the end starts); the board itself is the lobby's.

"Again": a press beeps, squashes the button and reads "Waiting"; each friend who is in warms
their photo back to colour with a tick on every screen; the first press starts "Going up in 10"
everywhere, and the next climb starts when everyone's in or the count runs out, so one friend who
wandered off never holds the rest (as DOORS' lobby elevators start counting down once the first
player steps in).
It goes with the elevator's chime and "Going up": a fresh seed, floor 1 laid at the last climb's
spot, everyone's new character side by side at `Climbs.Arrival` (the middle first, then either
side, 3 studs apart), then the end is cleared; each screen lifts the black off its new character
with the bell and "Floor 1". Where it leads is one function (`ClimbEnds.go`), for the owner's
lobby to replace. Enter, Space and a gamepad's A press it too.

The screen is two ScreenGuis over everything (50 and 51): the backdrop with no insets, the words
and button in the phone's safe area. It draws nothing (and sinks no touch) until the end shows
something, so a rider's controls answer through the ride. The title is sized from the screen's
height (never past 96 px), not scaled to its box: scaled text stops at 100 px, so the slam's
UIScale couldn't grow it on a big screen.

Verified in Studio (one player, seed 7): a real catch by 157's Mannequin ended the climb (Kept,
floor 1, 0:26), the character went under the black, the screen held its frames on the Client's
`DevRideHold`; "Again" by mouse and by Enter each laid a fresh floor 1 and lifted onto it with the
character at the arrival spot; floor 3 punched and ridden alone ended in the white (6.1 to 7.4 s
logged), "Made it", 1:30; left behind watching two stand-ins who were then removed ended as Kept
with the team on floor 2 and your photo on floor 1, the watch let go under the black with no
"Back in"; after each Again, prompts, camera, field of view, walk and sound all back; a saw
carried into the lobby dropped at the end and went with the floor (the new floor 1 had none);
Output clean but the known asset lines. Captures: `docs/art/L-08d-*.jpg`.

Not chosen: ending the climb when the car leaves empty (nobody chose to leave anyone); a vote
with no count (one absent friend holds everyone); keeping the floors until Again (keepers, the
padlock's dread and the ride would sound behind the results); the results over the world (a
character left standing there can still be caught); a fixed seed for Again (each climb a new
building, as DOORS' rooms are).

## D-107 Keepers hear the rest: every loud thing, a shut door muffles, a new sound stops it (L-15, Nov 11)
The moment: you punch the keypad, drop a tool, saw, crawl, put up the ladder or drop into a unit,
and somewhere down the hall the limp you were hearing stops dead on one deep thunk, and then comes
your way, as Lethal Company's Eyeless Dogs stop and turn to a noise before they come. Noise is a
choice with a price.
**What's heard, as far as players hear it** (one world, D-069): the keypad's beep and clear (30),
its chime (60) and a wrong code's alarm (400, every hall on the floor) from `Elevators.acted`; a
dropped tool's clank as it lands (`Carry.DropHeard` 40, the reach its sound already had; `Slots`
now fires `landed`); the saw starting (200) and its panel falling (a wall's 110, a top's 200) from
`Saws.sawing`; a crawl through a hole (35) from `Crawls.crawled`; and from `Ladders.climbed` the
ladder going up (60), climbing it (30), a crawl along the tops (30, every other pull), a drop off
a top or into a unit (45). `Keepers` listens to each signal, as it does `Doors.acted`, and calls
its one hearing (`hearAt`, `Keeper.heardAt`). A wall's hole is heard from the side it's sawn or
crawled from, a stud into that unit. Nothing is ever knocked flat yet, so that noise waits.
**Where it's heard from** (`Keeper.heardFrom`, Lune-tested): a sound in a hall, in a unit whose
door is all the way up, or in the unit the keeper stands in is where it is, as before. One up on
a unit's top (more than `Keeper.OnTop`, 8.5, over its floor) carries out over its front: heard
from that unit's door, its reach less the way to the door. One in a unit whose door is down gets
out through the door the same way at half its reach (`Keeper.Muffled`), as Lethal Company halves
noise made inside the shut ship; the keeper comes to stand outside the door and look at it, and
can't get in. Before, no sound got through a shut door (D-069, D-087), which made the saw, the
crawl and the drop-in silent wherever the door was pulled down: pulling a door down now buys
quiet, not silence. A keeper inside a shut unit still hears nothing from outside (a sleeper stays
asleep), and a horn blown on the tops is now heard from the hall, not the unit under you.
**The reaction** (`Keeper.hear`): a sound new to a keeper (not within `Keeper.Same`, 12 studs, of
the one it's already going to or looking at) stops it where it stands for its row's `startle`
(the Mannequin's 0.8 s, about two missing steps of its limp), turned to face the sound, then it
walks there at its looking pace. The same noise going on (a code's presses, a crawl's pulls, the
blows on a door) turns it toward the newest spot without stopping it again. The server stamps the
moment on the body (`KeeperTell.HeardAttribute`) and every screen plays its new Heard beat as it
shows the stop (`KeeperMotion.Delay` behind): the hollow Shell thunk at 1.7 and pitch 0.78, its
Weight, and its Creak at 1.4 groaning round. Far off only the thunk carries (to 70); within 32
you hear the groan too. Verified in Studio: the full chord at 30 studs, the lone thunk at 67.
**Output** says only news: "heard a wrong code's alarm 69 studs off along the halls; it wakes,
turns to it and goes to look", never once a pull. A trapped keeper prints one line as it's shut
in ("bangs on the door until it bursts out at 90 s") and none a blow; the padlock's last blow and
the burst still print. A crawler's feet, as the pops read them, are on what they lie on
(`Wrap.feetBelow`): from a tall avatar's hips they'd have read past `Wrap.Under`.
Not chosen: a faster walk when going to a sound (it would shrink D-069's seven seconds to get
behind a door; the stop says "it heard" without taking your time); silencing sounds behind shut
doors (the ticket's crawl and drop-in would never be heard); a voice (a mannequin has none).

## D-108 In hand and caught: the fix pass before friends play (L-16a, Nov 11)

The moment: the bugs a friend would hit in their first run with you. Each fixed at its cause.
**A friend's torch arm now rises.** The players' shoulders, elbows and wrists here are Roblox's
newer avatar joints (`AnimationConstraint`), not `Motor6D`s; FlashlightView looked only for
`Motor6D`s, found nothing, and never raised a friend's arm. Five views had their own copy of the
lookup, so one new client module, `Joints` (`find`, `get`, `set`, `bend`), now finds and turns
either kind for all of them (FlashlightView, HornView, CrawlView, LadderView, KneelView). Checked
in Studio on your own body: all three right-arm joints are AnimationConstraints, and the raise
lifts the hand from 0.95 below the root to 0.86 above it. A friend's arm needs two players.
**Caught mid-crawl or on the ladder, you're let go at once.** Before, nothing ended a crawl or a
climb at a catch: the server's Ladders lifted a caught climber onto the tops when the climb's
time ran out, then put them back there every check while KeptPlayers held them in their unit;
Crawls put a caught crawler through the hole; and the caught screen kept PlatformStand and moved
an anchored body the server no longer listened to. Now a kept player's climb or crawl ends on the
server that step (`Prompts.wrapped`), and their screen lets go of their body the moment `Kept`
goes on (LadderView, CrawlView: standing again, their own collision), never taking it over while
kept. The crawl's scripted camera is left to the catch, which takes it that frame (CaughtLunge)
and hands back your own camera at the black, not the crawl's. Verified in Studio both ways,
through a new Studio-only `ServerStorage.CatchTest` (the standing keeper nearest you catches you
through the real catch): caught 9.6 up the ladder and 1.3 s into a crawl, woken in a unit, then
cut free by a stand-in and walking 7.2 studs in 0.6 s.
**G at an open door is Slam.** G was both a door's Slam (a ProximityPrompt key) and the tool's
Drop (ContextActionService), so at an open door it did both. The slam is the moment, so while a
button in the world that takes the same key is up, ToolView's Drop passes the key to it and the
tool stays in your hand; anywhere else G drops as before. Verified in Studio: G at 102's open
door slammed it with the horn still held; G with the door shut dropped the horn. Not chosen:
moving Drop to another key (G is where Lethal Company players reach for it, and the slots' bar
says G).
**A click on a button on screen is never a use.** HornView's use (every verb tool's) took any
left click, so clicking a slot, Drop or its own button blew the horn or laid wrap (and its own
button used it twice). It now asks what's under the click (`PlayerGui:GetGuiObjectsAtPosition`,
which takes a click's `InputObject.Position` as is and skips hidden screens): on an active
button, the click is the button's. Verified: a click on slot 1 with the horn held blew nothing,
one out in the world blew it.
**Every recording is primed.** DoorSounds preloaded its sounds but never gave them the silent
first play (`SoundPrimer`, docs/STUDIO.md), so the first slam's bang could land a third of a
second late; the motion lights' click, a unit light's click and hum, and a peek's rustle had the
same gap. All four now prime at start. Tonight's Studio started even never-primed recordings on
time, so the late start wasn't seen again; the owner's ear on the first slam is the check.
**Output at Play.** KeeperView gave up for good on a keeper body it got before all of it had
arrived ("can't move ... Mannequin": seen once as the guard in 157 stood), leaving that keeper
frozen on that screen. It now waits for the rest (its row, its root, its joints) and binds then,
warning only for a keeper it doesn't know; and the server finishes a body (streamed whole,
its row, its first motion, its tag) before it goes into the world. The race didn't come back in
Studio either way, so this is belt and braces. `ContentId 203785492 ... Asset type does not
match` is Roblox's "Pop Close Sound", requested as something else by Studio or a plugin: it is in
neither the place (about 18,000 instances searched, Roblox's own interface included), the repo
nor Brix, and nothing the game does can silence it. 120448020095820 ("content representation is
being generated") is the kept wrap's colour map in the place, still being processed after its
upload; it didn't show in tonight's Plays.

## D-109 The test hall runs on live servers until the lobby exists (Nov 11)

The owner published the place to play it on a phone and got only the baseplate. Nothing was
missing from the upload: the code and the imported art were all in the place. The test hall
(`DevCorridor`) ran only when `RunService:IsStudio()`, and its "Walk a floor" post is the only
thing that starts a climb (the "Again" after a climb's end restarts one, but only once one has
run). So a live server, or a Team Test, built no hall, laid no floor and kept Roblox's baseplate
and spawn pad. It now runs on every server, so a published place plays exactly as Studio's Play
does: the hall, its test posts, "Walk a floor", the climb. The Studio-only test tools stay
Studio-only (stand-ins, `CatchTest`, the ride hold, `DevFloorSeed` and `DevFloorNumber`, which
no live player can set), so a live climb starts on seed 7, floor 3. Its posts (teleports, a
Mannequin on demand) and the floor's code in the server log are fine for a private test place
and wrong for a public game: the lobby (L-08e) replaces the hall as the way in on live servers,
and the hall goes back to Studio only, before the game goes public. Not chosen: a bare live start
that lays floor 1 and drops players in its lobby, which is the lobby's design (L-08e) built
early, and would differ from what the owner tests in Studio.

## D-110 The crawl glides as a walk does; a hand doesn't reach past a shut door (L-16c, Nov 11)

From the owner's Nov 11 play. **The tops:** "the view jerks all around repeatedly... It should be
just as smooth as moving on the normal floor." Recording every frame in Studio found the causes
in the steering itself, not in a check. First person's camera sits 1.5 studs up your lying body
(Roblox's head offset over the root), and `Tops.step` turned the body about its root toward your
push at 200° a second, so every turn of the mouse swung your view sideways at up to 5 studs a
second; you all but stopped (`cos` of the angle left) until the body came round; and each pull
surged your speed ±55%, a lurch twice a second. Now the body turns about your eye (`Tops.Eye`),
falling back to its middle and then the old squirm only where that won't fit; you move where you
push at once, slowed only with more than a quarter turn still to go; the surge is ±10% and the
head's dip and sway half what they were. Your view moves exactly as walking's: where you push,
turning in place. The server's crawl check allows for the hips swinging round the eye. Looked at
and cleared: the map and hole lookups (hundredths of a millisecond), physics (one assembly, every
joint kinematic), the server's put-backs (none in Studio; a live server is the owner's test).
Kept: turning rate, crawl speed, the pulls' sounds and arms (they run on distance crawled, which
counts the crawl alone, not the turn's swing).

**Reaching through a door:** a tool's Pick up showed through a shut door (it ignores line of
sight so boxes can't hide it), and a peek's crack was enough to take it. `ShutIn.reaches`: a hand
gets past a door only with both on one side or the door up at least half its opening
(`ReachShare`); `RollUpDoor.keepsApart` applies it to a unit, the server refuses such a pick-up
(`Slots`) and your screen hides its prompt (`BehindDoors`, five times a second). Shut in with a
tool, or crawled in through a hole, you still reach it.

**The floor's flicker:** a hall junction's concrete runs on under the front of the units round it
at exactly the unit floor's height, so the two drew over each other as the view turned. The
unit's drawn floor now sits 0.03 studs up (`FloorBuilder.unit`); its collider stays, so feet and
dealt things stand where they did.

## D-111 Landings bend the knees; nothing slides you over a hole; the door below is off the tops (L-16b1, Nov 11)
The moment: up on the tops with a friend watching, you drop off a front or in through a sawn
hole and land in a crouch, feet on the floor, and nothing up there takes you across a hole or
opens the door under you.

**The landing.** Both drops end in a crouch (`Tops.Squat`, 0.7 studs). Your body is PlatformStand
through the move, so Roblox's Animate stops every track and the legs hang straight: the whole
body went down and the feet into the floor, 0.63 studs at the deepest (Studio, default avatar),
on every screen. Now `Tops.landDip` says how deep the crouch is at each moment of either drop,
and `Tops.crouch` turns the hips, knees and ankles so each ankle stays under its hip on the
floor and the foot flat. LadderView bends every lander's legs (yours and friends'), each leg's
length read from the avatar's own rig attachments. Verified in Studio: with the knees bent the
feet stayed where they stood at 0.4 and 0.6 down. Rejected: dropping the body's dip and keeping
the crouch in your own view only, since friends would then see a stiff landing.

**Behind a hole.** Climb down and Drop down each start by sliding you from where you lie to the
move's start (the spot by the ladder, the front's edge). Lying behind a sawn hole, in reach of
either, that slide went straight over it. The server now ignores the press when the straight
slide would take your body over a hole (`slideClear`, `Tops.pathClear`). No refusal words (owner:
"it's common sense"); hiding the buttons there is in ROADMAP's polish. Rejected: a slide round the
hole, a long detour for a half-second move.

**The door below.** Lying at a front's edge your head is over it and the door's buttons are 7
studs off (their reach is 8), with nothing between: a crawler saw Open, Slam and Peek. The server
ignores a crawler's door press (`Doors`, `Ladders:crawling`), and your screen hides every door
button while you lie up there. Buttons were already hidden two ways, each fighting the other:
the server switches `Enabled` as a door moves, and ToolView zeroes a button's reach unless the
right tool is in hand. `ButtonReach` (client) now hides a button by its reach for any number of
reasons at once; ToolView ("Hand") and LadderView ("Tops") each say theirs, so a padlock in hand
can't bring Lock back while you lie up top. Door buttons carry `Door.ButtonTag`. The ladder's
foot buttons are 12 studs from a crawler (reach 6), and the server already ignored Climb, Take
and Lean from anyone on a climb.


## D-112 The lobby: DOORS' elevators, a shop at the counter, a cart to ride (owner's plan, Nov 11)
The moment: you spawn in Everkeep's front office facing six freight cars, step into one with your
friends, kick a cart around while the count runs, and the gate slams on the zero.

**The plan is the owner's** (Nov 11): a realistic storage entrance, elevators as the servers, the
counter as the shop, ridable push carts. Written into the GDD ("The lobby", "Monetization") and
split into L-08e1 to L-08e4 plus Phase 2's store. Research behind it: the October teardown and
hit-game reports in the owner's other projects, the GDD's store table, Roblox's docs read Nov 11.

**What earns, in order.** The rating first: Roblox's fear guide counts jump scares, creepy NPCs
and suspense as mild and keeps moderate for realistic blood and wounds, so staying bloodless
keeps the game Mild, which reaches Roblox Kids and players who never age-checked. Then days 8 to
28, which the ranking now rewards over quick spending. Then friends (co-play days rank; Roblox
pays 35% of a new or returning player's first $100 if they came on a share link), so Invite sits
on the car's panel. Then the shelf, kept small: 99 Nights ranked #10 by earnings with 28 products.

**Rules.** Robux never sit beside a timer: the car's Bring slot takes cash only, and Robux live at
the counter and the kept view. Once cash packs exist nothing random is sold for cash either,
since Roblox counts currency bought with Robux; the daily sealed lot stays free. The starter pack
shows after your first climb. A purchase must survive a failed save and a server hop before
launch, and every offer can be switched off without an update.

**The cart is a lobby ride** (owner: "definitely"), not the dolly. The owner, Nov 11: the climb
is an escape, not a haul, so the dolly in the levels is a maybe and nothing builds it until the
owner says. Rejected: one cart shared by the lobby and the levels, which only paid if hauling
finds was the loop. Riding an empty dolly in a level, fast but loud, would be an untested bet.

**Open, defaults in place (`OWNER.md`):** six slots for sale (four suggested), a clerk at the
counter (default none), a double-cash pass (default not at launch).

## D-113 A press on arrival counts everywhere; a hidden button stays remembered (L-16b2, Nov 11)
The moment: you sprint at the ladder and press Climb, or into a unit and press Saw at its wall,
and it works first time.

**Measured first** (Studio, a full run of 16 studs a second, the press made the instant the
button showed). The server saw the run 3.5 to 4.3 studs late (0.22 to 0.27 s), as D-085 found for
Crawl. Climb, pressed 5.8 studs from the ladder's foot, reached a server that saw you 9.2 off
(its reach 6 plus 3 slack): dropped, and you stood at the foot with nothing happening. Saw,
pressed just inside Unit 101, reached a server that still saw you out in the hall: dropped. Lean
(carrying the ladder at 12) landed, 2.3 to 2.8 studs late, on its 3 studs of slack: a live
server's longer ease would tip it over. A door's reach has 4 studs of slack and held.

**One pure helper, `Arrival`.** A press is judged where the server sees you, then at four moments
out to 0.4 s on at the speed it sees you moving; the first that passes counts. Several moments,
not only the last, so running past a button can't step over its reach. The check is given
seconds, not places, so the server's Vector3s and the pure modules' vectors use it as they are;
`ahead(i)` serves a check run every frame without making a closure. Used by `Crawling.counts`
(D-085's two places become this), every reach in `Ladders` (Lean, Climb, Take, Climb down, Drop
down), its hole check (`slideClear`) and Drop in, `Saws` (the press and every frame of the cut,
or the cut stopped the next frame while the server still saw you in the hall) and `Doors` (reach,
and the side for Lock and Cut: sprint out under a closing door and Lock it at once, and the
server may still see you inside; the first moment whose side lets it happen counts, else the
answer where it sees you). It gives a cheat nothing: your screen already moves your character.
A crawler's body is moved by setting its place each frame, which carries no speed to the server,
so `Ladders` measures it from the crawl check's last two places (`moving`). Rejected: more slack
on each reach, which lets a standing player press from further away; judging from your screen's
reported place, which a cheat writes.

**Verified in Studio** (one player): Climb on arrival counted with the server seeing you 9.45
off; Saw on arrival began with the server seeing you in the hall and the hole went through; Lean
counted. Lying behind a sawn hole, Climb down and Drop down were still ignored, and the same
Drop down from a clear spot at that depth dropped you (L-16b1's checks).

**`ButtonReach` without weak tables.** L-16b1's door buttons stayed hidden after climbing down
off the tops, on every door. `ButtonReach` kept each button's reach in a table with weak keys;
Roblox lets go of a weakly held Instance's entry while the Instance is still in the world (163
buttons in such a table, none left after a garbage pass), so the reach was lost and taken again
as 0. It now remembers only hidden buttons, in plain tables, and forgets one once nothing hides
it or it leaves the world (its reach put back, so a view still hiding it does so again as it
streams in). The elevator's gate cache has the same kind of table: it only rebuilds itself, so
it's listed, not fixed here.

## D-114 One look for every button in the world (L-19a, Nov 11)
The moment: a button in the world is a small, sharp key chip with its one verb beside it, there
the instant you're near and gone without a trace; on a phone a clean thumb target that never
covers the hall. The owner's "prompt updates" (Roblox's grey box "takes up too much space on
mobile... look modern and world-class").

**Roblox still decides, we only draw.** Every ProximityPrompt is made with `Style` Custom (the
server's `Prompts.make`, and the client's own: the keypad's Use, a note's Read, a friend's Give),
and one client system, `ButtonView`, draws each one Roblox shows (`PromptShown`, `PromptHidden`,
its holds and presses). So reach, sight lines, one-per-key and every view that listens to
`ProximityPromptService` (ToolView's G, HornView's click, KneelView's Peek) work as before. The
look's numbers and motion are pure, in `WorldButton` (shared, Lune-checked).

**The look.** A round chip (38 points on a computer with the key in it, from
`GetStringForKeyCode`; the pad's own button picture from `GetImageForKeyCode`; 48 on a phone with
only a dot, as Roblox's torch and jump buttons are, its target 8 points wider all round), the
verb beside it in the game's ink (BuilderSans Bold 20, a dark edge so it reads on any wall), no
box. The chip sits a fixed 30 points left of the button's point, so a chip and a short verb sit
centred on it and longer words never move the chip; `UIOffset` keeps spacing a door's row. It
swells in over 0.12 s with a spring and goes in 0.08 s; a hold fills a ring round the chip
clockwise from twelve (Roblox's own ring picture, two clipped halves), as Fortnite's
hold-to-interact ring does; a press pops it with a flash of light in the chip.

**A name only where it's news.** Made without a name: a door's buttons (the number is painted
on it), the ladder's, Lean and Drop down. Kept: Drop in (which unit, unseen from up top), Crawl
and Saw (which unit lies behind the wall), Pick up (which tool), Cut free (who is under the film),
Give (which friend), the test posts. A padlocked door's buttons are named "Padlocked": news
inside, where the padlock can't be seen. Buttons on one point sharing a name show it once, over
the leftmost.

**A refusal reaches the presser alone.** It used to swap the button's name for everyone near.
Now `Prompts.refuser(p)` gives `(text, player)` and fires `Remotes.Refused` to that player; their
screen shakes the button (7 points, dying away over 0.38 s), turns the verb into the refusal's
words and the chip's rim red for 1.2 s, eases back, and plays a quiet dull tick (Roblox's "UI
Bright Click" at 0.55 speed). The door's rattle and other world sounds still answer in the world.
The client checks what arrives (a ProximityPrompt, a string cut to 40 characters).

**`ButtonReach` folded in.** `ButtonView.hide(prompt, reason, hidden)` is the same plain-table
hiding by reach (D-111, D-113): a hidden button is never shown by Roblox, so it draws nothing
and no key presses it.

**Performance.** Only buttons in motion are stepped; a settled one costs nothing. Drawings are
pooled (eight kept) so walking a hall doesn't build and throw away GUIs.

**Verified in Studio** (one player, keyboard and the Galaxy A16): every prompt in the test hall
and the laid floor is Custom; Unit 112's Open and Cut drawn with "Padlocked" once; Open refused
red with "Padlocked" from the E key and from a real tap on the phone chip; Cut's ring filling
mid-hold with bolt cutters, the padlock cut, the row turning to Peek and Open; Pick up named
"Bolt cutters"; the keypad's Use on the phone. Rejected: a CanvasGroup per button for the fades
(a render texture per button, soft on phones); moving the chip with the words.

## D-115 A door's buttons where your hand would go (L-19b, Nov 11)
The moment: at a shut door your thumb finds Open on the door's middle and Peek low by the handle,
as if reaching to lift it a foot; at an open door Close and Slam sit side by side in the middle;
the padlock's Lock and the cutters' Cut sit on the latch. The owner's layout (ROADMAP L-19b).

**Each spot its own point.** `Doors.add` makes four Attachments on the unit's root, all facing
the hall as the door does: `DoorMiddle` (Open, Close, Slam), `DoorLow` (Peek), `DoorLatch` (Cut,
Lock; across the door wherever the art hangs its `Padlock`, the hall's right on today's M and S),
and `DoorInside` (Lift). Heights live in the pure `DoorSpot.Height` (4, 1, 0.5, 4); `Door.place
(state, action)` gives each button its spot and its place across the middle row.

**The middle row, per state, a double tap safe.** One alone in the middle; Close and Slam half a
step either side; three in a row (while you peek) a step apart; a step is 130 points (a chip and
a short verb, then air). Laid out so the place a tap hit is empty after it, by a phone chip's
whole target: tap Open and the middle is empty while it rises; tap Close and its place is empty
while it falls (Open comes back in the middle, Slam a step right). Lune checks every tap of every
state. Changing state moves a still-shown button along the row over 0.14 s (`WorldButton.slide`)
instead of jumping; one fading out keeps its place. Close no longer shares Peek's spot as a
toggle: while you kneel it sits in the row, so the low spot is empty after Peek (`OWNER.md`).

**Each screen keeps the spots in view** (`DoorSpotView`, the rule in `DoorSpot`). In first person
a button shows only while its spot is on screen, and the bottom of a phone's screen is the
hand's: on the Galaxy A16 the tool slots' top sits 87 points under the view's middle. So each
screen moves its own copy of the spots near it (within 14 studs, looked for five times a second,
moved only when they need to):
- Up into view: a spot sits no lower than `Below` under your gaze (Open at your eye, Peek and the
  latch 12 degrees under it, clear of the slots and a chip under Open). Looking down at the door
  lets them come down with your gaze onto the handle and the padlock; looking up counts as level,
  so nothing chases your gaze up the door. Your eye is your standing eye at most
  (`Kneel.standingEye`), so a jump never lifts them.
- Down with your eye as you kneel: no higher than 16 degrees over a level gaze and never under
  1.8, clear of the peek's gap. This replaces KneelView's own lowering of the door's buttons: the
  camera's drop does it.
- In along the bar: the latch's spot slides toward the door's middle just far enough to sit
  within 24 degrees of your gaze (`DoorSpot.slide`), so on a phone Cut stays off the torch and
  jump buttons and its red "Need bolt cutters" ends short of them; face the padlock and it's on
  it. Looking away from the door leaves it be.
The server judges a press's reach from the nearest place a screen may have put the spot (up the
door to a tall eye, down to the row's lowest, the latch's in to the door's middle), so a button a
player sees within reach is within reach on the server too.

**Names.** Only Open and Lift carry "Padlocked" (the head of each side), so it shows once now that
Open and Cut no longer share a point.

**Verified in Studio** (one player, a computer and the Galaxy A16 in the Device Simulator): the
spots on the laid floor's M and S units; a shut door from three studs, level and looking down;
Peek by key and press crouching you with the row brought down over the gap; Open, then Close,
with Slam sliding 65 to 130 and the tapped Close fading in place; a padlocked door's "Padlocked"
once, Cut slid in with its refusal short of the torch button; Cut held with bolt cutters (R)
taking the padlock off, again after the server's reach check moved to the spot's range (Peek,
Close, Open by press; R held). Rejected: spacing the buttons by world distance (they'd crowd far off
and fly apart close up); following your gaze's pitch both ways (buttons crawling up the door).

## D-116 The inventory wheel and three slots (L-20a, Nov 12)
The moment: one round button at the bottom middle; tap it and your slots fan out over it like
GTA V's and Red Dead Redemption 2's weapon wheels, pick one and it's in your hand; a small box
beside the button shows the slot your hand is on, and a tap on it puts the tool away or brings it
back up. Never slow. The owner's design (ROADMAP L-20).

**Three slots, one number.** `Carry.Slots` is 3 (the GDD's two plus one, the owner's note;
`OWNER.md` asks for the GDD's line). The server's checks, the attributes (`ToolSlot1` to
`ToolSlot3`), the wheel and HornView all read it, so six (L-20b) is a change of that number and
the wheel's spread (`Wheel.Spread`, already Lune-checked at six).

**Pocketed is the server's.** A pocketed tool stays on your slot but leaves your hand: `Carry`
keeps `pocketed` (never on an empty slot); `held` is nil while it's set, so the weld, the walk
speed, Use, Drop and Give all see an empty hand without changes. `Slots.carried` gives the hand
as 0 while pocketed, so Doors, Saws, Ladders and Crawls read a carried-but-not-held tool
("Hold the cutters", "Hold the saw") with no edits of their own. A new remote, `ToolPocket`
(a boolean: type, a living character, the hand's rate), and the attribute `ToolPocketed`. A
switch, a pick-up, a handover and clearing all bring the hand up. A big tool (the ladder) can't
be pocketed: it rides your shoulder and pocketing it would carry it through a crawl hole. Rejected:
a hand of 0 with no slot (the box would forget which slot it shows).

**How a press reads** (`Wheel.press`, pure): another slot switches and lifts; your own pocketed
slot lifts; your own slot's key a second time pockets (Rust's hotbar holsters on the second
press); a pick on the wheel of the slot you already hold just folds the wheel. The box and the
pad's d-pad up toggle. The d-pad's left and right step round the slots (`Wheel.step`), since
three slots no longer fit left and right.

**On a computer** first person pins the mouse, so the wheel has a key: Q opens it (GTA V's Tab;
Tab is Roblox's player list) and asks FreeCursor for the mouse while it's open, so a click picks
a slot; 1, 2, 3 still pick at once without it. The button shows "Q", each slot and the box their
number, on a keyboard only.

**The shape** (`Tools.Wheel`): slots 0.86 of the button, on an arc 1.5 buttons out, 45 degrees
apart (closing up to fit 150 degrees for six), each at least 1.3 slots from the next and clear of
the button and the box, on screen under the A16's top bar; Lune-checked at three and six, at 56 to
88 pixels. The button keeps the old slots' size (12% of the screen's height, 56 to 88) and bottom
gap, so its top on the A16 (270) is no higher than the slots' was (267) and `DoorSpot.Below` holds:
Peek's middle measured at 233 to 235 from 1.5 to 4 studs.

**Motion and sound:** each slot fans out from the button's middle in 0.12 s (Back), 0.02 s
apart, with Roblox's "UI Bright Click" soft and rising slot by slot; the others fold back in
0.08 s and the picked one flies into the box (0.1 s), which pops. Lifting plays the tool's own
pick-up clank at 0.45 (as switching did); pocketing the same clank softer and lower (0.25, pitch
0.8). A refused press (the ladder) shakes the box with a dull click; a switch away from the ladder
keeps its words ("Drop the ladder first"). A tap in the world or 4 s untouched folds the wheel, as
does losing your hands (caught).

**Verified in Studio** (one player): on a computer, Q opening and folding the wheel (the mouse
freed while open), 1 picking from it with the fly into the box and the name, 1 again pocketing
and lifting (the server's held model gone and back), d-pad right, up and left, clicks on the
button, a slot, the box and Drop; a padlock lifted showing all 14 Lock buttons and none
pocketed; Lock with the padlock, then Cut with the cutters (2) on the same door. On the Galaxy
A16: the wheel by tap, a slot by tap, the box by tap, clear of the thumbstick, Blow, jump and
torch buttons.

## D-117 Every button on a phone at once (L-17, Nov 12)

Judged on the Galaxy A16 in Studio, three crowds, with BillboardGuis mirrored into the shots:
kept with the Bang button up; the horn in hand at a shut and an open door with the torch, jump,
map and Blow showing; the wheel open by a door. Two things overlapped and one key collided.

**The open wheel over a door's buttons.** On a phone the wheel fans up to y 190 and a shut
door's Peek sits at 233, Open just above it, an open door's Close and Slam beside the top slot:
slots landed on chips, and a tap could take the wrong one. Now every button in the world steps
aside while the wheel is open: they fade out together in 0.1 s (`WorldButton.Aside`) and take
no taps, and come back as it folds (ButtonView's `aside(reason, on)`, called by ToolView's open
and fold). GTA V's weapon wheel takes the screen the same way, the world dimmed behind it. Their
keys still press them: a keyboard press on E meant the door. Moving the wheel instead was
ruled out: on a phone the low middle is the only place for it and a door's low row sits right
above it by design (D-115).

**The Bang button over the torch's switch.** Kept on a phone, the Bang button takes the jump
button's corner (96 points) and its top ran into the torch's switch, which sits over the jump;
mashing Bang could flick the torch. And the wheel sat on with three empty dots: a kept player has
dropped everything (KeptPlayers' `dropAll`), so it was a dead button. Now, while you're kept, the
wheel slides off the bottom of the screen (0.3 s in, Quad) and rises back with a small overshoot
when you're let out (0.45 s, Back); its presses are ignored (ToolView's `alive` is false while
kept). The torch's switch and the Use button go with the jump button and also while kept
(FlashlightView, HornView), so the screen holds the Bang button, the map and the thumbstick.
Hooked in Dead by Daylight, a player has one prompt; the same here. A torch left on stays on.

**Q at a shut door.** On a computer Q opens the wheel (D-116) and is Peek's key: at a shut door
one press peeked and the wheel's key fired too. Now while a shown button takes Q, Q is that
button's and the wheel stays shut, as G is Slam's at an open door (D-108); 1, 2, 3 still pick.

**Judged and left:** the held torch behind Cut at a padlocked door (L-19b's note): the chip and
its word draw over the torch and read, so the hand doesn't drop. Horn up at a shut and an open
door: Open/Peek and Close/Slam clear of the wheel, box and Drop by 7 points or more; Blow clear of
the jump. The map clear of everything.

**The round button is `UseButton`** (its ScreenGui and the button's Name): it carries every verb
tool's press (Blow, Lay), not the horn's alone.

**Seen, not chased:** at the first catch the torch's switch and the Use button's screen stayed
on while the jump button was hidden, as if its Visible change never reached them; toggling the
jump by hand after made both follow. The kept check now hides them whatever the cause.

**Verified in Studio** (one player, Galaxy A16 and computer): the three crowds captured
(`docs/art/L-17-*.jpg`, before and after); the wheel's slots over Open/Cut with the chips gone
and their taps off, back on fold after 4 s; kept with only Bang, the map and the thumbstick; let
out by a stand-in's Cut free with the wheel back at y 212 and the torch's switch back. On a
computer: Q at a shut door peeked with the wheel shut; at an open door Q opened it with Close and
Slam aside.

## D-118 The crawl is placed each drawn frame, not each physics step (L-16d, Nov 12)

The owner, Nov 11 night, after L-16c: crawling the tops was "still janky on my computer... it
still jitters a lot", less so on a phone. **The cause, measured:** your screen steered your lying
body in `PreSimulation`, and physics steps on its own clock, 60 a second, whatever the screen
draws. Recorded in Play: with Studio drawing 15 frames a second, `PreSimulation` still ran 60.1
times a second, four steps to most drawn frames and two to one. So a screen drawing faster than
physics (120, 144) gets a physics step on only some frames: the camera drew one place two or
three frames running, then jumped, a stutter a phone at 60 mostly hides. Roblox is moving more
of the engine onto this fixed clock (its BindToSimulation and UseFixedSimulation, announced Apr
29, 2026), so it stays true. And between placing your body and drawing it, physics nudged it down
a few hundredths of a stud on random frames: lying still, your eye dipped 0.017 studs now and
then.

**Now:** LadderView places your own body in a render step just before the camera
(`RenderPriority.Camera - 1`, "LadderViewPlace"): up the ladder, along the tops, down and off
alike, each drawn frame moving it by that frame's own time. The crawl over a frame is
`Tops.advance`: `Tops.step` in even steps no longer than a sixtieth of a second (`StepMax`, the
rate the crawl was tuned at), so turning and sliding along edges feel the same on any screen, and
a hitch past a quarter of a second (`FrameMax`) loses the rest rather than throwing you across
the steel. Before each physics step the body is held where the frame put it, still, so physics
and the server see what you see. Friends' arms stay in `PreSimulation`, after Roblox's animation.

**Measured, before and after** (Studio unfocused, 15 frames a second; it can't be brought to the
front from a script here): crawling straight, a frame's pace was off its neighbours' by up to
9.8% (3.8% on average), since every frame moved whole physics steps whatever its own length; now
at most 4.0% (2.2%), which is the pulls' own surge. Lying still, your eye now holds one height.
`tests/tops.spec.luau`: at 15, 30, 120, 144 and 240 frames a second every frame moves its share
and ends where 60 takes you, within 0.05 studs and facing the same way. The server's crawl check
put nobody back crawling flat out with weaving turns across three units' tops (about 25 studs
each run), with no lag, under the
network simulator's 4G and under its bad 3G (150 to 180 ms each way, jitter, loss). On the
Galaxy A16 in the Device Simulator: no frame held, one steady height, climbing down as before.

**Not measured here:** a computer drawing above 60. The fix doesn't depend on the rate (each
frame moves its own time), but the feel at 120 and 144 is the owner's to judge, with a live
server's lag (`OWNER.md`).

## D-119 The front office: one wide room of the building's own parts (L-08e1a, Nov 12)
The moment: you load in just inside the glass front door and six lit cars face you across the
room, numbered 1 to 6, their gates folded open. You know where to go before you've moved.

**One room, 120 by 48, the cars along the back wall.** Six cars need 108 studs of wall at the
climb's own landing (12.4 hole, 13.8 with its frame) with a post and the car's keypad between
each; the room's depth (44 from where you land to the cars, under 3 s at a run) leaves the floor
the cart ride needs (L-08e4) and keeps the GDD's 15-second rule easy. The counter and its shelves
stand to the left of the door, the cart rack to the right, as the GDD lays them out. The room
is plainly the same building: the corridor's deck at 14 on joists spanning front to back, its
walls (painted panels to the cap, R-panel above), the unit's concrete. Joists fall every 6 from
the middle, so every car's middle and every hall light sits between two.

**It bakes nothing.** Every part wears one of the unit's baked sets, as the corridor kit does:
the counter, shelves, rack, storefront and plates are steel, so the trim sheet's strips (painted,
galvanized, diamond, rubber) cover them, and the two painted surfaces (the walls, the counter's
front) are the Facade set, tinted in game. A new texture set would have cost a bake and a second
look for what is the same steel. The glass and the floor's stripes are plain parts the game
colours.

**Everkeep's colours** (default; `OWNER.md`): the walls' panels are the units' teal door colour,
the counter's front their cream. Teal was chosen over the halls' cream because the cars' insides
are cream: against teal they stand out from the door on a phone (Studio, A16); against cream
walls they would melt into them (not tried). The striped zone before each car is the climb's sill yellow,
so the lobby rehearses the line you have to be over when the gate shuts.

**Light: the cars brightest, few real lights.** The hall lights glow but throw nothing; two wide
fill lights (no shadows) light the room, each car's own lamp lights the car, and a porch light
outside lays a sodium pool on the concrete so the glass reads as the way out. Real lights: two
fills, the porch, six lamps (and each keypad's tiny glow). Rejected: lighting the hall lights for
real, which costs two lights each (HallLight's tube and fill) for 14 fixtures. The fixtures' eyes
are shut: no keeper watches the office.

**Plain glass, not Roblox's Glass.** Glass at 0.6 seen from the lit room showed only black in
Studio's A16 view; faint SmoothPlastic (0.82) shows the night sky and the porch light's pool.

**The cars are dressing until L-08e1b1:** the climb's elevator template, cloned untagged, gate
folded open, so the climb's keypad, gate clock and ride leave them alone. The test hall's post
to the lobby takes R, since two E posts stand 3 studs either side and a press goes to whichever
prompt is nearest the middle of the view.

## D-120 The lobby's cars are the climb's own elevators, counting (L-08e1b1, Nov 12)
The moment: you and a friend run into car 3, the chime, the count pops in green, the last one
sprints in at 2 and the gate slams behind them; the shaft slides by and the car opens on floor 1.

**The same elevator, not a lookalike.** Each lobby car is the climb's elevator, tagged like any
other and marked with its bay (`Boarding.CarAttribute`), so the gate's fold and slam, the clock,
the lamp's blink, the heartbeat and bells, the ride and the hand-off are the code friends already
hear on every floor: the lobby rehearses the last sprint (GDD). `Elevators` gained a lobby mode
(`lobby`, `count`): no code, keypad asleep, the group's pick of who rides, nobody left behind.

**Groups by a zone, as DOORS' lobby elevators.** A Brix zone over the car (the box that decides
who rode) joins you as you step in; you leave once out for 0.35 s, so a heel over the sill doesn't
chime you out and back. 20 s from the first step in, 5 once six are aboard, never climbing back
up; the last one out stops it. Once it's shutting, whoever is inside at the post rides (the group
first, then anyone who dived in, six at most); a seventh left inside is set down outside.

**Who sees the count.** On screen only for the group (GateClock's plate, the chime as you step
in), so six counts never crowd one screen; for the room, the car's keypad readout counts (dashes
at rest, green, then red from the warning) and its lamp blinks. The keypad stays as the car's
panel, its prompt gone: L-08e1b2's host's panel goes there. Rejected: hiding the keypad (the
panel is where DOORS' host choices live), a world sign over each car (L-08e3's dial).

**Up to floor 1 on this server** (until L-08e1c): floor 1 starts laying out of play the moment a
count starts (`Climbs:ready`, 2 to 4 s in Studio), so it's ready long before zero; at the post
`Climbs:board` ends whatever climb ran (the test hall's, in Studio) and floor 1's car takes the
lobby car's ride mid-cruise, the same `carry` every floor's hand-off uses. The ride's counter reads
L (`Ride.Lobby`, a new "L" on the readout's segments) then 1. Lobby climbs are laid at
`Lobby.ClimbOrigin`, clear of the test hall's climb. One climb a server: while a lobby climb runs
the other cars' groups form but their counts wait, starting again from 20 once it's over. The car
is back open in its bay 12 s after it left.

**You load in at the lobby.** FrontOffice owns the spawn (facing the cars) and clears the place's
baseplate and pad; `LobbyView` turns the camera to the cars the frame you arrive (a new character
keeps the camera's old look). The test hall is Studio only now (D-109 done), reached by the lobby's
"Test hall" post.

## D-121 The host's panel: a button inside the car, the choices on the car (L-08e1b2, Nov 12)
The moment: first into car 3, you tap the panel, flip it to Friends and 2 players, and hit Go the
second your friend is through the gate.

**The first one in hosts, as DOORS' lobby elevators.** `Boarding.host` is the group's first; if
they step out the next one hosts, the choices as they were (nobody loses what was picked mid-count),
and an empty car starts again from Open and 6. The host picks Open or Friends only, 1 to 6
players, the difficulty (one, "Normal", until the GDD's tiers are named: `OWNER.md`) and Go.
Never fewer players than are aboard (nobody is put out by a choice); filling the host's count cuts
the count to 5, as the sixth stepping in does; Go runs it out now (`Elevators:count(car, now)`).
Nothing once the gate is shutting, and no Go while the count is held by another climb.

**The button is inside the car, not on the keypad.** The keypad faces the room, beside the gate,
so from inside the car it can't be reached or seen, and stepping out to it would end your hosting.
The panel's button hangs on the car's wall on the keypad's side, just behind the gate (the gate
stacks on the other side), at the keypad's height, and reaches the whole car without a clear line,
so the host taps it from wherever they stand. Only those aboard see it: "Host" for the host, "View"
for the rest, who get the same panel greyed. Rejected: the keypad's own prompt (out of reach), an
on-screen button (a computer's locked mouse can't click it; a prompt has a key on every device),
opening the panel on its own as you step in (it would cover a phone while friends run in).

**The panel draws only what the car says.** One remote, `Remotes.CarPanel`, checked in order:
types (a lobby car of ours, a choice the panel has, its value's type), range (this car's host),
rate (half the panel's 0.12 s, for jitter), then Boarding's rules. The choices replicate as
`FriendsOnly` and `Players` on the car, so every open panel answers the same change at once. A
press answers at once on the presser's screen (the key dips, a click); one that can't go barely
moves with a dull click and no words.

**Turned away at the gate.** Someone stepping into a car its host's choices close to them (full,
or Friends only and not the host's friend) is set down outside the gate facing the room, and their
screen says why: "Car full" or "Friends only" in red, at most every 2 s if they keep at it. Words,
because nothing on the car shows the choices yet (L-08e3's dial will). Whether they're the host's
friend is asked of Roblox once as they step in (`Player:IsFriendsWith` yields, so off the step)
and kept both ways round; until it's answered they're neither in nor out; a failed ask counts as
no for 5 s, then is asked again. A diver under the shutting gate rides only within the host's
count and, while it's Friends only, only if known to be the host's friend.

## D-122 A server of the group's own: the ride goes on through the black (L-08e1c, Nov 12)
The moment: the gate slams on you and two friends, the car moves off, the screen sinks to black
("Going up"), and it opens on the same ride, the shaft sliding past, the car levelling on floor 1
of a building that's only yours.

**As DOORS' lobby elevators send each group to its own server.** Brix has no matchmaking (its
round loop, ENG-13, is unbuilt), so `Trips` is the smallest stand-in: one `TeleportAsync` for the
whole car to a new reserved server. Roblox's current way is `TeleportOptions.ReservedServerId`
set to a fresh GUID: the first teleport with it makes the server, and a retry with the same one
lands on it, so a hiccup never splits a group (`ReserveServer` and `ShouldReserveServer` are
deprecated; read on create.roblox.com Nov 12, docs/STUDIO.md). The data that goes along is who's in
the group, host first, and the difficulty (`Trip.encode`). It passes through each player's device,
so the group's server checks it (`Trip.decode`: our version, 1 to 6 distinct UserIds, a known
difficulty) and takes it only as whom to wait for; nothing of value rides on it yet. Rejected:
MemoryStore for the group (secure, but a second service that can fail, for data a cheat gains
nothing from today; take it when difficulties pay out more).

**The black hides the trip, the ride carries across it.** Riders' screens fade to black 1.6 s
into the ride (the slam has rung and the car has started to move) and the server sends them at
2.2 s, black by then; an opaque twin of the cover is Roblox's teleport screen, so the black
carries across, and ReplicatedFirst keeps it up on arrival. The group's server lays floor 1 the
moment it starts, waits for the whole group (or 10 s after the first: a slow phone isn't worth
everyone staring at black), streams floor 1's car to them and stands them in it, host at the
front, facing the gate, 3.4 s into the car's ride (`Elevators:ride`, `Climbs:arrive`): full speed,
the second clank, the slowdown and the bell still ahead, so the ride they left in is the ride
they arrive in. Someone later (a slow phone, a respawn at that server's front office) is stood in
front of the car once it has opened, as if they'd just stepped out. A group's own server opens no
lobby cars. Rejected: arriving on floor 1 standing outside the car (no ride, no reveal); holding
everyone until the last phone loads (one bad connection stalls five friends).

**A failed trip goes back to the car.** Failures Roblox thinks worth it (Failure, Flooded) are
tried again, three tries in all; a rider still here 15 s after their last try has failed too.
Those still here are back in their car, the car standing open again, in their old order (the host
hosts) with the choices as they were, "Teleport failed" on their screen and the count running
again; the next trip makes a new server (someone who did go isn't followed: OWNER.md). Two failed
trips in a row and that lobby rides its groups up on its own server, as before (D-120), so the
game stays playable if trips break; it warns once.

**Studio.** Studio rides on its own server, as before, so play and the dev tools keep working.
Workspace's `DevTrip` (set in Edit, never saved) tries the rest: "Arrive" makes the server a
group's own for whoever joins; "Send" takes the real trip through Studio's test teleports, which
open the group's server as a new test server from the place as last saved, with an empty
`PrivateServerId` (there, the first player arriving on a trip makes it one); "Fail" makes every
trip fail. Live, a group's own server is only one with a `PrivateServerId` and no owner, so
teleport data can't turn a public server into one.

## D-123 Back in your car: the same car, the same friends, the results on its wall (L-08e2, Nov 12)
The moment: the climb ends, you press Again, and the black lifts on the car you left from, your
friends beside you in the order you stepped in, the results on its back wall, the count running
for another go (GDD "The lobby": "they come back standing in the same car ... results on the
wall, with a countdown to go again"; DOORS' lobby elevators).

**Again stays the one button and leads to the car** (`ClimbEnds.go`, the one place D-106 left for
it). The end screen is unchanged but its words ("Back in 10", "Going back"); then the climb's
group gets characters standing in their car (LobbyCars' `home`), facing its back wall, the rest
of the server at the front office; once all are loaded and the car is streamed to them, the
results go on the wall and the car's full 20 s count runs (`welcome`, `Boarding.welcome`: full
even when the car is, so there's time to read the wall). Then the black lifts with the count's
chime instead of the bell, no floor number, and the camera turned the way the server stood you
(`ClimbEnd.StoodAttribute`: in first person the body turns to the camera, so the body's facing
isn't to be trusted). A climb no lobby car started (the test hall's) still goes to a fresh floor
1. Rejected: no button and everyone back once the results have shown (one fewer press, but it
changes D-106's moment the owner hasn't judged yet: OWNER.md); facing the gate (the results
behind you).

**Which car, which order.** On a lobby server the car that left, its riders in their order and
the host's choices as it left (`Boarding.back`: anyone who stepped in meanwhile keeps a place
after them, up to six; if the car has taken another group up, the first empty car). On a group's
own server, the car the trip's data names: `Trip.Version` 2 carries the bay and the host's
choices; version 1 still reads, as the first bay, Open and six. Its cars are laid and set up from
the start but take nobody until the group comes home (`Trips:home`: from then a respawn stays at
the front office), and their next climb rides up on that server, so the group keeps its server.

**The board** (CarResults, client): a plain part on the back wall above its upper wooden rail
with a SurfaceGui, the end screen's colours, "Kept"/"Made it", "Floor N · m:ss", each friend's
photo, name and floor, lost ones greyed and askew; the photos drop on one by one as the black
lifts. From the car's `Results` (`ClimbEnd.encodeResults`, at most six rows); it stays while
people step out and in and goes when the car next leaves. Sized for first person from the front
row (5.5 studs off the wall): the whole board fits the view.

## D-124 Invite and the dials: who's in each car, and where to go (L-08e3, Nov 12)
The moment: a friend's not here, so you tap Invite on the car's panel and Roblox's sheet of your
friends comes up; from the door every car tells you who's in it, and if you're in no car the
fullest one that will take you glows, a chevron bobbing in its doorway (GDD "The lobby":
"An Invite button on the car's panel", "Players alone are pointed to the fullest open car",
"The dial over each car shows who's aboard, or which floor a climbing party has reached"; DOORS'
lobby elevators show who's in each over its door).

**Invite is Roblox's own sheet, beside Go, for anyone aboard.** `SocialService:PromptGameInvite`
with an `ExperienceInviteOptions` (the line "Ride up with us", launch data `{ by = UserId }`);
read on create.roblox.com Nov 12 (docs/STUDIO.md). Anyone aboard may invite, not just the host
(a friend of anyone is welcome in an Open car; OWNER.md). It hides where
`CanSendGameInviteAsync` says no (asked once, it yields) and on a group's own server: a friend
can't follow you into a reserved server, so until L-08e3b sends them on, the key waits for a
public lobby (the ticket's fallback). The sheet's closing tells nothing (`GameInvitePromptClosed`'s
recipients are no longer filled in), so the press's answer is the key's dip, the click and the
sheet itself. Rejected: a toast after the sheet ("Invite sent"), which we can't know.

**A friend who comes by your invite is pointed to your car.** The server reads the launch data
from `GetJoinData` (it can take seconds: asked ten times, a second apart), checks only its type,
and marks the player `InvitedBy`; their pointer prefers a car with that friend aboard, if it
would take them. It's a hint, so it's not checked further: a forged one only points a screen.

**The share link is a separate thing and waits (L-08e3b).** Audience Expansion (Creator Rewards)
pays on new or returning players who come by the experience's share link; an invite to a friend
already on Roblox isn't that. A share link is `PromptLinkSharingAsync` (server only), a second
button whose place is the owner's call (OWNER.md).

**The dial covers the bay's number plate and keeps the number.** A client SurfaceGui plate (10.4
by 3 studs, 50 px a stud) over each gate: three round seats either side of the number, a photo in
a warm ring for each aboard (popping in), dark sockets for room, faint past the host's count;
one line under it: "Friends only" (warm), "Full", "Going up" (a trip), or "Floor N" in the
readout's green while the group it took climbs on this server. Rejected: words for the count
(the keypad readout beside the gate already counts), a separate sign beside the number plate
(two signs per car), photos alone (unreadable from the door: the seats read as lit and dark
dots there, the faces as you walk up). Built in code for now; the unit's way (a real indicator
box and needle) is in ROADMAP's polish.

**The floor is the server's word.** While a climb a car started runs on this server, LobbyCars
puts its floor on the car (`ClimbFloor`), cleared when the group is home or the climb is over.
A climb on a group's own server says nothing to the lobby yet (MessagingService, L-08e3b), so
those cars show "Going up" as they leave and then stand ready for the next group.

**The pointer.** Pure (`Boarding.fullest`, Lune-checked): the fullest car with someone aboard
that would take you (room, Friends only only if Roblox says you're the host's friend, asked once
and kept) and won't shut in under 4 s (`Boarding.Reach`: from the door it's under 3 s at a run),
more time left on a tie, the inviter's car first. Only for a player standing in the front office
in no car's group; worked out four times a second. No pointer while every car is empty: any car
will do and you spawn facing them. Its look is soft: the dial's rim warms and breathes, the seat
you'd take glows with it, and a warm chevron bobs in the doorway at head height. Rejected: a
screen arrow (it covers the phone), a light on the floor (a real light per car, against the
light budget).

## D-125 The platform cart: orange steel, swivel casters, parked every which way (L-08e4a, Nov 12)
The moment it serves (the ride is L-08e4b): from the spawn you see a rack of real carts by the
door, the thing you grab while the count runs, as R.E.P.O.'s carts and Roblox's classic
skateboard are there to be ridden.

**A real storage office's platform cart, built the unit's way** (`art/cart/`, the ladder's
recipe on the finds' kit): a welded steel deck 2.2 by 4.3 (the rack's slots were sized for it),
a ribbed rubber mat, a U handle with a cross bar and a foam grip, rubber bumpers on the nose,
6-inch casters. **Safety orange** on the steel: it reads against the teal walls from the spawn on
a phone, and it's the colour of the thing you grab and go with (a default; OWNER.md). Rejected:
Everkeep's teal (lost against its own walls), a plywood deck (reads as a pallet at phone size),
a cage cart (hides the rider).

**Seven parts so the ride can move them:** the body, the two front swivel forks (each turning
about its kingpin) and the four wheels (each spinning about its own middle, the axle). The
casters' kingpins and axles come from the generated `Cart.Specs`, left and right as you push it.
Zinc on the forks is half metal, as the ladder's aluminium is mostly diffuse: fully metal it
took on the dark studio and read black.

**Parked to look used, not placed:** `Lobby.lay` parks one nose-in at each rack slot
(`Cart.park`), each a degree or two off square and its front casters turned every which way
(`Lobby.Parked`), as carts left standing have them. Parked carts are anchored; an invisible
`Deck` box from the floor to the mat's top is what you bump and step on; the handle doesn't
collide yet (the ride decides what it needs).

## D-126 Riding a cart: your screen rolls it, the server watches (L-08e4b1, Nov 12)
The moment: you tap Ride on a cart in the rack, kick it across the lobby while the count runs and
roll up to the gate, as Roblox's classic skateboard kick-pushes and R.E.P.O.'s carts are ridden.

**You stand on the deck facing the handle and it rolls handle first**, like a kick scooter. The
carts park nose-in with their handles to the room, so this rolls you straight out of the rack;
ridden nose first you'd face the wall with no reverse. Stepping on, your view swings round to the
way it rolls (`Ride.View.Turn`), with a thud on the rubber mat.

**It heads where you look.** Roblox's controls already turn the stick or keys by your view into
the Humanoid's `MoveDirection`, which still updates while you stand on the seat; the cart turns
toward that way and you kick while it's within 100 degrees, so a cart that can't swing yet (in
the rack, against a wall) rolls out straight and then curves. Push away from it (past 125) and
you drag your foot: it slows in a straight line, then swivels round. Rejected: tank steering
(A and D turn), which fights a first-person view on a phone. Tuned in Lune and Play: one kick
adds 10.5 a second from a standstill and less near the cap (28), one every 0.55 s while held,
cruising about 22 (a walk is 16); let go and it coasts about 45 studs in 4 s. It turns about its
fixed casters at the handle end (they can't slide sideways), so you turn nearly on the spot while
its tail swings, and a turn that would scrape shuffles it back off the wall a little each frame:
without that a cart stopped nose to a wall could never leave it (seen in Play).

**Your screen rolls it.** The server stands you on the cart's hidden Seat, frees the cart and
gives it to your screen (`SetNetworkOwner`); your screen places it each drawn frame just before
the camera follows, in even steps (`Ride.advance`, as the crawl, D-118), and holds it there
before each physics step with a force against gravity. Nothing about it collides in the world's
physics while it rolls (`Cart.anchor`): a moving cart that shoved friends would launch them.
Instead a box swept ahead each frame finds what it would meet: head on, a clank, a jolt and a
dead stop (`Ride.hit`, never any speed added); met flatter than 30 degrees, a scrape and a slide
along. The sweep starts from where the cart last stood clear, and a turn is checked with a box a
hair bigger than the swept one: a sweep can't see what it starts inside, and in Play a turn at a
wall left a corner in it and the next kick carried cart and rider out through the wall.

**The server watches.** Every half second the cart must not have gone further than a cart can
roll (`Ride.tooFast`: the cap's pace times 1.3 plus 4 studs) and must be inside the front office,
short of the cars' striped band; one that fails is taken back where it last passed and its rider
put off (it caught the cart through the wall above). One rider a cart; a press while it's ridden
or rolling isn't shown at all (the button hides). Jump hops you off keeping at most 8 studs a
second of its speed; the cart rolls on to a stop on your screen and the server parks it where it
stood still, anchored, its trailing casters swung round behind. Leaving or dying parks it at
once.

**The cars' band is where you hop off.** Ride onto the yellow stripes before a car and you're put
off onto them, the cart stopped at their edge; until L-08e4b2 sends it home, it stands there.

**Feedback:** the casters' rattle (Pro Sound Effects' "Gurney Rolling 1", looped) rises in volume
and pitch with speed on every screen; each kick's plant a scuff and a dip of your view; at speed
the casters shiver under you, your view widens up to 7 degrees and leans into turns; a clank
jolts it; a hint once a session ("Hold forward to roll", "Jump to hop off"). Every screen spins
the wheels by how far the cart rolls and swings the front casters to trail their kingpins; a
friend's kicks, drags and bumps are read from how their cart moves (a surge, a hard slowing, a
sudden stop). The rider's body stands, leans and kicks (`Ride.leg`); their arms stay the torch's,
which FlashlightView holds out after any other pose.

## D-127 The owner's answers to the proposal (Nov 13)

The owner answered all 36 ideas in `docs/PROPOSAL.md`, added a note on the shop, and answered
four follow-up questions. The proposal now holds each answer under its number, written out in
full. This entry is the short list of what those answers settle. Nothing is built or ticketed,
and the design doc is not changed yet, so where the two disagree on the loop, the proposal is
the newer word.

**The building isn't a character.** It doesn't watch, send monsters or "come for you" (the
owner: that makes no sense). The lights are just lights. Each monster messes with the floor in
its own way and players go and put it right: a Mannequin can switch off the floor's breaker,
every hall light stays out, and someone has to find the breaker. Nothing runs on a timer the
players can see; not knowing when is the suspense.

**The climb has no top.** No roof, no Dale (the owner never chose him), no ten floors. Floors
are made by rules up to about floor 100 for launch; each monster has a lowest floor and is
mixed in at random above it; a floor that plays differently (the stair chase) about every five,
later. Best floor is the number to beat.

**You keep what you carry.** A find goes in one of your own three slots beside your tools; it
becomes yours when the gate shuts and the slot frees up. Everyone aboard is paid coins for the
floor, more for trapped monsters. No copies and no team pile. One big find a floor, carried in
both hands, is shown only once the code is in. Slots are sold up to six.

**Caught means caught.** Wrapped until a friend frees you or you buy Cut Free (Robux only; no
free hold-the-button). You are carried up floor after floor meanwhile, paid nothing, picking
nothing up; you can bang on the door or watch a friend, and can't help the team.

**Doors.** Coins in most units, not all. Two kinds of door: padlocked (always something good,
most monsters) and everything else (no idea). At most one faint mark for a note and nothing on
the map, because having to open doors, and what that lets out, is the game. About half as many
units. A timing tap only when you shut a door on a sleeping monster.

**Pressure.** A wrong code opens units with monsters in them, one and then three. Stay long
enough and sleeping monsters wake and pound on their doors, more of them on higher floors.

**Also settled:** one walking speed; the ride's choices can be bad for the team (this undoes
the Nov 2 cut) and grow over time with the monsters, on no weekly schedule; the machine on
every ride; a marker for tagging doors, bought with coins; no text that explains a rule to the
player; Part 6 and Part 7 of the proposal as written (a season pass is a maybe); the shop as
listed for now, which sells double cash from the day the store opens.

**Still the owner's to answer** (`OWNER.md`): tools rarer and wearing out, the second monster,
how the ride's choice looks, a monster you hide from, and a monster that takes your head.

## D-128 The proposal written into the design doc and the roadmap (Nov 13)

The owner said go ("update the design docs based on the latest revision of the proposal") and
answered four questions on the five ideas D-127 left open. The GDD is rewritten to match, and
ROADMAP's Phase 2 is now the proposal's build order as tickets (Steps 1 to 6, S1-01 on). From
here the GDD is the newer word again; `docs/PROPOSAL.md` is kept as the record of the answers.

**The four answers.**
- **Tools (idea 2): yes to both, and more.** Tools turn up in about one unit in twelve and wear
  out after a set number of uses. The owner added: the flashlight runs down too, with batteries
  sold in the machine on every ride and found in units. This overrides the proposal's "the
  flashlight doesn't change". How long it lasts, the meter, a battery filling it at once and
  taking no slot, and the prices are my defaults (`OWNER.md`).
- **The second monster (idea 12): build it next.** Silent, moves only while it stands in
  light, and a hall light it walks under sticks on until the breaker is switched off and on.
  It needs a look, a name and a reason to be alive from the owner before it's built.
- **The choice on the ride (idea 21): the elevator's own buttons.** Three buttons, each a
  version of the next floor and what it pays; harder pays more; it lasts one floor.
- **The two later monsters (ideas 8 and 39): both kept as ideas,** in no build step.

**Calls I made writing it in** (each is in `OWNER.md` to overrule):
- The GDD says "monsters" (the owner never agreed to "keepers"); the code keeps its names.
- The story section says the story isn't settled. The Nov 2 lore (Everkeep's name, Unit 0, the
  $1 auction, the three families) and the unbuilt monsters of the old roster are kept under
  "Nov 2 drafts, none agreed" rather than deleted. Dale, the Moth and the clock are listed as
  out.
- The director stays, described as pacing nobody sees ("it is not the building"). It no longer
  deals monsters as a door opens: sleepers are placed when the floor is made, which waking
  behind a shut door and the wrong code both need.
- Two products the proposal's store list left out stay in the GDD's store, marked: cart
  cosmetics (the owner's Nov 11 plan, D-112) and the streamers' admin pass (a Nov 2 draft).
- The GDD's rating section still says "no screamers", which the built catch isn't (D-102). Not
  part of this change; it's in HANDOFF's Queue.

## D-129 A cart rolls itself home (L-08e4b2, Nov 13)
The moment: you hop off at a car's stripes as the gate's about to shut, and behind you the cart
rolls itself back to the rack. One left anywhere else goes home after a while, so the rack is
tidy for the next round.

**Nose first, turning as a real cart does.** It rolls nose first, as a cart is pushed home: a
cart ridden out of the rack (handle first) already faces home, so the usual way is one smooth
curve with no turn round. (The handoff had said handle first; that would need a U-turn in
front of the rack every time.) The middle of its fixed casters (the hub, `Ride.Pivot` toward the
handle) follows the way and the cart points along it, so it never slides sideways; facing more
than 80 degrees from where it heads, it first swings round on the spot about the hub, as a
ridden cart turns. The way: a cubic curve from the hub into the slot's line, then the last 6
studs straight in so the nose clears the rack's hoops. A cart already lined up in front of its
slot squares up on the spot and rolls straight in (`Cart.Home.plan`, Lune specs).

**The server sends a run once; every screen rolls it.** The run is where along the way it was,
its speed, where it stops and when, by the server's clock (`GetServerTimeNow`), starting 0.15 s
ahead so every screen hears first. It sets off at 6 studs a second each second up to 7 (slower
than a walk), eases off at 3 down to 1.2 for the last stretch and stops dead against the rack.
On the server the cart stays anchored where it set off, its deck colliding as parked; each
screen places every part by hand each frame (`BulkMoveTo`: joints don't move anchored parts),
so its deck is solid where you see it, a ride clanks off it, and nothing is replicated per
frame. Rejected: the server moving it (per-frame replication) or unanchoring it (physics).

**Who it waits for.** Every tenth of a second the server looks 0.75, 1.75 and 3 studs ahead for
a character or another cart (`Home.meet`): something there, a new run brakes it to a stop (at
10, about 2.5 studs from its pace); clear for 0.6 s, a new run sets it off again. A run stamped
with the server's clock means a screen that hears late is off by a few hundredths of a stud,
never a jump. Held up 12 s all told, it's put in its slot if nobody stands there, else it parks
where it stopped and tries again later.

**Where it goes.** The nearest free slot (no cart in it, bound for it or over it), trying the
three nearest and three curve shapes each for a way clear of the walls, the rack and parked
carts (people and moving carts are waited for, not planned round). No way clear: straight
into the nearest free slot, with a line in Output. A cart counts as in a slot within 0.6
studs and 12 degrees of it. No Ride on the way home; arrived, its casters trail as pushed in.

Defaults on the owner's list (`OWNER.md`): nose first, the 20 s wait, the pace, the 12 s give-up,
no Ride on the way.

## D-130 Share and follow: a friend lands beside you, the lobby keeps your floor (L-08e3b, Nov 13)
The moment: back in your car on your group's own server, you tap Invite; your friend taps it,
lands in a public lobby, the screen drops to black ("Joining Sam") and opens in your front office,
pointed to your car (if you've gone up again, its dial says your floor). Meanwhile the car you
first left from in the public lobby shows "Floor 4" over its gate as you climb. Invite is on the
car's panel, so on your own server it's only there once you're home; joining mid-climb, beside
you, waits on the owner (ROADMAP L-08e3c, OWNER.md) (GDD "The lobby": "The
dial over each car shows who's aboard, or which floor a climbing party has reached").

**The trip names the group's server and the lobby it left (Trip version 3).** The lobby now
makes the reserved id itself (a fresh GUID) and puts it in the trip's data with its JobId; 2
and 1 still read, naming neither. The group's server puts its id on Workspace (`TripServer`), so
Invite there shows again and its launch data carries it, with the server time (`Trip.invite`).

**A friend's lobby sends them on (`Trips:follow`).** LobbyCars reads the launch data
(`Trip.readInvite`): a GUID sent within two hours (`Trip.FollowFor`) and the friend is sent on
alone (TeleportAsync, the same `ReservedServerId`), their data naming who invited them (the
pointer there prefers that friend's car once the group's home). Their screen goes black first
with the inviter's display name (`UserService:GetUserInfosByUserIdsAsync`, else "Going up"); the
twin carries across the teleport. There they arrive as a late arrival does: stood on the floor
the climb is on in front of its car (Climbs' `arrival`), or, after the first climb, in the lobby
where they spawned, the black lifting (that last path is new; before, a late joiner after home
stared at black for 45 s). Retries as a group's trip; failing for good, "Teleport failed" under
the black, then it lifts. A friend's failure doesn't count toward the lobby's fallback. A stale
invite whose server has shut makes a new reserved server and climbs alone: rejected sending them
back to a public lobby (a second teleport, 10 s more black, for a rare case).

**Word of the floor (MessagingService).** The group's server publishes `{ server, floor }` to
`"Floor" .. lobbyJobId` as the floor changes and every 60 s, 0 once the first climb is over (or
as it shuts, BindToClose). The lobby subscribes once (live only: Studio's JobId names no server),
takes a word only for the server its car last sent, and forgets after 150 s of silence. A lobby
of thousands of groups stays far inside the limits (600 + 240 per player sends a minute a
server). Rejected: MemoryStore polling (more calls, more to fail, same answer).

**Share beside Invite (the default; where it goes is the owner's call, OWNER.md).** A Share key
between Invite and Go for anyone aboard; the server opens the sheet
(`PromptLinkSharingAsync`, server only), launch data as an invite's; from a group's own server
the link expires with `FollowFor` and then falls back to the plain game link. Rate: one per 4 s.
The press dips and clicks; "Share failed" if the sheet won't open.


## D-131 Half the units: whole hall sides go, every wing keeps doors (S1-03, Nov 13)

**What.** Each floor's plan says about how many units it keeps (`Plan.units`: 30 on floors 1 and
2, 40 above, of about 60 and 80 its halls have room for; GDD "Doors": "Fewer units"). The halls
are laid as before; then step 5b (`thin` in `Floor`) turns whole hall sides into plain wall, a
hall piece's two M or three S units facing one way (or a junction corner's one) at once, so a
player sees a stretch of blank wall and then doors side by side, not a gap here and there, and
the doors that stay keep their neighbours to saw between.

**How the sides are picked.** In the order you meet them walking out from the lobby, each side
adds its share (the units to keep over the units there are) to a credit and stays when the
credit covers it, give or take half a side: kept doors come at an even pace with chance in it.
Rejected: a plain coin toss per side (the count swings more from floor to floor, and runs of
doors and of wall bunch up) and walling single units (a hall of gap-toothed doors, and units left
with no neighbour to crawl to).

**What always stays.** (1) One side in every wing, picked at random, so each wing has somewhere
for its note (Deal spreads the notes a wing each) and none is a dead walk. Without it 52 of 400
floors 1 and 2 left a wing bare. (2) On floors 1 and 2, the first `Floor.TeachDoors` (8) doors past the
lobby: the row of neighbours that teaches the hole trap. Protecting the whole lobby hall instead
kept up to 50 units on floors whose first fork is far. (3) A side whose loss would leave a unit
beside it with nothing to crawl to.

**No long bare stretch.** More than `Floor.BareMost` (4) hall pieces in a row with no door on
either side (about 96 studs, six seconds' walk) get a walled side back at their middle, the one
with the most units. Without it stretches ran to 7 pieces (170 studs past nothing). It adds a
unit or two on some floors (36 to 48 above, mean 39.7). A full floor whose halls stood bare
before any walling keeps that (about 1 in 200).

**Numbers.** Units are numbered again after the walling, still in the order you meet them, so
floor 1 runs 101 to about 130 with no gaps. Over 400 seeds: 26 to 37 units on floors 1 and 2
(mean 29.7), 36 to 48 above; crawl links at least 16 (were 30 and 40).

**Also (L-08e4b2, verified in Studio Play this session).** A cart going home looked for people
in boxes the size of the whole cart a little ahead of it, which covered most of its own deck: a
rider put off at the stripes who stood still held their own cart for 12 s, then it popped into
its slot. Now each look covers only the strip its nose rolls into (`Carts`, `inWay`).

## D-132 Coins: drawn last, one pile a unit, first tap takes it (S1-04a1, Nov 13)

**The moment.** A door goes up and there's a glint of gold on the concrete in the bulb's light;
you step in, tap, and it's yours with a chink while your count ticks up (GDD "Doors": about
seven units in ten have one to three coins; DOORS has gold in most of its drawers).

**The deal.** Each unit draws its coins when the floor is laid (`Deal.coinsFrom`: `CoinShare`
0.7, then `CoinSpread` 45/35/20 for one, two, three), after every other draw, so no seed's code,
notes, padlocks, guard or bag moved (holetrap.spec's replayed seed still passes). They're shown
as the door first lifts, beside whatever else the unit holds. Drawn at the start rather than as
the door opens (the GDD allows either) so a unit holds the same coins whatever order doors open.
Padlocks get no extra coins yet: S1-07 sets what a padlocked door holds.

**Where they lie.** In the bulb's pool as a tool does, at another turn, kept `DealSpot.Apart`
(0.5) from the floor the unit's tool, find or keeper takes, and that is never given up. Over 300
unit numbers in both sizes beside each thing, every pile found room.

**One pile, one tap, the whole pile.** One "Take" button a unit, not one per coin: fewer taps on
a phone, and the pile reads as one thing. Whoever's take reaches the server first gets it all
(DOORS' gold); a decision for the owner, default in place (`OWNER.md`). The count is a Player
attribute, zeroed on `Climbs.began` (new, fired by `begin`, `board`, `arrive`), nil outside a
climb so the count only shows in one. Nothing is saved (S1-01).

**The art.** A worn gold coin 0.8 across, 0.12 thick (about three times life, so a pile reads
from the doorway on a phone), a beaded rim and a keyhole stamped through both faces: the
building's own coin, for the machine on the ride. 512 triangles; piles laid out in the spec so
coins touch and never sink into each other. A faint sparkle (Roblox's built-in sparkle texture)
twinkles on the top coin so a pile catches the eye; it's the coin's own read, not atmosphere.

**Split.** The screen side (the count, the take's motion and sounds) and the import into the
place are S1-04a2: this session reached its context cap at the green point after the server.
Without `Props.Coin` the server lays nothing (one warning), so no take goes unanswered meanwhile.

## D-133 Coins on screen: the take hands each coin to the count (S1-04a2, Nov 14)

**The moment.** The door goes up, a glint on the concrete; a tap, the coins jump and spin and
are gone with a chink, and each one flies to the little count, which swells and ticks up.

**One coin, two lives.** On every screen each coin of a taken pile jumps `Lift` while it stands
up on its edge and spins (`Spin` turns), then shrinks away, a `Stagger` after the coin before:
a coin on its edge spinning is the pickup every platformer taught players to read. On the
taker's screen, the moment each coin starts to shrink a 2D coin appears at the same screen
point and flies on to the count, so the world coin becomes the one in your corner instead of
two separate effects. The flying coin and the count's coin are the real coin mesh in a
ViewportFrame, not a drawn icon (the art rule: real assets).

**Where the count sits.** At the right end of Roblox's top bar row (`GuiService.TopbarInset`),
the place most Roblox games keep their money: clear of the gate clock in the middle of the row
and above the corner map, which owns the corner under the bar. With no top bar it sits left of
the map. It shows only while the Player has a count (in a climb) and slides in like the map.

**Each landing is a step up.** One tick per coin, each `Climb` higher than the last, so a pile
of three sounds like a run up, as coin pickups in a row do in platformers. The count's number
moves only as coins land; a rise that arrives with no flight on this screen (a pile taken off
it) shows after `Grace`, a drop (a new climb) at once.

## D-134 Saving: Brix's saves, one shape, Studio apart (S1-01, Nov 14)

**What players get.** Nothing on screen; what a climb earns from here on is still yours when you
come back, on any server. Brix's Saves holds each save on one server at a time with a lease in
the same atomic write as the data (`UpdateAsync`), so a lobby-to-group-server hop never has two
servers writing it; a save from a newer game, or one the shape refuses, is never written over.

**The shape, version 1** (`src/shared/Save.luau`): `cash`, `finds` and `sealed` (name to how
many kept), `stamps` (`finds`, `sealed`, `keepers`: name to when first stamped) and `bestFloor`.
Purchases aren't in it: nothing is sold until Step 5, and a version with a migration adds them.
A shape change is a new version with a `migrate` and a sample in save.spec; never edit a
shipped version. Brix is handed to `Save.format(Brix)` since Lune and Roblox reach it by
different paths.

**Studio apart.** Studio keeps saves in `Saves.studio`, never the live `Saves`, so a test (or a
later dev command that grants cash) can't touch a player's save. Studio without DataStore access
keeps saves in memory with one warning rather than kicking the tester after 30 s.

**Can't hold it, kicked.** A save this server can't hold is Brix's default: a kick saying to
rejoin. Playing on unsaved would lose a climb's earnings without a word.

## D-135 The stuff in a unit: a mattress, a carpet, four stacks (S1-04b1, Nov 14)

**What players get.** Some units with nothing to take (S1-04b2 deals them) show somebody's stuff
when the door goes up: an old stained mattress leaning on a wall, a rolled rug tied with rope
stood in a corner, or boxes stacked nearly to the bulb (GDD "Doors").

**Built, not bought.** Both pieces are scripts in `art/stuff/` the unit's way. The stacks reuse
the moving boxes (`art/boxes`, already in the place) as data: each box's spot and turn in
`Stuff/Specs.luau`, checked by the spec to stand square on the floor or a closed box.

**Both stood against a wall.** A rolled rug lying on the floor read as a thin line from the
doorway in the sheets; stood on its end in a corner it reads as a rug at once. The mattress is
stood on its foot end, leaning back, as people leave one in storage. So every thing has a back
for a wall, and S1-04b2 only has to find it a wall.

**One atlas, packed together.** Smart project over both pieces at once, then Blender's island
packer (turning islands), gave 76 texels a stud with 70% of the 1024² atlas used; the finds' way
(a square per piece) gave 56, most of the mattress's square empty.

**Built straight, posed at export.** The mattress bakes upright and the roll lying, so the
quilting and the rug's pattern are worked out in their own flat frames; the lean, the sag and the
standing-up are applied to the vertices afterwards, keeping the UVs.

**Judged in Edit.** Doors open only through players' prompts, so the pieces were judged in a
copy of the S and M unit templates in the Edit view, door hidden, a bulb at `UnitLight`'s
settings: the quilting first showed each diamond as a pyramid (a crease along its diagonals) and
was rebuilt as a smooth dome.


## D-136 Somebody's stuff dealt into units: half the empty ones, back to a wall (S1-04b2, Nov 14)

**What players get.** Of the units with nothing to take (no coins, no tool, find or keeper, no
note), about half show somebody's stuff when the door goes up, pushed into a back corner: an old
mattress, a rolled rug, or a tower, wall, heap or column of boxes. The rest stay bare, so an
empty door still stings (GDD "Doors": some bare, some full of things to look at). With today's
deal that is about 2 units a floor with stuff and 2 bare; the share is the owner's (`OWNER.md`).

**No draw of its own.** A unit's pick says which find or keeper it holds, and a unit with
nothing in it never uses it, so the stuff is read from the pick. Nothing a seed lays or deals
moves, not even the bag's later shuffles (which a new draw at the end of `Deal.new` would have
moved). `tests/stuffdeal.spec` holds every seed's deal to a fingerprint taken before.

**Note units stay clean.** A unit with a note holds the note, so it gets no stuff; the yellow
square on the back wall is all you see.

**Wholly clear of the floor players need.** Stuff is solid and stays, so unlike a tool or keeper
it never gives up the crawl hole spots, the landing under the top's hole or where its panel
falls. That rules out the side walls for anything long: the crawl hole stretch runs 4.1 to 7.75
studs in from the door on both sides. So the mattress leans on the back wall, its face square to
the doorway, which reads better than a side wall would have. In a small unit the crawl hole
spots leave a 1.4-stud strip at the back's middle, room for the rolled rug alone: a small unit
drawn anything else stands the rug (the next in the list that fits). A narrower thing for small
units is in ROADMAP's polish list.

**Pushed into a corner.** The back wall first, into the corner the unit's number picks (odd to
one side, even the other, so a row alternates), 0.4 from each wall's middle line, too close for
anyone to squeeze behind; else a side wall, as near the back as it goes.

**Measured from the real boxes.** The stacks' sizes now count the open box's flaps and each box's
bulge (`box_reach` in `art/stuff/spec.py`): the heap grew from 4.40 x 4.02 to 4.62 x 4.44 and
its boxes re-centred. Seen in Play: every thing's parts end at the back wall's 11.60 and the side
wall's 5.60.

## D-137 Finds ride the tools' slots, each a catalog row with a grip and a heft (S1-05, Nov 14)

**What players get.** The door goes up on a teddy, a TV, a boombox or a pair of skates standing
in the bulb's light. One tap on Take and it's in a slot and in your hand: it comes up into your
view from below, sags as its weight lands and sways heavier as you walk, the heavier the find
the slower it comes up (the TV most, the teddy hardly). Its slot shows its picture and its name
shows over the slot button. Friends see it hanging from your left hand. Drop it and it falls
ahead of you with its own sound and stands there with its Take prompt; get caught and it drops
where you fell for a friend to take, as the GDD says. Full slots refuse it ("Hands full", as for
a tool): drop something or leave it.

**One slot system, not two.** A find is a row in the tools' catalog (`find = true`) and lies,
is held, dropped, handed over and caught by `Slots` exactly as a tool is (Lethal Company's scrap
shares its slots with your gear). Its template is built at run time on each side from the find's
art in `ReplicatedStorage.Props.Finds`, with its `grip` (where a hand closes, measured on the
art in Studio) at the model's pivot, as a prepared tool's grip is, so nothing needs importing
again. `Deals` lays a dealt find with `Slots:lay`, standing and facing the doorway as before.

**Weight is felt, not a rule.** `heft` (0 to 1) changes only the first-person motion
(`Tools.Heft`): a find comes up with no spring, sags 0.16 studs at the most and rebounds once,
and sways up to 1.8 times a tool's. Your walk is the same with any find: slowing a carrier (as
Lethal Company's weight does) would be new design, so it's an `OWNER.md` question.

**Sounds.** Each find has its own take and drop from Pro Sound Effects (measured in Studio,
docs/STUDIO.md): the boombox's plastic radio clack, the TV's slow hollow knocks and a big
crunching thud, the teddy's soft cloth grab, the skates' wheels rattling.

## D-138 Pay and keeping happen the instant the gate hits its post (S1-06, Nov 14)

**When.** Climbs fires `shut` the instant a floor's gate hits its post with friends aboard (the
top floor too), before the ride or the end. `GatePay` pays and keeps then, so the reward lands
on the slam, the climb's payoff, as Dandy's World pays at its elevator.

**Who.** Everyone in the car who is alive and not wrapped (GDD "Earning nothing"). A floor pays
a player once a climb (`Pay.owed`), so a ride that comes back to the same floor never pays twice.

**How much.** 10 coins on floor 1 and 2 more each floor (`Pay.Base`, `Pay.Rise`): about three
batteries, against the ~37 lying behind every door of floor 1. The GDD's trap bonus and a harder
floor paying more are untested bets and left out (`OWNER.md`).

**Keeping.** `Carry.keep` takes the finds out of the slots and leaves the tools; `Save.keep`
adds one of each to the save's `finds` and stamps the book's finds page the first time; the save
is written at once. A save not loaded yet holds the finds in GatePay until it loads.

**On screen.** The server tells the rider's screen first (`GatePay` remote: coins, kept keys),
then changes the count, so the coins are already flying when it rises. Coins burst from above
the middle into a ring and pour into the count, at most 12 drawn (`Pay.split`), each landing
worth its share, ticks climbing, a gold "+10" by the count. Each kept find rises from the slot
box on a gold-rimmed disc with a ring and sparks, its own pick-up sound and a bright chink,
hangs, and flies up off the screen. No words.

## D-139 What the game records, and where from (S1-02, Nov 14)

**Through Brix.** Brix's Analytics checks every record against one plan (`Record.plan`) and
sends it to Roblox's AnalyticsService (`Brix.Roblox.AnalyticsSink.analyticsService`), so a
misspelt name or a label past 50 bytes is dropped with its problem instead of making a stray row
on the dashboard. The pin moved to Brix `6717740`.

**Pure book, listening server.** `Record` (shared) holds the plan and a book with one method per
game moment, generic over the player so the spec drives it with names and Brix's recorder.
`Recording` (server) only listens to signals the systems fire where things happen (Coins'
`earned`, Deals' `dealt` now naming who opened it, GatePay's `kept`, KeptPlayers' `freed`,
ClimbEnds' `ended` and `again`, LobbyCars' `departed`, and Climbs' and Keepers' own), so no system
knows about analytics, and Brix's later ENG-12c can take its place.

**What, against the GDD's list.** Join to first door: `firstDoor` (seconds from joining this
server) plus `carLeft` (seconds from joining the lobby to the car leaving); live, the two plus the
trip's load make the GDD's number, since the trip doesn't carry the join time. Doors a minute and
how many gave something: `doorOpened` with `gave`. Caught on each floor: `caught`. Floors carried
wrapped: `freed`'s value (0 while kept friends stay on their floor). The floor each climb ends
on: `climbEnded` and the `climb` path's `failed`. Again: `again`. Who buys what and where: nothing
is sold yet. Every coin earned: economy records (`pile`, `gate`) with the count after; the count
is the climb's.

**Labels.** Floors 0 to 40 each their own label and "41+" past it (0 is Studio's test hall); team
sizes 1 to 8 and "9+"; finds by `Deal.Finds`. Roblox folds labels past 8,000 into "Other".

**No onboarding funnel yet.** Roblox's docs don't say whether its onboarding steps count only a
player's first time, so the game would need its own "first visit" mark in the save (a version 2).
The `climb` funnel repeats instead, once a climb, its run a GUID.

**Problems.** The first 8 different problems are warned in full, then a count once a minute, so
a server over Roblox's 120 a minute plus 20 a player never floods its output. Studio prints each
record sent as one line beside AnalyticsService's own "event fired" line.

## D-140 Behind a padlock: always a find or a tool, sometimes a monster with it (S1-07a, Nov 14)

**The moment.** You cut a padlock and the door rolls up on a TV in the bulb's light, and behind it
a Mannequin standing in the dark. The GDD ("Doors") says a padlocked door "always has something
good behind it" and "the highest chance of a monster". Read as both at once: the good thing is
always there, and a monster sometimes stands with it, as Escape from Tarkov's locked rooms hold
its best loot and Lethal Company's best scrap lies where its monsters are. The other reading (a
monster instead of the good thing) breaks "always", so it went to `OWNER.md` as a question.

**The deal.** A padlocked unit deals from `Deal.PadlockedHolds` (a find 70, a tool 30, never
nothing, whatever the mood). Then `Deal.besideOdds`: the mood's keeper odds times
`PadlockedKeeper` (2), so in Build 20 asleep and 10 awake in 100, under the same awake cap and
the guard's kept place as any door (`limit`). The keeper rides in `Contents.beside` with its
name in `keeper`; `Deal.keeperIn` reads a unit's keeper either way, for `Keepers` and
`KeptPlayers`. Replaced: the old multipliers (`Deal.Padlocked`), which could deal a padlock
nothing (9 in 100) or only a keeper (27).

**No new draw.** The second choice comes from where the unit's roll landed within its find or
tool's share (`landOn`): as random as a fresh roll and free of which it was. So nothing a seed
lays moved: deal.spec pins a fingerprint of every seed's code, notes, padlocks, guard, rolls,
coins and bag from before. What doors deal did change (stuffdeal.spec's fingerprint retaken).

**Tools rarer.** GDD: about one unit in twelve (a starting guess). Build's tool odds 20 to 6, the
rest onto nothing (Peak 30 to 15, Relief 20 to 6); with the padlocks' tools a floor comes to 1
in 11.8 on floors 1 and 3, 1 in 10.9 on floor 6 (deal.spec measures it).

**Laying both.** `Deals` lays the find or tool first, then the keeper behind the bulb clear of
the find's floor (`DealSpot.inUnit`'s `taken`), coins clear of both. `Dealt.keeper` is where the
keeper stands (its own spot here, `place` for a keeper-only unit); with no room it stands
nowhere, said in Output. Seen in Play: Unit 305 laid the TV at 2 studs in front of the
Mannequin. On the dev floor all five padlocked units drew a Mannequin: chance (their rolls
happen to bunch); over 3000 seeds, laid the server's way, the share is 30%.

**Batteries** (S1-07b) wait for the flashlight to run down (S1-09); no battery art exists yet.


## D-141 Tools wear out with a mark on the slot and a break you feel (S1-08, Nov 14)

As Minecraft's tools do (the precedent): each wearing tool has a `wear` row in `Tools.Catalog`
(uses, a short `late`, its snap sound, the colours of its bits). Bolt cutters 3, the saw 2, the
air horn 3, from the GDD's table. The padlock and the bubble wrap have no wear: each is used up
whole as it's placed (`Slots:spend`), so a one-notch mark would only ever be red. The ladder and
finds never wear. Uses live on the server with the tool itself, so a dropped or handed-over tool
keeps its wear; screens read them from `ToolUses1` to `ToolUses3`.

- The use that spends the last breaks the tool `late` seconds after (0.3 to 0.85 s), so the
  job's own sound lands first (the padlock's snap, the panel's clang, the horn's last blast) and
  the tool's break is a second, separate sound. Until it goes, the hand can't move and the tool
  can't be used.
- The break is in the world, not only on your screen: the whole tool jumps out of the hand,
  ten small bits in its colours fly (real parts, server-owned), it clanks on landing (keepers
  hear it as a dropped tool), lies 2.5 s and fades. No new art: each tool is one mesh, so it
  can't split; broken-piece art is on the polish list.
- The mark is notches, not a bar: with 2 or 3 uses, countable notches read better at phone size
  than a draining bar. The last one turns red and breathes; a spent one flares and pops out.
- The horn's last blast sags in pitch and dies (`Horn.Dry`), which is what a canned horn does
  when it runs dry, so the horn warns by sound as well as by its notch.

## D-142 The flashlight runs down: the server's seconds, each screen's flicker (S1-09, Nov 14)

- The charge is seconds of light, owned by the server per player (not per torch), so it carries
  through floors and a new character. It drains only while on and only while the torch is in a
  hand; everyone is full as a climb begins (`Climbs.began`); a battery calls `Flashlights:fill`
  (S1-07b), which says false when you're full so the battery stays for a friend.
- The Player carries whole seconds, rounded up (`Charge.Attribute`), written only as they tick:
  one small write a second while it's on, which also lets friends' screens see you dying. Each
  screen follows it smoothly between ticks (`Charge.follow`, kept inside the written second).
- The flicker is drawn by each screen from what's left (`Charge.glow`), not sent: a long first
  stutter as the half minute opens (and again when you switch a dying torch back on), then
  short ones far apart that close in on an ease and go darker, with whole moments of black at the
  end. The light sags to about half and browns; over its last 1.2 s it dies to nothing, so it's
  already dark when it clicks off. While it flickers the server still counts it as on: a
  Mannequin stays held until it's dead.
- Your screen puts it out on its own as its reckoning hits zero, a beat before the server's
  tick; so a torch switched off with under 1.5 s left is dead (`Charge.Spent`), and the two never
  disagree about a sliver.
- The meter is a ring of 12 ticks inside the button's edge (a clock face: a full turn is a full
  torch), lit warm, red and breathing for the last half minute, a faint ghost when spent. On a
  keyboard or gamepad the same button sits in the bottom right corner, as there's no jump button
  to sit over. No numbers, no words.
- Dead, a press only clicks softly (the off click at 0.55 speed), dips the torch in your hand and
  wobbles the button; the torch picture on it goes dull. Nothing explains it.
- The buzz is Pro Sound Effects' "Light Bulb Buzz 2" looped over its steady stretch, heard only
  in a stutter and loudest in the dips, retuned each blink so it crackles. No new lights: the
  flicker only changes the beam's and spill's brightness and colour, written when they move by a
  visible step.

## D-143 Batteries lie in units, and only a torch that's lost a tick takes one (S1-07b, Nov 14)

- About one unit in ten has a battery (`Deal.BatteryShare`, the owner's default in OWNER.md). It's
  the unit's own draw, taken after the coins in `Deal.new`, so nothing else a seed lays moved
  (deal.spec's fingerprint, every unit's coins included, is unchanged). A unit with a battery has
  something to take, so it holds no stuff; stuff stays at half of the units with nothing to take.
- It lies on its side in the bulb's pool, as coins do, at its own turn and spread
  (`DealSpot.inUnit(..., "Battery", ...)`), clear of the unit's tool, find, keeper and coins:
  Deals lays the coins first and passes their floor on. Rolled up to 28 degrees either way, so the
  plus on its amber band shows from the doorway; a faint cold glint on its steel button.
- "If yours is full you leave it" is read as the ring: a torch takes a battery only once its ring
  has lost a tick (`Battery.wants`, 25 seconds of a five-minute torch). A battery is never spent on
  a few seconds of light, and the rule is one the player can see. While your ring is full the
  battery shows you no button (BatteryView hides it on your screen); the server refuses the press
  anyway (`Flashlights:fill`). No text says why, as the owner asked.
- Taking one doesn't switch a dead torch on: your screen owns the switch (D-142) and would undo a
  server-side switch. The light snaps back for a flickering torch at once; a dead one is pressed
  on, now with a full ring.
- The take on every screen: a few sparks off its button, a hop end over end, a flight into the
  taker's torch (yours as drawn in your hand) shrinking as it slides in, then a clack-click. The
  sound is the torch's own two measured clicks: the off click slow and low (the cell seating),
  then the on click (the cap home) 75 ms later; friends within 24 studs hear it. No new sound asset
  was measured for it.
- Art: `art/battery/`, a chunky D-cell four times life size (0.9 by 0.46 studs) in the coin's
  way: one MeshPart, 896 triangles, the Battery set at 512².

## D-144 The ride takes about 20 seconds, a slow freight grind (S1-10a, Nov 14)

- The GDD's ride is about 20 seconds, filled by the car's machine (S1-10b, c) and later the
  team's choice. It stays one floor's climb (16 studs), so the car crawls at about a stud a
  second: brakes off at 0.8 s, full speed by 3.2, a 12.6 s cruise with three cable clanks, a 3 s
  slowdown, level at 18.8, the gate folding at 19.5. An old freight car's speed, and the shaft
  creeping past the gate keeps the dread of the next floor in view.
- One timeline for every ride, the first one (lobby to floor 1) too. Its riders were already
  sent through the trip's black at 2.2 s and land on the climb's server 6.2 s before the car
  levels, as before (`Trip.Since = Ride.arrives() - 6.2`), so the first ride looks as it did:
  the longer middle is the teleport's black, which gives a slow phone more time. A lobby car is
  back in its bay 2 s after its ride opens (`Boarding.Back`).
- The motor and the rumble recordings are shorter than the ride, so each loops on its steady
  stretch (`Recording.Loop`: Sound.LoopRegion inside the PlaybackRegion; `Ride.position` puts a
  late joiner on the loop). Seen in Play: both wrap cleanly and run until the winding-down.
- The lurch grew (0.08 to 0.09 studs) because the gentler speed-up no longer adds a sink; the
  hand-off to the next car moved to the last clank (`Climb.HandOff`), and a left-behind player
  stands frozen in the dark lobby hearing the car grind away until 3 s before it, rather than
  sitting in black for 13 s.

## D-145 The machine in the car: one cabinet, three rows behind one pane (S1-10b1, Nov 14)

- Built as ROADMAP's plan has it: a storage building's supply machine in oxblood enamel, two
  battery bays under four tool bays, one steel rail across the glass per row with a price window
  and a push button per bay, the coin plate and the bin's flap under the glass, a lit sign on top.
  It stands in the car's back-right corner facing the gate, eyes level with the top row.
- The rails stand on the front of the glass, not behind it, so the buttons are something you
  could press (as an old cigarette machine's knobs are); the glass is one pane behind them.
- The tubes sit just behind the glass at the top of each row, under the next rail: you see them
  catch, one row at a time, rather than only their light. The liner is an aged off-white, not
  bright white: lit by cold tubes in a dark car a clean white liner glared in the look sheets.
- One texture set for everything textured; the liner and shelves get 0.55 of the cabinet's
  texels a stud (seen only through glass), which lifts the cabinet's face. Geometric bevels were
  dropped for the bake's rounded normals: the thin bevel strips fell between texels.
- The six price windows are one coplanar part so a single SurfaceGui draws them all; the coil and
  the button are one part each, cloned per bay, so a coil can turn and a button sink alone.

## D-146 The machine wakes on the ride, a row at a time (S1-10b2, Nov 14)

- Every floor's car has the machine in its back-right corner, dark while it stands at a floor.
  On a ride from floor 1 up it wakes for those aboard (and anyone watching a friend), the same
  on every rider's screen from the ride's one clock: after the slam and the lurch, each row's
  tube tinks and flashes (two, one, three tries) and catches, bottom row first from 1.2 s; the
  sign stutters on with a buzz at 3.75 s, before the first clank; the price windows' LEDs show
  dashes; a ballast hum swells with what's lit. It dips with the car's lamp (0.7 of its dip) and
  cuts out as the gate starts to fold, the sign a beat after the tubes. The first ride, up from
  the lobby, never wakes it (nobody has coins yet). Old fluorescent starters, as players know them.
- Not in the lobby cars: their back wall carries the climb's results, which the machine would
  hide. So a lobby car has no machine and floor 1's car has a dark one (ROADMAP polish).
- The tubes are three plain cylinders from `Specs.Tubes` (the export now writes them), not the
  one tubes mesh, so each row catches alone. One real light, into the car; a second shone back
  into the cabinet blacked out every other light on screen in Play, so the bays read by their
  Neon tubes.
- Sounds, Pro Sound Effects': "Toggle Switches Moviola Editing Machine 17" pitched up for the
  tink (higher each row up), "Light Bulb Buzz 3" gated by the sign's flicker, "Transformer Hum 1"
  for the hum (36 s, longer than a ride). Volumes are a first guess against the motor.

## D-147 The machine's stock: dealt per ride, kept by the ride, shown as the light finds it (S1-10c1, Nov 14)

- The server deals the stock once per ride that wakes the machine, the moment the ride's value
  appears on a car, and keeps it by that value. The next floor's car takes the ride over
  mid-way with the same value, so it shows the same stock without Elevators knowing about the
  machine; c2's buy changes the one copy and both cars follow. A ride no car carries is
  forgotten. Lobby rides deal nothing.
- Batteries every ride in the two bottom coils, two to a coil (they're wider than one loop);
  three or four of the five tools that fit a bay (not the ladder), each once, each in a tool bay
  picked at random so the same tool moves about. Prices are starting guesses, the GDD's for the
  padlock (6) and bolt cutters (10); the others between (OWNER.md).
- One attribute, `key:price:count` per bay split by "/". The screen draws the prices from it;
  the buy will charge the server's own copy. Decoding refuses anything malformed.
- On screen the stock exists only while the machine is awake: each row appears at its tube's
  first flash (the sudden light hides the pop and reads as the light finding it) and goes at the
  cut. A dark machine at a floor stands empty, so nobody window-shops a stock that will change.
- Each thing stands where the coil's wire runs along the bottom of its loop, one pitch back from
  the tip, so the front loop curls in front of it as on a real machine. The coil's front and
  pitch are now in the generated Specs (art/machine/spec.py), not copied by hand.
- Long tools lie across the bay face to the glass at about 1.7 studs, a little leaned; the
  padlock grows to 1.35 so it reads from the gate. The LEDs test 88 for 0.18 s as each row
  catches, then settle on the price, an old machine's power-up.

## D-148 The buy: the server settles it in one step, every screen reads the sale off the stock (S1-10c2a, Nov 14)

- A bay's "Buy" button is live only while its row is lit and the price has settled (0.2 s after
  the tube catches) and until 1.2 s before the power cuts, so you never buy blind and the thing
  has dropped while the machine is still lit. Its name is the thing in the coil, since the
  button Roblox shows depends on where you stand and look (measured in Play: aiming the camera
  at a button shows that one, but not always), so you always see what you're about to buy.
- One server step, nothing yielding: the thing first (a torch refuses a battery while its ring is
  full, the slots refuse a tool with no room or a big tool in your hands), and the coins only if
  it went. A refused press costs nothing and says nothing (the price, the ring and the slots are
  on screen); a press with too few coins clicks, buzzes and blinks its price on your screen.
- The tool is in your hand on the server at once. The flights (coins into the slot, the thing to
  your hand) are c2b; until then the thing is gone from the bin as the flap settles.
- No remote for the sale: the stock attribute changing with only a count lowered is a sale
  (`Buy.sold`), so friends see it the same way, and a new stock still refills. `Bought` (bay,
  serial, buyer) is stamped on the machine just before, for c2b's flight to the right hand.
- Sounds reuse the game's measured recordings (a switch click pitched up, the ballast hum pitched
  to a motor whine, the starter's tink pitched down to the flap's knock, the thing's own drop
  sound in the bin); starting guesses for the owner to judge.
- Studio only: Workspace `DevCoins` sets every count in a climb, to stage a buy.

## D-149 The buy's flights: the server settles at once, screens hold the change until it lands (S1-10c2b, Nov 14)

- The server still settles the buy in one step (D-148). The flights are only what screens show:
  the buyer's screen is told first (`Buy.Remote`, fired just before `Coins:spend`, as GatePay
  tells the pay), so its coins can leave the count one at a time instead of it dropping.
- The coins reuse CoinView's own flyers (the same pictures, tick pool and count), run backwards:
  each leaving ticks the count down, lower each time, and the coin curves into `Specs.Slot`.
  At most `Buy.Coins` (8) are drawn, each worth its share (`Pay.split`), all in the slot before
  the thing has dropped.
- `InFlight` is a small client registry of things still flying to a player's hand, counted per
  player and per hand. The vend holds it from the moment the sale reaches the screen (the server
  has already given the thing) until it lands or the vend is cut short. ToolView keeps your hand
  empty meanwhile and then shows the tool where it flew to, with its weight, no swing; a
  friend's held tool is hidden here (`LocalTransparencyModifier`); FlashlightView keeps the
  torch's charge where it was.
- Your own torch now follows the server's charge only once a frame, never inside the attribute's
  signal: the charge arrives a moment before the sale's stock in the same batch, so lifting it in
  the signal filled the torch before the hold began (seen in Play, fixed).
- The give is quiet on the server (`Slots:give(..., quiet)`): every screen plays the tool's
  pick-up sound where it lands, so it isn't heard a second early.
- `HandAt` is where a player's hands are on this screen, shared by BatteryView and MachineVend:
  your tool at full size where ToolView draws it (it draws it small near your eye, which looks
  the same), a friend's at their real held tool.

## D-150 The faint mark: a chalk ring on one note's jamb, shown only in your own beam (S1-11, Nov 14)

- The precedent: Phasmophobia's fingerprints show on a door only under the light you hold (from
  memory). The mark rewards sweeping your beam along the frames; it never makes a trail.
- Which floors and which note (`Deal.markFrom`, drawn last in `Deal.new` so it moves nothing else
  a seed lays): floors 1 and 2 always have one, so a team meets it early; above, 6 floors in 10
  (`MarkShare`, a starting guess in OWNER.md). Never the guarded note's unit: that one already
  shows itself to a peek, so the mark always points somewhere new.
- Where: the middle of the left jamb's face as you face the door, at 4.4 studs (about eye
  height, so a beam aimed at the door crosses it). The jamb is 0.45 wide on both sizes, so the
  ring is about 0.33 across. Always the same jamb, so a player who has seen one knows where to
  look, as the crawl hole is always in the same place.
- The art is a plane with a chalk texture drawn by numpy (no bake: it's flat), its alpha into
  the BSDF's, so it imports in AlphaMode Transparency. It lives in the hall piece's folder, not
  the unit, so nothing that dresses or fades a unit's parts meets it.
- The server places it hidden (Transparency 1) and tags it; each screen sets its own
  transparency. `FaintMark.seen` takes your eye and aim from the camera (first person: the torch
  is at your eye) and gives 0 to 1: nothing past 9.5 studs or 25 degrees off the beam's middle
  or from behind; fullest within 5.5 studs and 14 degrees. It eases in fast and out slower, and
  is scaled by your torch's light this frame (`Beam.light`, new), so a dying torch takes it with
  it. Fullest is 70% solid: faint chalk, never paint.
- No sound and no word when it shows: a sound would find it for you. Friends' beams don't show
  it yet (their aim is sent a few times a second); ROADMAP polish.

## D-151 Cash: the coins left at a climb's end, one for one, saved the moment it ends (S1-12, Nov 14)

- The precedent: Dandy's World's Ichor is one money for its in-run shop and for keeping, so what
  you don't spend is yours (from memory); the tally counting up on the results is DOORS'
  end-of-run Knobs (from memory). The GDD says only "turned into cash", no rate.
- One coin is one dollar (`Cash.PerCoin`, a default in OWNER.md): the number your coin count showed
  is the cash on the board, so the swap teaches itself with no words. Cash shows as dollars
  ("+$42", `Cash.text`), so it never reads as more coins; no new icon was needed.
- When: the moment ClimbEnds ends the climb (`ended`, once an end), not at the cover or the
  results. The last gate's pay lands first (Climbs fires `shut` before `topped`, both at once),
  every count freezes there (Coins' `close`: no take, pay or buy after; a second call hands back
  nothing, so a double end can't pay twice), and the cash goes straight into the save and is
  written. Leaving afterwards, mid-count or in the black, or a shutdown, can't lose it: the save
  is let go with it (Saving). The counts stay on screen through the end and go at the cover
  (Coins' `clear` on ClimbEnds' new `covered`), so the lobby no longer shows a stale count.
- A climb that never ends for you (you leave mid-climb, the server shuts down under it) makes no
  cash: coins only count inside a climb. A save not loaded yet holds the cash until it loads.
- The board: each friend's cash under their photo (the results value gained a fourth field per
  row, `id:fate:floor:cash`, read back as 0 when missing). Every figure counts up together once
  the photos are pinned (`Cash.CountAt`), Cubic-eased so the last dollars land one by one; yours
  is bigger and bright, ticks from the board higher as it rises (Coins' `Tick`, two taking turns,
  at most one each `TickGap`) and lands with a swell (`Pop`), the chink and the jingle. Friends'
  count silently; $0 is dim. The board grew 0.4 studs at its foot (still above the rail).
- Recorded: coins out (`cashOut`, item "Cash", count 0 after) and cash in (`climb`, the saved
  total after), a second currency "Cash" in the plan.

## D-152 Sleepers are placed with the floor; the director deals only what's awake (S2-01, Nov 14)

- The precedent: Left 4 Dead's Witch is already sitting in her spot, asleep, before the team
  turns the corner (from memory), while its director still places items and infected as the
  team moves. The GDD ("What changed here", "Doors") asks for exactly this split: sleeping
  monsters are put in their units when the floor is made, so one can wake behind a shut door
  (S2-03) or be let out by a wrong code (S2-04); coins, finds, tools and awake keepers are still
  dealt as a door first lifts.
- How many: 10 in 100 units hold a sleeper (`Deal.Asleep`), Build's old asleep odds, now whatever
  the mood: a mood no longer deals sleepers. Behind a padlock twice that (20 in 100, standing with
  its find or tool). Never in the guarded note's unit (its keeper is awake) nor in the lobby's
  hall on floors 1 and 2. Each is a keeper that has joined by that floor (the Mannequin).
- The other odds are now out of the 90 in 100 the sleepers leave, so every kind lands as often as
  before in Build (54 nothing, 25 finds, 6 tools, 5 awake; a padlock's 10 awake out of the 80 its
  sleepers leave). Peak loses nothing (its old 10 asleep). Relief's sleepers went from 5 to 10, the
  5 taken from its empty units (49), keeping its finds.
- The awake cap is unchanged: past it an awake keeper is dealt asleep as its door lifts, as
  before. Those aren't placed sleepers (they appear only once their door is up); S2-03 can find
  them as sleeping bodies standing in their units.
- Seeds: the sleepers are drawn last in `Deal.new` (two numbers for every unit, whether it can
  hold one or not), so the code, notes, padlocks, guard, bag, coins, batteries and the mark lay
  as before (deal.spec's fingerprint unchanged). What doors deal did move (stuffdeal.spec's
  fingerprint retaken), so older Studio recipes naming what a unit holds may be stale.
- Who knows: the deck (`deck.sleepers`, slot to keeper name) and the keepers' brain, which gets a
  floor's sleepers as it's laid (`Keepers.add`) and hands out those still behind a door nobody
  has lifted (`Keepers.sleepers(floor)`); each leaves as its door first lifts and its body stands
  where the deal laid it, as before. In Studio, Output lists a floor's sleepers as it's laid.
  The body is still stood only when its door first lifts: standing every sleeper up front would
  cost instances for no one to see, and a body woken by a noise behind a door never lifted has no
  behaviour yet (S2-03 decides it). A caught friend is never stored in a sleeper's unit.


## D-153 The breaker box: a safety switch with its lever on the side, lamp in the door (S2-02a, Nov 14)

- The precedent: Phasmophobia's fuse box, a box on a wall that the ghost switches off and the team
  goes to find and switch back on, its light green when on and red when off (GDD "The breaker",
  checked Nov 13). The look is the heavy-duty safety switch every building's back hall has.
- The lever is on the box's right side and swings in a plane square to the wall, pointing at the
  hall: up 42 degrees is on, down 42 is off. Halls are seen along their walls, so a lever that
  moves toward and away from you reads in profile from down the hall (judged in Studio from 11
  studs along), and from across the hall its red grip sits clearly high or low (1.6 studs apart).
  A lever on the door's face, swinging flat to the wall, would read only head-on.
- One pilot lamp, untextured, so the game picks its colour and brightness (S2-02b): green with the
  power on and red with it off is the starting guess, Phasmophobia's; a red lamp is also the only
  thing that gives the box away in the dark.
- Sized to be found: about one and a half times a real switch, the box's middle 4.45 up (just
  under eye height), a plywood board behind it and a conduit to the wall's cap so it reads as
  the building's power from across a hall. A yellow sticker with a lightning bolt says
  "electrical" without a word.
- The game turns the lever with `CFrame.Angles(math.rad(a), 0, 0)` about `Specs.Pivot`; S2-02b's
  one-second hold drives `a` from `Specs.Down` to `Specs.Up`.

## D-154 Throw the breaker and switch it back: the server owns it, the lights come back on (S2-02b, Nov 14)

- Where it hangs (`Breaker.spots`): a plain wall along a straight hall, or a dead end's face,
  never in the lobby's hall (from the lobby to the first fork), so switching it back means going
  out into the dark floor. A junction's walls are the junction piece's own, so they're left out.
  The deal draws the spot last (`deck.breaker`), so every seed keeps the floor it had. Over 480
  floors in the spec, none lacked a spot.
- Thrown (`Breakers:throw`): every power zone on its floor cut, so every hall light goes blind
  (`MotionLights:cut`); the elevator has its own light and keeps it. Until S2-02c's Mannequin,
  only the Studio dev command throws it (Workspace's `ThrowBreakers`).
- Switching it back is the same one-second hold as cutting a friend free, judged on the server
  (`Breaker.judge`: the hold's length seen by the server, reach to the grip, the presser up and
  not wrapped, one press per half second). A refused hold shows no words: the lever falls back
  under your hand, which says it (no obvious refusal text). Nobody can throw it by hand yet;
  S2-06's light-sticking monster will need "off and on again", so the button can grow an Off.
- The lights come back on (an untested bet, in OWNER.md): the moment the power catches, every
  fixture on the floor lights at once, as real motion lights do when their power returns, then
  goes dark on its own 7.5 seconds (`MotionLights:flash`, the alarm's quiet flash: keepers aren't
  sent to look). Coming back dark would make the payoff invisible from the box. A side effect:
  a Mannequin standing under a light is frozen for those seconds.
- The feel: the lever slams down with a heavy clunk heard across the floor (a Pro Sound Effects
  circuit breaker, slowed), the camera kicking for whoever is near; the pilot lamp red Neon,
  pulsing slowly, with one short red light 1.6 studs out in front washing the box and the wall
  around it. Held, the lever creeps up just past half way under the hand (every friend sees it:
  the server marks the box `Straining`); caught, it snaps up with a click, the lamp turns a calm
  green and a low mains hum swells and dies over three seconds.
- The glow's numbers: Studio's eye adapts to the dark, so a lone light in a black hall gets
  brighter on screen over a few seconds. At range 6 the hall went red end to end; at range 4,
  brightness 1.5 only the box and its patch of wall do. It's on only while the box is thrown,
  when every hall light on the floor is out, so the floor's light count only drops.

## D-155 The Mannequin throws the breaker: a wander now and then, keener higher up (S2-02c, Nov 14)

- When: a loose Mannequin, picking where to wander next, heads for the box instead by a chance
  from the floor's Random (`Breaker.errand`), as Phasmophobia's ghost switches off the fuse box
  (D-153). It never decides mid-hunt or mid-look: hearing or seeing anyone calls the walk off, as
  the GDD's "doesn't always come for a player" reads. Only a row that freezes in light takes it
  (`Keeper.offer`): the one that wants the dark. The floor's Random is drawn only while an errand
  is offered, so floors without a box or Mannequin roam exactly as they did.
- How often (starting numbers, in OWNER.md): 8 in 100 picks on floor 1, 2 more each floor up, at
  most 30. A Mannequin picks about every 14 seconds of wandering (measured in Lune), so one left
  alone cuts the power about every three minutes on floor 1, every minute and a half by floor 5,
  every 48 seconds from floor 12. None while the box is thrown, and none for 45 seconds after the
  power comes on (the floor laid, or switched back), so a floor starts lit and a switch back on
  buys a real breather. The server offers it every step, so a box switched back while one walks
  there calls that walk off.
- Its walk: at its wandering pace, by the halls, held by any light on it as ever: the GDD's "a
  flashlight on it stops it". It stands 2.6 studs out from the wall square in front of the lever
  (`Breaker.stand`), its held-out hand on the grip, throws it, faces the box and stands its linger.
- The clunk carries to keepers as a slam does (110 studs along the halls, `Breaker.ClunkHeard`),
  not the 320 a player hears it: the ones near the box come to look, so whoever goes back walks
  toward them, without the whole floor converging. The thrower hears its own clunk and stands.
- No text: nothing tells players it's going; the clunk and the dark are the tell.


## D-156 When sleeping monsters wake: waves on a hidden schedule, sooner and bigger higher up (S2-03a, Nov 14)

- The precedent: Left 4 Dead's director sends a horde at a team that lingers (from memory), and
  Dead by Daylight's endgame collapse turns a stall into a race. Here it's sleepers behind shut
  doors starting to pound: no clock on screen and no words (GDD "Sleeping monsters wake"; AGENTS
  "Monsters, not the building"). The pounding is the warning and a padlock is the answer.
- The schedule (`Waking`), starting guesses in OWNER.md: the first wave at 240 s on floors 1 and
  2, 15 s sooner each floor above, never under 150 s; three at a time on floors 1 to 3, one more
  every three floors, never over five; 120 s between waves on floors 1 and 2, 10 s closer each
  floor above, never under 75 s.
- A conflict, settled by the GDD: ROADMAP's S2-03 line said "four minutes on floors 1 and 2 (six
  above)", which would make higher floors start later, but the same line and the GDD both say it
  starts sooner higher up. Built as sooner; the "six" is in OWNER.md for the owner to settle.
- Phones: `Waking.AwakeMost` is six keepers stepping on a floor at once, loose or pounding (twice
  `Deal.awakeCap`'s highest loose cap, since a pounding one stands still). A wave that would pass
  it waits, and the wakes it owes come as room opens. The director's own cap on loose keepers is
  unchanged, so a floor can now hold more loose keepers than the director deals: that's the
  pressure the GDD asks for, and it's capped.
- Which doors: a fair random pick among `Keepers.sleepers` (the units whose sleeper is still
  behind a door nobody lifted), so the team never learns which door goes first. Padlocked ones
  can be picked: they pound and never break out, a scare with no danger.
- How a woken sleeper stands and pounds is S2-03b's: stand its body when it wakes (not every
  sleeper up front, which costs instances nobody sees) and hand it straight to the trapped
  keeper's clock (`Keeper.trap`), whose break-out at 90 s is the GDD's number already.

## D-157 Sleepers wake for real: the clock starts with the first player on the floor (S2-03b, Nov 14)

- A floor's waking clock starts the first step a living, unkept player's feet are within 4 studs
  of its own level (`Keepers` `ON_FLOOR`), not when it's laid: the floor above is laid as the gate
  opens, while the team is still below, so counting from the lay would cost them the ride.
- A woken sleeper's unit is dealt then, door still shut (`Deals:dealShut`), so it stands exactly
  where a door lifting would have stood it, with the unit's find and coins laid around it as
  usual. Only woken sleepers get bodies; the rest stay a name on the floor until then (D-156).
- It stands awake facing its doorway and goes straight to the trapped keeper's clock
  (`Keeper.trap`): it bangs, dents the door, is heard by keepers, and bursts at its row's
  `breakOut` (90 s). A door already padlocked holds it from the start (`Keeper.padlock`), so a
  padlocked sleeper is a scare with no danger, as D-156 said.
- Output says one line a wave (how many, which units, how far in) and the trap's line for each;
  Deals' own Studio line for the unit's contents also prints. Nothing on screen: the pounding is
  the only warning (AGENTS "No text that explains a rule").
- Studio's Workspace `WakeSleepers` skips every floor with the team on it to its first wave.

## D-158 The owner's Nov 14 fixes: stepping out, the ride on a phone, the first cut, the coin icon

- **Nobody is shut in a car** (owner: "if anything it should force everyone out if it's going
  to shut"). As a floor's gate starts to shut behind the team (`Elevators:arm`, `Ride.Linger`
  after it opened), anyone still in the car is stood on the landing in front of it, side by
  side (`Departure.outAcross`), facing the hall, and the gate folds shut behind them. Chosen
  over holding the gate open while anyone's inside: the car would become a safe room. A lobby
  car already set down anyone the departure leaves (LobbyCars).
- **The ride is seen before the trip's black.** On a live lobby a car's group teleports to its
  own server; the black used to come 1.6 s into the ride, before the car had visibly moved. It
  now comes at 4.8 s (`Trip.FadeAt`): the lurch, the lobby going dark, the shaft sliding past at
  full speed and the first cable clank first. On the group's server, each screen fires
  `Remotes.TripReady` once loaded, and the group is stood in floor 1's car mid-ride only when
  every arrived screen has (at most `Trip.LoadMost`, 25 s, after the first arrives), so a phone
  still loading no longer misses the last six seconds of the ride. The remote carries nothing;
  a player can only mark their own screen ready.
- **The Mannequin's first cut comes soon.** At the old odds (8 in 100 wander picks on floor 1)
  the owner never saw it, and on floors 1 and 2 few Mannequins are loose at all. Until the power
  has been cut once on a floor, a loose Mannequin's chance is at least `Breaker.ErrandFirst`
  (half its picks), so the first cut comes within about half a minute of wandering after the
  floor's 45 s of light; after that the floor's own odds (D-155) hold. Its signature move is met
  on every floor that has a loose Mannequin.
- **The coin count's coin is a picture.** A ViewportFrame draws at reduced resolution, so the 3D
  coin looked fuzzy beside the sharp number. `art/coin/build.py --stage icon` renders the real
  coin face on, a little turned, at 256 px on a clear background (`CoinIcon.png`), uploaded as an
  image (`Coins.Icon`, ID in `art/coin/assets.json`); its spin as a coin lands is a flip (its
  width by the turn's cosine). The flying coins stay 3D: they move and spin, and are small.
- **The lobby's floor slab sat 7 studs into the cars** in the place's template (every other part
  matched its spec), so it ran under each car's floor at the same height and the two flickered
  as the camera moved ("the car floors' splotches"). Moved back onto its spec in Edit.

## D-159 A wrong code rolls up monsters' doors, and the keypad locks longer (S2-04a, Nov 14)

- **Which doors.** Each wrong code on a floor rolls up 1, then 3, then 5 units holding a monster
  (`WrongCode`, the owner's D-127; five is my default in the GDD). Sleepers first, since a door
  nobody has lifted going up by itself is the scare; then monsters already awake behind a shut
  door. A padlocked door is never picked: it holds against a wrong code as it holds a pounding
  monster (D-157), so padlocks stay the one answer to monsters behind doors (`OWNER.md`).
  Sleepers count against the floor's six on their feet (`Waking.AwakeMost`); one awake behind a
  door is already counted. Wrong-code wakes don't count toward the waves' tally (`woken`): the
  waves keep their own clock with whoever is left asleep.
- **How.** The keepers' brain handles it on the alarm, before the alarm is heard: a picked
  sleeper is dealt shut and stood awake (as a waking one is), so it hears the alarm and goes for
  the keypad once its door is up. The doors roll by `Doors:move(unit, "Open")`, the slow, loud
  open players know, from 1.2 s after the code (the buzz and bell first), 0.7 s apart.
- **The lock.** The keypad counts wrong codes since it was armed on its floor; it is dead
  `Keypad.dead` (3.5, 7, 14 s, the GDD). The bell recording is one clang that dies away in about
  2.5 s, so it can't loop: it strikes again every 3.5 s while the keypad is dead (one, two or
  four strikes), and a screen hushes any strike still ringing as the keypad clears.
- **Waking clock fix.** A floor's waking clock starts only for feet inside its reach as well as
  at its level (`Climb.stands`): every floor of a climb stands at one height, so height alone
  started the floor above's clock as it was laid.

## D-160 A wrong code's alarm calls every monster on the floor (S2-04b, Nov 14)

- **Who comes.** Every keeper awake on the alarm's floor hears it however far off
  (`Keeper.alarm`, reach `Keeper.Anywhere`), as Left 4 Dead's car alarm brings the horde from
  all over the map. Loose, it stops, turns and walks for the keypad at its usual "going to look"
  pace (about 7 studs a second), looks round there for its linger, then roams. Shut in a unit,
  it remembers the alarm and goes for the keypad once its door is up. Every hall on every floor
  was already inside the alarm's 400 studs from the lobby (the farthest is 377), so the change
  is that nothing awake is ever out of reach, whatever the floor's shape.
- **My defaults (in `OWNER.md`).** A monster chasing a player it can see keeps chasing: no sound
  pulls it off a hunt, the alarm included. A sleeper isn't called from afar: it wakes only
  within the alarm's 400 studs, as for any sound (the shut door stops it anyway), so the wrong
  code's own pick (D-159) says which sleepers come. It walks rather than runs, so a wrong code
  fills the lobby over the next minute instead of ending the climb on the spot.
- **Nothing pulls them off it.** Found in Play: a freed sleeper is shut in with its first blow
  due 1.2 s later, just as its door starts to roll, and the doors' own opens are loud door
  sounds; either one was newer than the alarm, so the loose and freed monsters went to those
  doors instead (one walked away from the keypad). Now a keeper behind a door the alarm picked
  stands quiet (`Keeper.hush`), and keepers don't go to look at the open of a door a wrong code
  rolls up (`rolling` in `Keepers`). D-159's scare stays: the door goes up by itself, unannounced.
- **Output.** One line a wrong code: the units it rolls up, how many monsters turn for the keypad
  now and how many more once out, and how long the keypad is dead. A freed keeper's door going up
  says it "goes after what it heard shut in" rather than "steps out to look".

## D-161 The machine's menu: one button, the machine's own front on screen, the server unchanged (S1-10d1, Nov 14)

- The precedent: Dandy's World's elevator shop opens a panel between floors (from memory). The
  owner asked for it in words: the bays were hard to read and a full car hard to use.
- One button per machine, made on each screen (MachineMenu, as KeypadPad's), on the middle of the
  glass (`Buy.point`), reaching 8 studs (`Buy.Reach`, was 5 from each bay's button) with no line
  of sight, so friends standing in front never hide it; shown only to a rider aboard while the
  bottom row is open (`Buy.open(1)`, so from its catch to 1.2 s before the cut). The server now
  measures a pick's reach from that point (+2 slack) and has no prompts, no per-frame arming.
- A pick is a client-to-server remote (`Buy.Pick`: machine, bay), typed first (an Instance we
  know, a whole bay number), then every check D-148 made, in its order. `Buy.Remote` still tells
  the buyer's screen; the menu drops away when it arrives, so it only moves for a real sale, and
  rises `Buy.ends()` + 0.3 s later. A second paid pick waits a second for the first's sale, so a
  double tap never buys two.
- A bay's state is the pure `Buy.tile` (tested): dark (row not lit), empty, full (a battery your
  full torch won't take: dim, a dead press, left for a friend, as BatteryView's rule hid it),
  poor (dim price; the pick clicks, buzzes and blinks on the machine as before, and shakes), ok.
  No words explain any of it.
- It looks like the machine, not a shop window: its enamel, sign and emblem, liner lit by each
  row's tube share from `Wake.tube` (so unlit rows light with the real ones and the panel dips
  with the lamp), steel rails, paper labels (the only words: the things' names), LED prices from
  LedReadout, chrome buttons; it rises from the screen's foot like a drawer. A plain Frame, not a
  CanvasGroup, so the six ViewportFrame pictures surely draw. Under CoinView (DisplayOrder 3 to
  5), so the paid coins fly over it. Its sounds (a latch's clunk, two tinks) are starting guesses.
- A chrome knob with an engraved cross shuts it (a close button, but the machine's own), besides
  walking off, E and B, since it rises again after each buy.

Later the same day: while the menu is up, the tool wheel and its Lay and Drop buttons slide off
the bottom of the screen the way they do when you're kept (`Tools.StowAttribute`, set by the
menu on your own Player), rather than shrinking or lifting the panel, which on a phone would cost
its readable size. And a tool bay goes dim like a full torch's battery when all your slots are
full (`Buy.tile`'s `room`, read from your slot attributes), since the server refuses that buy.

## D-162 The machine a quarter shallower, not a third (S1-10d2, Nov 14)

The owner: "I think we shrink the depth of the vending machine a bit" (a car full of friends
crowds it). The ticket read "a bit" as about a third.
- **1.8 deep, from 2.4: a quarter.** Each bottom coil stands two batteries one behind the other
  (`Stock.Batteries`, enough for a team of four from two coils), and a battery is 0.46 across, so
  the coil needs about 0.95 from its tip to the motor. At 1.6 (a third) that space is 0.68: the
  second battery would stand in the motor. 1.8 is the shallowest that keeps the stock as it is.
  Shallower would mean one battery a coil (two a ride) or smaller batteries in the machine than
  in your hand; both change the game, so they wait on the owner (`OWNER.md`).
- **Where the depth came from:** the face stays as it was (door, rails, glass, flap, plate, sign,
  all now measured from the front in the spec), the drop between the coils' tips and the glass
  0.59 to 0.4, the motor box 0.24 to 0.14 deep, the coils 4.5 turns to 3.5 (a pitch of about
  0.23, so two batteries still stand two loops apart). The machine's back stays on the car's
  back wall, so its front sits 0.3 further from the gate.
- **A narrower drop needs each thing sized:** the bubble wrap (0.72 across) and a tumbling
  battery or saw no longer fit the drop at any angle. MachineVend now stops a thing's ride off
  the tip once its tumbling reach (its box's half diagonal) would touch the glass, never short
  of leaving the tip, and lands it inside the bin by its size once tumbled (centred if it's
  longer than the bin is deep). Measured in Play: the bubble wrap and the saw land in the bin,
  the saw's box corner at most 0.05 past the glass as it tips (a box estimate, likely unseen).

## D-163 A wrong code puts the floor's hall lights out for the alarm (S2-04c, Nov 14)

- **What.** A wrong code blinds every hall fixture on its floor for the keypad's dead span
  (`Keypad.dead`: 3.5, 7, 14 s), instead of lighting them all (the GDD's alarm list; the old
  flash froze every Mannequin, so guessing made a team safer). The car's lamp isn't a motion
  light, so it stays: the car is the one lit thing on the floor. The precedent: Lethal Company's
  facility goes dark when the apparatus is pulled, waking what's inside.
- **How.** `MotionLights:out(floor, seconds)` keeps the floor's end time (`MotionLight.outEnds`,
  the later of two); a fixture has power only when neither its zone is cut by the breaker nor
  its floor out (`MotionLight.powered`). One blind only for the alarm shows "Out" on its model
  (`MotionLight.look`) so screens play the alarm's cut and return, not the breaker's silent snap;
  the breaker's cut wins when both apply. `flash` stays for the breaker's power coming back.
- **My default (in `OWNER.md`): the lights come back dark.** Each fixture returns watching, and
  only where something moves does it light. Coming back all lit, as the breaker's do, would
  freeze every Mannequin the alarm called and make the guess safe again.
- **Feedback.** Each lit tube stutters out (`HallLight.CutFlicker`), each dark one's red eye with
  it, up to 0.12 s apart, under one falling power-down whine heard across the floor ("light power
  off" 106554188841955, at 0.85 speed); short, so the dark you see is the dark the Mannequins move
  in. Back: each eye stutters red again with a faint surge of its tube (`BackFlicker`, up to 0.3 s
  apart) under a fluorescent flicker (116266785932124). One sound per floor (`OutGap`).
- **Seen in Play** (seed 7, floor 3): all 23 fixtures Out for 3.7 s on the server's ticks and
  back; a lit tube's light went 1.2, 0.4, 0.2, 0.7, off and its eye grey; both sounds played;
  the freed Mannequin walked through the dark and caught the player standing at the keypad.

## D-164 The machine's menu stays down after a buy (S1-10d3, Nov 14)

- The owner, Nov 14: "I don't think the vending machine needs to pop back up after you purchase.
  You'd click it again to buy another item." A sale coming back closes the menu (the drop, the
  tool wheel back); the Buy on the glass stays hidden until that vend is over (`Buy.ends()` plus
  0.3 s), the moment the panel used to rise, so you never open it over your own vend or buy
  twice in one. A refused pick keeps it up, as before. Passes checks, untested in Studio.

## D-165 A security camera feed shows a monster's moment: first, the Mannequin throwing the breaker (S2-02d1, Nov 14)

- The owner's idea (ROADMAP S2-02d, their words there): when the Mannequin is about to cut the
  power, the corner map becomes a CCTV view of it pulling the lever, so players see what
  happened instead of guessing, and first-timers get a "WTF moment". Precedent: Five Nights at
  Freddy's cameras show the animatronic where it wasn't.
- Who sees it: every player standing on that floor (`Climb.on` from the floor's origin, within
  40 studs up or down), kept players too. Nobody else.
- When: with `Feed.Lead` (2.4 s) of its walk left (straight-line distance over its pace), so it
  walks into the picture; the throw closes it (`Feeds:close`), the feed stays `Feed.After`
  (1.7 s) and cuts out. A walk called off still shows until `Feed.Most` (8 s): it turning away on
  camera is fine. The box's hall is streamed in on those screens as the errand starts
  (`RequestStreamAroundAsync`), since the picture is copied from what the screen has.
- Where the camera hangs (`Feeds:hang`, `Feed.hang`): from just off the box's wall, measured
  with rays (out across the hall, along the wall on the grip's side, up), 4 to 9 out, up to 6
  along, 1.5 to 4.5 up, `WallGap` off every surface; pulled in front of any corner between it and
  the box. It aims just below the grip and 1.3 out: the hand and the body's middle.
- The picture: a ViewportFrame in the map's own screen, on the map's corner, grown to 1.55 times
  its side at 4:3. The halls in the lens's view (up to 30 studs, 700 parts) copied once; what's
  watched (the body, the box) followed part by part at 12 frames a second, colour included, so
  the walk is choppy and the lever and the red lamp show. Its own flat cold light (cameras see in
  the dark); at a moment that puts the lights out, its light drops to 42% and its copied tubes go
  dark. Grain and snow are generated pictures (art/feed). "CAM nn" (from where it hangs) and a
  blinking red dot are the only marks: no words.
- Sounds, flat in your ears: a static burst in, thin static under it, the clunk through a thin
  distorted speaker, a burst out (Pro Sound Effects).
- Reusable: any monster's system calls `Feeds:show` (who, camera, number, what to watch, the
  floor) and `Feeds:close` (its sound, whether the lights went). The dev throw shows no feed.

## D-166 The Mannequin's hand on the lever: a beat on the grip, then the pull (S2-02d2, Nov 14)

- The camera feed (D-165) has to show the Mannequin cutting the power, not standing by a box
  whose lever falls by itself. Two stop-motion keys, as its walk is (L-06b): `Reach`, its right
  hand up on the grip with the lever up, its head tipped back and lolled; `Pull`, the lever
  dragged down to its low end, the elbow tucked at its side, its weight thrown onto that side and
  its head dropped over the box. It snaps into each, never easing, as the walk's keys land.
- Measured, not eyeballed: standing where `Breaker.stand` puts it (2.6 out from the wall, square
  in front of the grip), each key's palm is within 0.2 studs of the grip (`GripUp`, `GripDown`),
  checked in `tests/mannequin.spec.luau` with the rest (feet down, inside limits, nothing
  through anything). Right hand, because the camera hangs on the grip's side, the figure's right.
- The beat: arriving, it stands `Breaker.Grip` (0.6 s) with its hand on the grip, still on its
  errand (the feed stays open), then throws and lingers its usual 5 s holding the lever down.
  A light on it in the beat holds it there (its clocks stop, as ever); anything it hears or sees
  calls it off, and so does the offer going to 0 (the power cut another way). Long enough to see
  on a 12-frames-a-second feed; short enough that nobody can run there and stop it.
- Screens learn it through the state in its motion record: `Keeper.shown` says "Reaching" or
  "Pulling" while it stands with its hand on the lever, so the record goes out at once and every
  screen poses it (`KeeperMotion.how` gives Reach or Pull; `Pose.held` the frame). The brain's
  own states don't grow: the hand is a field (`lever`), only meaningful while it waits.
- Its arm creaks once as it goes up (the body's Creak, heard in the hall); the pull itself is
  silent on the body, since the slam and clunk are the box's.
- The one that threw the box no longer hears its own clunk (`hearAt`'s `maker`): before, it
  turned to "look" at the box it was standing at, so the pull never showed.


## D-167 The second monster is the Packrat, which collects things, not people (planning, Nov 14)

- The owner dropped the silent monster that moved only in the light: "I realized there isn't a
  way to stop it." The only thing that stopped it was standing still in the dark. That is not
  playing, a friend moving anywhere on the floor undid it, and it is when a Mannequin walks.
  Nothing had been built for it (S2-06 never started), so no code changes.
- Two were pitched in its place. The owner chose "the one that collects", and of its six
  defaults said "Yes I'm good with the suggestions."
- What it does (GDD "The Packrat collects things, not people"): it carries the floor's finds to
  its own unit one at a time and ignores everyone while its arms are full. With empty arms it
  comes for a player and takes their most valuable find, or wraps them if their slots are
  empty. A find dropped in its path sends it home instead. Its unit holds the pile, with finds
  of its own, there to take back. A find at the back of an empty unit baits it into a trap.
- Agreed defaults: anything in a slot counts (a find first, a tool only with no find, never the
  flashlight); before anyone has a find only a door stops it, and coins could count if that
  feels bad in play; one on a floor, none below floor 3; it isn't silent (one sound carrying,
  another with empty arms); its look (a tall, faceless bundle of grey moving blankets and tape
  with long bare arms, full arms told from empty ones down a hall on a phone); its reason (it
  can't stand anything being left out); Packrat as a working name.
- Mine and not yet put to the owner (`OWNER.md`): it sets hall lights off as it walks.
- It breaks "once out, never home" on purpose: it goes back to its unit every time its arms
  are full, and that is how a team finds the pile.
- Left out of the first build: it going after the big find, and a wrapped player being put on
  its pile.
- Where it comes from: Lethal Company's Hoarding Bug carries scrap to its nest; Sonic's rings
  take the hit (both from memory). Leaving you alone for a dropped find is the untested part.
- Not chosen: a silent monster that follows from behind, backs off when lit and comes for you
  if the light is held on it (Lethal Company's Bracken). It asks for the flashlight again, so
  the team does nothing new, and it lives behind you, where phone players look least. It and
  the dropped monster are in the GDD's "What's out".
- S2-06 is split into five sessions (art, carrying home, taking from you, the pile and the
  trap, its sounds) and no longer waits on the owner.

## D-168 No camera feed once you've left a floor; plain TV static in and out (S2-02d4, Nov 14)

- The owner, after playing: riding up, they still saw the Mannequin cut the power on the floor
  below. Who watches a floor's cameras was picked by where you stand (40 studs up or down, over
  its plan), and a car still climbing out of the floor passes. Now the instant a gate hits its
  post, Climbs tells Keepers who rode (`left`): they're off that floor for its cameras for good,
  and any of its feeds still on their screens cuts to static and the map that moment (`Feeds.cut`,
  a "Cut" to each). Friends still on the floor keep watching. A feed stays tracked for its
  aftermath (`Feed.After`) after the moment, so a gate shutting then still cuts it.
- A floor nobody's on any more offers its Mannequins no breaker errand (one already walking is
  called off): nobody would see it, and the power cut means nothing to an empty floor.
- In and out are a TV set's plain hiss, as the owner asked: two different Pro Sound Effects
  recordings so the two never sound pasted. In: "Television Static On Change Stations
  Constant 1" from 0.74 s (silence to full in 5 ms), full for the snow's 0.22 s, fading over
  0.12 s into the quiet bed. Out: "Television Static Change Stations Constant Off 2", full for
  the snow's 0.4 s and the window's shrink, then the set's own switch-off (it dies in 60 ms) as
  the map comes back. The quiet bed and the clunk through the camera stay (default, `OWNER.md`).
- A feed that starts while the corner map is still sliding in follows the map's window and lands
  in its place (it was left where the window was when it cut in).
- FeedView makes its in, out and bed sounds once at start and replays them, and keeps each
  moment's sound after its first play: in Studio Play a Sound made and played at once started
  0.28 s late even primed, which put the hiss after the snow; a ready one starts within a frame.

## D-169 The tap over a sleeper: the door hangs a foot up while the bar runs (S2-05a, Nov 14)

- Pulling a door down from at least 3 studs up, over a monster standing loose in its unit that's
  asleep or awake but not hunting you, eases it down instead of closing it (Motion's "Ease"):
  pulled down as a close is for 0.6 s, caught, then crept down to hang 0.9 studs up (about a
  foot, under a peek) over 1.85 s. That is longer than the bar (0.45 s lead, 1.1 s sweep) plus a
  late tap's 0.25 s, so the door is still moving, never resting a foot up, when the tap lands.
- A hit settles it from wherever it is ("Settle", 0.9 s, slow at both ends, a 0.12 thump nobody
  else hears; keepers don't hear it). A miss, a tap outside the zone (at once) or no tap (0.25 s
  after the bar's end), drops it ("Drop": a slam's fall from where it is, banging as hard as a
  slam from all the way up), heard as a slam, and its monster wakes shut in and pounds
  (`Keeper.wakeShut`, the trapped clock: its first blow 1.2 s on). Woken before the drop, so its
  own door's bang isn't news to it. As Dead by Daylight's skill check: a fail ends it at once.
- My defaults (`OWNER.md`): a hit always keeps the monster as it was (the GDD says "much more
  likely"); an awake monster that hasn't seen you is shut in and pounds either way, so its tap
  only spares the floor the bang; a peek's short drop never earns a tap; the zone is 15% of the
  bar, anywhere from 40% to 80%; a slam pressed while the bar is up is the miss; the puller
  leaving lets the door settle.
- One remote both ways (`Remotes.ShutTap`): the bar to the puller alone, their tap back with its
  moment on the server's clock. The server checks its type, holds its time to the window and
  0.25 s of lag (`ShutTap.heard`), checks the window is theirs and open, and drops taps closer
  than 0.2 s. A screen could still claim a time in the zone if it sends within 0.25 s of it: the
  price of being fair to a phone's lag.
- Doors asks `Taps` (registry slot "taps", typed in Doors since Taps requires Doors) before a
  Close; `move` lands the door ("Settle", "Drop") only while it's still easing.

## D-170 The tap's bar comes up where your thumb just was, and nothing else on screen answers (S2-05b, Nov 14)

- The bar rises in just under the pulled door's Close button on screen (40 px below its spot,
  held to the middle half of the screen's width and between 42% and 78% of its height; dead
  centre lower down when the button is off screen). That is where the thumb that pressed Close
  is and where the eye is, watching the door. Dead by Daylight always puts its check in the
  centre; whether ours should too is the owner's (`OWNER.md`).
- While it's up, the door buttons of the pulled door and of any door within 20 studs are hidden
  (`ButtonView.hide`, reason "Tap": no key presses them, so F taps the bar and can't open the next
  door along), and every other button steps aside (`ButtonView.aside`). Not
  `ProximityPromptService.Enabled`: CaughtView and CartRide switch that, and a bar shut while
  either had it off would switch it back on under them. So Slam can no longer be pressed by
  mistake during the bar; S2-05a's "Slam counts as a miss" still stands on the server.
- Sounds: the warning tick (Pro Sound Effects' "Toggle Switches Moviola Editing Machine 17",
  pitched 1.15) plays on the puller's screen alone as the bar rises; a hit is answered in the
  world by the settled door's quiet thump and, 0.12 s later, its latch catching (`DoorSound`
  "Settle", gain 0.22: far quieter than a close, as the spec holds); a miss by the slam's bang it
  already had. The marker's sweep has no sound: the silence over the door's creak is the held
  breath (the owner can ask for one).
- The answer is the server's alone ("Done"); the screen only freezes the marker at your tap with a
  flick, so you see where it stopped before the verdict comes about a ping later.


## D-171 Every monster moves in the camera's picture; a second feed never cuts off the first (S2-07a1, Nov 14)

- The picture follows every monster's body on the feed's floor (the "Keeper" tag under the
  floor), not only what the server names, so one wandering through the shot walks in it as the
  errand Mannequin does, choppy at `Feed.Fps`. All of them, not only those in the lens's view at
  the start: a monster can walk into the shot during the feed's 8 s. Only parts that moved are
  stepped (a compare per part, a sleeper costs that and nothing more). A body streaming in on the
  floor during a feed joins the picture; one streaming out goes invisible in it, never a statue.
- A second feed arriving while one shows (`Feed.arrive`): the same camera (within 0.5 studs,
  looks within about 8 degrees) and the first's moment still to come, it joins: one picture, no
  second snow, its id answers Close and Cut, and its time runs a full `Feed.Most` from then.
  Every feed today is a Mannequin at the floor's one box, always from the same camera, so two
  Mannequins making for it share one picture. Any other case waits: the newest waiting feed cuts
  in once the picture up has cut out, unless its moment came while it waited or it waited longer
  than a feed lasts (`Feed.kept`): the walk-up it was for is over, and the lights going out say
  the rest. Kept on each screen (not the server): every screen gets the same feeds in the same
  order, and the server's bookkeeping (who watches, Cut) is unchanged.

## D-172 The monsters' three: a busy Mannequin, a crowd that spreads, a wave held to the limit (S2-07a2, Nov 14)

- **The errand.** On its way to the breaker box, or with its hand on the grip, a Mannequin hears
  a third as far (`Keeper.ErrandHearing`), so four errands no longer come to one clunk. A busy
  guard turns only for a noise close by, as a coin thrown in Hitman draws only the guards it lands
  near (from memory). A door slammed in its own hall still turns it; the wrong code's alarm always
  does (S2-04b). A sound that does call it off takes it off the errand at once, so the camera feed
  lets it go as it turns away. The third is a default in `OWNER.md`.
- **The spread.** Monsters called to one spot each take their own place round it
  (`KeeperMap.spread`: rings 4 studs apart, each place 1.5 studs off the walls, on the floor and in
  plain sight of the spot), as Left 4 Dead's horde crowds round a car alarm instead of piling onto
  one point (from memory). The nearest along its way takes the spot itself; one already standing
  keeps its place as the noise goes on; one shut in is kept a place for once it's out. In a hall
  they line up along it; in the lobby they ring the keypad. The server spreads after every sound.
- **The wave and the limit.** A woken one breaks out only while the floor's loose monsters and the
  woken ones ahead of it leave room under `Deal.awakeCap` (`Waking.free`), the longest shut in
  first, as Left 4 Dead's director holds a special back until a place is free (from memory).
  Waking itself stays capped by `Waking.AwakeMost` (pounding ones stand still). Only a wave's are
  held: one let out by a wrong code or a missed tap is the players' doing and comes out anyway.
- **Held means quiet.** First built as pounding on past its time; in Play the loose monsters went
  to look at each blow and stood at the held door for good (each blow is the same noise going on,
  which keeps them looking), so the floor emptied and nothing ever freed a place. Held, it now
  gives one last blow at its time and stands quiet, as a padlocked one does, and bursts out the
  moment a place opens: the quiet door was never safe.

## D-173 The player's three: a light that sees you as it comes back, no Take through a door, a torch that goes out as you're caught (S2-07b1, Nov 14)

- **A light coming back from the alarm sees who's under it.** The motion lights only see
  movement, so a player standing still through a wrong code's alarm came back to a dark hall
  (the code's own comment meant "those under someone lit next tick"). Now each fixture whose
  power returns as the alarm ends looks once for anyone in its area, moving or not
  (`MotionLight` `watch:look`), and comes back lit over them, holding `HoldSeconds` like any
  other: standing on, they go dark to it again. A real motion light re-arming sees what's in
  front of it; the rest of the floor still comes back dark (D-163). It fires `woke` as any
  sighting does.
- **The keypad isn't under any light.** The lobby is lit only by the car's lamp (FloorBuilder,
  until L-05 dresses it), and no hall fixture's area reaches it (the nearest is 36 studs off on
  the dev floor). So a player at the keypad is dark to the monsters before, during and after
  the alarm; that is how S2-04c's tester was caught there. My default: leave it, since the
  alarm calling monsters to the keypad in the dark is its threat; `OWNER.md` asks whether the
  lobby should get its own motion light.
- **No Take through a shut door.** The server already refused a battery taken through its
  unit's shut door (D-143), but the button showed. Each battery now carries an ObjectValue
  naming its unit (`Battery.UnitValue`), since it lies in the floor's folder, not the unit; your
  screen checks the batteries within 16 studs five times a second with the server's own rule
  (`RollUpDoor.keepsApart`), and shows the Take only when your torch wants one and no shut door
  keeps you apart. A battery whose unit hasn't streamed in shows as before.
- **Caught, the torch goes out as the black lands.** It stays lit through the catch's lunge (the
  face rushing you in your own light) and goes out at `Caught.Dark`, on the server (`step`
  counts how long its holder has been kept) and on your screen (FlashlightView: your own click,
  no buzz); while wrapped the button is refused on both. Before, a torch left on drained in the
  unit's dark the whole time you were kept, and you came out with a dead torch. Let out, your
  thumb switches it on again with the charge it had.


## D-174 The screen's three: a friend's beam shows the mark, a saw that leans, the Output lines traced (S2-07b2, Nov 14)

- **A friend's beam shows the faint mark.** Why it didn't: FaintMarkView was only ever given
  your own beam (D-150 left friends' as polish). Now FlashlightView hands it the friends' beams
  it draws with real light (`Beam.friends`, a list reused frame to frame): each leaves the drawn
  lens, short of any surface as the light does, along the torch's look as their arm is raised to
  their `Aim`. `FaintMark.under` takes every lit beam: the mark shows as much as the best beam on
  it, in the brightest light on it (a friend's steady beam holds it while yours stutters), and
  lingers in the brightest torch lit anywhere, going at once when every torch is out. Not
  chosen: their head along their root's heading (the server's keeper test): the mark should
  show where this screen draws light, and a budgeted-out friend (lens only, no light) shows none.
  Phasmophobia shows prints under anyone's light (from memory).
- **A long thing leans in the bin.** The saw's corner crossed the glass by 0.056 as it tumbled
  (measured with the real saw's box, D-162 had 0.05). `Buy.tumble` gives the most it may tip
  so its reach (|cos| half-depth + |sin| half-height, a bound over its box) never passes the
  glass at the nearest its middle comes; it rides off at that angle and lands leaning, its middle
  raised by however much taller it stands, so its foot stays where a lying one's would. The saw
  now leans 41 degrees and stays 0.022 behind the glass; batteries, the wrap and short tools
  still tumble the full 100. No art changed (the path is code); a can leaning in a real bin is
  the look.
- **The Output lines aren't the game's.** The 23 `rbxassethash ... Requester does not have
  permission` lines come on the server and the client as the place loads, before any of the
  game's client code, and still with `LoadCharacterAppearance` off; no content id the place
  names failed on the client (`ContentProvider:GetAssetFetchStatus`: 77 loaded, 331 not yet
  asked for). Studio's own, so not silenced. 203785492: Studio's or a plugin's, as L-16a found.
  89260803894903 is a TexturePack (asset type 63) of the owner's, made 18 s after the coin's mesh
  on Nov 14: the coin's import made it. No property in the place names it and cloning the coin
  on either side didn't bring the line, so it stays watched (`OWNER.md`), not fixed blind.

## D-175 The Packrat's look: pale arms on a dark bundle, two walks built as opposites (S2-06a1, Nov 14)

- **What it is.** 7.3 studs tall at rest (8 clears a door), fifteen rigid R15 parts like the
  Mannequin's: grey quilted moving blankets in three or four shades, creased in the loft and
  pulled in under eight bands of tan packing tape (an X binds the chest), a hood with a dark
  hollow where a face would be, blanket-sacked feet, and two long bare arms, pale and mottled,
  fingertips grimed. 7,020 triangles, one 1024 texture set.
- **Readability comes from the arms.** The only pale thing on it is skin, so the arms are the
  read: full, both forearms cross its chest round the find (a pale knot at chest height, the
  hood bowed over it); empty, both hang wide of the bundle, never swung behind it (from ahead,
  an arm swung back sat in its own shadow and only one pale line showed at 30 studs). The Lune
  spec holds that as numbers: full hands within reach of the find and above the waist, empty
  hands below the hips and past its sides.
- **The hug was solved, not guessed.** Shoulder and elbow angles came from a search for elbows at
  its sides and wrists meeting ahead of the chest, the right arm higher so the forearms pass;
  the hunch was eased (waist -13) and the hood bowed more, because a deeper hunch dropped the
  find to its belly, and the GDD holds it against its chest.
- **`Rig.luau`** is the pose math (solve, turns, mirror, limits, blend) any jointed monster
  shares; the Mannequin's Pose keeps its own older copy for now (HANDOFF Queue).
- **Default (OWNER.md):** the carried find in the sheets is the teddy; the hall shot is a plain
  grey hall in Blender. The real hall at phone size is S2-06a2's.

## D-176 The Packrat in the place: a rig like the Mannequin's, the find behind its forearms (S2-06a2, Nov 14)

- **Into the place the Mannequin's way.** The FBX (asset 79124901483193) arrived as fifteen
  MeshParts turned 94 degrees about Y, every pivot on the floor between its feet, each with its
  SurfaceAppearance. `Packrat.prepare` adds the anchored HumanoidRootPart, R15's RigAttachments
  and Motor6Ds, makes the parts massless, collision-free and queryable, and paints each part's
  fallback colour by what it's made of (blanket grey, skin pale), so even with no maps the arms
  stay the only pale thing on it. The template stands `Still` at `ReplicatedStorage.Keepers.Packrat`.
- **Its own module, not a shared keeper body.** `Packrat/init.luau` repeats the Mannequin's
  prepare, pose and rest on the shared `Rig.luau` math rather than folding both into one module:
  the Mannequin's code is live and tested in Play, and a shared body module is a refactor for
  when a third jointed monster arrives. `transforms` is keyed by pose name until S2-06a3 adds the
  walks as frames for a screen to step through.
- **The find sits behind the forearms, not in them.** Judged in Studio with a real boombox at the
  carry point, the find's middle sat right where the forearms cross, so the find swallowed both
  pale forearms; a dark find would have hidden the very knot that tells full from empty. Measured
  by rays in Studio, the chest's front is 0.58 ahead of the torso's middle and the forearms' backs
  about 1.35, so `CARRY` moved from 1.22 to 0.95 ahead: a find up to about 0.7 deep now sits
  between chest and forearms, and the pale forearms cross its front. The Lune spec now checks
  each forearm passes at least 0.25 ahead of the find's middle (it failed on the old point).
- **`carry(model)` reads the UpperTorso's CFrame**, so the find follows whatever pose the body is
  in: in Edit by `pose`, on a screen by its joints' Transforms. On the server its joints stay at
  rest, so S2-06b decides where the server keeps a carried find. Deeper finds (a television)
  will still meet the forearms: S2-06b seats each by its own depth or accepts it.

## D-177 The Packrat's take: one long arm out, a smooth walk in numbered frames (S2-06a3, Nov 14)

- **The reach is one arm, not two.** Reaching, its right arm goes straight out ahead and a little
  wide, nearly level, the find (or a player's chest) at its fingertips 4.2 studs ahead of its
  chest, the hood craned after it and the other arm trailing low and back. Two arms out read as
  a zombie; one arm, from across a hall, is a single long pale line out of a dark lump, which is
  the moment the take is built on (`art/sheets/packrat-reach-hall.png`). Its hand sits at about
  4 studs, a player's chest, so it reads as coming for what you hold rather than for the floor.
- **Taking is halfway home.** Both hands close on the find 2.5 studs ahead of its chest at chest
  height, elbows bending back to its sides, so a screen showing reach, then take, then the full
  walk's hug reads as the find being pulled in. Putting down is a deep crouch, folded over, the
  find low between its hands, feet flat. The find's place in each comes from `Pose.grip` (one
  hand's fingertips, or between two palms), as `carry` gives it in the hug.
- **The walks glide; the Mannequin's jerk.** Each walk's four keys are blended by a Catmull-Rom
  curve through them by distance travelled, so every joint keeps moving through each key. The
  Mannequin's stop-motion jerk is its own character; the Packrat is a thing that moves fluidly
  and quietly. A key carries it half the spread of its feet in a step (1.6 studs empty, 1.15
  full), so a planted foot doesn't skate, and the full walk's stride is 72% of the empty one.
- **The hug isn't mirrored.** The left-foot keys of the full walk are the right ones mirrored,
  but with the same hug, the right forearm over the left: mirrored, the forearms swapped which
  was on top and passed through each other mid-step (the spec caught it in the in-between
  frames). The left forearm came 3 degrees forward to stay across the find's front throughout.
- **Frames, not names.** `Packrat.transforms(frame)` takes the KeeperView Kit's frame numbers:
  1 to 4 the held poses (Still, Reach, Take, PutDown, by `Pose.held(name)`), then 32 frames of
  the empty walk (8 a key), then 32 of the full. `Pose.along`, `frameAt` and `frame` take the
  walk first (`"Empty"` or `"Full"`), since which walk it shows is the Packrat's own state; the
  Kit's `along(travelled, how)` and `frameAt(along)` don't carry that, so S2-06b2 decides how a
  screen learns it carries (a How of its own, and resetting `along` when the walk changes).

## D-178 The Packrat's trip home: told what lies loose, nearest first, deaf and blind while full (S2-06b1, Nov 14)

- **The server says what lies where; the brain says where it goes.** `Keeper.lying(k, finds)`
  hands it the server's reused list of loose finds (ids and the floor under each), as `offer`
  hands the Mannequin the breaker. The server calls it whenever that changes (a find lifted,
  dropped or laid, a door up or down); the brain answers with `took` and `laid` for one step,
  as `threw` does, and the server moves the find. Nothing about a find's model is in the brain.
- **Nearest first, by the walk, not the crow.** It goes for the nearest find along the halls
  that it can reach (a find behind a shut door isn't reachable), never one in its own unit, so
  it never takes from its own pile. It commits: a nearer find turning up doesn't turn it. It
  knows of finds it can't see, so it drains the floor steadily outward (`OWNER.md` asks). Only
  a find gone first, or one moved, changes its mind.
- **It stops its grab short, along a clear line.** Like the hunt stopping at `Close`, a fetch
  stops 4 studs off the find once the map clears the line to it, so its long arm (D-177) lands
  on the find, never through a wall. The reach is a beat (0.8 s) a player can still snatch the
  find in; the take is when it becomes its own.
- **Full, it is a different animal.** While it holds a find it neither sees nor hears anyone
  (the GDD's "ignores everybody"), walks at 72% of its pace (the full stride's share, so its
  feet keep their beat) and goes home; shut in, it pounds as any monster and goes home once
  out. Empty, it hunts as any monster until S2-06c, and on its way to a find it hears a third
  as far, as the Mannequin's errand does (D-172).
- **Its way home shut, it roams carrying** and heads home once there's a way (`OWNER.md`).
- **Screens get names, not new states.** Its core states stay the Mannequin's (it walks as
  Roaming, stands as Waiting); `shown` names what a body must show: Reaching, Taking and
  PuttingDown as it stands, Carrying in any other state while full (trapped included), for the
  Kit to map in S2-06b2.

## D-179 The Packrat in the game: finds lifted by number, carried on its chest, laid with "Take" (S2-06b2a, Nov 14)

- **Split again for context.** S2-06b2 became b2a (this: the server moves the finds, both
  bodies, a dev post) and b2b (the deal on floors 3 and up, the hall lights as it walks, the
  find seated in its hands by frame). The screens' frames came into b2a rather than b2b,
  because without them a Packrat in Play slides unposed, and the payoff is watching it walk off
  with your find.
- **Slots owns every find; the brain knows them by number.** Each tool now has a number (`n`);
  `Slots:finds` lists the finds lying loose with the floor under each one's middle, `loose`
  fires whenever that set changes, `lift` welds one into a monster's arms and `putDown` sets it
  on a floor again. `Keepers` rebuilds each floor's `Keeper.Finds` at most once a step, after a
  find or a door changed, and tells every Packrat (`Keeper.lying`). If a find can't be lifted,
  the brain is told it's gone (`Keeper.dropped`) and sets off again.
- **The find rides its chest, welded.** On `took` the find is welded to the UpperTorso at
  `Packrat.Chest` (D-176's carry point) and parented into the body, so every screen shows it in
  the hug wherever that screen poses the body, and it streams with it. Its jump from the floor
  to the chest as the hands close is the next piece's to ease (and to sit between its hands in
  Take and PutDown).
- **Laid finds are takeable at once.** `putDown` eases it from its hands to the floor (0.35 s,
  no clank, so no monster hears it) and offers "Take" as any find, so S2-06d's "take it back"
  already works. The pile is a small heap: five spots around the pile's middle in turn.
- **Screens learn it carries from its state, as D-177 asked.** `KeeperMotion.How` gains Take,
  PutDown, Carry (walking full) and Hold (standing full); the Kit's `walk` says which of its two
  walks a How shows and `along` starts again when it changes. The Mannequin's Kit maps the new
  Hows to its own (it is never told them). The Packrat's Kit plays no beats and no turning creak
  until S2-06e.
- **The dev post stands it in a real unit.** Stood in a hall, its own unit would be none, and
  it would take its pile straight back up; so the post opens the shut unit nearest the lobby
  (dealing it nothing), stands it inside facing the back, and lays a boombox 70 studs off.
  Studio's `StandPackrat` Workspace attribute presses the post for a test, since a script
  can't press a ProximityPrompt (docs/STUDIO.md).


## D-180 The Packrat dealt among its pile; finds eased into its hands on screens; it lights the halls (S2-06b2b, Nov 14)

- **One a floor from 3, placed with the floor, drawn last.** `Deal.packratIn` picks its unit
  after everything else a seed lays (its five draws on every floor), so no other unit, note,
  padlock or sleeper moved: with it switched off the stuff spec's fingerprint is S2-01's. It is
  a sleeper (`sleepers`), so waking waves, the air horn, a wrong code and the kept-friend unit
  all treat it as one, and it isn't in `Deal.Keepers`' draw, so never two.
- **A medium unit, never a note's.** A small unit with a note has no room for its 2.7-stud body
  beside the note's line from the doorway, and a small one without a note fits it and one big
  find, not a pile (tests/dealspot). Every floor has at least one medium unit open to it (13 on
  average), so it always gets one; a note's unit is out so its tall body never hides the code.
- **It stands at the back, its pile at its feet.** `DealSpot.inUnit` gained `near` (the fitting
  spot nearest a point): the Packrat near the back wall's middle, its two or three different
  finds near the floor just ahead of its hanging hands, each clear of the floor it takes (its
  middle 0.55 ahead of its feet) and turned a few degrees off square, so the door lifts on a
  heap in the bulb's light and a tall shape behind it. `Keeper.nest` faces it at the pile's
  middle; it still stands facing the doorway asleep.
- **Laid finds go beside the pile, not into it.** `laidFind` takes the first of ten ring spots
  round the pile with no loose find within 1.6 studs, wholly inside its own unit, else the
  least crowded, and eases the find down from where screens show it in its crouched hands
  (`Packrat.Held.PutDown`), not from the server's resting chest.
- **Screens move the find; the server only says where it lay.** The server's weld arrives
  `KeeperMotion.Delay` before a screen shows the hands close, so the weld carries `From` (where
  it lay) and each screen holds it there until it shows Take, then eases it up in world space
  (0.22 s, so the snap from reach to take can't jolt it), to the chest (0.3 s) and down into the
  crouch (0.4 s) in the chest's frame. Only a body whose find is moving is stepped for it.
- **It lights the halls as it walks** (`KeeperRows.tripsLights`, the default in `OWNER.md`): its
  root trips motion lights as a player's does, so you see it coming and a Mannequin by it freezes.

## D-181 The Packrat robs whoever it reaches: the best thing they carry, torn from their grip (S2-06c1, Nov 14)

- **Split for context.** S2-06c became c1 (the take, the robbed screen) and c2 (a find dropped in
  its path fetched instead of you, and its own catch rather than the Mannequin's lunge).
- **The server says what it would take; the brain decides take or catch.** Each step's player
  list carries `loot` (the number of the thing it would take, or 0), filled by Slots' `prize`,
  so the rule "carrying something, you're robbed; empty, you're caught" lives in the brain and
  its Lune spec. A take is a catch's moment (its reach and cone): it sets `took` and `robbed`,
  holds the thing, stands `take` seconds pulling it in and goes home as after a fetch. The one it
  hunted is let go, not kept.
- **Which thing: `Carry.prize`.** Finds have no worth yet, so a find's heft stands in for it (the
  television, boombox, skates, teddy), a tool only with no find, the one in your hand on a tie,
  never a both-hands thing (the ladder now, the big find later) and never the flashlight, which
  is in no slot (`OWNER.md`).
- **No beat to pull away in.** Its hands close the moment it reaches you, as a catch does, so the
  take can't be dodged at arm's length. The fun is in keeping it off you, or handing a cheap find
  to whoever has nothing (GDD "With a Mannequin on the same floor").
- **Out of your hand into its arms, eased.** Slots' `snatch` takes it out of your slots, welds it
  at its chest with `From` where you held it (or your middle, if it was put away), and every
  screen eases it into its hands as a lifted find. On the pile it's a find (or tool) like any.
- **The robbed screen answers in one beat** (ToolSnatched, ToolView's `snatched`): a view kick
  harder than a break, the Packrat's Lunge beat (the Mannequin's creak and scrape until S2-06e)
  with the thing's own pick-up sound, the thing in your hand torn from your grip toward it, and
  its picture pulled off the wheel's button toward where it stands on your screen (off the top if
  it's behind you). No words: the empty slot says it.
- **A dev hook to test it:** the dev floor's `GiveFind` Workspace attribute (Studio only) puts a
  find of that key in the first player's hands.

## D-182 A find dropped in its path buys off the Packrat; its own body in the catch (S2-06c2, Nov 14)

- **The rule, in the brain's sight.** A Packrat with empty arms that would hunt a player (one it
  keeps its eyes on, or the nearest it notices) goes instead for a find it sees lying nearer than
  them: in its sight and view along a line the map clears, one it can walk to, never on its own
  pile (`bait`, `goForSeen` in `Keeper.luau`). The one it's already going for it watches any way
  it faces, as the one it hunts, so the reach isn't broken. A player nearer than the find still
  wins: "you before any find" stands. The distance cut runs before any line is cleared. Precedent:
  a thrown item drawing a monster off in Granny and Hello Neighbor; the GDD's Packrat item 7.
- **Its own landing doesn't call it off.** Seen in Play: right after it turned off the player, the
  dropped find's clank sent it to "go and look" and dropped the fetch. A sound within
  `Keeper.Landing` (3 studs) of the find it's going for is that find landing and is ignored.
- **A find let go at a run falls at your heels** (Slots' `DROP_BEHIND`, 1.8 studs back along the way
  you're moving, faster than 6 studs a second). Seen in Play: dropped 2.2 studs ahead, a solid find
  lands in a runner's path and they run into it; and ahead of the runner it isn't nearer to the
  monster behind them. At your heels it's between you and it, so the save is instant. Standing,
  it still lands ahead of you, in sight. This applies to every tool dropped at a run (`OWNER.md`).
- **The catch throws its own body.** CaughtLunge picks the body by the row's name (`BODIES`:
  clone, joints, rest, its Lunge pose and its head in it), the Mannequin's for any other. The
  Packrat's Lunge pose is reared up with both pale hands raised either side of its hood, at the
  hood's depth, so flown at the eye by its hood they frame it at the screen's edges rather than
  passing out of sight past the player's head (checked in `tests/packrat.spec.luau`). Not watched
  on a screen yet (`OWNER.md`).

## D-183 A find turning up nearer turns the Packrat; bait and its trap need nothing new (S2-06d, Nov 14)

- **A nearer find turns it on its way.** Going for a find with empty arms, when what lies loose
  changes (a find dropped, laid, lifted, a door up or down) and another it can walk to is now at
  least `Keeper.Nearer` (4 studs, a few strides) nearer along the halls, it turns for that
  (`Keeper.lying`). Without it, a find dropped at the back of a unit beside its path waited for
  some later trip, and the GDD's "drop a find at the back of an empty unit, wait for it to walk
  in" barely worked. Only on a change, so it costs one path length per find then, never a step.
  The margin keeps two finds about as far off from swapping it back and forth. Never while its
  arm is out over one, never its own pile. Precedent: Lethal Company's Hoarding Bug goes for the
  nearest scrap.
- **Bait and the trap were already there.** It stops a long arm's length (`grab`, 4) short of a
  find, so one at the back of any unit (8 or 12 deep) has it standing inside, where a door
  brought down traps it as any monster (`Keeper.trap`). Its arm out, the reach is called off and
  the find waits; its hands already closed, the find stays in its arms and, out at its row's 90 s,
  it carries it home. Shut in its own unit, the pile is shut in with it; holding the one it was
  laying, out, it lays it. Seen in Play: it heard the slam beside it first, then was trapped.
- **The window is about two seconds** from its arm going out to it turning with the find (reach
  0.8 s, take 0.5 s, the walk out). Players hide out of sight (a unit's roof, round a corner) and
  drop to the door when the arm goes out. `OWNER.md` asks whether that's fair on a phone.

## D-184 The Packrat heard: soft pads and tape when it's coming, a rattle when it's hauling (S2-06e, Nov 14)
The moment: in a dark hall you know from round a corner whether it's coming for you or busy
hauling something home, as Left 4 Dead's Witch is heard before she's seen and sounds one way
calm and another coming.
- **Empty (`KeeperRows` Packrat `tell`):** quiet and wrong. Its blanket-sacked feet land as
  padded thuds ("Foot Stomp" 1, 4, 7 on carpet, pitched to 0.66 to 0.76, heard to 60, past the
  48 it sees), the trailing foot lighter so the stride lopes, and once a stride a screech of
  packing tape pulled off a roll (the kept wrap's peel, L-07b, heard to 50): the tape it wraps
  you in. Turning, its tape crackles (to 30). Heard, it stops on a heavy step and the tape
  shrieks; a door lifted on it among its pile, a shift and a long low creak of tape.
- **Full (`full`, a typed local `PackratFull`):** busy and bright. Heavier, lower steps ("Foot
  Stomp" 2, 3) with a body's thump under them up close ("Body Impact 2"), the find jostling in
  its arms at each step (a purse of jingling things knocked on a wall, heard to 70) and junk
  rattling between ("Ammo Box Movement 2", "Chair Impact 12"). No recording is shared with the
  empty walk (spec'd), so the two never blur.
- **The switch** is the How a screen shows (`KeeperTell.full`: Carry or Hold, which is `Keeper.shown`
  "Carrying"), passed with every beat (`heard(model, beat, full)`), so the sound changes the
  moment the screen shows its arms full, not when the server decides. `KeeperTell.of` picks the
  row's `full` tell or its `tell`. Voices are kept per recording row, so two tells never mix.
- **Its walk's beats** (`Packrat.Pose.tell`): a foot, the pass, the other foot, nothing, on
  either walk; its arm going out for a find creaks once; held poses are silent; switching walks
  is silent and its next key is heard (the two walks count keys differently, so `tell`
  remembers which walk it counted on).
- **Bound late:** KeeperSounds now binds a body whose root or row arrives after its tag, as
  KeeperView does (D-108). Not the cause of the silence seen in Play (that was the test, D-185),
  kept as a guard.
Not chosen: a sound per find (each find its own rattle; ROADMAP polish once finds have their
own sounds), a breathing or voice layer (it's faceless; the owner's call).

## D-185 The Packrat was heard all along; each body's sounds are made as it streams in (S2-06e2, Nov 14)
The moment: the first steps you hear from round a corner, and the first heavy step as its arms
close on a find, land on the beat.
- **The silence was the test.** The S2-06e session's Studio was drawing no frames (the display
  idles with the owner away; STUDIO.md "Getting frames back"), and the client steps every
  monster's walk on RenderStepped (the Host's `advance`), so no body moved or sent a beat on that
  screen while the server walked it. With frames, in Play on floor 3: the Packrat's empty walk
  (pads, tape, crackle) and its full one (tread, weight, jostle, rattle) both played, and a
  woken Mannequin's walk too. With the pulse stopped, 0 frames: the server walked it, the
  client showed it still and played nothing. No game change for this.
- **Fixed on the way:** a Sound made and played at once starts about 0.28 s late (STUDIO.md), so
  the first play of each take started unloaded, late and cut short by its fade: the first steps
  into earshot, and the first full-arms steps. KeeperSounds now makes every take of both a
  body's tells as it binds (13 Sounds for a Mannequin, 19 for a Packrat, idle until played; a
  body streams in at up to 256 studs and is heard from 70 at most, so they load first). Measured
  after: all made and loaded at stream-in, every play of both sets loaded at its start.
Not chosen: stepping bodies off Heartbeat so a screen with no frames still hears them (a screen
that draws nothing shows nothing; a real player always has frames).

## D-186 Carried up: you watch the ride, then wake wrapped in a unit on the new floor (S3-01a, Nov 14)

The GDD's "When the elevator leaves without you" (agreed Nov 13): nobody is out of the climb.
Wrapped or late when the gate shuts, you watch your friends ride up, and when they arrive you're
on that floor too, wrapped in one of its units, with empty hands, until a friend cuts you free.
Precedent: R.E.P.O.'s dead player, whose head a teammate carries back to bring them in.

The moment. Everything up to the ride is L-08c's (D-105) and unchanged: the sting, the black,
your character gone at the hand-off, the friend's shoulder as their car levels and the gate folds
open. Then, `Left.CarryAfter` (1.4 s) after the gate is all the way open, so you've seen the new
floor's lobby over their shoulder, the view dips to black over `Left.CarryDip` (0.8 s, a faint,
not a switch's cut) as the film squeals round you; in the black a roll-up door slams close by,
muffled, with a small jolt (`Left.CarrySlam`); and your eyes open on a dark unit's inside the
way they do after any catch (CaughtView's wake from `Caught.Dark`, no lunge, no "Caught"). No
words: the squeal and the slam say you were wrapped and shut in.

How. Climbs' `carryUp` waits for the takeover car's `arrived`, sets `Left.CarryAttribute` (the
dip's server time, `Left.carryAt`) on everyone watching (`Watching:carry`), and once the black is
whole takes each out of the watch with a new character (`Watching:bring`: out of its table first,
so the new character isn't taken for a respawn) and has KeptPlayers stand them in a unit
(`KeptPlayers:store`): `Kept.choose` from the car's lobby (shut, nobody in it, never the
nearest, an unopened one first), anchored, wrapped with the film stamped long on (so no screen
winds it on), the unit streamed in (up to 4 s, under the black), pivoted inside, then
`Kept.BroughtAttribute` and the kept mark, then the same settling-in as a catch (`settleIn`: the
padlock's clock, Cut free, the light under the door). WatchView holds its black (over the caught
screen) until the kept mark has been on 0.1 s, then lets go onto CaughtView's black. With no unit
free you stand in the lobby (the let-in's lift). The watch bar's "Back in when they finish" is
gone (it explained a rule, and is false now).

Defaults (`OWNER.md`): 1.4 s after the gate opens; nobody else hears the squeal when you're put
in (KeptWrapOn skips a brought player: the bangs are how friends find you); the padlock's clock
starts fresh on the new floor.

Verified: checks green; in Studio Play the server and client started with no errors; the
carried wake run from the Client (the marks set locally): black whole for the hold with no
headline, the eyes' keys, clear by about 3.5 s, then the Bang button. The carry across a real
ride needs two players (or a stand-in friend and many captures) and waits on `OWNER.md`.

Not chosen: standing you in the car at the next floor (that's Cut Free's, S3-03); keeping you
watching until a friend opens a unit (you'd have no body to find); a squeal on friends' screens
from the shut unit (heard from nowhere, it teaches nothing the bangs don't).


## D-187 Everyone wrapped at once: a friend being carried up counts as wrapped (S3-01b, Nov 14)

The GDD's "Getting caught": the climb ends only when every player is wrapped at the same moment.
The moment is the last free friend grabbed, and the black coming down on the whole team as their
catch cuts to black (`ClimbEnd.AfterCatch`, as D-106 has it). Precedent: Dead by Daylight's match
ends the moment the last survivor is hooked, whatever the others are in the middle of.

The rule (`ClimbEnd.look`, one player at each of the server's looks ten times a second): kept in
a unit, left behind watching the ride, or being carried up (Climbs' `carrying`: from the car's
arrival on the new floor until they're stood in one of its units) counts as wrapped; anyone else
is climbing. Before this, a carried player had a character and no kept mark for up to 4 s while
their unit streamed in, so they counted as climbing and a wipe waited for the unit: the last
caught friend saw their eyes open in the dark before "Kept" came down. Default (`OWNER.md`): no
waiting, the carry is a wrap like any other.

The floor on each photo (`ClimbFate`, the car's results board): the floor they were first lost
on (kept, then left behind as the car goes, is still that floor), except that a carry moves it
to the floor they're carried to, so a friend wrapped on floor 4 after two carries reads floor 4,
not floor 2. Cut free, the note goes and the next catch names its own floor.

The end mid-carry. Once the end begins (Climbs' `ending`, from ClimbEnds' `endClimb`), no carry
takes anyone out of their watch: a new character handed over under a black that is still
coming down would flash the world for a moment. The watcher's dip still plays into black, but the
squeal and the door slam still to come don't (WatchView), and a carried black that's already up
holds until the end's own black is whole (`ClimbEnd.cover`), never falling through to the let-in's
"Back in". Everyone goes at the cover, as at any wipe. Playing alone, one catch still ends it.

Verified in Studio Play with one player and two stand-in friends (STUDIO.md "Testing a wipe
mid-carry"): left behind on floor 2, the stand-ins removed as the car arrived on floor 3; "Kept"
landed 1.1 s later, before the dip; the fate read `Kept|3`; nobody was carried up after it;
Again brought a clean screen with no "Back in"; no errors. The wipe after the bring (inside the
unit's stream, near instant in Studio) and two real players wait on `OWNER.md`.

Not chosen: waiting for the carried friend's unit before the end (the last catch's moment is
lost under a second wake); counting a carried friend as climbing until a friend could cut them
free (nobody is free to); a separate "Carried" fate on the photo (one more word explaining a rule;
"Kept" and the floor say it).

## D-188 Finds: six grades with Secret on top, and the catalog's other answers (owner, Nov 14)

The owner answered the item catalog's 14 questions (the catalog is its own Claude Doc, linked
from the GDD's "Coins, cash and finds"; nothing in it is built). Both docs now say what follows.

- **Six grades: Common, Uncommon, Rare, Epic, Legendary, Secret.** Kept is dropped as a grade:
  the owner finds it made up and too literal for a storage building. Its eight finds moved up to
  Secret (a default, `OWNER.md`), so Secrets turn up from floor 10 (0.2%) and from floor 25 (1%).
  The word still names getting caught (`ClimbEnd.Copy.Kept`, `Kept.luau`); `OWNER.md` asks.
- **Four of a kind make a Gold** (agreed loosely): commons sell on the spot, everything from
  Uncommon up goes home, copies too. Precedent: Pet Simulator's golden pets.
- **Blind boxes hide one Secret in 144.** The shout, the count ("1 of 214") and the first finder
  named on the find's page: yes, for Secrets (Sol's RNG's server-wide line for its rarest rolls).
- **A luck boost on sale instead of free help after a dry spell.** One use, bought with Robux,
  used in the elevator: better odds of rare finds on the next floor. Roblox names luck boosts as
  paid random items ("probability modifiers", create.roblox.com's paid random items page, read
  Nov 14): the odds with and without it show before purchase and stay true while it's on, and a
  player for whom `PolicyService`'s `ArePaidRandomItemsRestricted` is true can't buy or use it.
  Default (`OWNER.md`): it lifts only the units the buyer opens. Built with the shop (S5-07).
- **Noisy finds draw monsters only when used**, by the action button, as the air horn does:
  carrying one never gives you away. The catalog's finds that went off on their own no longer do.
- **Found lights hold a Mannequin** and run down in about a minute. **Search finds** (compass,
  metal detector, crystal ball, camcorder, binoculars, hand mirror) stay and stay rare; the
  detector and the ball wear out like tools.
- **Worn finds: yes.** Skates, slippers and helmets go on the character alongside what's carried
  (R15; things are already welded to players and `Slots` already sets walk speed from what you
  hold). Monsters hear no footsteps today (`Keeper.Hears`), so the quiet/loud part needs that
  first; `OWNER.md` asks. Try one before the rest.
- **Charms**: up to three, picked in the lobby, looks only. **Mashups** stay.
- **The unit comes alive**: hatched pets live there, plants grow when watered (Grow a Garden's
  loop), more finds like them in time; the owner wants players in awe of the detail. **Arcade
  cabinets** get real games, maybe several.
- **Trapping pays**: each monster shut in a unit as the gate shuts pays everyone aboard 5 coins
  (starting guess; floor 1's gate pays 10, `Pay.Base`). It replaces the GDD's untested "a quarter
  more". Precedent: R.E.P.O.'s beaten monsters drop an orb worth money.
- **Boss floors are not ruled out**, nor are units far bigger inside than they look (the owner's
  example: a jungle going on and on, a rare find at the back and a monster with it). Both wait
  until the generated floors (S4-01) are solid.

Not chosen: a seventh grade; the name Mythic; noise that gives a carrier away; free pity odds.

## D-189 "Kept" is gone everywhere players and the owner look: a wiped team is "Caught" (Nov 14)

The owner, after dropping Kept as a grade (D-188): drop the word everywhere. The end screen's word
and the car's results board say "Caught" (`ClimbEnd.Copy.Caught`), the climb's analytics record
the fate as `caught`, and the design doc's draft taglines read "Don't get caught". "Caught" is
the word a player would use ("we got caught on floor 7") and the GDD's own section name.

Left as working names, as "keepers" is: the code's `Kept`, `KeptPlayers`, the `Kept` fate and
state values, attribute names and `art/keptwrap`. Nothing on screen shows them; renaming them is
churn with no player benefit. The analytics `findKept` and the funnel step `kept` mean a find you
took home, plain English, and stay.

Not chosen: "Wrapped" (describes the body, not what happened to the team); "Game over" (says
nothing about the monsters).

## D-190 The catalog's finds are built to a world-class bar, wave 1 first, overnight (owner, Nov 14)

The owner, Nov 14, late: build the catalog's finds in Blender through the night, "absolute
world-class", from reference images rather than made up, with anything that does something
modelled to do it ("lamp that can turn on, RC car that can drive") and its animation perfect.
Sessions are capped at 300k context.

So: `art/finds/CRAFT.md` holds the bar and the method, and `art/finds/WAVES.md` tracks the 133
finds of the catalog's wave 1 plus two pulled forward. Lights go first and the remote-control
car and the die-cast car come next (from wave 4's Figures and models), because the owner named
both; then the catalog's wave 1 sets in its order. The bedroom set's shared 1024 texture is the
floor, not the target: new finds must stay sharp held in the hand, so F-01 sizes textures per
find and bakes detail from a high version. Moving parts are their own parts on real pivots, and
each action's motion is data that Blender previews and the game plays, so what was judged is
what ships. Each set's finds stay out of the floors' deal until a game ticket brings them in.

Not chosen: one atlas per set at 1024 (the bedroom set's way; blurs held in the hand), and
greybox first (AGENTS.md: real assets from the start).

## D-191 Finds are built with one shared kit: a texture set each, baked high to low (F-01, Nov 15)

Every catalog find from F-01 on is built with `art/finds/kit/` (CRAFT.md, "The kit"). Each find
gets its own texture set, sized to reach 300 texels a stud (the bedroom set shares one at 99),
which on a phone keeps a held find sharp; most finds land on 1024. Detail is modelled on a
high version and baked onto the game mesh with its occlusion. Moving and lit pieces are their own
MeshParts pivoted on their real hinges. Glow is the SurfaceAppearance's emissive mask switched by
`EmissiveStrength` (scripts may write it; the mask is set once on the template). Motions are keys
in the build, eased by the same sums in Python and in `Finds/Art.luau`, so the game plays what
the previews showed. The cost: a texture set per find is more memory than a shared atlas; F-S1
judges it on a phone in Studio.


## D-192 Glass and flames are see-through parts of their own; a part can scale (F-02b, Nov 15)

A find's glass (jars, bottles, lenses) and its flame are each their own MeshPart, imported in
AlphaMode Transparency: the alpha rides in the find's colour map and only those parts' material
links it, so the solid parts stay in Overlay and never sort as see-through. In Studio a clear
part wants Transparency 0.02 (or the alpha cuts, docs/STUDIO.md) and CastShadow off. Roblox has
no refraction, so glass reads by a dark glossy colour, thick edges, smudges, dust and soot. Motions
gained `scale` and `stretch` (squash and stretch keeping volume) about a part's pivot, which the
game plays by sizing the MeshPart; a flame is found at scale 0 and the game hides it until it's
lit. The held sheet is now a first-person view with the find in your hands (CRAFT.md), not a
camera 2.6 studs off. The cost: each clear part is another see-through draw; F-S1 judges glass on
a phone.

## D-193 The RC car comes with its transmitter, and drives away from it (F-03a, Nov 15)

The remote-control car is one find with its pistol-grip transmitter standing beside it, as real
ones are kept (a sensible default, not in the catalog row). The transmitter is the find's root,
so in a preview the car drives off and leaves it behind; in play the game lifts the transmitter
into your hands and drives the car's parts by wiring. Motions gained travel channels (x, z, yaw,
pitch, roll, in the parent's frame): the car's lower arms travel over the floor, the chassis
leans on them, the aerial whips in two lengths. The car's motions come from a small driving
simulation (Ackermann steering, each wheel turned by the distance its own tyre rolls), and the
generated Luau carries `Drive`: wheel radii, wheelbase, track, steering lock, suspension travel
and a suggested top speed of 20 studs a second.

## D-194 A kit-built find's template is a jointed Model, made by code; its lights stay under the unit's bulb (F-S1, Nov 15)

Every find built with the finds kit goes into the place the same way: `scripts/upload_art`
uploads its FBX and its glow mask, and `Finds/Kit.luau`'s `import` makes the template in
`ReplicatedStorage.Props.Finds`, checked against the generated Luau. A template is a Model, not
one MeshPart like the bedroom finds: its root is anchored and every moving part hangs on a
Motor6D through its real hinge, so the game plays the art's motions by writing joint
Transforms, the way Roblox animates bodies, with no welds to rebuild. Lights ship off, at full
brightness, for the game to scale by the glow. Judged in a lit unit: no find's light outshines
the unit's own bulb (0.6, range 11), since a lamp that floods the room would make it a light
source for the whole floor, a game choice for later tickets, not the art's. Small finds being
specks from a doorway when off is left for the owner (`OWNER.md`).

## D-195 The disco ball sits on a tabletop motor and makes its own dots (F-02h, Nov 15)

The catalog's disco ball spins and throws spots round the walls. A real mirror ball hangs from
a ceiling motor and needs a pinspot shining on it; a find is set down on a unit's floor or a
shelf at home, so it's built on a real tabletop battery motor (a black dome on a wide skirt, 5
turns a minute), and the spots come from six narrow Spot lights riding on the ball, with no
pinspot modelled: the game's licence, so the player's action (slide the switch) is all it
takes. The neon OPEN sign is pink letters in an aqua border (a real aqua and pink sign), so it
"glows pink" as the catalog says while still looking like the shop sign everyone knows.
Whether Roblox draws the ball's narrow spots on a phone is unchecked (spot lights drew nothing
in Edit captures): Spin's game ticket checks it in Play and may make the dots another way.

## D-196 The hard hat brings its battery; the jar's fireflies fly on their own (F-02j, F-02k, Nov 15)

The miner's hard hat is the mid-century kind the references show: a yellow fibreglass cap, a
round cap lamp hooked into a leather bracket on its front, and its cord over the crown to a
red battery case standing beside it. The cord and battery are their own part (`_Pack`) so the
"Wear" ticket can hide them or hang the battery at the hip; the hat is real size and wants
scaling about 1.4 times on a Roblox head. The jar of fireflies is a quart canning jar with a
punched lid; its twelve fireflies are each their own part with their own glow, flying paths
written as motion data in the jar's frame (`Open`, then `Drift` looped for the minute, then
`Gone`), timed from field records of the common eastern firefly. Three of them carry a light,
and each light follows its own firefly's glow, not the find's glow part (the kit's light
`glow_part`): the game's motion player must do the same.

## D-197 The theatre spotlight is a studio Fresnel on a rolling stand, aimed on its real pivots (F-02l, Nov 15)

The catalog's theatre spotlight ("At home: point it at your best find") is built as the kind of
stage light the references show and most players picture: a round, louvred studio Fresnel
with barn doors, on a tubular U-yoke, on a three-legged rolling stand, rather than a modern
black theatre can. Its lens sits 4.95 studs up, with the stand at its lowest, so it shines
down onto a shelf or the floor. Aiming is two real pivots: the yoke pans about the stand's pin
and the can tilts through its trunnions, so the "point it" ticket sets two joint angles toward
the find (pan any angle, tilt within 70 degrees). `Aim` is a sample of the feel (the lock
backed off, a heavy swing that overshoots and settles, the leaves swinging after), for that
ticket to play with its own end angles. The barn-door leaves are hinged parts, ready for a
later ticket to shape the beam; nothing closes them yet. Its red is a dark oxblood with no
maker's name.

## D-198 The stained-glass lamp is a leaded cone shade in our own pattern, lit by its pull chain (F-02m, Nov 15)

The catalog's stained-glass lamp ("At home: it throws coloured patterns on your walls",
Legendary, Fragile) is built as the leaded-glass table lamp most players picture: a cone shade
of small glass pieces in lead lines with a vented cap and finial, on a dark cast bronze base,
22 in tall with a 14 in shade. Its pattern is our own in that tradition (gold diamonds on cobalt
round the apron, ruby four-petal blossoms with amber cabochons on green, honey bricks to the top),
copying no maker's named design. It switches on the way the real ones do: a tug on one of its
two ball-chain pulls. The coloured patterns are three coloured spot lights shining out through
the band (ruby, green, cobalt) beside the bulbs' warm pool, since Roblox lights can't project
an image; they read on a unit's walls in Studio. It's found with one hairline crack in an apron
piece, as old shades often are, so Fragile has a place to show.


## D-199 The Secret Light is an ordinary 1940s lamp, lit, its plug lying loose (F-02n, Nov 15)

The catalog's Secret Light ("A lamp that's on when you find it": it never runs down, loose only
from floor 25, in a power cut the only light on the floor) says nothing about its look. It's
built as the most ordinary lamp there is, a 1940s brass table lamp with a parchment bell shade,
found lit with its cord running across the floor to a plug lying loose, so a player sees at once
it shouldn't be on; its light is a touch warmer than any bulb in the building and never wavers.
Its one action, `Switch`, turns the key twice and nothing answers. It's found lit by the kit's
own rule (its glow track's first key is 1). The look is a default; `OWNER.md` asks the owner.

## D-200 The die-cast car is our own late-1960s saloon, pushed by the RC car's simulation (F-03b, Nov 15)

The catalog's die-cast car (Common, "Push: it rolls off down the hall") is built as a pocket toy
of the late 1960s, the kind every family had a tin of: our own two-door saloon, 3 inches long, in
metallic blue on a bright zinc base, with painted windows and pale seats behind them, played
with (chips to the zinc on its edges). Its `Push` is the RC car's driving simulation without a
motor: a shove, a roll of about 7 studs that slows, a wandering heading and a rattle on loose
axles. The travel is on its root part, so the game plays it by moving the model, not a joint.
Colour and length are defaults the owner hasn't judged.

## D-201 The cymbal monkey is our own clockwork monkey, its beat timed from real ones (F-04a, Nov 15)

The catalog's cymbal monkey (Rare, "Wind: it bashes its cymbals for 20 seconds, loud") is built
as the 1960s Japanese clockwork kind at a museum record's size (10.5 inches): a plush monkey sat
with its legs out, a vinyl face, felt waistcoat, striped trousers and brass cymbals, wound by a
tin key in its back. It is no maker's character: a green waistcoat edged in gold braid, navy-
and-cream trousers and a maroon fez with a tassel, where the best-known one wears a yellow vest,
red stripes and no hat. Its `Play` is 70 clashes over 21 seconds, the beat taken from the sound
of two videos of real ones (4.6 and 6 a second, each slowing by about a fifth): ours, twice
their size, starts at 4.2, slows to 3.8, then gives out over its last few clashes and stalls
short. Every clash nods the head, rolls the eyes up wide, flings the fez's tassel and rings the
cymbals on their straps, so one action reads as frantic from any side. Its parts and numbers are
in `art/finds/windups/README.md`; the clash sound is a game ticket's (it lands as the arms reach
-24 degrees).


## D-202 The jack-in-the-box prints card suits, and its bang is timed from a real one (F-04b, Nov 15)

The catalog's jack-in-the-box (Uncommon, "Wind: a tune, then a bang as it pops") is built as a
1950s tin music box at a museum record's size (13.5 cm square, 14 cm tall shut), with the crank,
hinge, catch and yellow lid the museum pieces have. It is no maker's character: where the old
ones print clowns, ours prints a playing card's suit on each side (a jack in a box), and the
jack is our own clown in harlequin diamonds with a crazed painted face, which suits a horror
game without being a monster. Its timing comes from the sound of a video of a 1953 one: 7.8 s of
tune as the crank turns, 0.9 s of silence, the bang, then three bounces of the lid. `Wind` is
the tune and the silence, with the crank turning by itself (the catalog's "the bang comes a few
seconds after you let go"); `Pop` is the bang; `Shut` puts it back so it can be wound again,
which the catalog doesn't ask for but a reused toy needs. Once popped, the jack is left with its
head cocked at the player. Its parts and numbers are in `art/finds/windups/README.md`.

## D-203 The Nov 15 finds are dealt by grade, rolled by floor (F-G1a, Nov 15)

The finds built overnight join the floors' deal with the item catalog's numbers (D-188), taken
as written: six grades and their chance on floors 1 to 9, 10 to 24 and 25 up (Common 62, 50,
40 in 100; Legendary 0.5, 1.8, 4; Secret none, 0.2, 1, doubled from floor 50), and each find's
own grade and worth. A unit dealt a find rolls a grade, then one find of that grade, each as
likely, as Pet Simulator's eggs roll a rarity and then a pet. Grades with no find a floor can
deal drop out and the rest share their chance, so on floor 1 the glass lamp (the one Legendary
built) is 1 find in 200 and the firefly jar (the one Epic) 1 in 40. The Packrat's pile rolls the
same way. The bedroom four got the catalog's rows too: the teddy Common 4 ("Small teddy bear"),
the skates Uncommon 18, the boombox Uncommon 25, the TV Uncommon 22 ("Small box TV").

- **Left out:** the theatre spotlight, a catalog big find six studs tall: no floor has a big
  find yet. The Secret lamp is dealt from floor 25 only ("Loose only, floor 25 up").
- **The Packrat takes your most valuable find first** by the catalog's worth now, not by
  heft (S2-06c's stand-in): the TV over the skates over the teddy is unchanged.
- **Not yet:** a find's worth isn't rolled within a quarter either side (the catalog) or paid in
  cash; kept finds are counted by name as before. The grade doesn't show yet (F-G1c).
- **Found as the sheets show:** a kit-built find's template stands at its rest, the art kit's
  rule (each part at the first key of the first motion that moves it), worked out in the game
  (`Finds/Pose.luau`, the kit's own sums) and written into its joints, since Motor6D's
  Transform doesn't replicate. The motions' order is kept in `Finds/Order.luau`, checked
  against the generated sets, since a Luau table forgets it.

Not chosen: dealing every find as likely (a Legendary as common as a teddy kills the hunt);
putting the rest pose into the art (the sets are the art sessions' and the template is shared).

## D-204 Purchases before the climb with no top; the glow at the door parked (owner, Nov 15)

Brix built its purchases piece on Nov 15: `Purchases`, `Roblox.Marketplace` (asks Roblox for
prices) and `Roblox.PlayerPurchases` (takes Roblox's receipts and shows purchase prompts), on its
main branch at `5cdb8c2`, pushed, and in no release (v0.1.0 was tagged before it). This game
takes Brix as a submodule pinned to a commit (FRAMEWORK.md), so it doesn't wait for Brix 0.2.0:
S3-02 starts by moving the pin. With purchases no longer blocked, the GDD's build order stands
again and the owner agreed: Step 3's products (S3-02 to S3-04) come before Step 4, which had been
pulled ahead only because purchases were blocked. Brix's own last purchases check (its ENG-23e:
a phone purchase granted once through a forced save failure and a server hop, prices under
regional pricing, an offer switched off live) needs a published place with real products, so
S3-02's phone test in `OWNER.md` is that check.

F-G1c (a find's grade shown at the door: a Rare's glow, an Epic's light spilling as the door
rolls up, a Legendary's gold under the door) is parked: the owner cut it for now. They are
shaping packed units: boxes stacked to the ceiling with a path to the back, where a monster
sleeps or a box waits, and finds inside boxes, so the reveal is opening the box, a blind box
moment, and not the door (ROADMAP "In no step"; `OWNER.md` asks seven questions with defaults).

Not chosen: waiting for Brix 0.2.0; keeping S4-01 first.

## D-205 What you find comes in a box you open (owner, Nov 15)

The owner's design, answering D-204's questions. A door rolls up on what fits a storage unit:
most units hold somebody's stuff players can't use (stacked boxes, a mattress and the like),
some are bare. A unit with something to take has one box, marked just enough to show there's
something in it. Inside is a find, a tool, one or more coins, or one of the code's notes.
Opening the box is the payoff that brings players back, built with care to feel like opening a
blind box (Pop Mart's Labubu, blind-bag squishy toys): a find lifts out, shows its grade (a blue
light for Rare, purple for Epic, gold for Legendary, each with its own sound, as Pet
Simulator's eggs show theirs) and becomes yours; coins go to the bank as they do now; a tool goes
to your hands. The code's notes move off the units' back walls (D-044) into boxes: a player
takes the paper with them and can drop it at the elevator to read later, once the team has
found them all, as DOORS' library hands you hint books to carry.

Agreed defaults (D-204's questions): about one in three medium and large units packed (boxes to
the ceiling, a path through to the back, where the marked box or a sleeping monster waits,
never nothing), more on higher floors; small units stay open. Big finds and anything too long
for a box stay out of one. Opening is one press, then a two-second reveal you can't skip that
friends nearby see. Changed by the owner: a box can hold coins (and a tool or a note), not
only a find.

The owner placed these tickets (ROADMAP B-01 to B-05) right after S3-02, before Cut Free and the
floor rules. Defaults the owner hasn't seen yet (`OWNER.md`): the cue is a faint warm line of light at the tape and a soft sound up close, as
Fortnite's chests glow and hum; a note dropped in the car stays by the keypad for that floor; a
note held by a caught player drops where they were caught; one marked box a unit at most.

What it replaces: coins loose on the floor (D-132), finds standing on the floor as found
(F-G1a's pose now plays as a find comes out and when it's dropped), notes on the back walls
(D-044), somebody's stuff in only half the empty units (D-136), and the grade shown at the
door (F-G1c, parked by D-204).

## D-206 Purchases: the save's ledger, one product table, products found by name (S3-02a, Nov 15)
The pin moved to Brix `5cdb8c2` (its Purchases, Marketplace, PlayerPurchases, LiveConfig, Remotes and
round loop; checks green, nothing renamed). The save's version 2 adds `purchases` (Brix's ledger of
purchase ids), `recipients` (who a friend's purchase is for) and `bought` (how many of each offer, by
name); version 1 saves come up with all three empty. `src/shared/Products.luau` is the one table:
each row names its product's exact title on the Creator Dashboard, its live-config switch (on by
default) and what it grants; every grant also counts the purchase in `bought`, in the same change as
Brix's ledger. Prices are never in code: Brix's Marketplace asks Roblox each time.
Defaults taken overnight (in `OWNER.md` once S3-02b writes the phone test):
- **Products are found by their Dashboard title** (S3-02b reads `GetDeveloperProductsAsync` at
  start), so making a product with the row's title is all it takes, with no id typed into code.
  Renaming one on the Dashboard stops it selling.
- **The owner's test product, "Test purchase"**, grants nothing but its count, so Brix's ENG-23e
  phone test (forced save failure, server hop) never touches cash. Only the owner's dev prompt
  shows it.
- **Each offer has its own live switch** (`sellTestPurchase`, and `sell<Offer>` for each one to
  come), a plain true/false in the experience's configs, rather than one list of offers off.
- S3-02 was split for the session's size: S3-02a (this), S3-02b (the server's wiring and Studio's
  made-up receipts).

## D-207 The server takes receipts: Purchasing, Live, and the owner's two test switches (S3-02b, Nov 15)
`Purchasing` (a server system after `recording`) finds each `Products` row's id once at start by its
Dashboard title (4 tries, 5 s apart), then builds Brix's Purchases over Saving's saves (`saves()` or
`began`, which Studio fires a moment late) with Recording's Analytics, and Brix's PlayerPurchases on
`ProcessReceipt`. `Live` (slot `live`) is Brix's LiveConfig of every product's switch (true/false,
on by default) over Roblox's experience configs, kept current by Brix's ConfigRefresher. Proven in
Studio Play with made-up receipts: granted once, the same id again granted nothing, a failed write
waited and was granted once when the save came back; a switch set off took the offer off sale.
Defaults taken overnight:
- **Nothing sells on a server where no row's title matches a product.** Brix refuses an empty offer
  table, so Purchases isn't built and `ProcessReceipt` isn't set; Roblox keeps any receipt for a
  server that knows it. A product made while servers run sells on servers started after.
- **Studio gives a row with no product a made-up id** (its place in `Products.Names`), so receipts
  can be tried before the product exists. Such an offer can't be prompted (no price).
- **The owner's test switches work on live servers too**, since only server code can set a
  Workspace attribute: `DevSaveFails` (every save write fails) and `DevPrompt` (an offer's name;
  prompts the place's owner, anyone in Studio, owner-only offers included). `DevReceipt` is Studio
  only. The owner is a user (not a group), so "the owner" is `game.CreatorId`.
- **`prompt` answers Brix's listing or its not-on-sale**, and refuses with Brix's own reasons:
  `unknownOffer` for an owner-only offer asked for anyone else, `notHeld` before this server sells.
  S3-03 and S3-04 branch on them.
- **`offerShown` is recorded only once a prompt went up**, so with Brix's `offerBought` it gives
  each offer's share of prompts that sell.
- **Each grant prints one line on live servers too** (`[Purchasing] granted <offer> to <name>
  (bought N)`), for reading a purchase's fate in the server log.

## D-208 The marked box: eight parts on the boxes' atlas, the tape snaps in the middle (B-01a, Nov 15)
The box a unit's find, tool, coins or note comes in (D-205) is a Medium box built in `art/boxes`
beside the scenery boxes and exported in the same `Boxes.fbx`, so all six share one Cardboard
texture set (the atlas went from 97 to 90 texels a stud; its inside, flap insides and cut edges
wear the Open box's texels). It has the maker's print and no marker word. It is a Model of eight
parts: the body, four flaps (the end flaps fold under the long ones), two tape halves and the
seam (two thin lines along the tape's edges, untextured, so the game makes them Neon).
Defaults taken overnight (`OWNER.md` "Judge the marked box"):
- **The tape snaps across the middle and its halves whip back to the box's ends**, rather than
  splitting along the seam as a knife does: a strip parting in the middle reads on a phone; a
  split along a 2-inch strip doesn't. The flaps then burst past upright to the Open box's angles.
- **The cue is two warm lines leaking out along the tape's edges** (196, 122, 58 at 0.3
  transparency, mid warmth so Neon doesn't smear), with an optional warm PointLight for a player
  up close; the lines hide as the tape tears. Faint under the hall light, clear in the dark.
- **Sounds:** a 0.15 s nylon rip for the tape, a cardboard slap for the flaps, a soft pulsing
  hum looped up close (`Boxes.Sounds`).
B-01 was split for the session's size: B-01a (the art, this), B-01b (into Studio).
In the place (B-01b, Nov 15): the template is the Model `ReplicatedStorage.Props.Boxes.Marked`,
PrimaryPart its body, streamed atomically so a phone never draws a box without its flaps. Only the
body collides or answers a raycast; the flaps, tape and seam don't, so the burst never shoves a
player and a prompt or camera ray goes to the body. Each part's pivot sits on its hinge turned
square with the box, so a motion is one `PivotTo(box pivot * CFrame.new(Pivot) * turn about Axis)`
per part. The tape's halves cast no shadow (too thin to matter on a phone). The cue's warm PointLight
is not in the template: whoever lights the cue adds it, counted against the light cap.

## D-209 Opening the marked box: the server stamps, every screen plays it (B-02a, Nov 15)
`MarkedBoxes` (slot `markedBoxes`) stands a box (`stand(unit, place)`: tagged `MarkedBox`, the unit
in an ObjectValue `Unit`, one tap "Open" on the lid, line of sight off) and checks a press as every
press is (`Boxes.Opening.refuse`: opened, dead, wrapped, far, a shut door; then `allow`, 3 a second,
2 at once). The first press to arrive opens it once: the button goes, the box is stamped `OpenedBy`
then `OpenedAt` (server time), and `opened` fires for B-02b. The server never moves a flap.
`MarkedBoxView` plays `Specs.Marked.Motions.Open` on every screen. Defaults taken overnight:
- **A stamp arriving within 0.6 s plays from its first frame where it lands** (`Opening.clock`), so
  the opener and friends always see the whole tear (ping only delays it); one seen later (streamed
  in, joined) runs from the server's time, and a box reached after it opened stands open.
- **The rip plays 0.1 s in, the slap 0.3 s in** (the flaps bursting through upright), heard 40
  studs off; a beat a screen reaches more than 0.25 s late is skipped, never played out of step.
- **Up close, while shut:** the hum (heard within 12 studs, playing only within 16, out of step
  box to box) and the cue's warm PointLight on the one shut box nearest you within 10 studs: one
  light a screen, whatever the floor holds. Both go with the lines as the tape tears (the hum in
  0.08 s).
- **Reach 7 studs** (a little under a coin pile's 8, so you're close enough to see in), the
  server's 2 of slack. No words for any refusal: an opened box has no button, and a shut door
  hides its Open on your screen as a battery's Take is hidden.
- **An opened box stays open where it stood** for the rest of the floor, solid as before.
- **Studio's `DevBox`** (Workspace, true) stands one where a find would stand in the next unit that
  opens, then turns itself off; B-03 replaces it with the deal.

## D-210 The find comes out: a held breath in the grade's colour, then into your hand (B-02b, Nov 15)
The server keeps what's inside to itself until the open (`MarkedBoxes.stand(unit, place, find)`),
then stamps `Find` and `Grade` (and `LaidAt` for full hands) in the same batch before `OpenedAt`,
and gives the find at `Opening.handAt(hold)` (`Slots.give`, with its pick-up sound). On screens,
after the tape tears the flaps hold shut for the grade's hold (`Opening.flapTime`), lifting at
their edges and trembling, the box rocking on its base as a hatching egg wobbles (Pet Simulator);
a Neon glow under the flaps and one PointLight in the grade's colour build through the hold, flare
at the burst and die (`Opening.glow`); then a copy of the find rises over the rim with a hair of
overshoot, turns once and flies to the opener's hand (`Opening.lift`), gone as the server's own
arrives. In Play a Rare took 0.66 s to burst and was in the hand at 2.25 s; a Legendary's hold
washed the whole unit gold at Level01 (`docs/art/B-02b-hold-legendary-level01.jpg`).
Defaults taken overnight (`OWNER.md` "Open a marked box with a friend: the reveal"):
- **Colours** (`Grades.Colours`): Common the box's own warm light, Uncommon green, Rare blue,
  Epic purple, Legendary gold, Secret red, as Pet Simulator and Brawl Stars colour theirs.
- **Holds**: Common 0.14 s, Uncommon 0.3, Rare 0.5, Epic 0.7, Legendary 0.95, Secret 1.2; a
  Common is in your hand about 1.9 s after the press, a Secret about 2.9 s.
- **Sounds** (`Boxes.Reveal`, Pro Sound Effects'): a magic rattle through the hold, timed so its
  loudest lands on the burst, deeper and louder the rarer; Legendary and Secret add a thin
  rising tone; falling twinkles at the burst from Rare up, a shimmer of air for Common and
  Uncommon. Heard 30 studs (Common) to 140 (Secret); the rip and slap stay at 40.
- **Full hands**: the Open still works; the find comes out, turns and lands on the floor beside
  the box toward the opener, with its Take. Decided at the press; if the hand fills or the
  opener dies during the reveal, it lands there too.
- **An empty box** (no find, B-03's coins to come) plays as a Common with nothing rising.

## D-211 A unit's find or tool waits in its box when it packs into one (B-03a, Nov 15)
A unit dealt a find or tool stands its one marked box behind the bulb, facing the doorway, where
a find would stand, holding it (`Deals.layBoxed`, `MarkedBoxes.stand` with the catalog key); the
thing is never seen until someone opens the box. Whether it goes in is `Deal.packs` (pure,
`tests/boxdeal.spec.luau`): its three sizes against the box's, both sorted, so it packs whichever
way round fits, as you'd pack a moving box, less `Deal.BoxWall` (0.05 studs) of cardboard each
side (a real 18-inch box is about 17.6 inside; HANDOFF's suggested 0.1 would have left the skates
and the hard hat loose for a hair). Anything that doesn't pack stands loose as before, since a
box it couldn't have come out of would read as a trick (D-205: big finds stay out).
- **What packs today:** 16 of 23 built finds: every Common but the desk lamp, every Uncommon but
  the boombox and TV, the Epic firefly jar, and four of six Rares (the RC car, cymbal monkey,
  disco ball, hard hat; not the oil lamp or neon sign). No Legendary or Secret: the stained glass
  lamp and the unplugged lamp are taller than the box. Of the tools, only the padlock; the saw,
  bolt cutters, ladder, bubble wrap and air horn are too long. A tool's row has no grade, so it
  opens as a Common (MarkedBoxes' fallback).
- **Defaults** (`OWNER.md`): big finds loose (a tall marked box suggested, so the top grades get
  their reveal); the Packrat leaves shut boxes alone (`Slots.finds` never lists a find still in
  its box), so it fetches only big, dropped or laid-out finds; the faint mark is a note's and
  untouched until B-04 moves notes into boxes; the deal's odds are unchanged (a find unit is now a
  box unit).
- **`DevBox`** (Studio): a catalog key deals the next unit that opens that find or tool in place
  of what it held, in its box whatever its size (to see every grade's reveal); `true` is gone.
- Verified in Studio Play on seed 2000013's floor 3: six units dealt boxes (padlock, skates, blob
  lamp, moon lamp, die-cast car, night light), the oil lamp and desk lamp stood loose; the padlock
  opened as a Common into slot 1, the skates as an Uncommon (copy seen from 0.56 s, in the hand at
  2.1 s) into slot 2; `DevBox` "StainedGlassLamp" stood a forced box. No script errors.

## D-212 A unit's coins come in a box, and somebody's stuff stands in most units (B-03b, Nov 15)
No coins lie on a floor any more. A unit's coins (1 to 3) go in its marked box with its find or
tool; with no box for them (a find or tool too big to pack, a keeper, or nothing else), they get
a box of their own where a find would stand, clear of what else is there (`Deals.layCoinBox`).
Only where no box can stand do they lie loose as before. One box a unit (D-205) holds for finds;
a big loose find's coins in a second box beside it is the default (`OWNER.md`).
- **The moment:** the opener's coins go into their count with the open (`Coins:pay`, reason
  "box", which Recording counts as the climb funnel's "coins" step, as a pile was), so nothing
  is lost if they walk off. Their screen holds the count at its old number: CoinView queues one
  flying coin per coin the moment it sees `OpenedAt`, launching from the top of each coin's jump.
  On every screen, at the burst plus `Opening.Out.Rise` (with the find's rise), the coins jump
  out from under the rim (`Coins.Box`: a higher jump than a pile's, fanning out from a ring) so
  they burst round a rising find, not through it, with the take's chink and jingle at the box.
  The count ticks once per coin as each lands, the same tick climbing in pitch. A box of coins
  alone opens as a Common. In Studio Play a Common box's coins left at 0.47 s and ticked in from
  1.07 s; the skates' Uncommon box's at 0.58 s and 1.25 s, while the skates hung turning.
- **The battery stays loose:** it's a quick grab for a dying torch, as DOORS lays batteries out
  for the taking, not a reveal; a box would also break one box a unit.
- **Somebody's stuff in most units:** 7 in 10 of the units with no keeper and no note
  (`Deal.StuffShare` 0.7; it was half the empty ones), so most doors show somebody's life and some
  stay bare. Never with a keeper (it's the keeper's unit, and nothing solid in its way out) or a
  note (B-04 moves notes into boxes). Still no draw of its own: the unit's pick, scaled by 89
  with the whole part dropped (`Deal.StuffScramble`), since a find unit's pick chose its find;
  the deal's fingerprint is unchanged. Deals lays it last, clear of the box, a loose find or tool,
  the coins and the battery (`DealSpot.stuff`'s `taken`); in a medium unit something always
  stands beside the box, in a small one 3534 of 3600 tries (`tests/stuffdeal.spec`).
- Verified in Studio Play on seed 2000013's floor 3: Unit301 a box of 2 coins alone and a column
  of boxes; Unit312 the padlock and 3 coins in one box and a rolled rug; Unit319 the skates and 2
  coins and an old mattress. Each count rose 2, 3 and 2, held until the coins landed. No errors.

## D-213 A note comes in a box, and goes in your pocket (B-04a, Nov 15)

The code's notes leave the back walls (D-044). A note's unit has its one marked box with the note
in it, and the unit's coins with it; never a note on a wall unless no box can stand (then it goes
on the back wall as before, and Studio's Output says so, so the code is never lost).

- **One box, one thing.** A note's unit is never dealt a find or tool: D-205's box holds a find, a
  tool, coins or a note. The roll still decides its keeper, and behind a padlock a keeper may
  stand guard by the note's box as one would by a find (`Deal.open`, `Deal.noteIn`). The deal's
  fingerprint moved (`tests/stuffdeal.spec`); the odds' tallies leave note units out.
- **Its own reveal**, lighter than any find's (`Opening.Reveals.Note`: a 0.06 s hold, a weak warm
  light the colour of the bulb on yellow paper, heard 24 studs off), no rattle, just the sheet's
  sharp flap (the card's own sound) as the flaps burst. The paper rises out of the box rocking as
  a loose sheet does, turns once facing the opener and flies to their eyes, where the card lifts
  with it (D-045's card, unchanged): the first thing you do with a note is read it. Friends see it
  fly to the opener's hand.
- **A pocket, not a hand** (default, `OWNER.md`). The server keeps each player's notes and mirrors
  them on the player (`NoteCard.Held`, "_ 7 _ _" joined by "|", at most four). A note never takes
  a slot, so nobody has to choose between a find and the code, as DOORS keeps its hint paper in a
  slot of its own. Each held note is a small paper tucked at the screen's left edge with its slots
  on it, sliding in as you take it; a tap holds it up on the card. Walking doesn't drop a held
  note's card (it's in your hand); dying does. Notes leave pockets with their floor.
- **Until B-04b:** a caught player keeps their notes (they can still read them out); a player who
  leaves puts theirs back on its unit's back wall (`FloorBuilder.stickNote`). B-04b drops them where
  you were, and lets you leave one in the car by the keypad.
- Verified in Studio Play on seed 2000013's floor 3: Unit317's box held "_ _ _ 4"; the paper came
  out, the card lifted with it, the pocket paper showed. No errors.

## D-214 Notes go up by the keypad, and drop where you're caught (B-04b, Nov 15)

The code's notes now ride in a server system of their own (`Pockets`: `give`, `pin`, `drop`), out
of MarkedBoxes, which hands each box's note to it.

- **Up by the keypad, on their own** (default, `OWNER.md`). The gate is shut until the code is in,
  so "the car" is its keypad on the lobby wall. Walk within `NoteCard.PinReach` (5 studs) of its
  face, on the lobby's side, holding notes, and every one goes up on the wall beside it, in a row
  away from the opening (`NoteCard.pinAt`: four fit before the lobby's side wall at x -12), as a
  simulator's sell pad takes your bag as you step on it. Each is a wall note like any other, with
  its Read button. They go with their floor. Never from inside the car, so a ride can't pin.
- **Dropped where you were.** Caught (`Keepers.caught`) or leaving, your notes tumble out flat on
  the floor under you (`NoteCard.scatter` spreads more than one, short of walls), each with a Take
  button checked on the server (not caught, alive, within reach, one press a `TakeSeconds`); Take
  pockets it and lifts it on your screen, so a dropped note needs no Read button. Dying another way
  keeps them. A note whose holder left before it reached them still goes back on its wall.
- **Every screen sees it go** (`NotePlaces`): stamped `Placed`, `PlacedAt`, `PlacedFrom`, a pinned
  note flies from the hand in a short arc, a quarter turn spun off, and presses into the wall with
  a tack's tap (the unit light's click, its first click pitched up); a dropped one leaves the hand
  with a flap, rocks down as a loose sheet does, and settles with a softer flap.
- Verified in Studio Play on seed 2000013's floor 3 with a test instance of Pockets: notes pinned
  flush on the lobby wall beside the keypad (wall face hit at the note's back), the flight sampled
  landing at 0.39 s with its tap; two notes dropped flat 2 studs apart, Take pocketed one, its
  paper showed, no Read on dropped notes. A real box's note and a real catch through the running
  system are untested in Studio.


## D-215 A packed unit's walls are blocks of boxes that wear the boxes' own texture (B-05a, Nov 15)
B-05 was split for the session's size: B-05a the stacks' art (this), B-05b the deal and the path.
A packed unit's walls are built from seven blocks (`art/packed/`): ColumnA to C (one box wide, to
9.2 to 9.6 of the 10 stud steel top), WideA and WideB (two wide, on a wardrobe box laid on its
side), Half (5.2 high) and Toppled (a large on its back and a medium tipped off it). Each is one
MeshPart of 84 to 326 triangles: every box is cut into a few quads a face (2 x 2, bowed out a hair
at the middle like the boxes kit's), with no faces under a box or on the floor, so a unit walled
with about twenty of them costs about 5,000 triangles. The blocks' faces map onto the same atlas
islands the boxes' do (the boxes' own packer, run again), and the FBX carries no texture: on
import `Packed.prepare` gives each block a copy of the Medium box's SurfaceAppearance, so the
blocks share the boxes' texture IDs and add no texture memory.
Defaults taken:
- **Blocks stand side by side at a 2 stud pitch** (`Specs.Pitch`); a column's boxes are 1.8, so
  neighbours leave a dark crack about 0.2 wide, as real stacks do. The build nudges any box that
  would poke past its block's width back in, so neighbours never run into each other
  (`tests/packed.spec.luau`). A box sits at most 0.1 proud of or sunk behind its block's front,
  so the torch rakes a wall that isn't flat.
- **Larges are few** (one a column, two a wide stack): a large box says XMAS on both its side and
  its end. A medium box wears either its own sides (KITCHEN, FRAGILE) or the open box's (PHOTOS,
  UP), so a wall reads as many people's things. New marker words would mean rebaking the boxes.
- **The sheets' sample unit** brings the path in 3 studs wide up the middle (under the bulb) from
  2.5 in (`DealSpot.Door`), then turns left along the back wall into a clearing the doorway can't
  see. From the doorway the marked box's warm line just shows past the corner, a lure; B-05b
  decides whether real layouts keep that.
Not chosen: individual box clones (a packed unit would be 60 to 100 parts); a new texture set.

## D-216 A packed unit is one straight path in and one bend into a clearing, dealt last (B-05b1, Nov 15)
B-05b was split for the session's size: B-05b1 the layout and the deal (this), B-05b2 laying it on
the floor, the clearing's box or sleeper, the keepers and the camera.
- **The shape** (`src/shared/PackedLayout.luau`): the path comes in 3 wide straight up the middle
  from the doorway to the back wall, so it takes the landing under the top's hole whole and runs
  under the bulb. About 3 deep from the back wall (`Clearing`, the nearest whole columns), the
  stacks on one side stop and a clearing opens along the back wall to that side's wall. Which
  side, and which blocks, follow the unit's number. Blocks stand in lines with their fronts on
  the path, the doorway's line 2.5 in, the clearing's near side; each line meets the path flush and
  spreads its spare length between its blocks, so no gap is over 1.2. The floor behind the lines is
  left empty, so a unit is 9 to 11 blocks and at most about 2,100 triangles, not D-215's estimate
  of twenty. A low stack stands in the clearing's far corner in two units in three. From the
  doorway the clearing's far side is always hidden; its near corner may show, the lure D-215 liked.
- **Which units pack** (`Deal.packedShare`, `deck.packed`): medium units only, 0.3 of them on
  floor 1 rising 0.02 a floor to at most 0.5; never the lobby's hall on floors 1 and 2 (the first
  doors you meet show their floor) and never the Packrat's unit (its pile needs the floor round
  it). Drawn last in `Deal.new`, so every seed deals everything else as before (the stuff spec's
  fingerprint is unchanged).
- **Never for nothing**: a packed unit holds no somebody's stuff (the stacks are its stuff), and one
  dealt no find, tool, note or monster with no coins gets `Deal.PackedCoins` (1) in its box.
- **What the saw does to a packed unit is open.** The path can't keep the side walls' crawl hole
  floor (3.3 out from each side wall) or the top's fallen panel's floor clear without opening
  half the unit, so the stacks stand there. B-05b2's default: a crawl hole or a top hole into a
  packed unit opens onto boxes; until that's built, OWNER.md asks.
Not chosen: a path along a side wall (it can't take the landing under the top's hole); filling the
hidden floor with blocks (costs triangles nobody sees); a find as the empty unit's prize (it would
add about one find in seven medium units to the economy).

## D-217 A packed unit's things stand in its clearing; keepers turn at the bend (B-05b2a, Nov 15)
B-05b2 was split for the session's size: B-05b2a the code (this), B-05b2b walking it in Studio.
- **Stacks first.** `Deals.open` stands the blocks (`layStacks`) before anything the unit holds, in
  the unit's hall piece as somebody's stuff is, and marks the unit `PackedUnit` (an attribute).
  `Packed.layout(size, number)` is the one layout both the deal and the keepers' map use.
- **The clearing holds it all.** `DealSpot.Unit` gains `room` (the clearing: things stand there in
  place of the floor past the door and the From/To depths), `stacks` (never within
  `DealSpot.Stack`, 0.25, of a block), `lure` and `nook`. A find or any box goes nearest `lure`,
  the back wall `PackedLayout.Lure` (1.5) past the path's edge, so its near corner shows from the
  doorway; a keeper goes nearest `nook`, the clearing's far end, wholly out of the path's line.
  The clearing is searched on a quarter-stud grid, so a keeper guarding a find (a padlocked
  unit's) always fits beside its box, at the end of the path.
- **The corner's low stack stands last**, only where nothing the unit holds stands, so a sleeper
  or a box always has the clearing's hidden end.
- **Keepers walk the path.** `KeeperMap.pack` makes the unit's place its path (from the doorway up
  the middle to the bend) and adds the clearing as a place joined at the bend, so a woken sleeper
  turns there and comes down the middle, never through a stack (keepers move by CFrame), and
  can't see the hall until it reaches the path's line. Studio warns if the map's bend and the
  stacks' disagree.
- **Saws** (OWNER.md's default): a crawl hole into a packed unit has no Crawl button either side
  (no words: the boxes are what you see). The top's hole lands you in the path, as the layout
  keeps its landing clear. Panels falling under the stacks is a polish line.
Not chosen: laying the keeper before the box so a guard always gets the nook (the box would lose
its place round the bend); the stacks as keeper-map walls (the map has no walls, only places).

## D-218 A lone box peeks round the bend (B-05b2b, Nov 15)
Seen in Play (Unit302, floor 3, seed 2000013): the box at the lure (1.5 past the path's edge, at the
back wall) hid wholly behind the last stack from every spot in the doorway, so D-215's sliver never
showed. Moving the lure in wasn't enough: a guard (a padlocked unit's keeper) needs the path's end
beside its box, 2.1 across, so that box can't come nearer the path than it stands.
- **Two spots.** A box with no keeper to stand beside it (a find's or tool's box with no guard,
  a note's box, a coin box) goes nearest `peek` (`PackedLayout.Peek`, 0.5 past the path's edge, a
  stud off the back wall): its 1.8 stud front pokes 0.4 into the path's line, a hand's width of
  marked box at the foot of the back wall straight down the path. A guard's box keeps the lure.
- **A stud off the wall.** A peek on the back wall's line tied a spot deeper in the path with the
  one round the corner (both 1.25 away), and the first found won; a box's middle a stud off the
  wall breaks the tie.
- A sleeper with a box in its clearing walks through it at the bend; a ROADMAP polish line.
Not chosen: a deeper clearing (re-lays every unit's stacks); a glow from the box (a polish line).

## D-220 Cut Free on the server: a spare in the save, spent as it frees you (S3-03a1, Nov 15)
The GDD's "Getting caught": the screen you see while caught offers Cut Free, for Robux only; it
frees you right now, and bought while you're carried up, you're standing in the elevator when it
reaches the next floor. DOORS' revive. Built: `Products.Rows.cutFree` (title `Cut Free`, switch
`sellCutFree`); the save's version 3 adds `spares` (offers paid for and not yet used, by name);
`CutFree` (shared numbers, `spares`, `spend`); `CutFrees` (server system, slot `cutFrees`).
- **The grant is a spare, spent as you're freed.** A purchase lands seconds after the press, and
  by then a friend may have cut you free or the climb may have ended. Freeing you straight from
  the grant would lose that purchase, so the grant only adds a spare (saved before Roblox hears
  it's granted), and once saved CutFrees spends it on freeing you. If you can't be freed it waits
  in the save, and your next press uses it with no prompt. DOORS keeps bought revives too.
- **Freed in your unit, the door hauls itself up.** The film rips off you as a friend's cut rips
  it (every screen plays it; the record counts you freed, cutter yourself), then
  `CutFree.DoorAfter` (0.45 s) later the door rolls all the way up on its own, its padlock off
  first if one is on. Not chosen: standing you in the lobby (the old Studio let-in) or leaving
  you shut in the dark (a paid escape you'd still need a friend for).
- **Carried up, you stand in the car once it has reached the floor** (`Climbs`' car spot, the
  emptiest of the car's six riding spots, facing the gate), not mid-ride, where your screen
  wouldn't show the ride your friends see. A purchase that lands after you're already in a unit
  frees you there instead.
- **The button shows only while it can sell**: `Remotes.CutFree`'s `On` (a product of that title
  exists and its switch is on; checked every 2 s). In Studio it's always on, and with no product
  to prompt a press frees you for nothing, as before, so its moment can be felt.
- Split for size: S3-03a1 (this), S3-03a2 (the buttons), S3-03b, S3-03c.

## D-219 A sleeper waits just round the bend, its box behind it (B-05b2b fix, Nov 15)
- **The moment:** you walk the dark path, turn the corner, and the Mannequin is right there,
  side-on to the doorway and facing you; the marked box waits behind it at the far end, and you
  reach past it to open the box. Its walk out, woken, goes straight to the bend and never
  crosses the box. DOORS' Library works the same way: the books you need lie past Figure, and
  one loud move brings it to you.
- **Why side-on:** beside the path the clearing is 4.1 across. Facing the doorway a sleeper is 2.1
  across, so it, the half stud kept round it and a 1.8 box need 4.4. Side-on it is 1.5, leaving
  0.3, less than a step of the spot grid, so its floor stands flush with the path's line
  (`PackedLayout` `hide`, `face`).
- **Reaching the box:** a player can't get round the sleeper, but keepers don't block players
  (the Mannequin's parts don't collide) and the box's Open reaches 7 studs with no line-of-sight
  check, so it opens from the bend.
- **The path's end stays clear:** with a sleeper laid, Deals keeps everything laid after it (the
  note's or coins' box, loose coins, a battery, stuff) off the path's end (`walk`), so the box
  can't fall back to the walk when it can't turn to face the doorway behind the sleeper.
- A guard (a padlocked unit's keeper) still stands at the path's end beside its box at the lure
  (D-218), facing the doorway. A box with no keeper still peeks.
Not chosen: a deeper clearing (re-lays every unit's stacks, D-218); bending the walk round the
box (the floor in front of it is 1.27, the Mannequin 1.89 across).

## D-221 The Cut Free button: a warm pill beside Bang, F on a computer (S3-03a2, Nov 15)
- **The moment:** wrapped in the dark, Bang comes up as the thing you do; a beat later
  (`CutFree.InAfter`, 0.35 s) one smaller warm pill eases in to its left, the way out. Press it,
  pay, and the film rips off you and the door hauls up; both buttons fade as you walk out. DOORS'
  revive button on its death screen.
- **Warm against cold.** Bang is cold off-white on black; Cut Free is the hall's warm light on a
  dark warm fill (`CutFree.Ink`, `Fill`), a touch more solid. No pulse or glow: a paid button
  that throbs at a scared player is a trick, and "Hooked by fun, never by tricks" rules it out.
- **Placement.** Level with Bang's middle, left of it, `CutFree.Gap` (0.42 of Bang's side, 44
  points on an iPhone in landscape) clear, `Tall` 0.46 of Bang's side (48 points: above Apple's
  44-point tap minimum). On a phone the right thumb mashing Bang never reaches it, so a paid spare
  is never spent by accident. On a computer its key sits on Bang's key line.
- **F on a computer, Y on a gamepad.** First person pins the mouse to the middle, so a key reaches
  Cut Free as Click reaches Bang (FreeCursor's Left Alt still lets you click it). Not E: E is the
  game's use key, and a scared player mashing E at the door would spend a spare by accident. Not
  freeing the mouse while caught: you'd lose looking round the dark unit.
- **A click on Cut Free isn't a bang.** Bang binds the left mouse button everywhere; a click that
  lands on Cut Free (a freed mouse) is Cut Free's alone (`PlayerGui:GetGuiObjectsAtPosition`).
  Seen in Play: the server counted no bangs from it.
- **A press dims it for `CutFree.AskEvery`** (to `Dim`, 0.45 of fully in) as Roblox's prompt comes
  up, and the press is ignored till then, as the server would drop it. Cancel the prompt and it
  comes back.
- **The watch bar's button is the same pill**, shown on the same `On` flag (not Studio only now),
  fading with the bar, with the same click, spring and dim.
- Colours in the shared module are plain `{ r, g, b }` records: the Lune specs load
  `CutFree.luau`, and Lune has no `Color3`.

---
## D-222 Free a Friend: a free player's pill with the friend's face, under the corner map (S3-03b, Nov 15)
The GDD's "Getting caught": Free a Friend "frees a friend who is caught, from wherever you are
standing", 49 Robux. DOORS' revive, bought for a friend (Brix's `forAnother`, D-206).
- **The buyer is the free player.** The GDD's product table puts it on "the screen you see while
  you are caught", but a caught player would buy Cut Free, and "wherever you are standing" is the
  free one; built for them, the table's line in `OWNER.md`.
- **The moment:** a friend's scream cuts off across the floor and their dot drops off the map;
  `CutFree.FriendInAfter` (0.8 s) later a warm pill eases in under the map, their headshot and
  "Free". Paid and freed, their film rips and door hauls up as their own Cut Free would (cut by
  the buyer: the record and every screen count the buyer as cutter); left behind, they stand in
  the car at the next floor. The buyer hears a faint rip (`CutFree.FriendRipVolume`) and the
  pill swells and goes, if they pressed it in the last `FriendHeardFor` seconds.
- **One pill per caught friend**, the longest caught on top, at most `FriendMost` (3). Cut Free's
  warm ink, no price, no pulse. A tap, or a click with a freed mouse (Left Alt); no computer key,
  so it never grabs at a player mid-chase (F is the tap's); Y on a gamepad presses the top one.
- **The grant is a spare in the buyer's save** (`spares.freeFriend`), spent as the friend named
  in the sale is freed. A friend already out when it lands leaves it there, and the buyer's next
  press spends it with no prompt. The ticket's default was a spare Cut Free; a spare of what was
  bought keeps the purchase what the buyer paid for (`OWNER.md`).
- **The press** (`Remotes.FreeFriend`, the friend's UserId) is checked: no faster than
  `CutFree.AskEvery`, a whole non-zero UserId (`CutFree.friendId`), a player in this server, not
  the asker, caught now. The asker may be caught too; only the screen decides who sees it.
- Studio: Workspace `DevFreeFriend` (a UserId) stands up a pill as if that player were caught;
  `DevReceipt` takes `recipient` (a save key), naming who it's for as the prompt would.

## D-223 Free Everyone: the results wait while every caught screen offers it (S3-03c, Nov 15)
The GDD's "Getting caught": Free Everyone (149 Robux) frees every caught player at once; if the
whole team is caught it's offered before the results, and the climb carries on from that floor.
DOORS' revive on its death screen.
- **The moment:** the last of you is wrapped; instead of the black coming down, the dark holds,
  and on every caught screen the warm pill grows into "Free Everyone" (wider, a swell, its click
  pitched low: a chance, not a press). Someone pays and every film rips, every door goes up.
  Nobody does and the results come down as before. No countdown on screen (no visible clocks).
- **How long it waits:** `ClimbEnd.OfferFor`, 12 s from the last catch (about 8 s with the pill
  up), only while the offer is on sale (`CutFrees:offers`); nothing on sale, the end lands on the
  catch's black as before (`ClimbEnd.ends`). A prompt put up for it keeps the wait open until
  it's closed unbought (MarketplaceService's `PromptProductPurchaseFinished`) or its grant
  lands, at most `OfferPrompt` (30 s) after the press, so a buyer is never cut off mid-purchase.
- **Alone, the pill stays Cut Free** (`CutFree.wipeOffer`): it frees you, the whole team, and
  showing a dearer button for the same thing would be a trick. The end waits on it the same.
- **The grant is a spare Free Everyone in the buyer's save**, spent freeing every caught player
  (each cut by the buyer; one spare however many it frees). Players still in the black after a
  catch are freed on the same purchase over the settle tries. Nobody caught (the results came
  first), it's kept, and the buyer's next wipe press spends it with no prompt.
- **Nobody is freed once the end has begun** (`ClimbEnd.Attribute` set): the black is coming
  down, and a spare spent under it would be a purchase lost. This holds for Cut Free and Free a
  Friend too, which before could be spent in that second and a half.
- **Who sees it:** every caught screen (wrapped, carried, left behind on the watch bar). Free
  players can't exist in a wipe, so Free a Friend's pills never show then.


## D-224 Wrap colours: six tints on the one film, owned for good and worn at once (S3-04a, Nov 15)
The moment: a friend lifts your door and finds you wrapped in your colour, the one they know is
you. GDD "Monetization": wrap colours at the counter, 99 to 499 Robux, "the colour or pattern of
the shrink-wrap you get wrapped in". Proven: Fortnite's and DOORS' cosmetics are bought once, kept,
and seen by friends; real pallet film comes in colours, so a coloured wrap still belongs in a
storage building.
- **A colour is a tint, not new art.** The film stays the one model (art/keptwrap) with its
  near-white clear colour map; the server sets its SurfaceAppearance's `Color` (script-writable,
  STUDIO.md) as it wraps you, so the colour reaches every screen with the part and nothing else is
  sent. Patterns need texture sets of their own and wait for S3-04c.
- **Six colours, plain names** (Blue, Red, Green, Pink, Orange, Black: names a player would say,
  the owner's Nov 15 rule), each its own product titled "<Colour> Wrap". Default prices, owner's to
  set on the Dashboard: Blue, Red, Green 99; Pink, Orange 149; Black 199 (`OWNER.md`).
- **Owned for good, never a spare.** Save version 4 adds `wraps` (owned, by offer name, stamped
  with when first bought) and `wornWrap` (empty for the plain film). A purchase owns it and puts it
  on at once; an owned colour is refused at the prompt (`notBuyable`), and one bought twice anyway
  (two prompts open) is still granted and counted, never refused, since the Robux are spent.
- **What you wear rides on the Player** (`WrapColour`, mirrored by `Wearing` from the save as it
  loads and as a colour is granted), so the wrap and later screens read it without the save. A
  worn name that's no longer a colour, or no longer owned, is the plain film.
- Tints were judged in Studio Play at phone size on stand-in films: all six read as coloured film
  with the body showing through; Black reads as smoky dark film, not a solid shape.

## D-225 The counter's shop: you in each colour, priced by Roblox, bought through the server (S3-04b, Nov 15)
The moment: you walk up to the counter, the shop slides up, and every card is you turning in that
colour's film; you buy one and the film snaps tight round you. Proven: Fortnite's item shop and
DOORS' shop (cards in a row, a price on each, owned ones marked Owned or Equipped).
- **The figure is you.** Each card's ViewportFrame holds a copy of your own character (scripts,
  tools and sounds stripped, anchored) with the film fitted round its box as the server fits it
  (`Kept.fit`) and tinted (`WrapColours.tint`). Seeing yourself in the colour sells it better
  than a stand-in body. Made as the shop opens, gone as it shuts; only then does anything step.
- **Seven cards: the plain film first.** Taking a colour off needs a way back, so the clear film
  is a card of its own, always yours (Wear or Worn).
- **The counter's prompt is made on each screen**, not by the server: it only opens a screen.
  The server never trusts the screen anyway: `BuyWrap` and `WearWrap` take a colour's name
  (checked: a string, short, a colour; Wear also empty), no faster than `Shop.AskEvery`.
- **The shelf answers at once; prices follow.** Roblox's prices (Brix's `viewShop`, which also
  records the look) take seconds in Studio, so `ShopShelf` answers owned and worn at once with
  the prices last fetched for that player and fetches fresh ones behind it; the screen asks once
  more 1.2 s later if a price is missing. A Buy with no price yet reads just "Buy".
- **"Roblox's own" Shop button** (ROADMAP S3-04) was never defined: taken as a Shop button in
  Roblox's own top-bar row, at its left end, shown only in the front office (`OWNER.md`).
- **In Studio, Buy runs the real grant**: with no product of its title on Roblox, the press
  hands Purchasing's `DevReceipt` a made-up receipt, so the save, the attribute and the card's
  flip all run as a purchase would.
- A wear change is saved 5 s after the last one, so trying colours on writes once.

## D-226 One table for every floor, and no top (S4-01a, Nov 15)

The GDD's "Floor rules": one table says, for any floor number, what the floor holds and how hard
it is, and the climb never tops out (D-128 took the top away; the stand-in top at floor 3, D-106,
was all that ended a run in an escape). The moment it serves: the car rises off floor 3 and floor 4
is just there, so a team keeps going for a best floor.

- **`FloorRules.at(number)` answers for any floor**, 1 to 100 and past (below 1 counts as 1). It
  holds what `Floor` and `Deal` read from fixed numbers before: the plan (short or full size),
  how many doors the floor keeps, the notes, the share of padlocks, whether a note is padlocked,
  the most monsters loose, the packed share, and whether the floor teaches (the lobby's hall
  quiet, a saw first in the bag, the faint mark always there). Every floor's rules are worked out
  once and frozen.
- **Steps, each named for what players meet**, so S4-01b's changes read as a list: "Learning the
  doors" (floor 1), "Full size" (3), "Three loose" (5), "A note behind a padlock" (6). A step sets
  only what it names; the rest carries on. Smooth growth (the packed share) is a curve with a most.
- **Today's numbers kept exactly**: no floor plays differently yet; that's S4-01b.
- **The curves that already grew with the floor stay with what they drive**: waking (`Waking`),
  pay (`Pay`), the Mannequin's breaker errands (`Breaker`), find grades (`Grades`) and each
  monster's lowest floor (`Deal.Keepers`, `Deal.Packrat`; S4-02 owns those). `floorrules.spec`
  checks them with the table from floor 1 to 300: in range and never easier higher up. `Waking`
  no longer needs `Deal` at all.
- **The door count moved from the plans to the rules**: `Floor.Plans` hold only each plan's
  shape; `Floor.planFor` puts the rules' count in, one plan table per floor number.
- **The top is gone**: `Climb.Top` and `Climb.Building` are removed; every floor lays the one above
  it. The escape (`Climbs.topped`, ClimbEnds' light and "Made it") keeps its code, but nothing
  fires it; a way out the owner may want later would (`OWNER.md`).
- **Floors past 99 work**: a unit's number is its floor and two digits ("10102"); its plate's
  text scales to fit. Floor 101 laid and dealt in Studio Play. `DevFloorNumber` is no longer
  capped at 10.

## D-227 The chattering teeth walk on feet, a footfall every snap (F-04c, Nov 15)

The catalog's wind-up chattering teeth (Common, "Wind: they chatter off across the floor") are
built as the walking kind: a moulded denture, red-pink gums and cream teeth, on two orange
cartoon feet with a white key on the side, at the bigger listings' size (about 2.5 in). The
feet are what let them "chatter off across the floor": plain teeth only hop in place. The jaw
snaps 7 times a second, from the sound of a video of a walking pair (clicks about 0.085 s apart,
the open and the snap), and the feet share its crank, so every snap lands a footfall; the body
only moves while a foot is planted, so the soles never slide. As found, the top jaw stands 9
degrees open in a grin (drawn that way, so the bake lights both rows of teeth), and that is how
the template stands in the place. A run's feet and body keys sit only where each curve turns,
eased Sine InOut, which draws the same strides as a sampled curve with a third of the keys.
Its parts and numbers are in `art/finds/windups/README.md`.

## D-228 The climb steps up eight times, then holds from floor 25 (S4-01b, Nov 15)

The moment: each floor up feels a notch tighter, and the team can name what changed. The floor
rules (D-226) gain six steps past floor 6, each named for what players meet and each from a hit
game, then nothing past floor 25: from there only the slow curves rise (pay, finds, how soon
sleepers wake, the packed share), as Dandy's World's floors hold once they're at their hardest.

- **"More doors" (floor 8):** 50 doors of the full plan's ~80 (40 before), padlocks 15%. More to
  search before the code is in, as Dandy's World asks for more machines higher up.
- **"Four loose" (10):** up to four monsters loose, as Dandy's World sends more Twisteds higher
  up and Left 4 Dead's director allows more specials as it ramps.
- **"Big floors" (12):** a third plan, `Big`: 7 columns by 4 rows of junctions, 15 halls, 3
  loops (room for 95 doors and more), keeping 60. As wide again as Full but no deeper, so floors
  still stand 790+ studs apart. Lethal Company's harder moons hold bigger buildings.
- **"Two notes behind padlocks" (15):** `padlockedNote` (a yes/no) became `lockedNotes` (a
  count, always fewer than the notes); padlocks 18%. Two ways through needed, as Piggy's way out
  wants more than one tool found.
- **"More doors still" (20):** 70 doors on the big plan, padlocks 20%.
- **"Five loose" (25):** the last step. `Waking.AwakeMost` (6) still leaves one more pounding.
- **The notes stay four, not fewer.** ROADMAP said "fewer notes", but with the notes among the
  doors at random a team opens `notes * (doors + 1) / (notes + 1)` doors on average to hold
  them all, so fewer notes alone is quicker (and the GDD's "Codes" says four above the teaching
  floors). `floorrules.spec` now checks that search never shrinks floor to floor, so a later step
  can cut notes only with doors to make up for it. The owner can overrule (`OWNER.md`).
- **The 99-door cap moved after the thinning** (`Floor.generate` 5c): the big plan's halls have
  room for more than a floor numbers, so the cap now cuts (and renumbers) only if a floor keeps
  more than 99, never before the thinning picks its doors. Floors 1 to 6 lay exactly as before
  (`deal.spec`'s fingerprint, now over floors 1 to 6).
- **Laying no longer has a long first frame:** publishing the tops and building the lobby each
  get their own frame when the slice runs over (`FloorBuilder.lay`). The worst frame laying a
  floor fell from 17 to 46 ms (floor 12 during a ride) to 5 to 7 ms on every floor.
- **Specs judge each floor by its own rules:** `floor.spec` bands by plan (short, full, big) and
  compares each floor's doors to its own rules' count; it lays floors 12 to 26 too. `climb.spec`
  climbs 30 seeds to floor 26 (60 to floor 10 before).

## D-229 A find's press is one stamp on its model, played out by every screen (F-G1b1, Nov 15)

A find with a press (`Finds/Use.luau`'s rows) keeps one stamp, set by the server: what the last
press started (On, Again, Off), the server clock when it began, and the seconds of light left.
Every screen works out from it where the find is in its own motions (`Use.frame`), so a lantern
dropped lit stays lit on the floor and a friend arriving late sees the tea light mid-flicker. A
press that would do nothing (still burning, running down, spent, the jack mid-tune) is refused
by `Use.press` on both sides: the button hides then, rather than taking a dead press.

- **Which finds press:** the ones the catalog says work anywhere: the tea light and oil lamp
  (Light; a minute and two and a half, then they go out for good), the glow sticks (Crack; lit
  for the rest of the floor), the fairy lights, lantern and hard hat (Switch; a switch keeps its
  battery when switched off, as Lethal Company's flashlight does; the lantern 90 s, the hat 60),
  the firefly jar (Open; a minute, then they're gone), the disco ball (Spin, until stopped) and
  the jack-in-the-box (Wind; its tune, then the bang every monster hears, as an air horn blast;
  popped, it's shut and wound again by the next press).
- **No press (defaults, `OWNER.md`):** the lamps the catalog says work "at home" (the desk lamp,
  night-light, moon, blob and glass lamps, neon sign) need a socket, so none in the building; the
  Secret lamp is found lit and never runs down; the hard hat is switched on in your hand until
  worn finds come (D-188).
- **Sounds:** the switches click as the torch does; the jack's crank is Pro Sound Effects' music
  box under its Wind, not yet measured; the rest are F-G1b2's.

Not chosen: timers on the server flipping each find's state (the stamp and the pure sums need
none); a find's whole state replicated every frame.

## D-230 The walking robot walks on flat feet that never slide (F-04c2, Nov 16)

The wind-up walking robot (`art/finds/windups/`, "Wind: it clanks off in a straight line for 15
seconds") is a printed tin walker of our own, 6.4 in to its head. Its walk is worked out, not
keyed by hand: one crank phase drives the legs (15 degrees from the hips), the arms (24 degrees,
opposite), the waddle and the twist; each step, the planted foot is pinned to the floor and the
body moves only by what that foot's backward swing gives (a footfall about every 0.28 s, timed
from a real walker's clanks, slowing over the run). The feet are their own parts on the legs: they
counter-turn to stay flat on the floor whatever the leg, lean and waddle do, and slide a little
along the leg to keep their soles down (the game has no up-down travel for the whole find). The
aerial is a damped spring driven by the body's sway and clanks, so its wobble follows what the
body did. It walks straight (the catalog's line), so a game ticket can aim it down a hall: it
covers about 3.4 studs.

## D-231 A pressed find plays out by its joints, on every screen (F-G1b2, Nov 16)

The press reaches the game. The server (`FindUses`) takes `Slots.used` for a find with a row in
`Finds/Use`, keeps `Use.Gap` between one player's presses, asks `Use.press` against the stamp on
the find's model, and writes the stamp as attributes (`UseState`, `UseLeft` with -1 for forever,
`UseKey`, then `UseAt` last) and tags the model `FindUsed`. The same model moves between hand and
floor, so a lantern dropped lit stays lit. The jack's bang is `task.delay(Use.noiseAt)`, heard by
`Keepers:hearHorn` where the find is then, unless it was pressed again since.

Every screen (`FindUseView`) works out each tagged find's frame from the stamp and the server
clock and stands it by its joints alone (`Finds.joints`): each part's place comes from where it
was drawn and the kit's sums, and each Motor6D's C0 holds it there, so no part is ever moved and
a find in a hand never drags its holder. The root stays put (no pressable find moves its root). A
find is posed again only when its frame moves, within 90 studs of the camera. Your own find in
hand plays on your view's copy too, which carries the light; your press shows at once with the
stamp it will get, kept until the server's lands within `Use.Predict` (its clock kept, so nothing
replays). A step's sound plays as the step starts; a find seen more than a second after its press
is silent until its next step. Only the `Use.LightsShown` (2) nearest glowing finds light the
room; the rest still glow. The press button hides while `Use.press` says nothing would happen
(no refusal text, the owner's rule), and springs back when a press would work again.

Sounds for now: the switches click as the torch does, the tea light and oil lamp strike a match
("match strike/ignite", Creator Store), the jack winds its music box and bangs with the
catalog's tin clang made lower and louder. The rest wait in ROADMAP polish.

## D-232 The wind-up mouse's run is worked out from one spring (F-04d, Nov 16)

The mouse's `Zip` comes from one sum in `windups/build.py` (`mouse_zip`), not hand keys: its
speed from the spring (a quick bite, then fading until it stalls dead), its heading from a
steady curl to the left, its shimmy and nose buzz from the distance run (the gears), its wheels
and key from the distance, its stop as three nose-down rocks drawn as parabolas, and its tail and
ears as springs flung about by the body. Keys sit only where each curve turns, eased to be exact
for the shape between (the walkers' way), so the game plays what was judged. The tail's cam is
tuned to a whole number of wags, so it always stops straight. Small pieces sunk into a part
(ears, eye domes) smear onto it in the bake, so they become their own part or sit deep.

## D-233 The monkey lures for its whole play; the toy car is set down and rolls where the server laid it (F-G1b3a, Nov 16)

The cymbal monkey is the catalog's "strongest lure", Call of Duty Zombies' Monkey Bomb: wound, it
plays 21 seconds and every monster on the floor hears it every 2 seconds (`lure`), as far as the
air horn (`Use.LureReach`), wherever it is then, until it stalls or is wound again; each clash
sounds as its arms meet (the arm's furthest keys). A toy (`toy`) is pressed again once its
motions end, with no reset. The toy car (`down`) leaves your hand on its press: stood on the
floor 1.6 studs ahead facing where you face, its Push walked every 0.1 s for walls, laid at
once where it ends (no fall, no clank: `Slots.lower`'s `still`), and stamped with where it set
off and where it stopped short; every screen moves its root along the travel while it lies loose
and rolls, so it ends exactly where the server has it (seen within 0.01 studs). Finds without
real lights no longer take one of the two light slots. The RC car's catalog line says it
drives at home, so, like D-229's home lamps, it has no press in the building yet (`OWNER.md`).

## D-234 A found light lying lit holds a Mannequin as far as its own lamp reaches (F-G1b3b, Nov 16)

The moment: chased down a hall, you drop your lit lantern behind you and the Mannequin freezes in
its pool, as it does under a hall light or in your torch beam (D-188: "found lights hold a
Mannequin"; SCP-173 and Five Nights at Freddy's, as L-06b3b's light rule). How it's decided:
- **Lit** is the stamp the screens already play (`Use.litUntil`): from the press for as long as its
  light lasts, for good if it never runs down (a glow stick), never when switched off or a toy.
  A find takes presses only in a hand, so the server reads a lying find's stamp once, as it lands
  (`Keepers`' `tellLying`, beside the Packrat's list), and drops it as its time runs out.
- **Reach** is the find's own lamp: its widest point light's range (a spot's only if it has none)
  times `Use.LightShare` 0.8, past which the glow on a body is too faint to read as lit. A camp
  lantern holds it 9.6 studs off, a tea light 7.2, a glow stick 5.6.
- **Shade** is the map's clear line (`KeeperMap.clear`, as torches use): walls and a shut door
  block it, an open doorway lets it through. A hall light still wins where both shine.
- **In a hand it holds nothing** (the ticket's default: D-188 says found lights, and the moment is
  dropping it). Whether a lit lantern you carry should hold one is the owner's (`OWNER.md`).
Seen in Studio Play: the lantern's drop woke a Mannequin 17 studs off, it came at the player and
froze 9.5 studs from the lantern, held 35 s after the player left, and walked on as it ran down.

## D-235 The tin bird's hop is worked out in millimetres; the kit's travel is studs (F-04d2, Nov 16)

The tin bird's `Hop` comes from one crank in `windups/build.py` (`bird_hop`), the mouse's way
(D-232): hop heights, steps and flight times in millimetres with gravity at 9,810 mm/s², so the
sums read like the toy. Its `x`, `y` and `z` keys are turned into studs as the tracks are
written: the first export wrote millimetres where the kit reads studs, so the bird leapt 13 studs
and walked off the filmstrip's stage. The filmstrip's stage light now rides along with a find
that travels (`follow`) and stands on the camera's side when a motion picks its own `view`, so a
travelling find stays lit in every frame.

## D-236 The siren car's roof light is its own lamp, sweeping red, with no words on the car (F-04e, Nov 16)

The toy siren car is a 1960s-style tin friction chief's car of our own (the V&A's tin fire
chief's and highway patrol cars, Duckwells' Ichiko patrol car), not any real force's: red and
cream, a door roundel with our "7", a printed driver in a peaked cap and a passenger in its
windows, as every tin car of the kind has, and no words or badges. Its roof light is the part
that answers the push: a red fluted dome turning about its own post (`SirenCar_Beacon`), geared
to the flywheel so it speeds up with the pushes and slows as the car coasts, carrying a red Spot
light that sweeps round the walls and floor and a weak Point light for low graphics. The lamp
catches with a flicker on the first push and dies 0.9 s after the car stops. The siren's wail is
the game's sound to play over `Push`, not part of the art. Its lacquer is smooth: a fine
roughness noise broke the top light's sheen into what looked like dust on the bonnet, so painted
tin finds keep their roughness variation broad and gentle.

## D-237 The rubber duck is one soft surface, its game mesh gathered where it bends (F-04e2, Nov 16)

A vinyl duck has no seams between head, body, tail and wings, so it is drawn as rounded volumes
melted together and sampled as one surface along rays from a point low in its breast, rather
than built from lathes and lofts joined at edges. The game mesh (40 rings of 64, 5,562
triangles with the bill) is evened out over that surface with each point pulled toward a
neighbour whose edge cuts inside the curve (`dk_settle`), so points gather at the tail's tip,
the wing's edge and the tuft. Evened out plainly, its flat faces cut 5 mm inside the tail's tip,
past the bake's 2 mm cage, and the bake left black holes there; gathered, they stay within
0.8 mm at the same triangle count. Any later find drawn the same way (the squishies, plush)
should check that gap before baking. The squeeze is one `stretch` track on the whole duck
keeping its volume, as the tea light's flame does; a dent that bends in one place waits for
bones (F-05a).

## D-238 The kazoo's pressings are in its look, and its red folds up over the seam (F-04f, Nov 16)
The kazoo's rings, maker's mark, the cap's ribbed grip band and the bead round its top are
painted heights in its look (`kazoo_look`), baked into the normal map, with tarnish painted into
each crease and polish on each crest, rather than modelled: they are a few tenths of a millimetre
on a tube 121 mm long, finer than the detailed mesh's rows, and the bake turns either into the
same normal map. The red bottom half is painted to fold 1.5 mm up over the seam's bead onto the
top's side, as a crimped tin kazoo's is: the shell is widest at the seam and the half below tucks
under it, so without the fold the red showed as a hairline from any view above.

## D-239 The toy drum's worn patch sits where its beads land, spread toward the middle (F-04f2, Nov 16)
The drum's sticks are found lying across the head, and in `Bang` each turns about the hand's
grip, so its bead comes down where it lay. The grey-brown patch worn into the calfskin, pocked
with small dents (`drum_look`), is centred there, but its halo is drawn 10 mm toward the head's
middle, as a kid's hits wander: centred under the bead, the beads hid it from every view. The
pressed grooves round each hoop's band, the head's veins and the dents are painted heights, not
modelled, as the kazoo's pressings are (D-238); each groove is 1 mm wide, two texels at the
drum's 511 texels a stud, since a finer one vanished from the normal map.

## D-240 The farm-animal spinner is a red barn, and flat faces keep rounds off them (Nov 16, F-04g)

Our talking farm toy is a barn of our own (red case with pressed boards, a slate gambrel roof,
white trim, a white bezel, a yellow side lever, a black weathervane arrow), so nothing reads as
the famous yellow round one. Its Pull motion stops the arrow at 1305 degrees, a multiple of 45,
so the game picks the animal by adding 45 x k to the spin. In the kit, a flat face that meets a
round (the case's front round its bezel, its walls their rounded edges) needs a sharp foot or a
ring just past the round: the hi mesh's smooth shading otherwise bends across long flat
triangles and the normal bake streaks them. (`art/finds/windups/README.md`, "Farm-animal spinner".)

## D-241 The pull-string cowboy doll is a ginger kid of our own, and cloth hangs as real strips (Nov 16, F-04h)

Our talking cowboy doll is a 1960s-style talker of our own: a ginger, freckled kid with
side-glancing blue eyes and an open grin, a cream felt hat, a blue check shirt, a fringed tan
suede vest, a green spotted bandana and jeans, so nothing reads as a famous film's cowboy (no
yellow plaid, no cow-print vest, no brown hat, no red bandana, no long face). A vinyl head is one
smooth loft whose lower half is a rounder square than a circle, with the cheeks and the muzzle as
soft bumps in it: separate ellipsoids for cheeks and chin bulged like mumps. Fringe is built as
real separate strips hanging from a sewn band, never a grooved shell, which read as a knitted
waistband from behind. The game starts one of the six lines at the doll's `DL_LET_GO` (0.62 s);
the recorded audio waits on `OWNER.md`. (`art/finds/windups/README.md`, "Pull-string cowboy doll".)

## D-242 The singing fish plaque is a catfish of our own on honey oak (Nov 16, F-04i)

Our singing fish is a slate-blue speckled channel catfish with drooping barbels and amber eyes on
an arched, routed honey-oak board, with a plain brass plate engraved with a fish over waves (no
words), a red button and a drilled grille, so nothing reads as the famous bass on its dark plaque
with gold lettering. Its lips are the head's own grey: pale lips round an open mouth read as a
shark's teeth. The head swings out about a vertical hinge near the tail, and every move out is a
motor's push and every move back a spring's snap, as the real toys are built. The game starts the
song at 1.55 s; the recording waits on `OWNER.md`. Meshes handed to the kit's `merge` or lathe
must be in studs: they unwrap from the numbers they're given, before their matrix.
(`art/finds/windups/README.md`, "Singing fish plaque".)

## D-243 A friend carried up is moved into their unit at once, and the trip server leaves them alone (Nov 16, S3-05a)

The owner's three-player test (Nov 15): two friends left behind both woke wrapped on one spot in
front of floor 2's elevator, cameras inside each other, and the third player's Cut free said
"Get closer" for ever. Why: on a group's own server (a lobby car's trip, so never in a plain
Studio Play) Trips takes any new character still on the front office's spawn a frame after it
appears for a respawn, and stands it in front of the climb's car (`standLate`, one spot for
everyone). The carry gives each friend left behind a new character (`Watching:bring`), and
`KeptPlayers:store` wrapped them and held them on the spawn for up to 4 s while their unit
streamed in, then moved them in; Trips' move landed after it. Both were stood on the one spot,
still wrapped and marked kept, with Cut free judged at units far away.

Now: `store` moves the body into its unit in the same frame the character is given (anchored,
it can't fall while the unit streams in; the screen is black until the kept mark), and again
after the stream. Trips stands a new character only by `Trip.standsLate`: still on the spawn,
and neither being carried up (`Climbs:carrying`) nor kept, asked a frame on and again right
before the move. With no unit free, the carry's fallback stands each friend unwrapped on a spot
of their own in front of the car (`ClimbEnd.spot`, the end's Again row), never two on one. The
unit pick itself was sound: each pick marks its unit before the next (now spec'd for friends
stored together). The rule for anything that gives a player a new character during a climb:
move it off the spawn in the same frame (docs/STUDIO.md).

## D-244 Nobody is ever stored in a unit someone is standing in (Nov 16, S3-05b)

The owner's three-player test (Nov 15): a friend was caught and turned up wrapped in the shut
unit the owner was standing in. The pick (`Kept.choose`) knew a unit's door, its keepers and
whether it already held someone caught, but not whether a free player stood inside it, so a
friend who'd pulled a door down on themself counted as an empty unit.

Now each unit as the pick sees it (`Kept.Unit`) has `someone`: any player's root inside it, free
or caught, tested in the door's frame the way a keeper's feet are (`KeptPlayers`' `someoneIn`:
across the opening's width, from the door to the back wall, from the floor to the ceiling). The
body being stored is left out (it's the one being moved). In Studio the stand-in friends
(`Left.StandInTag`) count too, so one player can test it. The carry (`store`, D-243) uses the
same pick, so a friend carried up never lands with someone on the new floor either. With every
shut unit taken, the old fallbacks hold: a catch lets you go after the wrap, a carry stands you
on a spot of your own by the car. A door that's up was already skipped (`shut`).

## D-245 The tin carousel is ours: printed tin horses on a red drum, slowing as it runs down (Nov 16, F-04j)

Our wind-up carousel is a red printed drum with a butterfly key, a turning platform, a mirrored
column and a crimson-and-cream canopy with a navy scalloped valance, and four pressed-tin horses
(black, dapple grey, white, palomino) on twisted brass poles, with no maker's mark. The top turns
once every four seconds (a toy runs faster than a full-size ride's 4 rpm), each horse rises and
falls twice a turn out of step with the next (as a full-size ride's cranks do), and it all slows
over the last six seconds as the spring runs down, rocking back on the gears' slack as it stops.
The game plays its tune at the top's speed, so the tune slows with it; by default a public-domain
waltz on a music-box comb. The horses are drawn as a side-view distance field, traced and puffed
into two halves round a crimped seam, the way tin horses are pressed.
(`art/finds/windups/README.md`, "Wind-up tin carousel".)

## D-246 · 2026-11-16 · The finds kit bends in places with bones
A find that bends in one place (a squishy's dent, later a plush's ear) is a part with bones:
`kit.Bone(name, at, reach | weight, axis, hinge)`, the game mesh skinned to them in Blender, the
FBX carrying the armature, the generated Luau a `Bones` list (`Art.Bone`), each track's `Part`
naming a part or a bone, and the game writing each bone's `Transform` from its `move` and `turn`
(`Finds.pose`, `Finds.joints`). Checked first in Studio: the skinned mesh and its bones survive
our Open Cloud upload, and a Transform written from a script bends it in Edit (docs/STUDIO.md
"Bones"). A bone that only slides doesn't change how the mesh catches the light, so a dent is one
bone sinking its floor and six round it sinking half as far and tipping their slope toward the
middle; their shares are worked out to make one smooth bowl (`art/finds/squishies/build.py`,
`bu_bones`). Proven on the squishy butter stick: a thumb's dent pressed in over a third of a
second, held, then creeping back flat over about seven seconds, the slow-rise foam's way.
Not chosen: a pressed piece that sinks and rises (it would show its seam on a soft block, and
plush needs bones anyway); a whole-body squash (`stretch`), which the stress ball and mochi will
use, but which can't make a dent.

## D-247 · 2026-11-16 · The stress ball is ours, and its eyes ride the squash as their own parts
- **What:** the stress ball with a face (F-05b) is a lime-green vinyl eye-popper ball of our
  own: two white bubble eyes in soft rubber lips, black pupils crossed a little, a thin printed
  grin with a dimple at each end; no famous character's face, colour or ears. Each eye is its
  own part on the ball (`EyeL`, `EyeR`), pivoting on its middle, its axis straight out of its
  socket: a squeeze squashes the whole ball (`stretch`), and each eye goes out along its axis
  and swells (`move`, `scale`) while stretching against the ball's squash so it stays round.
- **Why:** the catalog's action is "its eyes bulge out"; the real toys push their eyes out of
  the face on air. A child part rides its parent's squash in the kit's pose (Blender and
  `Pose.solve` alike), so a part that must keep its own shape on a squashed body counters it
  with its own stretch (here 1/s to the 0.9). The eyes are baked `alone`, so the dark inside of
  the ball never shades the white that comes out of it.

## D-248 · 2026-11-16 · What's inside a clear find shows its far side on a wall drawn facing in
- **What:** the finds kit has an `inside` part (`kit.Part(..., inside=True)`, `Inside` in the
  set's Luau): a wall its builder draws facing in (the glitter goo ball's gel, a hair inside its
  clear skin). Roblox draws only a face's front, so its near side vanishes and its far side's
  inside shows behind everything in front of it; it casts no shadow and is baked apart from the
  other parts; `Kit.import` makes it one-sided with no shadow, and the previews cull its back
  faces as Roblox does. The glitter itself is half metal at most.
- **Why:** a clear ball of tinted gel needs a body of colour behind its glitter. A solid core
  hid every flake behind it and left a see-through ring round it (a ball in a ball); a second
  clear layer sorts badly against the skin in Roblox (the same middle). A wall facing in gives
  the gel's colour, the light pooling in its bottom, and full depth to every flake, for one
  sphere's triangles. Full-metal flakes reflect the dark unit and read grey; half metal with a
  bright colour stays bright from every side and still flashes where one faces the light. The
  galaxy goo ball's nebula is the next to use it.

## D-249 · 2026-11-16 · A find can be found glowing: its glow tracks' first key says how much
- **What:** the galaxy goo ball's glow tracks (its `Gel`, the kit's glow part, and its three
  star bands) start at 0.8, so its rest pose is glowing faintly: the emissive mask at 0.8 of its
  `Glow.Strength` and its light at 0.8 of its brightness. A squeeze raises them to 1 and they
  fade back. Nothing new in the kit: a part's rest value is already its first key in its first
  motion (CRAFT.md, motion data).
- **Why:** the catalog's galaxy ball is a ball of glowing stars; found dark, it would be a
  speck from a doorway, and its glow is the Legendary's tell. A find switched on and off (the
  lamps) still starts at 0.
- **So:** whatever lays a find in a unit (a game ticket) must set each glowing part's
  `EmissiveStrength` and enable its lights from their rest keys, not leave them at the
  template's 0 and disabled.

## D-250 · 2026-11-16 · The lamps switch on anywhere; the RC car is driven, a recon car the collector steals (F-G1b3c)

The owner answered D-229's and D-233's defaults: the lamps the catalog kept for home work in the
building too, and the RC car "serves an actual purpose": you drive it yourself through the halls
and into any open unit, seeing from a camera on its hood, so a player can hide in a unit and use
it to watch for monsters or look for finds. The collector (the Packrat) can and will steal it.
At home you drive it too.

- **Precedent:** Rainbow Six Siege's drones (a small car driven from its own camera while your
  body stands defenceless); the Packrat taking a loose find is ours already (S2-06b).
- **The lamps (built, F-G1b3c1):** each a switch (`Use.Rows`, `lamp`), lit `Use.LampLasts` (60 s,
  D-188's minute for a light, so the 90 s lantern is still the long one), keeping what's left
  when switched off. None has a motion for running down, so a spent lamp fades by its
  switch-off, silent; a flicker of its own is ROADMAP polish. The moon lamp's phase tap and the
  theatre spotlight stay at home.
- **The car's defaults** (proposed Nov 16; the owner replied "go ahead"): no range limit and no
  battery, as Siege's drones have neither; players hear its motor, monsters don't (a car they
  heard would be a weaker cymbal monkey); no headlight, since light stops the Mannequin and a
  headlight would stop it from anywhere; only the collector cares about it; taken, it goes on
  the pile, there to take back as any find is; a friend picking it up ends your drive; left on
  the floor when the elevator goes, it's lost with the floor.

Not chosen: the lamps never running down (a common desk lamp would beat the lantern); a
signal range that fades the hood camera to static (Siege has none, and a hidden player should
be able to scout the whole floor).

## D-251 · 2026-11-16 · Your finds are your gear: a home unit with a shelf and a chest, and anything you take up can be lost

The owner, talking through the miner's hard hat as a second light that you wear: worn finds go on
the character, a home unit holds everything you find, and your finds become what you prepare a
climb with. You can take any find up, not only worn ones, at your own risk. The owner answered my
first defaults the same day; this is the result.

- **Precedents:** Minecraft (what you carry drops where you die, and you go back for it before
  something else takes it) and Lethal Company (gear left where a crewmate died stays on the moon
  unless someone carries it back) for taking gear up at risk; Grow a Garden's plots (each player's
  own place on a shared server, open to friends) for the home unit, which the design doc already
  planned as the hall of units (PROPOSAL idea 29); Animal Crossing's house storage (everything
  kept in storage, only what you set out on show) for the shelf and the chest; Pet Simulator's
  golden machine for making a Gold; Bloxburg's larger plot sold for Robux for bigger units;
  Phasmophobia's head torch for the hard hat; Roblox's classic Speed Coil for the skates.
- **The hard hat goes on your head, and it's used up.** Wear lifts it on, lit, and frees its
  slot. Its headlamp beam is tighter and whiter than the flashlight's and goes where you look. It
  holds a Mannequin as any found light does. It lasts a minute. No battery refills it: when its
  light runs out it falls off your head and breaks, as the saw and bolt cutters do (D-141: its
  bits fly, it clanks, monsters hear it as a dropped tool, it fades). There are more to find.
  There's no switch: putting it on lights it, so you save its light by waiting.
- **Worn finds** have a head and feet of their own, apart from the three slots. Slippers are
  looks only for now. Skates make you faster (default: faster than your walk, still slower than
  a chasing monster, tuned in play). Monsters hearing footsteps is held off, which closes
  OWNER.md's question about worn finds and footsteps.
- **Home is your own unit** in a hall of units off the lobby, one per player on the server,
  which friends can walk into. It holds a display shelf and one chest. Every find you carry onto
  the elevator comes home, commons too: this replaces D-188's commons selling on the spot. Finds walk onto
  your shelf, or into the chest when it's full. Pressing the chest opens a panel of everything
  you own: each kind of find once, with how many you have ("x2"), a search bar and rarity
  filters. From it you put finds on the shelf (swapping one off when the shelf is full), take
  finds out to carry, and sell whatever you want. With four of one kind, the panel offers to
  make it Gold: a big animation, and the four become one Gold. Trading comes later.
- **Take anything up.** Any find can go up, a lamp or a glow stick too (lit and dropped, it pins
  a Mannequin). Each takes a slot, so what you bring is a choice. On the climb a brought find is
  at risk like any other: the Packrat can steal it (take it back from its pile before the
  elevator leaves); caught, everything you carry drops where you were caught (already true,
  `Slots:dropAll`), worn finds too. You keep what you carry onto the elevator and nothing else.
  Whoever carries a find aboard takes it home, wherever it came from: if you lose yours and
  someone else carries it onto the elevator, it's theirs. Leaving mid-climb drops what you carry.
- **Bigger units** give more shelf space; medium and large are both bought with Robux (the design
  doc had them for cash). The chest holds everything for everyone.
- **The results screen** still shows each find and what it's worth; the cash comes when you sell
  at your chest (S5-01).
- **The save:** a find taken out stays in the save, marked out, until its climb ends; it's struck
  off only when it was lost on a climb that ended properly. A server that shuts down or crashes
  mid-climb never costs a find.
- **Open** (`OWNER.md`): whether the other lights that run down are used up as the hard hat is.

Not chosen: finds brought from home being safe from loss; a lost find going back to the player
who lost it when someone else carries it aboard; a battery refilling the hard hat; commons sold
on the spot; a separate gear screen before a climb (the chest does that job); monsters hearing
feet, for now.

## D-252 · 2026-11-16 · Driving is built in Brix; the RC car is a body its driver's device moves (F-G1b3c2)

The owner, starting F-G1b3c2: "make sure it's absolute world-class. Write the code in Brix if you
have to, so that the Brix library will be in even better shape to iterate quickly on new games and
ideas within this game."

- **Brix work from here (the rule, now in AGENTS.md and `docs/FRAMEWORK.md`):** a system a ticket
  needs that Brix lacks is built in `../engine` as one Brix ticket, by Brix's own rules (nothing
  about this game, its check, its docs, its commit with no trailer), then the pin moves once Brix
  is pushed. It replaces "never edit Brix from here, only file a ticket".
- **How the car moves:** a physics body its driver's device owns (network ownership), as Roblox's
  own vehicles are. It moves at once on the driver's phone, walls and shut doors stop it as they
  stop a character, and friends see it move through Roblox's own smoothed replication. The server
  checks every move (no faster than the car's top, no wall passed through) and takes it back from
  a bad one. Not chosen: the server stepping the car from sent input, which puts a phone's round
  trip between the stick and the hood camera (Siege's drones answer at once).
- **Split:** Brix's Handling (ENG-24a, done: how a body answers its stick, held back by walls),
  Brix's driving adapters (ENG-24b), then here: drive it (c), the driver's body (d).
- **The handling's defaults** (Brix's stock car; numbers tuned in c): it can't turn standing still,
  as a car can't; the game mixes a little throttle into a sideways push of the stick, so a phone
  player pushing left from rest still turns. Its wheels ease into a turn over a fifth of a second.

## D-253 · 2026-11-16 · The Nov 16 wind-ups and squishies are dealt as the Nov 15 finds are (F-G1d)

The 12 wind-ups and 10 squishies built overnight Nov 15-16 join the floors' deal the way D-203
set it: each with the item catalog's grade and worth as written, dealt from floor 1, a unit
rolling a grade by its floor and then one find of that grade. On floor 1 that's now 13 Commons,
3 Epics (the firefly jar, the tin bird, the tin carousel) and 2 Legendaries (the glass lamp, the
galaxy goo ball): a teddy is about 1 find in 21 there, an Epic 1 in 120, a glass lamp 1 in 400.

- **Sounds borrowed** until each has its own (ROADMAP polish "Finds' own sounds"): the wind-ups
  take the tin, clack and plastic stretches pitched by size; the squishies and the cowboy doll
  the teddy's cloth grab (`SOFT` in `Tools/Catalog.luau`), the paper squishy the plastic rustle.
- **Held by size:** palm-sized (Small) but for the drum, the cowboy doll, the carousel and the
  jumbo strawberry (Medium) and the farm spinner and the fish plaque (Large).
- **Not yet:** pressing them (F-G1e). The four squishies not built are dealt as they're built.
- The check that a teddy turns up far more often than the glass lamp asks for 12 times now,
  not 20: it's about 19 with the new commons and the second Legendary.

Not chosen: holding the galaxy goo ball back to deeper floors (D-203 deals every grade from floor
1 at the catalog's odds; only the Secret waits for floor 25).

## D-254 · 2026-11-16 · The RC car comes off its transmitter onto the floor, and you get back with jump (F-G1b3c2c)

- **The car is the find's own parts:** Drive moves the drive's body and all that rides on it out
  of the find into a model of its own on the floor, on an invisible box with no friction (the
  meshes ride it without colliding), its body's joint hung from the box. The transmitter stays
  in your hand as the find, so slots, drops and the Packrat still see one find. Taken back, the
  parts go home and the joint hangs from the transmitter as before. Not chosen: a copy of the car,
  which would make the find two things to keep in step.
- **Back is the jump button** (Roblox's own vehicle seats are left with jump), with a Back button
  top left for anyone who doesn't know it, and B or Backspace.
- **Take it back by walking to it with the transmitter in your hand** (within 3 studs); Drive
  again drives on from wherever it stopped. Idle, the car is anchored so nobody kicks it about.
- **While you drive, your streaming follows the car** (`Player.ReplicationFocus`), so the halls it
  drives down stream in; your own body stays.
- **The stick is read from `Humanoid.MoveDirection`** turned back by the hood's facing, as the cart
  ride reads it: this place's PlayerModule hands out no move vector, so Brix's default read gives
  nothing here.
- **Numbers (defaults to tune with the owner):** 18 studs a second flat out in half a second, 7
  backing; the server allows 1.25 times that; the hood at 0.52 studs, 88 degrees wide.

## D-255 · 2026-11-16 · The RC car's view goes infrared when the lights near it are out (F-G1b3c2e)

The owner, asked about a headlight for dark halls: "What about infrared if it's dark?", then
"if players trip the lights on I don't think the view should stay infrared. It should be normal
when there are lights but go infrared if the lights go out."
- **The hood view follows the lights near the car:** normal colour where they're on, infrared
  (green-cast black and white with grain, Outlast's camcorder and Phasmophobia's video cameras)
  where they're out, switching with a relay click and a flicker.
- **The infrared lamp is seen only on the driver's screen** and isn't a light in the game's rules:
  it holds no Mannequin. Monsters' eyes shine white in it.
- **Not chosen:** a headlight on the car, which friends and monsters would see, and which would
  be a light that holds the Mannequin.
- Open, default in: the car doesn't trip motion lights (`OWNER.md`).


## D-256 · 2026-11-16 · The RC car's driver crouches over the transmitter, and the car can be driven home (F-G1b3c2d)

- **The driver crouches on every screen, theirs included:** on their heels, hunched, the
  transmitter held up at the chest in both hands (left round its pistol grip, right on its wheel),
  its aerial past the bowed head, the torch in the right hand pointed at the floor ahead (Rainbow
  Six Siege's drone pilots squat over their controllers). The server tags the character
  `Drive.BodyTag`; each screen poses the joints (`Drive.Crouch`, DriverBodies), eased over 0.45 s
  with the peek's cloth rustle. Your own body is shown only while your view is on the car, so the
  hood sees you crouched when you drive back, and it's hidden again the moment your view comes
  home. A friend's torch arm isn't raised to their aim while they drive.
- **The aerial is already up:** the transmitter's telescopic aerial is modelled extended and isn't
  a part of its own, so there's nothing to raise. A telescoping raise as you press Drive would need
  the aerial split out in the art (ROADMAP polish).
- **With its car out, the transmitter is held by its handle:** the find is held by the car's roof,
  so with the car gone the hand held air a stud from the transmitter. While the car is out the
  find's grip (its body's `PivotOffset`, and the hand's weld) moves to the handle at the same
  height, so a transmitter dropped alone still lands on its foot; taken back, the old grip returns.
- **Caught, the drive ends at once:** the server ends it on the caught mark (`Kept.Attribute`),
  before the drop that would end it anyway, and your screen leaves the hood before the catch's
  lunge reads your view (CaughtView calls DriveView's `leave`), so the lunge turns you from your
  own eyes to what caught your body.
- **Driving it to your feet takes it back,** once it has been 4.5 studs away this drive
  (`Drive.home`); it's set down closer than that, so it doesn't snap straight back as you start.
- Not chosen: a kneel on one knee (asymmetric, more numbers, no clearer); the peek's kneel itself
  (chest to the floor, wrong for holding something up).

## D-257 · 2026-11-16 · How the RC car's screen tells light from dark, and what infrared looks like (F-G1b3c2e)

Built from D-255. The choices that weren't the owner's:
- **The driver's screen judges the light at the car, ten times a second, from what every screen
  already knows:** a hall light's state (lit only; dark, a breaker's cut and the alarm's Out are
  all no light) and its pool (`MotionLight.PoolReach`, the same pool that holds a Mannequin), a
  unit whose door is up (its bulb is wired to its door), and the freight elevator's lamp. Nothing
  new is sent. Once in colour it holds 2 studs past a pool's edge, so a car parked there doesn't
  click back and forth.
- **Only inside the building's halls is dark dark:** more than 48 studs from every hall light (the
  lobby, lit by its own lamps) the view stays in colour.
- **Not counted as light:** a friend's torch on the car and a lit find on the floor. Night vision
  doesn't switch off for a torch, and a lamp's pool is small; both are in ROADMAP to revisit.
- **The look reuses what's built:** the security feed's grain (`Feed.Grain`), lighter; the hall
  light's relay click, smaller and higher, flat in your ears; a ColorCorrection made on the
  driver's screen alone. The lamp is one SpotLight on that screen only.
- **The eyes are two billboards per monster on attachments of the screen's own**, moved to its
  head each frame (nothing added to its body), glowing past white so they burn through the green
  cast, shown facing the car within 40 studs and hidden by walls as the monster is.
- **Your torch is put away while your view is on the car,** its light out, lit again as it was
  when you're back; while away it lights no faint mark. In the game's rules it's still on in your
  hand (the server tests it from your head along where you look), unchanged here.

## D-258 · 2026-11-16 · The Packrat steals the RC car, and a car left out stays with its floor (F-G1b3c3)

- **To monsters the find is where its car is.** Slots learns that a find can have a piece out on
  a floor (`Slots.out`, the RC car's `Drives` answers for it): `finds` lists it at the car's
  floor point, whatever holds the transmitter (a hand, a pocket, the floor), and never at the
  transmitter's own spot, so each find has one place. Drives tells Slots again each time the car
  has moved 1.5 studs (`Drive.ToldMoved`), and the Packrat's brain already follows a find that
  moves, letting go of its reach when it's driven out from under its hand.
- **Its hands closing on the car take the whole RC car.** `Slots.lift` frees the find from
  wherever it is (out of its holder's slots, their screen told as a snatch: the transmitter torn
  away in the hand, its picture off the wheel), then the car gathers it: the transmitter is
  brought to the car, not the car to it, so the whole find lies where the car was, and every
  screen eases it from there into the hands. The car must still be within 7 studs of its chest
  (it reaches about 4 ahead). On its pile it's an ordinary find, taken back with "Take".
- **The driver's screen: lift, shake, static, home.** Drives tells the driver first
  (`Drive.TakenRemote`); DriveView keeps the camera where the hood was, raises it 2.8 studs over
  half a second, tipped up 24 degrees and rolled 16, with a 0.8 shake as the hands close, then the
  security feed's snow over the whole screen with its hiss for 0.35 s, and your own eyes as the
  snow clears (`Drive.lifted`). A word arriving just after the drive ended (it and the car going
  can cross) still plays from the last hood view, within half a second. Your view's hand, your
  torch and your body stay as while driving until you're home.
- **Robbed from your hands, the car comes home first.** The Packrat's pick from a driver is
  still the RC car: `snatch` brings the car home into the transmitter (it vanishes from the
  floor) and the whole find is torn away, so a driver it reaches is robbed, not caught.
- **The car belongs to its floor.** It's set down into the model of the floor it's on
  (`Floor.modelName`, FloorBuilder's `Floor<n>`), the dev hall's off-floor spots keeping
  `Workspace.Driven`. At the gate an RC car whose car is still out isn't kept: it rides up in
  your hand, and as the floor below is cleared (the ride's hand-off) its transmitter dies in
  your hand with the feed's set-off crackle and the break answer (`Slots.lose`, `Drive.Lost`).
  Default, open to the owner: the transmitter goes with its car; keeping it as a dud or keeping
  the whole car are the alternatives (OWNER.md). Drive it to your feet or walk to it before the
  gate shuts to keep it.
- **Fixed on the way: pocketing or switching off the transmitter destroyed the car out.** Slots
  takes a find out of the world (`Parent` nil) when it's pocketed, and Drives took any `Parent`
  nil as the find going. It now watches the find's `Destroying`, and the car's own `Destroying`
  (which fires for a destroyed ancestor) for its floor going.

## D-259 · 2026-11-16 · Your home: a unit of your own on a re-laid ground floor (the owner's plan, S5-03)

The owner asked for a world-class home where players keep, set out and show off their finds, with
a real mirror for what they wear, and approved the plan on Nov 16. The plan is its own Claude Doc,
"Your unit: the home in the lobby" (https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, read with
the docs tools): 31 numbered ideas, each naming its precedent. Its section "What you decided
(Nov 16)" and its last table hold the answers. It extends D-251, which stands where this doesn't
change it. The design doc's "The lobby" and "Your unit" sections link it.

- **The front office is re-laid as the building's ground floor** (owner: "re-lay so everyone
  sees everyone's stuff"). Six units down each side wall, doors facing the open middle; the six
  cars, the front door, the counter and the cart rack stay. Precedent: Grow a Garden and Steal a
  Brainrot lay every player's plot round the same open ground. Not chosen: keeping the front office
  and opening its right-hand wall onto a hall of units (my first pick: less rebuilding and lighter
  on phones, but the units are out of sight from the main room).
- **12 players on a public lobby server, 12 units**, one handed to each player as they join
  (Grow a Garden's plots); spare units padlocked. The place's max players is the owner's to set.
- **You load in facing the cars**, as today. Adopt Me's load-in-at-home is not taken.
- **Doors start open.** Pulled down, a door keeps everyone out, friends too.
- **Arrange** (ideas 11 to 15): any find placed anywhere in your unit, a half-stud grid and
  quarter turns, a Free switch for everyone and never sold, floor, tabletop, wall and ceiling
  spots, a per-size limit for phones. Precedent: Bloxburg's build mode, Lethal Company's ship
  furniture, Animal Crossing's furniture.
- **The mirror** (ideas 21, 22): a ViewportFrame on the glass holding a back-to-front copy of the
  unit and left/right-swapped posed copies of each player in front of it, its camera at your eye
  reflected through the glass; one live mirror at a time. `ViewportFrame.IsMirrored` exists but is
  locked to CoreGui (DevForum, read Nov 16); if Roblox opens it, the mirror moves to it. Built
  first as a test the owner judges. Precedent: Animal Crossing's mirrors.
- **The clothes rail** (idea 23): press to wear (Lethal Company's suit rack). **At home nothing
  worn or switched on runs down** (owner: yes), so the hard hat's minute starts only on a climb.
- **Four sizes**: small to start, medium for cash, large and XL for Robux (owner; D-251 had
  medium and large for Robux). XL is 20 by 30 studs (my default). Every slot is built at XL and a
  smaller unit stands inside behind partitions that move when it grows (Animal Crossing's house
  growing; Bloxburg's bigger plot for Robux).
- **Order** (owner: "sure"): the ground floor (S5-03a), the hard hat on your head (F-G1b4a), the
  mirror test (S5-03b), then the rest of S5-03 in the doc's build order, all ahead of S4-02, by a
  chain of sessions capped at 300k context (owner, Nov 16).
- **Later, each its own ticket**: finds doing things at home (16), living finds (17), the home
  score, visits to friends on other servers, photos (27 to 29; 29 has no precedent and waits).

Starting guesses (`OWNER.md`): shelf spots 6, 10, 16, 24 and placed things 25, 50, 100, 150 for
small to XL; 4 lamps cast real light in a unit, the rest glow.

## D-260 · 2026-11-16 · The ground floor's numbers: 156 deep, a unit's front standing in each gap (S5-03a1a)

The home's ground floor (D-259) is laid out in `art/lobby/spec.py`. Six XL slots (20 by 30) down
each side wall, the nearest the cars 12 studs off the bay wall, so the room runs 156 deep and the
spawn, just inside the door, is 150 studs from the cars: about 9.4 s at a run, well inside the
GDD's 15. Everything at the front (counter, shelves, rack, door, spawn) is now measured off the
front wall (`FRONT`), so it moves with the depth. Units 1 to 6 run down the left wall from the
front, 7 to 12 down the right.

- **Each slot's front is the climb's M unit with its walls dropped**, standing in a 12-wide gap
  the side wall leaves, as units stand in the corridor's walls: its facade, frame and roll-up
  door come with it, so the door rolls, slams and locks exactly as on a climb (RollUpDoor). The
  lobby builds the rest: the partitions, back walls, closed tops, floor and the inside of the
  front wall either side of the gap. Not chosen: a door built into the lobby's mesh (it wouldn't
  roll) or a new XL unit model (12 more full units' triangles for walls the lobby shares).
- **The 8-wide M door**, not the L's 12: it's in the game and checked, and the L's paint
  stretches 1.46 times. A wider door shows more of a unit from the floor (`OWNER.md`).
- **Split S5-03a1** into the numbers (a1a, this) and the build and sheets (a1b), because the
  session ran out of room. `Lobby/Specs.luau` stays the front office's until a1b exports and
  imports the new mesh together, so today's lobby keeps working.

## D-261 · 2026-11-16 · The ground floor built: the units' shells from the unit kit, the import left to a2a (S5-03a1b)

`art/lobby/build.py` now builds D-260's ground floor. The side walls break for a 12-wide gap per
unit, with a full post on each partition's line and a half post on the lobby side of each gap's
edge, which the M unit's own half pilaster makes whole. The units' partitions, back walls and
closed tops are the unit kit's own parts (`art/unit/parts.py`) built at XL and placed in each
slot's frame (`unit_shells`, `slot_frame`): one partition per slot line, shared by the units
either side, as the climb's units share theirs.

- **The cap stops at the gaps**, not the whole wall as the ticket said: the M unit's frame
  carries its own cap at exactly the corridor's height and depth, so a lobby cap over the gap
  would sit in the same place and flicker. The R-panel above still runs the whole wall.
- **The joists are their own parts** (`JoistsLeft`, `JoistsRight`) and `Ceiling` is only the deck:
  over 156 deep one part of joists would pass Roblox's 20,000 triangles. Every part is under the
  cap; the whole room is 87,446 triangles before the twelve M fronts, which a2b weighs on a phone.
- **The sheets stand the climb's M unit in every gap** (its build loaded as a library, the
  elevator's trick) wearing the M's bake, ten open with a lit bulb and stand-in boxes, two shut
  and locked, each owner's name on its card. They show the floor before the spawn is black: the
  middle's lights start 38 studs in, which a2b fixes with the rest of the lighting.
- **Not imported** (the ticket's fallback): the FBX is built but `Lobby/Specs.luau` stays the
  front office's. Imported alone, the new mesh would leave twelve open holes in the game's side
  walls until the M fronts stand in them, so a2a exports, imports and lays the fronts together.
- **Split S5-03a2** into the import with the unit fronts (a2a) and the lights for 156 deep (a2b).

## D-262 · 2026-11-16 · The ground floor in the game: the climb's M fronts in the gaps, lit as homes (S5-03a2a)

The 156-deep ground floor (D-260, D-261) is in the game: its FBX and `Lobby/Specs.luau` exported,
uploaded and imported together, the template in the place replaced and saved. `Lobby.front`
stands a copy of the climb's M unit (`ReplicatedStorage.Units.M`) in each of the twelve gaps,
pivoted so its doorway's outer face sits on the slot's `Door` looking `Out`, as
`FloorBuilder.unit` stands a climb's unit at a door face.

- **The front is built in `Lobby`, not by `FloorBuilder.unit`**: that one is a server module
  that lifts the unit's floor and hangs a climb bulb under the unit's top, and the lobby drops
  both (`Lobby.Dropped`: both side walls, the back wall, the floor and the top, which the
  lobby's mesh stands). Each front is tagged as every unit is, so the Doors system gives it the
  climb's buttons and its door rolls, slams, peeks and locks the same. No floor deals it, so
  it's empty; anyone may open any one until a3 makes each a player's. Its plate shows its slot
  number.
- **Oxblood doors**, the climb's, on facades in the lobby's teal: warm against the walls either
  side, so twelve doors read as doors from the spawn, not more wall (`OWNER.md`).
- **The light, pulled forward from a2b** at the conductor's ask, after Studio showed it: from
  the spawn only the three open units nearest you threw real light (`UnitLight.NearBulbs`, the
  climb's phone cap) and the rest read as grey holes, when the home's point is that everyone
  sees everyone's units on the way to the cars. So each front's bulb (the climb's, wired to its
  door as on a climb) is marked a home's (`UnitLight.Home`): reach 22 and 1.7 times a climb
  bulb's brightness, so it fills the XL unit and spills a warm pool out of the doorway; no
  shadow; and never counted among the nearest, it throws light whenever it's lit. The room's
  two fills became a pair in each of three rows (26, 78 and 130 studs from the cars), so you
  load in to a lit floor running away to the cars. Judged in Studio's Play viewport (1380 by
  761), not the A16 emulator: ten open units warm down both walls, two shut ones red.
- **Not chosen:** a higher `NearBulbs` everywhere (the climb's budget is the climb's);
  shadowed home bulbs (twelve shadowed lights are the costliest thing a phone can draw);
  haze or other mood effects (AGENTS.md: loop before atmosphere).
- **The cost, for a2b:** up to 25 real lights in the lobby (6 fills, 12 home bulbs, 6 car
  lamps, the porch), none shadowed but the porch's. Unshadowed, a home bulb reaches through its
  unit's walls; its neighbours are homes too, and the warm wash on the wall between two open
  doors reads as more of the same light. a2b weighs it all on a phone.

## D-263 · 2026-11-16 · The ground floor and its units look like a home, not the climb (the owner's direction, S5-03a2b)

The owner, as the ground floor went in: "I just want to ensure that the art isn't quite so
strictly identical to the game. The lobby should feel calm and peaceful. Right now the ceiling
is very industrial, the units are all very rugged. The lobby and home base units should feel
welcoming and when decorated, fun and somewhere to hang out (within reason). Units should have
light switches as well because shutting the door makes it dark inside. ... The elevators are
uncertain, taking you to floors where god knows what happens, but the units on the base floor
are safe and a space all your own, so I want that vibe fully delivered as well."

- **Two moods in one building.** The six cars and their back wall keep the climb's edge: they
  are the way into the unknown. The rest of the ground floor is the building at its calmest and
  best kept: a finished ceiling with warm, soft lights in place of the bare joists and strip
  lights, warmer walls, a cared-for floor, and a few things that say someone looks after it
  (potted plants by the units, a bench). Precedent: Lethal Company's ship and Resident Evil's
  save rooms, the safe place set against the danger; Animal Crossing's homes for the warmth.
- **Home units are a kit of their own**, not the climb's M front: the same footprint and door
  rig, so the door still rolls, but smooth painted partitions in place of raw corrugated sheet,
  a finished ceiling in place of the wire top, a clean roll-up door in a warm colour. The
  climb's units don't change. This replaces D-262's climb fronts in the gaps.
- **A light switch in every unit**, by the door inside: Switch (the lamps' verb), a click, the
  warm light coming up or going down over a moment; with the door down and the light off it's
  dark. It starts on. Only the unit's owner switches it once a3 hands units out (my default,
  `OWNER.md`); everyone sees it as it is.
- **Welcoming from the first visit** (my default, `OWNER.md`): every unit starts with a rug, a
  beanbag and a floor lamp, as Animal Crossing's first tent comes with a sleeping bag, a lamp
  and a radio. Movable once Arrange exists (S5-03e).
- The phone weighing moves to S5-03a2c, after this, since the new look changes what's drawn.

## D-264 · 2026-11-16 · The ground floor re-done calm: plaster, oak, beams and round lamps (S5-03a2b1)

The ground floor's art is re-done for D-263. The climb's edge keeps to a strip 12 deep along the
bay wall (`LANDING`, the first partition's line): its concrete, the steel deck on open-web
joists, the hall lights, the striped zones and the cars. Past it the floor is a home.

- **The home's own texture sets** (`art/home`, baked the unit's way): `Plaster`, painted
  plaster whose paint is the part's Color (Overlay, as the unit's Facade), with only a roller's
  stipple and a satin sheen in the maps; `Wood`, an oiled oak plank floor, twelve planks to 8
  studs, ends staggered, every plank its own shade, no scratches (it's looked after). Wood trim
  (beams, rails, baseboards) wears one plank of that bake drawn out along its length, so no
  plank joints show on a beam.
- **The room:** oak planks running toward the cars; sage plaster below the rail and warm cream
  above it to the ceiling, a wood baseboard and a wood rail where the units' caps run; a soft
  white plaster ceiling at the deck's height on wood beams (two front to back, one across on
  every partition line, so each beam bay holds a pair of units), dropping to a bulkhead where
  it meets the cars' deck; 28 round lamps, four across in each beam bay; a deep red runner rug
  from the door to the cars. Precedent: a hotel's lobby, Animal Crossing's warm interiors.
- **The units' insides** are smooth plaster in a warm white with a flat ceiling at the walls'
  top and a wood baseboard round the inside, on the oak floor. Their fronts are still the
  climb's M until S5-03a2b2 builds the home front.
- **Phone cost:** 17,470 triangles in 24 parts (from 25,166): the finished ceiling and the
  plaster walls are a few boxes where the deck and R-panel were thousands. The lamps are one
  plain part (the game makes it Neon); which of them throw real light is S5-03a2c's.
- **Defaults the owner may change** (`OWNER.md`): the palette (sage, cream, oak, red runner).
- **Not chosen:** a carpeted floor (reads as an office, and shows nothing of the light); posts
  and pilasters on the home's walls (they were the climb's steel rhythm); the counter and shelves
  re-done (the shop's own piece).

## D-265 · 2026-11-17 · Each kit find's game row lives in its art spec (F-G1f1, the run's P1a)

The owner's third find run (Nov 16 night): a find goes from photos to playable in one ticket, so
what the game deals and plays for a find lives beside its art, not in lists kept by hand in the
game's code.

- **The row in the spec.** Each set's `art/finds/<set>/spec.py` ends in `GAME`, one row a find in
  the deal's order: its key, its line in the item catalog (as `art/finds/WAVES.md`'s table names
  it), its name on screen, grade, worth, lowest floor (`from_`), the catalog's rules (`loose`),
  grip, heft, size in your view, pick-up and drop sounds, and its press (`Finds/Use`'s row: its
  word, steps, how long it lasts, its noise and lure). The sounds and the lamp's press are named
  once in `art/finds/kit/game.py`, plain Python.
- **Generated, never by hand.** `art/finds/rows.py` (plain Python, no Blender, so a number changes
  without rebuilding a mesh) reads the specs and writes `src/shared/Finds/Rows.luau`, formatted by
  StyLua. `scripts/art.sh rows` runs it alone and every set's export runs it; `scripts/check.sh`
  fails if the module is stale or edited by hand. It refuses a row with a field it doesn't know
  or one missing, a grade or size it doesn't know, a key twice, no art in its set's generated
  module, or a catalog line WAVES.md doesn't have.
- **Judged means ticked built.** A row is `judged` when its catalog line in WAVES.md's set tables
  has a dated Built cell, the art's tick. P1b deals only judged rows.
- **The press types moved** from `Finds/Use` to `Finds/Game` (types only), so the generated rows
  and `Use` share one definition without a require loop; `Use` keeps their old names.
- **The proof.** `tests/fixtures/kitrows.luau` freezes the 41 hand-written kit rows as they
  stood; `tests/kitrows.spec` holds every generated row to it: every field, every press step, the
  deal's order, the Old lamp's floor 25 and loose only. A deliberate change updates its line in
  the fixture in the same commit; a press added where there was none needs nothing there.
- **Order matters.** `Deal.findFrom` picks by place within a grade, so the generator writes the
  sets in the order they were built (lights, figures, windups, squishies) and a new set goes last.
- **Left out:** the bedroom set stays hand-written (one-mesh finds with no kit spec); the theatre
  spotlight has no row (a big find, not dealt until a floor has a big-find place); the RC car's
  row names its verb, Drive, since its press is `Finds/Drive`.
- **P1b next:** the hand-written kit rows in `Tools.Catalog` and `Finds/Use` go, both built from
  `Finds/Rows`' judged rows; `Deal.Finds` becomes the bedroom set plus the judged rows, less any
  with no template in the place (checked by the server as it starts), and the Old lamp's `loose`
  is read where the marked box is chosen; then `art/finds/PIPELINE.md` and one Studio Play check.

## D-266 · 2026-11-17 · The deal takes every judged find with its art in the place (F-G1f2, P1b)

- **No hand-kept list for kit finds.** `Tools/Catalog`, `Finds/Use` and `Deal.Finds` are built
  from `Finds/Rows`' judged rows (D-265): the bedroom set (one-mesh finds with no kit spec) stays
  hand-written, first in the deal, then each judged row in the order the sets were built.
- **Art checked as the server starts.** `Deals.new` calls `Deal.onlyWith` once with whether each
  find's template is in `ReplicatedStorage.Props.Finds`; a find without one is left out of the
  deal and named in Output, so a find ticked before its import never deals a unit that stands
  empty. Left out, not an error: the art session imports it next (`art/finds/PIPELINE.md`).
- **Loose only is the catalog's.** A row's `loose` (the Old lamp) keeps `Deals`' `layBoxed` from
  standing it in a marked box; Studio's `DevBox` still forces one, as it forces any size.
- **Big finds wait.** A big find (both hands, behind a floor's code door) gets no game row until
  a floor has a big-find place, so the theatre spotlight stays out of the deal.

## D-266 · 2026-11-17 · The home front and the furnishings (S5-03a2b2)

The home's kit (`art/home`) gets its front and furnishings, D-263 made real. The moment: from
the car you see a row of little homes, a plant by each door and a bench between, and inside
yours a rug, a beanbag and a lamp waiting (Animal Crossing's first tent comes furnished; a
hotel lobby's planters and benches).

- **The home front** is the M's door rig in a home's doorway: the room's sage plaster wall runs
  across the front with its oak baseboard and rail, an oak casing on plinth blocks under a
  small cornice frames the door, the reveal is lined in oak back to the guides. The climb's
  jambs, pilasters, kick plates and cap are gone (`parts.frame(dress=False)` keeps only the
  mechanism). The door wears **HomeDoor**, the DoorKit's own layout baked new (satin enamel,
  bright galvanized, a clean bar), tinted by the game: clay in the sheets. The padlock and
  number plate stay on the climb: a home's door latches, and its owner's name is over it.
- **A light switch** inside by the door, on your left as you walk in, twice a real plate's
  size so it reads on a phone, its rocker a part of its own for the game to rock. **A round
  ceiling lamp** in each unit, the lobby's look, in place of the climb's bare bulb.
- **Furnishings, each its own part on its own origin**: a snake plant in a cream pot (a Leaf
  bake: banded leaves, yellow margins, soil), an oak bench with a back, a square planter you
  sit round on an oak seat with five snake plants in it, the starter rug (a flat-weave in
  terracotta, teal, mustard and oatmeal, baked), a slumped beanbag and a floor lamp with a
  drum shade (Fabric, tinted). New sets: Leaf, Fabric, Rug, HomeDoor.
- **The floor:** a plant either side of every door and a bench on each partition line between
  (24 plants, 10 benches), two planters in the middle under the cross beam at y -72, 20 off the
  runner either side: lanes stay wide to the walls and the carts' way. Rows the game reads:
  `Lobby.Specs.Dressing`; the starter set: `Home.Specs.Starter`.
- **Phone cost:** Home.fbx is 10,664 triangles in 25 parts; a plant is 764, a bench 404, a
  planter 2,396, a starter set 852. The floor's furnishings add 27,168 triangles of instanced copies.
- **Defaults the owner may change** (`OWNER.md`): the clay door, cream pots, a mustard beanbag,
  no padlock at home.
- **Not chosen:** a padlock on home doors; carpet in the units (the oak reads warmer); a round
  planter (four boards read cleaner at phone size than a ring); the climb's bulb kept.

## D-267 A loudness for each noisy find, and a cap on noise (F-G1e1a, Nov 17, V1)

- A press's noise carries as far as its row's `heard` (studs along the halls, `Use.loudness`),
  written in its art spec; none is the air horn's 130, so the cymbal monkey and the jack are as
  before. The duck's squeak is `DOWN_THE_HALL`, 60 (`art/finds/kit/game.py`). Later noisy finds
  (V2 to V5, the mega goo ball) set `heard` and nothing else.
- One noise ledger per server (`Use.Din`): monsters hear a find at most once every `HearGap`
  (1.5 s) however fast it's pressed, a lure's beat is never quicker, and only `LuresAtOnce` (3)
  lures are heard at once: a new one past that silences the oldest (it plays on unheard), since
  monsters go to the newest noise anyway. This bounds the server's hall searches on a low-end
  phone's game; each press still plays its own sound on every screen.
- The squishies are quiet (the catalog's Squeeze): `squeeze(sound)` in `kit/game.py`, a toy
  pressed again once it has come back. Their sounds are borrowed Pro Sound Effects stretches,
  measured in Studio; their own recordings are ROADMAP polish ("Finds' own sounds").

## D-268 · 2026-11-17 · The home look in the game, and its light switch (S5-03a2b3)

The ground floor's new art (D-264) and the home's kit (D-266) are in the place and the game.
The moment: you load in to a calm, warmly lit room, a row of little homes down each side, a
plant by every door, and inside your own a lamp on, a rug and a beanbag waiting; flick the switch
by the door and the light eases off (Animal Crossing's house lights; a real room's switch).

- **Templates:** `ReplicatedStorage.Props.Lobby` (asset 80376262399856, updated in place) and
  the new `Props.Home` (asset 110439035194989, `Home.prepare`: its pivot the identity, so each
  part's CFrame is its place in a unit's frame or on a piece's origin).
- **A home is the M's rig re-dressed** (`Home.dress`): the climb's M unit, walls dropped, keeps
  its door parts and RollUpDoor rig; they swap their SurfaceAppearance for HomeDoor (same meshes,
  same UVs) and paint clay; the M's facade, frame, padlock and number plate give way to the
  home's facade (sage), its back (warm white), the oak casing, the mechanism frame, the switch
  and the round lamp. Doors runs it as on a climb. With no Home template, the old M front stands.
- **The light is the switch's, not the door's:** `Home.LightAttribute` on the unit, on when laid,
  flipped by the server (FrontOffice: one "Switch" button per home, a 0.2 s cooldown per unit,
  refused to the wrapped). Every screen draws it (`HomeLights`): a click at the plate, the rocker
  tweened 12 degrees (top in for on), the ceiling lamp and the starter floor lamp easing over
  0.2 s. The ceiling lamp is a home bulb through UnitLight, now a clean warm white
  (`UnitLight.Home.Colour`, `GlassLit`, `GlassDark`) rather than the climb's dirty amber.
- **Dark with the door down and the light off:** the room's fills now carry HallLight's tag, so
  BehindDoors keeps them out of a shut unit on your screen (seen in Play: 3.3 down to 0.2).
- **The room:** plaster parts painted the sheets' colours (sage, cream, soft white ceiling, warm
  white units) through Overlay; the 28 round lamps Neon, warm; the runner Fabric; the hall
  fixtures only over the cars (nearer the bay wall than the first partition); the fills a warm
  white. 24 plants, 10 benches, 2 planters placed (`Home.piece`), solid parts colliding as
  boxes; Seats: two on a bench, one each side of a planter, one in the beanbag.
- **The switch's key is T** (pad d-pad up): inside a shut home the door's Lift has E and took the
  press. Its button hangs on a spot of its own just off the plate (the plate sits inside the
  front's wall collider). Seen to press in Studio Play (S5-03a2b4): T with the door up and
  down, and a tap on the A16 simulator; its button shows only while it is on screen.
- **Defaults** (`OWNER.md`): the light starts on; anyone may flip it until homes have owners
  (S5-03a3 decides with the owner's D-263 pick, "only the owner").
- **Not chosen:** the lamp on the door like a climb bulb (the home is a room you live in, not a
  fridge); a stutter (the climb's); hum (a home is quiet).

## D-269 A squishy squashes in your hand: the root sized, bones bent by their CFrame (F-G1e1b, Nov 17, V1b)

- **The root is sized too.** `Finds.joints` sizes every part as the kit's sums say, the root
  included, and places the others round the root's place in the sums. The root itself never
  moves (a hand's weld or a floor holds it), so a find squashes about the root's middle. Seen in
  Play: the root stays put against the hand that holds it (0.0000 studs) through every squash.
- **Bones bend through `Bone.CFrame`, never `Bone.Transform`.** A character's Animator puts
  every `Bone.Transform` in the character back to nothing each frame, between PreAnimation and
  PreSimulation (seen in Play), so a dent written there never showed in a hand. `bend` records
  each bone's unbent CFrame at the art's size (attribute `FindBoneRest`, carried by copies) and
  sets the CFrame from it, scaled for a copy drawn smaller (your view's, 0.3).
- **On the floor:** a press needs the find in your hand (`Slots.used`), so a squishy can't be
  squeezed lying down; one dropped mid-squash finishes it about its middle where it lies.
- **Not chosen:** squashing about the grip (the ticket's call: about the middle); moving the
  root (it would drag the player, `Finds.joints`); stopping the Animator (it runs your arms).

## D-270 Wind and go: a set-down find is heard along its path; a wind-up walks on at a wall (F-G1e2a, Nov 17, V2a)

- **Heard where it is, not where it ends.** The server still lays a find set down to play where
  its travel ends, at once (D-233: that's where it is for picking up and for the Packrat). For a
  noisy one it now keeps the path it walked (where it set off, its root's place along the press,
  where it stopped short) while it plays, and every hearing (`heardAt`) asks where along it the
  find is now (`Use.played`'s travel). The chattering teeth lure from each place they chatter
  through, every 2 seconds, so a monster follows them across the floor, away from you. A find
  picked up or moved since it was laid is heard where it is. No server stepping: the place is
  worked out only when a noise is heard.
- **A wind-up walks on at a wall** (a row's `walks`). The toy car meets a wall and holds the frame
  it stopped in. A wind-up meeting a wall stops going forward but not its going, as a real one
  does: its root's place over the floor and its facing (`Use.Holds`: x, z, yaw) hold where it
  stopped, while its legs, jaw and bob play on (`Pose.hold`), its clacks sound and its lure goes
  on. The server lays it where its last frame stands, held at the wall.
- **A hit beats on every peak, not only the furthest.** `Use.beats` (moved from FindUseView so a
  spec can hold it): each key where the hit part's channel (`hit.channel`, none: its turn) peaks on
  the side it swings furthest, at least `Use.BeatShare` (0.15) of that far. The teeth's snaps
  slow and weaken as the spring runs down and each still clacks; the monkey still clashes on every
  full swing (the spec checks it).
- **The teeth:** Wind sets them down in front of you; the key turns (the wind-up recording), then
  ten seconds of chatter, a clack each snap (the body's forward jolt, `hit` on its pitch), heard
  `ACROSS_THE_FLOOR` (90 studs, between the duck's squeak and the cymbals) every 2 seconds.
  Precedent: R.E.P.O.'s music box and the cymbal monkey's lure (the catalog's Wind row). The
  loudness is a default for the owner to feel (OWNER.md).

## D-271 · 2026-11-17 · The ground floor weighed for a phone (S5-03a2c)

The moment: on a cheap phone the calm ground floor runs smooth from the spawn to your home and on
to a car, with every home lit.

- **The caps:** the GDD's tech plan gives no numbers ("cap awake monsters and real light
  instances for low-end Android"; real lights near the camera, a glow farther out). The climb's
  default is 6 real lights (D-015), which the ground floor can't keep with every home lit (far
  homes read as grey holes, D-262). So its own default, until the owner says otherwise: the
  room's 6 unshadowed fills, the 12 home bulbs, the porch and the cars as on the climb; anything
  else throws real light only near you. Triangles: no heavier than a climb floor's busiest view
  (61k to 112k measured, `docs/STUDIO.md`).
- **Measured** in Studio Play on the Galaxy A16 simulator (685x338), every home lit, doors down:

  | Spot | Before | After |
  |---|---|---|
  | Spawn, facing the cars | 43 lights, 160,336 tris, 81 draws | 31 lights, 144,616 tris, 77 draws |
  | In home 1, facing its door | 43 lights, 17,684 tris, 29 draws | 33 lights, 17,684 tris, 29 draws |
  | In front of the cars | 43 lights, 61,124 tris, 40 draws | 31 lights, 61,124 tris, 40 draws |

  Studio drew 15 frames a second at every spot, before and after (its window was in the
  background, the throttle in `docs/STUDIO.md`), and its render CPU time was about 3 ms a frame
  throughout, so a phone's frame rate is the owner's to see (`OWNER.md`). The run from the
  spawn to the front of a car is 136 studs, 8.5 s at walking speed.
- **Trimmed, nothing warm cut:** the floor lamps throw real light only in the two homes nearest
  a point just ahead of you, within 32 studs (`Home.FloorLamp.Near`, `Reach`), coming and going
  over 0.4 s; every shade keeps its glow, so no home reads dark (UnitLight's near-bulb pattern).
  A front's drum and head plates (`Home.InsideOnly`: 1,310 triangles each, above the doorway
  behind the front wall) are drawn only on a screen whose camera is in that home or within 2
  studs of its doorway (`LocalTransparencyModifier`, HomeLights).
- **Still over the triangle default at the spawn:** the six cars are 51k (8.5k each, the climb's
  Elevator), the twelve fronts 44k (curtain, mechanism frame, bottom bar: all seen) and the
  furnishings 35k (24 plants, benches, planters, the carts). The cars' hidden parts are next
  (S5-03a2d); the plants and the fronts stay.
- **Not chosen:** fewer fills (they are the room's warmth and cast no shadow); the home bulbs
  near-only (D-262); the cars' lamps' shadows or keypad glows (the cars are the climb's, left
  as they are by this ticket).

## D-272 Wind and go for the rest: the robot, mouse, tin bird and carousel (F-G1e2b, Nov 17, V2b)

- **Only their rows.** Each is a `press` in `art/finds/windups/spec.py` on V2a's verb (D-270):
  wound, set down (`down`), walking on at a wall (`walks`), luring every 2 s from where it is
  (`lure=2`). The robot clanks on each footfall (its body's nod, `WalkingRobot_Body` pitch, 44
  beats), the bird whistles on each opening of its beak (`TinBird_Beak` turn: five whistles of
  two notes), the mouse squeaks where it stalls (its body's rock onto its nose, `WindupMouse_Body`
  pitch: two rocks big enough, so two squeaks, "eek-eek"). The carousel plays in place (no
  `down`): its tune is its Play step's sound, its lure the cymbal monkey's.
- **Loudness, a default for the owner (OWNER.md):** the robot's clanking and the bird's whistle
  carry 90 studs (`ACROSS_THE_FLOOR`, as the teeth); the mouse's squeak and the carousel's music
  box 60 (`DOWN_THE_HALL`, as the duck).
- **Sounds (all measured in Studio, `kit/game.py`):** `CLANK` (Pro Sound Effects' robot footstep,
  pitched up), `EEK` (the duck's squeak, higher), `WHISTLE` (a pealess whistle's burst, pitched
  up), `CAROUSEL_TUNE` (APM's "Music Box 6", 15.5 s). The tune slowing as the spring runs down is
  ROADMAP polish: `PlaybackSpeed` would drop its pitch too, and a music box keeps its pitch.
- **A hop is no wall.** The server's path walk cast along the root's whole step, so the tin bird's
  first landing pointed the ray down into the floor and read as a wall: it stopped 2.1 s in, on
  open floor. It now casts only the step's going over the floor (`FindUses`); the bird hops its
  0.78 studs.

## D-273 · 2026-11-17 · A home each comes from Brix's Plots (S5-03a3a)

The home doc's idea 1 (agreed Nov 16, D-251): as you join you're given one of the twelve homes, yours
until you leave, as Grow a Garden and Bee Swarm Simulator hand each player a plot.

- **Built in Brix** (D-252) as its ENG-25a: `Brix.Plots.new({ plots, pick })` keeps who holds which
  home, `Brix.PlotPick.inOrder()` gives a newcomer the first free one in the game's list, and
  `Brix.Roblox.PlayerPlots` claims on join, lets go on leave, fires `claimed` and `released` and
  writes the home's name on the player as an attribute. Nothing about this game is in Brix.
- **The game lists its homes nearest the spawn first**, so a half-full server's homes sit together
  and you walk the least to yours. Not chosen: a random home, which scatters a small group.
- **A full server** (13 players for 12 homes, which Roblox's player cap should prevent): the
  thirteenth waits in line and gets the next home let go, rather than having none.
- **Brix's pin moved to `482368f` before Brix's `main` was pushed**, since the owner wasn't there to
  say yes to a push. Brix must be pushed before this game is (OWNER.md).

## D-274 · 2026-11-17 · A sound partway into a press: a step's cues (F-G1e3a, V3a)
A find's press could sound only as a step starts (`sound`) or on its motion's beats (`hit`), but
the noisemakers' sounds come partway in: the kazoo hums once it's at your lips (0.36 s), the
doll talks as the cord is let go (0.62 s), the spinner's animal calls as its arrow stops
(3.07 s). A step now has `cues`, each a sound at a moment into its motion, merged with the
hit's beats into one time-ordered list (`Use.timeline`) that `FindUseView` plays as the motion
passes them; several due at once after a hitch play each different sound once. Monsters still
hear a noise as its step starts (`noiseAt` unchanged): a monster takes seconds to arrive, and the
press itself is the noise. The kazoo (Blow) and toy drum (Bang) are the jack's one-shot noise,
toys, no lure: the kazoo heard 60 studs (down the hall), the drum 130 (the catalog's "loud", as
the air horn). Sounds measured in Studio: the kazoo's hum is Pro Sound Effects' "Kazoo Fanfare
3" last held note (one pitch from 2.68 s, swelling), at 0.75 pitch to last its 1.22 s note; the
drum's bang a snare hit pitched up. The arrow, as built, stops on the cat, so V3b's spinner ships
the meow; a server pick of the animal is ROADMAP polish.

## D-275 · 2026-11-17 · Your home is handed to you as you join, and only you open its door (S5-03a3b)

The home doc's ideas 1 to 3 and the owner's Nov 16 answers ("Doors start open. Pulled down, a door
keeps everyone out, friends too."), on Brix's Plots (D-273).

- **Handed out nearest the front door first**: 1, 7, 2, 8 and so on (`Home.Holding.order`).
  A beat after you first stand in the lobby (1.5 s), your name goes on the card over your door in
  the building's capitals and, 0.6 s later, the padlock comes off and the door rolls up with its
  slow, loud open. Precedent: Grow a Garden's and Bee Swarm Simulator's plots.
- **The name is sprayed on through the stencil** on every screen (HomeCards): the letters come up
  from nothing, shrinking onto the card, the fresh ink glowing then settling, with a can's short
  hiss heard across the floor (Pro Sound Effects' "Spray Paint 4", 9119522956; not yet judged by
  ear). A name blanked as its holder leaves fades off.
- **A held door** (`Door.HolderAttribute`, `Door.decideHeld`): from the hall only its holder
  opens or peeks it; anyone else's try rattles it against the lock and it doesn't move, with no
  words (their name is over the door). Precedent: Adopt Me's house locked to its owner. From
  inside it always lifts, padlocked or not: nobody is ever shut in at home. Lock and Cut never
  show on a home. A rattle now keeps the door where it was (a peeked home rattles at its peek).
- **Anyone may pull an open home's door down** (my default, `OWNER.md`), as on the climb; only
  opening it is the holder's. Not chosen: closing kept to the holder too, which hides buttons
  everyone sees on every other door.
- **Spare homes wear the climb's padlock** (idea 2: rented out), drawn only while padlocked;
  yours wears none, so D-266's "no padlock at home" still holds for a home that's someone's. A
  home's padlock comes off with its key (the shackle's click and the bolt), never the cutters'
  snap, and isn't thrown into the hall.
- **Let go** (its holder leaves): the card blanks, the door comes down and the padlock goes back
  on once it lands; the light is left on for the next holder.
- **The switch is the holder's** (D-263): the server answers only their press, and the button
  shows only on their screen.
- **A home's room is its own size** (`RoomWidth`, `RoomDepth` on the unit, from the lobby slot's
  Inside, 20 by 30): ShutIn counts you shut in anywhere in it, not just the M's first 12 studs.


## D-276 · 2026-11-17 · The spinner, the doll and the fish; a part at rest is no beat (F-G1e3b, V3b)
The three talking finds are rows on D-274's cues, each the jack's one-shot noise heard 60 studs
(down the hall), toys, no lure. The farm spinner's Pull: the lever's clack as it slams back
(0.47 s), a tick on each hop of its arrow into a notch (a `hit` on `FarmSpinner_Arrow`'s turn),
the cat's meow as it stops (3.2 s). The doll's Pull and the fish's Press ship OWNER.md's
defaults until their voices are recorded: the cord's whirr from the let-go (0.62 s) and its clack
home (3.01 s); the button's click, the motors' hum from 0.28 s and the head's two knocks on the
board (5.86, 6.04 s). `Use.beats` no longer beats a part's last key, where it comes to rest: the
spinner's arrow settles into the notch it has just ticked into 0.09 s earlier, which sounded the
third tick twice; no other find's beats changed. The server's pick of the animal stays ROADMAP
polish (the session's context cap): as built it always lands on the cat. Sounds measured in
Studio (AudioAnalyzer): "Cat Meow Sound" (Creator Store, 0.97 s, the meow 0.06 to 0.6 s; it
loads in Play); Pro Sound Effects' "Robot Servo 3" (the whirr, 0.8 pitch over 2.4 s) and
"Robot Servo 19" (the hum, 0.7 pitch over 6 s).

## D-277 · 2026-11-17 · The hard hat goes on your head: Wear, lit, its slot freed (F-G1b4a1)

The owner's ticket (Nov 16, D-251) was too big for one session's context, so it is split: this
part puts the hat on your head and lights it; F-G1b4a2 draws the headlamp's own beam.

- **Wear is the hat's press.** Its row's word (`art/finds/lights/spec.py`, rows regenerated) is
  Wear: the press takes it from your hand onto your head (`Slots:toHead`), frees its slot, and
  lights it as before. The press is the shell's knock (the hollow plastic knock its pick-up uses,
  pitched down) with the lamp's click as a timed cue at 0.14 s, as its switch flips. It has no
  switch off: on your head it burns its minute (F-G1b4b spends it). A hat already lit goes back
  on as it is. The frozen rows test (`tests/kitrows.spec`) skips its verb and press, now tested in
  `tests/head.spec`.
- **On your head it's still in your slots' system.** `Slots` keeps one worn find per player
  (`ToolHead` on the Player, `WornBy` on the model), welded to the head's hat point by
  `Finds/Head`'s fit: grown 1.4 times (D-196), the rim 0.42 studs down, tipped 4 degrees, the
  cord and battery hidden. Caught or dying, it drops with the rest; aboard as the gate shuts, it's
  kept with your finds, leaving your head in a glint; a new character gets it back. Defaults the
  owner may change (OWNER.md): kept at the gate, one hat at a time, the Packrat never takes it.
- **Its light for now is the hat's own lamp**, the art's warm spot and glow, drawn by
  `FindUseView` as any found light and pointing where your head faces. F-G1b4a2 replaces it with
  the tighter, whiter beam that follows your look and bobs.
- **It holds a Mannequin as a found light lying lit does**, from where your head is now: Keepers
  gathers each lit worn find once a step and counts it with the floor's glows.
- **At home it never runs down** (D-259): worn on the ground floor (the front office's room and
  40 studs round it, `Head.home`), its light is stamped forever. A hat worn at home and then
  carried up the climb stays lit forever; F-G1b4b should start its minute as you leave home.

## D-278 A find's root carried by its own motion moves the grip that holds it (F-G1e3c, Nov 17)
- **The moment:** you blow the kazoo and it tips up toward your lips as it hums, in your hand,
  in your view and in your friends' hands, then settles back.
- **The problem:** `Finds.joints` never moves a find's root (a find in a hand is part of the
  character, and moving a part there drags the player), so a motion on the root's own channels
  (the kazoo's lift and tip, the duck's nod, the spinner's tip toward its lever) never showed.
- **The rule:** `Pose.carry` is the root's own rigid move (its lean, travel and turn), its squash
  and stretch left out so a squishy still squashes about its middle in the hand (D-269).
  `Finds.shift` turns it into a move from rest, and every screen moves what holds the root by it:
  the hand's weld (`Finds.grip` sets its C1, keeping the server's C1 on the weld as
  `FindGripRest` so shifts never add up) and your view's copy (`Hand.shift`). A find set down to
  play (`down`) never plays in a hand, so it's left out.


## D-279 The farm spinner lands on a new animal each pull, the server's pick (F-G1e3d, Nov 17)
- **The moment:** you pull the spinner's lever again and again to see which animal it lands on, a
  moo, an oink, a rooster's crow, and each one is a noise the monster down the hall may hear.
  Precedent: the prize wheel (Wheel of Fortune, every game's daily spin): one spin, the stop is
  the house's, you watch it slow into it.
- **The rule:** a step's `lands` (art spec, `rows.py`, `Game.Step`): the arrow part, the stop size
  (45 degrees), when the call plays (3.2 s) and the eight calls in the face's order from the cow
  the arrow is made pointing at. The server picks each press (`Use.pick`: any of the other seven,
  never the one it's on, so every pull shows something new) and writes `UseLandFrom` and
  `UseLand` before the stamp's clock. Every screen bends the art's one spin once a press
  (`Use.bend`): all the arrow's keys on by where it set off, and the keys from its first move on
  by the whole eighths that bring its end round to the pick (none to seven more: it spins a
  little further, never back), so the ticks stay on the art's hops. `Use.timeline` takes the stop
  and adds that animal's call. The last frame holds, so the arrow stays on its animal until the
  next pull; a find never pulled points at the cow.
- **Your own pull, shown at once:** it spins from where it rests to where the art's spin takes it;
  the server's pick arrives in the 0.4 s before the arrow moves and bends it there.
- **Defaults (OWNER.md):** the seven calls besides the meow are Creator Store uploads and Pro
  Sound Effects recordings, picked and leveled by measurement, not by ear.

## D-280 · 2026-11-17 · The mirror test: a world built behind the glass, seen through it (S5-03b)

The moment: you walk into your unit, turn to the mirror and see yourself, the right way round,
your unit behind you. D-259 wanted a ViewportFrame on the glass with left/right-swapped posed
copies; this is how it's built, as a test the owner judges before S5-03f.

- **A world behind the glass, not a flipped picture.** Roblox can't flip a picture
  (`ViewportFrame.IsMirrored` is locked) or a model, so every copy stands where its reflection
  would, behind the glass, turned to face back out, and the picture's camera is your own camera
  looking square into the glass. The picture is sized and placed so the glass is exactly a window
  onto that world (`Mirror.view`), so the reflection shifts as you step about, as a real one does.
  (D-259 put the camera at your eye reflected; that needs the flip Roblox doesn't allow.)
- **Copies turn, never flip.** Each copy is reflected and turned over along the one direction the
  thing is the same both ways across, and two flips make a real rotation: a body part across its
  own left and right, drawn with its partner (your right hand's reflection is your left hand's
  copy); a hat across your head; a wall or rug along its long level side. What can't come out
  right: writing on clothes reads the right way round, and a one-sided thing keeps its side.
- **One mirror at a time** (D-259): the nearest within 70 studs holds the room's copy, still, from
  a step in front; within 24 studs and on screen it moves with you every frame. Further off, plain
  glass. The room is copied once (only what's in front of the glass, within 34 studs, never a
  neighbour's unit, at most 900 parts); the door, the lamps and the switch each frame; people
  each frame, again whenever what they wear changes.
- **Light**: a ViewportFrame has no lamps or shadows, only an even light; it's warm while the
  unit's switch is on and dim when it's off (`MirrorView`'s LIT and DARK).
- **Where** (my default, OWNER.md): leaning on the unit's left wall by the rug, glass toward the
  floor lamp, 2.4 by 5.6 studs, an oak frame from plain parts for the test; the real frame is
  art for S5-03f.
- **It lives in this game for now**: it's a test. If the owner keeps it, S5-03f weighs moving its
  maths to Brix as a neutral part (D-252).
- **Seen in Studio Play, Nov 17, and fixed** (session 233; `docs/art/S5-03b-*.jpg`). With Studio
  in front it drew at 60 frames a second, and macOS `screencapture` of its window stood in for the
  MCP's capture (STUDIO.md). The glass was blank: the lobby's merged meshes (the units' walls, the
  woodwork) passed the old test by their middles, so the wall the mirror leans on was copied half
  a stud in front of the glass and hid the whole picture. Now `Mirror.keeps` decides what is
  copied: wholly in front, yes; through the glass, only what lies below its foot or above its top
  (floors, ceilings) or well off to its side. The unit's walls and baseboards, which exist only in
  those meshes, stand in the picture as plain parts, from the door face (the glass's `Face`
  attribute) and `Home.Mirror.Room`.
- Close up, 64 pixels a stud went to steps on your outline, so the picture sharpens as you come up
  (`Mirror.sharpness`: 64 from 4 studs off, 96, then 128 at 2). In front of it Studio held 60.
- Seen right: you the right way round (the torch in your right hand on your right), the room behind
  you with its rug, plant and lamp, the floor and walls running on into the glass, the far corner
  and not you from the side; the switch off dims the reflection with the room. Its ceiling lamp's
  copy stayed lit with the switch off; it now takes the lamp's colour and material each frame
  (passes checks, not seen again).
- The mirror showed a bug that isn't its own: the worn hard hat sits on your chin, its shell's
  middle 0.4 studs below your head's (the head weld in `Slots` seats the find's pivot, which isn't
  at the hat's rim). Queued in HANDOFF.

## D-281 The siren car rolls off wailing, its roof light lit only while it plays (F-G1e4, Nov 17, V4)

The moment: you set the toy siren car down, push it twice and it zooms off down the dark hall,
its red roof light turning and sweeping the walls, its wail pulling the monster after it while
you slip the other way. Built from rows on verbs that already existed:
- **The roll is the toy car's** (D-233): set down, its path walked for walls, every screen rolls
  it there. Its noise is heard where it is along that path, every 2 seconds, across the floor
  (90 studs, under the cymbals), the walking robot's lure (D-270).
- **A wall stops it going, not its flywheel** (`walks`): a friction toy pushed into a wall sits
  there with its wheels spinning and its siren winding down, so it plays on held at the wall
  and its lure with it, as the wind-up mouse does. This is also what puts its light out: a find
  that holds the frame it stopped in stays at that frame, lit, for good.
- **Its light shines only while it plays**: a toy's frame is lit until its motions end, and the
  art's beacon glow (up on the first push, out 0.9 s after it stops) drives its two lights, the
  spot on the turning dome sweeping the walls. A toy, so it never holds a Mannequin (D-234): it
  draws the monster, it doesn't stop it.
- **The real-light cap holds for things that move away**: a find's lights shine only within the
  90 studs where screens pose finds, still the 2 nearest, and one that leaves that range lit is
  posed once more to put its lights out (before, a siren car you walked away from mid-roll
  would have kept its light on after it stopped, past the cap).
- **Its sounds**: the wail is Pro Sound Effects' small whooper toy siren from the first push;
  the toy car's wheels roll under it as it's let go. A recording of a real friction siren and
  its pitch following the flywheel are ROADMAP polish.

## D-282 · 2026-11-17 · The hat you wear is hidden from your own eye (F-G1b4a1b)

- **The moment:** you put the hard hat on and look down a dark hall, its lamp lighting the way
  from your brow, with no shell or brim in your view. Friends see it on you; so does the mirror.
- **Why Roblox's own hiding wasn't enough:** the hat is welded to your head inside your
  character, so Roblox's PlayerModule hides it in first person, but only while its own camera
  runs. Under a camera the game holds (a crawl, a held shot) a hat put on then stays drawn: in
  Studio Play, respawned under a held camera, the hat's parts sat at 0 and its shell filled the
  bottom of the view (the S5-03b capture). Seen too: after that respawn the PlayerModule never
  hid the new body again, even back in its own camera (HANDOFF's queue).
- **The rule:** `HeadView` (client only, nothing sent) hides your own worn find from your screen
  each frame after the camera: wholly with the camera within `Head.HideNear` (1.5 studs) of your
  head, shown past `Head.HideFar` (3), eased between and over time (`Head.fade`, about a fifth of
  a second) so it never pops as the camera leaves your head; never less hidden than your head is,
  so a view that hides your whole body hides the hat with it. Local transparency never touches a
  light, so the lamp still lights the hall; MirrorView's copy keeps its own look, so the mirror
  still shows the hat on you. Tested in `tests/head.spec`; seen in Play (same respawn: the hat's
  parts at 1, both lights on; a fresh Play: nothing over your view, the mirror showing the hat).

## D-283 · 2026-11-17 · The hard hat sits on top of your head, by its rim (F-G1b4a1c)

The mirror showed the worn hard hat at your chin, and so did a third-person camera in Studio Play:
the real weld was low, not the mirror's copy. A find's pivot is its grip, which for the hat is the
crown of its shell, but D-277's fit put that pivot where the rim should go, so the shell sat a
whole hat-height low, its lamp on your mouth (and its brim round your eye before D-282).

- **Sat by its rim.** A fit names its rim part (`HardHat_Shell`); `Slots` measures how far that
  part's lowest edge is below the find's pivot, and `Head.seat` lifts the pivot so the rim lands
  `down` under the top of the head. Tested in `tests/head.spec` (failing first).
- **Grown with your head.** Fits are numbered for a standard 1.2-stud head and scale with yours,
  size and depth alike: seen at head scales 0.8, 1 and 1.5 in Play, the same look each time.
- **Bigger, over your hair** (seen in Play, `docs/art/F-G1b4a-on-head-*.jpg`): at 1.4 the shell
  was 1.25 studs across and the free Pal Hair (1.76) buried it; at 1.7 (1.5 across, a Roblox
  hat's width) it reads as a miner's hard hat from any side, with hair under its brim. Its rim
  sits 0.3 under the top of the head, the brim level over the brow. The owner's look waits on
  OWNER.md.
- Your own view stays clear (D-282's `HeadView`, seen: every worn part hidden at the eye).

## D-284 · 2026-11-17 · The shelf: oak behind the rug, and finds kept land on its spots in the save (S5-03c1a)

The plan's ideas 6 to 8 (every find carried aboard comes home; new finds wait sparkling; the shelf
is what's on show). Precedents: Animal Crossing's museum and house storage, Lethal Company's ship
shelf, Fortnite's locker marking what's new until you've looked.

- **The shelf is oak with a cream painted back**, not the plan's steel storage shelf: D-263 keeps
  the climb's steel out of the home. Six cubbies (three across, two up) on short legs, 7.5 studs
  wide and 5.5 tall, 384 triangles in the Wood and Plaster sets (`art/home/furnish.py`).
- **It stands behind the rug, facing the door** (my default, `OWNER.md`), the first thing you see
  as your door goes up. The plan has it on the back wall; the homes are the XL slot until the
  sizes come (S5-03h), so the small unit's back partition goes right behind it then.
- **The save keeps the shelf (version 5):** each spot's find by name ("" for empty) and how new it
  is: seen, new, or a kind you'd never owned (`Save.Fresh`). The shelf shows finds you own, so a
  find on it is counted in `finds` too; up to 24 spots, the XL unit's.
- **A find lands as it's kept at the gate** (`Save.keep`): the moment it's yours it takes the
  first empty spot, a kind stamped just now marked to chime. A full shelf leaves it in `finds`
  alone, for the job box (S5-03c2). So the shelf fills during the climb and is there, sparkling,
  when you get home, with nothing to press.
- **Split** (context): c1a this; c1b the finds standing on the shelf, sparkle, chime and turn, the
  server checking you're near before it marks one seen, seen in Studio Play; c2 the job box and
  its panel; c3 selling and Gold.


## D-285 · 2026-11-17 · Finds stand on the shelf and sparkle till you walk up (S5-03c1b)

The plan's ideas 6 to 8 (D-284) made visible: your door goes up after a climb and what you brought
home stands on your shelf, sparkling. Precedents: Animal Crossing's museum, Fortnite's locker marks.

- **The server stands every find** (`Shelves`): each spot of the save's `shelf` gets a copy of its
  find, inert and still, in the cubby, when the save loads, when you're handed a home, and each
  time a gate keeps finds for you (so it's there when you ride home). Every screen sees it; a
  visitor sees your shelf too. It goes when you leave.
- **Fitted, never grown** (`Home/Shelf.fit`, tested): shrunk to the cubby's room, square to the
  shelf, or turned a quarter when that lets a long thing lying deep stand bigger. Small finds (the
  windup mouse) stay small: true to size reads better than a row of equal blobs.
- **Its lights are off and its sounds gone**: a find on a shelf isn't switched on, and a phone's
  real lights are few.
- **New finds twinkle** at 3 glints a second, 0.5 studs: 1.4 and 0.32 were lost from the door in
  Studio. Walking up within 7 studs (looked for every 0.2 s) plays the answer: New a soft tink
  (the coin chink pitched up, quiet), Kind the box reveal's falling twinkles, one 1.8 s eased turn
  and a small "New" (warm white, clay edge) that pops, holds 2.4 s and fades.
- **The server checks the walk-up** (`ShelfSeen`): type and range, a new find of yours on that
  spot, your root within 11 studs (reach plus slack), Brix's bucket limit (4 a second, 8 at once).
  Seen isn't written at once; the autosave and the leave flush keep it (a lost one only sparkles
  again).
- **A Studio-only test hook** (`ServerStorage.ShelfTest`, as CatchTest is): keeps a find for a
  player as a gate does, so a test sees it land without a climb.

## D-286 · 2026-11-17 · The boombox plays and the teddy hugs: a press on a one-mesh find (F-G1e5a, V5a)

- **The moment.** You press Play: the key clacks down, then loud 80s electro booms out, the case
  thumping on every beat and swaying from its handle in your fist, and every monster on the floor
  comes to look, wherever you carry it or leave it; 15 seconds on the stop key clacks. You hug
  the teddy: it squashes in your arms with a tiny muffled squeak and wiggles back.
- **Precedents.** The boombox: the catalog's R.E.P.O. music box, through the cymbal monkey's lure
  (D-233): heard as far as the air horn (130 studs) every 2 seconds while it plays, a toy that
  takes no press mid-song; the case pulsing with its music, as Fortnite's Boom Box does. The
  teddy: the squishies' Squeeze (V1), quiet.
- **One-mesh presses are written by hand** in `Finds/OneMesh`, as the bedroom set's catalog rows
  are (PIPELINE.md "Not here"): each find's pivot (its grip), its motions on its one mesh in the
  kit's key format, and its press. `Finds.art` makes each a one-part find (its size from Specs),
  so `Use`, `FindUses`, `FindUseView`, `Pose` and `Finds.joints`/`shift`/`grip` play it unchanged;
  `Tools`' template records where the mesh was drawn (`Finds.pose`, its pivot set to the bottom's
  middle for that one call). The squash and swell show about the mesh's middle (V1b's root
  sizing), the sway and hop by moving the grip (V3c's carry). Pivots are plain numbers so Lune
  reads the module.
- **The song: APM's "Electroboogie"** (1842805228), from 8.04 s (a kick at 8.06), 113 beats a
  minute measured in Play: the motion is two beats (0.532 s each) and the song runs 28 beats, so
  it stops on a beat and the case comes to rest. Its length is 0.35 s short because `Tools.play`
  lets a sound run half a second past it: cut under the stop key's clack (finduse.spec holds it).
- **A tune is joined where it is** (`Use.join`, `Use.started`, `JoinLong` 2 s, `JoinLeft` 0.5 s):
  dropping a find parents it to nothing for a moment, so every screen gets a new copy and a sound
  under the old one dies; and a find walked up to mid-press was silent. Now a step sound of 2 s
  or more (a tune: the song, the carousel's, the siren's wail) is joined from where it is now for
  a find first seen part way through; a click never is. Seen in Play: dropped 2.5 s in, the song
  carried on from 10.6 s in its recording.


## D-287 · 2026-11-17 · The job box: a calm steel box that takes what the shelf can't (S5-03c2a1)

The home doc's idea 9 (one box holds every find you own) and idea 7 (its lid sparkles when finds
went in). Precedents: Resident Evil's item box, Animal Crossing's house storage, Fortnite's locker
marks (what's new shows until you look).

- **The look (D-263):** a job-site box, as the doc says, but powder-coated a dusty blue
  (`#6A8A93`, the Plaster set's stipple reads as powder coat), on two oak runners, graphite
  handles, hasp and piano hinge: calm beside the sage and the clay door, and the gold sparkle reads
  on it. 4.4 studs long, 2.2 deep, 2.7 tall with its lid; four parts (body, lid, fittings,
  runners), 1,588 triangles. The body is an open chest and the lid a tray, so an open box shows a
  real inside and a real edge.
- **Where (my default, `OWNER.md`):** against the left wall as you walk in, beside the shelf,
  facing the room; its back 0.8 studs off the wall so its lid opens to 88 degrees clear of it.
- **The save (version 6):** `boxFresh`, how new what went into the box since you last opened it is
  (Save.Fresh). `Save.keep` raises it when the shelf is full; `Save.open` clears it and says what
  it was, so opening on a kind you'd never owned chimes.
- **The server (`JobBoxes`) owns two attributes on the box:** `Fresh` (from the holder's save,
  following each of Shelves' lays through its new `laid` signal) and `Lid` (0 shut; up, 1 plus
  what it found: one attribute, so no screen sees the lid up without it). Open (E) is the holder's
  alone, as the switch is, and turns to Close; the lid shuts when the holder walks 14 studs away,
  leaves, or the home changes hands.
- **Every screen (`JobBoxView`):** the lid swings about its hinge (`JobBox.angle`, tested): up over
  1.1 s eased, with Pro Sound Effects' heavy metal creak quiet and a touch higher; down falling
  over 0.42 s with a mailbox flap's clack pitched to a heavier lid and a 2.5-degree kick. The
  shelf's twinkle spreads over the lid while something new is in it and bursts off as it opens.
- **The ceiling (the owner wanted it warm):** the home bulb's PointLight met the plaster ceiling
  edge-on from the lamp's glass and left it near black past the lamp. It now hangs 3 studs under
  the lamp (`UnitLight.Home.Drop`), so the ceiling catches it. Untested in Studio.
- **Split** (context): c2a1 this, passing checks; c2a2 the upload, import and Studio Play check.


## D-288 · 2026-11-17 · The carousel's tune slows as its spring runs down, keeping its pitch (F-G1e5f, V5f)

- **The moment.** You wind the tin carousel and it turns and plays; over its last six seconds the
  top slows and the tune slows with it, note by note, at the same pitch, the last note dying away
  as the top stops. You hear the lure ending before you see it.
- **Precedent.** The verb is the catalog's Wind (R.E.P.O.'s music box, the monkey's lure, D-233);
  the slowing is how a real music box runs down: the cylinder turns slower, the comb's teeth keep
  their pitch. The art's top already turned down on that curve (`RIDE`).
- **How.** No recording of a box running down turned up (`search_asset`), so a tempo change that
  keeps the pitch. A step's sound may carry `slows = { at, stop, fade }` (`Finds/Game`): full
  speed to `at`, then (1 - s) ^ `fade` to nothing at `stop`, the art spec's own numbers
  (`slowing(CAROUSEL_TUNE, RIDE[...])` in `windups/spec.py`, so one source); its length is what
  of the recording that plays (`Use.through`), 12.0 s over 15.5. The client steps it each frame
  while it plays (`FindUseView`'s `slowing`): `PlaybackSpeed` at the pace (`Use.pace`), two
  `PitchShiftSoundEffect`s (each up to an octave) hold its pitch down to `Use.SlowHeld` (a
  quarter speed), and below that it fades as it slows. Nothing else is stepped.
- **Joined part way** (`Use.join`): the tune's place in the recording by `through`, its slowing
  shifted to its own clock. A drop can carry your own copy from hand to floor as the same model
  (seen in Play), so its tune plays on; a tune already playing on the find is never joined again
  (this also kept the boombox's song from doubling).
- **Untested by ear:** the shifters' quality at two octaves (OWNER.md, the wind-ups' feel test).

## D-289 The Old lamp holds a Mannequin wherever it lies, for good, with no press (F-G1e5d, Nov 17)

The moment: deep in the climb you find the Old lamp standing lit in a unit, and a Mannequin that
comes for you stops dead at the edge of its pool; carry it and set it down behind you, and it
holds one there as long as you like. Found lights hold a Mannequin (D-188, D-234; SCP-173 and
Five Nights at Freddy's, as the hall lights do), and this one never runs down (the catalog).
- **Lit is now a row's word, not only a press's stamp.** The lamp has no press (D-229), so it
  never carries `UseKey` or a stamp. Its game row says `lit=True` (art spec, generated into
  `Finds/Rows`; the export refuses `lit` with a press), `Use.FoundLit` lists it, and
  `Use.lampUntil(key, stamp)` gives `math.huge` for it and the press's stamp for every other
  find. `Keepers`' `lampOf` reads it, naming a never-pressed find by its `Tool` attribute.
- **Reach and shade are D-234's:** its widest point light (10) times `LightShare`, 8 studs, along
  the map's clear line. In a hand it still holds nothing (D-234's default, OWNER.md's question).
- Every screen already shows it lit at rest (its `Switch` motion's first key glows), so nothing
  changes on screen: only that the Mannequin now obeys what players see.
Seen in Studio Play: dropped in floor 1's hall, its clank woke a Mannequin 17 studs off, which
came and froze 8.0 studs from it ("freezes in the light of a find on the floor"), held 50 s with
nobody near, and held again while hunting the player from 12.6 studs.

## D-290 · 2026-11-17 · The job box seen in Studio; its home keeps the c2a1 layout (S5-03c2a2)

- **Seen in Play** (one player, Studio): with the shelf full, a kept find twinkles faintly on the
  lid, seen from the doorway; Open eases the lid to 88 degrees in 1.1 s, clear of the wall, with
  the creak, the shelf's chime for a kind never owned, and the twinkle bursting off; Close drops
  it in 0.42 s with the clunk on the landing and a 2.4-degree kick; the lid stays up at 10 studs
  and shuts 0.43 s after its holder passes 14; Stop and Play finds it quiet. The sounds are the
  owner's to hear (`OWNER.md`).
- **The ceiling is warm now:** `UnitLight.Home.Drop` 3 lights the plaster ceiling cream all the
  way past the lamp; Range and the UnitTops paint stay as they were.
- **The import needs a fresh Home module:** the first import ran `prepare` from the MCP's cached
  copy, which knew no job box, so the box came in grey, unanchored and solid and was knocked about
  in Play. Re-imported from a clone (`docs/STUDIO.md`, `art/home/README.md`).
- **The layout stays** (D-287's default): from the door the floor lamp's pole crosses the box's
  right end, but it stands 2.5 studs to the side, never in the way of a player opening it.
- **Found, queued:** faces turned from the home bulb go near black (the shelf's end and back,
  seen from the box): the room needs a warm fill to be the calm place D-263 asks for.
- **Split:** the panel is two pieces, c2b1 looking through it and c2b2 taking a find out.

## D-291 · 2026-11-17 · The job box's panel rides the lid: every find you own, a kind a card (S5-03c2b1)

The home doc's idea 9: press the box, the lid creaks up and a panel slides in with each kind you
own shown once with how many, a search box and rarity filters. Precedents: Resident Evil's item
box, Animal Crossing's house storage, Pet Simulator's inventory (rarest first, search, rarity
filters).
- **It rides the lid.** The server sends the holder the box and their finds (`JobBoxList`) as it
  sets the lid up, once. The panel rises over the lid's 1.1 s on the lid's own curve (the lid's
  `(1 - cos)/2` is Sine in-out), and falls on the lid's curve when `Lid` goes to 0 for any reason
  (Quad in over `JobBox.landing` of how far the lid had risen), gone as the clunk lands. Its X and
  a tap outside ask `JobBoxClose` (nothing carried, rate-limited, the asker's own open box only):
  the panel waits for the lid rather than leaving before it.
- **The cards (my defaults, OWNER.md):** the find as your slots draw it (ToolPicture), its rim and a
  faint wash in its rarity's colour (Grades.Colours), its name, x2 for two or more; rarest first,
  then by name. Dealt in as the panel rises (all within 0.6 s), re-dealt in a quick ripple when a
  search or chip narrows them, so a narrowing never snaps.
- **Search and chips:** the search ignores case, spaces and dashes ("night light" finds the
  Night-light), 24 characters; chips are All plus only the rarities you own, so a chip never
  shows an empty panel; the lit chip tapped again goes back to All. "No match" and "Empty" are the
  only words beyond the chips.
- **The look (D-263):** the box's own dusty blue, deepened, with the lobby's cream ink: the panel
  reads as the box's inside. 76% of the screen's height (257 points on a Galaxy A16), so the
  raised lid shows above it.
- **Seen in Studio Play** at computer size (1380x761): 18 kinds, four chips, "lamp" left the two
  lamps, the X dropped it with the lid. The phone check is the owner's (OWNER.md).

## D-292 · 2026-11-17 · The glow sticks crack one stick a press, three to a bundle (F-G1e5b)
- **The catalog's line:** "Crack: one stick lights a small spot for the rest of the floor; three
  to a bundle." Each press cracks the next stick in the band and it stays lit for good, as the
  first did (DOORS' lighter, a light used again; the catalog's Crack is a Switch on). No stick is
  handed out: the bundle stays one find, its worth unchanged.
- **The press that counts:** a light's row can carry `more` (steps), each later press playing the
  next once the last one's motions are over; the stamp carries `count` (the `UseCount`
  attribute, 1 to 16, anything else read as the first). `Use.press` returns it; the server writes
  it before `UseAt`. `rows.py` refuses `more` with `off`, `reset`, `toy` or `lasts`.
- **The art:** the bottom two sticks are split at their middles like the top one; each kinks
  outwards about its outer side (the band holds their cap ends), snaps at 34 degrees and is
  shaken, the wags dying away while the light pulses up. The first crack keeps its motion.
- **The light:** each stick its own small point light (0.7, then 0.25 and 0.25, range 7), so all
  three stay a small glow; its Mannequin reach is unchanged (the widest range). A screen lights
  only its nearest few finds.
- **The sound:** every crack snaps (Pro Sound Effects' "Plastic Crack 2", from 0.1 s, its crack
  at 0.13 s, pitch 1.35, the third 1.25); the second and third slosh as they're shaken (`SLOSH`,
  short, soft, 1.7). The first crack had no sound before.


## D-293 · 2026-11-17 · A find out of the job box stays yours in the save, and no gate keeps it twice (S5-03c2b2a)

The home doc's idea 9 ("from the panel you put a find in your hands") and the start of idea 10.
Precedents: Resident Evil's item box (the box and what you carry side by side; take out only what
you need), Animal Crossing's house storage, Pet Simulator's inventory.
- **What's in the box is what you own, less the shelf's and what's out** (`Save.boxed`). The panel
  lists that now, not every find you own (D-291 listed all of `finds`): a find on the shelf or in
  your hands isn't in the box. What may come out is exactly what's in it, so nothing ever comes
  out past what you own (Lune specs: ten asks take out the three owned).
- **Taking one out never writes the save.** A find in your hands at home is still counted in
  `finds`; Slots marks it with whose box it came from (`unbox`), and what's out is counted from
  those live finds (`fromBox`), never stored. So a crash or a failed save can't lose or double
  one: a find out of the box that's destroyed for any reason (a floor cleared, a leave) is simply
  back in the box.
- **No gate keeps a find from a job box** (`Slots.keep` skips it): it stays in whoever's slots it
  is in, so carrying your own find aboard can never add a second to your save, and a friend
  carrying it can't take it into theirs. S5-03d builds the climb's risk on top (out until the
  climb ends, struck off only when lost on a climb that ended properly).
- **Its owner leaving takes it back** (`recall`): out of anyone's hands or head, or off the floor,
  in a glint. One set down by its system, with a piece out or in a monster's arms is left to its
  system (the floor clearing returns it).
- **Shelf moves one from the box to the first free cubby**, seen (you put it there), laid at once;
  the autosave keeps it, and a crash before that only leaves it in the box.
- **The screen (my defaults, OWNER.md):** tap a card, it lifts (1.08) and its rim lights; Take, and
  Shelf while a cubby is free, sit over its name. Your three hands sit over the panel's corner as
  round wells, drawn from your slots, so you see where it goes. The picture rises off the card the
  moment you press, then flies in a bow (0.42 s) into the hand the server put it in, which pops
  with the find's own pick-up sound; your view holds the find back until it lands (InFlight). Shelf
  flies it up toward the cubby with the shelf's tink. The count ticks down; the last one's card
  shrinks away. Hands full: the hands shake, nothing is asked. A refused take settles back onto its
  card. No words.
- **Split** (context): c2b2a this, built and green; c2b2b sees it in Studio Play and captures it.

## D-294 · 2026-11-17 · The fairy lights lay out along the floor when set down lit (F-G1e5c)
- **The catalog's line:** "Switch on: lay them along a hall for a dim line of light", and its
  Switch row: "Set it down lit and it lights the space round it." So the press stays a switch in
  your hand, and setting them down lit (the drop) is what lays them: no second word. Precedent:
  Minecraft's torches laid along a tunnel to light the way, with the game's own rule that light
  stops a Mannequin.
- **Where it runs:** away from whoever let it go (a player within 8 studs: dropped ahead of you
  it runs on ahead; dropped at your heels as you run, back down the hall behind you), else its
  own facing. Ten ways are tried, ahead first (`Strand.Ways`); the first within 85% of the
  longest clear run wins (`Strand.pick`), so in a hall it runs along the hall, and boxed in under
  1.5 studs it lies as the coil. It stops 0.3 short of a wall and where the floor falls away.
  The server decides (`FindUses.layStrand`, on `Slots.loose`) and tags it `LaidStrand` with its
  two ends and the time; lifted, carried off or gone, it's the coil again, still lit.
- **The hold:** points along the line no more than 4 studs apart, each holding a Mannequin 4
  studs round (`Strand.Reach`, under half a lamp's), added to the floor's lamps beside the box's
  own hold (`Keepers.tellLying`). A dim light, but it fills most of a hall's width.
- **The look, cheap on phones:** every screen draws it in a folder of its own (`StrandView`):
  the art's twenty LEDs (0.4 apart) as small neon drops that glow with no light of their own,
  the copper wire as beams between them, lying in a lazy wave (`Strand.sway`), one dim real
  light 70% along (range 7, brightness 0.55; the coil's own still lights the box end), the coil
  hidden. Just laid, it runs out over 0.6 s with the rustle played lower (`lays.sound`); a
  string seen later is drawn whole, in silence.
- **The row:** a press can carry `lays = { length, sound }` (`rows.py` refuses it with `toy`,
  `down` or `lasts`); the fairy lights' is 8 studs, the art's twenty LEDs 0.4 apart.
- **Defaults for the owner (OWNER.md):** the length, the reach, and that it runs away from you.

## D-295 · 2026-11-17 · Taking a find out, seen in Studio: the hand waits for the find to land (S5-03c2b2b)
- **Seen in Studio Play** at computer size (1380x761), the cards and verbs clicked for real with
  the Studio MCP's `user_mouse_input` on their instance paths: the pick, Take into a hand (x7 to
  x6), the last one's card leaving, Shelf to a free cubby, hands full asking nothing, the find in
  your hand after Close. Asks fired from the Client for a find you don't own, or have none of
  left in the box, are answered no and change nothing; wrong types get no answer. A rejoin found
  every find out of the box back in it. The sounds weren't heard (OWNER.md).
- **The hand waits for its find.** The server fills your slot just before it answers the take,
  so the hand drew the find before its picture had flown there, spoiling the landing. An empty
  hand whose new find matches a take still waiting stays empty until the picture lands in it;
  a take refused or given up redraws the hands from your slots.
- **A cubby can be emptied in Studio** for a test: `ShelfTest:Invoke(player, "", i)` puts cubby
  `i`'s find back in the box (server-side, Studio only).

## D-296 · 2026-11-17 · Fragile finds crack once when dropped hard, worth half (F-G1e5e)
As R.E.P.O.'s valuables. "Hard" is the server's own measure as you let go: your body's speed
(10 studs a second, two thirds of the walk) or the fall from your hand to the floor (4.5 studs);
the same for everything dropped where you're caught. The crack is a code-drawn picture on the
glass part the row names (two Decals, no art rebuild) and a short glass crack over the clank;
nothing on screen explains it. The save counts cracked finds per name (`chipped`, version 7,
never more than you keep), since finds are kept by name; which of two is the cracked one isn't
tracked. A find out of your job box doesn't crack yet (its save is the home chain's): waits on
S5-03. Selling (S5-03c3) reads `chipped` and `Chip.worth`.

## D-297 · 2026-11-17 · Selling from the job box: its catalog worth, paid and struck in one step (S5-03c3a)

The home doc's idea 9 ("from the panel you ... sell it") and D-251 ("sell whatever you want").
Precedents: Pet Simulator's sell from the inventory, Animal Crossing's Nook box (sell from what
you hold, the bells counted out), Bloxburg's sell button that shows its price.
- **The price is the find's catalog worth** (`BoxPanel.price`): the item catalog's value, the
  number the Packrat weighs (`Carry.worth`); with none, its grade's least (`Grades.Worth`); whole,
  1 at least, 12000 at most. The climb's coins aren't involved: D-251 moved a find's cash to the
  box.
- **The server sells, in one step** (`BoxPanel.sell`): Sell is the take's third way on
  `JobBoxTake`, through the same checks and rate limit (now 4 a second, 5 at once). Only one in
  the box sells (`Save.boxed`): never the shelf's or one out in someone's hands. One comes off
  `finds` (the name gone at none) and the price goes on `cash` in the same step, so any save ever
  written holds both or neither: never paid twice, never a find lost on a failed write. The answer
  on `JobBoxTook` carries the new cash.
- **One write per run of sales:** the save is written `BoxPanel.SellSave` (6) seconds after the
  first sale of a run (a DataStore key takes a write in six seconds); the autosave, a leave and a
  shutdown write it too. A crash in between undoes the whole sale.
- **The screen (my defaults, OWNER.md):** your cash sits over the panel's top right corner, as
  your hands sit over its left, sent as the box opens. The picked card shows a gold "Sell $22"
  over Take and Shelf (two rows: three side by side don't fit a phone's card). Pressed, the picture
  lifts, flies in a bow into your cash and fades; the cash chinks (the coins' chink) and counts up
  as the results board's does (Cash's curve, rising ticks, a swell and a jingle). The count ticks
  down; the last one's card shrinks away.
- **A tap guard** (found in Play): after a card leaves, the next slides under your thumb, so a
  mashed Sell picked it and the next tap would have sold it. Taps on cards wait 0.6 s after a card
  leaves, and each tap in that time starts the wait again (`BoxPanel.Guard`).
- **Cracked finds** (D-296, committed by the find run as this was built): a sale doesn't read
  `chipped` yet; S5-03c3a2 sells a cracked one first, at half, one off `chipped`.

## D-298 · 2026-11-17 · Four make a Gold: a name of its own in the save, made in one step (S5-03c3b1)

D-188 and D-251 ("with four of one kind, the panel offers to make it Gold: a big animation").
Precedent: Pet Simulator's golden machine (copies of one pet make its golden one). The item
catalog's variant table: solid gold that catches any light, worth five times, every find but the
Secrets.
- **Kept as a name of its own in `finds`**: the find's name with ":Gold" after it ("Teddy:Gold",
  `Home/Gold`). The save's shape is unchanged (no version 8), and the box, the shelf and the book
  count it as any find. Its catalog row is its find's (`Gold.base`); the gold is drawn
  (ToolPicture gilds the model: textures off, gold Metal) and priced (`BoxPanel.price`, x5).
- **Made in one step** (`BoxPanel.gold`): Gold is the take's fourth way on `JobBoxTake`, same
  checks and limit. Four of it in the box (never the shelf's or one out) come off `finds`, one
  Gold goes on, and its book page is stamped the first time, together; written as a sale is
  (`SellSave`). A Gold of a Gold, or of a Secret, is refused.
- **Cracked ones go in first** (my default, OWNER.md): `chipped` drops by up to four, so it never
  tops `finds`, and a gold made of cracked lamps is whole.
- **Its card sits just before its find's** (sorted by the find's name), so the new card is dealt
  beside the four. A Gold only sells for now (Take and Shelf hidden on its card, refused by the
  server) until S5-03c3b3.

## D-299 · 2026-11-17 · Four make a Gold: the show plays at once, the flash waits on the server (S5-03c3b2)

The owner asked for "a big animation" when four become a Gold (D-251). Precedents: Pet
Simulator's golden machine (copies drawn together into one gold pet) and every gacha reveal's
build to a flash (the job box's own Legendary reveal, `Boxes.Reveal`).
- **Gold is a third verb over Sell** on a card with four or more that can be made Gold, filled gold
  with a slow white shine crossing it, so it reads as the special one. A Gold's card gets a gold
  rim instead of its rarity's.
- **The show starts on the press, the flash waits on the answer**: the four leave the card and swirl
  for about two seconds while the server answers (it always has by then). Made: the flash and the
  Gold. Refused, or no answer by the flash: the four fly back onto their card, quietly. An answer
  after that is counted at once with no show.
- **The sounds are the reveal's Legendary set**, timed so the rattle and the rising tone are
  loudest at the flash, the falling twinkles at the flash with the coins' jingle; each copy lands
  on the ring with a chink a step higher. No new sound assets.
- **Everything over the panel is one veil** that swallows taps for the whole show, so no card can
  be picked mid-swirl. The panel closing ends the show where it is.
- Feel numbers in `Home/Gold`'s `Show`; about 3.5 s in all (swirl 2 s, hold 0.9 s, flight 0.4 s).


## D-300 · 2026-11-17 · A Gold is carried as its find with a gold mark, gilded everywhere (S5-03c3b3)

D-251 and D-298: a Gold is a find of yours like any other, so it comes out to your hand and your
shelf. Precedent: Pet Simulator's golden pets, which you equip and show off as you do the plain
ones; the item catalog's "solid gold that catches any light".
- **Its key in your slots stays its find's** ("Teddy"), with a gold mark beside it: on the
  server's carried thing (`gold`) and on the player (`Gold.slotAttribute(i)`, set before the key
  and cleared after it, so no screen draws it plain for a moment). Every catalog row, model,
  sound, verb (Hug) and weight is the find's untouched, so no other system had to learn the
  ":Gold" name. Only the save's counts use it: `fromBox` and `keep` name it "Teddy:Gold".
- **Gilded wherever it's drawn, one way** (`Gold.gild`, shared): textures off, one gold Metal.
  The server gilds its own model, so a friend sees it gold in your hand, on the floor or on your
  head; your own view's copy, your slot wheel, the panel's hands and the shelf gild theirs.
- **Solid gold never cracks** (my default, OWNER.md): a fragile find's Gold lands whole.
- **Its card shows Take and Shelf** as any find's; only Gold (a Gold of a Gold) is refused.
- **Kept at the gate as a Gold**: `keep` names it so. Today it never is (one out of your box is
  never kept, D-293); taking finds up (S5-03d) gets it for free.

## D-301 · 2026-11-17 · A cracked find sells first, at half, and Sell says so (S5-03c3a2)

D-296 and D-297. Precedent: R.E.P.O.'s valuables, whose price drops on screen once they're hit.
- **Cracked first** (`BoxPanel.sell`): the save counts cracked finds by name (`chipped`), not
  which one is cracked, so a name with cracked ones sells a cracked one first, at half
  (`Chip.worth`), one off `chipped` (never more than what's left). The whole ones then sell at
  full. A Gold makes from cracked ones first too (D-298), so the cracked ones are the box's:
  one taken out to your hands or the shelf is whole (D-296).
- **The price on Sell is the next one's**: the box sends how many of each name in it are cracked
  as it opens (`BoxPanel.cracked`: never more than the box holds); the screen counts them off
  after each answer (`BoxPanel.crackedLeft`: a sale one, a Gold four, a take none) and less the
  sales still asked, so "Sell $9" turns "Sell $18" once the cracked one is gone. Nothing else
  says why: the half price is the lesson.
- **A Studio-only hook** (`ServerStorage.StudioCrack`, a BindableFunction made only in Studio,
  never a remote): Invoke(player, name) cracks one of a find in that player's save as a climb's
  gate does (`Save.chip`), so a cracked sale is tested without a climb.

## D-302 · 2026-11-17 · Taking finds up: the save changes only at a proper end, and never doubles (S5-03d1)

D-251 ("a find taken out stays in the save, marked out, until its climb ends; it's struck off only
when it was lost on a climb that ended properly") and D-293 (what's out is counted live, never
stored). Precedents: Minecraft (what you carry drops where you die) and Lethal Company (gear left
where a crewmate died stays on the moon unless someone carries it back).
- **No save field for "out"**: a find out of your box is already counted live from the finds
  themselves (D-293), so the save keeps it all climb and no new save version is needed. A crash or
  a shutdown settles nothing: you come back to it in your box.
- **The save changes only at an end the server sees** (`Home.Taken.settle`), written at once:
  carried aboard by you, nothing (it stays in your hands, at risk on the next floor too); carried
  aboard by a friend, kept into their save as any find and struck off yours (`Save.lose`) in the
  same moment, so the two saves hold one between them; never carried aboard and left behind on a
  floor the climb leaves, or on a climb that's over, struck off yours; back in your box at home,
  nothing struck.
- **Leaving mid-climb loses it** (my default, OWNER.md): struck off as you leave, and a friend who
  carries it aboard keeps it as a find of their own. Otherwise leaving would save a find from a
  bad climb.
- **A crack it takes on the climb comes home with it** (D-296): into the save of whoever has it
  at the end. Losing a whole one leaves your cracked count alone, never above what you own.
- **Known edge:** the friend's keep and your strike are two saves' writes; a crash between them
  could leave both holding it. Both are written in the same server step, so the window is tiny.
- **Split** (context): d1 these rules, pure and tested; d2 wires them in Slots and GatePay; d3
  sees it in Studio Play.

## D-303 · 2026-11-17 · Colour where you pressed: a tint mask in the skin, not a second shell (S2a)

- **The moment:** you squeeze the colour-change goo ball and your fingerprints bloom orchid on its
  sky-blue skin, then slowly cool back to blue (the catalog: "changes colour where your fingers
  pressed"; the real heat-reactive goo balls do it with your hand's warmth).
- **How:** the ball's one skinned MeshPart keeps its own SurfaceAppearance in AlphaMode TintMask.
  The colour map's alpha holds five finger-shaped prints where the squeeze's fingers dent it;
  those texels are baked lighter by exactly what the rest tint takes off, so as found the ball is
  plain blue, and the game tweens `SurfaceAppearance.Color` from Rest to Warm by the Squeeze's
  `tint` track (kit.Find `tint`; Finds' `shine` writes it each frame of the press, as it writes
  glow). Verified in Studio (STUDIO.md, "Colour where pressed").
- **Why not the others:** a second shell over the skin doubles the triangles, needs the same
  bones and draws in the transparent pass; Decals project flat and don't follow bones;
  EditableImage painting needs the place's API setting, memory on low-end phones and a per-frame
  upload. The tint is one Color3 a frame for the press's few seconds, no new parts.
- **The fade is 4.6 s** (the whole press 6.6 s): a toy is pressed again only once its press is
  over (`Use.toy`), so a longer fade kept you waiting to squeeze again. A re-squeeze that warms
  it mid-fade is ROADMAP polish.
- **Colours:** sky blue to orchid, a real pair's look (blue to pink) kept clear of the goo ball's
  neon pink. Built, not yet seen in Play: S2b imports it (the alpha must survive the FBX upload:
  check the template's ColorMap tints only the prints) and plays it.
- **S2b (Nov 17): the prints are fingertips.** S2a's long capsules with joint creases read as
  hard bars; each print is now an oval fingertip, leaning a little, warmed all the way in its
  middle and feathered out to nothing, with a faint halo and a ragged edge, as a real
  thermochromic handprint is. Strongest in the middle, so as the one tint cools the print seems
  to shrink toward where the finger pressed hardest. The alpha survived the upload; seen in Play.


## D-304 · 2026-11-17 · Taking finds up, wired: up as you ride into floor 1, settled where it ends (S5-03d2)

D-302's rules, wired on the server. Precedents as D-302: Minecraft and Lethal Company.
- **A find out of a job box goes up as its holder rides a lobby car into floor 1** (Climbs'
  `board` calls `Slots:up` for each rider carried). Only then can it be lost: a find out of the
  box that never went up is back in the box whatever happens to it (D-293), so a save is struck
  only for a find the climb really had.
- **Every end reaches one place.** Slots' `taken` fires Lost as a taken-up find goes for good
  (cleared with a floor the climb leaves or with the climb's end, its piece gone with a floor,
  used up, spent) and Back as one goes back into its owner's box at home (`recall`, bringing its
  crack). A gate's end comes from `keep`: its owner's own stays in their slots; a friend's comes
  back apart (`Moved`) and rises out of the rider's slot as any kept find. GatePay settles each
  through `Home.Taken.settle` and writes every touched save at once.
- **Its owner leaving mid-climb:** each of theirs that went up is struck off as they go and its
  mark cleared where it is, so a friend who carries it aboard keeps it as any find. Their save is
  let go in that same frame, so Saving keeps it reachable a moment longer (`leaving`): the let-go's
  last write reads the data only after the store answers, so a strike made in that frame rides
  in it. Studio's in-memory store (no API access) may write first: such a strike can miss there.
- **A server stopping settles nothing:** GatePay stops listening as the server closes and settles
  a step later (`task.defer`) behind a `closing` flag. Known edge: a shutdown whose kicks land
  before the server's close begins looks like everyone leaving mid-climb; untested, OWNER.md.
- **Known edges, safe side:** a taken-up find in a monster's arms when its floor goes is never
  settled, so it stays in its owner's save. A friend's find carried aboard while the rider's save
  hasn't loaded is held for them (as any kept find) and struck off its owner's at once.
- **Not yet across a trip:** a live climb runs on a server of its own (L-08e1c), and the
  teleport carries nothing, so on a live server what you take up is back in your box as you
  leave the lobby. Carrying it across is S5-03d4; Studio (and a lobby's fallback) climb on the
  same server, where all of this runs.

## D-305 · 2026-11-17 · A taken-up find settles on the server's next step, so a stop never costs one (S5-03d3)

Seen in Studio Play (one player): taking a find up, keeping it at a gate, losing it with a floor
and a rejoin all did what D-302 and D-304 say. One thing didn't: Studio's Stop, mid-climb, struck
a taken-up find (Skates 3 to 2). Stop removes every player first (PlayerRemoving), then begins
the close 0.1 s later with no Heartbeat between, so a settle put off with `task.defer` ran before
GatePay heard the close and struck the find as if its owner had left. That is D-304's flagged
edge, and it breaks D-302's rule that a server going down never costs a find.
- **GatePay settles each taken-up find's end on the server's next Heartbeat**, then only if the
  server isn't closing. A stopping server steps no more, so nothing is settled. A real leave on a
  running server settles a frame later, still before the leaver's save is read for its last
  write (the store answers after a frame): a Kick mid-climb in Studio struck the Skates (2 to 1)
  and the let-go wrote it.
- `Enum.PlayerExitReason` can't tell a stop from a leave: Studio gave Unknown, and the enum has
  only Unknown, PlatformKick and CreatorKick.
- **Still open, safe side:** a live server going down might step between kicking players and
  closing; if it did, a taken-up find could be struck. It matters once finds cross to a climb's
  own server (S5-03d4), so that ticket's OWNER.md steps include a live shutdown mid-climb. If a
  store ever answered within a frame, a leaver's strike would miss their last write and they'd
  keep the find (no loss; a friend carrying it aboard would make two).

## D-306 · 2026-11-17 · Arranging is judged by Brix's Placements; the home supplies areas and spots (S5-03e1)

The owner's word (D-252): a system the home needs that Brix lacks is built in Brix, then the pin moves.
- **Built in Brix** as its ENG-26a (`7f25310`): `Brix.Placements.new({ areas, limit })` judges every
  find set out in one unit, and `Brix.PlacementSnap.grid({ step = 0.5, turn = 90 })` and
  `.free({ turn })` settle a find being dragged (idea 13: the grid, and Free for everyone).
- **How the home will use it (e2, e3):** each unit's floor, walls and ceiling are its areas, sized
  from its XL slot and its size; the shelf, the job box and any find with a flat top offer a top
  (idea 14's tabletop). A find's spot (floor, tabletop, wall, ceiling) and footprint come from a
  home file keyed by the find's kind. The limit is 25, 50, 100 and 150 by size (idea 15).
- **Saved:** the save keeps Brix's saved form per player in a new save version. A find that no
  longer fits after an update (its art grew, the unit shrank) is left out on load and is simply back
  in the chest; a form newer than the server reads is never written over.
- **The server's side stays here:** only the unit's holder may move its things (FrontOffice's
  plots), each ask is checked and rate-limited (`Brix.RateLimit.bucket`), and every change is told to
  every client. Brix's adapter for this (its ENG-26b) waits until the game has wired its own.
- Footprints are flat: a tall floor find and a low wall find may cross. Not judged until it shows.

## D-307 · 2026-11-17 · The mega goo ball: 8 in, marbled violet, heard across the floor (S3a)

The catalog's mega goo ball (Epic, 120, "both hands, and a deep squelch that carries").
- **Size:** 200 mm across (7.9 in), the jumbo stress balls sold for both hands (Giggle Zone's 8 in;
  Vat19's 5 in "Giant Stress Ball"): as big as your head, which is the moment.
- **Its look:** acid slime green with violet folded through it in smooth ribbons, as a marbled
  squeeze ball's (Vat19's "Mondo Marble"). Plain green read as a green apple, its fill plug as the
  stem; the violet also says Epic, as most games' rarity colours do. No plug on top.
- **Its squeeze:** the goo ball's builder (now the class `Goo` in `squishies/build.py`) with two
  palms for five fingers, each dent as wide as a palm; slower to close, a heavy wobble back.
- **How far it carries:** `squeeze(s, noisy=True, heard=ACROSS_THE_FLOOR)`, 90 studs, the
  clatter of the chattering teeth and the tin bird, round a corner or two; the duck's squeak is
  60. Its squelch is the goo ball's an octave down, at full volume.
- **Both hands** (built in S3b): the ladder's `bothHands` rule, Lethal Company's two-handed items
  (no switching slots or picking up while it's in your hands), with a hold of its own in your view.

## D-308 · 2026-11-17 · What's set out is saved with the finds; the home's spots and frames (S5-03e2a)

The moment: you set your lava lamp on the job box and it stays, for you and every friend who walks
in, after a rejoin too. Bloxburg's build mode (floor, wall and tabletop items), Animal Crossing's
things on tables.
- **Saved:** save version 8 holds `placed`, Brix's Placements saved form as it is (`form`, rows of
  id, on, x, y, turn), bounded so a broken pose is never stored (x and y within 500, turn within a
  whole turn; the server keeps turns from 0 to 360). A find set out is still yours, in `finds`;
  `Save.boxed` takes it off the job box as it does the shelf's (`Save.settable`: owned less the
  shelf and what's in hands, shared by the box and what's set out), so it's never counted twice.
- **Ids:** a find's name and a number, "Teddy#2", a Gold's "Teddy:Gold#1"; never an area's name.
- **Spots** (`Home/Spots`, the catalog's spot column, kept out of the find run's `Rows.luau`):
  Floor, Tabletop (the default), Wall, Ceiling; a footprint from the art's box (`Finds.box`), across
  by front-to-back, across by up on a wall. My picks, in OWNER.md: the neon sign and the singing
  fish on a wall, the disco ball on the ceiling, the RC car and skates on the floor only; the TV
  and the toy drum offer their tops.
- **The room** is the slot's XL inside box, in the starter set's frame (`face` in `Lobby.lay`:
  `CFrame.lookAt(door, door + out)`, so +Z runs in from the door): Floor, Ceiling, BackWall,
  LeftWall, RightWall (the front wall is the door's), plus ShelfTop and JobBoxTop from the
  starter pieces' top parts (`Home.Specs.Parts`). Until S5-03h builds sizes, everyone arranges
  the whole room they see, at the small unit's limit of 25; a later shrink leaves what no longer
  fits out on load, back in the box.
- **The frames, for e2b and e3:** an area's frame is `CFrame.fromMatrix(origin, across, normal)`;
  its `y` runs along `normal × across`, which is the frame's -Z, so a pose stands at
  `A * CFrame.new(x, 0, -y) * CFrame.Angles(0, rad(turn), 0)` (Brix turns x toward y, the same
  way). A find's own top is that frame lifted by its height (`Spots.topHeight`); a starter
  piece's is its pivot lifted by `furnitureTop`'s height. Turn 0 faces down `y`: toward the door
  on the floor and ceiling, out of the shelf's and job box's fronts. Drawn by its spot, its art's
  box centred on the pose: on a floor or top, upright on the face; on a wall, upright with its
  back to the wall (`fromMatrix(-T.X, -T.Z)`, its box out by half its depth); from the ceiling,
  upright, its top on the ceiling (`fromMatrix(-T.X, -T.Y)`, down by half its height).
- **Loading** trims the saved rows to what you own first (`Spots.owned`), then Brix drops what no
  longer fits; either way it's back in the box. A save whose form is newer than the server reads is
  never written over: that home refuses moves (`notYours`) until the server is updated.
- A find on the job box's lid would hang in the air as the lid opens: in e3 it rides the lid.

## D-309 · 2026-11-17 · The server arranges; the room's own things are in the way (S5-03e2b)

The moment: your lava lamp set on the job box stays, for you and every friend, after a rejoin too.
- **One judge per held home** (`Arranging`): a `Brix.Placements` with the room's areas, the shelf's
  and the job box's tops, and the room's own things placed first as things nothing can overlap
  (`Spots.blocks`): the starter pieces that stand on the floor (the rug lies flat, so finds stand
  on it), the ceiling's round lamp, and the mirror on the right wall and its foot on the floor. My
  pick, so a find is never set inside the shelf or over the mirror. Their ids are the pieces'
  names, never a find's, so they're never saved, moved or put away; the limit is raised by their
  count.
- **Ownership is the asker's home only**: no remote names a unit. A name needs one in your job box
  (`Save.boxed`) and a template; an id must be set out. Rate limit first, then type and range
  (`Spots.ask`), then ownership. Arranged(what, id, refusal) answers; ("", "") after a put away.
  A malformed ask gets no answer (only a cheat or a broken screen sends one).
- **Never lost or doubled:** a find set out stays in `finds`; every change rewrites `placed` in the
  live save at once (the autosave and the leave keep it); a crash loses only the move, never the
  find. Putting away puts what stands on it away first.
- **Drawn** as a hand holds it, gilded for a Gold, anchored, not collidable, but pickable
  (`CanQuery`, for e3's taps), lights off, tagged `Spots.Tag` with its id and owner, in the unit's
  `Placed` folder. Its box is measured from the model (the grip isn't the box's foot); a top's
  height is the drawn box's.
- The unit's frame (`Arranged.face`) is built square rather than with `CFrame.lookAt`: the same
  frame in Roblox, and Lune's `lookAt` flips Z, so the spec checks the real maths.

## D-310 · 2026-11-17 · A find that takes both hands is hugged at your chest (S3b)

The catalog's mega goo ball says "both hands". It is carried as Lethal Company's two-handed
scrap is: while it's in your hands you can't switch slots, pocket it or pick anything up; drop it
first (the ladder's `bothHands` rule, which `Slots`, `ToolView`, `MarkedBoxes` and `Carry` already
obey).
- **As data, once:** the find's game row in its art spec says `bothHands=True`; `rows.py` writes
  it into `Finds/Rows` and `Finds/Game`'s type; `Tools/Catalog`'s kit loop gives such a find
  `bothHands`, a hold low and centred in your view (`BOTH`), and friends see it at your chest
  (`CHEST`, its `shoulder` from the upper torso, its front ahead). Any later two-handed find needs
  only the field.
- **The Packrat leaves it**, as it leaves the ladder (`Carry.worth`): what it takes is what your
  hand can let go of.
- **Not built:** friends' arms round it (ROADMAP polish); the hold judged on a phone (OWNER.md).

## D-311 · 2026-11-17 · The Arrange screen: lift, drag, Place (S5-03e3a1)

The moment: in your unit you tap Arrange, the camera eases up into the corner by the door, a faint
grid on the floor; you slide your lava lamp up out of the tray and it lifts with a whoosh, outlined
white, ticking from square to square under your thumb, green on the job box, red in the shelf;
Place, and it drops with a soft knock and a puff of dust. Bloxburg's build mode, on a phone.
- **One set-up, two judges:** `Home/Arrange.room(unit, slot, pivot, limit)` builds the room's
  `Brix.Placements` (areas, frames, the room's own things placed first) for the server (Arranging)
  and the screen (ArrangeView) alike, so the ghost's green is the server's answer before it's
  asked. The screen loads what's set out from the server's drawn finds: each carries its pose as
  attributes (`PlacedOn`, `PlacedAt` = x, y, turn).
- **The tray** is the server's count of your job box, on a new remote `ArrangeBox` (the screen
  asks as Arrange opens, rate-limited with the others; the server sends it again after every
  move). Rarest first, as the box's panel deals them.
- **Place is a button, not letting go** (my pick, in OWNER.md): with one thumb you can't drag and
  turn at once, so the find stays lifted where you let go, green or red, until Place, Turn, Put
  away or ×. Place does nothing while it's red (no words). A tray card lifts when the finger goes
  up out of the tray; sideways scrolls; a tap drops it on the room's middle.
- **Arranging takes the screen:** touch controls hidden (`GuiService.TouchControlsEnabled`), the
  move keys sunk, the mouse free; the camera Scriptable, eased up and back over 0.7 s. The
  button shows only to the holder standing inside their home, checked four times a second.
- The ghost lands where the server's find will stand and waits (up to 1.5 s) for the drawn find
  to arrive there before it goes, so there's never a gap; no answer in 3 s slides it back.
- Riders stay put while the find under them is dragged and jump when it's set down (ROADMAP polish).

## D-312 · 2026-11-17 · Arrange seen on a phone: the room kept clear (S5-03e3a2)

Seen in Studio Play on the Galaxy A16 (685x338): the moment works (lift out of the tray with a
whoosh, ticks, green on the job box, red in the shelf, Place, a knock), but the screen got in its
own way. What changed:
- **The Arrange button sits top right**, where Done stands while arranging, so the one spot
  opens and closes it. At 0.42 down the right edge its word sat on the torch's switch.
- **The tray slides away while a find is lifted**, and back up when it's set down or let go: the
  tray hid the near third of the floor. **The verbs are a corner cluster** under the right thumb
  (Place where the jump button sits, Turn above it, Put away beside Place, × beside Turn), not a
  row across the room's middle, where it covered the find being judged.
- **Nothing of you shows in the room:** your body and what first person draws in front of the
  camera are hidden from your eye (held each frame while the camera rises, as Roblox's camera
  scripts rewrite them as it moves); your torch is put out of sight with the camera attribute a
  catch uses (`CaughtSeized`, FlashlightView's own rule; its light stays); the tool wheel slides
  away (`Tools.StowAttribute`, as the machine's menu does).
- **The grid reads:** lines 3 px at 24 a stud and 0.55 transparent (2 px at 0.85 vanished on the
  oak at phone size), floated 0.09 over the floor so it shows over the rug.
- Kept: the fixed camera high by the door (OWNER.md home defaults 12); a lifted find jumps under
  the finger (a thumb offset is ROADMAP polish).

## D-313 · 2026-11-17 · The limit bar, the lid's riders and friends' finds settling (S5-03e3b)

The moment: arranging, a small bar top middle fills honey as you set finds out (4/25), so you
see the room left without a word; open your job box and the moon lamp on its lid rides up with
it; a friend's find drops into place with a knock. Bloxburg's build budget bar is the bar.
- **The server's count:** ArrangeBox now carries, after the box's counts, how many finds are set
  out (`Spots.setOut` over the saved rows, the room's own pieces left out) and the most the home
  holds (`HomeSet.limit`, `Spots.limit(Spots.Start)` until S5-03h). The screen eases the fill
  (`Spots.fill`, `Feel.Fill`) and pops the count; at the limit the tray's cards dim (eased) and
  won't lift; a press on one shakes it, pulses the bar and clicks low. No words. A find already
  set out still moves at the limit, as Brix's judge allows.
- **Riders on the lid** are carried on each screen (JobBoxView): the server draws them on the lid
  shut; the screen turns them about the hinge with the lid, takes up any the server moves (a
  pivot not where the screen left it), and leaves them once it's shut. **The lid stops propped**
  where a rider's corner would pass `JobBox.Behind` (0.7 studs behind the hinge; the wall is
  0.79): at 88 degrees the moon lamp stood half a stud into the wall and showed next door. With
  the lamp on it the lid opens to 60 and knocks as it's propped (my pick, in OWNER.md).
- **Friends' finds settle in** (SettleView): a find drawn by a move carries the server's time
  (`Arrange.WhenAttribute`); on another player's screen one younger than `Feel.Fresh` (1.5 s) is
  lifted `Feel.Drop` (0.5; a ceiling find rises instead) and eased down over `Feel.Settle` with
  the Arrange knock heard within 30 studs. Finds laid at a join carry no time and stream in
  standing. Your own are left to your Arrange screen's ghost.

## D-314 · 2026-11-17 · The mirror's real frame: moulded oak, a bevelled edge, felt pads (S5-03f1)

The moment: you walk into your home and the long mirror leaning by the wall is a real piece of
furniture, the first thing you check your hat in. The test's frame was plain parts (D-280).

- **The look** (D-263's calm home): a floor mirror in a warm oak moulding mitred at its corners,
  each side cut from its own plank with the grain along it (the shelf's Wood set): a bead round
  the glass, a quirk, a face rising to a rounded crown, the glass set 0.08 studs back so the
  frame casts a lip. Round the picture a 0.06-stud bevelled edge, pale cool glass with a sheen
  (`Home.Paint.Bevel`, Reflectance 0.3). Two felt pads under its foot and two on its top's back.
  `art/home/furnish.py` (`ring` sweeps a profile round a mitred rectangle), `MirrorFrame`,
  `MirrorBevel`, `MirrorPads`: 332 triangles. Sheets `art/sheets/lobby-mirror*.png`.
- **The art owns where it stands.** `Specs.Mirror` (from `home_spec.py`): its foot, turn, lean
  (still 6 degrees), the glass's front face's middle and size in the piece's frame, and the whole
  frame's size. The foot stands where the top pads just touch the left wall's face (9.076 across,
  was 9.25, which put the old frame's top 0.1 into the wall). `Home.mirror(template, unit, face)`
  sets the art's pieces from the place's Home and makes the glass part where the art says; the
  glass stays 2.4 by 5.6 and MirrorView and `Mirror.luau` are untouched. Arrange's fixed
  footprint is the frame's size (3.08 by 6.32). The frame stops you (a box), as the plain one did.
- **Seen in Studio Play on the A16, Nov 17** (`docs/art/S5-03f1-*.jpg`): the oak frame at phone
  size, you facing out of it, the shelf, the floor lamp and the ceiling lamp behind you. The hard
  hat in it was not checked again (the copies' maths didn't change; D-283's look stands).

## D-315 · 2026-11-17 · The clothes rail: a rolling oak garment rail past the mirror (S5-03f2a)

The moment (the home doc's idea 23, Lethal Company's suit rack): beside your mirror stands a
rail with everything you can wear on it; you take one off it, put it on and turn to the mirror.
S5-03f2 was split: this part builds the rail and stands it in every home; S5-03f2b hangs what
you own on it and makes pressing one wear it.

- **The look** (D-263's calm home, the shelf's and the mirror's oak): four square oak posts on
  rubber castors (it rolls, a garment rail's tell), a frame round their feet with three slats
  across it for shoes, a stretcher across each end at the bar's height, a soft graphite steel
  bar between them (the job box's steel), three oak hangers hung side on from steel hooks, and
  an oak hat shelf on top with a low gallery rail along its back. 4.52 across, 5.21 tall, 1.62
  deep; 1,764 triangles in `Rail`, `RailHangers` (Wood), `RailSteel` and `RailWheels` (plain).
  `art/home/furnish.py`, numbers `GARMENT*` in `home_spec.py` (`RAIL` there is the wall's paint
  rail). Sheets `art/sheets/lobby-rail*.png`.
- **Three rows, one per kind of thing you wear:** hats on the shelf, clothes on the hangers,
  shoes on the rack, so the skates and slippers and the clothing still to come each have a row
  without the rail changing. The hard hat is the only worn find today (D-277). `Specs.Rail`
  gives f2b each row's height (`Shelf` 5.07, `Bar` 4.3, `Rack` 0.68) and the hangers' places.
- **Where it stands:** along the mirror's wall past it, its middle 17 studs in from the doorway
  (the mirror's is 12.5, so 0.7 studs between them), its back 0.12 off the wall, turned as the
  mirror is so its front looks across the room. My default (OWNER.md). It stops you as one box,
  as the shelf does. Arrange's fixed footprints gain it on the floor and on that wall.
- **Seen in Studio Play on the A16, Nov 17** (`docs/art/S5-03f2a-rail-a16.jpg`): in all 12
  homes, beside the mirror at phone size, in first person.

## D-316 · 2026-11-17 · Wearing from the rail: Wear and Hang up, the hat out of your box (S5-03f2b)

The moment (the home doc's idea 23, Lethal Company's suit rack): walk up to your rail, press the
hard hat and you're wearing it, its knock and its lamp's click; turn to the mirror and it's on
you. Press again and it hangs back up.

- **The rail shows what's in your box** (`Home/Rail`, `Rails`): each kind you own that you wear
  (today the hard hat and its Gold, anything `Head.fit` knows) has a place on its row, the hat
  shelf's middle first, then either side; a copy stands there while one of it is in your job box
  (`Save.boxed`), at the size you wear it (1.7), as worn (its battery pack left off), its lamp to
  the room, lights off. A visitor sees it too. The box's panel still lists it: one pool, two
  views, so nothing is ever counted twice.
- **What you wear never goes on the shelf**: `Save.keep` skips the shelf for it, and a save that
  already had the hat on the shelf has it lifted off as it loads (`Save.unshelve`), so it stands
  on the rail. Tested in `tests/rail.spec`.
- **Wear makes it from your box onto your head** (`Slots:boxToHead`), marked as from your box as
  a take to hand is (D-293): the save isn't written, the rail's copy goes at once, and it's taken
  up into a climb (D-251), recalled if you leave, as any find out of your box. Its press is
  stamped as Wear from the hand is (`FindUses:wearLit`): every screen plays its knock and click
  and lights it, for good at home (D-259). Only with your head free.
- **Hang up puts it back** (`Slots:hangUp`): off your head in a glint (as a find going back into
  the box at a leave), its knock on the rail, standing there again. Only a worn find out of your
  own box: a hat picked up on a floor isn't yours to hang until a gate keeps it.
- **One press a place, shown only to you** (HomeCards, as the switch and the box are): Wear while
  it stands and your head is free, Hang up while you wear that kind from your box, nothing
  otherwise (no refusal text: the press just isn't there). The server checks each one: rate
  (3 a second, 4 at once), not caught, your home, your root within 11 studs of the place (reach 7
  plus slack), and what the place offers now, never the button's words. A two-second sweep
  catches what no signal tells (a hat sold from the box).
- **Seen in Studio Play on the A16, Nov 17** (`docs/art/S5-03f2b-worn-mirror-a16.jpg`): the hat
  on the rail with Wear; pressed, on your head and lit, Hang up over the empty shelf, yourself
  in the hat in the mirror; Hang up, back on the rail, Wear again; no errors.


## D-317 · 2026-11-17 · Nothing worn or switched on runs down at home; its minute starts on the climb (S5-03f3)

The moment (the home doc's idea 23, the owner's yes in D-259): at home your hard hat burns for
good, and so does a lantern you switch on; ride a lobby car up and the minute starts as you step
out on floor 1, so the climb's danger is real and home stays safe. Before this a hat lit at home
stayed lit for good all the way up (D-277's last bullet), and a lantern switched on at home ran
down there.

- **At home any light lit burns for good** (`Use.home`): a press that switches a light on, on the
  ground floor (`Head.home`, as D-277), is stamped forever, the hat's Wear (from your hand or the
  rail) and a lantern's Switch alike. Switched off, a toy, or a light that never runs down anyway
  (the glow sticks) is stamped as anywhere.
- **Riding up gives each one its own full light from then** (`Use.leave`, `FindUses:leave`):
  Climbs calls it for each rider beside `Slots:up`, as the lobby car lands on floor 1 (my
  default: the ride itself doesn't count; OWNER.md asks). Every find in your slots or on your
  head (`Slots:onThem`) stamped forever gets its row's `lasts` from now; one switched off keeps a
  full light for later. One lit on a climb is left as it is.
- **Only the light changes, never the press's clock.** The stamp keeps its `at` and its `left`
  grows to the time already burned plus the full light, so no screen plays the knock or the
  click again; only `UseLeft` is written. Screens re-read a stamp only as its clock changes, so
  `FindUseView` also listens to `UseLeft` and takes the new light through `Use.relit` (the same
  press, a light lit for good given its minute; anything else waits for the clock). Monsters
  read the worn light each step (`Keepers`), so a Mannequin sees it go out.
- **A bundle's next stick gets its own full light** (`Use.press`: the row's `lasts`, not what the
  last stick had left), so a stick restamped as you left never hands its longer light on. No
  row has a bundle that runs down yet; the glow sticks never do, so nothing changes today.
- **Seen in Studio Play, Nov 17, server side:** worn from the rail at home, the hat's light read
  forever (`UseLeft` -1); the car landed on floor 1 and it read 87.03, its clock unchanged,
  27.06 s of it burned at home: lit until 60 s after arrival. Your screen running it down wasn't
  seen: Rojo wasn't connected and the client kept the old `Use` (STUDIO.md, "Patching scripts
  without Rojo"); the pure rule is tested in `tests/leavehome.spec.luau`, the rest in OWNER.md.

## D-318 · 2026-11-17 · A wrap colour tried on at any mirror: the catch's film for a few seconds, free (S5-03f4a)

The moment (idea 24): press Try on at the mirror, turn once round as the film winds up you from
the ankles, and there you are in the glass wrapped in a colour from the counter; three seconds
later it loosens with a crinkle, slumps to a heap round your ankles and fades. Every Roblox
avatar shop's try-on button; DOORS' and Fortnite's look before you buy.

- **It's the real film, not a picture.** The server wraps you in the catch's own film, made one
  way for both now (`Film.make`, moved out of KeptPlayers), tinted the colour, so the mirror shows
  it with nothing new: MirrorView copies the film as it copies anything on you, and follows its
  size and see-through each frame while it winds and peels (`TryOn.Tag`).
- **Held still, facing the glass.** Your root is anchored as the catch anchors a kept player, for
  the whole `TryOn.length()` (5.6 s): wound in film you can't walk, and the peel plays on you in
  the glass. Every screen turns you once round as the film climbs (`TryOn.turn`, the shorter way
  round plus one turn), from the stamp of when it went on and which way you faced.
- **Which colour** (my default, OWNER.md): each press tries the next on the counter's shelf after
  the one you last tried, owned or not, round and round, in memory only. No name on the button:
  you see the colour in the glass.
- **Who and where** (my default, OWNER.md): every glass tagged Mirror gets Try on on R (the pad's
  Y), apart from the rail's E; anyone may press it, a visiting friend too. Checked on the server:
  rate-limited, not kept, not trying one already, alive, standing, in front of that glass within
  reach. Refused presses are ignored, no words; your own button hides while your film is on.
- **Sounds**: the catch's squeal cut short and pitched up as a quick zip; the cellophane crunch
  pitched up as the crinkle, and as it is when the heap lands.
- **Free, saves nothing**: no save field, no purchase, no timer by any Robux price.
- **Seen in Studio Play, Nov 17, on the A16** (`docs/art/S5-03f4a-tried-on-a16.jpg`,
  `-peeling-a16.jpg`): Rojo wasn't connected, so Studio's copies were patched from Edit
  (STUDIO.md); the server tried Blue on, the mirror showed you wrapped, then the heap at your feet.
  The catch's film itself (KeptPlayers through `Film.make`) passes checks, untested in Studio.

## D-319 · 2026-11-17 · The counter's mirror: try a card's colour on beside the shop (S5-03f4b)

The moment (idea 24): at the counter's shop you see yourself in a colour on its card, tap the
figure, the shop slides away, your view turns to the mirror beside the counter, and there you are
wrapped in that very colour. Every Roblox avatar shop's Try On button, with Fortnite's and DOORS'
look before you buy; the film is the catch's own (D-318).

- **The mirror is the home's** (`Home.mirrorAt`, the same oak frame and glass), leaning on the
  front wall just past the counter's door end (`Shop.Mirror`, lobby frame x 47.5, foot z -155.2),
  its glass looking into the room. Walking from the spawn to the counter you pass it and see
  yourself. Any Mirror-tagged glass gets the mirror's own Try on (R), so this one has it too.
- **Its picture stands the front office's walls** (`Lobby.MirrorRoom`, a `Mirror.Room`): the
  side walls' sage below the rail, their oak baseboard, the bay wall's teal 156 studs off. The
  floor, ceiling and cream upper walls are the lobby's own meshes, which `Mirror.keeps` lets
  through (level, wholly below or above the glass); the home fronts along the side walls are
  left out, as a home's mirror leaves out its neighbours.
- **The counter's Shop button had been left at the old lobby's spot** (z -35, by a home's door
  since D-262 made the floor 156 deep) and the shop's "in the lobby" box covered only the cars'
  end. Both moved: the button to the counter's door end (z -147.5, the end you reach first), the
  box to the whole floor.
- **Try on on each colour's card** (my default, OWNER.md): the whole figure is the button, with
  a "Try on" pill at its foot in the colour's rim; shown only while you stand in front of a
  mirror's glass within `Shop.TryReach` (12 studs, so anywhere you'd stand at the counter) with
  no film on, never a refusal. A tap pops the card, clicks, fires `TryWrap` with the colour's
  name and shuts the shop. The plain film's card has none. Not owned, not saved, free; no price
  or timer by it.
- **On the server** (`TryOns`): `TryWrap` takes a colour's name checked by `Shop.name` (a colour
  only), the mirror button's rate limit, then that colour at the nearest glass you stand in
  front of within `Shop.TryReach` plus `TryOn.Slack`; with none, nothing. The same checks as
  the mirror's button otherwise; the next press of the mirror's button carries on after it.
- **Your view turns to the glass** (`TryOn.LookAttribute`, `TryOn.Look` 0.45 s, TryOnView):
  the game is first person, and from the shop you face the counter, so without it you'd miss
  yourself. Eased out on your screen only, from the glass's middle stamped on the film; from
  the mirror's own button it barely moves.
- **Passes checks, untested in Studio**: Rojo isn't connected and this session ran out of room
  to patch Studio's nine changed modules by hand; S5-03f4b2 sees it in Play.

## D-320 · 2026-11-17 · The counter's mirror, seen: in line with the glass, and no flash (S5-03f4b2)

Seen in Studio Play on the Galaxy A16 (Rojo still unconnected, Studio patched by hand): the
counter's mirror leans on the front wall by the counter and you see yourself in it walking up;
its picture holds the front office's walls, floor and ceiling with no dark gaps. With the shop
open in front of it, every colour's figure carries its Try on pill (not the plain film's); a tap
on Pink's pops it, the shop slides away and the counter's mirror shows you wound in pink, then
the peel and the heap (`docs/art/S5-03f4b-*.jpg`). The eye found two faults, both fixed in code:

- **A flash in the glass at each sound.** A try-on plays six sounds from your body (the zip, the
  crinkle, the thud, each added and later removed). MirrorView copied your whole body again for
  each one, and the fresh copy stood unposed where you stand, in front of the picture's camera,
  for a frame: a black slab across the glass at the peel. Now only a change to how you look (a
  part, clothes, a face, a mesh: `looksChange`) copies you again, and a copy is posed in the
  glass before it's shown. Patched into Studio; not yet watched through a peel.
- **From the counter you were off the glass's edge.** Your reflection is straight out from you
  along the glass, so you show in a 2.4-stud glass only standing within 1.2 of its middle to
  either side. The mirror stood at x 47.5, the counter's button at 49.6: from the shop your view
  turned to the glass and showed a pink sliver at its edge. The mirror now stands at the
  button's x (`Shop.Mirror`, 49.6; the counter ends 4.8 studs short of it), and the cards' Try on
  shows only while you're in line with a glass (`TryOn.inLine`, half its width; the server
  forgives `TryOn.SideSlack` more), never as a refusal. The mirror's own button is unchanged.

**Seen in Play (S5-03f4b3, the A16):** from the counter facing it, Pink's Try on swings your
view to the mirror with you in the middle of the glass, wound in pink; the peel and the slump go
by with no slab in the glass; three studs to one side the cards show no Try on, and the shop
still opens (`docs/art/S5-03f4b3-*.jpg`). The dark glass came back once, on the session's very
first look at the counter's mirror (you lit, the room behind you dark, for about a quarter
second); three later swings, one with a freshly rebuilt picture, came in whole. Left as polish
(ROADMAP), since it's once a session and brief.

## D-321 · 2026-11-17 · The looks a player gives their home: four floors, four walls, eight paints, eight doors (S5-03g1a)

The art for idea 18 (Animal Crossing's wallpaper and flooring, Bloxburg's paint), the unit's way.
The moment: on Arrange you pick a floor and a wall and the bare box becomes somewhere you'd hang
out; your door's colour is what the hall sees.
- **Four floors**: the oak boards a home starts with, a soft carpet, checkerboard tiles and
  interlocking rubber mats flecked with coloured crumb. **Four walls**: plain plaster (as a home
  starts), a regency stripe, a botanical of tossed leaves and a daisy print. Calm and warm
  (D-263); the checker in cherry and the daisies are the fun ones.
- **A look takes a colour where it should** (Overlay, the part's Color): a checker's coloured
  squares, the carpet, the mats' rubber and every paper's ground. What's printed keeps its own
  colour: the cream squares, the crumb, the leaves, the daisies. So a few sets make many homes,
  and the papers always agree with the paint. Each floor lists its own colours (five each; tiles
  want stronger ones than walls); the papers take the wall's paint.
- **Eight paints**, warm white first, from Butter to Ink; **eight door colours**, clay first, each
  reading against the lobby's teal walls (no teal or navy, which vanish there).
- **One tile size per kind**: every floor tiles at 8 by 8 studs (the oak's), every paper at 4 by 4
  (the plaster's), so g2 needs one floor panel and one wall panel, whatever the look.
- **Ids are what a home's save keeps**: never rename one; add looks at the ends.
- My defaults, all waiting on the owner (`OWNER.md`): the looks, their colours and their order.


## D-322 · 2026-11-17 · The name card's four styles: stencilled steel, a painted board, chalk and neon (S5-03g1b)

Idea 20, the unit's way. The moment: walking down the hall your friends' names are stencilled,
painted, chalked and glowing over their doors, and yours is the one you chose. Precedent: Bloxburg's
and Adopt Me's house signs and Animal Crossing's mailbox styles, each home's front its own.
- **Four plates, each its own parts on one origin** (the card's middle on the wall's face, its
  front out): `CardSteel` and its bolts (powder-coated steel, the job box's Plaster stipple, not the
  climb's raw steel), `CardBoard` and two brass screws (a sign-writer's board, the new SignBoard
  bake: brushed paint over the grain, a cream pinstripe), `CardSlate`, `CardChalkFrame`,
  `CardChalkStick` (the Chalkboard bake in a moulded oak frame with a chalk ledge), `CardNeonBack`
  and `CardNeonTube` (a glass tube round a dark backing; the game makes it Neon).
- **Every plate is dark** because the cards hang on the hall's cream upper wall (Lobby.Paint.Cream):
  a slate-blue steel with cream stencil letters, a forest-green board with cream lettering, the
  green-black slate with chalk, the near-black backing under pink neon.
- **Lettering in Studio's own fonts** (families in Studio's `content/fonts/families`, Font.fromName):
  Oswald Bold stencilled, Luckiest Guy painted, Patrick Hand chalked (Amatic SC was chalkier but
  its thin strokes vanished from across the floor), Nunito for the neon's tube lettering with its
  glow. The sheet renders them from Studio's own font files, so what it shows is what the game draws.
- **The neon lights the wall round it**: a light in the glow colour just in front of the plate
  (`Specs.CardLight`, range 9), the one style that's a light source. Seen on the sheet as a pink
  wash on the cream wall and the ceiling; it's what you see first from across the floor.
- **Who has which**: stencil every home's to start, painted and chalk for cash, neon for Robux (the
  ticket's split). The prices and the colours wait on the owner (`OWNER.md`).
- The plates sit inside 10.3 to 13.6 studs up (the cap at 10, the deck at 14); the writing faces
  are `Specs.Cards[i].Face` and `FaceSize`. `tests/homecards.spec.luau` holds it.
- Not in Studio yet: g3 uploads Home.fbx with them, puts the chosen style over each door in place
  of the lobby's plain plate (the lobby's `signs()` card plates go then) and writes the name on it.

## D-323 · 2026-11-17 · The counter's furniture, part one: a milk crate, a pallet table, a folding table, a steel shelf (S5-03g1c1)

Idea 19, the unit's way. The moment: at the counter you see things you'd put in your own unit and
want them, because each invites you to sit on it, set a find on it or gather round it. Precedent:
Lethal Company's crew buying furniture at the ship's terminal; Animal Crossing's furniture, each
piece with a flat top a find can stand on (idea 14).
- **The milk crate is upturned**, as people sit on one: its top (the crate's base, a grid of holes)
  is the seat at 1.65, a little under the bench's 1.7 so a sitting avatar's feet stay on the floor,
  and a top a find can stand on. Square holes through its four sides and top (geometry, so you see
  through it at phone size), rounded corner posts, a hand slot through its rim on two sides. Plain
  plastic: the game colours it (a buyable colour; mustard, teal and terracotta on the sheet).
- **The coffee table is two pallets stacked** (top at 1.2, under the seat): three notched
  stringers along each, seven deck boards over and five under, each a hair off true. Rough pine
  needed its own set (`Pine`, 1024², not tiled): oiled oak read as furniture, not a pallet. Each
  board is a strip of the set mapped in studs from its end, so the baked nail heads land where
  deck boards cross stringers (`home_spec.pallet_nails`).
- **The folding table** is a blow-moulded top (Plaster: the stipple reads as pebbled plastic; the
  game paints it pale) at 2.8, on graphite legs splayed a little with a crossbar and a brace.
- **The steel shelf** is four tiers on angle posts, powder-coated (Plaster, like the job box; sage
  on the sheet), tiers 1.85 apart so a find fits between, zinc bolts and rubber feet in their own
  plain part. Not the climb's raw steel.
- `Home.Specs.Tops` gives each new piece's flat tops (middle and size) for the finds and seats g4
  sets out; `tests/homefurniture.spec.luau` holds the heights. Sheet `art/sheets/home-furniture.png`
  (`build.py --stage furniture`, 10 s): the four set out by a person for scale, then a unit made
  into a hangout from the door, from a seat and by the wall. Judged at phone size: all four read.
- Not in Studio: g4 uploads Home.fbx and sets them out at the counter. Their prices and default
  colours wait on the owner (`OWNER.md`).

## D-324 · 2026-11-17 · The counter's furniture, part two: a blanket, a camp bed, string lights, a neon moon (S5-03g1c2)

Idea 19, the unit's way. The moment: you turn the ceiling lamp off and your unit is a sleepover,
friends on the blanket and the camp bed under string lights and a glowing moon. Precedent: Adopt
Me's and Bloxburg's homes, where string lights, neon signs and beds are the furniture players buy
to make a room theirs; Animal Crossing's lit furniture.
- **The moving blanket is folded into a floor cushion** (3.2 by 2.7, top at 0.44, under the pallet
  table's 1.2): a seat on the floor round the coffee table and a top a find can sit on. Four folds,
  each bulging and pinched where it meets the next, a hair off true; the top quilted in diamonds
  puffed in the geometry (a baked quilt didn't read on a phone); a binding at each fold's front
  and right, its own part so the game tints it apart (the sheet: mover's blue, cream binding; dark
  binding vanished in shadow). Not draped over a crate: Arrange sets pieces on the floor.
- **The camp bed** is a canvas sling at 1.45 (under the crate's seat) sagging 0.3, both sides
  modelled because you see under it, sleeves round its rails and end bars, three X legs on pivots,
  a pillow at its head. Canvas and pillow are Fabric, tinted (olive and cream on the sheet).
- **The string lights** are 9.6 studs (a small home is 10 across) in three catenary swags from
  four hooks, twelve warm globes. Their origin is the clips' line, everything below it, so they
  hang from the wire ceiling (idea 14) or along a wall's top.
- **The neon sign is a picture, the name card's neon the word**: a crescent moon with a star in
  its hollow, one tube each, on clear acrylic (the game's Glass) on standoffs, hung like a card.
  Swept flat, then stood up, so the tube's rings never twist where its run turns vertical (the
  card's tube can). Warm yellow to start; the game colours the tube.
- **Lights for a phone (D-271):** the bulbs and tube are Neon (a glow, no light), and each lit
  piece throws one real light, only near you as the floor lamps do. `Home.Specs.Glows` names each
  one's Neon parts, clear parts, its light's middle, range and brightness: the string lights 16
  (to the floor under a 10-high ceiling), 1.2; the moon 8, 1.1.
- Home.fbx 33,534 triangles in 63 parts; the pieces 2.3k to 3.4k each. Sheet
  `art/sheets/home-furniture.png` now three rows: both parts by a person, the hangout by day and at
  night (lamp off), from a seat and by the wall. Judged at phone size: all four read; the night
  panel is warm under the bulbs and round the moon. Their prices and colours wait on the owner.

## D-325 The home's wall and floor panels, and a swatch per look (S5-03g2a, 2026-11-17)

- **Panels over the lobby's walls, not new walls.** The lobby's unit walls and floor are merged
  meshes shared by all twelve homes, so a home's paint and floor go on its own panels a hair
  (0.02) proud of them: a floor panel, one per partition, the back wall and the front wall's
  inside round the doorway (`art/home/panels.py`). The lobby's walls stay under them. Thin boxes,
  not single planes, so no part imports with no depth; 84 triangles for a whole home.
- **UVs in studs over the tile**, so any floor set (8 studs) or paper (4) wears a panel at its
  true size. A paper's rows run level all round the room (V is the height) and carry on round both
  back corners (U runs round the room from the back wall's middle); only the front corners break,
  as real wallpaper does. The floor's squares start at the back wall and the room's middle, and
  oak boards now run from the door to the back wall (the lobby's ran across): it draws you in.
- **Each panel its own part on its own origin** (its middle, its face toward -Z); `Specs.Panels`
  gives its middle in the unit's frame and its turn, so S5-03h can move them. Sized for XL now.
- **A swatch per set** (`Swatch<Set>`, a 2-stud square showing half a tile): the only way a set's
  SurfaceAppearance reaches Studio, since game scripts can't write its maps; the game clones a
  swatch's onto a panel and sets the part's Color (Overlay). The swatch doubles as the picker's
  chip in a ViewportFrame. Home.fbx: 33,714 triangles in 76 parts, 18.8 MB with the looks' maps.

## D-326 A home's look: saved, judged by the server, wiped round the room (S5-03g2b1, 2026-11-17)

- **The save keeps ids** (version 9, `looks`): paint, paper, floor and floor colour from
  `Home.Specs.Looks`; a new home's are the first of each (warm white plaster on oak boards, whose
  colour is baked, so its floor colour is ""). A look dropped later falls back to the start's
  (`Looks.tidy`). A floor colour is one of that floor's own; a new floor keeps the colour when it
  has one by that name (sage carpet to sage checker), else takes its first.
- **Every paint, paper and floor is free for now** (my default; OWNER.md). Animal Crossing sells
  its papers, but a home is the calm reward for climbing (D-263), and no price was agreed; a
  price would be one check in `Decorating.pick`.
- **Panels only where a home differs.** A held home's four wall panels are laid once its paint or
  paper isn't a new home's, its floor panel once its floor isn't: five parts at most a home, none
  for a home as it starts (the lobby's own walls show). They cast no shadow and take no clicks or
  rays (the Arrange screen's aim passes to the lobby's floor under them).
- **The wipe is the answer** (idea 18). The server saves the pick at once, stamps the unit's new
  look and the time, and changes the panels `Looks.Wipe` (1.1 s) later; meanwhile each screen near
  grows sheets of the new look over the old: plain parts in the paint or floor colour with the
  set's colour map as a Texture (its clear bits show the colour, as Overlay does), tiled in studs
  and lined up with the panels' own tiles. The paper starts at the back wall's middle and goes
  round both back corners to the door (the panels' U: studs round the room), the front wall's
  inside fading in last as a copy of its panel (a Texture can't leave the doorway's hole); the
  floor unrolls from the back wall to the door. A roller's wet squish plays from the room's
  middle, lower for a floor, heard to 45 studs. The sheets go once the panels wear the look, so
  nothing jumps; a screen that sees a pick late just sees the panels.


## D-327 A home's new look seen in Play: fetched ahead, under the rug, no flash (S5-03g2b2, 2026-11-17)

Seen in Studio Play (not on the A16: Studio had restarted onto "Current device"). The paper wipe
works as D-326 planned: it grows from the back wall's middle round both corners to the door and
the panels take it with no jump (Leaves to Stripes; `LooksView.SHIFT = 1` holds). The save keeps
the look over a rejoin (version 9). Three faults, fixed in `LooksView`:
- **Every look is fetched before anyone picks.** A set's maps and the panels' meshes download
  only when something shows them (the swatches in `ReplicatedStorage.Props.Home` never draw), so
  a first pick of a paper wiped in as plain paint and its pattern popped in about 3 s later, and
  a first floor flashed the old boards back for a second before its panel drew. The first time a
  home is near (a unit tagged `HomeLook` streams in), the screen fetches all eight sets' four maps
  (512 maps, small) by id and the five panels by part. Lobby only: the climb never pays for it.
- **The sheets wait for the panels to draw.** They go a frame after `LookWorn` matches only once
  this screen has the new look's maps and meshes, else when the wipe's 3 s grace runs out.
- **The floor rolls under the rug.** The rug's top stands 0.045 over the floor; the floor's sheet
  was 0.03 to 0.05 and hid it as it went. It's now 0.01 thick, 0.025 to 0.035.
Left for polish (ROADMAP): the sheet (a Texture on plain plastic) reads a shade darker than the
panel's SurfaceAppearance under the bulb, a small step as the wipe hands over; the mirror's copy
of the room keeps the floor and paper it had when you came in.

## D-328 The paint tab on the Arrange screen: two rows, the walls over the floor (S5-03g2b3, 2026-11-17)

Seen in Studio Play on the Galaxy A16 simulator (685x338; the gui is 280 tall under the top bar):
- **Two tabs on the tray's top edge**, at the left, riding with the tray: the finds (the Arrange
  button's four squares) and the looks (a fan of three paint chips, a decorator's colour card).
  Bloxburg's build mode tabs. The tab you're on wears the white ring a worn look's chip does; the
  other stays solid, since a see-through one let the wallpaper muddy its icon. The tray slides
  190 under the screen now (was 120), so its tabs go with it. Which tab shows is kept between
  opens.
- **Two rows, not four.** Four rows of 44-point chips would cover over half of the A16's 280
  points; two take 120, the room's walls and the back of its floor still in view. The top row is
  the walls (the papers, a divider, the eight paints), the bottom the floor (the four floors, a
  divider, the chosen floor's colours), as the room stands. Everything fits the A16 without
  scrolling; each row scrolls sideways if a later look won't.
- **A chip shows what you'd get.** A paper's or floor's chip is its set's colour map (an
  ImageLabel) over the colour that surface would wear were it tapped (`Looks.pick`, then
  `Looks.wear`): the panels' Overlay, the map's clear bits showing the colour. Papers wear the
  home's paint, so a new paint re-tints them (eased); a floor wears the colour it would keep by
  name or its first. ImageLabels, not the ViewportFrames D-325 planned: twelve 3D views cost a
  low-end phone a frame each, and a flat 46-point map reads the pattern as well. LooksView's
  fetch-ahead already has the maps, so nothing pops.
- **The ring is the server's answer, the wipe the room's.** A tap presses the chip in with the
  job box's soft click and fires `PickLook`; the white ring moves when the unit's `Look` changes
  (a ping later), then the room rolls. Tapping what you already wear is just the click. A new
  floor's colours pop in where the old ones stood, the old shrinking away at the row's end so
  nothing shifts; the oak boards have none, and the divider fades with them.
- **Nothing to buy here.** Every look is free (D-326), so no chip is marked. When card styles or
  looks are sold, a chip you don't own shows a small coin or Robux mark and never opens a popup
  (S5-03g3c).

## D-329 The door's colour rolls down its slats, apart from the room's look (S5-03g3a1, 2026-11-17)

Idea 18's door (Animal Crossing's house front, Bloxburg's paint on any surface). The moment: you tap
Mustard and your roll-up door turns from the top down as you watch; the hall sees whose door it is.
- **Saved with the looks** (`looks.door`, save version 10; an older save's door is clay). Picked
  through the same `PickLook` remote, its fifth kind, under the same rate limit.
- **Apart from the room.** The door's id rides on the unit by itself (`Looks.DoorAttribute`), never
  in the room's encoded look, and the server paints it on its own timer. Folding it into the room's
  look would have restarted a wall's wipe on a door pick and pulled its sheets early (a flash).
- **The roll is every screen's, the paint the server's.** Each screen that draws the door holds its
  38-slat chain out, even on a shut door, and turns each slat over 0.15 s from the top down, the
  whole door in 0.5 s (`RollUpDoor.paint`, `Looks.rollShare`), with the roller's squish pitched up.
  An open door turns round its coil from the outside wrap, the part seen from inside. The server
  paints the door 0.8 s after the pick, once every roll is done, so nothing snaps; a screen that
  lags past that sees the rest of its roll jump to the colour, nothing worse. A home let go is clay
  again, as every spare home is.
- **A third tab, not a third row** (for S5-03g3a2): the door's eight dots don't fit beside the floor
  row on the Galaxy A16 (they need 408 points, 197 are free), and a third row would cover 174 of its
  280. The Arrange camera looks away from the door, so a "your front" tab turns it round to face
  the door, and the name card styles (S5-03g3c) take that tab's second row. Bloxburg's build mode
  has a tab per part of the house.

## D-330 Your front: a tab that turns the camera to face your door (S5-03g3a2, 2026-11-17)

Bloxburg's build mode has a tab per part of the house; this is the door's. The moment: on Arrange
you tap the little door tab, the camera swings round to face your door, and a tap on Mustard rolls
it mustard from the top down.
- **One tab module, two pages.** `LooksTab` takes a page ("room" or "front"): the front page is one
  row of the eight door dots, ringed from the unit's `LookDoor` and watching it, so the ring moves
  when the server takes the pick; the same `PickLook` remote, kind "door". The tray is 66 points
  tall on it; g3c's card styles go in its second row.
- **The camera stands near the room's middle, not a third of the way in.** The home is 29.75 deep
  with an 8-stud door, so a third of the way (10 studs) can't fit the door and its coil above the
  tray on the A16. 13.4 studs from the doorway at 6.3 high, looking at the doorway 4.5 up, fits it
  from the foot (at the tray's edge) to the coil, and stays in front of the starter shelf (14.4
  back). Kept a stud off the back wall for smaller homes (S5-03h).
- **A swing, not a tween.** One tween of the camera's CFrame between the dollhouse corner (steeply
  down) and the door view (a half turn away) slerps round a tilted axis and rolls the picture. The
  swing eases its place, heading and tilt apart (the heading the short way, a half turn always by
  the left), so the walls stay upright all the way round. Everything that moves the camera on
  Arrange (the ease in, the swing, the ease out) stops the one before.
- **The limit bar rises away on the front tab.** It counts finds and sat over the coil, the part
  that rolls on an open door. It goes to -120: at -60 it still peeks into the top bar's strip.
- **Finds don't lift on the front tab.** Facing the door, the room is seen low and edge on; a tap
  in the room does nothing there, and the finds lift from the other two tabs as before.
- **Open, the hall doesn't see your colour.** An open door is rolled up behind the header, so from
  across the floor your home shows its name card, not its door. Left as it is (your door stays
  open while you're on the floor); whether it should shut when you walk away waits on `OWNER.md`.

## D-331 Your name card's plate hung over your door, the style saved (S5-03g3b1, 2026-11-17)

The moment: you walk out across the floor and your name is over your door on the plate you
chose, your friends' on theirs. Precedent: Bloxburg's and Adopt Me's house signs, Animal
Crossing's mailbox styles (D-322).
- **Saved with the looks, carried apart from the room's.** `looks.card` (save version 11; an
  older save gets the stencil every home had), a sixth `PickLook` kind, the id on the unit in
  `Looks.CardAttribute` ("LookCard"), never in `encode`, as the door's is (D-329). Only Starter
  styles are picked until the counter sells the rest (S5-03g3c).
- **The server hangs the plate, not each screen.** FrontOffice watches each home's unit and
  `CardPlate.hang` (src/shared/Home) clones the style's parts from the home template onto the wall over the
  door, paints them (the mapped plate takes `Paint` through its Overlay map; bolts, screws, chalk,
  backing and tube take a material and colour), and moves the writing face onto the plate's
  `Face` in its font and ink. Every screen sees the same plate, and the client's spray still
  lands the name on it. The writing part keeps its wall frame (`CardWall`), so a plate can be
  swapped any number of times.
- **The lobby's plain plates are gone.** `signs()` no longer builds a card over each door (they
  sat exactly where the stencil hangs), so a spare home wears the blank stencilled steel plate,
  and a home let go goes back to it, its name fading off as before.
- **What it looks like on the A16:** close up the stencil reads well, cream Oswald on the dark
  slate plate; from mid-floor (40 studs) the name is small, the size the plain plate's was; from
  the far wall (100 studs) the plates are dark bars. The neon's tube already reads from far
  off; its glow stroke and light are g3b2.

## D-332 The neon card lit: a glowing name and a pink wall, near you only (S5-03g3b2, 2026-11-17)

The moment: down the calm ground floor one name glows over its door, the first thing you see from
across the floor. Precedent: Bloxburg's and Adopt Me's neon house signs (D-322).
- **The name glows** (`CardPlate.hang`, server): a Glow style's SurfaceGui takes LightInfluence 0
  and its lettering a UIStroke in the glow colour (`CardPlate.Neon.Stroke` 3 px at 60 px a stud,
  `Haze` 0.3), so the white Nunito reads as a lit tube in a pink halo; any other style goes back
  to the lobby's ink light (kept on the card as `CardInk` when Lobby lays it, since Lobby can't be
  required from CardPlate) with no stroke. HomeCards' spray settles onto the style's own light,
  read at the spray, and retargets if the plate changes mid-settle (a claim's name and plate can
  arrive in either order).
- **The wall's pink wash is a real light thrown only near you** (D-271's budget): each screen
  makes a PointLight (`Specs.CardLight`: range 9, `Out` 0.9 studs in front of the plate) for the
  two neon cards nearest a point just ahead of the camera within 48 studs (the floor lamps' pick,
  `UnitLight.NearLead`, `NearMargin`), fades it in over 0.6 s and fades it out and destroys it.
  A third neon card further on keeps its glowing name on a plain wall. Seen: two lit, the third
  taking over as one went back to the stencil, none after walking off.
- **Brightness 2.6, not the sheet's 1.4**: in Play on the A16 the hall's fills drowned 1.4 (a
  faint tint); 3.5 at range 11 turned the whole wall and ceiling pink; 2.6 at 9 reads as a
  pink glow round the plate from mid-floor. The light's place (`Out`) moved into the art spec so
  the sheet and the game hang it in the same spot.
- **On the A16:** from the far wall (108 studs) the lit name is a bright white-pink bar and spare
  neon plates a thin pink outline; from mid-floor (40) the name reads, small; close up the wash
  is plain on the cream wall and ceiling. Pictures `docs/art/S5-03g3b2-neon-*.jpg`.

## D-333 The counter's furniture: a weekly stock from the date, bought for cash, saved first (S5-03g4a, 2026-11-17)

Idea 19. The moment: back from a climb with cash, this week's pieces are at the counter and you
buy the camp bed; it's yours, saved, waiting in your job box. Precedents: Animal Crossing's Nook's
Cranny and Fortnite's item shop (a stock that changes, the same for everyone), Lethal Company's
ship store (bought with the run's pay).
- **The pieces are rows** (`Home/Furniture.luau`): the eight art pieces of D-323 and D-324 by
  their `Specs.Pieces` names, each with a cash price, how it stands (floor; the string lights the
  ceiling; the neon moon a wall) and a cap on how many one player owns. Prices are counted in a
  first floor's gate pay (`Pay.forFloor(1)`, 10): a crate is 3 of it, the camp bed 15, the neon
  moon 25, so they move with the pay. Defaults in `OWNER.md`.
- **The stock is worked out from the date alone, never rolled.** The pieces sit on a ring set by
  hand; a week shows five in a row round it and each Monday 00:00 UTC the window turns three
  places on. So every server shows the same stock all week, three pieces change each week, and a
  piece out this week is always back next week (the spec walks 200 weeks). No randomness at all,
  so nothing random is ever sold, and a piece is always bought by name. Two minutes' grace after
  the turn sells last week's pieces, so a shop left open over midnight isn't refused.
- **Save version 12** adds `furniture`, owned counts by piece id (listed only while one is owned);
  version 11 saves load with none. The version-11 shape is now built from a fields table that
  version 12 clones and adds to, rather than another 50 copied lines; the shapes are unchanged.
- **The buy is written before it's yours.** `BuyFurniture` (a piece's id) is rate-limited, then
  checked: a short string naming a piece, then the stock, the cap and the cash (`Furniture.buy`
  takes the price and adds the piece in one step, so any write from that moment holds both or
  neither). Then the save is written at once (`Saving.save` now answers why a write failed, nil
  once written), and only then does `FurnitureBought` answer the buyer: the id, their cash, how
  many they own, and "" or the refusal. A failed write undoes the buy whole (`Furniture.unbuy`:
  relative, so a sale from the job box during the write is kept) and answers "save". One buy at a
  time per player ("busy" while one's write is out). Unlike the job box's sales, which batch one
  write per run, a buy writes at once: one tap, one write, and it can't be undone by a crash.
- **Seen in Studio Play** (the server's `ServerStorage.FurnitureTest`): this week's stock was
  MilkCrate, Pallet, SteelShelf, CampBed, NeonSign; a Blanket was refused out of stock; the camp
  bed bought, the save written (version 12, cash 478 to 328) before the answer; with
  `DevSaveFails` on, a crate was undone ("save", cash and count as before); a crate bought through
  the remote from the client answered in 0.5 s after the write, cash 298.

## D-334 The counter's furniture on screen: a second tab, held until the save answers (S5-03g4b, 2026-11-17)

The moment: back from a climb you flip the counter's shop to Furniture and this week's pieces turn
in their cards; you buy the camp bed and your cash ticks down, the bed drops into its box with a
clunk and the card says it's in your box. Fortnite's item shop and Nook's Cranny (a stock that
changes), Lethal Company's ship store.
- **A tab beside the wraps, not a second shop.** The shop's title became two words, Wraps and
  Furniture, the one you're on underlined; the shop opens on the tab you last used. The cards
  share the wraps' row, size and deal; the furniture lives in its own module (FurnitureTab) that
  ShopView hosts, as Arrange hosts LooksTab.
- **The screen works the stock out itself** from the server's clock (`GetServerTimeNow`), the
  same sum the server does; only your cash and owned counts come from the server, on a new
  `FurnitureShelf` RemoteFunction (rate-limited) rather than the wraps' shelf, so the wraps'
  answer stays the wraps'.
- **Never yours before the save says so.** Buy holds the button pressed and dimmed until
  `FurnitureBought` answers (after the write); only "" ticks the cash down and drops the piece.
  Every other answer settles the card to the server's numbers, the coins silent; "notStocked"
  deals this week's pieces again. An answer lost for 8 s settles the card and asks again.
- **The answer's sounds are the game's own**: the coins' tick from the job box's count (falling
  in pitch as cash goes out, where a sale's rises) and the job box lid's clunk, lighter, as the
  piece lands: "it's in your box" heard as the box you know.
- **Short of cash: the price dimmed, no words.** A press on it nudges your cash pill with a dull
  click (the vending machine's blinking price for too few coins). At its cap a card says Owned.
- **The pieces are the home's real art** (`Home.template()`), framed from `Specs.Parts`' boxes.
  Floor pieces turn; the neon moon and the string lights sway either side of facing you, since
  their backs are bare. Five small viewports, rendered only while the tab shows.
- **Seen in Studio Play on the A16** (685x338): the five cards, $298, the crate and bed ×1; a crate
  bought through the screen ticked $298 to $268 and said In your box, ×2.

## D-335 The counter's furniture wears the sheet's paints (S5-03g4b's fix, 2026-11-17)

The furniture tab showed the milk crate, steel shelf, camp bed and neon moon plain white: the art
left their colours to the game ("plain, the game colours it"; tinted Plaster and Fabric) and
`Home.prepare`'s paint tables never got them. Now they do, the furniture sheet's own
(`art/home/build.py` TINTS, `art/home/front.py` PLAIN):
- **Tinted over their maps:** the steel shelf sage, the folding table pale, the blanket a mover's
  blue with a cream binding, the camp bed's canvas olive with a cream pillow.
- **Plain:** the milk crate mustard plastic, the shelf's bolts zinc, the table's legs graphite,
  the camp bed's frame aluminium, the string lights' cable near black, the bulbs and the moon's
  tube Neon in their light's colour (`Specs.Glows`), its standoffs pale metal, and its acrylic
  backing SmoothPlastic at 0.85 clear. Not Glass: Glass drew a flat grey card in the picture and
  reads black from a lit room (STUDIO.md).
- **The crates come in three colours,** mustard, teal and terracotta (`Home.CrateColours`), as
  the sheet stacks them, for when they're set out (S5-03g4c).
- `Home.paint(part)` is `prepare`'s paint on its own, so a template already in the place is
  repainted when the paints change without re-importing it; done in Edit for the sixteen parts.
- Seen in Studio Play on the A16 (`docs/art/S5-03g4b-tab.jpg`, re-captured).

## D-336 Bought furniture is set out as a find is, under a name of its own (S5-03g4c1, 2026-11-17)

The moment it serves: home from the counter, the camp bed out of your box and slid by the wall,
there when you come back and there for friends who visit (The Sims' and Bloxburg's build mode;
Animal Crossing's furniture from your pockets).
- **One judge, one save list.** A piece goes through the same Place and Put away the finds use
  (`Arranging`, Brix's Placements), so it stands clear of the walls, the starter set and every
  find and piece set out, and its rows live in the save's `placed` beside the finds'. No save
  version: the rows' shape is unchanged.
- **Its own name there**, "CampBed:Furniture#1" (`Furniture.Mark`, `Furniture.placed`,
  `ofPlaced`): the catalog has a find called NeonSign too, so a bare id would read as a find, and
  the finds' box counts, sales and shelf must never count a piece.
- **In the box** means owned less set out (`Furniture.boxed`); a load keeps a set-out row only
  while you own it (`Spots.owned` with the furniture in what's settable).
- **Its footprint is the art's** (`Spots.pieceBox`: its parts' boxes in `Specs.Parts`); floor
  pieces fit the floor only, and nothing stands on them yet (their tops, `Specs.Tops`, later).
- **Drawn as the starter set's pieces are** (`Home.piece`), every part solid as a box (you walk
  round a bed, not through it) and pickable by a tap, with a find's id, owner and tag.
- **Counted against the home's limit** like a find: the limit bar is everything set out, as
  Bloxburg's build budget counts everything placed.
- **Wall and ceiling pieces wait for their lights** (g4d): the neon moon and the string lights
  are refused "notYet" until then.
- The box remote sends the furniture in the box as its fourth value, for g4c2's panel.
- Seen in Studio Play (`ArrangeTest`): set out at (-4, 6) beside the rug after one overlap
  refused, drawn in Unit1 in its canvas and aluminium, saved, re-laid from the save, turned in
  place, put back, in the box again. Not yet seen by a second client (`OWNER.md` after g4c2).

## D-337 Bought furniture comes out of the job box into Arrange (S5-03g4c2, 2026-11-17)

The moment it serves: home from the counter you open your job box, the pallet is there first,
in its own colours; Set out, the lid shuts and Arrange rises with the pallet already lifted out
of the box onto a free spot, green; you slide it onto the rug and it lands with a knock (The
Sims' and Bloxburg's build mode; Animal Crossing's furniture from your pockets).
- **The furniture is dealt first** in the job box, before the finds: few, big, and newly bought,
  so they're never buried under forty finds. A rim of warm wood (D-263), not a rarity's colour;
  no rarity chip counts them, a search finds them. Their picture is the counter card's art,
  still, from the front corner (`FurnitureTab.picture`).
- **One verb, Set out**, for a floor piece: no sale, no hand, no shelf (furniture isn't carried).
  It shuts the lid and opens Arrange holding the piece (`ArrangeView`'s `hold`); the piece
  leaves the box only when it's set down, so closing Arrange leaves it there.
- **It arrives green**: with no thumb on it, it starts on the free spot nearest the floor's
  middle, searched in rings of grid steps, never red under nothing.
- **Arrange's tray lists the floor pieces too**, first, so a piece put back is set out again
  without leaving Arrange. Wall and ceiling pieces wait for g4d: the panel lists them, without
  Set out; the tray leaves them out.
- **A deeper knock** for a piece set down (the find's knock at 0.68 pitch, louder): a heavy thing
  on concrete.
- The job box's list remote carries the furniture in the box as its seventh value.
- Seen in Studio Play on the Galaxy A16: a pallet bought through the counter's remote, set out,
  saved across a rejoin, lifted by a tap and put back; the camp bed arriving green.

## D-338 A find stands on a piece's top, at the art's own height (S5-03g4c3, 2026-11-17)

The moment it serves: the pallet set down on the rug as a coffee table, you lift your moon lamp
out of the tray and it glows green on the pallet's boards and sets down there; slide the pallet
and the lamp rides with it; put the pallet away and the lamp goes back to the box with it
(Bloxburg's tabletop items, Animal Crossing's things on tables).
- **Four pieces take a find** (`Spots.PieceTops`): the milk crate, the pallet, the folding table
  and the steel shelf, each on its highest top in `Specs.Tops` (the shelf's top tier), kept a
  rim in as a find's top is. The camp bed and the floor cushion are sat on, not set on (their
  tops are seats, later); the shelf's lower tiers wait.
- **At the art's height, not the box's** (`Spots.pieceTop`): the top's middle is measured from
  the middle of the piece's box's foot. The shelf's posts stand 0.1 above its top tier and the
  pallet's box is 0.03 off its boards' middle, so a box height would float a find. Both the
  server and the screen take it through `Arrange.frameOn`, so they judge and draw alike.
- **What stands on a piece rides with it on the screen too**: lifting a piece puts a copy of each
  rider in its ghost and hides the drawn one, so the lamp glows green with the pallet, moves and
  turns with it, and slides back with it if refused; the drawn ones show again once it lands.
- **The save rule holds without a new save version**: rows save a holder before its riders, a
  move keeps each rider's pose on the top, Put away takes the riders back first, and a piece no
  longer owned drops its riders into the box on load (`tests/spots.spec`).
- No piece stands on a piece: a top is a "top" area, and furniture fits the floor only.
- Seen in Studio Play on the Galaxy A16 (`docs/art/S5-03g4c3-*.jpg`): the moon lamp on the
  pallet at 1.204 (the boards' 1.205), the pallet slid by the screen with the lamp aboard, the
  firefly jar aimed green onto it and placed, both back after a re-lay, all put away together;
  a jar on a crate's rim at 1.650. Not seen by a second client (`OWNER.md`).

## D-339 The lit pieces hang and glow, their light near you only (S5-03g4d, 2026-11-17)

The moment: home after a climb, you string the lights across your ceiling and hang the neon moon
on the wall; they glow warm as you walk in, and with the lamp off the room is a sleepover
(D-324). Precedents: Bloxburg's and Adopt Me's string lights and neon signs; The Sims' ceiling
lights hung from the tile you point at.
- **They hang by their art's origin**, as a find on a wall or the ceiling does (`Arranged.box`,
  `pivot`; nothing new): the moon's back flat on the wall facing the room, the lights' clips on
  the ceiling (0.0025 above, the art's gap). Footprints from `Spots.pieceBox`: the lights 9.65 by
  0.3 on the ceiling (not through its lamp), the moon 2.9 across by 2.8 up on a wall. Specs first.
- **Out of the job box onto their own surface** (`Spots.starts`): a ceiling piece onto the
  ceiling, a wall piece onto the back wall (the one you face coming in), then the side walls;
  the free spot nearest the middle, as a floor piece's.
- **A ceiling piece follows your finger over the floor under it** (ArrangeView's `aim`): the
  corner camera looks down on the room, so the ceiling is seldom on the screen. The disco ball
  find hangs the same way now.
- **Hung pieces don't collide** (`Arranging.drawPiece`); the server makes no light. Their Neon and
  the moon's clear backing were already `Home.paint`'s (D-335).
- **The light is the screen's** (`HomeGlows`, new): the three lit pieces nearest a point just
  ahead of the camera, within 40 studs (`Home.LitPiece`), each throw their `Specs.Glows` light
  from an attachment on the piece, warmed up and faded out over 0.8 s, picked every 0.25 s only
  while one is drawn. Three fills the room you're in; a home holds up to four strings and two
  moons, the rest glow without light. 24 studs left a 30-deep home's back wall dark. Always on,
  lamp or no lamp (the owner's to say, `OWNER.md`).
- **Measured** in Studio Play on the A16, in home 1 with both set out: 35 lights on the screen
  (D-271's 33, plus the two). Seen: both set out, laid again from the save after a restart,
  moved, the bulbs reading warm and swagged at phone size, brighter with the lamp off; the moon
  faint with the door up (its 1.1 drowned by the hall's light as the card's 1.4 was, D-332;
  2.4 didn't show with the door up either). Pictures `docs/art/S5-03g4d-lit-*.jpg`.


## D-340 The home's four sizes live in the save, and rows are carried between them (S5-03h1, 2026-11-17)

The moment it serves: you pay to grow your home and everything you'd set out stays where it was.
- **Four sizes** (`Home.Sizes`, pure, no requires so `Save` and `Spots` both read it): Small 8 by
  8, Medium 12 by 12, Large 16 by 20, XL 20 by 30 studs, across by deep, limits 25, 50, 100 and
  150. Each size's box is the slot's XL box cut down: as tall, its front at the door's frame,
  centred across (Small: 8 across, 7.75 in from the door's inner face).
- **Save v13**: `homeSize` (everyone starts Small) and `placedSize`, the size `placed`'s rows were
  laid at, both `Schema.oneOf(Sizes.Names)`. A v12 save loads Small, laid at XL (every home was the
  XL box). Growing writes only `homeSize`; whichever server lays the home next carries the rows
  (`Spots.carry`) and writes both the same, so a purchase granted after its save can't strand a
  half-moved room, on this server or after a hop.
- **Carrying**: a find on the floor or the ceiling keeps its place in the unit; one on a wall rides
  with its wall (as far along it, as high); a find on a top is the top's to carry. What the new
  size doesn't hold Brix drops as it loads, back in the box (only shrinking does that: the v12
  migration and the Studio test verb).
- **The room's own things a size doesn't hold** (`Spots.within`) are left out of its room: no top,
  no block, no warning. Until S5-03h4 lays the starter set by size, Small's room holds none of it
  (the set still stands at XL's places).
- **The unit's `HomeSize` attribute**, set by Arranging from the holder's save, is how the
  holder's screen builds the same room. Studio: `ArrangeTest:Invoke(player, "size", name)`.
- The test save went Small on load: the neon moon rode the back wall in; the string lights, the
  boombox, the camp lantern, the capybara and the moon lamp went back to the box. Checked in
  Studio Play from the server (Medium, XL and back, two boomboxes kept their places); the Arrange
  grid at Small not looked at on screen.

## D-341 Medium is sold for cash at the counter's third tab, written before it's yours (S5-03h2, 2026-11-17)

The moment: back from a good climb you've saved up, and the counter sells you a bigger unit;
your cash ticks down, the plan on its card opens out with the steel's roll, and your home is
Medium. Bloxburg's and Adopt Me's house upgrades, Animal Crossing's house loan.
- **The rules are pure** (`Home/Grow.luau`, `tests/grow.spec.luau`, failing first): Medium costs
  250 first-floor gates, 2,500 cash (ten neon moons; the owner's to set, `OWNER.md`). Refused when
  it isn't a size, when you're that size or bigger ("had": never sold smaller than you have, never
  twice), when it's a Robux size (Large and XL, "robux" until S5-03h3), or when you're short. A
  sale takes the cash and writes `homeSize` in one step; `unbuy` puts the cash back relatively
  (cash made meanwhile kept) and the size back only if it's still the one sold (a Robux size
  granted meanwhile is kept).
- **The server writes before it answers** (`Growing`, after furnishing): `GrowHome` is
  rate-limited (1 a second, a burst of 2) before its payload is read, then `Grow.ask`, one sale
  at a time ("busy"), `Grow.buy`, the save written at once; a failed write undoes the sale whole
  and answers "save". Only once written is the home set up again (`Arranging`'s new `relay`, the
  "size" test verb's clear and lay, which carries the rows) and `HomeGrown` answered. Growing
  only writes `homeSize` (D-340), so a server that stops before the relay loses nothing.
- **The counter's third tab, Units** (`UnitsTab`): a card per size from yours up (`Grow.ladder`):
  yours says Yours; a bigger one shows a plan from above (the slot's whole box faint, the size
  filled in the home's warm boards, the size you have outlined inside it, the door at its foot)
  that opens out from yours as the card deals, and its price. The purse is the furniture's, shared
  (`FurnitureTab.Wallet`). On "" the coins tick down, the roll-up door's roll plays while your
  outline opens out to the new size, a stop-bolt knock lands it, "More room!" pops and the button
  says Yours in gold; then the cards deal again from the new size, the smaller card gone. A short
  price is dimmed and its press nudges the cash. No grind yet: the walls are S5-03h5 and h6.
- **Seen in Studio Play on the A16** (Device Simulator): from the server, short refused "cash",
  Large "robux", Small "had"; with `DevSaveFails` a sale was undone (cash 3,000, Small); a real
  sale answered in 0.68 s after the write, cash 500, the unit's `HomeSize` Medium; a second sale
  "had". On screen: the tab's three words fit with room before the purse; the press held, the
  answer ("More room!", Yours, cash 500) and the re-deal to Medium alone. Test save put back:
  Small, cash 188. The plans are small inside the cards (the XL box frames them); judged
  readable, the owner to say.


## D-342 Large and XL are developer products, granted into the save before the counter answers (S5-03h3a, 2026-11-17)

The moment: you want the big unit now; at the counter's Units tab Large and XL show Roblox's own
price with the Robux mark, you tap it, Roblox's purchase box comes up, you buy, and the same steel
roll and "More room!" as Medium's land once it's kept. Adopt Me sells its bigger houses for Robux
at the same place its cheaper ones are bought.
- **Two rows in `Products`, the S3-02 way (D-206, D-207)**: `homeLarge` ("Large Unit") and
  `homeXL` ("XL Unit"), found on Roblox by their Dashboard title, each with its own live switch
  (`sellHomeLarge`, `sellHomeXL`), prices never in code. The ticket's "a product id per size, an off
  switch in Config" is met by D-206's titles and live switches rather than ids in Config: that's
  how every product here is found and switched off without an update. `Grow.Robux` names the
  offer per size; `Grow.owns` is the row's `owned` (that size or bigger), so Purchasing never
  prompts a size you have or a smaller one; `Grow.grant` is the row's grant: it only ever grows the
  home. Brix's Purchases writes the save before the purchase counts as granted, so a failed write
  or a hop never loses it, and the ledger never grants a receipt twice.
- **A late receipt for a size you have** (two prompts bought at once, Large landing after XL) is
  granted and counted, never refused (the Robux are spent, and a refusal would have Roblox send it
  forever); it changes nothing and is logged. Whether it should become something (cash back) is
  the owner's (`OWNER.md`).
- **The server answers only a screen that's waiting** (`Growing`): the counter's `GrowHome`
  naming a Robux size puts Roblox's prompt up (Purchasing's `prompt`), answering "had" or "off"
  when it can't. Closed unbought (`PromptProductPurchaseFinished` on the server, as Cut Free hears
  it), "closed" lets the card go at once; bought, Purchasing's `granted` (after the write) re-lays
  the home at its new size and answers "". A grant with no prompt up from this server (a hop, a
  late one) isn't answered: Roblox holds a remote's events until a listener connects, and the
  Units tab listens only once shown, so it would have played "More room!" on its first look.
  The card's own wait is `Shop.GrowPrompt` (30 s), a backstop for a lost answer.
- **The cards** (`UnitsTab`): `HomeSizeShelf` now carries each Robux size on sale to you at the
  price Roblox last reported (0 until it's in; fetched in the background at most once a minute,
  since each fetch counts as a look at the shop); a size switched off isn't dealt. A card shows
  the Robux mark and the price (Buy until the price is in, asked once more after
  `Shop.PriceWait`), in the warm Buy colours; the cash purse doesn't move. Studio shows both sizes
  on sale with no product and buys through a made-up receipt (`DevReceipt`), as the wraps do;
  `GrowTest "price"` makes up a price for judging the look.
- **Seen in Studio Play** (server and the client's remote, no screen: the Studio window's
  viewport read 1 by 1 and couldn't be captured): with every save write failing a made-up Large
  purchase was held in memory and not counted, the home left Small; once writes came back it was
  granted (bought 1) and the home laid at Large in 7 s. Large again and Medium for cash: "had".
  XL granted; a late Large receipt granted (bought 2), the home staying XL. From the client: the
  shelf dealt Small, Medium, Large, XL (Medium short, Large and XL "robux"); a Large press when
  Large answered "had" at once; XL answered "" 1.8 s after the press. Test save put back: Small,
  cash 188 (its `bought` now counts the made-up home purchases).

## D-343 Large and XL as gifts go through Brix's own gift: the friend's save first, a spare if they left (S5-03h3b1, 2026-11-17)

The moment: your friend's home is the little one, and from the counter you grow it for them, as
Pet Simulator and Adopt Me let you gift Robux things; their home opens out and they hear who did it.
- **Brix already had the gift** (Purchases' `gift`, `away`, at the pin `7f25310`), so no spare
  hand-off was built in this game: an offer with a `gift` grows the friend's home in their save and
  writes it before the buyer's ledger takes the purchase, so the buyer's ledger never holds a gift
  that isn't saved, and a receipt sent again (on whichever server holds the friend) gives nothing
  twice. The ticket's default (a spare in the buyer's save, spent friend-first) is kept only for the
  one case Brix hands back: the friend's save not held here when the receipt lands (they left
  mid-prompt). Then `away` puts a spare in the buyer's save (`spares.giftLarge` / `giftXL`, counted in
  `bought`), and their next Gift press of that size gives it with no prompt: the friend's home grows
  and their save is written first, then the spare is taken and the buyer's written; the friend's
  write failing undoes it (`Grow.ungive`) and keeps the spare.
- **Two rows in `Products`**: `giftLarge` ("Large Unit Gift", `sellGiftLarge`) and `giftXL` ("XL Unit
  Gift", `sellGiftXL`), `forAnother`, from `Grow.Gifts`. No `buyable` is handed to Brix: Brix asks it of
  the buyer's save when no recipient is given (the shop's price listing), and a buyer with a big home
  must still see the small gift's price. The server checks the friend's size itself before the prompt.
- **Who can be given one**: anyone in this server but you, whose save is loaded and whose home is
  smaller than the size (`Grow.friends`, by name, `Grow.FriendsMost` = 6), not only Roblox friends,
  as Pet Simulator's gifting works in a server. The owner's (`OWNER.md`).
- **A late gift** (two players gift the same friend Large at once) is granted and changes nothing,
  logged, as D-342's late receipt. Folded into D-342's owner question.
- **The wire** (`Growing`): `GrowHome` carries the friend's UserId after the size (`Grow.friendId`, a
  whole UserId, never trusted), answered on `HomeGrown` with that UserId last ("gone", "had",
  "notLoaded", "busy", "off", "closed", "save", or ""). The friend hears `HomeGifted` (size, the
  giver's UserId and name) once it's written and their home is set up again. The shelf now carries
  `gifts` (gift prices by size), `spares` (yours by size) and `friends` ({ id, name, size }).
- **Split**: the screen (the Units tab's Gift and the friend's own "More room!") is S5-03h3b2. Passes
  checks and the specs (Brix's real gift run over this game's save: given, written, once; a failed
  friend's write refused and given once after; late; a friend gone leaving a spare); untested in
  Studio.

## D-344 The Gift deals your friends as cards beside the size you give; their "More room!" drops in at the top (S5-03h3b2, 2026-11-17)

The moment, as Pet Simulator's and Adopt Me's gifts work: you tap the little wrapped box on Large's
card, the other sizes fold away and your friends deal in beside it, each a card with their face,
name and size and the price; you tap one, Roblox's box comes up, and once it's theirs their plan
opens out from their size to Large over the steel's roll, their face over it, "Sent!". On their
screen, wherever they stand, a banner drops in under the top bar with your face (a wrapped gift on
its corner), "More room!" and your name; the roll lands on the knock and it eases away.
- **Friends as cards, not a list inside one card.** On the Galaxy A16 a shop card is about 103 by
  157 points: six rows inside it would be too small for a thumb. Dealing a card per friend in the
  same row (the box you give stays first, its Gift pill pressed in gold; tapped again, back) keeps
  faces big and reads as "pick who", as Pet Simulator's player picker does.
- **The Gift pill is the box alone**, no word, beside the price (or the whole row on a size under
  yours and while friends are dealt). A gift you hold already (a spare) shows the box on the
  friend's pill instead of a price. Drawn from frames (`GiftMark`), not an emoji, so it sits in the
  home's colours.
- **No words on a refusal.** A friend already that big is dimmed and their tap does nothing; closed,
  gone or had settles the card and asks the shelf again, so a friend who left simply isn't dealt.
- **Studio's test players' UserIds are negative** (Player2 is -2), so `Grow.friendId` now takes any
  whole id but 0: before, the owner's two-player test would never have listed a friend. A negative id
  in a live game matches nobody here, so it changes nothing there.
- **Seeing it with one player**: `GrowTest:Invoke(player, "friend", name, size)` lists a made-up
  friend (Studio only); a gift to one lands after a beat with no save or prompt.
- Passes checks. In Studio Play on the A16 the friend's banner arrived with the giver's name, face
  and headline and hid after, no errors; Studio stopped drawing frames, so the motion, the Units
  tab's Gift and the friend cards weren't watched (the owner's two-player test, `OWNER.md`).

## D-345 Everything in a home moves, lifts and works (the owner, 2026-11-18)

The owner, trying the home in Studio: "All objects should be movable, placeable, and clickable. In
other words if I buy an end stand and put a lamp on it, I'd expect to be able to walk up and click
it. Right now none of the objects placed in the room are able to be interacted with." And: "This
is absolutely how I'd expect it to act. Anything in the room can be moved around. It makes 0 sense
to have a shelf in the middle, and the whole point is that players will be able to fully decorate
and modify a room to their liking."

As built up to b727b5c, the starter set (shelf, job box, mirror, clothes rail, rug, beanbag, floor
lamp) stood fixed in every home, so at Small the shelf stood mid-room; finds on it came and went
only through the job box's panel; and a find set out was looks only, since the home doc's idea 16
(finds doing things at home) was left for later, a find at a time. That's replaced:

- **Every piece in a home is furniture you arrange.** The starter pieces become rows in the home's
  layout like bought furniture: lifted, moved, turned and put away in Arrange, saved. A new home,
  and a home that grows, starts from a default layout for its size (this replaces S5-03h4's fixed
  set by size). A home laid before this gets its starter pieces as rows where they stood.
- **What stays with the room** (my default, `OWNER.md`): the ceiling bulb and the light switch by
  the door, as a real unit's wiring does. The job box moves but can't be put away, since it holds
  everything. The shelf's spots, the mirror's reflection and the rail's hangers go wherever their
  piece is set.
- **Take anything directly.** Outside Arrange, walk up to any find set out in your home (on the
  shelf, a table, the floor, a wall) and Take puts it in your hands, as on a climb. In Arrange, a
  find lifts straight off the shelf or any top.
- **Every find set out keeps its button.** Walk up to it and its own verb shows, the climb's press
  (Switch for a lamp, Play for the boombox, Wind for a wind-up): all finds at once through their
  existing rows (`Finds/Use`), not one at a time. Lights still under the phone's caps (D-271).
  Friends in your home can press a find's button but can't move or take anything (my default,
  `OWNER.md`; Animal Crossing's visitors use the furniture but don't pick it up).
- **Furniture works too**: sit on a crate, the beanbag, the cushion, the camp bed (the Seats
  already queued).
- **Precedents**: Animal Crossing (everything in your house moves, the pieces you start with too,
  and you walk up to use them) and Bloxburg's build mode (every object movable; lamps switch).
- **Order**: this comes next, as S5-03i, before the rest of the sizes: there's no point laying
  fixed pieces by size when they're about to move. S5-03h4 folds into S5-03i1.

## D-346 Every home's own pieces are rows, laid by size (S5-03i1a, 2026-11-18)

The moment: you walk into your new unit and it's a room, not a store: the shelf against the back
wall, the job box along the left wall, the mirror on the right, nothing in your way, and every one
of them yours to lift and move (D-345; Animal Crossing's house, Bloxburg's build mode).
- **Rows like bought furniture** (`Furniture.Starter`): the job box, shelf, mirror, clothes rail,
  rug, beanbag and floor lamp are pieces under the furniture mark ("Shelf:Furniture#1"), one each,
  never sold (`check` says "unknown"), never on the bought counts, and never counted against the
  size's limit (`Spots.setOut`). The job box is `kept`: never put away.
- **A layout per size** (`Home.Layout.default`, pure, from the floor's size and the pieces' boxes):
  the shelf centred on the back wall facing the door; the job box (its back 0.8 off the wall for
  its lid) then the floor lamp along the left wall; the mirror (its foot off the wall as it leans)
  then the rail along the right wall, each from the shelf's front toward the door; the rug in the
  floor left over, turned whichever way fits; the beanbag on the rug's far corner. A piece the
  floor can't hold starts in the job box: Small holds the shelf, the box and the mirror (the rail,
  rug, beanbag and lamp in the box); Medium and up hold all seven. Every row is judged whole by
  Brix in the spec at every size; the job box always comes first, so it always stands.
- **The rug is floor** (`Spots.pieceTop`): its top is a floor-kind area, so the beanbag, a crate
  or a find stands on it, and rides it when it moves (Brix has no layers; my default, OWNER.md).
  The shelf's and the job box's tops are their pieces' tops now, the same boxes as the fixed
  ShelfTop and JobBoxTop, so a find on one keeps its place.
- **A home laid before** (save v14's `starterLaid`, false in a new save and a v13 one): the
  server lays the rows as it sets the home up (`adopt`): each piece where it stood if the size
  holds it, else where the layout has it, else in the box; the beanbag back on the rug if it
  stood on it; finds on ShelfTop and JobBoxTop moved onto those pieces' rows, where they were.
  A find in a piece's way goes back in the box as Brix loads (nothing lost). XL homes keep the
  set where it stood; Small ones, which held none of it (D-340), get Small's layout.
- **Growing keeps your arrangement** (`grow`): a starter piece against a wall (its edge within
  0.9 studs) rides that wall as the home grows, in a corner both; everything else is carried as
  before (`Spots.carry`). D-345's line said a grown home starts from the default layout; I kept
  the arrangement instead, as the owner's "fully decorate and modify a room to their liking"
  reads, and a reset would box the finds in the defaults' way (OWNER.md).
- **Split**: the server and the views are S5-03i1b, lifting them in Arrange S5-03i1c. Nothing in
  the game uses the rows yet; save v14 only adds the flag.

## D-347 The server lays every home's own pieces as rows, and each piece's job follows it (S5-03i1b, 2026-11-18)

The moment: your Small unit's shelf stands on the back wall, not mid-room; an XL home laid before
keeps its set where it stood, with the finds on its shelf and box.
- **Laid by the server** (`Arranging`): a save whose `starterLaid` is false adopts the pieces once
  (`Layout.adopt`, after carrying its rows to the home's size) and is written with the flag true;
  a home that changed size since grows them (`Layout.grow`: a piece against a wall rides it);
  the job box's row always loads first (`Layout.boxFirst`).
- **Free, one each**: the starter pieces are settable and boxed one each (`Layout.settable`,
  `Layout.boxed`), so a put-away rug is in the job box's list. Brix's own count now holds them,
  so the server refuses a new find or bought piece past the size's limit itself ("full", Brix's
  word, so the screen's answer is unchanged).
- **The job box is never put away**: `PutAway` answers "kept" (`Spots.Refusals.Kept`); the
  screen's press does nothing (i1c).
- **Drawn by the spec's box**, not the measured one (`Arrange.starterPivot`), so a row stands
  exactly where `Layout` laid it and the mirror keeps its lean (its model pivoted upright at its
  foot, its glass marked with the unit's door for MirrorView's walls). A starter piece keeps
  `Home.piece`'s collision: the rug and the beanbag's seat never stop you.
- **The fixed set is gone**: `Arrange.room` holds only the ceiling lamp; no ShelfTop or JobBoxTop
  areas. A spare home shows Small's layout (`Lobby.front`), taken away while it's held and put
  back when it's let go (my default: the door's shut and padlocked, so it's rarely seen).
- **Each piece's job by its row**: `Arranging.drawn` fires after every lay and change; Shelves
  stands the finds in the drawn shelf (they're its children, so they ride it), JobBoxes wires the
  drawn box's Open button and moves it with the box, Rails hangs from the drawn rail, the lid's
  riders are what stands on the box's row (JobBoxView), and a floor lamp drawn later joins its
  home's switch (HomeLights).
- **Not seen yet**: Studio was in another session's Play; the pass moves to S5-03i1c, first.

## D-348 Your own pieces lift like anything else; the mirror finds a wall, the box keeps its lid's room (S5-03i1c1, 2026-11-18)

The moment: in Arrange you lift your shelf, finds and all, carry it off the middle of the room to
the back wall and set it down with a thud; carry the mirror to another wall and it turns its back
to that wall and leans there, still showing you; the job box slides up to a wall and stops where
its lid still opens. Seen in Studio Play at Galaxy A16 size on the XL test save.
- **A home's own piece is lifted as a find is** (`ArrangeView`): a tap on it (or on a find in the
  shelf, which is the shelf's child) lifts it with what stands on it; it stands by its spec box
  (`Arrange.starterPivot`), as the server draws it. The job box has no Put away button (my
  default over a press that does nothing: no copy for what's plain on screen).
- **The mirror leans on a wall** (`Layout.leanTo`, `stands`, `Lean`): carried within
  `LeanReach` (2 studs) of the back wall or a side wall, it turns its back to the nearest and
  stands at its lean (its foot 0.79 off, as it stood in XL's room, so its top rests on the wall);
  farther out, on the rug or a top, or against the door, it's red and the server refuses it
  ("wall"). It turns itself, so Turn is hidden while it's held. As Animal Crossing's and The
  Sims' wall pieces find the wall you point at.
- **The job box keeps its lid's room** (`Layout.Clear`, `clearOf`): its back stands at least
  `BoxOff` (0.8) off the wall behind it, door included; pushed nearer it stops at that line, and
  the server refuses one nearer. Found in the pass: pushed flush, the open lid went into the wall.
- **What follows a moved piece**: the job box's lid swings about the box's hinge where it stands
  now (`JobBoxView.frame`); the floor lamp's nearness reads its shade where it is now
  (`HomeLights`); a mirror hidden while it's lifted gives up the picture (`MirrorView`); the rail's
  hangers and Wear, the box's Open and the mirror's Try on are the piece's children, so they ride.
- **Not seen yet** (S5-03i1c2): the box's stop at its line, a true rejoin, a resize, the rail moved.

## D-349 A home that shrinks takes its size's layout; the job box always stands (S5-03i1c2, 2026-11-18)

The moment: you rejoin and your shelf is on the back wall where you put it; your home changes
size and it's still a room, tidy, nothing lost: the box by the door opens clear of the wall.
Seen in Studio Play at Galaxy A16 size on the XL test save (captures `docs/art/S5-03i1c2-*`):
the job box pushed at the left wall stopped at its line and opened clear; the clothes rail moved
along the right wall with its hangers, the hard hat and Wear (Wear put the hat on); the rug put
away took its beanbag into the box first and both set out again; a true Stop and Play laid all
of it where it was left, six finds in the shelf.
- **Found in the pass**: made Small, the XL arrangement went into the box whole, the job box
  too, and nothing ever laid the job box again. Small sits at the door's end of the unit, so
  every piece carried by its place in the unit fell outside it, and the shelf, 1.25 off-centre,
  was wider than Small allowed there.
- **Grown, your arrangement keeps** (`Layout.grow`): a piece against a wall rides it as before,
  now kept inside the new floor as far along its wall as it fits; a piece touching both side
  walls (Small's shelf) keeps its middle rather than riding one. **Shrunk, the size's own layout
  comes first**: each of the home's own pieces takes the size's layout spot if it's clear, else
  its own place kept inside the floor, else it goes in the box. Small keeps the job box, the
  shelf and the mirror, as a new Small home has them. My default, `OWNER.md`: no home shrinks
  in play today (sizes are only bought up), so this guards the test hook and any later downsize.
- **The job box always stands** (`Layout.withBox`): a save without its row gets it back where
  the size's layout has it, first, as the home is laid. The test save had lost it to the shrink.
- **Not chosen**: a shrunk home keeping your walls for every piece. Tried by the clamp alone,
  the job box rode into the back corner and pushed the shelf into the box.

## D-400 A find that lands after you chose what to hold keeps your hand where you put it (F-G1e6q2, Nov 17)
- **The rule**: a marked box's find reaches your hand as its reveal ends (about 2.4 s for an
  Epic). If you switched slots or put your tool away since the box opened, the find goes into a
  free slot (its pick-up sound plays, its slot fills) and your hand stays on what you chose; else
  it's in your hand as before. Picked up off a floor or handed over, it still goes in your hand.
- **A press while your own switch is on its way** waits for it and plays on what the switch put
  in your hand (the button squashes at once), as action games buffer an input; it was going to
  the find you held before on your screen while the server pressed the new one.
- **Precedents**: Lethal Company puts a picked-up item in your hand, but never moves your hand
  after you've moved it; input buffering is every action game's (fighting games, Fortnite's
  weapon swap).
- **The jar** was never dark: its fireflies blink by its art, so its real lights are off between
  blinks. Whether it lights a unit enough is a feel question for the owner's look at the Lights.

## D-401 Monsters by lowest floor: a seeded mix each floor (S4-02, Nov 17)

- **What:** each monster's row (`KeeperRows`) carries `lowest`, the lowest floor it turns up on,
  and `share`, the chance a floor above that has it at all. `KeeperMix.on` rolls one number per
  monster for each floor, from a Random seeded by the climb's seed and the floor's number (salted
  away from the layout's and the deal's seeds), and the deal places only those monsters
  (`Deal.new`'s `cast`; without one, everyone who has joined, as the specs and the test hall lay
  floors). As DOORS' entities each start at a door number and then turn up at random past it.
- **Numbers:** the Mannequin on every floor (share 1): it guards a note on each (D-072) and is the
  only one that hunts. The Packrat from floor 3 on about three floors in five (0.6), where it was
  on every one. No monster is promised on its lowest floor. Both go to `OWNER.md`.
- **Room for the next-floor cards (S4-03):** a floor version passes a `Lean`, its own chance for a
  monster in place of the row's share (1 brings it, 0 keeps it away). It never brings one below
  its lowest floor and moves no other monster's roll. Whatever a version asks, a floor keeps one
  monster that hunts (the closest roll comes in), so the guarded note always has its guard.
- **Fixed draw order** (`KeeperMix.Order`): a new monster goes on the end, so old seeds keep their
  floors' monsters; the spec checks every row is in it.

## D-402 Trapping pays at the gate, and a trapped monster keeps its place (S4-04, Nov 17)
The player moment: slamming a door on a monster stops being only an escape and becomes
something the team goes for, and the gate pays it out where everyone sees it. As R.E.P.O.'s
beaten monsters drop an orb worth money (D-188).
- **What counts.** A monster the team has shut in a unit on the floor at the instant the gate
  hits its post: one a door came down on awake (a slam or a close), a sleeper the tap's missed
  bang woke shut in, the Packrat baited in and shut. One out again before then (burst, or its
  door opened) doesn't count (`Keeper.shutIn`). One the floor woke behind its own unopened door
  (a wave or a wrong code) doesn't count while it's still in: the team never trapped it
  (Keepers' entry `wokeIn`).
- **The pay.** `Pay.Trap` (5, the owner's starting guess) a monster, on top of the floor's pay,
  to every rider paid; nothing while wrapped, and a ride back to a paid floor pays its traps no
  more, as the floor's pay doesn't (`Pay.owed`).
- **On your screen.** No words: after the floor's pour, one pop a monster beside it (left,
  right, then further out), each with the slam's bang pitched down as from inside a unit, a
  chink, and five coins that hang and fly to the count, the "+10" swelling to "+15", "+20" as
  each lands (`Pay.parts`, CoinView). The ticks climb a little higher each pop.
- **The cap.** The deal's cap of awake monsters (`awakeOn`) now counts the ones the team shut in,
  reversing D-071's third point: with pay on traps, a trapped one freeing its place let the next
  door hold a fresh one to trap again, a farm. The owner's reason for counting it (trapping makes
  the floor easier to search) stands. A wave's hold (`Waking.free`) still counts only the loose
  ones, and one the floor woke shut in still waits for a place, as before.

Not chosen: a bonus only for the monster you lured in (no precedent, D-071); a pop that names the
monster (no art for its face yet, and the bang already ties it to the trap).

## D-403 The next-floor cards: the versions and the vote (S4-03a, Nov 17)

The owner: the next-floor cards are the mechanic that makes no two climbs the same. Split into
four pieces (ROADMAP S4-03a to d). Piece a, built:

- **Versions are data rows** (`NextFloor.Versions`): name, lowest floor, pay, and each bend as a
  plain field the floor's systems read (`dark`, `monsters`, `padlocks`, `caughtToLobby`, `lean`).
  The GDD's four, nothing invented. Pay is a share of the floor's own gate pay (`payOf`), as Deep
  Rock Galactic's warnings add a percentage, so a version is still worth it on floor 20.
- **Three dealt from the climb's seed and the floor** (`NextFloor.seedOf`, its own salt), so a
  climb replays exactly; never for floor 1 (the ride up from the lobby has no choice); a version
  only from its lowest floor. A tie and a ride nobody pressed on both go at random among the tied:
  a vote with no presses is a three-way tie at none, as a lobby's map vote picks.
- **The vote ends on the cable's second knock** (`NextFloor.Closes` = `Ride.Clanks[2]`, 8.9 s),
  not as the ride ends: riders are handed to the next floor's car at the third knock (13.4 s), and
  the floor must be dealt and streamed to them first. About nine seconds to pick.
- **The halls are built at the code, the deal goes on after the vote.** `FloorBuilder.lay` no
  longer takes the deck; `FloorBuilder.dress` puts the deal's padlocks, mark and breaker on a laid
  floor (a padlock set late is seen by Doors and every screen, as a player's padlock is). Climbs'
  `build` (yields, at the code, as before) and `deal` (doesn't yield, with the version) replace
  one `lay`; a climb's first floor is both at once. The deal still carries on from the layout's
  Random, so a floor nobody picked deals exactly as before. Laying one floor per version was
  turned down: three floors' halls on a phone-sized server for one that's used.
- **The server owns the vote** (`NextFloors`): the offer, presses and winner go on the riding
  car as attributes for screens; a press is checked for type, range (lit on your car), ownership
  (you rode as its gate shut, not wrapped) and rate (`NextFloor.Limit`), one each, changeable
  until the knock. A car that comes back keeps its pick: no second vote for the same floor.

Not chosen: closing the vote early once everyone has pressed (it would stop a friend changing
their mind); a fixed plain version among the three (the GDD: some rides all three are bad).


## D-404 The next-floor cards' faces: a picture of each floor, in its own light (S4-03b1, Nov 17)

S4-03b split in two: b1 the faces, b2 the cards on the panel (the session's room went on proving
S4-03a live and on the art). Built in b1:

- **S4-03a works live.** Studio Play, seed 7 from floor 1: the code punched, the gate shut, and the
  car's `NextFloorOffer` lit three versions as it lurched off; a press, then a change of mind, each
  showed on `NextFloorPresses` within a frame; a junk name did nothing; on the cable's second knock
  (8.9 s) `NextFloorPicked` named the last press, and Output said "floor 2 of climb 7 has
  Mannequin, picked TwiceMonsters" before the riders changed cars at 13.42 s. No fix needed.
- **One picture per version, no words** (`art/cards/`), as Hades shows each door's reward: the
  hall's caged bulb dead in the dark (PowerOut), two padlocks on a steel door (TwicePadlocks), two
  Mannequins at the end of a hall (TwiceMonsters), the car far down its shaft (CaughtToLobby, the
  way back down to the lobby). Staged from the game's own exported models, so a face matches what
  you meet on the floor, and rendered with the unit's render kit.
- **Each face its own colour of light**: cold blue, warm bulb, sick green, emergency red. The three
  cards on a panel tell apart before anyone reads a picture, on a phone, in a nine-second vote.
- **The face is data on the version's row** (`face`, an uploaded image's ID), as a keeper's row
  carries its look: a new version brings its own picture. A spec checks each has its own.
- **Card size** 512 by 640 (4:5, portrait): about 340 pixels wide on a Galaxy A16's card, so the
  picture stays sharp; the phone-size sheet (`art/sheets/cards-phone.png`) is where they're judged.

Not chosen: words or a symbol on the face (the owner: no text that explains a rule); a hand-drawn
icon (art is code); a wide view of the whole floor per card (at 130 points the detail reads as
mush; one thing, big, reads).


## D-405 The next-floor cards on a rider's screen (S4-03b2, Nov 18)

- **Three cards up from the bottom middle as the car lurches off** (`Ride.moves()`), between the
  thumbstick and the jump button, 44% of the screen's height (78 by 123 on a Galaxy A16): big
  enough to tap and to read a picture, the top half left for the shaft. Proven: Hades shows each
  door's reward before you pick; a lobby's map vote shows who voted for which map.
- **No name on a card**, only its picture and its coins ("+12" by the coin): the owner's rule
  against text that explains a rule, and D-404's pictures carry the meaning.
- **Your head, and every rider's, on the card they pressed**, yours first with a light ring:
  avatar headshots dropped on with a bounce, carried across on a change of mind. A press shows at
  once and the car's word takes over within 0.6 s (the server owns the vote).
- **Each card glows in its face's own colour** (each version's `light` row): yours fully, one
  only friends are on faintly. At the knock the losers go dark and sink, the winner flares
  (white, a punch, the elevator's ding), glides to the middle and breathes until the gate opens.
  The state is kept on the screen, not the car: the car the vote was on is cleared at the
  13.4 s change of cars.
- **The tool wheel slides away while the cards are up** (`Tools.CardsStowAttribute`, its own so
  the machine's menu shutting doesn't bring it back under them), and the cards tuck away while
  the machine's menu is open, so the machine the ride sells from is never covered. Keys 1 to 3
  and the d-pad press them on a computer or pad; the mouse is freed for the vote.
- Not chosen: a fanned hand of cards round the wheel's button (taps land on a tilted card's
  unturned box); cards on the car's 3D panel (unreadable at phone size from across the car).
- The padlock face's open shackles come from the padlock model itself (built open), so the fix
  is the model's, in ROADMAP's polish list, not a card re-render.

## D-350 Take a find straight from where it stands (S5-03i2a1, 2026-11-18)

The moment: you walk up to the teddy in your shelf, press Take, and it hops off its cubby into
your hand with its pick-up sound, as a find on a climb comes up off the floor (D-345's "Take
anything directly"; precedents: Animal Crossing's house, where you pick up what you set out, and
the climb's own Take on a find lying loose).
- **One button, the climb's word.** Every find in a cubby and every find set out (not furniture,
  not the home's own pieces) carries a Take button (`Takes.offer`). Only its holder's screen shows
  it, and never while Arrange is open (your tools are stowed then). Friends see none (D-345).
- **Never lost or doubled.** The server checks the press (rate limit, the cubby or row is the
  presser's own and still drawn, within reach, not wrapped, a hand free: `Slots:room`), then in
  one step stamps the copy taken, frees the spot (`Save.unshelf`) or lifts the row
  (`Spots.lift`) and puts the find in their hands out of the box (`Slots:unbox`, marked as from
  it, D-293). What you own never changes; a crash before the autosave leaves it on its spot, one
  after leaves it in the box. Lune specs: `tests/hometake.spec`.
- **Hands full: nothing happens** (my default, OWNER.md; no refusal text, the hands are on
  screen). What rides on a find you take goes back in the box, as a put-away does.
- **The flight:** the copy is stamped with its taker (`Take.Attribute`) and stays a moment
  unseen; every screen flies its own copy: a quick hop (0.55 studs, 0.12 s), then into the hand
  (0.3 s), turning a little and growing back from a cubby's shrunk size; the pick-up sound plays
  as it lands, heard by friends close by. Your hand stays empty until it lands (InFlight), then
  it's simply there. Numbers in `Shared/Home/Take`.
- **Split** (context): i2a1 this, built and green; i2a2 sees it in Studio Play and captures it.

## D-351 Every find set out keeps its own button (S5-03i3, 2026-11-18)

The moment: you stand your moon lamp on the folding table, walk up, press Switch, and it lights
(D-345; Animal Crossing's lamps and Bloxburg's switches work where they stand).
- **The climb's own word, every find at once** (`Home.Press`, `tests/homepress.spec`): a find set
  out gets its `Finds/Use` row's press (Switch, Play, Hug, Wind, Squeeze, Light...) beside its
  Take, F on a keyboard and Y on a pad, the two a button's width apart (`Press.Side`). Its press is
  FindUses' own stamp (`setOut`), so every screen plays it as from a hand, and at home a light
  never runs down (D-259). Real lights stay under the screen's cap (`Use.LightsShown`, D-271).
- **No button where the press needs the hand** (my default, `OWNER.md`): the hard hat's Wear, the
  RC car's Drive and the diecast car's Push (it would roll off and just stop dead): Take them
  first. A wind-up that walks plays on where it stands, as one stopped by a wall (`Press.stop`).
- **Anyone in the home may press** (D-345): its holder or a friend, never move or take. Only a
  player inside the home's walls or in its doorway sees it or is heard (`Press.inside`, the room
  on the home's folder), so a neighbour through the wall never does. Hidden while your Arrange is
  open, and while a press would do nothing (a lit tea light, a jack mid-tune).
- **Not kept yet** (queued): a lamp left on is off after a rejoin or a re-lay (the stamp is the
  model's, not the save's); a lit find taken comes into your hand unlit.
- **Seen in Studio Play at Galaxy A16 size** (`docs/art/S5-03i3-*`): the lamp's Switch and Take
  side by side; Switch stamped On, its light lit, never running down. Found and fixed: the take
  screen grabbed a find's first button, now its Switch, so Take never showed (HomeTakeView finds
  Take by its attachment). After the fix a real Take press lifted the boombox off the job box
  into hand slot 1 (S5-03i2a2); the floor teddy went to slot 1 through the server hook.

## D-352 A find lifts straight out of your shelf in Arrange (S5-03i2b, 2026-11-18)

The moment: in Arrange you tap the teddy in its cubby and it rises out at its full size, not the
shelf; you set it on the folding table beside the lamp and the cubby stands empty (D-345: "in
Arrange, a find lifts straight off the shelf or any top"; Animal Crossing and Bloxburg lift the
thing you tap, not what it stands in).
- **The tap picks the find over its shelf** (`Shelf.hit`, `tests/homeshelflift.spec`): cubby
  finds stand unpickable (no collisions or queries), so the screen tests the ray against each of
  your cubby finds' boxes and lifts the nearest one met no further than `Arrange.Feel.CubbySlack`
  (0.35 studs) past whatever the tap lands on. A tap on the boards beside them lifts the shelf
  with its finds riding, as before. **While the home holds all it can**, a tap on a cubby find
  lifts the shelf (my default, `OWNER.md`: as the tray's cards won't lift then either).
- **It grows out of its cubby**: the ghost starts where the cubby's copy stood, at its shrunk
  size, and eases to its own size as it rises toward your finger (onto the nearest free spot when
  the finger isn't over one); × slides it back in, shrinking to the cubby's size.
- **One step on the server** (`Spots.offShelf`): Place and Put away carry the cubby's spot after
  their words (Place(name, on, x, y, turn, spot), PutAway(name, spot); the spot a whole number on
  the shelf, the put-away's name a find's, `Spots.askName`). Set down, the find comes off its spot
  and is placed as a find from the box is; refused, it's back on its spot as it stood, still new;
  a spot that no longer holds it is refused (`notShelved`) before anything moves. Put away just
  empties the cubby into the box. Either way the shelf is laid again. Each cubby copy now carries
  its saved name (`Shelf.FindAttribute`), so a Gold is lifted, and re-laid, as itself.
- **Seen in Studio Play at Galaxy A16 size** (`docs/art/S5-03i2b-*`): the teddy lifted out of its
  cubby and set on the folding table (the server: Teddy#1 on the table, spot 2 empty, nothing
  doubled); the boombox lifted out and Put away (back in the box); a tap on the board beside the
  wind-up mouse lifted the whole shelf; × let it go. No errors in Output.

## D-406 Each next-floor card felt on its floor: the deal and the pay (S4-03c1, Nov 18)

The team's pick has to be the floor it gets, from the moment the gate opens, or the choice means
nothing (the owner: the cards make no two climbs the same). S4-03c split in four: c1 the deal
and the pay (this), c2 the arrival and the version's own pop, c3 the power out, c4 caught to the
lobby.

- **The deal takes a bend** (`Deal.Bend`, `Deal.new`'s fourth argument; the version's row is
  one). It changes counts and chances, never what the seed draws, so a picked floor keeps its
  code, its guard and every door a plain floor padlocks. A floor nobody picked deals as before.
- **Twice the padlocks** is exactly twice a plain floor's count (as many as there are doors past
  the lobby's hall), not the doubled share rounded: on floor 2 that rounded 3.5 to 3 against a
  plain 2, which doesn't read as twice.
- **Twice the monsters** is three things, so the floor is twice as dangerous whichever way you
  meet them: twice each unit's chance of a sleeper (floor 3 in Play: 9 asleep, about 4 plain),
  twice the awake ones behind a door you lift (out of its empty share), and twice the floor's
  cap on loose ones (`Waking.cap`, used by the deal and by the waves' hold), never past five,
  one short of what a phone carries (`Waking.AwakeMost`). The Packrat's lean (D-401) brings it
  from its own lowest floor. As DOORS' modifiers raise how often its entities come.
- **The version's coins** go into the gate's pay (`Pay.owed`'s `picked`, `NextFloor.payOf`), on
  top of the floor's own and its traps, under the same rules: nothing while wrapped, nothing
  again for a ride back. On screen they pour with the floor's coins until c2 gives them a pop.

Not chosen: doubling the waves' size or pace (the sleepers are already twice as many, so the
waves find twice as many to wake); a cap past five (a phone's limit, D-156).

## D-407 The picked card flies into its floor, and pops its own coins at the gate (S4-03c2, Nov 18)

You must know which floor you chose before you see it, and its coins must read as its own.
- **The arrival.** As the gate starts to fold open (`Ride.opens()`), a copy of the winning card,
  heads and all, lifts (0.14 s), then flies into the gate's opening on your screen (0.42 s,
  speeding up, shrinking to a tenth, tipping in), to the middle of the screen if you're facing
  away. There it bursts in its own colour: a ring, a wash of that light over your view, and the
  hall six studs past the gate lit in it for a breath (one PointLight, this screen only). As
  Hades' door reward flies to you as you walk through. Numbers at the top of NextFloorView.
- **Each version's own sound** (`NextFloor` row `sound`, from sounds the game already plays): the
  power's out is the hall lights' dying whine; twice the padlocks, two shackles snapping; twice
  the monsters, two Mannequin steps pitched down; caught to the lobby, the low hit of being
  caught. Heard at the arrival and again at the pop. My defaults (OWNER.md).
- **The pop.** `Pay.parts` has a third part, the version's coins, taken first so they always
  show; GatePay's remote carries the version's name and coins. After the pour and the traps'
  pops, the card pops up small over the pour (a fifth of the screen tall) in its glow with its
  sound, holds half a second, flashes white and bursts into its coins, which hang lit in its
  colour (the coins' own light tinted) and fly to the count, ticking higher than the traps',
  the "+" swelling to the whole pay. As Balatro scores each joker in turn after the hand.

Not chosen: words or a name on the pop (D-405); the version's coins pouring with the floor's
(c1's stopgap: you couldn't tell what the pick earned).

## D-408 The power's out: the floor opens black, and its breaker brings it back (S4-03c3, Nov 18)

The dead-bulb card has to be felt the moment the gate rises: black halls, black units, the car's
light the only one, and somewhere out there the box. The team's job is to find it and throw it,
as Lethal Company's breaker brings a facility's power back. My default (OWNER.md).
- **The box is hung thrown** (FloorBuilder's `hangBreaker` with `deck.bend.dark`; `Deal.Bend`
  carries `dark`, the deal itself unchanged). Breakers finds it off and cuts the floor's power
  zones as a Mannequin's throw does, so the existing breaker does everything else: the hold
  brings the halls back, BreakerView's red lamp pulses in the dark (the one glow out there).
- **The units' bulbs are on that breaker on that floor only.** Breakers mirrors each box's power
  on the floor it hangs on (`Breaker.FloorAttribute`, so a screen needn't have the box streamed
  in); `NextFloor.dark(version, power)` says a floor is dark, and UnitLights reads it: a lifting
  door's switch clicks and the bulb stays dead; back on, each open unit's bulb stutters on up to
  `UnitLight.BackRagged` late, no click. A Mannequin's cut on any other floor leaves units lit, as
  before (S2-02); on this one a re-throw kills them again.
- **The Mannequin doesn't fight it.** The dark start counts as the floor's first cut (Keepers'
  `cut`, `add`'s `dark`), so after the team's switch-on its Mannequins wait the usual 45 s and go
  at the floor's own odds, not D-158's eager first-cut ones. A Mannequin already walking to a box
  that goes off is called off by the zero chance (`Keeper.offer`, unchanged).
- Every floor the card is dealt for has a box (`tests/powerout.spec`, floors 2 to 60).

Not chosen: no breaker on that floor (the dark would last the whole floor with nothing to do
about it but the torch's battery); unit bulbs on every floor's breaker (changes S2-02's floors).

## D-353 Sit on your furniture by its button (S5-03i4, 2026-11-18)

The moment: you walk up to the milk crate in your home, press Sit, and your view glides down into
the seat with a hollow knock; the beanbag gives under you with a soft puff, on the blanket by the
pallet you sit low on it, and a friend lands on the camp bed beside you (D-345: "sit on a
crate, the beanbag, the cushion, the camp bed"; Adopt Me's and Bloxburg's furniture: walk up,
press Sit, jump to get up).
- **A button, not a bump** (`Sits`, `Home.Sit`): every seat of a home's furniture is a Roblox
  Seat you can't sit on by walking into it (no touch), with a Sit button over it (R on a
  keyboard, B on a pad; Take is E and a find's own press F, so a teddy on the bed keeps its Take
  beside the bed's Sit). Walking across the blanket never drops you onto it. The lobby's benches
  and planters still seat you as you walk in, as before.
- **Where you sit** (`Sit.Seats`, `tests/homesit.spec`): the crate's lid at its top (1.65, feet
  on the floor); the beanbag low and a little back (1.25, it swallows you); the folded blanket at
  its top (0.44), low (cross-legged waits, below); the camp bed two side by side along its front edge, 2 studs apart,
  clear of the pillow, on the canvas where it rises toward the rail (its top plus 0.3). Every seat
  faces out its piece's front.
- **Who may sit** (`Sits`): anyone in the home, its holder or a friend, alive, not sat already, the
  seat free, within reach (`HomeUses.near`, as a find's own button). Each screen shows the button
  only to a player in that home with Arrange shut (`HomeSitView`). Arrange's lifted ghost has no
  seats or buttons. A piece moved or put away stands its sitters up first, so nobody rides a crate
  across the room.
- **Every landing answers on every screen** (`HomeSitView`): the seat's sound where you land (the
  crate a wood knock, the cushions a low cloth puff, the bed's canvas a shorter rub; getting up the
  same at half), and the part under you squashes and springs back (the beanbag 12%, the blanket
  25%, the canvas 10%; the crate is wood and doesn't). Your own view glides from where you stood
  into the seat over 0.35 s (`Humanoid.CameraOffset` eased to nothing).
- **Cross-legged on the blanket isn't built** (seen in Play): a body sat on an anchored Seat has
  its legs written by its Animator after any script's joint write (PreSimulation and PreRender
  both lost), so the blanket shows Roblox's sit, low, for now. It needs an animation of our own
  played over the sit (queued; an uploaded animation is the owner's).
- **Seen in Studio Play at Galaxy A16 size** (`docs/art/S5-03i4-*`): Sit over the crate beside the
  folding table's Switch and Take; a real R press sat you on the crate (the view glided 1.7 studs in
  over 0.3 s); Space stood you up; a real R press sat you on the blanket; a press sat you on the
  camp bed's second place; the server sat you on the beanbag, sunk in on the rug. Not seen: a
  friend's landing, the sounds by ear, the squash frame by frame, the bed's first place by a press.
- **The camp bed is sat on, not lain on** (my default, `OWNER.md`): Roblox Seats only sit, and lying
  down needs a sleeping pose and a way to get up that we haven't seen work here: an untested bet
  for the owner.

## D-354 A smaller home ends at movable steel walls under its own plaster (S5-03h5a, 2026-11-18)

The moment: you buy your first unit and it's snug, the walls close round you; grow it and the room
is plainly bigger (Animal Crossing's house rooms by size; real storage buildings cut units of any
size out of one floor with movable steel walls).
- **Three movable walls per home, no new mesh** (`Home.Walls`): the left partition, the back wall
  and the right partition, each a 1-stud steel slab (DiamondPlate, the unit kit's grey) under a
  clone of the home's own panel (`PanelLeft`, `PanelBack`, `PanelRight`, D-325) in a new home's
  look, set back by the panel's thickness so its face is where the lobby's wall's would be. A
  picked paint or paper still goes on Decorating's panels a hair proud of it, riding the same
  wall. D-325 built the panels on their own origins "so S5-03h can move them"; that's this.
- **Every wall is the XL wall's whole length**: the side walls run on behind the back wall and the
  back wall on behind the partitions, so the corners close at every size and a wall only ever
  slides, never stretches (h6 grinds them). At XL they're put away and the slot's own walls stand.
- **Pure first** (`Sizes.inset`, `Sizes.onWall`, `tests/walls.spec`): a partition stands in by
  half what the size is narrower than XL, the back wall by what it's shallower, so the room
  between them is exactly `Sizes.inside`'s box (the one Arrange already judged by); the
  ceiling's lamp hangs over the room's middle at every size, and Arrange's fixed lamp with it.
- **Everything that measured the XL room reads the size**: the door's count (`RoomWidth`,
  `RoomDepth`, set by `Walls.size`), the home lights' room (`HomeLights`, re-measured as the lamp
  moves), Arrange's button's inside box (re-measured on `HomeSize`) and the look's wipe
  (`LooksView`: it rolls round the size's room). A spare home stands Small (its set is Small's).
- **The steel shows only at a partition's end**: Small's room (7.75 across) is narrower than the
  M doorway (8.2 with its lining), so from the hall the open door shows the partitions' steel ends
  just inside its edges. S5-03h5b builds Small its own narrower doorway (the S door's 6).
- **Paper at the back corners**: a side panel's paper keeps its XL place as the wall slides in, so
  at Medium (half a 4-stud tile off) a paper's pattern breaks at the back corners, as it always
  did at the front; Small, Large and XL meet whole. Building a panel per size would mend it but
  snap the paper at h6's end; not worth it (my call).


## D-355 Small's doorway: the M's sides slide in a stud each, plaster with them (S5-03h5b, 2026-11-18)

The moment: your first unit is snug, a Small home with a doorway to match; grow it to Medium and
the door is plainly wider (Animal Crossing's house rooms by size).
- **One door rig, a narrower doorway in front of it.** Every home keeps the M's door (D-266); at
  Small the doorway is the S door's 6 wide (`Sizes.SmallDoor`, art's `SMALL_DOOR`): the
  doorway's two sides (the oak lining, the casing's leg, its plinth and a baseboard's end) stand a
  stud in each, a strip of the front's sage plaster comes in beside each, and the head is drawn
  narrower about its middle. The M's curtain rolls behind them, its ends hidden.
- **Built to slide, not swapped** (h6 grinds them): the Casing mesh split into what never moves
  (`Casing`: the baseboards and the rail) and `CasingLeft`, `CasingRight`, `CasingHead`, plus
  `FillLeft` and `FillRight`, each its own part built at the M's place. What slides into the wall
  sits a hair inside its faces and the baseboard's end a hair proud of the baseboard, so nothing
  flickers at either place or between. `Walls.doorway(unit, frame, inset)` slides the sides and
  scales the head's length (its cornice's ends in by the inset; the oak grain squeezes 22%, not
  seen at phone size); `Walls.size` calls it with `Sizes.doorIn` (1 at Small, 0 above).
- **Inside, oak boards** either side of Small's doorway (0.78 of front wall shows between the
  doorway and each partition). Plaster there would need Decorating's picked paint; oak suits every
  paint and paper (my call, `OWNER.md`).
- **Phone cost:** 372 triangles more per home (five parts); the Casing split takes nothing away.
- **Seen in Studio Play at A16 size** with h5a: all four sizes' walls, corners and lamp, the door
  counting you in by Small's room, Small's doorway from the hall, close and inside, Medium's.
## D-356 A home that grows grinds its walls back, and its holder sees it when they're next in (S5-03h6, 2026-11-18)

The moment (the home doc's idea 31; Animal Crossing, where you come home to find your house
bigger): you walk in to the room you know, and a beat later the steel lurches free, the
partitions grind out, the back wall rolls away, Small's doorway widens, dust sifts off the wall
tops, and the walls clunk home with everything you set out where it was.

- **The server still snaps; the slide is each screen's.** `Walls.size` stands the new size at
  once, as before. A grow (Growing's sale or gift, the Studio hook's "size") now goes through
  Arranging's `regrow`: the home's size stands through the re-lay (`clear(player, true)`: no
  pass through nil, so the walls go straight from the old size to the new), each drawn piece
  that lands elsewhere carries `GrewFrom` (its pivot before), and the unit gets `GrewFrom` (the
  old size) and `GrewAt` (server time), cleared when the home is let go.
- **Who sees it** (`HomeGrowView`): anyone within 36 studs while it's news (4 s) sees it at once;
  the holder, if it grew while they were out (at the counter, where you buy it), sees their
  home as it was until they next stand inside it, and half a second later it grows round them.
  Everyone else sees it as it is. My call: buying at the counter means you're never home when it
  happens, and the moment is the one you paid for (`OWNER.md`).
- **Each frame of the 2.6 s slide** stands the walls, the doorway, the lamp and the picked paint
  part way (`Walls.place` with `Sizes.between`, eased by `Sizes.slide`), and each moved piece
  part way by its parts' server places shifted, so a find on its top or in its cubbies rides
  with it. At the end everything is exactly as the server has it. While the holder's view holds
  the old size, the back wall's place is watched: when the server's new place replicates or
  streams in, the hold is stood again.
- **Sound, shake, dust, no words:** the grind is the roll-up curtain's rumble (DoorSound "Roll")
  pitched down to 0.5 to 0.78, its pitch and loudness riding the slide's speed
  (`Sizes.slideSpeed`); the lurch and the clunk are the door's thump pitched down, the clunk with
  the curtain's clatter; small camera kicks at both (0.14, 0.32) for someone inside; one dust
  emitter (the engine's smoke texture, plaster-coloured) along each moving wall's top, a burst
  of 10 at the lurch and the clunk and 4 a second between. Feel numbers in `Walls.Grind`.
- **Arrange open when it grows** (a friend's gift) closes as on a walk away, a lifted piece
  sliding back: the room it judged was laid again bigger.
- **Seen in Studio Play at A16 size**: Small to Medium, standing inside: the back wall eased from
  7.9 to 11.9 studs in 2.6 s, the shelf, job box and mirror riding out with it (captures
  `docs/art/S5-03h6-small.jpg`, `-mid-grind.jpg`, `-medium.jpg`). Not yet seen: Medium to Large,
  Large to XL (the walls hidden at the end), the hold until you walk in, the dust at phone size;
  not heard by ear.

## D-409 Caught on the back-to-the-lobby floor: down the shaft to the lobby car (S4-03c4a, Nov 18)

- **What happens.** On the floor the team picked with the "back to the lobby" card, a catch plays
  its lunge as any catch does; at the cut to black the card's own picture (the shaft from above,
  the car lit red far down it) comes up out of the black with the card's low hit and rushes at
  you, faster and faster, for 1.45 s; the gate's slam, pitched heavy, and a jolt as you land; then
  the black lifts in the lobby car the climb left from, with the car's ding, facing out of its
  gate. No words. Friends on the floor carry on. The precedent: DOORS' and Piggy's catch takes you
  out of the run while friends play on (the GDD's card, D-406).
- **How.** A new system takes these catches (`ToLobby`, server); KeptPlayers steps aside when the
  catch's floor model reads `FloorVersion` CaughtToLobby, so no unit and no film. The server
  drops what you carried (as any catch), anchors you, marks you (`SentDownAt`, the catch's server
  time) and at `ToLobby.Swap` gives you a new character stood in the car (`SentDownTo`) and takes
  the kept mark off. The car: on a group's own server the one its trip names, on a lobby riding
  here the one carrying the floor's number, else the first (Studio's test hall). Each one sent
  down takes the next of the car's standing spots.
- **Leaving a climb mid-way didn't exist**, so this is the first way: no teleport (the lobby is on
  the same server as the climb, L-08e2). Trips' late-arrival rule (`mayStand`) never stands a
  sent-down player back in the climb.
- **What you keep (my default, `OWNER.md`):** what any caught player keeps. Whatever you carried
  drops where you were caught. Your coins this climb stay counted and turn into cash with the
  team's when the climb ends (CashOut), as a caught friend's do; you're paid nothing at the gates
  you miss. The results count you caught on that floor (`ClimbEnd.look`'s new `sent`).
- **The last friend caught there** isn't swapped: the end's black comes down at the cut as for
  any wipe (EndView is over the fall), and Again brings the whole team back to the car.
- **Your screen.** CaughtView lets go at the cut to black for a sent-down player; ToLobbyView
  (DisplayOrder 45, between the catch's 30 and the end's 50) has the fall and the lift.

## D-410 A friend sent down the shaft, seen from the floor: dragged under in red (S4-03c4b, Nov 18)

- **What friends see.** As the monster lunges at someone on the back-to-the-lobby card's floor,
  the floor under them glows the card's red (a light and a flat red pool, the hall flooding red
  round them); as its hands close they're yanked down a little; from the moment their own screen
  cuts to black they're dragged down through the floor, faster and faster, with the card's low
  hit, and are under at the moment their own fall lands on the car, with a far, low slam from
  under the floor. The red fades; the server's swap takes the body a beat later. A friend close
  by feels a small jolt. No words. The precedent: a Dead by Daylight survivor taken off the hook
  while the rest play on; the shaft and its red are the card's own picture, so the stakes read.
- **The film's screech is gone for these catches**, on the caught one's screen and everyone
  else's: no film goes on, so the card's hit takes its place (KeptWrapOn waits a frame for the
  sent-down mark before it screeches).
- **Only on each screen.** The body's root is anchored by the server and moved down locally
  (`ToLobby.drag`), as the film's wind turns it; nothing extra goes over the network. Its name
  tag is hidden once it's under (it shows through floors). If the mark comes off with the body
  still there (the last friend caught: nobody is swapped, the end covers), it goes back where it
  stood, unless the server has moved it meanwhile.
- **Studio:** `DevCatchHold` holds the drag on one frame, and a stand-in friend given the mark on
  its model is dragged, so one player can see it.

## D-411 Sent down the shaft, you wait in the car for your team (S4-03c4c, Nov 18)

- **What happens.** You land in the lobby car the climb left from (D-409) and it stays as it is:
  its gate up, its keypad's readout at rest, no count, no chime. It hums low from its ceiling,
  coming up from nothing under the ding as the black lifts (the vending machine's "Transformer
  Hum 1" pitched down to 0.8, heard in the car, gone a few steps out into the lobby). The dial
  over its gate shows the floor your team is on and turns over as they climb on without you.
  You can walk the lobby meanwhile; nothing calls you back. When the team's climb ends (the last
  of them caught, or the top), the end's black and results come to you as to them, and Again
  stands the whole team in that car together. No words. The precedent: a caught Piggy player
  sits the round out until the team starts the next one together; the dial is the lobby car's
  own "Floor N" (L-08e3, D-124), which already shows a group's floor to the lobby.
- **Why it counted before.** Only in Studio's test hall (a `DevFloorNumber` climb no lobby car
  took up): there the lobby's cars aren't held, so stepping into one started its 20 seconds and
  carried you up alone into a new climb on the same server. On a group's own server (every live
  climb, Trips) its cars don't take anyone until the group comes home, and on a lobby riding a
  climb here other counts are held while it's on; neither counted, but a sent-down player could
  still join the car's group there.
- **How.** LobbyCars never takes a player marked sent down (`ToLobby.Attribute`) into a car's
  group, wherever they stand; with no group a car never counts, so its gate stays up. Its
  `teamCar` names the car the climb on now left from (the ridden car on a lobby riding here, the
  trip's bay on a group's own server, else the first: the test hall) and its dial shows the
  climb's floor while it's on, cleared once it isn't; ToLobby stands the sent down in that car
  (one place decides it). ToLobbyView hums from 6 studs over where you were stood until your
  mark clears at the end's cover.
- **My default (`OWNER.md`):** you sit it out; nothing brings you back into the same climb.

## D-412 The whole climb in Studio, first part: three cards ridden, the arrival's light tamed (S4-03d1, Nov 18)

S4-03d split in two (context): d1 this, d2 the back-to-the-lobby card picked on a ride and the
tamed light seen. Ridden in Studio Play at Galaxy A16 size, seed 7, one player, floors 1 to 4:
- **The held ride, stepped.** At 4 s the three cards sit centred between the thumbstick and the
  jump button, each coin strip ("+12", "+6", "+6") readable at A16 size: the bigger strip stays.
  A real tap put my head on the power-out card. On the knock the winner flashes white, the losers
  go dark and sink, the winner glides to the middle and breathes in its colour (caught on floor 3's
  ride, a stand-in's head on a loser). It stays up, lit, through the change into the next floor's
  car and flies into the gate as it opens. `docs/art/S4-03d-*.jpg`.
- **Each card's floor was what it promised.** Floor 2, the power out: black, `FloorPower` false,
  its box thrown; a real hold switched it back on. Floor 3, twice the monsters: Mannequin and
  Packrat, 9 asleep, 4 loose at most. Floor 4, twice the padlocks: 10 padlocked. At floors 2 and
  3's gates each card popped over the pour, flashed and burst into its coins (+6, +14).
- **Fixed: the arrival's light flooded the car.** The light past the gate (brightness 4, 30
  studs, a fade that eased in) lit the whole car pale blue for about 1.4 s, so a dark floor's
  first look was bright. Now 1.6 bright, 18 studs, a 1.2 s fade that falls fast then lingers
  (`NextFloorView` HALL_*): the hall glows in the card's colour, the car only catches its spill.
  Passes checks, not yet seen in Play (d2).
- **Not a bug:** floor 4 (twice the padlocks) had 11 asleep against twice-the-monsters floor 3's
  9: floor 4 has more units, and a padlocked unit holds a sleeper twice as often (S1-07a).
- **Found, left to the owner (`OWNER.md`):** a plain floor's lobby is as black from the car as the
  power-out floor's, its motion lights waiting for someone to walk under them; the two differ only
  once you step out. My default: leave it; the card's burst names the floor.

## D-357 Choosing your name card's style on the front tab, and the plate swinging down (S5-03g3c, 2026-11-18)

The moment: on Arrange's front tab you flick along your name card's styles, each a little plate
with your own name on it, tap one and the camera dips out to the hall, where the new plate swings
down over your door and clacks against the wall. The ones you don't have yet sit there marked,
waiting for the counter. Precedent: Animal Crossing's catalogue (every style shown, the ones you
don't own marked), Bloxburg's and Adopt Me's house signs (D-322).
- **A second row on the front page, under the door's colours.** Each chip is the plate in small
  (100 by 44 points, the plate's long shape a thumb tall): its paint under its own colour map (as
  the plate's Overlay shows it), your name (`Holding.words`, as the server letters it) in the
  style's font and ink, the neon's with its pink glow stroke, the steel's bolts and the board's
  screws as dots at the ends (`CardPlate.Plain`), the chalk slate in its oak frame. The front
  page's tray is two rows tall now, as the room's is (`LooksTab.Heights`).
- **Not yours yet: a small mark, a shade darker, and a shake.** `Looks.cardLock` says what stands
  between you and a style: nothing for a Starter style, else "Cash" (a gold coin with an inner
  ring) or "Robux" (Roblox's own mark on a dark disc). A tap on a marked chip asks nothing: the
  chip shakes its head and the mark pops with the soft click, no popup and no words (D-328's
  promise, the owner's no-refusal-text rule). `Looks.pick` now judges a card by the same rule, so
  the server and the chips can't disagree. Only the stencil is anyone's until the counter sells
  the rest; owning them is the counter's ticket.
- **The camera goes to what you changed.** A card chip you can pick (worn or not) takes the camera
  out to the hall facing your plate (`Arrange.Feel.HallOut`, `HallBelow`, `HallAim`), a door chip
  back inside to the door. Out and back are a quick dip through black (`Feel.Dip`, 0.16 s each
  way, under the tray and buttons), not a swing: a swing from inside to the hall would pass
  through the wall over your door. Arrange always opens on the door view.
- **The plate swings down, on every screen near it.** HomeCards answers a card's new style by
  swinging the new plate and its writing down from 75 degrees out on its top edge with a bounce
  ease, two small bounces off the wall, and the job box lid's metal flap clack on the first touch
  (`Holding.Card.Swing`). It moves the server's anchored parts on that screen only and puts each
  back exactly where the server laid it (the card's rest worked out from its style, never read,
  so a pick mid-swing can't keep a swung place). A plate further than 80 studs from the camera
  just changes. It also plays when a home is taken by someone with a sold style.

## D-413 The whole climb in Studio, second part: back to the lobby picked on a ride; the cards done (S4-03d2, Nov 18)

The last Studio check of the next-floor cards, and S4-03 ticked. Seed 7, one player, Play at
Galaxy A16 size; nothing needed fixing.
- **Start on floor 2 to reach the red card fast.** `DevFloorNumber` 2 starts the climb on floor
  2, and its ride deals floor 3's cards (the power's out, back to the lobby, twice the monsters):
  one ride instead of two. Offers and codes come from the seed and floor alone (D-403, D-406).
- **Back to the lobby, picked and played.** A real tap on the middle card put my head on it. On
  the arrival a red wash and a ring pop over the view for under a second, then the hall past the
  gate glows red for about a second and a half while the car's walls keep their colour: D-412's
  tamed light holds. A real catch on that floor (`CatchTest`, a stand-in in the car so the climb
  went on) sent me down the shaft and stood me in the lobby car within three seconds.
- **The lobby is black for two seconds after you land**, then its ceiling lights flicker on. The
  front office's ceiling fixtures are motion lights (HallLights); standing still a minute later,
  they read off again. My default: leave it, the lobby waking as you arrive. The owner judges it
  (`OWNER.md`).
- **The power coming back is one quick ragged wave.** Held to the end with the grip on screen,
  the breaker brought the whole hall from black to lit inside 0.3 s, one capture catching its far
  end still dark (`HallLight.BackStagger`). Turning the camera away mid-hold hides the prompt and
  cancels the hold.
- **Twice the padlocks' pop at its gate.** Floor 4 (10 padlocked) paid 24: the floor's coins
  poured first, then the card's picture flashed over the gate and its own coins burst in its
  colour and flew to the count.
- **Left to two players**: the back-to-the-lobby floor's pop is seen by whoever rides out, never
  by the one sent down, so it's in the owner's two-player test with the rest of that floor.
  Captures `docs/art/S4-03d2-*.jpg`.

## D-358 Taken-up finds cross the trip: the owner's word, checked against their save (S5-03d4, 2026-11-18)

The moment: you take your lucky boombox up from your home, ride the freight car, and it's in your
hand when your screen opens on floor 1's shaft, on the group's own server. Precedent: Lethal
Company's ship loot, carried between moons. D-302's rules hold across the trip: the save still
holds every find out of a box, so a crash, a failed teleport or a server hop costs nothing.
- **The lobby names them and lets them go quietly.** As a car's group is sent (Trips' `send`),
  each find out of a rider's job box that a rider holds or wears goes in the trip's data
  (`Trip.Version` 4, `finds`: whose box, its save key, who holds it, cracked, worn) and is marked
  going (Slots' `going`). As its holder leaves it goes from the lobby with them, not back into
  the box, so no Back is settled and its crack isn't written: the crack rides with it and comes
  home where its climb ends (the ticket's "the lobby doesn't recall what left on the trip").
  A trip that fails for good leaves it in hand (`stay`); one whose owner already left goes back
  into their box.
- **Only an owner's own word, only what their save backs.** The data passes through each
  rider's device. The group's server reads each rider's own copy for their own finds only (a
  friend can't name your finds into their hands), and deals only what `Home.Taken.backed` says
  their save still has in the box (Save.boxed, less those already out on this server): a forged,
  missing or extra one is refused and stays in the box. An owner who names their own find into a
  friend's hands only does what handing it over does.
- **When:** held until the owner's save has loaded there (the lobby lets the session go first),
  then dealt into its holder's slots (its owner's when the holder isn't there), already up:
  quietly just before the group is stood in floor 1's car, or with the pick-up sound the moment
  a late save loads. The climb's end clears what was never dealt; it stays in the box.
- **Never doubled:** the world never holds more of your box's finds than your save backs, on
  any server: the lobby's copies go as you leave, and the group's server counts against the save
  it holds the session lock for. A forged "whole" for one cracked in the lobby only undoes a crack
  the save never had.
- **Seen in Studio** (one player, DevTrip "Arrive" with `DevTripFinds` "Boombox,Boombox*,Skates,
  Skates,NotAFind"): "3 of 5 finds came across the trip", Boombox, Boombox, Skates in the slots
  before the car rode; the second Skates (the save has one) and the made-up name refused; the
  Boombox's claimed crack not drawn (it has no glass). The lobby's side and a live shutdown need
  live servers: OWNER.md.
- **Known edge, safe side:** a rider who drops a going find during the black ride leaves it on the
  lobby floor, where its owner's leave recalls it (its crack written there) and the group's
  server deals it too, so the crack could count twice; never the find.

## D-359 The cars' lamp cages drawn only from near: the one part of a car nobody sees from afar (S5-03a2d, 2026-11-18)

The moment: on a cheap phone the calm ground floor runs smooth from the spawn to a car, the six
cars as solid as ever.

- **Measured** in Studio Play on the Galaxy A16 simulator (685x338), first person (the eye 4.5
  studs up), looking straight at the cars from the middle of the room. The ground floor has grown
  since D-271 (the counter's furniture, shelves, cards), so the spawn view starts at 174k, not 145k:

  | Spot (studs from the cars) | Whole view | The six cars | Their lamp cages |
  |---|---|---|---|
  | Spawn (150) | 174,404 tris | 51,108 | 6,984 |
  | 100 | 136,084 | 52,476 | 6,984 |
  | 50 | 85,464 | 58,956 | 6,984 |
  | 15, before cars 3 and 4 | 44,148 | 31,960 | 2,328 |

  The cars from the spawn, part by part: gate straps 20,736, pickets 8,400, lamp cages 6,984,
  trim (bumper boards and hatch) 6,840, keypads 3,096, car fronts 2,664, landing frames 2,004,
  sills 252, shells 132. The keypads' keys are already 0 there: Roblox leaves parts that small
  undrawn from afar by itself (they're back by 50 studs, 6,480).
- **Which parts nobody sees** was settled by the pixels, not by guessing: Studio's window was
  captured (macOS `screencapture -l`, the A16 view about 1:1) with a part set hidden on the
  Client and without, and the cars' strip compared (a pixel changed by more than 12 of 255). From
  the spawn: the back layer of the gate's straps changed 42 pixels, the trim 136, the lamp cages
  0. The lamp cages again: 0 at 75 and at 50 studs, 20 at 30 (a one-pixel line under each
  fascia), 134 at 12. The cage and fitting hang behind the fascia; only their bottom ever peeks
  out, and only from near.
- **So a lobby car's lamp cage is drawn only on a screen within 60 studs of its threshold**
  (`Lobby.CarNear`, `LobbyCarsNear` on the Client: `LocalTransparencyModifier`, checked four
  times a second, as the fronts' drums are). 60 leaves room over the 50 measured for a kneeling
  eye, which sees a little farther under the fascia. The lamp's glass, its light and its glow
  across the room are untouched. **After,** seen in Studio Play
  with this code: the spawn view 174,404 down to 167,420 (the six cages, 6,984), not a pixel
  different; 40 studs out the four nearest cars' cages are drawn and cars 1 and 6 (60.4 away)
  not; 15 studs out and inside a car, all six, unchanged at 44,148.
- **Ground floor only.** A climb floor's car is the one you ride and wait by; nothing there is
  hidden (Lobby cars carry `Boarding.CarAttribute`, the climb's don't).
- **Not chosen:** the folded gates (29k from the spawn, 57% of the cars) are seen: their back
  straps alone change 42 pixels. A folded gate drawn from afar as one simple mesh baked from the
  real one would cut about 28k, but it's new art; it waits on the owner's phone test (OWNER.md),
  only if the ground floor stutters there. The trim's boards show through the open gate and its
  hatch shares their mesh. Still over a climb floor's busiest view (112k) at the spawn: the
  fronts and furnishings stay (D-271).

## D-360 The name card's other styles: owned in the save, picked once bought, sold beside the furniture (S5-03g3d1, 2026-11-18)

The moment: you see a friend's neon card glowing over their door, buy one at the counter, and the
next time you open Arrange its chip has lost its mark and picks, the plate swinging down. Animal
Crossing's Nook's Cranny sells wallpaper beside the furniture; Roblox games sell cosmetics for
Robux bought once and kept, as this game's wraps are (S3-04a).
- **Owned for good, in the save.** Save version 15 adds `cards`: each style you own by id,
  stamped with when you first owned it (the wraps' shape). A version 14 save comes back owning
  none. The stencil is everyone's and never listed.
- **Prices: the painted board 120 cash, the chalk slate 200** (12 and 20 floors' pay, `CardSale.Floors`;
  near the camp bed's 150 and below the neon moon's 250, since a sign is the hall's to see). The
  neon is the developer product "Neon Name Card" at the owner's Robux price (switch `sellNeonCard`).
  Defaults; the owner's call (`OWNER.md`).
- **The server's rules are the furniture's.** A cash buy takes the price and adds the style in
  one step, writes the save, and answers only then; a failed write undoes it whole. The neon goes
  through Roblox's prompt from the server and is granted in the save Brix writes before the
  purchase counts; owned already, it's never prompted ("had"). A new system, `CardSales`, after
  Purchasing in the start order (Furnishing starts before it, so it can't hear grants).
- **One rule judges a pick.** `Looks.cardLock(id, owned)` and `Looks.pick(..., owned)` read the
  save's `cards`; the server passes them, the paint tab reads the same list off your Player
  (`CardSale.Attribute`, "Painted,Chalk"), so they can't disagree. A style bought while the tab
  shows loses its mark there and then (the coin pops in on itself as the shade lifts); bought
  away from home, it goes as the tray next reveals; one owned as the tray is built has none.
- **Split.** The counter's cards for the three styles (on the Furniture tab, after this week's
  pieces) are S5-03g3d2: this session's room ran out after the rules, the server and the chips.
- **Seen in Studio Play at A16 size** (685x338), from the server and the real remotes: short of
  cash refused with nothing taken; the board bought (300 to 180), "had" the second time; the
  unbought chalk refused by `PickLook` and the bought board picked; a front tab built from the real
  LooksTab showed the board unmarked and lost the chalk's mark the moment it was bought; a true
  Stop and Play kept both and the board over the door; the neon through `BuyCard` asked its price
  (`CardShelf`), ran Studio's made-up receipt, was answered "" only after the grant, and picked.
  Arrange's own button still didn't open from the MCP (STUDIO.md). The test save was put back.

## D-361 The card styles' cards at the counter: the plate drawn flat, swinging down as it's yours (S5-03g3d2, 2026-11-18)

The moment: you see a friend's neon card glowing over their door, walk to the counter, flip to
Furniture, and past this week's pieces there's your own name on a neon plate; you buy it, it
swings down in its card with the clack it makes over a door, and the next time you open Arrange
its chip is yours. Nook's Cranny sells wallpaper beside the furniture (D-360).
- **The plate drawn flat, not in a viewport.** A SurfaceGui never draws in a ViewportFrame, so
  the plate's art there would carry no name; the paint tab's chip already draws the plate with
  your name in the style's font, ink and glow, so that drawing became one shared function
  (`LooksTab.plateFace`) and the counter's card wears it, larger (a UIScale to the card). It is
  also far cheaper on a phone than three more viewports.
- **Alive like the pieces, as a plate would be.** The pieces turn; a flat plate can't, so it
  sways a little about its top edge (`Shop.PlateSway`, 2.5 degrees, about three seconds a
  sway), as if hung on the counter's rail, with a soft shadow under it, and the neon's letters
  breathe (`Shop.PlateBreathe`).
- **The buy lands as it does over a door.** The plate swings out toward you (seen face on, a
  quarter of its height, `Shop.PlateSwingFrom`) and falls back with Bounce, the hall's own clack
  (`Holding.Card.Swing`, the job box lid's metal flap) on its first touch, the rim glinting and
  Owned popping in as it lands, never before; a cash style's price ticks off the shared purse in
  the coins' falling ticks. Rather than the furniture's drop into the box: a plate goes on your
  door, not in your box.
- **The answers are the furniture's.** Buy holds pressed until `CardBought`; "cash" nudges the
  purse, "had" says Owned, "off" asks again (a style off sale isn't dealt), the rest settle
  silent; 8 seconds unanswered settles and asks again. A piece bought restates the styles'
  prices and a style bought the pieces' (one purse). Names: Painted board, Chalk slate, Neon
  sign (`CardSale.Names`).
- **Seen in Studio Play at A16 size** (685x338), through the screen's own buttons: the three
  cards after the five pieces, $120, $200 and Buy (Studio's made-up price); the board bought
  ($300 to $180, Owned), the chalk then dimmed and its press nudged the purse; the neon through
  Studio's made-up receipt, Owned, cash kept; a true Stop and Play kept both and the board picked
  while the unbought chalk was refused; the chalk bought (a per-frame log: price held while the
  plate fell, Owned at its first touch, cash $300 to $100). The test save was put back.

## D-414 · 2026-11-18 · The big find split, and the jukebox first (S4-05a)

S4-05 is split in three (ROADMAP): **a** the first big find's art, **b** the big find on the
climb (waits for the home chain to free `Climbs`, `GatePay`, `Slots`), **c** seen in Studio.
- **The jukebox first.** Of F-12's eight wave 1 big finds, the design doc names the jukebox, so
  it is built first: a 1940s arch-top of our own design, real size (5.95 by 3.25 studs), in a new
  finds set `art/finds/big/` (README). Its plastics glow and its record spins when played
  (`Play`), found dark and still; its press is at home, so the climb only carries it.
- **Its row is written, not ticked.** `GAME` in `art/finds/big/spec.py` (Legendary, 800, floor
  2 up, heft 1) and `rows.py` takes the set, so `Rows.luau` has it with `judged = false`. A ticked
  find joins every unit's deal; a big find is dealt only by a floor's big-find place, so S4-05b
  ticks it when that place exists, and adds the "Big" size for how it sits in your arms.
- **Not imported yet.** Its upload and Studio import (PIPELINE steps 6 and 7) go with S4-05b,
  whose session needs it in the place anyway; this session ran out of room after the sheets.
- **Left to the owner** (OWNER.md): the pick, its grade against the big finds' Epic-heavy roll,
  and its height in your arms.

## D-415 · 2026-11-18 · The big find's deal and door (S4-05b1)

S4-05b is split in three (ROADMAP): **b1** the deal and the door (done), **b2** its mark on the
corner map and the haul, **b3** counted at the gate.
- **Chosen as the code goes in, from the units nobody has opened.** Picking the unit when the
  floor is laid would let a team open it early by hand and find the big find before the code,
  or need a lock with no reason players can see. Choosing at the code, among units still shut
  and to be dealt (Deals' `waiting`: never one searched, holed or holding a caught friend), and
  never one padlocked, a note's, a sleeper's, guarded, packed or the Packrat's, means the door
  that rolls up is always one nobody touched, and nothing searched is undone. One outside the
  lobby's hall when any is left, so it's down the halls and the haul is a real trip (Lethal
  Company's apparatus sits deep in the facility). Every one of 120 test floors had one.
- **Its rolls come from the floor's seed, not the deal's** (`BigFinds`, seed * 7 + 4051): the
  grade, the find, which unit. The deal's draws are untouched, so `tests/stuffdeal.spec`'s
  fingerprint is the same.
- **The deal stands it alone** (`deck.big`, `Deal.open`): no coins, no stuff, no monster, so
  the door rolls up on the jukebox alone in the dark. Deals lays it standing with its Take
  prompt, as any find too big for a box.
- **Ticked built, never in a unit's deal.** `Deal.Finds` leaves out the Big set; the catalog
  takes it, so it's carried as any find, in both hands (`bothHands`, as the mega goo ball:
  no other slot, no picking up). Its own hold and its slower walk are b2's.
- **Its sound is the door's own rattle** ("Open", as a wrong code's unit rolls up), heard by
  keepers as by players, so pulling the code draws monsters toward the find, as pulling the
  apparatus wakes Lethal Company's facility. Players far away learn where from the map (b2).
- **Seen in Studio** (floor 2, seed 7, code 9199): "BigFinds: floor 2's Jukebox rolls up in
  Unit228", the jukebox standing on the unit's floor at its back (3.25 by 5.95 by 2.68 studs, 4
  parts, 1 light) with its Take prompt on the client. Screen captures timed out, so none saved.


## D-416 · 2026-11-18 · Hauling the big find (S4-05b2a)

S4-05b2 is split in two (ROADMAP): **a** the haul (done), **b** its mark on the corner map.
- **A walk of its own, 9 studs a second.** Just over half a run: under every monster's hunt
  (0.9 of a run, 14.4) and the ladder's 12, so a monster that hunts the hauler always catches
  them and the team has to guard, as Lethal Company's heavy scrap makes you prey; yet over a
  monster's walk going to look (the Packrat's 8.6, the Mannequin's 7.2), so a wandering one can
  still be slipped. Finds rows now carry `walkSpeed` (art/finds/rows.py, the spec's GAME row),
  which the catalog hands to Slots' pace as the ladder's. `tests/haul.spec` holds all three.
- **A "Big" size for how it sits in your arms.** It's taller than you (5.95 studs), so it can't
  come up to the chest the way the goo ball does. Your view: low and out in front, its top a
  quarter stud under your eyes, its arch filling the bottom of the screen and the hall over
  it. Friends: hugged low in front, its foot just off the floor, its top over your head, so the
  hauler is plain from down the hall. First-person and friends' views don't agree in height;
  the owner judges both (OWNER.md).
- **Every step answers.** Each 4.2 studs walked (about two steps a second) lands a thud ("Body
  Impact 2" pitched down, the Packrat's laden step) and a rattle of its insides in turn, heard
  45 studs off by everyone, and the hauler's view dips. Players only: monsters don't hear it,
  since a haul that drew monsters would be a new bet (the door's rattle already does).
- **A tool's press, no words.** With it in your arms a slot press shakes the slot box with its
  dull click, thunks your hand on its cabinet and knocks your view; "Drop the jukebox first" is
  gone for big finds, as the cause fills your screen (the owner's no-obvious-refusal rule). The
  ladder and the goo ball keep their words for now.
- **Room in every unit it's dealt into.** `tests/dealspot` stands the jukebox in every small and
  medium unit (300 labels each); only a unit with the floor's note has no room in a small one,
  and `BigFind.fits` never picks a note's unit, so nothing is excluded.
- **Seen in Studio, not carried.** Floor 2, seed 7: Unit228 rolled up with it, the place's
  catalog reads walk 9 and the Big hold, and every client system starts (the first try caught
  HaulSteps with no `start`, which stopped the whole client). The MCP's client never sees a
  prompt, so the take, the walk and the steps are the owner's (OWNER.md).


## D-417 · 2026-11-18 · The big find's mark on the corner map (S4-05b2b)

- **A pink diamond, its own shape and colour.** The map already has your white dot, friends'
  blue dots, the car's amber mark and a caught friend's banging blue dot, so the big find gets
  the one shape nothing else uses, a diamond, in hot pink (not the jukebox's own amber glow,
  which is the car's colour), with a white rim to read on the dark window at phone size. It's
  held on the window's edge the way it lies while it's off it, as the car's mark is, so a team
  anywhere on the floor knows which way to go (Among Us's map shows where the task is; Lethal
  Company's ship radar, the crew).
- **Three rings the instant the door rolls up.** As its unit rolls up by itself the diamond pops
  in (grown from nothing, a little past its size, back) and three rings go out from it, one after
  another, so a glance a second late still catches it. Arriving on a floor whose big find is
  already out rings it the same. One ring each time it changes hands or is put down, so the
  team sees it move; none as its unit deals it where the unit's mark already stood.
- **It follows the find.** Round its hauler's dot while someone carries it (the diamond a size up
  and under the friend's blue dot, so the hauler shows inside it; your own dot when it's you),
  where it lies once dropped (a caught hauler's drop too), and gone while it's kept at the gate,
  lost, or in a monster's arms, back with its rings where the monster lays it down.
- **The server says where** (BigFinds), on the floor's model: `BigFindSlot` (its unit, from b1),
  `BigFindAt` (the floor point it lies on) and `BigFindHolder` (the hauler's UserId), worked out
  each time anyone's slots or the lying finds change (Slots' `changed`, `loose`), never per
  frame. The find is known by its model (the one lying of its key in its unit once dealt), so a
  second jukebox taken up from a home never confuses it. The new one is written before the old
  is cleared, so a screen between the two never shows it back in its unit. The map follows the
  hauler's own position each frame, as friends' dots do.
- **No sound of its own yet.** The door's rattle is its sound, heard down the halls; whether
  the map's pop needs a ping for players too far to hear it is a polish line in ROADMAP.
- **Seen in Studio** (floor 2, seed 7, code 9199, one player): the floor said slot 58 and the
  jukebox's lying point as the door rolled up; the diamond sat on the window's right edge and
  three rings went out over 2.1 s. Taken (Slots' Studio hook `DevTake`): the floor named the
  hauler, the diamond went round your dot a size up. Dropped: a ring, the diamond 2 studs in
  front where it lay. A friend's carry and the gate's clearing are the owner's (OWNER.md).
  Captures timed out twice, so none saved.

## D-418 · 2026-11-18 · The big find counted at the gate (S4-05b3)

The moment: the gate slams with the jukebox aboard and the whole team is paid for the haul, with
the jukebox itself lighting up and playing on everyone's screen before it bursts into coins.
- **Both, as the design doc says.** "Whoever carried it in keeps it": the hauler keeps it as any
  find in their slots (Slots' `keep`, its 800 worth into their save, KeepView's rise). And
  everyone aboard who is paid gets the floor's pay again (`Pay.bigOf`, `Pay.BigShare` 1), as
  Lethal Company's apparatus is the haul the whole crew's trip was for, so the guards earn it as
  much as the hauler. A share of the floor's pay, not a flat sum, so it stays worth the slow walk
  on floor 20 (as the versions' pay, D-403). My default (OWNER.md).
- **It counts only in a paid rider's arms** as the gate hits its post (BigFinds' `aboard`, asked
  before anyone's slots are kept): alive, aboard, not wrapped. In a monster's arms, lying in the
  halls, or held by someone left outside, it's left behind with the floor. Set down on the car's
  own floor it is still lost today, as any find lying there: S4-05b4 makes that count, as the
  design doc's "inside the elevator" says.
- **Its pop, last of the pay** (`Pay.parts`' fourth part, taken first so it always shows; Balatro
  scores each joker in turn, D-407). After the pour, the traps' pops and the version's card, the
  find itself (its slot picture, ToolPicture) punches up over the pour, a third of the screen
  tall, dark; as it lands its record drops (APM's "Duke of Harlem", 1940s swing) and its glow
  stutters on (its glow part's emissive, a halo of rings in its tint, the view's light warming),
  held a second, then it flashes and bursts into its coins, which hang lit in its amber and fly
  to the count, the "+" swelling to the whole pay.
- **Left behind, heard going.** Every paid rider hears its tune from far below, muffled (the high
  end cut), winding down to a quarter speed and fading over 2.4 s, as a record does when the
  power goes: the team learns what they left without a word (no text that explains a rule).
- Not chosen: coins only to the hauler (the guards would earn nothing for the riskiest job);
  a grade-based pay (one jukebox built, so every big find would pay the same today anyway).
- Passes checks, unseen in Studio: S4-05c sees the pop and the loss (context ran out here).

## D-419 · 2026-11-18 · Set down in the car, the big find still counts; seen in Studio (S4-05b4, c)

The moment: the hauler staggers into the car, sets the jukebox down to pull a friend in or grab
a tool, and as the gate slams it still counts, because the design doc counts it "inside the
elevator", as Lethal Company's scrap counts once it's in the ship, held or on the floor.
- **Who keeps it** (`BigFind.keeper`, pure, Lune spec): held by a paid rider, theirs; held by
  someone left outside, left behind (never counted as lying); set down inside the car's box
  (`Climbs.inCar`, the same box the ride carries riders by), its last hauler's if they ride,
  else the paid rider standing nearest it; nobody paid aboard, left behind. My default
  (OWNER.md): the last hauler did the work, and the nearest rider is who'd pick it up.
- **How**: as the gate hits its post, GatePay takes it up off the car's floor (Slots' `takeUp`:
  a glint where it lay, gone, as `keep` takes a held one) and adds it to its keeper's kept
  finds, so it pays everyone aboard, pops and rises out of the keeper's slot exactly as one held.
  Anyone can still pick it back up before then (its Take prompt, as any lying find).
- **Seen in Studio (S4-05c)**, seed 7, one player, floors 2 to 4: the code rolls up its unit
  (Unit228, then Unit340, slot 65), the diamond held on the map's edge, the take (walk 9), set
  down in the car ("set down aboard", paid 24), held aboard (paid 35: it punches up lit in its
  amber halo, then bursts into coins), left behind (its tune muffled, speed 1 to 0.25, fading).
- **Fixed from what was flat**: the tune's first 1.4 s read 0 to 56 loud, then 115 to 142, so the
  glow came on to near silence and the left-behind tune was loud only once faded out: both now
  start at 1.4 s. The kept jukebox's analytics record was dropped (Record knew only the units'
  finds): it now knows every big find (spec first).
- Not chosen: carrying a lying find up with the car into the next floor (it would have to ride
  out of the floor's lying folder; the gate keeps it at once instead, as any held find).

## D-420 · 2026-11-18 · The hard hat's own beam: white, from your eyes, swinging up as it goes on (F-G1b4a2)

Phasmophobia's head torch: the hat's light is a hard white cone that goes where you look, so your
hands stay free for the jukebox or a tool.

- **Tighter and whiter than the torch** (`Finds/Headlamp`): 34 degrees across (the torch 54), a
  white LED's cold white (236, 243, 255), brightness 2.8, 48 studs, shadows on. Yours adds a faint
  white spill (no shadows) for a wall right in front of you at low graphics, as the torch does.
- **Yours from your eyes** (`HeadlampView`): 0.3 studs over and 0.7 ahead of your camera (past
  your face and the hidden brim, never past a wall), along your camera's look, pitch included. It
  nods and weaves with `Torch.step`'s stride (1.3 times the torch's nod, 0.6 degrees of weave),
  fed no turns so it never lags your look. With your view away from your head (the RC car), it
  leaves the hat's lamp along your head instead.
- **The pull-on**: from the moment its bulb lights (0.155 s after the press, or when the hat lands
  on your head if that's later), the LED rises in 0.06 s and the cone swings up from 55 degrees
  below your look into place in 0.45 s, about 4 degrees past and back (seen in Play: -55, -26, +4,
  +0.6, 0). No camera move: the swing is the feel.
- **Friends' along their aim**: their screen now sends its aim while the hat is worn, not only
  while their torch is on (`FlashlightView.report`); the server takes it then too (`Flashlights`,
  range: a lit torch or `Head.wearing`). Keepers still test only a lit torch's beam. On your
  screen their beam leaves the art's lamp along their body's heading and their `Aim`, eased.
- **It replaces the hat's warm art light while worn**: `FindUseView.rank` skips worn finds, so
  their art lights stay out; the bulb still glows on the brow.
- **The phone's cap** (F-G1b4b's line, done here): yours and the nearest two friends' headlamps
  within 140 studs are real (`Headlamp.RealBeams` 3), from three rigs made once; the rest glow.
  On top of the torches' four, a full squad in hats and torches is at most seven spotlights.
- **A friend's hat settles onto their head** (seen in Play through `HeadlampTest`): their weld's
  C0 is eased on your screen alone, dropping 0.7 studs (grown with their head) in 0.16 s, tipped
  back 7 degrees, then a 0.05-stud hop that rocks level in 0.22 s. Only when it lands on a head
  this screen saw bare: a respawned character arrives wearing it and it's simply there.
- Defaults for the owner (OWNER.md): the cone's brightness, width and bob.

## D-421 · 2026-11-18 · The hard hat runs out as a torch dies, then cracks off your head (F-G1b4b)

The flashlight's run-down (D-142, after DOORS' and Lethal Company's flashlights) squeezed into the
hat's minute, and the saw's break (D-141, Minecraft's tools) for the end. The moment: deep in a dark
hall the white cone stutters and buzzes, the bulb sputters out, and the hat drops off your head
with a crack, leaving you in the dark with whatever's coming.

- **Its last 15 seconds stutter** (`Headlamp.Shape`, `Charge.glow` with a shape now; the torch's is
  the default, unchanged): a long first stutter you notice, then short ones about 4 s apart that
  close in and darken, with moments of black, the LED sagging to 0.6 of its light. No browning (an
  LED dims, it doesn't brown) and no fade of its own. The buzz is the torch's filament buzz, heard
  only in the stutters. 15 s, not the torch's 30: a quarter of a minute's light is warning enough
  to get back to a friend's light, and the hat stays a short, strong light.
- **Then its bulb's own run-down carries the beam out** (the art's `RunDown`, 3 s): the beam
  follows the bulb's glow track from where the sag left it (`Headlamp.light`), so on a friend's
  screen the bulb on the brow and the cone sputter out together. Through the stutter, a friend's
  bulb is dimmed with their beam (`HeadlampView`), only in that stretch so the pull-on's own glow
  isn't overwritten.
- **Spent, it falls off and breaks** (the server's: `FindUses` looks four times a second for a
  worn hat whose stamp is spent, `Slots:breakWorn`): it slips off forward with a small hop (4 up,
  2.5 ahead, not a tool's 8 and 4), and cracks apart as it hits the floor, not in the air, ten
  bits in safety yellow, black and the lens's grey flying, the finds kit's CRUNCH at 0.72 pitch,
  then its drop clank that monsters hear as a dropped tool, 2.5 s lying, a fade. It's lost, as
  a worn-out tool is (taken from home, it leaves your save). A hat dropped lit (caught) runs out
  on the floor and only goes dark; spent, it can't be worn again.
- **Studio's `DevHatSeconds`** shortens the minute for a hat worn off the ground floor.
- Defaults for the owner (OWNER.md "The hard hat running out"): the 15 s, the sag, losing it.


## D-422 · 2026-11-18 · Finds a little better every floor up, a padlock's a grade better (S5-02a)

The moment: a team that pushes from floor 4 to floor 8 opens doors on better things each floor,
and the padlock cut on floor 12 is worth the bolt cutters, its box's light blue, purple or gold
about half the time. Precedents: Lethal Company's scrap worth more on each riskier moon, Diablo's
deeper levels dropping better items level by level; Escape from Tarkov's locked rooms holding
its best loot (the GDD's padlock line: "the best chance of something great").

- **The grade odds climb every floor** (`Grades.odds`): the catalog's three bands stand on the
  floors they start (1, 10, 25), and each floor between moves evenly from one band's odds to the
  next, so floor 5 deals a Legendary about 1 in 93 (floor 1: 1 in 200, floor 9: 1 in 60). A grade
  a band has none of stays none until the band that has it, so no Secret below floor 10, the rest
  sharing its chance so the odds still add to 100. Past 25 they hold; Secret doubles from 50 as
  before. The catalog had the odds change only at 10 and 25, which left floors 2 to 9 dealing
  alike and contradicted `FloorRules`' "its finds keep rising"; `OWNER.md` asks.
- **A padlocked unit's find is one grade better** (`Deal.PadlockedBetter`, `findFrom`'s new
  `better`): the same pick rolls the plain grade, then steps one up the grades the floor deals
  (each with a find and a chance there), and lands the same place among that grade's finds, so
  every find of a grade stays as likely. The floor's best grade stays its best: on floors 10 to 24
  that's Legendary, the one Secret built (the unplugged lamp) dealing from 25. So never a common
  behind a padlock; on floor 12 an Epic or Legendary 23 times in 100 (an ordinary door: 8.5).
- **No grade at the door** (D-204): the marked box's light tells it as it opens (B-02b).
- Studio's deal line names each find's grade and "behind its padlock". `stuffdeal.spec`'s
  fingerprint moved for the finds alone (everything else a seed deals was checked unchanged).
- Seen in Studio Play: seed 7 dealt twice on floors 2, 10 and 12 came out the same; floor 10's
  seven padlocked finds were each its plain roll one grade up (Teddy to Boombox, Mega goo ball to
  Galaxy goo ball); floor 2's two padlocks held tools.

Not chosen: rolling a padlock's grade on better odds (a pick-for-pick step is provable and keeps
the seed's deal); two grades better (no commons and few uncommons already).

## D-423 The sealed find's packaging: three shared packs, fitted round the find (S5-02b1, Nov 18)

S5-02b split into b1 (the packaging's art) and b2 (sealed finds in the game). b1 built three
packs as their own finds-kit set, `art/finds/packs/` (no game rows, never dealt alone): a
card-backed blister for Small finds (yellow card, red header with a hang slot, a clear bubble),
a window box for Medium (red and yellow print, a window in the front and a skylight in the top,
a printed backdrop inside, a hang tab), a taped brown carton for Large (H-taped flaps, a window
cut in the front, hand holes in the ends, one red print on a pale band). No words, no maker's
name. Uploaded; not yet imported (b2 imports them in Studio).

How a pack fits a find: each pack has a room for a find; it scales on each axis to the find's
size plus a pad, and no axis less than the largest over a stretch (blister 1.15, box 1.3, carton
1.8), so the print never squashes far; the find sits in the room's middle. `spec.py`'s `fit` is
the rule, `Finds/PackFit.luau` its numbers for the game.

Why the skylight: a closed box lets no bulb light in, and the cymbal monkey's dark fur read as a
black shape behind the film; toy boxes often carry a second window, and the top one is where the
unit's bulb is. Why the film is a grey-warm 0.14 with a broad soft glare: a pale film read
milky, and a thin hard glare read as a white rod inside the box. The windups set's spec had two
sounds (`SIREN`, `DUCK`) shadowing its own numbers (PIPELINE's gotcha), so the set couldn't load;
both are now imported as `..._SOUND` (its rows unchanged).

Not chosen: one pack per find (95 more models for a 1 in 20 roll); scaling a pack uniformly (a
cube-ish RC car in a carton came out 3 studs wide); torn-packaging art (b2 pulls the pack off
with a rip and scraps, the crack's way).

## D-424 Sealed finds' rules and their deal: one in twenty from the unit's pick (S5-02b2a, Nov 18)

S5-02b2 split in three: a (the rules and the deal, pure), b (sealed on the floor: wrapped in its
pack in the box and your hands, no press, the tear), c (through the gate and into the home). The
rules are `Finds/Seal`, specs in `tests/seal.spec`.

- **The roll.** A find is sealed when the unit's own pick, times 7919, has a fraction under 0.05
  (`Seal.sealed`). The grade and the find within it read the pick as it is, and the unit's stuff
  reads it times 89, so a large prime keeps the seal apart from all three: the spec finds about
  1 in 20 in every fifth of the picks, every grade on floors 1, 12 and 30, and units with stuff
  as often as any. No new draw from the floor's Random, so every deal and the seed fingerprint
  are as they were (stuffdeal, findgrade, deal and boxdeal specs unchanged). Seen in Studio's
  Edit view from a fresh clone of `Shared`: 32 of 589 finds sealed over seeds 1 to 20.
- **What's never sealed:** the floor's big find (it returns before the roll), the Packrat's
  pile, a note's unit (its box holds the note), a tool, and any find with no pack for its size.
- **The pack by size.** Catalog rows now carry the find's `size` (kit rows from `Finds/Rows`;
  the bedroom four by hand: the boombox, television and skates Large, the teddy Medium), and
  `Seal.packOf` maps Small, Medium and Large to `PackFit`'s keys; Big has none.
- **The fit** mirrors `spec.py` on Roblox's axes; a find more than 1.5 times deeper than wide is
  turned a quarter round (`Seal.held`) so the window shows its long side.
- **Boxed or loose:** the deal boxes a sealed find by its packed outside size (`Seal.outer`,
  `Deal.packs`). Packed, these stand loose: Boombox, DeskLamp, FairyLights, HardHat, NeonSign,
  OilLamp, RCCar, Skates, StainedGlassLamp, Television, UnpluggedLamp. Every palm-sized find
  still boxes. The fairy lights are Small but near a stud across, and the blister's 1.15
  stretch grows the card to about 1.9 studs tall. b2b should stand a flat find up so its face
  shows through the window; that would also keep its card smaller.
- **Worth** three times (`Seal.worth`). A sealed find never cracks: a hard drop tears its pack
  instead (`Seal.tears`, the crack's own `Chip.hard`), so the two never stack.
- The packs are imported (`Props.Finds.Blister`, `WindowBox`, `Carton`, two parts each, no
  Bones); the owner saves the place.

## D-425 A sealed find in its pack, in the box and in your hands (S5-02b2b1, Nov 18)

S5-02b2b split in two: b1 (wrapped everywhere, the press, the set-down) and b2 (the tear, the
dev pick, seen in Studio). Context ran short for all of it in one session.

- **One wrap for every screen.** `Finds/Pack.wrap` stretches the size's pack round the find as
  the art fits it (`Seal.fit`) and welds its board and film to the find's root, weightless and
  passing through everything, so the find still carries, lies and is taken as itself and no
  other system needs to know. The server wraps its own model (everyone sees it on the floor and
  in a friend's hand); the box's reveal and your hand's view wrap their own copies the same way.
  Checked in Studio's Edit view on the cymbal monkey, fairy lights, kazoo, boombox and teddy.
- **How it sits.** Packs face the way finds face (-Z), so an upright find shows its front; a find
  1.5 times deeper than wide is turned to show its side (D-424); a flat one, lower than 1 in 2.5
  of both its width and depth (`Seal.FlatRatio`; only the fairy lights today), lies on its back
  in its blister with its top to the bubble, the way a blister lies on a counter. Lying, the
  pack holds the find off the floor by `Seal.lift` (spec'd: always above, never past a
  carton's floor).
- **Carried as a flag on the find.** `Tool.sealed` in Slots, the slot's `Seal.slotAttribute`
  set before the key and cleared after it (as a Gold's), the box's `Opening.Sealed` stamped with
  the open, and `Deal.Contents.sealed` passed through `layBoxed` (boxed by `Pack.outer`) or the
  loose lay. A Gold is never wrapped. If the place lacks the pack, the find is dealt plain.
- **The press.** A sealed find's press (the lamps' Switch, the windups' Wind) crinkles the
  plastic at your hand (`Pack.Crinkle`, the try-on film's cellophane, short and pitched up) and
  rocks the pack in your hand for 0.3 s (`Pack.Rattle`); nothing is sent, and the server ignores
  a sealed find's press anyway. No words: the pack on screen says why.
- **The set-down.** A sealed find lands with a soft cardboard thud (`Pack.Thud`, the marked
  box's flap slap, lower and softer) instead of its own clank, its window turned back toward
  you. It never cracks while sealed (`cracks` counts it whole); the tear is b2's.


## D-426 A sealed find's pack tears on a hard drop (S5-02b2b2, Nov 18)

- **When.** The crack's own measure (`Seal.tears`, `Chip.hard`: running at 10 studs a second or
  more, or a fall of 4.5 studs or more from your hand), counted on its own in `onDrop` and in
  `dropAll` (caught or fallen while carrying): a sealed find never cracks in the same drop, as
  D-424 set. Set down standing still, it lands in its pack with the thud (D-425).
- **What you see and hear.** As it lands, a rip (`Pack.Rip`: Kept.Rip's sheet torn from 0.31 s,
  0.55 s of it, pitched up a little, heard as far as a dropped find) and the pack comes off:
  its board and film flung opposite ways with seven scraps of card and film, tumbling, lying
  1.4 s and fading in 0.5 s (`Pack.Torn`). The bare find then drops the pack's height to the
  floor in 0.14 s, turned up to 22 degrees as if spilled out, and lands with its own drop sound
  (`Slots`' `rip`, `SPILL`). From then it's a plain find: `Tool.sealed` cleared, the model's
  `Sealed` attribute cleared, worth its plain price.
- **How the pieces fly.** The server throws them (its network owner), so every screen sees the
  same tumble. They sit in their own collision group (`TornPack`, which doesn't collide with
  itself) so a scrap made inside the board isn't shot out, and they're thrown one physics step
  after their welds go: thrown at once, the board was still part of the anchored find and went
  nowhere (seen in Studio Play; fixed, all nine pieces thrown up to 2 studs and gone by 2.2 s).
- **The dev pick.** `DealFind` (and Studio's `DevBox`) take a key followed by " sealed"
  (`"CymbalMonkey sealed"`) to deal it still in its pack; a tool or a Big find is dealt plain
  with a warning.
- **Seen in Studio Play** on floor 2: the cymbal monkey and the teddy dealt sealed, opened from
  their box into your hand (both read clearly in their packs at A16 size), set down with the
  thud and still sealed, dropped from high and torn into a plain find. The press's crinkle
  wasn't driven from a script (the Wind button can't be clicked from the MCP): `OWNER.md`.

## D-427 · 2026-11-18 · A sealed find is kept sealed, under a name of its own (S5-02b2c1)

The moment: back home, the mint-in-box find stands on your shelf in its window box, and in the
job box's panel its card reads "Sealed Teddy bear" at three times the loose one's price. S5-02b2c
split in two: c1 (kept, shelved, sold, carried out of the box) and c2 (set out in its pack with
Arrange, a trip's torn one, the Packrat's flyer).

- **Kept as a name, not a count.** A sealed find goes into the save's `finds` as "Teddy:Sealed"
  (`Seal.key`/`Seal.base`), the way a Gold is "Teddy:Gold" (D-298). The shelf's spots, the job
  box, what's set out and a trip's `Up` each hold one particular find, so a name tells each
  which teddy is the sealed one; a count beside `finds` (as `chipped` is) can't say which spot's
  teddy is sealed. Save v1's own `sealed` counts stay empty (the header says so); no new save
  version. The book: the find's page is stamped by the find's name, and the sealed page
  (`stamps.sealed`) the first time one of it is kept sealed; a first sealed one of a kind you
  own lands on the shelf as a new kind (it chimes).
- **Through the gate:** Slots' `named` gives a sealed find's name, so `keep`, `GatePay` and the
  keep's rise (KeepView, ToolPicture) carry it in its pack with no new remote.
- **At home:** the shelf stands it wrapped (`Pack.wrap` before the cubby's fit, so the pack is
  fitted with it); the panel gives it its own card, just before its loose ones, sells it at
  `Seal.Times` (`BoxPanel.price`'s `sealed`), never offers or makes a Gold of it; Take puts it in
  your hand still sealed (Slots' `unbox`, `carryUp`); it's never worn (`boxToHead` refuses it)
  and never goes on the clothes rail (`Rail.row` doesn't know the name).
- **Torn while out of your box:** the find keeps its sealed name (`Tool.torn`) until it's
  settled, so the right one is struck; back in the box it's plain (`Save.unseal`), carried
  aboard by a friend it's theirs plain (`Taken`'s `torn`).
- **Not yet:** setting one out in your home (Arrange's tray leaves sealed cards out and the
  server refuses one, till c2 stands it in its pack by its packed size).

Not chosen: `data.sealed` as a count under `finds` (which one is sealed is lost the moment two
teddies are kept); a new save version moving a count to names (nothing was ever written to it).

## D-428 · 2026-11-18 · The haul valued one find at a time: its order, its timing and its list (S5-01a)

The owner's idea 25 (PROPOSAL, agreed): each find that became yours on the climb comes up on the
results one at a time, its picture, name, grade and worth, the total counting up, then a line for
each player. S5-01 is split in four (ROADMAP): a the order, timing and the server's list (this),
b the cards on the board, c each player's line, d seen in Studio.

- **Where:** on the board on the lobby car's back wall (CarResults), where the group stands after
  Again, facing it, while the car's 20-second count runs; not on the black "Caught" screen. The
  brief's moment is the team standing in the car watching the haul flip up, and the board is
  already where the cash counts up (D-151). Proven: Lethal Company's end-of-day tally on the
  ship's screen, Hades' end-of-run summary. A default in `OWNER.md`.
- **What counts:** every find a gate kept for a rider (GatePay's `kept`, its new `found`: the
  rider's own slots and the jukebox set down, not a friend's find taken up from home, which was
  never the climb's), each marked cracked as `chipped` says, from Climbs' `began` to the end;
  only those of friends standing in the car (a friend who left took theirs home already).
- **Worth:** what it sells for at your chest, `BoxPanel.price` (sealed three times, cracked half,
  the jukebox its 800). The cash comes when you sell (D-251), so the total is the haul's worth,
  not cash paid.
- **Order:** cheapest first and the most valuable last (a tie by grade, find, cracked, who), the
  same on every screen whatever order things were kept in: the storage-auction shows' build to
  the big reveal; a sealed Legendary may outvalue a Secret and comes after it.
- **Stings:** a Secret, the floor's big find, a find still sealed and a Legendary land with their
  own sting and a hold of quiet after (`Tally.Holds`: 1.4, 1.0, 0.7, 0.7 seconds).
- **Timing (`Tally.times`):** a short haul gives each card its `Beat` (0.62 s); a long one's
  cheap cards quicken to fit `Within` (8 s), never quicker than `Quick` (0.14 s, seven a second),
  while the last three cards and every sting card keep their beat; if even that overruns, the
  holds shrink to no less than 40%. A haul of 30 cheap finds and two stings fits in 8 s; past
  that it runs a little longer, still inside the count. The total (`Tally.total`) ticks each
  card's worth on over 0.4 s from its landing (0.18 s in), Cubic-out as D-151's cash does, and is
  whole as the last beat ends. A tap (`Tally.skip`) jumps to the next sting card, else the end.
- **The list:** "<userId>=<key>[!]" cells, comma separated (`Tally.encode`, "!" cracked, Studio's
  negative ids read), at most 60 (the cheapest left off past it), as a fifth field of the car's
  results value (`ClimbEnd.encodeResults(..., haul)`; `decodeResults` gives `haul`, "" for an old
  value). One value, so the board builds once with everything. Junk cells and keys that aren't
  finds are skipped on reading.

Not chosen: the haul on the "Caught" screen (no one stands anywhere there, and it would hold the
Again button back); the order kept in (cheap and dear jumbled, no build); a separate attribute for
the haul (two values arriving apart would build the board twice); the cover renders as pictures
(they were never uploaded as images; ToolPicture's 3D picture is what every other card uses).
