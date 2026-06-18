#!/usr/bin/env bash
set -euo pipefail

printf '\nADA-IR Leads Tracker - GitHub auth setup\n'
printf 'This stores your GitHub token locally in ~/.hermes/.env (chmod 600) and configures git.\n\n'

read -r -p 'GitHub username: ' GITHUB_USERNAME
read -r -p 'Git commit email: ' GIT_EMAIL
read -r -p 'Git commit name [ADA-IR Bot]: ' GIT_NAME
GIT_NAME=${GIT_NAME:-ADA-IR Bot}

printf '\nPaste your GitHub Personal Access Token. Input is hidden.\n'
printf 'Required classic token scopes: repo, workflow\n'
read -r -s -p 'GitHub token: ' GITHUB_TOKEN
printf '\n'

mkdir -p "$HOME/.hermes"
touch "$HOME/.hermes/.env"
chmod 600 "$HOME/.hermes/.env"

python3 - "$HOME/.hermes/.env" "$GITHUB_TOKEN" "$GITHUB_USERNAME" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
token = sys.argv[2].strip()
username = sys.argv[3].strip()
lines = []
if path.exists():
    lines = [ln for ln in path.read_text().splitlines() if not (ln.startswith('GITHUB_TOKEN=') or ln.startswith('GITHUB_USERNAME='))]
lines.append(f'GITHUB_TOKEN={token}')
lines.append(f'GITHUB_USERNAME={username}')
path.write_text('\n'.join(lines) + '\n')
PY

git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"
git config --global credential.helper store

# Store credentials for normal git HTTPS operations. The token is hidden from terminal output.
printf 'protocol=https\nhost=github.com\nusername=%s\npassword=%s\n\n' "$GITHUB_USERNAME" "$GITHUB_TOKEN" | git credential approve

printf '\nVerifying token with GitHub API...\n'
HTTP_CODE=$(curl -sS -o /tmp/github-user-check.json -w '%{http_code}' \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H 'Accept: application/vnd.github+json' \
  https://api.github.com/user)

if [ "$HTTP_CODE" != "200" ]; then
  printf 'GitHub auth check failed (HTTP %s). Response:\n' "$HTTP_CODE" >&2
  cat /tmp/github-user-check.json >&2
  exit 1
fi

LOGIN=$(python3 - <<'PY'
import json
print(json.load(open('/tmp/github-user-check.json')).get('login',''))
PY
)
printf 'GitHub auth OK. Logged in as: %s\n' "$LOGIN"
printf '\nNext: tell Hermes: GitHub auth is done, username is %s\n' "$LOGIN"
