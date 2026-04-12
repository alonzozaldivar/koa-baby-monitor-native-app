#!/bin/bash
# ============================================================================
# KOA Baby Monitor — Build iOS para Xcode
# ============================================================================
# Ejecutar en una Mac con Xcode instalado:
#   1. Abre Terminal en la carpeta del proyecto
#   2. chmod +x ios/BUILD_IOS.sh
#   3. ./ios/BUILD_IOS.sh
# ============================================================================

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
echo "📁 Proyecto: $PROJECT_DIR"
cd "$PROJECT_DIR"

echo ""
echo "======================================"
echo "  KOA Baby Monitor — Build iOS v1.1"
echo "======================================"
echo ""

# 1. Obtener dependencias
echo "📦 Obteniendo dependencias Flutter..."
flutter pub get

# 2. Instalar pods
echo ""
echo "🍎 Instalando CocoaPods..."
cd ios && pod install --repo-update && cd ..

# 3. Build sin firma (para abrir en Xcode y firmar manualmente)
echo ""
echo "🔨 Compilando para iOS (sin firma de código)..."
flutter build ios --release --no-codesign

echo ""
echo "✅ Build completado!"
echo ""
echo "Siguiente paso — Abrir en Xcode:"
echo "  open ios/Runner.xcworkspace"
echo ""
echo "En Xcode:"
echo "  1. Selecciona tu equipo de desarrollo (Signing & Capabilities)"
echo "  2. Conecta tu iPhone / iPad"
echo "  3. Product → Run  (para instalar en dispositivo)"
echo "  4. Product → Archive  (para distribuir por TestFlight o App Store)"
echo ""
echo "Archivo .xcworkspace listo en: $PROJECT_DIR/ios/Runner.xcworkspace"
