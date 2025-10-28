# GitHub Publiceringsguide

## 📦 Filer att ladda upp till GitHub

Skapa ett nytt repository på GitHub med namnet: **droneroute**
Användare: **yxkastarn**

### Filer att inkludera:

1. **dronechart-viewer-pro.html** - Huvudapplikationen
2. **proxmox-install-dronechart.sh** - Installationsskript för Proxmox
3. **README.md** - Huvuddokumentation
4. **QUICKSTART.md** - Snabbstartsguide

### GitHub Repository-struktur:

```
droneroute/
├── README.md
├── QUICKSTART.md
├── proxmox-install-dronechart.sh
├── dronechart-viewer-pro.html
└── LICENSE (valfritt)
```

## 🚀 Snabbkommando för användare

När filerna är uppladdade på GitHub kan användare installera med:

```bash
bash <(curl -s https://raw.githubusercontent.com/yxkastarn/route/refs/heads/main/proxmox-install-dronechart.sh)
```

**Alternativt med wget:**

```bash
wget https://raw.githubusercontent.com/yxkastarn/droneroute/refs/heads/main/proxmox-install-dronechart.sh -O /tmp/install-dronechart.sh && chmod +x /tmp/install-dronechart.sh && /tmp/install-dronechart.sh
```

## 📋 Steg för att publicera på GitHub

### 1. Skapa repository

```bash
# Via GitHub web UI:
# 1. Gå till https://github.com/new
# 2. Repository name: droneroute
# 3. Description: "Drönarkarta Viewer Pro - Visualisera DJI-flygningar med LFV API-integration"
# 4. Public
# 5. Lägg INTE till README, .gitignore eller license (vi lägger till egna)
# 6. Create repository
```

### 2. Ladda upp filer

```bash
# Klona det tomma repot
git clone https://github.com/yxkastarn/droneroute.git
cd droneroute

# Kopiera filer
cp /path/to/dronechart-viewer-pro.html .
cp /path/to/proxmox-install-dronechart.sh .
cp /path/to/README.md .
cp /path/to/QUICKSTART.md .

# Gör installationsskriptet körbart
chmod +x proxmox-install-dronechart.sh

# Commit och pusha
git add .
git commit -m "Initial commit: Drönarkarta Viewer Pro v1.0"
git push origin main
```

### 3. Verifiera installation

Efter uppladdning, testa att installationen fungerar:

```bash
# På en Proxmox-host
bash <(curl -s https://raw.githubusercontent.com/yxkastarn/droneroute/refs/heads/main/proxmox-install-dronechart.sh)
```

## 📝 README-innehåll

README.md innehåller:
- ⚡ Snabbstartskommando
- ✨ Funktionslista
- 📋 Systemkrav
- 🚀 Detaljerad installation
- 📂 DJI SRT-filinformation
- 🎥 Videouppspelning
- 🔒 HTTPS/SSL-konfiguration
- 🛠️ Användningsinstruktioner
- 🐛 Felsökning
- 📚 Resurser och länkar

## 🔗 Viktiga URL:er efter publicering

- **Repository**: https://github.com/yxkastarn/droneroute
- **Raw HTML**: https://raw.githubusercontent.com/yxkastarn/droneroute/refs/heads/main/dronechart-viewer-pro.html
- **Raw Install Script**: https://raw.githubusercontent.com/yxkastarn/droneroute/refs/heads/main/proxmox-install-dronechart.sh
- **README**: https://github.com/yxkastarn/droneroute/blob/main/README.md
- **Install (curl)**: `bash <(curl -s https://raw.githubusercontent.com/yxkastarn/droneroute/refs/heads/main/proxmox-install-dronechart.sh)`

## 🎯 Efter publicering

### Uppdatera dokumentation
Om du gör ändringar i framtiden:

```bash
# I ditt lokala repo
git pull
# Gör ändringar
git add .
git commit -m "Beskrivning av ändringar"
git push
```

### Skapa releases (valfritt)

```bash
# Tagga en version
git tag -a v1.0.0 -m "Version 1.0.0 - Initial release"
git push origin v1.0.0
```

Sedan kan du skapa en release på GitHub web UI med release notes.

## 📢 Marknadsföring

### GitHub Topics
Lägg till följande topics till ditt repository:
- `drone`
- `dji`
- `proxmox`
- `lxc`
- `gis`
- `mapping`
- `aviation`
- `sweden`
- `leaflet`
- `flight-tracker`

### Beskrivning
"Visualisera DJI-drönarflygningar på interaktiv karta med LFV:s Drönarkarta-API. En-kommando installation för Proxmox LXC. Stöd för SRT-telemetri och videosynkronisering."

## ⚖️ Licens (valfritt)

Om du vill lägga till en licens, lägg till en LICENSE-fil. Förslag:

**MIT License** - Mest permissiv, tillåter kommersiell användning
```
MIT License

Copyright (c) 2025 yxkastarn

Permission is hereby granted, free of charge, to any person obtaining a copy...
```

**GPL-3.0** - Kräver att ändringar också är öppen källkod
```
GNU General Public License v3.0
```

## 🎉 Färdig checklista

- [ ] Skapat GitHub repository: droneroute
- [ ] Laddat upp alla filer
- [ ] Verifierat att raw URLs fungerar
- [ ] Testat installationsskriptet
- [ ] Lagt till repository topics
- [ ] Skrivit bra beskrivning
- [ ] (Valfritt) Lagt till LICENSE
- [ ] (Valfritt) Skapat första release

## 📧 Dela projektet

När allt är klart kan du dela:
- Repository URL: https://github.com/yxkastarn/droneroute
- Installations-kommando (se ovan)
- Screenshots (lägg till i README)
- Video-demo (lägg till i README)

---

**Lycka till med publiceringen! 🚀**
