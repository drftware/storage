#!/usr/bin/env bash
# Rebuild the storage unit's art from code (art/unit/README.md).
#   scripts/art.sh                      textures, export, renders, anim (about 15 min)
#   scripts/art.sh export               just the FBX and the game's spec module
#   SIZE=L scripts/art.sh geo export    another size (textures are shared by all sizes)
set -euo pipefail
cd "$(dirname "$0")/.."
SIZE=${SIZE:-M}
stages=${*:-textures export renders anim}
for st in $stages; do
	if [ "$st" != "textures" ] && [ "$st" != "geo" ] && [ ! -f "art/unit/out/$SIZE/unit.blend" ]; then
		blender -b --factory-startup -P art/unit/build.py -- --size "$SIZE" --stage textures --only none
	fi
	echo "== $st ($SIZE)"
	blender -b --factory-startup -P art/unit/build.py -- --size "$SIZE" --stage "$st" 2>&1 \
		| grep -E -i "error|traceback|RENDERED|BAKED|FBX|SPEC|ANIM|SAVED" || true
done
python3 art/unit/fixture.py "$SIZE"
