/* Client dell'API REST: un sottile wrapper attorno a fetch(). Nessuna
 * chiamata qui produce HTML: ogni funzione restituisce dati (JSON) gia'
 * pronti per essere usati dai renderer in pages.js. E' l'UNICO file che sa
 * come parlare col backend; il resto del front-end non chiama mai fetch()
 * direttamente. */

const API_BASE = "/api";

class ApiError extends Error {
  constructor(message, status, details) {
    super(message);
    this.status = status;
    this.details = details;
  }
}

async function apiRequest(path, { method = "GET", body, params } = {}) {
  let url = API_BASE + path;
  if (params) {
    const cleaned = Object.entries(params).filter(
      ([, v]) => v !== undefined && v !== null && v !== ""
    );
    const qsStr = new URLSearchParams(cleaned).toString();
    if (qsStr) url += "?" + qsStr;
  }

  const res = await fetch(url, {
    method,
    credentials: "include",
    headers: body !== undefined ? { "Content-Type": "application/json" } : {},
    body: body !== undefined ? JSON.stringify(body) : undefined,
  });

  const text = await res.text();
  let data = null;
  if (text) {
    try {
      data = JSON.parse(text);
    } catch (e) {
      data = null;
    }
  }

  if (!res.ok) {
    throw new ApiError((data && data.error) || `Errore HTTP ${res.status}`, res.status, data && data.details);
  }
  return data;
}

const Api = {
  auth: {
    login: (username, password) => apiRequest("/auth/login", { method: "POST", body: { username, password } }),
    logout: () => apiRequest("/auth/logout", { method: "POST" }),
    me: () => apiRequest("/auth/me"),
  },

  alimenti: {
    list: (params) => apiRequest("/alimenti", { params }),
    categorie: () => apiRequest("/alimenti/categorie"),
    campi: () => apiRequest("/alimenti/campi"),
    get: (id) => apiRequest(`/alimenti/${id}`),
    create: (data) => apiRequest("/alimenti", { method: "POST", body: data }),
    update: (id, data) => apiRequest(`/alimenti/${id}`, { method: "PUT", body: data }),
    remove: (id) => apiRequest(`/alimenti/${id}`, { method: "DELETE" }),
  },

  larn: {
    tables: () => apiRequest("/larn/tables"),
    list: (tableKey, params) => apiRequest(`/larn/${tableKey}`, { params }),
    get: (tableKey, id) => apiRequest(`/larn/${tableKey}/${id}`),
    create: (tableKey, data) => apiRequest(`/larn/${tableKey}`, { method: "POST", body: data }),
    update: (tableKey, id, data) => apiRequest(`/larn/${tableKey}/${id}`, { method: "PUT", body: data }),
    remove: (tableKey, id) => apiRequest(`/larn/${tableKey}/${id}`, { method: "DELETE" }),
  },

  ricette: {
    list: (params) => apiRequest("/ricette", { params }),
    campi: () => apiRequest("/ricette/campi"),
    alimentiOptions: () => apiRequest("/ricette/alimenti-options"),
    get: (id) => apiRequest(`/ricette/${id}`),
    create: (data) => apiRequest("/ricette", { method: "POST", body: data }),
    update: (id, data) => apiRequest(`/ricette/${id}`, { method: "PUT", body: data }),
    remove: (id) => apiRequest(`/ricette/${id}`, { method: "DELETE" }),
    ricalcola: (id) => apiRequest(`/ricette/${id}/ricalcola`, { method: "POST" }),
    ingredienti: {
      list: (ricettaId) => apiRequest(`/ricette/${ricettaId}/ingredienti`),
      add: (ricettaId, data) => apiRequest(`/ricette/${ricettaId}/ingredienti`, { method: "POST", body: data }),
      update: (ricettaId, ingId, data) =>
        apiRequest(`/ricette/${ricettaId}/ingredienti/${ingId}`, { method: "PUT", body: data }),
      remove: (ricettaId, ingId) =>
        apiRequest(`/ricette/${ricettaId}/ingredienti/${ingId}`, { method: "DELETE" }),
    },
  },

  smartfood: {
    fasce: () => apiRequest("/smartfood/fasce"),
    campi: () => apiRequest("/smartfood/campi"),
    gruppi: () => apiRequest("/smartfood/gruppi"),
    list: (params) => apiRequest("/smartfood", { params }),
    get: (id) => apiRequest(`/smartfood/${id}`),
    create: (data) => apiRequest("/smartfood", { method: "POST", body: data }),
    update: (id, data) => apiRequest(`/smartfood/${id}`, { method: "PUT", body: data }),
    remove: (id) => apiRequest(`/smartfood/${id}`, { method: "DELETE" }),
  },

  pazienti: {
    list: (params) => apiRequest("/pazienti", { params }),
    campi: () => apiRequest("/pazienti/campi"),
    get: (id) => apiRequest(`/pazienti/${id}`),
    create: (data) => apiRequest("/pazienti", { method: "POST", body: data }),
    update: (id, data) => apiRequest(`/pazienti/${id}`, { method: "PUT", body: data }),
    remove: (id) => apiRequest(`/pazienti/${id}`, { method: "DELETE" }),
    larn: (id) => apiRequest(`/pazienti/${id}/larn`),
    appuntamenti: (id) => apiRequest(`/pazienti/${id}/appuntamenti`),

    piani: {
      list: (pazienteId) => apiRequest(`/pazienti/${pazienteId}/piani`),
      create: (pazienteId, data) => apiRequest(`/pazienti/${pazienteId}/piani`, { method: "POST", body: data }),
      get: (pazienteId, pianoId) => apiRequest(`/pazienti/${pazienteId}/piani/${pianoId}`),
      update: (pazienteId, pianoId, data) =>
        apiRequest(`/pazienti/${pazienteId}/piani/${pianoId}`, { method: "PUT", body: data }),
      remove: (pazienteId, pianoId) =>
        apiRequest(`/pazienti/${pazienteId}/piani/${pianoId}`, { method: "DELETE" }),
    },

    giorno: {
      get: (pazienteId, pianoId, giorno) =>
        apiRequest(`/pazienti/${pazienteId}/piani/${pianoId}/giorni/${giorno}`),
      update: (pazienteId, pianoId, giorno, data) =>
        apiRequest(`/pazienti/${pazienteId}/piani/${pianoId}/giorni/${giorno}`, { method: "PUT", body: data }),
      ricalcolaKcal: (pazienteId, pianoId, giorno) =>
        apiRequest(`/pazienti/${pazienteId}/piani/${pianoId}/giorni/${giorno}/ricalcola-kcal`, { method: "POST" }),
      aggiungiAlimento: (pazienteId, pianoId, giorno, data) =>
        apiRequest(`/pazienti/${pazienteId}/piani/${pianoId}/giorni/${giorno}/alimenti`, {
          method: "POST",
          body: data,
        }),
      rimuoviAlimento: (pazienteId, pianoId, giorno, linkId) =>
        apiRequest(`/pazienti/${pazienteId}/piani/${pianoId}/giorni/${giorno}/alimenti/${linkId}`, {
          method: "DELETE",
        }),
    },
  },

  appuntamenti: {
    agenda: (params) => apiRequest("/appuntamenti", { params }),
    campi: () => apiRequest("/appuntamenti/campi"),
    get: (id) => apiRequest(`/appuntamenti/${id}`),
    create: (data) => apiRequest("/appuntamenti", { method: "POST", body: data }),
    update: (id, data) => apiRequest(`/appuntamenti/${id}`, { method: "PUT", body: data }),
    remove: (id) => apiRequest(`/appuntamenti/${id}`, { method: "DELETE" }),
  },
};
