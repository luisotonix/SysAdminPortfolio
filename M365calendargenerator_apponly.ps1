<#
.SYNOPSIS
    M365 Calendar Event Generator - App-Only Mode (v2 - Recurrence Fix)
.DESCRIPTION
    Cria eventos de calendário variados (normais, dia inteiro, recorrentes) 
    para usuários M365. Versão corrigida com recorrências válidas conforme
    documentação oficial do Microsoft Graph.
.NOTES
    Autor: Claude (corrigido)
    Requer: Microsoft.Graph PowerShell SDK
#>

Write-Host "`n📅 M365 Calendar Event Generator (App-Only Mode) v2" -ForegroundColor Cyan
Write-Host "🗓️  Criando eventos variados nos calendários...`n" -ForegroundColor Cyan

# ============================================================================
# CONFIGURAÇÃO - CREDENCIAIS
# ============================================================================

function Import-DotEnv {
    param([string]$Path = ".credentials")
    $envFile = Join-Path $PSScriptRoot $Path
    if (Test-Path $envFile) {
        Write-Host "📁 Carregando credenciais de $Path..." -ForegroundColor Gray
        Get-Content $envFile | ForEach-Object {
            if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
                $key = $matches[1].Trim()
                $value = $matches[2].Trim()
                [Environment]::SetEnvironmentVariable($key, $value, "Process")
            }
        }
        return $true
    }
    return $false
}

if (Import-DotEnv) {
    $TenantId = $env:M365_TENANT_ID
    $ClientId = $env:M365_CLIENT_ID
    $ClientSecret = $env:M365_CLIENT_SECRET
    Write-Host "✅ Credenciais carregadas" -ForegroundColor Green
} else {
    Write-Host "⚠️  Arquivo .credentials não encontrado." -ForegroundColor Yellow
    exit
}

# ============================================================================
# CONEXÃO COM MICROSOFT GRAPH
# ============================================================================

Write-Host "🔐 Conectando ao Microsoft Graph (App-Only)..." -ForegroundColor Yellow

try {
    $secureSecret = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($ClientId, $secureSecret)
    
    Connect-MgGraph -TenantId $TenantId -ClientSecretCredential $credential -NoWelcome
    Write-Host "✅ Conectado com sucesso`n" -ForegroundColor Green
    
    $org = Get-MgOrganization
    Write-Host "ℹ️  Tenant: $($org.DisplayName) ($($org.Id))" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Erro ao conectar: $_" -ForegroundColor Red
    exit
}

# Confirmação
$confirm = Read-Host "Deseja continuar? (sim/não)"
if ($confirm -ne "sim") {
    Write-Host "Operação cancelada." -ForegroundColor Yellow
    Disconnect-MgGraph | Out-Null
    exit
}

# ============================================================================
# BUSCAR USUÁRIOS COM MAILBOX
# ============================================================================

Write-Host "`n🔎 Buscando usuários com mailbox ativa..." -ForegroundColor Yellow

$users = Get-MgUser -All -Property Id, DisplayName, UserPrincipalName, Mail, AssignedLicenses | 
    Where-Object { $_.AssignedLicenses.Count -gt 0 -and $_.Mail }

if ($users.Count -eq 0) {
    Write-Host "❌ Nenhum usuário licenciado encontrado." -ForegroundColor Red
    Disconnect-MgGraph | Out-Null
    exit
}

Write-Host "✅ Encontrados $($users.Count) usuários com mailbox ativa.`n" -ForegroundColor Green

# ============================================================================
# DEFINIÇÃO DE EVENTOS
# ============================================================================

# Eventos normais (com hora específica)
$eventosNormais = @(
    @{ Subject = "Daily Standup"; DurationMinutes = 30; Category = "Trabalho" }
    @{ Subject = "1:1 com Gestor"; DurationMinutes = 60; Category = "Trabalho" }
    @{ Subject = "Sprint Planning"; DurationMinutes = 120; Category = "Trabalho" }
    @{ Subject = "Sprint Review"; DurationMinutes = 90; Category = "Trabalho" }
    @{ Subject = "Retrospectiva"; DurationMinutes = 60; Category = "Trabalho" }
    @{ Subject = "Tech Talk"; DurationMinutes = 60; Category = "Aprendizado" }
    @{ Subject = "Workshop Azure"; DurationMinutes = 180; Category = "Aprendizado" }
    @{ Subject = "Review de Código"; DurationMinutes = 45; Category = "Trabalho" }
    @{ Subject = "Arquitetura Review"; DurationMinutes = 90; Category = "Trabalho" }
    @{ Subject = "Sync de Projeto"; DurationMinutes = 30; Category = "Trabalho" }
    @{ Subject = "Kickoff - Novo Projeto"; DurationMinutes = 60; Category = "Trabalho" }
    @{ Subject = "Budget Review"; DurationMinutes = 60; Category = "Financeiro" }
    @{ Subject = "OKR Check-in"; DurationMinutes = 45; Category = "Trabalho" }
    @{ Subject = "All Hands"; DurationMinutes = 60; Category = "Empresa" }
    @{ Subject = "Town Hall"; DurationMinutes = 90; Category = "Empresa" }
    @{ Subject = "Apresentação de Resultados Q4"; DurationMinutes = 120; Category = "Empresa" }
    @{ Subject = "Onboarding TI"; DurationMinutes = 240; Category = "RH" }
    @{ Subject = "Treinamento Power Platform"; DurationMinutes = 180; Category = "Aprendizado" }
    @{ Subject = "Certificação Microsoft"; DurationMinutes = 120; Category = "Aprendizado" }
    @{ Subject = "Curso de Liderança"; DurationMinutes = 180; Category = "Aprendizado" }
    @{ Subject = "Happy Hour"; DurationMinutes = 120; Category = "Social" }
    @{ Subject = "Almoço de equipe"; DurationMinutes = 90; Category = "Social" }
    @{ Subject = "Evento Externo"; DurationMinutes = 180; Category = "Networking" }
    @{ Subject = "Planejamento Estratégico 2025"; DurationMinutes = 240; Category = "Estratégia" }
)

# Eventos de dia inteiro
$eventosDiaInteiro = @(
    @{ Subject = "Férias"; Days = 5 }
    @{ Subject = "Trabalho Remoto"; Days = 1 }
    @{ Subject = "Foco - Não Perturbe"; Days = 1 }
    @{ Subject = "Conferência Tech"; Days = 3 }
    @{ Subject = "Viagem a trabalho"; Days = 2 }
    @{ Subject = "Aniversário - João"; Days = 1 }
    @{ Subject = "Médico"; Days = 1 }
    @{ Subject = "Dentista"; Days = 1 }
    @{ Subject = "Academia"; Days = 1 }
)

# ============================================================================
# FUNÇÃO: Gerar Recurrence Pattern VÁLIDO conforme documentação Microsoft
# ============================================================================

function Get-ValidRecurrencePattern {
    param(
        [string]$Type  # daily, weekly, absoluteMonthly, relativeMonthly
    )
    
    $startDate = (Get-Date).AddDays((Get-Random -Minimum 1 -Maximum 14)).ToString("yyyy-MM-dd")
    $endDate = (Get-Date).AddMonths(3).ToString("yyyy-MM-dd")
    
    # Dias da semana válidos
    $weekDays = @("monday", "tuesday", "wednesday", "thursday", "friday")
    $allDays = @("sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday")
    
    switch ($Type) {
        "daily" {
            # DAILY: Apenas type e interval são necessários
            return @{
                pattern = @{
                    type = "daily"
                    interval = Get-Random -Minimum 1 -Maximum 4  # A cada 1-3 dias
                }
                range = @{
                    type = "endDate"
                    startDate = $startDate
                    endDate = $endDate
                }
            }
        }
        
        "weekly" {
            # WEEKLY: type, interval, daysOfWeek, firstDayOfWeek são OBRIGATÓRIOS
            $numDays = Get-Random -Minimum 1 -Maximum 3
            $selectedDays = $weekDays | Get-Random -Count $numDays
            
            return @{
                pattern = @{
                    type = "weekly"
                    interval = Get-Random -Minimum 1 -Maximum 3  # A cada 1-2 semanas
                    daysOfWeek = @($selectedDays)  # OBRIGATÓRIO - array com pelo menos 1 dia
                    firstDayOfWeek = "sunday"      # OBRIGATÓRIO
                }
                range = @{
                    type = "endDate"
                    startDate = $startDate
                    endDate = $endDate
                }
            }
        }
        
        "absoluteMonthly" {
            # ABSOLUTE MONTHLY: type, interval, dayOfMonth são OBRIGATÓRIOS
            return @{
                pattern = @{
                    type = "absoluteMonthly"
                    interval = Get-Random -Minimum 1 -Maximum 3   # A cada 1-2 meses
                    dayOfMonth = Get-Random -Minimum 1 -Maximum 28  # OBRIGATÓRIO - dia 1-28 (seguro)
                }
                range = @{
                    type = "endDate"
                    startDate = $startDate
                    endDate = $endDate
                }
            }
        }
        
        "relativeMonthly" {
            # RELATIVE MONTHLY: type, interval, daysOfWeek são OBRIGATÓRIOS
            $selectedDay = $weekDays | Get-Random -Count 1
            $indexes = @("first", "second", "third", "fourth", "last")
            
            return @{
                pattern = @{
                    type = "relativeMonthly"
                    interval = Get-Random -Minimum 1 -Maximum 3    # A cada 1-2 meses
                    daysOfWeek = @($selectedDay)                    # OBRIGATÓRIO
                    index = $indexes | Get-Random -Count 1          # Opcional mas útil
                }
                range = @{
                    type = "endDate"
                    startDate = $startDate
                    endDate = $endDate
                }
            }
        }
        
        default {
            return $null
        }
    }
}

# ============================================================================
# FUNÇÃO: Criar Evento
# ============================================================================

function New-CalendarEvent {
    param(
        [string]$UserId,
        [string]$Subject,
        [int]$DurationMinutes = 60,
        [bool]$IsAllDay = $false,
        [int]$AllDayDays = 1,
        [bool]$IsRecurring = $false
    )
    
    $baseDate = (Get-Date).AddDays((Get-Random -Minimum 1 -Maximum 60))
    $hour = Get-Random -Minimum 8 -Maximum 17
    $startDateTime = $baseDate.Date.AddHours($hour)
    $endDateTime = $startDateTime.AddMinutes($DurationMinutes)
    
    $eventBody = @{
        subject = $Subject
        body = @{
            contentType = "text"
            content = "Evento criado automaticamente para testes de backup M365."
        }
    }
    
    if ($IsAllDay) {
        # Evento de dia inteiro
        $eventBody.isAllDay = $true
        $eventBody.start = @{
            dateTime = $baseDate.Date.ToString("yyyy-MM-ddT00:00:00")
            timeZone = "E. South America Standard Time"
        }
        $eventBody.end = @{
            dateTime = $baseDate.Date.AddDays($AllDayDays).ToString("yyyy-MM-ddT00:00:00")
            timeZone = "E. South America Standard Time"
        }
    } else {
        # Evento normal com horário
        $eventBody.start = @{
            dateTime = $startDateTime.ToString("yyyy-MM-ddTHH:mm:ss")
            timeZone = "E. South America Standard Time"
        }
        $eventBody.end = @{
            dateTime = $endDateTime.ToString("yyyy-MM-ddTHH:mm:ss")
            timeZone = "E. South America Standard Time"
        }
    }
    
    # Adicionar recorrência se solicitado
    if ($IsRecurring -and -not $IsAllDay) {
        $recurrenceTypes = @("daily", "weekly", "absoluteMonthly", "relativeMonthly")
        $selectedType = $recurrenceTypes | Get-Random
        $recurrence = Get-ValidRecurrencePattern -Type $selectedType
        
        if ($recurrence) {
            $eventBody.recurrence = $recurrence
        }
    }
    
    try {
        $result = New-MgUserEvent -UserId $UserId -BodyParameter $eventBody -ErrorAction Stop
        return @{ Success = $true; Event = $result }
    } catch {
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

# ============================================================================
# PROCESSAR USUÁRIOS
# ============================================================================

Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor DarkGray
Write-Host "📅 Iniciando criação de eventos (10 por usuário)..." -ForegroundColor Cyan
Write-Host "   Tipos: 📆 Normal | 📅 Dia Inteiro | 🔄 Recorrente" -ForegroundColor Gray
Write-Host "════════════════════════════════════════════════════════════`n" -ForegroundColor DarkGray

$totalCreated = 0
$totalErrors = 0
$userCount = 0

foreach ($user in $users) {
    $userCount++
    $userCreated = 0
    $userErrors = 0
    
    Write-Host "▶ [$userCount/$($users.Count)] $($user.UserPrincipalName)" -ForegroundColor White
    
    # Criar 10 eventos por usuário com distribuição variada
    for ($i = 1; $i -le 10; $i++) {
        $eventType = Get-Random -Minimum 1 -Maximum 101
        
        if ($eventType -le 40) {
            # 40% - Evento normal
            $evento = $eventosNormais | Get-Random
            $result = New-CalendarEvent -UserId $user.Id -Subject $evento.Subject -DurationMinutes $evento.DurationMinutes -IsRecurring $false
            $icon = "📆"
        }
        elseif ($eventType -le 70) {
            # 30% - Evento de dia inteiro
            $evento = $eventosDiaInteiro | Get-Random
            $result = New-CalendarEvent -UserId $user.Id -Subject $evento.Subject -IsAllDay $true -AllDayDays $evento.Days -IsRecurring $false
            $icon = "📅"
        }
        else {
            # 30% - Evento recorrente
            $evento = $eventosNormais | Get-Random
            $result = New-CalendarEvent -UserId $user.Id -Subject $evento.Subject -DurationMinutes $evento.DurationMinutes -IsRecurring $true
            $icon = "🔄"
        }
        
        if ($result.Success) {
            Write-Host "  $icon Criado: $($evento.Subject)" -ForegroundColor Green
            $userCreated++
        } else {
            $errorMsg = $result.Error -replace '.*\[(\w+)\].*', '$1'
            Write-Host "  ❌ Erro: $($evento.Subject) - $errorMsg" -ForegroundColor Red
            $userErrors++
        }
        
        Start-Sleep -Milliseconds 300
    }
    
    $totalCreated += $userCreated
    $totalErrors += $userErrors
    
    Write-Host "  ✅ Concluído: $userCreated criados, $userErrors erros`n" -ForegroundColor Cyan
}

# ============================================================================
# RESUMO FINAL
# ============================================================================

Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor DarkGray
Write-Host "✅ Processo finalizado!" -ForegroundColor Green
Write-Host "   • Usuários processados: $userCount" -ForegroundColor White
Write-Host "   • Eventos criados: $totalCreated" -ForegroundColor White
Write-Host "   • Erros: $totalErrors" -ForegroundColor $(if ($totalErrors -eq 0) { "White" } else { "Yellow" })
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor DarkGray

Disconnect-MgGraph | Out-Null