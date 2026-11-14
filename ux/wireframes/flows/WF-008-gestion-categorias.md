# WF-008 — Gestión de categorías y subcategorías

> Fuentes: SPEC-008, HU-008, DESIGN.md, INDEX.md. Prevalece SPEC → HU → WF.

## 0. Producción
- Jerarquía recursiva, MVP 2 niveles.
- Nombre no único.
- Padre editable.
- Categorías no definen características.
- Baja lógica con estado pendiente; solo resultado seguro la confirma.
- No eliminación física.
- Crear consume slug de SEO y **muestra el slug final antes de confirmar**.
- Si existe sufijo por colisión, abrir una confirmación explícita.
- No editar SEO en esta UI.
- Estilo monocromático.

## 1. Metadatos
| Campo | Valor |
|---|---|
| ID | WF-008 |
| Versión | 0.7 |
| Estado | Alineado |
| Responsable | Leonardo Lopez |
| Última actualización | 2026-09-29 |

## 2. Pantallas
S-01 árbol; S-02 crear; S-02-C confirmar slug; S-03 editar; S-04 desactivar; S-04-P verificando; S-04-B bloqueada; S-05 detalle; S-05-R reactivación bloqueada.

## 3. Crear
Campos: nombre, descripción, imagen, orden, padre opcional.

Antes de crear:
1. solicitar `POST /api/v1/seo/categorias/slug/resolver` con el nombre;
2. mostrar `/categoria/{slug}`;
3. si `colisionResuelta=true`, destacar que se aplicó un sufijo;
4. `Confirmar creación` o `Volver`;
5. al confirmar, enviar exactamente ese valor como `slugConfirmado` en `POST /api/v1/categorias`.

Si la creación responde `409 SLUG_DUPLICADO` porque otra operación ocupó el slug entre la propuesta y el commit, no mostrar el alta como completada y no aceptar un cambio automático de URL: volver a resolver, mostrar la nueva propuesta y pedir otra confirmación.

## 4. Editar
`categoria_padre_id` editable. Validar padre activo, ciclo y profundidad. No editar slug.

## 5. Baja
Secuencia visible:
`Solicitud recibida → Verificando dependencias → Confirmada / Rechazada`.

No prometer timeout fijo. No desactivar al recibir solo admisión.

## 6. Contratos EDA confirmados
- `taxonomy.master.deactivation.check.requested`
- `catalog.master.deactivation.checked`
- `taxonomy.master.deactivated`
- `taxonomy.master.deactivation.rejected`
- `taxonomy.category.updated`

No inventar eventos adicionales.

## 7. Accesibilidad/responsive
320px, 44px, tabla contenida/tarjetas, foco visible, diálogos accesibles.

## 8. Registro
v0.7 incorpora en el prototipo la recuperación ante una carrera de slug: nueva resolución y segunda confirmación sin exponer códigos técnicos.
v0.6 cierra el contrato HTTP de creación en dos pasos: resolver, mostrar, confirmar y re-resolver ante carrera de concurrencia.  
v0.5 incorpora confirmación explícita del slug final de creación y conserva la baja segura EDA.
