# LAB â€” taco

> Rama temporal: `lab/taco`  
> Rama oficial: `taco`  
> **Regla inmutable: Nunca hacer merge de esta rama hacia una rama oficial ni abrir Pull Request.**

## Finalidad

Iterar y experimentar mockups con Stitch MCP y asistentes en un entorno aislado.

La UX no se define aquÃ­. Stitch **no estÃ¡ autorizado a redefinir la UX del mÃ³dulo**. Esta rama debe aplicar obligatoriamente:

```text
mockups/ux/propuesta-ux.md
mockups/ux/ux-decisions.md
mockups/ux/ux-guidelines.md
```

Cada funcionalidad se guÃ­a por:

```text
mockups/MK-XXX/component-spec.md
mockups/MK-XXX/plan.md
mockups/MK-XXX/tasks.md
```

## Regla Conceptual

```text
3 propuestas UX del mÃ³dulo â†’ comparaciÃ³n y consolidaciÃ³n â†’ Propuesta UX Integral Adoptada
                                      â†“
                               16 funcionalidades
                                      â†“
                               1 MK por funcionalidad
                                      â†“
                               N pantallas por MK
```

Stitch puede generar candidatos de implementaciÃ³n para perfeccionar una pantalla, pero esos candidatos **nunca son propuestas UX**.

## Solo Web Desktop

- Entorno: Web Desktop exclusivamente.
- `deviceType = DESKTOP` en Stitch MCP.
- Viewport canÃ³nico de generaciÃ³n y revisiÃ³n: 1440 px (sin considerarlo un ancho rÃ­gido).
- No diseÃ±ar ni generar variantes mobile o tablet.

## Trabajo Permitido en `lab/taco`

- Pantallas y componentes temporales de prototipado.
- Variantes y candidatos de implementaciÃ³n.
- Versionado de artefactos experimentales livianos en `.stitch/` (prompts, IDs de pantalla generados, notas de sesiÃ³n, HTML/cÃ³digo de prueba).
- Commits y pruebas iterativas rÃ¡pidas.

## Trabajo Prohibido en `lab/taco`

- Modificar la UX transversal sin aprobaciÃ³n oficial en `master`.
- Abrir Pull Request desde `lab/taco`.
- Fusionar (`git merge`) `lab/taco` hacia ramas oficiales (`taco`, `master`, `testing`).
- Promover carpetas `.stitch/`, cachÃ©s o prompts temporales a la rama oficial.

## PolÃ­tica de `.stitch/`

- **Versionar en `lab/taco` (livianos):** prompts enviados, notas de sesiÃ³n (`stitch-session.json`), IDs de pantalla y cÃ³digo HTML preliminar generado para conservar la trazabilidad de iteraciones.
- **Ignorar (pesados/regenerables):** cachÃ©s de herramientas, dependencias locales y screenshots redundantes.
- **En ramas oficiales:** NingÃºn archivo de `.stitch/` puede promoverse.

## Flujo de ExperimentaciÃ³n con Stitch MCP

```mermaid
flowchart TD
    A["Leer UX global + fuentes del MK"]
    B["Elegir pantalla ancla"]
    C["Generar candidato con Stitch DESKTOP"]
    D["Revisar cumplimiento"]
    E["Editar de forma focalizada edit_screens"]
    F{"Â¿Cumple criterios?"}
    G["Seguir refinando"]
    H["Normalizar cÃ³digo en prototipo/src/pantallas/"]
    I["Completar validation-report.md"]
    J["Promover selectivamente a taco"]

    A --> B --> C --> D --> E --> F
    F -- "No" --> G --> E
    F -- "SÃ­" --> H --> I --> J
```

## PromociÃ³n Selectiva hacia la Rama Oficial

Cuando una funcionalidad (`MK-XXX`) estÃ© finalizada y cuente con `validation-report.md` con dictamen **APROBADO**:

```bash
# 1. Posicionarse en la rama oficial limpia y actualizada
git switch taco
git pull --ff-only origin taco

# 2. Restaurar selectivamente ÃšNICAMENTE el cÃ³digo normalizado y validation-report.md
git restore --source lab/taco -- \
  mockups/MK-XXX/validation-report.md \
  mockups/prototipo/src/pantallas/MKXXX

# 3. Inspeccionar el estado de los archivos restaurados (unstaged)
git status
git diff

# 4. Agregar explÃ­citamente Ãºnicamente las rutas aprobadas
git add mockups/MK-XXX/validation-report.md mockups/prototipo/src/pantallas/MKXXX

# 5. Auditar minuciosamente el staging (sin .stitch/, prompts ni residuos experimentales)
git diff --cached

# 6. Commit y push a la rama oficial
git commit -m "feat(mockups): promover cÃ³digo y reporte de MK-XXX aprobado desde lab/taco"
git push origin taco
```

> **Aviso:** `component-spec.md`, `plan.md` y `tasks.md` no se sobrescriben masivamente desde `lab/`. Si requirieron ajustes justificados, se restauran individualmente tras revisiÃ³n explÃ­cita.

## SincronizaciÃ³n desde la Rama Oficial

Para incorporar actualizaciones provenientes de `taco` hacia `lab/taco`:

```bash
git switch lab/taco
git fetch origin
git merge origin/taco
git push origin lab/taco
```

## Cierre y EliminaciÃ³n

Al finalizar la validaciÃ³n de todos los mockups asignados:

```bash
git push origin --delete lab/taco
git branch -D lab/taco
```