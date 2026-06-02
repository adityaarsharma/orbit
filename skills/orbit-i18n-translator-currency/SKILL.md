---
name: orbit-i18n-translator-currency
description: Translator .po file currency audit — for every shipped /languages/<plugin>-<locale>.po file, runs `msgmerge` against the current .pot and reports the percentage of msgids that are missing, fuzzy, or obsolete vs the current source code. Catches the silent-English-fallback bug where a translator delivered 100% translation against an OLD pot, but new strings shipped since. Use when the user says "translator currency", "stale po", "translation drift", "translator delivered translation", "ship translations", or before any release that has shipped .po/.mo files.
---

# 🪐 orbit-i18n-translator-currency — Per-locale translation currency

`orbit-i18n` checks the POT file is fresh vs the source code. This skill checks the .po files (one per locale) are fresh vs the POT. **POT can be 100% current AND translations can still be silently broken** — because the translator delivered against an older POT and new strings have shipped since.

**Why this skill exists:** RankReady received a 100% Turkish translation from Tolga, anchored to the v1.0.x POT. Between Tolga's delivery and ship, 30+ new strings were added to the codebase. The .po file was missing every new string — so the Turkish site silently fell back to English for ~30% of UI labels, with no warning. Plugin-agnostic — applies to any plugin shipping translated .po files.

---

## What this skill checks

### 1. Regenerate the canonical POT

```bash
wp i18n make-pot . languages/<plugin>.pot --slug=<plugin>
```

If this differs from the committed POT → the POT itself is stale. Fix that first (defer to `orbit-i18n` step 8).

### 2. For every shipped .po file, run `msgmerge --dry-run`

```bash
for po in languages/<plugin>-*.po; do
  locale=$(basename "$po" .po | sed "s/<plugin>-//")
  msgmerge --update --no-fuzzy-matching --backup=off --quiet "$po" "languages/<plugin>.pot" 2>&1 | tee "/tmp/merge-$locale.log"
  
  # Count states
  total=$(grep -c '^msgid "' "$po")
  fuzzy=$(grep -c '^#, fuzzy' "$po")
  obsolete=$(grep -c '^#~ msgid' "$po")
  untranslated=$(awk '/^msgid /{m=$0} /^msgstr ""$/&&m!=""{c++} {if(/^$/)m=""} END{print c+0}' "$po")
  
  echo "Locale: $locale"
  echo "  Total msgids:       $total"
  echo "  Untranslated:       $untranslated  ($(( untranslated * 100 / total ))%)"
  echo "  Fuzzy:              $fuzzy"
  echo "  Obsolete (removed): $obsolete"
done
```

### 3. Compute drift per locale

For each locale:
```
DRIFT % = (untranslated + fuzzy) / total * 100
```

Thresholds:
- **0–2% drift:** Pass (translator file is current)
- **2–10% drift:** Warning (notify translator pre-release)
- **10–25% drift:** Block release (significant silent-fallback)
- **>25% drift:** Block release (translator file is materially stale)

### 4. Cross-check `.mo` file freshness

The .mo (compiled binary) file is what WP loads at runtime. .po edits don't take effect until .mo is regenerated:

```bash
for po in languages/<plugin>-*.po; do
  mo="${po%.po}.mo"
  if [ ! -f "$mo" ] || [ "$po" -nt "$mo" ]; then
    echo "STALE .mo: $mo"
  fi
done
```

Any stale .mo → user runs the latest .po → still sees old translations. **High severity.**

### 5. Locale charset

Every .po `Content-Type:` header MUST declare `charset=UTF-8`. Anything else (Latin-1, Windows-1252) corrupts non-Latin glyphs at the .mo compile step.

```bash
for po in languages/<plugin>-*.po; do
  charset=$(grep -m1 '^"Content-Type:' "$po")
  if ! echo "$charset" | grep -q 'charset=UTF-8'; then
    echo "BAD CHARSET in $po: $charset"
  fi
done
```

### 6. Plural-Forms header per locale

Every .po MUST have a correct `Plural-Forms:` header matching the locale's plural rules. Missing or wrong → `_n()` plurals silently fall back to the singular for non-singular counts.

Reference: https://www.gnu.org/software/gettext/manual/html_node/Plural-forms.html

### 7. Translator file ownership / contact

For each locale, the .po headers should record:
- `Last-Translator:` (with current contact, not just "FULL NAME")
- `Language-Team:` (or community link)
- `PO-Revision-Date:` (within last 12 months for active locales)

This is the operational layer — without contact info, drift can't be repaired.

### 8. Compare locale list against what the plugin advertises

Some plugins list "supported languages" in readme.txt. If the .po list disagrees with the readme list → either ship the missing .po or update the readme. Both are misleading.

---

## Report format

```markdown
# Translator Currency Audit — [Plugin] v[Version]

## POT freshness
POT vs source: [PASS / STALE — regenerate first]

## Per-locale status

| Locale | Total | Done | Untrans | Fuzzy | Obsolete | Drift % | .mo current | Status |
|--------|-------|------|---------|-------|----------|---------|-------------|--------|
| tr_TR  | 412   | 287  | 110     | 15    | 7        | 30.3%   | ❌ stale     | BLOCK  |
| de_DE  | 412   | 408  | 2       | 2     | 0        | 1.0%    | ✅           | PASS   |
| es_ES  | 412   | 380  | 28      | 4     | 0        | 7.8%    | ✅           | WARN   |

## Charset issues
[Locales where Content-Type != charset=UTF-8]

## Plural-Forms issues
[Locales missing or incorrect Plural-Forms header]

## Translator contact freshness
[Locales with PO-Revision-Date > 12 months OR missing Last-Translator]

## Action items
- BLOCK: tr_TR — re-sync POT, notify Tolga (110 new strings since last delivery)
- WARN: es_ES — notify Spanish translator (28 strings drift)
- All: regenerate .mo via `wp i18n make-mo languages/`
```

---

## Auto-fix path

```bash
# 1. Refresh POT
wp i18n make-pot . languages/<plugin>.pot --slug=<plugin>

# 2. Merge POT into each .po (preserves existing translations, adds new msgids as untranslated)
for po in languages/<plugin>-*.po; do
  msgmerge --update --backup=off --previous "$po" languages/<plugin>.pot
done

# 3. Recompile all .mo
wp i18n make-mo languages/

# 4. Commit updated .po/.mo files. THEN notify translators of drift % per locale.
```

---

## Plugin-agnostic

This skill scans the `/languages` directory for any plugin slug. No plugin name hardcoded. Reads slug from plugin header `Text Domain:` field.

---

## Cross-references

- **`orbit-i18n`** — POT freshness vs source code (step 8). Run before this.
- **`orbit-i18n-runtime`** — JSON encoding flags (different bug class).
- **WP.org Plugin Check** — does not currently audit .po currency. This skill fills that gap.

---

## Severity

- Drift > 25% on any active locale:        **Critical** (translator handoff broken)
- Drift 10–25% on any active locale:       **High**    (block release)
- Stale .mo (newer .po exists):            **High**    (runtime can't see edits)
- Wrong / missing charset header:          **High**    (compile-time glyph corruption)
- Wrong / missing Plural-Forms header:     **Medium**  (singular fallback for counts > 1)
- Drift 2–10%:                              **Medium**  (warn translator pre-release)
- PO-Revision-Date > 12 months:            **Low**    (operational, not a code bug)
- readme.txt language list disagrees:      **Low**    (docs drift)
