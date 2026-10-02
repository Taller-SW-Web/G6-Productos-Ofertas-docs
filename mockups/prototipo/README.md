# Entorno de Prototipado — Mockups

## 1. Propósito

Este directorio contiene el código interactivo de prototipado para la validación funcional, ergonómica y visual de las pantallas de la etapa de mockups.

> **Nota importante:** El código contenido en este directorio corresponde exclusivamente a un entorno de prototipado interactivo para revisión y pruebas de usabilidad. **No corresponde al frontend productivo** de la aplicación final.

---

## 2. Estructura Prevista

A medida que se incorpore código interactivo validado, se organizará bajo la siguiente estructura modular:

```text
prototipo/
├── README.md                                  # Este documento
└── src/
    ├── componentes/                           # Componentes de UI reutilizables del prototipo
    ├── pantallas/                             # Vistas organizadas por funcionalidad (MK-001 a MK-016)
    │   ├── MK001/
    │   ├── MK002/
    │   └── ...
    └── tema/                                  # Tokens de diseño, estilos globales y tipografía
```

---

## 3. Normas de Implementación del Prototipo

1. **Modularidad:** Cada funcionalidad se ubica en su subcarpeta dentro de `src/pantallas/MKXXX/` (sin guiones en el nombre del paquete de código).
2. **Reutilización:** Los componentes transversales (botones, modales, barras de herramientas, inputs) se ubican bajo `src/componentes/`.
3. **Consistencia Visual:** Todos los estilos deben basarse en los tokens definidos en `src/tema/` y alinearse con las especificaciones del Design System.
4. **Fidelidad al Alcance:** Implementar exclusivamente para Web Desktop (verificado en el viewport canónico de 1440 px). No incluir media queries o hacks para dispositivos móviles.

---

## 4. Acceso Directo a Pantallas

### 4.1. Principio y Justificación

Toda pantalla formalmente inventariada como `MK-XXX-SXX`, independientemente de su prioridad (`P0`, `P1`, `P2`, etc.), debe disponer de una ruta directa, estable y reproducible dentro del entorno de prototipado.

La prioridad de una pantalla determina su criticidad, obligatoriedad y alcance en el pipeline de entrega, pero no determina si debe tener o no una ruta directa: la ruta directa garantiza accesibilidad, trazabilidad, revisión y reproducibilidad para todas las pantallas inventariadas.

Esta convención responde y se justifica exclusivamente por:
- **Revisión independiente de pantallas:** Permitir la inspección directa de cualquier pantalla sin necesidad de recorrer manualmente un flujo previo ni depender de transiciones anteriores.
- **Validación reproducible:** Garantizar que evaluadores y revisores puedan acceder a una vista concreta de forma consistente y determinista.
- **Pruebas:** Facilitar la ejecución aislada de pruebas funcionales, visuales y de usabilidad sobre pantallas específicas.
- **Trazabilidad:** Establecer un enlace claro, verificable e inequívoco entre el inventario de la documentación, el código fuente y las vistas renderizadas.
- **Acceso directo durante auditorías:** Posibilitar la comprobación inmediata de cualquier pantalla requerida durante sesiones de revisión o control de calidad.
- **Facilidad para inspeccionar estados concretos:** Permitir la visualización y verificación directa de estados particulares del prototipo sin obligar a forzar secuencias complejas en la interfaz.

La navegación completa entre pantallas (según los diagramas de flujo definidos) puede y debe coexistir con estas rutas directas; disponer de acceso directo no sustituye ni restringe la interacción natural del flujo interactivo.

### 4.2. Correspondencia y Nomenclatura de Rutas

La ruta debe ser estable y determinista. Debe existir una correspondencia inequívoca:

```text
MK-XXX-SXX
↓
componente/vista de código
↓
ruta del prototipo
```

Se establece como convención conceptual el uso de **rutas relativas** bajo el patrón:

```text
/MKXXX/SXX
```

Ejemplos:
- `/MK001/S01`
- `/MK001/S02`
- `/MK003/S01`
- `/MK003/S02`

> **Nota sobre el entorno:** La documentación define estrictamente la **ruta relativa** y no una URL dependiente del entorno. No se fija de manera rígida ningún dominio, hostname, puerto (por ejemplo, no asumir ni fijar `localhost:5173`) ni una biblioteca o framework específico de routing. El prototipo debe emplear un mecanismo de routing interno capaz de resolver estas rutas relativas de manera estable y determinista en cualquier entorno de ejecución.

### 4.3. Reproducción Determinista de Estados

Cuando resulte de utilidad para revisión, pruebas o auditoría, los estados importantes de una misma pantalla (por ejemplo: estado por defecto, carga, datos vacíos o error) pueden exponerse mediante mecanismos deterministas adicionales, tales como parámetros de ruta o parámetros de consulta (*query parameters*).

Ejemplo meramente ilustrativo:
```text
/MK003/S01?estado=default
/MK003/S01?estado=loading
/MK003/S01?estado=empty
/MK003/S01?estado=error
```

Este ejemplo ilustra una alternativa técnica posible y no constituye una obligación técnica exacta respecto a la sintaxis del parámetro. La obligación técnica radica en que los estados requeridos del prototipo puedan reproducirse e inspeccionarse de manera controlada, directa y determinista.
