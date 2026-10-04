#!/usr/bin/env bash
# orchestra-install.sh — makes the installer executable, then launches it

DIR="$HOME/FlakeShell/install-script"
find "$DIR" -type f -name '*.sh' -exec chmod +x {} +
exec "$DIR/orchestra-script.sh"
