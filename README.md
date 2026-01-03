# Linux First Install Script

Automatisches Setup-Script für frische Linux-Installationen mit umfassenden Konfigurationsmöglichkeiten.

## 🚀 Schnellstart - Direkte Ausführung von GitHub

Du kannst das Script direkt von GitHub ausführen, ohne es manuell herunterzuladen:

### Variante 1: Mit curl
```bash
curl -sSL https://raw.githubusercontent.com/DEIN-USERNAME/DEIN-REPO/main/linux-first-install.sh | sudo bash
```

### Variante 2: Mit wget
```bash
wget -qO- https://raw.githubusercontent.com/DEIN-USERNAME/DEIN-REPO/main/linux-first-install.sh | sudo bash
```

### Variante 3: Herunterladen und ausführen
```bash
wget https://raw.githubusercontent.com/DEIN-USERNAME/DEIN-REPO/main/linux-first-install.sh
chmod +x linux-first-install.sh
sudo ./linux-first-install.sh
```

## 📋 Funktionen

- ✅ **Automatische OS-Erkennung** (Ubuntu, Debian, Fedora, CentOS, Arch, openSUSE)
- ✅ **System Update & Upgrade** mit dem richtigen Package Manager
- ✅ **Hostname-Konfiguration** mit automatischer /etc/hosts Aktualisierung
- ✅ **Timezone-Setup** mit übersichtlichem Auswahlmenü
- ✅ **Swap-Einrichtung** mit intelligenter Größenempfehlung
- ✅ **Essential Tools Installation** (curl, wget, git, vim, htop, ufw, fail2ban, etc.)
- ✅ **Firewall-Konfiguration** (UFW oder firewalld)
- ✅ **SSH-Härtung** (Root-Login deaktivieren, Port ändern, etc.)
- ✅ **Automatische Sicherheitsupdates**
- ✅ **Detaillierte Zusammenfassung** aller durchgeführten Aktionen

## 🔧 Unterstützte Betriebssysteme

- **Debian-basiert**: Ubuntu, Debian, Linux Mint, Pop!_OS
- **Red Hat-basiert**: Fedora, CentOS, RHEL, Rocky Linux, AlmaLinux
- **Arch-basiert**: Arch Linux, Manjaro
- **SUSE-basiert**: openSUSE, SLES

## 📦 GitHub Repository Setup

### 1. Repository erstellen

```bash
# Lokales Repository initialisieren
git init
git add linux-first-install.sh README.md
git commit -m "Initial commit: Linux First Install Script"

# Mit GitHub verbinden
git branch -M main
git remote add origin https://github.com/DEIN-USERNAME/DEIN-REPO.git
git push -u origin main
```

### 2. Repository auf GitHub erstellen

1. Gehe zu https://github.com/new
2. Repository-Name: z.B. `linux-first-install`
3. Beschreibung: "Automated Linux first install setup script"
4. Wähle "Public" (damit der Raw-Link funktioniert)
5. Klicke "Create repository"

### 3. Lokales Repo mit GitHub verbinden

```bash
git remote add origin https://github.com/DEIN-USERNAME/linux-first-install.git
git branch -M main
git push -u origin main
```

## 🔗 Eigenen Download-Link erstellen

Nach dem Upload auf GitHub ist dein Script verfügbar unter:

```
https://raw.githubusercontent.com/DEIN-USERNAME/DEIN-REPO/main/linux-first-install.sh
```

### Kurz-URL erstellen (optional)

Du kannst einen kurzen Link mit Services wie:
- **bit.ly**: https://bitly.com
- **tinyurl**: https://tinyurl.com
- **is.gd**: https://is.gd

Beispiel:
```bash
# Original
curl -sSL https://raw.githubusercontent.com/username/linux-first-install/main/linux-first-install.sh | sudo bash

# Mit Kurz-URL
curl -sSL https://bit.ly/linux-setup | sudo bash
```

## 💡 Verwendung

### Interaktive Ausführung
```bash
sudo ./linux-first-install.sh
```

### Direkt von GitHub
```bash
curl -sSL https://raw.githubusercontent.com/DEIN-USERNAME/DEIN-REPO/main/linux-first-install.sh | sudo bash
```

## ⚙️ Was das Script macht

1. **System-Check**: Prüft Root-Rechte und erkennt das Betriebssystem
2. **Updates**: Führt System-Update und Upgrade durch
3. **Hostname**: Ermöglicht interaktive Hostname-Änderung
4. **Timezone**: Bietet Menü zur Zeitzone-Auswahl
5. **Swap**: Erstellt optional eine Swap-Datei
6. **Tools**: Installiert wichtige Basis-Tools
7. **Firewall**: Konfiguriert UFW oder firewalld
8. **SSH**: Härtet SSH-Konfiguration
9. **Auto-Updates**: Aktiviert automatische Sicherheitsupdates
10. **Summary**: Zeigt detaillierte Zusammenfassung

## 🛡️ Sicherheitshinweise

- Das Script erfordert Root-Rechte (sudo)
- Es erstellt Backups wichtiger Konfigurationsdateien
- SSH-Konfiguration wird vor Änderungen gesichert
- Firewall-Regeln werden sicher konfiguriert

## 📝 Beispiel-Output

```
╔═══════════════════════════════════════════════╗
║   Linux First Install Setup Script            ║
║   Automatisierte Erstkonfiguration            ║
╚═══════════════════════════════════════════════╝

[INFO] Erkenne Betriebssystem...
[OK] Erkanntes System: Ubuntu 24.04 LTS
[INFO] Führe System-Update durch...
[OK] System-Update erfolgreich abgeschlossen
...
╔═══════════════════════════════════════════════╗
║           SETUP ABGESCHLOSSEN                 ║
╚═══════════════════════════════════════════════╝

Zusammenfassung der durchgeführten Aktionen:
✓ Betriebssystem: Ubuntu 24.04 LTS
✓ System wurde aktualisiert und upgraded
✓ Hostname geändert von 'localhost' zu 'webserver01'
✓ Zeitzone geändert zu 'Europe/Berlin'
✓ Swap-Datei erstellt: 4G
✓ Tools installiert: curl wget git vim nano htop...
✓ UFW Firewall aktiviert (SSH erlaubt, zusätzlich: 80,443)
✓ SSH-Sicherheit verbessert
✓ Automatische Sicherheitsupdates aktiviert
```

## 🤝 Beitragen

Verbesserungsvorschläge und Pull Requests sind willkommen!

## 📄 Lizenz

MIT License - Frei verwendbar für private und kommerzielle Zwecke

## 👤 Autor

Erstellt für schnelle und sichere Linux-Server-Setups

---

**Wichtig**: Überprüfe immer Scripts, bevor du sie mit sudo ausführst!
