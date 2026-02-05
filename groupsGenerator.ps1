# ============================================================
# GROUPS GENERATOR - CRIAR GRUPOS COM ESTRUTURA ALEATÓRIA
# Script para criar grupos de segurança, M365 e dinâmicos
# com nomes e configurações aleatórias
# ============================================================

# Palavras aleatórias para gerar nomes
$adjectives = @("Azure", "Cloud", "Digital", "Smart", "Agile", "Rapid", "Secure", "Dynamic", "Stellar", "Elite")
$nouns = @("Developers", "Architects", "Managers", "Analysts", "Engineers", "Specialists", "Coordinators", "Consultants", "Advisors", "Leaders")
$departments = @("Tecnologia", "RH", "Financeiro", "Marketing", "Vendas", "Operações", "Logística")
$cities = @("São Paulo", "Rio de Janeiro", "Belo Horizonte", "Brasília", "Salvador", "Recife", "Curitiba", "Porto Alegre")

function Get-RandomName {
    param(
        [int]$Type = 1 # 1 = Adjective+Noun, 2 = Department, 3 = City
    )
    
    if ($Type -eq 1) {
        $adj = $adjectives | Get-Random
        $noun = $nouns | Get-Random
        return "$adj $noun"
    } elseif ($Type -eq 2) {
        return $departments | Get-Random
    } else {
        return $cities | Get-Random
    }
}

# Conectar ao Microsoft Graph
Write-Host "🔐 Conectando ao Microsoft Graph..." -ForegroundColor Cyan
Connect-MgGraph -Scopes "Group.ReadWrite.All", "User.ReadWrite.All", "Directory.ReadWrite.All" | Out-Null

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
Write-Host "ℹ️  Carregando usuários para operações..." -ForegroundColor Cyan
$allUsers = Get-MgUser -All -PageSize 999
Write-Host "✅ Total de usuários encontrados: $($allUsers.Count)" -ForegroundColor Green
Write-Host ""

# ============================================================
# RESUMO DO PLANO
# ============================================================
Write-Host "📋 PLANO DE CRIAÇÃO:" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host "  • 30 Grupos de Segurança (nomes aleatórios)" -ForegroundColor White
Write-Host "  • 10 Grupos Microsoft 365 (nomes aleatórios)" -ForegroundColor White
Write-Host "  • 5 Grupos Dinâmicos (com regras variadas)" -ForegroundColor White
Write-Host "  • 2 Grupos Role-Assignable" -ForegroundColor White
Write-Host "  • 1 Hierarquia de 3 Grupos Aninhados" -ForegroundColor White
Write-Host "  • Membros aleatórios adicionados aos grupos" -ForegroundColor White
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host ""

# Pedir confirmação final
Write-Host "⚠️  CONFIRMAÇÃO NECESSÁRIA:" -ForegroundColor Yellow
Write-Host "Esta operação criará múltiplos grupos e pode levar alguns minutos." -ForegroundColor Yellow
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
# FASE 1: CRIAR 30 GRUPOS DE SEGURANÇA
# ============================================================
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "FASE 1: Criando 30 Grupos de Segurança (nomes aleatórios)" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan

$securityGroups = @()
$successCount = 0

for ($i = 1; $i -le 30; $i++) {
    $groupName = "GrpSec - $(Get-RandomName -Type 1)"
    $mailNickname = "grpsec$(Get-Random -Minimum 10000 -Maximum 99999)"
    
    try {
        $params = @{
            displayName      = $groupName
            mailEnabled      = $false
            mailNickname     = $mailNickname
            securityEnabled  = $true
        }
        
        $newGroup = New-MgGroup -BodyParameter $params
        $securityGroups += $newGroup
        Write-Host "✅ [$i/30] $groupName criado" -ForegroundColor Green
        $successCount++
    } catch {
        Write-Host "❌ [$i/30] Erro ao criar grupo: $_" -ForegroundColor Red
    }
    
    Start-Sleep -Milliseconds 500
}

Write-Host ""
Write-Host "📊 Grupos de segurança criados: $successCount/30" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# FASE 2: CRIAR 10 GRUPOS MICROSOFT 365
# ============================================================
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "FASE 2: Criando 10 Grupos Microsoft 365 (nomes aleatórios)" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan

$m365Groups = @()
$successCount = 0

for ($i = 1; $i -le 10; $i++) {
    $groupName = "GrpM365 - $(Get-RandomName -Type 1)"
    $mailNickname = "grpm365$(Get-Random -Minimum 10000 -Maximum 99999)"
    
    try {
        $params = @{
            displayName  = $groupName
            mailEnabled  = $true
            mailNickname = $mailNickname
            securityEnabled = $false
            groupTypes   = @("Unified")
            visibility   = "Private"
        }
        
        $newGroup = New-MgGroup -BodyParameter $params
        $m365Groups += $newGroup
        Write-Host "✅ [$i/10] $groupName criado" -ForegroundColor Green
        $successCount++
    } catch {
        Write-Host "❌ [$i/10] Erro ao criar grupo M365: $_" -ForegroundColor Red
    }
    
    Start-Sleep -Milliseconds 500
}

Write-Host ""
Write-Host "📊 Grupos M365 criados: $successCount/10" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# FASE 3: CRIAR 5 GRUPOS DINÂMICOS
# ============================================================
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "FASE 3: Criando 5 Grupos Dinâmicos (com regras variadas)" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan

$dynamicGroups = @()
$dynamicRules = @(
    @{ name = "Dinâmico TI"; rule = "(user.department -eq `"Tecnologia`")"; description = "Usuários do departamento de Tecnologia" },
    @{ name = "Dinâmico RH"; rule = "(user.department -eq `"RH`")"; description = "Usuários do departamento de RH" },
    @{ name = "Dinâmico SP"; rule = "(user.city -eq `"São Paulo`")"; description = "Usuários localizados em São Paulo" },
    @{ name = "Dinâmico Financeiro"; rule = "(user.department -eq `"Financeiro`")"; description = "Usuários do departamento de Financeiro" },
    @{ name = "Dinâmico Vendas"; rule = "(user.department -eq `"Vendas`")"; description = "Usuários do departamento de Vendas" }
)

$successCount = 0

foreach ($rule in $dynamicRules) {
    try {
        $params = @{
            displayName             = $rule.name
            description             = $rule.description
            mailEnabled             = $false
            mailNickname            = "dyn$(Get-Random -Minimum 10000 -Maximum 99999)"
            securityEnabled         = $true
            groupTypes              = @("DynamicMembership")
            membershipRule          = $rule.rule
            membershipRuleProcessingState = "On"
        }
        
        $newGroup = New-MgGroup -BodyParameter $params
        $dynamicGroups += $newGroup
        Write-Host "✅ $($rule.name) criado" -ForegroundColor Green
        Write-Host "   Regra: $($rule.rule)" -ForegroundColor Gray
        $successCount++
    } catch {
        Write-Host "❌ Erro ao criar $($rule.name): $_" -ForegroundColor Red
    }
    
    Start-Sleep -Milliseconds 500
}

Write-Host ""
Write-Host "📊 Grupos dinâmicos criados: $successCount/5" -ForegroundColor Cyan
Write-Host "⚠️  Nota: Pode levar 15-30 minutos para os membros serem adicionados automaticamente" -ForegroundColor Yellow
Write-Host ""

# ============================================================
# FASE 4: CRIAR 2 GRUPOS ROLE-ASSIGNABLE
# ============================================================
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "FASE 4: Criando 2 Grupos Role-Assignable" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan

$roleAssignableGroups = @()
$successCount = 0

for ($i = 1; $i -le 2; $i++) {
    $groupName = "GrpRole - $(Get-RandomName -Type 1)"
    
    try {
        $params = @{
            displayName      = $groupName
            mailEnabled      = $false
            mailNickname     = "grprole$(Get-Random -Minimum 10000 -Maximum 99999)"
            securityEnabled  = $true
            isAssignableToRole = $true
        }
        
        $newGroup = New-MgGroup -BodyParameter $params
        $roleAssignableGroups += $newGroup
        Write-Host "✅ [$i/2] $groupName criado (Role-Assignable)" -ForegroundColor Green
        $successCount++
    } catch {
        Write-Host "❌ [$i/2] Erro ao criar grupo Role-Assignable: $_" -ForegroundColor Red
    }
    
    Start-Sleep -Milliseconds 500
}

Write-Host ""
Write-Host "📊 Grupos Role-Assignable criados: $successCount/2" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# FASE 5: CRIAR HIERARQUIA DE GRUPOS ANINHADOS
# ============================================================
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "FASE 5: Criando Hierarquia de 3 Grupos Aninhados" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan

try {
    $grupoA = New-MgGroup -DisplayName "Grupo PAI - $(Get-RandomName -Type 1)" -MailEnabled:$false -MailNickname "grpparent$(Get-Random -Minimum 10000 -Maximum 99999)" -SecurityEnabled:$true
    Write-Host "✅ Grupo Pai criado: $($grupoA.DisplayName)" -ForegroundColor Green
    Start-Sleep -Milliseconds 300
    
    $grupoB = New-MgGroup -DisplayName "Grupo FILHO - $(Get-RandomName -Type 1)" -MailEnabled:$false -MailNickname "grpchild$(Get-Random -Minimum 10000 -Maximum 99999)" -SecurityEnabled:$true
    Write-Host "✅ Grupo Filho criado: $($grupoB.DisplayName)" -ForegroundColor Green
    Start-Sleep -Milliseconds 300
    
    $grupoC = New-MgGroup -DisplayName "Grupo NETO - $(Get-RandomName -Type 1)" -MailEnabled:$false -MailNickname "grpgrandchild$(Get-Random -Minimum 10000 -Maximum 99999)" -SecurityEnabled:$true
    Write-Host "✅ Grupo Neto criado: $($grupoC.DisplayName)" -ForegroundColor Green
    Start-Sleep -Milliseconds 300
    
    # Aninhar os grupos
    Write-Host ""
    Write-Host "🔗 Estabelecendo relações de aninhamento..." -ForegroundColor Cyan
    
    New-MgGroupMember -GroupId $grupoB.Id -DirectoryObjectId $grupoC.Id
    Write-Host "✅ $($grupoC.DisplayName) adicionado a $($grupoB.DisplayName)" -ForegroundColor Green
    Start-Sleep -Milliseconds 300
    
    New-MgGroupMember -GroupId $grupoA.Id -DirectoryObjectId $grupoB.Id
    Write-Host "✅ $($grupoB.DisplayName) adicionado a $($grupoA.DisplayName)" -ForegroundColor Green
    Start-Sleep -Milliseconds 300
    
    Write-Host ""
    Write-Host "✨ Hierarquia criada: $($grupoA.DisplayName) > $($grupoB.DisplayName) > $($grupoC.DisplayName)" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Erro ao criar hierarquia: $_" -ForegroundColor Red
}

Write-Host ""

# ============================================================
# FASE 6: ADICIONAR MEMBROS AOS GRUPOS
# ============================================================
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "FASE 6: Adicionando Membros Aleatórios aos Grupos" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan

if ($securityGroups.Count -gt 0 -and $allUsers.Count -gt 0) {
    # Adicionar membros ao primeiro grupo de segurança
    $targetGroup = $securityGroups[0]
    $memberCount = [Math]::Min(50, $allUsers.Count)
    $randomUsers = $allUsers | Get-Random -Count $memberCount
    
    Write-Host ""
    Write-Host "👥 Adicionando $memberCount membros aleatórios a: $($targetGroup.DisplayName)" -ForegroundColor Cyan
    
    $addedCount = 0
    foreach ($user in $randomUsers) {
        try {
            New-MgGroupMember -GroupId $targetGroup.Id -DirectoryObjectId $user.Id | Out-Null
            $addedCount++
        } catch {
            # Silenciosamente ignora erros (usuário pode já ser membro)
        }
        
        if ($addedCount % 10 -eq 0) {
            Write-Host "✅ $addedCount membros adicionados..." -ForegroundColor Green
        }
        
        Start-Sleep -Milliseconds 200
    }
    
    Write-Host "✅ Total de membros adicionados: $addedCount" -ForegroundColor Green
    
    # Adicionar 3 owners aleatórios
    Write-Host ""
    Write-Host "👔 Adicionando 3 owners aleatórios..." -ForegroundColor Cyan
    $owners = $allUsers | Get-Random -Count 3
    
    $ownerCount = 0
    foreach ($owner in $owners) {
        try {
            New-MgGroupOwner -GroupId $targetGroup.Id -DirectoryObjectId $owner.Id | Out-Null
            Write-Host "✅ $($owner.DisplayName) adicionado como owner" -ForegroundColor Green
            $ownerCount++
        } catch {
            Write-Host "❌ Erro ao adicionar owner $($owner.DisplayName): $_" -ForegroundColor Red
        }
        
        Start-Sleep -Milliseconds 300
    }
    
    Write-Host ""
    Write-Host "📊 Owners adicionados: $ownerCount/3" -ForegroundColor Cyan
}

# Adicionar membros aleatórios aos outros grupos
Write-Host ""
Write-Host "👥 Adicionando membros aleatórios aos demais grupos..." -ForegroundColor Cyan

$allGroupsToPopulate = $securityGroups[1..($securityGroups.Count - 1)] + $m365Groups

foreach ($group in $allGroupsToPopulate) {
    if ($allUsers.Count -gt 0) {
        $memberCountForGroup = Get-Random -Minimum 5 -Maximum 15
        $memberCountForGroup = [Math]::Min($memberCountForGroup, $allUsers.Count)
        
        $randomMembers = $allUsers | Get-Random -Count $memberCountForGroup
        
        $countAdded = 0
        foreach ($member in $randomMembers) {
            try {
                New-MgGroupMember -GroupId $group.Id -DirectoryObjectId $member.Id | Out-Null
                $countAdded++
            } catch {
                # Silenciosamente ignora
            }
            
            Start-Sleep -Milliseconds 100
        }
        
        Write-Host "✅ $($group.DisplayName): $countAdded membros adicionados" -ForegroundColor Green
    }
}

Write-Host ""

# ============================================================
# RESUMO FINAL
# ============================================================
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "✨ RESUMO FINAL DO PROCESSO" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green

Write-Host ""
Write-Host "📋 GRUPOS CRIADOS:" -ForegroundColor Cyan
Write-Host "  • Grupos de Segurança: $($securityGroups.Count)/30" -ForegroundColor White
Write-Host "  • Grupos Microsoft 365: $($m365Groups.Count)/10" -ForegroundColor White
Write-Host "  • Grupos Dinâmicos: $($dynamicGroups.Count)/5" -ForegroundColor White
Write-Host "  • Grupos Role-Assignable: $($roleAssignableGroups.Count)/2" -ForegroundColor White
Write-Host "  • Hierarquias de Grupos: 1 (3 grupos aninhados)" -ForegroundColor White

Write-Host ""
Write-Host "📊 TOTAL DE GRUPOS CRIADOS: $($securityGroups.Count + $m365Groups.Count + $dynamicGroups.Count + $roleAssignableGroups.Count + 3)" -ForegroundColor Green

Write-Host ""
Write-Host "⏰ PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "  • Aguardar 15-30 minutos para processamento dos Grupos Dinâmicos" -ForegroundColor White
Write-Host "  • Verificar se membros foram adicionados automaticamente aos grupos dinâmicos" -ForegroundColor White
Write-Host "  • Revisar os nomes e membros dos grupos criados" -ForegroundColor White

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green
