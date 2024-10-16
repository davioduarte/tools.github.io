@echo off

:: Definindo código para UTF-8 (65001)
chcp 65001 > nul 

:: Ativa a expansão atrasada de variáveis
setlocal enabledelayedexpansion

:: Diretório padrão para onde vai o script e o arquivo de instalação
set dir_padrao="c:\Users\Public\Downloads"

:: Arquivo de execução
set arq_exec=script.bin

:: Validar se está sendo executado como ADM
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo. Este script precisa ser executado em modo administrador.
    :: Reinicia o script em modo administrador
    powershell -Command "Start-Process cmd -ArgumentList '/c %~fnx0' -Verb RunAs"
    exit /b
)

:menu
    mode 70,25
    color 17
    cls

    title **%username%**** Utilitarios para Windows ****************

    echo.
    echo.
    echo.	   Computador: %computername%	Usuario: %username%
    echo ---------------------------------------------------------------------
    echo.       [ 1 ] - Limpeza no sistema
    echo.       [ 2 ] - Desistalar Netskope
    echo.       [ 3 ] - Reparo Windows
    echo.       [ 4 ] - Formatar Pendrive para boot
    echo.       [ 5 ] - Compactar OS
    echo.       [ 6 ] - Reset placa de Rede
    echo ---------------------------------------------------------------------
    echo v0.2
    echo.
    choice /c 123456 /n /m "Digite uma opcao:"
    cls
    if %errorlevel%==1 goto limpar_sistema
    if %errorlevel%==2 goto desistalar_netskope
    if %errorlevel%==3 goto reparo_windows
    if %errorlevel%==4 goto diskpartInicio
    if %errorlevel%==5 goto compactar_os
    if %errorlevel%==6 goto reset_rede

:fim_operacao
    echo.
	echo. ===== Fim da Operacao =====================================
	echo.
	pause
	goto menu

:limpar_sistema
    echo. Limpando pasta temp
	rd %temp%\* /f /s /q >nul
	rd C:\Windows\Temp /s /q >nul
	del /f /s /q %windir%\temp\* >nul
	
	echo. Limpando Prefetch
	rd C:\Windows\Prefetch /s /q >nul

	echo. Parando servico do Windows Update
	net stop wuauserv >nul
	net stop bits >nul
	
	echo. Apagando arquivos de Download do Win Update
	del /f /s /q C:\Windows\SoftwareDistribution\Download\* >nul  
	del /f /s /q %windir%\SoftwareDistribution\Download\* >nul

	echo Retomando servico do Windows Update
	net start bits >nul
	net start wuauserv >nul

	echo. Limpando componentes do Win Update que nao sao mais necessarios
	DISM /Online /Cleanup-Image /StartComponentCleanup

	:: Desativar a Hibernação
	echo Desativando a hibernação...
	powercfg -h off 

	:: Limpar pontos de restauração antigos
	echo Limpando pontos de restauração antigos...
	vssadmin delete shadows /for=C: /oldest /q

	echo. Iniciando cleanmgr
	cleanmgr.exe /d c /LOWDISK /AUTOCLEAN  /VERYLOWDISK /s /q /sagerun:1

	echo ============================================
	echo Limpeza Completa
	echo ============================================

    goto fim_operacao

:desistalar_netskope
    :: Desistala o netskope pelo id da instalação
    for /f "tokens=*" %%i in ('wmic product where "Name like '%%Netskope%%'" get IdentifyingNumber ^| find "{"') do (
        echo. ID da instalacao %%i
        set "id_netskope=%%i"
    )

    if "%id_netskope%"=="" (
        goto desistalar_netskope
    )

    echo. 
    echo. ID da instalação Netskope: %id_netskope%
    echo.
    msiexec /uninstall %id_netskope% /quiet /norestart /log c:\Users\Public\Downloads\un-fclient.log

    if %errorlevel% neq 0 (
        echo. Erro ao desinstalar o Netskope com ID %id_netskope%
    ) else (
        echo.
        echo. Netskope desinstalado com sucesso.
        echo.
        echo. Validando se o servico esta ativo:
        echo.
        echo.
        sc query stagentsvc
        echo.
    )

    goto menu

:reparo_windows
    cls
	echo. 		==== Reparando o windows ====
	echo.	
		sfc /scannow
	echo.
	echo.		=== Scaneando ===
	echo.
		Dism /online /cleanup-image /ScanHealth
	echo.
	echo.		=== Restaurando ===
	echo.
		Dism /online /cleanup-image /RestoreHealth

	goto fim_operacao

:diskpartInicio

    title ========== Criando Pendrive Botavel =============

	set diret="c:\Users\Public\Downloads\scriptboot.bin"
	set partdisk=diskpart /s %diret%
	del %diret% /s /q

	cls
	echo list disk >>%diret%
	echo.=== diskpart ===
	%partdisk%

	echo.=== Selecione a Unidade ===

	set /p un=:
	cls
	del %diret% /s /q

	echo select disk %un% >>%diret%
	echo list disk >>%diret%
	%partdisk%

	set /p quest=desenha continuar com a operacao? [S/N]:

	if /i %quest%==s goto proximo
	if /i %quest%==n goto diskpartfinal

	
	:diskpartfinal

	del %diret% /s /q
	goto fim_operacao

	:proximo

	cls
	echo clean >>%diret%
	echo create partition primary >>%diret%
	echo format fs=fat32 quick >>%diret%
	echo active >>%diret%
	%partdisk%
	
	echo.
	echo.=== Agora só copiar o systema operacional ==
	echo.=== para o pendrive formatado ==============
	echo.
	goto diskpartfinal

:compactar_os
    cls
	
	echo. Compactando Sistema...
	
	compact.exe /CompactOS:always

	goto fim_operacao

:reset_rede
	echo.
	echo. Iniciando reset da placa de Rede

	netsh winsock reset

	echo.
	
	goto fim_operacao
