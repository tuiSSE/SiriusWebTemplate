#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE_DIR="$ROOT_DIR/template"

read -p "Project name [my-sirius-extension]: " PROJECT_NAME
PROJECT_NAME="${PROJECT_NAME:-my-sirius-extension}"

read -p "Group ID [example.com]: " GROUP_ID
GROUP_ID="${GROUP_ID:-example.com}"

read -p "Version [0.0.1-SNAPSHOT]: " VERSION
VERSION="${VERSION:-0.0.1-SNAPSHOT}"

PROJECT_IDENTITY="${PROJECT_NAME//[-_. ]/}"
PACKAGE_BASE="${GROUP_ID}.${PROJECT_IDENTITY,,}"
MODEL_PACKAGE="${PACKAGE_BASE}.model"
SERVICE_PACKAGE="${PACKAGE_BASE}.services"
MODEL_NAME="${PROJECT_IDENTITY^}"
SERVICE_CLASS="${MODEL_NAME}Service"

ECORE_NS_URI="http://www.${GROUP_ID}/${PROJECT_NAME}"

TARGET_DIR="$ROOT_DIR/generated/$PROJECT_NAME"
if [ -d "$TARGET_DIR" ]; then
  echo "Target directory already exists: $TARGET_DIR"
  exit 1
fi

mkdir -p "$ROOT_DIR/generated"
cp -R "$TEMPLATE_DIR" "$TARGET_DIR"

PACKAGE_PATH="$(echo "$PACKAGE_BASE" | tr '.' '/')"
MODEL_PACKAGE_PATH="$(echo "$MODEL_PACKAGE" | tr '.' '/')"
SERVICE_PACKAGE_PATH="$(echo "$SERVICE_PACKAGE" | tr '.' '/')"

find "$TARGET_DIR" -type f \( -name "*.java" -o -name "*.xml" -o -name "*.ecore" -o -name "*.md" -o -name "*.sh" -o -name ".project" -o -name ".classpath" -o -name "*.genmodel" \) -print0 | while IFS= read -r -d '' file; do
  sed -i "s|__GROUP_ID__|$GROUP_ID|g; s|__PROJECT_NAME__|$PROJECT_NAME|g; s|__VERSION__|$VERSION|g; s|__PACKAGE_BASE__|$PACKAGE_BASE|g; s|__MODEL_PACKAGE__|$MODEL_PACKAGE|g; s|__SERVICE_PACKAGE__|$SERVICE_PACKAGE|g; s|__MODEL_NAME__|$MODEL_NAME|g; s|__SERVICE_CLASS__|$SERVICE_CLASS|g; s|__ECORE_NS_URI__|$ECORE_NS_URI|g; s|__PACKAGE_PATH__|$PACKAGE_PATH|g; s|__MODEL_PACKAGE_PATH__|$MODEL_PACKAGE_PATH|g; s|__SERVICE_PACKAGE_PATH__|$SERVICE_PACKAGE_PATH|g" "$file"
done

if [ -d "$TARGET_DIR/backend/starter-template" ]; then
  mv "$TARGET_DIR/backend/starter-template" "$TARGET_DIR/backend/${PROJECT_NAME}"
fi

if [ -d "$TARGET_DIR/backend/${PROJECT_NAME}/src/main/java/__SERVICE_PACKAGE_PATH__" ]; then
  mkdir -p "$(dirname "$TARGET_DIR/backend/${PROJECT_NAME}/src/main/java/${SERVICE_PACKAGE_PATH}")"
  mv "$TARGET_DIR/backend/${PROJECT_NAME}/src/main/java/__SERVICE_PACKAGE_PATH__" "$TARGET_DIR/backend/${PROJECT_NAME}/src/main/java/${SERVICE_PACKAGE_PATH}"
fi

if [ -d "$TARGET_DIR/backend/${PROJECT_NAME}/src/main/java/${SERVICE_PACKAGE_PATH}" ]; then
  find "$TARGET_DIR/backend/${PROJECT_NAME}/src/main/java/${SERVICE_PACKAGE_PATH}" -type f -name "__PROJECT_NAME__*.java" -print0 | while IFS= read -r -d '' file; do
    dir="$(dirname "$file")"
    base="$(basename "$file")"
    renamed="${base//__PROJECT_NAME__/$PROJECT_NAME}"
    if [ "$base" != "$renamed" ]; then
      mv "$file" "$dir/$renamed"
    fi
  done
fi

if [ -d "$TARGET_DIR/backend/__PROJECT_NAME__-metamodel" ]; then
  mv "$TARGET_DIR/backend/__PROJECT_NAME__-metamodel" "$TARGET_DIR/backend/${PROJECT_NAME}-metamodel"
fi

if [ -d "$TARGET_DIR/backend/__PROJECT_NAME__-metamodel-edit" ]; then
  mv "$TARGET_DIR/backend/__PROJECT_NAME__-metamodel-edit" "$TARGET_DIR/backend/${PROJECT_NAME}-metamodel-edit"
fi

if [ -f "$TARGET_DIR/backend/${PROJECT_NAME}-metamodel/model/__MODEL_NAME__.ecore" ]; then
  mv "$TARGET_DIR/backend/${PROJECT_NAME}-metamodel/model/__MODEL_NAME__.ecore" "$TARGET_DIR/backend/${PROJECT_NAME}-metamodel/model/${MODEL_NAME}.ecore"
fi

if [ -f "$TARGET_DIR/backend/${PROJECT_NAME}-metamodel/model/__MODEL_NAME__.genmodel" ]; then
  mv "$TARGET_DIR/backend/${PROJECT_NAME}-metamodel/model/__MODEL_NAME__.genmodel" "$TARGET_DIR/backend/${PROJECT_NAME}-metamodel/model/${MODEL_NAME}.genmodel"
fi

if [ -f "$TARGET_DIR/backend/${PROJECT_NAME}-metamodel/model/example.ecore" ]; then
  mv "$TARGET_DIR/backend/${PROJECT_NAME}-metamodel/model/example.ecore" "$TARGET_DIR/backend/${PROJECT_NAME}-metamodel/model/${MODEL_NAME}.ecore"
fi

if [ -f "$TARGET_DIR/scripts/install.sh" ]; then
  chmod +x "$TARGET_DIR/scripts/install.sh"
fi
if [ -f "$TARGET_DIR/scripts/generate.sh" ]; then
  chmod +x "$TARGET_DIR/scripts/generate.sh"
fi

echo "Generated project: $TARGET_DIR"
echo "Next step: cd $TARGET_DIR && ./scripts/install.sh"
