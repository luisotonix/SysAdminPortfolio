# ============================================================
# INVENTORY REPORT GENERATOR - FASE 7
# Gera relatório Excel com inventário de todos os recursos criados
# ============================================================

Write-Host ""
Write-Host "📊 Conectando ao Microsoft Graph..." -ForegroundColor Cyan
Write-Host "⚠️  Este script requer módulo ImportExcel" -ForegroundColor Yellow
Write-Host ""

# Verificar se ImportExcel está instalado
$importExcelModule = Get-Module -Name ImportExcel -ErrorAction SilentlyContinue
if (-not $importExcelModule) {
    Write-Host "⏳ Instalando módulo ImportExcel..." -ForegroundColor Yellow
    Install-Module -Name ImportExcel -Scope CurrentUser -Force -ErrorAction SilentlyContinue | Out-Null
    Import-Module ImportExcel
}

Connect-MgGraph -Scopes "User.Read.All", "Group.Read.All", "Application.Read.All", "Directory.Read.All", "Policy.Read.All" | Out-Null

Write-Host "✅ Conectado!" -ForegroundColor Green
Write-Host ""

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
Write-Host "ℹ️  Carregando dados para o relatório..." -ForegroundColor Cyan
Write-Host ""

# ============================================================
# CARREGAR DADOS
# ============================================================

Write-Host "📥 Coletando dados..." -ForegroundColor Cyan
Write-Host ""

# Usuários
Write-Host "   👥 Usuários..." -ForegroundColor Gray
$users = @(Get-MgUser -All -PageSize 999 -Property Id,DisplayName,UserPrincipalName,Mail,Department,AccountEnabled,UserType,AssignedLicenses | Select-Object `
    DisplayName, UserPrincipalName, @{N="License";E={if($_.AssignedLicenses.Count -gt 0){"Sim"}else{"Não"}}}, Department, AccountEnabled, UserType)

# Grupos
Write-Host "   👥 Grupos..." -ForegroundColor Gray
$groups = @(Get-MgGroup -All -PageSize 999 -Property Id,DisplayName,GroupTypes,MailEnabled,SecurityEnabled | Select-Object `
    DisplayName, `
    @{N="Type";E={if($_.GroupTypes -contains "DynamicMembership"){"Dynamic"}elseif($_.MailEnabled){"M365"}else{"Security"}}}, `
    @{N="Members";E={(Get-MgGroupMember -GroupId $_.Id | Measure-Object).Count}}, `
    @{N="Owners";E={(Get-MgGroupOwner -GroupId $_.Id | Measure-Object).Count}}, `
    @{N="Dynamic";E={if($_.GroupTypes -contains "DynamicMembership"){"Sim"}else{"Não"}}})

# Aplicações
Write-Host "   📱 Aplicações..." -ForegroundColor Gray
$apps = @(Get-MgApplication -All -PageSize 999 -Property Id,DisplayName,SignInAudience,Web | Select-Object `
    DisplayName, `
    Id, `
    @{N="RedirectUris";E={($_.Web.RedirectUris -join ", ") | if([string]::IsNullOrEmpty($_)){"Nenhuma"}else{$_}}}, `
    @{N="Owners";E={(Get-MgApplicationOwner -ApplicationId $_.Id | Measure-Object).Count}})

# Políticas de Conditional Access
Write-Host "   🔐 Políticas de CA..." -ForegroundColor Gray
try {
    $caPolicies = @(Get-MgBetaIdentityConditionalAccessPolicy -All | Select-Object `
        DisplayName, State, `
        @{N="Conditions";E={if($_.Conditions.Users -or $_.Conditions.Applications){"Configurado"}else{"Vazio"}}}, `
        @{N="Controls";E={if($_.GrantControls.BuiltInControls){"MFA"}else{"Outras"}}})
} catch {
    Write-Host "      ⚠️  Não foi possível acessar políticas de CA" -ForegroundColor Yellow
    $caPolicies = @()
}

# Roles
Write-Host "   👑 Roles..." -ForegroundColor Gray
$rolesData = @()
try {
    $directoryRoles = Get-MgDirectoryRole -All
    foreach ($role in $directoryRoles) {
        $roleMembers = Get-MgDirectoryRoleMember -DirectoryRoleId $role.Id
        foreach ($member in $roleMembers) {
            $user = Get-MgUser -UserId $member.Id -ErrorAction SilentlyContinue
            if ($user) {
                $rolesData += @{
                    Role = $role.DisplayName
                    User = $user.DisplayName
                    Type = "Permanent"
                    Scope = "Tenant-wide"
                }
            }
        }
    }
} catch {
    Write-Host "      ⚠️  Não foi possível acessar roles" -ForegroundColor Yellow
}

# Named Locations
Write-Host "   📍 Named Locations..." -ForegroundColor Gray
try {
    $namedLocations = @(Get-MgBetaIdentityConditionalAccessNamedLocation -All | Select-Object `
        DisplayName, `
        @{N="Type";E={if($_.OdataType -like "*ipNamedLocation*"){"IP-based"}elseif($_.OdataType -like "*countryNamedLocation*"){"Country-based"}else{"Unknown"}}})
} catch {
    $namedLocations = @()
}

# Administrative Units
Write-Host "   🏢 Administrative Units..." -ForegroundColor Gray
try {
    $administrativeUnits = @(Get-MgDirectoryAdministrativeUnit -All | Select-Object `
        DisplayName, `
        @{N="Members";E={(Get-MgDirectoryAdministrativeUnitMember -AdministrativeUnitId $_.Id | Measure-Object).Count}}, `
        Description)
} catch {
    $administrativeUnits = @()
}

Write-Host ""
Write-Host "✅ Dados coletados com sucesso!" -ForegroundColor Green
Write-Host ""

# ============================================================
# CRIAR ARQUIVO EXCEL
# ============================================================

$timestamp = Get-Date -Format "yyyyMMdd"
$reportPath = "$($env:PWD)/Baseline_$timestamp.xlsx"

Write-Host "📝 Criando arquivo Excel..." -ForegroundColor Cyan
Write-Host "   Arquivo: Baseline_$timestamp.xlsx" -ForegroundColor Gray
Write-Host ""

try {
    # Preparar estilos
    $titleStyle = New-ExcelStyle -FontColor ([System.Drawing.Color]::White) -BackgroundColor ([System.Drawing.Color]::FromArgb(0, 102, 204)) -Bold
    $headerStyle = New-ExcelStyle -BackgroundColor ([System.Drawing.Color]::FromArgb(217, 217, 217)) -Bold

    # Criar workbook com múltiplas abas
    $excel = $null

    # ABA 1: SUMMARY (Resumo)
    Write-Host "   📊 Aba: Summary..." -ForegroundColor Gray
    $summaryData = @(
        [PSCustomObject]@{Entidade = "Total de Usuários"; Quantidade = $users.Count}
        [PSCustomObject]@{Entidade = "Total de Grupos"; Quantidade = $groups.Count}
        [PSCustomObject]@{Entidade = "Total de Aplicações"; Quantidade = $apps.Count}
        [PSCustomObject]@{Entidade = "Total de Políticas CA"; Quantidade = $caPolicies.Count}
        [PSCustomObject]@{Entidade = "Total de Named Locations"; Quantidade = $namedLocations.Count}
        [PSCustomObject]@{Entidade = "Total de Administrative Units"; Quantidade = $administrativeUnits.Count}
        [PSCustomObject]@{Entidade = "Total de Roles Atribuídas"; Quantidade = $rolesData.Count}
        [PSCustomObject]@{Entidade = "Data do Relatório"; Quantidade = (Get-Date -Format "dd/MM/yyyy HH:mm:ss")}
    )
    $excel = $summaryData | Export-Excel -Path $reportPath -WorksheetName "Summary" -AutoSize
    
    # ABA 2: USUÁRIOS
    Write-Host "   👥 Aba: Usuários..." -ForegroundColor Gray
    $usersFormatted = $users | Select-Object `
        @{N="Nome";E={$_.DisplayName}}, `
        @{N="UPN";E={$_.UserPrincipalName}}, `
        @{N="Licença";E={$_.License}}, `
        @{N="Departamento";E={$_.Department}}, `
        @{N="Habilitado";E={if($_.AccountEnabled){"Sim"}else{"Não"}}}, `
        @{N="Tipo";E={$_.UserType}}
    
    if ($usersFormatted.Count -gt 0) {
        $usersFormatted | Export-Excel -Path $reportPath -WorksheetName "Usuários" -AutoSize -Append
    }

    # ABA 3: GRUPOS
    Write-Host "   👥 Aba: Grupos..." -ForegroundColor Gray
    $groupsFormatted = $groups | Select-Object `
        @{N="Nome";E={$_.DisplayName}}, `
        @{N="Tipo";E={$_.Type}}, `
        @{N="Membros";E={$_.Members}}, `
        @{N="Owners";E={$_.Owners}}, `
        @{N="Dinâmico";E={$_.Dynamic}}
    
    if ($groupsFormatted.Count -gt 0) {
        $groupsFormatted | Export-Excel -Path $reportPath -WorksheetName "Grupos" -AutoSize -Append
    }

    # ABA 4: APLICAÇÕES
    Write-Host "   📱 Aba: Aplicações..." -ForegroundColor Gray
    $appsFormatted = $apps | Select-Object `
        @{N="Nome";E={$_.DisplayName}}, `
        @{N="AppId";E={$_.Id}}, `
        @{N="Redirect URIs";E={$_.RedirectUris}}, `
        @{N="Owners";E={$_.Owners}}
    
    if ($appsFormatted.Count -gt 0) {
        $appsFormatted | Export-Excel -Path $reportPath -WorksheetName "Aplicações" -AutoSize -Append
    }

    # ABA 5: POLÍTICAS CA
    Write-Host "   🔐 Aba: Políticas CA..." -ForegroundColor Gray
    $caPoliciesFormatted = $caPolicies | Select-Object `
        @{N="Nome";E={$_.DisplayName}}, `
        @{N="Estado";E={$_.State}}, `
        @{N="Condições";E={$_.Conditions}}, `
        @{N="Controles";E={$_.Controls}}
    
    if ($caPoliciesFormatted.Count -gt 0) {
        $caPoliciesFormatted | Export-Excel -Path $reportPath -WorksheetName "Políticas CA" -AutoSize -Append
    }

    # ABA 6: ROLES
    Write-Host "   👑 Aba: Roles..." -ForegroundColor Gray
    $rolesFormatted = $rolesData | Select-Object `
        @{N="Role";E={$_.Role}}, `
        @{N="Usuário";E={$_.User}}, `
        @{N="Tipo";E={$_.Type}}, `
        @{N="Scope";E={$_.Scope}}
    
    if ($rolesFormatted.Count -gt 0) {
        $rolesFormatted | Export-Excel -Path $reportPath -WorksheetName "Roles" -AutoSize -Append
    }

    # ABA 7: NAMED LOCATIONS
    Write-Host "   📍 Aba: Named Locations..." -ForegroundColor Gray
    if ($namedLocations.Count -gt 0) {
        $namedLocations | Export-Excel -Path $reportPath -WorksheetName "Named Locations" -AutoSize -Append
    }

    # ABA 8: ADMINISTRATIVE UNITS
    Write-Host "   🏢 Aba: Administrative Units..." -ForegroundColor Gray
    if ($administrativeUnits.Count -gt 0) {
        $administrativeUnits | Export-Excel -Path $reportPath -WorksheetName "Admin Units" -AutoSize -Append
    }

    Write-Host ""
    Write-Host "✅ Arquivo Excel criado com sucesso!" -ForegroundColor Green
    Write-Host ""

} catch {
    Write-Host "❌ Erro ao criar arquivo Excel: $_" -ForegroundColor Red
    exit
}

# ============================================================
# RESUMO FINAL
# ============================================================
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "✨ RELATÓRIO CONCLUÍDO COM SUCESSO!" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green

Write-Host ""
Write-Host "📊 INVENTÁRIO CRIADO:" -ForegroundColor Cyan
Write-Host "  ✅ Summary - Resumo executivo" -ForegroundColor Green
Write-Host "  ✅ Usuários - $($users.Count) usuários documentados" -ForegroundColor Green
Write-Host "  ✅ Grupos - $($groups.Count) grupos documentados" -ForegroundColor Green
Write-Host "  ✅ Aplicações - $($apps.Count) aplicações documentadas" -ForegroundColor Green
Write-Host "  ✅ Políticas CA - $($caPolicies.Count) políticas documentadas" -ForegroundColor Green
Write-Host "  ✅ Roles - $($rolesData.Count) atribuições de roles documentadas" -ForegroundColor Green
Write-Host "  ✅ Named Locations - $($namedLocations.Count) localizações documentadas" -ForegroundColor Green
Write-Host "  ✅ Administrative Units - $($administrativeUnits.Count) AUs documentadas" -ForegroundColor Green

Write-Host ""
Write-Host "📁 ARQUIVO SALVO:" -ForegroundColor Cyan
Write-Host "  Caminho: $reportPath" -ForegroundColor White
Write-Host "  Tamanho: $(("{0:N0}" -f (Get-Item -Path $reportPath).Length / 1024))KB" -ForegroundColor White
Write-Host "  Data: $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")" -ForegroundColor White

Write-Host ""
Write-Host "📋 PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "  1. Abra o arquivo Excel para revisar dados" -ForegroundColor White
Write-Host "  2. Valide se todos os recursos foram capturados" -ForegroundColor White
Write-Host "  3. Guarde este arquivo como baseline para comparações futuras" -ForegroundColor White
Write-Host "  4. Use para auditorias e compliance" -ForegroundColor White

Write-Host ""
Write-Host "🔒 SEGURANÇA:" -ForegroundColor Yellow
Write-Host "  • Este arquivo contém informações sensíveis" -ForegroundColor White
Write-Host "  • Armazene em local seguro com backup" -ForegroundColor White
Write-Host "  • Considere criptografar se compartilhar" -ForegroundColor White
Write-Host "  • Este é seu baseline para detectar mudanças" -ForegroundColor White

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green
