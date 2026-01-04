#!/bin/bash

#######################################
# Linux First Install Setup Script v2
# Mit Progress Bars und detailliertem Feedback
#######################################

set -euo pipefail  # Exit bei Fehlern, undefinierte Variablen = Fehler

# Farben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Fortschrittsvariablen
TOTAL_STEPS=9
CURRENT_STEP=0
declare -a SUMMARY=()

# Progress Bar anzeigen
show_progress() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local completed=$((width * current / total))
    local remaining=$((width - completed))
    
    printf "\r${CYAN}["
    printf "%${completed}s" | tr ' ' '='
    printf "%${remaining}s" | tr ' ' '-'
    printf "] %3d%% (%d/%d)${NC}" "$percentage" "$current" "$total"
}

# Schritt-Header anzeigen
step_header() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo ""
    echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║${NC} ${YELLOW}Schritt $CURRENT_STEP von $TOTAL_STEPS: $1${NC}"
    echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════╝${NC}"
    show_progress $CURRENT_STEP $TOTAL_STEPS
    echo ""
}

# Info-Nachricht
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Erfolgs-Nachricht
success() {
    echo -e "${GREEN}[✓ OK]${NC} $1"
}

# Warnung
warning() {
    echo -e "${YELLOW}[! WARNUNG]${NC} $1"
}

# Fehler
error() {
    echo -e "${RED}[✗ FEHLER]${NC} $1"
}

# Debug-Info anzeigen
debug() {
    echo -e "${CYAN}[DEBUG]${NC} $1"
}

# Simpler Progress Bar für lange Operationen
simple_progress() {
    local duration=$1
    local steps=20
    local step_duration=$((duration / steps))
    
    printf "${CYAN}Progress: ["
    for i in $(seq 1 $steps); do
        sleep $step_duration
        printf "▓"
    done
    printf "] Fertig!${NC}\n"
}

# Banner
show_banner() {
    clear
    echo -e "${GREEN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   Linux First Install Setup Script v2                    ║
║   Mit Progress Bars und detailliertem Feedback           ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo ""
    info "Datum: $(date '+%d.%m.%Y %H:%M:%S')"
    info "Benutzer: $(whoami)"
    info "Hostname: $(hostname)"
    echo ""
}

# Root-Check
check_root() {
    info "Prüfe Root-Rechte..."
    if [ "$EUID" -ne 0 ]; then 
        error "Dieses Script muss als root ausgeführt werden!"
        echo ""
        echo "Bitte ausführen mit:"
        echo "  sudo $0"
        exit 1
    fi
    success "Root-Rechte bestätigt"
}

# Eingabe einlesen mit Timeout-Anzeige
read_input() {
    local prompt="$1"
    local varname="$2"
    local default="${3:-}"
    
    if [ -n "$default" ]; then
        read -p "$prompt [Standard: $default]: " input
        eval "$varname=\"${input:-$default}\""
    else
        read -p "$prompt: " input
        eval "$varname=\"$input\""
    fi
    
    debug "Eingabe für '$varname' = '${!varname}'"
}

# Ja/Nein Frage
ask_yes_no() {
    local prompt="$1"
    local varname="$2"
    local response
    
    while true; do
        read -p "$prompt (j/n): " response
        debug "Antwort: '$response'"
        
        case "$response" in
            [JjYy]*)
                eval "$varname=true"
                info "Antwort: Ja"
                return 0
                ;;
            [Nn]*)
                eval "$varname=false"
                info "Antwort: Nein"
                return 0
                ;;
            *)
                warning "Bitte 'j' für Ja oder 'n' für Nein eingeben"
                ;;
        esac
    done
}

# Schritt 1: OS-Erkennung
detect_os() {
    step_header "Betriebssystem-Erkennung"
    
    info "Ermittle Betriebssystem-Details..."
    
    if [ ! -f /etc/os-release ]; then
        error "Kann /etc/os-release nicht finden!"
        exit 1
    fi
    
    source /etc/os-release
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${CYAN}OS-Details:${NC}"
    echo "  • Name:           $NAME"
    echo "  • Version:        ${VERSION:-N/A}"
    echo "  • ID:             $ID"
    echo "  • ID Like:        ${ID_LIKE:-N/A}"
    echo "  • Kernel:         $(uname -r)"
    echo "  • Architektur:    $(uname -m)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Package Manager festlegen
    case $ID in
        ubuntu|debian|linuxmint|pop)
            PKG_MGR="apt"
            UPDATE_CMD="apt-get update"
            UPGRADE_CMD="apt-get upgrade -y"
            INSTALL_CMD="apt-get install -y"
            info "Package Manager: APT (Debian-basiert)"
            ;;
        fedora|rhel|centos|rocky|almalinux)
            PKG_MGR="dnf"
            UPDATE_CMD="dnf check-update || true"
            UPGRADE_CMD="dnf upgrade -y"
            INSTALL_CMD="dnf install -y"
            info "Package Manager: DNF (Red Hat-basiert)"
            ;;
        arch|manjaro)
            PKG_MGR="pacman"
            UPDATE_CMD="pacman -Sy"
            UPGRADE_CMD="pacman -Syu --noconfirm"
            INSTALL_CMD="pacman -S --noconfirm"
            info "Package Manager: Pacman (Arch-basiert)"
            ;;
        opensuse*|sles)
            PKG_MGR="zypper"
            UPDATE_CMD="zypper refresh"
            UPGRADE_CMD="zypper update -y"
            INSTALL_CMD="zypper install -y"
            info "Package Manager: Zypper (SUSE-basiert)"
            ;;
        *)
            warning "Unbekanntes System: $ID"
            warning "Verwende APT als Fallback"
            PKG_MGR="apt"
            UPDATE_CMD="apt-get update"
            UPGRADE_CMD="apt-get upgrade -y"
            INSTALL_CMD="apt-get install -y"
            ;;
    esac
    
    success "Betriebssystem erkannt: $NAME"
    SUMMARY+=("OS: $NAME ($ID)")
    
    sleep 1
}

# Schritt 2: System Update
system_update() {
    step_header "System Update & Upgrade"
    
    local do_update
    ask_yes_no "System-Update und Upgrade durchführen?" do_update
    
    if [ "$do_update" = false ]; then
        warning "System-Update übersprungen"
        SUMMARY+=("System-Update: übersprungen")
        return 0
    fi
    
    echo ""
    info "Aktualisiere Paketlisten..."
    info "Befehl: $UPDATE_CMD"
    echo ""
    
    if eval $UPDATE_CMD; then
        success "Paketlisten aktualisiert"
    else
        error "Fehler beim Aktualisieren der Paketlisten"
        warning "Fortfahren trotz Fehler..."
    fi
    
    echo ""
    info "Führe System-Upgrade durch..."
    info "Dies kann mehrere Minuten dauern..."
    info "Befehl: $UPGRADE_CMD"
    echo ""
    
    # Upgrade mit Fortschrittsanzeige
    eval $UPGRADE_CMD &
    local pid=$!
    
    while kill -0 $pid 2>/dev/null; do
        printf "."
        sleep 2
    done
    wait $pid
    local exit_code=$?
    
    echo ""
    if [ $exit_code -eq 0 ]; then
        success "System-Upgrade erfolgreich abgeschlossen"
        SUMMARY+=("System-Update: erfolgreich")
    else
        error "System-Upgrade mit Fehlercode $exit_code beendet"
        SUMMARY+=("System-Update: Fehler (Code: $exit_code)")
    fi
    
    sleep 1
}

# Schritt 3: Hostname ändern
change_hostname() {
    step_header "Hostname-Konfiguration"
    
    info "Aktueller Hostname: $(hostname)"
    echo ""
    
    local change_it
    ask_yes_no "Hostname ändern?" change_it
    
    if [ "$change_it" = false ]; then
        info "Hostname bleibt: $(hostname)"
        SUMMARY+=("Hostname: nicht geändert")
        return 0
    fi
    
    local new_hostname
    read_input "Neuer Hostname" new_hostname
    
    if [ -z "$new_hostname" ]; then
        warning "Kein Hostname eingegeben, überspringe..."
        SUMMARY+=("Hostname: nicht geändert")
        return 0
    fi
    
    local old_hostname=$(hostname)
    
    info "Setze Hostname: $new_hostname"
    hostnamectl set-hostname "$new_hostname"
    
    info "Aktualisiere /etc/hosts..."
    sed -i "s/$old_hostname/$new_hostname/g" /etc/hosts
    
    if ! grep -q "127.0.1.1" /etc/hosts; then
        echo "127.0.1.1    $new_hostname" >> /etc/hosts
        info "127.0.1.1 Eintrag hinzugefügt"
    fi
    
    success "Hostname geändert: $old_hostname → $new_hostname"
    info "Neuer Hostname wird nach Neustart aktiv"
    SUMMARY+=("Hostname: $old_hostname → $new_hostname")
    
    sleep 1
}

# Schritt 4: Timezone
change_timezone() {
    step_header "Zeitzone-Konfiguration"
    
    info "Aktuelle Zeitzone: $(timedatectl | grep "Time zone" | awk '{print $3}')"
    info "Aktuelle Zeit: $(date)"
    echo ""
    
    local change_it
    ask_yes_no "Zeitzone ändern?" change_it
    
    if [ "$change_it" = false ]; then
        info "Zeitzone bleibt unverändert"
        SUMMARY+=("Zeitzone: nicht geändert")
        return 0
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${CYAN}Verfügbare Zeitzonen:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  1) Europe/Berlin     (Deutschland)"
    echo "  2) Europe/London     (UK)"
    echo "  3) Europe/Paris      (Frankreich)"
    echo "  4) Europe/Rome       (Italien)"
    echo "  5) Europe/Madrid     (Spanien)"
    echo "  6) Europe/Vienna     (Österreich)"
    echo "  7) Europe/Zurich     (Schweiz)"
    echo "  8) Europe/Amsterdam  (Niederlande)"
    echo "  9) Andere (manuell eingeben)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    local choice
    read_input "Wähle eine Option (1-9)" choice
    
    local timezone
    case $choice in
        1) timezone="Europe/Berlin" ;;
        2) timezone="Europe/London" ;;
        3) timezone="Europe/Paris" ;;
        4) timezone="Europe/Rome" ;;
        5) timezone="Europe/Madrid" ;;
        6) timezone="Europe/Vienna" ;;
        7) timezone="Europe/Zurich" ;;
        8) timezone="Europe/Amsterdam" ;;
        9) 
            read_input "Zeitzone (z.B. America/New_York)" timezone
            ;;
        *)
            warning "Ungültige Auswahl"
            SUMMARY+=("Zeitzone: nicht geändert")
            return 0
            ;;
    esac
    
    info "Setze Zeitzone: $timezone"
    if timedatectl set-timezone "$timezone" 2>/dev/null; then
        success "Zeitzone geändert: $timezone"
        info "Neue Zeit: $(date)"
        SUMMARY+=("Zeitzone: $timezone")
    else
        error "Konnte Zeitzone nicht setzen"
        SUMMARY+=("Zeitzone: Fehler")
    fi
    
    sleep 1
}

# Schritt 5: Swap
setup_swap() {
    step_header "Swap-Konfiguration"
    
    info "Überprüfe vorhandenen Swap..."
    
    if swapon --show | grep -q '/'; then
        echo ""
        swapon --show
        echo ""
        success "Swap bereits vorhanden"
        SUMMARY+=("Swap: bereits konfiguriert")
        return 0
    fi
    
    info "Kein Swap gefunden"
    
    local create_it
    ask_yes_no "Swap-Datei erstellen?" create_it
    
    if [ "$create_it" = false ]; then
        info "Swap-Erstellung übersprungen"
        SUMMARY+=("Swap: nicht erstellt")
        return 0
    fi
    
    # RAM-Größe ermitteln
    local total_ram=$(free -m | awk '/^Mem:/{print $2}')
    info "Verfügbarer RAM: ${total_ram}MB"
    
    local suggested_swap
    if [ $total_ram -lt 2048 ]; then
        suggested_swap="2G"
    elif [ $total_ram -lt 8192 ]; then
        suggested_swap="4G"
    else
        suggested_swap="8G"
    fi
    
    local swap_size
    read_input "Swap-Größe" swap_size "$suggested_swap"
    
    echo ""
    info "Erstelle Swap-Datei: $swap_size"
    info "Dies kann einen Moment dauern..."
    
    # Swap erstellen mit Fortschritt
    info "Schritt 1/5: Datei allokieren..."
    fallocate -l $swap_size /swapfile
    success "Datei erstellt"
    
    info "Schritt 2/5: Rechte setzen..."
    chmod 600 /swapfile
    success "Rechte gesetzt"
    
    info "Schritt 3/5: Swap-Bereich einrichten..."
    mkswap /swapfile
    success "Swap-Bereich eingerichtet"
    
    info "Schritt 4/5: Swap aktivieren..."
    swapon /swapfile
    success "Swap aktiviert"
    
    info "Schritt 5/5: In fstab eintragen..."
    if ! grep -q '/swapfile' /etc/fstab; then
        echo '/swapfile none swap sw 0 0' >> /etc/fstab
        success "In fstab eingetragen"
    else
        info "Bereits in fstab vorhanden"
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    swapon --show
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    success "Swap-Datei erfolgreich erstellt: $swap_size"
    SUMMARY+=("Swap: $swap_size erstellt")
    
    sleep 1
}

# Schritt 6: Essential Tools
install_tools() {
    step_header "Wichtige Tools installieren"
    
    local install_it
    ask_yes_no "Standard-Tools installieren?" install_it
    
    if [ "$install_it" = false ]; then
        info "Tool-Installation übersprungen"
        SUMMARY+=("Tools: nicht installiert")
        return 0
    fi
    
    local tools
    case $PKG_MGR in
        apt)
            tools="curl wget git vim nano htop net-tools ufw fail2ban unzip"
            ;;
        dnf)
            tools="curl wget git vim nano htop net-tools firewalld fail2ban unzip"
            ;;
        pacman)
            tools="curl wget git vim nano htop net-tools ufw fail2ban unzip"
            ;;
        zypper)
            tools="curl wget git vim nano htop net-tools firewalld fail2ban unzip"
            ;;
    esac
    
    echo ""
    info "Folgende Tools werden installiert:"
    echo ""
    for tool in $tools; do
        echo "  • $tool"
    done
    echo ""
    
    info "Installiere Tools..."
    info "Befehl: $INSTALL_CMD $tools"
    echo ""
    
    eval $INSTALL_CMD $tools &
    local pid=$!
    
    while kill -0 $pid 2>/dev/null; do
        printf "."
        sleep 1
    done
    wait $pid
    local exit_code=$?
    
    echo ""
    if [ $exit_code -eq 0 ]; then
        success "Tools erfolgreich installiert"
        SUMMARY+=("Tools: installiert")
    else
        error "Tool-Installation mit Fehler beendet"
        SUMMARY+=("Tools: teilweise installiert")
    fi
    
    sleep 1
}

# Schritt 7: Firewall
setup_firewall() {
    step_header "Firewall-Konfiguration"
    
    local setup_it
    ask_yes_no "Firewall aktivieren?" setup_it
    
    if [ "$setup_it" = false ]; then
        info "Firewall-Konfiguration übersprungen"
        SUMMARY+=("Firewall: nicht konfiguriert")
        return 0
    fi
    
    case $PKG_MGR in
        apt|pacman)
            if command -v ufw &> /dev/null; then
                info "Konfiguriere UFW..."
                
                ufw default deny incoming
                info "Standard: Eingehend blockiert"
                
                ufw default allow outgoing
                info "Standard: Ausgehend erlaubt"
                
                ufw allow ssh
                success "SSH-Port erlaubt"
                
                echo ""
                info "Zusätzliche Ports? (z.B. 80,443 für Webserver)"
                local ports
                read_input "Ports (kommagetrennt, oder Enter für keine)" ports ""
                
                if [ -n "$ports" ]; then
                    IFS=',' read -ra PORT_ARRAY <<< "$ports"
                    for port in "${PORT_ARRAY[@]}"; do
                        ufw allow $port
                        success "Port $port erlaubt"
                    done
                fi
                
                echo ""
                info "Aktiviere UFW..."
                echo "y" | ufw enable
                
                echo ""
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                ufw status verbose
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                
                success "UFW Firewall aktiviert"
                SUMMARY+=("Firewall: UFW aktiviert")
            fi
            ;;
        dnf|zypper)
            if command -v firewall-cmd &> /dev/null; then
                info "Konfiguriere firewalld..."
                
                systemctl enable --now firewalld
                firewall-cmd --permanent --add-service=ssh
                success "SSH-Service erlaubt"
                
                echo ""
                info "Zusätzliche Services? (z.B. http,https)"
                local services
                read_input "Services (kommagetrennt, oder Enter für keine)" services ""
                
                if [ -n "$services" ]; then
                    IFS=',' read -ra SERVICE_ARRAY <<< "$services"
                    for service in "${SERVICE_ARRAY[@]}"; do
                        firewall-cmd --permanent --add-service=$service 2>/dev/null || \
                        firewall-cmd --permanent --add-port=$service/tcp
                        success "Service/Port $service erlaubt"
                    done
                fi
                
                firewall-cmd --reload
                
                echo ""
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                firewall-cmd --list-all
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                
                success "firewalld aktiviert"
                SUMMARY+=("Firewall: firewalld aktiviert")
            fi
            ;;
    esac
    
    sleep 1
}

# Schritt 8: SSH Hardening
harden_ssh() {
    step_header "SSH-Sicherheit"
    
    local harden_it
    ask_yes_no "SSH-Konfiguration härten?" harden_it
    
    if [ "$harden_it" = false ]; then
        info "SSH-Härtung übersprungen"
        SUMMARY+=("SSH: nicht gehärtet")
        return 0
    fi
    
    local ssh_config="/etc/ssh/sshd_config"
    
    if [ ! -f "$ssh_config" ]; then
        warning "SSH-Config nicht gefunden: $ssh_config"
        SUMMARY+=("SSH: Config nicht gefunden")
        return 0
    fi
    
    info "Erstelle Backup: ${ssh_config}.backup"
    cp $ssh_config ${ssh_config}.backup
    success "Backup erstellt"
    
    echo ""
    local disable_root
    ask_yes_no "Root-Login deaktivieren? (empfohlen)" disable_root
    
    if [ "$disable_root" = true ]; then
        sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' $ssh_config
        success "Root-Login deaktiviert"
    fi
    
    echo ""
    local change_port
    ask_yes_no "SSH-Port ändern?" change_port
    
    if [ "$change_port" = true ]; then
        local new_port
        read_input "Neuer SSH-Port" new_port "2222"
        
        sed -i "s/^#*Port.*/Port $new_port/" $ssh_config
        success "SSH-Port geändert: $new_port"
        warning "Stelle sicher, dass Port $new_port in der Firewall offen ist!"
    fi
    
    info "Starte SSH-Dienst neu..."
    systemctl restart sshd || systemctl restart ssh
    success "SSH neu gestartet"
    
    echo ""
    info "Backup verfügbar unter: ${ssh_config}.backup"
    
    success "SSH-Konfiguration gehärtet"
    SUMMARY+=("SSH: gehärtet (Backup: ${ssh_config}.backup)")
    
    sleep 1
}

# Schritt 9: Auto-Updates
setup_auto_updates() {
    step_header "Automatische Updates"
    
    local setup_it
    ask_yes_no "Automatische Sicherheitsupdates aktivieren?" setup_it
    
    if [ "$setup_it" = false ]; then
        info "Auto-Updates nicht konfiguriert"
        SUMMARY+=("Auto-Updates: nicht aktiviert")
        return 0
    fi
    
    case $PKG_MGR in
        apt)
            info "Installiere unattended-upgrades..."
            eval "$INSTALL_CMD unattended-upgrades"
            
            info "Konfiguriere unattended-upgrades..."
            dpkg-reconfigure -plow unattended-upgrades
            
            success "Automatische Updates aktiviert (unattended-upgrades)"
            SUMMARY+=("Auto-Updates: unattended-upgrades")
            ;;
        dnf)
            info "Installiere dnf-automatic..."
            eval "$INSTALL_CMD dnf-automatic"
            
            info "Aktiviere dnf-automatic Timer..."
            systemctl enable --now dnf-automatic.timer
            
            success "Automatische Updates aktiviert (dnf-automatic)"
            SUMMARY+=("Auto-Updates: dnf-automatic")
            ;;
        *)
            warning "Automatische Updates für $PKG_MGR noch nicht implementiert"
            SUMMARY+=("Auto-Updates: nicht unterstützt")
            ;;
    esac
    
    sleep 1
}

# Finale Zusammenfassung
show_summary() {
    clear
    echo ""
    echo -e "${GREEN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║                    SETUP ABGESCHLOSSEN                    ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo ""
    
    show_progress $TOTAL_STEPS $TOTAL_STEPS
    echo ""
    echo ""
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Durchgeführte Aktionen:${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    for item in "${SUMMARY[@]}"; do
        echo -e "${GREEN}  ✓${NC} $item"
    done
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Systeminfo:${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  Hostname:     $(hostname)"
    echo "  Zeitzone:     $(timedatectl | grep "Time zone" | awk '{print $3}')"
    echo "  Kernel:       $(uname -r)"
    echo "  Uptime:       $(uptime -p)"
    echo "  Datum/Zeit:   $(date)"
    echo ""
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Empfohlene nächste Schritte:${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  1. Neuen Benutzer erstellen: adduser username"
    echo "  2. Benutzer zu sudo-Gruppe: usermod -aG sudo username"
    echo "  3. SSH-Keys konfigurieren"
    echo "  4. Firewall-Regeln überprüfen"
    echo "  5. Benötigte Anwendungen installieren"
    echo ""
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    local reboot_now
    ask_yes_no "Jetzt neu starten?" reboot_now
    
    if [ "$reboot_now" = true ]; then
        info "System wird in 5 Sekunden neu gestartet..."
        info "CTRL+C zum Abbrechen"
        sleep 5
        reboot
    else
        success "Setup abgeschlossen!"
        warning "Bitte das System später neu starten für alle Änderungen"
    fi
}

# Main
main() {
    # Error Handler
    trap 'error "Script wurde bei Zeile $LINENO mit Fehler beendet"' ERR
    
    show_banner
    check_root
    
    echo ""
    info "Dieses Script führt eine vollständige Erstkonfiguration durch"
    info "Alle Schritte werden mit detailliertem Feedback angezeigt"
    info "Du kannst jeden Schritt einzeln bestätigen oder überspringen"
    echo ""
    
    local start_now
    ask_yes_no "Setup jetzt starten?" start_now
    
    if [ "$start_now" = false ]; then
        info "Setup abgebrochen"
        exit 0
    fi
    
    # Alle Schritte ausführen
    detect_os
    system_update
    change_hostname
    change_timezone
    setup_swap
    install_tools
    setup_firewall
    harden_ssh
    setup_auto_updates
    
    show_summary
}

# Script starten
main "$@"
