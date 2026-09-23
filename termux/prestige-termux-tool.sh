#!/data/data/com.termux/files/usr/bin/bash
# PRESTIGE TERMUX TOOL
# Autor: Dominik Wasilak | GitHub: w4sy1
# v3.2.0
set -u
umask 077

APP="Prestige Termux Tool"
VER="3.2.0"
ROOT="$HOME/.prestige-termux"
CFG="$ROOT/config"
REPORTS="$ROOT/reports"
BACKUPS="$ROOT/backups"
DATA="$ROOT/data"
LOGS="$ROOT/logs"
SELF="$ROOT/prestige"
KNOWN="$DATA/known_hosts.txt"
BASELINE="$DATA/network_baseline.txt"
CONF="$CFG/prestige.conf"
mkdir -p "$CFG" "$REPORTS" "$BACKUPS" "$DATA" "$LOGS"
touch "$KNOWN"

R='\033[0m'; B='\033[1m'; GREEN='\033[38;5;46m'; BLUE='\033[38;5;39m'; PURPLE='\033[38;5;141m'; RED='\033[38;5;196m'; CYAN='\033[38;5;51m'; YELLOW='\033[38;5;220m'; GRAY='\033[38;5;245m'

have(){ command -v "$1" >/dev/null 2>&1; }
pause(){ printf "\nNaciśnij Enter, aby wrócić..."; read -r _; }
yn(){ local a; read -rp "$1 [t/N]: " a; [[ "$a" =~ ^[tTyY]$ ]]; }
notify(){ if have termux-notification; then termux-notification --title "Prestige Termux Tool" --content "$1" >/dev/null 2>&1 || true; fi; }
log(){ printf '%s | %s\n' "$(date '+%F %T')" "$*" >> "$LOGS/prestige.log"; }
status(){ have "$1" && printf "${GREEN}[OK]${R}" || printf "${RED}[BRAK]${R}"; }
is_root(){
  [[ "$(id -u)" == "0" ]] && return 0
  have su || return 1
  have timeout || return 1
  timeout 2 su -c 'id -u' </dev/null 2>/dev/null | grep -qx '0'
}

load_conf(){
  USER_NAME="${USER_NAME:-Użytkownik}"; DEVICE_NAME="${DEVICE_NAME:-$(getprop ro.product.model 2>/dev/null || echo Android)}"
  BANNER="${BANNER:-PRESTIGE}"; SHELL_MODE="${SHELL_MODE:-bash}"; LOCK_MODE="${LOCK_MODE:-none}"
  PASS_HASH="${PASS_HASH:-}"; PASS_SALT="${PASS_SALT:-}"; MONITOR_MIN="${MONITOR_MIN:-15}"
  [[ -f "$CONF" ]] && . "$CONF"
}
save_conf(){
  cat > "$CONF" <<EOF
USER_NAME=$(printf %q "$USER_NAME")
DEVICE_NAME=$(printf %q "$DEVICE_NAME")
BANNER=$(printf %q "$BANNER")
SHELL_MODE=$(printf %q "$SHELL_MODE")
LOCK_MODE=$(printf %q "$LOCK_MODE")
PASS_HASH=$(printf %q "$PASS_HASH")
PASS_SALT=$(printf %q "$PASS_SALT")
MONITOR_MIN=$(printf %q "$MONITOR_MIN")
EOF
  chmod 600 "$CONF"
}
load_conf

hash_secret(){
  local salt="$1" secret="$2"
  printf '%s' "${salt}:${secret}" | sha256sum | awk '{print $1}'
}
lock_setup(){
  clear; echo "ZABEZPIECZENIE PRESTIGE"; echo "1) Brak  2) PIN  3) Hasło"; read -rp "Wybór: " x
  case "$x" in
    1) LOCK_MODE=none; PASS_HASH=""; PASS_SALT="" ;;
    2|3)
      [[ "$x" == 2 ]] && LOCK_MODE=pin || LOCK_MODE=password
      read -rsp "Wpisz nowe hasło/PIN: " p1; echo; read -rsp "Powtórz: " p2; echo
      [[ "$p1" != "$p2" || -z "$p1" ]] && { echo "Hasła nie są zgodne."; pause; return; }
      PASS_SALT="$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')"
      PASS_HASH="$(hash_secret "$PASS_SALT" "$p1")"; unset p1 p2
      ;;
  esac
  save_conf; echo "Zapisano."; pause
}
unlock(){
  [[ "$LOCK_MODE" == "none" ]] && return 0
  local p i
  for i in 1 2 3; do
    read -rsp "Prestige ${LOCK_MODE^^}: " p; echo
    [[ "$(hash_secret "$PASS_SALT" "$p")" == "$PASS_HASH" ]] && return 0
    echo "Błędne dane."
  done
  exit 1
}

header(){
  clear
  printf "${CYAN}${B}"
  if have figlet; then figlet -f small "$BANNER" 2>/dev/null || echo "$BANNER"; else echo "╔══════════════════════════════════════════════╗"; printf "║ %-44s ║\n" "$BANNER"; echo "╚══════════════════════════════════════════════╝"; fi
  printf "${R}${B}%s v%s${R}\n" "$APP" "$VER"
  printf "%s @ %s | Android %s | ROOT: " "$USER_NAME" "$DEVICE_NAME" "$(getprop ro.build.version.release 2>/dev/null || echo '?')"
  is_root && printf "${RED}TAK${R}" || printf "NIE"
  printf " | API: "; have termux-battery-status && printf "${GREEN}OK${R}" || printf "${YELLOW}BRAK${R}"
  printf "\nGitHub: w4sy1 | by Dominik Wasilak\n"
  printf '%*s\n' "${COLUMNS:-58}" '' | tr ' ' '='
}
lvl(){ case "$1" in G) printf "${GREEN}[PODSTAWOWY]${R}";; B) printf "${BLUE}[STANDARD]${R}";; P) printf "${PURPLE}[ZAAWANSOWANY]${R}";; R) printf "${RED}[ROOT]${R}";; esac; }

pkg_install(){ pkg install -y "$@" || true; }
dependency(){
  local cmd="$1" pkgname="$2"
  have "$cmd" && return 0
  echo "Brakuje programu: $cmd (pakiet: $pkgname)"
  yn "Zainstalować teraz?" && pkg_install "$pkgname"
  have "$cmd"
}
first_run(){
  header; echo "$(lvl G) KREATOR PIERWSZEJ KONFIGURACJI"
  read -rp "Nazwa użytkownika/nick [$USER_NAME]: " x; [[ -n "$x" ]] && USER_NAME="$x"
  read -rp "Nazwa urządzenia [$DEVICE_NAME]: " x; [[ -n "$x" ]] && DEVICE_NAME="$x"
  read -rp "Tekst bannera [$BANNER]: " x; [[ -n "$x" ]] && BANNER="$x"
  echo "Powłoka: 1 Bash  2 Zsh  3 Zsh Prestige"; read -rp "Wybór [1]: " x
  case "$x" in 2) SHELL_MODE=zsh;; 3) SHELL_MODE=zsh-prestige;; *) SHELL_MODE=bash;; esac
  save_conf
  echo; echo "Profil pakietów: 1 podstawowy, 2 standard, 3 zaawansowany, 4 pełny"; read -rp "Wybór [2]: " x
  install_profile "${x:-2}"
  yn "Ustawić PIN/hasło programu?" && lock_setup
  configure_shell
  touch "$ROOT/.configured"
  echo "Konfiguracja zakończona."; pause
}

install_profile(){
  local n="$1"
  pkg update -y
  local p=(curl git wget nano procps coreutils findutils grep sed tar zip unzip)
  (( n>=2 )) && p+=(iproute2 nmap dnsutils traceroute openssh jq whois)
  (( n>=3 )) && p+=(python clang make cmake nodejs tor termux-api cronie)
  (( n>=4 )) && p+=(zsh figlet rsync file android-tools)
  for q in "${p[@]}"; do pkg_install "$q"; done
}
package_center(){
  header
  echo "$(lvl G) 1 git  2 curl  3 wget  4 nano  5 tree"
  echo "$(lvl B) 6 python  7 openssh  8 nmap  9 dnsutils  10 traceroute  11 jq"
  echo "$(lvl P) 12 zsh  13 tor  14 clang  15 nodejs  16 android-tools  17 termux-api  18 cronie"
  echo "$(lvl R) 19 root-repo"
  echo "Możesz wpisać np. 1,3,7,8 albo 'wszystkie'."
  read -rp "Wybór: " s
  [[ "$s" == "wszystkie" ]] && s="1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18"
  IFS=',' read -ra a <<< "$s"
  for i in "${a[@]}"; do
    case "${i// /}" in
      1) pkg_install git;;2) pkg_install curl;;3) pkg_install wget;;4) pkg_install nano;;5) pkg_install tree;;
      6) pkg_install python;;7) pkg_install openssh;;8) pkg_install nmap;;9) pkg_install dnsutils;;10) pkg_install traceroute;;
      11) pkg_install jq;;12) pkg_install zsh;;13) pkg_install tor;;14) pkg_install clang;;15) pkg_install nodejs;;
      16) pkg_install android-tools;;17) pkg_install termux-api;;18) pkg_install cronie;;19) pkg_install root-repo;;
    esac
  done
  pause
}
configure_shell(){
  local rc="$HOME/.bashrc"
  [[ "$SHELL_MODE" == zsh* ]] && { dependency zsh zsh || return; rc="$HOME/.zshrc"; }
  [[ -f "$rc" ]] && cp "$rc" "$BACKUPS/$(basename "$rc").$(date +%s).bak"
  sed -i '/# PRESTIGE-BEGIN/,/# PRESTIGE-END/d' "$rc" 2>/dev/null || true
  cat >> "$rc" <<EOF
# PRESTIGE-BEGIN
alias ll='ls -lah'
alias update='pkg update && pkg upgrade'
alias prestige='$SELF'
alias myip='curl -s https://api.ipify.org; echo'
PS1='\[\e[36m\]${USER_NAME}@${DEVICE_NAME}\[\e[0m\] \w > '
# PRESTIGE-END
EOF
  if [[ "$SHELL_MODE" == "zsh-prestige" ]]; then
    cat >> "$rc" <<'EOF'
autoload -Uz compinit && compinit
setopt AUTO_CD HIST_IGNORE_DUPS SHARE_HISTORY
HISTFILE=$HOME/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
EOF
  fi
  echo "Skonfigurowano: $rc"
}
personalize(){
  while true; do header; echo "PERSONALIZACJA"
    echo "1 Nick  2 Nazwa urządzenia  3 Banner  4 Bash  5 Zsh  6 Zsh Prestige  7 Zastosuj konfigurację  8 PIN/hasło  0 Powrót"
    read -rp "Wybór: " x
    case "$x" in
      1) read -rp "Nick: " USER_NAME; save_conf;;2) read -rp "Nazwa urządzenia: " DEVICE_NAME; save_conf;;
      3) read -rp "Banner: " BANNER; save_conf;;4) SHELL_MODE=bash; save_conf;;5) SHELL_MODE=zsh; save_conf;;
      6) SHELL_MODE=zsh-prestige; save_conf;;7) configure_shell; pause;;8) lock_setup;;0) return;;
    esac
  done
}
network_info(){
  dependency ip iproute2 || { pause; return; }
  header; echo "$(lvl G) SIEĆ"
  ip -br addr; echo; ip route; echo
  echo "Publiczne IP:"; dependency curl curl && curl -s --max-time 6 https://api.ipify.org; echo
  echo; echo "DNS:"; getprop | grep -Ei '\.dns|dns\]' | head -20 || true
  pause
}
scan_lan(){
  dependency nmap nmap || { pause; return; }; dependency ip iproute2 || { pause; return; }
  local net out
  net="$(ip route | awk '$1 ~ /^[0-9]+\./ && $1 ~ /\// {print $1; exit}')"
  read -rp "Podsieć [$net]: " x; net="${x:-$net}"
  [[ -z "$net" ]] && { echo "Nie wykryto podsieci."; pause; return; }
  out="$REPORTS/lan_$(date +%Y%m%d_%H%M%S).txt"
  echo "Skanuję własną/administracyjnie dozwoloną sieć: $net"
  nmap -sn "$net" | tee "$out"
  pause
}
nmap_menu(){
  dependency nmap nmap || { pause; return; }
  header; echo "$(lvl B) NMAP"
  echo "1 Host discovery LAN  2 Top 100 portów  3 Wersje usług  4 Własne parametry  0 Powrót"
  read -rp "Wybór: " x
  case "$x" in
    1) scan_lan;;
    2) read -rp "Host/IP: " h; nmap --top-ports 100 "$h"; pause;;
    3) read -rp "Host/IP: " h; nmap -sV "$h"; pause;;
    4) read -rp "Parametry Nmap: " args; read -r -a av <<< "$args"; nmap "${av[@]}"; pause;;
  esac
}
monitor_once(){
  dependency nmap nmap || return 1; dependency ip iproute2 || return 1
  local net tmp new=0
  net="$(ip route | awk '$1 ~ /^[0-9]+\./ && $1 ~ /\// {print $1; exit}')"; [[ -z "$net" ]] && return 1
  tmp="$(mktemp)"
  nmap -sn "$net" -oG - 2>/dev/null | awk '/Up$/{print $2}' | sort -u > "$tmp"
  if [[ ! -s "$BASELINE" ]]; then cp "$tmp" "$BASELINE"; echo "Utworzono stan bazowy."; else
    while read -r ipx; do
      if ! grep -qxF "$ipx" "$BASELINE"; then echo "NOWY HOST: $ipx"; notify "Nowe urządzenie/host w LAN: $ipx"; log "NEW_HOST $ipx"; new=1; fi
    done < "$tmp"
    [[ "$new" == 0 ]] && echo "Brak nowych hostów względem stanu bazowego."
  fi
  cp "$tmp" "$DATA/last_scan.txt"; rm -f "$tmp"
}
monitor_menu(){
  while true; do header; echo "$(lvl P) MONITOR SIECI"
    echo "1 Skan teraz  2 Ustaw stan bazowy  3 Pokaż stan bazowy  4 Harmonogram cron  5 Log alertów  0 Powrót"
    read -rp "Wybór: " x
    case "$x" in
      1) monitor_once; pause;;
      2) rm -f "$BASELINE"; monitor_once; pause;;
      3) cat "$BASELINE" 2>/dev/null || echo "Brak."; pause;;
      4) cron_setup;;
      5) tail -100 "$LOGS/prestige.log" 2>/dev/null; pause;;
      0) return;;
    esac
  done
}
cron_setup(){
  dependency crond cronie || { pause; return; }
  read -rp "Co ile minut skanować LAN? [15]: " m; m="${m:-15}"
  [[ "$m" =~ ^[0-9]+$ ]] || { echo "Błędna wartość."; pause; return; }
  ((m<5)) && m=5
  MONITOR_MIN="$m"; save_conf
  local job="*/$m * * * * $SELF --monitor >/dev/null 2>&1"
  (crontab -l 2>/dev/null | grep -v "$SELF --monitor"; echo "$job") | crontab -
  crond 2>/dev/null || true
  echo "Ustawiono monitoring co $m min. Android może zatrzymywać procesy w tle; dla trwałości warto użyć Termux:Boot i wyłączyć optymalizację baterii dla Termuxa."
  pause
}
security(){
  header; echo "$(lvl P) KONTROLA BEZPIECZEŃSTWA"
  echo "Aktualizacje:"; apt list --upgradable 2>/dev/null | head -30
  echo; echo "Nasłuchujące gniazda:"
  if have ss; then ss -lntu; else echo "Brak ss. Zainstaluj iproute2."; fi
  echo; echo "Procesy widoczne dla Termuxa:"; ps -A | head -50
  echo; echo "Uwaga: bez roota Android nie daje Termuxowi pełnego wglądu w ruch i procesy innych aplikacji."
  pause
}
ssh_menu(){
  dependency ssh openssh || { pause; return; }
  while true; do header; echo "$(lvl B) SSH"
    echo "1 Status  2 Uruchom sshd  3 Zatrzymaj  4 Utwórz klucz Ed25519  5 authorized_keys  6 Ustaw hasło użytkownika  7 Dane połączenia  0 Powrót"
    read -rp "Wybór: " x
    case "$x" in
      1) pgrep -a sshd || echo "sshd nie działa"; pause;;
      2) sshd; echo "sshd uruchomiony (Termux domyślnie port 8022)."; pause;;
      3) pkill sshd 2>/dev/null || true; pause;;
      4) ssh-keygen -t ed25519; pause;;
      5) mkdir -p "$HOME/.ssh"; chmod 700 "$HOME/.ssh"; touch "$HOME/.ssh/authorized_keys"; chmod 600 "$HOME/.ssh/authorized_keys"; nano "$HOME/.ssh/authorized_keys";;
      6) passwd;;
      7) dependency ip iproute2; echo "Użytkownik: $(whoami)"; ip -br addr 2>/dev/null; echo "Przykład: ssh -p 8022 $(whoami)@IP_TELEFONU"; pause;;
      0) return;;
    esac
  done
}
tor_menu(){
  dependency tor tor || { pause; return; }
  while true; do header; echo "$(lvl P) TOR I PRYWATNOŚĆ"; echo "1 Start Tor  2 Stop  3 Status  4 Test SOCKS  5 Wyjaśnienie  0 Powrót"; read -rp "Wybór: " x
    case "$x" in
      1) tor --RunAsDaemon 1; pause;;2) pkill tor 2>/dev/null || true; pause;;3) pgrep -a tor || echo "Tor nie działa"; pause;;
      4) dependency curl curl; curl --socks5-hostname 127.0.0.1:9050 --max-time 15 https://check.torproject.org/api/ip || true; echo; pause;;
      5) echo "Tor udostępnia lokalny SOCKS proxy. Program korzysta z Tor tylko wtedy, gdy jawnie skierujesz jego ruch przez proxy. Samo uruchomienie Tor nie przekierowuje automatycznie całego Androida."; pause;;
      0) return;;
    esac
  done
}
adb_menu(){
  dependency adb android-tools || { pause; return; }
  while true; do header; echo "$(lvl P) ANDROID / ADB"; echo "1 adb devices  2 Wireless connect  3 Informacje  4 Instaluj APK  5 Logcat  6 Lista pakietów  0 Powrót"; read -rp "Wybór: " x
    case "$x" in
      1) adb devices -l; pause;;2) read -rp "IP:PORT: " a; adb connect "$a"; pause;;
      3) adb shell getprop 2>/dev/null | head -100; pause;;4) read -rp "Ścieżka APK: " a; adb install "$a"; pause;;
      5) adb logcat;;6) adb shell pm list packages | less;;0) return;;
    esac
  done
}
api_menu(){
  header; echo "$(lvl B) TERMUX:API"
  echo "CLI termux-api nie wystarcza sam. Potrzebna jest także kompatybilna aplikacja Termux:API z tego samego źródła/podpisu co Termux."
  echo "1 Bateria  2 Schowek  3 Powiadomienie testowe  4 WiFi info  5 Otwórz URL  6 Odtwórz plik audio  0 Powrót"
  read -rp "Wybór: " x
  case "$x" in
    1) dependency termux-battery-status termux-api && termux-battery-status; pause;;
    2) dependency termux-clipboard-get termux-api && termux-clipboard-get; pause;;
    3) dependency termux-notification termux-api && termux-notification --title "Prestige" --content "Termux:API działa"; pause;;
    4) dependency termux-wifi-connectioninfo termux-api && termux-wifi-connectioninfo; pause;;
    5) read -rp "URL: " u; termux-open-url "$u"; pause;;
    6) read -rp "Plik audio: " f; termux-media-player play "$f"; pause;;
  esac
}
dev_menu(){
  header; echo "$(lvl B) PROGRAMOWANIE"; echo "1 Python  2 Git  3 Node.js  4 Clang/C  5 Utwórz projekt Python  0 Powrót"; read -rp "Wybór: " x
  case "$x" in
    1) dependency python python && python; pause;;2) dependency git git && git --version; pause;;
    3) dependency node nodejs && node; pause;;4) dependency clang clang && clang --version; pause;;
    5) dependency python python; read -rp "Nazwa projektu: " n; mkdir -p "$HOME/projects/$n"; printf 'print("Hello from Prestige")\n' > "$HOME/projects/$n/main.py"; echo "$HOME/projects/$n"; pause;;
  esac
}
root_menu(){
  header; echo "$(lvl R) ROOT"
  if ! is_root; then echo "ROOT nie został wykryty. Moduły wymagające pełnego dostępu są wyłączone."; echo "Prestige nie rootuje telefonu i nie omija zabezpieczeń Androida."; pause; return; fi
  echo "1 Informacje root  2 Interfejsy  3 Routing  4 tcpdump podgląd  0 Powrót"; read -rp "Wybór: " x
  case "$x" in
    1) su -c id; pause;;2) su -c 'ip addr'; pause;;3) su -c 'ip route'; pause;;
    4) dependency tcpdump tcpdump && su -c 'tcpdump -nn -c 50'; pause;;
  esac
}
guide(){
  while true; do header; echo "PORADNIK TERMUXA"
    echo "1 Nawigacja  2 Pliki  3 Pakiety  4 Git  5 SSH  6 Nmap  7 Tor  8 Internet/URL  9 Muzyka  10 Ściąga  0 Powrót"
    read -rp "Wybór: " x
    case "$x" in
      1) echo "pwd = gdzie jestem | ls = lista | cd KATALOG = wejdź | cd .. = poziom wyżej | cd ~ = katalog domowy";;
      2) echo "mkdir katalog | cp źródło cel | mv źródło cel | rm plik | nano plik";;
      3) echo "pkg search nazwa | pkg install nazwa | pkg update | pkg upgrade";;
      4) echo "git clone URL | git status | git add . | git commit -m 'opis' | git pull | git push";;
      5) echo "sshd | ssh -p 8022 użytkownik@IP | scp -P 8022 plik użytkownik@IP:~/";;
      6) echo "nmap -sn PODSIEĆ = wykrywanie hostów | nmap --top-ports 100 HOST | nmap -sV HOST";;
      7) echo "tor uruchamia lokalny SOCKS zwykle 127.0.0.1:9050. Aplikacja musi zostać skonfigurowana do korzystania z proxy.";;
      8) echo "curl URL pobiera treść | wget URL pobiera plik | termux-open-url URL otwiera stronę w Androidzie";;
      9) echo "termux-media-player play /ścieżka/plik.mp3 | pause | stop";;
      10) echo "clear | history | whoami | uname -a | df -h | free -h | ps -A | ip addr | ip route | ping HOST";;
      0) return;;
    esac
    pause
  done
}
backup_menu(){
  header; local f="$BACKUPS/prestige_$(date +%Y%m%d_%H%M%S).tar.gz"
  tar -czf "$f" --exclude="$BACKUPS" "$ROOT" "$HOME/.bashrc" "$HOME/.zshrc" 2>/dev/null || tar -czf "$f" --exclude="$BACKUPS" "$ROOT"
  echo "Backup: $f"; pause
}
report(){
  header; local f="$REPORTS/report_$(date +%Y%m%d_%H%M%S).txt"
  {
    echo "PRESTIGE TERMUX TOOL REPORT"; date; echo "Version: $VER"; echo "User: $USER_NAME"; echo "Device: $DEVICE_NAME"
    echo; echo "[ANDROID]"; getprop ro.product.model; getprop ro.build.version.release
    echo; echo "[UNAME]"; uname -a
    echo; echo "[DISK]"; df -h "$HOME"
    echo; echo "[RAM]"; free -h 2>&1
    echo; echo "[NETWORK]"; have ip && { ip -br addr; ip route; } || echo "iproute2 missing"
    echo; echo "[LISTEN]"; have ss && ss -lntu || echo "ss missing"
    echo; echo "[TOOLS]"; for c in git curl python nmap ssh tor adb zsh; do printf '%-10s ' "$c"; have "$c" && echo OK || echo BRAK; done
  } | tee "$f"
  echo; echo "Zapisano: $f"; pause
}
update_all(){
  header; echo "Aktualizacja pakietów Termuxa."; pkg update -y && pkg upgrade -y; pause
}
diagnostics(){
  header; echo "DIAGNOSTYKA PRESTIGE"
  for pair in "curl:curl" "git:git" "ip:iproute2" "ss:iproute2" "nmap:nmap" "ssh:openssh" "python:python" "tor:tor" "adb:android-tools" "zsh:zsh"; do
    c="${pair%%:*}"; p="${pair##*:}"; printf "%-16s " "$c"; have "$c" && echo -e "${GREEN}OK${R}" || echo -e "${RED}BRAK ($p)${R}"
  done
  echo; echo "ROOT: $(is_root && echo TAK || echo NIE)"; echo "Config: $CONF"; echo "Log: $LOGS/prestige.log"; pause
}
# ========================= PRESTIGE V3 EXTENSIONS =========================

section(){ printf "\n${B}${1}${R}\n\n"; }
item(){ printf " %2s. %s\n" "$1" "$2"; }
back(){ item 0 "Powrót"; }

phone_info(){
  header; section "[PODSTAWOWY] INFORMACJE O TELEFONIE"
  echo "Model: $(getprop ro.product.model 2>/dev/null)"
  echo "Producent: $(getprop ro.product.manufacturer 2>/dev/null)"
  echo "Android: $(getprop ro.build.version.release 2>/dev/null)"
  echo "SDK: $(getprop ro.build.version.sdk 2>/dev/null)"
  echo "ABI: $(getprop ro.product.cpu.abi 2>/dev/null)"
  echo "Kernel: $(uname -r)"
  echo "Host: $(hostname 2>/dev/null || true)"
  echo; echo "[Pamięć]"; df -h "$HOME" 2>/dev/null
  echo; echo "[RAM]"; free -h 2>/dev/null || true
  echo; echo "[Bateria]"
  have termux-battery-status && termux-battery-status || echo "Termux:API niedostępne."
  pause
}

tools_menu(){
  while true; do header; section "[PODSTAWOWY] NARZĘDZIA SYSTEMOWE"
    item 1 "Procesy"; item 2 "RAM"; item 3 "Dysk"; item 4 "Uname / kernel"
    item 5 "Zmienne środowiskowe"; item 6 "Historia poleceń"; item 7 "Największe pliki w HOME"
    item 8 "Lista zainstalowanych pakietów"; item 9 "Wyszukaj plik"; back
    read -rp "PRESTIGE/NARZĘDZIA> " x
    case "$x" in
      1) ps -A | less;; 2) free -h; pause;; 3) df -h; pause;; 4) uname -a; pause;;
      5) env | sort | less;; 6) history | tail -100; pause;;
      7) du -ah "$HOME" 2>/dev/null | sort -h | tail -40; pause;;
      8) pkg list-installed 2>/dev/null | less;;
      9) read -rp "Nazwa/wzorzec: " q; find "$HOME" -iname "*$q*" 2>/dev/null | head -100; pause;;
      0) return;;
    esac
  done
}

internet_diag(){
  while true; do header; section "[PODSTAWOWY] DIAGNOSTYKA INTERNETU"
    item 1 "Ping 1.1.1.1"; item 2 "Ping domeny"; item 3 "DNS domeny"; item 4 "Traceroute"
    item 5 "Publiczny IP"; item 6 "Nagłówki HTTP/HTTPS"; item 7 "Test pobierania curl"
    item 8 "Routing"; item 9 "Pełny szybki test Internetu"; back
    read -rp "PRESTIGE/INTERNET> " x
    case "$x" in
      1) ping -c 4 1.1.1.1; pause;;
      2) read -rp "Host: " h; ping -c 4 "$h"; pause;;
      3) dependency dig dnsutils || continue; read -rp "Domena: " h; dig "$h"; pause;;
      4) dependency traceroute traceroute || continue; read -rp "Host: " h; traceroute "$h"; pause;;
      5) dependency curl curl && { curl -4 -s https://api.ipify.org; echo; }; pause;;
      6) dependency curl curl || continue; read -rp "URL: " u; curl -I --max-time 10 "$u"; pause;;
      7) dependency curl curl && curl -L -o /dev/null -sS -w 'HTTP:%{http_code}\nDNS:%{time_namelookup}s\nConnect:%{time_connect}s\nTTFB:%{time_starttransfer}s\nTotal:%{time_total}s\nSpeed:%{speed_download} B/s\n' https://speed.cloudflare.com/__down?bytes=5000000; pause;;
      8) dependency ip iproute2 && ip route; pause;;
      9) echo "== IP =="; curl -4 -s --max-time 8 https://api.ipify.org; echo
         echo "== Gateway =="; ip route 2>/dev/null | head
         echo "== Ping IP =="; ping -c 2 1.1.1.1
         echo "== DNS =="; ping -c 2 example.com; pause;;
      0) return;;
    esac
  done
}

wifi_menu(){
  while true; do header; section "[STANDARD] WI-FI"
    item 1 "Informacje Wi-Fi (Termux:API)"; item 2 "IP i interfejsy"; item 3 "Gateway i routing"
    item 4 "Skan urządzeń w aktualnej podsieci"; item 5 "Znane hosty / baseline"; back
    read -rp "PRESTIGE/WIFI> " x
    case "$x" in
      1) dependency termux-wifi-connectioninfo termux-api && termux-wifi-connectioninfo; pause;;
      2) dependency ip iproute2 && ip -br addr; pause;;
      3) dependency ip iproute2 && ip route; pause;;
      4) scan_lan;;
      5) echo "Baseline: $BASELINE"; [[ -f "$BASELINE" ]] && cat "$BASELINE" || echo "Brak baseline."; pause;;
      0) return;;
    esac
  done
}

git_menu_v3(){
  while true; do header; section "[STANDARD] GIT / GITHUB"
    item 1 "Status Git"; item 2 "Ustaw imię i e-mail"; item 3 "Klonuj repozytorium"
    item 4 "git pull"; item 5 "git add + commit"; item 6 "git push"
    item 7 "Lista remote"; item 8 "Dodaj/zmień origin"; item 9 "GitHub CLI gh"
    item 10 "Log ostatnich commitów"; back
    read -rp "PRESTIGE/GIT> " x
    case "$x" in
      1) dependency git git && git status; pause;;
      2) dependency git git || continue; read -rp "Imię/nick: " n; read -rp "E-mail: " e; git config --global user.name "$n"; git config --global user.email "$e"; pause;;
      3) dependency git git || continue; read -rp "URL repo: " u; read -rp "Katalog docelowy [HOME]: " d; d="${d:-$HOME}"; cd "$d" && git clone "$u"; pause;;
      4) git pull; pause;; 5) read -rp "Opis commita: " m; git add . && git commit -m "$m"; pause;;
      6) git push; pause;; 7) git remote -v; pause;;
      8) read -rp "URL origin: " u; git remote get-url origin >/dev/null 2>&1 && git remote set-url origin "$u" || git remote add origin "$u"; pause;;
      9) pkg_install gh; gh auth status 2>/dev/null || gh auth login; pause;;
      10) git log --oneline --decorate -20; pause;; 0) return;;
    esac
  done
}

logcat_menu(){
  dependency adb android-tools || { pause; return; }
  while true; do header; section "[ZAAWANSOWANY] LOGCAT"
    item 1 "Logcat urządzenia ADB"; item 2 "Tylko błędy"; item 3 "Wyczyść logcat"
    item 4 "Zapisz logcat do pliku"; item 5 "Filtruj tekst"; back
    read -rp "PRESTIGE/LOGCAT> " x
    case "$x" in
      1) adb logcat;;
      2) adb logcat '*:E';;
      3) adb logcat -c; pause;;
      4) f="$REPORTS/logcat_$(date +%Y%m%d_%H%M%S).txt"; adb logcat -d > "$f"; echo "$f"; pause;;
      5) read -rp "Tekst: " q; adb logcat -d | grep -i -- "$q" | less;;
      0) return;;
    esac
  done
}

dns_menu(){
  while true; do header; section "[ZAAWANSOWANY] DNS / WHOIS / ROUTING"
    item 1 "dig"; item 2 "nslookup"; item 3 "WHOIS"; item 4 "Traceroute"; item 5 "Routing"
    item 6 "Adresy interfejsów"; item 7 "ARP / sąsiedzi"; back
    read -rp "PRESTIGE/DNS> " x
    case "$x" in
      1) dependency dig dnsutils || continue; read -rp "Domena: " h; dig "$h"; pause;;
      2) dependency nslookup dnsutils || continue; read -rp "Domena: " h; nslookup "$h"; pause;;
      3) dependency whois whois || continue; read -rp "Domena/IP: " h; whois "$h" | less;;
      4) dependency traceroute traceroute || continue; read -rp "Host: " h; traceroute "$h"; pause;;
      5) ip route; pause;; 6) ip -br addr; pause;; 7) ip neigh 2>&1; pause;; 0) return;;
    esac
  done
}

traffic_menu(){
  while true; do header; section "[ZAAWANSOWANY] ANALIZA RUCHU"
    echo "Android bez ROOT ogranicza globalny podsłuch ruchu. Ta sekcja nie udaje dostępu, którego system nie daje."
    item 1 "Nasłuchujące sockety (ss)"; item 2 "Aktywne połączenia (ss)"
    item 3 "Statystyki socketów"; item 4 "Procesy sieciowe dostępne dla Termuxa"
    item 5 "ROOT: tcpdump 50 pakietów"; back
    read -rp "PRESTIGE/RUCH> " x
    case "$x" in
      1) dependency ss iproute2 && ss -lntu; pause;;
      2) dependency ss iproute2 && ss -ntup 2>&1; pause;;
      3) dependency ss iproute2 && ss -s; pause;;
      4) ps -A | less;;
      5) root_tcpdump;;
      0) return;;
    esac
  done
}

root_tcpdump(){
  header; section "[ROOT] TCPDUMP"
  is_root || { echo "ROOT nie jest dostępny. Nie uruchamiam przechwytywania."; pause; return; }
  dependency tcpdump tcpdump || { pause; return; }
  su -c 'tcpdump -nn -c 50'; pause
}

root_network(){
  header; section "[ROOT] SIEĆ"
  is_root || { echo "ROOT niedostępny."; pause; return; }
  echo "[INTERFEJSY]"; su -c 'ip addr'; echo; echo "[ROUTING]"; su -c 'ip route'
  echo; echo "[SOCKETY]"; su -c 'ss -ntulp 2>/dev/null || true'; pause
}

root_processes(){
  header; section "[ROOT] PROCESY / SOCKETY"
  is_root || { echo "ROOT niedostępny."; pause; return; }
  su -c 'ps -A'; pause
}

cron_menu_v3(){
  while true; do header; section "[ZAAWANSOWANY] AUTOMATYZACJE / CRON"
    item 1 "Konfiguruj monitor sieci z v1"; item 2 "Pokaż crontab"; item 3 "Uruchom crond"
    item 4 "Zatrzymaj crond"; item 5 "Test monitora teraz"; back
    read -rp "PRESTIGE/CRON> " x
    case "$x" in
      1) cron_setup;;
      2) crontab -l 2>/dev/null || echo "Brak wpisów."; pause;;
      3) dependency crond cronie && crond; echo "crond uruchomiony."; pause;;
      4) pkill crond 2>/dev/null || true; echo "crond zatrzymany."; pause;;
      5) monitor_once; pause;;
      0) return;;
    esac
  done
}

restore_menu(){
  header; section "[SYSTEM] RESTORE"
  ls -1t "$BACKUPS"/*.tar.gz 2>/dev/null | head -20 || { echo "Brak backupów."; pause; return; }
  read -rp "Pełna ścieżka backupu do przywrócenia (0 = anuluj): " f
  [[ "$f" == 0 ]] && return
  [[ -f "$f" ]] || { echo "Nie znaleziono pliku."; pause; return; }
  echo "Backup zostanie rozpakowany do HOME. Istniejące pliki mogą zostać nadpisane."
  yn "Kontynuować?" && tar -xzf "$f" -C "$HOME"
  pause
}

command_center(){
  while true; do header; section "[SYSTEM] COMMAND CENTER"
    echo "Wpisz hasło, np. nmap, wifi, git, ssh, tor, adb, raport, backup, cron, root."
    echo "0 = powrót"
    read -rp "SZUKAJ> " q
    case "${q,,}" in
      0) return;; *nmap*) nmap_menu;; *wifi*|*sieć*) wifi_menu;; *git*) git_menu_v3;;
      *ssh*) ssh_menu;; *tor*) tor_menu;; *adb*) adb_menu;; *log*) logcat_menu;;
      *raport*) report;; *backup*) backup_menu;; *cron*|*automat*) cron_menu_v3;;
      *root*) root_menu;; *dns*|*whois*) dns_menu;; *internet*) internet_diag;;
      *) echo "Brak skrótu dla: $q"; pause;;
    esac
  done
}

prestige_update(){
  header; section "[SYSTEM] AKTUALIZACJA PRESTIGE"
  echo "Aktualizacja online zostanie aktywowana po publikacji stabilnego repozytorium w4sy1."
  echo "Obecna wersja: $VER"
  pause
}

main_menu(){
  while true; do
    header
    section "${GREEN}[ PODSTAWOWY ]${R}"
    item 1 "Informacje o telefonie"
    item 2 "Pierwsza konfiguracja / konfiguruj od zera"
    item 3 "Personalizacja Termuxa"
    item 4 "Pakiety i instalator"
    item 5 "Narzędzia systemowe"
    item 6 "Diagnostyka Internetu"

    section "${BLUE}[ STANDARD ]${R}"
    item 7 "Centrum sieci"
    item 8 "Wi-Fi"
    item 9 "Nmap i profile skanowania"
    item 10 "Git / GitHub"
    item 11 "SSH / SFTP / SCP"
    item 12 "Programowanie"
    item 13 "Termux:API"
    item 14 "Android / ADB"

    section "${PURPLE}[ ZAAWANSOWANY ]${R}"
    item 15 "Monitor sieci / baseline LAN"
    item 16 "Automatyzacje / Cron"
    item 17 "Kontrola bezpieczeństwa"
    item 18 "Logcat"
    item 19 "Tor / prywatność"
    item 20 "Analiza ruchu i socketów"
    item 21 "DNS / WHOIS / routing"

    section "${RED}[ ROOT ]${R}"
    item 22 "Centrum ROOT"
    item 23 "Tcpdump"
    item 24 "Sieć ROOT"
    item 25 "Procesy / sockety ROOT"

    section "${CYAN}[ SYSTEM / PRESTIGE ]${R}"
    item 26 "Pełny raport urządzenia"
    item 27 "Backup Prestige"
    item 28 "Restore"
    item 29 "Diagnostyka Prestige"
    item 30 "Aktualizacja Termuxa i pakietów"
    item 31 "Aktualizacja Prestige"
    item 32 "Poradnik / baza komend"
    item 33 "Command Center / wyszukiwarka"
    echo
    item 0 "Wyjście"
    echo
    read -rp "PRESTIGE> " x
    case "$x" in
      1) phone_info;; 2) first_run;; 3) personalize;; 4) package_center;; 5) tools_menu;; 6) internet_diag;;
      7) network_info;; 8) wifi_menu;; 9) nmap_menu;; 10) git_menu_v3;; 11) ssh_menu;; 12) dev_menu;;
      13) api_menu;; 14) adb_menu;; 15) monitor_menu;; 16) cron_menu_v3;; 17) security;; 18) logcat_menu;;
      19) tor_menu;; 20) traffic_menu;; 21) dns_menu;; 22) root_menu;; 23) root_tcpdump;; 24) root_network;;
      25) root_processes;; 26) report;; 27) backup_menu;; 28) restore_menu;; 29) diagnostics;; 30) update_all;;
      31) prestige_update;; 32) guide;; 33) command_center;; 0) exit 0;;
      *) echo "Nieprawidłowy wybór."; sleep 1;;
    esac
  done
}

install_self(){
  local src
  src="$(realpath "$0" 2>/dev/null || echo "$0")"
  if [[ "$src" != "$SELF" ]]; then
    cp "$src" "$SELF"
    chmod 700 "$SELF"
  fi
  mkdir -p "$PREFIX/bin"
  cat > "$PREFIX/bin/prestige" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
exec "$SELF" "\$@"
EOF
  chmod +x "$PREFIX/bin/prestige"
}

main(){
  [[ "${1:-}" == "--monitor" ]] && { load_conf; monitor_once; exit $?; }
  install_self
  [[ ! -f "$ROOT/.configured" ]] && first_run
  load_conf
  unlock
  main_menu
}

# ================= V3.1 NETWORK UPDATE =================
net_iface(){ ip route 2>/dev/null|awk '/default/{print $5;exit}'; }
net_gw(){ ip route 2>/dev/null|awk '/default/{print $3;exit}'; }
net_ip(){ local i="$(net_iface)"; ip -4 addr show dev "$i" 2>/dev/null|awk '/inet /{print $2;exit}'|cut -d/ -f1; }
net_prefix(){ local i="$(net_iface)"; ip -4 addr show dev "$i" 2>/dev/null|awk '/inet /{print $2;exit}'; }
net_cidr_v31(){ local p="$(net_prefix)"; [[ -z "$p" ]]&&return 1; python - "$p" <<'PY'
import ipaddress,sys
try: print(ipaddress.ip_interface(sys.argv[1]).network)
except: raise SystemExit(1)
PY
}
net_snapshot_v31(){
 echo "Interfejs : $(net_iface)"; echo "IP        : $(net_ip)"; echo "Prefiks   : $(net_prefix)"
 echo "Gateway   : $(net_gw)"; printf "Public IP : "; curl -4 -sS --max-time 5 https://api.ipify.org 2>/dev/null||true; echo
}
net_health_v31(){
 header; section "[STANDARD] DIAGNOSTYKA SIECI 3.1"; local g="$(net_gw)"
 printf "%-25s " "Lokalny IPv4"; [[ -n "$(net_ip)" ]]&&echo "[OK] $(net_ip)"||echo "[UWAGA]"
 printf "%-25s " "Gateway"; [[ -n "$g" ]]&&ping -c 1 -W 2 "$g" >/dev/null 2>&1&&echo "[OK] $g"||echo "[UWAGA]"
 printf "%-25s " "Internet po IP"; ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1&&echo "[OK]"||echo "[UWAGA]"
 printf "%-25s " "DNS"; ping -c 1 -W 2 example.com >/dev/null 2>&1&&echo "[OK]"||echo "[UWAGA]"
 printf "%-25s " "HTTPS"; curl -IsS --max-time 6 https://example.com >/dev/null 2>&1&&echo "[OK]"||echo "[UWAGA]"
 pause
}
nmap_v31(){
 dependency nmap nmap||{ pause;return; }
 while true;do header;section "[STANDARD] NMAP 3.1";echo "Do własnych lub autoryzowanych hostów/sieci."
 item 1 "Wykryj hosty w mojej podsieci";item 2 "Szybki skan hosta";item 3 "Top 1000 TCP";item 4 "Usługi i wersje"
 item 5 "Wszystkie porty TCP";item 6 "Wybrane porty";item 7 "Top 20 UDP";item 8 "Traceroute";item 9 "Własne parametry"
 item 10 "Skan usług + zapisz raport";item 11 "Historia raportów";back;read -rp "PRESTIGE/NMAP> " x
 case "$x" in
 1)c="$(net_cidr_v31 2>/dev/null)";[[ -z "$c" ]]&&read -rp "CIDR: " c;nmap -sn "$c";pause;;
 2)read -rp "Host/IP: " h;nmap -T4 --top-ports 100 "$h";pause;;
 3)read -rp "Host/IP: " h;nmap -T4 "$h";pause;;4)read -rp "Host/IP: " h;nmap -sV "$h";pause;;
 5)read -rp "Host/IP: " h;nmap -p- "$h";pause;;6)read -rp "Host/IP: " h;read -rp "Porty: " p;nmap -p "$p" "$h";pause;;
 7)read -rp "Host/IP: " h;nmap -sU --top-ports 20 "$h";pause;;8)read -rp "Host/IP: " h;nmap --traceroute "$h";pause;;
 9)read -rp "Host/IP: " h;read -rp "Parametry: " a;read -ra aa<<<"$a";nmap "${aa[@]}" "$h";pause;;
 10)read -rp "Host/IP: " h;f="$REPORTS/nmap_$(date +%Y%m%d_%H%M%S).txt";nmap -sV --top-ports 1000 "$h"|tee "$f";echo "Raport: $f";pause;;
 11)ls -1t "$REPORTS"/nmap_*.txt 2>/dev/null|head -30||echo "Brak raportów.";pause;;0)return;;esac;done
}
lan_radar_scan(){
 dependency nmap nmap||{ pause;return; };dependency python python||{ pause;return; }
 local c="$(net_cidr_v31 2>/dev/null)" now="$(date '+%F %T')" cur="$DATA/lan_current.txt" known="$DATA/lan_known.tsv" raw="$DATA/lan_raw.txt"
 [[ -z "$c" ]]&&read -rp "CIDR: " c;touch "$known";echo "Skanuję $c..."
 nmap -sn "$c" -oG "$raw" >/dev/null;awk '/Status: Up/{print $2}' "$raw"|sort -V>"$cur"
 python - "$cur" "$known" "$DATA/lan_new.txt" "$now" <<'PY'
import sys,pathlib
curf,kf,nf,now=sys.argv[1:];cur=set(pathlib.Path(curf).read_text().split());p=pathlib.Path(kf);known={}
for l in p.read_text().splitlines():
 a=l.split("\t")
 if a: known[a[0]]=a
new=cur-set(known);pathlib.Path(nf).write_text("\n".join(sorted(new))+("\n" if new else ""))
for ip in cur:
 if ip not in known: known[ip]=[ip,now,now,""]
 else:
  while len(known[ip])<4:known[ip].append("")
  known[ip][2]=now
p.write_text("\n".join("\t".join(known[k]) for k in sorted(known))+"\n")
PY
 while read -r ip;do [[ -z "$ip" ]]&&continue;grep -qx "$ip" "$DATA/lan_new.txt"&&st="[NOWE]"||st="[ZNANE]";printf "%-16s %s\n" "$ip" "$st";done<"$cur"
 [[ -s "$DATA/lan_new.txt" ]]&&{ echo;echo "NOWE:";cat "$DATA/lan_new.txt";notify "Prestige LAN Radar: nowe urządzenie w LAN."; }
 echo;echo "Radar wykrywa zmiany hostów w LAN. Nie jest detektorem skanowania portów.";pause
}
lan_radar(){
 while true;do header;section "[ZAAWANSOWANY] LAN RADAR 3.1";item 1 "Skanuj i porównaj z bazą";item 2 "Baza znanych hostów";item 3 "Nadaj nazwę urządzeniu"
 item 4 "Ostatnio wykryte nowe hosty";item 5 "Aktualnie aktywne hosty";item 6 "Resetuj bazę";back;read -rp "PRESTIGE/RADAR> " x
 case "$x" in 1)lan_radar_scan;;2)cat "$DATA/lan_known.tsv" 2>/dev/null||echo "Brak.";pause;;
 3)read -rp "IP: " ip;read -rp "Nazwa: " n;python - "$DATA/lan_known.tsv" "$ip" "$n" <<'PY'
import sys,pathlib
f,ip,n=sys.argv[1:];p=pathlib.Path(f);out=[];hit=False
for l in p.read_text().splitlines():
 a=l.split("\t")
 if a and a[0]==ip:
  while len(a)<4:a.append("")
  a[3]=n;hit=True
 out.append("\t".join(a))
if not hit:out.append("\t".join([ip,"","",n]))
p.write_text("\n".join(out)+"\n")
PY
 pause;;4)cat "$DATA/lan_new.txt" 2>/dev/null||echo "Brak.";pause;;5)cat "$DATA/lan_current.txt" 2>/dev/null||echo "Brak.";pause;;
 6)yn "Usunąć bazę LAN Radar?"&&rm -f "$DATA"/lan_*.txt "$DATA"/lan_known.tsv;pause;;0)return;;esac;done
}
network_report_v31(){
 local f="$REPORTS/network_$(date +%Y%m%d_%H%M%S).txt";{ echo "PRESTIGE NETWORK REPORT 3.1";date;net_snapshot_v31;echo;ip -br addr 2>&1;echo;ip route 2>&1;echo;ip neigh 2>&1;echo;ss -s 2>&1;echo;ss -lntu 2>&1;}|tee "$f";echo "Zapisano: $f";pause
}
security_v31(){
 header;section "[ZAAWANSOWANY] SECURITY CENTER 3.1"
 printf "%-25s " "SSHD";pgrep -x sshd >/dev/null 2>&1&&echo "[UWAGA] działa"||echo "[OK] nie działa"
 printf "%-25s " "Tor";pgrep -x tor >/dev/null 2>&1&&echo "[INFO] działa"||echo "[INFO] nie działa"
 printf "%-25s " "ADB";have adb&&echo "[OK]"||echo "[BRAK]";printf "%-25s " "Nmap";have nmap&&echo "[OK]"||echo "[BRAK]"
 printf "%-25s " "ROOT";is_root&&echo "[ROOT] dostępny"||echo "[OK] niewykryty"
 echo;echo "[Nasłuchujące sockety]";ss -lntu 2>&1||true;echo;echo "Globalna inspekcja ruchu innych aplikacji może wymagać ROOT lub rozwiązania VPN.";pause
}
network_center_v31(){
 while true;do header;section "[STANDARD] CENTRUM SIECI 3.1";net_snapshot_v31;echo
 item 1 "Automatyczna diagnostyka";item 2 "Wi-Fi";item 3 "Nmap 3.1";item 4 "LAN Radar";item 5 "Interfejsy";item 6 "Routing / gateway"
 item 7 "Sąsiedzi LAN";item 8 "Sockety";item 9 "DNS / WHOIS / routing";item 10 "Raport sieciowy";item 11 "Stare Centrum sieci v3.0";back
 read -rp "PRESTIGE/SIEĆ> " x;case "$x" in 1)net_health_v31;;2)wifi_menu;;3)nmap_v31;;4)lan_radar;;5)ip -br addr;pause;;6)ip route;pause;;
 7)ip neigh;pause;;8)ss -ntup 2>&1;pause;;9)dns_menu;;10)network_report_v31;;11)network_info;;0)return;;esac;done
}
# Override menu only. Wszystkie funkcje v3.0 pozostają w pliku.
main_menu(){
 while true;do header
 section "${GREEN}[ PODSTAWOWY ]${R}";item 1 "Informacje o telefonie";item 2 "Pierwsza konfiguracja / konfiguruj od zera";item 3 "Personalizacja Termuxa";item 4 "Pakiety i instalator";item 5 "Narzędzia systemowe";item 6 "Diagnostyka Internetu"
 section "${BLUE}[ STANDARD ]${R}";item 7 "Centrum sieci 3.1";item 8 "Wi-Fi";item 9 "Nmap 3.1 i profile skanowania";item 10 "Git / GitHub";item 11 "SSH / SFTP / SCP";item 12 "Programowanie";item 13 "Termux:API";item 14 "Android / ADB"
 section "${PURPLE}[ ZAAWANSOWANY ]${R}";item 15 "Monitor sieci / baseline LAN";item 16 "Automatyzacje / Cron";item 17 "Security Center 3.1";item 18 "Logcat";item 19 "Tor / prywatność";item 20 "Analiza ruchu i socketów";item 21 "DNS / WHOIS / routing";item 34 "LAN Radar 3.1"
 section "${RED}[ ROOT ]${R}";item 22 "Centrum ROOT";item 23 "Tcpdump";item 24 "Sieć ROOT";item 25 "Procesy / sockety ROOT"
 section "${CYAN}[ SYSTEM / PRESTIGE ]${R}";item 26 "Pełny raport urządzenia";item 27 "Backup Prestige";item 28 "Restore";item 29 "Diagnostyka Prestige";item 30 "Aktualizacja Termuxa i pakietów";item 31 "Aktualizacja Prestige";item 32 "Poradnik / baza komend";item 33 "Command Center / wyszukiwarka";item 35 "Raport sieciowy 3.1"
 echo;item 0 "Wyjście";echo;read -rp "PRESTIGE> " x
 case "$x" in 1)phone_info;;2)first_run;;3)personalize;;4)package_center;;5)tools_menu;;6)internet_diag;;7)network_center_v31;;8)wifi_menu;;9)nmap_v31;;10)git_menu_v3;;11)ssh_menu;;12)dev_menu;;13)api_menu;;14)adb_menu;;15)monitor_menu;;16)cron_menu_v3;;17)security_v31;;18)logcat_menu;;19)tor_menu;;20)traffic_menu;;21)dns_menu;;22)root_menu;;23)root_tcpdump;;24)root_network;;25)root_processes;;26)report;;27)backup_menu;;28)restore_menu;;29)diagnostics;;30)update_all;;31)prestige_update;;32)guide;;33)command_center;;34)lan_radar;;35)network_report_v31;;0)exit 0;;*)echo "Nieprawidłowy wybór.";sleep 1;;esac;done
}


# ================= V3.2 FULL EXPANSION =================

status_tag(){
  case "$1" in
    ok) printf "${GREEN}[OK]${R}";;
    missing) printf "${RED}[BRAK]${R}";;
    warn) printf "${YELLOW}[UWAGA]${R}";;
    root) printf "${RED}[ROOT]${R}";;
    info) printf "${BLUE}[INFO]${R}";;
  esac
}

dep_offer(){
  local cmd="$1" pkg="$2"
  have "$cmd" && return 0
  echo "$(status_tag missing) Brakuje: $cmd (pakiet: $pkg)"
  echo "1. Zainstaluj teraz"
  echo "2. Pokaż informację"
  echo "0. Anuluj"
  read -rp "Wybór: " x
  case "$x" in
    1) pkg_install "$pkg";;
    2) echo "Funkcja wymaga programu '$cmd'. Prestige może doinstalować pakiet '$pkg' przez pkg."; pause;;
    *) return 1;;
  esac
  have "$cmd"
}

adb_connected(){
  have adb || return 1
  adb get-state >/dev/null 2>&1
}

adb_center_v32(){
  dep_offer adb android-tools || return
  while true; do
    header; section "[STANDARD] ADB CENTER 3.2"
    printf "ADB: "; adb_connected && echo "$(status_tag ok) urządzenie podłączone" || echo "$(status_tag warn) brak aktywnego urządzenia"
    echo
    item 1 "adb devices -l"
    item 2 "Połącz ADB przez IP:PORT"
    item 3 "Rozłącz ADB"
    item 4 "Informacje o urządzeniu"
    item 5 "Bateria przez dumpsys"
    item 6 "Lista pakietów"
    item 7 "Wyszukaj pakiet"
    item 8 "Zainstaluj APK"
    item 9 "Odinstaluj pakiet"
    item 10 "Wyłącz pakiet dla użytkownika 0"
    item 11 "Włącz pakiet"
    item 12 "ADB shell"
    item 13 "Screenshot urządzenia"
    item 14 "Pobierz plik z urządzenia (pull)"
    item 15 "Wyślij plik na urządzenie (push)"
    item 16 "Logcat Center"
    item 17 "Restart serwera ADB"
    item 18 "Porty TCP urządzenia przez shell"
    back
    read -rp "PRESTIGE/ADB> " x
    case "$x" in
      1) adb devices -l; pause;;
      2) read -rp "IP:PORT: " a; adb connect "$a"; pause;;
      3) adb disconnect; pause;;
      4) adb shell 'getprop ro.product.manufacturer; getprop ro.product.model; getprop ro.build.version.release; getprop ro.build.version.sdk; uname -a'; pause;;
      5) adb shell dumpsys battery; pause;;
      6) adb shell pm list packages | less;;
      7) read -rp "Fragment nazwy: " q; adb shell pm list packages | grep -i -- "$q"; pause;;
      8) read -rp "Ścieżka APK: " f; adb install "$f"; pause;;
      9) read -rp "Nazwa pakietu: " p; echo "Odinstalowanie dotyczy wskazanego urządzenia ADB."; yn "Kontynuować?" && adb uninstall "$p"; pause;;
      10) read -rp "Nazwa pakietu: " p; echo "Wyłączenie pakietu systemowego może zmienić działanie telefonu."; yn "Kontynuować?" && adb shell pm disable-user --user 0 "$p"; pause;;
      11) read -rp "Nazwa pakietu: " p; adb shell pm enable "$p"; pause;;
      12) adb shell;;
      13) f="$REPORTS/adb_screen_$(date +%Y%m%d_%H%M%S).png"; adb exec-out screencap -p > "$f"; echo "Zapisano: $f"; pause;;
      14) read -rp "Ścieżka na urządzeniu: " a; read -rp "Cel lokalny [$HOME]: " b; adb pull "$a" "${b:-$HOME}"; pause;;
      15) read -rp "Plik lokalny: " a; read -rp "Cel na urządzeniu [/sdcard/Download/]: " b; adb push "$a" "${b:-/sdcard/Download/}"; pause;;
      16) logcat_menu;;
      17) adb kill-server; adb start-server; pause;;
      18) adb shell 'ss -lntu 2>/dev/null || netstat -lnt 2>/dev/null || true'; pause;;
      0) return;;
    esac
  done
}

github_center_v32(){
  dep_offer git git || return
  while true; do
    header; section "[STANDARD] GITHUB CENTER 3.2"
    printf "Git: "; git --version 2>/dev/null
    printf "GitHub CLI: "; have gh && echo "$(status_tag ok)" || echo "$(status_tag missing)"
    echo
    item 1 "Konfiguracja Git user.name / user.email"
    item 2 "GitHub CLI: instalacja / logowanie"
    item 3 "Status logowania GitHub"
    item 4 "Lista moich repozytoriów"
    item 5 "Klonuj repozytorium"
    item 6 "Status bieżącego repo"
    item 7 "Pull"
    item 8 "Add + commit"
    item 9 "Push"
    item 10 "Branch: lista / bieżący"
    item 11 "Utwórz nowy branch"
    item 12 "Remote / origin"
    item 13 "Ostatnie commity"
    item 14 "Utwórz repo GitHub z bieżącego katalogu"
    item 15 "Lista release"
    item 16 "Utwórz release z plikiem"
    item 17 "Szybki backup repo do TAR.GZ"
    item 18 "Profil w4sy1: lista repo"
    back
    read -rp "PRESTIGE/GITHUB> " x
    case "$x" in
      1) read -rp "Nazwa: " n; read -rp "E-mail: " e; git config --global user.name "$n"; git config --global user.email "$e"; pause;;
      2) dep_offer gh gh && gh auth login; pause;;
      3) dep_offer gh gh && gh auth status; pause;;
      4) dep_offer gh gh && gh repo list --limit 100; pause;;
      5) read -rp "URL lub owner/repo: " u; if have gh && [[ "$u" != http* ]]; then gh repo clone "$u"; else git clone "$u"; fi; pause;;
      6) git status; pause;; 7) git pull; pause;;
      8) read -rp "Opis commita: " m; git add . && git commit -m "$m"; pause;;
      9) git push; pause;;
      10) git branch -vv; pause;;
      11) read -rp "Nazwa brancha: " b; git switch -c "$b" 2>/dev/null || git checkout -b "$b"; pause;;
      12) git remote -v; echo; read -rp "Zmienić origin? [t/N]: " a; if [[ "$a" =~ ^[tTyY]$ ]]; then read -rp "URL: " u; git remote get-url origin >/dev/null 2>&1 && git remote set-url origin "$u" || git remote add origin "$u"; fi; pause;;
      13) git log --oneline --decorate --graph -30; pause;;
      14) dep_offer gh gh || continue; read -rp "Nazwa repo: " n; read -rp "Publiczne? [t/N]: " a; [[ "$a" =~ ^[tTyY]$ ]] && vis=--public || vis=--private; gh repo create "$n" "$vis" --source=. --remote=origin; pause;;
      15) dep_offer gh gh && gh release list; pause;;
      16) dep_offer gh gh || continue; read -rp "Tag np. v1.0.0: " t; read -rp "Plik do release: " f; gh release create "$t" "$f" --generate-notes; pause;;
      17) d="$(basename "$PWD")"; f="$BACKUPS/${d}_git_$(date +%Y%m%d_%H%M%S).tar.gz"; tar -czf "$f" --exclude=.git "$PWD"; echo "Backup: $f"; pause;;
      18) dep_offer gh gh && gh repo list w4sy1 --limit 100; pause;;
      0) return;;
    esac
  done
}

ssh_center_v32(){
  dep_offer ssh openssh || return
  while true; do
    header; section "[STANDARD] SSH CENTER 3.2"
    item 1 "Uruchom sshd"
    item 2 "Zatrzymaj sshd"
    item 3 "Status sshd i port 8022"
    item 4 "Pokaż użytkownika i lokalne IP"
    item 5 "Połącz SSH"
    item 6 "SCP: wyślij plik"
    item 7 "SCP: pobierz plik"
    item 8 "Generuj klucz ed25519"
    item 9 "Pokaż klucz publiczny"
    item 10 "known_hosts"
    item 11 "authorized_keys"
    item 12 "Konfiguracja ~/.ssh/config"
    back
    read -rp "PRESTIGE/SSH> " x
    case "$x" in
      1) sshd; echo "sshd uruchomiony. Domyślny port Termuxa: 8022."; pause;;
      2) pkill sshd 2>/dev/null || true; pause;;
      3) pgrep -a sshd 2>/dev/null || echo "sshd nie działa."; ss -lnt 2>/dev/null | grep ':8022' || true; pause;;
      4) echo "User: $(whoami)"; echo "IP: $(net_ip)"; pause;;
      5) read -rp "user@host: " h; read -rp "Port [22]: " p; ssh -p "${p:-22}" "$h";;
      6) read -rp "Plik lokalny: " f; read -rp "user@host:ścieżka: " d; read -rp "Port [22]: " p; scp -P "${p:-22}" "$f" "$d"; pause;;
      7) read -rp "user@host:plik: " f; read -rp "Cel lokalny [.]: " d; read -rp "Port [22]: " p; scp -P "${p:-22}" "$f" "${d:-.}"; pause;;
      8) mkdir -p "$HOME/.ssh"; ssh-keygen -t ed25519; pause;;
      9) cat "$HOME/.ssh/id_ed25519.pub" 2>/dev/null || echo "Brak klucza."; pause;;
      10) ${EDITOR:-nano} "$HOME/.ssh/known_hosts";;
      11) mkdir -p "$HOME/.ssh"; touch "$HOME/.ssh/authorized_keys"; chmod 600 "$HOME/.ssh/authorized_keys"; ${EDITOR:-nano} "$HOME/.ssh/authorized_keys";;
      12) mkdir -p "$HOME/.ssh"; touch "$HOME/.ssh/config"; chmod 600 "$HOME/.ssh/config"; ${EDITOR:-nano} "$HOME/.ssh/config";;
      0) return;;
    esac
  done
}

report_full_v32(){
  header; section "[SYSTEM] PEŁNY RAPORT PRESTIGE 3.2"
  local f="$REPORTS/full_report_$(date +%Y%m%d_%H%M%S).txt"
  {
    echo "PRESTIGE TERMUX TOOL FULL REPORT"; echo "Version: $VER"; date
    echo; echo "=== ANDROID ==="
    for p in ro.product.manufacturer ro.product.model ro.product.device ro.build.version.release ro.build.version.sdk ro.product.cpu.abi; do printf "%-30s %s\n" "$p" "$(getprop "$p" 2>/dev/null)"; done
    echo; echo "=== KERNEL ==="; uname -a
    echo; echo "=== CPU ==="; cat /proc/cpuinfo 2>/dev/null | head -80
    echo; echo "=== RAM ==="; free -h 2>&1
    echo; echo "=== STORAGE ==="; df -h 2>&1
    echo; echo "=== TERMUX ==="; echo "PREFIX=$PREFIX"; echo "HOME=$HOME"; pkg --version 2>&1
    echo; echo "=== NETWORK ==="; net_snapshot_v31; ip -br addr 2>&1; ip route 2>&1; ip neigh 2>&1
    echo; echo "=== SOCKETS ==="; ss -s 2>&1; ss -lntu 2>&1
    echo; echo "=== TOOLS ==="
    for c in git gh curl wget python node clang nmap ssh scp adb tor crond jq dig whois; do printf "%-12s " "$c"; have "$c" && command -v "$c" || echo "BRAK"; done
    echo; echo "=== SERVICES ==="; pgrep -a sshd 2>/dev/null || true; pgrep -a tor 2>/dev/null || true; pgrep -a crond 2>/dev/null || true
    echo; echo "=== ROOT ==="; is_root && echo "TAK" || echo "NIE"
    echo; echo "=== GIT ==="; git config --global --list 2>/dev/null || true
    echo; echo "=== ADB ==="; adb devices -l 2>/dev/null || true
    echo; echo "=== BATTERY/API ==="; have termux-battery-status && termux-battery-status 2>/dev/null || echo "BRAK TERMUX:API"
    echo; echo "=== PRESTIGE FILES ==="; ls -lah "$ROOT" 2>&1
  } | tee "$f"
  echo; echo "Zapisano: $f"; pause
}

command_center_v32(){
  while true; do
    header; section "[SYSTEM] COMMAND CENTER 3.2"
    echo "Wpisz temat albo polecenie skrótowe:"
    echo "sieć | internet | wifi | nmap | radar | security | adb | logcat | github | git | ssh | tor | dns | raport | backup | cron | root | telefon | pakiety"
    echo "0 = powrót"
    read -rp "PRESTIGE/SZUKAJ> " q
    case "${q,,}" in
      0) return;;
      sieć|siec|network) network_center_v31;;
      internet|net) net_health_v31;;
      wifi|wi-fi) wifi_menu;;
      nmap|skan|porty) nmap_v31;;
      radar|lan) lan_radar;;
      security|bezpieczeństwo|bezpieczenstwo) security_v31;;
      adb|android) adb_center_v32;;
      logcat|logi) logcat_menu;;
      github|git) github_center_v32;;
      ssh|scp|sftp) ssh_center_v32;;
      tor|prywatność|prywatnosc) tor_menu;;
      dns|whois|routing) dns_menu;;
      raport|report) report_full_v32;;
      backup) backup_menu;;
      cron|automat|automatyzacje) cron_menu_v3;;
      root) root_menu;;
      telefon|phone) phone_info;;
      pakiety|packages) package_center;;
      *) echo "$(status_tag warn) Nie znam skrótu '$q'."; echo "Możesz użyć jednej z nazw pokazanych wyżej."; pause;;
    esac
  done
}

prestige_dashboard_v32(){
  header; section "[SYSTEM] STATUS PRESTIGE 3.2"
  printf "%-18s " "Internet"; curl -IsS --max-time 4 https://example.com >/dev/null 2>&1 && echo "$(status_tag ok)" || echo "$(status_tag warn)"
  printf "%-18s " "Nmap"; have nmap && echo "$(status_tag ok)" || echo "$(status_tag missing)"
  printf "%-18s " "Git"; have git && echo "$(status_tag ok)" || echo "$(status_tag missing)"
  printf "%-18s " "GitHub CLI"; have gh && echo "$(status_tag ok)" || echo "$(status_tag missing)"
  printf "%-18s " "SSH"; have ssh && echo "$(status_tag ok)" || echo "$(status_tag missing)"
  printf "%-18s " "ADB"; have adb && echo "$(status_tag ok)" || echo "$(status_tag missing)"
  printf "%-18s " "Tor"; have tor && echo "$(status_tag ok)" || echo "$(status_tag missing)"
  printf "%-18s " "Cron"; have crond && echo "$(status_tag ok)" || echo "$(status_tag missing)"
  printf "%-18s " "Termux:API"; have termux-battery-status && echo "$(status_tag ok)" || echo "$(status_tag missing)"
  printf "%-18s " "ROOT"; is_root && echo "$(status_tag root) dostępny" || echo "$(status_tag info) niewykryty"
  echo
  net_snapshot_v31
  pause
}

# Final v3.2 menu override. All older functions remain available in the same script.
main_menu(){
  while true; do
    header
    section "${GREEN}[ PODSTAWOWY ]${R}"
    item 1 "Informacje o telefonie"
    item 2 "Pierwsza konfiguracja / konfiguruj od zera"
    item 3 "Personalizacja Termuxa"
    item 4 "Pakiety i instalator"
    item 5 "Narzędzia systemowe"
    item 6 "Diagnostyka Internetu"

    section "${BLUE}[ STANDARD ]${R}"
    item 7 "Centrum sieci 3.1"
    item 8 "Wi-Fi"
    item 9 "Nmap 3.1 i profile skanowania"
    item 10 "GitHub Center 3.2"
    item 11 "SSH Center 3.2"
    item 12 "Programowanie"
    item 13 "Termux:API"
    item 14 "ADB Center 3.2"

    section "${PURPLE}[ ZAAWANSOWANY ]${R}"
    item 15 "Monitor sieci / baseline LAN"
    item 16 "Automatyzacje / Cron"
    item 17 "Security Center 3.1"
    item 18 "Logcat"
    item 19 "Tor / prywatność"
    item 20 "Analiza ruchu i socketów"
    item 21 "DNS / WHOIS / routing"
    item 34 "LAN Radar 3.1"

    section "${RED}[ ROOT ]${R}"
    item 22 "Centrum ROOT"
    item 23 "Tcpdump"
    item 24 "Sieć ROOT"
    item 25 "Procesy / sockety ROOT"

    section "${CYAN}[ SYSTEM / PRESTIGE ]${R}"
    item 26 "Pełny raport urządzenia 3.2"
    item 27 "Backup Prestige"
    item 28 "Restore"
    item 29 "Diagnostyka Prestige"
    item 30 "Aktualizacja Termuxa i pakietów"
    item 31 "Aktualizacja Prestige"
    item 32 "Poradnik / baza komend"
    item 33 "Command Center 3.2"
    item 35 "Raport sieciowy 3.1"
    item 36 "Dashboard statusu Prestige"
    echo
    item 0 "Wyjście"
    echo
    read -rp "PRESTIGE> " x
    case "$x" in
      1) phone_info;; 2) first_run;; 3) personalize;; 4) package_center;; 5) tools_menu;; 6) internet_diag;;
      7) network_center_v31;; 8) wifi_menu;; 9) nmap_v31;; 10) github_center_v32;; 11) ssh_center_v32;;
      12) dev_menu;; 13) api_menu;; 14) adb_center_v32;; 15) monitor_menu;; 16) cron_menu_v3;;
      17) security_v31;; 18) logcat_menu;; 19) tor_menu;; 20) traffic_menu;; 21) dns_menu;;
      22) root_menu;; 23) root_tcpdump;; 24) root_network;; 25) root_processes;; 26) report_full_v32;;
      27) backup_menu;; 28) restore_menu;; 29) diagnostics;; 30) update_all;; 31) prestige_update;;
      32) guide;; 33) command_center_v32;; 34) lan_radar;; 35) network_report_v31;; 36) prestige_dashboard_v32;;
      0) exit 0;; *) echo "Nieprawidłowy wybór."; sleep 1;;
    esac
  done
}

main "$@"
