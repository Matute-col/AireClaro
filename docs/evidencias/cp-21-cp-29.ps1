# CP-21 y CP-29 · Acceso a un reporte ajeno (RB-01) — demostración en vivo
#
# Qué hace (solo lecturas y un intento de envío que DEBE ser rechazado):
#   1. Inicia sesión con la cuenta A (dueña del reporte) y con la cuenta B (otra persona).
#   2. Toma el reporte más reciente de la cuenta A.
#   3. Con la cuenta A pide el detalle (debe dar 200) para mostrar que el reporte existe.
#   4. Con la cuenta B pide detalle, PDF, evidencia y envío por correo: todo debe dar 404.
#
# Seguridad para el video:
#   - Correo y contraseña se escriben ocultos; los tokens nunca se imprimen.
#   - Del reporte solo se muestra su número corto (8 caracteres): ni placa, ni dirección, ni datos personales.
#   - La cuenta A nunca envía nada; el envío lo intenta solo la cuenta B y el API lo rechaza (404).
#   - No se borra nada (este script no usa DELETE).
#
# Uso (con el API encendido: cd backend; npm run dev):
#   powershell -ExecutionPolicy Bypass -File .\docs\evidencias\cp-21-cp-29.ps1
# Para dejar las variables $Api, $TokenB y $ReportId listas para los comandos curl de una línea:
#   . .\docs\evidencias\cp-21-cp-29.ps1
# Al terminar, cierra esa terminal para borrar los tokens de la memoria.

param([string]$Api = 'http://localhost:3000/api')

$ErrorActionPreference = 'Stop'

# Texto de un SecureString, solo en memoria (no se imprime).
function Read-Hidden([string]$prompt) {
  $secure = Read-Host $prompt -AsSecureString
  $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
  try { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) }
  finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
}

function Get-Token([string]$label) {
  $body = @{ email = (Read-Hidden "Correo de la cuenta $label"); password = (Read-Hidden "Contraseña de la cuenta $label") } |
    ConvertTo-Json
  try {
    $res = Invoke-RestMethod -Method Post -Uri "$Api/auth/login" -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($body))
    Write-Host "  Cuenta $label`: sesión iniciada." -ForegroundColor Green
    return $res.token
  } catch {
    Write-Host "  Cuenta $label`: no se pudo iniciar sesión (revisa el correo, la contraseña y que el API esté encendido)." -ForegroundColor Red
    exit 1
  }
}

# Hace una petición y devuelve solo el código HTTP y el mensaje de error del API (nunca el contenido).
function Invoke-Check([string]$method, [string]$path, [string]$token, $body = $null) {
  $params = @{ Method = $method; Uri = "$Api$path"; Headers = @{ Authorization = "Bearer $token" }; UseBasicParsing = $true }
  if ($body) { $params.ContentType = 'application/json'; $params.Body = ($body | ConvertTo-Json) }
  try {
    $res = Invoke-WebRequest @params
    return @{ Status = [int]$res.StatusCode; Message = '' }
  } catch {
    $status = 0
    if ($_.Exception.Response) { $status = [int]$_.Exception.Response.StatusCode }
    $message = 'sin respuesta del API'
    if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
      try { $message = ($_.ErrorDetails.Message | ConvertFrom-Json).error.message } catch { }
    }
    return @{ Status = $status; Message = $message }
  }
}

function Show-Result([string]$case, [string]$what, $result, [int]$expected) {
  $ok = $result.Status -eq $expected
  $mark = if ($ok) { 'OK ' } else { 'FALLA' }
  $color = if ($ok) { 'Green' } else { 'Red' }
  $detail = if ($result.Message) { " «$($result.Message)»" } else { '' }
  Write-Host ("  [{0}] {1} · {2} → {3}{4} (esperado {5})" -f $mark, $case, $what, $result.Status, $detail, $expected) -ForegroundColor $color
}

Write-Host "`nCP-21 / CP-29 · Reporte ajeno (API: $Api)`n" -ForegroundColor Cyan
$TokenA = Get-Token 'A (dueña del reporte)'
$TokenB = Get-Token 'B (otra persona)'

$list = Invoke-RestMethod -Uri "$Api/reports?limit=1" -Headers @{ Authorization = "Bearer $TokenA" }
if ($list.total -eq 0) {
  Write-Host "  La cuenta A no tiene reportes. Crea uno en la app y vuelve a correr el script." -ForegroundColor Yellow
  exit 1
}
$ReportId = $list.items[0].id
$short = ($ReportId -replace '-', '').Substring(0, 8).ToUpper()
Write-Host "`n  Reporte de la cuenta A: n.º $short`n"

Show-Result 'Control' 'la cuenta A ve su propio reporte' (Invoke-Check 'GET' "/reports/$ReportId" $TokenA) 200
Show-Result 'CP-21' 'la cuenta B pide el detalle' (Invoke-Check 'GET' "/reports/$ReportId" $TokenB) 404
Show-Result 'CP-21' 'la cuenta B pide el PDF de la solicitud' (Invoke-Check 'GET' "/reports/$ReportId/pqrsd.pdf" $TokenB) 404
Show-Result 'CP-21' 'la cuenta B pide un id que no existe' (Invoke-Check 'GET' '/reports/00000000-0000-4000-8000-000000000000' $TokenB) 404
Show-Result 'CP-29' 'la cuenta B intenta enviar el correo' (Invoke-Check 'POST' "/reports/$ReportId/send" $TokenB @{ confirm = $true }) 404
Show-Result 'CP-29' 'la cuenta B intenta marcarlo como enviado' (Invoke-Check 'PATCH' "/reports/$ReportId/status" $TokenB @{ status = 'enviado' }) 404

Write-Host "`n  El reporte ajeno responde 404, igual que uno que no existe: no se revela que existe." -ForegroundColor Cyan
Write-Host "  Nada se envió ni se cambió. Cierra esta terminal al terminar.`n"
Remove-Variable TokenA
