@echo off

:: Definindo código para UTF-8 (65001)
chcp 65001 > nul 

:: Ativa a expansão atrasada de variáveis
setlocal enabledelayedexpansion

:: Diretório padrão para onde vai o script e o arquivo de instalação
set dir_padrao="c:\Users\Public\Downloads"

:: Diretório do arquivo de instalação
set dir_arquivo_instalacao="\\serverpavuna\Arquivos\VPN\NSClient.msi"
:: Arquivo de execução
set arq_exec=script.bin

:: Apagando arquivo InstallNetskoper.log
del %dir_padrao%\InstallNetSkope.log /s /a

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

    title 		**%username%**** Utilitários para Windows ****************

    echo.
    echo.
    echo.	   Computador: %computername%	Usuario: %username%
    echo -----------------------------------------------------------------
    echo.       [ 1 ] - Limpeza no sistema
    echo.       [ 2 ] - Desistalar Netskope
    echo.       [ 3 ] - Instalar Netskope
    echo -----------------------------------------------------------------

    choice /c 123 /n /m "Digite uma opção:"
    cls
    if %errorlevel%==1 goto limpar_sistema
    if %errorlevel%==2 goto desistalar_netskope
    if %errorlevel%==3 goto instalacao_netskope

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

:instalacao_netskope
    :: Código de instalação do Netskope
    echo.
    echo. Iniciando a instalacao do Netskope...
    echo.

    :: Executa o comando de instalação do Netskope e gera o arquivo de log
    msiexec /quiet /I %dir_arquivo_instalacao% installmode=idP tenant=dpsp domain=eu.goskope.com mode=peruserconfig /log c:\Users\Public\Downloads\InstallNetSkope.log

    :: Verifica se o arquivo de log foi gerado
    if exist c:\Users\Public\Downloads\InstallNetSkope.log (
        echo. Arquivo de log encontrado. Exibindo conteúdo relevante:
        
        :: Exibe as linhas relevantes do log que indicam a instalação do cliente Netskope
        for /f "tokens=11" %%i in ('find /i "Product: Netskope client" ^< c:\Users\Public\Downloads\InstallNetSkope.log') do (
            echo %%i
        )
    ) else (
        echo. Arquivo de log não encontrado.
    )

    goto menu
