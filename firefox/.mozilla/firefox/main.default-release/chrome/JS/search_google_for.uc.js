window.addEventListener(
  "keydown",
  async (e) => {
    if (e.key === "Insert") {
      let target = e.target;
      if (
        target.localName === "input" ||
        target.localName === "textarea" ||
        target.id === "urlbar-input"
      ) {
        return;
      }

      // Chặn ngay lập tức trong chu kỳ đồng bộ của pha capture
      e.preventDefault();
      e.stopPropagation();

      // Sau đó mới xử lý bất đồng bộ
      let res = await gBrowser.selectedBrowser.finder.getInitialSelection();
      let text = res?.selectedText?.trim();
      if (!text) {
        gBrowser.removeCurrentTab();
        return;
      }

      openTrustedLinkIn(
        "https://www.google.com/search?q=" + encodeURIComponent(text),
        "tab"
      );
    }
  },
  { capture: true }
);
