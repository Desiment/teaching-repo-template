# AGENTS.md

## Repo Shape
- This is a LuaLaTeX template repo for course materials, not an app/library build.
- Custom classes/packages are Git submodules under `src/configuration/`; run `just init` after checkout before compiling.
- Generated course source `.tex` files belong in `src/seminars/`, `src/homeworks/`, `src/assessments/`, and `src/lectures/chapters/`; generated PDFs/aux files go under `project/build` or `project/pdf` depending on the build entrypoint.
- `src/assessments/` holds assessment, quiz, and test files together.
- Lecture chapters are included by `src/lectures/notes.tex`; prefer `just new lecture <chapter/file.tex> --no-edit` because it creates the chapter and inserts the `\include{...}` line.
- `src/configuration/` is template/external configuration; do not patch it during course-material work. If a configuration bug is found, report it with a minimal working example and wait for maintainer instructions.
- `src/configuration/practices/` is a submodule with its own `AGENTS.md`; use that file only if explicitly instructed to work inside that class repo.
- Do not add parent-template or derived-course workflow notes to submodule instruction files such as `src/configuration/practices/AGENTS.md`; those repos should stay usable standalone.

## Template Workflow For Derived Repos
- This section applies only in course repos derived from this template, not when working in the template repository itself.
- In derived repos, treat infrastructure files such as `justfile`, `latexmkrc`, `project/.latexmkrc.*`, `scripts/`, directory conventions, CI, and shared scaffolding as template-owned.
- If an infrastructure bug or generally reusable improvement is found in a derived repo, do not patch it locally; report it to the maintainer and leave the work untouched until explicit instructions are provided.
- Bring template fixes into derived repos with a normal merge from the template remote, for example `git fetch template --tags` then `git merge <template-version-or-template/main>`.
- Do not rebase project history just to update from the template; template updates should normally be explicit merge events.
- Keep course-specific customization outside template-owned files whenever an extension point exists.
- If a reusable infrastructure fix was made locally first, port or cherry-pick it into the template repo, then merge the resulting template change back.

## Commands
- `just` prints the repo command help.
- `just init` initializes/updates the public submodules under `src/configuration/`.
- Run `scripts/ai-sync sync` from the repository root to link skills from
  `src/configuration/**/.skills/` into `.opencode/skills/`.
- Run `scripts/ai-sync check` first to inspect Git-pinned source commits,
  expected links, conflicts and drift without writing files or Git state.
- `scripts/ai-sync release` is disabled. Distribute reviewed package commits
  by explicit template gitlink updates and selected course merges,
  with confirmation of the exact targets; see README.md. Never distribute
  changes to every course automatically.
- Run `just install-hooks` to configure `.githooks/`. Run `just branches check`
  before changing cumulative weekly branches; the complete workflow is in
  `docs/BRANCHING.md`.
- Use `just new <kind> --no-edit` for non-interactive creation: `seminar`, `homework`, `assessment`, `quiz`, or `test`.
- Use `just new lecture chapter-01/topic.tex --no-edit` for lecture chapter files; the path is relative to `src/lectures/chapters/`.
- Build a specific file with `just build <path> [latexmk flags]`, for example `just build src/seminars/seminar-01.tex`.
- Shortcut builds exist: `just seminar 01`, `just homework 01`, `just assessment 01`, `just quiz 01`, `just quiz-print 01`, `just test 01`, and `just lecture notes`.
- Preview with `just preview <path> [latexmk flags]`.
- Clean aux files with `just clean`; remove generated LaTeX output with `just distclean`.

## OpenCode Skills
- Run `scripts/ai-sync sync` after `just init`, after submodule updates, or after adding/removing skills under configuration packages.
- Shared teaching skills come from the global teaching profile and are not
  stored or pinned in course repositories. LaTeX package-specific skills stay
  in their package repositories and are pinned by package submodule commits,
  not skill versions.
- `scripts/ai-sync check` is read-only (exit 0 healthy, exit 1 drift/conflicts).
  Sync preflights before writing and leaves foreign entries in place; missing
  required package submodules, mismatched gitlinks, dirty skill sources
  (staged/unstaged/untracked/ignored, including support files), or conflicting
  IDs must be fixed deliberately.
  Stale managed links and legacy links into `.bundle/skills/` are not
  automatically deleted: verify the intended source before removing a link by
  hand.
  Preflight cannot prevent a rare I/O error mid-sync; links may then be
  partially updated. Run `check`, resolve the error and rerun `sync` to
  reconcile the remaining managed links; foreign links are preserved.
- OpenCode V2 watches skill/config changes; use `/reload` if a session does
  not pick them up. A restart is not normally required.
- Skill sources under `src/configuration/**/.skills/` are part of configuration packages/submodules; do not patch them during course-material work unless explicitly instructed to maintain that package.
- `.opencode/skills/` is local project OpenCode configuration and may be modified for course-specific guidance. Sync-created entries are symlinks; replace a symlink with a real skill directory before local customization if you do not want to modify the source package.
- Use `practice-create-sheet` when creating full seminar, homework, assessment, quiz, or test sheets with document class setup, records files, metadata setters, `\null`, totals, and solution flags.
- Use `practice-author-problems` when writing practice-compatible exercises, questions, problem statements, solutions, answers, points, tasks, choices, or problem snippets.
- Use `practice-build` when compiling or debugging practice sheets, `latexmk`, LuaLaTeX, `--solutions`, `--print`, `TEXINPUTS`, `LUAINPUTS`, or generated artifacts.
- Use `practice-templates` when editing practice templates, examples, placeholder values, generated starter files, body inputs, or template conventions.
- Use `practice-maintenance` only when explicitly maintaining `practice.cls`, `code/practice.<mode>.tex`, public modes, class APIs, XSIM setup, metadata fields, or the practice repository itself.
- Use `flsuite-*` for floats, figures, captions, tables, reusable widths, graphics, TikZ, PGFPlots, TikZ-CD, SVG, source listings, and minted integration.
- Use `tssuite-*` for compact lists, text fields, small-caps shortcuts, draft todos, theorem declarations, and framed theorem environments.
- Use `xamsmath-*` for math package loading, aliases, paired delimiters, operators, braces, autosized operators, math fonts, sets, logic, number systems, algebra, calculus, combinatorics, and probability notation.
- Use `refsuite-*` for reference loading/configuration, TeX or Lua reference names, short references, bibliography helpers, indexes, zref-clever, and azcref integration.
- Use `luaboolean-00-usage` when creating TeX booleans from Lua boolean values in LuaLaTeX documents.

## Branch Topology
- Course `main` owns the scaffold, metadata and reviewed infrastructure; it is
  not an alias for the latest teaching week.
- Existing `week-NN` branches form one mutable cumulative chain. Every earlier
  week must be an ancestor of every later week.
- When an earlier week changes, use `scripts/week-chain` to create backup refs
  and recursively rebase all later weeks. Review the dry push plan and use only
  the script's atomic explicit `--force-with-lease` update; never use plain
  `--force`.
- New weekly deltas must be linear. Do not merge weeks or template branches
  into `week-NN`; template changes enter course `main` through a reviewed merge,
  then the weekly chain is rebased.
- `work/*` contains drafts and `backup/*` contains recovery refs. The Git remote
  belongs to the course owner; Git storage and student delivery are distinct.

## Build Gotchas
- `just build` changes into the TeX file's directory so local `.latexmkrc` files set the correct `TEXINPUTS`, `LUAINPUTS`, and `BIBINPUTS`; do not replace it with a root `latexmk <src/file.tex>` unless you want root-output behavior.
- LuaLaTeX is enforced via `project/.latexmkrc.make` (`$pdf_mode = 4`) with `--shell-escape`, `-halt-on-error`, and SyncTeX enabled.
- Solutions print by default. Pass `--no-solutions` to hide them, `--solutions` to force them, and `--print` for quiz print imposition.
- `SOLUTIONS_MODE=include|exclude latexmk ...` is supported and changes the jobname to `%A-solutions-<mode>`.
- Builds from material directories write PDF and aux output to `project/build`; root `latexmkrc` writes PDFs to `project/pdf` and aux to `project/build`.
- Memoize support is wired through `project/.latexmkrc.memoize`; keep `.mmz` and related generated files out of commits.

## Content Conventions
- Do not edit root `records.lua` unless explicitly asked; course metadata is owner-provided and templates load it as `recordsfile={records.lua}` via the configured Lua input paths.
- `src/configuration/preamble.tex` is the shared course preamble currently imported by generated materials and lecture notes.
- Template files intentionally contain `PLACEHOLDER-*` and `PROBLEM STATEMENT.` text; `just new ...` replaces the numbered/title/date/deadline placeholders when generating course source files.
- Keep generated artifacts out of commits: `project/build/`, `project/pdf/` contents except `.gitkeep`, `src/**/build/`, `**/.build/`, PDFs, SyncTeX, minted files, and LaTeX aux files are ignored.
