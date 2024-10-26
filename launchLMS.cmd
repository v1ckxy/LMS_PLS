@echo off
rem VXN LMStudio Portable Launch Script (LMS PLS)
setlocal EnableDelayedExpansion

rem Modify in case you want to change in which GPU(s) you want to load models.
rem 0 (1st GPU), 1 (2nd), 2 (3rd) and so on. Specify multiple GPUs with commas: 1,2,3
rem set CUDA_VISIBLE_DEVICES=1

cd /D "%~dp0"
set "CurrentPath=%CD%"

rem \
set "HomeDrive=%~d0"
echo HomeDrive:"%HomeDrive%"
set "HomePath=%cd:~2%"
echo HomePath:"%HomePath%"

rem \
set "OriginalUserProfile=%UserProfile%"
set "UserProfile=%CurrentPath%"
echo UserProfile:"%UserProfile%"

rem \AppData\Local
set "LocalAppData=%CurrentPath%\AppData\Local"
echo LocalAppData:"%LocalAppData%"

rem \AppData\Local\Temp
set "Temp=%LocalAppData%\Temp"
echo Temp:"%Temp%"

rem \AppData\Roaming
set "AppData=%CurrentPath%\AppData\Roaming"
echo AppData:"%AppData%"

rem Create paths if doesn't exist
if not exist "%UserProfile%\Desktop" mkdir "%UserProfile%\Desktop"
if not exist "%UserProfile%\AppData" mkdir "%UserProfile%\AppData"
if not exist "%LocalAppData%" mkdir "%LocalAppData%"
if not exist "%AppData%" mkdir "%AppData%"
if not exist "%Temp%" mkdir "%Temp%"

rem Check if latest installer is ready for installation, in case needed
set "InstallerPath=%CurrentPath%\Installers"
if not exist "%InstallerPath%" mkdir "%InstallerPath%"

for /f "delims=" %%A in ('dir /b /a-d /on "%InstallerPath%\LM-Studio-*-Setup.exe" 2^>nul') do ( set "InstallerExe=%%A" )

rem Application Startup
if not exist "%LocalAppData%\LM-Studio\LM Studio.exe" (
	echo LM Studio not found. Performing installation...
	if "%InstallerExe%"=="" (
		echo Please download LM Studio from https://lmstudio.ai/download and put the LM-Studio-Setup.exe file inside "%InstallerPath%"
		pause
		exit
	) else ( 
		echo Launching installer %InstallerExe% from "%InstallerPath%"
		call %InstallerPath%\%InstallerExe%
		pause
		exit
	)
) else (
	set "inputFile=%AppData%\LM Studio\settings.json"
	echo inputFile:!inputFile!
	set "tempFile=%AppData%\LM Studio\settings_temp.json"
	echo tempFile:!tempFile!
	
	set searchString=downloadsFolder
	echo !searchString!
	
	rem "downloadsFolder": "..\\..\\..\\..\\.cache\\lm-studio\\models",
	set replaceString=  "downloadsFolder": "%UserProfile:\=\\%\\.cache\\lm-studio\\models",
	echo !replaceString!
	
	
	if not exist "!inputFile!" (
		echo File !inputFile! not found, will be generated upon launch and fixed on next run.
		pause
	)

	(
		rem Recreate config file with a modified downloadsFolder
		for /f "usebackq delims=" %%A in ("!inputFile!") do (
			set "line=%%A"
			echo !line! | findstr /c:!searchString! >nul
			if !errorlevel! equ 0 (
				rem Replace line if the string is found
				echo !replaceString!
			) else (
				rem Keep rest of lines
				echo !line!
			)
		)
	) > "!tempFile!"

	rem Replace original settings file with modified one
	move /y "!tempFile!" "!inputFile!" >nul
	echo File !inputFile! fixed, launching app...
	
	"%LocalAppData%\LM-Studio\LM Studio.exe"
	
	rem Workaround - LMS recreates config-presets during launch under %UserProfile%
	if exist "%OriginalUserProfile%\.cache\lm-studio" (
		timeout /t 5
		echo Syncing files and cleaning up leftovers
		robocopy "%OriginalUserProfile%\.cache\lm-studio" "%UserProfile%\.cache\lm-studio" /E /XC /XN /XO
		del /f /s /q "%OriginalUserProfile%\.cache\lm-studio"
		timeout /t 5
	)
)