#!/usr/bin/env bash
# Rebuild the storage unit's art from code (art/unit/README.md).
#   scripts/art.sh                      textures, export, renders, anim (about 15 min)
#   scripts/art.sh export               just the FBX and the game's spec module
#   SIZE=S scripts/art.sh geo export    another size (the M's textures serve every size)
#   scripts/art.sh dent                 the dent's bowed ribs: DoorDent_M.fbx and the Specs module
#                                       (seconds; SIZE=S for the small unit's)
#   scripts/art.sh dentsheet            the dent's look sheet, art/sheets/unit-dent.png (~2 min)
#   scripts/art.sh corridor             the corridor kit: FBX, Specs module, look sheets (under a
#                                       minute; it wears the unit's textures, so build those first)
#   scripts/art.sh corridor export      just the corridor kit's FBX and Specs module
#   scripts/art.sh boxes                the moving boxes: labels, their Cardboard bake, FBX, Specs
#                                       module, look sheets (about 3 minutes)
#   scripts/art.sh boxes export         just the boxes' FBX and Specs module
#   scripts/art.sh finds                the bedroom set's finds: their Bedroom bake, FBX, Specs
#                                       module, look sheets (the unit look needs the boxes built)
#   scripts/art.sh finds export         just the finds' FBX and Specs module
#   scripts/art.sh mannequin            the Mannequin: its bake, FBX, Specs module, then its look
#                                       sheets in the game's own poses (about 3 minutes)
#   scripts/art.sh mannequin export     just the Mannequin's FBX and Specs module
#   scripts/art.sh packrat              the Packrat: its bake, FBX, Specs module, then its look
#                                       sheets in the game's poses (about 3 minutes)
#   scripts/art.sh elevator             the freight elevator: key labels, its Car, Elevator and Keypad
#                                       bakes, FBX, Specs module, look sheets (about 6 minutes)
#   scripts/art.sh elevator export      just the elevator's FBX and Specs module
#   scripts/art.sh flashlight           the flashlight: its bake, FBX, Specs module, look sheets (the
#                                       view sheet needs the boxes built; about 3 minutes)
#   scripts/art.sh flashlight export    just the flashlight's FBX and Specs module
#   scripts/art.sh boltcutters          the bolt cutters: their bake, FBX, Specs module, look sheets
#                                       (the floor and view sheets need the boxes built; about 3 min)
#   scripts/art.sh boltcutters export   just the bolt cutters' FBX and Specs module
#   scripts/art.sh padlock              the padlock you carry: its bake, FBX, Specs module, look
#                                       sheets (the floor and view sheets need the boxes built)
#   scripts/art.sh padlock export       just the padlock's FBX and Specs module
#   scripts/art.sh coin                 the coin: its bake, FBX, Specs module (the coin and its
#                                       piles), look sheets (the floor sheet needs the boxes built)
#   scripts/art.sh coin export          just the coin's FBX and Specs module
#   scripts/art.sh coin icon            the coin count's icon, art/coin/out/CoinIcon.png (upload it
#                                       by hand: art/coin/README.md, "The count's icon")
#   scripts/art.sh battery              the battery: its bake, FBX, Specs module, look sheets (the
#                                       floor sheets need the boxes built; about a minute)
#   scripts/art.sh battery export       just the battery's FBX and Specs module
#   scripts/art.sh machine              the machine in the car: its bake, FBX, Specs module, look
#                                       sheets (the car sheets need the elevator built; ~3 min)
#   scripts/art.sh machine export       just the machine's FBX and Specs module
#   scripts/art.sh breaker              the breaker box: its bake, FBX (the box, the lever, the lamp),
#                                       Specs module, look sheets (the hall sheets wear the unit's
#                                       textures; about 3 minutes)
#   scripts/art.sh breaker export       just the breaker's FBX and Specs module
#   scripts/art.sh stuff                the mattress and the rolled carpet: their Stuff bake, FBX,
#                                       Specs module (with the box stacks), look sheets (the sheets
#                                       need the boxes built; about 4 minutes)
#   scripts/art.sh stuff export         just their FBX and Specs module
#   scripts/art.sh saw                  the saw: its bake, FBX, Specs module, look sheets (the floor
#                                       and view sheets need the boxes built; about 3 minutes)
#   scripts/art.sh saw export           just the saw's FBX and Specs module
#   scripts/art.sh airhorn              the air horn: its bake, FBX, Specs module, look sheets (the
#                                       floor and view sheets need the boxes built; about 2 minutes)
#   scripts/art.sh airhorn export       just the air horn's FBX and Specs module
#   scripts/art.sh bubblewrap           the bubble wrap: its bake (the roll and the laid sheet), FBX,
#                                       Specs module, look sheets (the floor and view sheets need
#                                       the boxes built; about 3 minutes)
#   scripts/art.sh bubblewrap export    just the bubble wrap's FBX and Specs module
#   scripts/art.sh ladder               the extension ladder: its bake, FBX (the base and the fly),
#                                       Specs module, look sheets (the floor and view sheets need the
#                                       boxes built; about 3 minutes)
#   scripts/art.sh ladder export        just the ladder's FBX and Specs module
#   scripts/art.sh cart                 the platform cart: its bake, FBX (body, forks, wheels), Specs
#                                       module, look sheets (about two minutes)
#   scripts/art.sh cart export          just the cart's FBX and Specs module
#   scripts/art.sh hole                 the crawl hole: its bake, FBX, Specs module, look sheets (it
#                                       wears the unit's Partition set: build the unit first)
#   scripts/art.sh hole export          just the crawl hole's FBX and Specs module
#   scripts/art.sh tophole              the sawn top: its bake, FBX, Specs module, look sheets (it
#                                       wears the unit's textures and reuses the hole kit's code)
#   scripts/art.sh tophole export       just the sawn top's FBX and Specs module
#   scripts/art.sh keptwrap             the wrap a kept player stands in: its bake (colour with
#                                       alpha), FBX, Specs module, look sheets (the unit sheets
#                                       need the boxes built; about 3 minutes)
#   scripts/art.sh keptwrap export      just the wrap's FBX and Specs module
#   scripts/art.sh feed                 the security camera feed's grain and snow pictures (seconds)
#   scripts/art.sh mark                 the faint mark on a note's door frame: its chalk texture
#                                       (drawn with numpy, no bake), FBX, look sheet (seconds)
#   scripts/art.sh lobby                the front office: FBX, Specs module, look sheets (it wears the
#                                       unit's textures and stands the elevator in its bays: build
#                                       both first; about 3 minutes)
#   scripts/art.sh lobby export         just the front office's FBX and Specs module
#   scripts/art.sh set figures          the Figures and models set (the RC car), the same way
#   scripts/art.sh set windups          the Wind-ups and noisemakers set (the cymbal monkey), the same way
#   scripts/art.sh set lights           a finds set built with the finds kit (art/finds/CRAFT.md,
#                                       "The kit"): bake, FBX and Luau, sheets and motion previews.
#                                       Name stages (textures export renders, or quick: fast,
#                                       rough sheets) and a find (DeskLamp) to do less
set -euo pipefail
cd "$(dirname "$0")/.."
if [ "${1:-}" = "set" ]; then
	# a finds set built with the finds kit (art/finds/CRAFT.md, "The kit"):
	#   scripts/art.sh set lights [textures|export|renders|quick ...] [FindName]
	name=$2
	shift 2
	stages=""
	only=""
	for w in "$@"; do
		case $w in textures | export | renders | quick) stages="$stages $w" ;; *) only=$w ;; esac
	done
	for st in ${stages:-textures export renders}; do
		echo "== $name $st ${only}"
		blender -b --factory-startup -P "art/finds/$name/build.py" -- --stage "$st" ${only:+--find "$only"} 2>&1 \
			| grep -E -i "error|traceback|RENDERED|BAKED|FBX|SPEC|skip|DONE|assert" || true
	done
	exit 0
fi
if [ "${1:-}" = "elevator" ]; then
	shift
	for st in ${*:-labels textures export renders}; do
		# the sheets stand the Mannequin in the game's own poses, written out by Lune
		if [ "$st" = "renders" ]; then lune run scripts/mannequin-poses; fi
		echo "== elevator $st"
		blender -b --factory-startup -P art/elevator/build.py -- --stage "$st" 2>&1 \
			| grep -E -i "error|traceback|RENDERED|BAKED|FBX|SPEC|atlas|DONE" || true
	done
	exit 0
fi
if [ "${1:-}" = "lobby" ]; then
	shift
	for st in ${*:-export renders}; do
		echo "== lobby $st"
		blender -b --factory-startup -P art/lobby/build.py -- --stage "$st" 2>&1 \
			| grep -E -i "error|traceback|RENDERED|FBX|SPEC|DONE|assert" || true
	done
	exit 0
fi
if [ "${1:-}" = "feed" ]; then
	blender -b --factory-startup -P art/feed/build.py 2>&1 | grep -E -i "error|traceback|DONE" || true
	exit 0
fi
if [ "${1:-}" = "mark" ]; then
	shift
	for st in ${*:-textures export renders}; do
		echo "== mark $st"
		blender -b --factory-startup -P art/mark/build.py -- --stage "$st" 2>&1 \
			| grep -E -i "error|traceback|RENDERED|BAKED|FBX|DONE" || true
	done
	exit 0
fi
if [ "${1:-}" = "keptwrap" ]; then
	shift
	for st in ${*:-textures export renders}; do
		echo "== keptwrap $st"
		blender -b --factory-startup -P art/keptwrap/build.py -- --stage "$st" 2>&1 \
			| grep -E -i "error|traceback|RENDERED|BAKED|FBX|SPEC|atlas|DONE" || true
	done
	exit 0
fi
if [ "${1:-}" = "boltcutters" ]; then
	shift
	for st in ${*:-textures export renders}; do
		echo "== boltcutters $st"
		blender -b --factory-startup -P art/boltcutters/build.py -- --stage "$st" 2>&1 \
			| grep -E -i "error|traceback|RENDERED|BAKED|FBX|SPEC|atlas|DONE" || true
	done
	exit 0
fi
if [ "${1:-}" = "hole" ]; then
	shift
	for st in ${*:-textures export renders}; do
		echo "== hole $st"
		blender -b --factory-startup -P art/hole/build.py -- --stage "$st" 2>&1 \
			| grep -E -i "error|traceback|RENDERED|BAKED|FBX|SPEC|atlas|DONE" || true
	done
	exit 0
fi
if [ "${1:-}" = "tophole" ]; then
	shift
	for st in ${*:-textures export renders}; do
		echo "== tophole $st"
		blender -b --factory-startup -P art/tophole/build.py -- --stage "$st" 2>&1 \
			| grep -E -i "error|traceback|RENDERED|BAKED|FBX|SPEC|atlas|DONE" || true
	done
	exit 0
fi
if [ "${1:-}" = "ladder" ]; then
	shift
	for st in ${*:-textures export renders}; do
		echo "== ladder $st"
		blender -b --factory-startup -P art/ladder/build.py -- --stage "$st" 2>&1 \
			| grep -E -i "error|traceback|RENDERED|BAKED|FBX|SPEC|atlas|DONE" || true
	done
	exit 0
fi
if [ "${1:-}" = "cart" ]; then
	shift
	for st in ${*:-textures export renders}; do
		echo "== cart $st"
		blender -b --factory-startup -P art/cart/build.py -- --stage "$st" 2>&1 \
			| grep -E -i "error|traceback|RENDERED|BAKED|FBX|SPEC|atlas|DONE" || true
	done
	exit 0
fi
if [ "${1:-}" = "saw" ]; then
	shift
	for st in ${*:-textures export renders}; do
		echo "== saw $st"
		blender -b --factory-startup -P art/saw/build.py -- --stage "$st" 2>&1 \
			| grep -E -i "error|traceback|RENDERED|BAKED|FBX|SPEC|atlas|DONE" || true
	done
	exit 0
fi
if [ "${1:-}" = "bubblewrap" ]; then
	shift
	for st in ${*:-textures export renders}; do
		echo "== bubblewrap $st"
		blender -b --factory-startup -P art/bubblewrap/build.py -- --stage "$st" 2>&1 \
			| grep -E -i "error|traceback|RENDERED|BAKED|FBX|SPEC|atlas|DONE" || true
	done
	exit 0
fi
if [ "${1:-}" = "airhorn" ]; then
	shift
	for st in ${*:-textures export renders}; do
		echo "== airhorn $st"
		blender -b --factory-startup -P art/airhorn/build.py -- --stage "$st" 2>&1 \
			| grep -E -i "error|traceback|RENDERED|BAKED|FBX|SPEC|atlas|DONE" || true
	done
	exit 0
fi
if [ "${1:-}" = "stuff" ]; then
	shift
	for st in ${*:-textures export renders}; do
		echo "== stuff $st"
		blender -b --factory-startup -P art/stuff/build.py -- --stage "$st" 2>&1 \
			| grep -E -i "error|traceback|RENDERED|BAKED|FBX|SPEC|atlas|DONE" || true
	done
	exit 0
fi
if [ "${1:-}" = "coin" ]; then
	shift
	for st in ${*:-textures export renders}; do
		echo "== coin $st"
		blender -b --factory-startup -P art/coin/build.py -- --stage "$st" 2>&1 \
			| grep -E -i "error|traceback|RENDERED|BAKED|FBX|SPEC|atlas|DONE" || true
	done
	exit 0
fi
if [ "${1:-}" = "battery" ]; then
	shift
	for st in ${*:-textures export renders}; do
		echo "== battery $st"
		blender -b --factory-startup -P art/battery/build.py -- --stage "$st" 2>&1 \
			| grep -E -i "error|traceback|RENDERED|BAKED|FBX|SPEC|atlas|DONE" || true
	done
	exit 0
fi
if [ "${1:-}" = "machine" ]; then
	shift
	for st in ${*:-textures export renders}; do
		echo "== machine $st"
		blender -b --factory-startup -P art/machine/build.py -- --stage "$st" 2>&1 \
			| grep -E -i "error|traceback|RENDERED|BAKED|FBX|SPEC|atlas|DONE" || true
	done
	exit 0
fi
if [ "${1:-}" = "breaker" ]; then
	shift
	for st in ${*:-textures export renders}; do
		echo "== breaker $st"
		blender -b --factory-startup -P art/breaker/build.py -- --stage "$st" 2>&1 \
			| grep -E -i "error|traceback|RENDERED|BAKED|FBX|SPEC|atlas|DONE" || true
	done
	exit 0
fi
if [ "${1:-}" = "padlock" ]; then
	shift
	for st in ${*:-textures export renders}; do
		echo "== padlock $st"
		blender -b --factory-startup -P art/padlock/build.py -- --stage "$st" 2>&1 \
			| grep -E -i "error|traceback|RENDERED|BAKED|FBX|SPEC|atlas|DONE" || true
	done
	exit 0
fi
if [ "${1:-}" = "flashlight" ]; then
	shift
	for st in ${*:-textures export renders}; do
		echo "== flashlight $st"
		blender -b --factory-startup -P art/flashlight/build.py -- --stage "$st" 2>&1 \
			| grep -E -i "error|traceback|RENDERED|BAKED|FBX|SPEC|atlas|DONE" || true
	done
	exit 0
fi
if [ "${1:-}" = "mannequin" ]; then
	shift
	for st in ${*:-textures export renders}; do
		# the sheets wear the poses from src/shared/Mannequin/Pose.luau, written out by Lune
		if [ "$st" = "renders" ]; then lune run scripts/mannequin-poses; fi
		echo "== mannequin $st"
		blender -b --factory-startup -P art/mannequin/build.py -- --stage "$st" 2>&1 \
			| grep -E -i "error|traceback|RENDERED|BAKED|FBX|SPEC|atlas|DONE" || true
	done
	exit 0
fi
if [ "${1:-}" = "packrat" ]; then
	shift
	for st in ${*:-textures export renders}; do
		# the sheets wear the poses from src/shared/Packrat/Pose.luau, written out by Lune
		if [ "$st" = "renders" ]; then lune run scripts/packrat-poses; fi
		echo "== packrat $st"
		blender -b --factory-startup -P art/packrat/build.py -- --stage "$st" 2>&1 \
			| grep -E -i "error|traceback|RENDERED|BAKED|FBX|SPEC|FIND|atlas|DONE" || true
	done
	exit 0
fi
if [ "${1:-}" = "finds" ]; then
	shift
	for st in ${*:-textures export renders}; do
		echo "== finds $st"
		blender -b --factory-startup -P art/finds/build.py -- --stage "$st" 2>&1 \
			| grep -E -i "error|traceback|RENDERED|BAKED|FBX|SPEC|atlas|DONE" || true
	done
	exit 0
fi
if [ "${1:-}" = "boxes" ]; then
	shift
	for st in ${*:-labels textures export renders}; do
		echo "== boxes $st"
		blender -b --factory-startup -P art/boxes/build.py -- --stage "$st" 2>&1 \
			| grep -E -i "error|traceback|RENDERED|BAKED|FBX|SPEC|atlas|DONE" || true
	done
	exit 0
fi
if [ "${1:-}" = "corridor" ]; then
	shift
	for st in ${*:-export renders}; do
		echo "== corridor $st"
		blender -b --factory-startup -P art/corridor/build.py -- --stage "$st" 2>&1 \
			| grep -E -i "error|traceback|RENDERED|FBX|SPEC|DONE" || true
	done
	exit 0
fi
SIZE=${SIZE:-M}
stages=${*:-textures export renders anim}
for st in $stages; do
	# The M's bake is every size's textures: another size never bakes, and its scene is rebuilt
	# from the scripts before each stage, so an export never ships stale geometry.
	if [ "$st" = "textures" ] && [ "$SIZE" != "M" ]; then
		echo "art.sh: only the M bakes textures (they serve every size); skipping textures ($SIZE)"
		continue
	fi
	if [ "$st" != "textures" ] && [ "$st" != "geo" ] \
		&& { [ "$SIZE" != "M" ] || [ ! -f "art/unit/out/$SIZE/unit.blend" ]; }; then
		rm -f "art/unit/out/$SIZE/unit.blend" # a failed rebuild leaves nothing stale to export
		blender -b --factory-startup -P art/unit/build.py -- --size "$SIZE" --stage textures --only none \
			| grep -E -i "error|traceback|SAVED" || true
	fi
	echo "== $st ($SIZE)"
	blender -b --factory-startup -P art/unit/build.py -- --size "$SIZE" --stage "$st" 2>&1 \
		| grep -E -i "error|traceback|RENDERED|BAKED|FBX|SPEC|ANIM|SAVED" || true
done
python3 art/unit/fixture.py "$SIZE"
