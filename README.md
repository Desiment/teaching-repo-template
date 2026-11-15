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
scripts/ai-sync check
scripts/ai-sync sync
just install-hooks
just branches check
```

Shared teaching skills are provided by the global teaching profile and are not
stored or pinned in course repositories. Package-specific skills stay beside
their LaTeX packages in `src/configuration/**/.skills/`.
`scripts/ai-sync check` is read-only: it prints package Git gitlink commit SHAs,
checkout HEADs, skill sources, expected links, missing or broken links, and
skill-ID conflicts. Exit 0 means managed package links match clean Git-pinned
sources; exit 1 reports drift, dirty skill files, broken links, legacy
`.bundle` links or conflicts. This includes ignored SKILL.md and support files:
Git status alone cannot detect them, so they cannot be advertised as pinned
content. Check does not initialize submodules. `scripts/ai-sync sync`
preflights the entire set before editing local `.opencode/skills/`: it
creates/corrects only recognizable managed links and preserves other entries,
including foreign symlinks. Stale managed links require manual review/removal:
a missing source file alone does
not prove that the pinned commit deleted it. Sync refuses to proceed when a
required package submodule is missing, a checkout differs from its gitlink,
the available source's skill files have staged, unstaged, untracked or ignored
changes, IDs collide, or an existing local entry blocks a skill. Resolve such
issues explicitly; do not delete course-local skills to make sync succeed.
Preflight catches known conflicts before writes; a rare runtime I/O failure
can still leave some links updated and others pending. Run `check` and then
rerun `sync` after resolving the failure; it safely reconciles managed links
without deleting unrelated entries.
OpenCode V2 watches skill/config changes; use `/reload` if the current session
does not pick them up. A restart is not normally necessary.

`just install-hooks` configures the repository-managed hooks. The pre-push hook
checks cumulative `week-NN` ancestry and rejects new merge commits in weekly
updates. `just init` installs the same hook path after initializing package
submodules.

Course `main` stores the course scaffold, metadata and reviewed infrastructure;
it is not the latest teaching week. Mutable cumulative branches `week-NN` form
one ordered chain. Correcting an earlier week requires a cascading rebase of
all later weeks. Use `just branches check` and the guarded workflow documented
in [`docs/BRANCHING.md`](docs/BRANCHING.md). The Git remote belongs to the
course owner and is separate from delivery of material to students.

## Updating skills safely

Do not use `scripts/ai-sync release`: it is disabled and cannot commit, push,
or merge courses. Shared teaching skills are maintained in the global teaching
profile, outside this template. Maintain package-specific skills in their
respective LaTeX package repositories. Select and review concrete Git commit
SHAs, never invented skill versions. Once package changes are reviewed and
published with explicit authorization:

1. In the template, update only the intended package submodule checkouts to
   their chosen commits; review and commit the resulting gitlink changes. A
   gitlink records the exact commit SHA.
2. Review the template commit and update **each selected course individually**
   by an explicit template merge (not a rebase or automatic workspace-wide
   release). Review merge conflicts and the selected course's gitlinks.
3. Initialize/update the selected package submodules in that course. Run
   `scripts/ai-sync check` to inspect the plan and `scripts/ai-sync sync` to
   install its local links, then run `check` again. Legacy links into
   `.bundle/skills/` must be verified and removed manually. Use `/reload` if
   needed.

Before any commits, pushes, merges, or submodule updates, obtain explicit
confirmation for the exact repositories and target commits. Sync does not
publish Git changes, and `.opencode/` is ignored by this template.

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
just publish seminar 1
just publish seminar 1 --no-solutions
just publish lecture

scripts/ai-sync check
scripts/ai-sync sync
just install-hooks
just branches check
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

Seminar publication names always state whether solutions are present:
`just publish seminar 1` and `--solutions` publish
`seminar-01-solutions.pdf`, while `--no-solutions` publishes
`seminar-01-no-solutions.pdf`. Seminar publication does not accept a custom
`--suffix` or `--print`; this prevents ambiguous files such as
`seminar-01.pdf` under `project/files/seminars/`.

Lecture notes are published only as `project/files/notes.pdf` with
`just publish lecture`. Lecture publication rejects `--suffix`, `--print`, and
solution-mode flags.

Assessment-related materials live together in `src/assessments/`.
