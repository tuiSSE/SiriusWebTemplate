#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
GENERATED_DIR="$PROJECT_DIR/generated"

usage() {
  cat << EOF
Usage: $0 [PROJECT_NAME ...] [--all] [--uninstall] [--yes]

Removes stale generated extensions under generated/ so install.sh can no longer
pick the wrong project by accident.

  PROJECT_NAME   One or more project names under generated/ to remove.
  --all          Remove every project under generated/.
  --uninstall    Also undo install.sh's changes in the sirius-web checkout
                 (requires SIRIUS_WEB_ROOT env var or prompt), for each
                 project being removed.
  --yes          Do not ask for confirmation.

Examples:
  $0 --all
  $0 myExtension anotherExtension
  $0 --all --uninstall
EOF
}

ALL=false
UNINSTALL=false
ASSUME_YES=false
TARGETS=()

for arg in "$@"; do
  case "$arg" in
    --all) ALL=true ;;
    --uninstall) UNINSTALL=true ;;
    --yes|-y) ASSUME_YES=true ;;
    -h|--help) usage; exit 0 ;;
    *) TARGETS+=("$arg") ;;
  esac
done

if [ ! -d "$GENERATED_DIR" ]; then
  echo "Nothing to clean: $GENERATED_DIR does not exist."
  exit 0
fi

if [ "$ALL" = true ]; then
  mapfile -t TARGETS < <(find "$GENERATED_DIR" -maxdepth 1 -mindepth 1 -type d ! -name ".*" -printf '%f\n' | sort)
fi

if [ "${#TARGETS[@]}" -eq 0 ]; then
  echo "No project names given. Use --all to remove every generated project, or pass names explicitly."
  usage
  exit 1
fi

uninstall_from_sirius_web() {
  local project_name="$1" group_id="$2"
  local sirius_web_root="${SIRIUS_WEB_ROOT:-}"
  if [ -z "$sirius_web_root" ]; then
    read -rp "Path to your sirius-web checkout (to uninstall ${project_name}): " sirius_web_root
  fi
  sirius_web_root="$(cd "$sirius_web_root" 2>/dev/null && pwd || true)"
  if [ -z "$sirius_web_root" ] || [ ! -f "$sirius_web_root/packages/pom.xml" ]; then
    echo "  ⚠ '$sirius_web_root' does not look like a sirius-web checkout, skipping uninstall for ${project_name}."
    return
  fi

  local packages_dir="$sirius_web_root/packages"
  local packages_pom="$packages_dir/pom.xml"
  local starters_pom="$packages_dir/starters/backend/pom.xml"
  local app_pom="$packages_dir/sirius-web/backend/sirius-web/pom.xml"

  echo "  • Removing ${packages_dir}/${project_name}"
  rm -rf "${packages_dir:?}/${project_name}"

  echo "  • Removing ${packages_dir}/starters/backend/${project_name}-starter"
  rm -rf "${packages_dir:?}/starters/backend/${project_name}-starter"

  if [ -f "$packages_pom" ]; then
    echo "  • Unregistering module from packages/pom.xml"
    sed -i "\|<module>${project_name}/backend</module>|d" "$packages_pom"
  fi

  if [ -f "$starters_pom" ]; then
    echo "  • Unregistering module from starters/backend/pom.xml"
    sed -i "\|<module>${project_name}-starter</module>|d" "$starters_pom"
  fi

  if [ -f "$app_pom" ]; then
    echo "  • Removing dependency from sirius-web app pom.xml"
    awk -v artifactId="${project_name}" '
      BEGIN { skip=0 }
      /<dependency>/ { block=$0; inblock=1; next }
      inblock && /<\/dependency>/ {
        block = block "\n" $0
        if (block ~ ("<artifactId>" artifactId "</artifactId>")) {
          inblock=0
          next
        }
        print block
        inblock=0
        next
      }
      inblock { block = block "\n" $0; next }
      { print }
    ' "$app_pom" > "$app_pom.tmp" && mv "$app_pom.tmp" "$app_pom"
  fi
}

for name in "${TARGETS[@]}"; do
  TARGET_DIR="$GENERATED_DIR/$name"
  if [ ! -d "$TARGET_DIR" ]; then
    echo "Skipping '$name': not found under $GENERATED_DIR"
    continue
  fi

  if [ "$ASSUME_YES" != true ]; then
    read -rp "Remove generated/$name$( [ "$UNINSTALL" = true ] && echo ' and its sirius-web installation')? [y/N] " CONFIRM
    [[ "$CONFIRM" =~ ^[Yy]$ ]] || { echo "Skipped $name."; continue; }
  fi

  if [ "$UNINSTALL" = true ]; then
    GROUP_ID=""
    SIRIUS_WEB_ROOT="${SIRIUS_WEB_ROOT:-}"
    # shellcheck disable=SC1090
    [ -f "$TARGET_DIR/.project-info" ] && source "$TARGET_DIR/.project-info"
    echo "Uninstalling $name from sirius-web..."
    uninstall_from_sirius_web "$name" "$GROUP_ID"
  fi

  echo "Removing generated/$name"
  rm -rf "$TARGET_DIR"

  CURRENT_MARKER="$GENERATED_DIR/.current-project"
  if [ -f "$CURRENT_MARKER" ] && [ "$(cat "$CURRENT_MARKER")" = "$name" ]; then
    rm -f "$CURRENT_MARKER"
  fi
done

echo ""
echo "✅ Clean complete."
