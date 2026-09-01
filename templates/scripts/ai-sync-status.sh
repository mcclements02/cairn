#!/usr/bin/env bash
# AI-SYNC status — live cross-worktree / cross-branch view to surface stranded
# (uncommitted or unmerged) work. Read-only: performs NO git mutations.
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

base=""
for b in main master develop; do
  if git show-ref --verify --quiet "refs/heads/$b"; then base="$b"; break; fi
done

echo "== AI-SYNC status: $(basename "$ROOT") =="
echo "base branch: ${base:-<none>}"
echo
echo "-- worktrees --"
git worktree list
echo

echo "-- per-worktree state --"
path=""; branch=""
while IFS= read -r line; do
  case "$line" in
    "worktree "*) path="${line#worktree }" ;;
    "branch "*)   branch="${line#branch refs/heads/}" ;;
    "detached")   branch="(detached)" ;;
    "")
      if [ -n "$path" ]; then
        dirty="$(git -C "$path" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
        flag=""; [ "$dirty" != "0" ] && flag="  <-- uncommitted"
        printf "  %-44s %-22s dirty=%s%s\n" "$path" "$branch" "$dirty" "$flag"
        path=""; branch=""
      fi ;;
  esac
done < <(git worktree list --porcelain)
echo

if [ -n "$base" ]; then
  echo "-- local branches NOT merged into $base (potential stranded work) --"
  found=0
  while IFS= read -r b; do
    [ "$b" = "$base" ] && continue
    if ! git merge-base --is-ancestor "$b" "$base" 2>/dev/null; then
      ahead="$(git rev-list --count "$base..$b" 2>/dev/null || echo '?')"
      printf "  %-32s +%s ahead of %s\n" "$b" "$ahead" "$base"; found=1
    fi
  done < <(git for-each-ref --format='%(refname:short)' refs/heads)
  [ "$found" = "0" ] && echo "  (none — all local branches merged)"
  echo
fi

echo "-- latest ledger entries (AI_HANDOFF.md) --"
if [ -f AI_HANDOFF.md ]; then
  awk '/^### /{c++} c>=1 && c<=3{print} c>3{exit}' AI_HANDOFF.md | sed 's/^/  /'
else
  echo "  (no AI_HANDOFF.md in this repo)"
fi
