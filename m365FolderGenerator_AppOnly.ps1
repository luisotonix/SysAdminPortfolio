# ============================================================
# M365 Mailbox Folder Generator (App-Only Version)
# Cria estrutura de pastas personalizadas em mailboxes
# Requer: App Registration com Mail.ReadWrite application permission
# ============================================================

param(
    [switch]$WhatIf,
    [switch]$AutoConfirm,
    [string]$ClientId,
    [string]$ClientSecret,
    [string]$TenantId,
    [int]$FullStructureUsers = 3,      # Usuários com estrutura completa (9 pastas)
    [int]$SimpleStructureUsers = 5     # Usuários com estrutura simples (3 pastas)
)

# ============================================================
# Função para carregar arquivo .credentials (formato .env)
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
# Função para criar pasta (com suporte a subpastas)
# ============================================================
function New-MailboxFolder {
    param(
        [string]$UserId,
        [string]$FolderPath
    )

    $parts = $FolderPath -split '\\'
    $parentFolderId = $null
    $currentPath = ""

    foreach ($folderName in $parts) {
        $currentPath = if ($currentPath) { "$currentPath\$folderName" } else { $folderName }

        if ($WhatIf) {
            Write-Host "  [WhatIf] Criaria pasta: $currentPath" -ForegroundColor Gray
            continue
        }

        try {
            if ($null -eq $parentFolderId) {
                # Pasta raiz
                $folder = New-MgUserMailFolder -UserId $UserId -DisplayName $folderName -ErrorAction Stop
                $parentFolderId = $folder.Id
            } else {
                # Subpasta
                $folder = New-MgUserMailFolderChildFolder -UserId $UserId -MailFolderId $parentFolderId -DisplayName $folderName -ErrorAction Stop
                $parentFolderId = $folder.Id
            }
            Write-Host "  ✅ Criada: $currentPath" -ForegroundColor Green
        } catch {
            if ($_.Exception.Message -match "already exists") {
                Write-Host "  ⏭️  Já existe: $currentPath" -ForegroundColor Yellow
                # Buscar ID da pasta existente para continuar com subpastas
                try {
                    if ($null -eq $parentFolderId) {
                        $existing = Get-MgUserMailFolder -UserId $UserId -Filter "displayName eq '$folderName'" -ErrorAction Stop
                    } else {
                        $existing = Get-MgUserMailFolderChildFolder -UserId $UserId -MailFolderId $parentFolderId -Filter "displayName eq '$folderName'" -ErrorAction Stop
                    }
                    $parentFolderId = $existing.Id
                } catch {
                    Write-Host "  ⚠️  Não conseguiu obter ID de: $currentPath" -ForegroundColor Yellow
                    return
                }
            } else {
                Write-Host "  ❌ Erro em $currentPath : $($_.Exception.Message)" -ForegroundColor Red
                return
            }
        }
        Start-Sleep -Milliseconds 300
    }
}

# ============================================================
# Estruturas de pastas
# ============================================================
$FullFolderStructure = @(
    "Projetos-UOL",
    "Projetos-UOL\PagBank",
    "Projetos-UOL\UOL EdTech",
    "Projetos-UOL\Corporativo",
    "Backup-Importante",
    "Arquivos-2024",
    "Arquivos-2024\Q1",
    "Arquivos-2024\Q2",
    "Clientes"
)

$SimpleFolderStructure = @(
    "Projetos",
    "Pessoal",
    "Arquivados"
)

# ============================================================
# Início do script
# ============================================================
Write-Host ""
Write-Host "📂 M365 Mailbox Folder Generator (App-Only Mode)" -ForegroundColor Cyan
Write-Host "📁 Criando estrutura de pastas em mailboxes..." -ForegroundColor Yellow
Write-Host ""

# Se não tiver credentials via parâmetros, tentar carregar do .env
if (-not $ClientId -or -not $ClientSecret -or -not $TenantId) {
    Import-DotEnv | Out-Null
    
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
    Write-Host "  . './m365FolderGenerator_AppOnly.ps1' -ClientId 'xxx' -ClientSecret 'yyy' -TenantId 'zzz'" -ForegroundColor Gray
    Write-Host ""
    return
}

Write-Host "✅ Credenciais carregadas" -ForegroundColor Green

# Desconectar sessão anterior
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

# Buscar usuários com mailbox
Write-Host ""
Write-Host "🔎 Buscando usuários com mailbox ativa..." -ForegroundColor Cyan
$users = @()
try {
    $users = Get-MgUser -Top 200 -Property "userPrincipalName,Mail,UserType" | 
             Where-Object { 
                 $_.Mail -and
                 $_.Mail -ne "" -and
                 $_.UserType -eq "Member" -and
                 $_.userPrincipalName -notmatch "#EXT#"
             } | 
             Select-Object -ExpandProperty userPrincipalName
} catch {
    Write-Host "⚠️  Erro ao buscar usuários: $($_.Exception.Message)" -ForegroundColor Yellow
}

$totalNeeded = $FullStructureUsers + $SimpleStructureUsers
if ($users.Count -lt $totalNeeded) {
    Write-Host "❌ Precisa de pelo menos $totalNeeded usuários COM MAILBOX no tenant." -ForegroundColor Red
    Write-Host "   Usuários com mailbox encontrados: $($users.Count)" -ForegroundColor Red
    return
}

Write-Host "✅ Encontrados $($users.Count) usuários com mailbox ativa." -ForegroundColor Green

# Selecionar usuários aleatoriamente
$selectedUsers = $users | Get-Random -Count $totalNeeded
$fullStructureUsersList = $selectedUsers | Select-Object -First $FullStructureUsers
$simpleStructureUsersList = $selectedUsers | Select-Object -Skip $FullStructureUsers -First $SimpleStructureUsers

Write-Host ""
Write-Host "📂 Usuários selecionados para estrutura COMPLETA ($FullStructureUsers usuários, 9 pastas cada):" -ForegroundColor Cyan
$fullStructureUsersList | ForEach-Object { Write-Host "  • $_" -ForegroundColor Gray }

Write-Host ""
Write-Host "📁 Usuários selecionados para estrutura SIMPLES ($SimpleStructureUsers usuários, 3 pastas cada):" -ForegroundColor Cyan
$simpleStructureUsersList | ForEach-Object { Write-Host "  • $_" -ForegroundColor Gray }

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor DarkGray
Write-Host "📂 Iniciando criação de pastas..." -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor DarkGray

# Criar estrutura completa
$counter = 1
foreach ($upn in $fullStructureUsersList) {
    Write-Host ""
    Write-Host "▶ [$counter/$FullStructureUsers] Estrutura COMPLETA: $upn" -ForegroundColor White
    
    foreach ($folderPath in $FullFolderStructure) {
        New-MailboxFolder -UserId $upn -FolderPath $folderPath
    }
    
    Write-Host "  ✅ Concluído: 9 pastas processadas" -ForegroundColor Cyan
    $counter++
    Start-Sleep -Seconds 1
}

# Criar estrutura simples
$counter = 1
foreach ($upn in $simpleStructureUsersList) {
    Write-Host ""
    Write-Host "▶ [$counter/$SimpleStructureUsers] Estrutura SIMPLES: $upn" -ForegroundColor White
    
    foreach ($folderPath in $SimpleFolderStructure) {
        New-MailboxFolder -UserId $upn -FolderPath $folderPath
    }
    
    Write-Host "  ✅ Concluído: 3 pastas processadas" -ForegroundColor Cyan
    $counter++
    Start-Sleep -Seconds 1
}

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor DarkGray
Write-Host "✅ Processo finalizado!" -ForegroundColor Green
Write-Host "   • $FullStructureUsers usuários com estrutura completa (9 pastas)" -ForegroundColor White
Write-Host "   • $SimpleStructureUsers usuários com estrutura simples (3 pastas)" -ForegroundColor White
Write-Host "   • Total: $(($FullStructureUsers * 9) + ($SimpleStructureUsers * 3)) pastas criadas" -ForegroundColor White
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor DarkGray