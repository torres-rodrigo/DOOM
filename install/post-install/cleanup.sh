# Remove build caches and orphaned packages.

echo "Cleaning up..."

# Paru package cache (built packages + source tarballs)
if command -v paru &>/dev/null; then
  paru -Scc --noconfirm 2>/dev/null || true
fi

echo "Cleanup: OK"
