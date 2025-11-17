@echo off
echo ============================================
echo Creando estructura Flutter (Clean + GoRouter + Riverpod)...
echo ============================================

REM ======= CORE STRUCTURE ========
mkdir lib\core
mkdir lib\core\config
mkdir lib\core\constants
mkdir lib\core\themes
mkdir lib\core\utils
mkdir lib\core\widgets

REM ======= DATA LAYER ========
mkdir lib\data
mkdir lib\data\models
mkdir lib\data\repositories
mkdir lib\data\datasources
mkdir lib\data\datasources\local
mkdir lib\data\datasources\remote

REM ======= DOMAIN LAYER ========
mkdir lib\domain
mkdir lib\domain\entities
mkdir lib\domain\repositories
mkdir lib\domain\usecases

REM ======= PRESENTATION LAYER ========
mkdir lib\presentation
mkdir lib\presentation\pages
mkdir lib\presentation\pages\home
mkdir lib\presentation\pages\login
mkdir lib\presentation\pages\splash
mkdir lib\presentation\widgets
mkdir lib\presentation\controllers

REM ======= ROUTES ========
mkdir lib\routes

REM ======= SERVICES ========
mkdir lib\services

REM ======= ASSETS ========
mkdir assets
mkdir assets\images
mkdir assets\images\logos
mkdir assets\images\icons
mkdir assets\media
mkdir assets\data