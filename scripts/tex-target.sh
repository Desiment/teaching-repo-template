#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf '%s\n' \
    'Usage:' \
    '  scripts/tex-target.sh build <file> [latexmk flags]' \
    '  scripts/tex-target.sh build <kind> <number> [latexmk flags]' \
    '  scripts/tex-target.sh build lecture [latexmk flags]' \
    '  scripts/tex-target.sh open <target> [latexmk flags]' \
    '  scripts/tex-target.sh clean [target]' \
    '  scripts/tex-target.sh distclean [target]' >&2
}

die() {
  printf '%s\n' "$1" >&2
  exit 1
}

normalize_number() {
  local number="$1"
  [[ "$number" =~ ^[0-9]+$ ]] || die "Expected numeric sheet number, got: $number"
  printf '%02d' "$((10#$number))"
}

resolve_target() {
  local target="$1"
  shift
  local number

  case "$target" in
    seminar)
      [ "$#" -gt 0 ] || die 'Usage: just build seminar <number> [latexmk flags]'
      number=$(normalize_number "$1")
      shift
      resolved_file="src/seminars/seminar-${number}.tex"
      ;;
    homework)
      [ "$#" -gt 0 ] || die 'Usage: just build homework <number> [latexmk flags]'
      number=$(normalize_number "$1")
      shift
      resolved_file="src/homeworks/homework-${number}.tex"
      ;;
    assessment)
      [ "$#" -gt 0 ] || die 'Usage: just build assessment <number> [latexmk flags]'
      number=$(normalize_number "$1")
      shift
      resolved_file="src/assessments/assessment-${number}.tex"
      ;;
    quiz)
      [ "$#" -gt 0 ] || die 'Usage: just build quiz <number> [latexmk flags]'
      number=$(normalize_number "$1")
      shift
      resolved_file="src/assessments/quiz-${number}.tex"
      ;;
    test)
      [ "$#" -gt 0 ] || die 'Usage: just build test <number> [latexmk flags]'
      number=$(normalize_number "$1")
      shift
      resolved_file="src/assessments/test-${number}.tex"
      ;;
    lecture)
      [ "$#" -eq 0 ] || [[ "$1" == -* ]] || die 'Lecture builds use src/lectures/notes.tex; pass latexmk flags only after lecture.'
      resolved_file='src/lectures/notes.tex'
      ;;
    *.tex|*/*.tex)
      resolved_file="$target"
      ;;
    *)
      die "Unknown target: $target"
      ;;
  esac

  [ -f "$resolved_file" ] || die "No such TeX file: $resolved_file"
  resolved_args=("$@")
}

run_latexmk() {
  local file="$1"
  shift
  local dir filename
  dir=$(dirname -- "$file")
  filename=$(basename -- "$file")
  (cd -- "$dir" && latexmk "$@" "$filename")
}

pdf_path_for() {
  local file="$1"
  local base
  base=$(basename -- "$file" .tex)
  case "$file" in
    src/seminars/*|src/homeworks/*|src/assessments/*|src/lectures/*)
      printf 'project/build/%s.pdf\n' "$base"
      ;;
    *)
      printf '%s/%s.pdf\n' "$(dirname -- "$file")" "$base"
      ;;
  esac
}

open_target() {
  local file="$1"
  shift
  local pdf
  run_latexmk "$file" "$@"
  pdf=$(pdf_path_for "$file")
  [ -f "$pdf" ] || die "Expected PDF was not created: $pdf"
  xdg-open "$pdf"
}

all_targets() {
  shopt -s nullglob
  local files=( \
    src/seminars/seminar-*.tex \
    src/homeworks/homework-*.tex \
    src/assessments/assessment-*.tex \
    src/assessments/quiz-*.tex \
    src/assessments/test-*.tex \
  )
  [ "${#files[@]}" -gt 0 ] && printf '%s\0' "${files[@]}"
  [ -f src/lectures/notes.tex ] && printf '%s\0' src/lectures/notes.tex
}

clean_all() {
  local flag="$1"
  local file found=0
  while IFS= read -r -d '' file; do
    found=1
    run_latexmk "$file" "$flag"
  done < <(all_targets)
  [ "$found" -eq 1 ] || printf '%s\n' 'No TeX files found to clean.'
}

remove_generated_outputs() {
  rm -rf project/build/*
  find project/pdf -mindepth 1 ! -name .gitkeep -delete
}

main() {
  [ "$#" -gt 0 ] || { usage; exit 2; }
  local command="$1"
  shift

  case "$command" in
    build)
      [ "$#" -gt 0 ] || die 'Usage: just build <target> [latexmk flags]'
      resolved_args=()
      resolve_target "$@"
      run_latexmk "$resolved_file" "${resolved_args[@]}"
      ;;
    open)
      [ "$#" -gt 0 ] || die 'Usage: just <kind> <number> [latexmk flags]'
      resolved_args=()
      resolve_target "$@"
      open_target "$resolved_file" "${resolved_args[@]}"
      ;;
    clean)
      if [ "$#" -eq 0 ]; then
        clean_all -c
      else
        resolved_args=()
        resolve_target "$@"
        [ "${#resolved_args[@]}" -eq 0 ] || die 'clean accepts a target, not latexmk flags.'
        run_latexmk "$resolved_file" -c
      fi
      ;;
    distclean)
      if [ "$#" -eq 0 ]; then
        clean_all -C
        remove_generated_outputs
      else
        resolved_args=()
        resolve_target "$@"
        [ "${#resolved_args[@]}" -eq 0 ] || die 'distclean accepts a target, not latexmk flags.'
        run_latexmk "$resolved_file" -C
      fi
      ;;
    *)
      usage
      exit 2
      ;;
  esac
}

main "$@"
