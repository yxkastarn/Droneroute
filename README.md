# Drönarkarta Viewer Pro - Komplett Guide

## 🚁 Översikt
En kraftfull webbapplikation för visualisering av drönarflygningar med integration mot LFV:s Drönarkarta-API. Utvecklad för att köra i Proxmox LXC-containrar.

## ⚡ Snabbstart - Ett kommando!

**Kör detta på din Proxmox-host:**

```bash
wget https://raw.githubusercontent.com/yxkastarn/dronechart-pro/main/proxmox-install-dronechart.sh -O /tmp/install-dronechart.sh && chmod +x /tmp/install-dronechart.sh && /tmp/install-dronechart.sh
```

Det är allt! Skriptet skapar automatiskt en komplett LXC-container med Drönarkarta Viewer Pro installerat.

### Alternativt (steg för steg):

```bash
# Steg 1: Ladda ner installationsskriptet
wget https://raw.githubusercontent.com/yxkastarn/dronechart-pro/main/proxmox-install-dronechart.sh

# Steg 2: Gör det körbart
chmod +x proxmox-install-dronechart.sh

# Steg 3: Kör installationen
./proxmox-install-dronechart.sh
```

Följ sedan instruktionerna på skärmen för att konfigurera din container!

## ✨ Funktioner

### Grundfunktioner
- ✅ **GPS-positionering**: Visa användarens position i realtid
- ✅ **LFV Drönarkarta**: Hämta automatiskt alla restriktionsområden från LFV:s API
  - CTR (Kontrollzoner)
  - TIZ (Trafikinformationszoner)
  - ATZ (Flygplatstrafikzoner)
  - Restriktionsområden
  - Farliga områden
- ✅ **Interaktiv karta**: OpenStreetMap-baserad kartvy
- ✅ **Responsiv design**: Fungerar på desktop och mobil

### DJI-integration (PRO-funktioner)
- 🎯 **SRT-filstöd**: Ladda upp DJI:s SRT-telemetrifiler
- 📊 **Flygstatistik**: Visa detaljerad information om flygningen
  - Totalt avstånd
  - Maximal höjd
  - Maximal hastighet
  - Flygningens varaktighet
- 🎬 **Videouppspelning**: Ladda upp och synkronisera DJI-video med flygdata
- ▶️ **Animerad uppspelning**: Se flygningen återuppspelas på kartan i realtid
- 🔄 **Perfekt synkronisering**: Video och kartposition synkroniseras automatiskt
- 📍 **Flygvägsvisualisering**: Se hela flygrutten på kartan med start- och slutmarkörer

## 📋 Systemkrav

### Minimum
- **CPU**: 1 core
- **RAM**: 512 MB
- **Disk**: 2 GB
- **Nätverk**: Internetanslutning

### Rekommenderat
- **CPU**: 2 cores
- **RAM**: 1 GB
- **Disk**: 4 GB (mer om du ska ladda upp stora videofiler)
- **Nätverk**: Stabil internetanslutning med god bandbredd

## 🚀 Installation

### Metod 1: Snabbinstallation (Rekommenderad)

1. **Skapa LXC-container i Proxmox Web UI**
   - CT ID: Valfritt (t.ex. 100)
   - Template: Debian 12 eller Ubuntu 22.04
   - Disk: 4 GB
   - RAM: 1024 MB
   - CPU: 2 cores
   - Nätverk: DHCP eller statisk IP

2. **Logga in på containern**
   ```bash
   pct enter 100
   ```

3. **Ladda upp båda filerna till containern**
   ```bash
   # Från Proxmox-hosten eller via SCP
   scp dronechart-viewer-pro.html root@CONTAINER_IP:/root/
   scp install-dronechart-pro.sh root@CONTAINER_IP:/root/
   ```

4. **Kör installationsskriptet**
   ```bash
   cd /root
   chmod +x install-dronechart-pro.sh
   ./install-dronechart-pro.sh
   ```

5. **Följ instruktionerna** för SSL-konfiguration (valfritt men rekommenderat)

### Metod 2: Manuell installation via Proxmox CLI

```bash
# Skapa container
pct create 100 local:vztmpl/debian-12-standard_12.2-1_amd64.tar.zst \
  --hostname dronechart-pro \
  --memory 1024 \
  --swap 512 \
  --cores 2 \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp \
  --storage local-lvm \
  --rootfs local-lvm:4 \
  --unprivileged 1 \
  --features nesting=1 \
  --start 1

# Logga in och kör installation
pct enter 100
# Följ sedan steg 3-5 från Metod 1
```

## 📂 DJI SRT-filer

### Hur man aktiverar SRT-filer på DJI-drönare

1. Öppna **DJI Go 4 App** eller **DJI Fly App**
2. Gå till **Kamerainställningar**
3. Välj **Video Caption** eller **Videoundertext**
4. Aktivera funktionen (ON)
5. Sätt videoformat till **MP4**

Nu kommer en .SRT-fil att skapas för varje video du spelar in!

### SRT-filformat

SRT-filer innehåller telemetridata som:
- GPS-koordinater (latitud/longitud)
- Höjd (altitude)
- Hastighet (speed)
- Avstånd från hemposition
- Kompassriktning (heading)
- Tidsstämpel

### Exempel på SRT-filinnehåll

```
100
00:01:50,000 --> 00:01:51,000
Time 2025-10-28 12:48:43
Latitude 59.3293
Longitude 18.0686
Hdg 101
Altitude 45 m
Speed 15 km/h
Distance From Home 458 m
```

### Filextraktion från video

Om din drönare inte skapar separata SRT-filer kan du extrahera dem från MP4-filen:

**Online-verktyg:**
- https://djitelemetryoverlay.com/subtitle-extractor/

**Lokalt (med FFmpeg):**
```bash
ffmpeg -i DJI_0001.MP4 -map 0:s:0 DJI_0001.srt
```

## 🎥 Videouppspelning

### Stödda format
- **MP4** (rekommenderat)
- **MOV**

### Synkronisering
Applikationen synkroniserar automatiskt:
1. Videons tidslinje
2. Drönarens position på kartan
3. Telemetridata (höjd, hastighet, etc.)

### Användning
1. Ladda upp SRT-fil först
2. Ladda upp motsvarande videofil
3. Klicka på "▶️ Synkad uppspelning"
4. Se flygningen återuppspelas på kartan medan videon spelas

## 🔒 HTTPS/SSL-konfiguration

### Varför behövs HTTPS?
Moderna webbläsare kräver HTTPS för att använda geolocation-API:et över internet (fungerar utan på localhost).

### Automatisk konfiguration
Installationsskriptet frågar om du vill konfigurera SSL och guidar dig genom processen.

### Krav för SSL
- Domännamn som pekar till serverns IP
- Port 80 och 443 öppna från internet
- Giltig e-postadress för Let's Encrypt-notifikationer

### Manuell SSL-konfiguration

```bash
# Installera Certbot
apt-get install -y certbot python3-certbot-nginx

# Uppdatera domännamn i Nginx-konfiguration
nano /etc/nginx/sites-available/dronechart
# Ändra "server_name _;" till "server_name dronechart.dindomän.se;"

# Få SSL-certifikat
certbot --nginx -d dronechart.dindomän.se

# Testa automatisk förnyelse
certbot renew --dry-run
```

## 🛠️ Användning

### Grundläggande användning

1. **Öppna webbläsaren** och navigera till containerns IP eller domännamn
2. **Tillåt platsåtkomst** när webbläsaren frågar
3. **Din position** visas automatiskt på kartan
4. **LFV-data** laddas automatiskt från API:et

### Ladda upp flygning

1. **Klicka på "Välj SRT-fil"** och välj din DJI SRT-fil
2. **Flygvägen** visas omedelbart på kartan
3. **Statistik** visas i kontrollpanelen
4. **(Valfritt)** Ladda upp motsvarande videofil

### Spela upp flygning

1. **Klicka på "▶️ Spela upp flygning"** eller "▶️ Synkad uppspelning"
2. **Se drönaren** röra sig längs flygvägen
3. **Videon** spelas synkroniserat (om uppladdad)
4. **Statistik** uppdateras i realtid
5. **Använd timeline** för att hoppa till specifika tidpunkter

### Visa/dölja kartlager

Klicka på checkboxarna för att visa eller dölja:
- CTR (Kontrollzoner)
- TIZ (Trafikinformationszoner)
- ATZ (Flygplatstrafikzoner)
- Restriktionsområden
- Farliga områden

## 📊 API-endpoints

Applikationen använder LFV:s WFS API:

- **Base URL**: `https://daim.lfv.se/geoserver/wfs`
- **Format**: GeoJSON (EPSG:4326)
- **Lager**:
  - `mais:CTR` - Kontrollzoner
  - `mais:TIZ` - Trafikinformationszoner
  - `mais:ATZ` - Flygplatstrafikzoner
  - `mais:RSTA` - Restriktionsområden
  - `mais:DANGER` - Farliga områden

### Exempel API-anrop

```
https://daim.lfv.se/geoserver/wfs?service=WFS&version=2.0.0&request=GetFeature&typename=mais:CTR&outputFormat=application/json&srsname=EPSG:4326
```

## 🐛 Felsökning

### Problem: Kan inte nå webbservern

```bash
# Kontrollera att Nginx körs
systemctl status nginx

# Kontrollera firewall
iptables -L -n | grep 80

# Visa Nginx-loggar
tail -f /var/log/nginx/error.log
```

### Problem: Geolocation fungerar inte

- **Lösning 1**: Använd HTTPS (konfigurera SSL)
- **Lösning 2**: Åtkomst via localhost/127.0.0.1 (fungerar utan HTTPS)
- **Kontrollera**: Webbläsarens inställningar för platsåtkomst

### Problem: SRT-filen laddas inte

- **Kontrollera format**: Filen ska vara text-baserad
- **Prova umbenenämning**: Byt .txt till .srt eller vice versa
- **Öppna i textredigerare**: Verifiera att data finns
- **Kontrollera console**: Öppna webbläsarens Developer Tools (F12) och se efter felmeddelanden

### Problem: Video synkar inte

- **Kontrollera format**: Endast MP4 och MOV stöds
- **Filstorlek**: För stora filer kan ta tid att ladda
- **Tidsstämplar**: SRT-fil och video måste vara från samma flygning
- **Webbläsare**: Prova en annan webbläsare (Chrome/Firefox rekommenderas)

### Problem: API-data laddas inte

```bash
# Testa API-anrop från containern
curl "https://daim.lfv.se/geoserver/wfs?service=WFS&version=2.0.0&request=GetCapabilities"

# Kontrollera internetanslutning
ping -c 4 daim.lfv.se
```

## 🔧 Underhåll

### Uppdatera systemet

```bash
pct enter 100
apt-get update && apt-get upgrade -y
systemctl restart nginx
```

### Backup

```bash
# Från Proxmox-hosten
vzdump 100 --mode snapshot --compress zstd --storage local
```

### Kontrollera diskutrymme

```bash
df -h
# Om disk är full, rensa gamla videor eller öka diskstorlek
```

### Loggar

```bash
# Nginx access log
tail -f /var/log/nginx/access.log

# Nginx error log
tail -f /var/log/nginx/error.log

# System log
journalctl -u nginx -f
```

## 🔐 Säkerhet

### Rekommendationer

1. **Använd HTTPS**: Alltid vid produktion
2. **Brandvägg**: Öppna endast nödvändiga portar
3. **Uppdateringar**: Håll systemet uppdaterat
4. **Backup**: Ta regelbundna backuper
5. **Åtkomst**: Begränsa SSH-åtkomst om möjligt

### Öppna portar

- **Port 80**: HTTP (kan stängas om endast HTTPS används)
- **Port 443**: HTTPS (rekommenderat)

## 📚 Resurser

### LFV Drönarkarta
- **Produktspecifikation**: https://daim.lfv.se/echarts/dronechart/API/
- **Webbkarta**: https://dronechart.lfv.se/
- **Licens**: CC BY-NC-ND 4.0

### Transportstyrelsen
- **Drönarregler**: https://www.transportstyrelsen.se/sv/luftfart/Dronare/
- **Operatörs-ID**: Krävs för drönare >250g

### DJI Telemetri
- **SRT Viewer**: https://djitelemetryoverlay.com/srt-viewer/
- **Subtitle Extractor**: https://djitelemetryoverlay.com/subtitle-extractor/

### Teknisk dokumentation
- **Leaflet.js**: https://leafletjs.com/reference.html
- **Nginx**: https://nginx.org/en/docs/
- **Let's Encrypt**: https://letsencrypt.org/docs/

## 💡 Tips och tricks

### Förbättra prestanda

1. **Öka RAM**: För stora videofiler, öka till 2GB RAM
2. **CPU-cores**: Använd 2+ cores för bättre videouppspelning
3. **Nätverk**: Använd kabelanslutning för containern när möjligt

### Exportera flygdata

SRT-filer kan konverteras till andra format:
- **GPX**: För GPS-enheter
- **KML**: För Google Earth
- **CSV**: För Excel/analys

Använd online-verktyg eller `srt2gpx`-konverterare.

### Kombinera flera flygningar

Om du har flera SRT-filer från samma session kan du slå ihop dem manuellt eller med verktyg som Subtitle Edit.

## 🤝 Support

### Problem eller frågor?

1. **Kontrollera felsökningssektionen** ovan
2. **Granska loggar** för felmeddelanden
3. **Testa API:et** manuellt med curl
4. **Verifiera filformat** för SRT och video

### Kända begränsningar

- SRT-filer från vissa äldre DJI-modeller kan ha lägre precision
- Mycket stora videofiler (>2GB) kan ta lång tid att ladda
- Geolocation kräver HTTPS för fjärråtkomst
- Vissa webbläsare kan ha begränsningar för videoformat

## 📄 Licens

- **Applikation**: Öppen källkod
- **LFV-data**: CC BY-NC-ND 4.0
- **OpenStreetMap**: ODbL

## 🎉 Ändringslogg

### Version Pro (2025-10-28)
- ✨ Nytt: DJI SRT-filstöd
- ✨ Nytt: Videouppladdning och uppspelning
- ✨ Nytt: Synkroniserad kart- och videouppspelning
- ✨ Nytt: Flygstatistik och analys
- ✨ Nytt: Timeline-kontroll
- ✨ Förbättrad: UI med separatorer och tydligare layout
- ✨ Förbättrad: Stöd för stora videofiler (upp till 2GB)

### Version 1.0 (2025-10-28)
- 🎉 Initial release
- ✅ GPS-positionering
- ✅ LFV API-integration
- ✅ Interaktiv karta
- ✅ SSL-stöd med Let's Encrypt
