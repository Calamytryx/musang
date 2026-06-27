#!/usr/bin/env python3
"""
Comprehensive app scanner that GETS EVERYTHING.
- Reads from ~/.local/share/desktop-directories/ only
- Uses exact .directory file names
- Matches ALL apps including waydroid, help, unknown categories
- Allows duplicates (apps in multiple groups)
- Falls back to kf5-unknown.directory for unmatched apps
"""
import os
import json
import configparser
from pathlib import Path
from collections import OrderedDict

# Desktop file lookup directories
desktop_dirs = [
    '/usr/share/applications',
    '/usr/local/share/applications',
    '/var/lib/flatpak/exports/share/applications',
    Path.home() / '.local/share/flatpak/exports/share/applications',
    Path.home() / '.local/share/applications',
]

# Parse .directory files from user local only
directories = OrderedDict()

dir_path = Path.home() / '.local/share/desktop-directories'
if dir_path.exists():
    for fn in sorted(dir_path.iterdir()):
        if fn.suffix != '.directory':
            continue

        category_id = fn.stem

        cp = configparser.RawConfigParser()
        try:
            cp.read(fn, encoding='utf-8')
        except Exception:
            continue

        if not cp.has_section('Desktop Entry'):
            continue

        e = cp['Desktop Entry']
        name = e.get('Name', '').strip()
        icon = e.get('Icon', '').strip()

        if name:
            directories[category_id] = {'name': name, 'icon': icon}

# Parse desktop files - GET EVERYTHING
desktop_cache = {}
for dir_path in desktop_dirs:
    if not os.path.isdir(dir_path):
        continue
    for fn in os.listdir(dir_path):
        if not fn.endswith('.desktop'):
            continue
        path = os.path.join(dir_path, fn)
        cp = configparser.RawConfigParser()
        try:
            cp.read(path, encoding='utf-8')
        except Exception:
            continue
        if not cp.has_section('Desktop Entry'):
            continue
        e = cp['Desktop Entry']
        if e.get('NoDisplay', '').lower() == 'true':
            continue
        if e.get('Hidden', '').lower() == 'true':
            continue
        if e.get('Type', '') != 'Application':
            continue
        name = e.get('Name', '').strip()
        exec_ = e.get('Exec', '').strip()
        cats = [c.strip() for c in e.get('Categories', '').split(';') if c.strip()]
        if name and exec_:
            desktop_cache[fn] = {
                'name': name,
                'exec': exec_,
                'categories': cats,
            }

# Comprehensive matching function
def get_matching_dirs(app_cats):
    """
    Returns list of .directory IDs that match this app.
    Very inclusive - catches most cases.
    """
    matches = []
    cats_lower = [c.lower() for c in app_cats]

    for cat_id in directories.keys():
        cat_id_lower = cat_id.lower()

        # EXACT CATEGORY MATCHES (most reliable)
        if 'development' in cat_id_lower:
            if any(c in cats_lower for c in ['development', 'ide', 'programming']):
                matches.append(cat_id)
                continue

        if 'education' in cat_id_lower:
            if any(c in cats_lower for c in ['education', 'science', 'math']):
                matches.append(cat_id)
                continue

        if cat_id_lower == 'kf5-games' or 'games' in cat_id_lower:
            if 'game' in cats_lower or any('game' in c.lower() for c in app_cats):
                matches.append(cat_id)
                continue

        if 'graphics' in cat_id_lower:
            if any(c in cats_lower for c in ['graphics', 'raster', 'vector', 'drawing']):
                matches.append(cat_id)
                continue

        if 'internet' in cat_id_lower:
            if any(c in cats_lower for c in ['network', 'email', 'webbrowser', 'chat', 'telephony', 'browser']):
                matches.append(cat_id)
                continue

        if 'multimedia' in cat_id_lower:
            if any(c in cats_lower for c in ['audio', 'video', 'audiovideo', 'music', 'audio', 'mixer']):
                matches.append(cat_id)
                continue

        if 'office' in cat_id_lower:
            if any(c in cats_lower for c in ['office', 'wordprocessor', 'spreadsheet', 'presentation']):
                matches.append(cat_id)
                continue

        if 'science' in cat_id_lower:
            if any(c in cats_lower for c in ['science', 'math', 'physics', 'engineering']):
                matches.append(cat_id)
                continue

        if 'system' in cat_id_lower:
            if any(c in cats_lower for c in ['system', 'settings', 'monitor', 'systemtools']):
                matches.append(cat_id)
                continue

        if 'utilities' in cat_id_lower:
            if any(c in cats_lower for c in ['utility', 'accessories', 'texteditor', 'terminal']):
                matches.append(cat_id)
                continue

        if 'help' in cat_id_lower:
            if any(c in cats_lower for c in ['help', 'documentation']):
                matches.append(cat_id)
                continue

        if 'waydroid' in cat_id_lower:
            if any('waydroid' in c.lower() or 'android' in c.lower() for c in app_cats):
                matches.append(cat_id)
                continue

        if 'webapps' in cat_id_lower:
            if any(c in cats_lower for c in ['webapps', 'web']):
                matches.append(cat_id)
                continue

        # Custom directory patterns
        if 'x-' in cat_id_lower or cat_id_lower not in ['kf5-development', 'kf5-education', 'kf5-games', 'kf5-graphics', 'kf5-internet', 'kf5-multimedia', 'kf5-office', 'kf5-science', 'kf5-system', 'kf5-utilities', 'kf5-help', 'kf5-unknown']:
            # Custom categories - try to match
            for cat in app_cats:
                if cat.lower() in cat_id_lower or cat_id_lower in cat.lower():
                    matches.append(cat_id)
                    break

    return matches

# Build result with ALL .directory files
result = []
all_placed_apps = set()

for cat_id, dir_info in directories.items():
    group_apps = []

    # Find apps that match this directory
    for fn, app_data in desktop_cache.items():
        matches = get_matching_dirs(app_data['categories'])

        # If this directory matches, add the app (duplicates allowed)
        if cat_id in matches:
            group_apps.append({
                'name': app_data['name'],
                'exec': app_data['exec']
            })
            all_placed_apps.add(fn)

    # Add group ONLY if it has apps
    if group_apps:
        result.append({
            'name': dir_info['name'],
            'expanded': False,
            'apps': group_apps,
            'subgroups': []
        })

# Add uncategorized apps to "kf5-unknown" (if it exists)
other_apps = []
for fn, app_data in desktop_cache.items():
    if fn not in all_placed_apps:
        other_apps.append({
            'name': app_data['name'],
            'exec': app_data['exec']
        })

if other_apps:
    # Check if kf5-unknown exists in directories
    if 'kf5-unknown' in directories:
        # Find and append to kf5-unknown
        unknown_found = False
        for group in result:
            if group['name'] == directories['kf5-unknown']['name']:
                group['apps'].extend(other_apps)
                unknown_found = True
                break
        if not unknown_found:
            # kf5-unknown wasn't in result yet, add it
            result.append({
                'name': directories['kf5-unknown']['name'],
                'expanded': False,
                'apps': other_apps,
                'subgroups': []
            })
    else:
        # No kf5-unknown, create "Other"
        result.append({
            'name': 'Other',
            'expanded': False,
            'apps': other_apps,
            'subgroups': []
        })

print(json.dumps(result))
