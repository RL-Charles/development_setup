#!/usr/bin/env python3
"""Upload gitignored .env files into a Bitwarden collection or folder.

Prints item names and env key names only. Never prints values.

You must log in once in your own terminal:

    ~/development/development_setup/scripts/bw-agent-login.sh

Then tell the agent "logged in". Do not paste BW_SESSION or env values into chat.
"""

from __future__ import annotations

import argparse
import base64
import json
import os
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


FIELD_HIDDEN = 1
ITEM_SECURE_NOTE = 2
SECURE_NOTE_GENERIC = 0
SESSION_FILE = Path.home() / ".config" / "bitwarden-agent" / "session"


def die(message: str, code: int = 1) -> None:
    print(message, file=sys.stderr)
    raise SystemExit(code)


def load_agent_session() -> None:
    """Use ~/.config/bitwarden-agent/session if BW_SESSION is unset. Never print it."""
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
        die(
            "bw is not on PATH. Install the Bitwarden CLI:\n"
            "  https://bitwarden.com/help/cli/#download-and-install\n"
            "Then in THIS terminal: bw login && export BW_SESSION=\"$(bw unlock --raw)\""
        )
    return path


def bw(*args: str, input_bytes: bytes | None = None) -> Any:
    env = os.environ.copy()
    result = subprocess.run(
        [bw_bin(), *args],
        input=input_bytes,
        capture_output=True,
        env=env,
    )
    if result.returncode != 0:
        err = result.stderr.decode("utf-8", errors="replace").strip()
        out = result.stdout.decode("utf-8", errors="replace").strip()
        # Errors are safe to show; stdout from create/get can contain secrets.
        die(f"bw {' '.join(args)} failed ({result.returncode}): {err or 'no stderr'}")
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
        die("bw status returned unexpected output. Is the CLI installed?")
    state = status.get("status")
    if state == "unauthenticated":
        die("bw is not logged in. In your terminal run: ~/development/development_setup/scripts/bw-agent-login.sh")
    if state != "unlocked":
        die(
            "bw vault is locked. In your terminal run:\n"
            "  ~/development/development_setup/scripts/bw-agent-login.sh"
        )
    return status


def parse_env_file(path: Path) -> list[tuple[str, str]]:
    if not path.is_file():
        die(f"env file not found: {path}")
    ordered: dict[str, str] = {}
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("export "):
            line = line[7:].strip()
        if "=" not in line:
            continue
        key, _, value = line.partition("=")
        key = key.strip()
        if not key or not key.replace("_", "").isalnum() or key[0].isdigit():
            continue
        value = value.strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in {'"', "'"}:
            value = value[1:-1]
        ordered[key] = value
    return list(ordered.items())


def summarize_item(obj: Any) -> dict[str, str]:
    if not isinstance(obj, dict):
        die("bw returned a non-object where an item was expected")
    item_id = obj.get("id")
    name = obj.get("name")
    if not item_id or not name:
        die("bw item JSON missing id or name")
    return {"id": str(item_id), "name": str(name)}


def list_named(kind: str) -> list[dict[str, str]]:
    rows = bw("list", kind)
    if not isinstance(rows, list):
        die(f"bw list {kind} returned unexpected output")
    named: list[dict[str, str]] = []
    for row in rows:
        if isinstance(row, dict) and row.get("name") and row.get("id"):
            named.append(
                {
                    "id": str(row["id"]),
                    "name": str(row["name"]),
                    "organizationId": str(row.get("organizationId") or ""),
                }
            )
    return named


def pick_by_name(kind: str, name: str) -> dict[str, str]:
    matches = [row for row in list_named(kind) if row["name"].casefold() == name.casefold()]
    if not matches:
        available = ", ".join(row["name"] for row in list_named(kind)) or "(none)"
        die(f"No {kind[:-1]} named {name!r}. Available: {available}")
    if len(matches) > 1:
        die(f"Multiple {kind} named {name!r}; rename so the name is unique.")
    return matches[0]


def item_name_for(path: Path, prefix: str) -> str:
    return f"{prefix}{path.name}" if prefix.endswith("/") or not prefix else f"{prefix}/{path.name}"


def find_existing(name: str, collection_id: str | None, folder_id: str | None) -> dict[str, str] | None:
    args = ["list", "items", "--search", name]
    if collection_id:
        args.extend(["--collectionid", collection_id])
    if folder_id:
        args.extend(["--folderid", folder_id])
    rows = bw(*args)
    if not isinstance(rows, list):
        return None
    for row in rows:
        if isinstance(row, dict) and row.get("name") == name and row.get("id"):
            return {"id": str(row["id"]), "name": str(row["name"])}
    return None


def build_item(
    *,
    name: str,
    path: Path,
    pairs: list[tuple[str, str]],
    organization_id: str | None,
    folder_id: str | None,
) -> dict[str, Any]:
    keys = [key for key, _ in pairs]
    notes = (
        f"Imported from {path.name} on {datetime.now(timezone.utc).strftime('%Y-%m-%d')} UTC.\n"
        f"Keys: {', '.join(keys)}"
    )
    item: dict[str, Any] = {
        "type": ITEM_SECURE_NOTE,
        "name": name,
        "notes": notes,
        "favorite": False,
        "reprompt": 0,
        "secureNote": {"type": SECURE_NOTE_GENERIC},
        "fields": [{"name": key, "value": value, "type": FIELD_HIDDEN} for key, value in pairs],
    }
    if organization_id:
        item["organizationId"] = organization_id
    if folder_id:
        item["folderId"] = folder_id
    return item


def assign_collection(item_id: str, organization_id: str, collection_id: str) -> None:
    encoded = encode([collection_id])
    bw(
        "edit",
        "item-collections",
        item_id,
        encoded,
        "--organizationid",
        organization_id,
    )


def upsert_item(
    *,
    name: str,
    path: Path,
    pairs: list[tuple[str, str]],
    collection: dict[str, str] | None,
    folder: dict[str, str] | None,
    dry_run: bool,
) -> str:
    collection_id = collection["id"] if collection else None
    folder_id = folder["id"] if folder else None
    organization_id = collection["organizationId"] if collection else None
    existing = find_existing(name, collection_id, folder_id)
    action = "update" if existing else "create"
    key_names = [key for key, _ in pairs]
    print(f"{action} {name} ({len(key_names)} keys: {', '.join(key_names)})")
    if dry_run:
        return action

    payload = build_item(
        name=name,
        path=path,
        pairs=pairs,
        organization_id=organization_id,
        folder_id=folder_id,
    )
    encoded = encode(payload)
    if existing:
        raw = bw("edit", "item", existing["id"], encoded)
        summary = summarize_item(raw)
    else:
        raw = bw("create", "item", encoded)
        summary = summarize_item(raw)
    if collection and organization_id:
        assign_collection(summary["id"], organization_id, collection["id"])
    return action


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Import .env files into a Bitwarden collection (or personal folder)."
    )
    parser.add_argument(
        "--collection",
        help="Exact organization collection name (from the Bitwarden web vault).",
    )
    parser.add_argument(
        "--folder",
        help="Exact personal-vault folder name (use this only if you did not create an org collection).",
    )
    parser.add_argument(
        "--file",
        action="append",
        dest="files",
        help="Path to a .env file. Repeat for each file. Each file becomes one Secure Note.",
    )
    parser.add_argument(
        "--item-prefix",
        default="tradiepro/",
        help="Prefix for item names. Default: tradiepro/",
    )
    parser.add_argument(
        "--list-collections",
        action="store_true",
        help="Print collection (and folder) names, then exit.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Parse files and print key names without writing to Bitwarden.",
    )
    parser.add_argument(
        "--no-sync",
        action="store_true",
        help="Skip bw sync at the start.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    if args.collection and args.folder:
        die("Use either --collection or --folder, not both.")
    require_unlocked()
    if not args.no_sync:
        bw("sync")

    if args.list_collections:
        collections = list_named("collections")
        folders = list_named("folders")
        print("Collections:")
        if collections:
            for row in collections:
                print(f"  {row['name']}")
        else:
            print("  (none)")
        print("Folders:")
        if folders:
            for row in folders:
                print(f"  {row['name']}")
        else:
            print("  (none)")
        return

    if not args.collection and not args.folder:
        die("Pass --collection 'Name' (or --folder 'Name'). Use --list-collections to see names.")
    if not args.files:
        die("Pass at least one --file /path/to/.env")

    collection = pick_by_name("collections", args.collection) if args.collection else None
    folder = pick_by_name("folders", args.folder) if args.folder else None
    if collection and not collection["organizationId"]:
        die("That collection has no organization id; pass --folder if this is a personal folder.")

    created = updated = 0
    for raw_path in args.files:
        path = Path(raw_path).expanduser().resolve()
        pairs = parse_env_file(path)
        if not pairs:
            print(f"skip {path.name} (no KEY=VALUE lines)")
            continue
        name = item_name_for(path, args.item_prefix)
        action = upsert_item(
            name=name,
            path=path,
            pairs=pairs,
            collection=collection,
            folder=folder,
            dry_run=args.dry_run,
        )
        if action == "create":
            created += 1
        else:
            updated += 1

    suffix = " (dry-run)" if args.dry_run else ""
    print(f"done{suffix}: {created} created, {updated} updated")


if __name__ == "__main__":
    main()
