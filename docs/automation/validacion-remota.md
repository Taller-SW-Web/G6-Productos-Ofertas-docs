# Validación del despliegue en GitHub Actions

Piloto **cueva → lab/cueva** instalado y activado el 2026-10-02 (America/Lima). El usuario autorizó la publicación después de la validación local. Implementación integrada mediante el [PR #75](https://github.com/Taller-SW-Web/Productos-y-Ofertas-docs/pull/75), commit de merge `f2260e28693b151f8a15e5d05ba0c1bdf341408c`.

## Ejecuciones verificadas

| Ejecución | Resultado |
| --- | --- |
| [Simulación manual](https://github.com/Taller-SW-Web/Productos-y-Ofertas-docs/actions/runs/37097168771) | SUCCESS; resultado `dry_run`, sin publicar |
| [Aplicación manual del piloto](https://github.com/Taller-SW-Web/Productos-y-Ofertas-docs/actions/runs/37097230354) | SUCCESS; resultado `published`, push realizado por `GITHUB_TOKEN` |
| [Workflow existente de master](https://github.com/Taller-SW-Web/Productos-y-Ofertas-docs/actions/runs/37097309765) | SUCCESS; despacho manual sobre master para verificar el encadenamiento |
| [Sincronización automática encadenada](https://github.com/Taller-SW-Web/Productos-y-Ofertas-docs/actions/runs/37097358085) | SUCCESS; evento `workflow_run`, resultado `up_to_date`, sin otro commit |

La variable del repositorio `SYNC_WORKSPACES_ENABLED` se estableció y confirmó en `true` después de validar la primera aplicación real. En `.github/sync-config.json`, `enabled_sources` contiene únicamente `cueva`; los otros cinco laboratorios no se habilitaron.

## Integridad del piloto

- Fuente observada y conservada: `f2260e28693b151f8a15e5d05ba0c1bdf341408c`.
- Destino anterior: `1dc0b5322f285227b01e4e504fc6fd1ec92e9921`.
- Destino publicado: `6fac22ecfdc454facf17c372f19aff6486676e92`, con ambos SHA anteriores como padres. La fuente es ancestro del resultado.
- Blob de `README.md` operativo antes y después: `f5948c687ef4e2dffdc3af0580aba00a8a51b9cb`; conservación exacta.
- `.gitignore` resultante conserva `/frontend` y `.stitch/`, con salto final. Su blob cambia por la normalización de ese salto, no por eliminación de reglas funcionales.
- El workflow existente `sync-master.yml` mantiene el blob `8c53db2e860df8af98631baa5a92e9c49cd2200c` respecto al master anterior al despliegue.
- La segunda ejecución automática mantuvo el mismo SHA de destino, acreditando idempotencia en GitHub.

Los SHA corresponden al primer piloto; ejecuciones posteriores incorporarán nuevos avances legítimos. La comprobación periódica está configurada y habilitada, pero no se esperó su siguiente horario para declarar validado el encadenamiento. Los conflictos y carreras se probaron en los repositorios locales desechables; no se introdujeron conflictos artificiales en las ramas del equipo.

Para suspender o retirar el servicio se mantiene el [procedimiento operativo](sincronizacion.md). Este despliegue completa la fase de implementación posterior al análisis aprobado del #47.
