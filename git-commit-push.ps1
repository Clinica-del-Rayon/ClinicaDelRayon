# Script para hacer commit y push de los cambios
# Ejecutar desde PowerShell en el directorio del repositorio

Write-Host "=== Git Commit y Push Automático ===" -ForegroundColor Cyan
Write-Host ""

# Ir al directorio del repositorio
$repoPath = "C:\Users\javie\OneDrive\Documentos\unijaveriana\Clinica del rayon\ClinicaDelRayon\app"
Set-Location $repoPath

Write-Host "Directorio actual: $(Get-Location)" -ForegroundColor Yellow
Write-Host ""

# Ver estado actual
Write-Host "Estado actual de Git:" -ForegroundColor Yellow
git status
Write-Host ""

# Agregar todos los cambios
Write-Host "Agregando todos los cambios..." -ForegroundColor Yellow
git add .

# Ver qué se agregó
Write-Host ""
Write-Host "Archivos agregados:" -ForegroundColor Yellow
git status --short
Write-Host ""

# Pedir mensaje de commit
$mensaje = Read-Host "Ingresa el mensaje del commit (o presiona Enter para usar el predeterminado)"
if ([string]::IsNullOrWhiteSpace($mensaje)) {
    $mensaje = "Implementar Realtime Database con sistema de roles y mejorar UX de registro"
}

# Hacer commit
Write-Host ""
Write-Host "Haciendo commit..." -ForegroundColor Yellow
git commit -m "$mensaje"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Commit exitoso" -ForegroundColor Green

    # Hacer push
    Write-Host ""
    Write-Host "Haciendo push a GitHub..." -ForegroundColor Yellow
    git push origin main

    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ ¡Push exitoso! Tus cambios están en GitHub" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "❌ Error al hacer push" -ForegroundColor Red
        Write-Host "Intenta ejecutar manualmente:" -ForegroundColor Yellow
        Write-Host "git push origin main" -ForegroundColor White
    }
} else {
    Write-Host ""
    Write-Host "⚠️ No hay cambios para hacer commit" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Proceso completado ===" -ForegroundColor Cyan

