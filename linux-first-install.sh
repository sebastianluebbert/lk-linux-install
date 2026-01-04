#!/bin/bash

#######################################
# Interaktives Linux Setup Script
# Einfach und robust
#######################################

# Farben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Zusammenfassung
declare -a SUMMARY=()

# Ausgabe-Funktionen
print_header() {
    echo ""
    echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║${NC} ${YELLOW}$1${NC}"
    echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[✓]${NC} $1"; }
warning() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }

# Banner
show_banner() {
    clear
    echo -e "${GREEN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║        LK-EDV Dienstleistungen                            ║
║        Interaktives Linux Setup Script                    ║
║        Schritt für Schritt Konfiguration                  ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Root-Check
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        error "Dieses Script muss als root ausgeführt werden!"
        echo "Bitte mit 'sudo $0' ausführen"
        exit 1
    fi
}

# Ja/Nein Frage - VEREINFACHT
ask_yes_no() {
    local prompt="$1"
    local answer
    
    while true; do
        echo ""
        echo -n "${prompt} (j/n): "
        read answer
        
        if [ "$answer" = "j" ] || [ "$answer" = "J" ] || [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
            return 0
        elif [ "$answer" = "n" ] || [ "$answer" = "N" ]; then
            return 1
        else
            warning "Bitte nur 'j' oder 'n' eingeben!"
        fi
    done
}

# Text-Eingabe - VEREINFACHT
ask_input() {
    local prompt="$1"
    local default="$2"
    local result
    
    if [ -n "$default" ]; then
        echo -n "${prompt} [Standard: ${default}]: "
        read result
        if [ -z "$result" ]; then
            echo "$default"
        else
            echo "$result"
        fi
    else
        echo -n "${prompt}: "
        read result
        echo "$result"
    fi
}

# Nummerierte Auswahl - VEREINFACHT
select_number() {
    local prompt="$1"
    shift
    local options=("$@")
    local choice
    
    echo ""
    echo "$prompt"
    echo ""
    
    for i in "${!options[@]}"; do
        echo "  $((i+1))) ${options[$i]}"
    done
    echo ""
    
    while true; do
        echo -n "Wähle eine Nummer (1-${#options[@]}): "
        read choice
        
        if [[ "$choice" =~ ^[0-9]+$ ]]; then
            if [ "$choice" -ge 1 ] && [ "$choice" -le "${#options[@]}" ]; then
                return $((choice-1))
            fi
        fi
        
        warning "Bitte eine Zahl zwischen 1 und ${#options[@]} eingeben!"
    done
}

# System-Erkennung
detect_system() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME="$NAME"
        OS_ID="$ID"
        
        case $OS_ID in
            ubuntu|debian|linuxmint|pop)
                PKG_MGR="apt"
                UPDATE_CMD="apt-get update -qq"
                UPGRADE_CMD="DEBIAN_FRONTEND=noninteractive apt-get upgrade -y"
                INSTALL_CMD="DEBIAN_FRONTEND=noninteractive apt-get install -y"
                ;;
            fedora|rhel|centos|rocky|almalinux)
                PKG_MGR="dnf"
                UPDATE_CMD="dnf check-update || true"
                UPGRADE_CMD="dnf upgrade -y"
                INSTALL_CMD="dnf install -y"
                ;;
            arch|manjaro)
                PKG_MGR="pacman"
                UPDATE_CMD="pacman -Sy --noconfirm"
                UPGRADE_CMD="pacman -Syu --noconfirm"
                INSTALL_CMD="pacman -S --noconfirm"
                ;;
            *)
                PKG_MGR="apt"
                UPDATE_CMD="apt-get update"
                UPGRADE_CMD="apt-get upgrade -y"
                INSTALL_CMD="apt-get install -y"
                ;;
        esac
    fi
}

#######################################
# FRAGEN
#######################################

question_welcome() {
    show_banner
    check_root
    
    echo "Willkommen! Dieses Script hilft dir bei der Erstkonfiguration."
    echo ""
    echo "Ich werde dir Fragen stellen und du wählst aus,"
    echo "was du machen möchtest."
    echo ""
    
    if ask_yes_no "Bereit für die Konfiguration?"; then
        info "Los geht's!"
    else
        info "Setup abgebrochen."
        exit 0
    fi
}

question_system_update() {
    print_header "System Update"
    
    info "System: $OS_NAME"
    info "Package Manager: $PKG_MGR"
    
    if ask_yes_no "System jetzt aktualisieren?"; then
        echo ""
        info "Starte Update..."
        $UPDATE_CMD
        echo ""
        info "Starte Upgrade..."
        $UPGRADE_CMD
        echo ""
        success "System aktualisiert!"
        SUMMARY+=("✓ System-Update durchgeführt")
    else
        info "Update übersprungen"
        SUMMARY+=("⊘ System-Update übersprungen")
    fi
}

question_hostname() {
    print_header "Hostname"
    
    info "Aktueller Hostname: $(hostname)"
    echo ""
    echo "Beispiele: webserver01, dbserver, meinserver"
    
    if ask_yes_no "Hostname ändern?"; then
        new_hostname=$(ask_input "Wie soll der Server heißen?" "")
        
        if [ -n "$new_hostname" ]; then
            old_hostname=$(hostname)
            hostnamectl set-hostname "$new_hostname"
            sed -i "s/$old_hostname/$new_hostname/g" /etc/hosts
            
            if ! grep -q "127.0.1.1" /etc/hosts; then
                echo "127.0.1.1    $new_hostname" >> /etc/hosts
            fi
            
            success "Hostname: $old_hostname → $new_hostname"
            SUMMARY+=("✓ Hostname: $new_hostname")
        fi
    else
        SUMMARY+=("⊘ Hostname nicht geändert")
    fi
}

question_timezone() {
    print_header "Zeitzone"
    
    info "Aktuelle Zeitzone: $(timedatectl | grep "Time zone" | awk '{print $3}')"
    
    if ask_yes_no "Zeitzone ändern?"; then
        echo ""
        
        select_number "Wähle deine Region:" \
            "Europa" \
            "Amerika" \
            "Asien" \
            "Andere"
        region=$?
        
        case $region in
            0) # Europa
                select_number "Wähle deine Zeitzone:" \
                    "Europe/Berlin (Deutschland)" \
                    "Europe/London (UK)" \
                    "Europe/Paris (Frankreich)" \
                    "Europe/Vienna (Österreich)" \
                    "Europe/Zurich (Schweiz)"
                
                tz=$?
                timezones=("Europe/Berlin" "Europe/London" "Europe/Paris" "Europe/Vienna" "Europe/Zurich")
                timezone="${timezones[$tz]}"
                ;;
                
            1) # Amerika
                select_number "Wähle deine Zeitzone:" \
                    "America/New_York (US Ostküste)" \
                    "America/Chicago (US Zentral)" \
                    "America/Los_Angeles (US Westküste)" \
                    "America/Toronto (Kanada)"
                
                tz=$?
                timezones=("America/New_York" "America/Chicago" "America/Los_Angeles" "America/Toronto")
                timezone="${timezones[$tz]}"
                ;;
                
            2) # Asien
                select_number "Wähle deine Zeitzone:" \
                    "Asia/Tokyo (Japan)" \
                    "Asia/Shanghai (China)" \
                    "Asia/Dubai (VAE)" \
                    "Asia/Singapore (Singapur)"
                
                tz=$?
                timezones=("Asia/Tokyo" "Asia/Shanghai" "Asia/Dubai" "Asia/Singapore")
                timezone="${timezones[$tz]}"
                ;;
                
            3) # Andere
                timezone=$(ask_input "Zeitzone eingeben (z.B. Europe/Berlin)" "Europe/Berlin")
                ;;
        esac
        
        timedatectl set-timezone "$timezone" 2>/dev/null
        success "Zeitzone: $timezone"
        SUMMARY+=("✓ Zeitzone: $timezone")
    else
        SUMMARY+=("⊘ Zeitzone nicht geändert")
    fi
}

question_swap() {
    print_header "Swap"
    
    if swapon --show | grep -q '/'; then
        info "Swap bereits vorhanden"
        SUMMARY+=("⊘ Swap bereits vorhanden")
        return
    fi
    
    total_ram=$(free -m | awk '/^Mem:/{print $2}')
    info "Dein RAM: ${total_ram}MB"
    
    if ask_yes_no "Swap einrichten?"; then
        echo ""
        
        if [ $total_ram -lt 2048 ]; then
            recommended="2G"
        elif [ $total_ram -lt 8192 ]; then
            recommended="4G"
        else
            recommended="8G"
        fi
        
        select_number "Swap-Größe wählen:" \
            "Empfohlen: ${recommended}" \
            "2 GB" \
            "4 GB" \
            "8 GB" \
            "Eigene Größe"
        
        choice=$?
        
        case $choice in
            0) swap_size="$recommended" ;;
            1) swap_size="2G" ;;
            2) swap_size="4G" ;;
            3) swap_size="8G" ;;
            4) swap_size=$(ask_input "Größe (z.B. 4G)" "4G") ;;
        esac
        
        echo ""
        info "Erstelle ${swap_size} Swap..."
        
        fallocate -l $swap_size /swapfile
        chmod 600 /swapfile
        mkswap /swapfile >/dev/null 2>&1
        swapon /swapfile
        
        if ! grep -q '/swapfile' /etc/fstab; then
            echo '/swapfile none swap sw 0 0' >> /etc/fstab
        fi
        
        success "Swap: $swap_size"
        SUMMARY+=("✓ Swap: $swap_size")
    else
        SUMMARY+=("⊘ Swap nicht eingerichtet")
    fi
}

question_tools() {
    print_header "Tools installieren"
    
    echo "Standard-Tools: curl, wget, git, vim, nano, htop, ufw, fail2ban"
    echo ""
    
    if ask_yes_no "Diese Tools installieren?"; then
        echo ""
        info "Installiere Tools..."
        
        case $PKG_MGR in
            apt) $INSTALL_CMD curl wget git vim nano htop net-tools ufw fail2ban unzip ;;
            dnf) $INSTALL_CMD curl wget git vim nano htop net-tools firewalld fail2ban unzip ;;
            *) $INSTALL_CMD curl wget git vim nano htop unzip ;;
        esac
        
        success "Tools installiert"
        SUMMARY+=("✓ Tools installiert")
    else
        SUMMARY+=("⊘ Tools nicht installiert")
    fi
}

question_firewall() {
    print_header "Firewall"
    
    if ! ask_yes_no "Firewall aktivieren?"; then
        SUMMARY+=("⊘ Firewall nicht aktiviert")
        return
    fi
    
    case $PKG_MGR in
        apt|pacman)
            if ! command -v ufw &> /dev/null; then
                $INSTALL_CMD ufw
            fi
            
            ufw --force reset >/dev/null 2>&1
            ufw default deny incoming >/dev/null 2>&1
            ufw default allow outgoing >/dev/null 2>&1
            ufw allow ssh >/dev/null 2>&1
            
            echo ""
            if ask_yes_no "Webserver (Ports 80, 443)?"; then
                ufw allow 80 >/dev/null 2>&1
                ufw allow 443 >/dev/null 2>&1
                success "Webserver-Ports geöffnet"
            fi
            
            echo "y" | ufw enable >/dev/null 2>&1
            success "UFW aktiviert"
            SUMMARY+=("✓ Firewall: UFW")
            ;;
            
        dnf)
            systemctl enable --now firewalld >/dev/null 2>&1
            firewall-cmd --permanent --add-service=ssh >/dev/null 2>&1
            
            echo ""
            if ask_yes_no "Webserver (HTTP/HTTPS)?"; then
                firewall-cmd --permanent --add-service=http >/dev/null 2>&1
                firewall-cmd --permanent --add-service=https >/dev/null 2>&1
            fi
            
            firewall-cmd --reload >/dev/null 2>&1
            success "firewalld aktiviert"
            SUMMARY+=("✓ Firewall: firewalld")
            ;;
    esac
}

question_ssh() {
    print_header "SSH absichern"
    
    if [ ! -f /etc/ssh/sshd_config ]; then
        warning "SSH-Config nicht gefunden"
        return
    fi
    
    if ! ask_yes_no "SSH-Sicherheit verbessern?"; then
        SUMMARY+=("⊘ SSH nicht geändert")
        return
    fi
    
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
    
    echo ""
    if ask_yes_no "Root-Login deaktivieren? (EMPFOHLEN)"; then
        sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
        success "Root-Login deaktiviert"
    fi
    
    echo ""
    if ask_yes_no "SSH-Port ändern?"; then
        select_number "Wähle Port:" \
            "2222" \
            "2200" \
            "Eigener Port"
        
        choice=$?
        case $choice in
            0) new_port="2222" ;;
            1) new_port="2200" ;;
            2) new_port=$(ask_input "Port (1024-65535)" "2222") ;;
        esac
        
        sed -i "s/^#*Port.*/Port $new_port/" /etc/ssh/sshd_config
        success "SSH-Port: $new_port"
        warning "Öffne Port $new_port in der Firewall!"
    fi
    
    systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
    success "SSH neu gestartet"
    SUMMARY+=("✓ SSH gesichert")
}

question_auto_updates() {
    print_header "Automatische Updates"
    
    if ! ask_yes_no "Automatische Updates aktivieren?"; then
        SUMMARY+=("⊘ Auto-Updates nicht aktiviert")
        return
    fi
    
    case $PKG_MGR in
        apt)
            $INSTALL_CMD unattended-upgrades
            success "Auto-Updates aktiviert"
            SUMMARY+=("✓ Auto-Updates: unattended-upgrades")
            ;;
        dnf)
            $INSTALL_CMD dnf-automatic
            systemctl enable --now dnf-automatic.timer >/dev/null 2>&1
            success "Auto-Updates aktiviert"
            SUMMARY+=("✓ Auto-Updates: dnf-automatic")
            ;;
        *)
            warning "Nicht unterstützt für $PKG_MGR"
            SUMMARY+=("⊘ Auto-Updates nicht unterstützt")
            ;;
    esac
}

show_summary() {
    clear
    echo ""
    echo -e "${GREEN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║              SETUP ABGESCHLOSSEN!                         ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo ""
    echo "Zusammenfassung:"
    echo ""
    
    for item in "${SUMMARY[@]}"; do
        echo "  $item"
    done
    
    echo ""
    info "Hostname: $(hostname)"
    info "Zeitzone: $(timedatectl | grep "Time zone" | awk '{print $3}')"
    echo ""
    
    if ask_yes_no "System neu starten?"; then
        info "Neustart in 5 Sekunden..."
        sleep 5
        reboot
    else
        success "Setup fertig! Bitte später neu starten."
    fi
}

# MAIN
main() {
    detect_system
    
    question_welcome
    question_system_update
    question_hostname
    question_timezone
    question_swap
    question_tools
    question_firewall
    question_ssh
    question_auto_updates
    
    show_summary
}

main "$@"
