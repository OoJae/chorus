/* Chorus landing page. No libraries, no network beyond this server. */
(function () {
  'use strict';

  // The film. Put its address here and the "Watch the film" button appears.
  var FILM_URL = '';

  var APP = '/app/';

  // ── Old visitors: the app used to live at the root ──────────────────────
  if (window.matchMedia && matchMedia('(display-mode: standalone)').matches) {
    location.replace(APP);
    return;
  }
  if (location.hash.indexOf('#/') === 0) {
    location.replace(APP + location.hash);
    return;
  }
  if ('serviceWorker' in navigator && navigator.serviceWorker.getRegistrations) {
    navigator.serviceWorker.getRegistrations().then(function (regs) {
      var root = location.origin + '/';
      regs.forEach(function (r) { if (r.scope === root) r.unregister(); });
    }).catch(function () {});
  }

  var doc = document.documentElement;
  doc.classList.add('js');
  var reduce = window.matchMedia && matchMedia('(prefers-reduced-motion: reduce)');
  function still() { return !!(reduce && reduce.matches); }

  function $(sel, root) { return (root || document).querySelector(sel); }
  function $$(sel, root) { return Array.prototype.slice.call((root || document).querySelectorAll(sel)); }
  function clamp(v, lo, hi) { return v < lo ? lo : v > hi ? hi : v; }
  function buzz() { if (navigator.vibrate) { try { navigator.vibrate(8); } catch (e) {} } }

  // ── Speech: the device's own voice, everyday en-US first ────────────────
  var synth = window.speechSynthesis;
  var voice = null;
  var engineSpeaking = false;
  var turn = 0;
  var everyday = ['Samantha', 'Microsoft Zira', 'Microsoft David',
    'Google US English', 'Microsoft Aria', 'Microsoft Jenny'];
  function langOf(v) { return (v.lang || '').toLowerCase().replace('_', '-'); }
  function chooseVoice() {
    if (!synth || voice) return;
    var list = Array.prototype.filter.call(synth.getVoices() || [], function (v) { return v.localService !== false; });
    for (var i = 0; i < everyday.length && !voice; i++) {
      for (var j = 0; j < list.length; j++) {
        if (langOf(list[j]) === 'en-us' && list[j].name.indexOf(everyday[i]) === 0) { voice = list[j]; break; }
      }
    }
    for (var k = 0; k < list.length && !voice; k++) { if (langOf(list[k]) === 'en-us') voice = list[k]; }
    for (var m = 0; m < list.length && !voice; m++) {
      var l = langOf(list[m]);
      if (l === 'en' || l.indexOf('en-') === 0) voice = list[m];
    }
  }
  if (synth && synth.addEventListener) synth.addEventListener('voiceschanged', chooseVoice);
  function speak(text) {
    if (!synth || !text) return;
    var mine = ++turn;
    var wasSpeaking = engineSpeaking;
    synth.cancel();
    var waits = 0;
    (function go() {
      if (mine !== turn) return;
      if (wasSpeaking && engineSpeaking && waits < 30) { waits++; setTimeout(go, 10); return; }
      chooseVoice();
      var u = new SpeechSynthesisUtterance(text);
      u.lang = 'en-US';
      if (voice) u.voice = voice;
      u.rate = 0.9;
      u.onstart = function () { engineSpeaking = true; };
      u.onend = u.onerror = function () { engineSpeaking = false; };
      synth.speak(u);
    })();
  }

  // ── The hero board: tap to build a sentence ─────────────────────────────
  var strip = $('#strip');
  var announce = $('#announce');
  var said = [];
  function say(text) {
    announce.textContent = '';
    // A fresh node each time, so a repeated word is announced again.
    setTimeout(function () { announce.textContent = text; }, 30);
    speak(text);
  }
  function renderStrip() {
    strip.textContent = '';
    if (!said.length) {
      var hint = document.createElement('span');
      hint.className = 'strip-hint';
      hint.textContent = 'Tap the words to make a sentence';
      strip.appendChild(hint);
    }
  }
  $$('.board-grid .tile').forEach(function (tile, i) {
    tile.addEventListener('click', function () {
      var word = tile.getAttribute('data-say');
      if (!said.length) strip.textContent = '';
      said.push(word);
      var w = document.createElement('span');
      w.className = 'w';
      w.textContent = word;
      strip.appendChild(w);
      tile.classList.remove('lit'); void tile.offsetWidth; tile.classList.add('lit');
      say(word);
    });
    // Where each tile flies when the board opens into the app.
    var col = i % 4, row = Math.floor(i / 4);
    tile.style.setProperty('--fx', ((col - 1.5) * 80) + 'vw');
    tile.style.setProperty('--fy', ((row - 1) * 70) + 'vh');
    tile.style.setProperty('--fr', ((col - 1.5) * 9) + 'deg');
  });
  $('#say').addEventListener('click', function () { if (said.length) say(said.join(' ')); });
  $('#clear').addEventListener('click', function () {
    said = [];
    renderStrip();
    turn++;
    if (synth) synth.cancel();
    announce.textContent = 'Cleared';
  });

  // ── Laminated presses: every button and tile ────────────────────────────
  $$('.btn, .tile, .big-btn').forEach(function (el) {
    el.addEventListener('pointerdown', function () { el.classList.add('pressed'); buzz(); }, { passive: true });
    ['pointerup', 'pointerleave', 'pointercancel', 'blur'].forEach(function (t) {
      el.addEventListener(t, function () { el.classList.remove('pressed'); }, { passive: true });
    });
    el.addEventListener('keydown', function (e) { if (e.key === ' ' || e.key === 'Enter') el.classList.add('pressed'); });
    el.addEventListener('keyup', function () { el.classList.remove('pressed'); });
  });

  // ── "Open Chorus": the board flies apart, then the app ──────────────────
  var flying = false;
  $$('a.open-app').forEach(function (a) {
    a.addEventListener('click', function (e) {
      if (e.metaKey || e.ctrlKey || e.shiftKey || e.altKey || e.button !== 0) return;
      e.preventDefault();
      if (flying) return;
      if (still()) { location.href = APP; return; }
      flying = true;
      doc.classList.add('flying');
      setTimeout(function () { location.href = APP; }, 440);
    });
  });
  // Coming back with the back button restores the page as it was.
  window.addEventListener('pageshow', function (e) {
    if (e.persisted) { flying = false; doc.classList.remove('flying'); }
  });

  // ── Film button ──────────────────────────────────────────────────────────
  var film = $('#film');
  if (FILM_URL && film) {
    film.hidden = false;
    film.addEventListener('click', function () { location.href = FILM_URL; });
  }

  // ── Nav state ────────────────────────────────────────────────────────────
  var nav = $('#nav');

  // ── Reveals: headings wipe in, cards rise with a stagger ────────────────
  var cards = $$('.card');
  cards.forEach(function (c) { c.classList.add('pending'); });
  if ('IntersectionObserver' in window) {
    var io = new IntersectionObserver(function (entries) {
      var batch = 0;
      entries.forEach(function (en) {
        if (!en.isIntersecting) return;
        var el = en.target;
        if (el.classList.contains('card')) {
          el.style.setProperty('--i', String(batch++));
          el.classList.remove('pending');
          el.classList.add('risen');
        } else {
          $$('.wipe', el).forEach(function (w) { w.classList.add('in'); });
        }
        io.unobserve(el);
      });
    }, { rootMargin: '0px 0px -8% 0px', threshold: 0.15 });
    // A heading is observed through its parent: its own clip-path hides it
    // from the observer until it is uncovered.
    $$('.wipe').forEach(function (el) { io.observe(el.parentElement); });
    cards.forEach(function (el) { io.observe(el); });
  } else {
    $$('.wipe').forEach(function (el) { el.classList.add('in'); });
    cards.forEach(function (c) { c.classList.remove('pending'); });
  }

  // Cards lean towards the pointer.
  if (window.matchMedia && matchMedia('(hover: hover) and (pointer: fine)').matches) {
    cards.forEach(function (c) {
      c.addEventListener('pointermove', function (e) {
        if (still()) return;
        var r = c.getBoundingClientRect();
        var x = (e.clientX - r.left) / r.width - 0.5;
        var y = (e.clientY - r.top) / r.height - 0.5;
        c.style.setProperty('--ty', (x * 10).toFixed(2) + 'deg');
        c.style.setProperty('--tx', (-y * 10).toFixed(2) + 'deg');
      }, { passive: true });
      c.addEventListener('pointerleave', function () {
        c.style.setProperty('--tx', '0deg');
        c.style.setProperty('--ty', '0deg');
      }, { passive: true });
    });
  }

  // ── The board leans towards the pointer, or the phone's tilt ────────────
  var board = $('#board3d');
  var aim = { x: 0, y: 0 };
  var lean = { x: 0, y: 0 };
  var lastInput = -1e9;
  window.addEventListener('pointermove', function (e) {
    if (e.pointerType === 'touch') return;
    aim.x = clamp(e.clientX / innerWidth * 2 - 1, -1, 1);
    aim.y = clamp(e.clientY / innerHeight * 2 - 1, -1, 1);
    lastInput = performance.now();
  }, { passive: true });
  var needsPermission = window.DeviceOrientationEvent && typeof DeviceOrientationEvent.requestPermission === 'function';
  if (window.DeviceOrientationEvent && !needsPermission) {
    window.addEventListener('deviceorientation', function (e) {
      if (e.beta == null || e.gamma == null) return;
      aim.x = clamp(e.gamma / 30, -1, 1);
      aim.y = clamp((e.beta - 40) / 30, -1, 1);
      lastInput = performance.now();
    }, { passive: true });
  }

  // ── The story ────────────────────────────────────────────────────────────
  var story = $('#story');
  var stage = $('#story-stage');
  var devices = $('.devices', stage);
  var tablet = $('#dev-tablet');
  var phone = $('#dev-phone');
  var laptop = $('#dev-laptop');
  var miniWant = $('.m-want', stage);
  var miniMore = $('.m-more', stage);

  // Where the flying words start: measured on load and on resize only.
  function centre(el) {
    var r = el.getBoundingClientRect();
    return { x: r.left + r.width / 2, y: r.top + r.height / 2 };
  }
  function measure() {
    if (still()) return;
    var saved = devices.style.getPropertyValue('--split');
    devices.style.setProperty('--split', '1');
    var p = centre(phone), l = centre(laptop), t = centre(tablet);
    var sj = centre($('.slot-juice', stage)), sc = centre($('.slot-clash', stage));
    devices.style.setProperty('--split', saved || '0');
    // The tablet is scaled while measuring as at the end of the split, so
    // these offsets are where the phone and laptop sit when words fly.
    stage.style.setProperty('--jx', (p.x - sj.x) + 'px');
    stage.style.setProperty('--jy', (p.y - sj.y) + 'px');
    stage.style.setProperty('--ax2', (p.x - sc.x) + 'px');
    stage.style.setProperty('--ay2', (p.y - sc.y) + 'px');
    stage.style.setProperty('--bx2', (l.x - sc.x) + 'px');
    stage.style.setProperty('--by2', (l.y - sc.y) + 'px');
    var dr = devices.getBoundingClientRect();
    // Pulses run from the phone and the laptop to the tablet.
    var pa = $('.pulse-a', devices), pb = $('.pulse-b', devices);
    pa.style.left = (p.x - dr.left) + 'px'; pa.style.top = (p.y - dr.top) + 'px';
    pb.style.left = (l.x - dr.left) + 'px'; pb.style.top = (l.y - dr.top) + 'px';
    pa.style.setProperty('--ax', (t.x - p.x) + 'px'); pa.style.setProperty('--ay', (t.y - p.y) + 'px');
    pb.style.setProperty('--bx', (t.x - l.x) + 'px'); pb.style.setProperty('--by', (t.y - l.y) + 'px');
    var la = $('.link-a', devices), lb = $('.link-b', devices);
    function pct(v, lo, size) { return ((v - lo) / size * 100).toFixed(2); }
    la.setAttribute('x1', pct(p.x, dr.left, dr.width)); la.setAttribute('y1', pct(p.y, dr.top, dr.height));
    la.setAttribute('x2', pct(t.x, dr.left, dr.width)); la.setAttribute('y2', pct(t.y, dr.top, dr.height));
    lb.setAttribute('x1', pct(l.x, dr.left, dr.width)); lb.setAttribute('y1', pct(l.y, dr.top, dr.height));
    lb.setAttribute('x2', pct(t.x, dr.left, dr.width)); lb.setAttribute('y2', pct(t.y, dr.top, dr.height));
  }

  var shownStep = -1, shownPhase = '';
  function setStory(step, phase) {
    if (step === shownStep && phase === shownPhase) return;
    shownStep = step; shownPhase = phase;
    stage.setAttribute('data-step', String(step));
    stage.setAttribute('data-phase', phase);
    devices.classList.toggle('syncing', step >= 2);
    var talking = step === 1 || (step === 2 && phase === 'a');
    miniWant.classList.toggle('lit', talking);
    miniMore.classList.toggle('lit', talking);
  }

  // ── The diagram draws itself ─────────────────────────────────────────────
  var diagram = $('#diagram');

  // ── One frame loop: read scroll once, write custom properties ───────────
  var running = false;
  var split = -1, drawn = -1;
  function frame(now) {
    running = false;
    var vh = innerHeight;
    var y = scrollY;
    nav.classList.toggle('scrolled', y > 24);

    if (!still()) {
      // Hero lean, with a gentle drift when nobody is touching it.
      var idle = now - lastInput > 2500;
      var tx = idle ? Math.sin(now / 2400) * 0.45 : aim.x;
      var ty = idle ? Math.cos(now / 3100) * 0.35 : aim.y;
      lean.x += (tx - lean.x) * 0.08;
      lean.y += (ty - lean.y) * 0.08;
      board.style.setProperty('--ry', (lean.x * 8).toFixed(2) + 'deg');
      board.style.setProperty('--rx', (10 - lean.y * 8).toFixed(2) + 'deg');

      // Story progress 0..1 across the pinned stretch.
      var top = story.offsetTop;
      var span = story.offsetHeight - vh;
      var p = clamp((y - top) / span, 0, 1);
      var s = clamp(p / 0.16, 0, 1);
      s = 1 - Math.pow(1 - s, 3);
      if (Math.abs(s - split) > 0.001) { split = s; devices.style.setProperty('--split', s.toFixed(3)); }
      var step = p < 0.12 ? 0 : p < 0.38 ? 1 : p < 0.7 ? 2 : 3;
      var phase = step === 2 ? (p < 0.55 ? 'a' : 'b') : step === 3 ? (p < 0.82 ? 'a' : 'b') : '';
      setStory(step, phase);

      var dr = diagram.getBoundingClientRect();
      var d = clamp((vh * 0.92 - dr.top) / (dr.height * 0.9 + vh * 0.2), 0, 1);
      if (Math.abs(d - drawn) > 0.002) { drawn = d; diagram.style.setProperty('--draw', d.toFixed(3)); }

      // Keep the idle drift alive while the hero is on screen.
      if (y < vh * 1.2) schedule();
    }
  }
  function schedule() { if (!running) { running = true; requestAnimationFrame(frame); } }
  window.addEventListener('scroll', schedule, { passive: true });
  window.addEventListener('pointermove', schedule, { passive: true });
  window.addEventListener('resize', function () { measure(); schedule(); }, { passive: true });

  function settleStill() {
    if (still()) {
      split = 1;
      devices.style.setProperty('--split', '1');
      setStory(3, 'b');
      miniWant.classList.remove('lit');
      miniMore.classList.remove('lit');
      diagram.style.setProperty('--draw', '1');
      board.style.setProperty('--rx', '0deg');
      board.style.setProperty('--ry', '0deg');
    } else {
      measure();
      shownStep = -1;
    }
    schedule();
  }
  if (reduce && reduce.addEventListener) reduce.addEventListener('change', settleStill);
  if (document.fonts && document.fonts.ready) document.fonts.ready.then(function () { measure(); schedule(); });
  settleStill();
})();
