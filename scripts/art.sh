#!/usr/bin/env bash
# Rebuild the storage unit's art from code (art/unit/README.md).
#   scripts/art.sh                      textures, export, renders, anim (about 15 min)
#   scripts/art.sh export               just the FBX and the game's spec module
#   SIZE=S scripts/art.sh geo export    another size (the M's textures serve every size)
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
#   scripts/art.sh elevator             the freight elevator: key labels, its Car, Elevator and Keypad
#                                       bakes, FBX, Specs module, look sheets (about 6 minutes)
#   scripts/art.sh elevator export      just the elevator's FBX and Specs module
set -euo pipefail
cd "$(dirname "$0")/.."
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
