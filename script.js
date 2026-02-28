/* ============================================
   MOTODASH — script.js
   ============================================ */

(function () {
    'use strict';

    /* ── THEME TOGGLE ── */
    var themeToggle = document.getElementById('theme-toggle');

    function setTheme(theme) {
        document.documentElement.setAttribute('data-theme', theme);
        localStorage.setItem('motodash-theme', theme);
    }

    if (themeToggle) {
        themeToggle.addEventListener('click', function () {
            var current = document.documentElement.getAttribute('data-theme');
            setTheme(current === 'dark' ? 'light' : 'dark');
        });
    }

    /* ── DISCLAIMER MODAL ── */
    var modal = document.getElementById('disclaimer-modal');
    var modalConfirm = document.getElementById('modal-confirm');
    var modalCancel = document.getElementById('modal-cancel');
    var pendingHref = null;
    var pendingType = null;
    var focusableSel = 'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])';
    var lastFocused = null;

    function openModal(href, type) {
        pendingHref = href;
        pendingType = type;
        lastFocused = document.activeElement;
        modal.removeAttribute('hidden');
        document.body.style.overflow = 'hidden';
        if (modalConfirm) modalConfirm.focus();
    }

    function closeModal() {
        modal.setAttribute('hidden', '');
        document.body.style.overflow = '';
        pendingHref = null;
        pendingType = null;
        if (lastFocused) lastFocused.focus();
    }

    function triggerDownload(href) {
        var a = document.createElement('a');
        a.href = href;
        a.download = '';
        a.rel = 'noopener noreferrer';
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
    }

    function handleModalKeydown(e) {
        if (!modal.hasAttribute('hidden')) {
            if (e.key === 'Escape') {
                closeModal();
                return;
            }
            if (e.key === 'Tab') {
                var focusable = Array.from(modal.querySelectorAll(focusableSel));
                var first = focusable[0];
                var last = focusable[focusable.length - 1];
                if (e.shiftKey) {
                    if (document.activeElement === first) {
                        e.preventDefault();
                        last.focus();
                    }
                } else {
                    if (document.activeElement === last) {
                        e.preventDefault();
                        first.focus();
                    }
                }
            }
        }
    }

    document.addEventListener('keydown', handleModalKeydown);

    if (modalConfirm) {
        modalConfirm.addEventListener('click', function () {
            var href = pendingHref;
            var type = pendingType;
            closeModal();
            if (!href) return;
            if (type === 'download') {
                triggerDownload(href);
            } else {
                window.open(href, '_blank', 'noopener,noreferrer');
            }
        });
    }

    if (modalCancel) {
        modalCancel.addEventListener('click', closeModal);
    }

    if (modal) {
        modal.addEventListener('click', function (e) {
            if (e.target === modal) closeModal();
        });
    }

    /* ── CTA BUTTONS ── */
    // GitHub /releases/latest/download/<filename> resolves to the newest release asset.
    // Update the filename below to match your actual APK asset name in GitHub Releases.
    var downloadUrl = 'https://github.com/ujwalnk/Motodash/releases/latest/download/app-release.apk';
    var githubUrl = 'https://github.com/ujwalnk/Motodash';

    function handleCtaClick(e) {
        var type = e.currentTarget.getAttribute('data-type');
        var href = type === 'github' ? githubUrl : downloadUrl;
        openModal(href, type);
    }

    var ctaButtons = document.querySelectorAll('.cta-download');
    ctaButtons.forEach(function (btn) {
        btn.addEventListener('click', handleCtaClick);
    });

    /* ── CAROUSEL ── */
    function initCarousel(trackId, prevId, nextId, dotsId) {
        var track = document.getElementById(trackId);
        var prevBtn = document.getElementById(prevId);
        var nextBtn = document.getElementById(nextId);
        var dotsContainer = document.getElementById(dotsId);

        if (!track) return;

        var slides = track.children;
        var total = slides.length;
        var current = 0;

        for (var i = 0; i < total; i++) {
            var dot = document.createElement('button');
            dot.className = 'carousel-dot' + (i === 0 ? ' active' : '');
            dot.setAttribute('role', 'tab');
            dot.setAttribute('aria-selected', i === 0 ? 'true' : 'false');
            dot.setAttribute('aria-label', 'Slide ' + (i + 1) + ' of ' + total);
            dot.dataset.index = i;
            dotsContainer.appendChild(dot);
        }

        var dots = dotsContainer.querySelectorAll('.carousel-dot');

        function goTo(index) {
            current = (index + total) % total;
            track.style.transform = 'translateX(-' + (current * 100) + '%)';
            dots.forEach(function (d, idx) {
                var active = idx === current;
                d.classList.toggle('active', active);
                d.setAttribute('aria-selected', active ? 'true' : 'false');
            });
        }

        if (prevBtn) prevBtn.addEventListener('click', function () { goTo(current - 1); });
        if (nextBtn) nextBtn.addEventListener('click', function () { goTo(current + 1); });

        dots.forEach(function (dot) {
            dot.addEventListener('click', function () {
                goTo(parseInt(dot.dataset.index, 10));
            });
        });

        var carouselEl = document.getElementById(trackId.replace('-track', '-carousel'));
        if (carouselEl) {
            carouselEl.addEventListener('keydown', function (e) {
                if (e.key === 'ArrowLeft') { goTo(current - 1); e.preventDefault(); }
                if (e.key === 'ArrowRight') { goTo(current + 1); e.preventDefault(); }
            });
            carouselEl.setAttribute('tabindex', '0');
        }
    }

    initCarousel('call-track', 'call-prev', 'call-next', 'call-dots');

    /* ── SCROLL REVEAL ── */
    var prefersReduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

    if (!prefersReduced && 'IntersectionObserver' in window) {
        var revealObserver = new IntersectionObserver(function (entries) {
            entries.forEach(function (entry) {
                if (entry.isIntersecting) {
                    entry.target.classList.add('visible');
                    revealObserver.unobserve(entry.target);
                }
            });
        }, { threshold: 0.1, rootMargin: '0px 0px -40px 0px' });

        document.querySelectorAll('.reveal').forEach(function (el) {
            revealObserver.observe(el);
        });
    } else {
        document.querySelectorAll('.reveal').forEach(function (el) {
            el.classList.add('visible');
        });
    }

    /* ── MERMAID (specifications page only) ── */
    if (document.querySelector('.mermaid') && typeof mermaid !== 'undefined') {
        var isDark = document.documentElement.getAttribute('data-theme') === 'dark';
        mermaid.initialize({
            startOnLoad: true,
            theme: isDark ? 'dark' : 'default',
            themeVariables: isDark ? {
                primaryColor: '#1f1f1f',
                primaryTextColor: '#e8e8e8',
                primaryBorderColor: '#2a2a2a',
                lineColor: '#555555',
                secondaryColor: '#161616',
                tertiaryColor: '#161616'
            } : {}
        });
    }

})();