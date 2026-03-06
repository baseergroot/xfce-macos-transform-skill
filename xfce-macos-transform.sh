#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# =====================================================================
# XFCE -> macOS (Sonoma/Ventura) Transformation Script
# Summary of changes:
# - Installs and applies WhiteSur GTK and XFWM4 themes (light/macOS style)
# - Installs and applies WhiteSur icon theme
# - Installs and applies a macOS-like cursor theme
# - Replaces bottom taskbar with Plank dock and configures autostart
# - Configures a top panel as macOS-style menu bar with global menu support
# - Downloads and applies a macOS wallpaper (fallback to Unsplash)
# - Installs Inter font and applies font and antialiasing settings
# - Enables compositor, shadows, and window behavior tweaks in XFWM4
# - Installs and configures Rofi with a Spotlight-style theme and keybinding
# - Cleans desktop icons and minimizes desktop clutter
# - Backs up current XFCE config to ~/.config/xfce4-backup-YYYYMMDD-HHMMSS
# =====================================================================

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[INFO]${NC} $*"; }
ok() { echo -e "${GREEN}[OK]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
err() { echo -e "${RED}[ERROR]${NC} $*"; }

trap 'err "Script failed on line $LINENO"' ERR

if [[ -z "${HOME:-}" ]]; then
  err "HOME is not set. Aborting."
  exit 1
fi

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
  else
    err "This script requires root privileges for package installs. Install sudo or run as root."
    exit 1
  fi
else
  SUDO=""
fi

APT_UPDATED=0
apt_update_once() {
  if [[ "$APT_UPDATED" -eq 0 ]]; then
    log "Updating apt package lists..."
    $SUDO apt-get update -y
    APT_UPDATED=1
  fi
}

apt_install() {
  local pkgs=()
  local missing=()
  pkgs=("$@")
  for p in "${pkgs[@]}"; do
    if ! dpkg -s "$p" >/dev/null 2>&1; then
      missing+=("$p")
    fi
  done
  if [[ "${#missing[@]}" -gt 0 ]]; then
    apt_update_once
    log "Installing packages: ${missing[*]}"
    $SUDO apt-get install -y "${missing[@]}"
  fi
}

apt_install_optional() {
  local pkgs=("$@")
  local to_install=()
  for p in "${pkgs[@]}"; do
    if dpkg -s "$p" >/dev/null 2>&1; then
      continue
    fi
    if apt-cache show "$p" >/dev/null 2>&1; then
      to_install+=("$p")
    else
      warn "Optional package not available in apt: $p"
    fi
  done
  if [[ "${#to_install[@]}" -gt 0 ]]; then
    apt_update_once
    log "Installing optional packages: ${to_install[*]}"
    $SUDO apt-get install -y "${to_install[@]}" || true
  fi
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    err "Required command not found: $1"
    exit 1
  fi
}

clone_or_update() {
  local repo="$1"
  local dest="$2"
  if [[ -d "$dest/.git" ]]; then
    log "Updating $dest"
    git -C "$dest" pull --ff-only
  else
    log "Cloning $repo to $dest"
    git clone --depth=1 "$repo" "$dest"
  fi
}

xfconf_set() {
  local channel="$1" prop="$2" type="$3" value="$4"
  xfconf-query -c "$channel" -p "$prop" -t "$type" -s "$value" --create >/dev/null 2>&1 || true
}

xfconf_set_bool() {
  local channel="$1" prop="$2" value="$3"
  xfconf_set "$channel" "$prop" bool "$value"
}

xfconf_set_int() {
  local channel="$1" prop="$2" value="$3"
  xfconf_set "$channel" "$prop" int "$value"
}

xfconf_set_string() {
  local channel="$1" prop="$2" value="$3"
  xfconf_set "$channel" "$prop" string "$value"
}

backup_xfce_config() {
  local src="$HOME/.config/xfce4"
  local stamp
  stamp="$(date +%Y%m%d-%H%M%S)"
  local dest="$HOME/.config/xfce4-backup-$stamp"
  if [[ -d "$src" ]]; then
    log "Backing up XFCE config to $dest"
    mkdir -p "$dest"
    cp -a "$src/." "$dest/"
    ok "Backup created"
  else
    warn "XFCE config directory not found at $src; skipping backup"
  fi
}

install_whitesur_gtk() {
  local repo="https://github.com/vinceliuice/WhiteSur-gtk-theme"
  local dest="/tmp/WhiteSur-gtk-theme"
  clone_or_update "$repo" "$dest"

  log "Installing WhiteSur GTK theme (light/macOS style)"
  pushd "$dest" >/dev/null
  set +e
  local success=0
  local attempts=(
    "-t all -c Light -m"
    "-t all -c light -m"
    "-t all -c Light"
    "-t all -c light"
    "-c Light -m"
    "-c light -m"
    "-m"
    ""
  )
  for args in "${attempts[@]}"; do
    if [[ -n "$args" ]]; then
      ./install.sh $args
    else
      ./install.sh
    fi
    if [[ $? -eq 0 ]]; then
      success=1
      break
    fi
  done
  set -e
  popd >/dev/null

  if [[ "$success" -ne 1 ]]; then
    err "WhiteSur GTK theme installation failed"
    exit 1
  fi

  ok "WhiteSur GTK theme installed"
}

choose_whitesur_theme() {
  local theme
  for theme in "WhiteSur-light" "WhiteSur-Light" "WhiteSur"; do
    if [[ -d "$HOME/.themes/$theme" || -d "/usr/share/themes/$theme" ]]; then
      echo "$theme"
      return 0
    fi
  done
  theme=$(ls -1 "$HOME/.themes" 2>/dev/null | grep -i '^WhiteSur' | head -n 1 || true)
  if [[ -n "$theme" ]]; then
    echo "$theme"
    return 0
  fi
  theme=$(ls -1 /usr/share/themes 2>/dev/null | grep -i '^WhiteSur' | head -n 1 || true)
  if [[ -n "$theme" ]]; then
    echo "$theme"
    return 0
  fi
  echo ""
}

install_whitesur_icons() {
  local repo="https://github.com/vinceliuice/WhiteSur-icon-theme"
  local dest="/tmp/WhiteSur-icon-theme"
  clone_or_update "$repo" "$dest"

  log "Installing WhiteSur icon theme"
  pushd "$dest" >/dev/null
  ./install.sh
  popd >/dev/null
  ok "WhiteSur icon theme installed"
}

install_cursor_theme() {
  local chosen=""
  if [[ -d "$HOME/.local/share/icons/macOS-Monterey" || -d "/usr/share/icons/macOS-Monterey" ]]; then
    chosen="macOS-Monterey"
  fi

  if [[ -z "$chosen" ]]; then
    apt_install_optional bibata-cursor-theme
    if [[ -d "$HOME/.local/share/icons/Bibata-Modern-Classic" || -d "/usr/share/icons/Bibata-Modern-Classic" ]]; then
      chosen="Bibata-Modern-Classic"
    fi
  fi

  if [[ -z "$chosen" ]]; then
    log "Installing macOS-style cursor theme from ful1e5/apple_cursor"
    local dest="/tmp/apple_cursor"
    rm -rf "$dest"
    mkdir -p "$dest"
    if command -v curl >/dev/null 2>&1; then
      curl -L "https://github.com/ful1e5/apple_cursor/archive/refs/heads/main.tar.gz" -o "$dest/apple_cursor.tar.gz"
    else
      wget -O "$dest/apple_cursor.tar.gz" "https://github.com/ful1e5/apple_cursor/archive/refs/heads/main.tar.gz"
    fi
    tar -xzf "$dest/apple_cursor.tar.gz" -C "$dest"
    local src_dir
    src_dir=$(find "$dest" -maxdepth 1 -type d -name "apple_cursor-*" | head -n 1)
    if [[ -n "$src_dir" && -f "$src_dir/install.sh" ]]; then
      pushd "$src_dir" >/dev/null
      ./install.sh -d "$HOME/.local/share/icons"
      popd >/dev/null
    else
      warn "apple_cursor install script not found; skipping"
    fi
    if [[ -d "$HOME/.local/share/icons/macOS-Monterey" || -d "/usr/share/icons/macOS-Monterey" ]]; then
      chosen="macOS-Monterey"
    fi
  fi

  if [[ -z "$chosen" ]]; then
    warn "Could not determine cursor theme; leaving default"
  else
    ok "Cursor theme set to $chosen"
    xfconf_set_string xsettings /Gtk/CursorThemeName "$chosen"
    xfconf_set_int xsettings /Gtk/CursorThemeSize 24
  fi
}

configure_fonts() {
  log "Installing and configuring fonts"
  apt_install_optional fonts-inter

  if ! fc-list | grep -qi "Inter"; then
    log "Downloading Inter font"
    local dest="/tmp/inter-font"
    rm -rf "$dest"
    mkdir -p "$dest"
    if command -v curl >/dev/null 2>&1; then
      curl -L "https://github.com/rsms/inter/releases/download/v4.0/Inter-4.0.zip" -o "$dest/Inter.zip"
    else
      wget -O "$dest/Inter.zip" "https://github.com/rsms/inter/releases/download/v4.0/Inter-4.0.zip"
    fi
    mkdir -p "$HOME/.local/share/fonts/Inter"
    unzip -o "$dest/Inter.zip" -d "$dest" >/dev/null
    find "$dest" -type f -name "*.ttf" -exec cp -f {} "$HOME/.local/share/fonts/Inter/" \;
  fi

  fc-cache -f >/dev/null

  xfconf_set_string xsettings /Gtk/FontName "Inter Regular 13"
  xfconf_set_int xsettings /Xft/Antialias 1
  xfconf_set_int xsettings /Xft/Hinting 1
  xfconf_set_string xsettings /Xft/HintStyle "hintslight"
  xfconf_set_string xsettings /Xft/RGBA "rgb"

  ok "Fonts configured"
}

configure_xfwm4() {
  log "Configuring XFWM4 compositor and window behavior"
  xfconf_set_bool xfwm4 /general/use_compositing true
  xfconf_set_bool xfwm4 /general/show_dock_shadow true
  xfconf_set_bool xfwm4 /general/show_frame_shadow true
  xfconf_set_int xfwm4 /general/inactive_opacity 95
  xfconf_set_bool xfwm4 /general/snap_to_border true
  xfconf_set_bool xfwm4 /general/snap_to_window true
  xfconf_set_bool xfwm4 /general/snap_to_workarea true
  xfconf_set_bool xfwm4 /general/placement_centered true
  ok "XFWM4 configured"
}

ensure_panel_plugin() {
  local panel_id="$1"
  local plugin_type="$2"

  local plugin_ids
  plugin_ids=$(xfconf-query -c xfce4-panel -p "/panels/panel-$panel_id/plugin-ids" 2>/dev/null || true)

  local pid
  for pid in $plugin_ids; do
    local ptype
    ptype=$(xfconf-query -c xfce4-panel -p "/plugins/plugin-$pid" 2>/dev/null || true)
    if [[ "$ptype" == "$plugin_type" ]]; then
      echo "$pid"
      return 0
    fi
  done

  local max_id
  max_id=$(xfconf-query -c xfce4-panel -l 2>/dev/null | sed -n 's#^/plugins/plugin-\([0-9]\+\)$#\1#p' | sort -n | tail -n 1)
  if [[ -z "$max_id" ]]; then
    max_id=0
  fi
  local new_id=$((max_id + 1))
  xfconf_query_create_plugin "$new_id" "$plugin_type"
  xfconf_query_append_plugin "$panel_id" "$new_id"
  echo "$new_id"
}

xfconf_query_create_plugin() {
  local id="$1"
  local type="$2"
  xfconf_query_set_if_missing xfce4-panel "/plugins/plugin-$id" string "$type"
}

xfconf_query_set_if_missing() {
  local channel="$1" prop="$2" type="$3" value="$4"
  if ! xfconf-query -c "$channel" -p "$prop" >/dev/null 2>&1; then
    xfconf-query -c "$channel" -p "$prop" -t "$type" -s "$value" --create >/dev/null 2>&1 || true
  fi
}

xfconf_query_append_plugin() {
  local panel_id="$1"
  local plugin_id="$2"
  xfconf-query -c xfce4-panel -p "/panels/panel-$panel_id/plugin-ids" -a -t int -s "$plugin_id" >/dev/null 2>&1 || true
}

panel_has_plugin_type() {
  local panel_id="$1"
  local plugin_type="$2"
  local plugin_ids
  plugin_ids=$(xfconf-query -c xfce4-panel -p "/panels/panel-$panel_id/plugin-ids" 2>/dev/null || true)
  local pid
  for pid in $plugin_ids; do
    local ptype
    ptype=$(xfconf-query -c xfce4-panel -p "/plugins/plugin-$pid" 2>/dev/null || true)
    if [[ "$ptype" == "$plugin_type" ]]; then
      return 0
    fi
  done
  return 1
}

configure_top_panel() {
  log "Configuring top panel (menu bar)"

  local panels
  mapfile -t panels < <(xfconf-query -c xfce4-panel -p /panels 2>/dev/null || true)

  if [[ "${#panels[@]}" -eq 0 ]]; then
    warn "No XFCE panels detected; skipping panel configuration"
    return 0
  fi

  local taskbar_panel=""
  local panel_id
  for panel_id in "${panels[@]}"; do
    if panel_has_plugin_type "$panel_id" "tasklist" || panel_has_plugin_type "$panel_id" "windowbuttons"; then
      taskbar_panel="$panel_id"
      break
    fi
  done

  if [[ -n "$taskbar_panel" ]]; then
    log "Hiding taskbar panel: $taskbar_panel"
    xfconf_set_int xfce4-panel "/panels/panel-$taskbar_panel/autohide-behavior" 2
    xfconf_set_bool xfce4-panel "/panels/panel-$taskbar_panel/enable-struts" false
  else
    warn "No taskbar panel found; skipping hide"
  fi

  local top_panel=""
  for panel_id in "${panels[@]}"; do
    if [[ "$panel_id" != "$taskbar_panel" ]]; then
      top_panel="$panel_id"
      break
    fi
  done
  if [[ -z "$top_panel" ]]; then
    top_panel="$taskbar_panel"
  fi

  if [[ -z "$top_panel" ]]; then
    warn "Unable to determine top panel; skipping configuration"
    return 0
  fi

  xfconf_set_int xfce4-panel "/panels/panel-$top_panel/size" 28
  xfconf_set_int xfce4-panel "/panels/panel-$top_panel/length" 100
  xfconf_set_bool xfce4-panel "/panels/panel-$top_panel/length-adjust" true
  xfconf_set_int xfce4-panel "/panels/panel-$top_panel/mode" 0
  xfconf_set_int xfce4-panel "/panels/panel-$top_panel/autohide-behavior" 0
  xfconf_set_bool xfce4-panel "/panels/panel-$top_panel/enable-struts" true
  xfconf_set_string xfce4-panel "/panels/panel-$top_panel/position" "p=6;x=0;y=0"

  xfconf_set_int xfce4-panel "/panels/panel-$top_panel/background-style" 1
  xfconf_set_string xfce4-panel "/panels/panel-$top_panel/background-color" "#f2f2f2"
  xfconf_set_int xfce4-panel "/panels/panel-$top_panel/background-alpha" 80

  local appmenu_plugin=""
  if compgen -G "/usr/lib*/xfce4/panel/plugins/libappmenu.so" >/dev/null 2>&1; then
    appmenu_plugin="appmenu"
  fi

  local apps_plugin_id
  apps_plugin_id=$(ensure_panel_plugin "$top_panel" "applicationsmenu")
  if [[ -n "$apps_plugin_id" ]]; then
    xfconf_set_bool xfce4-panel "/plugins/plugin-$apps_plugin_id/show-button-title" false
    xfconf_set_string xfce4-panel "/plugins/plugin-$apps_plugin_id/button-icon" "start-here"
  fi

  if [[ -n "$appmenu_plugin" ]]; then
    ensure_panel_plugin "$top_panel" "$appmenu_plugin" >/dev/null
  else
    warn "xfce4-appmenu-plugin not found; global menu may not appear"
  fi

  local sep_id
  sep_id=$(ensure_panel_plugin "$top_panel" "separator")
  if [[ -n "$sep_id" ]]; then
    xfconf_set_bool xfce4-panel "/plugins/plugin-$sep_id/expand" true
    xfconf_set_int xfce4-panel "/plugins/plugin-$sep_id/style" 0
  fi

  local clock_id
  clock_id=$(ensure_panel_plugin "$top_panel" "clock")
  if [[ -n "$clock_id" ]]; then
    xfconf_set_int xfce4-panel "/plugins/plugin-$clock_id/mode" 2
    xfconf_set_string xfce4-panel "/plugins/plugin-$clock_id/digital-format" "%a %b %d  %H:%M"
  fi

  ok "Top panel configured"
}

configure_plank() {
  log "Installing and configuring Plank dock"
  apt_install plank

  mkdir -p "$HOME/.config/plank/dock1"
  cat <<'PLANKCFG' > "$HOME/.config/plank/dock1/settings"
[PlankDockPreferences]
Alignment=center
AutoPinning=false
CurrentTheme=Transparent
DockItems=
HideDelay=0
HideMode=none
IconSize=48
ItemsAlignment=center
LockItems=false
Monitor=
Offset=0
PinOnly=false
Position=bottom
PressureReveal=false
ShowDockItem=true
Theme=Transparent
TooltipsEnabled=true
UnhideDelay=0
ZoomEnabled=true
ZoomPercent=120
PLANKCFG

  mkdir -p "$HOME/.config/plank/dock1/launchers"

  add_plank_launcher() {
    local name="$1"
    local desktop_file="$2"
    local out="$HOME/.config/plank/dock1/launchers/$name.dockitem"
    cat <<PLANKITEM > "$out"
[PlankDockItemPreferences]
Launcher=file://$desktop_file
PLANKITEM
  }

  find_desktop_file() {
    local candidates=("$@")
    local c
    for c in "${candidates[@]}"; do
      if [[ -f "/usr/share/applications/$c" ]]; then
        echo "/usr/share/applications/$c"
        return 0
      fi
      if [[ -f "$HOME/.local/share/applications/$c" ]]; then
        echo "$HOME/.local/share/applications/$c"
        return 0
      fi
    done
    return 1
  }

  local files_desktop
  files_desktop=$(find_desktop_file "thunar.desktop" "org.xfce.Thunar.desktop" "org.gnome.Nautilus.desktop" || true)
  if [[ -n "$files_desktop" ]]; then
    add_plank_launcher "Files" "$files_desktop"
  fi

  local term_desktop
  term_desktop=$(find_desktop_file "xfce4-terminal.desktop" "org.gnome.Terminal.desktop" "xterm.desktop" || true)
  if [[ -n "$term_desktop" ]]; then
    add_plank_launcher "Terminal" "$term_desktop"
  fi

  local browser_desktop
  browser_desktop=$(find_desktop_file "firefox.desktop" "chromium.desktop" "google-chrome.desktop" || true)
  if [[ -n "$browser_desktop" ]]; then
    add_plank_launcher "Browser" "$browser_desktop"
  fi

  local settings_desktop
  settings_desktop=$(find_desktop_file "xfce4-settings-manager.desktop" "org.gnome.Settings.desktop" || true)
  if [[ -n "$settings_desktop" ]]; then
    add_plank_launcher "Settings" "$settings_desktop"
  fi

  cat <<'TRASHITEM' > "$HOME/.config/plank/dock1/launchers/Trash.dockitem"
[PlankDockItemPreferences]
Launcher=trash:///
TRASHITEM

  mkdir -p "$HOME/.config/autostart"
  cat <<'AUTOSTART' > "$HOME/.config/autostart/plank.desktop"
[Desktop Entry]
Type=Application
Name=Plank
Exec=plank
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Comment=macOS-style dock
AUTOSTART

  ok "Plank configured"
}

configure_wallpaper() {
  log "Setting macOS wallpaper"
  mkdir -p "$HOME/Pictures"
  local wallpaper="$HOME/Pictures/macos-wallpaper.jpg"

  local urls=(
    "https://512pixels.net/downloads/macos-wallpapers/14-Sonoma.jpg"
    "https://512pixels.net/downloads/macos-wallpapers/13-Ventura.jpg"
    "https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=3840&q=80"
  )

  local fetched=0
  local url
  for url in "${urls[@]}"; do
    if command -v curl >/dev/null 2>&1; then
      if curl -L "$url" -o "$wallpaper"; then
        fetched=1
        break
      fi
    else
      if wget -O "$wallpaper" "$url"; then
        fetched=1
        break
      fi
    fi
  done

  if [[ "$fetched" -ne 1 ]]; then
    warn "Wallpaper download failed; leaving existing wallpaper"
    return 0
  fi

  local paths
  mapfile -t paths < <(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep -E "/backdrop/.*/workspace0/last-image$" || true)
  if [[ "${#paths[@]}" -eq 0 ]]; then
    warn "No XFCE desktop backdrop paths found"
    return 0
  fi

  local p
  for p in "${paths[@]}"; do
    xfconf_set_string xfce4-desktop "$p" "$wallpaper"
    local style_path
    style_path="${p%/last-image}/image-style"
    xfconf_set_int xfce4-desktop "$style_path" 5
  done

  ok "Wallpaper applied"
}

configure_rofi_spotlight() {
  log "Installing and configuring Rofi"
  apt_install rofi

  local dest="/tmp/rofi-themes"
  clone_or_update "https://github.com/newmanls/rofi-themes-collection" "$dest"

  mkdir -p "$HOME/.config/rofi/themes"
  local theme_file
  theme_file=$(find "$dest" -type f -iname "*spotlight*dark*.rasi" | head -n 1 || true)
  if [[ -z "$theme_file" ]]; then
    theme_file=$(find "$dest" -type f -iname "*spotlight*.rasi" | head -n 1 || true)
  fi

  if [[ -n "$theme_file" ]]; then
    cp -f "$theme_file" "$HOME/.config/rofi/themes/spotlight-dark.rasi"
  else
    warn "Spotlight theme not found; using default Rofi theme"
  fi

  cat <<'ROFICFG' > "$HOME/.config/rofi/config.rasi"
configuration {
  modi: "drun,run";
  show-icons: true;
  drun-display-format: "{name}";
  sidebar-mode: false;
}
@theme "spotlight-dark"
ROFICFG

  xfconf_set_string xfce4-keyboard-shortcuts "/commands/custom/<Super>space" "rofi -show drun -theme spotlight-dark"

  ok "Rofi configured"
}

configure_desktop_cleanup() {
  log "Cleaning desktop icons"
  xfconf_set_int xfce4-desktop /desktop-icons/style 0
  xfconf_set_bool xfce4-desktop /desktop-menu/show false
  xfconf_set_bool xfce4-desktop /desktop-icons/file-icons/show-home false
  xfconf_set_bool xfce4-desktop /desktop-icons/file-icons/show-trash false
  xfconf_set_bool xfce4-desktop /desktop-icons/file-icons/show-filesystem false
  xfconf_set_bool xfce4-desktop /desktop-icons/file-icons/show-removable false
  ok "Desktop cleaned"
}

apply_theme_settings() {
  local gtk_theme="$1"
  if [[ -z "$gtk_theme" ]]; then
    warn "WhiteSur GTK theme not found; skipping theme application"
    return 0
  fi

  xfconf_set_string xsettings /Net/ThemeName "$gtk_theme"
  xfconf_set_string xsettings /Gtk/ThemeName "$gtk_theme"
  xfconf_set_string xsettings /Gtk/DecorationLayout "close,minimize,maximize:"
  xfconf_set_string xfwm4 /general/theme "$gtk_theme"
  ok "Applied GTK/XFWM4 theme: $gtk_theme"
}

apply_icon_theme() {
  xfconf_set_string xsettings /Net/IconThemeName "WhiteSur"
  ok "Applied icon theme: WhiteSur"
}

configure_global_menu_env() {
  log "Configuring environment for global menu"
  mkdir -p "$HOME/.config/environment.d"
  local env_file="$HOME/.config/environment.d/90-appmenu.conf"
  if ! grep -q "GTK_MODULES" "$env_file" 2>/dev/null; then
    cat <<'ENVFILE' >> "$env_file"
GTK_MODULES=appmenu-gtk-module
UBUNTU_MENUPROXY=1
ENVFILE
  fi
  ok "Global menu environment configured"
}

main() {
  log "Starting XFCE -> macOS transformation"

  backup_xfce_config

  apt_install git curl wget unzip tar xfconf
  apt_install_optional gtk2-engines-murrine gtk2-engines-pixbuf gnome-themes-extra
  apt_install_optional xfce4-appmenu-plugin appmenu-gtk2-module appmenu-gtk3-module appmenu-gtk-module

  require_cmd xfconf-query
  require_cmd git

  install_whitesur_gtk
  install_whitesur_icons

  local gtk_theme
  gtk_theme=$(choose_whitesur_theme)
  apply_theme_settings "$gtk_theme"
  apply_icon_theme

  install_cursor_theme
  configure_fonts
  configure_xfwm4
  configure_plank
  configure_top_panel
  configure_wallpaper
  configure_rofi_spotlight
  configure_desktop_cleanup
  configure_global_menu_env

  ok "All steps completed"
  echo
  echo -e "${GREEN}Done.${NC} Please log out and log back in to apply all changes."
}

main "$@"
