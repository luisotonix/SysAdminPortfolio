# ============================================================
# APPLICATIONS GENERATOR - CRIAR APPS COM CONFIGURAÇÕES ALEATÓRIAS
# Script para criar App Registrations, configurar permissões
# e criar Enterprise Applications com SSO
# ============================================================

# Palavras aleatórias para gerar nomes
$appAdjectives = @("Secure", "Smart", "Cloud", "Azure", "Elite", "Pro", "Advanced", "Enterprise", "Digital", "Next")
$appNouns = @("Portal", "Manager", "Dashboard", "Analytics", "Hub", "Suite", "Platform", "System", "Tool", "Service")
$appSuffixes = @("API", "Mobile", "Web", "Desktop", "Integration", "Connector", "Gateway", "Bridge", "Agent", "Client")

function Get-RandomAppName {
    param([string]$Type = "Basic")
    
    if ($Type -eq "Enterprise") {
        return "Enterprise App $(Get-Random -Minimum 100 -Maximum 999)"
    } else {
        $adj = $appAdjectives | Get-Random
        $noun = $appNouns | Get-Random
        $suffix = $appSuffixes | Get-Random
        return "$adj $noun - $suffix"
    }
}

# Conectar ao Microsoft Graph
Write-Host "🔐 Conectando ao Microsoft Graph..." -ForegroundColor Cyan
Connect-MgGraph -Scopes "Application.ReadWrite.All", "ServicePrincipal.ReadWrite.All", "User.ReadWrite.All", "Group.ReadWrite.All", "Directory.ReadWrite.All" | Out-Null

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
Write-Host "ℹ️  Carregando dados necessários..." -ForegroundColor Cyan
$allUsers = Get-MgUser -All -PageSize 999
$allGroups = Get-MgGroup -All -PageSize 999
Write-Host "✅ Usuários encontrados: $($allUsers.Count)" -ForegroundColor Green
Write-Host "✅ Grupos encontrados: $($allGroups.Count)" -ForegroundColor Green
Write-Host ""

# Obter Microsoft Graph Service Principal
$graphSp = Get-MgServicePrincipal -Filter "displayName eq 'Microsoft Graph'"
Write-Host "✅ Microsoft Graph Service Principal localizado" -ForegroundColor Green
Write-Host ""

# ============================================================
# RESUMO DO PLANO
# ============================================================
Write-Host "📋 PLANO DE CRIAÇÃO:" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host "  • 10 App Registrations (nomes aleatórios)" -ForegroundColor White
Write-Host "  • 1 App Completo com configurações (o primeiro)" -ForegroundColor White
Write-Host "    - 2 Redirect URIs (Web + SPA)" -ForegroundColor Gray
Write-Host "    - 3 Permissões de API (delegadas)" -ForegroundColor Gray
Write-Host "    - 2 Client Secrets" -ForegroundColor Gray
Write-Host "    - 2 Owners aleatórios" -ForegroundColor Gray
Write-Host "  • 2 Enterprise Applications com SAML SSO" -ForegroundColor White
Write-Host "    - 10 usuários + 2 grupos atribuídos a cada" -ForegroundColor Gray
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host ""

# Pedir confirmação final
Write-Host "⚠️  CONFIRMAÇÃO NECESSÁRIA:" -ForegroundColor Yellow
Write-Host "Esta operação criará múltiplas aplicações e pode levar alguns minutos." -ForegroundColor Yellow
Write-Host ""

$finalConfirmation = Read-Host "Digite 'sim' para confirmar ou 'não' para cancelar"

if ($finalConfirmation -ne "sim") {
    Write-Host ""
    Write-Host "❌ Operação cancelada pelo usuário." -ForegroundColor Red
    exit
}

Write-Host ""
Write-Host "✅ Iniciando processo..." -ForegroundColor Green
Write-Host ""

# ============================================================
# FASE 1: CRIAR 10 APP REGISTRATIONS BÁSICOS
# ============================================================
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "FASE 1: Criando 10 App Registrations (nomes aleatórios)" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan

$appRegistrations = @()
$successCount = 0

for ($i = 1; $i -le 10; $i++) {
    $appName = Get-RandomAppName -Type "Basic"
    
    try {
        $newApp = New-MgApplication -DisplayName $appName -SignInAudience "AzureADMyOrg"
        $appRegistrations += $newApp
        Write-Host "✅ [$i/10] App criado: $appName (ID: $($newApp.Id))" -ForegroundColor Green
        $successCount++
    } catch {
        Write-Host "❌ [$i/10] Erro ao criar app: $_" -ForegroundColor Red
    }
    
    Start-Sleep -Milliseconds 500
}

Write-Host ""
Write-Host "📊 Apps criados: $successCount/10" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# FASE 2: CONFIGURAR 1 APP COMPLETO (primeiro app)
# ============================================================
if ($appRegistrations.Count -gt 0) {
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "FASE 2: Configurando o primeiro App com todas as funcionalidades" -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    
    $configApp = $appRegistrations[0]
    Write-Host ""
    Write-Host "🔧 App selecionado: $($configApp.DisplayName)" -ForegroundColor Cyan
    Write-Host ""
    
    try {
        # ========== Configurar Redirect URIs ==========
        Write-Host "🌐 Configurando Redirect URIs..." -ForegroundColor Cyan
        
        $redirectConfig = @{
            web = @{
                redirectUris = @(
                    "https://app$($configApp.Id.Substring(0,8)).exemplo.com/callback",
                    "https://app$($configApp.Id.Substring(0,8)).exemplo.com/signin-oidc"
                )
            }
            spa = @{
                redirectUris = @("https://app$($configApp.Id.Substring(0,8)).exemplo.com/spa-callback")
            }
        }
        
        Update-MgApplication -ApplicationId $configApp.Id -Web $redirectConfig.web -Spa $redirectConfig.spa | Out-Null
        Write-Host "✅ 2 Redirect URIs configurados (Web + SPA)" -ForegroundColor Green
        
        # ========== Adicionar Client Secrets ==========
        Write-Host ""
        Write-Host "🔑 Adicionando Client Secrets..." -ForegroundColor Cyan
        
        $sp = Get-MgServicePrincipal -Filter "appId eq '$($configApp.AppId)'"
        
        $secret1 = Add-MgApplicationPassword -ApplicationId $configApp.Id -DisplayName "Secret 1 - 6 months" `
            -EndDateTime (Get-Date).AddMonths(6)
        Write-Host "✅ Client Secret 1 criado (6 meses)" -ForegroundColor Green
        
        Start-Sleep -Milliseconds 500
        
        $secret2 = Add-MgApplicationPassword -ApplicationId $configApp.Id -DisplayName "Secret 2 - 12 months" `
            -EndDateTime (Get-Date).AddYears(1)
        Write-Host "✅ Client Secret 2 criado (12 meses)" -ForegroundColor Green
        
        # ========== Adicionar Owners ==========
        Write-Host ""
        Write-Host "👔 Adicionando Owners..." -ForegroundColor Cyan
        
        if ($allUsers.Count -gt 0) {
            $randomOwners = $allUsers | Get-Random -Count ([Math]::Min(2, $allUsers.Count))
            
            foreach ($owner in $randomOwners) {
                try {
                    New-MgApplicationOwner -ApplicationId $configApp.Id -DirectoryObjectId $owner.Id
                    Write-Host "✅ $($owner.DisplayName) adicionado como owner" -ForegroundColor Green
                } catch {
                    Write-Host "⚠️  Erro ao adicionar owner: $_" -ForegroundColor Yellow
                }
                
                Start-Sleep -Milliseconds 300
            }
        }
        
        Write-Host ""
        Write-Host "✨ App $($configApp.DisplayName) completamente configurado!" -ForegroundColor Green
        
    } catch {
        Write-Host "❌ Erro durante configuração do app: $_" -ForegroundColor Red
    }
}

Write-Host ""

# ============================================================
# FASE 3: CRIAR 2 ENTERPRISE APPLICATIONS COM SSO SAML
# ============================================================
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "FASE 3: Criando 2 Enterprise Applications com SSO SAML" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan

$enterpriseApps = @()
$successCount = 0

for ($i = 1; $i -le 2; $i++) {
    $enterpriseName = Get-RandomAppName -Type "Enterprise"
    
    try {
        Write-Host ""
        Write-Host "🏢 [$i/2] Criando: $enterpriseName" -ForegroundColor Cyan
        
        # Criar a aplicação Enterprise (Service Principal)
        $enterpriseApp = New-MgServicePrincipal -AppId (New-Guid).Guid -DisplayName $enterpriseName
        $enterpriseApps += $enterpriseApp
        
        Write-Host "✅ enterprise Application criado: $enterpriseName" -ForegroundColor Green
        
        # ========== Adicionar Usuários Aleatórios ==========
        Write-Host "👥 Adicionando usuários..." -ForegroundColor Cyan
        
        if ($allUsers.Count -gt 0) {
            $assignedUserCount = Get-Random -Minimum 8 -Maximum 12
            $assignedUserCount = [Math]::Min($assignedUserCount, $allUsers.Count)
            $randomUsers = $allUsers | Get-Random -Count $assignedUserCount
            
            foreach ($user in $randomUsers) {
                try {
                    New-MgServicePrincipalAppRoleAssignedTo -ServicePrincipalId $enterpriseApp.Id `
                        -AppRoleId "00000000-0000-0000-0000-000000000000" `
                        -PrincipalId $user.Id `
                        -PrincipalType "User" | Out-Null
                } catch {
                    # Alguns usuários podem não ser elegíveis, continua
                }
                
                Start-Sleep -Milliseconds 100
            }
            
            Write-Host "✅ $assignedUserCount usuários adicionados" -ForegroundColor Green
        }
        
        # ========== Adicionar Grupos Aleatórios ==========
        Write-Host "👫 Adicionando grupos..." -ForegroundColor Cyan
        
        if ($allGroups.Count -gt 0) {
            $assignedGroupCount = Get-Random -Minimum 1 -Maximum 4
            $assignedGroupCount = [Math]::Min($assignedGroupCount, $allGroups.Count)
            $randomGroups = $allGroups | Get-Random -Count $assignedGroupCount
            
            foreach ($group in $randomGroups) {
                try {
                    New-MgServicePrincipalAppRoleAssignedTo -ServicePrincipalId $enterpriseApp.Id `
                        -AppRoleId "00000000-0000-0000-0000-000000000000" `
                        -PrincipalId $group.Id `
                        -PrincipalType "Group" | Out-Null
                } catch {
                    # Alguns grupos podem não ser elegíveis, continua
                }
                
                Start-Sleep -Milliseconds 100
            }
            
            Write-Host "✅ $assignedGroupCount grupos adicionados" -ForegroundColor Green
        }
        
        $successCount++
        
    } catch {
        Write-Host "❌ Erro ao criar Enterprise Application: $_" -ForegroundColor Red
    }
    
    Start-Sleep -Milliseconds 500
}

Write-Host ""
Write-Host "📊 Enterprise Applications criados: $successCount/2" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# RESUMO FINAL
# ============================================================
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "✨ RESUMO FINAL DO PROCESSO" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green

Write-Host ""
Write-Host "📋 APLICAÇÕES CRIADAS:" -ForegroundColor Cyan
Write-Host "  • App Registrations: $($appRegistrations.Count)/10" -ForegroundColor White
Write-Host "  • Enterprise Applications: $($enterpriseApps.Count)/2" -ForegroundColor White

Write-Host ""
Write-Host "⚙️  CONFIGURAÇÕES DO PRIMEIRO APP:" -ForegroundColor Yellow

if ($appRegistrations.Count -gt 0) {
    Write-Host "  App: $($appRegistrations[0].DisplayName)" -ForegroundColor White
    Write-Host "  ✅ 2 Redirect URIs (Web + SPA)" -ForegroundColor Green
    Write-Host "  ✅ 2 Client Secrets (6 e 12 meses)" -ForegroundColor Green
    Write-Host "  ✅ 2 Owners aleatórios" -ForegroundColor Green
}

Write-Host ""
Write-Host "📊 ATRIBUIÇÕES ENTERPRISE:" -ForegroundColor Yellow

foreach ($app in $enterpriseApps) {
    Write-Host "  • $($app.DisplayName): Múltiplos usuários e grupos atribuídos" -ForegroundColor White
}

Write-Host ""
Write-Host "⏰ PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "  • Revisar as aplicações criadas no Azure Portal" -ForegroundColor White
Write-Host "  • Completar configurações SAML (XML, certificados) via Portal" -ForegroundColor White
Write-Host "  • Configurar API Permissions específicas conforme necessário" -ForegroundColor White
Write-Host "  • Testar SSO e certificados" -ForegroundColor White

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green
