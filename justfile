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
      '  just build <file|kind number|lecture> [latexmk flags]' \
      '  just <kind> <number> [latexmk flags]' \
      '  just clean [file|kind number|lecture]' \
      '  just distclean [file|kind number|lecture]' \
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
      '  just build seminar 1' \
      '                                   Build src/seminars/seminar-01.tex' \
      '  just build src/seminars/seminar-01.tex' \
      '                                   Build from the TeX file directory' \
      '  just build seminar 1 --no-solutions' \
      '                                   Build without printing solutions' \
      '  just build quiz 1 --print' \
      '                                   Build quiz print imposition' \
      '  just seminar 1' \
      '                                   Build and open seminar-01.pdf' \
      '  just build lecture' \
      '                                   Build src/lectures/notes.tex' \
      '' \
      'Helper utilities:' \
      '  just init                         Initialize Git submodules' \
      '  just sync-skills                  Sync configuration package OpenCode skills' \
      '  just clean                        Clean auxiliary files for all materials' \
      '  just clean seminar 1              Clean one material target' \
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

# Build a TeX target from its own directory
build target *args:
    @scripts/tex-target.sh build "{{ target }}" {{ args }}

# Build and open a TeX target with xdg-open
preview target *args:
    @scripts/tex-target.sh open "{{ target }}" {{ args }}

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

# Build and open a numbered seminar
seminar num *flags:
    @scripts/tex-target.sh open seminar "{{ num }}" {{ flags }}

# Build and open a numbered homework
homework num *flags:
    @scripts/tex-target.sh open homework "{{ num }}" {{ flags }}

# Build and open lecture notes
lecture *flags:
    @scripts/tex-target.sh open lecture {{ flags }}

# Build and open a numbered assessment
assessment num *flags:
    @scripts/tex-target.sh open assessment "{{ num }}" {{ flags }}

# Build and open a numbered quiz
quiz num *flags:
    @scripts/tex-target.sh open quiz "{{ num }}" {{ flags }}

# Build and open a numbered test
test num *flags:
    @scripts/tex-target.sh open test "{{ num }}" {{ flags }}

# Build and open a numbered quiz using print mode
quiz-print num *flags:
    @scripts/tex-target.sh open quiz "{{ num }}" --print {{ flags }}

# Remove LaTeX auxiliary files
clean *target:
    @scripts/tex-target.sh clean {{ target }}

# Remove all generated LaTeX output
distclean *target:
    @scripts/tex-target.sh distclean {{ target }}
