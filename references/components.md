# Component Implementation Reference

Full technical specs for each XFCE → macOS transformation component.

---

## 1. GTK Theme — WhiteSur

```bash
# Install WhiteSur GTK theme
if [ ! -d "$HOME/.themes/WhiteSur-Light" ]; then
  git clone --depth=1 https://github.com/vinceliuice/WhiteSur-gtk-theme /tmp/WhiteSur-gtk
  cd /tmp/WhiteSur-gtk
  ./install.sh -c Light -l -i ubuntu
  cd -
fi

xfconf-query -c xsettings -p /Net/ThemeName -s "WhiteSur-Light"
xfconf-query -c xfwm4 -p /general/theme -s "WhiteSur-Light"
log "GTK theme applied: WhiteSur-Light"
```

**Options explained:**
- `-c Light` → light macOS style
- `-l` → install for all users (requires sudo) or just `~/.themes`
- `-i ubuntu` → use Ubuntu-style panel icons

---

## 2. Icon Theme — WhiteSur

```bash
if [ ! -d "$HOME/.local/share/icons/WhiteSur" ]; then
  git clone --depth=1 https://github.com/vinceliuice/WhiteSur-icon-theme /tmp/WhiteSur-icons
  cd /tmp/WhiteSur-icons
  ./install.sh -a
  cd -
fi

xfconf-query -c xsettings -p /Net/IconThemeName -s "WhiteSur"
log "Icon theme applied: WhiteSur"
```

---

## 3. Cursor Theme — macOS Monterey

```bash
CURSOR_DIR="$HOME/.local/share/icons/macOS-Monterey"
if [ ! -d "$CURSOR_DIR" ]; then
  wget -q https://github.com/ful1e5/apple_cursor/releases/latest/download/macOS-Monterey.tar.gz \
    -O /tmp/macos-cursor.tar.gz
  mkdir -p "$HOME/.local/share/icons"
  tar -xzf /tmp/macos-cursor.tar.gz -C "$HOME/.local/share/icons/"
fi

xfconf-query -c xsettings -p /Gtk/CursorThemeName -s "macOS-Monterey"
xfconf-query -c xsettings -p /Gtk/CursorThemeSize -s 32

# Also set via index.theme for DM compatibility
mkdir -p "$HOME/.icons/default"
cat > "$HOME/.icons/default/index.theme" <<EOF
[Icon Theme]
Name=Default
Comment=Default cursor theme
Inherits=macOS-Monterey
EOF
log "Cursor theme applied: macOS-Monterey"
```

---

## 4. Dock — Plank

```bash
sudo apt-get install -y plank

# Configure Plank via dconf
mkdir -p "$HOME/.config/plank/dock1"
cat > "$HOME/.config/plank/dock1/settings" <<EOF
[PlankDockPreferences]
Position=3
Alignment=3
IconSize=48
HideMode=1
Theme=Gtk+
ZoomEnabled=true
ZoomPercent=150
PressureReveal=false
ShowDockItem=false
LockItems=false
EOF

# Autostart Plank
mkdir -p "$HOME/.config/autostart"
cat > "$HOME/.config/autostart/plank.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Plank
Exec=plank
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

# Hide XFCE bottom panel (panel 1)
xfconf-query -c xfce4-panel -p /panels -a -t int -s 1  # keep only panel 1 (top)
# Or move existing panel to top and remove bottom
log "Dock installed: Plank (auto-starts on login)"
```

---

## 5. Top Panel — macOS Menu Bar Style

```bash
# Ensure panel is at top, full width, 28px height
PANEL=1
xfconf-query -c xfce4-panel -p /panels/panel-$PANEL/position -s "p=8;x=0;y=0"
xfconf-query -c xfce4-panel -p /panels/panel-$PANEL/size -s 28
xfconf-query -c xfce4-panel -p /panels/panel-$PANEL/length -s 100
xfconf-query -c xfce4-panel -p /panels/panel-$PANEL/length-adjust -s true
xfconf-query -c xfce4-panel -p /panels/panel-$PANEL/position-locked -s true

# Panel background — semi-transparent white (macOS light menu bar)
xfconf-query -c xfce4-panel -p /panels/panel-$PANEL/background-style -s 1
xfconf-query -c xfce4-panel -p /panels/panel-$PANEL/background-rgba \
  -a -t double -s 0.97 -t double -s 0.97 -t double -s 0.97 -t double -s 0.85

log "Top panel configured as macOS menu bar"
```

**Recommended panel plugins (left to right):**
- `applicationsmenu` — Apple-style app menu
- `separator` (expand)
- `clock` — format: `%a %b %-d  %-I:%M %p`
- `systray` / `statusnotifier`
- `pulseaudio` or `pasystray`
- `power-manager-plugin`
- `notification-plugin`

---

## 6. Wallpaper — macOS Sonoma/Ventura

```bash
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
WALLPAPER="$WALLPAPER_DIR/macos-sonoma.jpg"
mkdir -p "$WALLPAPER_DIR"

# Try multiple sources
download_wallpaper() {
  local url="$1"
  wget -q --timeout=15 "$url" -O "$WALLPAPER" && return 0 || return 1
}

# Primary: macOS Sonoma light wallpaper (hi-res)
download_wallpaper "https://512pixels.net/downloads/macos-wallpapers-6k/14-Light.jpg" || \
download_wallpaper "https://raw.githubusercontent.com/vinceliuice/WhiteSur-wallpapers/main/originals/WhiteSur.jpg" || \
warn "Could not download wallpaper — set manually in Settings > Desktop"

if [ -f "$WALLPAPER" ]; then
  # Apply to all monitors and workspaces dynamically
  for monitor_path in $(xfconf-query -c xfce4-desktop -l | grep "last-image"); do
    xfconf-query -c xfce4-desktop -p "$monitor_path" -s "$WALLPAPER"
  done
  for style_path in $(xfconf-query -c xfce4-desktop -l | grep "image-style"); do
    xfconf-query -c xfce4-desktop -p "$style_path" -s 5  # Zoom
  done
  log "Wallpaper applied: $WALLPAPER"
fi
```

---

## 7. Fonts — Inter (San Francisco substitute)

```bash
FONT_DIR="$HOME/.local/share/fonts/Inter"
if [ ! -d "$FONT_DIR" ]; then
  mkdir -p "$FONT_DIR"
  wget -q https://github.com/rsms/inter/releases/download/v4.0/Inter-4.0.zip \
    -O /tmp/inter.zip
  unzip -q /tmp/inter.zip -d /tmp/inter-extracted/
  find /tmp/inter-extracted/ -name "*.ttf" -exec cp {} "$FONT_DIR/" \;
  fc-cache -f "$FONT_DIR"
fi

xfconf-query -c xsettings -p /Gtk/FontName          -s "Inter Regular 13"
xfconf-query -c xsettings -p /Gtk/MonospaceFontName  -s "JetBrains Mono 12"
xfconf-query -c xsettings -p /Xft/Antialias          -s 1
xfconf-query -c xsettings -p /Xft/Hinting            -s 1
xfconf-query -c xsettings -p /Xft/HintStyle          -s "hintslight"
xfconf-query -c xsettings -p /Xft/RGBA               -s "rgb"
xfconf-query -c xsettings -p /Xft/DPI                -s 96
log "Fonts set: Inter Regular 13"
```

---

## 8. Compositor — Rounded Corners & Shadows

```bash
# Enable XFWM4 compositor
xfconf-query -c xfwm4 -p /general/use_compositing     -s true
xfconf-query -c xfwm4 -p /general/show_dock_shadow    -s true
xfconf-query -c xfwm4 -p /general/show_frame_shadow   -s true
xfconf-query -c xfwm4 -p /general/show_popup_shadow   -s true
xfconf-query -c xfwm4 -p /general/shadow_opacity      -s 40
xfconf-query -c xfwm4 -p /general/inactive_opacity    -s 95
xfconf-query -c xfwm4 -p /general/frame_opacity       -s 100

# Optional: install picom for better effects (rounded corners)
if command -v picom &>/dev/null || apt-cache show picom &>/dev/null; then
  sudo apt-get install -y picom
  mkdir -p "$HOME/.config/picom"
  cat > "$HOME/.config/picom/picom.conf" <<EOF
corner-radius = 12;
rounded-corners-exclude = [
  "window_type = 'dock'",
  "window_type = 'desktop'"
];
shadow = true;
shadow-radius = 20;
shadow-opacity = 0.3;
shadow-offset-x = -5;
shadow-offset-y = -5;
fading = true;
fade-in-step = 0.03;
fade-out-step = 0.03;
backend = "glx";
EOF
  # Autostart picom
  cat > "$HOME/.config/autostart/picom.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Picom
Exec=picom --config $HOME/.config/picom/picom.conf
Hidden=false
X-GNOME-Autostart-enabled=true
EOF
fi
log "Compositor configured with shadows and rounded corners"
```

---

## 9. Spotlight Launcher — Rofi

```bash
sudo apt-get install -y rofi

# Install macOS-style Rofi theme
ROFI_THEME_DIR="$HOME/.local/share/rofi/themes"
mkdir -p "$ROFI_THEME_DIR"
wget -q https://raw.githubusercontent.com/newmanls/rofi-themes-collection/master/themes/spotlight-dark.rasi \
  -O "$ROFI_THEME_DIR/spotlight-dark.rasi" 2>/dev/null || \
# Fallback: write a basic Spotlight-style theme inline
cat > "$ROFI_THEME_DIR/spotlight-dark.rasi" <<'EOF'
* { font: "Inter Regular 14"; }
window { width: 600px; border-radius: 12px; background-color: rgba(30,30,30,0.95); }
inputbar { padding: 12px; background-color: transparent; }
entry { color: white; }
listview { padding: 8px; }
element-text { color: #dddddd; }
element selected { background-color: #0a7ef9; border-radius: 6px; }
EOF

# Bind Super+Space to launch Rofi
xfconf-query -c xfce4-keyboard-shortcuts \
  -p "/commands/custom/<Super>space" \
  -s "rofi -show drun -theme $ROFI_THEME_DIR/spotlight-dark.rasi" \
  --create -t string 2>/dev/null || true

log "Spotlight launcher installed: press Super+Space"
```

---

## 10. Desktop Cleanup

```bash
# Hide desktop icons (macOS has no desktop icons by default)
xfconf-query -c xfce4-desktop -p /desktop-icons/style -s 0

# Disable Thunar desktop manager
xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-filesystem -s false
xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-home       -s false
xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-trash      -s false
xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-removable  -s false

log "Desktop cleaned: no icons (macOS style)"
```

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Plank doesn't show | Run `plank` manually; check autostart |
| Theme not applied | Run `xfsettingsd --replace` or log out/in |
| Cursor unchanged in apps | Set `~/.Xresources`: `Xcursor.theme: macOS-Monterey` |
| Wallpaper not updating | Run `xfdesktop --reload` |
| Fonts look wrong | Run `fc-cache -f -v` and restart apps |
| picom conflicts with xfwm4 compositor | Disable xfwm4 compositor first: `xfconf-query -c xfwm4 -p /general/use_compositing -s false` |
