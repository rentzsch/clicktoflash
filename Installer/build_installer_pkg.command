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
	--info Info-nonadmin.plist \
	--scripts scripts \
	--target 10.4 \
	--version "$PRODUCT_VERSION" \
	--verbose \
	--out "$BUILT_PRODUCTS_DIR/ClickToFlash-nonadmin.pkg"

"$SYSTEM_DEVELOPER_UTILITIES_DIR/PackageMaker.app/Contents/MacOS/PackageMaker" \
	--root "$BUILT_PRODUCTS_DIR/ClickToFlash.dst" \
	--info Info-admin.plist \
	--scripts scripts \
	--target 10.4 \
	--version "$PRODUCT_VERSION" \
	--verbose \
	--out "$BUILT_PRODUCTS_DIR/ClickToFlash-admin.pkg"



# go into one of the packages and strip out the contents and symbolic link them to the other
# package so that we keep the file size down, since the only difference is requiring admin auth

cd "$BUILT_PRODUCTS_DIR/ClickToFlash-admin.pkg/Contents"
rm Archive.bom
rm Archive.pax.gz
ln -s ../../ClickToFlash-nonadmin.pkg/Contents/Archive.bom ./
ln -s ../../ClickToFlash-nonadmin.pkg/Contents/Archive.pax.gz ./
cd $SCRIPT_WD



# make the friggin' distribution ourselves since friggin' PackageMaker friggin' doesn't friggin' support this
mkdir "$BUILT_PRODUCTS_DIR/ClickToFlash.mpkg"
mkdir "$BUILT_PRODUCTS_DIR/ClickToFlash.mpkg/Contents"
mkdir "$BUILT_PRODUCTS_DIR/ClickToFlash.mpkg/Contents/Packages/"
mkdir "$BUILT_PRODUCTS_DIR/ClickToFlash.mpkg/Contents/Resources/"
cp -R distribution-mpkg/resources/en.lproj "$BUILT_PRODUCTS_DIR/ClickToFlash.mpkg/Contents/Resources/en.lproj"
cp -R distribution-mpkg/resources/admin_privs_needed.command "$BUILT_PRODUCTS_DIR/ClickToFlash.mpkg/Contents/Resources/admin_privs_needed.command"
cp -R distribution-mpkg/resources/no_admin_privs_needed.command "$BUILT_PRODUCTS_DIR/ClickToFlash.mpkg/Contents/Resources/no_admin_privs_needed.command"
cp distribution-mpkg/distribution.dist "$BUILT_PRODUCTS_DIR/ClickToFlash.mpkg/Contents/distribution.dist"

cp -R "$BUILT_PRODUCTS_DIR/ClickToFlash-nonadmin.pkg" "$BUILT_PRODUCTS_DIR/ClickToFlash.mpkg/Contents/Packages/ClickToFlash-nonadmin.pkg"
cp -R "$BUILT_PRODUCTS_DIR/ClickToFlash-admin.pkg" "$BUILT_PRODUCTS_DIR/ClickToFlash.mpkg/Contents/Packages/ClickToFlash-admin.pkg"


# clean up the non-mpkg pkgs

rm -rf "$BUILT_PRODUCTS_DIR/ClickToFlash-admin.pkg"
rm -rf "$BUILT_PRODUCTS_DIR/ClickToFlash-nonadmin.pkg"


# Stuff it into a .zip.
cd "$BUILT_PRODUCTS_DIR"
zip -r -y "$VERSIONED_NAME.zip" "ClickToFlash.mpkg"
cd $SCRIPT_WD

rm -rf "$MY_INSTALLER_ROOT"
