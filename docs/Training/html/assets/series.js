/* Deep Skills Training Series — shared interactions */
(function () {
  'use strict';

  // ---- mobile nav toggle ----
  var btn = document.querySelector('.menu-btn');
  var links = document.querySelector('.navlinks');
  if (btn && links) {
    btn.addEventListener('click', function () {
      links.classList.toggle('open');
    });
  }

  // ---- scroll progress bar ----
  var bar = document.getElementById('progress');
  function onScroll() {
    if (bar) {
      var h = document.documentElement;
      var max = h.scrollHeight - h.clientHeight;
      var pct = max > 0 ? (h.scrollTop / max) * 100 : 0;
      bar.style.width = pct + '%';
    }
    spyTOC();
  }

  // ---- reveal on scroll ----
  var reveals = [].slice.call(document.querySelectorAll('.reveal'));
  if ('IntersectionObserver' in window && reveals.length) {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) {
        if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target); }
      });
    }, { threshold: 0.12 });
    reveals.forEach(function (el) { io.observe(el); });
  } else {
    reveals.forEach(function (el) { el.classList.add('in'); });
  }

  // ---- TOC scrollspy ----
  var tocLinks = [].slice.call(document.querySelectorAll('.toc a'));
  var targets = tocLinks
    .map(function (a) {
      var id = a.getAttribute('href');
      return id && id.charAt(0) === '#' ? document.querySelector(id) : null;
    })
    .filter(Boolean);
  function spyTOC() {
    if (!targets.length) return;
    var pos = window.scrollY + 120;
    var current = targets[0];
    for (var i = 0; i < targets.length; i++) {
      if (targets[i].offsetTop <= pos) current = targets[i];
    }
    tocLinks.forEach(function (a) {
      a.classList.toggle('active', a.getAttribute('href') === '#' + current.id);
    });
  }

  window.addEventListener('scroll', onScroll, { passive: true });
  onScroll();
})();
