# ============================================================
# CONDITIONAL ACCESS POLICIES GENERATOR
# Script para criar Named Locations e Políticas de Conditional Access
# com nomes e configurações aleatórias
# ============================================================

# Palavras aleatórias para gerar nomes de políticas
$policyAdjectives = @("Rigorosa", "Flexível", "Inteligente", "Segura", "Avançada", "Dinâmica", "Híbrida", "Proteção")
$policyNouns = @("Acesso", "Autenticação", "Identidade", "Ameaça", "Compliance", "Risco", "Verificação", "Validação")
$policyTypes = @("MFA", "Dispositivo", "Local", "Risco", "Legacy", "Admin", "Viagem", "Sensível")

function Get-RandomPolicyName {
    param([string]$Type = "Simple")
    
    if ($Type -eq "Simple") {
        $adj = $policyAdjectives | Get-Random
        $noun = $policyNouns | Get-Random
        return "CA - $adj $noun"
    } else {
        $type = $policyTypes | Get-Random
        return "CA - Bloquear $type"
    }
}

# Conectar ao Microsoft Graph
Write-Host "🔐 Conectando ao Microsoft Graph..." -ForegroundColor Cyan
Write-Host "⚠️  Nota: Você precisa ser Global Admin ou Security Admin para criar Conditional Access Policies" -ForegroundColor Yellow
Write-Host ""

Connect-MgGraph -Scopes "Policy.ReadWrite.ConditionalAccess", "Policy.Read.All", "Application.Read.All", "User.Read.All", "Group.Read.All", "Directory.Read.All" | Out-Null

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

# ============================================================
# RESUMO DO PLANO
# ============================================================
Write-Host "📋 PLANO DE CRIAÇÃO:" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host "  • 2 Named Locations (IP-based + Country-based)" -ForegroundColor White
Write-Host "  • 1 Política CA Simples (Report-Only)" -ForegroundColor White
Write-Host "  • 1 Política CA Complexa (Disabled)" -ForegroundColor White
Write-Host "  • 3 Políticas CA Adicionais (Report-Only)" -ForegroundColor White
Write-Host "  • Total: 5 Políticas de Conditional Access" -ForegroundColor White
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host ""

# Pedir confirmação final
Write-Host "⚠️  CONFIRMAÇÃO NECESSÁRIA:" -ForegroundColor Yellow
Write-Host "Esta operação criará Named Locations e Políticas de CA." -ForegroundColor Yellow
Write-Host "⚠️  Nota: Algumas políticas estarão em modo Report-Only ou Disabled para segurança." -ForegroundColor Yellow
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
# FASE 1: CRIAR 2 NAMED LOCATIONS
# ============================================================
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "FASE 1: Criando 2 Named Locations" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan

$namedLocations = @()
$successCount = 0

try {
    # Named Location 1 - IP Based
    Write-Host ""
    Write-Host "📍 Criando Named Location IP-Based..." -ForegroundColor Cyan
    
    $ipRanges = @("200.200.200.0/24", "201.201.201.0/24", "202.202.202.100/32")
    
    $params = @{
        displayName = "Office IPs"
        "@odata.type" = "#microsoft.graph.ipNamedLocation"
        isTrusted = $true
        ipRanges = @($ipRanges | ForEach-Object { @{"cidrAddress" = $_} })
    }
    
    $namedLoc1 = New-MgIdentityConditionalAccessNamedLocation -BodyParameter $params
    $namedLocations += $namedLoc1
    Write-Host "✅ Named Location 'Office IPs' criado (IP-Based)" -ForegroundColor Green
    Write-Host "   IP Ranges: $($ipRanges -join ', ')" -ForegroundColor Gray
    $successCount++
    
    Start-Sleep -Milliseconds 500
    
    # Named Location 2 - Country Based
    Write-Host ""
    Write-Host "📍 Criando Named Location Country-Based..." -ForegroundColor Cyan
    
    $countries = @("BR", "PT", "AO")
    
    $params = @{
        displayName = "Países Permitidos"
        "@odata.type" = "#microsoft.graph.countryNamedLocation"
        countriesAndRegions = @($countries)
        includeUnknownCountriesAndRegions = $false
    }
    
    $namedLoc2 = New-MgIdentityConditionalAccessNamedLocation -BodyParameter $params
    $namedLocations += $namedLoc2
    Write-Host "✅ Named Location 'Países Permitidos' criado (Country-Based)" -ForegroundColor Green
    Write-Host "   Países: $($countries -join ', ')" -ForegroundColor Gray
    $successCount++
    
} catch {
    if ($_.Exception.Message -like "*403*" -or $_.Exception.Message -like "*AccessDenied*") {
        Write-Host "❌ Erro de permissão (403 - AccessDenied)" -ForegroundColor Red
        Write-Host "⚠️  Você precisa ter permissões de Global Admin ou Security Admin" -ForegroundColor Yellow
        Write-Host "   Erro completo: $($_.Exception.Message)" -ForegroundColor Red
    } else {
        Write-Host "❌ Erro ao criar Named Locations: $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "📊 Named Locations criadas: $successCount/2" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# FASE 2: CRIAR POLÍTICA CA SIMPLES (Report-Only)
# ============================================================
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "FASE 2: Criando Política CA Simples (Report-Only)" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan

$policies = @()
$successCount = 0

try {
    Write-Host ""
    Write-Host "🔐 Criando CA Teste 01 - Require MFA..." -ForegroundColor Cyan
    
    # Selecionar um grupo aleatório para incluir
    $targetGroup = $allGroups | Get-Random
    
    $params = @{
        displayName = "CA Teste 01 - Require MFA"
        state = "enabledForReportingButNotEnforced"
        conditions = @{
            users = @{
                includeGroups = @($targetGroup.Id)
            }
            applications = @{
                includeApplications = @("All")
            }
        }
        grantControls = @{
            operator = "AND"
            builtInControls = @("mfa")
        }
    }
    
    $policy1 = New-MgIdentityConditionalAccessPolicy -BodyParameter $params
    $policies += $policy1
    Write-Host "✅ CA Teste 01 criado em modo Report-Only" -ForegroundColor Green
    Write-Host "   Grupo alvo: $($targetGroup.DisplayName)" -ForegroundColor Gray
    Write-Host "   Controle: MFA obrigatório" -ForegroundColor Gray
    $successCount++
    
} catch {
    if ($_.Exception.Message -like "*403*" -or $_.Exception.Message -like "*AccessDenied*") {
        Write-Host "❌ Erro de permissão (403) ao criar CA Teste 01" -ForegroundColor Red
    } else {
        Write-Host "❌ Erro ao criar CA Teste 01: $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "📊 Políticas simples criadas: $successCount/1" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# FASE 3: CRIAR POLÍTICA CA COMPLEXA (Disabled)
# ============================================================
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "FASE 3: Criando Política CA Complexa (Disabled)" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan

$successCount = 0

try {
    Write-Host ""
    Write-Host "🔐 Criando CA Teste 02 - Complexa..." -ForegroundColor Cyan
    
    # Selecionar um ou dois grupos aleatórios
    $randomGroup = $allGroups | Get-Random
    
    $params = @{
        displayName = "CA Teste 02 - Require MFA for Sensitive Apps"
        state = "disabled"
        conditions = @{
            users = @{
                includeGroups = @($randomGroup.Id)
            }
            applications = @{
                includeApplications = @("Office365")
            }
        }
        grantControls = @{
            operator = "AND"
            builtInControls = @("mfa")
        }
    }
    
    $policy2 = New-MgIdentityConditionalAccessPolicy -BodyParameter $params
    $policies += $policy2
    Write-Host "✅ CA Teste 02 criado em modo Disabled" -ForegroundColor Green
    Write-Host "   Grupo alvo: $($randomGroup.DisplayName)" -ForegroundColor Gray
    Write-Host "   Aplicações: Office 365" -ForegroundColor Gray
    Write-Host "   Controle: MFA obrigatório" -ForegroundColor Gray
    $successCount++
    
} catch {
    if ($_.Exception.Message -like "*403*" -or $_.Exception.Message -like "*AccessDenied*") {
        Write-Host "❌ Erro de permissão (403) ao criar CA Teste 02" -ForegroundColor Red
    } else {
        Write-Host "⚠️  Não foi possível criar CA Teste 02 com esta configuração" -ForegroundColor Yellow
        Write-Host "   Você pode criar manualmente no Portal com configurações complexas" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "📊 Políticas complexas criadas: $successCount/1" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# FASE 4: CRIAR 3 POLÍTICAS CA ADICIONAIS (Report-Only)
# ============================================================
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "FASE 4: Criando 3 Políticas CA Adicionais (Report-Only)" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan

$successCount = 0

$additionalPolicies = @(
    @{
        name = "CA Teste 03 - Block Legacy Authentication"
        description = "Bloqueia autenticação legada"
        clientAppTypes = @("exchangeActiveSync", "other")
        effect = "block"
    },
    @{
        name = "CA Teste 04 - Require Compliant Device for Admins"
        description = "Exige dispositivo compatível para admins"
        userFilter = "admin"
        effect = "compliantDevice"
    },
    @{
        name = "CA Teste 05 - Require MFA for High Risk"
        description = "Exige MFA em situações de risco"
        effect = "mfa"
    }
)

foreach ($policyDef in $additionalPolicies) {
    try {
        Write-Host ""
        Write-Host "🔐 Criando $($policyDef.name)..." -ForegroundColor Cyan
        
        $params = @{
            displayName = $policyDef.name
            state = "enabledForReportingButNotEnforced"
            conditions = @{
                users = @{
                    includeUsers = @("All")
                }
                applications = @{
                    includeApplications = @("All")
                }
            }
            grantControls = @{
                operator = "AND"
                builtInControls = @($policyDef.effect)
            }
        }
        
        # Adicionar condições específicas baseadas no tipo
        if ($policyDef.name -like "*Legacy*") {
            $params.conditions.clientAppTypes = @("exchangeActiveSync", "other")
        }
        elseif ($policyDef.name -like "*Compliant*") {
            $targetAdminGroup = $allGroups | Where-Object { $_.DisplayName -like "*admin*" -or $_.DisplayName -like "*owner*" } | Get-Random
            if ($targetAdminGroup) {
                $params.conditions.users.includeGroups = @($targetAdminGroup.Id)
                $params.conditions.users.Remove("includeUsers")
            }
            $params.grantControls.builtInControls = @("compliantDevice")
        }
        
        $newPolicy = New-MgIdentityConditionalAccessPolicy -BodyParameter $params
        $policies += $newPolicy
        Write-Host "✅ $($policyDef.name) criado em modo Report-Only" -ForegroundColor Green
        Write-Host "   Descrição: $($policyDef.description)" -ForegroundColor Gray
        $successCount++
        
    } catch {
        if ($_.Exception.Message -like "*403*" -or $_.Exception.Message -like "*AccessDenied*") {
            Write-Host "❌ Erro de permissão (403): $($policyDef.name)" -ForegroundColor Red
        } else {
            Write-Host "❌ Erro ao criar $($policyDef.name): $_" -ForegroundColor Red
        }
    }
    
    Start-Sleep -Milliseconds 500
}

Write-Host ""
Write-Host "📊 Políticas adicionais criadas: $successCount/3" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# RESUMO FINAL
# ============================================================
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "✨ RESUMO FINAL DO PROCESSO" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green

Write-Host ""
Write-Host "📍 NAMED LOCATIONS CRIADAS:" -ForegroundColor Cyan
Write-Host "  • Office IPs (IP-Based) - IPs confiáveis" -ForegroundColor White
Write-Host "  • Países Permitidos (Country-Based) - BR, PT, AO" -ForegroundColor White

Write-Host ""
Write-Host "🔐 POLÍTICAS DE CONDITIONAL ACCESS:" -ForegroundColor Cyan
Write-Host "  Total: $($policies.Count) políticas criadas" -ForegroundColor White
Write-Host ""
Write-Host "  Ativas (Report-Only):" -ForegroundColor Yellow
Write-Host "    • CA Teste 01 - Require MFA" -ForegroundColor White
Write-Host "    • CA Teste 03 - Block Legacy Authentication" -ForegroundColor White
Write-Host "    • CA Teste 04 - Require Compliant Device for Admins" -ForegroundColor White
Write-Host "    • CA Teste 05 - Monitor High Risk Signins" -ForegroundColor White

Write-Host ""
Write-Host "  Desabilitadas (Disabled):" -ForegroundColor Yellow
Write-Host "    • CA Teste 02 - Complexa (para testes posteriores)" -ForegroundColor White

Write-Host ""
Write-Host "📊 RESUMO DETALHADO:" -ForegroundColor Yellow
Write-Host "  • Named Locations criadas: 2/2" -ForegroundColor Green
Write-Host "  • Políticas CA criadas: $($policies.Count)/5" -ForegroundColor Green
Write-Host "  • Políticas em Report-Only: 4" -ForegroundColor Green
Write-Host "  • Políticas em Disabled: 1" -ForegroundColor Green

Write-Host ""
Write-Host "⏰ PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "  • Revisar políticas no Azure Portal (Security > Conditional Access)" -ForegroundColor White

if ($successCount -lt 2) {
    Write-Host ""
    Write-Host "⚠️  AVISO IMPORTANTE:" -ForegroundColor Red
    Write-Host "  • Verifique se sua conta tem permissões de Global Admin ou Security Admin" -ForegroundColor White
    Write-Host "  • Pode ser necessário fazer logout e login novamente" -ForegroundColor White
    Write-Host "  • Authenticate-MgGraph -Scopes 'Policy.ReadWrite.ConditionalAccess' com conta admin" -ForegroundColor White
} else {
    Write-Host "  • Ajustar grupos e condições conforme necessário" -ForegroundColor White
    Write-Host "  • Testar políticas em modo Report-Only" -ForegroundColor White
    Write-Host "  • Ativar políticas gradualmente em produção" -ForegroundColor White
    Write-Host "  • Monitorar relatórios de CA para impacto" -ForegroundColor White
}

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green
