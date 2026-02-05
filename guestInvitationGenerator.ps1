# ============================================================
# GUEST INVITATION GENERATOR
# Script para convidar usuários externos (guests) para o tenant
# ============================================================

# Conectar ao Microsoft Graph
Write-Host "🔐 Conectando ao Microsoft Graph..." -ForegroundColor Cyan
Connect-MgGraph -Scopes "User.Invite.All" | Out-Null

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
# LISTA DE GUESTS A CONVIDAR
# ============================================================
$guestEmails = @(
    "luisfos3@gmail.com",
    "luisotoni@outlook.com",
    "luisfelipe@ymail.com",
    "luisotonni@gmail.com",
    "luisotoni@icloud.com"
)

# Validar emails
$validEmails = @()
Write-Host "✓ Validando emails..." -ForegroundColor Cyan

foreach ($email in $guestEmails) {
    if ($email -match '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$') {
        $validEmails += $email
    } else {
        Write-Host "⚠️  Email inválido ignorado: $email" -ForegroundColor Yellow
    }
}

if ($validEmails.Count -eq 0) {
    Write-Host "❌ Nenhum email válido encontrado." -ForegroundColor Red
    exit
}

Write-Host "✅ $($validEmails.Count) email(s) válido(s) para convidar" -ForegroundColor Green
Write-Host ""

# Pedir confirmação final
Write-Host "⚠️  CONFIRMAÇÃO NECESSÁRIA:" -ForegroundColor Yellow
Write-Host "Deseja enviar convites para $($validEmails.Count) usuário(s)?" -ForegroundColor Yellow
Write-Host ""

$finalConfirmation = Read-Host "Digite 'sim' para confirmar ou 'não' para cancelar"

if ($finalConfirmation -ne "sim") {
    Write-Host ""
    Write-Host "❌ Operação cancelada pelo usuário." -ForegroundColor Red
    exit
}

Write-Host ""
Write-Host "✅ Iniciando envio de convites..." -ForegroundColor Green
Write-Host "⏳ Processando..." -ForegroundColor Cyan
Write-Host ""

# ============================================================
# ENVIAR CONVITES
# ============================================================
$successCount = 0
$errorCount = 0
$currentCount = 0
$totalCount = $validEmails.Count

foreach ($email in $validEmails) {
    $currentCount++
    
    try {
        New-MgInvitation `
            -InvitedUserEmailAddress $email `
            -InviteRedirectUrl "https://myapps.microsoft.com" `
            -SendInvitationMessage | Out-Null
        
        Write-Host "✅ [$currentCount/$totalCount] Convite enviado para $email" -ForegroundColor Green
        $successCount++
    } catch {
        Write-Host "❌ [$currentCount/$totalCount] Erro ao convidar $email : $_" -ForegroundColor Red
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
Write-Host "Total processado: $totalCount" -ForegroundColor White
Write-Host "✅ Sucessos: $successCount" -ForegroundColor Green
Write-Host "❌ Erros: $errorCount" -ForegroundColor Red
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

if ($errorCount -eq 0) {
    Write-Host ""
    Write-Host "✨ Processo concluído com sucesso!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "⚠️  Processo concluído com $errorCount erro(s)." -ForegroundColor Yellow
}