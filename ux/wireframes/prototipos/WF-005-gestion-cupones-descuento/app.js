const promotions = [
  {id: 'pm1', name: '20% primera compra', mode: 'CUPON'},
  {id: 'pm2', name: '10% temporada', mode: 'CUPON'},
  {id: 'pm3', name: '15% accesorios', mode: 'CUPON'}
];
let coupons = [
  {id: 'c1', code: 'BIENVENIDA20', promotion: 'pm1', state: 'ACTIVO', minimum: null, globalLimit: 500, customerLimit: 1, policy: 'RESTAURAR_EN_CANCELACION', used: 83},
  {id: 'c2', code: 'SETIEMBRE10', promotion: 'pm2', state: 'INACTIVO', minimum: null, globalLimit: null, customerLimit: 2, policy: 'NO_RESTAURAR', used: 0}
];
const app = document.getElementById('couponApp');
const modal = document.getElementById('couponModal');
const escapeHtml = value => String(value ?? '').replace(/[&<>"']/g, c => ({'&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'}[c]));
const normalizeCode = value => value.trim().toUpperCase();
const limit = value => value === null ? 'Sin límite' : String(value);
const policyLabel = value => value === 'RESTAURAR_EN_CANCELACION' ? 'Restaurar al cancelar' : 'No restaurar';
let currentId = null, returnFocus = null;

function renderList() {
  const blocked = {'#no-permission': 'No tienes permiso para administrar cupones.', '#session-expired': 'Tu sesión finalizó. Ingresa nuevamente.'}[location.hash];
  app.innerHTML = `<div class="page-head"><div><h1>Gestión de cupones de descuento</h1><p>Crea cupones, configura límites y define qué ocurre con su uso cuando un pedido se cancela.</p></div>${blocked ? '' : '<button class="btn primary" data-action="create">Crear cupón</button>'}</div>
    <div class="notice soft">Demostración local: los cambios duran hasta recargar la página. Validar un cupón no consume su uso; el consumo y la restitución se realizan automáticamente desde el pedido.</div>`;
  if (blocked) { app.innerHTML += `<p role="alert">${blocked}</p>`; return; }
  if (location.hash === '#list-loading') { app.innerHTML += '<p role="status">Cargando cupones…</p>'; return; }
  const rows = location.hash === '#list-empty' ? [] : coupons;
  app.innerHTML += rows.length ? `<div class="table-wrap" style="margin-top:16px"><table><thead><tr><th>Código</th><th>Promoción</th><th>Estado</th><th>Uso global</th><th>Límite por cliente</th><th>Restitución</th><th>Acciones</th></tr></thead><tbody>${rows.map(c => `<tr><td><strong>${escapeHtml(c.code)}</strong></td><td>${escapeHtml(promotions.find(p => p.id === c.promotion)?.name)}</td><td>${c.state === 'ACTIVO' ? 'Activo' : 'Inactivo'}</td><td>${c.used} / ${limit(c.globalLimit)}</td><td>${limit(c.customerLimit)}</td><td>${policyLabel(c.policy)}</td><td><button class="btn ghost" data-action="detail" data-id="${c.id}">Ver</button></td></tr>`).join('')}</tbody></table></div>` : '<p class="empty">No hay cupones.</p>';
}

function openModal(title, body) {
  returnFocus = document.activeElement;
  document.getElementById('modalTitle').textContent = title;
  document.getElementById('modalBody').innerHTML = body;
  modal.classList.add('open');
  modal.querySelector('#modalBody input, #modalBody button, #modalBody select')?.focus();
}
function closeModal() {
  modal.classList.remove('open');
  if (returnFocus?.isConnected) returnFocus.focus();
  else app.querySelector('button')?.focus();
}
function field(id, label, type, value, help = '') {
  return `<div class="field"><label for="${id}">${label}</label><input class="input" id="${id}" name="${id}" type="${type}" value="${escapeHtml(value)}" ${type === 'number' ? 'step="any"' : ''} aria-describedby="${id}-help ${id}-error"><span class="help" id="${id}-help">${help}</span><span id="${id}-error" class="help"></span></div>`;
}
function openForm(id = null) {
  currentId = id;
  const c = coupons.find(x => x.id === id) || {code: '', promotion: '', state: 'ACTIVO', minimum: null, globalLimit: null, customerLimit: null, policy: 'RESTAURAR_EN_CANCELACION'};
  openModal(id ? 'Editar cupón' : 'Crear cupón', `<form id="couponForm" class="stack" novalidate><div class="grid two">
    ${field('code', 'Código', 'text', c.code, 'Letras, números, guion y guion bajo. Se guarda en mayúsculas.')}
    <div class="field"><label for="promotion">Promoción asociada</label><select id="promotion" class="select"><option value="">Seleccionar</option>${promotions.filter(p => p.mode === 'CUPON').map(p => `<option value="${p.id}" ${c.promotion === p.id ? 'selected' : ''}>${escapeHtml(p.name)}</option>`).join('')}</select><span class="help" id="promotion-error"></span></div>
    <div class="field"><label for="couponState">Estado</label><select id="couponState" class="select"><option value="ACTIVO" ${c.state === 'ACTIVO' ? 'selected' : ''}>Activo</option><option value="INACTIVO" ${c.state === 'INACTIVO' ? 'selected' : ''}>Inactivo</option></select></div>
    ${field('minimum', 'Monto mínimo', 'number', c.minimum, 'Vacío = sin monto mínimo. Si se indica, debe ser mayor que cero.')}
    ${field('globalLimit', 'Límite global', 'number', c.globalLimit, 'Vacío = Sin límite. Si se indica, entero positivo.')}
    ${field('customerLimit', 'Límite por cliente', 'number', c.customerLimit, 'Vacío = Sin límite. Si se indica, entero positivo.')}
    <div class="field"><label for="policy">Restitución</label><select id="policy" class="select"><option value="RESTAURAR_EN_CANCELACION" ${c.policy === 'RESTAURAR_EN_CANCELACION' ? 'selected' : ''}>Restaurar uso al cancelar</option><option value="NO_RESTAURAR" ${c.policy === 'NO_RESTAURAR' ? 'selected' : ''}>No restaurar</option></select></div>
    </div><p id="formError" role="alert"></p><div class="actions"><button type="button" class="btn" data-modal="close">Cancelar</button><button class="btn primary">Guardar</button></div></form>`);
  document.getElementById('couponForm').onsubmit = saveCoupon;
}
function saveCoupon(event) {
  event.preventDefault();
  const get = id => document.getElementById(id).value;
  const errors = {};
  const code = normalizeCode(get('code'));
  if (!/^[A-Z0-9_-]+$/.test(code)) errors.code = 'Ingresa un código válido.';
  else if (coupons.some(c => c.id !== currentId && normalizeCode(c.code) === code)) errors.code = 'Ya existe un cupón con este código.';
  const promotion = get('promotion');
  if (!promotions.some(p => p.id === promotion && p.mode === 'CUPON')) errors.promotion = 'Selecciona una promoción mediante cupón.';
  const values = {};
  for (const id of ['minimum', 'globalLimit', 'customerLimit']) {
    const raw = get(id).trim();
    values[id] = raw === '' ? null : Number(raw);
    if (raw !== '' && (!Number.isFinite(values[id]) || values[id] <= 0 || (id !== 'minimum' && !Number.isSafeInteger(values[id])))) errors[id] = id === 'minimum' ? 'Ingresa un monto mayor que cero.' : 'Ingresa un entero positivo o deja el campo vacío.';
  }
  for (const id of ['code', 'promotion', 'minimum', 'globalLimit', 'customerLimit']) {
    document.getElementById(id + '-error').textContent = errors[id] || '';
    document.getElementById(id).setAttribute('aria-invalid', String(!!errors[id]));
  }
  if (Object.keys(errors).length) { document.getElementById('formError').textContent = 'Corrige los campos indicados.'; document.getElementById(Object.keys(errors)[0]).focus(); return; }
  if (location.hash === '#save-error') { document.getElementById('formError').textContent = 'No se pudo guardar. Tus datos se conservan; vuelve a intentarlo.'; return; }
  const existing = coupons.find(c => c.id === currentId);
  const saved = {id: currentId || 'c' + Date.now(), code, promotion, state: get('couponState'), policy: get('policy'), ...values, used: existing?.used || 0};
  if (existing) Object.assign(existing, saved); else coupons.unshift(saved);
  closeModal(); renderList(); showToast('Cupón guardado en esta demostración.');
}
function showDetail(id) {
  const c = coupons.find(x => x.id === id);
  if (!c) return;
  currentId = id;
  const entries = [['Código', c.code], ['Promoción', promotions.find(p => p.id === c.promotion)?.name], ['Estado', c.state === 'ACTIVO' ? 'Activo' : 'Inactivo'], ['Monto mínimo', c.minimum === null ? 'Sin monto mínimo' : 'S/ ' + c.minimum.toFixed(2)], ['Uso global', `${c.used} / ${limit(c.globalLimit)}`], ['Usos disponibles', c.globalLimit === null ? 'Sin límite' : Math.max(c.globalLimit - c.used, 0)], ['Límite por cliente', limit(c.customerLimit)], ['Al cancelar', policyLabel(c.policy)]];
  openModal('Detalle del cupón', `<ul class="summary-list">${entries.map(([label, value]) => `<li><span>${label}</span><strong>${escapeHtml(value)}</strong></li>`).join('')}</ul><p class="notice soft">No hay acciones manuales para consumir o devolver usos. Esas operaciones se ejecutan automáticamente desde el pedido.</p><div class="actions"><button class="btn" data-modal="edit">Editar</button><button class="btn" data-modal="state">${c.state === 'ACTIVO' ? 'Desactivar' : 'Activar'}</button><button class="btn" data-modal="close">Volver</button></div>`);
}
function confirmState() {
  const c = coupons.find(x => x.id === currentId);
  openModal(c.state === 'ACTIVO' ? 'Desactivar cupón' : 'Activar cupón', '<p>El cambio afecta nuevas validaciones y no modifica los usos registrados.</p><div class="actions"><button class="btn" data-modal="cancelState">Cancelar</button><button class="btn primary" data-modal="confirmState">Confirmar</button></div>');
}
function showToast(message) { const toast = document.getElementById('toast5'); toast.textContent = message; toast.classList.remove('hidden'); setTimeout(() => toast.classList.add('hidden'), 2000); }
app.onclick = event => {
  const button = event.target.closest('[data-action]');
  if (!button) return;
  if (button.dataset.action === 'create') openForm();
  if (button.dataset.action === 'detail') showDetail(button.dataset.id);
};
modal.onclick = event => {
  const action = event.target.closest('[data-modal]')?.dataset.modal;
  if (action === 'close') closeModal();
  if (action === 'edit') openForm(currentId);
  if (action === 'state') confirmState();
  if (action === 'cancelState') showDetail(currentId);
  if (action === 'confirmState') { const c = coupons.find(x => x.id === currentId); c.state = c.state === 'ACTIVO' ? 'INACTIVO' : 'ACTIVO'; renderList(); showDetail(currentId); }
};
document.addEventListener('keydown', event => {
  if (!modal.classList.contains('open')) return;
  if (event.key === 'Escape') closeModal();
  if (event.key === 'Tab') {
    const controls = [...modal.querySelectorAll('button,input,select')].filter(x => !x.disabled);
    const first = controls[0], last = controls[controls.length - 1];
    if (event.shiftKey && document.activeElement === first) { event.preventDefault(); last.focus(); }
    else if (!event.shiftKey && document.activeElement === last) { event.preventDefault(); first.focus(); }
  }
});
window.addEventListener('hashchange', renderList);
renderList();
