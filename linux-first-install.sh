#!/bin/bash

#######################################
# Linux First Install Setup Script
# Automatische Erstkonfiguration für Linux-Systeme
#######################################

# Farben für bessere Lesbarkeit
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Array für die Zusammenfassung
declare -a SUMMARY=()

# Funktion für farbige Ausgaben
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNUNG]${NC} $1"
}

print_error() {
    echo -e "${RED}[FEHLER]${NC} $1"
}

# Banner anzeigen
show_banner() {
    clear
    echo -e "${GREEN}"
    echo "╔═══════════════════════════════════════════════╗"
    echo "║   Linux First Install Setup Script            ║"
    echo "║   Automatisierte Erstkonfiguration            ║"
    echo "╚═══════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Root-Rechte prüfen
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        print_error "Dieses Script muss als root ausgeführt werden!"
        echo "Bitte führe es mit 'sudo $0' aus"
        exit 1
    fi
}

# Betriebssystem erkennen
detect_os() {
    print_info "Erkenne Betriebssystem..."
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
        OS_NAME=$NAME
    else
        print_error "Kann Betriebssystem nicht erkennen!"
        exit 1
    fi
    
    print_success "Erkanntes System: $OS_NAME"
    SUMMARY+=("Betriebssystem: $OS_NAME")
    
    # Package Manager festlegen
    case $OS in
        ubuntu|debian|linuxmint|pop)
            PKG_MANAGER="apt"
            UPDATE_CMD="apt update"
            UPGRADE_CMD="apt upgrade -y"
            INSTALL_CMD="apt install -y"
            ;;
        fedora|rhel|centos|rocky|almalinux)
            PKG_MANAGER="dnf"
            UPDATE_CMD="dnf check-update"
            UPGRADE_CMD="dnf upgrade -y"
            INSTALL_CMD="dnf install -y"
            ;;
        arch|manjaro)
            PKG_MANAGER="pacman"
            UPDATE_CMD="pacman -Sy"
            UPGRADE_CMD="pacman -Syu --noconfirm"
            INSTALL_CMD="pacman -S --noconfirm"
            ;;
        opensuse*|sles)
            PKG_MANAGER="zypper"
            UPDATE_CMD="zypper refresh"
            UPGRADE_CMD="zypper update -y"
            INSTALL_CMD="zypper install -y"
            ;;
        *)
            print_warning "Unbekanntes System: $OS. Versuche apt als Standard..."
            PKG_MANAGER="apt"
            UPDATE_CMD="apt update"
            UPGRADE_CMD="apt upgrade -y"
            INSTALL_CMD="apt install -y"
            ;;
    esac
    
    print_info "Package Manager: $PKG_MANAGER"
    sleep 2
}

# System Update und Upgrade
system_update() {
    print_info "Führe System-Update durch..."
    
    echo ""
    print_info "Aktualisiere Paketlisten..."
    eval $UPDATE_CMD
    
    echo ""
    print_info "Führe System-Upgrade durch (dies kann einige Minuten dauern)..."
    eval $UPGRADE_CMD
    
    if [ $? -eq 0 ]; then
        print_success "System-Update erfolgreich abgeschlossen"
        SUMMARY+=("System wurde aktualisiert und upgraded")
    else
        print_error "System-Update fehlgeschlagen"
        SUMMARY+=("System-Update FEHLGESCHLAGEN")
    fi
    
    sleep 2
}

# Hostname ändern
change_hostname() {
    print_info "Aktueller Hostname: $(hostname)"
    echo ""
    read -p "Möchtest du den Hostname ändern? (j/n): " change_hn
    
    if [[ $change_hn =~ ^[Jj]$ ]]; then
        read -p "Neuer Hostname: " new_hostname
        
        if [ -n "$new_hostname" ]; then
            old_hostname=$(hostname)
            
            # Hostname setzen
            hostnamectl set-hostname "$new_hostname"
            
            # /etc/hosts aktualisieren
            sed -i "s/$old_hostname/$new_hostname/g" /etc/hosts
            
            # Falls nicht vorhanden, hinzufügen
            if ! grep -q "127.0.1.1" /etc/hosts; then
                echo "127.0.1.1    $new_hostname" >> /etc/hosts
            fi
            
            print_success "Hostname geändert: $old_hostname → $new_hostname"
            SUMMARY+=("Hostname geändert von '$old_hostname' zu '$new_hostname'")
        else
            print_warning "Kein Hostname eingegeben. Überspringe..."
            SUMMARY+=("Hostname nicht geändert")
        fi
    else
        print_info "Hostname wird nicht geändert"
        SUMMARY+=("Hostname nicht geändert")
    fi
    
    sleep 2
}

# Timezone ändern
change_timezone() {
    print_info "Aktuelle Zeitzone: $(timedatectl | grep "Time zone" | awk '{print $3}')"
    echo ""
    read -p "Möchtest du die Zeitzone ändern? (j/n): " change_tz
    
    if [[ $change_tz =~ ^[Jj]$ ]]; then
        echo ""
        print_info "Verfügbare Zeitzonen in Europa:"
        echo "1) Europe/Berlin (Deutschland)"
        echo "2) Europe/London (UK)"
        echo "3) Europe/Paris (Frankreich)"
        echo "4) Europe/Rome (Italien)"
        echo "5) Europe/Madrid (Spanien)"
        echo "6) Europe/Vienna (Österreich)"
        echo "7) Europe/Zurich (Schweiz)"
        echo "8) Europe/Amsterdam (Niederlande)"
        echo "9) Andere Zeitzone manuell eingeben"
        echo ""
        read -p "Wähle eine Option (1-9): " tz_choice
        
        case $tz_choice in
            1) timezone="Europe/Berlin" ;;
            2) timezone="Europe/London" ;;
            3) timezone="Europe/Paris" ;;
            4) timezone="Europe/Rome" ;;
            5) timezone="Europe/Madrid" ;;
            6) timezone="Europe/Vienna" ;;
            7) timezone="Europe/Zurich" ;;
            8) timezone="Europe/Amsterdam" ;;
            9) 
                read -p "Zeitzone eingeben (z.B. America/New_York): " timezone
                ;;
            *)
                print_warning "Ungültige Auswahl. Zeitzone wird nicht geändert."
                SUMMARY+=("Zeitzone nicht geändert")
                return
                ;;
        esac
        
        # Zeitzone setzen
        if timedatectl set-timezone "$timezone" 2>/dev/null; then
            print_success "Zeitzone geändert zu: $timezone"
            SUMMARY+=("Zeitzone geändert zu '$timezone'")
        else
            print_error "Fehler beim Setzen der Zeitzone"
            SUMMARY+=("Zeitzone NICHT geändert (Fehler)")
        fi
    else
        print_info "Zeitzone wird nicht geändert"
        SUMMARY+=("Zeitzone nicht geändert")
    fi
    
    sleep 2
}

# Swap-Datei erstellen (falls nicht vorhanden)
setup_swap() {
    print_info "Überprüfe Swap-Konfiguration..."
    
    if swapon --show | grep -q '/'; then
        print_info "Swap ist bereits konfiguriert"
        SUMMARY+=("Swap bereits vorhanden")
    else
        read -p "Möchtest du eine Swap-Datei erstellen? (j/n): " create_swap
        
        if [[ $create_swap =~ ^[Jj]$ ]]; then
            # RAM-Größe ermitteln
            total_ram=$(free -m | awk '/^Mem:/{print $2}')
            
            if [ $total_ram -lt 2048 ]; then
                swap_size="2G"
            elif [ $total_ram -lt 8192 ]; then
                swap_size="4G"
            else
                swap_size="8G"
            fi
            
            read -p "Swap-Größe (Standard: $swap_size): " user_swap_size
            swap_size=${user_swap_size:-$swap_size}
            
            print_info "Erstelle ${swap_size} Swap-Datei..."
            
            fallocate -l $swap_size /swapfile
            chmod 600 /swapfile
            mkswap /swapfile
            swapon /swapfile
            
            # In fstab eintragen
            if ! grep -q '/swapfile' /etc/fstab; then
                echo '/swapfile none swap sw 0 0' >> /etc/fstab
            fi
            
            print_success "Swap-Datei ($swap_size) erfolgreich erstellt"
            SUMMARY+=("Swap-Datei erstellt: $swap_size")
        else
            SUMMARY+=("Swap-Datei nicht erstellt")
        fi
    fi
    
    sleep 2
}

# Wichtige Tools installieren
install_essential_tools() {
    print_info "Installation wichtiger Tools..."
    echo ""
    
    read -p "Möchtest du wichtige Standard-Tools installieren? (j/n): " install_tools
    
    if [[ $install_tools =~ ^[Jj]$ ]]; then
        case $PKG_MANAGER in
            apt)
                TOOLS="curl wget git vim nano htop net-tools ufw fail2ban unzip"
                ;;
            dnf)
                TOOLS="curl wget git vim nano htop net-tools firewalld fail2ban unzip"
                ;;
            pacman)
                TOOLS="curl wget git vim nano htop net-tools ufw fail2ban unzip"
                ;;
            zypper)
                TOOLS="curl wget git vim nano htop net-tools firewalld fail2ban unzip"
                ;;
        esac
        
        print_info "Installiere: $TOOLS"
        eval "$INSTALL_CMD $TOOLS"
        
        if [ $? -eq 0 ]; then
            print_success "Tools erfolgreich installiert"
            SUMMARY+=("Tools installiert: $TOOLS")
        else
            print_error "Installation der Tools fehlgeschlagen"
            SUMMARY+=("Tool-Installation FEHLGESCHLAGEN")
        fi
    else
        print_info "Tool-Installation übersprungen"
        SUMMARY+=("Keine zusätzlichen Tools installiert")
    fi
    
    sleep 2
}

# Firewall konfigurieren
setup_firewall() {
    print_info "Firewall-Konfiguration..."
    echo ""
    
    read -p "Möchtest du die Firewall aktivieren? (j/n): " setup_fw
    
    if [[ $setup_fw =~ ^[Jj]$ ]]; then
        case $PKG_MANAGER in
            apt|pacman)
                if command -v ufw &> /dev/null; then
                    print_info "Konfiguriere UFW..."
                    ufw default deny incoming
                    ufw default allow outgoing
                    ufw allow ssh
                    
                    read -p "Möchtest du zusätzliche Ports öffnen? (z.B. 80,443) [Enter für keine]: " ports
                    if [ -n "$ports" ]; then
                        IFS=',' read -ra PORT_ARRAY <<< "$ports"
                        for port in "${PORT_ARRAY[@]}"; do
                            ufw allow $port
                        done
                    fi
                    
                    echo "y" | ufw enable
                    print_success "UFW Firewall aktiviert"
                    SUMMARY+=("UFW Firewall aktiviert (SSH erlaubt${ports:+, zusätzlich: $ports})")
                fi
                ;;
            dnf|zypper)
                if command -v firewall-cmd &> /dev/null; then
                    print_info "Konfiguriere firewalld..."
                    systemctl enable --now firewalld
                    firewall-cmd --permanent --add-service=ssh
                    
                    read -p "Möchtest du zusätzliche Services/Ports öffnen? (z.B. http,https) [Enter für keine]: " services
                    if [ -n "$services" ]; then
                        IFS=',' read -ra SERVICE_ARRAY <<< "$services"
                        for service in "${SERVICE_ARRAY[@]}"; do
                            firewall-cmd --permanent --add-service=$service 2>/dev/null || \
                            firewall-cmd --permanent --add-port=$service/tcp
                        done
                    fi
                    
                    firewall-cmd --reload
                    print_success "firewalld aktiviert"
                    SUMMARY+=("firewalld aktiviert (SSH erlaubt${services:+, zusätzlich: $services})")
                fi
                ;;
        esac
    else
        print_info "Firewall-Konfiguration übersprungen"
        SUMMARY+=("Firewall nicht konfiguriert")
    fi
    
    sleep 2
}

# SSH-Konfiguration härten
harden_ssh() {
    print_info "SSH-Sicherheit verbessern..."
    echo ""
    
    read -p "Möchtest du SSH-Sicherheitseinstellungen verbessern? (j/n): " harden
    
    if [[ $harden =~ ^[Jj]$ ]]; then
        SSH_CONFIG="/etc/ssh/sshd_config"
        
        # Backup erstellen
        cp $SSH_CONFIG ${SSH_CONFIG}.backup
        
        # Root-Login deaktivieren
        read -p "Root-Login via SSH deaktivieren? (empfohlen) (j/n): " disable_root
        if [[ $disable_root =~ ^[Jj]$ ]]; then
            sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' $SSH_CONFIG
            print_success "Root-Login deaktiviert"
        fi
        
        # Password-Authentication deaktivieren (nur wenn SSH-Keys existieren)
        if [ -d ~/.ssh ] && [ "$(ls -A ~/.ssh/*.pub 2>/dev/null)" ]; then
            read -p "Passwort-Authentifizierung deaktivieren? (nur mit SSH-Keys) (j/n): " disable_pw
            if [[ $disable_pw =~ ^[Jj]$ ]]; then
                sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' $SSH_CONFIG
                print_success "Passwort-Authentifizierung deaktiviert"
            fi
        fi
        
        # SSH-Port ändern
        read -p "SSH-Port ändern? (Standard: 22) (j/n): " change_port
        if [[ $change_port =~ ^[Jj]$ ]]; then
            read -p "Neuer SSH-Port: " new_port
            if [[ $new_port =~ ^[0-9]+$ ]]; then
                sed -i "s/^#*Port.*/Port $new_port/" $SSH_CONFIG
                print_success "SSH-Port geändert zu $new_port"
                print_warning "Vergiss nicht, den Port in der Firewall zu öffnen!"
            fi
        fi
        
        systemctl restart sshd
        print_success "SSH-Konfiguration aktualisiert"
        SUMMARY+=("SSH-Sicherheit verbessert (Backup: ${SSH_CONFIG}.backup)")
    else
        print_info "SSH-Härtung übersprungen"
        SUMMARY+=("SSH nicht gehärtet")
    fi
    
    sleep 2
}

# Automatische Updates konfigurieren
setup_auto_updates() {
    print_info "Automatische Updates konfigurieren..."
    echo ""
    
    read -p "Möchtest du automatische Sicherheitsupdates aktivieren? (j/n): " auto_update
    
    if [[ $auto_update =~ ^[Jj]$ ]]; then
        case $PKG_MANAGER in
            apt)
                eval "$INSTALL_CMD unattended-upgrades"
                dpkg-reconfigure -plow unattended-upgrades
                print_success "Automatische Updates aktiviert"
                SUMMARY+=("Automatische Sicherheitsupdates aktiviert (unattended-upgrades)")
                ;;
            dnf)
                eval "$INSTALL_CMD dnf-automatic"
                systemctl enable --now dnf-automatic.timer
                print_success "Automatische Updates aktiviert"
                SUMMARY+=("Automatische Updates aktiviert (dnf-automatic)")
                ;;
            *)
                print_warning "Automatische Updates für dieses System noch nicht implementiert"
                SUMMARY+=("Automatische Updates nicht unterstützt")
                ;;
        esac
    else
        print_info "Automatische Updates übersprungen"
        SUMMARY+=("Automatische Updates nicht konfiguriert")
    fi
    
    sleep 2
}

# Zusammenfassung anzeigen
show_summary() {
    clear
    echo -e "${GREEN}"
    echo "╔═══════════════════════════════════════════════╗"
    echo "║           SETUP ABGESCHLOSSEN                 ║"
    echo "╚═══════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    print_info "Zusammenfassung der durchgeführten Aktionen:"
    echo ""
    
    for i in "${!SUMMARY[@]}"; do
        echo -e "${GREEN}✓${NC} ${SUMMARY[$i]}"
    done
    
    echo ""
    print_info "Systeminfo:"
    echo "  Hostname: $(hostname)"
    echo "  Zeitzone: $(timedatectl | grep "Time zone" | awk '{print $3}')"
    echo "  Kernel: $(uname -r)"
    echo "  Uptime: $(uptime -p)"
    
    echo ""
    print_warning "Empfohlene nächste Schritte:"
    echo "  - Erstelle einen neuen Benutzer (adduser username)"
    echo "  - Konfiguriere SSH-Keys für sichere Anmeldung"
    echo "  - Überprüfe die Firewall-Regeln"
    echo "  - Installiere benötigte Anwendungen"
    
    echo ""
    read -p "Möchtest du jetzt neu starten? (j/n): " reboot_now
    if [[ $reboot_now =~ ^[Jj]$ ]]; then
        print_info "System wird neu gestartet..."
        sleep 3
        reboot
    else
        print_success "Setup abgeschlossen! Bitte starte das System später neu."
    fi
}

# Hauptprogramm
main() {
    # Argumente verarbeiten
    case "${1:-}" in
        --reset)
            reset_progress
            echo ""
            print_success "Fortschritt wurde zurückgesetzt. Führe das Script erneut aus."
            exit 0
            ;;
        --help|-h)
            echo "Linux First Install Setup Script"
            echo ""
            echo "Verwendung: $0 [OPTION]"
            echo ""
            echo "Optionen:"
            echo "  --reset    Setzt den gespeicherten Fortschritt zurück"
            echo "  --help     Zeigt diese Hilfe an"
            echo ""
            exit 0
            ;;
    esac
    
    show_banner
    check_root
    
    # Prüfe ob vorheriger Fortschritt existiert
    if load_progress; then
        echo ""
        print_warning "Es wurde ein vorheriger Setup-Fortschritt gefunden."
        read -p "Möchtest du das Setup fortsetzen? (j/n): " resume
        
        if [[ ! $resume =~ ^[JjYy]$ ]]; then
            read -p "Von vorne beginnen? (j/n): " restart
            if [[ $restart =~ ^[JjYy]$ ]]; then
                reset_progress
                print_info "Starte Setup von Anfang an..."
            else
                print_info "Setup abgebrochen."
                exit 0
            fi
        else
            print_info "Setze Setup fort..."
            # Konfiguration laden
            if [ -f "$CONFIG_FILE" ]; then
                source "$CONFIG_FILE"
            fi
        fi
    else
        echo ""
        print_info "Dieses Script führt folgende Konfigurationen durch:"
        echo "  • OS-Erkennung"
        echo "  • System-Update und Upgrade"
        echo "  • Hostname-Änderung"
        echo "  • Zeitzone-Konfiguration"
        echo "  • Swap-Einrichtung"
        echo "  • Installation wichtiger Tools"
        echo "  • Firewall-Konfiguration"
        echo "  • SSH-Härtung"
        echo "  • Automatische Updates"
        echo ""
        print_info "Das Setup kann jederzeit mit CTRL+C unterbrochen werden."
        print_info "Bei erneutem Ausführen kannst du das Setup fortsetzen."
        echo ""
        read -p "Möchtest du fortfahren? (j/n): " continue
        
        if [[ ! $continue =~ ^[JjYy]$ ]]; then
            print_info "Setup abgebrochen."
            exit 0
        fi
    fi
    
    echo ""
    detect_os
    system_update
    change_hostname
    change_timezone
    setup_swap
    install_essential_tools
    setup_firewall
    harden_ssh
    setup_auto_updates
    
    show_summary
}

# Script starten
main "$@"
