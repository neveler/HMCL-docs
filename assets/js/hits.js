(() => {
  window.hits = (tag) => {
    const pageTitle = document.getElementById("page-title");
    if (pageTitle === null) return;
    const header = pageTitle.parentElement;
    let meta = header.getElementsByClassName("page__meta")[0];
    if (meta === null) {
      meta = document.createElement("div");
      element.className = "page__meta";
      header.append(element);
    }
    if (meta.children.length > 0) {
      const sep = document.createElement("span");
      sep.className = "page__meta-sep";
      meta.append(sep);
    }
    const hits = document.createElement("span");
    hits.className = "page__meta-hits";
    const hitsIcon = document.createElement("i");
    hitsIcon.className = "far fa-eye";
    const todayHits = document.createElement("span");
    todayHits.textContent = "-";
    const totalHits = document.createElement("span");
    totalHits.textContent = "-";
    hits.append(hitsIcon, " ", todayHits, " / ", totalHits);
    meta.append(hits);
    const hitsUrl = new URL("https://hits.zkitefly.eu.org");
    hitsUrl.searchParams.set("tag", tag);
    fetch(hitsUrl, { method: "HEAD" }).then((response) => {
      if (response.status !== 200) return;
      const { headers } = response;
      const total = headers.get("X-Total-Hits");
      const today = headers.get("X-Today-Hits");
      if (total !== null && today !== null) {
        totalHits.textContent = total;
        todayHits.textContent = today;
      }
    });
  }
})();
