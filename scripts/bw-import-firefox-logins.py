#!/usr/bin/env python3
"""Import Firefox saved logins into a Bitwarden personal-vault folder.

Prints site + username only. Never prints passwords or BW_SESSION.

You must unlock once in your own terminal:

    ~/development/development_setup/scripts/bw-agent-login.sh

Then tell the agent "logged in". Do not paste the session or passwords into chat.
"""

from __future__ import annotations

import argparse
import base64
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any
from urllib.parse import urlparse


ITEM_LOGIN = 1
SESSION_FILE = Path.home() / ".config" / "bitwarden-agent" / "session"
DEFAULT_PROFILE = Path(
    "/mnt/c/Users/charl/AppData/Roaming/Mozilla/Firefox/Profiles/7yhy4w9k.default-release"
)
DECRYPT_SCRIPT = Path("/tmp/firefox_decrypt/firefox_decrypt.py")


def die(message: str, code: int = 1) -> None:
    print(message, file=sys.stderr)
    raise SystemExit(code)


def load_agent_session() -> None:
    if os.environ.get("BW_SESSION"):
        return
    if not SESSION_FILE.is_file():
        return
    token = SESSION_FILE.read_text(encoding="utf-8").strip()
    if token:
        os.environ["BW_SESSION"] = token


def bw_bin() -> str:
    path = shutil.which("bw")
    if not path:
        die("bw is not on PATH. Expected ~/.local/bin/bw")
    return path


def bw(*args: str, input_bytes: bytes | None = None) -> Any:
    result = subprocess.run(
        [bw_bin(), *args],
        input=input_bytes,
        capture_output=True,
        env=os.environ.copy(),
    )
    if result.returncode != 0:
        err = result.stderr.decode("utf-8", errors="replace").strip()
        safe_args = [arg if len(arg) < 80 else "[redacted]" for arg in args]
        die(f"bw {' '.join(safe_args)} failed ({result.returncode}): {err or 'no stderr'}")
    text = result.stdout.decode("utf-8", errors="replace").strip()
    if not text:
        return None
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        return text


def encode(payload: Any) -> str:
    raw = json.dumps(payload, separators=(",", ":")).encode("utf-8")
    encoded = bw("encode", input_bytes=raw)
    if isinstance(encoded, str) and encoded:
        return encoded
    return base64.b64encode(raw).decode("ascii")


def require_unlocked() -> dict[str, Any]:
    load_agent_session()
    status = bw("status")
    if not isinstance(status, dict):
        die("bw status returned unexpected output.")
    state = status.get("status")
    if state == "unauthenticated" or state != "unlocked":
        die(
            "bw vault is locked. In your terminal run:\n"
            "  ~/development/development_setup/scripts/bw-agent-login.sh\n"
            "Then reply in Cursor: logged in"
        )
    return status


def item_name(url: str, username: str) -> str:
    host = urlparse(url).hostname or url
    if username:
        return f"{host} ({username})"
    return host


def decrypt_firefox(profile: Path) -> list[dict[str, str]]:
    if not DECRYPT_SCRIPT.is_file():
        DECRYPT_SCRIPT.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run(
            [
                "curl",
                "-fsSL",
                "-o",
                str(DECRYPT_SCRIPT),
                "https://raw.githubusercontent.com/unode/firefox_decrypt/main/firefox_decrypt.py",
            ],
            check=True,
        )
    if not profile.is_dir():
        die(f"Firefox profile not found: {profile}")

    work = Path(tempfile.mkdtemp(prefix="ff-logins."))
    os.chmod(work, 0o700)
    for name in ("logins.json", "key4.db", "cert9.db"):
        src = profile / name
        if not src.is_file():
            die(f"Missing {name} in Firefox profile")
        shutil.copy2(src, work / name)

    out = work / "export.json"
    err = work / "err.log"
    with out.open("wb") as stdout, err.open("wb") as stderr:
        result = subprocess.run(
            [sys.executable, str(DECRYPT_SCRIPT), "-n", "-f", "json", str(work)],
            stdout=stdout,
            stderr=stderr,
        )
    if result.returncode != 0:
        hint = err.read_text(encoding="utf-8", errors="replace")[:400]
        shutil.rmtree(work, ignore_errors=True)
        die(
            "Could not decrypt Firefox logins (primary password may be set).\n"
            f"Decrypt tool said: {hint}"
        )
    data = json.loads(out.read_text(encoding="utf-8"))
    shutil.rmtree(work, ignore_errors=True)
    if not isinstance(data, list):
        die("firefox_decrypt returned unexpected JSON")
    cleaned: list[dict[str, str]] = []
    for row in data:
        if not isinstance(row, dict):
            continue
        url = str(row.get("url") or "").strip()
        if not url:
            continue
        cleaned.append(
            {
                "url": url,
                "username": str(row.get("user") or ""),
                "password": str(row.get("password") or ""),
            }
        )
    return cleaned


def list_folders() -> list[dict[str, str]]:
    rows = bw("list", "folders")
    if not isinstance(rows, list):
        die("bw list folders returned unexpected output")
    named: list[dict[str, str]] = []
    for row in rows:
        if isinstance(row, dict) and row.get("name") and row.get("id"):
            named.append({"id": str(row["id"]), "name": str(row["name"])})
    return named


def ensure_folder(name: str, dry_run: bool) -> dict[str, str] | None:
    for row in list_folders():
        if row["name"].casefold() == name.casefold():
            print(f"using existing folder {row['name']}")
            return row
    print(f"create folder {name}")
    if dry_run:
        return None
    raw = bw("create", "folder", encode({"name": name}))
    if not isinstance(raw, dict) or not raw.get("id"):
        die("bw create folder failed")
    return {"id": str(raw["id"]), "name": str(raw.get("name") or name)}


def existing_login_names(folder_id: str | None) -> set[str]:
    args = ["list", "items"]
    if folder_id:
        args.extend(["--folderid", folder_id])
    rows = bw(*args)
    names: set[str] = set()
    if isinstance(rows, list):
        for row in rows:
            if isinstance(row, dict) and row.get("name") and row.get("type") == ITEM_LOGIN:
                names.add(str(row["name"]))
    return names


def build_login(row: dict[str, str], folder_id: str | None) -> dict[str, Any]:
    item: dict[str, Any] = {
        "type": ITEM_LOGIN,
        "name": item_name(row["url"], row["username"]),
        "favorite": False,
        "reprompt": 0,
        "notes": "Imported from Windows Firefox profile",
        "login": {
            "uris": [{"match": None, "uri": row["url"]}],
            "username": row["username"],
            "password": row["password"],
            "totp": None,
        },
    }
    if folder_id:
        item["folderId"] = folder_id
    return item


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Import Firefox logins into a Bitwarden personal folder."
    )
    parser.add_argument("--folder", default="Firefox", help="Personal vault folder name.")
    parser.add_argument(
        "--profile",
        default=str(DEFAULT_PROFILE),
        help="Firefox profile directory.",
    )
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--no-sync", action="store_true")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    require_unlocked()
    if not args.no_sync:
        bw("sync")

    rows = decrypt_firefox(Path(args.profile))
    print(f"decrypted {len(rows)} Firefox logins")
    folder = ensure_folder(args.folder, args.dry_run)
    folder_id = folder["id"] if folder else None
    existing = existing_login_names(folder_id) if folder_id else set()

    created = skipped = 0
    for row in rows:
        name = item_name(row["url"], row["username"])
        if name in existing:
            print(f"skip {name} (already in folder)")
            skipped += 1
            continue
        print(f"create {name}")
        if not args.dry_run:
            bw("create", "item", encode(build_login(row, folder_id)))
        created += 1
        existing.add(name)

    suffix = " (dry-run)" if args.dry_run else ""
    print(f"done{suffix}: {created} created, {skipped} skipped")


if __name__ == "__main__":
    main()
