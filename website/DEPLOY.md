# Deploy runbook - deep-skills.com

How to take this site live on Netlify at `deep-skills.com`, with DNS on Cloudflare.

> **Who runs this:** a human with access to the Netlify account and the Cloudflare zone for
> `deep-skills.com`. Nothing in this repo performs the deploy or touches DNS - the repo only
> ships the static files (`website/`), `netlify.toml`, and `website/_redirects`.

**What Netlify picks up automatically from the repo:**

- `netlify.toml` (repo root): `publish = "website"`, no build command, and the security
  headers (CSP, `X-Frame-Options`, etc.).
- `website/_redirects`: vanity short paths (`/plan` → `/deep-plan.html`, etc.). No custom
  404 yet - Netlify's default 404 page serves for unmatched URLs (deferred; see plan D3).

---

## Part 1 - Netlify: connect the repo and deploy

1. In Netlify: **Add new site → Import an existing project → GitHub** and pick
   **`reurgency/Deep-Skills`**.
2. Configure the deploy settings (Netlify may pre-fill these from `netlify.toml` - verify
   they match):
   - **Branch to deploy:** `main`. That is the production branch once the site branch is
     merged. Until then, Deploy Previews built from the open PR let you verify everything
     below on a preview URL.
   - **Build command:** *empty* (leave blank - this is a static site, there is no build).
   - **Publish directory:** `website`
3. Click **Deploy**. The first deploy takes under a minute (no build).
4. Note the generated site URL, e.g. `https://<site>.netlify.app`.
5. **Verify the site on the `netlify.app` URL FIRST - before touching domains or DNS:**
   - Homepage renders; nav works; all six skill pages, `install.html`, and
     `how-it-works.html` load.
   - `https://<site>.netlify.app/sitemap.xml` and `/robots.txt` are reachable.
   - A vanity redirect works: `https://<site>.netlify.app/plan` → `/deep-plan.html` (301).
   - Response headers include the CSP (browser devtools → Network → any page →
     `content-security-policy`), and Google Fonts still load (no CSP errors in the console).

   Do not proceed to Part 2 until this checks out. Debugging site problems is much easier
   before DNS is in the mix.

## Part 2 - Netlify: add the custom domains

1. In the site's **Domain management** panel: **Add a domain** → `deep-skills.com`.
2. Add `www.deep-skills.com` as a domain alias (Netlify usually offers this automatically).
3. Set `deep-skills.com` (apex) as the **primary domain**. Netlify will then 301-redirect
   `www` → apex, matching the site's canonical URLs (which use the apex, no `www`).
4. Netlify's Domain settings panel now shows the **exact DNS records it wants**. Keep this
   panel open - Part 3 copies those values verbatim.
5. TLS: under **HTTPS**, Netlify provisions a Let's Encrypt certificate automatically once
   DNS resolves (Part 3). No action needed here yet - just know the cert appears in this
   panel when it's issued.

## Part 3 - Cloudflare: DNS records

> ### ⚠️ Critical TLS gotcha - read before creating any record
>
> Create both records as **DNS only (grey cloud)**. Do **not** enable the Cloudflare proxy
> (orange cloud) until Netlify shows the certificate as issued. Proxying intercepts
> Netlify's HTTP-01 certificate challenge, so the cert never provisions and you get SSL
> errors and/or redirect loops. Grey cloud first, always.

1. In Cloudflare, open the `deep-skills.com` zone → **DNS → Records**.
2. Create the records **using the exact targets Netlify's Domain settings panel shows**
   (do not hardcode from this doc - the values below are only what Netlify *typically*
   shows):
   - **`www`** - `CNAME` → the per-site hostname, typically `<site>.netlify.app`.
   - **`@` (apex)** - whatever Netlify displays for the apex. Netlify's documented apex
     path is an `A`/`ALIAS` record to its load balancer, or a `CNAME` to
     `apex-loadbalancer.netlify.com` (Cloudflare supports CNAME at the apex via
     flattening). Netlify discourages pointing the apex at the per-site
     `<site>.netlify.app` directly - use the apex target it shows.
3. Set **both records to DNS only (grey cloud)** - see the gotcha above.
4. Use a **low TTL** (e.g. 5 minutes / "Auto") during cutover so mistakes propagate out
   quickly. You can raise it once everything is verified.
5. Back in Netlify's Domain/HTTPS panel: wait for DNS verification to pass and the
   Let's Encrypt certificate to show as issued. This is usually minutes after propagation,
   occasionally up to an hour. Netlify has a "Verify DNS configuration" / renew button if
   it seems stuck.

### After the certificate is issued - pick one

**Option A - safe minimal path (recommended): stay DNS-only.**
Leave both records grey-cloud. Netlify serves the site and TLS directly; cert renewals
just work. You give up Cloudflare's proxy/CDN features, which a small static site behind
Netlify's own CDN does not need. Done - go to Part 4.

**Option B - enable the Cloudflare proxy.**
If you want Cloudflare's proxy features (WAF, analytics, etc.):

1. In Cloudflare **SSL/TLS → Overview**, set the encryption mode to **Full (strict)** -
   *before* flipping the clouds. Anything weaker ("Flexible" especially) causes redirect
   loops against Netlify.
2. Flip both records to **Proxied (orange cloud)**.
3. Re-verify the site loads over HTTPS with no redirect loop.
4. Caveat: with the proxy on, Netlify's future cert *renewals* can fail for the same
   HTTP-01 reason. If a renewal gets stuck, temporarily flip back to grey cloud, let it
   renew, then re-enable the proxy.

## Part 4 - Verification checklist

After DNS propagates (check with `dig deep-skills.com` / `dig www.deep-skills.com`, or an
online propagation checker):

- [ ] `https://deep-skills.com` loads the homepage with a **valid certificate** (padlock,
      no warnings).
- [ ] `https://www.deep-skills.com` loads with a valid cert and **301-redirects to
      `https://deep-skills.com`** (www → apex, matching the canonicals).
- [ ] `http://deep-skills.com` (plain HTTP) redirects to HTTPS.
- [ ] `https://deep-skills.com/sitemap.xml` and `https://deep-skills.com/robots.txt` are
      reachable.
- [ ] Spot-check a vanity redirect: `https://deep-skills.com/plan` →
      `/deep-plan.html`.
- [ ] All six skill pages + `install.html` + `how-it-works.html` load; fonts render
      (no CSP violations in the browser console).
- [ ] Run **Lighthouse** (Chrome devtools → Lighthouse) against
      `https://deep-skills.com` - target ≥ 90 on Performance, Accessibility,
      Best Practices, and SEO.

Optionally, submit `https://deep-skills.com/sitemap.xml` in Google Search Console once
the domain is verified there.

## Troubleshooting quick hits

- **SSL error / redirect loop right after adding DNS:** records are orange-clouded before
  the cert was issued. Flip to grey cloud (DNS only), wait for Netlify to provision the
  cert, then revisit Option B if desired.
- **Redirect loop with proxy enabled:** Cloudflare SSL/TLS mode is not **Full (strict)**.
  Fix the mode; never use "Flexible" in front of Netlify.
- **Netlify says "Check DNS configuration":** compare Cloudflare's records against the
  targets in Netlify's Domain panel character-for-character; confirm grey cloud; allow for
  TTL propagation.
- **Fonts missing / console CSP errors:** the CSP in `netlify.toml` must keep both
  `https://fonts.googleapis.com` (style-src) and `https://fonts.gstatic.com` (font-src).
