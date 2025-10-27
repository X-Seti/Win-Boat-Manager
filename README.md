# X-Seti - Oct 25 - WinBoat-Manager

Winboat helper script, "config", "backup", "service start / stop"

Remember to chmod +x winboat-manager.sh

Usage: winboat-manager.sh [command]

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

  A simple little script will assist your voyager into Winboat.

contact me;
  keithvc1972@hotmail.com

  
