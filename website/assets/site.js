/* Deep Skills - marketing site shared interactions.
   Zero dependencies. Every feature is guarded so a page that
   omits a component (or an old browser) degrades gracefully. */
(function () {
  'use strict';

  // signal JS availability for CSS fallbacks (no-JS keeps nav/dropdowns usable)
  document.documentElement.classList.add('js');

  // ---- mobile nav toggle ----
  var toggle = document.querySelector('.nav-toggle');
  var menu = document.querySelector('.nav-menu');
  if (toggle && menu) {
    toggle.addEventListener('click', function () {
      var open = menu.classList.toggle('open');
      toggle.setAttribute('aria-expanded', open ? 'true' : 'false');
    });
  }

  // ---- skills dropdown ----
  var drop = document.querySelector('.nav-dropdown');
  var dropBtn = drop ? drop.querySelector('.nav-dropbtn') : null;
  if (drop && dropBtn) {
    dropBtn.addEventListener('click', function () {
      var open = drop.classList.toggle('open');
      dropBtn.setAttribute('aria-expanded', open ? 'true' : 'false');
    });
    document.addEventListener('click', function (e) {
      if (drop.classList.contains('open') && !drop.contains(e.target)) {
        drop.classList.remove('open');
        dropBtn.setAttribute('aria-expanded', 'false');
      }
    });
    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape' && drop.classList.contains('open')) {
        drop.classList.remove('open');
        dropBtn.setAttribute('aria-expanded', 'false');
        dropBtn.focus();
      }
    });
    // close before navigating away so bfcache doesn't restore it open
    drop.addEventListener('click', function (e) {
      if (e.target.closest && e.target.closest('a')) {
        drop.classList.remove('open');
        dropBtn.setAttribute('aria-expanded', 'false');
      }
    });
  }

  // bfcache restores DOM state as-is; reset transient nav state on every show
  window.addEventListener('pageshow', function () {
    if (drop && dropBtn) {
      drop.classList.remove('open');
      dropBtn.setAttribute('aria-expanded', 'false');
    }
    if (toggle && menu) {
      menu.classList.remove('open');
      toggle.setAttribute('aria-expanded', 'false');
    }
  });

  // ---- current-page nav highlighting (aria-current) ----
  // normalize so it works both as authored (deep-plan.html) and after
  // Netlify's pretty-URL rewrite (/deep-plan)
  function pageKey(s) {
    return s.replace(/^\.?\//, '').replace(/\.html$/, '') || 'index';
  }
  var path = window.location.pathname;
  var page = pageKey(path.substring(path.lastIndexOf('/') + 1) || 'index.html');
  var navLinks = [].slice.call(document.querySelectorAll('.nav-menu a[href]'));
  navLinks.forEach(function (a) {
    var href = a.getAttribute('href');
    if (href.indexOf('://') === -1 && pageKey(href) === page) {
      a.setAttribute('aria-current', 'page');
      // if the current page lives in the dropdown, mark the trigger too
      var parentDrop = a.closest ? a.closest('.nav-dropdown') : null;
      if (parentDrop) {
        var btn = parentDrop.querySelector('.nav-dropbtn');
        if (btn) btn.classList.add('here');
      }
    }
  });

  // ---- scroll progress bar ----
  var bar = document.getElementById('progress');
  function onScroll() {
    if (!bar) return;
    var h = document.documentElement;
    var max = h.scrollHeight - h.clientHeight;
    var pct = max > 0 ? (h.scrollTop / max) * 100 : 0;
    bar.style.width = pct + '%';
  }
  if (bar) {
    window.addEventListener('scroll', onScroll, { passive: true });
    onScroll();
  }

  // ---- copy-to-clipboard (install command chips) ----
  var copyBtns = [].slice.call(document.querySelectorAll('.copy-btn'));
  if (copyBtns.length) {
    var canCopy = false;
    try {
      canCopy = !!(navigator.clipboard && typeof navigator.clipboard.writeText === 'function');
    } catch (err) { /* ignore */ }
    copyBtns.forEach(function (btn) {
      if (!canCopy) { btn.hidden = true; return; }
      btn.addEventListener('click', function () {
        var row = btn.closest ? btn.closest('.cmdline') : null;
        var chip = row ? row.querySelector('code') : null;
        if (!chip) return;
        navigator.clipboard.writeText(chip.textContent.trim()).then(function () {
          btn.classList.add('copied');
          btn.textContent = 'Copied';
          setTimeout(function () {
            btn.classList.remove('copied');
            btn.textContent = 'Copy';
          }, 1600);
        }).catch(function () { /* ignore */ });
      });
    });
  }

  // ---- reveal on scroll (fallback: visible) ----
  var reveals = [].slice.call(document.querySelectorAll('.reveal'));
  var reduceMotion = false;
  try {
    reduceMotion = window.matchMedia &&
      window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  } catch (err) { /* ignore */ }
  if ('IntersectionObserver' in window && reveals.length && !reduceMotion) {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) {
        if (e.isIntersecting) {
          e.target.classList.add('in');
          io.unobserve(e.target);
        }
      });
    }, { threshold: 0.12 });
    reveals.forEach(function (el) { io.observe(el); });
  } else {
    reveals.forEach(function (el) { el.classList.add('in'); });
  }
})();
