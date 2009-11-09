#!/bin/bash
cd "`dirname \"$0\"`"
SCRIPT_WD=`pwd`

if [ -z "$PROJECT_DIR" ]; then
	# Script invoked outside of Xcode, figure out environmental vars for ourself.
	PROJECT_DIR='..'
	BUILT_PRODUCTS_DIR="$PROJECT_DIR/build/Release"
	BUILD_STYLE='Release'
	BUILT_PLUGIN="$BUILT_PRODUCTS_DIR/ClickToFlash.webplugin"
	PRODUCT_VERSION=`/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$BUILT_PLUGIN/Contents/Info.plist"`
	SYSTEM_DEVELOPER_UTILITIES_DIR='/Developer/Applications/Utilities'
fi

if [ $BUILD_STYLE != "Release" ]; then
	echo "Could not generate package."
	echo "Active Configuration needs to be set to 'Release'."
	exit 1
fi

MY_INSTALLER_ROOT="$BUILT_PRODUCTS_DIR/ClickToFlash.dst"
BUILT_PLUGIN="$BUILT_PRODUCTS_DIR/ClickToFlash.webplugin"
BUILT_PKG="$BUILT_PRODUCTS_DIR/ClickToFlash.pkg" # Sparkle currently can't handle -$VERSION in .pkg names.
VERSIONED_NAME="ClickToFlash-$PRODUCT_VERSION"
BUILT_ZIP="$BUILT_PRODUCTS_DIR/$VERSIONED_NAME.zip"

# Delete old files if they're around.
if [ -d "$MY_INSTALLER_ROOT" ]; then
	rm -rf "$MY_INSTALLER_ROOT"
fi
if [ -d "$BUILT_PKG" ]; then
	rm -rf "$BUILT_PKG"
fi
if [ -f "$BUILT_ZIP" ]; then
	rm -rf "$BUILT_ZIP"
fi

# Create the .pkg.
mkdir "$MY_INSTALLER_ROOT"
cp -R "$BUILT_PLUGIN" "$MY_INSTALLER_ROOT"

"$SYSTEM_DEVELOPER_UTILITIES_DIR/PackageMaker.app/Contents/MacOS/PackageMaker" \
	--root "$BUILT_PRODUCTS_DIR/ClickToFlash.dst" \
	--no-relocate \
	--info Info.plist \
	--resources resources \
	--scripts scripts \
	--target 10.4 \
	--version "$PRODUCT_VERSION" \
	--verbose \
	--out "$BUILT_PKG"

# Stuff it into a .zip.
cd "$BUILT_PRODUCTS_DIR"
zip -r "$VERSIONED_NAME.zip" "ClickToFlash.pkg"

if [ -f "$HOME/Documents/releases/ClickToFlash/dsa_priv.pem" ]; then
	`openssl dgst -sha1 -binary < "$VERSIONED_NAME.zip" | openssl dgst -dss1 -sign "$HOME/Documents/releases/ClickToFlash/dsa_priv.pem" | openssl enc -base64 > $VERSIONED_NAME.dsaSignature`
fi
cd "$SCRIPT_WD"

rm -rf "$MY_INSTALLER_ROOT"
