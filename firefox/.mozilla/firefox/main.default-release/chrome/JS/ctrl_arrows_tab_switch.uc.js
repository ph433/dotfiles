(() => {
  const MSG_SWITCH = "CustomNav:SwitchTab";

  // 1. CONTENT PROCESS: Bắt phím đồng bộ ngay trong trang web
  const contentCode = function() {
    addEventListener("keydown", (e) => {
      if (!e.ctrlKey || e.altKey || e.shiftKey) return;
      if (e.key !== "ArrowLeft" && e.key !== "ArrowRight") return;

      const el = content.document.activeElement;
      const isInput = el && (
        el.tagName === "INPUT" ||
        el.tagName === "TEXTAREA" ||
        el.isContentEditable
      );

      const text = isInput ? (el.value || el.textContent || "") : "";

      // Nếu đang trong input và CÓ chữ -> bỏ qua để trình duyệt nhảy từ bình thường
      if (isInput && text.trim() !== "") {
        return;
      }

      // Nếu không phải input hoặc text rỗng -> chặn phím và yêu cầu Parent chuyển tab
      e.preventDefault();
      e.stopPropagation();

      sendAsyncMessage("CustomNav:SwitchTab", {
        direction: e.key === "ArrowLeft" ? -1 : 1
      });
    }, true);
  };

  const frameScriptURI = "data:application/javascript," + encodeURIComponent(`(${contentCode})();`);
  Services.mm.loadFrameScript(frameScriptURI, true);

  // 2. PARENT PROCESS: Nhận lệnh chuyển tab từ Content
  Services.mm.addMessageListener(MSG_SWITCH, (msg) => {
    gBrowser.tabContainer.advanceSelectedTab(msg.data.direction, true);
  });

  // 3. PARENT PROCESS: Xử lý riêng khi focus nằm ở thanh địa chỉ (Urlbar) của trình duyệt
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
      // Nếu thanh địa chỉ có chữ -> để nguyên cho nhảy từ
      if (val.trim() !== "") return;

      // Thanh địa chỉ rỗng -> chặn và chuyển tab
      e.preventDefault();
      e.stopPropagation();
      gBrowser.tabContainer.advanceSelectedTab(e.key === "ArrowLeft" ? -1 : 1, true);
    }
  }, true);
})();
