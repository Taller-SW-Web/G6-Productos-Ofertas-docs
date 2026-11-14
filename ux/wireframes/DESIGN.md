---
version: alpha
name: Industry Standard Wireframe
description: Un sistema de diseño de baja fidelidad para wireframes enfocado puramente en UX, estructura, arquitectura de la información y jerarquía visual.
colors:
  surface: "#FFFFFF"
  neutral-10: "#F3F4F6"
  neutral-30: "#D1D5DB"
  neutral-50: "#6B7280"
  neutral-90: "#111827"
  primary: "#111827"
typography:
  headline-display:
    fontFamily: "Inter, system-ui, sans-serif"
    fontSize: 48px
    fontWeight: 700
    lineHeight: 1.1
  headline-md:
    fontFamily: "Inter, system-ui, sans-serif"
    fontSize: 24px
    fontWeight: 600
    lineHeight: 1.2
  body-md:
    fontFamily: "Inter, system-ui, sans-serif"
    fontSize: 16px
    fontWeight: 400
    lineHeight: 1.5
  label-sm:
    fontFamily: "Roboto Mono, monospace"
    fontSize: 12px
    fontWeight: 500
    letterSpacing: 0.05em
    lineHeight: 1
spacing:
  xs: 4px
  sm: 8px
  md: 16px
  lg: 32px
  xl: 64px
  gutter: 24px
rounded:
  none: 0px
  sm: 4px
  md: 8px
  full: 9999px
components:
  button-primary:
    backgroundColor: "{colors.neutral-90}"
    textColor: "{colors.surface}"
    rounded: "{rounded.sm}"
    padding: 12px
  button-secondary:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.neutral-90}"
    rounded: "{rounded.sm}"
    padding: 12px
  image-placeholder:
    backgroundColor: "{colors.neutral-10}"
    rounded: "{rounded.none}"
---

# Wireframe Design System

## Overview

También conocido como "Brand & Style". En el contexto de un wireframe, el "estilo" es intencionalmente neutral y utilitario. 

El objetivo de este sistema de diseño es eliminar distracciones visuales (colores, sombras, fotografías) para centrar la discusión de los stakeholders en la arquitectura de la información, los flujos de usuario y la funcionalidad. La estética debe sentirse como el plano estructural de un edificio: clara, matemática, densa cuando sea necesario, pero siempre altamente legible y objetiva.

## Colors

El wireframe se construye estrictamente en escala de grises. La ausencia de color evita que el usuario final o los stakeholders asuman que el diseño visual está terminado.

- **Surface (#FFFFFF):** Blanco puro para el fondo general y el interior de las tarjetas.
- **Neutral-10 (#F3F4F6):** Gris muy claro, utilizado principalmente para rellenar marcadores de posición de imágenes (placeholders) o fondos secundarios.
- **Neutral-30 (#D1D5DB):** Gris medio-claro empleado para bordes de contenedores, inputs inactivos y divisores horizontales.
- **Neutral-50 (#6B7280):** Gris medio-oscuro utilizado para texto secundario, descripciones y estados deshabilitados.
- **Neutral-90 / Primary (#111827):** Casi negro, utilizado para el texto principal, encabezados, y botones de llamada a la acción (CTA) para garantizar un contraste máximo y legibilidad WCAG AAA.

## Typography

La tipografía debe ser estándar, sin adornos y fácil de leer. Utilizamos fuentes del sistema o sin remates (sans-serif) para el contenido general, y una fuente monoespaciada para anotaciones técnicas.

- **Headlines:** `Inter` o fuente del sistema en pesos Bold/Semi-Bold. Define la jerarquía clara de la página.
- **Body:** `Inter` en peso Regular. Se utiliza para simular cómo ocupará espacio el contenido real o el texto simulado (Lorem Ipsum).
- **Labels (Anotaciones):** `Roboto Mono` o cualquier tipografía monoespaciada en tamaño pequeño. Se usa exclusivamente para notas técnicas del diseñador (ej. "Área dinámica", "Carrusel: 3 items visibles").

## Layout

El layout sigue el estándar de una **Cuadrícula de 12 columnas (Grid)** para escritorio y 4 columnas para dispositivos móviles. 

Nos basamos en un sistema de espaciado estricto múltiplo de 8px. Los contenedores y las secciones se agrupan utilizando bordes sólidos de 1px (`neutral-30`) en lugar de colores de fondo, para mantener la interfaz ligera y fácil de imprimir o escanear visualmente. Se usa un margen interno estándar de 16px o 24px dentro de las tarjetas estructurales.

## Elevation & Depth

En los wireframes, **no se utilizan sombras ni desenfoques (blurs)**. 

La profundidad y la separación de elementos (ej. modales, menús desplegables o popovers) se logran mediante:
1. Un borde de mayor contraste (`neutral-90`).
2. Una capa de oscurecimiento en el fondo (overlay al 50% de opacidad usando `neutral-90`) para resaltar elementos modales por encima de la página principal.

## Shapes

Las formas son puramente utilitarias e informativas:
- **Cajas rectangulares con una "X" diagonal:** Representan imágenes o videos (placeholders).
- **Círculos perfectos:** Representan avatares de usuarios o íconos principales.
- **Bordes rectos o mínimamente redondeados (4px):** Para botones y campos de entrada de texto, solo para sugerir interaccionabilidad.

## Components

Los componentes son bloques de construcción desnudos, diseñados para denotar función más que forma.

* **Buttons (Botones):** Los primarios utilizan un relleno oscuro (`neutral-90`) con texto blanco. Los secundarios solo tienen un borde oscuro y fondo blanco.
* **Input fields (Campos de texto):** Se representan como rectángulos con un borde gris (`neutral-30`) y la etiqueta descriptiva posicionada siempre en la parte superior.
* **Image Placeholders (Imágenes):** Contenedores grises (`neutral-10`). No se deben incluir fotografías reales en esta etapa.
* **Checkboxes & Radios:** Cuadrados y círculos vacíos con bordes definidos. Se usa un cuadro sólido negro en su interior para representar el estado seleccionado.

## Do's and Don'ts

- **Do (Hacer):** Utiliza siempre escala de grises para no desviar la atención de la funcionalidad.
- **Don't (No hacer):** No utilices fotografías reales o logotipos finales; usa cajas con una "X" y texto genérico como "Logo de Marca".
- **Do (Hacer):** Asegúrate de que el tamaño de los botones (mínimo 44x44px en móviles) respete los estándares de accesibilidad para áreas táctiles.
- **Don't (No hacer):** No uses sombras (drop shadows); define las áreas flotantes utilizando bordes oscuros de 1px y fondos blancos.
- **Do (Hacer):** Utiliza texto real (copy) en botones y títulos en lugar de *Lorem Ipsum* siempre que sea posible, ya que afecta directamente al ancho de los elementos y a la experiencia de usuario.
