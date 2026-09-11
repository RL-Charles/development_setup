# Firefox on a new machine

This folder is bookmarks and portable link state from Windows Firefox
(`7yhy4w9k.default-release`). It is not a full profile copy.

Passwords are in Bitwarden, personal folder **Firefox** (44 logins).
They are not in this repo.

## Restore on Linux / Omarchy

```bash
git clone https://github.com/RL-Charles/development_setup.git
# or: git pull, if you already have the repo
```

1. Install Firefox and Bitwarden (app or browser extension).
2. Sign into Bitwarden. Open the **Firefox** folder for site passwords.
3. In Firefox: Bookmarks → Manage bookmarks → Import and Backup →
   Import Bookmarks from HTML → pick `firefox/bookmarks.html`.
4. Optional: use `firefox/bookmarks.md` as a readable list.

You will still need to sign into sites. Cookies and sessions were not copied.

## Files

| Path | What it is |
| --- | --- |
| `bookmarks.html` | Import this into Firefox |
| `bookmarks.md` / `bookmarks.json` | Same list, readable |
| `bookmarkbackups/` | Native Firefox jsonlz4 backup |
| `pinned-and-open-tabs.md` | Last live-session tabs (usually thin) |
| `last-full-session.md` | Previous session snapshot |
| `containers.json` | Cookie containers |
| `search-engines.json` | Search engines (names only) |
| `extensions.json` | Add-on names (built-in only on the source profile) |
| `handlers.json` / `xulstore.json` | Protocol handlers / window chrome |

Re-export from Windows (needs `pip install lz4`):

```bash
python scripts/export-firefox-bookmarks.py
```
