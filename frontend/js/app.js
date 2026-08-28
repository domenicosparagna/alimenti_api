/* Guscio dell'applicazione: router basato su hash (#/...), intestazione con
 * stato di login, e il "collante" fra i renderer di pagina (pages.js) e il
 * DOM. Nessun framework: la SPA e' tenuta volutamente semplice, in linea
 * con "qualsiasi framework va bene" della traccia — qui la scelta e'
 * "nessun framework", per restare a HTML/CSS/JS puri.
 */

const AppState = { user: null };

const NAV_ITEMS = [
  { href: "#/", label: "Home" },
  { href: "#/alimenti", label: "Alimenti" },
  { href: "#/larn", label: "LARN" },
  { href: "#/ricette", label: "Ricette" },
  { href: "#/smartfood", label: "Smartfood" },
  { href: "#/pazienti", label: "Pazienti" },
  { href: "#/appuntamenti", label: "Agenda" },
];

function renderHeader() {
  const path = currentPath();
  const navHtml = NAV_ITEMS.map((item) => {
    const active = item.href === "#/" ? path === "/" : path.startsWith(item.href.slice(1));
    return `<a href="${item.href}" class="${active ? "active" : ""}">${esc(item.label)}</a>`;
  }).join("");

  const authHtml = AppState.user
    ? h`<span class="auth-status">Ciao, <strong>${esc(AppState.user)}</strong></span>
        <button class="btn btn-outline btn-sm" id="logout-btn" type="button">Esci</button>`
    : `<a class="btn btn-accent btn-sm" href="#/login">Accedi</a>`;

  qs("#site-header-inner").innerHTML = h`
    <a class="brand" href="#/">
      <span class="brand__mark">API</span>
      <span>
        <span class="brand__title">Registro Alimenti</span><br>
        <span class="brand__subtitle">Front-end HTML/CSS/JS &middot; REST API</span>
      </span>
    </a>
    <div class="header-actions">${authHtml}</div>`;

  qs("#site-nav-inner").innerHTML = navHtml;

  const logoutBtn = qs("#logout-btn");
  if (logoutBtn) {
    logoutBtn.addEventListener("click", async () => {
      await Api.auth.logout();
      AppState.user = null;
      renderHeader();
      flash("Sessione terminata.");
      navigate("#/");
    });
  }
}

function currentPath() {
  const hash = location.hash || "#/";
  const [path] = hash.slice(1).split("?");
  return path || "/";
}

function currentQuery() {
  const hash = location.hash || "#/";
  const [, query] = hash.slice(1).split("?");
  return new URLSearchParams(query || "");
}

function navigate(hash) {
  location.hash = hash;
}

function setContent(html) {
  qs("#content").innerHTML = html;
  window.scrollTo({ top: 0 });
}

function showLoading(label = "Caricamento...") {
  setContent(h`<p class="loading">${esc(label)}</p>`);
}

function showAppError(err) {
  console.error(err);
  const message = err instanceof ApiError ? err.message : "Errore imprevisto.";
  setContent(h`<p class="app-error">${esc(message)}</p>`);
}

/** Esegue un renderer di pagina "al sicuro": mostra un loader, intercetta
 * ApiError 401 (redirige al login) e qualunque altro errore (mostra un
 * messaggio invece di lasciare la pagina bianca). */
async function runPage(renderFn, params) {
  showLoading();
  try {
    await renderFn(params);
  } catch (err) {
    if (err instanceof ApiError && err.status === 401) {
      flash("Devi accedere per vedere questa pagina.", "error");
      navigate("#/login");
      return;
    }
    showAppError(err);
  }
}

// ---------------------------------------------------------------------
// Router: tabella di rotte come liste di segmenti. ":x" cattura un
// parametro; i segmenti letterali (es. "nuovo") hanno sempre precedenza
// sui parametri quando entrambi potrebbero corrispondere.
// ---------------------------------------------------------------------
const ROUTES = [
  { segs: [], page: Pages.home },
  { segs: ["login"], page: Pages.login },

  { segs: ["alimenti"], page: Pages.alimentiList },
  { segs: ["alimenti", "nuovo"], page: Pages.alimentoForm },
  { segs: ["alimenti", ":id", "modifica"], page: Pages.alimentoForm },
  { segs: ["alimenti", ":id"], page: Pages.alimentoDetail },

  { segs: ["larn"], page: Pages.larnMenu },
  { segs: ["larn", ":table", "nuovo"], page: Pages.larnForm },
  { segs: ["larn", ":table", ":id", "modifica"], page: Pages.larnForm },
  { segs: ["larn", ":table", ":id"], page: Pages.larnDetail },
  { segs: ["larn", ":table"], page: Pages.larnList },

  { segs: ["ricette"], page: Pages.ricetteList },
  { segs: ["ricette", "nuova"], page: Pages.ricettaForm },
  { segs: ["ricette", ":id", "modifica"], page: Pages.ricettaForm },
  { segs: ["ricette", ":id"], page: Pages.ricettaDetail },

  { segs: ["smartfood"], page: Pages.smartfoodMenu },
  { segs: ["smartfood", "nuovo"], page: Pages.smartfoodForm },
  { segs: ["smartfood", ":id", "modifica"], page: Pages.smartfoodForm },
  { segs: ["smartfood", ":id"], page: Pages.smartfoodDetail },

  { segs: ["pazienti"], page: Pages.pazientiList },
  { segs: ["pazienti", "nuovo"], page: Pages.pazienteForm },
  { segs: ["pazienti", ":id", "modifica"], page: Pages.pazienteForm },
  { segs: ["pazienti", ":id", "piani", "nuovo"], page: Pages.pianoForm },
  { segs: ["pazienti", ":id", "piani", ":pianoId", "giorni", ":giorno"], page: Pages.giornoDetail },
  { segs: ["pazienti", ":id", "piani", ":pianoId"], page: Pages.pianoDetail },
  { segs: ["pazienti", ":id"], page: Pages.pazienteDetail },

  { segs: ["appuntamenti"], page: Pages.agendaList },
  { segs: ["appuntamenti", "nuovo"], page: Pages.appuntamentoForm },
  { segs: ["appuntamenti", ":id", "modifica"], page: Pages.appuntamentoForm },
];

function matchRoute(path) {
  const parts = path.split("/").filter(Boolean);
  for (const route of ROUTES) {
    if (route.segs.length !== parts.length) continue;
    const params = {};
    let ok = true;
    for (let i = 0; i < parts.length; i++) {
      const seg = route.segs[i];
      if (seg.startsWith(":")) {
        params[seg.slice(1)] = decodeURIComponent(parts[i]);
      } else if (seg !== parts[i]) {
        ok = false;
        break;
      }
    }
    if (ok) return { page: route.page, params };
  }
  return null;
}

function router() {
  renderHeader();
  const path = currentPath();
  const match = matchRoute(path);
  if (!match) {
    setContent(h`<div class="empty-state"><h2>Pagina non trovata</h2><p><a href="#/">Torna alla home</a></p></div>`);
    return;
  }
  runPage(match.page, { ...match.params, query: currentQuery() });
}

async function bootstrap() {
  try {
    const me = await Api.auth.me();
    AppState.user = me.logged_in ? me.username : null;
  } catch (e) {
    AppState.user = null;
  }
  window.addEventListener("hashchange", router);
  router();
}

document.addEventListener("DOMContentLoaded", bootstrap);
