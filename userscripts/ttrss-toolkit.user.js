// ==UserScript==
// @name         tt-rss Toolkit
// @namespace    wpcreative.ttrss.toolkit
// @version      1.0
// @description  Star current page, subscribe to feeds, and one-click YouTube channel RSS - all via tt-rss toolbar menu
// @author       You
// @match        *://*/*
// @grant        GM_xmlhttpRequest
// @grant        GM_registerMenuCommand
// @run-at       document-idle
// ==/UserScript==

(function () {
    'use strict';

    // ---- config: fill these in after deploying the plugin ----
    const TTRSS_BASE = 'https://rss.gurungsujal.com.np/tt-rss';
    const STAR_ENDPOINT = TTRSS_BASE + '/public.php?op=star_bookmarklet--star'; // verify against Preferences -> Feeds -> Bookmarklets (custom) tab
    const STAR_TOKEN = 'REPLACE_ME_WITH_A_LONG_RANDOM_STRING'; // must match STAR_TOKEN in the plugin
    // ------------------------------------------------------------

    function toast(message, isError) {
        const el = document.createElement('div');
        el.textContent = message;
        el.style.cssText = `
            position: fixed; top: 16px; right: 16px; z-index: 2147483647;
            background: ${isError ? '#c0392b' : '#27ae60'}; color: #fff;
            padding: 10px 16px; border-radius: 6px; font: 14px/1.4 system-ui, sans-serif;
            box-shadow: 0 2px 10px rgba(0,0,0,.3); opacity: 0; transition: opacity .15s ease;
        `;
        document.body.appendChild(el);
        requestAnimationFrame(() => { el.style.opacity = '1'; });
        setTimeout(() => {
            el.style.opacity = '0';
            setTimeout(() => el.remove(), 200);
        }, 2000);
    }

    function starCurrentPage() {
        const url = location.href;
        const title = document.title;

        GM_xmlhttpRequest({
            method: 'POST',
            url: STAR_ENDPOINT,
            data: new URLSearchParams({ token: STAR_TOKEN, url, title }).toString(),
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            onload: function (res) {
                try {
                    const data = JSON.parse(res.responseText);
                    if (data.success) {
                        toast('★ Starred in tt-rss');
                    } else {
                        toast('Star failed: ' + (data.error || 'unknown error'), true);
                    }
                } catch (e) {
                    toast('Star failed: bad response', true);
                }
            },
            onerror: function () {
                toast('Star failed: request error', true);
            }
        });
    }

    function subscribeCurrentPage() {
        const url = location.href;
        if (!confirm('Subscribe to ' + url + ' in Tiny Tiny RSS?')) return;
        location.href = TTRSS_BASE + '/public.php?op=bookmarklets--subscribe&feed_url=' + encodeURIComponent(url);
    }

    GM_registerMenuCommand('★ Star this page in tt-rss', starCurrentPage);
    GM_registerMenuCommand('📡 Subscribe to this feed in tt-rss', subscribeCurrentPage);

    // ---- YouTube channel -> RSS ----
    if (location.hostname.endsWith('youtube.com')) {

        function extractChannelId() {
            // Try the SEO meta tag first - present on both /@handle and /channel/UC... pages.
            const meta = document.querySelector('meta[itemprop="channelId"]');
            if (meta && meta.content) return meta.content;

            const link = document.querySelector('link[itemprop="url"][href*="/channel/"]');
            if (link) {
                const m = link.href.match(/\/channel\/(UC[\w-]+)/);
                if (m) return m[1];
            }

            // Fallback: scrape the raw HTML for a channelId reference.
            const m = document.documentElement.innerHTML.match(/"channelId":"(UC[\w-]+)"/);
            if (m) return m[1];

            return null;
        }

        function subscribeYouTubeChannel() {
            const channelId = extractChannelId();
            if (!channelId) {
                toast('Could not find channel ID on this page', true);
                return;
            }
            const feedUrl = 'https://www.youtube.com/feeds/videos.xml?channel_id=' + channelId;
            if (!confirm('Subscribe to this channel\'s RSS feed in tt-rss?')) return;
            window.open(TTRSS_BASE + '/public.php?op=bookmarklets--subscribe&feed_url=' + encodeURIComponent(feedUrl), '_blank');
        }

        GM_registerMenuCommand('📡 Subscribe to this YouTube channel', subscribeYouTubeChannel);

        // Floating button, appended directly to <body> (not injected into YouTube's
        // own shadow-DOM component tree) so it isn't affected by YT's frequent
        // internal DOM/CSS changes.
        function addFloatingButton() {
            if (document.getElementById('ttrss-yt-subscribe-btn')) return;
            if (!extractChannelId()) return; // not a channel page (yet) - YT is an SPA, page may still be loading

            const btn = document.createElement('button');
            btn.id = 'ttrss-yt-subscribe-btn';
            btn.textContent = '📡 tt-rss';
            btn.style.cssText = `
                position: fixed; bottom: 16px; right: 16px; z-index: 2147483647;
                background: #d92929; color: #fff; border: none; border-radius: 20px;
                padding: 10px 16px; font: 13px/1 system-ui, sans-serif; cursor: pointer;
                box-shadow: 0 2px 10px rgba(0,0,0,.3);
            `;
            btn.addEventListener('click', subscribeYouTubeChannel);
            document.body.appendChild(btn);
        }

        // YouTube is an SPA - re-check on navigation, not just initial load.
        addFloatingButton();
        let lastUrl = location.href;
        new MutationObserver(() => {
            if (location.href !== lastUrl) {
                lastUrl = location.href;
                document.getElementById('ttrss-yt-subscribe-btn')?.remove();
                setTimeout(addFloatingButton, 800); // give YT time to render the new page
            }
        }).observe(document.body, { childList: true, subtree: true });
    }
})();
