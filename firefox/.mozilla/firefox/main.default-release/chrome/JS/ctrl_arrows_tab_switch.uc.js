(() => {
  const MSG_SWITCH = "CustomNav:SwitchTab";

  // 1. CONTENT PROCESS
  const contentCode = function() {
    // Hàm tìm phần tử thực sự đang active xuyên qua iframe và shadow DOM
    function getDeepActiveElement(doc) {
      let active = doc?.activeElement;
      while (active) {
        if (active.shadowRoot && active.shadowRoot.activeElement) {
          active = active.shadowRoot.activeElement;
        } else if (active.tagName === "IFRAME" || active.tagName === "FRAME") {
          try {
            const subDoc = active.contentDocument || active.contentWindow?.document;
            if (subDoc && subDoc.activeElement && subDoc.activeElement !== active) {
              active = subDoc.activeElement;
            } else {
              break;
            }
          } catch (err) {
            // Trường hợp cross-origin iframe không truy cập được contentDocument
            break;
          }
        } else {
          break;
        }
      }
      return active;
    }

    addEventListener("keydown", (e) => {
      if (!e.ctrlKey || e.altKey || e.shiftKey) return;
      if (e.key !== "ArrowLeft" && e.key !== "ArrowRight") return;

      // Ưu tiên e.target, nếu chưa rõ thì duyệt sâu từ document
      let el = e.target;
      if (!el || el === content.document.body || el.tagName === "IFRAME") {
        el = getDeepActiveElement(content.document);
      }

      const isInput = el && (
        el.tagName === "INPUT" ||
        el.tagName === "TEXTAREA" ||
        el.isContentEditable ||
        el.getAttribute?.("contenteditable") === "true"
      );

      const text = isInput ? (el.value || el.textContent || "") : "";

      // Đang focus trong ô nhập và CÓ text -> để mặc định nhảy từ, không chuyển tab
      if (isInput && text.trim() !== "") {
        return;
      }

      // Không có input hoặc text rỗng -> chặn sự kiện và chuyển tab
      e.preventDefault();
      e.stopPropagation();

      sendAsyncMessage("CustomNav:SwitchTab", {
        direction: e.key === "ArrowLeft" ? -1 : 1
      });
    }, true); // Dùng capture phase để tóm sự kiện sớm nhất
  };

  const frameScriptURI = "data:application/javascript," + encodeURIComponent(`(${contentCode})();`);
  Services.mm.loadFrameScript(frameScriptURI, true);

  // 2. PARENT PROCESS
  Services.mm.addMessageListener(MSG_SWITCH, (msg) => {
    gBrowser.tabContainer.advanceSelectedTab(msg.data.direction, true);
  });

  // 3. PARENT PROCESS: Xử lý Urlbar
  window.addEventListener("keydown", (e) => {
    if (!e.ctrlKey || e.altKey || e.shiftKey) return;
    if (e.key !== "ArrowLeft" && e.key !== "ArrowRight") return;

    const focused = document.activeElement;
    const isUrlbar = focused && (
      focused.id === "urlbar-input" ||
      focused.tagName === "input" ||
      focused.getAttribute?.("focused") === "true"
    );

    if (isUrlbar) {
      const val = focused.value || "";
      if (val.trim() !== "") return;

      e.preventDefault();
      e.stopPropagation();
      gBrowser.tabContainer.advanceSelectedTab(e.key === "ArrowLeft" ? -1 : 1, true);
    }
  }, true);
})();
