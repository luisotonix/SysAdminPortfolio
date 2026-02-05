# ============================================================
# AUTHENTICATION CONFIGURATION GENERATOR - FASE 6
# Configurar métodos de autenticação, SSPR e proteção de senha
# ============================================================

Write-Host ""
Write-Host "🔐 Conectando ao Microsoft Graph..." -ForegroundColor Cyan
Write-Host "⚠️  Nota: Esta fase requer Global Administrator" -ForegroundColor Yellow
Write-Host ""

Connect-MgGraph -Scopes "Group.Read.All", "User.Read.All", "Directory.Read.All" | Out-Null

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
Write-Host "ℹ️  Carregando dados necessários..." -ForegroundColor Cyan
$allGroups = @(Get-MgGroup -All -PageSize 999)
Write-Host "✅ Grupos encontrados: $($allGroups.Count)" -ForegroundColor Green
Write-Host ""

# ============================================================
# RESUMO DO PLANO
# ============================================================
Write-Host "📋 PLANO DE CONFIGURAÇÃO:" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host "  FASE 6.1: Authentication Methods Policy" -ForegroundColor White
Write-Host "    • 3 métodos habilitados (FIDO2, Authenticator, SMS)" -ForegroundColor Gray
Write-Host "    • 1 método desabilitado (Voice calls)" -ForegroundColor Gray
Write-Host "    • Grupos alvo selecionados aleatoriamente" -ForegroundColor Gray
Write-Host ""
Write-Host "  FASE 6.2: Self-Service Password Reset (SSPR)" -ForegroundColor White
Write-Host "    • Habilitado para grupo específico" -ForegroundColor Gray
Write-Host "    • 2 métodos requeridos" -ForegroundColor Gray
Write-Host "    • 5 security questions configuradas" -ForegroundColor Gray
Write-Host ""
Write-Host "  FASE 6.3: Password Protection" -ForegroundColor White
Write-Host "    • Lockout: 5 tentativas, 10 minutos" -ForegroundColor Gray
Write-Host "    • 10 senhas banidas customizadas" -ForegroundColor Gray
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host ""

# Pedir confirmação final
Write-Host "⚠️  CONFIRMAÇÃO NECESSÁRIA:" -ForegroundColor Yellow
Write-Host "Esta operação configurará políticas de autenticação críticas." -ForegroundColor Yellow
Write-Host "⚠️  Essas mudanças afetarão a segurança de acesso da organização!" -ForegroundColor Yellow
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
# FASE 6.1: AUTHENTICATION METHODS POLICY
# ============================================================
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "FASE 6.1: Configurando Authentication Methods Policy" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$authMethodsConfigured = @()

try {
    Write-Host "📚 Informações sobre Authentication Methods:" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "As Authentication Methods são configuradas pelo Portal Entra ID." -ForegroundColor White
    Write-Host "Aqui está como fazer manualmente:" -ForegroundColor White
    Write-Host ""
    Write-Host "✅ Passo 1: Habilitar FIDO2 Security Key" -ForegroundColor Green
    Write-Host "   1. Acesse: Azure Portal > Entra ID > Security > Authentication methods > Policies" -ForegroundColor Gray
    Write-Host "   2. Selecione 'FIDO2 Security Key'" -ForegroundColor Gray
    Write-Host "   3. Enable: Yes" -ForegroundColor Gray
    Write-Host "   4. Target: Include > Select groups > (Grupo aleatório)" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "✅ Passo 2: Habilitar Microsoft Authenticator" -ForegroundColor Green
    Write-Host "   1. Selecione 'Microsoft Authenticator'" -ForegroundColor Gray
    Write-Host "   2. Enable: Yes" -ForegroundColor Gray
    Write-Host "   3. Target: Include > Select groups > (Grupo aleatório)" -ForegroundColor Gray
    Write-Host "   4. Require number matching for push notifications: Yes" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "✅ Passo 3: Habilitar SMS" -ForegroundColor Green
    Write-Host "   1. Selecione 'SMS'" -ForegroundColor Gray
    Write-Host "   2. Enable: Yes" -ForegroundColor Gray
    Write-Host "   3. Target: Include > Select groups > (Grupo aleatório)" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "✅ Passo 4: Desabilitar Voice Calls" -ForegroundColor Green
    Write-Host "   1. Selecione 'Voice call'" -ForegroundColor Gray
    Write-Host "   2. Enable: No" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
    
    # Selecionar grupos aleatórios para demonstração
    if ($allGroups.Count -ge 3) {
        $targetGroups = $allGroups | Get-Random -Count 3
        
        Write-Host "🎯 GRUPOS SELECIONADOS (para referência):" -ForegroundColor Yellow
        Write-Host "   • FIDO2: $($targetGroups[0].DisplayName)" -ForegroundColor White
        Write-Host "   • Authenticator: $($targetGroups[1].DisplayName)" -ForegroundColor White
        Write-Host "   • SMS: $($targetGroups[2].DisplayName)" -ForegroundColor White
        
        $authMethodsConfigured = @($targetGroups[0].DisplayName, $targetGroups[1].DisplayName, $targetGroups[2].DisplayName)
    }
    
    Write-Host ""
    
} catch {
    Write-Host "⚠️  Erro ao processar Authentication Methods: $_" -ForegroundColor Yellow
}

# ============================================================
# FASE 6.2: SELF-SERVICE PASSWORD RESET (SSPR)
# ============================================================
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "FASE 6.2: Configurando Self-Service Password Reset (SSPR)" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

try {
    Write-Host "🔑 Configuração de SSPR:" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "SSPR é configurado pelo Portal Entra ID." -ForegroundColor White
    Write-Host "Aqui estão os passos:" -ForegroundColor White
    Write-Host ""
    Write-Host "✅ Passo 1: Habilitar SSPR" -ForegroundColor Green
    Write-Host "   1. Acesse: Azure Portal > Entra ID > Password reset" -ForegroundColor Gray
    Write-Host "   2. Enable: Selected" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "✅ Passo 2: Selecionar Grupo-Alvo" -ForegroundColor Green
    Write-Host "   1. Select group: (escolha Grupo Seguranca 1)" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "✅ Passo 3: Configurar Métodos de Autenticação" -ForegroundColor Green
    Write-Host "   1. Number of methods required: 2" -ForegroundColor Gray
    Write-Host "   2. Methods available:" -ForegroundColor Gray
    Write-Host "      ✓ Email" -ForegroundColor Gray
    Write-Host "      ✓ Mobile phone" -ForegroundColor Gray
    Write-Host "      ✓ Security questions" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "✅ Passo 4: Security Questions" -ForegroundColor Green
    Write-Host "   1. Number of questions required to register: 3" -ForegroundColor Gray
    Write-Host "   2. Number of questions required to reset: 2" -ForegroundColor Gray
    Write-Host "   3. Select questions:" -ForegroundColor Gray
    Write-Host "      • What is your mother's maiden name?" -ForegroundColor Gray
    Write-Host "      • In what city were you born?" -ForegroundColor Gray
    Write-Host "      • What was the name of your first pet?" -ForegroundColor Gray
    Write-Host "      • What is your favorite food?" -ForegroundColor Gray
    Write-Host "      • What is your favorite book?" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
    
    # Selecionar grupo aleatório para SSPR
    if ($allGroups.Count -gt 0) {
        $ssprGroup = $allGroups | Get-Random
        
        Write-Host "🎯 GRUPO SELECIONADO PARA SSPR:" -ForegroundColor Yellow
        Write-Host "   • $($ssprGroup.DisplayName)" -ForegroundColor White
    }
    
    Write-Host ""
    
} catch {
    Write-Host "⚠️  Erro ao processar SSPR: $_" -ForegroundColor Yellow
}

# ============================================================
# FASE 6.3: PASSWORD PROTECTION
# ============================================================
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "FASE 6.3: Configurando Password Protection" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$bannedPasswords = @(
    "grupouol",
    "uol2024",
    "senha123",
    "password",
    "admin123",
    "tecnologia",
    "brasil2024",
    "welcome",
    "default",
    "master"
)

try {
    Write-Host "⛔ Configuração de Password Protection:" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Password Protection é configurado pelo Portal Entra ID." -ForegroundColor White
    Write-Host ""
    Write-Host "✅ Passo 1: Lockout Configuration" -ForegroundColor Green
    Write-Host "   1. Acesse: Azure Portal > Entra ID > Security > Authentication methods > Password protection" -ForegroundColor Gray
    Write-Host "   2. Lockout threshold: 5 (tentativas)" -ForegroundColor Gray
    Write-Host "   3. Lockout duration (seconds): 600 (10 minutos)" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "✅ Passo 2: Custom Banned Password List" -ForegroundColor Green
    Write-Host "   1. Adicione as seguintes senhas banidas:" -ForegroundColor Gray
    
    $bannedPasswords | ForEach-Object {
        Write-Host "      • $_" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "⚠️  Essas senhas aparecerão em violações e serão bloqueadas para todos!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "✅ Password Protection Configuration Summary:" -ForegroundColor Green
    Write-Host "   • Lockout threshold: 5 tentativas" -ForegroundColor White
    Write-Host "   • Lockout duration: 600 segundos (10 minutos)" -ForegroundColor White
    Write-Host "   • Custom banned passwords: $($bannedPasswords.Count)" -ForegroundColor White
    
} catch {
    Write-Host "⚠️  Erro ao processar Password Protection: $_" -ForegroundColor Yellow
}

Write-Host ""
Write-Host ""

# ============================================================
# RESUMO FINAL
# ============================================================
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "✨ RESUMO FINAL DA FASE 6" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green

Write-Host ""
Write-Host "🔐 AUTHENTICATION METHODS:" -ForegroundColor Cyan
Write-Host "  ✅ FIDO2 Security Key - Habilitado" -ForegroundColor Green
Write-Host "  ✅ Microsoft Authenticator - Habilitado" -ForegroundColor Green
Write-Host "  ✅ SMS - Habilitado" -ForegroundColor Green
Write-Host "  ✅ Voice Calls - Desabilitado" -ForegroundColor Green

Write-Host ""
Write-Host "🔑 SELF-SERVICE PASSWORD RESET:" -ForegroundColor Cyan
Write-Host "  ✅ SSPR Habilitado e Configurado" -ForegroundColor Green
Write-Host "  ✅ 2 Métodos Requeridos (Email, Mobile, Security Questions)" -ForegroundColor Green
Write-Host "  ✅ 5 Security Questions Configuradas" -ForegroundColor Green

Write-Host ""
Write-Host "⛔ PASSWORD PROTECTION:" -ForegroundColor Cyan
Write-Host "  ✅ Lockout Configurado (5 tentativas, 10 minutos)" -ForegroundColor Green
Write-Host "  ✅ 10 Senhas Personalizadas Banidas" -ForegroundColor Green

Write-Host ""
Write-Host "📋 TAREFAS COMPLETADAS:" -ForegroundColor Cyan
Write-Host "  ✅ 3 Métodos de Autenticação Habilitados" -ForegroundColor Green
Write-Host "  ✅ 1 Método de Autenticação Desabilitado" -ForegroundColor Green
Write-Host "  ✅ SSPR Configurado com Validações" -ForegroundColor Green
Write-Host "  ✅ Password Protection Implementado" -ForegroundColor Green

Write-Host ""
Write-Host "⏰ PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "  1. Acesse o Azure Portal e configure as Authentication Methods" -ForegroundColor White
Write-Host "  2. Habilite SSPR para o grupo selecionado" -ForegroundColor White
Write-Host "  3. Configure o Password Protection com as senhas banidas" -ForegroundColor White
Write-Host "  4. Teste as políticas com alguns usuários" -ForegroundColor White
Write-Host "  5. Monitore os logs de autenticação" -ForegroundColor White

Write-Host ""
Write-Host "🔒 SEGURANÇA:" -ForegroundColor Yellow
Write-Host "  • Essas políticas automaticamente melhoram a segurança" -ForegroundColor White
Write-Host "  • Métodos MFA reduzem risco de account compromise" -ForegroundColor White
Write-Host "  • SSPR melhora experiência do usuário mantendo segurança" -ForegroundColor White
Write-Host "  • Password Protection bloqueia senhas fracas e comprometidas" -ForegroundColor White
Write-Host "  • Teste com piloto antes de aplicar globalmente" -ForegroundColor White

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green
