#!/bin/bash
#
# Droneroute Viewer - Proxmox Host Installation Script
# Detta script körs på Proxmox-hosten och skapar en komplett LXC-container
# med Droneroute Viewer installerat
#

set -e

# Färger för output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funktion för att skriva ut status
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[i]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=========================================="
    echo -e "$1"
    echo -e "==========================================${NC}"
}

# Banner
clear
echo -e "${GREEN}"
cat << "EOF"
╔═══════════════════════════════════════════════════╗
║                                                   ║
║      🚁 Droneroute Viewer Installer 🚁      ║
║                                                   ║
║      Automatisk LXC-installation för Proxmox     ║
║                                                   ║
╚═══════════════════════════════════════════════════╝
EOF
echo -e "${NC}"
echo ""


# GitHub-länkar
GITHUB_RAW_BASE="https://raw.githubusercontent.com/yxkastarn/droneroute/refs/heads/main"
GITHUB_HTML_URL="${GITHUB_RAW_BASE}/droneroute-viewer.html"

# Kontrollera att vi kör på Proxmox
if ! command -v pct &> /dev/null; then
    print_error "Detta script måste köras på en Proxmox-host"
    exit 1
fi

print_status "Proxmox-miljö detekterad"

# GitHub-länkar
GITHUB_RAW_BASE="https://raw.githubusercontent.com/yxkastarn/droneroute/refs/heads/main"
GITHUB_HTML_URL="${GITHUB_RAW_BASE}/droneroute-viewer.html"

# Konfiguration
print_header "Konfiguration"
echo ""

# Fråga efter CT ID
while true; do
    read -p "Ange Container ID (100-999): " CTID
    if [[ "$CTID" =~ ^[0-9]+$ ]] && [ "$CTID" -ge 100 ] && [ "$CTID" -le 999 ]; then
        if pct status $CTID &> /dev/null; then
            print_error "Container ID $CTID används redan"
        else
            break
        fi
    else
        print_error "Ogiltigt Container ID. Ange ett nummer mellan 100-999"
    fi
done

print_status "Container ID: $CTID"

# Fråga efter hostname
read -p "Ange hostname (standard: droneroute): " HOSTNAME
HOSTNAME=${HOSTNAME:-droneroute}
print_status "Hostname: $HOSTNAME"

# Fråga efter lösenord
while true; do
    read -s -p "Ange root-lösenord för containern: " PASSWORD
    echo ""
    read -s -p "Bekräfta lösenord: " PASSWORD2
    echo ""
    if [ "$PASSWORD" = "$PASSWORD2" ]; then
        break
    else
        print_error "Lösenorden matchar inte. Försök igen."
    fi
done

print_status "Lösenord satt"

# Storage
print_info "Tillgängliga storage:"
pvesm status | grep -E "^(local|local-lvm)" | awk '{print "  - " $1 " (" $2 ")"}'
read -p "Välj storage (standard: local-lvm): " STORAGE
STORAGE=${STORAGE:-local-lvm}
print_status "Storage: $STORAGE"

# Template - INTERAKTIV VERSION MED MANUELLT VAL
print_info "Uppdaterar template-lista..."
pveam update

echo ""
print_info "Visar tillgängliga Debian och Ubuntu templates:"
echo ""
pveam available | grep -E "debian|ubuntu" | nl -w2 -s'. '

echo ""
read -p "Välj template nummer (eller tryck Enter för att visa alla tillgängliga): " TEMPLATE_CHOICE

if [ -z "$TEMPLATE_CHOICE" ]; then
    # Visa alla templates
    echo ""
    print_info "Alla tillgängliga templates:"
    pveam available | nl -w2 -s'. '
    echo ""
    read -p "Välj template nummer: " TEMPLATE_CHOICE
fi

# Hämta valt template
SELECTED_TEMPLATE=$(pveam available | sed -n "${TEMPLATE_CHOICE}p" | awk '{print $2}')

if [ -z "$SELECTED_TEMPLATE" ]; then
    print_error "Ogiltigt val"
    exit 1
fi

print_info "Valt template: $SELECTED_TEMPLATE"

# Kontrollera om redan nedladdad
if pveam list local | grep -q "$SELECTED_TEMPLATE"; then
    print_status "Template redan nedladdad"
else
    print_info "Laddar ner template (detta kan ta några minuter)..."
    pveam download local "$SELECTED_TEMPLATE"
    
    if [ $? -eq 0 ]; then
        print_status "Template nedladdad"
    else
        print_error "Nedladdning misslyckades"
        print_info "Prova att välja en annan template"
        exit 1
    fi
fi

TEMPLATE="local:vztmpl/$SELECTED_TEMPLATE"
print_status "Template: $TEMPLATE"

# Resurser
read -p "RAM (MB) (standard: 1024): " MEMORY
MEMORY=${MEMORY:-1024}

read -p "CPU cores (standard: 2): " CORES
CORES=${CORES:-2}

read -p "Disk storlek (GB) (standard: 4): " DISK
DISK=${DISK:-4}

# Nätverk
print_info "Tillgängliga nätverksbryggor:"
ip link show | grep -E "^[0-9]+: vmbr" | awk '{print "  - " $2}' | sed 's/:$//'
read -p "Välj nätverksbrygga (standard: vmbr0): " BRIDGE
BRIDGE=${BRIDGE:-vmbr0}

read -p "Använd DHCP? (j/n, standard: j): " USE_DHCP
USE_DHCP=${USE_DHCP:-j}

if [[ $USE_DHCP =~ ^[Nn]$ ]]; then
    read -p "Ange statisk IP (format: 192.168.1.100/24): " STATIC_IP
    read -p "Ange gateway: " GATEWAY
    IP_CONFIG="ip=$STATIC_IP,gw=$GATEWAY"
else
    IP_CONFIG="ip=dhcp"
fi

# Sammanfattning
echo ""
print_header "Sammanfattning"
echo ""
echo "Container ID: $CTID"
echo "Hostname: $HOSTNAME"
echo "Template: $TEMPLATE"
echo "RAM: ${MEMORY}MB"
echo "CPU: ${CORES} cores"
echo "Disk: ${DISK}GB"
echo "Storage: $STORAGE"
echo "Nätverk: $BRIDGE ($IP_CONFIG)"
echo ""

read -p "Vill du fortsätta med installationen? (j/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[JjYy]$ ]]; then
    print_info "Installation avbruten"
    exit 0
fi

# Skapa LXC-container
echo ""
print_header "Skapar LXC-container"
echo ""

print_info "Skapar container $CTID..."

pct create $CTID $TEMPLATE \
    --hostname $HOSTNAME \
    --password "$PASSWORD" \
    --memory $MEMORY \
    --swap 512 \
    --cores $CORES \
    --net0 name=eth0,bridge=$BRIDGE,$IP_CONFIG \
    --storage $STORAGE \
    --rootfs $STORAGE:$DISK \
    --unprivileged 1 \
    --features nesting=1 \
    --onboot 1

print_status "Container skapad"

# Starta container
print_info "Startar container..."
pct start $CTID
sleep 5
print_status "Container startad"

# Vänta på att nätverket ska komma upp
print_info "Väntar på nätverksanslutning..."
for i in {1..30}; do
    if pct exec $CTID -- ping -c 1 8.8.8.8 &> /dev/null; then
        break
    fi
    sleep 2
done
print_status "Nätverksanslutning etablerad"

# Hämta IP-adress
print_info "Hämtar IP-adress..."
sleep 3
CT_IP=$(pct exec $CTID -- hostname -I | awk '{print $1}')
print_status "Container IP: $CT_IP"

# Installera applikationen i containern
echo ""
print_header "Installerar Droneroute Viewer"
echo ""

# Skapa installationsskript i containern
print_info "Förbereder installation..."

pct exec $CTID -- bash << 'CONTAINER_SCRIPT'
#!/bin/bash
set -e

# Färger
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[✓]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }
print_info() { echo -e "${YELLOW}[i]${NC} $1"; }

# Uppdatera system
print_info "Uppdaterar paketlistan..."
apt-get update -qq

# Installera nödvändiga paket
print_info "Installerar nginx, curl och certbot..."
DEBIAN_FRONTEND=noninteractive apt-get install -y nginx curl wget net-tools certbot python3-certbot-nginx > /dev/null 2>&1

print_status "Nginx installerad"

# Skapa webbkatalog
WEB_ROOT="/var/www/droneroute"
mkdir -p $WEB_ROOT

# Ladda ner HTML-fil från GitHub
print_info "Laddar ner webbapplikation från GitHub..."

if curl -f -o $WEB_ROOT/index.html https://raw.githubusercontent.com/yxkastarn/droneroute/refs/heads/main/droneroute-viewer.html 2>/dev/null; then
    print_status "Webbapplikation nedladdad från GitHub"
else
    print_info "GitHub-nedladdning misslyckades, använder inbyggd version..."
    # Fallback: Skapa HTML-filen lokalt om GitHub inte är tillgängligt
cat > $WEB_ROOT/index.html << 'HTMLEOF'
<!DOCTYPE html>
<html lang="sv">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Droneroute Viewer</title>
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: Arial, sans-serif; height: 100vh; display: flex; flex-direction: column; }
        #header { background-color: #2c3e50; color: white; padding: 15px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
        #header h1 { font-size: 24px; margin-bottom: 5px; }
        #status { font-size: 14px; color: #ecf0f1; }
        #map { flex: 1; width: 100%; }
        #controls { position: absolute; top: 80px; right: 10px; background: white; padding: 15px; border-radius: 5px; box-shadow: 0 2px 10px rgba(0,0,0,0.2); z-index: 1000; max-width: 320px; max-height: 80vh; overflow-y: auto; }
        .control-group { margin-bottom: 15px; }
        .control-group label { display: block; margin-bottom: 5px; font-weight: bold; font-size: 14px; }
        button { background-color: #3498db; color: white; border: none; padding: 10px 15px; border-radius: 5px; cursor: pointer; width: 100%; margin-bottom: 5px; }
        button:hover { background-color: #2980b9; }
        button.danger { background-color: #e74c3c; }
        .checkbox-group { display: flex; align-items: center; margin-bottom: 8px; }
        .checkbox-group input[type="checkbox"] { margin-right: 8px; }
        .file-input-wrapper { position: relative; overflow: hidden; display: inline-block; width: 100%; margin-bottom: 5px; }
        .file-input-wrapper input[type=file] { position: absolute; left: -9999px; }
        .file-input-wrapper label { display: block; padding: 10px 15px; background-color: #27ae60; color: white; text-align: center; border-radius: 5px; cursor: pointer; font-weight: normal; }
        .file-name { font-size: 11px; color: #7f8c8d; margin-top: 3px; word-break: break-all; }
        #videoPlayer { position: absolute; bottom: 10px; right: 10px; width: 400px; background: white; border-radius: 5px; box-shadow: 0 2px 10px rgba(0,0,0,0.3); z-index: 1000; display: none; }
        #videoPlayer video { width: 100%; border-radius: 5px 5px 0 0; }
        .flight-stats { background: #ecf0f1; padding: 10px; border-radius: 5px; margin-bottom: 10px; font-size: 12px; }
        .separator { border-top: 1px solid #ecf0f1; margin: 15px 0; }
        .loading { display: inline-block; width: 12px; height: 12px; border: 2px solid #f3f3f3; border-top: 2px solid #3498db; border-radius: 50%; animation: spin 1s linear infinite; margin-left: 5px; }
        @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
    </style>
</head>
<body>
    <div id="header">
        <h1>🚁 Droneroute Viewer</h1>
        <div id="status">Initierar...</div>
    </div>
    <div id="map"></div>
    <div id="controls">
        <div class="control-group">
            <button id="locateBtn">📍 Hitta min position</button>
            <button id="refreshBtn">🔄 Uppdatera data</button>
        </div>
        <div class="separator"></div>
        <div class="control-group">
            <label>📂 DJI Flygrutt (.SRT):</label>
            <div class="file-input-wrapper">
                <input type="file" id="srtFile" accept=".srt,.txt">
                <label for="srtFile">Välj SRT-fil</label>
            </div>
            <div class="file-name" id="srtFileName"></div>
        </div>
        <div class="control-group">
            <label>🎥 DJI Video (.MP4):</label>
            <div class="file-input-wrapper">
                <input type="file" id="videoFile" accept="video/mp4,video/mov">
                <label for="videoFile">Välj videofil</label>
            </div>
            <div class="file-name" id="videoFileName"></div>
        </div>
        <div class="control-group" id="flightStatsContainer" style="display: none;">
            <div class="flight-stats" id="flightStats"></div>
            <button id="playFlightBtn">▶️ Spela upp flygning</button>
            <button id="clearFlightBtn" class="danger">🗑️ Rensa flygning</button>
        </div>
        <div class="separator"></div>
        <div class="control-group">
            <label>Kartlager (LFV):</label>
            <div class="checkbox-group"><input type="checkbox" id="layer-ctr" checked><label for="layer-ctr">CTR</label></div>
            <div class="checkbox-group"><input type="checkbox" id="layer-tiz" checked><label for="layer-tiz">TIZ</label></div>
            <div class="checkbox-group"><input type="checkbox" id="layer-atz" checked><label for="layer-atz">ATZ</label></div>
            <div class="checkbox-group"><input type="checkbox" id="layer-rsta" checked><label for="layer-rsta">Restriktioner</label></div>
            <div class="checkbox-group"><input type="checkbox" id="layer-danger" checked><label for="layer-danger">Farliga områden</label></div>
        </div>
    </div>
    <div id="videoPlayer">
        <video id="droneVideo" controls></video>
        <div id="videoControls" style="padding: 10px; background: #34495e;">
            <button id="syncPlayBtn">▶️ Synkad uppspelning</button>
            <button id="stopPlayBtn">⏹️ Stopp</button>
            <input type="range" id="timeline" min="0" max="100" value="0" step="0.1" style="width: 100%; margin-top: 10px;">
            <button id="closeVideoBtn" class="danger">✕ Stäng video</button>
        </div>
    </div>
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
    <script>
        const map = L.map('map').setView([59.3293, 18.0686], 6);
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {attribution: '© OpenStreetMap', maxZoom: 19}).addTo(map);
        let userMarker, userCircle, flightPath, flightMarker, flightData, videoElement = document.getElementById('droneVideo');
        let isPlayingFlight = false, playbackInterval = null;
        const layers = {
            ctr: L.layerGroup().addTo(map), tiz: L.layerGroup().addTo(map), atz: L.layerGroup().addTo(map),
            rsta: L.layerGroup().addTo(map), danger: L.layerGroup().addTo(map)
        };
        const layerStyles = {
            ctr: {color: '#e74c3c', fillOpacity: 0.2}, tiz: {color: '#f39c12', fillOpacity: 0.2},
            atz: {color: '#9b59b6', fillOpacity: 0.2}, rsta: {color: '#c0392b', fillOpacity: 0.3},
            danger: {color: '#e67e22', fillOpacity: 0.25}
        };
        function parseSRT(content) {
            const entries = [], blocks = content.trim().split('\n\n');
            for (const block of blocks) {
                const lines = block.split('\n');
                if (lines.length < 3) continue;
                const timeMatch = lines[1].match(/(\d{2}):(\d{2}):(\d{2}),(\d{3})/);
                if (!timeMatch) continue;
                const timestamp = parseInt(timeMatch[1])*3600 + parseInt(timeMatch[2])*60 + parseInt(timeMatch[3]) + parseInt(timeMatch[4])/1000;
                const entry = {timestamp};
                for (const line of lines.slice(2)) {
                    if (line.match(/lat/i)) { const m = line.match(/([-+]?\d+\.\d+)/); if(m) entry.lat = parseFloat(m[1]); }
                    if (line.match(/lon/i)) { const m = line.match(/([-+]?\d+\.\d+)/); if(m) entry.lng = parseFloat(m[1]); }
                    if (line.match(/alt/i)) { const m = line.match(/(\d+\.?\d*)/); if(m) entry.altitude = parseFloat(m[1]); }
                    if (line.match(/speed/i)) { const m = line.match(/(\d+\.?\d*)/); if(m) entry.speed = parseFloat(m[1]); }
                }
                if (entry.lat && entry.lng) entries.push(entry);
            }
            return entries;
        }
        document.getElementById('srtFile').addEventListener('change', async (e) => {
            const file = e.target.files[0];
            if (!file) return;
            document.getElementById('srtFileName').textContent = file.name;
            const content = await file.text();
            flightData = parseSRT(content);
            if (flightData.length === 0) return alert('Ingen GPS-data hittades');
            if (flightPath) map.removeLayer(flightPath);
            const coords = flightData.map(e => [e.lat, e.lng]);
            flightPath = L.polyline(coords, {color: '#2ecc71', weight: 3}).addTo(map);
            L.marker(coords[0]).addTo(map).bindPopup('Start');
            L.marker(coords[coords.length-1]).addTo(map).bindPopup('Slut');
            map.fitBounds(flightPath.getBounds());
            const duration = flightData[flightData.length-1].timestamp - flightData[0].timestamp;
            const maxAlt = Math.max(...flightData.map(e => e.altitude||0));
            document.getElementById('flightStats').innerHTML = `<div><strong>Varaktighet:</strong> ${Math.floor(duration/60)}m ${Math.floor(duration%60)}s</div><div><strong>Punkter:</strong> ${flightData.length}</div><div><strong>Max höjd:</strong> ${maxAlt.toFixed(1)}m</div>`;
            document.getElementById('flightStatsContainer').style.display = 'block';
        });
        document.getElementById('videoFile').addEventListener('change', (e) => {
            const file = e.target.files[0];
            if (!file) return;
            document.getElementById('videoFileName').textContent = file.name;
            videoElement.src = URL.createObjectURL(file);
            document.getElementById('videoPlayer').style.display = 'block';
        });
        document.getElementById('locateBtn').addEventListener('click', () => {
            if (!navigator.geolocation) return;
            navigator.geolocation.getCurrentPosition((pos) => {
                const lat = pos.coords.latitude, lng = pos.coords.longitude;
                if (userMarker) map.removeLayer(userMarker);
                userMarker = L.marker([lat, lng]).addTo(map).bindPopup(`Din position<br>${lat.toFixed(6)}, ${lng.toFixed(6)}`).openPopup();
                map.setView([lat, lng], 12);
            });
        });
        async function loadAllData() {
            const WFS = 'https://daim.lfv.se/geoserver/wfs';
            const types = [
                {t: 'mais:CTR', l: 'ctr'}, {t: 'mais:TIZ', l: 'tiz'}, {t: 'mais:ATZ', l: 'atz'},
                {t: 'mais:RSTA', l: 'rsta', f: "LOWER='GND' OR LOWER='SFC'"}, {t: 'mais:DANGER', l: 'danger'}
            ];
            for (const {t, l, f} of types) {
                const params = new URLSearchParams({service: 'WFS', version: '2.0.0', request: 'GetFeature', typename: t, outputFormat: 'application/json', srsname: 'EPSG:4326'});
                if (f) params.append('CQL_FILTER', f);
                try {
                    const res = await fetch(`${WFS}?${params}`);
                    const data = await res.json();
                    if (data.features) {
                        layers[l].clearLayers();
                        L.geoJSON(data, {style: layerStyles[l]}).addTo(layers[l]);
                    }
                } catch(e) { console.error(e); }
            }
        }
        document.getElementById('refreshBtn').addEventListener('click', loadAllData);
        document.querySelectorAll('[id^="layer-"]').forEach(cb => {
            cb.addEventListener('change', (e) => {
                const l = e.target.id.replace('layer-', '');
                e.target.checked ? layers[l].addTo(map) : map.removeLayer(layers[l]);
            });
        });
        loadAllData();
        setTimeout(() => document.getElementById('locateBtn').click(), 500);
    </script>
</body>
</html>
HTMLEOF

print_status "Webbapplikation skapad"

# Konfigurera Nginx
cat > /etc/nginx/sites-available/droneroute << 'NGINXEOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    root /var/www/droneroute;
    index index.html;
    server_name _;
    client_max_body_size 2G;
    location / { try_files $uri $uri/ =404; }
    gzip on;
    gzip_types text/plain text/css text/javascript application/javascript application/json;
}
NGINXEOF

ln -sf /etc/nginx/sites-available/droneroute /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

nginx -t && systemctl restart nginx && systemctl enable nginx
print_status "Nginx konfigurerad och startad"

echo "INSTALLATION_COMPLETE"
CONTAINER_SCRIPT

if pct exec $CTID -- bash -c 'exit 0' 2>/dev/null; then
    print_status "Installation i containern slutförd"
else
    print_error "Installation misslyckades"
    exit 1
fi

# Slutresultat
echo ""
print_header "Installation slutförd!"
echo ""
echo -e "${GREEN}✅ Container skapad: ${CTID}${NC}"
echo -e "${GREEN}✅ Hostname: ${HOSTNAME}${NC}"
echo -e "${GREEN}✅ IP-adress: ${CT_IP}${NC}"
echo ""
echo -e "${BLUE}Åtkomst till applikationen:${NC}"
echo -e "   ${GREEN}http://${CT_IP}${NC}"
echo ""
echo -e "${YELLOW}Nästa steg:${NC}"
echo ""
echo "1. SSL-konfiguration (valfritt men rekommenderat):"
echo "   pct enter $CTID"
echo "   certbot --nginx -d dittdomän.se"
echo ""
echo "2. Öppna webbläsaren och navigera till: http://${CT_IP}"
echo ""
echo "3. Ladda upp DJI SRT-filer och videor för att visualisera flygningar!"
echo ""
echo -e "${BLUE}Hantera containern:${NC}"
echo "   Starta:  pct start $CTID"
echo "   Stoppa:  pct stop $CTID"
echo "   Logga in: pct enter $CTID"
echo "   Ta bort: pct destroy $CTID"
echo ""
print_status "Tack för att du använder Droneroute Viewer!"
echo ""
