// ==UserScript==
// @name         WP Plugin Update Extractor
// @namespace    wpc-tools
// @version      3.0
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

  function clickUpdatesTabAndWait() {
    return new Promise((resolve, reject) => {
      const tabs = document.querySelectorAll('.tab-button');
      let target = null;
      tabs.forEach(t => {
        if ((t.getAttribute('uib-tooltip') || '').trim() === 'Updates') target = t;
      });
      if (!target) {
        reject(new Error('Could not find the "Updates" tab on this page. Make sure you\'re on the site\'s Plugins > Manage page in ManageWP.'));
        return;
      }
      target.click();

      let tries = 0;
      const maxTries = 40; // ~4s
      const check = () => {
        tries++;
        if (document.querySelector('.list-item-content a[slug][from-version][to-version]') || tries >= maxTries) {
          resolve();
          return;
        }
        setTimeout(check, 100);
      };
      setTimeout(check, 150);
    });
  }

  function extractManageWPManage() {
    const results = [];
    document.querySelectorAll('.list-item-content').forEach(item => {
      const link = item.querySelector('a[slug][from-version][to-version]');
      if (!link) return; // no update flagged for this plugin on the Updates tab

      const nameEl = item.querySelector('.component-name');
      if (!nameEl) return;
      // .component-name's first text node is the plugin name; later child elements are icons (vulnerability/favorite)
      const nameNode = nameEl.childNodes[0];
      const name = nameNode ? nameNode.textContent.trim() : nameEl.textContent.trim();
      if (!name) return;

      const slug = link.getAttribute('slug');
      const current = link.getAttribute('from-version');
      const next = link.getAttribute('to-version');

      // active/inactive isn't exposed on this tab's markup — leave null rather than guess
      results.push({ name, slug, active: null, current, updateAvailable: true, new: next });
    });
    return results;
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
      try {
        await clickUpdatesTabAndWait();
      } catch (e) {
        alert(e.message);
        return null;
      }
      data = extractManageWPManage();
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

  GM_registerMenuCommand('📋 Copy plugin list (JSON)', async () => {
    const json = await getJson();
    if (!json) return;
    GM_setClipboard(json, 'text');
    const data = JSON.parse(json);
    const updates = data.filter(p => p.updateAvailable).length;
    alert(`Copied ${data.length} plugin(s) to clipboard (${updates} with updates available).`);
  });

  GM_registerMenuCommand('💾 Export plugin list (JSON file)', async () => {
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
  });
})();
