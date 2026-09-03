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
- `just init` initializes/updates all submodules.
- `just sync-skills` links configuration package skills from `src/configuration/**/.skills/` into `.opencode/skills/`.
- Use `just new <kind> --no-edit` for non-interactive creation: `seminar`, `homework`, `assessment`, `quiz`, or `test`.
- Use `just new lecture chapter-01/topic.tex --no-edit` for lecture chapter files; the path is relative to `src/lectures/chapters/`.
- Build a specific file with `just build <path> [latexmk flags]`, for example `just build src/seminars/seminar-01.tex`.
- Shortcut builds exist: `just seminar 01`, `just homework 01`, `just assessment 01`, `just quiz 01`, `just quiz-print 01`, `just test 01`, and `just lecture notes`.
- Preview with `just preview <path> [latexmk flags]`.
- Clean aux files with `just clean`; remove generated LaTeX output with `just distclean`.

## OpenCode Skills
- Run `just sync-skills` after `just init`, after submodule updates, or after adding/removing skills under configuration packages.
- OpenCode loads skills at startup; restart OpenCode after syncing or editing `.opencode/skills/`.
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
