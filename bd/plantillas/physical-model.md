# _TEMPLATE — Modelo Físico de Base de Datos

> Plantilla estándar para documentar el modelo físico de un bounded context.
> Completar **una copia por servicio** en la carpeta de persistencia del microservicio.

---

## 1. Identificación

- **Servicio:** [nombre-svc]
- **Schema:** [nombre_schema]
- **Bounded context:** [nombre del contexto]
- **Responsable:** [Nombre del desarrollador]
- **Documentos relacionados:** `physical-model.md` / `migrations/` / `validation.sql`
- **Última actualización:** YYYY-MM-DD

---

## 2. Alcance del bounded context

Describir en una o dos frases qué datos posee este servicio y qué datos **no** posee.

```text
Posee:
- [entidad]
- [entidad]

No posee (son de otro owner):
- [dato] -> [owner]
```

Fuente: [`Modelo_Conceptual.md`](../../Modelo_Conceptual.md) y [`Contrato_Api.md`](../../Contrato_Api.md).

---

## 3. Convenciones aplicadas

Declarar que este modelo sigue [`CONVENCIONES_BD.md`](../CONVENCIONES_BD.md) y registrar las decisiones locales que se apartan, con su motivo.

| Decisión local | ¿Se aparta de la convención? | Motivo | Aprobado por |
|---|---|---|---|
| [decisión] | [no / sí] | [motivo] | [persona, fecha] |

> Si no hay apartamientos, escribir: *Sin apartamientos. Este modelo aplica íntegramente las convenciones vigentes.*

---

## 4. Inventario de tablas

| Tabla | Propósito | PK | ¿Append-only? |
|---|---|---|---|
| [nombre] | [qué representa] | [columna] | [sí / no] |

Toda tabla listada aquí debe existir en `migrations/` y ser verificable en `validation.sql`.

---

## 5. Modelo por tabla

Repetir esta sección por cada tabla.

### 5.N. [nombre_de_tabla]

**Propósito:** [qué representa y quién lo consume]

**Estabilidad:** `mutable` | `append-only`

**Columnas:**

| Columna | Tipo | Null | Default | Restricciones |
|---|---|---|---|---|
| [columna] | [tipo] | [sí/no] | [default] | [PK, FK, UNIQUE, CHECK, NN] |

**Índices:**

| Índice | Columnas | Tipo | Justificación |
|---|---|---|---|
| [ix_nombre] | [columnas] | [btree / parcial / compuesto] | [consulta que lo justifica] |

**Disparadores:**

| Disparador | Evento | Función |
|---|---|---|
| [trg_nombre_updated_at] | `BEFORE UPDATE` | `fn_set_updated_at` |

**Reglas de borrado:**

- `estado`: [enum aplicado / no aplica]
- `deleted_at`: [sí, con motivo / no, con motivo]
- `ON DELETE`: [RESTRICT / CASCADE — aplica solo a FK]

---

## 6. Referencias externas

Referencias a datos de otros bounded contexts. **Ninguna puede ser FK.** Verificar contra `CONVENCIONES_BD.md` §4.

| Columna | Tipo | Schema dueño | Se puebla desde | ¿Tiene columna de versión? |
|---|---|---|---|---|
| [columna] | [tipo] | [schema] | [contrato/evento] | [sí: columna / no] |

> Justificación de por qué no hay FK:

---

## 7. Outbox e Inbox

| Tabla | ¿Aplica? | Motivo |
|---|---|---|
| `outbox` | [sí / no] | [publica hechos de dominio / no publica] |
| `inbox` | [sí / no] | [consume eventos / no consume] |

Si no aplican, declarar el motivo. No se crean tablas vacías por simetría.

**Campos no estándar que este servicio agrega** (además de la estructura común):

| Campo | Tipo | Motivo |
|---|---|---|
| [campo] | [tipo] | [motivo] |

**Idempotencia de negocio:**

| Tabla | Restricción | Regla |
|---|---|---|
| [tabla] | `uq_[nombre] UNIQUE (operation_id)` | [misma identidad + misma intención = replay sin efectos] |

---

## 8. Enumeraciones

| Tipo | Valores | Por qué es tipo nativo y no `text + CHECK` |
|---|---|---|
| [schema.tipo] | ['A','B'] | [estado de ciclo de vida propio y publicado en contrato] |

Si un tipo declarado en otro schema aparece referenciado aquí, la convención está violada. Verificar `CONVENCIONES_BD.md` §13.3.

---

## 9. Proyecciones locales

Datos duplicados de otros owners, sin FK y con owner explícito.

| Tabla | Proyecta desde | Columnas de versionado | Evento que la actualiza |
|---|---|---|---|
| [tabla] | [schema] | [columnas] | [evento] |

Regla vigente: duplicar para leer **no** es compartir ownership.

---

## 10. Reglas de escritura

| Regla | Implementación |
|---|---|
| Idempotencia | [restricción] |
| Concurrencia optimista | [columna `*_version` o similar] |
| Reservas | [transición terminal única] |
| Estado de escritura | [constraint] |

---

## 11. Excepciones a las convenciones

Declarar cualquier tabla exceptuada de `updated_at`/`deleted_at` con su motivo.

| Tabla | Columna exceptuada | Motivo |
|---|---|---|
| [tabla] | [updated_at / deleted_at] | [append-only] |

---

## 12. Checklist de aprobación

- [ ] No existe FK entre schemas de servicios distintos.
- [ ] No existe acceso SQL cross-service.
- [ ] Toda FK tiene índice en su columna referenciante.
- [ ] Toda tabla tiene `created_at timestamptz NOT NULL DEFAULT now()`.
- [ ] `updated_at` existe salvo en tablas exentas declaradas en §11.
- [ ] No hay `float`, `real`, `double precision` ni `money`.
- [ ] No hay `timestamp` sin zona horaria.
- [ ] No hay `serial`, `bigserial` ni PK natural.
- [ ] Los tipos enumerados son locales a este schema.
- [ ] Toda constraint, índice, disparador y función lleva prefijo.
- [ ] `estado` y `deleted_at` no se usan para el mismo propósito.
- [ ] Las referencias externas son columnas escalares sin FK.
- [ ] `outbox` existe solo si el servicio publica eventos.
- [ ] El registro en `outbox` está dentro de la transacción de negocio.
- [ ] No se FK a `auth.users`; el usuario es `user_id text`.
- [ ] Las migraciones se ejecutan desde cero en una base vacía.
- [ ] `validation.sql` devuelve todos los checks en `PASS`.