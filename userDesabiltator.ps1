# ============================================================
# USER DISABLER - DESABILITAR 5 USUÁRIOS ALEATÓRIOS
# Script para desabilitar 5 usuários aleatórios do tenant
# Mantém todos os atributos preenchidos intactos
# ============================================================

# Conectar ao Microsoft Graph
Write-Host "🔐 Conectando ao Microsoft Graph..." -ForegroundColor Cyan
Connect-MgGraph -Scopes "User.ReadWrite.All" | Out-Null

# Obter informações do tenant
Write-Host ""
Write-Host "ℹ️  Informações do Tenant Conectado:" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow

$organization = Get-MgOrganization
$tenantName = $organization.DisplayName
$tenantId = $organization.Id

Write-Host "Nome do Tenant: $tenantName" -ForegroundColor White
Write-Host "ID do Tenant: $tenantId" -ForegroundColor White
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host ""

# Pedir confirmação do tenant
$confirmation = Read-Host "Deseja continuar com este tenant? (sim/não)"

if ($confirmation -ne "sim") {
    Write-Host ""
    Write-Host "❌ Operação cancelada pelo usuário." -ForegroundColor Red
    exit
}

Write-Host ""

# ============================================================
# BUSCAR USUÁRIOS ATIVOS
# ============================================================
Write-Host "🔍 Buscando usuários ativos do tenant..." -ForegroundColor Cyan
$activeUsers = Get-MgUser -All -PageSize 999 -Filter "accountEnabled eq true"
$totalActiveUsers = $activeUsers.Count

if ($totalActiveUsers -lt 5) {
    Write-Host "❌ Não há usuários ativos suficientes. Encontrados: $totalActiveUsers (necessário: 5)" -ForegroundColor Red
    exit
}

Write-Host "✅ Total de usuários ativos encontrados: $totalActiveUsers" -ForegroundColor Green
Write-Host ""

# ============================================================
# SELECIONAR 5 USUÁRIOS ALEATORIAMENTE
# ============================================================
Write-Host "🎲 Selecionando 5 usuários aleatoriamente..." -ForegroundColor Cyan

$randomUsers = $activeUsers | Get-Random -Count 5
$selectedCount = 0

Write-Host ""
Write-Host "📋 USUÁRIOS SELECIONADOS PARA DESABILITAÇÃO:" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow

foreach ($user in $randomUsers) {
    $selectedCount++
    Write-Host "  $selectedCount. $($user.DisplayName) ($($user.UserPrincipalName))" -ForegroundColor White
}

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host ""

# ============================================================
# CONFIRMAÇÃO FINAL
# ============================================================
Write-Host "⚠️  CONFIRMAÇÃO NECESSÁRIA:" -ForegroundColor Yellow
Write-Host "Você está prestes a DESABILITAR 5 usuários aleatórios!" -ForegroundColor Yellow
Write-Host "⚠️  Todos os atributos serão mantidos, apenas a conta será desabilitada." -ForegroundColor Yellow
Write-Host ""

$finalConfirmation = Read-Host "Digite 'sim' para confirmar ou 'não' para cancelar"

if ($finalConfirmation -ne "sim") {
    Write-Host ""
    Write-Host "❌ Operação cancelada pelo usuário." -ForegroundColor Red
    exit
}

Write-Host ""
Write-Host "✅ Iniciando desabilitação de usuários..." -ForegroundColor Green
Write-Host "⏳ Processando..." -ForegroundColor Cyan
Write-Host ""

# ============================================================
# DESABILITAR USUÁRIOS
# ============================================================
$successCount = 0
$errorCount = 0
$currentCount = 0

foreach ($user in $randomUsers) {
    $currentCount++
    $upn = $user.UserPrincipalName
    $displayName = $user.DisplayName
    
    try {
        Update-MgUser -UserId $upn -AccountEnabled:$false
        Write-Host "✅ [$currentCount/5] $displayName desabilitado" -ForegroundColor Green
        $successCount++
    } catch {
        Write-Host "❌ [$currentCount/5] Erro ao desabilitar $displayName : $_" -ForegroundColor Red
        $errorCount++
    }
    
    Start-Sleep -Milliseconds 500
}

# ============================================================
# RESUMO FINAL
# ============================================================
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "📊 RESUMO DO PROCESSO:" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "Total processado: 5" -ForegroundColor White
Write-Host "✅ Desabilitados com sucesso: $successCount" -ForegroundColor Green
Write-Host "❌ Erros: $errorCount" -ForegroundColor Red
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

if ($errorCount -eq 0) {
    Write-Host ""
    Write-Host "✨ 5 usuários desabilitados com sucesso! Todos os atributos foram mantidos." -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "⚠️  Processo concluído com $errorCount erro(s)." -ForegroundColor Yellow
}
