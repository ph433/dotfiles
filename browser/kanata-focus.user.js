// ==UserScript==
// @name         Test Focus Detector
// @match        *://*/*
// @run-at       document-start
// ==/UserScript==

(function() {
    'use strict';

    let currentMode = null;

    function isTextInput(el) {
        if (!el) return false;
        const tag = el.tagName ? el.tagName.toLowerCase() : '';
        if (tag === 'textarea' || el.isContentEditable) return true;
        if (tag === 'input') {
            const type = (el.getAttribute('type') || 'text').toLowerCase();
            return ['text', 'search', 'password', 'email', 'url', 'tel', 'number'].includes(type);
        }
        return false;
    }

    function evaluateFocus(target) {
        const mode = isTextInput(target) ? 'insert' : 'default';
        if (currentMode === mode) return;
        currentMode = mode;

        if (mode === 'insert') {
            console.log('%c[Kanata Test] ĐANG Ở Ô INPUT -> layer: insert', 'color: #00ff00; font-weight: bold;');
        } else {
            console.log('%c[Kanata Test] NGOÀI Ô INPUT -> layer: default', 'color: #ff9900; font-weight: bold;');
        }
    }

    // Lắng nghe khi focus vào element (click chuột, tab, autofocus)
    window.addEventListener('focusin', (e) => evaluateFocus(e.target), true);

    // Lắng nghe khi rời khỏi element
    window.addEventListener('focusout', () => {
        setTimeout(() => evaluateFocus(document.activeElement), 0);
    }, true);

    // Kiểm tra ngay khi vừa nạp trang (đề phòng trang tự autofocus)
    window.addEventListener('DOMContentLoaded', () => evaluateFocus(document.activeElement));
})();
