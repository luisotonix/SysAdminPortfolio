# ============================================================
# Setup App Registration para M365 Test Email Generator
# Cria automaticamente App Registration com Mail.Send permission
# ============================================================

Write-Host ""
Write-Host "📦 Importando Microsoft.Graph..." -ForegroundColor Cyan
try {
    Import-Module Microsoft.Graph -ErrorAction Stop | Out-Null
    Write-Host "✅ Módulo carregado" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Microsoft.Graph não encontrado, continuando..." -ForegroundColor Yellow
}

# Conectar como Global Admin (delegated auth)
Write-Host ""
Write-Host "🔐 Conectando ao Microsoft Graph (delegated)..." -ForegroundColor Cyan
Connect-MgGraph -Scopes 'Application.ReadWrite.All' -NoWelcome | Out-Null
Write-Host "✅ Conectado" -ForegroundColor Green

# Validar que está conectado como Global Admin
Write-Host ""
Write-Host "👤 Validando conexão..." -ForegroundColor Cyan
try {
    $context = Get-MgContext
    Write-Host "✅ Conectado como: $($context.Account.Id)" -ForegroundColor Green
} catch {
    Write-Host "❌ Erro ao validar: $_" -ForegroundColor Red
    return
}

# Obter TenantId
$org = Get-MgOrganization
$tenantId = $org.Id
Write-Host "📍 Tenant ID: $tenantId" -ForegroundColor Green

# Criar App Registration
Write-Host ""
Write-Host "📱 Criando App Registration..." -ForegroundColor Cyan
$appName = "M365 Test Email Generator - $(Get-Date -Format 'yyyyMMddHHmmss')"
$app = New-MgApplication -DisplayName $appName -ErrorAction Stop
$appId = $app.AppId
Write-Host "✅ App criado: $appId" -ForegroundColor Green

# Criar Service Principal
Write-Host ""
Write-Host "👥 Criando Service Principal..." -ForegroundColor Cyan
$spn = New-MgServicePrincipal -AppId $appId -ErrorAction Stop
$spnId = $spn.Id
Write-Host "✅ Service Principal criado: $spnId" -ForegroundColor Green

# Encontrar Mail.Send permission (application)
Write-Host ""
Write-Host "🔍 Procurando Mail.Send permission..." -ForegroundColor Cyan
$graphSpn = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'" -ErrorAction SilentlyContinue
if ($graphSpn) {
    $mailSendRole = $graphSpn.AppRoles | Where-Object { $_.Value -eq "Mail.Send" } | Select-Object -First 1
    if ($mailSendRole) {
        Write-Host "✅ Encontrado: Mail.Send" -ForegroundColor Green
        
        # Conceder permissão
        Write-Host ""
        Write-Host "🔐 Concedendo Mail.Send permission..." -ForegroundColor Cyan
        New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $spnId `
            -PrincipalId $spnId `
            -AppRoleId $mailSendRole.Id `
            -ResourceId $graphSpn.Id -ErrorAction Stop | Out-Null
        Write-Host "✅ Permissão concedida!" -ForegroundColor Green
    } else {
        Write-Host "❌ Mail.Send role não encontrado" -ForegroundColor Red
    }
} else {
    Write-Host "❌ Microsoft Graph service principal não encontrado" -ForegroundColor Red
}

# Criar Client Secret
Write-Host ""
Write-Host "🔑 Criando Client Secret..." -ForegroundColor Cyan
$now = Get-Date
$expires = $now.AddMonths(6)
$secret = Add-MgApplicationPassword -ApplicationId $app.Id `
    -PasswordCredential @{ `
        displayName = "Test Email Generator Secret"; `
        endDateTime = $expires `
    } -ErrorAction Stop
$secretValue = $secret.SecretText
Write-Host "✅ Client Secret criado (válido até: $expires)" -ForegroundColor Green

# Exibir resumo
Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "✨ APP REGISTRATION CRIADO COM SUCESSO!" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "📋 CREDENCIAIS (guarde com segurança):" -ForegroundColor Yellow
Write-Host ""
Write-Host "TenantID:     $tenantId" -ForegroundColor White
Write-Host "ClientID:     $appId" -ForegroundColor White
Write-Host "ClientSecret: $secretValue" -ForegroundColor Cyan
Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "🚀 Para usar o App-Only email generator:" -ForegroundColor Green
Write-Host ""
Write-Host "  . './m365TestEmailGenerator_AppOnly.ps1' -ClientId '$appId' -ClientSecret '$secretValue' -TenantId '$tenantId' -AutoConfirm" -ForegroundColor Gray
Write-Host ""
Write-Host "Ou com WhatIf primeiro:" -ForegroundColor Green
Write-Host "  . './m365TestEmailGenerator_AppOnly.ps1' -ClientId '$appId' -ClientSecret '$secretValue' -TenantId '$tenantId' -WhatIf -AutoConfirm" -ForegroundColor Gray
Write-Host ""
