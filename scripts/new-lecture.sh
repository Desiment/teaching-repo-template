#!/usr/bin/env bash
set -euo pipefail

usage() {
    printf 'Usage: %s [--no-edit] chapter-dir/file[.tex]\n' "$0" >&2
}

edit=1
name=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        --no-edit)
            edit=0
            ;;
        --edit)
            edit=1
            ;;
        --*)
            printf 'Unknown option: %s\n' "$1" >&2
            usage
            exit 1
            ;;
        *)
            if [ -n "$name" ]; then
                printf 'Unexpected extra argument: %s\n' "$1" >&2
                usage
                exit 1
            fi
            name="$1"
            ;;
    esac
    shift
done

if [ -z "$name" ]; then
    usage
    exit 1
fi

name="${name#chapters/}"
case "$name" in
    /*|../*|*/../*|*/..|..)
        printf 'Lecture path must stay inside src/lectures/chapters: %s\n' "$name" >&2
        exit 1
        ;;
esac

case "$name" in
    *.tex) ;;
    *) name="$name.tex" ;;
esac

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)
lectures_dir="$repo_root/src/lectures"
chapters_dir="$lectures_dir/chapters"
notes_file="$lectures_dir/notes.tex"
template="$repo_root/src/templates/template.lecture.tex"
file="$chapters_dir/$name"
dir=$(dirname -- "$file")
filename=$(basename -- "$file")
include_path="chapters/$name"

mkdir -p -- "$dir"

if [ ! -s "$notes_file" ]; then
    cat > "$notes_file" <<'NOTES'
% !TeX root = notes.tex
% !TeX spellcheck = ru-RU
% !TeX encoding = UTF-8 Unicode
% !BIB program = biber
% LTeX: language=ru-RU
% LTeX: enablePickyRules=true

\documentclass{lecturenotes}
\input{preamble.tex}

\title{PLACEHOLDER-TITLE}
\author{PLACEHOLDER-AUTHOR}
\date{\today}

\begin{document}
\maketitle
\newpage
\tableofcontents
\newpage

\chapter{PLACEHOLDER-CHAPTER}
\localtableofcontents

\end{document}
NOTES
fi

if [ ! -e "$file" ]; then
    title=""
    if [ -t 0 ]; then
        printf 'Section title: '
        IFS= read -r title
    fi
    title=${title:-PLACEHOLDER-TITLE}

    root=$(realpath --relative-to="$dir" "$notes_file")
    ROOT="$root" TITLE="$title" perl -0pe \
        's/PLACEHOLDER-ROOT/$ENV{ROOT}/g; s/PLACEHOLDER-TITLE/$ENV{TITLE}/g' \
        "$template" > "$file"
    printf 'Created %s\n' "$file"
else
    printf 'File already exists: %s\n' "$file"
fi

if ! grep -F "\\include{$include_path}" "$notes_file" > /dev/null; then
    INCLUDE_LINE="\\include{$include_path}" perl -0pi -e '
        my $include = $ENV{INCLUDE_LINE} . "\n\n";
        s/\n\\end\{document\}\s*\z/\n$include\\end{document}\n/
            or die "Cannot find \\end{document} in $ARGV\n";
    ' "$notes_file"
    printf 'Inserted %s into %s\n' "$include_path" "$notes_file"
fi

if [ "$edit" -eq 1 ]; then
    cd -- "$dir"
    ${EDITOR:?EDITOR is not set} "$filename"
fi
