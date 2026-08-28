/* Funzioni di utilita' condivise dal front-end (nessuna dipendenza da
   librerie esterne: solo JavaScript "vanilla", come richiesto dalla
   traccia). */

/** Effettua l'escape di una stringa prima di inserirla in un template HTML.
 * Fondamentale: i dati (nomi di pazienti, note, ecc.) arrivano dall'API come
 * testo qualunque, e qui vengono composti a mano in stringhe HTML — senza
 * questo escape, un nome contenente "<" o "&" romperebbe il markup (o, dati
 * pubblici a parte, aprirebbe a XSS). */
function esc(value) {
  if (value === null || value === undefined) return "";
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

/** Come esc(), ma restituisce un trattino per valori assenti (utile nelle
 * schede di dettaglio, dove un campo vuoto va mostrato come "-" invece che
 * come stringa vuota). */
function escOr(value, fallback = "-") {
  if (value === null || value === undefined || value === "") return esc(fallback);
  return esc(value);
}

function fmtNum(value, decimals = 1) {
  if (value === null || value === undefined || value === "") return "-";
  const n = Number(value);
  if (Number.isNaN(n)) return "-";
  return n.toLocaleString("it-IT", { minimumFractionDigits: 0, maximumFractionDigits: decimals });
}

function fmtDate(value) {
  if (!value) return "-";
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return esc(value);
  return d.toLocaleDateString("it-IT", { year: "numeric", month: "long", day: "numeric" });
}

function fmtDateTime(value) {
  if (!value) return "-";
  const d = new Date(value.replace(" ", "T"));
  if (Number.isNaN(d.getTime())) return esc(value);
  return d.toLocaleString("it-IT", { dateStyle: "medium", timeStyle: "short" });
}

/** Converte un valore ISO ("2026-05-15T10:00:00" o simile) nel formato
 * richiesto da <input type="datetime-local">. */
function toDatetimeLocal(value) {
  if (!value) return "";
  return value.replace(" ", "T").slice(0, 16);
}

function qs(selector, root = document) {
  return root.querySelector(selector);
}

function qsa(selector, root = document) {
  return Array.from(root.querySelectorAll(selector));
}

function h(strings, ...values) {
  return strings.reduce((out, s, i) => out + s + (i < values.length ? values[i] : ""), "");
}

/** Legge tutti i campi di un <form> come oggetto piano, pronto per essere
 * mandato come JSON. I checkbox diventano booleani; i campi vuoti diventano
 * null (cosi' l'API li tratta come "assente" per i campi non obbligatori). */
function formToJson(form) {
  const data = {};
  for (const el of form.elements) {
    if (!el.name || el.disabled) continue;
    if (el.type === "checkbox") {
      data[el.name] = el.checked;
    } else if (el.type === "radio") {
      if (el.checked) data[el.name] = el.value;
    } else {
      data[el.name] = el.value === "" ? null : el.value;
    }
  }
  return data;
}

/** Mostra i messaggi di errore restituiti da validate_fields() (vedi
 * validation.py) sopra un form, riusando lo stile .flash-error gia'
 * definito nel foglio di stile originale. */
function renderFormErrors(details) {
  if (!details || !details.length) return "";
  return h`<ul class="flash-list"><li class="flash flash-error">${details.map(esc).join("<br>")}</li></ul>`;
}

function flash(message, kind = "success") {
  const container = qs("#flash-container");
  if (!container) return;
  const div = document.createElement("div");
  div.className = `flash flash-${kind}`;
  div.style.marginBottom = "12px";
  div.textContent = message;
  container.prepend(div);
  setTimeout(() => div.remove(), 5000);
}

function paginationHtml(meta, hrefFor) {
  if (!meta || meta.total_pages <= 1) return "";
  const prevDisabled = meta.page <= 1;
  const nextDisabled = meta.page >= meta.total_pages;
  return h`
    <div class="pagination">
      ${prevDisabled ? `<span>&larr; Precedente</span>` : `<a href="${hrefFor(meta.page - 1)}">&larr; Precedente</a>`}
      <span>Pagina ${meta.page} di ${meta.total_pages} &middot; ${meta.total} risultati</span>
      ${nextDisabled ? `<span>Successiva &rarr;</span>` : `<a href="${hrefFor(meta.page + 1)}">Successiva &rarr;</a>`}
    </div>`;
}
