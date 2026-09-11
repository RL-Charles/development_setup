#!/usr/bin/env python3
"""Export Firefox bookmarks and portable link state (no passwords or cookies)."""

from __future__ import annotations

import datetime
import html
import json
import os
import re
import shutil
import sqlite3
import tempfile
from pathlib import Path

import lz4.block

PROFILE = Path(
    os.environ.get(
        "FIREFOX_PROFILE",
        r"C:\Users\charl\AppData\Roaming\Mozilla\Firefox\Profiles\7yhy4w9k.default-release",
    )
)
OUT = Path(
    os.environ.get(
        "FIREFOX_EXPORT_DIR",
        str(Path(__file__).resolve().parents[1] / "firefox"),
    )
)

ROOT_LABELS = {
    2: "Bookmarks Menu",
    3: "Bookmarks Toolbar",
    5: "Other Bookmarks",
    6: "Mobile Bookmarks",
}

TOKEN_RE = re.compile(
    r"(access_token|id_token|refresh_token|token|session|auth|jwt|password|code|key|state)=([^&#]*)",
    re.I,
)


def moz_time(us: int | None) -> str:
    if not us:
        return ""
    try:
        return datetime.datetime.fromtimestamp(
            us / 1_000_000, tz=datetime.timezone.utc
        ).strftime("%Y-%m-%d")
    except Exception:
        return ""


def decompress_mozlz4(path: Path) -> bytes:
    data = path.read_bytes()
    if data[:8] != b"mozLz40\0":
        raise ValueError(f"not mozlz4: {path}")
    return lz4.block.decompress(data[8:])


def scrub(url: str) -> str:
    return TOKEN_RE.sub(lambda m: f"{m.group(1)}=<redacted>", url or "")


def html_escape(s: str) -> str:
    return html.escape(s or "", quote=True)


def walk(by_parent: dict, parent_id: int, folder_path: list[str]) -> list[dict]:
    items: list[dict] = []
    for n in by_parent.get(parent_id, []):
        if n["type"] == 2:
            title = n["title"] or ROOT_LABELS.get(n["id"], "Untitled")
            children = walk(by_parent, n["id"], folder_path + [title])
            items.append(
                {
                    "type": "folder",
                    "title": title,
                    "dateAdded": moz_time(n["dateAdded"]),
                    "children": children,
                }
            )
        elif n["type"] == 1 and n["url"]:
            items.append(
                {
                    "type": "bookmark",
                    "title": n["title"] or n["url"],
                    "url": scrub(n["url"]),
                    "dateAdded": moz_time(n["dateAdded"]),
                    "folder": " / ".join(folder_path) if folder_path else "",
                }
            )
    return items


def flatten(items: list[dict], acc: list[dict] | None = None) -> list[dict]:
    if acc is None:
        acc = []
    for it in items:
        if it["type"] == "bookmark":
            acc.append(it)
        else:
            flatten(it.get("children") or [], acc)
    return acc


def write_html_items(items: list[dict], lines: list[str], indent: int = 1) -> None:
    pad = "    " * indent
    for it in items:
        if it["type"] == "folder":
            lines.append(f"{pad}<DT><H3>{html_escape(it['title'])}</H3>")
            lines.append(f"{pad}<DL><p>")
            write_html_items(it.get("children") or [], lines, indent + 1)
            lines.append(f"{pad}</DL><p>")
        else:
            lines.append(
                f'{pad}<DT><A HREF="{html_escape(it["url"])}">{html_escape(it["title"])}</A>'
            )


def write_md(items: list[dict], md: list[str], depth: int = 0) -> None:
    last_was_bookmark = False
    for it in items:
        if it["type"] == "folder":
            if last_was_bookmark:
                md.append("")
            if not it.get("children"):
                continue
            md.append(f"{'#' * min(depth + 2, 6)} {it['title']}")
            md.append("")
            write_md(it["children"], md, depth + 1)
            last_was_bookmark = False
        else:
            date = f" — {it['dateAdded']}" if it.get("dateAdded") else ""
            md.append(f"- [{it['title']}]({it['url']}){date}")
            last_was_bookmark = True
    if last_was_bookmark:
        md.append("")


def export_places() -> tuple[list[dict], dict]:
    td = Path(tempfile.mkdtemp())
    for name in ["places.sqlite", "places.sqlite-wal", "places.sqlite-shm"]:
        src = PROFILE / name
        if src.exists():
            shutil.copy2(src, td / name)
    conn = sqlite3.connect(td / "places.sqlite")
    conn.row_factory = sqlite3.Row
    rows = conn.execute(
        """
        SELECT b.id, b.parent, b.type, b.title, b.dateAdded, b.lastModified, b.position, p.url
        FROM moz_bookmarks b
        LEFT JOIN moz_places p ON b.fk = p.id
        ORDER BY b.parent, b.position, b.id
        """
    ).fetchall()
    conn.close()

    by_parent: dict[int, list[dict]] = {}
    for r in rows:
        d = dict(r)
        by_parent.setdefault(d["parent"], []).append(d)

    tree: list[dict] = []
    for n in by_parent.get(1, []):
        if n["id"] == 4:
            continue
        title = ROOT_LABELS.get(n["id"], n["title"] or "Untitled")
        tree.append(
            {
                "type": "folder",
                "title": title,
                "dateAdded": moz_time(n["dateAdded"]),
                "children": walk(by_parent, n["id"], [title]),
            }
        )
    return flatten(tree), {
        "exportedFrom": f"Windows Firefox profile {PROFILE.name}",
        "exportedAt": datetime.datetime.now(datetime.timezone.utc).strftime(
            "%Y-%m-%dT%H:%M:%SZ"
        ),
        "bookmarkCount": 0,
        "tree": tree,
    }


def parse_session_file(session_path: Path) -> tuple[list[dict], list[dict]]:
    sess = json.loads(decompress_mozlz4(session_path))
    pinned: list[dict] = []
    open_tabs: list[dict] = []
    for wi, win in enumerate(sess.get("windows") or [], 1):
        for tab in win.get("tabs") or []:
            entries = tab.get("entries") or []
            idx = tab.get("index", len(entries)) - 1
            entry = (
                entries[idx]
                if 0 <= idx < len(entries)
                else (entries[-1] if entries else {})
            )
            rec = {
                "window": wi,
                "title": entry.get("title") or entry.get("url") or "",
                "url": scrub(entry.get("url") or ""),
                "pinned": bool(tab.get("pinned")),
            }
            (pinned if rec["pinned"] else open_tabs).append(rec)
    return pinned, open_tabs


def write_tabs_markdown(
    path: Path, heading: str, note: str, pinned: list[dict], open_tabs: list[dict]
) -> None:
    lines = [f"# {heading}", "", note, "", f"## Pinned ({len(pinned)})", ""]
    if pinned:
        for t in pinned:
            lines.append(f"- [{t['title']}]({t['url']})")
    else:
        lines.append("_None in this snapshot._")
    lines += ["", f"## Open tabs ({len(open_tabs)})", ""]
    for t in open_tabs:
        lines.append(f"- [{t['title']}]({t['url']})")
    lines.append("")
    path.write_text("\n".join(lines), encoding="utf-8")
    path.with_suffix(".json").write_text(
        json.dumps({"pinned": pinned, "open": open_tabs}, indent=2), encoding="utf-8"
    )


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "bookmarkbackups").mkdir(exist_ok=True)

    flat, payload = export_places()
    payload["bookmarkCount"] = len(flat)
    (OUT / "bookmarks.json").write_text(
        json.dumps(payload, indent=2), encoding="utf-8"
    )

    html_lines = [
        "<!DOCTYPE NETSCAPE-Bookmark-file-1>",
        "<!-- This is an automatically generated file. -->",
        '<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">',
        "<TITLE>Bookmarks</TITLE>",
        "<H1>Bookmarks</H1>",
        "<DL><p>",
    ]
    write_html_items(payload["tree"], html_lines)
    html_lines.append("</DL><p>")
    (OUT / "bookmarks.html").write_text("\n".join(html_lines) + "\n", encoding="utf-8")

    md = [
        "# Firefox bookmarks",
        "",
        f"Exported {payload['exportedAt']} from `{PROFILE.name}`.",
        "",
        f"**{len(flat)} bookmarks.** Restore with `bookmarks.html` via Bookmarks → Manage bookmarks → Import and Backup → Import Bookmarks from HTML.",
        "",
    ]
    write_md(payload["tree"], md)
    (OUT / "bookmarks.md").write_text("\n".join(md).rstrip() + "\n", encoding="utf-8")

    backups = sorted((PROFILE / "bookmarkbackups").glob("bookmarks-*.jsonlz4"))
    if backups:
        latest = backups[-1]
        shutil.copy2(latest, OUT / "bookmarkbackups" / latest.name)
        (OUT / "bookmarkbackups" / "LATEST.txt").write_text(
            latest.name + "\n", encoding="utf-8"
        )

    recovery = PROFILE / "sessionstore-backups" / "recovery.jsonlz4"
    previous = PROFILE / "sessionstore-backups" / "previous.jsonlz4"
    if recovery.exists():
        pinned, open_tabs = parse_session_file(recovery)
        write_tabs_markdown(
            OUT / "pinned-and-open-tabs.md",
            "Firefox pinned and open tabs",
            "Live Windows session snapshot. Login tokens in URLs were redacted.",
            pinned,
            open_tabs,
        )
    else:
        pinned, open_tabs = [], []
    if previous.exists():
        prev_pinned, prev_open = parse_session_file(previous)
        write_tabs_markdown(
            OUT / "last-full-session.md",
            "Firefox last full session",
            "Previous Windows session (`previous.jsonlz4`). Login tokens in URLs were redacted.",
            prev_pinned,
            prev_open,
        )

    for name in ["containers.json", "handlers.json", "xulstore.json"]:
        src = PROFILE / name
        if src.exists():
            shutil.copy2(src, OUT / name)

    search = PROFILE / "search.json.mozlz4"
    if search.exists():
        raw = json.loads(decompress_mozlz4(search))
        engines = [
            {
                "name": e.get("_name") or e.get("name"),
                "id": e.get("id"),
                "isAppProvided": e.get("_isAppProvided"),
            }
            for e in (raw.get("engines") or [])
        ]
        (OUT / "search-engines.json").write_text(
            json.dumps(engines, indent=2), encoding="utf-8"
        )

    ext_path = PROFILE / "extensions.json"
    if ext_path.exists():
        ext = json.loads(ext_path.read_text(encoding="utf-8"))
        addons = []
        for a in ext.get("addons") or []:
            loc = a.get("defaultLocale") or {}
            addons.append(
                {
                    "name": loc.get("name") or a.get("id"),
                    "id": a.get("id"),
                    "type": a.get("type"),
                    "active": a.get("active"),
                    "location": a.get("location"),
                }
            )
        (OUT / "extensions.json").write_text(
            json.dumps(addons, indent=2), encoding="utf-8"
        )

    print(f"exported {len(flat)} bookmarks, {len(pinned)} pinned, {len(open_tabs)} open tabs -> {OUT}")


if __name__ == "__main__":
    main()
