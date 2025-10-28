# Drönarkarta Viewer Pro - Snabbstart

## 🚀 Installation på Proxmox (Ett kommando!)

### Snabbast - Allt-i-ett kommando:

Logga in på din **Proxmox-host** via SSH och kör:

```bash
wget https://raw.githubusercontent.com/yxkastarn/dronechart-pro/main/proxmox-install-dronechart.sh -O /tmp/install-dronechart.sh && chmod +x /tmp/install-dronechart.sh && /tmp/install-dronechart.sh
```

### Alternativt - Steg för steg:

```bash
# Steg 1: Ladda ner installationsskriptet
wget https://raw.githubusercontent.com/yxkastarn/dronechart-pro/main/proxmox-install-dronechart.sh

# Steg 2: Gör det körbart
chmod +x proxmox-install-dronechart.sh

# Steg 3: Kör installationen
./proxmox-install-dronechart.sh
```

### Steg 2: Följ instruktionerna

Skriptet kommer att fråga dig om:
- Container ID (100-999)
- Hostname (standard: dronechart-pro)
- Root-lösenord för containern
- Storage (standard: local-lvm)
- Template (standard: Debian 12)
- RAM (standard: 1024 MB)
- CPU cores (standard: 2)
- Disk (standard: 4 GB)
- Nätverksbrygga (standard: vmbr0)
- DHCP eller statisk IP (standard: DHCP)

### Steg 3: Klart!

Efter några minuter är allt färdigt och du får:
- ✅ En komplett LXC-container
- ✅ Nginx installerat och konfigurerat
- ✅ Drönarkarta Viewer Pro installerat
- ✅ IP-adress visas för åtkomst

## 📋 Vad gör skriptet?

### På Proxmox-hosten:
1. ✅ Verifierar att det körs på Proxmox
2. ✅ Frågar efter konfiguration interaktivt
3. ✅ Laddar ner Debian 12 template (om behövs)
4. ✅ Skapar LXC-container med rätt inställningar
5. ✅ Startar containern
6. ✅ Väntar på nätverksanslutning

### I containern:
1. ✅ Uppdaterar paketsystemet
2. ✅ Installerar Nginx, Curl, Certbot
3. ✅ Skapar webbkatalog
4. ✅ Installerar Drönarkarta Viewer Pro HTML-applikation
5. ✅ Konfigurerar Nginx med stöd för stora videofiler (2GB)
6. ✅ Startar och aktiverar Nginx
7. ✅ Rapporterar tillbaka IP-adress

## 🎯 Efter installation

### Öppna webbläsaren
```
http://[CONTAINER-IP]
```

### Konfigurera SSL (rekommenderat)

```bash
# Logga in på containern
pct enter [CONTAINER-ID]

# Kör Certbot
certbot --nginx -d dronechart.dindomän.se
```

### Testa applikationen
1. Tillåt platsåtkomst när webbläsaren frågar
2. Ladda upp en DJI SRT-fil
3. Ladda upp motsvarande video
4. Klicka på "Spela upp flygning"

## 🔧 Hantera containern

### Från Proxmox-hosten:

```bash
# Starta container
pct start [CONTAINER-ID]

# Stoppa container
pct stop [CONTAINER-ID]

# Logga in i container
pct enter [CONTAINER-ID]

# Se status
pct status [CONTAINER-ID]

# Ta bort container
pct destroy [CONTAINER-ID]

# Backup
vzdump [CONTAINER-ID] --compress zstd --storage local
```

### Loggar

```bash
# Container-loggar
pct exec [CONTAINER-ID] -- journalctl -u nginx -f

# Nginx access log
pct exec [CONTAINER-ID] -- tail -f /var/log/nginx/access.log

# Nginx error log
pct exec [CONTAINER-ID] -- tail -f /var/log/nginx/error.log
```

## ⚙️ Konfigurationsexempel

### Minimal installation (512MB RAM)
```
Container ID: 100
Hostname: dronechart-pro
RAM: 512
CPU: 1
Disk: 2
```

### Rekommenderad installation (1GB RAM)
```
Container ID: 100
Hostname: dronechart-pro
RAM: 1024
CPU: 2
Disk: 4
```

### Kraftfull installation (stora videofiler)
```
Container ID: 100
Hostname: dronechart-pro
RAM: 2048
CPU: 4
Disk: 8
```

## 🌐 Nätverksinställningar

### DHCP (automatisk IP)
Enklast för de flesta installationer. Containern får automatiskt en IP från din router.

### Statisk IP
Om du vill ha en fast IP-adress:
```
IP: 192.168.1.100/24
Gateway: 192.168.1.1
```

### Portforwarding
För att nå applikationen från internet, konfigurera portforwarding i din router:
```
Extern port: 80 (eller 443 för HTTPS)
Intern IP: [CONTAINER-IP]
Intern port: 80 (eller 443)
```

## 🔒 Säkerhet

### Rekommendationer:
1. **Använd HTTPS** - Konfigurera SSL med Certbot
2. **Stark lösenord** - Välj ett säkert root-lösenord
3. **Brandvägg** - Öppna endast nödvändiga portar
4. **Uppdateringar** - Håll systemet uppdaterat
5. **Backup** - Ta regelbundna backuper

### Uppdatera systemet:
```bash
pct enter [CONTAINER-ID]
apt-get update && apt-get upgrade -y
systemctl restart nginx
```

## 🐛 Felsökning

### Container startar inte
```bash
# Kolla loggar
pct exec [CONTAINER-ID] -- journalctl -xe

# Kontrollera status
pct status [CONTAINER-ID]

# Tvångsstarta
pct start [CONTAINER-ID] --force
```

### Ingen nätverksanslutning
```bash
# Kontrollera nätverksinställningar
pct config [CONTAINER-ID] | grep net0

# Testa anslutning
pct exec [CONTAINER-ID] -- ping -c 4 8.8.8.8

# Starta om nätverket
pct exec [CONTAINER-ID] -- systemctl restart networking
```

### Webbserver svarar inte
```bash
# Kontrollera att Nginx körs
pct exec [CONTAINER-ID] -- systemctl status nginx

# Starta om Nginx
pct exec [CONTAINER-ID] -- systemctl restart nginx

# Testa Nginx-konfiguration
pct exec [CONTAINER-ID] -- nginx -t
```

### Kan inte ladda upp stora filer
Kontrollera att `client_max_body_size` är satt till 2G i Nginx-konfigurationen:
```bash
pct exec [CONTAINER-ID] -- grep client_max_body_size /etc/nginx/sites-available/dronechart
```

## 📦 Mallar och templates

### Debian 12 (rekommenderad)
- Stabil och vältestad
- Bra dokumentation
- Lång support

### Ubuntu 22.04 LTS
- Modern och uppdaterad
- Stort community
- Lång support (LTS)

### Ubuntu 24.04 LTS
- Senaste LTS-version
- Moderna paket
- Förstklassigt stöd

## 💾 Backup och återställning

### Skapa backup
```bash
# Full backup
vzdump [CONTAINER-ID] --mode snapshot --compress zstd --storage local

# Backup till extern storage
vzdump [CONTAINER-ID] --mode snapshot --storage backup-disk
```

### Återställ backup
```bash
# Lista backuper
pveam list local

# Återställ
pct restore [NY-CONTAINER-ID] /var/lib/vz/dump/vzdump-lxc-[CONTAINER-ID]-*.tar.zst --storage local-lvm
```

## 🔗 Länkar och resurser

### Officiella resurser:
- **Proxmox Documentation**: https://pve.proxmox.com/wiki/Main_Page
- **LFV Drönarkarta**: https://dronechart.lfv.se/
- **LFV API**: https://daim.lfv.se/echarts/dronechart/API/

### DJI-resurser:
- **DJI Telemetry Overlay**: https://djitelemetryoverlay.com/
- **Subtitle Extractor**: https://djitelemetryoverlay.com/subtitle-extractor/

### Verktyg:
- **Leaflet.js**: https://leafletjs.com/
- **Let's Encrypt**: https://letsencrypt.org/

## 🎓 Video tutorials

*(Lägg till länkar till video tutorials här om sådana skapas)*

## 📧 Support

### Problem eller frågor?
1. Kontrollera felsökningssektionen ovan
2. Granska container-loggar
3. Verifiera nätverksinställningar
4. Testa API-åtkomst manuellt

### Bidra
Om du hittar buggar eller har förbättringsförslag, välkommen att bidra!

## 📝 Changelog

### Version 1.0 (2025-10-28)
- 🎉 Initial release
- ✅ Automatisk LXC-skapande från Proxmox-host
- ✅ Interaktiv konfiguration
- ✅ Komplett installation med ett kommando
- ✅ DJI SRT och videouppspelning
- ✅ LFV API-integration

---

**Lycka till med din installation! 🚁**
