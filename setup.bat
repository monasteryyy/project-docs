@echo off

echo ==================================
echo  Configuracion automatica FreeTime
echo ==================================

:: =========================================
:: Verificar FRONTEND
:: =========================================

if exist "..\project-frontend" (
    echo.
    echo El frontend ya existe.
) else (
    echo.
    echo Clonando frontend...

    git clone https://github.com/monasteryyy/project-frontend.git ..\project-frontend
)

:: =========================================
:: Verificar BACKEND
:: =========================================

if exist "..\project-backend" (
    echo.
    echo El backend ya existe.
) else (
    echo.
    echo Clonando backend...

    git clone https://github.com/monasteryyy/project-backend.git ..\project-backend
)

:: =========================================
:: Instalar FRONTEND
:: =========================================

echo.
echo Instalando dependencias frontend...

cd ..\project-frontend

call npm install

cd ..\project-docs

:: =========================================
:: Instalar BACKEND
:: =========================================

echo.
echo Instalando dependencias backend...

cd ..\project-backend

call npm install

cd ..\project-docs

:: =========================================
:: Finalizacion
:: =========================================

echo.
echo ==================================
echo  Configuracion completada
echo ==================================

pause