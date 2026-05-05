#!/bin/bash
# from https://gist.github.com/samapriya/412babdfd3530c2766acb9d603ed1bb9
set -e  # Exit on any error

echo "🌍 GDAL Latest Version Installer"
echo "=================================="

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "❌ This script should not be run as root directly."
   echo "   Run it as a regular user with sudo access."
   echo "   Usage: curl -sL [YOUR_URL] | bash"
   exit 1
fi

# Check if sudo is available
if ! command -v sudo &> /dev/null; then
    echo "❌ sudo is required but not installed."
    exit 1
fi

echo "🔍 Fetching latest GDAL version..."

# Parse the GDAL CURRENT page to get the latest version
GDAL_PAGE=$(curl -s https://download.osgeo.org/gdal/CURRENT/)
if [ $? -ne 0 ]; then
    echo "❌ Failed to fetch GDAL version page"
    exit 1
fi

# Extract the tar.gz filename using grep and sed
GDAL_TAR=$(echo "$GDAL_PAGE" | grep -o 'gdal-[0-9]\+\.[0-9]\+\.[0-9]\+\.tar\.gz' | head -1)

if [ -z "$GDAL_TAR" ]; then
    echo "❌ Could not find GDAL tar.gz file in the current directory"
    exit 1
fi

# Extract version number from filename
GDAL_VERSION=$(echo "$GDAL_TAR" | sed 's/gdal-\([0-9]\+\.[0-9]\+\.[0-9]\+\)\.tar\.gz/\1/')
GDAL_DIR="gdal-$GDAL_VERSION"
GDAL_URL="https://download.osgeo.org/gdal/CURRENT/$GDAL_TAR"

echo "✅ Found latest GDAL version: $GDAL_VERSION"
echo "📦 Download URL: $GDAL_URL"

# Remove existing GDAL if installed
echo "🗑️  Removing existing GDAL installation..."
sudo apt purge -y gdal-bin || true

# Update package list
echo "📦 Updating package list..."
sudo apt update

# Install build dependencies
echo "🔨 Installing build dependencies..."
sudo apt install -y build-essential cmake git
sudo apt install -y libproj-dev libgeos-dev libsqlite3-dev libcurl4-openssl-dev
sudo apt install -y libtiff5-dev libgeotiff-dev libpng-dev libjpeg-dev libgif-dev

# Create temporary directory for build
BUILD_DIR=$(mktemp -d)
cd "$BUILD_DIR"
echo "🏗️  Building in temporary directory: $BUILD_DIR"

# Download GDAL source
echo "⬇️  Downloading GDAL $GDAL_VERSION..."
wget "$GDAL_URL"

if [ ! -f "$GDAL_TAR" ]; then
    echo "❌ Failed to download $GDAL_TAR"
    exit 1
fi

# Extract source code
echo "📂 Extracting source code..."
tar -xzf "$GDAL_TAR"

# Verify extraction
if [ ! -d "$GDAL_DIR" ]; then
    echo "❌ Failed to extract GDAL source"
    exit 1
fi

# Check for ECW coordinate system file (optional verification)
if [ -f "$GDAL_DIR/ogr/data/ecw_cs.wkt" ]; then
    echo "✅ ECW coordinate system file found"
else
    echo "⚠️  ECW coordinate system file not found (this may be normal)"
fi

# Configure and build
echo "⚙️  Configuring build..."
cd "$GDAL_DIR"
mkdir build && cd build

echo "🔧 Running CMake configuration..."
cmake .. -DCMAKE_BUILD_TYPE=Release

echo "🔨 Building GDAL (this may take a while)..."
make -j$(nproc)

echo "📦 Installing GDAL..."
sudo make install

echo "🔗 Updating library cache..."
sudo ldconfig

# Cleanup
echo "🧹 Cleaning up temporary files..."
cd /
sudo rm -rf "$BUILD_DIR"

# Verify installation
echo "✅ Verifying installation..."
if command -v gdalinfo &> /dev/null; then
    INSTALLED_VERSION=$(gdalinfo --version | cut -d' ' -f2 | cut -d',' -f1)
    echo "🎉 GDAL successfully installed!"
    echo "   Version: $INSTALLED_VERSION"
    echo "   Location: $(which gdalinfo)"
else
    echo "❌ GDAL installation verification failed"
    exit 1
fi

echo ""
echo "🌟 Installation complete!"
echo "   You can now use both classic and modern GDAL commands:"
echo ""
echo "   📊 Get dataset info:"
echo "   - gdal raster info my.tif"
echo "   - gdal vector info my.gpkg"
echo ""
echo "   🔄 Convert and transform:"
echo "   - gdal raster convert --of COG input.tif output.tif"
echo "   - gdal vector convert --format GPKG input.shp output.gpkg"
echo ""
echo "   ✂️  Clip and process:"
echo "   - gdal raster clip --bbox 0,0,10,10 input.tif output.tif"
echo "   - gdal vector clip --bbox 0,0,10,10 input.gpkg output.gpkg"
echo ""
echo "   🚀 Try the new unified interface:"
echo "   - gdal --help"
echo "   - gdal raster --help"
echo "   - gdal vector --help"
echo ""
echo "   To verify everything works, try:"
echo "   gdal --version"
