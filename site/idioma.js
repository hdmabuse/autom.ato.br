// ============================================================
// idioma.js: troca entre portugues, espanhol e ingles.
//
// Nas paginas, cada texto aparece tres vezes, com as classes
// i-pt, i-es e i-en. O CSS mostra so a do idioma ativo, lendo
// o atributo data-idioma da tag <html>.
//
// Ordem de escolha do idioma:
//   1. ?lang=pt|es|en no endereco
//   2. a escolha anterior, guardada no navegador
//   3. o idioma do navegador
//   4. portugues
//
// Textos gerados por JavaScript usam window.idioma.t({pt, es, en}).
// Quem precisa reagir a troca escuta o evento "idioma" no document.
// ============================================================
(function () {
  const IDIOMAS = ["pt", "es", "en"];
  const LANG_HTML = { pt: "pt-BR", es: "es", en: "en" };
  const CHAVE = "autom.ato.br:idioma";

  function lerGuardado() {
    try { return localStorage.getItem(CHAVE); } catch (e) { return null; }
  }
  function guardar(i) {
    try { localStorage.setItem(CHAVE, i); } catch (e) { /* sem armazenamento */ }
  }

  function inicial() {
    const param = new URLSearchParams(location.search).get("lang");
    if (IDIOMAS.includes(param)) return param;
    const guardado = lerGuardado();
    if (IDIOMAS.includes(guardado)) return guardado;
    const nav = (navigator.languages || [navigator.language || "pt"]);
    for (const l of nav) {
      const base = String(l).slice(0, 2).toLowerCase();
      if (IDIOMAS.includes(base)) return base;
    }
    return "pt";
  }

  let atual = inicial();

  function aplica(i) {
    atual = i;
    const html = document.documentElement;
    html.dataset.idioma = i;
    html.lang = LANG_HTML[i];

    // Titulo da aba: <title data-pt="..." data-es="..." data-en="...">
    const titulo = document.querySelector("title");
    if (titulo && titulo.dataset[i]) titulo.textContent = titulo.dataset[i];

    // Atributos traduzidos: data-aria-pt, data-aria-es, data-aria-en
    document.querySelectorAll("[data-aria-pt]").forEach((el) => {
      const v = el.getAttribute("data-aria-" + i);
      if (v) el.setAttribute("aria-label", v);
    });

    document.querySelectorAll("[data-escolhe-idioma]").forEach((b) => {
      b.setAttribute("aria-pressed", String(b.dataset.escolheIdioma === i));
    });

    document.dispatchEvent(new CustomEvent("idioma", { detail: i }));
  }

  window.idioma = {
    get atual() { return atual; },
    t(textos) { return textos[atual] || textos.pt; },
    muda(i) {
      if (!IDIOMAS.includes(i)) return;
      guardar(i);
      aplica(i);
    }
  };

  // Aplica antes do primeiro desenho, para nao piscar.
  document.documentElement.dataset.idioma = atual;
  document.documentElement.lang = LANG_HTML[atual];

  document.addEventListener("DOMContentLoaded", () => {
    document.querySelectorAll("[data-escolhe-idioma]").forEach((b) => {
      b.addEventListener("click", () => window.idioma.muda(b.dataset.escolheIdioma));
    });
    aplica(atual);
  });
})();
