#!/usr/bin/env bash
# Create a repo + 1 linked worktree. Sub-agent should be invoked with cwd pointing at the worktree,
# not the main checkout — simulating an already-isolated session.
# Usage: cwd-is-worktree.sh <target-parent-dir>
# Produces:
#   <target-parent-dir>/repo/                  (main checkout on main)
#   <target-parent-dir>/repo-dashboard/        (worktree on feat/dashboard) <-- invoke sub-agent here
set -euo pipefail

PARENT="${1:?target parent dir required}"
mkdir -p "$PARENT"
cd "$PARENT"
rm -rf repo repo-dashboard

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

git remote add origin "$(pwd)/.git"
git fetch -q origin 2>/dev/null || true

git worktree add -b feat/dashboard ../repo-dashboard HEAD -q
( cd ../repo-dashboard
  mkdir -p app/dashboard
  cat > app/dashboard/page.tsx <<'EOF'
export default function DashboardPage() { return <div>Dashboard</div> }
EOF
  git add -A
  git -c user.email=test@example.com -c user.name="Test User" commit -q -m "feat(dashboard): scaffold page"
)

echo "main checkout at: $(pwd)"
echo "dashboard worktree at: $(cd ../repo-dashboard && pwd)"
echo "Sub-agent should cd into the dashboard worktree before running the skill."
