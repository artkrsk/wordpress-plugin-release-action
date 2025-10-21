# WordPress Plugin Release Action

A robust, universal GitHub Actions workflow for automating WordPress plugin releases to GitHub and WordPress.org.

## Features

- ✅ **Smart Auto-Detection** - Automatically detects plugin slug, main file, and version
- ✅ **Flexible Configuration** - Override any default with custom inputs
- ✅ **Version Validation** - Ensures consistency across plugin header, readme.txt, and package.json
- ✅ **GitHub Releases** - Creates releases with auto-generated changelogs
- ✅ **WordPress.org Deployment** - Automated SVN deployment to WordPress.org repository
- ✅ **Asset Management** - Handles plugin assets (banners, icons, screenshots)
- ✅ **Build System Support** - Works with npm, composer-only, or custom build systems
- ✅ **ZIP Validation** - Verifies plugin structure and dependencies

## Quick Start

### 1. Create Release Workflow

Create `.github/workflows/release.yml` in your plugin repository:

```yaml
name: Release Plugin

on:
  push:
    tags:
      - "v*"

jobs:
  release:
    uses: artkrsk/wordpress-plugin-release-action/.github/workflows/release.yml@main
    secrets:
      SVN_USERNAME: ${{ secrets.SVN_USERNAME }}
      SVN_PASSWORD: ${{ secrets.SVN_PASSWORD }}
```

### 2. Add Secrets

Add your WordPress.org credentials to GitHub repository secrets:

- `SVN_USERNAME` - WordPress.org username
- `SVN_PASSWORD` - WordPress.org password

### 3. Create Release

```bash
# Ensure versions match in all files
# - Plugin header: Version: 1.2.3
# - readme.txt: Stable tag: 1.2.3
# - package.json: "version": "1.2.3"

git tag v1.2.3
git push origin v1.2.3
```

The workflow will:

- Build your plugin
- Validate structure and versions
- Create GitHub release with changelog
- Deploy to WordPress.org SVN

## How It Works

### Auto-Detection

The workflow automatically detects:

1. **Plugin Slug** - From main plugin file or directory name
2. **Main Plugin File** - Searches for file with `Plugin Name:` header
3. **Version** - Extracts from plugin header
4. **ZIP Path** - Uses standard `dist/{slug}.zip` pattern

### Jobs

1. **detect** - Identifies plugin metadata
2. **test** - Builds and validates plugin structure
3. **build_and_release** - Creates GitHub release
4. **deploy_to_wordpress** - Deploys to WordPress.org (optional)

## Configuration

### Basic Configuration

```yaml
jobs:
  release:
    uses: artkrsk/wordpress-plugin-release-action/.github/workflows/release.yml@main
    with:
      node_version: "23"
      build_command: "npm run build"
      assets_directory: "__assets__"
    secrets:
      SVN_USERNAME: ${{ secrets.SVN_USERNAME }}
      SVN_PASSWORD: ${{ secrets.SVN_PASSWORD }}
```

### All Options

#### Plugin Identification

| Input              | Description           | Default       |
| ------------------ | --------------------- | ------------- |
| `plugin_slug`      | Plugin slug           | Auto-detected |
| `main_plugin_file` | Main plugin file path | Auto-detected |

#### Build Configuration

| Input           | Description     | Default         |
| --------------- | --------------- | --------------- |
| `node_version`  | Node.js version | `23`            |
| `build_command` | Build command   | `npm run build` |
| `skip_build`    | Skip build step | `false`         |

#### Validation

| Input                     | Description                   | Default                                           |
| ------------------------- | ----------------------------- | ------------------------------------------------- |
| `test_command`            | Test command to run           | None                                              |
| `validate_zip_script`     | Path to ZIP validation script | None                                              |
| `skip_version_validation` | Skip version checks           | `false`                                           |
| `version_files`           | Files to check versions in    | `["plugin_header", "readme.txt", "package.json"]` |

#### Paths

| Input              | Description                                   | Default           |
| ------------------ | --------------------------------------------- | ----------------- |
| `zip_path`         | ZIP file path (supports `{slug}` placeholder) | `dist/{slug}.zip` |
| `assets_directory` | Assets directory for WordPress.org            | `__assets__`      |

#### WordPress.org Deployment

| Input                 | Description             | Default          |
| --------------------- | ----------------------- | ---------------- |
| `deploy_to_wordpress` | Deploy to WordPress.org | `true`           |
| `wordpress_svn_url`   | WordPress.org SVN URL   | Auto-constructed |

#### Changelog

| Input                       | Description                      | Default           |
| --------------------------- | -------------------------------- | ----------------- |
| `changelog_since_last_tag`  | Generate changelog from commits  | `true`            |
| `initial_release_changelog` | Custom initial release changelog | Standard template |

## Examples

### Minimal (Auto-Detection)

```yaml
jobs:
  release:
    uses: artkrsk/wordpress-plugin-release-action/.github/workflows/release.yml@main
    secrets:
      SVN_USERNAME: ${{ secrets.SVN_USERNAME }}
      SVN_PASSWORD: ${{ secrets.SVN_PASSWORD }}
```

### With Custom Build

```yaml
jobs:
  release:
    uses: artkrsk/wordpress-plugin-release-action/.github/workflows/release.yml@main
    with:
      build_command: "npm run production"
      validate_zip_script: "__tests__/validate.sh"
    secrets:
      SVN_USERNAME: ${{ secrets.SVN_USERNAME }}
      SVN_PASSWORD: ${{ secrets.SVN_PASSWORD }}
```

### Composer-Only Plugin

```yaml
jobs:
  release:
    uses: artkrsk/wordpress-plugin-release-action/.github/workflows/release.yml@main
    with:
      skip_build: true
      version_files: '["plugin_header", "readme.txt"]'
    secrets:
      SVN_USERNAME: ${{ secrets.SVN_USERNAME }}
      SVN_PASSWORD: ${{ secrets.SVN_PASSWORD }}
```

### GitHub Only (No WordPress.org)

```yaml
jobs:
  release:
    uses: artkrsk/wordpress-plugin-release-action/.github/workflows/release.yml@main
    with:
      deploy_to_wordpress: false
```

## Plugin Structure Requirements

### Minimum Requirements

Your plugin must have:

1. **Main plugin file** with standard WordPress headers:

   ```php
   /**
    * Plugin Name: My Awesome Plugin
    * Version: 1.0.0
    * ...
    */
   ```

2. **readme.txt** (recommended for WordPress.org):
   ```
   === My Awesome Plugin ===
   Stable tag: 1.0.0
   ```

### Supported Structures

The workflow supports various plugin structures:

#### Standard Structure

```
my-plugin/
├── my-plugin.php          # Main file (auto-detected)
├── readme.txt
├── includes/
└── assets/
```

#### Framework Structure

```
my-plugin/
├── src/
│   ├── php/
│   └── wordpress-plugin/
│       ├── my-plugin.php  # Main file (auto-detected)
│       └── readme.txt
├── package.json
└── __assets__/
```

#### Subdirectory Structure

```
my-plugin/
└── plugin-name/
    ├── plugin-name.php    # Main file (auto-detected)
    ├── readme.txt
    └── includes/
```

## Asset Management

### Local Assets

Place WordPress.org assets in your assets directory (default: `__assets__/`):

```
__assets__/
├── banner-772x250.png
├── banner-1544x500.png
├── icon-128x128.png
├── icon-256x256.png
├── screenshot-1.png
└── screenshot-2.png
```

### Asset Preservation

If assets directory is missing, the workflow will:

1. Attempt to download existing assets from WordPress.org
2. Preserve them in the SVN repository
3. Warn if no assets are found

## Version Validation

The workflow checks version consistency across:

- **Plugin Header** - `Version: 1.2.3`
- **readme.txt** - `Stable tag: 1.2.3`
- **package.json** - `"version": "1.2.3"`
- **Git Tag** - `v1.2.3`

Customize checked files:

```yaml
with:
  version_files: '["plugin_header", "readme.txt"]' # Skip package.json
```

## Changelog Generation

### Automatic Generation

By default, changelogs are generated from git commits:

```
## What's Changed Since v1.0.0

* feat: Add new feature X
* fix: Resolve bug in Y
* docs: Update documentation
```

### Custom Initial Release

```yaml
with:
  initial_release_changelog: |
    ## 🚀 Features
    * Feature 1
    * Feature 2

    ## 🐛 Bug Fixes
    * Fix 1
```

## Testing Locally

### Auto-Detection Testing

Use the detection script to test auto-detection:

```bash
# Test in your plugin directory
cd my-plugin/

# Detect all metadata
bash /path/to/detect-plugin.sh --all

# Test specific detection
bash /path/to/detect-plugin.sh --slug
bash /path/to/detect-plugin.sh --main-file
bash /path/to/detect-plugin.sh --version
```

### SVN Deployment Simulation

**Test your WordPress.org deployment locally before pushing to production:**

The `test-svn-deploy.sh` script simulates the entire SVN deployment process without actually committing to WordPress.org. This is invaluable for catching issues early.

```bash
# Run from your plugin directory
cd my-plugin/

# Test with default detection
bash /path/to/wordpress-plugin-release-action/scripts/test-svn-deploy.sh

# Test with custom ZIP path
ZIP_PATH="build/my-plugin.zip" bash /path/to/test-svn-deploy.sh

# Test with custom assets directory
ASSETS_DIRECTORY="assets" bash /path/to/test-svn-deploy.sh
```

The script will:

1. Auto-detect your plugin slug, version, and main file
2. Build the plugin if needed (runs `npm run build`)
3. Extract the ZIP and create SVN structure (trunk, tags, assets)
4. Validate the structure for common issues
5. Show you exactly what would be deployed

**Output includes:**

- File counts for trunk, tag, and assets
- Listing of all files that would be committed
- Validation of critical files (main plugin file, vendor directory)
- Warnings for missing assets or structure issues

**Benefits:**

- ✅ Catch missing files before deploying to production
- ✅ Verify vendor dependencies are included
- ✅ Check asset files are properly formatted
- ✅ Test build process locally
- ✅ No risk of breaking WordPress.org repository

**Example output:**

```
✅ Detected plugin: my-awesome-plugin
✅ Version: 1.2.3
✅ Main file: my-awesome-plugin.php

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TRUNK DIRECTORY:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
total 48
drwxr-xr-x  12 user  staff   384 Oct 17 14:30 .
drwxr-xr-x   5 user  staff   160 Oct 17 14:30 ..
-rw-r--r--   1 user  staff  1234 Oct 17 14:30 my-awesome-plugin.php
-rw-r--r--   1 user  staff  5678 Oct 17 14:30 readme.txt
drwxr-xr-x   8 user  staff   256 Oct 17 14:30 includes
drwxr-xr-x  45 user  staff  1440 Oct 17 14:30 vendor

✅ Validation passed! Structure looks good.

Files in trunk: 123
Files in tag: 123
Asset files: 5
```

## Troubleshooting

### "Could not detect main plugin file"

**Solution:** Ensure your main PHP file has the `Plugin Name:` header.

### "Version mismatch detected"

**Solution:** Ensure versions match in:

- Plugin header: `Version: 1.2.3`
- readme.txt: `Stable tag: 1.2.3`
- package.json: `"version": "1.2.3"`
- Git tag: `v1.2.3`

### "ZIP file not found"

**Solution:** Check your build command generates a ZIP at the expected path:

```yaml
with:
  zip_path: "dist/my-custom-plugin.zip" # Match your build output
```

### "vendor/autoload.php missing"

**Solution:** Ensure your build process includes Composer dependencies:

```bash
composer install --no-dev
```

## Advanced Usage

### Custom Validation

Create a custom validation script:

```bash
# __tests__/validate.sh
#!/bin/bash
set -e

ZIP_FILE="${ZIP_PATH}"

echo "Validating plugin structure..."

# Check for required files
unzip -l "$ZIP_FILE" | grep -q "vendor/autoload.php" || {
  echo "ERROR: Missing vendor/autoload.php"
  exit 1
}

echo "✅ Validation passed"
```

Use in workflow:

```yaml
with:
  validate_zip_script: "__tests__/validate.sh"
```

### Multiple Build Steps

```yaml
with:
  build_command: "npm install && composer install --no-dev && npm run build"
```

### Conditional WordPress.org Deployment

```yaml
with:
  deploy_to_wordpress: ${{ !contains(github.ref, 'beta') }} # Skip beta releases
```

## Security

### Secrets Management

Never commit credentials! Always use GitHub Secrets:

1. Go to repository **Settings → Secrets and variables → Actions**
2. Add `SVN_USERNAME` and `SVN_PASSWORD`
3. Reference in workflow: `${{ secrets.SVN_USERNAME }}`

### Credential Exposure

The workflow uses:

- `--non-interactive` flag for SVN
- `--trust-server-cert` for HTTPS
- Masked secrets in logs

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Test with a sample plugin
4. Submit a pull request

## License

MIT License - see LICENSE file for details

## Support

- **Issues**: [GitHub Issues](https://github.com/artkrsk/wordpress-plugin-release-action/issues)
- **Discussions**: [GitHub Discussions](https://github.com/artkrsk/wordpress-plugin-release-action/discussions)

## Credits

Based on WordPress plugin development best practices and GitHub Actions workflows used by the WordPress community.
