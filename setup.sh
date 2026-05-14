#!/bin/bash

echo "=================================="
echo " Configuracion automatica FreeTime"
echo "=================================="

# =========================================
# Verificar FRONTEND
# =========================================

if [ -d "../project-frontend" ]
then
    echo ""
    echo "El frontend ya existe."
else
    echo ""
    echo "Clonando frontend..."

    git clone https://github.com/monasteryyy/project-frontend.git ../project-frontend
fi

# =========================================
# Verificar BACKEND
# =========================================

if [ -d "../project-backend" ]
then
    echo ""
    echo "El backend ya existe."
else
    echo ""
    echo "Clonando backend..."

    git clone https://github.com/monasteryyy/project-backend.git ../project-backend
fi

# =========================================
# Instalar FRONTEND
# =========================================

echo ""
echo "Instalando dependencias frontend..."

cd ../project-frontend

npm install

cd ../project-docs

# =========================================
# Instalar BACKEND
# =========================================

echo ""
echo "Instalando dependencias backend..."

cd ../project-backend

npm install

cd ../project-docs

# =========================================
# Finalizacion
# =========================================

echo ""
echo "=================================="
echo " Configuracion completada"
echo "=================================="