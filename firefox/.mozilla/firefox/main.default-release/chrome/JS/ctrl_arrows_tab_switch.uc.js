// ==UserScript==
// @name                 Ctrl + Arrows Tab Switcher
// @version              2.2
// @description          Reliably ignore input/textarea across all content processes
// @author               phuong
// ==/UserScript==

(function() {
  function isEditing(win) {
    // 1. Kiểm tra các ô nhập ở tầng UI Firefox (URL bar, findbar, popup...)
    const uiFocused = win.document.commandDispatcher?.focusedElement || win.document.activeElement;
    if (uiFocused) {
      const tag = uiFocused.tagName?.toUpperCase();
      if (tag === "INPUT" || tag === "TEXTAREA" || uiFocused.isContentEditable) {
        return true;
      }
      // Nếu đang đứng ở thanh URL (urlbar-input)
      if (uiFocused.classList && (uiFocused.classList.contains("urlbar-input") || uiFocused.id === "urlbar-input")) {
        return true;
      }
    }

    // 2. Kiểm tra tiến trình trang web thông qua nsIEditingSession/command controller
    // Khi đang trỏ con trỏ vào ô text/input trên web, Firefox kích hoạt bộ command "cmd_cut" hoặc editing session
    try {
      const controller = win.gBrowser?.selectedBrowser?.docShell?.editingSession;
      if (controller) return true;
    } catch (e) {}

    // 3. Kiểm tra trạng thái focus window con (content window)
    const focusedWindow = win.document.commandDispatcher?.focusedWindow;
    if (focusedWindow && focusedWindow !== win) {
      try {
        const active = focusedWindow.document?.activeElement;
        if (active) {
          const tag = active.tagName?.toUpperCase();
          if (tag === "INPUT" || tag === "TEXTAREA" || active.isContentEditable) {
            return true;
          }
        }
      } catch (e) {}
    }

    // 4. Fallback an toàn: nếu lệnh copy/cut/paste của text đang khả dụng ở trạng thái edit
    try {
      const cmdController = win.document.commandDispatcher?.getControllerForCommand("cmd_deleteCharBackward");
      if (cmdController && cmdController.isCommandEnabled("cmd_deleteCharBackward")) {
        return true;
      }
    } catch (e) {}

    return false;
  }

  function init(win) {
    if (!win.gBrowser) return;

    win.addEventListener("keydown", (event) => {
      if (!event.ctrlKey || event.altKey || event.shiftKey || event.metaKey) return;
      if (event.key !== "ArrowLeft" && event.key !== "ArrowRight") return;

      // Đang nằm trong vùng soạn thảo văn bản
      if (isEditing(win)) return;

      event.preventDefault();
      event.stopPropagation();

      if (event.key === "ArrowRight") {
        win.gBrowser.tabContainer.advanceSelectedTab(1, true);
      } else if (event.key === "ArrowLeft") {
        win.gBrowser.tabContainer.advanceSelectedTab(-1, true);
      }
    }, true);
  }

  init(window);

  if (typeof _ucUtils !== "undefined") {
    _ucUtils.windowData({
      id: "ctrl-arrows-tab-switcher",
      type: "browser",
      load: win => init(win)
    });
  }
})();
