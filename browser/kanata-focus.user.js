// ==UserScript==
// @name         Kanata Browser Bridge
// @namespace    https://github.com/ph433/kanata_bridge
// @version      1.2.0
// @match        *://*/*
// @run-at       document-start
// @grant        GM_xmlhttpRequest
// @inject-into  content
// @connect      127.0.0.1
// ==/UserScript==

(function() {
    'use strict';

    const BRIDGE_URL = 'http://127.0.0.1:9999/';
    let currentMode = null;

    function sendLayer(mode) {
        GM_xmlhttpRequest({
            method: 'POST',
            url: BRIDGE_URL + mode,
            timeout: 300,
            onload: () => {},
            onerror: () => {},
            ontimeout: () => {}
        });
    }

    function isTextInput(el) {
        if (!el) return false;

        // 1. Kiểm tra thuộc tính contenteditable (Gemini, Facebook, Docs)
        if (el.isContentEditable || el.getAttribute('contenteditable') === 'true') return true;

        // 2. Kiểm tra các thẻ chuẩn
        const tag = el.tagName ? el.tagName.toLowerCase() : '';
        if (tag === 'textarea') return true;
        if (tag === 'input') {
            const type = (el.getAttribute('type') || 'text').toLowerCase();
            return ['text', 'search', 'password', 'email', 'url', 'tel', 'number'].includes(type);
        }

        // 3. Kiểm tra các Custom Element / ARIA Role của Gemini
        const role = el.getAttribute('role');
        if (role === 'textbox' || role === 'combobox') return true;
        if (tag === 'rich-textarea' || el.closest('rich-textarea')) return true;

        // 4. Nếu click vào thẻ con nằm bên trong một khối soạn thảo
        if (el.closest('[contenteditable="true"]') || el.closest('[role="textbox"]')) return true;

        return false;
    }

    function evaluateFocus(target) {
        const mode = isTextInput(target) ? 'insert' : 'default';
        if (currentMode === mode) return;
        currentMode = mode;

        sendLayer(mode);
    }

    window.addEventListener('focusin', (e) => evaluateFocus(e.target), true);
    window.addEventListener('focusout', () => setTimeout(() => evaluateFocus(document.activeElement), 0), true);
    window.addEventListener('focus', () => evaluateFocus(document.activeElement));

    evaluateFocus(document.activeElement);
})();
