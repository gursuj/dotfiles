# Handoff — lift the IdeaPad's Firefox extension shortcuts into the repo

Status: **open, blocked on the IdeaPad side.** Nothing below needs re-discovery.

## Goal

The user set keyboard shortcuts for browser extensions on the IdeaPad. They do not come across on
their own (Firefox Sync syncs extensions, not their command bindings). Extract them on the
IdeaPad, put them in the repo, so `chezmoi apply` restores them.

## What is already known on the t14

- The t14 profile (`~/.config/mozilla/firefox/ay458jc3.default-release`) has nothing to migrate:
  `extensions.json` has no `shortcuts` key and `prefs.js` has no `commands.*` prefs.
- Format when they exist: one pref per binding in `prefs.js` —

  ```
  user_pref("commands.<extension-id>.<command-name>", "Ctrl+Shift+Y");
  ```

  id is the addon id (`uBlock0@raymondhill.net`, `{uuid}` for AMO-hosted ones); command name is the
  manifest name (`_execute_browser_action`, `_execute_sidebar_action`, or a custom one); the key
  uses Firefox syntax (`Ctrl+Shift+Y`, `Alt+P`, `F7`).
- The obvious one-liner failed for a reason worth remembering: it assumed the legacy root.
  Firefox 147+ keeps profiles in `~/.config/mozilla/firefox` (XDG, bug 259356).

## Do this on the IdeaPad

Search **both** roots and **every** profile (not just the default one):

```bash
python3 - <<'PY'
import configparser, pathlib, re

roots = [pathlib.Path.home()/".config/mozilla/firefox", pathlib.Path.home()/".mozilla/firefox"]
cands = []
for root in roots:
    ini = root/"profiles.ini"
    if ini.exists():
        cfg = configparser.ConfigParser(); cfg.read(ini)
        for s in cfg.sections():
            if s.startswith("Profile"):
                cands.append(root/cfg.get(s, "Path", fallback=""))
    cands += [p for p in root.glob("*") if (p/"prefs.js").exists()]

pat = re.compile(r'user_pref\("commands\.([^"]+)\.([^"]+)",\s*"([^"]*)"\)')
n = 0
for profile in dict.fromkeys(p for p in cands if p and (p/"prefs.js").exists()):
    for line in (profile/"prefs.js").read_text(errors="replace").splitlines():
        if m := pat.search(line):
            n += 1
            print(f"{profile.name}\t{m.group(1)}\t{m.group(2)}\t{m.group(3)}")
print(f"# {n} binding(s) found")
PY
```

Tab-separated: `profile / extension id / command / key`. `# 0 binding(s) found` means the shortcuts
are the extensions' defaults — nothing to migrate, close this. Cross-check in the browser:
`about:addons` → gear → **Manage Extension Shortcuts** (shows the effective key per command).

## Land it in the repo

Append to `.chezmoitemplates/firefox-preferences.js.tmpl` on `main`:

```js
/** EXTENSION SHORTCUTS ***/
// Set by hand on the IdeaPad and carried here: Sync syncs extensions, not their
// command bindings, which live in prefs.js as commands.<id>.<command>. user.js is
// applied at startup and wins over prefs.js, so these are fixed from here on --
// changing a shortcut means editing this block, not just about:addons.
user_pref("commands.<extension-id>.<command-name>", "<key>");
```

Render to check (`chezmoi execute-template < .chezmoitemplates/firefox-preferences.js.tmpl`),
commit, and note in the message that `t14` needs the same block merged.

## Definition of done

- The extracted lines are in `.chezmoitemplates/firefox-preferences.js.tmpl` on `main`, additive only.
- The rendered `~/.config/firefox-tweaks/user.js` contains them after `chezmoi apply`.
- `about:addons` → Manage Extension Shortcuts shows the same keys.
