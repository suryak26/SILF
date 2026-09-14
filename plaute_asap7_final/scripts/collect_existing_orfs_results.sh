#!/usr/bin/env bash
set -euo pipefail

# Run from the root of the SILF repository after creating palute_7nm_final.
# This imports the previously completed ASAP7 ORFS baseline without modifying
# the original SILF_ASAP7 workspace.

DEST="$(pwd)/palute_7nm_final/results/orfs_asap7_previous_run"
SRC="${HOME}/SILF_ASAP7/orfs/runs/results/asap7/palute_baseline_lut_gen"

if [[ ! -d "$SRC" ]]; then
  echo "ERROR: previous ASAP7 ORFS results not found:"
  echo "  $SRC"
  exit 1
fi

mkdir -p "$DEST"

for variant in base 2ns; do
  if [[ -d "$SRC/$variant" ]]; then
    echo "Copying $variant ..."
    mkdir -p "$DEST/$variant"
    cp -a "$SRC/$variant/." "$DEST/$variant/"
  fi
done

echo
echo "Imported previous ORFS ASAP7 results into:"
echo "  $DEST"
echo
echo "Note: large ODB/GDS artifacts may be better handled with Git LFS."
