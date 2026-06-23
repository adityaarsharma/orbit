# GPL & licensing reality for WordPress plugins (free + commercial)

Load this when the intake scan finds a license header, or when someone argues "it's GPL so we can copy it."

## The copying myth, killed

**GPL is a license with conditions, not a transfer of copyright.** When an author releases a plugin under
GPL, they keep the copyright; GPL grants *you* rights to use, study, modify, and redistribute **on the
condition** that you preserve their copyright notices and license, and license your distributed
derivative under GPL too.

What GPL lets you do freely:
- Reuse the **WordPress APIs, hooks, and ideas** — those aren't the author's to restrict.
- Read their code to **understand the approach** (the idea, the algorithm, the feature set).

What GPL does **not** let you do:
- Copy their PHP/JS/CSS **expression** into your plugin and ship it as yours.
- Strip their copyright headers and relicense their code under your name. That is **both** copyright
  infringement **and** a GPL violation.
- Paraphrase their code and call it original — structure/sequence/organization is still protected
  (derivative work).

## Free (WP.org) vs commercial / freemium — the license is the same, the risk differs

- **Free WP.org plugins** are GPL (or GPL-compatible). Studying ideas = fine. Copying expression = not.
- **Commercial / freemium "pro" plugins** are usually *also* GPL on the code, but distributed under a
  **vendor EULA** that adds terms (no redistribution of the paid package, license-key gating, support
  terms). The code license and the distribution contract are different things.

## 🛑 Hard stop: obfuscated / encrypted pro plugins

If the reference is ionCube-encoded, obfuscated, or otherwise technically protected and you are
**decompiling or deobfuscating** it:
- That likely breaches the vendor EULA, **and**
- It may violate the DMCA anti-circumvention rule (17 U.S.C. §1201) — a **separate** offense from
  copyright, with its own penalties.

**STOP and escalate to legal.** Do not proceed inside the clean-room skill.

## Copyleft variants to flag

- **GPL-2 / GPL-3** — standard for WP; derivative must stay GPL.
- **LGPL** — weaker copyleft; linking allowed, modifications to the lib stay LGPL.
- **AGPL / Affero** — adds a **network/SaaS clause**: if you run a modified version as a service, you must
  offer the source to users. Material if your plugin has a hosted component. Flag on intake.
- **MPL-2** — file-level copyleft; modified files stay MPL, can combine with other licenses.

## Bundling = redistribution

Bundling any third-party library, icon set, font, or image inside the shipped plugin **is
redistribution**. Most stock-asset licenses (Envato Elements, Shutterstock, Adobe Stock, and similar)
**forbid extractable redistribution** without an extended license. For bundled assets prefer:
own work · verified-CC0 · permissive (MIT/ISC/BSD icon sets, OFL fonts self-hosted). Ship a
`THIRD-PARTY-NOTICES` / `CREDITS` file listing every bundled library + its license, and retain MIT/BSD
notices and required attributions.

WP.org requires the plugin be **100% GPL-compatible** — verify no bundled dependency is proprietary or
otherwise GPL-incompatible before submitting.

> Engineering risk-reduction, NOT legal advice. Org-specific asset policy + escalation contact live in
> brain (`orbit/00-cto` hard-rules and `orbit/07-security` ip-cleanroom RUNBOOK).
