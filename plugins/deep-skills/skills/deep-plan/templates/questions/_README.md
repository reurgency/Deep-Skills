# Question format templates

Editable JSON schemas for the question types `/deep-plan` asks during a session. The skill reads a template, fills it, and renders it via the host's structured-question tool (see `references/host-affordances.md`). Tweak these or clone one to add a new type.

These specs are host-neutral: they render via the host's structured-question tool where available, else as a numbered chat list (see `references/host-affordances.md`).

## Shipped types

| File | `questionType` | Use for |
|---|---|---|
| `multiple-choice.json` | `multiple-choice` | Pick one (or several) from defined options. Maps to structured-question options. |
| `yes-no-explain.json` | `yes-no-explain` | A boolean decision plus required reasoning. |
| `open-ended.json` | `open-ended` | Free-form text answer. |

## Field reference

Common fields (modeled on `apps/shared/types/blueprint-qa.types.ts` → `BlueprintQuestion`):

- `questionType` *(string)* — the type id; matches the filename.
- `question` *(string)* — the prompt shown to the user.
- `context` *(string, optional)* — brief rationale for why this is being asked.
- `header` *(string, optional)* — short chip label (≤12 chars) for the structured-question tool.

Type-specific fields are documented inside each file via an `_comment`.

## Adding a new type

1. Copy an existing file to `<your-type>.json`.
2. Set `questionType` to your type id and adjust the fields.
3. Add an `_comment` describing the type-specific fields and how to render it.
4. Add a row to the table above.

`_comment` / `_*` keys are documentation only — strip them before rendering.
