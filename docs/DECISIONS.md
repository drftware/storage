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
