# ============================================================
# M365 Test Email Generator
# Envia emails de teste entre usuários (Exchange Online / Microsoft Graph)
# Padrão: suporte a modo de simulação (-WhatIf) e confirmação automática (-AutoConfirm)
# ============================================================

param(
    [switch]$WhatIf,
    [switch]$AutoConfirm,
    [int]$PauseSeconds = 2
)

Write-Host ""
Write-Host "📧 M365 Test Email Generator" -ForegroundColor Cyan
Write-Host "⚠️  Nota: para envio real é necessário Connect-MgGraph com escopo Mail.Send." -ForegroundColor Yellow
Write-Host ""

# Validar se já existe conexão ao Graph; se não, conectar
Write-Host "🔐 Verificando conexão ao Microsoft Graph..." -ForegroundColor Cyan
$graphConnected = $false
try {
    $org = Get-MgOrganization -ErrorAction SilentlyContinue
    if ($org) {
        $graphConnected = $true
        Write-Host "✅ Já conectado ao Graph" -ForegroundColor Green
    }
} catch {
    # ignore
}

if (-not $graphConnected) {
    Write-Host "⚠️  Não há conexão ativa ao Microsoft Graph. Conectando..." -ForegroundColor Yellow
    try {
        Connect-MgGraph -Scopes 'User.Read','Mail.Send','User.Read.All' -NoWelcome -ErrorAction Stop | Out-Null
        Write-Host "✅ Conectado ao Microsoft Graph" -ForegroundColor Green
    } catch {
        Write-Host "❌ Erro ao conectar ao Microsoft Graph: $($_.Exception.Message)" -ForegroundColor Red
        return
    }
}

if (-not $AutoConfirm) {
    $org = Get-MgOrganization -ErrorAction SilentlyContinue
    if ($org) {
        Write-Host "ℹ️  Tenant detectado: $($org.DisplayName) ($($org.Id))" -ForegroundColor White
        $confirm = Read-Host "Deseja continuar com este tenant? (sim/não)"
        if ($confirm -ne 'sim') {
            Write-Host "❌ Operação cancelada pelo usuário." -ForegroundColor Red
            return
        }
    }
}

# Buscar usuários reais do tenant
Write-Host "🔎 Buscando usuários do tenant..." -ForegroundColor Cyan
$users = @()
try {
    $users = Get-MgUser -Top 200 -Property "userPrincipalName" | 
             Where-Object { $_.userPrincipalName -and $_.userPrincipalName -ne "" } | 
             Select-Object -ExpandProperty userPrincipalName
} catch {
    Write-Host "⚠️  Erro ao buscar usuários: $($_.Exception.Message)" -ForegroundColor Yellow
}

if ($users.Count -lt 2) {
    Write-Host "❌ Precisa de pelo menos 2 usuários no tenant para enviar emails de teste." -ForegroundColor Red
    Write-Host "   Usuários encontrados: $($users.Count)" -ForegroundColor Red
    return
}

Write-Host "✅ Encontrados $($users.Count) usuários no tenant." -ForegroundColor Green


# Obter ID do usuário autenticado (remetente)
Write-Host "🔏 Obtendo informações do usuário autenticado..." -ForegroundColor Cyan
$senderId = $null
try {
    $meUser = Get-MgMe -ErrorAction SilentlyContinue
    if ($meUser) {
        $senderId = $meUser.Id
        Write-Host "✅ Remetente (você): $($meUser.userPrincipalName)" -ForegroundColor Green
    }
} catch {
    # ignore
}

if (-not $senderId) {
    Write-Host "❌ Erro: não foi possível obter seu usuário autenticado para enviar emails." -ForegroundColor Red
    Write-Host "   (Mail.Send requer estar conectado como um usuário com mailbox ativo)" -ForegroundColor Red
    return
}

function Send-TestEmail {
    param(
        [string]$SenderId,
        [string]$ToEmail,
        [string]$Subject,
        [string]$Body
    )

    $message = @{ 
        Message = @{ 
            Subject = $Subject
            Body = @{ ContentType = 'Text'; Content = $Body }
            ToRecipients = @(@{ EmailAddress = @{ Address = $ToEmail } })
        }
        SaveToSentItems = 'true'
    }

    if ($WhatIf) {
        Write-Host "[WhatIf] Would send to $ToEmail : $Subject" -ForegroundColor Gray
        return
    }

    try {
        Send-MgUserMail -UserId $SenderId -BodyParameter $message -ErrorAction Stop
        Write-Host "✅ Sent to: $ToEmail : $Subject" -ForegroundColor Green
    } catch {
        Write-Host "❌ Error sending to $ToEmail : $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "📧 Preparando envio de ~110 emails para múltiplos destinatários..." -ForegroundColor Cyan
Write-Host ""

# Fase A: 20 emails para destinatários aleatórios
Write-Host "▶ Fase 1: 20 emails para destinatários aleatórios" -ForegroundColor White
1..20 | ForEach-Object {
    $toUser = Get-Random -InputObject $users
    $subject = "Email Teste $_"
    $body = "Este é um email de teste número $_ criado em $(Get-Date) para validar backup do Exchange Online."

    Send-TestEmail -SenderId $senderId -ToEmail $toUser -Subject $subject -Body $body
    Start-Sleep -Seconds $PauseSeconds
}

Write-Host "✅ Concluído: 20 emails enviados (ou simulados)." -ForegroundColor Cyan

# Fase B: 9 lotes de 10 emails cada
Write-Host ""
Write-Host "▶ Fase 2: 90 emails adicionais (9 lotes de 10)" -ForegroundColor White
1..9 | ForEach-Object {
    $lote = $_
    1..10 | ForEach-Object {
        $toUser = Get-Random -InputObject $users
        $subject = "Lote $lote - Email Teste $_"
        $body = "Email do lote $lote, número $_, enviado em $(Get-Date)."

        Send-TestEmail -SenderId $senderId -ToEmail $toUser -Subject $subject -Body $body
        Start-Sleep -Seconds $PauseSeconds
    }
    Write-Host "Concluído: Lote $lote (10 emails)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "✅ Processo finalizado. Total: ~110 emails enviados (ou simulados)." -ForegroundColor Green

