# Shared page skeleton - copy-paste convention

This is a static site with **no build step and no server-side includes**. Every page
copies the three blocks below verbatim and fills in the per-page placeholders.
This file is the single source of truth for that skeleton - if the nav or footer
changes, update it here first, then apply to all nine pages.

`_shared/` is a documentation folder only. Nothing in it is linked from the site,
and it is excluded from the sitemap.

## Link convention (decided Phase 1 - follow everywhere)

- **Internal page links are plain relative filenames**: `deep-plan.html`,
  `install.html`, `how-it-works.html`, `index.html`. All nine pages live flat in
  the publish root (`website/`), so plain filenames are unambiguous and work both
  locally via `file://` and deployed on Netlify. **Never** use root-relative
  (`/deep-plan.html`) or directory-style (`./deep-plan.html`) forms.
- **Asset paths are relative too**: `assets/site.css`, `assets/site.js`,
  `assets/og-image.png`, etc.
- **Canonical / OG URLs are absolute** on the apex host:
  `https://deep-skills.com/<page>.html` (homepage canonical is
  `https://deep-skills.com/`). No `www` in canonicals.

## Exclusions (repo-wide gate)

No page may reference **deep-goal, deep-learn, production-guide, or roadmap** in
any form (link, nav item, copy, meta, sitemap). Verify with:

```
grep -rEi "deep-goal|deep goal|deep-learn|production-guide|roadmap" website/
```

## Nine public pages

`index.html`, `how-it-works.html`, `deep-plan.html`, `deep-plan-review.html`,
`deep-implement.html`, `deep-code-review.html`, `deep-bugfix.html`,
`deep-docs.html`, `install.html`.

---

## 1. Canonical `<head>` block

Replace the `{{...}}` placeholders per page. Favicon/manifest/OG-image files land
in Phase 5 - keep the links in place from day one so pages don't need re-editing.

```html
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{{PAGE_TITLE}} - Deep Skills</title>
<meta name="description" content="{{PAGE_DESCRIPTION}}">
<link rel="canonical" href="https://deep-skills.com/{{PAGE}}.html">

<!-- Open Graph / Twitter -->
<meta property="og:type" content="website">
<meta property="og:site_name" content="Deep Skills">
<meta property="og:title" content="{{PAGE_TITLE}} - Deep Skills">
<meta property="og:description" content="{{PAGE_DESCRIPTION}}">
<meta property="og:url" content="https://deep-skills.com/{{PAGE}}.html">
<meta property="og:image" content="https://deep-skills.com/assets/og-image.png">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="{{PAGE_TITLE}} - Deep Skills">
<meta name="twitter:description" content="{{PAGE_DESCRIPTION}}">
<meta name="twitter:image" content="https://deep-skills.com/assets/og-image.png">

<!-- Favicons (files arrive in Phase 5) -->
<link rel="icon" href="assets/favicon.ico" sizes="any">
<link rel="icon" type="image/png" sizes="32x32" href="assets/favicon-32.png">
<link rel="icon" type="image/png" sizes="16x16" href="assets/favicon-16.png">
<link rel="apple-touch-icon" href="assets/apple-touch-icon.png">
<link rel="manifest" href="site.webmanifest">
<meta name="theme-color" content="#07080c">

<!-- Fonts: preconnect to BOTH origins; display=swap is required -->
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500;600&family=Space+Grotesk:wght@500;600;700&display=swap" rel="stylesheet">

<link rel="stylesheet" href="assets/site.css">
<script src="assets/site.js" defer></script>
```

Homepage exception: canonical and `og:url` are `https://deep-skills.com/`
(not `index.html`).

## 2. Canonical nav block (first thing inside `<body>`)

Identical on all nine pages. `site.js` sets `aria-current="page"` on the matching
link at runtime - do not hardcode it. The Install link is the primary CTA button.

```html
<a class="skip-link" href="#main">Skip to content</a>
<div id="progress" aria-hidden="true"></div>
<div class="glow a" aria-hidden="true"></div>
<div class="glow b" aria-hidden="true"></div>

<header class="site-nav">
  <div class="wrap nav-row">
    <a class="brand" href="index.html"><span class="brand-dot" aria-hidden="true"></span>Deep Skills</a>
    <button class="nav-toggle" aria-expanded="false" aria-controls="nav-menu" aria-label="Menu">
      <span></span><span></span><span></span>
    </button>
    <nav id="nav-menu" class="nav-menu" aria-label="Primary">
      <ul>
        <li><a href="index.html">Home</a></li>
        <li><a href="how-it-works.html">How it works</a></li>
        <li class="nav-dropdown">
          <button class="nav-dropbtn" aria-expanded="false" aria-controls="skills-menu">Skills</button>
          <ul id="skills-menu" class="dropdown">
            <li><a href="deep-plan.html">deep-plan</a></li>
            <li><a href="deep-plan-review.html">deep-plan-review</a></li>
            <li><a href="deep-implement.html">deep-implement</a></li>
            <li><a href="deep-code-review.html">deep-code-review</a></li>
            <li><a href="deep-bugfix.html">deep-bugfix</a></li>
            <li><a href="deep-docs.html">deep-docs</a></li>
          </ul>
        </li>
        <li><a class="btn btn-primary" href="install.html">Install</a></li>
      </ul>
    </nav>
  </div>
</header>
```

Page content goes in `<main id="main">…</main>` (the skip-link target).

## 3. Canonical footer block (last thing before `</body>`)

```html
<footer class="site-footer">
  <div class="wrap">
    <div class="footer-cta">
      <h2>Get started in one command</h2>
      <p>Install the Deep Skills plugin and run your first <code>/deep-plan</code>.</p>
      <!-- Install snippet: verbatim from README.md's Claude Code install block (D1 - slug as written) -->
      <div class="chip-stack">
        <code class="chip no-prompt">/plugin marketplace add reurgency/marketplace</code>
        <code class="chip no-prompt">/plugin install deep-skills@reurgency</code>
      </div>
      <div class="btn-row" style="margin-top:22px">
        <a class="btn btn-primary" href="install.html">Install Deep Skills</a>
      </div>
    </div>
    <div class="footer-meta">
      <span>&copy; 2026 Deep Skills &middot; MIT License</span>
      <div class="footer-links">
        <a href="how-it-works.html">How it works</a>
        <a href="install.html">Install</a>
        <a href="https://github.com/reurgency/Deep-Skills">GitHub</a>
      </div>
    </div>
  </div>
</footer>
```
