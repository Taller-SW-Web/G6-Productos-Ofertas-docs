# Protección requerida para `master`

Este procedimiento es preparatorio. **No lo ejecutes desde este PR.** Primero integra el workflow en `master` y comprueba que GitHub haya publicado el check exacto `validate-docs`. Después, Marco debe autorizar expresamente el cambio de protección.

Desde una sesión `gh` autenticada con permisos de administración, el owner debe revisar el efecto y ejecutar:

```powershell
$body = @{
  required_status_checks = @{ strict = $true; contexts = @('validate-docs') }
  enforce_admins = $true
  required_pull_request_reviews = @{ required_approving_review_count = 1; dismiss_stale_reviews = $true }
  restrictions = $null
  allow_force_pushes = $false
  allow_deletions = $false
} | ConvertTo-Json -Depth 8
$body | gh api --method PUT repos/Taller-SW-Web/G6-Productos-Ofertas-docs/branches/master/protection --input -
```

Verifica el resultado sin modificarlo con:

```powershell
gh api repos/Taller-SW-Web/G6-Productos-Ofertas-docs/branches/master/protection
```

La regla exige PR, una aprobación y el check requerido con rama actualizada. Esta tarea solo prepara el procedimiento; no modifica protecciones.
