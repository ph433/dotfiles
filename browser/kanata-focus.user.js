// ==UserScript==
// @name         Kanata Browser Bridge
// @namespace    https://github.com/ph433/kanata_bridge
// @version      1.0.0
// @description  Gửi trạng thái focus ô input sang Kanata qua WebSocket bridge
// @match        *://*/*
// @run-at       document-start
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    const WS_URL = 'ws://127.0.0.1:9999';
    let ws = null;
    let currentMode = null;
    let reconnectTimeout = null;

    // Khởi tạo kết nối WebSocket với cơ chế retry tự động
    function initWebSocket() {
        if (ws && (ws.readyState === WebSocket.CONNECTING || ws.readyState === WebSocket.OPEN)) {
            return;
        }

        ws = new WebSocket(WS_URL);

        ws.onopen = () => {
            console.log('%c[Kanata Bridge] Đã kết nối WebSocket thành công', 'color: #00ff00;');
            // Đồng bộ trạng thái hiện tại ngay sau khi vừa kết nối xong
            if (currentMode) {
                ws.send(currentMode);
            }
        };

        ws.onclose = () => {
            // Tự động kết nối lại sau 2 giây nếu server bridge tắt hoặc restart
            clearTimeout(reconnectTimeout);
            reconnectTimeout = setTimeout(initWebSocket, 2000);
        };

        ws.onerror = () => {
            if (ws) ws.close();
        };
    }

    function sendLayer(mode) {
        if (ws && ws.readyState === WebSocket.OPEN) {
            ws.send(mode);
        }
    }

    // Kiểm tra xem element có phải là nơi nhập văn bản hay không
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

        sendLayer(mode);
    }

    // Lắng nghe sự kiện focus vào ô (click chuột, Tab phím, autofocus)
    window.addEventListener('focusin', (e) => evaluateFocus(e.target), true);

    // Lắng nghe sự kiện rời khỏi ô (blur, click ra ngoài)
    window.addEventListener('focusout', () => {
        setTimeout(() => evaluateFocus(document.activeElement), 0);
    }, true);

    // Đề phòng trường hợp chuyển qua tab khác rồi quay lại
    window.addEventListener('focus', () => evaluateFocus(document.activeElement));

    // Khởi tạo kết nối
    initWebSocket();
    evaluateFocus(document.activeElement);
})();
