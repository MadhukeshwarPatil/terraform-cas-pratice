#!/bin/bash

# Script to create jose Lambda Layer for JWT verification

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAYER_DIR="${SCRIPT_DIR}/jose-layer-build"
ZIP_FILE="${SCRIPT_DIR}/jose-layer.zip"

echo "Creating jose Lambda Layer..."

# Clean up previous build
rm -rf "${LAYER_DIR}"
rm -f "${ZIP_FILE}"

# Create layer structure
mkdir -p "${LAYER_DIR}/nodejs"
cd "${LAYER_DIR}/nodejs"

# Initialize package.json
cat > package.json <<EOF
{
  "name": "jose-layer",
  "version": "1.0.0",
  "description": "Jose library for JWT verification in Lambda",
  "dependencies": {
    "jose": "^5.2.0",
    "@aws-sdk/client-cognito-identity-provider": "^3.0.0"
  }
}
EOF

# Install dependencies
echo "Installing npm packages..."
npm install --production

# Create zip file with correct Lambda Layer structure
cd "${LAYER_DIR}"
zip -r "${ZIP_FILE}" nodejs/

# Cleanup
cd "${SCRIPT_DIR}"
rm -rf "${LAYER_DIR}"

echo "✓ Lambda Layer created: ${ZIP_FILE}"
echo "  Size: $(du -h "${ZIP_FILE}" | cut -f1)"
