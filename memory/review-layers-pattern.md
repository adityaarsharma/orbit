# Orbit — Review Layers Pattern (4 layers, mandatory for every audit)

> Every Orbit review runs all four layers. Each exists because something real got past the
> layer above it. Skipping one is not a shortcut, it is a known blind spot.

---

## Why layers, and in this order

Each layer catches a class the others **structurally cannot**. That word matters: it is not
about effort or care. A changeset-scoped review cannot find a pre-existing defect no matter how
carefully it is done, because the defect is not in the changeset.

| Layer | Catches | Cannot catch | Cost |
|---|---|---|---|
| 1. Lint | parse errors | anything that parses | seconds |
| 2. Static analysis | undeclared symbols, undefined constants, wrong arity | anything semantically wrong | seconds |
| 3. Runtime | races, caching, privacy, environment variance | anything the tests do not exercise | minutes |
| 4. Full read | semantics: code that does not do what its name says | nothing, but it is the slowest | hours |

---

## Layer 1 — Lint is not static analysis

`php -l` proves a file parses. It does not prove a symbol exists.

An undeclared static property and a missing class constant are **runtime** errors. Lint passes,
and on PHP 8 the first access is a fatal. A release can therefore be lint-clean and return HTTP
500 on its main code path.

**Rule:** never report `php -l` as the static-analysis step.

## Layer 2 — Static analysis, whole tree, filtered

Run PHPStan at level 2 or above over the entire plugin, not the diff. WordPress core functions
are out of scope, so most raw output is unresolvable-symbol noise; filter to the categories that
are real defects regardless of stubs:

```
undeclared static property | undefined static property |
Undefined constant | Undefined variable | undeclared property
```

Exclude classes that extend an absent third-party parent (page-builder widget base classes
produce hundreds of false "undefined method" lines). Non-zero in the filtered set is a blocker.

## Layer 3 — Runtime, and the two dimensions everyone forgets

Stand up real WordPress and drive it. Two dimensions are routinely missed:

**Concurrency.** Sequential tests pass on every race. Fire parallel requests at any read path
that writes, then assert `COUNT(*) == COUNT(DISTINCT key)`. Non-atomic meta writes with no
unique index duplicate rows under ordinary crawler traffic.

**Environment matrix.** Vary web server, PHP version, WordPress version, multisite **and
locale**. Locale is a first-class dimension for anything that produces language-sensitive
output, and a suite that only ever runs the default locale will not see it.

Also: never classify a surface as untestable because it needs a paid API key. Prompt
construction, request building and response parsing are all testable offline. The expensive
call is usually not where the defect is.

## Layer 4 — The full read, driven by a manifest

**Never scope a review to the diff.** Build a manifest of every shipped source file and require
each to be accounted for, so skipping one is a deliberate act rather than an accident.

For a plugin of a few tens of thousands of lines this is entirely achievable: split the manifest
into disjoint sets across parallel reviewers, never two reviewers on one file, and require each
to read its files completely rather than grep and stop.

The single highest-yield question, asked of every function:

> **Does the body actually do what the name and the docblock promise?**

Then:
- Is a weak proxy being treated as ground truth?
- Does a fallback produce wrong-but-plausible output instead of failing or omitting?
- Does a guard actually guard, or is its condition permanently false?
- Does a probe return `pass` without observing the thing it names?

Signatures for all of these are Category H in `knowledge/bug-signatures.md`.

**Wrong data that looks right is worse than an error**, because nothing alerts on it and a green
check stops anyone looking.

---

## Reporting discipline

Two rules, both learned by getting them wrong.

**Verify before relaying.** A reviewer's finding is a hypothesis until it is executed. Reading
plausible source and concluding a bug exists produces confident, wrong findings. Prove it with a
command whose output you paste, then report.

**Record retractions.** State findings that did not survive verification, and why. A report that
only lists hits gives no way to calibrate the ones that remain. Retractions are evidence the
process is working, not an embarrassment.

Common false-positive shapes worth checking before reporting:
- a third-party cache holding stale state, mistaken for the plugin's own staleness
- a core polyfill making an apparently version-unsafe function call safe
- a static analyser's always-false verdict on a condition that does render, checkable by
  rendering it
- comparing two versions at different analyser levels, where the rule only fires at one

## Gate integration

A review is complete when all four layers have run and the manifest is fully accounted for.
Layers 1 to 3 are automatable and belong in the release gate. Layer 4 is the one that needs a
reader, and it is the one that finds the defects users actually report.
