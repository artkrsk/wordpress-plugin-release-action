#!/bin/bash

# WordPress Plugin Auto-Detection Script
# Detects plugin slug, main file, and version from standard WordPress plugin structure

set -e

# Detect main plugin file (file with "Plugin Name:" header)
detect_main_plugin_file() {
  local main_file=""

  # Search for PHP files with Plugin Name header
  # Priority: root directory > src/ > plugin directories

  # First check root directory
  for file in *.php; do
    if [ -f "$file" ] && grep -q "Plugin Name:" "$file"; then
      main_file="$file"
      break
    fi
  done

  # If not found, check common plugin directories
  if [ -z "$main_file" ]; then
    for dir in src wordpress-plugin plugin; do
      if [ -d "$dir" ]; then
        for file in "$dir"/*.php; do
          if [ -f "$file" ] && grep -q "Plugin Name:" "$file"; then
            main_file="$file"
            break 2
          fi
        done
      fi
    done
  fi

  # If still not found, search recursively (slower)
  if [ -z "$main_file" ]; then
    main_file=$(find . -maxdepth 3 -name "*.php" -type f -exec grep -l "Plugin Name:" {} \; | head -1)
  fi

  if [ -z "$main_file" ]; then
    echo "ERROR: Could not detect main plugin file with 'Plugin Name:' header" >&2
    exit 1
  fi

  # Clean up the path
  main_file="${main_file#./}"

  echo "$main_file"
}

# Detect plugin slug from main file or directory structure
detect_plugin_slug() {
  local main_file="${1:-}"

  # If main file not provided, detect it
  if [ -z "$main_file" ]; then
    main_file=$(detect_main_plugin_file)
  fi

  # Extract slug from main file name (remove .php extension)
  local slug=$(basename "$main_file" .php)

  # If the file is in a subdirectory, use the directory name as slug
  local dir=$(dirname "$main_file")
  if [ "$dir" != "." ] && [ "$(basename "$dir")" != "src" ] && [ "$(basename "$dir")" != "wordpress-plugin" ]; then
    slug=$(basename "$dir")
  fi

  echo "$slug"
}

# Extract version from plugin header
extract_plugin_version() {
  local main_file="${1:-}"

  if [ -z "$main_file" ]; then
    main_file=$(detect_main_plugin_file)
  fi

  if [ ! -f "$main_file" ]; then
    echo "ERROR: Plugin file not found: $main_file" >&2
    exit 1
  fi

  # Extract version from plugin header
  local version=$(grep -m 1 "Version:" "$main_file" | sed 's/.*Version:\s*//' | tr -d '\r\n' | xargs)

  if [ -z "$version" ]; then
    echo "ERROR: Could not extract version from $main_file" >&2
    exit 1
  fi

  echo "$version"
}

# Extract plugin name from plugin header
extract_plugin_name() {
  local main_file="${1:-}"

  if [ -z "$main_file" ]; then
    main_file=$(detect_main_plugin_file)
  fi

  if [ ! -f "$main_file" ]; then
    echo "ERROR: Plugin file not found: $main_file" >&2
    exit 1
  fi

  local name=$(grep -m 1 "Plugin Name:" "$main_file" | sed 's/.*Plugin Name:\s*//' | tr -d '\r\n' | xargs)

  if [ -z "$name" ]; then
    echo "ERROR: Could not extract plugin name from $main_file" >&2
    exit 1
  fi

  echo "$name"
}

# Validate plugin structure
validate_plugin_structure() {
  local main_file="${1:-}"
  local errors=0

  if [ -z "$main_file" ]; then
    main_file=$(detect_main_plugin_file)
  fi

  echo "Validating plugin structure..."

  # Check main file exists
  if [ ! -f "$main_file" ]; then
    echo "❌ Main plugin file not found: $main_file"
    ((errors++))
  fi

  # Check for required headers
  if ! grep -q "Plugin Name:" "$main_file"; then
    echo "❌ Missing 'Plugin Name:' header"
    ((errors++))
  fi

  if ! grep -q "Version:" "$main_file"; then
    echo "❌ Missing 'Version:' header"
    ((errors++))
  fi

  # Check for readme.txt
  local readme_paths=("readme.txt" "src/wordpress-plugin/readme.txt" "wordpress-plugin/readme.txt")
  local readme_found=false

  for readme in "${readme_paths[@]}"; do
    if [ -f "$readme" ]; then
      readme_found=true
      echo "✅ Found readme.txt at: $readme"
      break
    fi
  done

  if [ "$readme_found" = false ]; then
    echo "⚠️  readme.txt not found (recommended for WordPress.org)"
  fi

  # Report results
  if [ $errors -eq 0 ]; then
    echo "✅ Plugin structure validation passed"
    return 0
  else
    echo "❌ Plugin structure validation failed with $errors error(s)"
    return 1
  fi
}

# If script is executed directly (not sourced), run detection
if [ "${BASH_SOURCE[0]}" -ef "$0" ]; then
  case "${1:-}" in
    --slug)
      detect_plugin_slug "${2:-}"
      ;;
    --main-file)
      detect_main_plugin_file
      ;;
    --version)
      extract_plugin_version "${2:-}"
      ;;
    --name)
      extract_plugin_name "${2:-}"
      ;;
    --validate)
      validate_plugin_structure "${2:-}"
      ;;
    --all)
      MAIN_FILE=$(detect_main_plugin_file)
      SLUG=$(detect_plugin_slug "$MAIN_FILE")
      VERSION=$(extract_plugin_version "$MAIN_FILE")
      NAME=$(extract_plugin_name "$MAIN_FILE")

      echo "Plugin Detection Results:"
      echo "========================"
      echo "Plugin Name: $NAME"
      echo "Plugin Slug: $SLUG"
      echo "Main File: $MAIN_FILE"
      echo "Version: $VERSION"
      ;;
    *)
      echo "WordPress Plugin Detection Script"
      echo ""
      echo "Usage: $0 [option] [file]"
      echo ""
      echo "Options:"
      echo "  --slug [file]       Detect plugin slug"
      echo "  --main-file         Detect main plugin file"
      echo "  --version [file]    Extract version from plugin header"
      echo "  --name [file]       Extract plugin name from header"
      echo "  --validate [file]   Validate plugin structure"
      echo "  --all               Show all detected information"
      echo ""
      echo "Examples:"
      echo "  $0 --slug"
      echo "  $0 --main-file"
      echo "  $0 --version my-plugin.php"
      echo "  $0 --all"
      ;;
  esac
fi
