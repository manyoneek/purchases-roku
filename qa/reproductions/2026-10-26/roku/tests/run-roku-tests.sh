#!/bin/bash
# Runs each fix branch's suite with the fix, then with upstream Purchases.brs and the same tests.
set -u
run=$(cd "$(dirname "$0")" && pwd); export PATH="$run/bin:$PATH"
mkdir -p "$run/tests"
summary() { local log=$1; echo "cases_ok=$(grep -cE '^        ok ' "$log") cases_not_ok=$(grep -cE '^        not ok ' "$log") finished=$(grep -o 'EXIT_[A-Z_]*' "$log" | tail -1)"; }
for b in roku-fix-network roku-fix-nonsub roku-fix-config; do
  w="$run/worktrees/$b"; cd "$w"; ln -sfn ../purchases-roku/node_modules node_modules
  sh scripts/runLocal.sh > "$run/tests/$b-fixed.log" 2>&1; echo "exit=$?" >> "$run/tests/$b-fixed.log"
  git show origin/main:source/Purchases.brs > source/Purchases.brs
  sh scripts/runLocal.sh > "$run/tests/$b-upstream-sdk.log" 2>&1; echo "exit=$?" >> "$run/tests/$b-upstream-sdk.log"
  git checkout -- source/Purchases.brs; rm -f node_modules; rm -rf out
  echo "$b $(git rev-parse --short HEAD) fixed: $(summary $run/tests/$b-fixed.log) $(tail -1 $run/tests/$b-fixed.log)"
  echo "$b upstream-sdk: $(summary $run/tests/$b-upstream-sdk.log) $(tail -1 $run/tests/$b-upstream-sdk.log)"
  grep -E '^        not ok ' "$run/tests/$b-upstream-sdk.log" | sed 's/^ */    /'
  git status --porcelain
done
cd "$run/worktrees/purchases-roku"; sh scripts/runLocal.sh > "$run/tests/upstream-baseline.log" 2>&1; echo "exit=$?" >> "$run/tests/upstream-baseline.log"; rm -rf out
echo "upstream baseline 3011f85: $(summary $run/tests/upstream-baseline.log) $(tail -1 $run/tests/upstream-baseline.log)"
