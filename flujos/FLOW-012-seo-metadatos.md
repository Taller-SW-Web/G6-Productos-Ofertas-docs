# FLOW-012 — Gestión de SEO y metadatos

## 1. Identificación

- **Código:** FLOW-012
- **Funcionalidad:** Gestión de SEO y metadatos
- **Relacionado con:** [HU-012](../hu/HU-012-seo-metadatos.md) / [SPEC-012](../specs/SPEC-012-seo-metadatos.md) / [WF-012](../wireframes/flows/WF-012-seo-metadatos.md)
- **Responsable:** Leonardo Lopez
- **Última actualización:** 2026-10-01

---

## 2. Objetivo del flujo

Representar la generación automática y la edición manual del slug de cada categoría, la política de duplicados (sufijo incremental en la creación y error explícito en la edición manual), las advertencias de longitud de metadatos y el historial de redirecciones. El flujo separa explícitamente SEO de Categorías: SEO solo resuelve y proporciona la propuesta de slug, el gestor la confirma y Categorías la persiste y revalida su unicidad. El flujo contempla la resolución `old_slug -> new_slug` que el Marketplace ejecuta como HTTP 301 y el endpoint público de metadatos por slug activo.

---

## 3. Actores participantes

- **Gestor comercial:** configura el slug y los metadatos SEO de cada categoría, y confirma la propuesta de slug durante la creación.
- **Sistema SEO:** normaliza slugs, resuelve colisiones, registra el historial y expone el endpoint público. No persiste el slug de la categoría.
- **Categorías:** crea la categoría con el `slugConfirmado` y revalida su unicidad.
- **Marketplace:** canal que sirve la URL pública y ejecuta el HTTP 301.
- **Consumidor externo:** canal que consulta los metadatos SEO por slug activo.

---

## 4. Diagramas de flujo

### 4.1 Resolución y confirmación del slug al crear una categoría

```mermaid
flowchart LR

    subgraph GESTOR["Gestor comercial"]
        direction TB
        INICIO((Creación de una categoría))
        G1["Ver el slug propuesto y confirmarlo"]
        D2{"¿Se confirma el slug propuesto?"}
        G2["Volver a editar los datos de la categoría"]
        G3["Ver la nueva propuesta y confirmarla de nuevo"]
    end

    subgraph SEO["Sistema SEO"]
        direction TB
        S1["Recibir el nombre de la categoría"]
        S2["Normalizar el slug: minúsculas, sin tildes ni espacios"]
        D1{"¿El slug ya existe?"}
        S3["Proponer sufijo numérico incremental"]
        S4["Devolver la propuesta con slug y colisionResuelta sin reservarla"]
        S5["Volver a generar una propuesta cuando se le solicite"]
    end

    subgraph CATEGORIAS["Categorías"]
        direction TB
        C1["Enviar el alta a POST /api/v1/categorias con slugConfirmado"]
        C2["Revalidar la unicidad del slug antes de persistir"]
        D3{"¿El slug confirmado sigue libre?"}
        C3["Rechazar con 409 SLUG_DUPLICADO sin aplicar otro sufijo"]
        C4["Persistir la categoría con exactamente el slug confirmado"]
    end

    FIN_PUBLICADO(((Categoría creada con el slug confirmado)))
    FIN_CANCELADA(((Creación cancelada)))

    INICIO --> S1
    S1 --> S2
    S2 --> D1
    D1 -->|"Sí"| S3
    S3 --> S4
    D1 -->|"No"| S4
    S4 --> G1
    G1 --> D2
    D2 -->|"No"| G2
    G2 --> S4
    D2 -->|"Sí"| C1
    C1 --> C2
    C2 --> D3
    D3 -->|"No"| C3
    C3 --> S5
    S5 --> G3
    G3 --> D2
    D3 -->|"Sí"| C4
    C4 --> FIN_PUBLICADO
```

> En la creación, la colisión de slugs se resuelve con un sufijo incremental, pero el slug final siempre se muestra al gestor antes de publicar; no hay cambios silenciosos de URL.

> SEO **solo resuelve y proporciona la propuesta**: no persiste el slug de la categoría ni guarda silenciosamente otro valor. Quien crea y revalida la unicidad es Categorías, mediante `slugConfirmado` en `POST /api/v1/categorias`. La propuesta no reserva el slug, por lo que si otro proceso lo ocupa antes del commit la creación responde `409 SLUG_DUPLICADO` y el flujo vuelve a la resolución de SEO, muestra la nueva propuesta y exige una nueva confirmación antes de reintentar.

### 4.2 Edición manual de un slug

```mermaid
flowchart LR

    subgraph GESTOR["Gestor comercial"]
        direction TB
        INICIO((Edición manual del slug))
        G1["Ingresar el nuevo slug"]
        G2["Corregir el slug duplicado"]
        G3["Guardar los cambios"]
    end

    subgraph SEO["Sistema SEO"]
        direction TB
        S1["Validar el slug ingresado"]
        D1{"¿El slug ya está en uso en otra categoría?"}
        S2["Rechazar con error: El slug indicado ya está en uso"]
        S3["Registrar historial y resolución old_slug → new_slug"]
    end

    FIN_EDITADO(((Slug editado)))
    FIN_RECHAZADO(((Guardado rechazado)))

    INICIO --> G1
    G1 --> S1
    S1 --> D1
    D1 -->|"Sí"| S2
    S2 --> G2
    G2 --> G1
    D1 -->|"No"| S3
    S3 --> G3
    G3 --> FIN_EDITADO
```

> En la edición manual no se autogeneran sufijos: el duplicado se rechaza con un error visible exigiendo un valor distinto.

### 4.3 Advertencias de longitud de metadatos

```mermaid
flowchart LR

    subgraph GESTOR["Gestor comercial"]
        direction TB
        INICIO((Ingreso de metadatos SEO))
        G1["Escribir el meta-título y la meta-descripción"]
        G2["Confirmar el guardado"]
    end

    subgraph SEO["Sistema SEO"]
        direction TB
        S1["Validar los límites recomendados"]
        D1{"¿El meta-título supera los 70 caracteres?"}
        D2{"¿La meta-descripción supera los 160 caracteres?"}
        S2["Mostrar advertencia del título"]
        S3["Mostrar advertencia de la descripción"]
        S4["Permitir el guardado con aviso"]
    end

    FIN_GUARDADO(((Metadatos guardados)))

    INICIO --> G1
    G1 --> S1
    S1 --> D1
    D1 -->|"Sí"| S2
    S2 --> D2
    D1 -->|"No"| D2
    D2 -->|"Sí"| S3
    S3 --> S4
    D2 -->|"No"| S4
    S4 --> G2
    G2 --> FIN_GUARDADO
```

> Los límites de 70 y 160 caracteres son recomendados: se advierte al superarlos, pero no se bloquea el guardado.

### 4.4 Resolución de redirección de slug histórico

```mermaid
flowchart LR

    subgraph USUARIO["Cliente"]
        direction TB
        INICIO((Ingresa a una URL con slug histórico))
        U1["Navegar hacia el slug antiguo"]
    end

    subgraph MARKETPLACE["Marketplace"]
        direction TB
        M1["Consultar la resolución del slug antiguo"]
        M2["Ejecutar HTTP 301 a la URL vigente"]
    end

    subgraph SEO["Sistema SEO"]
        direction TB
        S1["Devolver la redirección permanente old → new"]
    end

    FIN_REDIRIGIDO(((Cliente redirigido a la URL vigente)))

    INICIO --> U1
    U1 --> M1
    M1 --> S1
    S1 --> M2
    M2 --> FIN_REDIRIGIDO
```

> Productos y Ofertas solo expone la resolución `old_slug -> new_slug`; la ejecución del HTTP 301 corresponde al capa web del Marketplace.

### 4.5 Endpoint público de metadatos por slug activo

```mermaid
flowchart LR

    subgraph CONSUMIDOR["Canal, Marketplace o Chatbot"]
        direction TB
        INICIO((Consulta por slug de categoría))
        G1["Invocar endpoint público de metadatos"]
    end

    subgraph SEO["Sistema SEO"]
        direction TB
        S1["Validar que el slug corresponde a una categoría activa"]
        D1{"¿La categoría está activa?"}
        S2["Devolver el meta-título y la meta-descripción vigentes"]
        S3["No publicar metadatos de una categoría inactiva"]
    end

    FIN_DATOS(((Metadatos SEO entregados)))
    FIN_NO_DISPONIBLE(((Sin metadatos publicados)))

    INICIO --> G1
    G1 --> S1
    S1 --> D1
    D1 -->|"Sí"| S2
    S2 --> FIN_DATOS
    D1 -->|"No"| S3
    S3 --> FIN_NO_DISPONIBLE
```

## 5. Contratos publicados

```text
POST /api/v1/seo/categorias/slug/resolver
  { nombre }
  -> { slug, colisionResuelta }

POST /api/v1/categorias
  { .., slugConfirmado }
  -> 201 con el slug confirmado
  -> 409 SLUG_DUPLICADO si la propuesta dejó de estar disponible

GET  /api/v1/seo/{slug}
GET  /api/v1/seo/resoluciones/{slugAnterior}
GET  /api/v1/categorias/{categoriaId}/seo
GET  /api/v1/categorias/{categoriaId}/seo/historial
```

SEO no expone el alta de la categoría: esa operación pertenece a Categorías y exige `slugConfirmado`. El `301 Moved Permanently` sobre la URL pública no forma parte de estos contratos y lo ejecuta Marketplace.
