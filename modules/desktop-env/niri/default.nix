{pkgs, config, host, lib, helper, ...}: let
  swayidleStyle = pkgs.writeText "style.css" ''
window {
  background-color: black;
  background-size: cover;
  background-repeat: no-repeat;
  background-position: center;
}

#input-box {
  background: #1e1e2e;
  border: 1px solid #313244;
  border-radius: 10px;
  padding: 10px;
}

entry {
  background: transparent;
  color: #cdd6f4;
  caret-color: #cdd6f4;
}

#label {
  color: #cdd6f4;
}
'';
  suspendIfNotOnAC = pkgs.writeShellScript "suspend-if-not-on-ac" ''
    for type_file in /sys/class/power_supply/*/type; do
      [ -e "$type_file" ] || continue
      if [ "$(cat "$type_file")" = "Mains" ]; then
        online_file="''${type_file%/type}/online"
        if [ -r "$online_file" ] && [ "$(cat "$online_file")" = "1" ]; then
          exit 0
        fi
      fi
    done

    exec ${pkgs.systemd}/bin/systemctl suspend
  '';
  swayidleLauncher = pkgs.writeShellScriptBin "swayidle-start" ''
exec ${pkgs.swayidle}/bin/swayidle -w \
  timeout 300 '${pkgs.gtklock}/bin/gtklock -g Adwaita-dark -s ${swayidleStyle}' \
  timeout 600 '${pkgs.niri}/bin/niri msg action output all dpms off' \
    resume '${pkgs.niri}/bin/niri msg action output all dpms on' \
  timeout 1800 '${suspendIfNotOnAC}' \
  before-sleep '${pkgs.gtklock}/bin/gtklock -g Adwaita-dark -s ${swayidleStyle}'
'';
  niri-find-window = ''
SEARCH_METHOD_FLAG=$1
SCRATCH_WIN_NAME=$2

windows=$(niri msg -j windows)

case $SEARCH_METHOD_FLAG in
  "--app-id")
    app_window=$(echo "$windows" | jq ".[] | select(.app_id == \"$SCRATCH_WIN_NAME\")")
    ;;
  "--title")
    app_window=$(echo "$windows" | jq ".[] | select(.title == \"$SCRATCH_WIN_NAME\")")
    ;;
  "--help")
    showHelp
    exit 0
    ;;
  "--version")
    echo "niri-scratchpad v0.0.1"
    exit 0
    ;;
  *)
    SCRATCH_WIN_NAME=$1
    app_window=$(echo "$windows" | jq ".[] | select(.app_id == \"$SCRATCH_WIN_NAME\")")
    ;;
esac

echo $app_window
  '';
  niri-focus-create-script = ''
#! /usr/bin/env bash
SPAWN_FLAG=$3
PROCESS_NAME=$4
echo "Running focus-create-script"

showHelp() {
  echo "[niri-scratchpad]"
  echo ""
  echo "  Open scratchpad app by app-id:"
  echo "    - 'niri-scratchpad spotify'"
  echo "    - 'niri-scratchpad --app-id spotify'"
  echo ""
  echo "  Open scratchpad by title (some apps do not support app-id):"
  echo "    - 'niri-scratchpad --title Telegram'"
  echo ""
  echo "  Spawn process on first request if it does not exist:"
  echo "    - 'niri-scratchpad --app-id Audacious --spawn audacious'"
  echo ""
  echo "  NOTE: when using the '--spawn' flag, you MUST indicate either '--app-id' or 'title' flag as well."
}

win_id=$(niri.find-window $@ | jq .id | head -1)

if [[ -z $win_id ]]; then
  echo "Window not found"
  case $SPAWN_FLAG in
    "--spawn")
      if [[ -z $PROCESS_NAME ]]; then
        showHelp
        exit 1
      else
        echo "Spawning $PROCESS_NAME"
        niri msg action spawn -- "$PROCESS_NAME"
        exit 0
      fi
      ;;
  "--spawn-sh")
       echo "Spawning $PROCESS_NAME"
       niri msg action spawn-sh -- "$PROCESS_NAME"
       exit 0
    ;;
    *)
      showHelp
      exit 1
      ;;
  esac
fi
niri msg action focus-window --id "$win_id"
  '';
  niri-scratch-script = ''
#! /usr/bin/env bash

echo "Running scratchpad"
SCRATCH_WORKSPACE_NAME=scratchpad

SPAWN_FLAG=$3
PROCESS_NAME=$4

showHelp() {
  echo "[niri-scratchpad]"
  echo ""
  echo "  Open scratchpad app by app-id:"
  echo "    - 'niri-scratchpad spotify'"
  echo "    - 'niri-scratchpad --app-id spotify'"
  echo ""
  echo "  Open scratchpad by title (some apps do not support app-id):"
  echo "    - 'niri-scratchpad --title Telegram'"
  echo ""
  echo "  Spawn process on first request if it does not exist:"
  echo "    - 'niri-scratchpad --app-id Audacious --spawn audacious'"
  echo ""
  echo "  NOTE: when using the '--spawn' flag, you MUST indicate either '--app-id' or 'title' flag as well."
}

app_window=$(niri.find-window $@)
win_id=$(echo $app_window | jq .id)


if [[ -z $win_id ]]; then
  echo "Window not found"
  case $SPAWN_FLAG in
    "--spawn")
      if [[ -z $PROCESS_NAME ]]; then
        showHelp
        exit 1
      else
        echo "Spawning $PROCESS_NAME"
        niri msg action spawn-sh -- "$PROCESS_NAME"
        exit 0
      fi
      ;;
    *)
      showHelp
      exit 1
      ;;
  esac
fi


moveWindowToScratchpad() {
  niri msg action move-window-to-workspace --window-id "$win_id" "$SCRATCH_WORKSPACE_NAME" --focus=false
  if [[ -n $NIRI_SCRATCHPAD_ANIMATIONS ]]; then
    niri msg action move-window-to-tiling --id "$win_id"
  fi
}

bringScratchpadWindowToFocus() {
echo "Bring window to focus $app_window $work_idx"
  is_win_floating=$(echo "$app_window" | jq .is_floating)
  niri msg action move-window-to-monitor --id "$win_id" "$output_id"
  niri msg action move-window-to-workspace --window-id "$win_id" "$work_idx"
  if [[ $is_win_floating == "false" && -n $NIRI_SCRATCHPAD_ANIMATIONS ]]; then
    niri msg action move-window-to-floating --id "$win_id"
  fi
  niri msg action focus-window --id "$win_id"
}

if [[ $(echo "$app_window" | jq .is_focused) == "false" ]]; then
  focused_workspaces=$(niri msg -j workspaces | jq '.[] | select(.is_focused == true)')
  work_id=$(echo "$focused_workspaces" | jq .id)
  work_idx=$(echo "$focused_workspaces" | jq .idx)
  output_id=$(echo "$focused_workspaces" | jq -r .output)
  win_work_id=$(echo "$app_window" | jq .workspace_id)
  win_output=$(echo "$app_window" | jq .output)
  win_work_id_global=$(niri msg -j workspaces | jq ".[] | select(.idx == $win_work_id and .output==$win_output)" | jq .id)

  if [[ "$win_work_id_global" == "$work_id" ]]; then
    moveWindowToScratchpad
  else
    bringScratchpadWindowToFocus
  fi
else
  moveWindowToScratchpad
fi

  '';
  in
{
  
  programs.niri = {
    enable = true;
    package = pkgs.niri;
  };

  environment.systemPackages = with pkgs; [
    imagemagick
    rofi
    waybar
    awww
    mako
    bibata-cursors
    jetbrains-mono
    material-symbols
    papirus-icon-theme
    xwayland-satellite
    gtklock
    swayidleLauncher
    grim
    slurp
    wl-clipboard
    tmux
    (writeShellScriptBin "niri.find-window" niri-find-window)
    (writeShellScriptBin "niri.scratchpad" niri-scratch-script)
    (writeShellScriptBin "niri.focus-create-window" niri-focus-create-script)
    btop
  ];

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        user = "greeter";
        command = "${pkgs.tuigreet}/bin/tuigreet --remember --time --cmd 'niri-session'";
      };
    } // lib.optionalAttrs host.autoLogin {
      initial_session = {
        command = "${pkgs.niri}/bin/niri-session";
        user = host.username;
      };
    };
  };

  xdg.portal.enable = true;
  xdg.portal.extraPortals = with pkgs; [
    xdg-desktop-portal-wlr  # Wayland-native (for screen sharing, screenshots, etc.)
    xdg-desktop-portal-gtk  # Nice GTK file chooser dialogs
  ];
  # PAM auth for gtklock
  security.pam.services.gtklock = {};
  systemd.tmpfiles.rules = helper.mkTmpFileRules host.username ".config/niri" ./dotfiles;
}
