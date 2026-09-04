#!/usr/bin/env bash
# Interactive Bitwarden login for this machine. Run in YOUR terminal, not chat.
# Saves an unlock session to ~/.config/bitwarden-agent/session (mode 600)
# so the agent can import env files without seeing your password.
set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"
session_dir="$HOME/.config/bitwarden-agent"
session_file="$session_dir/session"

if ! command -v bw >/dev/null 2>&1; then
  echo "bw is not installed. Expected $HOME/.local/bin/bw" >&2
  exit 1
fi

mkdir -p "$session_dir"
chmod 700 "$session_dir"
umask 077

state="$(bw status 2>/dev/null | python3 -c 'import json,sys; print(json.load(sys.stdin).get("status",""))' || true)"

if [[ "$state" == "unauthenticated" || -z "$state" ]]; then
  echo "Log in with your Bitwarden email, master password, and 2FA if prompted."
  echo "This stays in your terminal. Do not paste it into Cursor."
  bw login
fi

echo "Unlocking the vault and writing a local session file for the agent..."
if ! bw unlock --raw >"$session_file"; then
  rm -f "$session_file"
  echo "Unlock failed." >&2
  exit 1
fi
chmod 600 "$session_file"

if ! BW_SESSION="$(cat "$session_file")" bw status 2>/dev/null | python3 -c 'import json,sys; raise SystemExit(0 if json.load(sys.stdin).get("status")=="unlocked" else 1)'; then
  echo "Vault is not unlocked." >&2
  exit 1
fi

echo "Done. Session saved. Reply in Cursor: logged in"
echo "After the import, you can run: rm -f \"$session_file\" && bw lock"
