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
