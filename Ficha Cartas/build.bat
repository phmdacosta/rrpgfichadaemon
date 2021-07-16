@echo off
::--------------------------------------------------------------------------------
::  Handle child project build
::  RRPG's SDK need to have all scripts in main project folder
::  To avoid we have two versions of the same scripts,
::  lets copy base project scripts to this project's folder
::--------------------------------------------------------------------------------

set proj_base=Ficha Base
set from_path_1="..\%proj_base%\item*.lfm"
set from_path_2="..\%proj_base%\layout"
set from_path_3="..\%proj_base%\scripts"
set from_path_4="..\%proj_base%\database"
set to_path_1=ficha_base_temp
set to_path_2=%to_path_1%\layout
set to_path_3=%to_path_1%\scripts
set to_path_4=%to_path_1%\database
set list_base_files=base_proj_files

::Copy scripts from base project
echo Copiando arquivos do projeto %proj_base%...
::Create folders if not exists
mkdir %to_path_2% > nul
mkdir %to_path_3% > nul
mkdir %to_path_4% > nul

xcopy %from_path_1% %to_path_1% > nul
xcopy %from_path_2% %to_path_2% > nul
xcopy %from_path_3% %to_path_3% > nul
xcopy %from_path_4% %to_path_4% > nul
::Save list of base scripts
dir %to_path_1% /s /b > %list_base_files%

::Move base scripts to 'scripts' folder
move %to_path_1%\* . > nul
move %to_path_2%\* .\layout > nul
move %to_path_3%\* .\scripts > nul
move %to_path_4%\* .\database > nul
::Remove temp folders
rmdir %to_path_4% > nul
rmdir %to_path_3% > nul
rmdir %to_path_2% > nul
rmdir %to_path_1% > nul

::Build RRPG project
rdk i

echo Finalizando compilacao.
::Remove base scripts
for /F "tokens=*" %%A in (%list_base_files%) do (
    set "replaceWith=."
    set "str=%%A"
    SETLOCAL ENABLEDELAYEDEXPANSION
    call set "str=%%str:\%to_path_1%=%%"
    ::Delete if it is file
    if not exist "!str!"\* del /q "!str!"
    ENDLOCAL
)

::Remove list of files
del /q %list_base_files%