_TEMPLATE — Modelo Físico de Base de Datos

«Plantilla estándar para documentar el modelo físico de un bounded context.

Completar una copia por microservicio/schema dentro de "bd/<schema>/physical-model.md".

Este documento materializa el "logical-model.md" correspondiente en un diseño implementable sobre PostgreSQL/Supabase.

Debe cumplir obligatoriamente las reglas definidas en "bd/CONVENCIONES_BD.md".»

---

1. Identificación

- Issue: #"<N>" — "<título del issue>"
- Responsable: "<nombre del responsable>"
- Bounded context: "<nombre>"
- Microservicio: "<microservicio>"
- Schema: "<schema>"
- Owner exclusivo: "<microservicio>"
- Última actualización: "<AAAA-MM-DD>"
- Estado: "<BORRADOR | EN REVISIÓN | APROBADO>"
- Modelo lógico de origen: "logical-model.md"
- Migraciones: "migrations/"
- Validación: "validation.sql"
- Motor objetivo: PostgreSQL / Supabase

---

2. Fuentes y precedencia

Este modelo físico deriva de las fuentes funcionales, contractuales, arquitectónicas y lógicas vigentes.

Revisar como mínimo, según corresponda:

- "Modelo_Conceptual.md"
- "Arquitectura.md"
- "Contrato_Api.md"
- "api/openapi.yaml"
- "asyncapi/asyncapi.yaml"
- SPEC asociadas
- HU asociadas
- WF asociados
- FLOW asociados
- "logical-model.md"
- "bd/CONVENCIONES_BD.md"
- decisiones inter-módulo vigentes

La precedencia general es:

fuentes funcionales y contractuales
        ↓
modelo conceptual
        ↓
logical-model.md
        ↓
physical-model.md
        ↓
migrations/
        ↓
validation.sql

El modelo físico no puede introducir reglas funcionales nuevas.

Si existe una contradicción entre fuentes, no debe resolverse silenciosamente mediante una decisión de base de datos.

---

3. Propósito

Materializar el modelo lógico del bounded context "<nombre>" como un diseño implementable en PostgreSQL/Supabase.

Este documento define:

- tablas;
- columnas;
- tipos PostgreSQL;
- claves primarias;
- claves foráneas internas;
- restricciones;
- valores por defecto;
- enumeraciones;
- índices;
- funciones y triggers estrictamente necesarios;
- persistencia técnica;
- Outbox/Inbox cuando corresponda;
- proyecciones locales;
- estrategia de idempotencia;
- estrategia de despliegue;
- trazabilidad entre modelo lógico e implementación física.

Toda tabla física debe derivar de al menos uno de los siguientes elementos:

1. una entidad lógica;
2. una relación lógica;
3. una necesidad técnica documentada.

---

4. Alcance del bounded context

4.1. Datos que posee

El bounded context es autoridad sobre:

- "<entidad / dato propio 1>"
- "<entidad / dato propio 2>"
- "<entidad / dato propio 3>"

4.2. Datos que NO posee

No es autoridad sobre:

- "<dato externo>" → owner: "<bounded context / servicio>"
- "<dato externo>" → owner: "<bounded context / servicio>"

Las referencias a datos externos se almacenan únicamente cuando existe una necesidad funcional documentada.

Una referencia externa:

NO transfiere ownership
NO crea acceso SQL cross-service
NO genera FK entre bounded contexts

---

5. Principios de diseño físico

5.1. Aislamiento

Todo el bounded context vive dentro del schema:

<schema>

Owner:

<microservicio>

Está prohibido crear:

- FK hacia schemas de otros microservicios;
- joins operativos cross-service;
- vistas que unan schemas de distintos bounded contexts;
- acceso SQL directo a tablas de otros microservicios;
- "dblink";
- "postgres_fdw";
- dependencias físicas hacia tablas externas al contexto.

Las referencias entre servicios se resuelven mediante contratos HTTP, eventos o proyecciones locales.

---

5.2. Convenciones aplicadas

Este modelo aplica "bd/CONVENCIONES_BD.md".

Registrar únicamente las decisiones locales o excepciones:

Decisión local| ¿Se aparta de la convención?| Motivo| Evidencia / aprobación
"<decisión>"| No/Sí| "<motivo>"| "<fuente>"

Si no existen apartamientos:

Sin apartamientos. Este modelo aplica íntegramente las convenciones vigentes.

No duplicar innecesariamente las convenciones transversales dentro de este documento.

---

6. Inventario de tablas

Tabla| Propósito| Origen| PK| Estabilidad
"<tabla>"| "<qué representa>"| "<entidad lógica / necesidad técnica>"| "<columna>"| "mutable / append-only"

Toda tabla incluida aquí debe:

- aparecer posteriormente en el detalle del modelo;
- existir en "migrations/";
- poder verificarse mediante "validation.sql".

---

7. Enumeraciones y tipos propios

Crear tipos PostgreSQL únicamente cuando exista una justificación funcional y contractual.

7.1. "<schema.enum_name>"

Origen lógico:

logical-model.md §<N>

Valores:

<VALOR_1>
<VALOR_2>
<VALOR_3>

Usado por:

- "<tabla.columna>"
- "<tabla.columna>"

Justificación de tipo nativo:

"<por qué se usa ENUM y no text + CHECK>"

Reglas:

- los enums pertenecen exclusivamente al schema local;
- no se reutilizan enums pertenecientes a otros bounded contexts;
- no introducir valores que no existan en las fuentes funcionales;
- agregar valores en migraciones nuevas, nunca editando migraciones aplicadas.

Si no existen enums:

No se requieren tipos enumerados propios para este bounded context.

---

8. Modelo por tabla

Repetir esta sección por cada tabla.

8.N. "<table_name>"

Origen lógico: "<ENTIDAD / relación / necesidad técnica>"
Propósito: "<qué representa>"
Estabilidad: "mutable | append-only"

Columnas

Columna| Tipo PostgreSQL| Nulo| Default| Restricciones| Origen lógico
"id"| "uuid"| No| "gen_random_uuid()"| PK| Identificador
"<columna>"| "<tipo>"| Sí/No| "<default>"| "<UNIQUE / CHECK / FK / NN>"| "<atributo/regla>"
"created_at"| "timestamptz"| No| "now()"| —| Técnico
"updated_at"| "timestamptz"| No| "now()"| —| Técnico

Clave primaria

<definición>

Claves únicas

Constraint| Columnas| Regla de negocio
"<uq_nombre>"| "<columnas>"| "<regla>"

Foreign keys internas

Constraint| Columna origen| Tabla destino| ON DELETE| Justificación
"<fk_nombre>"| "<columna>"| "<tabla.columna>"| "<RESTRICT/CASCADE/...>"| "<motivo>"

Solo se permiten FK dentro del mismo bounded context.

Constraints

Constraint| Tipo| Expresión| Regla que protege
"<ck_nombre>"| CHECK| "<expresión>"| "<invariante>"

Índices

Índice| Columnas| Tipo| Justificación
"<ix_nombre>"| "<columnas>"| "btree / compuesto / parcial"| "<consulta/proceso>"

Disparadores

Trigger| Evento| Función| Justificación
"<trg_nombre>"| "<BEFORE UPDATE>"| "<fn_nombre>"| "<motivo>"

Si no existen:

No se requieren triggers específicos para esta tabla.

Reglas de borrado

- "estado": "<aplica / no aplica>"
- "deleted_at": "<aplica / no aplica>"
- borrado físico: "<permitido / prohibido>"
- "ON DELETE": "<acción y justificación>"

Notas

- "<decisión física>"
- "<limitación>"
- "<consideración de concurrencia>"
- "<consideración de idempotencia>"

---

9. Referencias externas

Los siguientes identificadores pertenecen a otros bounded contexts y se almacenan sin FK física.

Tabla| Columna| Tipo| Owner| Se obtiene desde| Versión/proyección
"<tabla>"| "<sku>"| "<tipo>"| "catalog-svc"| "<contrato/evento>"| "<columna/no aplica>"
"<tabla>"| "<order_id>"| "<tipo>"| "<Ventas>"| "<contrato>"| "<no aplica>"

Regla:

referencia externa != entidad local autoritativa

Está prohibido:

FOREIGN KEY (...)
REFERENCES otro_schema.otra_tabla(...)

aunque todos los schemas se encuentren físicamente dentro de la misma instancia PostgreSQL/Supabase.

---

10. Constraints e invariantes

Mapear cada invariante del modelo lógico hacia un mecanismo físico.

Regla lógica| Implementación física| Justificación
"<cantidad >= 0>"| "CHECK (...)"| "<motivo>"
"<identidad única>"| "UNIQUE (...)"| "<motivo>"
"<relación obligatoria>"| "NOT NULL + FK interna"| "<motivo>"
"<regla compleja>"| "<trigger / aplicación>"| "<motivo>"

Orden de preferencia:

constraint declarativa
        >
trigger
        >
lógica exclusiva de aplicación

cuando la regla pueda protegerse correctamente desde la base de datos.

No utilizar triggers para reglas expresables de manera segura mediante constraints declarativas.

---

11. Foreign keys

11.1. FK permitidas

Solo dentro del mismo bounded context.

Origen| Destino| Constraint| ON DELETE
"<tabla.columna>"| "<tabla.columna>"| "<fk_nombre>"| "<acción>"

Toda FK debe tener índice en su columna referenciante cuando corresponda según las convenciones vigentes.

11.2. FK prohibidas

No crear FK hacia:

schemas pertenecientes a otros microservicios
auth.users
tablas de otros módulos

Las relaciones interdominio se resuelven mediante contratos.

---

12. Índices

Crear únicamente índices vinculados a:

- constraints;
- consultas reales;
- filtros frecuentes;
- ordenamiento requerido;
- workers;
- polling;
- idempotencia;
- procesamiento de eventos.

Índice| Tabla| Columnas| Tipo| Justificación
"<ix_nombre>"| "<tabla>"| "<columnas>"| "<btree/compuesto/parcial>"| "<consulta>"

No crear índices "por si acaso".

Toda optimización debe tener una razón explícita.

---

13. Funciones y triggers

13.1. "<fn_nombre / trg_nombre>"

Objetivo: "<qué protege>"
Origen lógico: "<regla>"
Tablas involucradas: "<tabla>"
Justificación: "<por qué una constraint declarativa no es suficiente>"

Descripción:

<comportamiento a alto nivel>

Si no son necesarios:

No se requieren funciones ni triggers específicos para este bounded context.

---

14. Outbox e Inbox

14.1. Aplicabilidad

Tabla| ¿Aplica?| Motivo
"outbox"| Sí/No| "<publica/no publica eventos>"
"inbox"| Sí/No| "<consume/no consume eventos>"

No crear tablas vacías únicamente por simetría.

---

14.2. Outbox

Si aplica, su propósito es:

persistir el cambio de negocio y el evento dentro de la misma transacción local

Columnas mínimas esperadas:

Columna| Tipo| Restricción
"id"| "<tipo>"| PK
"message_id" / "event_id"| "<tipo>"| UNIQUE
"message_type"| "<tipo>"| NOT NULL
"aggregate_type"| "<tipo>"| "<restricción>"
"aggregate_id"| "<tipo>"| "<restricción>"
"operation_id"| "<tipo>"| "<restricción>"
"correlation_id"| "<tipo>"| "<restricción>"
"payload"| "<tipo>"| NOT NULL
"status"| "<tipo>"| NOT NULL
"published_at"| "<tipo>"| NULL
"created_at"| "<tipo>"| NOT NULL

Flujo esperado:

BEGIN
    mutación de negocio
    INSERT outbox
COMMIT

publisher
    ↓
publicación
    ↓
confirmación
    ↓
marcar evento como publicado

---

14.3. Inbox

Si aplica, su propósito es:

deduplicar mensajes antes de ejecutar efectos locales

Columnas mínimas:

Columna| Tipo| Restricción
"id"| "<tipo>"| PK
"message_id"| "<tipo>"| UNIQUE
"operation_id"| "<tipo>"| "<restricción>"
"message_type"| "<tipo>"| NOT NULL
"source"| "<tipo>"| NOT NULL
"payload"| "<tipo>"| NOT NULL
"status"| "<tipo>"| NOT NULL
"processed_at"| "<tipo>"| NULL
"created_at"| "<tipo>"| NOT NULL

"message_id" debe permitir deduplicación técnica.

La idempotencia técnica por mensaje no sustituye la idempotencia funcional mediante "operation_id" cuando esta exista.

---

15. Idempotencia y concurrencia

15.1. Idempotencia

Operación / tabla| Identificador| Restricción| Comportamiento ante replay
"<operación>"| "operation_id"| "<UNIQUE/...>"| "<resultado>"

Definir claramente cuándo:

misma identidad + misma intención = replay sin efectos duplicados

---

15.2. Concurrencia

Entidad / tabla| Estrategia| Implementación
"<tabla>"| "<optimista/pesimista/serialización>"| "<version/lock/etc.>"

No introducir mecanismos de concurrencia sin una necesidad funcional o técnica documentada.

---

16. Proyecciones locales

Los datos duplicados de otros owners deben declararse explícitamente.

Tabla / columna| Owner original| Se actualiza desde| Versionado| Reconstruible
"<dato>"| "<servicio>"| "<evento/contrato>"| "<campo>"| Sí/No

Regla:

duplicar para leer != compartir ownership

Una proyección reconstruible no se convierte en fuente de verdad por encontrarse persistida localmente.

---

17. Reglas de escritura

Regla| Implementación física
Idempotencia| "<constraint / tabla>"
Concurrencia| "<estrategia>"
Ciclo de vida| "<enum/check>"
Transición terminal| "<mecanismo>"
Auditoría| "<mecanismo>"
Outbox transaccional| "<mecanismo>"

No incorporar reglas de escritura que no tengan respaldo en el modelo lógico o fuentes oficiales.

---

18. Excepciones de timestamps y borrado

Registrar tablas que justificadamente no utilicen "updated_at", "estado" o "deleted_at".

Tabla| Excepción| Motivo
"<tabla>"| "updated_at"| "append-only"
"<tabla>"| "deleted_at"| "<motivo>"

Toda excepción debe ser deliberada y documentada.

---

19. Diagrama entidad-relación físico

erDiagram

    TABLE_A ||--o{ TABLE_B : "contiene"

    TABLE_A {
        uuid id PK
        text external_id UK
        timestamptz created_at
        timestamptz updated_at
    }

    TABLE_B {
        uuid id PK
        uuid table_a_id FK
        integer quantity
        timestamptz created_at
    }

El diagrama debe mostrar únicamente relaciones físicas reales.

Debe representar:

- tablas;
- PK;
- FK internas;
- claves únicas relevantes;
- columnas necesarias para comprender las relaciones.

No dibujar como FK relaciones que conceptualmente apunten a otros bounded contexts.

---

20. Trazabilidad lógico → físico

Toda tabla física debe aparecer en esta matriz.

Elemento lógico| Materialización física
"<ENTIDAD A>"| "<table_a>"
"<ENTIDAD B>"| "<table_b>"
"<relación A-B>"| "<FK / tabla asociativa>"
"<invariante>"| "<CHECK / UNIQUE / trigger>"
"<referencia externa>"| "<columna sin FK>"
"<Outbox>"| "outbox"
"<Inbox>"| "inbox"
"<proyección>"| "<tabla local>"

Una tabla sin origen lógico o técnico documentado requiere justificación explícita.

---

21. Trazabilidad funcional

Fuente| Elemento físico derivado
"SPEC-XXX"| "<tabla / columna / constraint>"
"HU-XXX"| "<tabla / constraint>"
"WF-XXX"| "<estado / dato>"
"FLOW-XXX"| "<estado / relación / transición>"
OpenAPI| "<campo / identidad / enum>"
AsyncAPI| "<outbox / inbox / evento>"
"Modelo_Conceptual.md"| "<tabla / ownership>"
"Arquitectura.md"| "<schema / aislamiento>"
"logical-model.md"| "<tabla / constraint>"

---

22. Decisiones físicas

Registrar las decisiones que pertenecen específicamente al nivel de implementación.

ID| Decisión| Alternativas consideradas| Justificación| Impacto
"D-PHY-01"| "<decisión>"| "<alternativas>"| "<motivo>"| "<tablas>"

Ejemplos válidos:

- utilizar PK surrogate separada de un identificador contractual;
- utilizar un ENUM PostgreSQL;
- usar "jsonb" para un snapshot no autoritativo;
- crear un índice parcial;
- utilizar una columna generada;
- definir una estrategia específica de concurrencia.

Esta sección no puede utilizarse para introducir reglas funcionales nuevas.

---

23. Decisiones pendientes

ID| Pregunta| Fuente afectada| Impacto| ¿Bloquea migración?
"P-PHY-01"| "<pregunta>"| "<fuente>"| "<impacto>"| Sí/No

Una contradicción funcional no debe resolverse mediante una decisión física local.

---

24. Migraciones

La implementación correspondiente vive en:

bd/<schema>/migrations/

Nomenclatura:

0001_descripcion.sql
0002_descripcion.sql
0003_descripcion.sql

Toda migración debe:

- ser reproducible desde una base limpia;
- modificar únicamente su propio schema;
- crear explícitamente los objetos requeridos;
- respetar el orden de versiones;
- evitar secretos;
- evitar dependencia de creación automática del ORM;
- coincidir con este modelo físico;
- respetar las convenciones de nombres;
- ser compatible con el mecanismo de despliegue vigente;
- no editar una versión ya aplicada en un entorno compartido.

Los cambios destructivos deben seguir estrategia "expand/contract".

---

25. Validación

La validación correspondiente vive en:

bd/<schema>/validation.sql

Debe comprobar como mínimo:

1. existencia del schema;
2. existencia de las tablas;
3. columnas esperadas;
4. tipos;
5. PK;
6. FK internas;
7. ausencia de FK cross-context;
8. "UNIQUE";
9. "CHECK";
10. índices críticos;
11. enums;
12. idempotencia;
13. reglas principales;
14. Outbox/Inbox cuando correspondan;
15. proyecciones cuando correspondan;
16. operaciones representativas del dominio;
17. aislamiento del schema.

Resultado esperado:

todos los checks obligatorios en PASS

La validación no debe dejar fixtures comerciales permanentes.

---

26. Despliegue en Supabase

El schema desplegado debe coincidir exactamente con el código versionado.

Registrar como evidencia:

- entorno;
- commit;
- schema;
- versión de migración;
- checksums;
- fecha;
- resultado;
- versión de PostgreSQL;
- resultado de "validation.sql";
- PR asociado.

No incluir:

- contraseñas;
- API keys;
- tokens;
- connection strings con secretos;
- credenciales de servicios.

Cada owner es responsable del despliegue de su propio schema.

---

27. Checklist de aprobación

27.1. Correspondencia con el modelo lógico

- [ ] Cada entidad lógica requerida tiene materialización física.
- [ ] Toda tabla tiene origen lógico o técnico documentado.
- [ ] No aparecen reglas funcionales nuevas.
- [ ] Las cardinalidades lógicas se conservan.
- [ ] Las referencias externas mantienen su ownership original.

27.2. Aislamiento

- [ ] No existe FK entre schemas de servicios distintos.
- [ ] No existe acceso SQL cross-service.
- [ ] No existen joins operativos cross-service.
- [ ] No existen FK hacia "auth.users".
- [ ] Las referencias externas son columnas escalares sin FK.

27.3. Identificadores

- [ ] Las PK siguen las convenciones vigentes.
- [ ] No existen PK naturales salvo decisión formal excepcional.
- [ ] No se utiliza "serial", "bigserial" ni autoincremento prohibido.
- [ ] Las claves naturales están documentadas.

27.4. Tipos y timestamps

- [ ] No se utiliza "float", "real", "double precision" ni "money" para valores de negocio.
- [ ] No existe "timestamp" sin zona horaria para instantes.
- [ ] Toda tabla posee "created_at timestamptz NOT NULL DEFAULT now()".
- [ ] "updated_at" existe salvo excepción documentada.
- [ ] Los enums pertenecen exclusivamente al schema local.

27.5. Integridad

- [ ] Todas las PK están definidas.
- [ ] Todas las FK internas necesarias están definidas.
- [ ] Toda FK posee índice cuando corresponde.
- [ ] "NOT NULL" se utiliza correctamente.
- [ ] "UNIQUE" protege las identidades de negocio aplicables.
- [ ] "CHECK" protege invariantes declarativas.
- [ ] Toda constraint tiene nombre explícito.
- [ ] Toda constraint, índice, función y trigger sigue la convención de nombres.

27.6. Borrado y ciclo de vida

- [ ] "estado" y "deleted_at" no representan el mismo concepto.
- [ ] Las excepciones están documentadas.
- [ ] No se utiliza DELETE físico cuando la retención contractual lo prohíbe.

27.7. Rendimiento

- [ ] Los índices están asociados a consultas o procesos concretos.
- [ ] No existen índices redundantes evidentes.
- [ ] Los workers tienen índices adecuados cuando corresponda.
- [ ] No existen optimizaciones sin justificación.

27.8. Mensajería

- [ ] "outbox" existe únicamente si el servicio publica eventos.
- [ ] "inbox" existe únicamente si el servicio consume eventos.
- [ ] El registro en "outbox" forma parte de la transacción de negocio.
- [ ] "message_id" permite deduplicación.
- [ ] "operation_id" protege idempotencia funcional cuando corresponde.

27.9. Implementación

- [ ] "migrations/" coincide con este documento.
- [ ] Las migraciones pueden ejecutarse desde cero.
- [ ] El schema puede desplegarse aisladamente.
- [ ] "validation.sql" valida las invariantes principales.
- [ ] La repetición del proceso de migración es segura.
- [ ] No existen secretos versionados.

27.10. Trazabilidad

- [ ] Todas las tablas aparecen en la matriz lógico → físico.
- [ ] Las reglas principales tienen fuente identificable.
- [ ] Las decisiones físicas están documentadas.
- [ ] Las decisiones pendientes están declaradas.
- [ ] No existen contradicciones funcionales ocultas.

27.11. Evidencia

- [ ] Validación local satisfactoria.
- [ ] Ejecución desde una base limpia satisfactoria.
- [ ] Reejecución del mecanismo de migraciones satisfactoria.
- [ ] Evidencia Supabase disponible cuando corresponda.
- [ ] Pull Request asociado.

---

28. Resultado de revisión

Resultado:

<APROBADO | REQUIERE CAMBIOS>

Observaciones:
<observación>
<observación>
Revisor:
<nombre>
Fecha:
<AAAA-MM-DD>