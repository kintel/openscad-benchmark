#!/bin/bash
# Copyright 2021 Google LLC.
# SPDX-License-Identifier: Apache-2.00
#
# Usage
#   ./render (preview|render|throwntogether) file.scad [parameter-set-name]
#
# New Usage
#   ./render -m (preview|render|throwntogether) -v (none,vbo-old,vbo-new,vbo-indexed) file.scad[:<param-set>]
#
set -euo pipefail

printUsage()
{
  echo "Usage: $0 [-mv] <file.scad>[:<param-set>]"
  echo
  echo "  -m RENDER_MODE  preview | render | throwntogether"
  echo "  -v VBO_MODE     none | vbo-old | vbo-new | vbo-indexed"
}

while getopts 'm:v:' c
do
  case $c in
    m) RENDER_MODE=${OPTARG};;
    v) VBO_MODE=${OPTARG};;
    *) printUsage;exit 1;;
  esac
done
shift $((OPTIND - 1))

#echo "Render mode: $RENDER_MODE"
#echo "VBO mode: $VBO_MODE"

INPUT_AND_PARAM_SET="${1:?Input file not set}"
INPUT="$( echo "$INPUT_AND_PARAM_SET" | sed -E 's/^(.*):.*$/\1/' )"
PARAM_SET="$( echo "$INPUT_AND_PARAM_SET" | sed -E 's/^[^:]*:?(.*)$/\1/' )"

OPENSCAD=${OPENSCAD:-$HOME/code/OpenSCAD/openscad/build/OpenSCAD.app/Contents/MacOS/OpenSCAD}

OUTPUT_DIR=${OUTPUT_DIR:-$PWD/out}
mkdir -p "$OUTPUT_DIR"

INPUT_NAME=$( basename "$INPUT" )
OUTPUT_PREFIX="${OUTPUT_DIR}/${INPUT_NAME%.scad}-${RENDER_MODE}-${VBO_MODE}"


ARGS=(
  "$INPUT"
  -o "$OUTPUT_PREFIX.png"
)

if [[ -n "$PARAM_SET" ]]; then
  ARGS+=(
    -p "${INPUT%.scad}.json"
    -P "$PARAM_SET"
  )
fi

case "$RENDER_MODE" in
  preview)
    ;;
  render)
    ARGS+=(
      "--render"
    )
    ;;
  throwntogether)
    ARGS+=(
      "--preview=throwntogether"
    )
    ;;
  *)
    echo "Invalid render mode: $RENDER_MODE" >&2
    exit 1
esac

case "$VBO_MODE" in
  none)
    ;;
  vbo-old)
    ARGS+=(
      "--enable=vertex-object-renderers"
    )
    ;;
  vbo-new)
    ARGS+=(
      "--enable=vertex-object-renderers" "--enable=vertex-object-renderers-direct" "--enable=vertex-object-renderers-prealloc"
    )
    ;;
  vbo-indexed)
    ARGS+=(
      "--enable=vertex-object-renderers" "--enable=vertex-object-renderers-indexed"
    )
    ;;
  *)
    echo "Invalid VBO mode: $VBO_MODE" >&2
    exit 1
esac

echo $OPENSCAD "${ARGS[@]}" > "$OUTPUT_PREFIX.log" 2>&1
$OPENSCAD "${ARGS[@]}" >> "$OUTPUT_PREFIX.log" 2>&1
