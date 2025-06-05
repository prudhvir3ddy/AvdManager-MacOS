#!/bin/bash

# AVD Manager Release Build Script
# This script builds the app and creates a DMG for local testing

set -e  # Exit on any error

# Configuration
APP_NAME="avdmanager"
BUILD_DIR="build"
DMG_DIR="dmg-temp"
EXPORT_DIR="$BUILD_DIR/export"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if create-dmg is installed
check_dependencies() {
    print_status "Checking dependencies..."
    
    if ! command -v create-dmg &> /dev/null; then
        print_warning "create-dmg not found. Installing via Homebrew..."
        if command -v brew &> /dev/null; then
            brew install create-dmg
        else
            print_error "Homebrew not found. Please install create-dmg manually:"
            print_error "  brew install create-dmg"
            exit 1
        fi
    fi
    
    print_success "Dependencies check passed"
}

# Clean previous builds
clean_build() {
    print_status "Cleaning previous builds..."
    rm -rf "$BUILD_DIR"
    rm -rf "$DMG_DIR"
    rm -f *.dmg
    rm -f *.sha256
    print_success "Clean completed"
}

# Build the app
build_app() {
    print_status "Building AVD Manager..."
    
    xcodebuild -project avdmanager.xcodeproj \
               -scheme avdmanager \
               -configuration Release \
               -derivedDataPath "$BUILD_DIR/" \
               -archivePath "$BUILD_DIR/avdmanager.xcarchive" \
               archive
               
    print_success "Build completed successfully"
}

# Export the app
export_app() {
    print_status "Exporting app..."
    
    # Create export options plist
    cat > ExportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>thinning</key>
    <string>&lt;none&gt;</string>
</dict>
</plist>
EOF
    
    # Export the app
    xcodebuild -exportArchive \
               -archivePath "$BUILD_DIR/avdmanager.xcarchive" \
               -exportOptionsPlist ExportOptions.plist \
               -exportPath "$EXPORT_DIR/"
               
    # Clean up export options
    rm ExportOptions.plist
    
    print_success "Export completed"
}

# Create DMG
create_dmg() {
    print_status "Creating DMG..."
    
    # Create a temporary directory for DMG contents
    mkdir -p "$DMG_DIR"
    
          # Copy the app to the temp directory
      cp -R "$EXPORT_DIR/avdmanager.app" "$DMG_DIR/"
      
      # Create Applications symlink for USB cable installation
      ln -s /Applications "$DMG_DIR/Applications"
      
      # Using default DMG background
      print_status "Using default DMG background"
      
      # Get version from git or use timestamp
    if git describe --tags --exact-match HEAD 2>/dev/null; then
        VERSION=$(git describe --tags --exact-match HEAD | sed 's/^v//')
    else
        VERSION="dev-$(date +%Y%m%d-%H%M%S)"
    fi
    
    DMG_NAME="AVD-Manager-${VERSION}.dmg"
    
    print_status "Creating DMG: $DMG_NAME"
    
    create-dmg \
        --volname "AVD Manager" \
        --window-pos 200 120 \
        --window-size 600 360 \
        --icon-size 72 \
        --icon "avdmanager.app" 165 180 \
        --icon "Applications" 435 180 \
        --hide-extension "avdmanager.app" \
        --text-size 14 \
        --format ULFO \
        --filesystem HFS+ \
        --skip-jenkins \
        "$DMG_NAME" \
        "$DMG_DIR/"
      
    # Calculate checksum
    shasum -a 256 "$DMG_NAME" > "${DMG_NAME}.sha256"
    
    print_success "DMG created: $DMG_NAME"
    print_success "Checksum: $(cat ${DMG_NAME}.sha256)"
}

# Cleanup temporary files
cleanup() {
    print_status "Cleaning up temporary files..."
    rm -rf "$BUILD_DIR"
    rm -rf "$DMG_DIR"
    print_success "Cleanup completed"
}

# Show usage
show_usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -k, --keep     Keep build artifacts (don't cleanup)"
    echo "  -v, --version  Show version and exit"
    echo ""
    echo "This script builds AVD Manager and creates a DMG for distribution."
}

# Parse command line arguments
KEEP_ARTIFACTS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -k|--keep)
            KEEP_ARTIFACTS=true
            shift
            ;;
        -v|--version)
            if git describe --tags --exact-match HEAD 2>/dev/null; then
                echo "$(git describe --tags --exact-match HEAD)"
            else
                echo "dev-$(git rev-parse --short HEAD)"
            fi
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Main execution
main() {
    print_status "Starting AVD Manager release build..."
    
    # Change to script directory
    cd "$(dirname "$0")/.."
    
    check_dependencies
    clean_build
    build_app
    export_app
    create_dmg
    
    if [ "$KEEP_ARTIFACTS" = false ]; then
        cleanup
    else
        print_warning "Keeping build artifacts as requested"
    fi
    
    print_success "Release build completed successfully!"
    print_status "DMG file is ready for distribution."
}

# Run main function
main 