# Situational check — file-upload pipeline

Fired because the diff touches file upload, ingestion, or routing an uploaded file into a parser or AI vision/transcription call. Upload pipelines fail the last mile in characteristic ways: the UI advertises a format the read path can't actually consume, an unsupported file's content vanishes silently or 500s at assembly, or an image is serialized to an AI harness in a shape that harness rejects. Trace the full chain and run every hunt below; this is one of the highest-value surfaces to escalate to a **live smoke** (see end).

## The chain to trace

```
file picker (accept=…) → client-side validateFile → upload/store on disk/blob
  → read path (extension/MIME allow-list → text extractor | vision/transcription)
  → assembly (uploaded text merged into the unified artifact)
  → downstream consumers (prompts, persistence, response)
```

Record evidence (path:line) at every hop, exactly like a last-mile chain. A gap anywhere is a finding.

## Hunts

- **Advertised format with no reader (silent drop or 500).** Diff the **advertised** allow-list (the `accept=` attribute + client `validateFile`) against the **read-path** allow-list (the extension/MIME set the extractor actually handles). Every format offered at upload must have a reader. The classic failure: `accept=".pdf,.md,.txt,.html"` but the text extractor's `TEXT_EXTENSIONS` excludes `.pdf` and no PDF parser exists on the read path → the uploaded PDF's content is **silently absent** from the assembled artifact (the user believes their doc was incorporated; it wasn't), and a **PDF-only** submit makes assembly throw → the intake route returns **500**. Enumerate every advertised type and confirm a reader exists for each.
- **Silent drop vs surfaced error.** When the reader returns `null`/empty for an unsupported file, what happens downstream? Silent omission (content vanishes, no signal) is worse than a hard error. At minimum the pipeline must surface "this file yielded no usable text" rather than dropping it. Flag readers that return empty on the unsupported path with no caller check.
- **Single-unsupported-format submit.** Can the user submit with *only* the unsupported file (does `canSubmit()`/validation allow it)? If so, the assembly step gets nothing and throws → 500 on the happy path, not an edge case.
- **Vision / transcription payload shape vs the external harness.** When an uploaded image routes to an AI harness (Codex, Ollama, Claude-code, a vision API), the serialized image block must match **that harness's** wire schema — and different harnesses need different shapes. This is an external contract: repo code and repo tests are not ground truth (see `references/dimensions.md` § `seam-trace`, external-consumer hunt, and `references/review-lenses.md` § Reading tests adversarially). **Compare the sibling clients field-by-field** — if the Ollama/Claude clients send `image_url: { url }` and the new Codex client sends bare `image_url: url`, the odd one out is the bug. The benchmark miss: `input.push({ type: 'image', image_url: url })` 500'd against Codex (which wanted `image_url: { url, detail }`), while a new contract test asserted the wrong flat shape and the suite passed green.
- **Byte-cap packing and truncation.** If uploads are packed under a size cap (total-bytes limit, max image count), check the packing order against its own comment (largest-first vs smallest-first divergence is common and the doc usually lies), and confirm that files dropped to fit under the cap are **reported**, not silently truncated.
- **MIME/extension trust.** Is the type derived from a trusted source (sniffed bytes / server-validated MIME) or from the client-supplied filename extension alone? Extension-only trust both misroutes (a `.png` that's really a PDF) and is a validation gap.

## Escalate to a live smoke

This surface rewards `--browser` (or a manual smoke) more than almost any other, because the two worst failures — the advertised-format drop/500 and the harness payload-shape rejection — reproduce in seconds and are invisible to a static green pre-pass. If a dev server is available, upload **one file of each advertised type** and confirm (a) its content reaches the assembled artifact and (b) no 500. If running under `--browser`, cite the observed request/status as `evidence.observed`.
