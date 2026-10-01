#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE_DIR="$ROOT_DIR/template"

# Reuse the sirius-web path from the previously generated (current) project, so repeated
# runs (e.g. after a restart) don't require retyping it.
CURRENT_MARKER="$ROOT_DIR/generated/.current-project"
if [ -z "${SIRIUS_WEB_ROOT:-}" ] && [ -f "$CURRENT_MARKER" ]; then
  PROJECT_INFO="$ROOT_DIR/generated/$(cat "$CURRENT_MARKER")/.project-info"
  if [ -f "$PROJECT_INFO" ]; then
    SIRIUS_WEB_ROOT="$(grep '^SIRIUS_WEB_ROOT=' "$PROJECT_INFO" | cut -d= -f2-)"
  fi
fi

read -p "Project name [my_extension]: " PROJECT_NAME
PROJECT_NAME="${PROJECT_NAME:-my_extension}"
# Folder/package names derived from this must start lowercase.
PROJECT_NAME="${PROJECT_NAME,}"

read -p "Group ID [example.com]: " GROUP_ID
GROUP_ID="${GROUP_ID:-example.com}"

read -p "Version [0.0.1-SNAPSHOT]: " VERSION
VERSION="${VERSION:-0.0.1-SNAPSHOT}"

# Ask for the sirius-web location unless already known (env var or previous run); store it
# so install.sh (and clean.sh --uninstall) can reuse it without asking again.
SIRIUS_WEB_ROOT="${SIRIUS_WEB_ROOT:-}"
if [ -z "$SIRIUS_WEB_ROOT" ]; then
  read -rp "Path to your sirius-web checkout: " SIRIUS_WEB_ROOT
fi
SIRIUS_WEB_ROOT="$(cd "$SIRIUS_WEB_ROOT" 2>/dev/null && pwd || true)"
if [ -z "$SIRIUS_WEB_ROOT" ] || [ ! -f "$SIRIUS_WEB_ROOT/packages/pom.xml" ]; then
  echo "Error: '$SIRIUS_WEB_ROOT' does not look like a sirius-web checkout (packages/pom.xml not found)."
  exit 1
fi
export SIRIUS_WEB_ROOT

PROJECT_IDENTITY="${PROJECT_NAME//[-_. ]/}"
PACKAGE_BASE="${GROUP_ID}.${PROJECT_IDENTITY,,}"
ECORE_PACKAGE_NAME="${PROJECT_IDENTITY,,}"
MODEL_PACKAGE="${PACKAGE_BASE}"
SERVICE_PACKAGE="${PACKAGE_BASE}.services"
MODEL_NAME="${PROJECT_IDENTITY^}"
SERVICE_CLASS="${MODEL_NAME}Service"
MODEL_ROOT_CLASS="${MODEL_NAME}Model"

ECORE_NS_URI="http://www.${GROUP_ID}/${PROJECT_NAME}"

CLEAN_SCRIPT="$ROOT_DIR/scripts/clean.sh"

TARGET_DIR="$ROOT_DIR/generated/$PROJECT_NAME"
if [ -d "$TARGET_DIR" ]; then
  read -rp "Target directory already exists: $TARGET_DIR. Remove it and regenerate? [y/N] " REMOVE_EXISTING
  if [[ "$REMOVE_EXISTING" =~ ^[Yy]$ ]]; then
    UNINSTALL_FLAG=""
    read -rp "Also clean its installation from a sirius-web checkout? [y/N] " UNINSTALL_EXISTING
    [[ "$UNINSTALL_EXISTING" =~ ^[Yy]$ ]] && UNINSTALL_FLAG="--uninstall"
    "$CLEAN_SCRIPT" "$PROJECT_NAME" --yes $UNINSTALL_FLAG
  else
    echo "Aborted: $TARGET_DIR already exists."
    exit 1
  fi
fi

# Switching the "current" project away from a different previous one: offer to remove it
# (and its sirius-web installation, via clean.sh) so stale extensions don't linger.
if [ -f "$CURRENT_MARKER" ]; then
  PREVIOUS_PROJECT="$(cat "$CURRENT_MARKER")"
  PREVIOUS_DIR="$ROOT_DIR/generated/$PREVIOUS_PROJECT"
  if [ "$PREVIOUS_PROJECT" != "$PROJECT_NAME" ] && [ -d "$PREVIOUS_DIR" ]; then
    read -rp "Previous current project '$PREVIOUS_PROJECT' found. Remove generated/$PREVIOUS_PROJECT? [y/N] " REMOVE_PREVIOUS
    if [[ "$REMOVE_PREVIOUS" =~ ^[Yy]$ ]]; then
      UNINSTALL_FLAG=""
      read -rp "Also clean '$PREVIOUS_PROJECT' from a sirius-web checkout (undoes install.sh)? [y/N] " UNINSTALL_PREVIOUS
      [[ "$UNINSTALL_PREVIOUS" =~ ^[Yy]$ ]] && UNINSTALL_FLAG="--uninstall"
      "$CLEAN_SCRIPT" "$PREVIOUS_PROJECT" --yes $UNINSTALL_FLAG
    fi
  fi
fi

mkdir -p "$ROOT_DIR/generated"
cp -R "$TEMPLATE_DIR" "$TARGET_DIR"

# Persist the chosen values so install.sh can reuse them without re-deriving anything
cat > "$TARGET_DIR/.project-info" << EOF
PROJECT_NAME=$PROJECT_NAME
GROUP_ID=$GROUP_ID
VERSION=$VERSION
SIRIUS_WEB_ROOT=$SIRIUS_WEB_ROOT
EOF

# Record this as the current project so install.sh always installs it, without
# having to guess among any other projects left under generated/.
echo "$PROJECT_NAME" > "$CURRENT_MARKER"

PACKAGE_PATH="$(echo "$PACKAGE_BASE" | tr '.' '/')"
MODEL_PACKAGE_PATH="$(echo "$MODEL_PACKAGE" | tr '.' '/')"
SERVICE_PACKAGE_PATH="$(echo "$SERVICE_PACKAGE" | tr '.' '/')"

find "$TARGET_DIR" -type f \( -name "*.java" -o -name "*.xml" -o -name "*.ecore" -o -name "*.md" -o -name "*.sh" -o -name ".project" -o -name ".classpath" -o -name "*.genmodel" -o -name "*.aird" -o -name "*.imports" \) -print0 | while IFS= read -r -d '' file; do
  sed -i "s|__GROUP_ID__|$GROUP_ID|g; s|__PROJECT_NAME__|$PROJECT_NAME|g; s|__VERSION__|$VERSION|g; s|__PACKAGE_BASE__|$PACKAGE_BASE|g; s|__ECORE_PACKAGE_NAME__|$ECORE_PACKAGE_NAME|g; s|__MODEL_PACKAGE__|$MODEL_PACKAGE|g; s|__SERVICE_PACKAGE__|$SERVICE_PACKAGE|g; s|__MODEL_ROOT_CLASS__|$MODEL_ROOT_CLASS|g; s|__MODEL_NAME__|$MODEL_NAME|g; s|__SERVICE_CLASS__|$SERVICE_CLASS|g; s|__ECORE_NS_URI__|$ECORE_NS_URI|g; s|__PACKAGE_PATH__|$PACKAGE_PATH|g; s|__MODEL_PACKAGE_PATH__|$MODEL_PACKAGE_PATH|g; s|__SERVICE_PACKAGE_PATH__|$SERVICE_PACKAGE_PATH|g" "$file"
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

if [ -f "$TARGET_DIR/backend/${PROJECT_NAME}-metamodel/model/__MODEL_NAME__.aird" ]; then
  mv "$TARGET_DIR/backend/${PROJECT_NAME}-metamodel/model/__MODEL_NAME__.aird" "$TARGET_DIR/backend/${PROJECT_NAME}-metamodel/model/${MODEL_NAME}.aird"
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
