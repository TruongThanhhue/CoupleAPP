# Couple Design System — Codex Skill

A repo-local Agent Skill for designing and implementing the Couple App frontend in Flutter.

## What is included

```text
couple-design-system/
├── SKILL.md
├── AGENTS.md
├── README.md
├── references/
│   ├── nathan-curtis-eightshapes.md
│   ├── design-system-methodology.md
│   ├── design-tokens.md
│   ├── component-specification.md
│   └── ui-review-checklist.md
├── templates/
│   ├── component-spec.md
│   ├── screen-spec.md
│   └── ui-review.md
└── examples/
    └── component-spec-task-card.md
```

## Recommended placement in a Couple App repository

Place the skill here:

```text
<repo>/.codex/skills/couple-design-system/
```

Copy the included `AGENTS.md` to the repository root as:

```text
<repo>/AGENTS.md
```

Codex's current skill format uses a `SKILL.md` with YAML front matter plus optional
reference/template/script assets; repo-scoped skills can live under `.codex/skills/`.

## First prompt after installation

Use:

```text
Read AGENTS.md and use the couple-design-system skill.
Audit the existing Flutter frontend before changing any UI.
Do not implement yet. Produce:
1. the current UI architecture,
2. reusable components already present,
3. design inconsistencies,
4. missing tokens,
5. missing states,
6. the first design-system improvements you recommend.
```

## Second prompt

```text
Use the couple-design-system skill.
Design the Couple Home screen for the existing project.
First write a screen specification, then implement it in Flutter.
Reuse existing components and tokens. Do not invent arbitrary spacing or colors.
After implementation, run formatting, flutter analyze, and relevant tests.
Review the result using references/ui-review-checklist.md and fix issues you find.
```

## Important

The Nathan Curtis / EightShapes references in this skill are concise methodological
summaries. They are not a replacement for the original articles. The project's own
product requirements and design decisions remain authoritative.
