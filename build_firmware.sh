#!/bin/bash

#=====================================================================================
# Description:   Build OpenWrt and ImmortalWrt with Image Builder
# Instructions:  https://openwrt.org/docs/guide-user/additional-software/imagebuilder
# Download from: https://downloads.openwrt.org/releases
#                https://downloads.immortalwrt.org/releases
#=====================================================================================

# Default values
export TARGET="Orange Pi Zero 3"
export RELEASE_BRANCH="openwrt:snapshots"
export TUNNEL="all"
export CLEAN="true"
export SQUASHFS="false"
export UPDATE="false"
export REMOVE="false"

# For local build
export GITHUB_WORKSPACE="$PWD"

# Function to display usage instructions
usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -t, --target            Set the target device (default: $TARGET)"
    echo "  -r, --release-branch    Set the release branch (default: $RELEASE_BRANCH)"
    echo "  -n, --tunnel            Set the tunnel (default: $TUNNEL)"
    echo "  -c, --clean             Clean build (true/false, default: $CLEAN)"
    echo "  -s, --squashfs          Generate SquashFS image (true/false, default: $SQUASHFS)"
    echo "  -u, --update            Update the script (true/false, default: $UPDATE)"
    echo " -rm, --remove            Remove cache (true/false, default: $REMOVE)"
    echo "  -h, --help              Display this help message"
    exit 1
}

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -t|--target) export TARGET="$2"; shift ;;
        -r|--release-branch) export RELEASE_BRANCH="$2"; shift ;;
        -n|--tunnel) export TUNNEL="$2"; shift ;;
        -c|--clean) export CLEAN="$2"; shift ;;
        -s|--squashfs) export SQUASHFS="$2"; shift ;;
        -u|--update) export UPDATE="$2"; shift ;;
        -rm|--remove) export REMOVE="$2"; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
    shift
done

echo "Building firmware for target: $TARGET"
echo "Using release branch: $RELEASE_BRANCH"
echo "Tunnel setting: $TUNNEL"
echo "Clean build: $CLEAN"
echo "Generate SquashFS image: $SQUASHFS"

# Environment variables
export TZ="Asia/Jakarta"
echo "Time Zone: $TZ"

export DATE=$(date +'%Y%m%d')
echo "Date: $DATE"

export DATETIME=$(date +'%Y.%m.%d-%H:%M:%S')
echo "Date and Time: $DATETIME"

export DATEMONTH=$(date +"%B-%Y" | awk '{print tolower($0)}')
echo "Date Month: $DATEMONTH"

export WORKING_DIR="${RELEASE_BRANCH%:*}-imagebuilder-$(echo $TARGET | tr ' ' '-').Linux-x86_64"
echo "Working Directory: $WORKING_DIR"

export DOWNLOAD_BASE="https://downloads.${RELEASE_BRANCH%:*}.org"
echo "Download Base: $DOWNLOAD_BASE"

export BASE=${RELEASE_BRANCH%:*}
echo "Base: $BASE"

export BRANCH=${RELEASE_BRANCH#*:}
echo "Branch: $BRANCH"

# Give space for readability
echo ""

logger() {
  printf "\033[33;4m$1\033[0m\n"
}

# Set target-specific variables
case $TARGET in
    "Raspberry Pi 3B")
        export PROFILE="rpi-3"
        echo "Profile: $PROFILE"
        ;;
esac

# Set target-specific variables
case $TARGET in
    "Raspberry Pi 3B")
        export PROFILE="rpi-3"
        export TARGET_SYSTEM="bcm27xx/bcm2710"
        export TARGET_NAME="bcm27xx-bcm2710"
        export ARCH_1="armv7"
        export ARCH_2="aarch64"
        export ARCH_3="aarch64_cortex-a53"
        ;;
    "Raspberry Pi 4B")
        export PROFILE="rpi-4"
        export TARGET_SYSTEM="bcm27xx/bcm2711"
        export TARGET_NAME="bcm27xx-bcm2711"
        export ARCH_1="arm64"
        export ARCH_2="aarch64"
        export ARCH_3="aarch64_cortex-a72"
        ;;
    "NanoPi-R2S")
        export PROFILE="friendlyarm_nanopi-r2s"
        export TARGET_SYSTEM="rockchip/armv8"
        export TARGET_NAME="rockchip-armv8"
        export ARCH_1="armv8"
        export ARCH_2="aarch64"
        export ARCH_3="aarch64_generic"
        ;;
    "NanoPi-R5S")
        export PROFILE="friendlyarm_nanopi-r5s"
        export TARGET_SYSTEM="rockchip/armv8"
        export TARGET_NAME="rockchip-armv8"
        export ARCH_1="armv8"
        export ARCH_2="aarch64"
        export ARCH_3="aarch64_generic"
        ;;
    "Orange Pi Zero 3")
        export PROFILE="xunlong_orangepi-zero3"
        export TARGET_SYSTEM="sunxi/cortexa53"
        export TARGET_NAME="sunxi-cortexa53"
        export ARCH_1="armv8"
        export ARCH_2="aarch64"
        export ARCH_3="aarch64_generic"
        ;;
    "x86-64")
        export PROFILE="generic"
        export TARGET_SYSTEM="x86/64"
        export TARGET_NAME="x86-64"
        export ARCH_1="amd64"
        export ARCH_2="x86_64"
        export ARCH_3="x86_64"
        ;;
    *)
        echo "Unknown target: $TARGET"
        exit 1
        ;;
esac

# Set timezone
sudo timedatectl set-timezone "$TZ"

# Install dependencies
if [ "$UPDATE" == "true" ]; then
  sudo apt-get update -y
  sudo apt-get install -y build-essential libncurses5-dev libncursesw5-dev zlib1g-dev gawk git gettext libssl-dev xsltproc rsync wget unzip tar gzip qemu-utils mkisofs zstd python3-distutils
fi

# Download Image Builder
if [ "$BRANCH" == "snapshots" ]; then
  BASE_URL="$DOWNLOAD_BASE/$BRANCH/targets/$TARGET_SYSTEM"
  FILE_NAME="$BASE-imagebuilder-$TARGET_NAME.Linux-x86_64.tar.zst"
else
  BASE_URL="$DOWNLOAD_BASE/releases/$BRANCH/targets/$TARGET_SYSTEM"
  FILE_NAME="$BASE-imagebuilder-$BRANCH-$TARGET_NAME.Linux-x86_64.tar.xz"
fi

# Download the file if it doesn't exist
if [ -f "$FILE_NAME" ]; then
  logger "Using existing file: $FILE_NAME"
else
  logger "Downloading file: $FILE_NAME"
  DOWNLOAD_URL="$BASE_URL/$FILE_NAME"
  wget -nv "$DOWNLOAD_URL" -O "$FILE_NAME" || { echo "Error downloading file"; exit 1; }
fi

# Verify the checksum
logger "\nVerifying checksum for Image Builder"
CHECKSUM_URL="$BASE_URL/sha256sums"
wget -nv "$CHECKSUM_URL" -O "sha256sums" || { echo "Error downloading checksum file"; exit 1; }
sha256sum "${FILE_NAME}" || { echo "Checksum verification failed"; exit 1; }
[ "$REMOVE" == "true" ] && rm -f sha256sums

# Extract the file
mkdir -p tmp
if [[ "$FILE_NAME" == *.zst ]]; then
  tar --use-compress-program=zstd -xf "$FILE_NAME" -C tmp/ || { echo "Error extracting file"; exit 1; }
else
  tar -xJf "$FILE_NAME" -C tmp/ || { echo "Error extracting file"; exit 1; }
fi

mkdir -p "$WORKING_DIR"
cp -rf tmp/*-imagebuilder-*/* "./$WORKING_DIR"
cp -rf tmp/*-imagebuilder-*/.[^.]* "./$WORKING_DIR"

[ "$REMOVE" == "true" ] && rm --rf tmp && rm -rf $FILE_NAME

# Copy the custom files
logger "\nCopying custom files to working directory"
cp make-build.sh $WORKING_DIR
cp external-package-urls.txt $WORKING_DIR
cp -r scripts $WORKING_DIR
cp -r packages $WORKING_DIR
cp -r files $WORKING_DIR

# Run custom scripts
cd $WORKING_DIR
logger "\nRunning external-package-urls.sh\n" && bash scripts/external-package-urls.sh
logger "\nRunning builder-patch.sh\n" && bash scripts/builder-patch.sh
logger "\nRunning agh-core.sh\n" && bash scripts/agh-core.sh
logger "\nRunning misc.sh\n" && bash scripts/misc.sh

# Compile firmware
logger "\nCompiling firmware\n"
mkdir -p compiled_images
if [[ "$TUNNEL" == "all" && "$BRANCH" != "21.02.7" ]]; then
    for t in openclash-passwall neko-passwall neko-openclash openclash-passwall-neko openclash passwall neko no-tunnel; do
        [ "$CLEAN" == "true" ] && make clean
        bash make-build.sh $PROFILE $t
        mv bin/targets/"$TARGET_SYSTEM"/*-"$TARGET_NAME"-*.img.gz compiled_images/fri_${PROFILE}_$t_$DATE.img.gz
    done
else
    [ "$CLEAN" == "true" ] && make clean
    bash make-build.sh $PROFILE $TUNNEL
    mv bin/targets/"$TARGET_SYSTEM"/*-"$TARGET_NAME"-*.img.gz compiled_images/fri_${PROFILE}_$TUNNEL_$DATE.img.gz
fi

# Generate checksum
logger "\nGenerating checksum\n"
sha256sum compiled_images/*.img.gz > compiled_images/sha256sums

# Display compilation details
logger "\nFirmware compilation completed successfully for target: $TARGET"
logger "\nStored in: $WORKING_DIR/compiled_images/"
logger "\nTotal custom packages: $(find packages -type f -name "*.ipk" | wc -l)"
ls -l compiled_images
