# Situational checks — catalog (sparse; read every run)

This is the **only** situational file loaded on every review. Each entry is the front matter for a check whose full body (`references/situational/<id>.md`) is read **only when its Match pattern hits the resolved diff**. Mechanism, matching discipline, and how to author a new entry: `references/situational-checks.md`.

Match patterns are grepped against the diff (chunk files under `--multi-agent`, the raw diff otherwise) by a small script — never an agent. Triggers err toward loading: a false match is cheap, a false miss loses the whole bug class.

---

### file-upload-pipeline
- **Loads when:** the diff touches file upload / ingestion / attachment handling, or routes an uploaded file into a parser or an AI vision/transcription call.
- **Match:** path or content matches `(?i)accept=|multipart|form-?data|multer|busboy|MAX_[A-Z_]*BYTES|TEXT_EXTENSIONS|validateFile|toVisionMimeType|encodeImageForRequest|pdf-?parse|pdfjs|readIntakeText|uploadedSpec|transcrib`
- **Attaches to:** `last-mile`, `seam-trace`
- **Catches:** advertised-but-unparsed formats (the `accept` list offers a type the read path silently drops or 500s on), single-unsupported-format submit → empty assembly → 500, vision/transcription payload shape vs the external harness, byte-cap packing/truncation that silently drops files.

<!-- Add new entries above this line, one per surface (payments, timezones, websockets,
     migrations, auth, caching, pagination, …). Keep each to ~5 lines — this file is read
     every run. Author the body at references/situational/<id>.md. -->
