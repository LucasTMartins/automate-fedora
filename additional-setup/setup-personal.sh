#!/bin/bash

# --------------- INSTALAR APPS DE TERMINAL ---------------
print_status "instalando apps de sistema..."
sudo dnf install -y \
    qbittorrent \
    steam
check_status "instalar apps de sistema"
# ---------------

# --------------- INSTALAR APPS FLATPAK ---------------
print_status "instalando apps flatpak..."
flatpak install -y flathub \
    com.discordapp.discord \
    com.heroicgameslauncher.hgl \
    com.parsecgaming.parsec
check_status "instalar apps flatpak"
# ---------------