#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="/usr/share/sddm/themes/ultrakill-sddm"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=============================="
echo " ULTRAKILL SDDM Theme Installer"
echo "=============================="

if [[ $EUID -ne 0 ]]; then
    echo ":: This script must be run as root (sudo)."
    exec sudo "$0" "$@"
fi

echo ""
echo ":: Installing dependencies..."
pacman -S --needed --noconfirm \
    sddm \
    qt5-base \
    qt5-declarative \
    qt5-quickcontrols2 \
    qt5-multimedia \
    gst-plugins-good \
    gst-libav

if command -v yay &>/dev/null; then
    echo ":: Installing VCR OSD Mono font via yay..."
    su "$SUDO_USER" -c "yay -S --noconfirm ttf-vcr-osd-mono" 2>/dev/null || true
elif command -v paru &>/dev/null; then
    echo ":: Installing VCR OSD Mono font via paru..."
    su "$SUDO_USER" -c "paru -S --noconfirm ttf-vcr-osd-mono" 2>/dev/null || true
fi

if ! fc-list | grep -qi "VCR OSD Mono"; then
    echo ":: Font not installed via AUR. Downloading manually..."
    mkdir -p /tmp/vcr-font
    cd /tmp/vcr-font
    curl -sL "https://github.com/coryarcangel/Cory-Arcangel---Save/raw/master/VCR%20OSD%20Mono/VCR_OSD_MONO_1.001.ttf" -o vcr.ttf
    install -Dm644 vcr.ttf /usr/share/fonts/TTF/VCR_OSD_MONO_1.001.ttf
    fc-cache -f
    rm -rf /tmp/vcr-font
    cd "$SCRIPT_DIR"
fi

echo ""
echo ":: Installing theme files..."
install -d "$INSTALL_DIR"
install -m644 "$SCRIPT_DIR/Main.qml"        "$INSTALL_DIR/Main.qml"
install -m644 "$SCRIPT_DIR/theme.conf"      "$INSTALL_DIR/theme.conf"
install -m644 "$SCRIPT_DIR/metadata.desktop" "$INSTALL_DIR/metadata.desktop"
install -m644 "$SCRIPT_DIR/logo.png"        "$INSTALL_DIR/logo.png"
install -m644 "$SCRIPT_DIR/bg.mp4"          "$INSTALL_DIR/bg.mp4"

echo ""
echo ":: Configuring SDDM..."
SDDM_CONF="/etc/sddm.conf"
if [[ -f "$SDDM_CONF" ]]; then
    if grep -q "^Current=" "$SDDM_CONF"; then
        sed -i "s|^Current=.*|Current=ultrakill-sddm|" "$SDDM_CONF"
    else
        if grep -q "\[Theme\]" "$SDDM_CONF"; then
            sed -i "/\[Theme\]/a Current=ultrakill-sddm" "$SDDM_CONF"
        else
            echo -e "\n[Theme]\nCurrent=ultrakill-sddm" >> "$SDDM_CONF"
        fi
    fi
else
    echo -e "[Theme]\nCurrent=ultrakill-sddm" > "$SDDM_CONF"
fi

echo ""
echo ":: Enabling SDDM..."
systemctl enable sddm 2>/dev/null || true

echo ""
echo "=============================="
echo " Installation complete!"
echo "=============================="
echo ""
echo "To apply now, restart SDDM:"
echo "  sudo systemctl restart sddm"
echo ""
