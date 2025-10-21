#!/bin/bash
# Test script for WordPress.org SVN deployment
# Simulates the GitHub Actions workflow for deploying to WordPress SVN
# Does NOT actually commit to the SVN repository - safe for local testing

set -e

echo "=== Testing WordPress.org SVN Deployment ==="
echo "This script simulates the deployment process without committing to SVN."
echo

# Check for required tools
if ! command -v svn >/dev/null 2>&1; then
    echo "⚠️  SVN is not installed. Continuing in simulation mode only."
    SVN_INSTALLED=false
else
    SVN_INSTALLED=true
fi

command -v unzip >/dev/null 2>&1 || {
    echo "❌ Error: unzip is required but not installed."
    exit 1
}

# Get the current directory (project root is where this script is run from)
if [ -n "$PROJECT_ROOT" ]; then
    PROJECT_ROOT="$PROJECT_ROOT"
else
    PROJECT_ROOT="$(pwd)"
fi

echo "Project root: $PROJECT_ROOT"

# Auto-detect plugin using the detection script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/detect-plugin.sh"

MAIN_FILE=$(detect_main_plugin_file)
PLUGIN_SLUG=$(detect_plugin_slug "$MAIN_FILE")
VERSION=$(extract_plugin_version "$MAIN_FILE")

echo "✅ Detected plugin: $PLUGIN_SLUG"
echo "✅ Version: $VERSION"
echo "✅ Main file: $MAIN_FILE"
echo

# Determine ZIP path
if [ -n "$ZIP_PATH" ]; then
    ZIP_FILE="$PROJECT_ROOT/$ZIP_PATH"
else
    ZIP_FILE="$PROJECT_ROOT/dist/$PLUGIN_SLUG.zip"
fi

# Build the plugin if it doesn't exist
if [ ! -f "$ZIP_FILE" ]; then
    echo "Plugin ZIP not found at: $ZIP_FILE"

    if [ -f "$PROJECT_ROOT/package.json" ]; then
        echo "Building plugin with npm..."
        cd "$PROJECT_ROOT"
        npm run build
    else
        echo "❌ No build script found and ZIP doesn't exist."
        echo "Please build your plugin first or specify ZIP_PATH environment variable."
        exit 1
    fi
fi

if [ ! -f "$ZIP_FILE" ]; then
    echo "❌ ZIP file still not found after build: $ZIP_FILE"
    exit 1
fi

echo "✅ Using ZIP file: $ZIP_FILE"
echo

# Create a temporary directory
TMP_DIR="/tmp/svn-test-$PLUGIN_SLUG-$(date +%s)"
mkdir -p "$TMP_DIR"
echo "Created temporary directory: $TMP_DIR"

# Extract the plugin
echo "Extracting plugin..."
mkdir -p "$TMP_DIR/plugin"
unzip -q "$ZIP_FILE" -d "$TMP_DIR/plugin"

# Create SVN structure
echo "Creating SVN structure..."
mkdir -p "$TMP_DIR/svn/trunk"
mkdir -p "$TMP_DIR/svn/assets"
mkdir -p "$TMP_DIR/svn/tags/$VERSION"

# Copy plugin to trunk (handle both flat and nested structures)
echo "Copying files to trunk..."
if [ -d "$TMP_DIR/plugin/$PLUGIN_SLUG" ]; then
    # Nested structure (ZIP contains plugin folder)
    cp -R "$TMP_DIR/plugin/$PLUGIN_SLUG/"* "$TMP_DIR/svn/trunk/"
else
    # Flat structure (ZIP contains files directly)
    cp -R "$TMP_DIR/plugin/"* "$TMP_DIR/svn/trunk/"
fi

# Verify critical files
echo "Verifying plugin structure..."
ERRORS=0

if [ ! -f "$TMP_DIR/svn/trunk/$MAIN_FILE" ] && [ ! -f "$TMP_DIR/svn/trunk/$(basename "$MAIN_FILE")" ]; then
    echo "❌ Main plugin file not found in trunk"
    ((ERRORS++))
fi

if [ -f "$PROJECT_ROOT/composer.json" ]; then
    if [ ! -f "$TMP_DIR/svn/trunk/vendor/autoload.php" ]; then
        echo "⚠️  vendor/autoload.php not found (plugin may use Composer)"
    fi
fi

# Copy trunk to tag
echo "Copying trunk to tag/$VERSION..."
cp -R "$TMP_DIR/svn/trunk/"* "$TMP_DIR/svn/tags/$VERSION/"

# Copy assets
ASSETS_DIR="${ASSETS_DIRECTORY:-__assets__}"
if [ -d "$PROJECT_ROOT/$ASSETS_DIR" ]; then
    echo "Copying assets from $ASSETS_DIR..."
    cp -R "$PROJECT_ROOT/$ASSETS_DIR/"* "$TMP_DIR/svn/assets/"
    # Remove hidden files
    find "$TMP_DIR/svn/assets" -name ".DS_Store" -delete 2>/dev/null || true
    find "$TMP_DIR/svn/assets" -name ".*" -delete 2>/dev/null || true
else
    echo "⚠️  No assets directory found at: $PROJECT_ROOT/$ASSETS_DIR"
    echo "Assets are optional but recommended for WordPress.org"
fi

echo
echo "=== SVN Structure Created ==="
echo "Here's what would be sent to WordPress.org:"
echo

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TRUNK DIRECTORY:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ls -lah "$TMP_DIR/svn/trunk" | head -n 20
if [ $(ls -1 "$TMP_DIR/svn/trunk" | wc -l) -gt 19 ]; then
    echo "... ($(ls -1 "$TMP_DIR/svn/trunk" | wc -l) files total)"
fi

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TAG DIRECTORY (version $VERSION):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ls -lah "$TMP_DIR/svn/tags/$VERSION" | head -n 20
if [ $(ls -1 "$TMP_DIR/svn/tags/$VERSION" | wc -l) -gt 19 ]; then
    echo "... ($(ls -1 "$TMP_DIR/svn/tags/$VERSION" | wc -l) files total)"
fi

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ASSETS DIRECTORY:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -d "$TMP_DIR/svn/assets" ] && [ "$(ls -A "$TMP_DIR/svn/assets")" ]; then
    ls -lah "$TMP_DIR/svn/assets"
else
    echo "(empty)"
fi

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Plugin: $PLUGIN_SLUG"
echo "Version: $VERSION"
echo "Files prepared in: $TMP_DIR/svn"
echo

# Count files
TRUNK_FILES=$(find "$TMP_DIR/svn/trunk" -type f | wc -l)
TAG_FILES=$(find "$TMP_DIR/svn/tags/$VERSION" -type f | wc -l)
ASSET_FILES=$(find "$TMP_DIR/svn/assets" -type f 2>/dev/null | wc -l)

echo "Files in trunk: $TRUNK_FILES"
echo "Files in tag: $TAG_FILES"
echo "Asset files: $ASSET_FILES"

if [ $ERRORS -eq 0 ]; then
    echo
    echo "✅ Validation passed! Structure looks good."
else
    echo
    echo "⚠️  Found $ERRORS error(s) in structure."
fi

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$SVN_INSTALLED" = false ]; then
    echo
    echo "ℹ️  SVN is not installed - this was a structure-only simulation."
    echo
    echo "To install SVN:"
    echo "  macOS:        brew install subversion"
    echo "  Ubuntu/Debian: sudo apt-get install subversion"
    echo "  Windows:      https://tortoisesvn.net/"
else
    echo
    echo "✅ SVN is installed. You can inspect the structure:"
    echo "   cd $TMP_DIR/svn"
    echo "   svn status (would show what would be committed)"
fi

echo
echo "To view the complete structure:"
echo "  tree $TMP_DIR/svn  # If tree is installed"
echo "  find $TMP_DIR/svn -type f  # List all files"
echo
echo "To clean up temporary files:"
echo "  rm -rf $TMP_DIR"
echo

if [ $ERRORS -gt 0 ]; then
    exit 1
fi

exit 0
