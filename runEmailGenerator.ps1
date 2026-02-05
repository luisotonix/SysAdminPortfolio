# ============================================================
# Wrapper para executar M365 Test Email Generator
# Mantém sessão Graph conectada enquanto executa o script
# ============================================================

Write-Host ""
Write-Host "🔐 Importando Microsoft Graph SDK..." -ForegroundColor Cyan
try {
    Import-Module Microsoft.Graph -ErrorAction Stop | Out-Null
    Write-Host "✅ Microsoft.Graph importado" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Aviso: Microsoft.Graph não encontrado, tentando Connect-MgGraph" -ForegroundColor Yellow
}

Write-Host "🔐 Conectando ao Microsoft Graph..." -ForegroundColor Cyan

# Conectar uma única vez
Connect-MgGraph -Scopes 'User.Read','Mail.Send','User.Read.All' -NoWelcome | Out-Null

# Validar conexão
try {
    $meUser = Get-MgMe -ErrorAction SilentlyContinue
} catch {
    $meUser = $null
}

if (-not $meUser) {
    Write-Host "❌ Falha na autenticação. Por favor, complete o login." -ForegroundColor Red
    exit 1
}

Write-Host "✅ Conectado como: $($meUser.userPrincipalName)" -ForegroundColor Green
Write-Host ""

# Agora rodar o script com -AutoConfirm e sem reconectar
& {
    param(
        [switch]$WhatIf,
        [switch]$AutoConfirm = $true,
        [int]$PauseSeconds = 2
    )

    Write-Host "📧 M365 Test Email Generator" -ForegroundColor Cyan
    Write-Host ""

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

    # Usar o usuário autenticado como remetente
    Write-Host "🔏 Remetente (você): $($meUser.userPrincipalName)" -ForegroundColor Green
    $senderId = $meUser.Id

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
} -WhatIf:$WhatIf -AutoConfirm

Write-Host ""
Write-Host "Desconectando do Microsoft Graph..." -ForegroundColor Cyan
Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null

