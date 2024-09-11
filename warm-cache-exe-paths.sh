#!/bin/bash

source "prelude.sh"

# extracted from https://github.com/vegerot/dotfiles/blob/a9a50230d808572173d3eeec057739d0fe8d4470/bin/fzf-menu by @vegerot
get_programs_in_path() {
  local find_prog
  local find_args
  if [[ -n "${FIND_PROG:-}" ]]; then
    find_prog=$FIND_PROG
    find_args=${FIND_ARGS:-}
  elif find / -maxdepth 0 -executable &>/dev/null || command -v gfind &>/dev/null; then
    # GNU find
    find_prog="$(command -v gfind || echo find) -L"
    find_args="-maxdepth 1 -executable -type f,l -printf %f\n"
  elif command -v fd > /dev/null; then
    find_prog="fd ."
    find_args="--hidden --max-depth=1 --type=executable --follow --format {/}"
  else
    # BSD find
    find_prog="find"
    find_args="-maxdepth 1 -perm +111 -type f,l -exec basename {} ;"
  fi

  local pathDeduped=$(printf '%s\n' $PATH | tr ':' '\n' | uniq )
  for p in $pathDeduped; do
    $find_prog $p $find_args 2>/dev/null || true
  done \
    | awk '!x[$0]++'
    # awk removes duplicates without sorting.  Thanks https://stackoverflow.com/a/11532197/6100005 \
  }
export -f get_programs_in_path


COMMAND_FIND="FIND_PROG='find -L' FIND_ARGS='-maxdepth 1 -executable -type f,l -printf %f\n' get_programs_in_path"
COMMAND_FD="FIND_PROG='fd .' FIND_ARGS='--hidden --max-depth=1 --type=executable --follow --format {/} ' get_programs_in_path"

hyperfine --shell=bash --warmup "$WARMUP_COUNT" \
    "$COMMAND_FIND" \
    "$COMMAND_FD" \
    --export-markdown results-warm-cache-no-pattern.md
check_for_differences "false" "$COMMAND_FIND" "$COMMAND_FD"
