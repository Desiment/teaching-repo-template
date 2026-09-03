set shell := ["bash", "-cu"]

# Show command help
default:
    @just help

# Show command help
help:
    @printf '%s\n' \
      'Usage:' \
      '  just' \
      '  just new <kind> [name] [--no-edit]' \
      '  just build <file> [latexmk flags]' \
      '  just preview <file> [latexmk flags]' \
      '' \
      'Create practice files:' \
      '  just new seminar [--no-edit]      Create and edit the next seminar sheet' \
      '  just new homework [--no-edit]     Create and edit the next homework sheet' \
      '  just new assessment [--no-edit]   Create and edit the next assessment sheet' \
      '  just new quiz [--no-edit]         Create and edit the next quiz sheet' \
      '  just new test [--no-edit]         Create and edit the next test sheet' \
      '' \
      'Create lecture files:' \
      '  just new lecture chapter-01/meow.tex [--no-edit]' \
      '                                   Create, include, and edit a lecture chapter file' \
      '' \
      'Build and preview:' \
      '  just build src/seminars/seminar-01.tex' \
      '                                   Build from the TeX file directory' \
      '  just build src/seminars/seminar-01.tex --no-solutions' \
      '                                   Build without printing solutions' \
      '  just build src/assessments/quiz-01.tex --print' \
      '                                   Build quiz print imposition' \
      '  just preview src/lectures/notes.tex' \
      '                                   Build and preview from the TeX file directory' \
      '' \
      'Helper utilities:' \
      '  just init                         Initialize Git submodules' \
      '  just sync-skills                  Sync configuration package OpenCode skills' \
      '  just clean                        Remove LaTeX auxiliary files' \
      '  just distclean                    Remove generated LaTeX output'

# Create a new practice sheet or lecture chapter file
new kind *args:
    @set -- {{ args }}; \
    kind="{{ kind }}"; \
    edit=1; lecture_name=""; \
    while [ "$#" -gt 0 ]; do \
      case "$1" in \
        --no-edit) edit=0 ;; \
        --edit) edit=1 ;; \
        --*) echo "Unknown option: $1" >&2; exit 1 ;; \
        *) \
          if [ "$kind" != lecture ]; then echo "Unexpected argument for $kind: $1" >&2; exit 1; fi; \
          if [ -n "$lecture_name" ]; then echo "Unexpected extra lecture path: $1" >&2; exit 1; fi; \
          lecture_name="$1" ;; \
      esac; \
      shift; \
    done; \
    if [ "$kind" = lecture ]; then \
      if [ -z "$lecture_name" ]; then echo "Usage: just new lecture chapter-01/meow.tex [--no-edit]" >&2; exit 1; fi; \
      if [ "$edit" -eq 1 ]; then scripts/new-lecture.sh "$lecture_name"; else scripts/new-lecture.sh --no-edit "$lecture_name"; fi; \
      exit 0; \
    fi; \
    case "$kind" in \
      seminar) dir="src/seminars"; prefix="seminar"; template="src/templates/template.seminar.tex" ;; \
      homework) dir="src/homeworks"; prefix="homework"; template="src/templates/template.homework.tex" ;; \
      assessment) dir="src/assessments"; prefix="assessment"; template="src/templates/template.assessment.tex" ;; \
      quiz) dir="src/assessments"; prefix="quiz"; template="src/templates/template.quiz.tex" ;; \
      test) dir="src/assessments"; prefix="test"; template="src/templates/template.test.tex" ;; \
      *) echo "Unknown material kind: $kind" >&2; exit 1 ;; \
    esac; \
    last=$(compgen -G "${dir}/${prefix}-*.tex" | sed -E "s|.*${prefix}-([0-9]+)\.tex|\1|" | sort -n | tail -1); \
    if [ -z "$last" ]; then next=1; else next=$((10#$last + 1)); fi; \
    number=$(printf "%02d" "$next"); \
    filename="${prefix}-${number}.tex"; \
    file="${dir}/${filename}"; \
    title=""; date=""; deadline=""; \
    if [ -t 0 ]; then \
      case "$kind" in \
        seminar) read -r -p "Title: " title; read -r -p "Date: " date ;; \
        homework) read -r -p "Deadline: " deadline ;; \
        assessment) read -r -p "Title: " title; read -r -p "Date: " date ;; \
        quiz) read -r -p "Title: " title; read -r -p "Date: " date ;; \
        test) read -r -p "Title: " title; read -r -p "Date: " date ;; \
      esac; \
    fi; \
    cp "$template" "$file"; \
    NUMBER="$number" TITLE="$title" DATE="$date" DEADLINE="$deadline" perl -0pi -e 's/PLACEHOLDER-NUMBER/$ENV{NUMBER}/g; s/PLACEHOLDER-TITLE/$ENV{TITLE}/g; s/PLACEHOLDER-DATE/$ENV{DATE}/g; s/PLACEHOLDER-DEADLINE/$ENV{DEADLINE}/g' "$file"; \
    echo "Created $file"; \
    if [ "$edit" -eq 1 ]; then cd "$dir" && ${EDITOR:?EDITOR is not set} "$filename"; fi

# Build a TeX file from its own directory
build file *flags:
    @file="{{ file }}"; \
    dir=$(dirname -- "$file"); \
    filename=$(basename -- "$file"); \
    cd -- "$dir"; \
    latexmk {{ flags }} "$filename"

# Build and preview a TeX file from its own directory
preview file *flags:
    @file="{{ file }}"; \
    dir=$(dirname -- "$file"); \
    filename=$(basename -- "$file"); \
    cd -- "$dir"; \
    latexmk -pv {{ flags }} "$filename"

# Initialize Git submodules
init:
    git submodule update --init --recursive

# Sync configuration package OpenCode skills into project-local OpenCode config
sync-skills:
    @skills_dir=.opencode/skills; \
    mkdir -p "$skills_dir"; \
    for link in "$skills_dir"/*; do \
      [ -L "$link" ] && [ ! -e "$link" ] && rm "$link"; \
    done; \
    link_skill() { \
      name="$1"; \
      source="$2"; \
      target="$skills_dir/$name"; \
      if [ -L "$target" ]; then \
        current=$(readlink "$target"); \
        [ "$current" = "$source" ] && return 0; \
        rm "$target"; \
      elif [ -e "$target" ]; then \
        printf '%s\n' "Refusing to replace existing non-symlink: $target" >&2; \
        exit 1; \
      fi; \
      ln -s "$source" "$target"; \
    }; \
    shopt -s globstar nullglob; \
    count=0; \
    for skill_dir in src/configuration/**/.skills/*; do \
      [ -d "$skill_dir" ] || continue; \
      [ -f "$skill_dir/SKILL.md" ] || continue; \
      skill_name=$(basename "$skill_dir"); \
      link_skill "$skill_name" "../../$skill_dir"; \
      count=$((count + 1)); \
    done; \
    printf 'Synced %s OpenCode skill symlinks.\n' "$count"

# Build a numbered seminar
seminar num *flags:
    @just build "src/seminars/seminar-{{ num }}.tex" {{ flags }}

# Build a numbered homework
homework num *flags:
    @just build "src/homeworks/homework-{{ num }}.tex" {{ flags }}

# Build lecture notes or a named lecture file
lecture name="notes" *flags:
    @just build "src/lectures/{{ name }}.tex" {{ flags }}

# Build a numbered assessment
assessment num *flags:
    @just build "src/assessments/assessment-{{ num }}.tex" {{ flags }}

# Build a numbered quiz
quiz num *flags:
    @just build "src/assessments/quiz-{{ num }}.tex" {{ flags }}

# Build a numbered test
test num *flags:
    @just build "src/assessments/test-{{ num }}.tex" {{ flags }}

# Build a numbered quiz using print mode
quiz-print num *flags:
    @just build "src/assessments/quiz-{{ num }}.tex" --print {{ flags }}

# Remove LaTeX auxiliary files
clean:
    latexmk -c

# Remove all generated LaTeX output
distclean:
    latexmk -C
    rm -rf project/build/*
    find project/pdf -mindepth 1 ! -name .gitkeep -delete
