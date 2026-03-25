# Kernel tuning via sysctl drop-in.
# Written to /etc/sysctl.d/ so settings persist across reboots and are applied
# by systemd-sysctl at boot without any extra service configuration.

echo "Applying kernel tuning..."

# ── File watchers ─────────────────────────────────────────────────────────────
# The kernel default of 8192 inotify watches is exhausted by a single mid-size
# Node.js project or Neovim with LSP active. When the limit is hit, watchers
# silently stop working — LSP diagnostics freeze, dev servers stop reloading,
# Neovim plugins drop events with no error message.
# 524288 is the standard value used by VS Code, JetBrains, and most
# developer-focused distros. The memory cost is negligible.
printf 'fs.inotify.max_user_watches=524288\n' \
  | sudo tee /etc/sysctl.d/99-doom.conf >/dev/null

sudo sysctl --system --pattern 'fs.inotify' >/dev/null

echo "Kernel tuning: OK"
