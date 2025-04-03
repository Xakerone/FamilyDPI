@echo off
if "%1" neq "secret_key_12345" (
    exit /b
)
chcp 65001 >nul
cd /d "%~dp0"
set BIN=%~dp0bin\
set LIST_PATH=%~dp0lists\list-ultimate.txt
set DISCORD_IPSET_PATH=%~dp0lists\ipset-discord.txt

:: Проверка прав администратора
net session >nul 2>&1 || (
    echo Требуются права администратора. Запустите скрипт от имени администратора.
    pause
    exit /b
)

"%BIN%nssm.exe" remove "FamilyDPI Service" confirm

:: Установка службы
"%BIN%nssm.exe" install "FamilyDPI Service" "%BIN%winws.exe" ^
--wf-tcp=80,443 --wf-udp=443,50000-50100 ^
--filter-udp=443 --hostlist="%LIST_PATH%" --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic="%BIN%quic_initial_www_google_com.bin" --new ^
--filter-udp=50000-50100 --ipset="%DISCORD_IPSET_PATH%" --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d3 --dpi-desync-repeats=6 --new ^
--filter-tcp=80 --hostlist="%LIST_PATH%" --dpi-desync=fake,split2 --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 --hostlist="%LIST_PATH%" --dpi-desync=split2 --dpi-desync-split-seqovl=652 --dpi-desync-split-pos=2 --dpi-desync-split-seqovl-pattern="%BIN%tls_clienthello_www_google_com.bin" --new ^

::schtasks /create /tn "Delete FamilyDPI Service" /sc ONSTART /ru SYSTEM /tr "\"D:\test\bin\nssm.exe\" remove \"FamilyDPI Service\" confirm" /f

:: Установка ручного запуска
"%BIN%nssm.exe" set "FamilyDPI Service" Start SERVICE_DEMAND_START

:: Запуск службы
"%BIN%nssm.exe" start "FamilyDPI Service"

:: Проверка статуса
"%BIN%nssm.exe" status "FamilyDPI Service"
if errorlevel 1 (
    echo Ошибка запуска службы. Проверьте логи.
    pause
)



exit /b