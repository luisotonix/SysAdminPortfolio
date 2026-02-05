# ============================================================
# M365 Test Email Generator (App-Only Version)
# Múltiplos usuários do tenant enviam emails para outros
# Requer: App Registration com Mail.Send application permission
# ============================================================

param(
    [switch]$WhatIf,
    [switch]$AutoConfirm,
    [string]$ClientId,
    [string]$ClientSecret,
    [string]$TenantId,
    [int]$PauseSeconds = 2
)

# ============================================================
# Função para carregar arquivo .env
# ============================================================
function Import-DotEnv {
    param([string]$Path = ".credentials")
    
    $envFile = Join-Path $PSScriptRoot $Path
    
    if (Test-Path $envFile) {
        Write-Host "📁 Carregando credenciais de $Path..." -ForegroundColor Gray
        Get-Content $envFile | ForEach-Object {
            if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
                $key = $matches[1].Trim()
                $value = $matches[2].Trim()
                [Environment]::SetEnvironmentVariable($key, $value, "Process")
            }
        }
        return $true
    }
    return $false
}

# ============================================================
# Início do script
# ============================================================
Write-Host ""
Write-Host "📧 M365 Test Email Generator (App-Only Mode)" -ForegroundColor Cyan
Write-Host "💼 Múltiplos usuários do tenant enviando emails..." -ForegroundColor Yellow
Write-Host ""

# Se não tiver credentials via parâmetros, tentar carregar do .env
if (-not $ClientId -or -not $ClientSecret -or -not $TenantId) {
    $loaded = Import-DotEnv
    
    # Preencher com variáveis de ambiente (do .env ou do sistema)
    if (-not $TenantId)     { $TenantId = $env:M365_TENANT_ID }
    if (-not $ClientId)     { $ClientId = $env:M365_CLIENT_ID }
    if (-not $ClientSecret) { $ClientSecret = $env:M365_CLIENT_SECRET }
}

# Validar se temos tudo
if (-not $ClientId -or -not $ClientSecret -or -not $TenantId) {
    Write-Host "❌ Erro: Credenciais não encontradas." -ForegroundColor Red
    Write-Host ""
    Write-Host "Opção 1 - Criar arquivo .env na pasta do script:" -ForegroundColor Yellow
    Write-Host "  Copie .env.example para .env e preencha suas credenciais" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Opção 2 - Passar via parâmetros:" -ForegroundColor Yellow
    Write-Host "  . './m365TestEmailGenerator_AppOnly.ps1' -ClientId 'xxx' -ClientSecret 'yyy' -TenantId 'zzz'" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Opção 3 - Definir variáveis de ambiente:" -ForegroundColor Yellow
    Write-Host "  `$env:M365_TENANT_ID = 'xxx'" -ForegroundColor Gray
    Write-Host "  `$env:M365_CLIENT_ID = 'yyy'" -ForegroundColor Gray
    Write-Host "  `$env:M365_CLIENT_SECRET = 'zzz'" -ForegroundColor Gray
    Write-Host ""
    return
}

Write-Host "✅ Credenciais carregadas" -ForegroundColor Green

# Desconectar sessão anterior (evita problemas de cache de token)
try { Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null } catch { }

# Conectar com app-only auth
Write-Host "🔐 Conectando ao Microsoft Graph (App-Only)..." -ForegroundColor Cyan
try {
    $securePassword = ConvertTo-SecureString -String $ClientSecret -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($ClientId, $securePassword)
    
    Connect-MgGraph -TenantId $TenantId -ClientSecretCredential $credential -NoWelcome -ErrorAction Stop | Out-Null
    Write-Host "✅ Conectado com sucesso" -ForegroundColor Green
} catch {
    Write-Host "❌ Erro ao conectar: $($_.Exception.Message)" -ForegroundColor Red
    return
}

# Validar tenant
Write-Host ""
$org = Get-MgOrganization -ErrorAction SilentlyContinue
if ($org) {
    Write-Host "ℹ️  Tenant: $($org.DisplayName) ($($org.Id))" -ForegroundColor White
    if (-not $AutoConfirm) {
        $confirm = Read-Host "Deseja continuar? (sim/não)"
        if ($confirm -ne 'sim') {
            Write-Host "❌ Cancelado." -ForegroundColor Red
            return
        }
    }
}

Write-Host ""
Write-Host "🔎 Buscando usuários com mailbox ativa..." -ForegroundColor Cyan
$users = @()
try {
    $users = Get-MgUser -Top 200 -Property "userPrincipalName,Mail,UserType" | 
             Where-Object { 
                 $_.Mail -and                                    # Tem email preenchido
                 $_.Mail -ne "" -and
                 $_.UserType -eq "Member" -and                   # Não é guest/externo
                 $_.userPrincipalName -notmatch "#EXT#"          # Não é conta externa
             } | 
             Select-Object -ExpandProperty userPrincipalName
} catch {
    Write-Host "⚠️  Erro ao buscar usuários: $($_.Exception.Message)" -ForegroundColor Yellow
}

if ($users.Count -lt 15) {
    Write-Host "❌ Precisa de pelo menos 15 usuários COM MAILBOX no tenant." -ForegroundColor Red
    Write-Host "   Usuários com mailbox encontrados: $($users.Count)" -ForegroundColor Red
    Write-Host ""
    Write-Host "💡 Dica: Os usuários precisam ter licença de Exchange Online." -ForegroundColor Yellow
    return
}

Write-Host "✅ Encontrados $($users.Count) usuários com mailbox ativa." -ForegroundColor Green

# Selecionar 10 remetentes e resto como destinatários
$senders = $users | Get-Random -Count 10
$potentialRecipients = $users | Where-Object { $_ -notin $senders }

Write-Host ""
Write-Host "📧 Remetentes selecionados (10 usuários):" -ForegroundColor Cyan
$senders | ForEach-Object { Write-Host "  • $_" -ForegroundColor Gray }

function Send-TestEmail {
    param(
        [string]$SenderEmail,
        [string]$RecipientEmail,
        [string]$Subject,
        [string]$Body
    )

    $message = @{ 
        Message = @{ 
            Subject = $Subject
            Body = @{ ContentType = 'Text'; Content = $Body }
            ToRecipients = @(@{ EmailAddress = @{ Address = $RecipientEmail } })
        }
        SaveToSentItems = 'true'
    }

    if ($WhatIf) {
        Write-Host "[WhatIf] Would send from $SenderEmail -> $RecipientEmail : $Subject" -ForegroundColor Gray
        return
    }

    try {
        Send-MgUserMail -UserId $SenderEmail -BodyParameter $message -ErrorAction Stop
        Write-Host "✅ Sent from $SenderEmail -> $RecipientEmail : $Subject" -ForegroundColor Green
    } catch {
        Write-Host "❌ Error from $SenderEmail -> $RecipientEmail : $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "📧 Iniciando envio de ~110 emails..." -ForegroundColor Cyan
Write-Host ""

# Fase A: Primeiro remetente envia 20 emails
$sender1 = $senders[0]
Write-Host "▶ Fase 1: $sender1 envia 20 emails" -ForegroundColor White
1..20 | ForEach-Object {
    $recipient = Get-Random -InputObject $potentialRecipients
    $subject = "Email Teste $_"
    $body = "Este é um email de teste número $_ enviado em $(Get-Date) para validar backup do Exchange Online."

    Send-TestEmail -SenderEmail $sender1 -RecipientEmail $recipient -Subject $subject -Body $body
    Start-Sleep -Seconds $PauseSeconds
}
Write-Host "✅ Concluído: 20 emails de $sender1 (ou simulados)." -ForegroundColor Cyan

# Fase B: Remetentes 2-10 enviam 10 emails cada
Write-Host ""
Write-Host "▶ Fase 2: $($senders.Count - 1) remetentes adicionais (10 emails cada)" -ForegroundColor White
1..9 | ForEach-Object {
    $senderIdx = $_
    $senderEmail = $senders[$senderIdx]
    
    1..10 | ForEach-Object {
        $recipient = Get-Random -InputObject $potentialRecipients
        $subject = "Lote $senderIdx - Email $_"
        $body = "Email do remetente $senderEmail, número $_, enviado em $(Get-Date)."

        Send-TestEmail -SenderEmail $senderEmail -RecipientEmail $recipient -Subject $subject -Body $body
        Start-Sleep -Seconds $PauseSeconds
    }
    Write-Host "Concluído: Lote $senderIdx ($senderEmail) - 10 emails" -ForegroundColor Gray
}

Write-Host ""
Write-Host "✅ Processo finalizado. Total: ~110 emails enviados por 10 remetentes (ou simulados)." -ForegroundColor Green