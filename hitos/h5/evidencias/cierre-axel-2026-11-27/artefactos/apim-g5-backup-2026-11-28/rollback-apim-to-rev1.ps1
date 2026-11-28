# Rollback inmediato de APIM g6-productos-ofertas a rev=1 (145 operaciones)
$ErrorActionPreference = 'Stop'
$sub = az account show --query id -o tsv
$tok = az account get-access-token --resource https://management.azure.com/ --query accessToken -o tsv
$relId = "rollback-to-rev1-$(Get-Date -Format 'yyyyMMddHHmmss')"
$url = "https://management.azure.com/subscriptions/$sub/resourceGroups/rg-g6-aca-chile/providers/Microsoft.ApiManagement/service/apim-g6-productos-chile/apis/g6-productos-ofertas;rev=1/releases/${relId}?api-version=2023-05-01-preview"
$body = '{"properties":{"apiId":"/apis/g6-productos-ofertas;rev=1","notes":"Rollback operativo a rev=1 (145 operaciones)"}}'
curl.exe -sS -X PUT -H "Authorization: Bearer $tok" -H "Content-Type: application/json" -d $body $url
