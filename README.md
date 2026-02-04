# 🔐 SysAdmin Portfolio - Microsoft 365 & Azure AD Automation Suite

Por Luís Otoni — Cloud Admin @ Grupo UOL

Um conjunto completo e profissional de scripts PowerShell para automação de Microsoft 365 e Azure Active Directory, desenvolvido com foco em **segurança**, **confiabilidade** e **experiência do usuário**.

## 📊 Sobre Este Projeto

Este portfólio demonstra expertise em:
- ✅ **Automação em larga escala** de identidades e acesso
- ✅ **Governança e Compliance** com Azure AD/Entra ID
- ✅ **Security by Design** com confirmações de tenant e validações
- ✅ **Código production-ready** com tratamento robusto de erros
- ✅ **UX amigável** com feedback visual e progresso em tempo real

---

## 🚀 Scripts Inclusos

### 1️⃣ **Extension Attribute Generator** (`extensionattributeGenerator.ps1`)
Preenche extension attributes customizados em **todos os usuários do tenant** de forma automática.

**Funcionalidades:**
- 🔍 Busca automática de usuários do tenant
- 📝 Preenche 15 extension attributes com valores dinâmicos
- ⚠️ Validação de tenant antes de executar
- ✅ Confirmação explícita antes de processar
- 📊 Relatório detalhado de sucesso/erro
- ⏱️ Rate limiting automático (300ms entre requisições)

**Uso:**
```powershell
. './extensionattributeGenerator.ps1'
```

---

### 2️⃣ **Guest Invitation Generator** (`guestInvitationGenerator.ps1`)
Convida usuários externos (guests) em massa com rastreamento completo.

**Funcionalidades:**
- 📧 Validação de formato de email
- 👥 Suporte a múltiplos convidados simultâneos
- 📬 Envio automático de emails de convite
- 🛡️ Tratamento robusto de erros
- 📈 Estatísticas finais (sucessos/falhas)

**Recursos técnicos:**
- Try-catch com mensagens descritivas
- Seleção dinâmica de convidados
- Rate limiting entre requisições

---

### 3️⃣ **User Disabler** (`userDesabiltator.ps1`)
Desabilita **5 usuários aleatórios** mantendo todos os seus atributos intactos.

**Funcionalidades:**
- 🎲 Seleção aleatória de usuários ativos
- 🔒 Desabilitação sem perder dados (accountEnabled = false)
- 📋 Visualização prévia dos usuários antes de desabilitar
- ✅ Confirmação dupla de segurança
- 📊 Relatório com nomes e status

**Use case:** Testes de audit trails, compliance testing, simulações de desativação.

---

### 4️⃣ **Groups Generator** (`groupsGenerator.ps1`)
Cria uma estrutura completa de **47 grupos diferentes** com membros e hierarquia.

**Criações:**
- 🔐 **30 Grupos de Segurança** (nomes gerados aleatoriamente)
- 📧 **10 Grupos Microsoft 365** (com visibility Private)
- 🎯 **5 Grupos Dinâmicos** (com regras de membership automático)
- 👑 **2 Grupos Role-Assignable** (para atribuição de roles)
- 🔗 **1 Hierarquia de 3 grupos aninhados** (PAI > FILHO > NETO)
- 👥 **Membros aleatórios** adicionados automaticamente

**Recursos avançados:**
- Geradores de nomes aleatórios
- Nomes dinâmicos para cada grupo
- Atribuição inteligente de membros
- Suporte a múltiplos tipos de grupo

---

### 5️⃣ **Applications Generator** (`applicationsGenerator.ps1`)
Cria **10 App Registrations** com configuração completa de segurança.

**Criações:**
- 📱 **10 App Registrations** (nomes únicos e aleatórios)
- ⚙️ **1 App completamente configurado:**
  - 2 Redirect URIs (Web + SPA)
  - 2 Client Secrets (válidos por 6 e 12 meses)
  - 2 Owners aleatórios do tenant
- 🏢 **2 Enterprise Applications** com SSO
  - Múltiplos usuários e grupos atribuídos
  - Pronto para SAML SSO

**Funcionalidades:**
- Geração de nomes realistas
- Secrets com expiração configurada
- Atribuição dinâmica de owners
- Suporte a Service Principals

---

### 6️⃣ **Conditional Access Generator** (`conditionalAccessGenerator.ps1`)
Cria uma suite completa de **políticas de Conditional Access** para segurança.

**Criações:**
- 📍 **2 Named Locations** (IP-based + Country-based)
  - Brazil, Portugal, Angola
  - Office IPs confiáveis (200.200.200.0/24, etc)
- 🔐 **5 Política de Conditional Access:**
  - CA Teste 01: Require MFA (Report-Only)
  - CA Teste 02: Require MFA for Sensitive Apps (Disabled)
  - CA Teste 03: Block Legacy Authentication (Report-Only)
  - CA Teste 04: Require Compliant Device for Admins (Report-Only)
  - CA Teste 05: Require MFA for High Risk (Report-Only)

**Características:**
- Modo Report-Only para testes seguros
- Modo Disabled para políticas complexas
- Validação de permissões (Global Admin required)
- Controles granulares (MFA, Device Compliance, etc)

---

### 7️⃣ **Roles & PIM Generator** (`rolesAndPimGenerator.ps1`)
Gerencia **roles privilegiadas, Administrative Units e Privileged Identity Management (PIM)** para governança de identidades.

**Criações:**
- 👤 **3 Atribuições de Roles Built-in:**
  - Global Administrator (para usuário aleatório)
  - User Administrator (para usuário aleatório)
  - Application Administrator (para usuário aleatório)
- 🏢 **2 Administrative Units:**
  - AU-Marketing (com 10 membros aleatórios)
  - AU-Sales (com 10 membros aleatórios)
- 📚 **Guia Interativo para:**
  - Custom Roles (Limited User Administrator com 5 permissões)
  - PIM Eligible Assignments (com validação de licença P2)
  - Scoped Role Assignments (per AU)

**Funcionalidades avançadas:**
- ✅ Ativação automática de roles (se necessário)
- ✅ Seleção aleatória de usuários para roles
- ✅ Validação de disponibilidade de PIM (P2 check)
- ✅ Guias passo-a-passo para configurações via Portal
- ✅ Mensagens de segurança alertando sobre permissões críticas
- 📊 Relatório detalhado de assignments realizados

**Características de Segurança:**
- ⚠️ Confirmação dupla para atribuições privilegiadas
- ⚠️ Alerta sobre requisitos de Global Admin
- ⚠️ Orientação sobre uso de PIM just-in-time
- ⚠️ Recomendações de audit regular

---

### 8️⃣ **Authentication Configuration Generator** (`authenticationConfigGenerator.ps1`)
Configura **políticas de autenticação, SSPR e proteção de senha** para segurança máxima de acesso.

**Configurações:**
- 🔐 **Authentication Methods Policy (3 habilitados):**
  - FIDO2 Security Key (grupos aleatórios)
  - Microsoft Authenticator (grupos aleatórios)
  - SMS (grupos aleatórios)
  - Voice Calls desabilitado
- 🔑 **Self-Service Password Reset (SSPR):**
  - Habilitado para grupo específico
  - 2 métodos requeridos (Email, Mobile, Security Questions)
  - 5 Security Questions pré-configuradas
- ⛔ **Password Protection:**
  - Lockout: 5 tentativas, 600 segundos (10 minutos)
  - 10 senhas banidas personalizadas

**Métodos de Autenticação:**
- Email
- Mobile phone
- Security questions

**Security Questions Incluídas:**
- What is your mother's maiden name?
- In what city were you born?
- What was the name of your first pet?
- What is your favorite food?
- What is your favorite book?

**Senhas Bloqueadas:**
- grupouol, uol2024, senha123, password, admin123, tecnologia, brasil2024, welcome, default, master

**Características:**
- ✅ Confirmação dupla antes de configurar
- ✅ Grupos aleatórios selecionados automaticamente
- ✅ Guias passo-a-passo integrados para Portal
- ✅ Recomendações de teste piloto
- 📊 Relatório completo de configurações

---

### 9️⃣ **Inventory Report Generator** (`inventoryReportGenerator.ps1`)
Gera **relatório Excel completo com inventário de todos os recursos** criados pelos scripts anteriores.

**Relatório Contém (8 Abas):**
- 📊 **Summary** - Resumo executivo com contadores
  - Total de usuários, grupos, apps, políticas, etc
  - Data e hora do relatório
- 👥 **Usuários**
  - Nome, UPN, Licença, Departamento, Habilitado, Tipo
- 👥 **Grupos**
  - Nome, Tipo (Security/M365/Dynamic), Membros, Owners, Dinâmico
- 📱 **Aplicações**
  - Nome, AppId, Redirect URIs, Owners  
- 🔐 **Políticas CA**
  - Nome, Estado, Condições, Controles
- 👑 **Roles**
  - Role, Usuário, Tipo, Scope
- 📍 **Named Locations**
  - Nome, Tipo (IP-based/Country-based)
- 🏢 **Administrative Units**
  - Nome, Membros, Descrição

**Funcionalidades:**
- ✅ Coleta dados de múltiplas entidades
- ✅ Cria arquivo Excel formatado profissionalmente
- ✅ Salva com data (Baseline_YYYYMMDD.xlsx)
- ✅ Múltiplas abas para diferentes recursos
- ✅ Auto-sizing de colunas
- ✅ Resumo executivo integrado

**Características Técnicas:**
- Usa módulo ImportExcel para excelente formatação
- Instalação automática de dependências
- Tratamento de erros para dados indisponíveis
- Relatório baseline para auditorias futuras

---

## 🎯 Recursos Técnicos Comuns

Todos os scripts foram desenvolvidos com os mesmos padrões de qualidade:

### Segurança
- ✅ Validação automática de tenant
- ✅ Confirmação dupla antes de operações críticas
- ✅ Escopos Microsoft Graph específicos e seguros
- ✅ Rate limiting automático para evitar throttling

### Confiabilidade
- ✅ Try-catch com tratamento granular de erros
- ✅ Validação de dados de entrada
- ✅ Retry automático em caso de falha (onde aplicável)
- ✅ Mensagens de erro descritivas

### Experiência do Usuário
- ✅ Feedback visual colorido e emojis para legibilidade
- ✅ Progresso em tempo real (X/Total)
- ✅ Separadores visuais e estrutura clara
- ✅ Resumo final detalhado com estatísticas
- ✅ Instruções para próximos passos

### Flexibilidade
- ✅ Seleção aleatória de usuários/grupos quando apropriado
- ✅ Nomes gerados dinamicamente para realismo
- ✅ Suporte a múltiplos tipos de recurso
- ✅ Fácil customização

---

## 📋 Requisitos

### Módulos PowerShell
```powershell
# Instalar Microsoft Graph PowerShell
Install-Module Microsoft.Graph -Scope CurrentUser
```

### Permissões Azure AD
Dependendo do script, você precisa de uma das seguintes roles:
- **Global Administrator** (recomendado para CA)
- **User Administrator** (para user management)
- **Application Administrator** (para app registration)
- **Groups Administrator** (para group management)

### Escopos Microsoft Graph
Cada script usa escopos específicos:
- `User.ReadWrite.All` - Manejo de usuários
- `Group.ReadWrite.All` - Manejo de grupos
- `Application.ReadWrite.All` - Manejo de apps
- `Directory.ReadWrite.All` - Operações do diretório
- `Policy.ReadWrite.ConditionalAccess` - Políticas de CA
- `RoleManagement.ReadWrite.Directory` - Manejo de roles
- `PrivilegedAccess.ReadWrite.AzureAD` - PIM e elevação de privilégios
- `PolicyConfiguration.ReadWrite.AuthenticationMethod` - Auth methods
- `AuthenticationMethod.ReadWrite.All` - Configuração de autenticação

---

## 🚀 Como Usar

### Execução Básica
```powershell
# Abrir PowerShell como Administrator
# Navegar até o diretório do script

# Executar qualquer script
. './nomeDoScript.ps1'

# Seguir as confirmações interativas
```

### Exemplo Completo

```powershell
# 1. Extension Attributes
. './extensionattributeGenerator.ps1'
# Preenche 100 usuários com extension attributes

# 2. Criar Grupos
. './groupsGenerator.ps1'
# Cria 47 grupos com membros e hierarquia

# 3. Desabilitar Usuários
. './userDesabiltator.ps1'
# Desabilita 5 usuários aleatoriamente

# 4. Criar Apps
. './applicationsGenerator.ps1'
# Cria 10 apps com configuração completa

# 5. Configurar Roles e PIM
. './rolesAndPimGenerator.ps1'
# Atribui 3 roles, cria 2 AUs, guia para PIM

# 6. Configurar Autenticação
. './authenticationConfigGenerator.ps1'
# Configura Authentication Methods, SSPR, Password Protection

# 7. Gerar Relatório
. './inventoryReportGenerator.ps1'
# Gera arquivo Excel com inventário completo (Baseline_YYYYMMDD.xlsx)
```

---

## 📊 Saída de Exemplo

Todos os scripts fornecem saída estruturada e amigável:

```
════════════════════════════════════════════════════════════
🔐 Conectando ao Microsoft Graph...

ℹ️  Informações do Tenant Conectado:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Nome do Tenant: Contoso
ID do Tenant: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ 101 usuários encontrados
✅ 59 grupos encontrados

📋 PLANO DE CRIAÇÃO:
  • 30 Grupos de Segurança
  • 10 Grupos Microsoft 365
  • 5 Grupos Dinâmicos
  ...

✅ [1/30] Grupo criado: Azure Architects
✅ [2/30] Grupo criado: Digital Specialists
...

════════════════════════════════════════════════════════════
✨ RESUMO FINAL: 47 grupos criados com sucesso!
════════════════════════════════════════════════════════════
```

---

## 🛠️ Customização

Todos os scripts são facilmente customizáveis:

### Adionar/Remover Grupos
Edite os arrays no início de cada script:
```powershell
$departments = @("TI", "RH", "Financeiro", "Marketing", "Seu Depto")
```

### Alterar Nomes
Modifique as funções `Get-RandomName()`:
```powershell
$policyAdjectives = @("Seu", "Adjective", "Aqui")
```

### Ajustar Rates
Modifique o intervalo de espera:
```powershell
Start-Sleep -Milliseconds 300  # Aumentar/diminuir conforme necessário
```

---

## 📈 Performance

Performance esperada:

| Script | Recursos | Tempo Estimado |
|--------|----------|-----------------|
| Extension Attribute | 100 usuários | 5-10 min |
| Guest Invitation | 5 convidados | 2-5 min |
| User Disabler | 5 usuários | 1-2 min |
| Groups Generator | 47 grupos | 10-15 min |
| Applications Generator | 10 apps + 2 services | 5-10 min |
| CA Generator | 5 políticas + 2 locations | 3-5 min |
| Roles & PIM Generator | 3 roles + 2 AUs | 3-5 min |
| Authentication Config | 3 auth methods + SSPR | 3-5 min |
| Inventory Report | 8 abas Excel | 2-3 min |

---

## ⚠️ Responsabilidades & Segurança

- ✅ **Use em ambiente de teste primeiro**
- ✅ **Faça backup antes de usar em produção**
- ✅ **Revise os scripts antes de executar**
- ✅ **Monitore os resultados no Azure Portal**
- ✅ **Use em conta com permissões limitadas se possível**

---

## 📝 Histórico & Melhorias

Este portfólio demonstra:
- ✨ Progressão de simples (criar usuários) para complexo (CA policies)
- ✨ Aprendizado com tratamento de erros e validações
- ✨ Foco em user experience e feedback
- ✨ Escalabilidade e flexibilidade

---

## 🎓 O que Demonstra

Como SysAdmin/Cloud Administrator, este portfólio mostra que você pode:

1. **Automatizar tarefas repetitivas** - Ganhar horas/dias em processos manuais
2. **Trabalhar com APIs modernas** - Microsoft Graph com segurança
3. **Escrever código robusto** - Tratamento de erros, validações
4. **Pensar em segurança first** - Confirmações, escopos mínimos, validações
5. **Criar experiência profissional** - UX feedback, relatórios, e documentação
6. **Escalar operações** - De 1 para 100+ recursos sem aumentar complexidade
7. **Gerenciar governança de identidades** - Roles, PIM, Administrative Units com segurança
8. **Implementar políticas de segurança** - MFA, SSPR, Password Protection em escala
9. **Gerar relatórios executivos** - Excel/Baseline para auditorias e compliance

---

## 📞 Suporte & Contato

Para dúvidas ou melhorias nos scripts, consulte:
- Microsoft Graph Documentation: https://learn.microsoft.com/graph
- Azure AD Best Practices: https://learn.microsoft.com/azure/active-directory
- PowerShell Module Docs: https://learn.microsoft.com/powershell/module/microsoft.graph

---

## 📄 Licença

Este portfólio é fornecido como demonstração de expertise técnica.

---

**⭐ Desenvolvido com ❤️ para demonstrar expertise em Microsoft 365 & Entra ID Administration**
