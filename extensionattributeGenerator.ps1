# Conectar
Write-Host "🔐 Conectando ao Microsoft Graph..." -ForegroundColor Cyan
Connect-MgGraph -Scopes "User.ReadWrite.All" | Out-Null

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

# Buscar todos os usuários do tenant
Write-Host "🔍 Buscando todos os usuários do tenant..." -ForegroundColor Cyan
$allUsers = Get-MgUser -All -PageSize 999
$totalUsers = $allUsers.Count
$currentUser = 0

Write-Host "📊 Total de usuários encontrados: $totalUsers" -ForegroundColor Cyan
Write-Host ""

# Pedir confirmação
Write-Host "⚠️  CONFIRMAÇÃO NECESSÁRIA:" -ForegroundColor Yellow
Write-Host "Deseja preencher extension attributes para os $totalUsers usuários?" -ForegroundColor Yellow
Write-Host ""

$confirmation = Read-Host "Digite 'sim' para confirmar ou 'não' para cancelar"

if ($confirmation -ne "sim") {
    Write-Host ""
    Write-Host "❌ Operação cancelada pelo usuário." -ForegroundColor Red
    exit
}

Write-Host ""
Write-Host "✅ Confirmado! Iniciando preenchimento de extension attributes..." -ForegroundColor Green
Write-Host "⏳ Processando..." -ForegroundColor Cyan
Write-Host ""

# Iterar sobre todos os usuários
$allUsers | ForEach-Object {
    $currentUser++
    $upn = $_.UserPrincipalName
    $displayName = $_.DisplayName
    
    $extensionAttributes = @{
        extensionAttribute1 = "ExtAttr1_$upn"
        extensionAttribute2 = "ExtAttr2_$upn"
        extensionAttribute3 = "ExtAttr3_$upn"
        extensionAttribute4 = "ExtAttr4_$upn"
        extensionAttribute5 = "ExtAttr5_$upn"
        extensionAttribute6 = "ExtAttr6_$upn"
        extensionAttribute7 = "ExtAttr7_$upn"
        extensionAttribute8 = "ExtAttr8_$upn"
        extensionAttribute9 = "ExtAttr9_$upn"
        extensionAttribute10 = "ExtAttr10_$upn"
        extensionAttribute11 = "ExtAttr11_$upn"
        extensionAttribute12 = "ExtAttr12_$upn"
        extensionAttribute13 = "ExtAttr13_$upn"
        extensionAttribute14 = "ExtAttr14_$upn"
        extensionAttribute15 = "ExtAttr15_$upn"
    }
    
    try {
        Update-MgUser -UserId $upn -OnPremisesExtensionAttributes $extensionAttributes
        Write-Host "✅ [$currentUser/$totalUsers] Extension attributes preenchidos para $displayName" -ForegroundColor Green
    } catch {
        Write-Host "❌ [$currentUser/$totalUsers] Erro em $displayName ($upn): $_" -ForegroundColor Red
    }
    
    Start-Sleep -Milliseconds 300
}

Write-Host ""
Write-Host "✨ Processo concluído! $currentUser usuários processados." -ForegroundColor Cyan