#!/usr/bin/env bash
#
# WinBoat Manager ("Shall A Play A Game - Edition")
# X-Seti Oct 25 - Manage WinBoat container, auto-start service, backups, diagnostics, and updates

#!/usr/bin/env bash
# ===========================================================
# WinBoat Manager - Retro Edition (2025)
# Manage WinBoat containers with retro sound, animations, and systemd support
# Author: ChatGPT (GPT-5)
# ===========================================================

# === CONFIGURATION ===
COMPOSE_FILE="$HOME/.winboat/docker-compose.yml"
INSTALL_DIR="$HOME/winboat"
CONTAINER_NAME="WinBoat"
BACKUP_DIR="$HOME/winboat_backups"
SERVICE_NAME="winboat"
SCRIPT_PATH="$HOME/winboat-manager.sh"

# === COLORS ===
green="\033[1;32m"
red="\033[1;31m"
blue="\033[1;34m"
yellow="\033[1;33m"
cyan="\033[1;36m"
reset="\033[0m"

# === SOUND SYSTEM (No Samples, Synth Only) ===

_play_tone() {
  local freq="${1:-440}"
  local dur="${2:-0.1}"
  if command -v play >/dev/null 2>&1; then
    play -q -n synth "$dur" square "$freq" vol 0.5 2>/dev/null
  elif command -v beep >/dev/null 2>&1; then
    local ms
    ms=$(awk "BEGIN{print int($dur*1000)}")
    beep -f "$freq" -l "$ms" >/dev/null 2>&1
  else
    printf '\a' >/dev/tty 2>/dev/null || true
  fi
}

_sfx_boot()      { _play_tone 440 0.08; _play_tone 660 0.08; _play_tone 880 0.15; }
_sfx_success()   { _play_tone 660 0.08; _play_tone 880 0.12; _play_tone 1320 0.15; }
_sfx_error()     { _play_tone 220 0.15; _play_tone 180 0.15; _play_tone 140 0.2; }
_sfx_game_start(){ _play_tone 523 0.1; _play_tone 659 0.1; _play_tone 784 0.1; _play_tone 1046 0.15; sleep 0.05; _play_tone 784 0.15; }
_sfx_shutdown()  { _play_tone 880 0.1; _play_tone 660 0.1; _play_tone 440 0.15; }

# === RETRO INTRO ===

_intro_animation() {
  clear
  echo -e "${cyan}"
  cat <<'EOF'
 __          __  _       ____              _
 \ \        / / | |     |  _ \            | |
  \ \  /\  / /__| |__   | |_) | ___   ___ | |_
   \ \/  \/ / _ \ '_ \  |  _ < / _ \ / _ \| __|
    \  /\  /  __/ |_) | | |_) | (_) | (_) | |_
     \/  \/ \___|_.__/  |____/ \___/ \___/ \__|
EOF
  echo -e "${reset}"
  sleep 0.4
  echo -ne "${yellow}Initializing Retro Systems${reset}"
  for i in {1..5}; do
    _play_tone 660 0.05
    echo -n "."
    sleep 0.2
  done
  echo
  sleep 0.4
  echo -e "${green}>>> Shall we play a game?${reset}"
  _sfx_game_start
  sleep 1
  clear
}

# === SETUP HELPERS ===

ensure_audio_tools() {
  if ! command -v play >/dev/null && ! command -v beep >/dev/null; then
    echo -e "${blue}Installing minimal sound support (sox)...${reset}"
    if command -v apt >/dev/null; then
      sudo apt install -y sox
    elif command -v pacman >/dev/null; then
      sudo pacman -S --noconfirm sox
    elif command -v dnf >/dev/null; then
      sudo dnf install -y sox
    fi
  fi
}

# === MAIN COMMANDS ===

show_help() {
  cat <<EOF
${blue}WinBoat Manager - Retro Edition${reset}

Usage: $0 [command]

Commands:
  start             Start the WinBoat container
  stop              Stop the container
  restart           Restart the container
  status            Show container status
  logs              Show container logs
  fix-creds         Remove Docker Desktop credential helper issue
  update            Pull latest image & restart container
  backup            Backup WinBoat data to $BACKUP_DIR
  restore <file>    Restore from backup archive
  prune             Clean unused Docker resources
  install-service   Enable auto-start at boot (systemd)
  remove-service    Remove the systemd service
  game              Show retro intro / startup sequence
  help              Show this help message
EOF
}

fix_creds() {
  echo -e "${blue}Checking Docker config for invalid credential helpers...${reset}"
  CONFIG="$HOME/.docker/config.json"
  if grep -q '"credsStore":' "$CONFIG" 2>/dev/null; then
    sed -i '/"credsStore"/d' "$CONFIG"
    echo -e "${green}Removed credsStore entry from Docker config.${reset}"
  else
    echo -e "${green}No invalid credsStore found.${reset}"
  fi
}

start_container() {
  echo -e "${blue}Starting WinBoat...${reset}"
  _sfx_boot
  docker compose -f "$COMPOSE_FILE" up -d && _sfx_success || _sfx_error
  echo -e "${green}WinBoat started.${reset}"
}

stop_container() {
  echo -e "${blue}Stopping WinBoat...${reset}"
  docker compose -f "$COMPOSE_FILE" down && _sfx_shutdown || _sfx_error
  echo -e "${green}WinBoat stopped.${reset}"
}

restart_container() {
  echo -e "${blue}Restarting WinBoat...${reset}"
  _sfx_boot
  docker compose -f "$COMPOSE_FILE" down
  docker compose -f "$COMPOSE_FILE" up -d && _sfx_success || _sfx_error
}

show_status() {
  echo -e "${cyan}Container status:${reset}"
  docker ps --filter "name=$CONTAINER_NAME"
}

show_logs() {
  docker logs -f "$CONTAINER_NAME"
}

update_container() {
  echo -e "${blue}Updating WinBoat image...${reset}"
  docker compose -f "$COMPOSE_FILE" pull && restart_container
}

backup_container() {
  mkdir -p "$BACKUP_DIR"
  TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
  ARCHIVE="$BACKUP_DIR/winboat_backup_$TIMESTAMP.tar.gz"
  echo -e "${blue}Backing up to $ARCHIVE...${reset}"
  tar -czf "$ARCHIVE" "$INSTALL_DIR"
  _sfx_success
  echo -e "${green}Backup complete.${reset}"
}

restore_backup() {
  [ -z "$1" ] && { echo -e "${red}Usage: $0 restore <file>${reset}"; exit 1; }
  echo -e "${blue}Restoring from $1...${reset}"
  tar -xzf "$1" -C "$HOME"
  _sfx_success
  echo -e "${green}Restore complete.${reset}"
}

prune_docker() {
  echo -e "${blue}Cleaning unused Docker resources...${reset}"
  docker system prune -af
  _sfx_shutdown
  echo -e "${green}Docker cleaned.${reset}"
}

install_service() {
  echo -e "${blue}Creating systemd service for WinBoat...${reset}"
  SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
  sudo bash -c "cat > $SERVICE_FILE" <<EOF
[Unit]
Description=WinBoat Docker Container
After=network.target docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
User=$USER
ExecStart=/usr/bin/docker compose -f $COMPOSE_FILE up -d
ExecStop=/usr/bin/docker compose -f $COMPOSE_FILE down
Restart=on-failure
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

  sudo systemctl daemon-reload
  sudo systemctl enable "$SERVICE_NAME"
  _sfx_success
  echo -e "${green}Systemd service installed and enabled.${reset}"
  echo -e "${cyan}Manage it with:${reset}\n  sudo systemctl start winboat\n  sudo systemctl status winboat"
}

remove_service() {
  SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
  if [ -f "$SERVICE_FILE" ]; then
    echo -e "${blue}Removing WinBoat systemd service...${reset}"
    sudo systemctl disable "$SERVICE_NAME" --now
    sudo rm -f "$SERVICE_FILE"
    sudo systemctl daemon-reload
    _sfx_shutdown
    echo -e "${green}Service removed successfully.${reset}"
  else
    echo -e "${red}Service not found.${reset}"
  fi
}

# === COMMAND DISPATCH ===
ensure_audio_tools

case "$1" in
  start) start_container ;;
  stop) stop_container ;;
  restart) restart_container ;;
  status) show_status ;;
  logs) show_logs ;;
  fix-creds) fix_creds ;;
  update) update_container ;;
  backup) backup_container ;;
  restore) restore_backup "$2" ;;
  prune) prune_docker ;;
  install-service) install_service ;;
  remove-service) remove_service ;;
  game) _intro_animation ;;
  help|--help|-h|"") show_help ;;
  *) echo -e "${red}Unknown command: $1${reset}"; show_help ;;
esac
