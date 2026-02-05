# Instalar módulo se ainda não tiver
Install-Module Microsoft.Graph -Scope CurrentUser

# Conectar
Connect-MgGraph -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All"

# Criar 84 usuários de uma vez
1..84 | ForEach-Object {
    $userNumber = $_ + 22  # Começar do 23
    $params = @{
        accountEnabled = $true
        displayName = "Usuario Teste $userNumber"
        mailNickname = "usuario.teste$userNumber"
        userPrincipalName = "usuario.teste$userNumber@lfosoares.onmicrosoft.com"
        passwordProfile = @{
            forceChangePasswordNextSignIn = $false
            password = "Senha@Complexa123!"
        }
        usageLocation = "BR"
    }
    
    try {
        New-MgUser -BodyParameter $params
        Write-Host "Criado: Usuario Teste $userNumber" -ForegroundColor Green
    } catch {
        Write-Host "Erro ao criar Usuario $userNumber`: $_" -ForegroundColor Red
    }
    
    Start-Sleep -Milliseconds 500  # Evitar throttling
}