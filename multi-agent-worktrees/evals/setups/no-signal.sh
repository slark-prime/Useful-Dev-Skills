#!/usr/bin/env bash
# Create a fresh repo with no concurrency signals.
# Usage: no-signal.sh <target-parent-dir>
# Produces: <target-parent-dir>/repo/  (fresh Next.js-like project, 1 commit, no other worktrees)
set -euo pipefail

PARENT="${1:?target parent dir required}"
mkdir -p "$PARENT"
cd "$PARENT"
rm -rf repo
mkdir repo
cd repo

git init -b main -q
git config user.email "test@example.com"
git config user.name "Test User"

cat > package.json <<'EOF'
{ "name": "testrepo", "version": "0.0.1", "private": true }
EOF

mkdir -p app/api
cat > app/layout.tsx <<'EOF'
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return <html><body>{children}</body></html>
}
EOF

git add -A
git commit -q -m "initial commit"

echo "repo ready at: $(pwd)"
echo "main checkout, no other worktrees, no recent activity on other branches."
