#!/usr/bin/env bash
#
# Install cleanX:
#   curl -fsSL https://raw.githubusercontent.com/hlum/cleanX/main/install.sh | bash
#
# Uninstall:
#   curl -fsSL https://raw.githubusercontent.com/hlum/cleanX/main/install.sh | bash -s -- --uninstall
#
# Set PREFIX to choose the install directory, e.g. PREFIX=~/bin.

set -e

RAW="https://raw.githubusercontent.com/hlum/cleanX/main/cleanx"
CANDIDATES="/usr/local/bin $HOME/.local/bin"

if [ "${1:-}" = "--uninstall" ]; then
  removed=0
  for dir in ${PREFIX:-} $CANDIDATES; do
    if [ -f "$dir/cleanx" ]; then rm -f "$dir/cleanx" && echo "Removed $dir/cleanx" && removed=1; fi
  done
  [ $removed -eq 1 ] || echo "cleanX isn't installed."
  exit 0
fi

if [ "$(uname)" != "Darwin" ]; then
  echo "cleanX only runs on macOS." >&2
  exit 1
fi

if [ -n "${PREFIX:-}" ]; then
  BIN=$PREFIX
elif [ -w /usr/local/bin ]; then
  BIN=/usr/local/bin
else
  BIN=$HOME/.local/bin
fi
mkdir -p "$BIN"

# Use the local copy when run from a clone, otherwise download the latest.
here=""
[ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ] && here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
if [ -n "$here" ] && [ -f "$here/cleanx" ]; then
  cp "$here/cleanx" "$BIN/cleanx"
else
  curl -fsSL "$RAW" -o "$BIN/cleanx"
fi
chmod +x "$BIN/cleanx"

echo "✓ Installed cleanX to $BIN/cleanx"

case ":$PATH:" in
  *":$BIN:"*) echo "  Run it with: cleanx" ;;
  *)
    echo ""
    echo "  $BIN isn't on your PATH yet. Add it with:"
    echo "    echo 'export PATH=\"$BIN:\$PATH\"' >> ~/.zshrc && source ~/.zshrc"
    echo "  Then run: cleanx"
    ;;
esac
