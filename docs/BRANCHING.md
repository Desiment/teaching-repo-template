# Course branch policy

## Roles

- `main` contains the course scaffold, metadata and reviewed template-owned
  infrastructure. It is not the latest teaching week.
- `week-NN` branches form one cumulative, ordered chain of course materials.
  Each existing earlier week must be an ancestor of every later week.
- `work/*` branches hold drafts that have not yet been assigned to the weekly
  chain.
- `backup/*` refs are temporary recovery points. They are not working branches.

The Git remote belongs to the course owner. Git storage, building PDFs, keeping
files under `project/files/`, and delivering material to students are separate
operations. A branch name does not prove that material was delivered.

## Mutable cumulative weeks

Weekly branches are mutable. Correcting `week-03` requires rebasing every later
existing week in order:

```text
main -> week-01 -> week-02 -> week-03' -> week-04' -> ...
```

Do not merge one week into another. New weekly deltas must be linear. Historical
merge commits may remain until the affected part of the chain is rewritten.
During propagation, `week-chain` replays each commit on the old first-parent
path. A historical merge is replayed as its net change against its first
parent, producing an ordinary commit; a patch already present in the new parent
is skipped as empty. The result is linear without discarding the merge's course
tree changes. The repository pre-push hook rejects new merge commits in weekly
updates.

When `main` changes, treat it as the changed parent and rebase the entire weekly
chain onto it. Template-owned changes first enter course `main` through a normal,
reviewed merge from the `template` remote. The cascading rebase then keeps the
weekly publication history linear.

## Safe cascading workflow

Start with a clean working tree and up-to-date remote-tracking refs. Before
editing an existing weekly tip:

```sh
scripts/week-chain check
scripts/week-chain begin week-03
```

`begin` records local and remote tips, creates timestamped refs under
`backup/week-chain/`, and writes a manifest under the repository's Git metadata.
After editing and committing `week-03`, propagate the change using the state path
printed by `begin`:

```sh
scripts/week-chain propagate <state.json>
scripts/week-chain check
scripts/week-chain push <state.json>
```

`push` is a dry plan by default. After reviewing every ref and lease, the owner
may run it with `--execute`. It uses one atomic push and an explicit
`--force-with-lease` for every rewritten branch. Never replace this with a plain
`--force`.

If the changed branch already moved, pass its former parent tip explicitly:

```sh
scripts/week-chain begin week-06 --old-tip origin/week-06
```

If a cherry-pick stops, resolve it and run `git cherry-pick --continue`, then
rerun `propagate <state.json> --accept-current`. The explicit flag makes the
script validate and record the manually created commit before continuing. If
you abort the cherry-pick instead, rerunning `propagate` retries that commit.
Backup refs and the state manifest must remain until the rewritten chain and
remote refs have been verified.

## Restrictions

- Do not run the cascade with a dirty working tree or an unfinished Git
  operation.
- Do not silently move a branch checked out in another worktree.
- Do not rebase `backup/*` refs.
- Inspect special branches such as assessment releases and `work/*` branches;
  the script deliberately does not rewrite them.
- Do not push, delete refs, or remove backups without reviewing the exact
  repository and branch list.
