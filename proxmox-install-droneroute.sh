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

pct exec $CTID -- bash -c "curl -L -o /var/www/droneroute/index.html https://raw.githubusercontent.com/yxkastarn/Droneroute/refs/heads/main/droneroute-viewer.html"

print_status "Webbapplikation skapad"

# Konfigurera Nginx
pct exec $CTID -- cat > /etc/nginx/sites-available/droneroute << 'NGINXEOF'
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

pct exec $CTID -- ln -sf /etc/nginx/sites-available/droneroute /etc/nginx/sites-enabled/
pct exec $CTID -- rm -f /etc/nginx/sites-enabled/default

pct exec $CTID -- nginx -t && systemctl restart nginx && systemctl enable nginx
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
