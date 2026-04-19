#!/usr/bin/env bash
# Create a repo with 2 existing worktrees and recent commits on both — strong multi-agent signal.
# Usage: existing-worktrees.sh <target-parent-dir>
# Produces:
#   <target-parent-dir>/repo/                 (main checkout on main)
#   <target-parent-dir>/repo-billing-a/       (worktree on feat/billing-a)
#   <target-parent-dir>/repo-search-b/        (worktree on feat/search-b)
set -euo pipefail

PARENT="${1:?target parent dir required}"
mkdir -p "$PARENT"
cd "$PARENT"
rm -rf repo repo-billing-a repo-search-b

mkdir repo
cd repo
git init -b main -q
git config user.email "test@example.com"
git config user.name "Test User"

cat > package.json <<'EOF'
{ "name": "testrepo", "version": "0.0.1", "private": true }
EOF
mkdir -p app
cat > app/layout.tsx <<'EOF'
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return <html><body>{children}</body></html>
}
EOF
git add -A
git commit -q -m "initial commit"

# Simulate a stable remote so worktree creation from origin/main works
git remote add origin "$(pwd)/.git"
git fetch -q origin 2>/dev/null || true

# Worktree 1: feat/billing-a with a recent commit
git worktree add -b feat/billing-a ../repo-billing-a HEAD -q
( cd ../repo-billing-a
  echo "billing work" > billing.ts
  git add -A
  git -c user.email=test@example.com -c user.name="Test User" commit -q -m "feat(billing): stub webhook"
)

# Worktree 2: feat/search-b with a recent commit
git worktree add -b feat/search-b ../repo-search-b HEAD -q
( cd ../repo-search-b
  echo "search work" > search.ts
  git add -A
  git -c user.email=test@example.com -c user.name="Test User" commit -q -m "feat(search): initial index"
)

echo "repo tree:"
git worktree list
echo ""
echo "main checkout at: $(pwd)"
echo "2 existing worktrees, recent commits on both. Strong multi-agent signal."
