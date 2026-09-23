#!/data/data/com.termux/files/usr/bin/bash
set -e
SRC="$(cd "$(dirname "$0")" && pwd)/prestige-termux-tool-v3.2.sh"
ROOT="$HOME/.prestige-termux"
mkdir -p "$ROOT"/{config,reports,backups,data,logs}
echo "== Prestige Termux Tool v3.2 FULL =="
bash -n "$SRC"
echo "[OK] Walidacja bash -n"
if [[ -f "$ROOT/prestige" ]]; then
  B="$ROOT/backups/prestige_before_v3.2_$(date +%Y%m%d_%H%M%S).sh"
  cp "$ROOT/prestige" "$B"
  echo "[OK] Backup obecnej wersji: $B"
fi
cp "$SRC" "$ROOT/prestige"
chmod 700 "$ROOT/prestige"
cat > "$PREFIX/bin/prestige" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
exec "$ROOT/prestige" "\$@"
EOF
chmod +x "$PREFIX/bin/prestige"
echo "[OK] Zachowano config, dane, raporty i backupy."
echo "[OK] Prestige Termux Tool v3.2 FULL zainstalowany."
echo "Uruchom: prestige"
