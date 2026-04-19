#!/usr/bin/env bash
# Minimal Next.js-looking app with a dashboard page, a connector UI stub, and a Gmail integration stub.
# Usage: fake-next-app.sh <target-parent-dir>
# Produces: <target-parent-dir>/app/  (a fake Next.js App Router project — NO dev server, NO real code execution)
set -euo pipefail

PARENT="${1:?target parent dir required}"
mkdir -p "$PARENT"
cd "$PARENT"
rm -rf app

mkdir app
cd app

git init -b main -q 2>/dev/null || true
git config user.email "test@example.com" 2>/dev/null || true
git config user.name "Test User" 2>/dev/null || true

cat > package.json <<'EOF'
{
  "name": "fake-next-app",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start"
  },
  "dependencies": {
    "next": "^15.0.0",
    "react": "^19.0.0",
    "react-dom": "^19.0.0"
  }
}
EOF

cat > .env.example <<'EOF'
NEXT_PUBLIC_APP_URL=http://localhost:3000
PLATFORM_URL=
GOOGLE_OAUTH_CLIENT_ID=
GOOGLE_OAUTH_CLIENT_SECRET=
NOTION_OAUTH_CLIENT_ID=
NOTION_OAUTH_CLIENT_SECRET=
EOF

mkdir -p app/dashboard app/api/oauth/notion/authorize app/api/gmail/send app/components
cat > app/layout.tsx <<'EOF'
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return <html><body>{children}</body></html>
}
EOF

cat > app/dashboard/page.tsx <<'EOF'
// Dashboard shows the logged-in user's avatar and display name.
export default async function DashboardPage() {
  const user = await fetchCurrentUser()  // stub
  return (
    <div>
      <img src={user.avatarUrl} alt="avatar" />
      <h1>{user.displayName}</h1>
    </div>
  )
}

async function fetchCurrentUser() {
  return { avatarUrl: '/avatar.png', displayName: 'Jane Doe' }
}
EOF

cat > app/components/ConnectNotionButton.tsx <<'EOF'
'use client'
// Click this button → starts Notion OAuth by redirecting to /api/oauth/notion/authorize
export default function ConnectNotionButton() {
  return <button onClick={() => { window.location.href = '/api/oauth/notion/authorize' }}>Connect Notion</button>
}
EOF

cat > app/api/oauth/notion/authorize/route.ts <<'EOF'
import { NextResponse } from 'next/server'
// Redirects the user to Notion's authorize URL with the app's client_id, redirect_uri, scope, state.
export async function GET() {
  const clientId = process.env.NOTION_OAUTH_CLIENT_ID
  const redirect = `${process.env.PLATFORM_URL}/api/oauth/notion/callback`
  const state = crypto.randomUUID()
  const url = `https://api.notion.com/v1/oauth/authorize?client_id=${clientId}&redirect_uri=${encodeURIComponent(redirect)}&response_type=code&state=${state}`
  return NextResponse.redirect(url)
}
EOF

cat > app/api/gmail/send/route.ts <<'EOF'
import { NextResponse } from 'next/server'
// Sends an email via the Gmail API using a stored OAuth token for the current user.
export async function POST(req: Request) {
  const { to, subject, body } = await req.json()
  // ... fetch user's stored Gmail token, call gmail.users.messages.send ...
  return NextResponse.json({ sent: true, to, subject })
}
EOF

git add -A 2>/dev/null || true
git commit -q -m "scaffold fake next app" 2>/dev/null || true

echo "repo ready at: $(pwd)"
echo "routes:"
echo "  /dashboard                          — app-only flow (shows avatar + name)"
echo "  /api/oauth/notion/authorize         — connector-initiation flow (Notion OAuth)"
echo "  /api/gmail/send                     — full-third-party flow (requires real Gmail auth)"
echo "  no .env.local (only .env.example) — OAuth client ids intentionally missing"
