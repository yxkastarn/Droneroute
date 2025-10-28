#!/bin/bash
# test
# Installation script för Drönarkarta Viewer Pro i Proxmox LXC
# Detta script installerar en webbserver och konfigurerar applikationen
# med stöd för DJI SRT-filer och videouppspelning
#

set -e

echo "=========================================="
echo "Drönarkarta Viewer Pro - Installation"
echo "=========================================="
echo ""

# Färger för output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Kontrollera om vi kör som root
if [ "$EUID" -ne 0 ]; then 
    print_error "Detta script måste köras som root"
    exit 1
fi

print_info "Uppdaterar paketlistan..."
apt-get update -qq

print_status "Paketlista uppdaterad"

# Installera nödvändiga paket
print_info "Installerar nginx och certbot..."
apt-get install -y nginx curl wget net-tools > /dev/null 2>&1

print_status "Nginx installerad"

# Skapa katalog för webbapplikationen
WEB_ROOT="/var/www/dronechart"
mkdir -p $WEB_ROOT

print_status "Webbkatalog skapad: $WEB_ROOT"

# Ladda ner HTML-filen om den finns i samma katalog, annars skapa den
if [ -f "dronechart-viewer-pro.html" ]; then
    print_info "Kopierar HTML-fil från lokal katalog..."
    cp dronechart-viewer-pro.html $WEB_ROOT/index.html
else
    print_info "Laddar ner HTML-fil..."
    # Skapa en URL-säker version av filen (du kan ersätta detta med en faktisk URL om filen ligger online)
    curl -o $WEB_ROOT/index.html https://raw.githubusercontent.com/yourusername/dronechart/main/index.html 2>/dev/null || {
        print_info "Skapar HTML-fil lokalt..."
        cat > $WEB_ROOT/index.html << 'EOF'
        # HTML-innehållet finns i dronechart-viewer-pro.html
EOF
    }
fi

print_status "HTML-fil installerad"

# Konfigurera Nginx
cat > /etc/nginx/sites-available/dronechart << 'NGINXEOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/dronechart;
    index index.html;

    server_name _;

    # Öka maximala uppladdningsstorleken för videofiler
    client_max_body_size 2G;

    location / {
        try_files $uri $uri/ =404;
    }

    # CORS headers för API-anrop
    location ~* \.(html|js|css)$ {
        add_header Access-Control-Allow-Origin *;
        add_header Access-Control-Allow-Methods "GET, POST, OPTIONS";
        add_header Access-Control-Allow-Headers "Origin, Content-Type, Accept";
    }

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/javascript application/json;
}
NGINXEOF

# Aktivera site
ln -sf /etc/nginx/sites-available/dronechart /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

print_status "Nginx konfigurerad"

# Testa Nginx-konfiguration
nginx -t > /dev/null 2>&1
if [ $? -eq 0 ]; then
    print_status "Nginx-konfiguration OK"
else
    print_error "Nginx-konfiguration misslyckades"
    exit 1
fi

# Starta om Nginx
systemctl restart nginx
systemctl enable nginx > /dev/null 2>&1

print_status "Nginx startat och aktiverat"

# Hämta IP-adress
IP_ADDR=$(hostname -I | awk '{print $1}')

echo ""
echo "=========================================="
echo -e "${GREEN}Grundläggande installation klar!${NC}"
echo "=========================================="
echo ""
echo "Applikationen är nu tillgänglig på:"
echo -e "${GREEN}http://$IP_ADDR${NC}"
echo ""

# Fråga om SSL-certifikat
echo ""
echo "=========================================="
echo "SSL/HTTPS Konfiguration"
echo "=========================================="
echo ""
print_info "Vill du konfigurera HTTPS med Let's Encrypt SSL?"
print_info "Detta krävs för att geolocation ska fungera över internet."
echo ""
echo "Krav för SSL:"
echo "  - Ett domännamn som pekar till denna servers IP ($IP_ADDR)"
echo "  - Port 80 och 443 måste vara tillgängliga från internet"
echo ""

read -p "Vill du konfigurera SSL nu? (j/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[JjYy]$ ]]; then
    # Fråga efter domännamn
    echo ""
    read -p "Ange ditt domännamn (t.ex. dronechart.example.com): " DOMAIN_NAME
    
    if [ -z "$DOMAIN_NAME" ]; then
        print_error "Inget domännamn angivet. Hoppar över SSL-konfiguration."
    else
        print_info "Konfigurerar SSL för domän: $DOMAIN_NAME"
        
        # Installera certbot
        print_info "Installerar Certbot..."
        apt-get install -y certbot python3-certbot-nginx > /dev/null 2>&1
        
        if [ $? -eq 0 ]; then
            print_status "Certbot installerat"
            
            # Uppdatera Nginx-konfiguration med domännamn
            print_info "Uppdaterar Nginx-konfiguration med domännamn..."
            sed -i "s/server_name _;/server_name $DOMAIN_NAME;/" /etc/nginx/sites-available/dronechart
            
            # Testa Nginx-konfiguration
            nginx -t > /dev/null 2>&1
            if [ $? -eq 0 ]; then
                systemctl reload nginx
                print_status "Nginx-konfiguration uppdaterad"
                
                # Fråga om email för Let's Encrypt
                echo ""
                read -p "Ange din e-postadress för Let's Encrypt-notifikationer: " EMAIL_ADDR
                
                if [ -z "$EMAIL_ADDR" ]; then
                    print_error "Ingen e-postadress angiven. Hoppar över SSL-certifikat."
                else
                    # Få SSL-certifikat
                    print_info "Begär SSL-certifikat från Let's Encrypt..."
                    echo ""
                    print_info "Detta kan ta en minut..."
                    
                    certbot --nginx -d "$DOMAIN_NAME" --non-interactive --agree-tos --email "$EMAIL_ADDR" --redirect
                    
                    if [ $? -eq 0 ]; then
                        print_status "SSL-certifikat installerat!"
                        
                        # Konfigurera automatisk förnyelse
                        systemctl enable certbot.timer > /dev/null 2>&1
                        print_status "Automatisk certifikatförnyelse konfigurerad"
                        
                        echo ""
                        echo "=========================================="
                        echo -e "${GREEN}SSL-konfiguration klar!${NC}"
                        echo "=========================================="
                        echo ""
                        echo "Applikationen är nu tillgänglig på:"
                        echo -e "${GREEN}https://$DOMAIN_NAME${NC}"
                        echo ""
                        echo "HTTP-trafik omdirigeras automatiskt till HTTPS"
                        echo "Certifikatet förnyas automatiskt var 60:e dag"
                        echo ""
                    else
                        print_error "Kunde inte få SSL-certifikat från Let's Encrypt"
                        print_info "Kontrollera att:"
                        print_info "  - Domännamnet $DOMAIN_NAME pekar till IP $IP_ADDR"
                        print_info "  - Port 80 och 443 är öppna i brandväggen"
                        print_info "  - Domänen är nåbar från internet"
                        echo ""
                        print_info "Du kan köra certbot manuellt senare med:"
                        echo "  certbot --nginx -d $DOMAIN_NAME"
                    fi
                fi
            else
                print_error "Nginx-konfiguration misslyckades efter domännamnsändring"
            fi
        else
            print_error "Kunde inte installera Certbot"
        fi
    fi
else
    print_info "Hoppar över SSL-konfiguration"
    echo ""
    print_info "Du kan konfigurera SSL senare genom att köra:"
    echo "  apt-get install -y certbot python3-certbot-nginx"
    echo "  certbot --nginx -d dittdomän.se"
fi

echo ""
echo "=========================================="
echo -e "${GREEN}Installation slutförd!${NC}"
echo "=========================================="
echo ""
echo "Funktioner i Drönarkarta Viewer Pro:"
echo "  ✅ Visar användarens GPS-position på kartan"
echo "  ✅ Hämtar och visar alla drönarkarta-lager från LFV API"
echo "  ✅ Ladda upp DJI SRT-filer för att visa flygrutt"
echo "  ✅ Ladda upp DJI-video och synkronisera med flygdata"
echo "  ✅ Spela upp flygning animerat på kartan"
echo "  ✅ Visa statistik för flygning (höjd, hastighet, avstånd)"
echo "  ✅ Interaktiv karta med OpenStreetMap"
echo ""
print_info "För att testa certifikatförnyelse, kör:"
echo "  certbot renew --dry-run"
echo ""
