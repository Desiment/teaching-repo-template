# Course Materials Template

Template repository for LaTeX-based course materials: lectures, seminars,
homeworks, and assessment materials.

## Structure

```text
├── latexmkrc
├── justfile
├── records.lua
├── project/
│   ├── build/      # generated PDFs and auxiliary build files
│   └── pdf/        # root-build PDFs
└── src/
    ├── configuration/
    │   ├── lecturenotes/
    │   ├── practices/
    │   └── packages/
    ├── seminars/
    ├── homeworks/
    ├── lectures/
    │   ├── chapters/
    │   └── notes.tex
    ├── assessments/
    └── templates/
```

## Dependencies

All custom LaTeX classes and packages are GitHub submodules under
`src/configuration/`.

```sh
just init
just sync-skills
```

`just sync-skills` links OpenCode skills from configuration packages into
`.opencode/skills/`. Restart OpenCode after syncing or editing skills so the
running session reloads them.

## Metadata

Edit `records.lua` before writing course materials.

```lua
return {
  subject = "Subject Name",
  speciality = "Program Name",
  course = "1",
  uni = "University Name",
  year = "YYYY-YYYY"
}
```

## Commands

```sh
just

just new seminar
just new homework --no-edit
just new assessment
just new quiz
just new test
just new lecture chapter-01/meow.tex

just build src/seminars/seminar-01.tex
just build src/seminars/seminar-01.tex --no-solutions
just build src/assessments/quiz-01.tex --print
just preview src/lectures/notes.tex

just sync-skills
```

`just new ...` prompts for template values and creates the next numbered source
file in the appropriate folder. By default it opens the created file from that
folder using `$EDITOR`; pass `--no-edit` for non-interactive agent workflows.

`just new lecture chapter-01/meow.tex` creates
`src/lectures/chapters/chapter-01/meow.tex`, computes the relative `% !TeX root`
for `src/lectures/notes.tex`, and inserts the file into the master notes file.

Local `.latexmkrc` files are intended for editor integrations. They set
`$pdf_mode = 4`, use local source-directory paths, write builds to
`project/build`, and import shared memoize/build rules from `project/`.
Solutions are enabled by default for editor builds; use `--no-solutions` to
disable them and `--print` for quiz print imposition.

Assessment-related materials live together in `src/assessments/`.
