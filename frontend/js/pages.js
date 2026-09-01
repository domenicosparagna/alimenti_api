/* Renderer di pagina: una funzione per ogni "schermata" della SPA. Ogni
 * funzione e' async, fa 1+ chiamate a Api.*, costruisce una stringa HTML e
 * la inserisce con setContent(); se la pagina ha un form o azioni,
 * ricollega gli event listener DOPO l'inserimento (l'HTML iniettato con
 * innerHTML non porta con se' i listener). */

const Pages = {};

// =====================================================================
// Helper generici: form e schede di dettaglio guidati dai metadati dei
// campi esposti dall'API (gli stessi registri usati server-side per
// validare: fields.py, larn_fields.py, ricette_fields.py, ...). Un'unica
// implementazione copre i form di Alimento, LARN, Smartfood, Ricetta,
// Paziente e Appuntamento, invece di scriverne uno per tipo.
// =====================================================================

function fieldInputHtml(f, value) {
  let val = value === undefined || value === null || value === "" ? "" : value;
  if (val === "" && f.default !== undefined && f.default !== null) val = f.default;
  const req = f.required ? '<span class="req">*</span>' : "";
  const labelHtml = f.hide_label ? "" : h`<label for="f_${f.name}">${esc(f.label)} ${req}</label>`;

  if (f.type === "bool") {
    return h`<div class="form-field checkbox-field">
      <input type="checkbox" id="f_${f.name}" name="${f.name}" ${val ? "checked" : ""}>
      <label for="f_${f.name}">${esc(f.label)}</label>
    </div>`;
  }

  let control;
  if (f.type === "textarea") {
    control = h`<textarea id="f_${f.name}" name="${f.name}">${esc(val)}</textarea>`;
  } else if (f.type === "select") {
    const labels = f.choice_labels || {};
    const opts = (f.choices || [])
      .map((c) => `<option value="${esc(c)}" ${String(val) === String(c) ? "selected" : ""}>${esc(labels[c] || c)}</option>`)
      .join("");
    control = h`<select id="f_${f.name}" name="${f.name}"><option value="">-</option>${opts}</select>`;
  } else if (f.type === "int") {
    control = h`<input type="number" step="1" id="f_${f.name}" name="${f.name}" value="${esc(val)}">`;
  } else if (f.type === "decimal") {
    control = h`<input type="number" step="0.01" id="f_${f.name}" name="${f.name}" value="${esc(val)}">`;
  } else if (f.type === "date") {
    control = h`<input type="date" id="f_${f.name}" name="${f.name}" value="${esc(val)}">`;
  } else if (f.type === "datetime") {
    control = h`<input type="datetime-local" id="f_${f.name}" name="${f.name}" value="${esc(toDatetimeLocal(val))}">`;
  } else {
    control = h`<input type="text" id="f_${f.name}" name="${f.name}" ${
      f.maxlength ? `maxlength="${f.maxlength}"` : ""
    } value="${esc(val)}">`;
  }
  return h`<div class="form-field">${labelHtml}${control}</div>`;
}

/** `groupsOrFields` puo' essere un elenco piatto di campi, oppure un
 * elenco di sezioni {name|title, fields}: in quel caso ogni sezione
 * diventa un .form-section con il proprio titolo. */
function renderFieldsForm(groupsOrFields, values = {}) {
  if (!groupsOrFields.length) return "";
  const isGrouped = groupsOrFields[0].fields !== undefined;
  const groups = isGrouped ? groupsOrFields : [{ name: null, fields: groupsOrFields }];
  return groups
    .map((g) => {
      const title = g.title || g.name;
      const grid = `<div class="form-grid">${g.fields.map((f) => fieldInputHtml(f, values[f.name])).join("")}</div>`;
      return title ? h`<div class="form-section"><h2>${esc(title)}</h2>${grid}</div>` : grid;
    })
    .join("");
}

/** Scheda di sola lettura per un elenco piatto di campi (usata nelle
 * pagine di dettaglio LARN/Smartfood/Ricetta/Appuntamento). */
function renderDetailGrid(fieldsFlat, data) {
  return h`<div class="detail-grid">
    ${fieldsFlat
      .map((f) => {
        let display;
        const v = data[f.name];
        if (f.type === "bool") display = v ? "Si" : "No";
        else if (f.type === "date") display = v ? fmtDate(v) : null;
        else if (f.type === "datetime") display = v ? fmtDateTime(v) : null;
        else if (typeof v === "number") display = fmtNum(v, 2);
        else display = v;
        const empty = display === null || display === undefined || display === "";
        return h`<div class="detail-item"><span class="k">${esc(f.label)}</span><span class="v ${
          empty ? "empty" : ""
        }">${empty ? "-" : esc(display)}</span></div>`;
      })
      .join("")}
  </div>`;
}

function flatFields(groupsOrFields) {
  if (!groupsOrFields.length) return [];
  if (groupsOrFields[0].fields !== undefined) return groupsOrFields.flatMap((g) => g.fields);
  return groupsOrFields;
}

/** Ricollega un <form data-role="entity-form"> gia' presente nel DOM: alla
 * submit valida via l'API (create o update a seconda di `id`), mostra gli
 * eventuali errori senza perdere i valori inseriti, altrimenti naviga a
 * `hrefAfter(risultato)`. */
function wireEntityForm({ formSelector = "#entity-form", onSave, hrefAfter, successMessage }) {
  const form = qs(formSelector);
  if (!form) return;
  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    const data = formToJson(form);
    const errBox = qs("#form-errors");
    errBox.innerHTML = "";
    const submitBtn = qs('button[type="submit"]', form);
    submitBtn.disabled = true;
    try {
      const result = await onSave(data);
      flash(successMessage, "success");
      navigate(hrefAfter(result));
    } catch (err) {
      if (err instanceof ApiError && err.status === 400) {
        errBox.innerHTML = renderFormErrors(err.details || [err.message]);
        window.scrollTo({ top: 0, behavior: "smooth" });
      } else {
        errBox.innerHTML = renderFormErrors([err.message || "Errore imprevisto."]);
      }
    } finally {
      submitBtn.disabled = false;
    }
  });
}

async function confirmAndDelete(message, deleteFn, hrefAfter) {
  if (!confirm(message)) return;
  try {
    await deleteFn();
    flash("Eliminato.", "success");
    navigate(hrefAfter);
  } catch (err) {
    flash(err.message || "Impossibile eliminare.", "error");
  }
}

// =====================================================================
// Home
// =====================================================================

Pages.home = async function () {
  const [alimenti, ricette] = await Promise.all([
    Api.alimenti.list({ page: 1 }),
    Api.ricette.list({ page: 1 }),
  ]);
  let pazientiCard = "";
  if (AppState.user) {
    try {
      const pazienti = await Api.pazienti.list({ page: 1 });
      pazientiCard = h`<a class="stat-card" href="#/pazienti"><span class="n">${pazienti.total}</span><span class="l">Pazienti</span></a>`;
    } catch (e) {
      /* non loggato o errore: la card resta fuori */
    }
  }

  setContent(h`
    <div class="page-head">
      <div>
        <p class="eyebrow">API REST + front-end HTML/CSS/JS</p>
        <h1>Registro Alimenti</h1>
      </div>
    </div>
    <p>
      Front-end statico che parla esclusivamente con <code>/api/*</code> (nessun HTML generato dal
      server): apri gli strumenti di sviluppo del browser, scheda "Network", per vedere ogni azione
      diventare una chiamata JSON.
    </p>
    <div class="stat-strip">
      <a class="stat-card" href="#/alimenti"><span class="n">${alimenti.total}</span><span class="l">Alimenti</span></a>
      <a class="stat-card" href="#/larn"><span class="n">15</span><span class="l">Tabelle LARN</span></a>
      <a class="stat-card" href="#/ricette"><span class="n">${ricette.total}</span><span class="l">Ricette</span></a>
      <a class="stat-card" href="#/smartfood"><span class="n">4</span><span class="l">Fasce Smartfood</span></a>
      ${pazientiCard}
      <a class="stat-card" href="#/appuntamenti"><span class="n">&rarr;</span><span class="l">Agenda</span></a>
    </div>
    <div class="info-block">${
      AppState.user
        ? "Sei autenticato: puoi creare, modificare ed eliminare in tutte le sezioni."
        : 'Stai navigando come ospite: la consultazione e\' libera, ma creare, modificare o eliminare richiede il login. La sezione Pazienti e Agenda e\' visibile solo dopo l\'accesso.'
    }</div>
  `);
};

// =====================================================================
// Login
// =====================================================================

Pages.login = async function () {
  setContent(h`
    <div class="auth-page">
      <div class="form-section">
        <h2>Accedi</h2>
        <div id="form-errors"></div>
        <form id="login-form">
          <div class="form-grid">
            <div class="form-field">
              <label for="f_username">Utente</label>
              <input type="text" id="f_username" name="username" autocomplete="username" required>
            </div>
            <div class="form-field">
              <label for="f_password">Password</label>
              <input type="password" id="f_password" name="password" autocomplete="current-password" required>
            </div>
          </div>
          <div class="form-actions">
            <button class="btn btn-primary" type="submit">Accedi</button>
          </div>
        </form>
      </div>
    </div>
  `);

  qs("#login-form").addEventListener("submit", async (e) => {
    e.preventDefault();
    const data = formToJson(e.target);
    const errBox = qs("#form-errors");
    try {
      const res = await Api.auth.login(data.username, data.password);
      AppState.user = res.username;
      renderHeader();
      flash(`Benvenuto, ${res.username}.`, "success");
      navigate("#/");
    } catch (err) {
      errBox.innerHTML = renderFormErrors([err.message]);
    }
  });
};

// =====================================================================
// Alimenti
// =====================================================================

Pages.alimentiList = async function (params) {
  const q = params.query.get("q") || "";
  const categoria = params.query.get("categoria") || "";
  const page = Number(params.query.get("page") || 1);

  const [data, categorie] = await Promise.all([
    Api.alimenti.list({ q, categoria, page }),
    Api.alimenti.categorie(),
  ]);

  const hrefFor = (p) => `#/alimenti?${new URLSearchParams({ q, categoria, page: p })}`;

  setContent(h`
    <div class="page-head">
      <div><p class="eyebrow">Composizione alimenti CREA/INRAN</p><h1>Alimenti</h1></div>
      <a class="btn btn-primary" href="#/alimenti/nuovo">+ Nuovo alimento</a>
    </div>

    <form class="search-bar" id="filter-form">
      <div class="field-inline">
        <label for="q">Cerca</label>
        <input type="search" id="q" name="q" value="${esc(q)}" placeholder="Nome o codice...">
      </div>
      <div class="field-inline">
        <label for="categoria">Categoria</label>
        <select id="categoria" name="categoria">
          <option value="">Tutte</option>
          ${categorie.map((c) => `<option value="${esc(c)}" ${c === categoria ? "selected" : ""}>${esc(c)}</option>`).join("")}
        </select>
      </div>
      <button class="btn btn-outline" type="submit">Filtra</button>
    </form>

    <div class="table-wrap">
      <table class="ledger">
        <thead><tr><th>Codice</th><th>Nome</th><th>Categoria</th><th class="num">Kcal</th><th class="num">Proteine g</th><th></th></tr></thead>
        <tbody>
          ${
            data.items.length
              ? data.items
                  .map(
                    (a) => h`<tr>
                <td><span class="code-tag">${esc(a.codice_alimento)}</span></td>
                <td class="food-name"><a href="#/alimenti/${a.id}">${esc(a.nome_alimento)}</a></td>
                <td>${esc(a.categoria)}</td>
                <td class="num">${fmtNum(a.energia_kcal, 0)}</td>
                <td class="num">${fmtNum(a.proteine_g)}</td>
                <td class="row-actions"><a class="btn btn-outline btn-sm" href="#/alimenti/${a.id}">Apri</a></td>
              </tr>`
                  )
                  .join("")
              : `<tr><td colspan="6"><div class="empty-state">Nessun alimento trovato.</div></td></tr>`
          }
        </tbody>
      </table>
    </div>
    ${paginationHtml(data, hrefFor)}
  `);

  qs("#filter-form").addEventListener("submit", (e) => {
    e.preventDefault();
    const fd = formToJson(e.target);
    navigate(`#/alimenti?${new URLSearchParams({ q: fd.q || "", categoria: fd.categoria || "" })}`);
  });
};

Pages.alimentoDetail = async function (params) {
  const [alimento, groups] = await Promise.all([Api.alimenti.get(params.id), Api.alimenti.campi()]);

  setContent(h`
    <p class="breadcrumb"><a href="#/alimenti">&larr; Alimenti</a></p>
    <div class="detail-head">
      <div>
        <h1>${esc(alimento.nome_alimento)}</h1>
        <p class="meta"><span class="code-tag">${esc(alimento.codice_alimento)}</span> &middot; ${esc(alimento.categoria)}</p>
        <div class="badges">
          <span class="badge ${alimento.vegano ? "badge-on" : "badge-off"}">Vegano</span>
          <span class="badge ${alimento.vegetariano ? "badge-on" : "badge-off"}">Vegetariano</span>
          <span class="badge ${alimento.senza_glutine ? "badge-on" : "badge-off"}">Senza glutine</span>
        </div>
      </div>
      ${
        AppState.user
          ? h`<div class="row-actions">
              <a class="btn btn-outline btn-sm" href="#/alimenti/${alimento.id}/modifica">Modifica</a>
              <button class="btn btn-danger btn-sm" id="del-btn" type="button">Elimina</button>
            </div>`
          : ""
      }
    </div>
    ${groups.map((g) => h`<div class="form-section"><h2>${esc(g.name)}</h2>${renderDetailGrid(g.fields, alimento)}</div>`).join("")}
  `);

  const delBtn = qs("#del-btn");
  if (delBtn) {
    delBtn.addEventListener("click", () =>
      confirmAndDelete(`Eliminare "${alimento.nome_alimento}"?`, () => Api.alimenti.remove(alimento.id), "#/alimenti")
    );
  }
};

Pages.alimentoForm = async function (params) {
  const isEdit = Boolean(params.id);
  const groups = await Api.alimenti.campi();
  const values = isEdit ? await Api.alimenti.get(params.id) : {};

  setContent(h`
    <p class="breadcrumb"><a href="#/alimenti">&larr; Alimenti</a></p>
    <div class="page-head"><h1>${isEdit ? "Modifica alimento" : "Nuovo alimento"}</h1></div>
    <div id="form-errors"></div>
    <form id="entity-form">
      ${renderFieldsForm(groups, values)}
      <div class="form-actions">
        <a class="btn btn-outline" href="${isEdit ? `#/alimenti/${params.id}` : "#/alimenti"}">Annulla</a>
        <button class="btn btn-primary" type="submit">Salva</button>
      </div>
    </form>
  `);

  wireEntityForm({
    onSave: (data) => (isEdit ? Api.alimenti.update(params.id, data) : Api.alimenti.create(data)),
    hrefAfter: (result) => `#/alimenti/${result.id}`,
    successMessage: isEdit ? "Alimento aggiornato." : "Alimento creato.",
  });
};

// =====================================================================
// LARN
// =====================================================================

Pages.larnMenu = async function () {
  const tables = await Api.larn.tables();
  setContent(h`
    <div class="page-head">
      <div><p class="eyebrow">Livelli di Assunzione di Riferimento di Nutrienti</p><h1>Tabelle LARN</h1></div>
    </div>
    <div class="larn-grid">
      ${tables
        .map(
          (t) => h`<a class="larn-card" href="#/larn/${t.key}">
            <h2>${esc(t.plural_label)}</h2>
            <p>${esc(t.description || "")}</p>
            <span class="count-tag badge badge-off">${t.total} righe</span>
          </a>`
        )
        .join("")}
    </div>
  `);
};

Pages.larnList = async function (params) {
  const tables = await Api.larn.tables();
  const meta = tables.find((t) => t.key === params.table);
  if (!meta) {
    setContent(`<div class="empty-state"><h2>Tabella LARN sconosciuta</h2><p><a href="#/larn">&larr; Torna al menu</a></p></div>`);
    return;
  }
  const activeFilters = {};
  meta.filters.forEach((col) => {
    activeFilters[col] = params.query.get(col) || "";
  });

  const data = await Api.larn.list(params.table, activeFilters);

  setContent(h`
    <p class="breadcrumb"><a href="#/larn">&larr; Tabelle LARN</a></p>
    <div class="page-head">
      <div><p class="eyebrow">LARN</p><h1>${esc(meta.plural_label)}</h1></div>
      ${AppState.user ? `<a class="btn btn-primary" href="#/larn/${params.table}/nuovo">+ Nuova riga</a>` : ""}
    </div>
    ${
      meta.filters.length
        ? h`<form class="search-bar" id="filter-form">
            ${meta.filters
              .map((col) => {
                const opts = data.filter_options[col] || [];
                return h`<div class="field-inline">
                  <label for="ff_${col}">${esc(col)}</label>
                  <select id="ff_${col}" name="${col}">
                    <option value="">Tutti</option>
                    ${opts.map((o) => `<option value="${esc(o)}" ${o === activeFilters[col] ? "selected" : ""}>${esc(o)}</option>`).join("")}
                  </select>
                </div>`;
              })
              .join("")}
            <button class="btn btn-outline" type="submit">Filtra</button>
          </form>`
        : ""
    }
    <div class="table-wrap">
      <table class="ledger">
        <thead><tr>${meta.list_columns.map((c) => `<th>${esc(c)}</th>`).join("")}<th></th></tr></thead>
        <tbody>
          ${
            data.items.length
              ? data.items
                  .map(
                    (row) => h`<tr>
                ${meta.list_columns.map((c) => `<td>${escOr(row[c])}</td>`).join("")}
                <td class="row-actions"><a class="btn btn-outline btn-sm" href="#/larn/${params.table}/${row.id}">Apri</a></td>
              </tr>`
                  )
                  .join("")
              : `<tr><td colspan="${meta.list_columns.length + 1}"><div class="empty-state">Nessuna riga.</div></td></tr>`
          }
        </tbody>
      </table>
    </div>
  `);

  const filterForm = qs("#filter-form");
  if (filterForm) {
    filterForm.addEventListener("submit", (e) => {
      e.preventDefault();
      const fd = formToJson(e.target);
      const clean = {};
      Object.entries(fd).forEach(([k, v]) => {
        if (v) clean[k] = v;
      });
      navigate(`#/larn/${params.table}?${new URLSearchParams(clean)}`);
    });
  }
};

Pages.larnDetail = async function (params) {
  const tables = await Api.larn.tables();
  const meta = tables.find((t) => t.key === params.table);
  const row = await Api.larn.get(params.table, params.id);

  setContent(h`
    <p class="breadcrumb"><a href="#/larn/${params.table}">&larr; ${esc(meta ? meta.plural_label : params.table)}</a></p>
    <div class="detail-head">
      <div><h1>${esc(meta ? meta.label : "Riga")} #${row.id}</h1></div>
      ${
        AppState.user
          ? h`<div class="row-actions">
              <a class="btn btn-outline btn-sm" href="#/larn/${params.table}/${row.id}/modifica">Modifica</a>
              <button class="btn btn-danger btn-sm" id="del-btn" type="button">Elimina</button>
            </div>`
          : ""
      }
    </div>
    ${renderDetailGrid(meta ? meta.fields : [], row)}
  `);

  const delBtn = qs("#del-btn");
  if (delBtn) {
    delBtn.addEventListener("click", () =>
      confirmAndDelete("Eliminare questa riga?", () => Api.larn.remove(params.table, row.id), `#/larn/${params.table}`)
    );
  }
};

Pages.larnForm = async function (params) {
  const isEdit = Boolean(params.id);
  const tables = await Api.larn.tables();
  const meta = tables.find((t) => t.key === params.table);
  const values = isEdit ? await Api.larn.get(params.table, params.id) : {};

  setContent(h`
    <p class="breadcrumb"><a href="#/larn/${params.table}">&larr; ${esc(meta ? meta.plural_label : params.table)}</a></p>
    <div class="page-head"><h1>${isEdit ? "Modifica riga" : "Nuova riga"} &mdash; ${esc(meta ? meta.label : "")}</h1></div>
    <div id="form-errors"></div>
    <form id="entity-form">
      ${renderFieldsForm(meta ? meta.fields : [], values)}
      <div class="form-actions">
        <a class="btn btn-outline" href="#/larn/${params.table}${isEdit ? "/" + params.id : ""}">Annulla</a>
        <button class="btn btn-primary" type="submit">Salva</button>
      </div>
    </form>
  `);

  wireEntityForm({
    onSave: (data) => (isEdit ? Api.larn.update(params.table, params.id, data) : Api.larn.create(params.table, data)),
    hrefAfter: (result) => `#/larn/${params.table}/${result.id}`,
    successMessage: isEdit ? "Riga aggiornata." : "Riga creata.",
  });
};

// =====================================================================
// Alimento picker condiviso (usato da ricette e dal collegamento
// alimento->pasto nei giorni del piano): un <input> con <datalist> che
// suggerisce "Nome (codice)" mentre si digita, senza dipendenze esterne.
// =====================================================================

let _alimentoOptionsCache = null;
async function getAlimentoOptions() {
  if (!_alimentoOptionsCache) _alimentoOptionsCache = await Api.ricette.alimentiOptions();
  return _alimentoOptionsCache;
}
function alimentoLabel(opt) {
  return `${opt.nome_alimento} (${opt.codice_alimento})`;
}
function alimentoDatalistHtml(options, datalistId) {
  return h`<datalist id="${datalistId}">${options
    .map((o) => `<option value="${esc(alimentoLabel(o))}">`)
    .join("")}</datalist>`;
}
function resolveCodiceAlimento(options, typed) {
  const found = options.find((o) => alimentoLabel(o) === typed);
  return found ? found.codice_alimento : typed.trim();
}

// =====================================================================
// Ricette
// =====================================================================

Pages.ricetteList = async function (params) {
  const q = params.query.get("q") || "";
  const categoria_ricetta = params.query.get("categoria_ricetta") || "";
  const difficolta = params.query.get("difficolta") || "";
  const page = Number(params.query.get("page") || 1);

  const [data, campi] = await Promise.all([
    Api.ricette.list({ q, categoria_ricetta, difficolta, page }),
    Api.ricette.campi(),
  ]);
  const hrefFor = (p) => `#/ricette?${new URLSearchParams({ q, categoria_ricetta, difficolta, page: p })}`;

  setContent(h`
    <div class="page-head">
      <div><p class="eyebrow">Ricette</p><h1>Ricette</h1></div>
      ${AppState.user ? `<a class="btn btn-primary" href="#/ricette/nuova">+ Nuova ricetta</a>` : ""}
    </div>
    <form class="search-bar" id="filter-form">
      <div class="field-inline"><label for="q">Cerca</label><input type="search" id="q" name="q" value="${esc(q)}"></div>
      <div class="field-inline"><label for="categoria_ricetta">Categoria</label>
        <select id="categoria_ricetta" name="categoria_ricetta">
          <option value="">Tutte</option>
          ${campi.categorie.map((c) => `<option value="${esc(c)}" ${c === categoria_ricetta ? "selected" : ""}>${esc(c)}</option>`).join("")}
        </select>
      </div>
      <div class="field-inline"><label for="difficolta">Difficolta'</label>
        <select id="difficolta" name="difficolta">
          <option value="">Tutte</option>
          ${campi.difficolta.map((c) => `<option value="${esc(c)}" ${c === difficolta ? "selected" : ""}>${esc(c)}</option>`).join("")}
        </select>
      </div>
      <button class="btn btn-outline" type="submit">Filtra</button>
    </form>
    <div class="table-wrap">
      <table class="ledger">
        <thead><tr><th>Nome</th><th>Categoria</th><th class="num">Porzioni</th><th class="num">Tempo (min)</th><th class="num">Kcal/porz.</th><th></th></tr></thead>
        <tbody>
          ${
            data.items.length
              ? data.items
                  .map(
                    (r) => h`<tr>
                <td class="food-name"><a href="#/ricette/${r.id}">${esc(r.nome_ricetta)}</a></td>
                <td>${escOr(r.categoria_ricetta)}</td>
                <td class="num">${fmtNum(r.porzioni, 0)}</td>
                <td class="num">${fmtNum(r.tempo_preparazione_min, 0)}</td>
                <td class="num">${fmtNum(r.energia_kcal_porzione, 0)}</td>
                <td class="row-actions"><a class="btn btn-outline btn-sm" href="#/ricette/${r.id}">Apri</a></td>
              </tr>`
                  )
                  .join("")
              : `<tr><td colspan="6"><div class="empty-state">Nessuna ricetta trovata.</div></td></tr>`
          }
        </tbody>
      </table>
    </div>
    ${paginationHtml(data, hrefFor)}
  `);

  qs("#filter-form").addEventListener("submit", (e) => {
    e.preventDefault();
    const fd = formToJson(e.target);
    navigate(
      `#/ricette?${new URLSearchParams({
        q: fd.q || "",
        categoria_ricetta: fd.categoria_ricetta || "",
        difficolta: fd.difficolta || "",
      })}`
    );
  });
};

Pages.ricettaDetail = async function (params) {
  const [ricetta, ingredienti, campi, alimentoOptions] = await Promise.all([
    Api.ricette.get(params.id),
    Api.ricette.ingredienti.list(params.id),
    Api.ricette.campi(),
    AppState.user ? getAlimentoOptions() : Promise.resolve([]),
  ]);

  const nutrientRows = [
    ["Energia", ricetta.energia_kcal_porzione, "kcal"],
    ["Proteine", ricetta.proteine_g_porzione, "g"],
    ["Lipidi", ricetta.lipidi_g_porzione, "g"],
    ["Carboidrati", ricetta.carboidrati_g_porzione, "g"],
    ["Fibra", ricetta.fibra_g_porzione, "g"],
    ["Sodio", ricetta.sodio_mg_porzione, "mg"],
  ];

  setContent(h`
    <p class="breadcrumb"><a href="#/ricette">&larr; Ricette</a></p>
    <div class="detail-head">
      <div>
        <h1>${esc(ricetta.nome_ricetta)}</h1>
        <p class="meta">${escOr(ricetta.categoria_ricetta)} &middot; ${escOr(ricetta.difficolta)} &middot; ${fmtNum(ricetta.porzioni, 0)} porzioni &middot; ${fmtNum(ricetta.tempo_preparazione_min, 0)} min</p>
        <div class="badges">
          <span class="badge ${ricetta.vegano ? "badge-on" : "badge-off"}">Vegano</span>
          <span class="badge ${ricetta.vegetariano ? "badge-on" : "badge-off"}">Vegetariano</span>
          <span class="badge ${ricetta.senza_glutine ? "badge-on" : "badge-off"}">Senza glutine</span>
        </div>
      </div>
      ${
        AppState.user
          ? h`<div class="row-actions">
              <a class="btn btn-outline btn-sm" href="#/ricette/${ricetta.id}/modifica">Modifica</a>
              <button class="btn btn-danger btn-sm" id="del-btn" type="button">Elimina</button>
            </div>`
          : ""
      }
    </div>

    ${ricetta.procedimento ? h`<div class="form-section"><h2>Procedimento</h2><p>${esc(ricetta.procedimento).replaceAll("\n", "<br>")}</p></div>` : ""}

    <div class="form-section">
      <h2>Valori nutrizionali per porzione</h2>
      <div class="kcal-summary">
        ${nutrientRows.map(([label, v, unit]) => h`<div class="kcal-summary__item"><span class="k">${esc(label)}</span><span class="v">${v === null ? "-" : `${fmtNum(v)} ${unit}`}</span></div>`).join("")}
      </div>
      ${AppState.user ? h`<div class="form-actions"><button class="btn btn-accent btn-sm" id="ricalcola-btn" type="button">Ricalcola e salva dagli ingredienti</button></div>` : ""}
    </div>

    <div class="form-section">
      <h2>Ingredienti</h2>
      <div class="table-wrap">
        <table class="ledger">
          <thead><tr><th>Alimento</th><th class="num">Quantita' (g)</th><th class="num">Kcal</th><th>Note</th>${AppState.user ? "<th></th>" : ""}</tr></thead>
          <tbody>
            ${
              ingredienti.length
                ? ingredienti
                    .map(
                      (ing) => h`<tr>
                  <td>${esc(ing.nome_alimento)}</td>
                  <td class="num">${fmtNum(ing.quantita_g)}</td>
                  <td class="num">${fmtNum(ing.kcal_contributo, 0)}</td>
                  <td>${escOr(ing.note, "")}</td>
                  ${AppState.user ? `<td class="row-actions"><button class="btn btn-outline btn-sm" data-remove-ing="${ing.id}" type="button">Rimuovi</button></td>` : ""}
                </tr>`
                    )
                    .join("")
                : `<tr><td colspan="${AppState.user ? 5 : 4}"><div class="empty-state">Nessun ingrediente ancora.</div></td></tr>`
            }
          </tbody>
        </table>
      </div>
      ${
        AppState.user
          ? h`<form id="add-ing-form" class="search-bar" style="margin-top:14px;">
              <div class="field-inline">
                <label for="ing_alimento">Alimento</label>
                <input type="text" id="ing_alimento" name="alimento_label" list="alimenti-datalist" placeholder="Cerca alimento..." required>
              </div>
              <div class="field-inline">
                <label for="ing_qta">Quantita' (g)</label>
                <input type="number" step="0.1" id="ing_qta" name="quantita_g" required>
              </div>
              <div class="field-inline">
                <label for="ing_note">Note</label>
                <input type="text" id="ing_note" name="note">
              </div>
              <button class="btn btn-primary" type="submit">Aggiungi ingrediente</button>
              ${alimentoDatalistHtml(alimentoOptions, "alimenti-datalist")}
            </form>`
          : ""
      }
    </div>
  `);

  const delBtn = qs("#del-btn");
  if (delBtn) {
    delBtn.addEventListener("click", () =>
      confirmAndDelete(`Eliminare la ricetta "${ricetta.nome_ricetta}"?`, () => Api.ricette.remove(ricetta.id), "#/ricette")
    );
  }
  const ricalcolaBtn = qs("#ricalcola-btn");
  if (ricalcolaBtn) {
    ricalcolaBtn.addEventListener("click", async () => {
      try {
        await Api.ricette.ricalcola(ricetta.id);
        flash("Valori nutrizionali ricalcolati.", "success");
        Pages.ricettaDetail(params);
      } catch (err) {
        flash(err.message, "error");
      }
    });
  }
  qsa("[data-remove-ing]").forEach((btn) => {
    btn.addEventListener("click", () =>
      confirmAndDelete("Rimuovere questo ingrediente?", async () => {
        await Api.ricette.ingredienti.remove(ricetta.id, btn.dataset.removeIng);
        Pages.ricettaDetail(params);
      }, `#/ricette/${ricetta.id}`)
    );
  });
  const addIngForm = qs("#add-ing-form");
  if (addIngForm) {
    addIngForm.addEventListener("submit", async (e) => {
      e.preventDefault();
      const fd = formToJson(e.target);
      const codice_alimento = resolveCodiceAlimento(alimentoOptions, fd.alimento_label || "");
      try {
        await Api.ricette.ingredienti.add(ricetta.id, { codice_alimento, quantita_g: fd.quantita_g, note: fd.note });
        flash("Ingrediente aggiunto.", "success");
        Pages.ricettaDetail(params);
      } catch (err) {
        flash((err.details && err.details.join(" ")) || err.message, "error");
      }
    });
  }
};

Pages.ricettaForm = async function (params) {
  const isEdit = Boolean(params.id);
  const campi = await Api.ricette.campi();
  const values = isEdit ? await Api.ricette.get(params.id) : { porzioni: 4 };

  setContent(h`
    <p class="breadcrumb"><a href="${isEdit ? `#/ricette/${params.id}` : "#/ricette"}">&larr; ${isEdit ? "Ricetta" : "Ricette"}</a></p>
    <div class="page-head"><h1>${isEdit ? "Modifica ricetta" : "Nuova ricetta"}</h1></div>
    <div id="form-errors"></div>
    <form id="entity-form">
      ${renderFieldsForm(campi.fields, values)}
      <div class="form-actions">
        <a class="btn btn-outline" href="${isEdit ? `#/ricette/${params.id}` : "#/ricette"}">Annulla</a>
        <button class="btn btn-primary" type="submit">Salva</button>
      </div>
    </form>
  `);

  wireEntityForm({
    onSave: (data) => (isEdit ? Api.ricette.update(params.id, data) : Api.ricette.create(data)),
    hrefAfter: (result) => `#/ricette/${result.id}`,
    successMessage: isEdit ? "Ricetta aggiornata." : "Ricetta creata: ora puoi aggiungere gli ingredienti.",
  });
};

// =====================================================================
// Smartfood
// =====================================================================

Pages.smartfoodMenu = async function (params) {
  const frequenza = params.query.get("frequenza") || "";
  if (!frequenza) {
    const fasce = await Api.smartfood.fasce();
    setContent(h`
      <div class="page-head">
        <div><p class="eyebrow">Piramide alimentare Smartfood</p><h1>Smartfood</h1></div>
        ${AppState.user ? `<a class="btn btn-primary" href="#/smartfood/nuovo">+ Nuova voce</a>` : ""}
      </div>
      <div class="larn-grid">
        ${fasce
          .map(
            (f) => h`<a class="larn-card smartfood-card--${esc(f.key)}" href="#/smartfood?frequenza=${esc(f.key)}">
              <h2>${esc(f.label)}</h2>
              <p>${esc(f.description || "")}</p>
              <span class="count-tag badge badge-off">${f.total} alimenti</span>
            </a>`
          )
          .join("")}
      </div>
    `);
    return;
  }

  const [fasce, gruppi, data] = await Promise.all([
    Api.smartfood.fasce(),
    Api.smartfood.gruppi(),
    Api.smartfood.list({ frequenza }),
  ]);
  const fasciaMeta = fasce.find((f) => f.key === frequenza);

  setContent(h`
    <p class="breadcrumb"><a href="#/smartfood">&larr; Smartfood</a></p>
    <div class="page-head">
      <div><p class="eyebrow">Smartfood</p><h1>${esc(fasciaMeta ? fasciaMeta.label : frequenza)}</h1></div>
      ${AppState.user ? `<a class="btn btn-primary" href="#/smartfood/nuovo">+ Nuova voce</a>` : ""}
    </div>
    <div class="pill-nav">
      ${fasce.map((f) => `<a class="${f.key === frequenza ? "active" : ""}" href="#/smartfood?frequenza=${esc(f.key)}">${esc(f.label)}</a>`).join("")}
    </div>
    <div class="table-wrap">
      <table class="ledger">
        <thead><tr><th>Alimento</th><th>Gruppo</th><th>Porzione</th><th>Quante volte</th><th></th></tr></thead>
        <tbody>
          ${
            data.items.length
              ? data.items
                  .map(
                    (r) => h`<tr>
                <td class="food-name"><a href="#/smartfood/${r.id}">${esc(r.alimento)}</a></td>
                <td>${esc(r.gruppo_alimenti)}</td>
                <td>${escOr(r.porzione_standard)}</td>
                <td>${escOr(r.quante_volte)}</td>
                <td class="row-actions"><a class="btn btn-outline btn-sm" href="#/smartfood/${r.id}">Apri</a></td>
              </tr>`
                  )
                  .join("")
              : `<tr><td colspan="5"><div class="empty-state">Nessuna voce in questa fascia.</div></td></tr>`
          }
        </tbody>
      </table>
    </div>
  `);
};

Pages.smartfoodDetail = async function (params) {
  const [row, groups] = await Promise.all([Api.smartfood.get(params.id), Api.smartfood.campi()]);
  setContent(h`
    <p class="breadcrumb"><a href="#/smartfood">&larr; Smartfood</a></p>
    <div class="detail-head">
      <div><h1>${esc(row.alimento)}</h1><p class="meta">${esc(row.gruppo_alimenti)}</p></div>
      ${
        AppState.user
          ? h`<div class="row-actions">
              <a class="btn btn-outline btn-sm" href="#/smartfood/${row.id}/modifica">Modifica</a>
              <button class="btn btn-danger btn-sm" id="del-btn" type="button">Elimina</button>
            </div>`
          : ""
      }
    </div>
    ${groups.map((g) => h`<div class="form-section"><h2>${esc(g.name)}</h2>${renderDetailGrid(g.fields, row)}</div>`).join("")}
  `);
  const delBtn = qs("#del-btn");
  if (delBtn) {
    delBtn.addEventListener("click", () =>
      confirmAndDelete(`Eliminare "${row.alimento}"?`, () => Api.smartfood.remove(row.id), "#/smartfood")
    );
  }
};

Pages.smartfoodForm = async function (params) {
  const isEdit = Boolean(params.id);
  const groups = await Api.smartfood.campi();
  const values = isEdit ? await Api.smartfood.get(params.id) : {};
  setContent(h`
    <p class="breadcrumb"><a href="#/smartfood">&larr; Smartfood</a></p>
    <div class="page-head"><h1>${isEdit ? "Modifica voce" : "Nuova voce"}</h1></div>
    <div id="form-errors"></div>
    <form id="entity-form">
      ${renderFieldsForm(groups, values)}
      <div class="form-actions">
        <a class="btn btn-outline" href="${isEdit ? `#/smartfood/${params.id}` : "#/smartfood"}">Annulla</a>
        <button class="btn btn-primary" type="submit">Salva</button>
      </div>
    </form>
  `);
  wireEntityForm({
    onSave: (data) => (isEdit ? Api.smartfood.update(params.id, data) : Api.smartfood.create(data)),
    hrefAfter: (result) => `#/smartfood/${result.id}`,
    successMessage: isEdit ? "Voce aggiornata." : "Voce creata.",
  });
};

// =====================================================================
// Pazienti
// =====================================================================

Pages.pazientiList = async function (params) {
  const q = params.query.get("q") || "";
  const page = Number(params.query.get("page") || 1);
  const data = await Api.pazienti.list({ q, page });
  const hrefFor = (p) => `#/pazienti?${new URLSearchParams({ q, page: p })}`;

  setContent(h`
    <div class="page-head">
      <div><p class="eyebrow">Dati clinici riservati</p><h1>Pazienti</h1></div>
      <a class="btn btn-primary" href="#/pazienti/nuovo">+ Nuovo paziente</a>
    </div>
    <form class="search-bar" id="filter-form">
      <div class="field-inline"><label for="q">Cerca</label><input type="search" id="q" name="q" value="${esc(q)}" placeholder="Cognome o nome..."></div>
      <button class="btn btn-outline" type="submit">Filtra</button>
    </form>
    <div class="table-wrap">
      <table class="ledger">
        <thead><tr><th>Cognome</th><th>Nome</th><th>Data di nascita</th><th>Telefono</th><th></th></tr></thead>
        <tbody>
          ${
            data.items.length
              ? data.items
                  .map(
                    (p) => h`<tr>
                <td class="food-name"><a href="#/pazienti/${p.id}">${esc(p.cognome)}</a></td>
                <td>${esc(p.nome)}</td>
                <td>${p.data_nascita ? fmtDate(p.data_nascita) : "-"}</td>
                <td>${escOr(p.telefono)}</td>
                <td class="row-actions"><a class="btn btn-outline btn-sm" href="#/pazienti/${p.id}">Apri</a></td>
              </tr>`
                  )
                  .join("")
              : `<tr><td colspan="5"><div class="empty-state">Nessun paziente trovato.</div></td></tr>`
          }
        </tbody>
      </table>
    </div>
    ${paginationHtml(data, hrefFor)}
  `);

  qs("#filter-form").addEventListener("submit", (e) => {
    e.preventDefault();
    navigate(`#/pazienti?${new URLSearchParams({ q: formToJson(e.target).q || "" })}`);
  });
};

Pages.pazienteDetail = async function (params) {
  const [paziente, campi, larn, appuntamenti, piani] = await Promise.all([
    Api.pazienti.get(params.id),
    Api.pazienti.campi(),
    Api.pazienti.larn(params.id).catch(() => null),
    Api.pazienti.appuntamenti(params.id),
    Api.pazienti.piani.list(params.id),
  ]);

  setContent(h`
    <p class="breadcrumb"><a href="#/pazienti">&larr; Pazienti</a></p>
    <div class="detail-head">
      <div>
        <h1>${esc(paziente.cognome)} ${esc(paziente.nome)}</h1>
        <p class="meta">${paziente.data_nascita ? fmtDate(paziente.data_nascita) : "Data di nascita non indicata"}</p>
        <span class="badge ${paziente.attivo ? "badge-on" : "badge-off"}">${paziente.attivo ? "In carico" : "Non in carico"}</span>
      </div>
      <div class="row-actions">
        <a class="btn btn-outline btn-sm" href="#/pazienti/${paziente.id}/modifica">Modifica</a>
        <button class="btn btn-danger btn-sm" id="del-btn" type="button">Elimina</button>
      </div>
    </div>

    <div class="form-section">
      <h2>Anagrafica</h2>
      ${renderDetailGrid(campi.paziente.filter((f) => !["attivo"].includes(f.name)), paziente)}
    </div>

    ${
      larn
        ? h`<div class="form-section">
            <h2>Fabbisogno di riferimento (LARN)</h2>
            <div class="larn-compare">
              <div class="larn-compare__row"><span class="larn-compare__label">Energia</span><span class="larn-compare__value">${larn.energia && larn.energia.kcal !== null ? fmtNum(larn.energia.kcal, 0) + " kcal/die" : "Dati insufficienti"}</span></div>
              <div class="larn-compare__row"><span class="larn-compare__label">Proteine</span><span class="larn-compare__value">${larn.proteine && larn.proteine.g !== null ? fmtNum(larn.proteine.g, 0) + " g/die" : "Dati insufficienti"}</span></div>
              <div class="larn-compare__row"><span class="larn-compare__label">Acqua</span><span class="larn-compare__value">${larn.acqua && larn.acqua.ml !== null ? fmtNum(larn.acqua.ml, 0) + " ml/die" : "Dati insufficienti"}</span></div>
            </div>
            <p class="hint">Calcolato dalle tabelle LARN in base a eta', sesso, peso, altezza e livello di attivita' fisica del paziente.</p>
          </div>`
        : ""
    }

    <div class="form-section">
      <div class="page-head" style="margin-bottom:10px;">
        <h2>Piani alimentari</h2>
        <a class="btn btn-accent btn-sm" href="#/pazienti/${paziente.id}/piani/nuovo">+ Nuovo piano</a>
      </div>
      ${
        piani.length
          ? h`<div class="table-wrap"><table class="ledger">
              <thead><tr><th>Titolo</th><th>Inizio</th><th>Stato</th><th></th></tr></thead>
              <tbody>${piani
                .map(
                  (p) => h`<tr>
                    <td class="food-name"><a href="#/pazienti/${paziente.id}/piani/${p.id}">${esc(p.titolo)}</a></td>
                    <td>${p.data_inizio ? fmtDate(p.data_inizio) : "-"}</td>
                    <td><span class="badge ${p.attivo ? "badge-on" : "badge-off"}">${p.attivo ? "Attivo" : "Archiviato"}</span></td>
                    <td class="row-actions"><a class="btn btn-outline btn-sm" href="#/pazienti/${paziente.id}/piani/${p.id}">Apri</a></td>
                  </tr>`
                )
                .join("")}</tbody>
            </table></div>`
          : `<div class="empty-state">Nessun piano ancora.</div>`
      }
    </div>

    <div class="form-section">
      <div class="page-head" style="margin-bottom:10px;">
        <h2>Appuntamenti</h2>
        <a class="btn btn-accent btn-sm" href="#/appuntamenti/nuovo?paziente_id=${paziente.id}">+ Nuovo appuntamento</a>
      </div>
      ${
        appuntamenti.length
          ? h`<div class="table-wrap"><table class="ledger">
              <thead><tr><th>Data e ora</th><th>Tipo</th><th>Stato</th><th></th></tr></thead>
              <tbody>${appuntamenti
                .map(
                  (a) => h`<tr>
                    <td>${fmtDateTime(a.data_ora)}</td>
                    <td>${escOr(a.tipo)}</td>
                    <td><span class="badge ${a.stato === "Annullato" ? "badge-danger" : a.stato === "Non presentato" ? "badge-warn" : a.stato === "Completato" ? "badge-off" : "badge-on"}">${esc(a.stato)}</span></td>
                    <td class="row-actions"><a class="btn btn-outline btn-sm" href="#/appuntamenti/${a.id}/modifica">Modifica</a></td>
                  </tr>`
                )
                .join("")}</tbody>
            </table></div>`
          : `<div class="empty-state">Nessun appuntamento ancora.</div>`
      }
    </div>
  `);

  qs("#del-btn").addEventListener("click", () =>
    confirmAndDelete(
      `Eliminare il paziente "${paziente.cognome} ${paziente.nome}"? Verranno eliminati anche i suoi piani e appuntamenti.`,
      () => Api.pazienti.remove(paziente.id),
      "#/pazienti"
    )
  );
};

Pages.pazienteForm = async function (params) {
  const isEdit = Boolean(params.id);
  const campi = await Api.pazienti.campi();
  const values = isEdit ? await Api.pazienti.get(params.id) : { attivo: true };

  setContent(h`
    <p class="breadcrumb"><a href="${isEdit ? `#/pazienti/${params.id}` : "#/pazienti"}">&larr; ${isEdit ? "Paziente" : "Pazienti"}</a></p>
    <div class="page-head"><h1>${isEdit ? "Modifica paziente" : "Nuovo paziente"}</h1></div>
    <div id="form-errors"></div>
    <form id="entity-form">
      ${renderFieldsForm(campi.paziente, values)}
      <div class="form-actions">
        <a class="btn btn-outline" href="${isEdit ? `#/pazienti/${params.id}` : "#/pazienti"}">Annulla</a>
        <button class="btn btn-primary" type="submit">Salva</button>
      </div>
    </form>
  `);

  wireEntityForm({
    onSave: (data) => (isEdit ? Api.pazienti.update(params.id, data) : Api.pazienti.create(data)),
    hrefAfter: (result) => `#/pazienti/${result.id}`,
    successMessage: isEdit ? "Paziente aggiornato." : "Paziente creato.",
  });
};

// =====================================================================
// Piani alimentari e giorni
// =====================================================================

Pages.pianoForm = async function (params) {
  const [paziente, campi] = await Promise.all([Api.pazienti.get(params.id), Api.pazienti.campi()]);
  setContent(h`
    <p class="breadcrumb"><a href="#/pazienti/${params.id}">&larr; ${esc(paziente.cognome)} ${esc(paziente.nome)}</a></p>
    <div class="page-head"><h1>Nuovo piano alimentare</h1></div>
    <p>Alla creazione vengono generati automaticamente i 7 giorni della settimana, pronti da compilare.</p>
    <div id="form-errors"></div>
    <form id="entity-form">
      ${renderFieldsForm(campi.piano, { attivo: true })}
      <div class="form-actions">
        <a class="btn btn-outline" href="#/pazienti/${params.id}">Annulla</a>
        <button class="btn btn-primary" type="submit">Crea piano</button>
      </div>
    </form>
  `);
  wireEntityForm({
    onSave: (data) => Api.pazienti.piani.create(params.id, data),
    hrefAfter: (result) => `#/pazienti/${params.id}/piani/${result.id}`,
    successMessage: "Piano creato con i 7 giorni della settimana.",
  });
};

Pages.pianoDetail = async function (params) {
  const [paziente, data] = await Promise.all([Api.pazienti.get(params.id), Api.pazienti.piani.get(params.id, params.pianoId)]);
  const { piano, giorni, giorni_label } = data;

  setContent(h`
    <p class="breadcrumb"><a href="#/pazienti/${params.id}">&larr; ${esc(paziente.cognome)} ${esc(paziente.nome)}</a></p>
    <div class="detail-head">
      <div><h1>${esc(piano.titolo)}</h1><p class="meta">${piano.data_inizio ? fmtDate(piano.data_inizio) : "Data di inizio non indicata"}</p></div>
      <span class="badge ${piano.attivo ? "badge-on" : "badge-off"}">${piano.attivo ? "Attivo" : "Archiviato"}</span>
    </div>
    ${piano.note ? h`<div class="info-block">${esc(piano.note)}</div>` : ""}
    <div class="day-grid">
      ${giorni
        .map((g) => {
          const compilato = g.dati && g.dati.compilato;
          return h`<a class="day-card ${compilato ? "" : "day-card--empty"}" href="#/pazienti/${params.id}/piani/${params.pianoId}/giorni/${g.giorno}">
            <div class="day-card__head"><h3>${esc(giorni_label[g.giorno] || g.giorno)}</h3></div>
            <p>${compilato ? "Pasti compilati" : "Ancora da compilare"}</p>
            ${g.dati && g.dati.kcal_stimate ? `<div class="day-card__kcal">${fmtNum(g.dati.kcal_stimate, 0)} kcal stimate</div>` : ""}
          </a>`;
        })
        .join("")}
    </div>
    <div class="form-actions" style="margin-top:20px;">
      <button class="btn btn-danger btn-sm" id="del-btn" type="button">Elimina piano</button>
    </div>
  `);

  qs("#del-btn").addEventListener("click", () =>
    confirmAndDelete("Eliminare questo piano e tutti i suoi giorni?", () => Api.pazienti.piani.remove(params.id, params.pianoId), `#/pazienti/${params.id}`)
  );
};

Pages.giornoDetail = async function (params) {
  const [paziente, campi, giornoData, alimentoOptions] = await Promise.all([
    Api.pazienti.get(params.id),
    Api.pazienti.campi(),
    Api.pazienti.giorno.get(params.id, params.pianoId, params.giorno),
    getAlimentoOptions(),
  ]);
  const { giorno, giorno_label, alimenti_per_pasto, pasti_labels, kcal_totale_collegati, proteine_totali_collegate } = giornoData;

  setContent(h`
    <p class="breadcrumb"><a href="#/pazienti/${params.id}/piani/${params.pianoId}">&larr; ${esc(paziente.cognome)} ${esc(paziente.nome)} &middot; piano</a></p>
    <div class="page-head"><div><p class="eyebrow">${esc(giorno_label)}</p><h1>Giorno del piano</h1></div></div>

    <div class="form-section">
      <h2>Alimenti collegati e kcal stimate</h2>
      <div class="kcal-summary">
        <div class="kcal-summary__item"><span class="k">Kcal totali (da alimenti collegati)</span><span class="v">${fmtNum(kcal_totale_collegati, 0)}</span></div>
        <div class="kcal-summary__item"><span class="k">Kcal stimate salvate</span><span class="v">${giorno.kcal_stimate !== null && giorno.kcal_stimate !== undefined ? fmtNum(giorno.kcal_stimate, 0) : "-"}</span></div>
        <div class="kcal-summary__item"><span class="k">Proteine totali collegate</span><span class="v">${fmtNum(proteine_totali_collegate)} g</span></div>
      </div>
      <div class="form-actions"><button class="btn btn-accent btn-sm" id="ricalcola-kcal-btn" type="button">Ricalcola e salva le kcal</button></div>

      ${Object.entries(pasti_labels)
        .map(([key, label]) => {
          const items = alimenti_per_pasto[key] || [];
          return h`<div class="linked-foods">
            <h3>${esc(label)}</h3>
            ${
              items.length
                ? h`<ul>${items
                    .map(
                      (it) => h`<li>
                        <span>${esc(it.nome_alimento)} &middot; ${fmtNum(it.quantita_g)} g &middot; ${fmtNum(it.kcal_contributo, 0)} kcal</span>
                        <button class="btn btn-outline btn-sm" data-remove-link="${it.id}" type="button">Rimuovi</button>
                      </li>`
                    )
                    .join("")}</ul>`
                : `<p class="hint">Nessun alimento collegato.</p>`
            }
          </div>`;
        })
        .join("")}

      <form id="add-food-form" class="search-bar" style="margin-top:14px;">
        <div class="field-inline">
          <label for="pasto">Pasto</label>
          <select id="pasto" name="pasto">
            ${Object.entries(pasti_labels).map(([k, l]) => `<option value="${esc(k)}">${esc(l)}</option>`).join("")}
          </select>
        </div>
        <div class="field-inline">
          <label for="af_alimento">Alimento</label>
          <input type="text" id="af_alimento" name="alimento_label" list="alimenti-datalist" placeholder="Cerca alimento..." required>
        </div>
        <div class="field-inline">
          <label for="af_qta">Quantita' (g)</label>
          <input type="number" step="0.1" id="af_qta" name="quantita_g" required>
        </div>
        <button class="btn btn-primary" type="submit">Collega alimento</button>
        ${alimentoDatalistHtml(alimentoOptions, "alimenti-datalist")}
      </form>
    </div>

    <div class="form-section">
      <h2>Pasti (descrizione libera, come sul modulo cartaceo)</h2>
      <div id="form-errors"></div>
      <form id="entity-form">
        ${renderFieldsForm(campi.giorno_sezioni, giorno)}
        <div class="form-actions"><button class="btn btn-primary" type="submit">Salva pasti</button></div>
      </form>
    </div>
  `);

  qs("#ricalcola-kcal-btn").addEventListener("click", async () => {
    try {
      await Api.pazienti.giorno.ricalcolaKcal(params.id, params.pianoId, params.giorno);
      flash("Kcal ricalcolate.", "success");
      Pages.giornoDetail(params);
    } catch (err) {
      flash(err.message, "error");
    }
  });

  qsa("[data-remove-link]").forEach((btn) => {
    btn.addEventListener("click", () =>
      confirmAndDelete("Rimuovere questo alimento dal pasto?", async () => {
        await Api.pazienti.giorno.rimuoviAlimento(params.id, params.pianoId, params.giorno, btn.dataset.removeLink);
        Pages.giornoDetail(params);
      }, `#/pazienti/${params.id}/piani/${params.pianoId}/giorni/${params.giorno}`)
    );
  });

  qs("#add-food-form").addEventListener("submit", async (e) => {
    e.preventDefault();
    const fd = formToJson(e.target);
    const codice_alimento = resolveCodiceAlimento(alimentoOptions, fd.alimento_label || "");
    try {
      await Api.pazienti.giorno.aggiungiAlimento(params.id, params.pianoId, params.giorno, {
        pasto: fd.pasto,
        codice_alimento,
        quantita_g: fd.quantita_g,
      });
      flash("Alimento collegato.", "success");
      Pages.giornoDetail(params);
    } catch (err) {
      flash((err.details && err.details.join(" ")) || err.message, "error");
    }
  });

  wireEntityForm({
    onSave: (data) => Api.pazienti.giorno.update(params.id, params.pianoId, params.giorno, data),
    hrefAfter: () => `#/pazienti/${params.id}/piani/${params.pianoId}/giorni/${params.giorno}`,
    successMessage: "Pasti aggiornati.",
  });
};

// =====================================================================
// Appuntamenti (agenda)
// =====================================================================

Pages.agendaList = async function (params) {
  const q = params.query.get("q") || "";
  const stato = params.query.get("stato") || "";
  const passati = params.query.get("passati") || "0";
  const page = Number(params.query.get("page") || 1);

  const [data, campi] = await Promise.all([Api.appuntamenti.agenda({ q, stato, passati, page }), Api.appuntamenti.campi()]);
  const hrefFor = (p) => `#/appuntamenti?${new URLSearchParams({ q, stato, passati, page: p })}`;

  const badgeClass = (s) =>
    s === "Annullato" ? "badge-danger" : s === "Non presentato" ? "badge-warn" : s === "Completato" ? "badge-off" : "badge-on";

  setContent(h`
    <div class="page-head">
      <div><p class="eyebrow">Agenda</p><h1>Appuntamenti</h1></div>
      <a class="btn btn-primary" href="#/appuntamenti/nuovo">+ Nuovo appuntamento</a>
    </div>
    <form class="search-bar" id="filter-form">
      <div class="field-inline"><label for="q">Paziente</label><input type="search" id="q" name="q" value="${esc(q)}"></div>
      <div class="field-inline"><label for="stato">Stato</label>
        <select id="stato" name="stato">
          <option value="">Tutti</option>
          ${campi.stati.map((s) => `<option value="${esc(s)}" ${s === stato ? "selected" : ""}>${esc(s)}</option>`).join("")}
        </select>
      </div>
      <div class="field-inline checkbox-field" style="align-self:flex-end;">
        <input type="checkbox" id="passati" name="passati" ${passati === "1" ? "checked" : ""}>
        <label for="passati">Includi passati</label>
      </div>
      <button class="btn btn-outline" type="submit">Filtra</button>
    </form>
    <div class="table-wrap">
      <table class="ledger">
        <thead><tr><th>Data e ora</th><th>Paziente</th><th>Tipo</th><th>Stato</th><th></th></tr></thead>
        <tbody>
          ${
            data.items.length
              ? data.items
                  .map(
                    (a) => h`<tr>
                <td>${fmtDateTime(a.data_ora)}</td>
                <td><a href="#/pazienti/${a.paziente_id}">${esc(a.paziente_cognome)} ${esc(a.paziente_nome)}</a></td>
                <td>${escOr(a.tipo)}</td>
                <td><span class="badge ${badgeClass(a.stato)}">${esc(a.stato)}</span></td>
                <td class="row-actions"><a class="btn btn-outline btn-sm" href="#/appuntamenti/${a.id}/modifica">Modifica</a></td>
              </tr>`
                  )
                  .join("")
              : `<tr><td colspan="5"><div class="empty-state">Nessun appuntamento trovato.</div></td></tr>`
          }
        </tbody>
      </table>
    </div>
    ${paginationHtml(data, hrefFor)}
  `);

  qs("#filter-form").addEventListener("submit", (e) => {
    e.preventDefault();
    const fd = formToJson(e.target);
    navigate(
      `#/appuntamenti?${new URLSearchParams({ q: fd.q || "", stato: fd.stato || "", passati: fd.passati ? "1" : "0" })}`
    );
  });
};

Pages.appuntamentoForm = async function (params) {
  const isEdit = Boolean(params.id);
  const campi = await Api.appuntamenti.campi();
  let values = {};
  let paziente = null;

  if (isEdit) {
    values = await Api.appuntamenti.get(params.id);
    paziente = await Api.pazienti.get(values.paziente_id);
  } else {
    const presetPazienteId = params.query.get("paziente_id");
    if (presetPazienteId) {
      paziente = await Api.pazienti.get(presetPazienteId);
      values = { paziente_id: presetPazienteId };
    } else {
      values = {};
    }
  }

  const pazienti = paziente ? [paziente] : (await Api.pazienti.list({ page: 1 })).items;

  setContent(h`
    <p class="breadcrumb"><a href="#/appuntamenti">&larr; Agenda</a></p>
    <div class="page-head"><h1>${isEdit ? "Modifica appuntamento" : "Nuovo appuntamento"}</h1></div>
    <div id="form-errors"></div>
    <form id="entity-form">
      <div class="form-grid">
        <div class="form-field">
          <label for="f_paziente_id">Paziente <span class="req">*</span></label>
          <select id="f_paziente_id" name="paziente_id" ${isEdit ? "disabled" : ""} required>
            ${pazienti.map((p) => `<option value="${p.id}" ${String(values.paziente_id) === String(p.id) ? "selected" : ""}>${esc(p.cognome)} ${esc(p.nome)}</option>`).join("")}
          </select>
        </div>
      </div>
      ${renderFieldsForm(campi.fields, values)}
      <div class="form-actions">
        <a class="btn btn-outline" href="${paziente ? `#/pazienti/${paziente.id}` : "#/appuntamenti"}">Annulla</a>
        <button class="btn btn-primary" type="submit">Salva</button>
      </div>
    </form>
  `);

  wireEntityForm({
    onSave: (data) => (isEdit ? Api.appuntamenti.update(params.id, data) : Api.appuntamenti.create(data)),
    hrefAfter: (result) => `#/pazienti/${result.paziente_id}`,
    successMessage: isEdit ? "Appuntamento aggiornato." : "Appuntamento creato.",
  });
};
