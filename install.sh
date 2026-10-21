#!/usr/bin/env bash
# kali-rice installer: GNOME neon-professional theme with Fastfetch
# Usage: ./install.sh   (run as your normal user, not root)
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="$HOME/.config"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "==> Updating package lists and installing GNOME + tools"
sudo apt update
sudo apt install -y \
    kali-desktop-gnome \
    gnome-shell-extension-dashtodock \
    gnome-tweaks \
    kitty \
    papirus-icon-theme \
    imagemagick \
    git \
    wget \
    unzip \
    fontconfig \
    fastfetch

# Install Starship prompt (tries apt first, falls back to official installer script)
if ! command -v starship &>/dev/null; then
    echo "==> Installing Starship prompt"
    sudo apt install -y starship || curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

echo "==> Installing Nerd Font (JetBrainsMono)"
mkdir -p "$HOME/.local/share/fonts/JetBrainsMonoNF"
wget -q -O "$WORK/jb.zip" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
unzip -oq "$WORK/jb.zip" -d "$HOME/.local/share/fonts/JetBrainsMonoNF"
fc-cache -f -v

echo "==> Installing Orchis GTK theme"
git clone --depth 1 https://github.com/vinceliuice/Orchis-theme "$WORK/orchis"
(cd "$WORK/orchis" && ./install.sh -c dark -t teal --tweaks black)

echo "==> Applying Papirus cyan folders"
if command -v papirus-folders &>/dev/null; then
    papirus-folders -C cyan --theme Papirus-Dark || true
else
    wget -qO- https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-folders/master/install.sh | sh
    papirus-folders -C cyan --theme Papirus-Dark || true
fi

echo "==> Linking configurations"
mkdir -p "$CFG/kitty"

# Link config files if they exist in repo
[[ -f "$REPO_DIR/config/kitty/kitty.conf" ]] && ln -sf "$REPO_DIR/config/kitty/kitty.conf" "$CFG/kitty/kitty.conf"
[[ -f "$REPO_DIR/config/starship.toml" ]]    && ln -sf "$REPO_DIR/config/starship.toml"     "$CFG/starship.toml"

echo "==> Configuring Shell (Starship Prompt & Fastfetch Sysinfo)"
for RC_FILE in "$HOME/.zshrc" "$HOME/.bashrc"; do
    if [[ -f "$RC_FILE" ]]; then
        # Enable starship prompt
        grep -q 'starship init' "$RC_FILE" 2>/dev/null || echo 'eval "$(starship init $(basename $SHELL))"' >> "$RC_FILE"
        # Enable fastfetch ASCII display on terminal open
        grep -q 'fastfetch' "$RC_FILE" 2>/dev/null || echo '[ -t 1 ] && fastfetch' >> "$RC_FILE"
    fi
done

echo "==> Generating neon wallpaper"
mkdir -p "$HOME/Pictures"
WALL="$HOME/Pictures/neon-wall.png"
convert -size 2560x1440 radial-gradient:'#0f2a3a-#0b0e14' "$WALL"

echo "==> Applying GNOME settings (dconf/gsettings)"
# Set GNOME color scheme to dark mode & apply Orchis GTK / Papirus icons
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || true
gsettings set org.gnome.desktop.interface gtk-theme 'Orchis-Teal-Dark' || true
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' || true
gsettings set org.gnome.desktop.wm.preferences theme 'Orchis-Teal-Dark' || true

# Set custom font
gsettings set org.gnome.desktop.interface font-name 'JetBrainsMono Nerd Font 10' || true
gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font Mono 10' || true

# Set wallpaper
WALL_URI="file://$WALL"
gsettings set org.gnome.desktop.background picture-uri "$WALL_URI" || true
gsettings set org.gnome.desktop.background picture-uri-dark "$WALL_URI" || true
gsettings set org.gnome.desktop.background picture-options 'zoom' || true

# Enable Dash to Dock extension if available
if command -v gnome-extensions &>/dev/null; then
    gnome-extensions enable dash-to-dock@micxgx.gmail.com 2>/dev/null || true
fi

echo "==> Setting default X session to GNOME"
sudo update-alternatives --set x-session-manager /usr/bin/gnome-session || true

echo
echo "=========================================================="
echo "Installation complete!"
echo "1. Reboot your system to log into GNOME:"
echo "   sudo reboot"
echo "2. Optional: Set Kitty as default terminal:"
echo "   sudo update-alternatives --config x-terminal-emulator"
echo "=========================================================="
