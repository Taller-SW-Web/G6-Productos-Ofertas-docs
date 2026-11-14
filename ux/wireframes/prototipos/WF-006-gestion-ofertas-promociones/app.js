const catalog = [
  {id: 'p1', name: 'Zapatillas Running', skus: [['RUN-39', 'Talla 39'], ['RUN-40', 'Talla 40'], ['RUN-41', 'Talla 41']]},
  {id: 'p2', name: 'Polo deportivo', skus: [['POL-S', 'Talla S'], ['POL-M', 'Talla M'], ['POL-L', 'Talla L']]},
  {id: 'p3', name: 'Casaca térmica', skus: [['CAS-M', 'Talla M'], ['CAS-L', 'Talla L']]}
];
const supportedChannels = ['Marketplace', 'Chatbot', 'Retail', 'Ventas'];
let promos = [
  {id: 'pr1', name: 'Semana Running', mode: 'AUTOMATICA', type: 'PORCENTAJE', value: 15, state: 'ACTIVA', start: '2026-09-20T00:00', end: '2026-10-05T23:59', priority: 1, channels: ['Marketplace', 'Chatbot', 'Retail'], combineOffer: false, combinePromo: false, combineCoupon: false, scope: {productIds: ['p1'], skus: []}, everActivated: true, couponCount: 0, usesCount: 0},
  {id: 'pr2', name: 'S/ 25 en Running 40', mode: 'AUTOMATICA', type: 'MONTO_FIJO', value: 25, state: 'INACTIVA', start: '2026-10-01T00:00', end: '2026-10-31T23:59', priority: 2, channels: ['Marketplace'], combineOffer: true, combinePromo: false, combineCoupon: true, scope: {productIds: [], skus: ['RUN-40']}, everActivated: false, couponCount: 0, usesCount: 0},
  {id: 'pr3', name: 'Cupón lanzamiento polos', mode: 'CUPON', type: 'PORCENTAJE', value: 10, state: 'ACTIVA', start: '2026-09-25T00:00', end: '2026-10-10T23:59', priority: 3, channels: ['Marketplace'], combineOffer: false, combinePromo: false, combineCoupon: false, scope: {productIds: ['p2'], skus: []}, everActivated: true, couponCount: 1, usesCount: 0}
];
const state = {view: 'list', current: null, edit: null, errors: {}};
const filters = {search: '', state: '', type: '', mode: ''};
const app = document.getElementById('app');
const esc = value => String(value ?? '').replace(/[&<>"']/g, c => ({'&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'}[c]));
const date = value => new Date(value).toLocaleString('es-PE', {dateStyle: 'short', timeStyle: 'short'});
const byId = id => promos.find(p => p.id === id);
const canChangeMode = p => p.state === 'INACTIVA' && p.everActivated === false && p.couponCount === 0 && p.usesCount === 0;
const modeEditable = () => !state.current || canChangeMode(byId(state.current));
const mode = p => p.mode === 'AUTOMATICA' ? 'Automática' : 'Mediante cupón';
const discount = p => p.type === 'PORCENTAJE' ? `${p.value} %` : `S/ ${Number(p.value).toFixed(2)}`;
const channels = p => p.channels.join(', ');
const scopeCount = p => `${p.scope.productIds.length} producto(s) · ${p.scope.skus.length} SKU`;
function matchesScope(p, sku) { return p.scope.skus.includes(sku) || catalog.some(g => p.scope.productIds.includes(g.id) && g.skus.some(s => s[0] === sku)); }
function comb(p) { const parts = []; if (p.combineOffer) parts.push('oferta vigente'); if (p.combinePromo) parts.push('otra promoción'); if (p.combineCoupon) parts.push('cupón'); return parts.length ? `Combina con ${parts.join(', ')}` : 'Exclusiva'; }
function notify(message) { const toast = document.getElementById('toast'); toast.textContent = message; toast.classList.add('show'); setTimeout(() => toast.classList.remove('show'), 2000); }
function head(title, copy, actions = '') { return `<div class="pagehead"><div><h1>${title}</h1><p>${copy}</p></div><div class="row">${actions}</div></div>`; }
function render() {
  const denied = {'#no-permission': 'No tienes permiso para administrar promociones.', '#session-expired': 'Tu sesión finalizó. Ingresa nuevamente.'}[location.hash];
  if (denied) { app.innerHTML = head('Ofertas y promociones', 'Administra campañas comerciales.') + `<p role="alert">${denied}</p>`; return; }
  if (state.view === 'form') renderForm(); else if (state.view === 'detail') renderDetail(); else renderList();
}
function renderList() {
  const rows = location.hash === '#list-empty' ? [] : promos.filter(p => p.name.toLowerCase().includes(filters.search.toLowerCase()) && (!filters.state || p.state === filters.state) && (!filters.type || p.type === filters.type) && (!filters.mode || p.mode === filters.mode));
  const options = (entries, selected) => entries.map(([value, label]) => `<option value="${value}" ${value === selected ? 'selected' : ''}>${label}</option>`).join('');
  app.innerHTML = head('Ofertas y promociones', 'Demostración local: los cambios duran hasta recargar la página.', '<button class="btn primary" data-a="new">Crear promoción</button>') +
    `<section class="toolbar panel"><div class="field"><label for="search">Buscar</label><input class="input" id="search" data-filter="search" value="${esc(filters.search)}"></div><div class="field"><label for="filterState">Estado</label><select id="filterState" data-filter="state">${options([['', 'Todos'], ['ACTIVA', 'Activas'], ['INACTIVA', 'Inactivas']], filters.state)}</select></div><div class="field"><label for="filterType">Tipo</label><select id="filterType" data-filter="type">${options([['', 'Todos'], ['PORCENTAJE', 'Porcentaje'], ['MONTO_FIJO', 'Monto fijo']], filters.type)}</select></div><div class="field"><label for="filterMode">Modalidad</label><select id="filterMode" data-filter="mode">${options([['', 'Todas'], ['AUTOMATICA', 'Automática'], ['CUPON', 'Mediante cupón']], filters.mode)}</select></div></section>`;
  if (location.hash === '#list-loading') { app.innerHTML += '<p role="status">Cargando promociones…</p>'; return; }
  if (!rows.length) { app.innerHTML += '<p>No hay promociones para estos filtros.</p>'; return; }
  app.innerHTML += `<div class="desktop tablewrap"><table><thead><tr><th>Promoción</th><th>Descuento</th><th>Modalidad</th><th>Combinación</th><th>Canales</th><th>Alcance</th><th>Vigencia</th><th>Estado</th><th></th></tr></thead><tbody>${rows.map(p => `<tr><td><strong>${esc(p.name)}</strong></td><td>${discount(p)}</td><td>${mode(p)}</td><td>${comb(p)}</td><td>${channels(p)}</td><td>${scopeCount(p)}</td><td>${date(p.start)} — ${date(p.end)}</td><td>${p.state === 'ACTIVA' ? 'Activa' : 'Inactiva'}</td><td><button class="btn" data-a="detail" data-id="${p.id}">Ver detalle</button></td></tr>`).join('')}</tbody></table></div><div class="cards">${rows.map(p => `<article class="card"><strong>${esc(p.name)}</strong><p>${discount(p)} · ${mode(p)}</p><button class="btn" data-a="detail" data-id="${p.id}">Ver detalle</button></article>`).join('')}</div>`;
}
function blank() { return {name: '', mode: 'AUTOMATICA', type: 'PORCENTAJE', value: '', state: 'INACTIVA', start: '', end: '', priority: 1, channels: [], combineOffer: false, combinePromo: false, combineCoupon: false, scope: {productIds: [], skus: []}, everActivated: false, couponCount: 0, usesCount: 0}; }
function renderForm() {
  const p = state.edit, errors = state.errors;
  const error = key => `<span class="error" id="${key}-error">${esc(errors[key] || '')}</span>`;
  const input = (id, label, type, value) => `<div class="field"><label for="${id}">${label}</label><input class="input" id="${id}" type="${type}" ${type === 'number' ? 'step="any"' : ''} value="${esc(value)}" aria-invalid="${!!errors[id]}" aria-describedby="${id}-error">${error(id)}</div>`;
  const scope = catalog.map(g => { const whole = p.scope.productIds.includes(g.id); return `<div class="scope-group"><label><input type="checkbox" data-product="${g.id}" ${whole ? 'checked' : ''}> <strong>${esc(g.name)} — producto completo</strong></label><div class="skus">${g.skus.map(s => `<label><input type="checkbox" data-sku="${s[0]}" ${whole || p.scope.skus.includes(s[0]) ? 'checked' : ''} ${whole ? 'disabled' : ''}> <span>${esc(s[1])}</span> <span class="small muted">${esc(s[0])}</span></label>`).join('')}</div></div>`; }).join('');
  app.innerHTML = head(state.current ? 'Editar promoción' : 'Crear promoción', 'Define condiciones comerciales.') + `<form id="promotionForm" novalidate><section class="panel"><div class="formgrid">
    ${input('name', 'Nombre', 'text', p.name)}
    <div class="field"><label for="mode">Modalidad</label><select id="mode" ${modeEditable() ? '' : 'disabled'}><option value="AUTOMATICA" ${p.mode === 'AUTOMATICA' ? 'selected' : ''}>Automática</option><option value="CUPON" ${p.mode === 'CUPON' ? 'selected' : ''}>Mediante cupón</option></select>${!modeEditable() ? '<p class="small muted">Solo puede cambiarse si nunca fue activada, está inactiva y no tiene cupones ni usos. Crea otra promoción.</p>' : ''}${error('mode')}</div>
    <div class="field"><label for="type">Tipo de descuento</label><select id="type"><option value="PORCENTAJE" ${p.type === 'PORCENTAJE' ? 'selected' : ''}>Porcentaje</option><option value="MONTO_FIJO" ${p.type === 'MONTO_FIJO' ? 'selected' : ''}>Monto fijo</option></select></div>
    ${input('value', 'Valor', 'number', p.value)}${input('start', 'Inicio', 'datetime-local', p.start)}${input('end', 'Fin', 'datetime-local', p.end)}${input('priority', 'Prioridad', 'number', p.priority)}
    <div class="field"><label for="state">Estado</label><select id="state"><option value="ACTIVA" ${p.state === 'ACTIVA' ? 'selected' : ''}>Activa</option><option value="INACTIVA" ${p.state === 'INACTIVA' ? 'selected' : ''}>Inactiva</option></select></div>
    <fieldset class="wide"><legend>Canales habilitados</legend><div class="checkrow">${supportedChannels.map(channel => `<label class="check"><input type="checkbox" data-channel="${channel}" ${p.channels.includes(channel) ? 'checked' : ''}>${channel}</label>`).join('')}</div><p class="small muted">Selecciona al menos un canal. Para habilitarlos todos, márcalos explícitamente.</p>${error('channels')}</fieldset>
    <fieldset class="wide"><legend>Política de combinación</legend><div class="checkrow"><label><input type="checkbox" id="co" ${p.combineOffer ? 'checked' : ''}> Con oferta vigente de Pricing</label><label><input type="checkbox" id="cp" ${p.combinePromo ? 'checked' : ''}> Con otra promoción automática</label><label><input type="checkbox" id="combineCoupon" ${p.combineCoupon ? 'checked' : ''}> Con cupón</label></div></fieldset>
    <fieldset class="wide"><legend>Alcance</legend><p>Selecciona productos completos o SKU específicos. El producto completo incluye sus SKU vendibles.</p><div class="scope">${scope}</div>${error('scope')}</fieldset>
    </div></section><p role="alert" id="formError">${Object.keys(errors).length ? 'Corrige los campos indicados.' : ''}</p><div class="row" style="justify-content:flex-end"><button type="button" class="btn" data-a="back">Cancelar</button><button class="btn primary">Guardar promoción</button></div></form>`;
}
function validate(p) {
  const e = {};
  if (!p.name.trim()) e.name = 'Ingresa un nombre.';
  const value = Number(p.value);
  if (!Number.isFinite(value) || value <= 0 || (p.type === 'PORCENTAJE' && value > 100)) e.value = p.type === 'PORCENTAJE' ? 'Ingresa un porcentaje mayor que 0 y hasta 100.' : 'Ingresa un monto mayor que cero.';
  if (!p.start || !Number.isFinite(Date.parse(p.start))) e.start = 'Indica el inicio.';
  if (!p.end || !Number.isFinite(Date.parse(p.end)) || Date.parse(p.end) <= Date.parse(p.start)) e.end = 'El fin debe ser posterior al inicio.';
  if (!Number.isSafeInteger(Number(p.priority)) || Number(p.priority) < 1) e.priority = 'Ingresa una prioridad entera positiva.';
  if (!p.channels.length || p.channels.some(c => !supportedChannels.includes(c))) e.channels = 'Selecciona al menos un canal habilitado.';
  if ((!p.scope.productIds.length && !p.scope.skus.length) || p.scope.productIds.some(id => !catalog.some(g => g.id === id)) || p.scope.skus.some(sku => !catalog.some(g => g.skus.some(s => s[0] === sku)))) e.scope = 'Selecciona al menos un producto o SKU activo.';
  const existing = byId(state.current);
  if (existing && existing.mode !== p.mode && !canChangeMode(existing)) e.mode = 'Esta promoción ya no permite cambiar su modalidad.';
  return e;
}
function syncForm() {
  if (state.view !== 'form') return;
  const p = state.edit, q = id => document.getElementById(id);
  for (const id of ['name', 'mode', 'type', 'value', 'start', 'end', 'state']) p[id] = q(id).value;
  p.priority = Number(q('priority').value);
  p.combineOffer = q('co').checked; p.combinePromo = q('cp').checked; p.combineCoupon = q('combineCoupon').checked;
  p.channels = [...app.querySelectorAll('[data-channel]:checked')].map(x => x.dataset.channel);
  p.scope.productIds = [...new Set([...app.querySelectorAll('[data-product]:checked')].map(x => x.dataset.product))];
  p.scope.skus = [...new Set([...app.querySelectorAll('[data-sku]:checked:not(:disabled)')].map(x => x.dataset.sku))].filter(sku => !catalog.some(g => p.scope.productIds.includes(g.id) && g.skus.some(s => s[0] === sku)));
}
function renderDetail() {
  const p = byId(state.current);
  if (!p) { state.view = 'list'; render(); return; }
  const scope = [...p.scope.productIds.map(id => `<li>${esc(catalog.find(g => g.id === id)?.name)} — producto completo</li>`), ...p.scope.skus.map(sku => `<li>SKU ${esc(sku)}</li>`)].join('');
  app.innerHTML = head(esc(p.name), 'Detalle de configuración comercial.', '<button class="btn" data-a="back">Volver</button><button class="btn" data-a="edit">Editar</button>') + `<section class="panel"><p>${p.state === 'ACTIVA' ? 'Activa' : 'Inactiva'} · ${mode(p)} · ${discount(p)}</p><p>Prioridad ${p.priority}</p><p>Vigencia: ${date(p.start)} — ${date(p.end)}</p><p>Canales: ${channels(p)}</p><h2>Alcance</h2><ul>${scope}</ul><p>${comb(p)}</p></section><button class="btn primary" data-a="state">${p.state === 'ACTIVA' ? 'Desactivar' : 'Activar'} promoción</button>`;
}
app.onclick = event => {
  const button = event.target.closest('[data-a]'); if (!button) return;
  const action = button.dataset.a;
  if (action === 'new') { state.current = null; state.edit = blank(); state.errors = {}; state.view = 'form'; }
  if (action === 'detail') { state.current = button.dataset.id; state.view = 'detail'; }
  if (action === 'edit') { state.edit = structuredClone(byId(state.current)); state.errors = {}; state.view = 'form'; }
  if (action === 'back') { state.view = state.view === 'form' && state.current ? 'detail' : 'list'; }
  if (action === 'state') { openConfirm(); return; }
  render();
};
app.onchange = event => {
  if (event.target.dataset.filter) { filters[event.target.dataset.filter] = event.target.value; renderList(); return; }
  if (state.view !== 'form') return;
  syncForm();
  if (event.target.dataset.product || event.target.id === 'mode') renderForm();
};
app.onsubmit = event => {
  event.preventDefault(); syncForm(); state.errors = validate(state.edit);
  if (Object.keys(state.errors).length) { renderForm(); const key = Object.keys(state.errors)[0]; (document.getElementById(key) || app.querySelector('fieldset input'))?.focus(); return; }
  if (location.hash === '#save-error') { document.getElementById('formError').textContent = 'No se pudo guardar. Tus datos se conservan; vuelve a intentarlo.'; return; }
  const saved = structuredClone(state.edit); saved.name = saved.name.trim(); saved.value = Number(saved.value);
  saved.everActivated = saved.everActivated || saved.state === 'ACTIVA';
  if (state.current) Object.assign(byId(state.current), saved);
  else { saved.id = 'pr' + Date.now(); promos.unshift(saved); state.current = saved.id; }
  state.view = 'detail'; notify('Promoción guardada en esta demostración.'); render();
};
let confirmReturnFocus;
function openConfirm() {
  confirmReturnFocus = document.activeElement; const p = byId(state.current);
  document.getElementById('ct').textContent = p.state === 'ACTIVA' ? 'Desactivar promoción' : 'Activar promoción';
  document.getElementById('confirmText').textContent = p.state === 'ACTIVA' ? 'Dejará de participar en nuevas evaluaciones. Los pedidos confirmados conservan su beneficio.' : 'Participará cuando esté vigente y corresponda a su alcance y canal.';
  document.getElementById('confirm').classList.add('open'); document.getElementById('confirm').setAttribute('aria-hidden', 'false'); document.getElementById('cancelState').focus();
}
function closeConfirm() { document.getElementById('confirm').classList.remove('open'); document.getElementById('confirm').setAttribute('aria-hidden', 'true'); if (confirmReturnFocus?.isConnected) confirmReturnFocus.focus(); else app.querySelector('button')?.focus(); }
document.getElementById('cancelState').onclick = closeConfirm;
document.getElementById('applyState').onclick = () => { const p = byId(state.current); p.state = p.state === 'ACTIVA' ? 'INACTIVA' : 'ACTIVA'; p.everActivated = p.everActivated || p.state === 'ACTIVA'; render(); closeConfirm(); notify('Estado actualizado en esta demostración.'); };
document.addEventListener('keydown', event => { if (!document.getElementById('confirm').classList.contains('open')) return; if (event.key === 'Escape') closeConfirm(); if (event.key === 'Tab') { const first = document.getElementById('cancelState'), last = document.getElementById('applyState'); if (event.shiftKey && document.activeElement === first) { event.preventDefault(); last.focus(); } else if (!event.shiftKey && document.activeElement === last) { event.preventDefault(); first.focus(); } } });
window.addEventListener('hashchange', render);
render();
