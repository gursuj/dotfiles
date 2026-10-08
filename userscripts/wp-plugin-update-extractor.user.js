// ==UserScript==
// @name         WP Plugin Update Extractor
// @namespace    wpc-tools
// @version      3.3
// @description  Extract all plugin names + current versions + available update versions to clipboard or file, from wp-admin or ManageWP
// @match        *://*/wp-admin/plugins.php*
// @match        *://*/wp-admin/network/plugins.php*
// @match        *://*.managewp.com/*
// @grant        GM_registerMenuCommand
// @grant        GM_setClipboard
// ==/UserScript==

(function () {
  'use strict';

  function slugify(raw) {
    return raw.replace(/[^a-z0-9]+/gi, '-').replace(/^-+|-+$/g, '').toLowerCase() || 'site';
  }

  function getSiteName() {
    const abItem = document.querySelector('#wp-admin-bar-site-name .ab-item');
    if (abItem) {
      const raw = abItem.textContent.trim().replace(/^Visit\s+/i, '').trim();
      return slugify(raw);
    }
    const m = location.pathname.match(/\/site\/(\d+)/);
    if (m) return `managewp-site-${m[1]}`;
    return slugify(location.hostname);
  }

  function getPageContext() {
    const host = location.hostname;
    if (host.endsWith('managewp.com')) {
      if (/\/dashboard\/site\/\d+\/dashboard/.test(location.pathname)) return 'managewp-dashboard';
      if (/\/dashboard\/site\/\d+\/component\/plugins\/manage/.test(location.pathname)) return 'managewp-manage';
      return 'managewp-other';
    }
    if (/\/wp-admin\/(network\/)?plugins\.php/.test(location.pathname)) return 'wp-admin';
    return 'unknown';
  }

  // --- wp-admin plugins.php (single site or network) ---

  function extractWpAdminPlugins() {
    const results = [];
    document.querySelectorAll('.plugin-version-author-uri').forEach(verEl => {
      const mainRow = verEl.closest('tr');
      if (!mainRow) return;

      const nameEl = mainRow.querySelector('.plugin-title strong');
      const name = nameEl ? nameEl.textContent.trim() : null;
      if (!name) return;

      const slug = mainRow.getAttribute('data-slug') || null;
      const active = mainRow.classList.contains('active');

      let current = null;
      const m = verEl.textContent.match(/Version\s+([^\s|]+)/i);
      if (m) current = m[1];

      const updateAvailable = verEl.classList.contains('update');
      let next = null;
      if (updateAvailable) {
        const updateRow = mainRow.nextElementSibling;
        const msg = updateRow ? updateRow.querySelector('.update-message') : null;
        if (msg) {
          const link = msg.querySelector('a[aria-label*="version"]') || msg.querySelector('a.open-plugin-details-modal');
          if (link) {
            const vm = (link.getAttribute('aria-label') || link.textContent).match(/version\s+([^\s]+)\s+details/i);
            if (vm) next = vm[1];
          }
        }
      }

      results.push({ name, slug, active, current, updateAvailable, new: next });
    });
    return results;
  }

  // --- ManageWP: site Dashboard tab (shows plugins/themes/core that have updates) ---

  function extractManageWPDashboard() {
    const results = [];
    document.querySelectorAll('.update-row').forEach(row => {
      const link = row.querySelector('[slug][from-version][to-version]');
      if (!link) return; // theme/core update rows don't carry a plugin slug this way — skip

      const nameEl = row.querySelector('.component-name');
      const name = nameEl ? nameEl.textContent.trim() : null;
      if (!name) return;

      const tooltip = nameEl.getAttribute('uib-tooltip') || '';
      let active = null;
      if (/\(active\)/i.test(tooltip)) active = true;
      else if (/\(inactive\)/i.test(tooltip)) active = false;

      const slug = link.getAttribute('slug');
      const current = link.getAttribute('from-version');
      const next = link.getAttribute('to-version');

      results.push({ name, slug, active, current, updateAvailable: true, new: next });
    });
    return results;
  }

  // --- ManageWP: site's Plugins > Manage tab (needs the "Updates" sub-tab clicked first) ---

  const sleep = ms => new Promise(r => setTimeout(r, ms));

  // Find a sub-tab by tooltip text. startsWith so "Active" never matches "Inactive".
  function findManageWPTab(label) {
    const tabs = Array.from(document.querySelectorAll('.tab-button'));
    return tabs.find(t => (t.getAttribute('uib-tooltip') || '').trim().toLowerCase().startsWith(label.toLowerCase())) || null;
  }

  // Click a tab, then wait until the list stops changing (Angular re-renders async).
  // An empty tab (e.g. no inactive plugins) just times out with 0 items, which is fine.
  async function openTabAndWait(tab) {
    tab.click();
    await sleep(300);
    let last = -1;
    let stable = 0;
    for (let i = 0; i < 40 && stable < 3; i++) { // ~4s max
      const n = document.querySelectorAll('.list-item-content').length;
      if (n === last && n > 0) stable++;
      else stable = 0;
      last = n;
      await sleep(100);
    }
  }

  function readManageWPItem(item) {
    const nameEl = item.querySelector('.component-name');
    if (!nameEl) return null;
    // First text node is the plugin name; later child elements are icons (vulnerability/favorite).
    const nameNode = Array.from(nameEl.childNodes).find(n => n.nodeType === 3 && n.textContent.trim());
    const name = (nameNode ? nameNode.textContent : nameEl.textContent).trim();
    if (!name) return null;

    const link = item.querySelector('a[slug][from-version][to-version]');
    if (link) {
      return {
        name,
        slug: link.getAttribute('slug'),
        current: link.getAttribute('from-version'),
        next: link.getAttribute('to-version'),
      };
    }

    // No update link: version is plain text. Markup unknown, so try likely spots then regex.
    const slugEl = item.querySelector('[slug]');
    const verEl = item.querySelector('[class*="version"]');
    const src = verEl ? verEl.textContent : item.textContent.replace(nameEl.textContent, '');
    const m = src.match(/\d+(?:\.\d+)+[\w.\-+]*/);
    if (!m) console.warn('[WP Plugin Extractor] no version found, item HTML:', item.outerHTML);
    return {
      name,
      slug: slugEl ? slugEl.getAttribute('slug') : null,
      current: m ? m[0] : null,
      next: null,
    };
  }

  function readManageWPList() {
    return Array.from(document.querySelectorAll('.list-item-content')).map(readManageWPItem).filter(Boolean);
  }

  // Walk Active, Inactive, Updates tabs and merge. Updates tab wins for version info.
  async function extractManageWPManage() {
    const byKey = new Map();
    // Key by name only: Active/Inactive rows have no slug but Updates rows do,
    // so keying by slug would treat the same plugin as two entries.
    const keyOf = p => p.name.trim().toLowerCase();
    const missing = [];

    for (const [label, active] of [['Active', true], ['Inactive', false], ['Updates', null]]) {
      const tab = findManageWPTab(label);
      if (!tab) { missing.push(label); continue; }
      await openTabAndWait(tab);

      for (const p of readManageWPList()) {
        const prev = byKey.get(keyOf(p)) || {};
        byKey.set(keyOf(p), {
          name: p.name,
          slug: p.slug || prev.slug || null,
          active: active !== null ? active : (prev.active ?? null),
          current: p.current || prev.current || null,
          updateAvailable: label === 'Updates' ? !!p.next : !!prev.updateAvailable,
          new: p.next || prev.new || null,
        });
      }
    }

    if (missing.length) console.warn('[WP Plugin Extractor] tabs not found:', missing.join(', '));
    return Array.from(byKey.values());
  }

  // --- dispatch ---

  async function getJson() {
    const ctx = getPageContext();
    let data;

    if (ctx === 'wp-admin') {
      data = extractWpAdminPlugins();
    } else if (ctx === 'managewp-dashboard') {
      data = extractManageWPDashboard();
    } else if (ctx === 'managewp-manage') {
      data = await extractManageWPManage();
    } else {
      alert(
        "This isn't a page this script can read.\n\n" +
        'For a single WordPress site: visit its wp-admin Plugins page.\n\n' +
        "For ManageWP: visit the site's Dashboard tab " +
        '(e.g. https://orion.managewp.com/dashboard/site/9887429/dashboard) or its ' +
        'Plugins > Manage tab ' +
        '(e.g. https://orion.managewp.com/dashboard/site/22046915/component/plugins/manage).'
      );
      return null;
    }

    if (!data.length) {
      alert('No plugins found on this page.');
      return null;
    }
    return JSON.stringify(data, null, 2);
  }

  // Log full stack so "undefined is not a function" shows the real line.
  // Callback itself returns nothing: Violentmonkey on Firefox chokes if a menu
  // callback returns a Promise ("undefined is not a function" in injected.js).
  function guarded(fn) {
    return () => {
      (async () => {
        try {
          await fn();
        } catch (e) {
          console.error('[WP Plugin Extractor]', e);
          alert('Extractor failed: ' + e.message + '\n(see console for stack)');
        }
      })();
    };
  }

  // GM_setClipboard can be missing depending on the userscript manager; fall back to the web API.
  async function copyText(text) {
    if (typeof GM_setClipboard === 'function') {
      GM_setClipboard(text, 'text');
    } else {
      await navigator.clipboard.writeText(text);
    }
  }

  GM_registerMenuCommand('📋 Copy plugin list (JSON)', guarded(async () => {
    const json = await getJson();
    if (!json) return;
    await copyText(json);
    const data = JSON.parse(json);
    const updates = data.filter(p => p.updateAvailable).length;
    alert(`Copied ${data.length} plugin(s) to clipboard (${updates} with updates available).`);
  }));

  GM_registerMenuCommand('💾 Export plugin list (JSON file)', guarded(async () => {
    const json = await getJson();
    if (!json) return;
    const blob = new Blob([json], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `${getSiteName()}-plugin-updates-${new Date().toISOString().slice(0, 10)}.json`;
    document.body.appendChild(a);
    a.click();
    a.remove();
    URL.revokeObjectURL(url);
  }));
})();
