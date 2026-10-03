# GUÍA LOCAL DE EXPERIMENTACIÓN EN `lab/*`

> **DOCUMENTO OPERATIVO TEMPORAL — NO VERSIONAR**
>
> Este archivo se utiliza únicamente como guía interna durante la fase experimental de mockups.
> **No constituye una fuente de verdad del proyecto y no debe subirse al repositorio oficial.**
>
> Toda decisión funcional, técnica, contractual, arquitectónica o UX que deba permanecer vigente después de esta fase debe quedar reflejada en la documentación oficial correspondiente antes de considerar aprobado un mockup.

**Versión operativa:** 2.0 — 02/10/2026

---

## 1. Objetivo de esta guía

Esta guía define cómo trabajar temporalmente con las ramas `lab/*` durante la etapa de construcción y refinamiento de mockups del módulo **Productos y Ofertas**.

Su propósito es:

- permitir experimentación rápida sin contaminar las ramas oficiales;
- separar el prototipado temporal de los entregables permanentes;
- indicar qué archivos consultar en cada fase;
- aclarar el flujo de trabajo entre Leonardo Vera y los owners funcionales;
- establecer qué artefactos sí deben llegar posteriormente a la rama oficial;
- reducir divergencias entre `lab/*` y las ramas oficiales;
- facilitar la eliminación completa de la infraestructura experimental cuando termine esta etapa.

Las ramas `lab/*` son **entornos temporales de experimentación**, no ramas oficiales del proyecto.

---

## 2. Correspondencia de ramas

| Rama oficial | Rama experimental | Responsable funcional |
|---|---|---|
| `castilla` | `lab/castilla` | Marco Renato Castilla Huanca |
| `poma` | `lab/poma` | Gabriel Poma Gutierrez |
| `cueva` | `lab/cueva` | Axel Andree Cueva Alcalá |
| `lopez` | `lab/lopez` | Leonardo Lopez |
| `vera` | `lab/vera` | Leonardo Vera Rodríguez |
| `taco` | `lab/taco` | Miguel Ángel Taco Zavala |

Regla principal:

```text
rama oficial -> lab correspondiente
```

La rama experimental debe partir de la documentación y estructura vigente de la rama oficial correspondiente.

La rama `lab/*` no debe convertirse en una fuente independiente de requisitos.

---

## 3. Qué es oficial y qué es experimental

### 3.1. Fuentes oficiales

Las siguientes fuentes deben consultarse para construir cada mockup:

| Fuente | Uso |
|---|---|
| `specs/` | Reglas de negocio, validaciones y comportamiento funcional. |
| `hu/` | Necesidades e intención del usuario. |
| `wireframes/` | Estructura base de pantallas y distribución funcional. |
| `wireframes/INDEX.md` | Mapeo canónico de funcionalidades, responsables y referencias. |
| `wireframes/DESIGN.md` | Reglas visuales y restricciones del diseño existente. |
| `flujos/` | Navegación, decisiones, caminos principales y alternativos. |
| `Contrato_Api.md` | Datos que la interfaz puede consultar, mostrar o enviar. |
| `api/` | Contratos OpenAPI vigentes cuando se necesite detalle de request/response. |
| `asyncapi/` | Contratos de mensajería cuando afecten estados visibles o procesos asíncronos. |
| `mockups/ux/propuesta-ux.md` | Enfoque UX transversal adoptado para el módulo. |
| `mockups/ux/ux-decisions.md` | Decisiones UX transversales aprobadas (`UXD-XXX`). |
| `mockups/ux/ux-guidelines.md` | Reglas UX obligatorias derivadas de las decisiones aprobadas. |
| `mockups/README.md` | Pipeline oficial de mockups, DoR, DoD y trazabilidad. |
| `EQUIPO_Y_RESPONSABILIDADES.md` | Ownership funcional y revisiones transversales. |

### 3.2. Artefactos experimentales

Todo lo que exista únicamente para explorar soluciones visuales, generar variantes, probar composiciones, ajustar densidad, experimentar con componentes o acelerar la construcción inicial se considera temporal.

Puede vivir en `lab/*`, pero:

- no redefine reglas de negocio;
- no reemplaza SPEC/HU/WF/FLOW;
- no introduce nuevos endpoints;
- no crea estados que no estén respaldados por documentación;
- no crea nuevas reglas UX transversales por sí solo;
- no debe asumirse como correcto únicamente porque "funciona visualmente".

---

## 4. Archivos del pipeline de mockups y para qué sirve cada uno

El pipeline formal de cada funcionalidad sigue esta separación:

```text
component-spec.md
= especificación principal del resultado esperado del mockup
= qué debe existir

plan.md
= estrategia y contrato de ejecución
= cómo debe construirse

tasks.md
= unidades de trabajo ejecutables y verificables
= qué acciones concretas deben completarse

validation-report.md
= evidencia y trazabilidad de ejecución
= cómo se demuestra que el resultado cumple
```

`component-spec.md` está subordinado a las fuentes oficiales (SPEC, HU, WF, FLOW, API Contract y Design System). Ninguno de estos cuatro artefactos puede contradecir dichas fuentes.

Cada funcionalidad `MK-XXX` debe terminar teniendo su propia carpeta oficial:

```text
mockups/MK-XXX/
├── component-spec.md
├── plan.md
├── tasks.md
└── validation-report.md
```

Las plantillas base están en:

```text
mockups/_plantillas/mockup/
├── component-spec.template.md
├── plan.template.md
├── tasks.template.md
└── validation-report.template.md
```

### 4.1. `component-spec.md`

**Para qué sirve**

Es la **especificación principal del resultado esperado del mockup**, subordinada a las fuentes oficiales.

Define formalmente qué debe existir.

Debe incluir:

- identificación del `MK-XXX`;
- inventario de pantallas `MK-XXX-S01`, `S02`, etc.;
- componentes principales;
- estados requeridos;
- referencias a SPEC/HU/WF/FLOW;
- decisiones UX locales `LUX-XX` cuando corresponda;
- información necesaria para que el mockup pueda construirse sin inventar comportamiento.

**Quién lo consolida**

El owner funcional.

**Qué papel tiene Vera**

Puede señalar incoherencias UX, pero no debe redefinir el comportamiento funcional del owner mediante la versión raw.

---

### 4.2. `plan.md`

**Para qué sirve**

Define la **estrategia de ejecución técnica** de la funcionalidad y el **Contrato de ejecución** que debe seguir una persona o agente.

Debe indicar:

- entradas obligatorias;
- salidas esperadas;
- restricciones de ejecución;
- condiciones de parada / escalamiento;
- pantalla ancla;
- orden de construcción;
- componentes reutilizables;
- estados;
- normalización;
- estrategia de revisión;
- Quality Gates.

**Regla**

La versión raw de Vera no sustituye este archivo.

El `plan.md` debe describir cómo convertir la funcionalidad en un mockup completo y validable, no cómo se generó la primera propuesta visual.

---

### 4.3. `tasks.md`

**Para qué sirve**

Es el checklist de **unidades de trabajo ejecutables y verificables** derivadas del plan.

Aquí viven tareas como:

```text
MK-XXX-T10
MK-XXX-T11
MK-XXX-T12
...
```

Debe utilizarse para:

- implementar pantallas;
- completar estados;
- normalizar componentes;
- revisar copy;
- verificar Flow;
- corregir accesibilidad;
- autovalidar;
- atender observaciones de Vera;
- registrar cierre.

Para las tareas principales, el patrón esperado es:

```text
Entrada
Acción
Salida esperada
Verificación
```

Una tarea solo puede marcarse `DONE` cuando su verificación sea objetivamente comprobable.

Si una tarea pasa a `BLOCKED`, debe registrarse la causa, la condición de parada y la fuente o documento que requiere resolución.

**Importante**

No trasladar estas tareas una por una a GitHub Issues.

El Issue representa el entregable completo `MK-XXX`; `tasks.md` representa el trabajo interno detallado.

---

### 4.4. `validation-report.md`

**Para qué sirve**

Registrar **evidencia y trazabilidad de ejecución** para demostrar que el mockup final cumple las fuentes oficiales.

Debe terminar reflejando:

- trazabilidad `Task -> Pantalla/Componente -> Evidencia -> Resultado`;
- validación contra SPEC;
- validación contra HU;
- validación contra WF;
- validación contra FLOW;
- aplicación de UX Decisions y UX Guidelines;
- consistencia con Design System;
- revisión en viewport canónico;
- accesibilidad básica;
- hallazgos;
- correcciones;
- autovalidación del owner;
- revisión UX transversal posterior;
- estado `APROBADO PARA FIGMA`;
- fidelidad con Figma;
- resultado general final.

El reporte no debe usarse como gestor de tareas pendientes; las tareas pertenecen a `tasks.md`.

**Regla**

La versión raw nunca se considera aprobada por sí misma.

---

## 5. Código de prototipado

La implementación interactiva pertenece al entorno:

```text
mockups/prototipo/
```

La estructura prevista para pantallas finales normalizadas es:

```text
mockups/prototipo/src/pantallas/MKXXX/
```

La implementación allí debe:

- utilizar React;
- utilizar TypeScript;
- usar los componentes y convenciones definidas para el prototipo;
- aplicar el Design System;
- aplicar las UX Guidelines;
- evitar componentes ad hoc cuando exista equivalente compartido;
- evitar colores, espaciados, iconos o tipografías arbitrarias;
- evitar términos técnicos que no deban aparecer al usuario final.

El `README.md` de `mockups/prototipo/` debe consultarse antes de incorporar código definitivo del mockup.

---

# 6. FLUJO ESPECIAL PARA LEONARDO VERA — VERSIÓN RAW

## 6.1. Rol de Vera en la fase experimental

Durante esta fase, Leonardo Vera prepara **únicamente la versión raw inicial** de las funcionalidades.

La versión raw es:

- una propuesta visual inicial;
- rápida;
- exploratoria;
- no definitiva;
- no aprobada para Figma;
- no equivalente al mockup terminado;
- no fuente de verdad funcional.

Su objetivo es reducir el tiempo necesario para que cada owner llegue a una primera representación visual utilizable.

---

## 6.2. Archivos que Vera debe usar para preparar el prompt de la versión raw

Para cada `MK-XXX`, Vera debe trabajar principalmente con este paquete:

```text
mockups/MK-XXX/component-spec.md
mockups/MK-XXX/plan.md
wireframe correspondiente
FLOW correspondiente
mockups/ux/propuesta-ux.md
mockups/ux/ux-decisions.md
mockups/ux/ux-guidelines.md
wireframes/DESIGN.md
```

### Prioridad de uso

```text
Fuentes oficiales
(SPEC / HU / WF / FLOW / API Contract / Design System)
        ↓
component-spec.md
        ↓
plan.md
        ↓
versión raw
```

### Función de cada archivo para Vera

| Archivo | Uso durante la generación raw |
|---|---|
| `component-spec.md` | Referencia principal del **qué debe existir**: pantallas, estructura, componentes, acciones, estados, contenido y jerarquía. |
| `plan.md` | Referencia principal del **cómo ejecutar**: pantalla ancla, orden, entradas, salidas, restricciones y condiciones de parada. |
| WF correspondiente | Estructura base y distribución funcional que debe respetarse. |
| FLOW correspondiente | Navegación, decisiones y caminos que la representación debe respetar. |
| `ux-decisions.md` | Patrones UX aprobados aplicables a la funcionalidad. |
| `ux-guidelines.md` | Reglas UX normativas que deben cumplirse. |
| `propuesta-ux.md` | Contexto global de la experiencia adoptada para el módulo. |
| `DESIGN.md` | Reglas visuales, lenguaje UI y restricciones de diseño. |

### Fuentes de consulta adicional

Cuando una decisión visual dependa de reglas funcionales o de datos concretos, Vera debe consultar además:

```text
SPEC correspondiente
HU correspondiente
Contrato_Api.md
api/*
asyncapi/*
```

Estas fuentes no se sustituyen por el contenido de `component-spec.md` ni `plan.md`.

---

## 6.3. Cómo debe usar Vera `component-spec.md`

`component-spec.md` es la especificación principal del resultado esperado del mockup.

Vera debe extraer de ahí:

- inventario de pantallas `MK-XXX-SXX`;
- propósito de cada pantalla;
- estructura de cada pantalla;
- componentes;
- acciones;
- estados;
- contenido clave;
- jerarquía de información;
- fixtures relevantes;
- decisiones UX locales `LUX-XX`.

Si falta información necesaria para representar una pantalla, Vera **no debe inventarla**.

Debe reportar el vacío para que el owner o la fuente oficial correspondiente lo resuelva.

---

## 6.4. Cómo debe usar Vera `plan.md`

`plan.md` define la estrategia y el contrato de ejecución.

Vera debe usar especialmente:

- entradas obligatorias;
- pantalla ancla;
- orden de pantallas;
- estrategia de construcción;
- componentes que deben reutilizarse;
- estados requeridos;
- restricciones;
- salidas esperadas;
- condiciones de parada / escalamiento.

La pantalla ancla debe generarse primero cuando el plan así lo establezca.

El resto de pantallas raw debe conservar el lenguaje visual y los patrones fijados por dicha pantalla.

---

## 6.5. Qué NO necesita Vera para promptear la versión raw

`tasks.md` no debe utilizarse como fuente principal para construir el prompt visual.

Su función es controlar las unidades de trabajo ejecutables del proceso de implementación/refinamiento.

Vera puede consultarlo si necesita conocer el estado operativo de una funcionalidad, pero no debe duplicar su contenido en el prompt.

`validation-report.md` tampoco es una entrada para la generación inicial.

Ese documento registra evidencia posteriormente.

---

## 6.6. Qué debe hacer Vera

Vera debe concentrarse en:

1. leer `component-spec.md`;
2. leer `plan.md`;
3. identificar la pantalla ancla;
4. revisar WF y FLOW;
5. identificar las UX Decisions aplicables;
6. revisar UX Guidelines y DESIGN;
7. generar primero la pantalla ancla raw;
8. comprobar coherencia básica;
9. generar las demás pantallas raw manteniendo el patrón establecido;
10. registrar dudas o vacíos detectados para el owner.

---

## 6.7. Qué NO debe hacer Vera en la versión raw

Vera no debe:

- inventar reglas de negocio;
- inventar campos;
- inventar endpoints;
- inventar permisos;
- inventar estados funcionales;
- reemplazar decisiones del owner funcional;
- modificar SPEC/HU/WF/FLOW desde la versión raw;
- redefinir lo establecido en `component-spec.md`;
- ignorar restricciones o condiciones de parada de `plan.md`;
- considerar terminada la funcionalidad;
- completar por sí mismo toda la normalización;
- asumir que una pantalla visualmente atractiva es funcionalmente correcta;
- registrar el mockup como `APROBADO`;
- trasladar directamente la versión raw a Figma como entrega final.

Si encuentra una contradicción o ausencia documental, debe detener esa decisión y escalarla.

---

## 6.8. Condiciones de parada para Vera

Vera debe detener la generación o refinamiento de la parte afectada cuando:

- `component-spec.md` contradiga una fuente oficial;
- `plan.md` indique una condición de parada;
- falte información necesaria para una decisión funcional;
- sea necesario inventar comportamiento;
- una dependencia externa no esté definida;
- WF y FLOW sean incompatibles;
- el dato que se desea representar no esté respaldado por contrato cuando el contrato sea necesario.

La condición debe comunicarse al owner para resolución.

---

## 6.9. Qué puede quedar imperfecto en una versión raw

La versión raw puede contener:

- componentes todavía no reutilizados;
- jerarquías por ajustar;
- copy provisional;
- datos fixture simples;
- detalles menores de spacing pendientes;
- estados secundarios incompletos;
- implementación no totalmente normalizada.

Pero no debería contener:

- reglas funcionales inventadas;
- navegaciones incompatibles con FLOW;
- acciones imposibles según contratos;
- términos internos/técnicos visibles al usuario;
- patrones que contradigan las UX Guidelines.

---

## 6.10. Entrega de Vera al owner

La entrega de una versión raw debe incluir como mínimo:

```text
MK-XXX
pantallas raw creadas
pantalla ancla utilizada
supuestos visuales utilizados
dudas detectadas
bloqueos encontrados
puntos que requieren validación del owner
```

No hace falta convertir esta entrega experimental en documentación oficial.

El owner debe poder identificar claramente:

- qué recibió;
- qué debe corregir;
- qué debe completar;
- qué decisiones siguen pendientes.

---

## 7. Flujo del owner funcional después de recibir la versión raw

El owner funcional sigue siendo responsable del `MK-XXX`.

Antes de solicitar la versión raw, el owner debe haber preparado al menos `component-spec.md`, `plan.md` y `tasks.md` conforme al Definition of Ready.

Después de recibir la base raw debe:

1. contrastarla contra SPEC;
2. contrastarla contra HU;
3. contrastarla contra WF;
4. contrastarla contra FLOW;
5. verificar los datos contra contratos;
6. comprobar que el raw respeta `component-spec.md`;
7. comprobar que el raw respeta las restricciones de `plan.md`;
8. ejecutar las tareas correspondientes de `tasks.md`;
9. corregir la propuesta raw;
10. implementar estados faltantes;
11. normalizar componentes;
12. normalizar layout;
13. normalizar colores;
14. normalizar tipografía;
15. corregir copy;
16. eliminar términos técnicos indebidos;
17. revisar accesibilidad;
18. validar en viewport desktop;
19. realizar autovalidación;
20. registrar evidencia y trazabilidad en `validation-report.md`.

La entrega raw acelera el inicio.

**No transfiere ownership.**

---

## 8. Segunda intervención de Vera: revisión transversal

Después de que el owner haya refinado y autovalidado su funcionalidad, Vera vuelve a intervenir, esta vez como revisor UX transversal.

Aquí su función ya no es crear una versión raw.

Debe revisar:

- consistencia con UX integral;
- UX Decisions;
- UX Guidelines;
- Design System;
- patrones compartidos;
- jerarquía visual;
- consistencia entre funcionalidades;
- interacción;
- copy visible;
- accesibilidad básica;
- densidad;
- coherencia del layout.

Puede devolver hallazgos al owner.

El owner corrige.

El ciclo continúa hasta que no existan hallazgos bloqueantes ni importantes pendientes.

Después de eso Vera puede otorgar:

```text
APROBADO PARA FIGMA
```

---

## 9. Flujo completo resumido

```text
DOCUMENTACIÓN OFICIAL
        |
        v
Owner prepara
component-spec + plan + tasks
        |
        v
Vera consulta
component-spec + plan + WF + FLOW + UX + DESIGN
        |
        v
Vera crea versión RAW en entorno experimental
        |
        v
Owner funcional recibe la base
        |
        v
Owner contrasta RAW contra
SPEC/HU/WF/FLOW/API + component-spec + plan
        |
        v
Owner ejecuta tasks
y refina/normaliza implementación
        |
        v
Owner realiza autovalidación
y registra evidencia
        |
        v
Vera realiza revisión UX transversal
        |
        +---- hallazgos ----> Owner corrige ----+
        |                                      |
        +--------------------------------------+
        |
        v
APROBADO PARA FIGMA
        |
        v
Figma
        |
        v
Validación de fidelidad
        |
        v
validation-report.md = APROBADO
```

---

## 10. Qué debe existir en `lab/*`

Las ramas `lab/*` pueden contener temporalmente:

- pruebas visuales;
- prototipos incompletos;
- propuestas raw;
- variantes descartables;
- fixtures experimentales;
- modificaciones intermedias;
- implementaciones que todavía no superaron los Quality Gates.

Deben considerarse áreas de trabajo temporal.

No debe asumirse que todo contenido de una `lab/*` debe terminar en la rama oficial.

---

## 11. Qué debe llegar finalmente a las ramas oficiales

Solo debe trasladarse el resultado consolidado necesario para el proyecto.

Dependiendo del estado del `MK-XXX`, esto puede incluir:

```text
mockups/MK-XXX/component-spec.md
mockups/MK-XXX/plan.md
mockups/MK-XXX/tasks.md
mockups/MK-XXX/validation-report.md
```

y la implementación normalizada correspondiente en:

```text
mockups/prototipo/src/pantallas/MKXXX/
```

También deben incorporarse cambios oficiales necesarios en fuentes superiores si durante el desarrollo se detectó una inconsistencia real.

Ejemplo:

```text
Se detecta contradicción en FLOW
        ->
se corrige FLOW oficialmente
        ->
se actualiza mockup
```

No:

```text
se corrige únicamente el mockup
        ->
se deja FLOW contradictorio
```

---

## 12. Regla de promoción de decisiones

Si durante una lab aparece una solución aplicable únicamente a una funcionalidad:

```text
registrar como LUX-XX en component-spec.md
```

Si la decisión resulta aplicable a varias funcionalidades:

```text
evaluar promoción a UXD-XXX
```

La promoción debe hacerse en:

```text
mockups/ux/ux-decisions.md
```

y derivarse posteriormente hacia:

```text
mockups/ux/ux-guidelines.md
```

Una decisión transversal no debe permanecer únicamente en una rama `lab/*`.

---

## 13. Sincronización de una lab

Antes de iniciar o continuar trabajo experimental, comprobar que la lab correspondiente esté alineada con la rama oficial de su owner.

Conceptualmente:

```text
rama oficial actualizada
        |
        v
lab/<owner>
        |
        v
experimentación
```

Si la rama oficial cambia durante el trabajo, la lab debe actualizarse antes de seguir refinando sobre documentación obsoleta.

Nunca resolver un conflicto funcional eligiendo arbitrariamente la versión de la lab.

La fuente oficial tiene prioridad salvo que exista una corrección aprobada pendiente de incorporar.

---

## 14. Manejo de discrepancias

Si el mockup experimental contradice una fuente oficial:

```text
detener esa decisión
        |
        v
identificar fuente afectada
        |
        v
resolver contradicción
        |
        v
actualizar fuente oficial si corresponde
        |
        v
continuar mockup
```

Ejemplos:

### Caso A — WF incompleto

No completar silenciosamente una navegación compleja.

Revisar FLOW y SPEC. Si realmente falta información en WF, corregir la cadena documental.

### Caso B — API no expone un dato mostrado

No asumir que el frontend podrá obtenerlo.

Confirmar contrato antes de consolidar la pantalla.

### Caso C — nueva decisión UX transversal

No dejarla solo en el prototipo.

Evaluar `UXD-XXX`.

---

## 15. Qué NO debe guardarse solo en esta guía

Este archivo nunca debe ser el único lugar donde exista:

- una regla de negocio;
- una regla de validación;
- un endpoint;
- un payload;
- una regla de autorización;
- una decisión arquitectónica;
- una decisión UX permanente;
- una nueva pantalla obligatoria;
- un cambio de ownership;
- un criterio de aceptación;
- una integración con otro módulo.

Si algo debe sobrevivir a la eliminación de `lab/*`, debe estar en la documentación oficial correspondiente.

---

## 16. Uso de GitHub Issues durante esta etapa

Los Issues oficiales de mockups deben representar los entregables `MK-XXX`.

Ejemplo:

```text
[Hito 2][Mockup] MK-003 — Gestión de productos
```

El Issue puede contener:

- owner;
- rama oficial;
- fuentes;
- entregables;
- checkpoints globales;
- revisión UX;
- aprobación para Figma;
- criterio de cierre.

No es necesario que el Issue documente el funcionamiento interno de `lab/*`.

Las tareas detalladas permanecen en:

```text
mockups/MK-XXX/tasks.md
```

---

## 17. Qué NO trasladar desde la fase experimental

Antes de incorporar un resultado a la rama oficial, eliminar o reemplazar:

- comentarios de experimentación;
- componentes descartados;
- fixtures innecesarios;
- nombres temporales;
- código duplicado;
- decisiones visuales no justificadas;
- dependencias utilizadas solo para pruebas;
- referencias a herramientas experimentales;
- rutas temporales;
- archivos auxiliares que no forman parte del entregable;
- contenido que contradiga el Design System.

El resultado oficial debe poder entenderse sin conocer cómo se realizó la experimentación.

---

## 18. Checklist del owner antes de solicitar revisión UX

- [ ] La funcionalidad coincide con SPEC.
- [ ] La funcionalidad coincide con HU.
- [ ] Las pantallas respetan WF.
- [ ] La navegación respeta FLOW.
- [ ] Los datos representados existen en contratos vigentes.
- [ ] `component-spec.md` está actualizado y no contradice fuentes oficiales.
- [ ] `plan.md` contiene entradas, salidas, restricciones y condiciones de parada vigentes.
- [ ] `tasks.md` refleja unidades ejecutables con verificación comprobable.
- [ ] No existen tareas `BLOCKED` sin causa y condición de desbloqueo registradas.
- [ ] Todas las pantallas P0 están implementadas.
- [ ] Los estados P0 están representados.
- [ ] Se aplicaron UX Decisions.
- [ ] Se aplicaron UX Guidelines.
- [ ] Se respetó el Design System.
- [ ] No existen términos técnicos indebidos en la interfaz.
- [ ] No existen tokens visuales arbitrarios.
- [ ] Los componentes reutilizables fueron normalizados.
- [ ] Se verificó teclado/foco cuando corresponde.
- [ ] No existe overflow horizontal involuntario en 1440 px.
- [ ] `validation-report.md` contiene la autovalidación.
- [ ] No existen hallazgos bloqueantes propios abiertos.

---

## 19. Checklist de Vera para revisión transversal

- [ ] El mockup mantiene coherencia con la UX integral.
- [ ] Se aplican correctamente las UXD relevantes.
- [ ] Los patrones visuales coinciden con el resto del módulo.
- [ ] La navegación visible es comprensible.
- [ ] La densidad es apropiada para desktop.
- [ ] Los drawers/wizards/grids se usan donde corresponde.
- [ ] Loading, empty states y feedback siguen las reglas transversales.
- [ ] El copy visible es comprensible.
- [ ] No hay términos internos o técnicos injustificados.
- [ ] Las acciones críticas son claras.
- [ ] Los estados no dependen únicamente del color.
- [ ] No existen inconsistencias visuales importantes.
- [ ] No existen hallazgos bloqueantes.
- [ ] No existen hallazgos importantes pendientes.
- [ ] Puede declararse `APROBADO PARA FIGMA`.

---

## 20. Cierre de una funcionalidad

Una funcionalidad no termina cuando existe una versión raw.

Tampoco termina cuando "se ve bien".

Debe completar:

```text
raw
-> refinamiento del owner
-> normalización
-> autovalidación
-> revisión UX
-> correcciones
-> APROBADO PARA FIGMA
-> Figma
-> validación de fidelidad
-> validation-report.md APROBADO
```

---

## 21. Cierre de la fase experimental

Cuando todos los mockups hayan abandonado la fase experimental:

1. verificar que toda decisión permanente esté en documentación oficial;
2. verificar que los `MK-XXX` necesarios estén incorporados a sus ramas oficiales;
3. verificar que ningún resultado dependa exclusivamente de `lab/*`;
4. verificar que no haya trabajo válido sin trasladar;
5. eliminar las ramas `lab/*` cuando el equipo lo autorice;
6. eliminar copias locales de esta guía cuando ya no sean necesarias;
7. continuar el proyecto únicamente con las fuentes y ramas oficiales.

---

## 22. Regla final

La relación entre ambos espacios debe mantenerse así:

```text
REPOSITORIO OFICIAL
= lo que el proyecto afirma, mantiene y entrega

LABS
= espacio temporal para explorar cómo llegar a ese resultado
```

Y el reparto operativo durante esta fase:

```text
Vera
= primera versión raw + posterior revisión UX transversal

Owner funcional
= validación funcional + refinamiento + normalización + cierre del MK

Marco
= coordinación + trazabilidad + QA global del proceso
```

La velocidad de experimentación no debe convertir un borrador visual en una decisión oficial por accidente.
