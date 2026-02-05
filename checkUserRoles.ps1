# ============================================================
# CHECK USER ROLES - Verificar roles do usuário conectado
# ============================================================

Write-Host ""
Write-Host "🔐 Conectando ao Microsoft Graph..." -ForegroundColor Cyan

Connect-MgGraph -Scopes "RoleManagement.Read.Directory", "User.Read.All", "Directory.Read.All" | Out-Null

Write-Host "✅ Conectado!" -ForegroundColor Green
Write-Host ""

# Obter o usuário conectado
Write-Host "📋 Obtendo informações do usuário conectado..." -ForegroundColor Cyan

$context = Get-MgContext
$currentUser = Get-MgUser -UserId $context.Account

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "👤 USUÁRIO CONECTADO" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "Nome: $($currentUser.DisplayName)" -ForegroundColor White
Write-Host "Email: $($currentUser.Mail)" -ForegroundColor White
Write-Host "UPN: $($currentUser.UserPrincipalName)" -ForegroundColor White
Write-Host "ID: $($currentUser.Id)" -ForegroundColor White
Write-Host ""

# Obter roles do usuário
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🎯 ROLES ATRIBUÍDAS" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

try {
    # Obter todas as directory roles
    $allRoles = Get-MgDirectoryRole -All
    
    $userRoles = @()
    
    foreach ($role in $allRoles) {
        # Verificar se o usuário está nesta role
        $members = Get-MgDirectoryRoleMember -DirectoryRoleId $role.Id
        
        if ($members | Where-Object { $_.Id -eq $currentUser.Id }) {
            $userRoles += $role.DisplayName
            Write-Host "✅ $($role.DisplayName)" -ForegroundColor Green
        }
    }
    
    if ($userRoles.Count -eq 0) {
        Write-Host "⚠️  Nenhuma role atribuída" -ForegroundColor Yellow
    } else {
        Write-Host ""
        Write-Host "📊 Total de roles: $($userRoles.Count)" -ForegroundColor Cyan
    }
    
} catch {
    Write-Host "❌ Erro ao obter roles: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""

# Verificar se é Global Administrator
if ($userRoles -contains "Global Administrator") {
    Write-Host "✅ Confirmado: Você É Global Administrator!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Todas as operações deveriam funcionar sem problemas." -ForegroundColor White
} else {
    Write-Host "⚠️  Aviso: Você NÃO é Global Administrator" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Roles atuais: $($userRoles -join ', ')" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Para usar todos os scripts, você precisa de Global Administrator." -ForegroundColor Yellow
}

Write-Host ""
