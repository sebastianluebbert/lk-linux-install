#!/bin/bash

#######################################
# Interaktives Linux Setup Script
# Führt dich durch alle Konfigurationen
#######################################

set -euo pipefail

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

# Funktionen für formatierte Ausgaben
print_header() {
    echo ""
    echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║${NC} ${YELLOW}$1${NC}"
    echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_box() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
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
║                                                           ║
║        Interaktives Linux Setup Script                   ║
║        Schritt für Schritt Konfiguration                 ║
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

# Eingabe mit Nummer-Auswahl
select_option() {
    local prompt="$1"
    shift
    local options=("$@")
    
    echo -e "${YELLOW}$prompt${NC}"
    echo ""
    
    for i in "${!options[@]}"; do
        echo "  $((i+1))) ${options[$i]}"
    done
    echo ""
    
    while true; do
        read -p "Wähle eine Nummer (1-${#options[@]}): " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#options[@]}" ]; then
            return $((choice-1))
        else
            warning "Bitte eine Zahl zwischen 1 und ${#options[@]} eingeben!"
        fi
    done
}

# Ja/Nein Frage
ask_yes_no() {
    local prompt="$1"
    while true; do
        read -p "$(echo -e ${YELLOW}$prompt${NC}) (j/n): " answer
        case "$answer" in
            [JjYy]*) return 0 ;;
            [Nn]*) return 1 ;;
            *) warning "Bitte 'j' oder 'n' eingeben!" ;;
        esac
    done
}

# Text-Eingabe
ask_input() {
    local prompt="$1"
    local default="$2"
    local result
    
    if [ -n "$default" ]; then
        read -p "$(echo -e ${YELLOW}$prompt${NC}) [Standard: $default]: " result
        echo "${result:-$default}"
    else
        read -p "$(echo -e ${YELLOW}$prompt${NC}): " result
        echo "$result"
    fi
}

# Wartezeit mit Animation
wait_animation() {
    local duration=$1
    local text="$2"
    echo -n "$text"
    for i in $(seq 1 $duration); do
        echo -n "."
        sleep 1
    done
    echo " Fertig!"
}

#######################################
# HAUPTFRAGEN
#######################################

# Frage 1: Willkommen und Start
question_welcome() {
    show_banner
    check_root
    
    echo "Willkommen! Dieses Script hilft dir bei der Erstkonfiguration."
    echo ""
    echo "Ich werde dir jetzt einige Fragen stellen, um dein System"
    echo "optimal einzurichten. Du kannst bei jeder Frage entscheiden,"
    echo "was du machen möchtest."
    echo ""
    
    if ! ask_yes_no "Bereit für die Konfiguration?"; then
        info "Setup abgebrochen. Bis zum nächsten Mal!"
        exit 0
    fi
}

# Frage 2: System-Update
question_system_update() {
    print_header "System Update"
    
    echo "Dein System sollte auf dem neuesten Stand sein."
    echo ""
    info "Aktuelles System: $OS_NAME"
    info "Package Manager: $PKG_MGR"
    echo ""
    
    if ask_yes_no "System jetzt aktualisieren?"; then
        echo ""
        info "Starte System-Update..."
        echo ""
        
        eval $UPDATE_CMD
        echo ""
        eval $UPGRADE_CMD
        
        success "System wurde aktualisiert!"
        SUMMARY+=("✓ System-Update durchgeführt")
    else
        info "System-Update übersprungen"
        SUMMARY+=("⊘ System-Update übersprungen")
    fi
}

# Frage 3: Hostname
question_hostname() {
    print_header "Hostname festlegen"
    
    echo "Der Hostname ist der Name deines Servers im Netzwerk."
    echo ""
    info "Aktueller Hostname: $(hostname)"
    echo ""
    echo "Beispiele für gute Hostnamen:"
    echo "  • webserver01, dbserver, mailserver"
    echo "  • app-prod-01, staging-web"
    echo "  • meinserver, homelab"
    echo ""
    
    if ask_yes_no "Möchtest du den Hostname ändern?"; then
        echo ""
        new_hostname=$(ask_input "Wie soll dein Server heißen?" "")
        
        if [ -n "$new_hostname" ]; then
            old_hostname=$(hostname)
            
            info "Setze Hostname auf: $new_hostname"
            hostnamectl set-hostname "$new_hostname"
            sed -i "s/$old_hostname/$new_hostname/g" /etc/hosts
            
            if ! grep -q "127.0.1.1" /etc/hosts; then
                echo "127.0.1.1    $new_hostname" >> /etc/hosts
            fi
            
            success "Hostname geändert: $old_hostname → $new_hostname"
            SUMMARY+=("✓ Hostname: $new_hostname")
        fi
    else
        info "Hostname bleibt: $(hostname)"
        SUMMARY+=("⊘ Hostname nicht geändert")
    fi
}

# Frage 4: Zeitzone
question_timezone() {
    print_header "Zeitzone einstellen"
    
    echo "Die richtige Zeitzone ist wichtig für Logs und Timestamps."
    echo ""
    info "Aktuelle Zeitzone: $(timedatectl | grep "Time zone" | awk '{print $3}')"
    info "Aktuelle Uhrzeit: $(date '+%H:%M:%S')"
    echo ""
    
    if ask_yes_no "Möchtest du die Zeitzone ändern?"; then
        echo ""
        
        # Zeitzone auswählen
        print_box "Wähle deine Zeitzone"
        
        select_option "In welcher Region befindest du dich?" \
            "Europa" \
            "Amerika" \
            "Asien" \
            "Afrika" \
            "Australien/Ozeanien" \
            "Andere (Liste anzeigen)"
        region_choice=$?
        
        echo ""
        
        case $region_choice in
            0) # Europa
                select_option "Wähle deine Zeitzone:" \
                    "Europe/Berlin (Deutschland, MEZ)" \
                    "Europe/London (UK, GMT)" \
                    "Europe/Paris (Frankreich)" \
                    "Europe/Rome (Italien)" \
                    "Europe/Madrid (Spanien)" \
                    "Europe/Vienna (Österreich)" \
                    "Europe/Zurich (Schweiz)" \
                    "Europe/Amsterdam (Niederlande)" \
                    "Europe/Stockholm (Schweden)" \
                    "Europe/Warsaw (Polen)"
                
                tz_choice=$?
                timezones=("Europe/Berlin" "Europe/London" "Europe/Paris" "Europe/Rome" "Europe/Madrid" "Europe/Vienna" "Europe/Zurich" "Europe/Amsterdam" "Europe/Stockholm" "Europe/Warsaw")
                timezone="${timezones[$tz_choice]}"
                ;;
                
            1) # Amerika
                select_option "Wähle deine Zeitzone:" \
                    "America/New_York (US Ostküste)" \
                    "America/Chicago (US Zentral)" \
                    "America/Denver (US Mountain)" \
                    "America/Los_Angeles (US Westküste)" \
                    "America/Toronto (Kanada Ost)" \
                    "America/Vancouver (Kanada West)" \
                    "America/Mexico_City (Mexiko)" \
                    "America/Sao_Paulo (Brasilien)"
                
                tz_choice=$?
                timezones=("America/New_York" "America/Chicago" "America/Denver" "America/Los_Angeles" "America/Toronto" "America/Vancouver" "America/Mexico_City" "America/Sao_Paulo")
                timezone="${timezones[$tz_choice]}"
                ;;
                
            2) # Asien
                select_option "Wähle deine Zeitzone:" \
                    "Asia/Tokyo (Japan)" \
                    "Asia/Shanghai (China)" \
                    "Asia/Hong_Kong (Hongkong)" \
                    "Asia/Singapore (Singapur)" \
                    "Asia/Dubai (VAE)" \
                    "Asia/Kolkata (Indien)" \
                    "Asia/Bangkok (Thailand)" \
                    "Asia/Seoul (Südkorea)"
                
                tz_choice=$?
                timezones=("Asia/Tokyo" "Asia/Shanghai" "Asia/Hong_Kong" "Asia/Singapore" "Asia/Dubai" "Asia/Kolkata" "Asia/Bangkok" "Asia/Seoul")
                timezone="${timezones[$tz_choice]}"
                ;;
                
            3) # Afrika
                select_option "Wähle deine Zeitzone:" \
                    "Africa/Cairo (Ägypten)" \
                    "Africa/Johannesburg (Südafrika)" \
                    "Africa/Lagos (Nigeria)" \
                    "Africa/Nairobi (Kenia)"
                
                tz_choice=$?
                timezones=("Africa/Cairo" "Africa/Johannesburg" "Africa/Lagos" "Africa/Nairobi")
                timezone="${timezones[$tz_choice]}"
                ;;
                
            4) # Australien
                select_option "Wähle deine Zeitzone:" \
                    "Australia/Sydney (Ost)" \
                    "Australia/Melbourne (Süd-Ost)" \
                    "Australia/Brisbane (Nord-Ost)" \
                    "Australia/Perth (West)" \
                    "Pacific/Auckland (Neuseeland)"
                
                tz_choice=$?
                timezones=("Australia/Sydney" "Australia/Melbourne" "Australia/Brisbane" "Australia/Perth" "Pacific/Auckland")
                timezone="${timezones[$tz_choice]}"
                ;;
                
            5) # Andere
                echo ""
                info "Verfügbare Zeitzonen anzeigen mit: timedatectl list-timezones"
                timezone=$(ask_input "Gib die Zeitzone ein (z.B. Europe/Berlin)" "Europe/Berlin")
                ;;
        esac
        
        echo ""
        info "Setze Zeitzone: $timezone"
        
        if timedatectl set-timezone "$timezone" 2>/dev/null; then
            success "Zeitzone geändert!"
            info "Neue Uhrzeit: $(date '+%H:%M:%S %Z')"
            SUMMARY+=("✓ Zeitzone: $timezone")
        else
            error "Konnte Zeitzone nicht setzen"
            SUMMARY+=("✗ Zeitzone konnte nicht gesetzt werden")
        fi
    else
        info "Zeitzone bleibt unverändert"
        SUMMARY+=("⊘ Zeitzone nicht geändert")
    fi
}

# Frage 5: Swap
question_swap() {
    print_header "Swap-Speicher konfigurieren"
    
    echo "Swap ist virtueller Arbeitsspeicher auf der Festplatte."
    echo "Er hilft, wenn der RAM voll ist."
    echo ""
    
    if swapon --show | grep -q '/'; then
        info "Du hast bereits Swap konfiguriert:"
        echo ""
        swapon --show
        echo ""
        SUMMARY+=("⊘ Swap bereits vorhanden")
        return
    fi
    
    info "Aktuell ist kein Swap konfiguriert"
    
    total_ram=$(free -m | awk '/^Mem:/{print $2}')
    info "Dein RAM: ${total_ram}MB"
    echo ""
    
    if ask_yes_no "Möchtest du Swap einrichten?"; then
        echo ""
        
        # Empfehlung basierend auf RAM
        if [ $total_ram -lt 2048 ]; then
            recommended="2G"
        elif [ $total_ram -lt 8192 ]; then
            recommended="4G"
        else
            recommended="8G"
        fi
        
        print_box "Swap-Größe wählen"
        
        select_option "Wie groß soll der Swap sein?" \
            "Empfohlen: ${recommended} (basierend auf deinem RAM)" \
            "2 GB (für kleine Server)" \
            "4 GB (für mittlere Server)" \
            "8 GB (für große Server)" \
            "16 GB (für sehr große Server)" \
            "Eigene Größe eingeben"
        
        swap_choice=$?
        
        case $swap_choice in
            0) swap_size="$recommended" ;;
            1) swap_size="2G" ;;
            2) swap_size="4G" ;;
            3) swap_size="8G" ;;
            4) swap_size="16G" ;;
            5) swap_size=$(ask_input "Größe eingeben (z.B. 4G, 8G)" "4G") ;;
        esac
        
        echo ""
        info "Erstelle ${swap_size} Swap-Datei..."
        
        fallocate -l $swap_size /swapfile
        chmod 600 /swapfile
        mkswap /swapfile > /dev/null 2>&1
        swapon /swapfile
        
        if ! grep -q '/swapfile' /etc/fstab; then
            echo '/swapfile none swap sw 0 0' >> /etc/fstab
        fi
        
        echo ""
        success "Swap erfolgreich eingerichtet!"
        swapon --show
        SUMMARY+=("✓ Swap: $swap_size erstellt")
    else
        info "Swap-Einrichtung übersprungen"
        SUMMARY+=("⊘ Swap nicht eingerichtet")
    fi
}

# Frage 6: Tools installieren
question_tools() {
    print_header "Wichtige Tools installieren"
    
    echo "Diese Tools sind für die meisten Server nützlich."
    echo ""
    
    case $PKG_MGR in
        apt) tools=("curl" "wget" "git" "vim" "nano" "htop" "net-tools" "ufw" "fail2ban" "unzip" "zip" "tree" "screen") ;;
        dnf) tools=("curl" "wget" "git" "vim" "nano" "htop" "net-tools" "firewalld" "fail2ban" "unzip" "zip" "tree" "screen") ;;
        pacman) tools=("curl" "wget" "git" "vim" "nano" "htop" "net-tools" "ufw" "fail2ban" "unzip" "zip" "tree" "screen") ;;
        *) tools=("curl" "wget" "git" "vim" "htop" "unzip") ;;
    esac
    
    echo "Folgende Tools werden installiert:"
    echo ""
    for tool in "${tools[@]}"; do
        echo "  • $tool"
    done
    echo ""
    
    if ask_yes_no "Diese Tools installieren?"; then
        echo ""
        info "Installiere Tools..."
        
        eval $INSTALL_CMD ${tools[@]} > /dev/null 2>&1
        
        success "Tools installiert!"
        SUMMARY+=("✓ ${#tools[@]} Tools installiert")
    else
        info "Tool-Installation übersprungen"
        SUMMARY+=("⊘ Keine Tools installiert")
    fi
}

# Frage 7: Firewall
question_firewall() {
    print_header "Firewall einrichten"
    
    echo "Eine Firewall schützt deinen Server vor unerwünschtem Zugriff."
    echo ""
    
    if ! ask_yes_no "Möchtest du die Firewall aktivieren?"; then
        info "Firewall-Konfiguration übersprungen"
        SUMMARY+=("⊘ Firewall nicht aktiviert")
        return
    fi
    
    echo ""
    print_box "Firewall-Konfiguration"
    
    case $PKG_MGR in
        apt|pacman)
            if ! command -v ufw &> /dev/null; then
                info "UFW wird installiert..."
                eval $INSTALL_CMD ufw > /dev/null 2>&1
            fi
            
            info "Konfiguriere UFW..."
            ufw --force reset > /dev/null 2>&1
            ufw default deny incoming > /dev/null 2>&1
            ufw default allow outgoing > /dev/null 2>&1
            ufw allow ssh > /dev/null 2>&1
            
            success "Grundkonfiguration: Eingehend blockiert, Ausgehend erlaubt, SSH erlaubt"
            
            echo ""
            echo "Brauchst du zusätzliche Dienste?"
            echo ""
            
            if ask_yes_no "Webserver (Ports 80 und 443)?"; then
                ufw allow 80 > /dev/null 2>&1
                ufw allow 443 > /dev/null 2>&1
                success "Webserver-Ports geöffnet (80, 443)"
            fi
            
            if ask_yes_no "FTP (Port 21)?"; then
                ufw allow 21 > /dev/null 2>&1
                success "FTP-Port geöffnet (21)"
            fi
            
            if ask_yes_no "MySQL/MariaDB (Port 3306)?"; then
                ufw allow 3306 > /dev/null 2>&1
                success "MySQL-Port geöffnet (3306)"
            fi
            
            if ask_yes_no "Weitere Ports manuell öffnen?"; then
                custom_ports=$(ask_input "Ports (kommagetrennt, z.B. 8080,9000)" "")
                if [ -n "$custom_ports" ]; then
                    IFS=',' read -ra PORT_ARRAY <<< "$custom_ports"
                    for port in "${PORT_ARRAY[@]}"; do
                        ufw allow $port > /dev/null 2>&1
                        success "Port $port geöffnet"
                    done
                fi
            fi
            
            echo ""
            info "Aktiviere Firewall..."
            echo "y" | ufw enable > /dev/null 2>&1
            
            echo ""
            success "UFW Firewall aktiviert!"
            echo ""
            ufw status
            
            SUMMARY+=("✓ Firewall: UFW aktiviert")
            ;;
            
        dnf|zypper)
            if ! command -v firewall-cmd &> /dev/null; then
                info "firewalld wird installiert..."
                eval $INSTALL_CMD firewalld > /dev/null 2>&1
            fi
            
            info "Konfiguriere firewalld..."
            systemctl enable --now firewalld > /dev/null 2>&1
            firewall-cmd --permanent --add-service=ssh > /dev/null 2>&1
            
            success "SSH-Service erlaubt"
            
            echo ""
            if ask_yes_no "Webserver (HTTP/HTTPS)?"; then
                firewall-cmd --permanent --add-service=http > /dev/null 2>&1
                firewall-cmd --permanent --add-service=https > /dev/null 2>&1
                success "Webserver-Services aktiviert"
            fi
            
            if ask_yes_no "MySQL?"; then
                firewall-cmd --permanent --add-service=mysql > /dev/null 2>&1
                success "MySQL-Service aktiviert"
            fi
            
            firewall-cmd --reload > /dev/null 2>&1
            
            echo ""
            success "firewalld aktiviert!"
            echo ""
            firewall-cmd --list-all
            
            SUMMARY+=("✓ Firewall: firewalld aktiviert")
            ;;
    esac
}

# Frage 8: SSH absichern
question_ssh() {
    print_header "SSH-Zugang absichern"
    
    echo "SSH ist die Fernverbindung zu deinem Server."
    echo "Wir können sie sicherer machen."
    echo ""
    
    if [ ! -f /etc/ssh/sshd_config ]; then
        warning "SSH-Config nicht gefunden"
        SUMMARY+=("⊘ SSH nicht konfiguriert")
        return
    fi
    
    if ! ask_yes_no "SSH-Sicherheit verbessern?"; then
        info "SSH-Konfiguration übersprungen"
        SUMMARY+=("⊘ SSH nicht geändert")
        return
    fi
    
    echo ""
    info "Erstelle Backup der SSH-Config..."
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d)
    success "Backup erstellt"
    
    echo ""
    print_box "SSH-Sicherheitsoptionen"
    
    # Root-Login
    if ask_yes_no "Root-Login via SSH deaktivieren? (EMPFOHLEN)"; then
        sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
        success "Root-Login deaktiviert"
        warning "Stelle sicher, dass du einen anderen Benutzer mit sudo-Rechten hast!"
    fi
    
    # SSH-Port ändern
    if ask_yes_no "SSH-Port ändern? (erhöht Sicherheit)"; then
        echo ""
        select_option "Wähle einen Port:" \
            "2222 (häufig verwendet)" \
            "2200" \
            "22000" \
            "Eigenen Port eingeben"
        
        port_choice=$?
        
        case $port_choice in
            0) new_port="2222" ;;
            1) new_port="2200" ;;
            2) new_port="22000" ;;
            3) new_port=$(ask_input "Port-Nummer (1024-65535)" "2222") ;;
        esac
        
        sed -i "s/^#*Port.*/Port $new_port/" /etc/ssh/sshd_config
        success "SSH-Port geändert: $new_port"
        warning "Öffne Port $new_port in der Firewall!"
        warning "Merke dir den neuen Port für die nächste Verbindung!"
        
        # Port in Firewall öffnen
        if ask_yes_no "Port $new_port jetzt in Firewall öffnen?"; then
            if command -v ufw &> /dev/null; then
                ufw allow $new_port > /dev/null 2>&1
            elif command -v firewall-cmd &> /dev/null; then
                firewall-cmd --permanent --add-port=$new_port/tcp > /dev/null 2>&1
                firewall-cmd --reload > /dev/null 2>&1
            fi
            success "Port in Firewall geöffnet"
        fi
    fi
    
    # Passwort-Auth deaktivieren (nur wenn Keys vorhanden)
    if [ -f ~/.ssh/authorized_keys ] && [ -s ~/.ssh/authorized_keys ]; then
        if ask_yes_no "Passwort-Authentifizierung deaktivieren? (nur SSH-Keys)"; then
            sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
            success "Passwort-Auth deaktiviert - nur noch SSH-Keys erlaubt"
        fi
    fi
    
    echo ""
    info "Starte SSH-Dienst neu..."
    systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
    success "SSH neu gestartet"
    
    SUMMARY+=("✓ SSH-Sicherheit verbessert")
}

# Frage 9: Automatische Updates
question_auto_updates() {
    print_header "Automatische Updates"
    
    echo "Automatische Sicherheitsupdates halten dein System geschützt."
    echo ""
    
    if ! ask_yes_no "Automatische Sicherheitsupdates aktivieren?"; then
        info "Auto-Updates nicht aktiviert"
        SUMMARY+=("⊘ Auto-Updates nicht aktiviert")
        return
    fi
    
    echo ""
    
    case $PKG_MGR in
        apt)
            info "Installiere unattended-upgrades..."
            eval $INSTALL_CMD unattended-upgrades > /dev/null 2>&1
            
            info "Konfiguriere automatische Updates..."
            echo 'APT::Periodic::Update-Package-Lists "1";' > /etc/apt/apt.conf.d/20auto-upgrades
            echo 'APT::Periodic::Unattended-Upgrade "1";' >> /etc/apt/apt.conf.d/20auto-upgrades
            
            success "Automatische Updates aktiviert!"
            SUMMARY+=("✓ Auto-Updates: unattended-upgrades")
            ;;
            
        dnf)
            info "Installiere dnf-automatic..."
            eval $INSTALL_CMD dnf-automatic > /dev/null 2>&1
            
            info "Aktiviere automatische Updates..."
            systemctl enable --now dnf-automatic.timer > /dev/null 2>&1
            
            success "Automatische Updates aktiviert!"
            SUMMARY+=("✓ Auto-Updates: dnf-automatic")
            ;;
            
        *)
            warning "Automatische Updates für $PKG_MGR nicht implementiert"
            SUMMARY+=("⊘ Auto-Updates nicht unterstützt")
            ;;
    esac
}

# Frage 10: Zusätzlicher Benutzer
question_user() {
    print_header "Benutzer erstellen"
    
    echo "Für die tägliche Arbeit solltest du einen normalen Benutzer"
    echo "statt root verwenden."
    echo ""
    
    if ! ask_yes_no "Möchtest du einen neuen Benutzer erstellen?"; then
        info "Benutzer-Erstellung übersprungen"
        SUMMARY+=("⊘ Kein neuer Benutzer")
        return
    fi
    
    echo ""
    username=$(ask_input "Benutzername" "")
    
    if [ -z "$username" ]; then
        warning "Kein Benutzername eingegeben"
        return
    fi
    
    if id "$username" &>/dev/null; then
        warning "Benutzer '$username' existiert bereits"
        return
    fi
    
    info "Erstelle Benutzer: $username"
    adduser --gecos "" "$username"
    
    echo ""
    if ask_yes_no "Benutzer $username sudo-Rechte geben?"; then
        usermod -aG sudo "$username" 2>/dev/null || usermod -aG wheel "$username" 2>/dev/null
        success "Sudo-Rechte vergeben"
    fi
    
    success "Benutzer $username erstellt!"
    SUMMARY+=("✓ Benutzer: $username erstellt")
}

# Finale Zusammenfassung
show_final_summary() {
    clear
    echo ""
    echo -e "${GREEN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║              SETUP ERFOLGREICH ABGESCHLOSSEN!             ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo ""
    
    print_box "Zusammenfassung"
    
    for item in "${SUMMARY[@]}"; do
        echo "  $item"
    done
    
    echo ""
    print_box "Systeminfo"
    
    echo "  Hostname:     $(hostname)"
    echo "  Zeitzone:     $(timedatectl | grep "Time zone" | awk '{print $3}')"
    echo "  Datum/Zeit:   $(date '+%d.%m.%Y %H:%M:%S')"
    echo "  Kernel:       $(uname -r)"
    echo "  Uptime:       $(uptime -p)"
    
    echo ""
    print_box "Wichtige Hinweise"
    
    echo "  • SSH-Config Backup: /etc/ssh/sshd_config.backup.*"
    echo "  • Bei SSH-Port-Änderung: Neue Verbindung testen BEVOR du dich abmeldest!"
    echo "  • Root-Login deaktiviert? Stelle sicher, dass du dich als anderer User einloggen kannst!"
    
    echo ""
    print_box "Nächste Schritte"
    
    echo "  1. System neu starten für alle Änderungen"
    echo "  2. SSH-Verbindung testen (bei Änderungen)"
    echo "  3. Firewall-Regeln überprüfen"
    echo "  4. Deine Anwendungen installieren"
    
    echo ""
    
    if ask_yes_no "System jetzt neu starten?"; then
        info "Neustart in 5 Sekunden... (CTRL+C zum Abbrechen)"
        sleep 5
        reboot
    else
        success "Setup abgeschlossen!"
        warning "Bitte starte das System später manuell neu: sudo reboot"
    fi
}

# System-Erkennung (läuft still im Hintergrund)
detect_system() {
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        OS_NAME="$NAME"
        OS_ID="$ID"
        
        case $OS_ID in
            ubuntu|debian|linuxmint|pop)
                PKG_MGR="apt"
                UPDATE_CMD="apt-get update -qq"
                UPGRADE_CMD="DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq"
                INSTALL_CMD="DEBIAN_FRONTEND=noninteractive apt-get install -y -qq"
                ;;
            fedora|rhel|centos|rocky|almalinux)
                PKG_MGR="dnf"
                UPDATE_CMD="dnf check-update -q || true"
                UPGRADE_CMD="dnf upgrade -y -q"
                INSTALL_CMD="dnf install -y -q"
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

# Hauptprogramm
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
    question_user
    
    show_final_summary
}

main "$@"
