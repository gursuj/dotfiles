// ==UserScript==
// @name         cPanel PHP Extensions Extractor
// @namespace    wpc-tools
// @version      1.0
// @description  Extract names of checked PHP extensions (CloudLinux Select PHP Version) to console, clipboard or file
// @match        *://*/cpsess*/*/lveversion/*
// @grant        GM_registerMenuCommand
// @grant        GM_setClipboard
// ==/UserScript==

(function () {
  'use strict';

  const CARD = '.lvemanager-extensions-card';
  const ITEM = '.lvemanager-setting-item';

  // Name = text node directly inside the item. Checkbox/label/spinner are child elements.
  function itemName(item) {
    return Array.from(item.childNodes)
      .filter(n => n.nodeType === 3)
      .map(n => n.textContent.trim())
      .join(' ')
      .trim();
  }

  function getChecked() {
    const card = document.querySelector(CARD);
    if (!card) return null;
    const names = [];
    card.querySelectorAll(ITEM).forEach(item => {
      const label = item.querySelector('label[role="checkbox"]');
      if (!label || label.getAttribute('aria-checked') !== 'true') return;
      const name = itemName(item);
      if (name) names.push(name);
    });
    return names;
  }

  function guarded(fn) {
    return () => {
      try {
        const out = fn();
        if (out && typeof out.catch === 'function') out.catch(report);
      } catch (e) {
        report(e);
      }
    };
  }

  function report(e) {
    console.error('[PHP Extensions Extractor]', e);
    alert('Extractor failed: ' + e.message + '\n(see console for stack)');
  }

  function getNames() {
    const names = getChecked();
    if (names === null) {
      alert(`Can't find ${CARD} on this page.`);
      return null;
    }
    if (!names.length) {
      alert('No checked extensions found.');
      return null;
    }
    return names;
  }

  GM_registerMenuCommand('🖥️ Log checked extensions (console)', guarded(() => {
    const names = getNames();
    if (!names) return;
    console.log(`[PHP Extensions Extractor] ${names.length} checked:\n` + names.join('\n'));
    console.log(names);
  }));

  GM_registerMenuCommand('📋 Copy checked extensions', guarded(async () => {
    const names = getNames();
    if (!names) return;
    const text = names.join('\n');
    if (typeof GM_setClipboard === 'function') GM_setClipboard(text, 'text');
    else await navigator.clipboard.writeText(text);
    alert(`Copied ${names.length} extension(s) to clipboard.`);
  }));

  GM_registerMenuCommand('💾 Export checked extensions (txt file)', guarded(() => {
    const names = getNames();
    if (!names) return;
    const blob = new Blob([names.join('\n') + '\n'], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `${location.hostname}-php-extensions-${new Date().toISOString().slice(0, 10)}.txt`;
    document.body.appendChild(a);
    a.click();
    a.remove();
    URL.revokeObjectURL(url);
  }));
})();
