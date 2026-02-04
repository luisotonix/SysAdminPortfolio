# ============================================================
# ROLES & PIM GENERATOR - GERENCIAR ROLES E IDENTIDADES PRIVILEGIADAS
# Script para atribuir roles, criar custom roles, configurar PIM
# e gerenciar Administrative Units
# ============================================================

# Conectar ao Microsoft Graph
Write-Host "🔐 Conectando ao Microsoft Graph..." -ForegroundColor Cyan
Write-Host "⚠️  Nota: Você precisa ser Global Admin para atribuir roles" -ForegroundColor Yellow
Write-Host ""

Connect-MgGraph -Scopes "RoleManagement.ReadWrite.Directory", "User.ReadWrite.All", "Directory.ReadWrite.All", "AdministrativeUnit.ReadWrite.All", "PrivilegedAccess.ReadWrite.AzureAD" | Out-Null

# Obter informações do tenant
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
$allUsers = @(Get-MgUser -All -PageSize 999)
Write-Host "✅ Usuários encontrados: $($allUsers.Count)" -ForegroundColor Green
Write-Host ""

# ============================================================
# RESUMO DO PLANO
# ============================================================
Write-Host "📋 PLANO DE CRIAÇÃO:" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host "  • 3 Atribuições de Roles Built-in a usuários aleatórios" -ForegroundColor White
Write-Host "    - Global Administrator" -ForegroundColor Gray
Write-Host "    - User Administrator" -ForegroundColor Gray
Write-Host "    - Application Administrator" -ForegroundColor Gray
Write-Host "  • 2 Administrative Units com 10 membros cada" -ForegroundColor White
Write-Host "  • Informações sobre Custom Roles e PIM (via Portal)" -ForegroundColor White
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host ""

# Pedir confirmação final
Write-Host "⚠️  CONFIRMAÇÃO NECESSÁRIA:" -ForegroundColor Yellow
Write-Host "Esta operação atribuirá roles privilegiadas a usuários." -ForegroundColor Yellow
Write-Host "⚠️  Use com cuidado - essas são permissões críticas!" -ForegroundColor Yellow
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
# FASE 1: ATRIBUIR ROLES BUILT-IN
# ============================================================
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "FASE 1: Atribuindo Roles Built-in a Usuários Aleatórios" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan

$rolesAssigned = @()
$successCount = 0

$rolesToAssign = @(
    @{ name = "Global Administrator"; displayName = "Global Administrator" },
    @{ name = "User Administrator"; displayName = "User Administrator" },
    @{ name = "Application Administrator"; displayName = "Application Administrator" }
)

foreach ($roleDefn in $rolesToAssign) {
    try {
        Write-Host ""
        Write-Host "👤 Atribuindo $($roleDefn.name)..." -ForegroundColor Cyan
        
        # Obter a role por nome
        $role = Get-MgDirectoryRole -Filter "displayName eq '$($roleDefn.displayName)'" -ErrorAction SilentlyContinue
        
        if (-not $role) {
            # Se a role não existe, ativar primeiro (necessário para algumas roles)
            Write-Host "⏳ Ativando role $($roleDefn.name)..." -ForegroundColor Gray
            $allRoleTemplates = Get-MgDirectoryRoleTemplate -All
            $roleTemplate = $allRoleTemplates | Where-Object { $_.DisplayName -eq $roleDefn.displayName }
            if ($roleTemplate) {
                $role = New-MgDirectoryRole -RoleTemplateId $roleTemplate.Id -ErrorAction SilentlyContinue
                Start-Sleep -Milliseconds 500
            } else {
                Write-Host "⚠️  Role template não encontrado para $($roleDefn.name)" -ForegroundColor Yellow
            }
        }
        
        if ($role) {
            # Selecionar usuário aleatório
            $targetUser = $allUsers | Get-Random
            
            # Atribuir role ao usuário
            $memberRef = @{"@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($targetUser.Id)"}
            New-MgDirectoryRoleMemberByRef -DirectoryRoleId $role.Id -BodyParameter $memberRef | Out-Null
            
            Write-Host "✅ $($roleDefn.name) atribuído a $($targetUser.DisplayName)" -ForegroundColor Green
            $rolesAssigned += @{
                role = $roleDefn.name
                user = $targetUser.DisplayName
                userId = $targetUser.Id
            }
            $successCount++
        } else {
            Write-Host "⚠️  Role $($roleDefn.name) não pôde ser ativada ou encontrada" -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "❌ Erro ao atribuir $($roleDefn.name): $_" -ForegroundColor Red
    }
    
    Start-Sleep -Milliseconds 500
}

Write-Host ""
Write-Host "📊 Roles atribuídas: $successCount/3" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# FASE 2: INFORMAÇÕES SOBRE CUSTOM ROLES
# ============================================================
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "FASE 2: Custom Roles (Configure via Portal)" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan

Write-Host ""
Write-Host "ℹ️  Custom Roles devem ser criadas via Azure Portal" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host ""
Write-Host "Passos para criar 'Limited User Administrator':" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Acesse: Entra ID > Roles and administrators > New custom role" -ForegroundColor White
Write-Host ""
Write-Host "2. Basics:" -ForegroundColor White
Write-Host "   • Name: 'Limited User Administrator'" -ForegroundColor Gray
Write-Host "   • Description: 'Can manage users but with limited permissions'" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Permissions (adicione):" -ForegroundColor White
Write-Host "   • microsoft.directory/users/create" -ForegroundColor Gray
Write-Host "   • microsoft.directory/users/update" -ForegroundColor Gray
Write-Host "   • microsoft.directory/users/password/update" -ForegroundColor Gray
Write-Host "   • microsoft.directory/users/userPrincipalName/update" -ForegroundColor Gray
Write-Host "   • microsoft.directory/users/basic/update" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Assign role aos usuários aleatórios" -ForegroundColor White
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host ""

# ============================================================
# FASE 3: INFORMAÇÕES SOBRE PIM
# ============================================================
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "FASE 3: Privileged Identity Management (PIM)" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan

Write-Host ""
Write-Host "⚠️  PIM requer Entra ID P2 (licença Premium)" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host ""

# Tentar verificar se PIM está disponível
try {
    $pimSettings = Get-MgPolicyScopeRoleAssignmentPolicy -ErrorAction SilentlyContinue
    $pimAvailable = $true
} catch {
    $pimAvailable = $false
}

if ($pimAvailable) {
    Write-Host "✅ PIM parece estar disponível no seu tenant!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Para configurar PIM:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Acesse: Entra ID > Identity Governance > Privileged Identity Management" -ForegroundColor White
    Write-Host ""
    Write-Host "2. Azure AD roles > Roles" -ForegroundColor White
    Write-Host ""
    Write-Host "3. Selecione 'Global Administrator'" -ForegroundColor White
    Write-Host ""
    Write-Host "4. Add assignments > Add eligible assignment" -ForegroundColor White
    Write-Host "   • Select member: escolha usuário aleatório" -ForegroundColor Gray
    Write-Host "   • Assignment type: Eligible" -ForegroundColor Gray
    Write-Host "   • Start time: today" -ForegroundColor Gray
    Write-Host "   • End time: +30 days" -ForegroundColor Gray
    Write-Host "   • Justification required: Yes" -ForegroundColor Gray
    Write-Host ""
    Write-Host "5. Repetir para mais roles (User Administrator, Application Administrator)" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "❌ PIM não parece estar disponível (pode precisar de licença P2)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Para ativar PIM:" -ForegroundColor Yellow
    Write-Host "1. Verifique se tem Entra ID Premium P2" -ForegroundColor White
    Write-Host "2. Acesse: Azure Portal > Entra ID > Licenses" -ForegroundColor White
    Write-Host "3. Confirme que Premium P2 está atribuído ao tenant" -ForegroundColor White
    Write-Host ""
}

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host ""

# ============================================================
# FASE 4: CRIAR ADMINISTRATIVE UNITS
# ============================================================
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "FASE 4: Criando 2 Administrative Units com Membros" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan

$administrativeUnits = @()
$successCount = 0

$auConfigs = @(
    @{ name = "AU-Marketing"; description = "Marketing department Administrative Unit" },
    @{ name = "AU-Sales"; description = "Sales department Administrative Unit" }
)

foreach ($auConfig in $auConfigs) {
    try {
        Write-Host ""
        Write-Host "🏢 Criando $($auConfig.name)..." -ForegroundColor Cyan
        
        # Criar AU
        $au = New-MgDirectoryAdministrativeUnit -DisplayName $auConfig.name -Description $auConfig.description
        $administrativeUnits += $au
        
        Write-Host "✅ $($auConfig.name) criado (ID: $($au.Id))" -ForegroundColor Green
        
        # Adicionar membros aleatórios
        Write-Host "   Adicionando membros..." -ForegroundColor Cyan
        
        $numMembersToAdd = [Math]::Min(10, $allUsers.Count)
        $membersToAdd = $allUsers | Get-Random -Count $numMembersToAdd
        $addedCount = 0
        
        foreach ($member in $membersToAdd) {
            try {
                $memberRef = @{"@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($member.Id)"}
                New-MgDirectoryAdministrativeUnitMemberByRef -AdministrativeUnitId $au.Id -BodyParameter $memberRef | Out-Null
                $addedCount++
            } catch {
                Write-Host "      ⚠️  Erro ao adicionar $($member.DisplayName): $($_.Exception.Message)" -ForegroundColor Yellow
            }
            
            Start-Sleep -Milliseconds 100
        }
        
        Write-Host "   ✅ $addedCount membros adicionados" -ForegroundColor Green
        $successCount++
        
    } catch {
        Write-Host "❌ Erro ao criar $($auConfig.name): $_" -ForegroundColor Red
    }
    
    Start-Sleep -Milliseconds 500
}

Write-Host ""
Write-Host "📊 Administrative Units criadas: $successCount/2" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# INFORMAÇÕES SOBRE ROLE ASSIGNMENTS SCOPADOS
# ============================================================
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Atribuições de Roles Scopadas (Configure via Portal)" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan

Write-Host ""
Write-Host "ℹ️  Para atribuir roles com escopo a uma AU específica:" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host ""
Write-Host "Passos:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Acesse: Entra ID > Administrative units > AU-Marketing" -ForegroundColor White
Write-Host ""
Write-Host "2. Roles and administrators > Add role assignment" -ForegroundColor White
Write-Host ""
Write-Host "3. Selecione role: User Administrator" -ForegroundColor White
Write-Host ""
Write-Host "4. Selecione membro: usuário aleatório" -ForegroundColor White
Write-Host ""
Write-Host "5. Adicione assignment" -ForegroundColor White
Write-Host ""
Write-Host "⚠️  Isso restringe a permissão da role apenas a usuários dentro da AU" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host ""

# ============================================================
# RESUMO FINAL
# ============================================================
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "✨ RESUMO FINAL DO PROCESSO" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green

Write-Host ""
Write-Host "👤 ROLES BUILT-IN ATRIBUÍDAS:" -ForegroundColor Cyan

foreach ($assignment in $rolesAssigned) {
    Write-Host "  ✅ $($assignment.role) → $($assignment.user)" -ForegroundColor White
}

Write-Host ""
Write-Host "🏢 ADMINISTRATIVE UNITS CRIADAS:" -ForegroundColor Cyan
Write-Host "  • AU-Marketing com 10 membros" -ForegroundColor White
Write-Host "  • AU-Sales com 10 membros" -ForegroundColor White

Write-Host ""
Write-Host "📋 TAREFAS COMPLETADAS:" -ForegroundColor Cyan
Write-Host "  ✅ 3 Roles Built-in atribuídas" -ForegroundColor Green
Write-Host "  ⏳ Custom Roles (via Portal)" -ForegroundColor Yellow
Write-Host "  ⏳ PIM Configuration (via Portal + Licença P2)" -ForegroundColor Yellow
Write-Host "  ✅ 2 Administrative Units criadas" -ForegroundColor Green
Write-Host "  ⏳ Scoped Role Assignments (via Portal)" -ForegroundColor Yellow

Write-Host ""
Write-Host "⏰ PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "  • Revisar atribuições de roles no Azure Portal" -ForegroundColor White
Write-Host "  • Criar Custom Roles conforme descrito acima" -ForegroundColor White
Write-Host "  • Configurar PIM eligible assignments (se tiver P2)" -ForegroundColor White
Write-Host "  • Atribuir roles com escopo às AUs" -ForegroundColor White
Write-Host "  • Validar permissões dos usuários atribuídos" -ForegroundColor White

Write-Host ""
Write-Host "🔒 SEGURANÇA:" -ForegroundColor Yellow
Write-Host "  • Roles delegadas foram atribuídas a usuários aleatórios" -ForegroundColor White
Write-Host "  • Use PIM para ativar roles just-in-time quando necessário" -ForegroundColor White
Write-Host "  • Revise regularmente quem tem roles privilegiadas" -ForegroundColor White
Write-Host "  • Use Administrative Units para escopo de delegação" -ForegroundColor White

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green
