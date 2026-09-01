#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE_DIR="$ROOT_DIR/template"

read -p "Group ID [com.example]: " GROUP_ID
GROUP_ID="${GROUP_ID:-com.example}"

read -p "Artifact ID [my-sirius-extension]: " ARTIFACT_ID
ARTIFACT_ID="${ARTIFACT_ID:-my-sirius-extension}"

read -p "Version [0.0.1-SNAPSHOT]: " VERSION
VERSION="${VERSION:-0.0.1-SNAPSHOT}"

read -p "Java base package [com.example.myextension]: " PACKAGE_BASE
PACKAGE_BASE="${PACKAGE_BASE:-com.example.myextension}"

read -p "Model package [com.example.myextension.model]: " MODEL_PACKAGE
MODEL_PACKAGE="${MODEL_PACKAGE:-${PACKAGE_BASE}.model}"

read -p "Service package [com.example.myextension.services]: " SERVICE_PACKAGE
SERVICE_PACKAGE="${SERVICE_PACKAGE:-${PACKAGE_BASE}.services}"

read -p "Model name [MyModel]: " MODEL_NAME
MODEL_NAME="${MODEL_NAME:-MyModel}"

read -p "Service class name [RandomGeneratorService]: " SERVICE_CLASS
SERVICE_CLASS="${SERVICE_CLASS:-RandomGeneratorService}"

read -p "Ecore namespace URI [http://www.example.com/myextension]: " ECORE_NS_URI
ECORE_NS_URI="${ECORE_NS_URI:-http://www.example.com/myextension}"

TARGET_DIR="$ROOT_DIR/generated/$ARTIFACT_ID"
if [ -d "$TARGET_DIR" ]; then
  echo "Target directory already exists: $TARGET_DIR"
  exit 1
fi

cp -R "$TEMPLATE_DIR" "$TARGET_DIR"

PACKAGE_PATH="$(echo "$PACKAGE_BASE" | tr '.' '/')"
MODEL_PACKAGE_PATH="$(echo "$MODEL_PACKAGE" | tr '.' '/')"
SERVICE_PACKAGE_PATH="$(echo "$SERVICE_PACKAGE" | tr '.' '/')"

find "$TARGET_DIR" -type f \( -name "*.java" -o -name "*.xml" -o -name "*.ecore" -o -name "*.md" -o -name "*.sh" \) -print0 | while IFS= read -r -d '' file; do
  sed -i "s|__GROUP_ID__|$GROUP_ID|g; s|__ARTIFACT_ID__|$ARTIFACT_ID|g; s|__VERSION__|$VERSION|g; s|__PACKAGE_BASE__|$PACKAGE_BASE|g; s|__MODEL_PACKAGE__|$MODEL_PACKAGE|g; s|__SERVICE_PACKAGE__|$SERVICE_PACKAGE|g; s|__MODEL_NAME__|$MODEL_NAME|g; s|__SERVICE_CLASS__|$SERVICE_CLASS|g; s|__ECORE_NS_URI__|$ECORE_NS_URI|g; s|__PACKAGE_PATH__|$PACKAGE_PATH|g; s|__MODEL_PACKAGE_PATH__|$MODEL_PACKAGE_PATH|g; s|__SERVICE_PACKAGE_PATH__|$SERVICE_PACKAGE_PATH|g" "$file"
done

if [ -d "$TARGET_DIR/backend/__ARTIFACT_ID__-metamodel" ]; then
  mv "$TARGET_DIR/backend/__ARTIFACT_ID__-metamodel" "$TARGET_DIR/backend/${ARTIFACT_ID}-metamodel"
fi

if [ -d "$TARGET_DIR/backend/__ARTIFACT_ID__-metamodel-edit" ]; then
  mv "$TARGET_DIR/backend/__ARTIFACT_ID__-metamodel-edit" "$TARGET_DIR/backend/${ARTIFACT_ID}-metamodel-edit"
fi

if [ -f "$TARGET_DIR/backend/${ARTIFACT_ID}-metamodel/model/__MODEL_NAME__.ecore" ]; then
  mv "$TARGET_DIR/backend/${ARTIFACT_ID}-metamodel/model/__MODEL_NAME__.ecore" "$TARGET_DIR/backend/${ARTIFACT_ID}-metamodel/model/${MODEL_NAME}.ecore"
fi

if [ -f "$TARGET_DIR/backend/${ARTIFACT_ID}-metamodel/model/example.ecore" ]; then
  mv "$TARGET_DIR/backend/${ARTIFACT_ID}-metamodel/model/example.ecore" "$TARGET_DIR/backend/${ARTIFACT_ID}-metamodel/model/${MODEL_NAME}.ecore"
fi

chmod +x "$TARGET_DIR/scripts/install.sh" "$TARGET_DIR/scripts/generate.sh"

echo "Generated project: $TARGET_DIR"
echo "Next step: cd $TARGET_DIR && ./scripts/install.sh"
