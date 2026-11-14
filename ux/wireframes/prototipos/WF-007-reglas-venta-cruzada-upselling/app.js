const products = [
  {id: 'p1', name: 'Zapatillas Run Pro', active: true},
  {id: 'p2', name: 'Medias deportivas', active: true},
  {id: 'p3', name: 'Botella deportiva', active: true},
  {id: 'p4', name: 'Zapatillas Run Pro Max', active: true},
  {id: 'p5', name: 'Zapatillas Trail Elite', active: true},
  {id: 'p6', name: 'Modelo retirado', active: false}
];
const categories = [{id: 'running', name: 'Zapatillas de running', active: true}];
const criteria = {MAYOR_RENDIMIENTO: 'Mayor rendimiento', MEJOR_MATERIAL: 'Mejor material', MAYOR_CAPACIDAD: 'Mayor capacidad', FUNCIONALIDAD_ADICIONAL: 'Funcionalidad adicional'};
let rules = [
  {name: 'Complementos para running', type: 'CROSS_SELL', origin: {type: 'PRODUCTO', id: 'p1'}, priority: 1, state: 'ACTIVO', start: '2026-10-01T00:00', end: '2026-10-31T23:59', items: [{productId: 'p2', order: 1, criterion: '', note: ''}]},
  {name: 'Mejora de calzado', type: 'UPSELL', origin: {type: 'CATEGORIA', id: 'running'}, priority: 2, state: 'ACTIVO', start: '2026-10-01T00:00', end: '2026-10-31T23:59', items: [{productId: 'p4', order: 1, criterion: 'MAYOR_RENDIMIENTO', note: 'Amortiguación adicional.'}]}
];
const s = {view: 'list', i: null, form: null, errors: {}};
const app = document.getElementById('app');
const esc = value => String(value ?? '').replace(/[&<>"']/g, c => ({'&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'}[c]));
const productName = id => products.find(p => p.id === id)?.name || 'Producto no disponible';
const originName = origin => (origin.type === 'PRODUCTO' ? products : categories).find(x => x.id === origin.id)?.name || 'Origen no disponible';
const typeName = type => type === 'UPSELL' ? 'Upselling' : 'Venta cruzada';
const stateName = state => state === 'ACTIVO' ? 'Activa' : 'Inactiva';
const date = value => new Date(value).toLocaleString('es-PE', {dateStyle: 'short', timeStyle: 'short'});
function head(title, actions = '') { return `<div class="head"><h1>${esc(title)}</h1><div>${actions}</div></div>`; }
function render() {
  const denied = {'#no-permission': 'No tienes permiso para administrar recomendaciones.', '#session-expired': 'Tu sesión finalizó. Ingresa nuevamente.'}[location.hash];
  if (denied) { app.innerHTML = head('Venta cruzada y upselling') + `<p role="alert">${denied}</p>`; return; }
  if (s.view === 'form') form(); else if (s.view === 'detail') detail(); else list();
}
function list() {
  app.innerHTML = head('Venta cruzada y upselling', '<button class="btn primary" data-a="new">Crear regla</button>') + '<p class="muted">Demostración local: los cambios duran hasta recargar la página.</p>';
  if (location.hash === '#list-loading') { app.innerHTML += '<p role="status">Cargando reglas…</p>'; return; }
  const rows = location.hash === '#list-empty' ? [] : rules;
  if (!rows.length) { app.innerHTML += '<p>No hay reglas de recomendación.</p>'; return; }
  app.innerHTML += `<div class="desktop tablewrap"><table><thead><tr><th>Regla</th><th>Tipo</th><th>Origen</th><th>Prioridad</th><th>Vigencia</th><th>Estado</th><th></th></tr></thead><tbody>${rows.map((r, i) => `<tr><td>${esc(r.name)}</td><td>${typeName(r.type)}</td><td>${r.origin.type === 'PRODUCTO' ? 'Producto' : 'Categoría'}: ${esc(originName(r.origin))}</td><td>${r.priority}</td><td>${date(r.start)} — ${date(r.end)}</td><td>${stateName(r.state)}</td><td><button class="btn" data-a="detail" data-i="${i}">Ver</button></td></tr>`).join('')}</tbody></table></div><div class="cards">${rows.map((r, i) => `<article class="rec">${esc(r.name)}<br><button class="btn" data-a="detail" data-i="${i}">Ver</button></article>`).join('')}</div>`;
}
function blank() { return {name: '', type: 'CROSS_SELL', origin: {type: 'PRODUCTO', id: ''}, priority: 1, state: 'INACTIVO', start: '', end: '', items: []}; }
function form() {
  const r = s.form, up = r.type === 'UPSELL';
  const origins = (r.origin.type === 'PRODUCTO' ? products : categories).filter(x => x.active);
  const error = key => `<span class="error" id="${key}-error">${esc(s.errors[key] || '')}</span>`;
  const input = (id, label, type, value) => `<div><label for="${id}">${label}</label><input class="input" id="${id}" type="${type}" value="${esc(value)}" ${type === 'number' ? 'step="any"' : ''} aria-invalid="${!!s.errors[id]}" aria-describedby="${id}-error">${error(id)}</div>`;
  app.innerHTML = head(s.i === null ? 'Crear regla' : 'Editar regla') + `<form class="panel" id="form" novalidate><div class="grid">
    ${input('name', 'Nombre', 'text', r.name)}
    <fieldset><legend>Tipo</legend><label><input type="radio" name="kind" value="CROSS_SELL" ${!up ? 'checked' : ''}> Venta cruzada</label><label><input type="radio" name="kind" value="UPSELL" ${up ? 'checked' : ''}> Upselling</label></fieldset>
    <div><label for="originType">Tipo de origen</label><select id="originType"><option value="PRODUCTO" ${r.origin.type === 'PRODUCTO' ? 'selected' : ''}>Producto</option><option value="CATEGORIA" ${r.origin.type === 'CATEGORIA' ? 'selected' : ''}>Categoría</option></select></div>
    <div><label for="origin">Origen</label><select id="origin" aria-describedby="origin-error"><option value="">Seleccionar</option>${origins.map(x => `<option value="${x.id}" ${r.origin.id === x.id ? 'selected' : ''}>${esc(x.name)}</option>`).join('')}</select>${error('origin')}</div>
    ${input('prio', 'Prioridad', 'number', r.priority)}${input('start', 'Inicio', 'datetime-local', r.start)}${input('end', 'Fin', 'datetime-local', r.end)}
    <div><label for="ruleState">Estado</label><select id="ruleState"><option value="ACTIVO" ${r.state === 'ACTIVO' ? 'selected' : ''}>Activa</option><option value="INACTIVO" ${r.state === 'INACTIVO' ? 'selected' : ''}>Inactiva</option></select></div>
    <div class="wide"><div class="row"><h2>Recomendados</h2><button type="button" class="btn" data-a="add">Agregar</button></div>${error('items')}
    ${r.items.map((x, i) => `<article class="rec"><div class="row"><strong>${esc(productName(x.productId))}</strong><button type="button" class="btn" data-a="remove" data-i="${i}" aria-label="Quitar ${esc(productName(x.productId))}">Quitar</button></div><div class="grid"><div><label for="order-${i}">Orden</label><input class="input ord" id="order-${i}" data-i="${i}" type="number" step="any" value="${x.order}" aria-describedby="order-${i}-error">${error('order-' + i)}</div>
    ${up ? `<div><label for="criterion-${i}">Criterio de superioridad</label><select class="crit" id="criterion-${i}" data-i="${i}" aria-describedby="criterion-${i}-error"><option value="">Seleccionar</option>${Object.entries(criteria).map(([value, label]) => `<option value="${value}" ${x.criterion === value ? 'selected' : ''}>${label}</option>`).join('')}</select>${error('criterion-' + i)}</div><div class="wide"><label for="note-${i}">Justificación (opcional, hasta 500 caracteres)</label><textarea class="note" id="note-${i}" data-i="${i}" maxlength="500" aria-describedby="note-${i}-error">${esc(x.note)}</textarea>${error('note-' + i)}</div>` : ''}</div></article>`).join('')}</div>
    </div><p id="err" role="alert">${Object.keys(s.errors).length ? 'Corrige los campos indicados.' : ''}</p><div class="row"><button type="button" class="btn" data-a="back">Cancelar</button><button class="btn primary">Guardar</button></div></form>`;
}
function sync() {
  if (s.view !== 'form') return;
  const r = s.form;
  r.name = document.getElementById('name').value;
  r.type = app.querySelector('input[name="kind"]:checked').value;
  r.origin = {type: document.getElementById('originType').value, id: document.getElementById('origin').value};
  r.priority = Number(document.getElementById('prio').value);
  r.state = document.getElementById('ruleState').value;
  r.start = document.getElementById('start').value; r.end = document.getElementById('end').value;
  app.querySelectorAll('.ord').forEach(x => r.items[x.dataset.i].order = Number(x.value));
  app.querySelectorAll('.crit').forEach(x => r.items[x.dataset.i].criterion = x.value);
  app.querySelectorAll('.note').forEach(x => r.items[x.dataset.i].note = x.value);
}
function validateRule(r) {
  const e = {};
  if (!r.name.trim()) e.name = 'Ingresa un nombre.';
  const origins = r.origin.type === 'PRODUCTO' ? products : r.origin.type === 'CATEGORIA' ? categories : [];
  if (!origins.some(x => x.id === r.origin.id && x.active)) e.origin = 'Selecciona un origen activo.';
  if (!Number.isSafeInteger(r.priority) || r.priority < 1) e.prio = 'Ingresa una prioridad entera positiva.';
  if (!r.start || !Number.isFinite(Date.parse(r.start))) e.start = 'Indica el inicio.';
  if (!r.end || !Number.isFinite(Date.parse(r.end)) || Date.parse(r.end) <= Date.parse(r.start)) e.end = 'El fin debe ser posterior al inicio.';
  if (!['ACTIVO', 'INACTIVO'].includes(r.state)) e.ruleState = 'Selecciona un estado válido.';
  if (!r.items.length) e.items = 'Agrega al menos un recomendado.';
  const seen = new Set();
  r.items.forEach((item, i) => {
    if (!products.some(p => p.id === item.productId && p.active) || seen.has(item.productId) || (r.origin.type === 'PRODUCTO' && r.origin.id === item.productId)) e.items = 'Los recomendados deben estar activos, no repetirse ni ser el origen.';
    seen.add(item.productId);
    if (!Number.isSafeInteger(item.order) || item.order < 1) e['order-' + i] = 'Ingresa un orden entero positivo.';
    if (r.type === 'UPSELL' && !Object.hasOwn(criteria, item.criterion)) e['criterion-' + i] = 'Selecciona un criterio para este Upselling.';
    if (Array.from(item.note).length > 500) e['note-' + i] = 'Usa hasta 500 caracteres.';
  });
  return e;
}
function save(event) {
  event.preventDefault(); sync(); s.errors = validateRule(s.form);
  if (Object.keys(s.errors).length) { form(); (document.getElementById(Object.keys(s.errors)[0]) || document.getElementById('err')).focus(); return; }
  if (location.hash === '#save-error') { document.getElementById('err').textContent = 'No se pudo guardar. Tus datos se conservan; vuelve a intentarlo.'; return; }
  const saved = structuredClone(s.form); saved.name = saved.name.trim();
  if (s.i === null) rules.unshift(saved); else rules[s.i] = saved;
  s.view = 'list'; render();
}
function detail() {
  const r = rules[s.i];
  if (!r) { s.view = 'list'; render(); return; }
  app.innerHTML = head(r.name, '<button class="btn" data-a="edit">Editar</button>') + `<section class="panel"><p>${typeName(r.type)} · Prioridad ${r.priority}</p><p>Origen: ${r.origin.type === 'PRODUCTO' ? 'Producto' : 'Categoría'} ${esc(originName(r.origin))}</p><p><strong>Estado:</strong> ${stateName(r.state)}</p><p>Vigencia: ${date(r.start)} — ${date(r.end)}</p><p class="rec">Las recomendaciones no agregan ni reemplazan productos automáticamente.</p>
    ${[...r.items].sort((a, b) => a.order - b.order).map(x => `<article class="rec">${x.order}. <strong>${esc(productName(x.productId))}</strong><p>Precio: No disponible · Disponibilidad: No disponible</p>${r.type === 'UPSELL' ? `<p>Criterio: ${criteria[x.criterion]}${x.note ? ' · ' + esc(x.note) : ''}</p>` : ''}</article>`).join('')}
    <div class="row"><button class="btn" data-a="back">Volver</button><button class="btn primary" data-a="toggle">${r.state === 'ACTIVO' ? 'Desactivar' : 'Activar'} regla</button></div></section>`;
}
function openPicker() {
  sync();
  const available = products.filter(p => p.active && !s.form.items.some(x => x.productId === p.id) && !(s.form.origin.type === 'PRODUCTO' && s.form.origin.id === p.id));
  document.getElementById('pick').innerHTML = available.map(p => `<option value="${p.id}">${esc(p.name)}</option>`).join('');
  document.getElementById('addPick').disabled = !available.length;
  document.getElementById('pickerEmpty').textContent = available.length ? '' : 'No hay otros productos activos disponibles.';
  openDialog('picker');
}
app.onclick = event => {
  const button = event.target.closest('[data-a]'); if (!button) return;
  const action = button.dataset.a;
  if (action === 'new') { s.i = null; s.form = blank(); s.errors = {}; s.view = 'form'; }
  if (action === 'detail') { s.i = Number(button.dataset.i); s.view = 'detail'; }
  if (action === 'edit') { s.form = structuredClone(rules[s.i]); s.errors = {}; s.view = 'form'; }
  if (action === 'back') s.view = 'list';
  if (action === 'add') { openPicker(); return; }
  if (action === 'remove') { sync(); s.form.items.splice(Number(button.dataset.i), 1); s.errors = {}; }
  if (action === 'toggle') { const r = rules[s.i]; document.getElementById('stateTitle').textContent = r.state === 'ACTIVO' ? 'Desactivar regla' : 'Activar regla'; document.getElementById('stateText').textContent = r.state === 'ACTIVO' ? 'La regla dejará de participar en nuevas recomendaciones.' : 'Participará cuando esté vigente y coincida con el origen consultado.'; openDialog('stateModal'); return; }
  render();
};
app.onchange = event => {
  if (s.view !== 'form') return;
  const previousOriginType = s.form.origin.type;
  sync();
  if (event.target.id === 'originType' && previousOriginType !== s.form.origin.type) s.form.origin.id = '';
  if (event.target.name === 'kind' || event.target.id === 'originType') form();
};
app.onsubmit = save;
let dialogReturnFocus;
function openDialog(id) { dialogReturnFocus = document.activeElement; const dialog = document.getElementById(id); dialog.classList.add('open'); dialog.querySelector('select,button')?.focus(); }
function closeDialog(id) { document.getElementById(id).classList.remove('open'); if (dialogReturnFocus?.isConnected) dialogReturnFocus.focus(); else app.querySelector('button')?.focus(); }
document.getElementById('cancelPick').onclick = () => closeDialog('picker');
document.getElementById('addPick').onclick = () => { const id = document.getElementById('pick').value; if (!id) return; s.form.items.push({productId: id, order: s.form.items.length + 1, criterion: '', note: ''}); form(); closeDialog('picker'); };
document.getElementById('stateCancel').onclick = () => closeDialog('stateModal');
document.getElementById('stateConfirm').onclick = () => { const r = rules[s.i]; r.state = r.state === 'ACTIVO' ? 'INACTIVO' : 'ACTIVO'; render(); closeDialog('stateModal'); };
document.addEventListener('keydown', event => {
  const dialog = document.querySelector('.overlay.open'); if (!dialog) return;
  if (event.key === 'Escape') closeDialog(dialog.id);
  if (event.key === 'Tab') { const controls = [...dialog.querySelectorAll('button,select')].filter(x => !x.disabled), first = controls[0], last = controls[controls.length - 1]; if (event.shiftKey && document.activeElement === first) { event.preventDefault(); last.focus(); } else if (!event.shiftKey && document.activeElement === last) { event.preventDefault(); first.focus(); } }
});
window.addEventListener('hashchange', render);
render();
