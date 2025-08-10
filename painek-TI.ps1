# Painel Completo de Manutenção e Diagnóstico - PowerShell
# Salvar como: painel_ti.ps1
# Executar como Administrador

# Caminho do relatório na Área de Trabalho
$logPath = [System.IO.Path]::Combine([Environment]::GetFolderPath("Desktop"), "Relatorio_TI.txt")

function Add-Log {
    param ([string]$mensagem)
    $dataHora = (Get-Date).ToString("dd/MM/yyyy HH:mm:ss")
    Add-Content -Path $logPath -Value "$dataHora - $mensagem"
}

# ======= Funções de Manutenção =======
function Rodar-CHKDSK {
    Add-Log "Executando CHKDSK"
    chkdsk C: /F /R
    Add-Log "CHKDSK finalizado (pode exigir reinicialização)"
    Pause
}

function Rodar-SFC {
    Add-Log "Executando SFC /SCANNOW"
    sfc /scannow
    Add-Log "SFC finalizado"
    Pause
}

function Rodar-DISM {
    Add-Log "Executando DISM /RestoreHealth"
    DISM /Online /Cleanup-Image /RestoreHealth
    Add-Log "DISM finalizado"
    Pause
}

function Reiniciar-Rede {
    Add-Log "Reiniciando adaptador de rede"
    netsh int ip reset
    netsh winsock reset
    Add-Log "Adaptador de rede reiniciado"
    Pause
}

function Limpar-Temporarios {
    Add-Log "Limpando arquivos temporários"
    Remove-Item "$env:TEMP\*" -Force -Recurse -ErrorAction SilentlyContinue
    Remove-Item "C:\Windows\Temp\*" -Force -Recurse -ErrorAction SilentlyContinue
    Add-Log "Arquivos temporários removidos"
    Pause
}

function Manutencao-Completa {
    Rodar-CHKDSK
    Rodar-SFC
    Rodar-DISM
    Reiniciar-Rede
    Limpar-Temporarios
    Add-Log "Manutenção completa concluída"
    Pause
}

# ======= Funções de Diagnóstico =======
function Uso-Recursos {
    Add-Log ">>> USO DE RECURSOS"
    $cpu = Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average | Select -ExpandProperty Average
    $ramTotal = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB
    $ramLivre = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB
    $disco = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"

    Add-Log "CPU em uso: $cpu%"
    Add-Log ("RAM Total: {0:N2} GB | RAM Livre: {1:N2} GB" -f $ramTotal, $ramLivre)
    Add-Log ("Espaço em disco C: {0:N2} GB livre de {1:N2} GB" -f ($disco.FreeSpace/1GB), ($disco.Size/1GB))
}

function Top-Processos {
    Add-Log ">>> TOP 10 PROCESSOS POR USO DE CPU"
    Get-Process | Sort CPU -Descending | Select -First 10 Name,CPU,Id |
        ForEach-Object { Add-Log ("{0} - CPU: {1:N2}" -f $_.Name, $_.CPU) }

    Add-Log ">>> TOP 10 PROCESSOS POR USO DE MEMÓRIA"
    Get-Process | Sort WorkingSet -Descending | Select -First 10 Name,@{Name="MemoriaMB";Expression={[math]::Round($_.WorkingSet/1MB,2)}} |
        ForEach-Object { Add-Log ("{0} - Memória: {1} MB" -f $_.Name, $_.MemoriaMB) }
}

function Drivers-Problema {
    Add-Log ">>> DRIVERS COM PROBLEMAS"
    Get-WmiObject Win32_PnPEntity | Where-Object { $_.ConfigManagerErrorCode -ne 0 } |
        ForEach-Object { Add-Log ("Driver com problema: {0}" -f $_.Name) }
}

function Eventos-Criticos {
    Add-Log ">>> EVENTOS CRÍTICOS (últimas 24h)"
    $ontem = (Get-Date).AddDays(-1)
    Get-WinEvent -FilterHashtable @{LogName='System'; Level=1; StartTime=$ontem} -ErrorAction SilentlyContinue |
        ForEach-Object { Add-Log ("[{0}] {1}" -f $_.TimeCreated, $_.Message) }
}

function Apps-Travaram {
    Add-Log ">>> APLICATIVOS QUE TRAVARAM (últimas 24h)"
    $ontem = (Get-Date).AddDays(-1)
    Get-WinEvent -FilterHashtable @{LogName='Application'; Level=2; StartTime=$ontem} -ErrorAction SilentlyContinue |
        ForEach-Object { Add-Log ("[{0}] {1}" -f $_.TimeCreated, $_.Message) }
}

function Status-Disco {
    Add-Log ">>> STATUS DO DISCO"
    Get-WmiObject Win32_DiskDrive | ForEach-Object { Add-Log ("Modelo: {0} | Status: {1}" -f $_.Model, $_.Status) }
}

function Diagnostico-Completo {
    Uso-Recursos
    Top-Processos
    Drivers-Problema
    Eventos-Criticos
    Apps-Travaram
    Status-Disco
    Add-Log "Diagnóstico completo concluído"
    Pause
}

# ======= Menu Principal =======
function Mostrar-Menu {
    Clear-Host
    Write-Host "===== PAINEL DE MANUTENÇÃO E DIAGNÓSTICO =====" -ForegroundColor Cyan
    Write-Host "1 - Menu de Manutenção"
    Write-Host "2 - Menu de Diagnóstico"
    Write-Host "3 - Executar Manutenção Completa"
    Write-Host "4 - Executar Diagnóstico Completo"
    Write-Host "0 - Sair"
    Write-Host "==============================================" -ForegroundColor Cyan
}

# ======= Menus Secundários =======
function Menu-Manutencao {
    do {
        Clear-Host
        Write-Host "===== MENU DE MANUTENÇÃO =====" -ForegroundColor Cyan
        Write-Host "1 - Executar CHKDSK"
        Write-Host "2 - Executar SFC /SCANNOW"
        Write-Host "3 - Executar DISM /RestoreHealth"
        Write-Host "4 - Reiniciar adaptador de rede"
        Write-Host "5 - Limpar arquivos temporários"
        Write-Host "0 - Voltar"
        $opc = Read-Host "Escolha uma opção"
        switch ($opc) {
            1 { Rodar-CHKDSK }
            2 { Rodar-SFC }
            3 { Rodar-DISM }
            4 { Reiniciar-Rede }
            5 { Limpar-Temporarios }
            0 { }
            default { Write-Host "Opção inválida" -ForegroundColor Red; Pause }
        }
    } until ($opc -eq "0")
}

function Menu-Diagnostico {
    do {
        Clear-Host
        Write-Host "===== MENU DE DIAGNÓSTICO =====" -ForegroundColor Cyan
        Write-Host "1 - Uso de CPU, RAM e Disco"
        Write-Host "2 - Top 10 processos"
        Write-Host "3 - Drivers com problemas"
        Write-Host "4 - Eventos críticos"
        Write-Host "5 - Aplicativos que travaram"
        Write-Host "6 - Status do disco"
        Write-Host "0 - Voltar"
        $opc = Read-Host "Escolha uma opção"
        switch ($opc) {
            1 { Uso-Recursos; Pause }
            2 { Top-Processos; Pause }
            3 { Drivers-Problema; Pause }
            4 { Eventos-Criticos; Pause }
            5 { Apps-Travaram; Pause }
            6 { Status-Disco; Pause }
            0 { }
            default { Write-Host "Opção inválida" -ForegroundColor Red; Pause }
        }
    } until ($opc -eq "0")
}

# ======= Loop Principal =======
do {
    Mostrar-Menu
    $opcao = Read-Host "Escolha uma opção"
    switch ($opcao) {
        1 { Menu-Manutencao }
        2 { Menu-Diagnostico }
        3 { Manutencao-Completa }
        4 { Diagnostico-Completo }
        0 { Add-Log "Script encerrado pelo usuário"; Write-Host "Saindo..." -ForegroundColor Red }
        default { Write-Host "Opção inválida" -ForegroundColor Red; Pause }
    }
} until ($opcao -eq "0")

Write-Host "Relatório salvo em: $logPath" -ForegroundColor Yellow
