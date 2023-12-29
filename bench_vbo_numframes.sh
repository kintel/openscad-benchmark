#!/bin/bash
# Copyright 2021 Google LLC.
# SPDX-License-Identifier: Apache-2.00
#
# ./bench foo.scad
#
set -euo pipefail

TIMEOUT=120
RUNS=${RUNS:-1}
export OUTPUT_DIR=${OUTPUT_DIR:-$PWD/out}
mkdir -p "$OUTPUT_DIR"

LIBS_DIR=${LIBS_DIR:-$PWD/libs}
test -d "$LIBS_DIR" || ./get_libs

# TODO: Turn this into a cmd-line arg instead of using multiple top-level bench_*.sh scripts
vbo_modes=( none vbo-old vbo-new vbo-indexed )
num_frames=( 50 )
render_modes=( preview )

# Note: ~/Documents/OpenSCAD/libraries also on path on Mac
export OPENSCADPATH=$LIBS_DIR:${OPENSCADPATH:-}

function join_by {
  local IFS="$1"
  shift
  echo "$*"
}

function parse_parameter_set_names() {
  python3 -c "import sys, json; print('\n'.join(json.load(sys.stdin)['parameterSets'].keys()))"
}

files=()

for scad_file in "$@" ; do
  files+=( "$scad_file" )

  json_file="${scad_file%.scad}.json"
  if [[ -f "$json_file" ]]; then
    set_names="$( cat "$json_file" | parse_parameter_set_names )"
    while IFS= read -r setting
    do
      files+=( "$scad_file:$setting" )
    done <<< "$set_names"
  fi
done

if [[ "$#" -eq 1 ]]; then
  OUTPUT_NAME_PREFIX="$( basename "${1%.scad}" )"
else
  OUTPUT_NAME_PREFIX="results-$#-files"
fi

if [[ "${#files[@]}" -eq "$#" ]]; then
  OUTPUT_NAME="${OUTPUT_NAME_PREFIX}"
else
  OUTPUT_NAME="${OUTPUT_NAME_PREFIX}-${#files[@]}-variants"
fi

TIMESTAMP=$( date '+%Y%m%d-%H%M' )
OUTPUT_PREFIX="$OUTPUT_DIR/$OUTPUT_NAME-$TIMESTAMP"

hyperfine_args=(
  -i
  --show-output
  -L vbo_mode "$( join_by , "${vbo_modes[@]}" )"
  -L render_mode "$( join_by , "${render_modes[@]}" )"
  -L num_frames "$( join_by , "${num_frames[@]}" )"
  -L file "$( join_by , "${files[@]}" )"
  --runs "$RUNS"
  --export-json "$OUTPUT_PREFIX.json"
  "timeout ${TIMEOUT}s ./png-export.sh -m {render_mode} -v {vbo_mode} -f {num_frames} '{file}'"
)

echo "# Output will go in $OUTPUT_PREFIX.json"

hyperfine "${hyperfine_args[@]}"

./analyze_results.py --row-field=file --col-field=vbo_mode "$OUTPUT_PREFIX.json" --timeout=${TIMEOUT}
