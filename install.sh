#!/usr/bin/env bash
# kali-rice installer: XFCE neon-professional theme
# Usage: ./install.sh   (run as your normal user, not root)
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="$HOME/.config"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "==> Installing packages"
sudo apt update
sudo apt install -y spice-vdagent kitty picom plank papirus-icon-theme \
  imagemagick git wget unzip fontconfig xfconf
sudo apt install -y starship || curl -sS https://starship.rs/install.sh | sh -s -- -y

echo "==> Nerd Font (JetBrainsMono)"
mkdir -p "$HOME/.local/share/fonts"
wget -q -O "$WORK/jb.zip" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
unzip -oq "$WORK/jb.zip" -d "$HOME/.local/share/fonts/JetBrainsMonoNF"
fc-cache -f

echo "==> Orchis GTK theme"
git clone --depth 1 https://github.com/vinceliuice/Orchis-theme "$WORK/orchis"
(cd "$WORK/orchis" && ./install.sh -c dark -t teal --tweaks black)

echo "==> Papirus cyan folders"
wget -qO- https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-folders/master/install.sh | sh
papirus-folders -C cyan --theme Papirus-Dark || true

echo "==> Linking configs"
mkdir -p "$CFG/kitty" "$CFG/picom"
ln -sf "$REPO_DIR/config/kitty/kitty.conf"   "$CFG/kitty/kitty.conf"
ln -sf "$REPO_DIR/config/picom/picom.conf"   "$CFG/picom/picom.conf"
ln -sf "$REPO_DIR/config/starship.toml"      "$CFG/starship.toml"

echo "==> Shell prompt (zsh)"
grep -q 'starship init zsh' "$HOME/.zshrc" 2>/dev/null || \
  echo 'eval "$(starship init zsh)"' >> "$HOME/.zshrc"

echo "==> Wallpaper"
mkdir -p "$HOME/Pictures"
WALL="$HOME/Pictures/neon-wall.png"
convert -size 2560x1440 radial-gradient:'#0f2a3a-#0b0e14' "$WALL"

echo "==> Autostart (picom, plank)"
mkdir -p "$CFG/autostart"
cat > "$CFG/autostart/picom.desktop" <<'EOD'
[Desktop Entry]
Type=Application
Name=picom
Exec=picom --config %h/.config/picom/picom.conf
EOD
cat > "$CFG/autostart/plank.desktop" <<'EOD'
[Desktop Entry]
Type=Application
Name=plank
Exec=plank
EOD

echo "==> Applying XFCE settings"
xfconf-query -c xsettings -p /Net/ThemeName     -s "Orchis-Teal-Dark" || xfconf-query -c xsettings -p /Net/ThemeName -s "Orchis-Dark" || true
xfconf-query -c xsettings -p /Net/IconThemeName -s "Papirus-Dark"
xfconf-query -c xfwm4 -p /general/theme -s "Orchis-Teal-Dark" || true
xfconf-query -c xfwm4 -p /general/use_compositing -s false   # picom takes over
xfconf-query -c xfce4-desktop -l | grep last-image | while read -r p; do
  xfconf-query -c xfce4-desktop -p "$p" -s "$WALL"
done

echo
echo "Done. Log out and back in (or reboot) to apply everything."
echo "Optional: make kitty your default terminal ->"
echo "  sudo update-alternatives --config x-terminal-emulator"
