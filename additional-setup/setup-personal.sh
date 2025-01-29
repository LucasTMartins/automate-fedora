#!/bin/bash

# apps de sistema
print_status "instalando apps de sistema..."
sudo dnf install -y \
    qbittorrent \
    steam
check_status "instalar apps de sistema"

# instalar apps flatpak
print_status "instalando apps flatpak..."
flatpak install -y flathub \
    com.discordapp.discord \
    com.heroicgameslauncher.hgl \
    com.parsecgaming.parsec
check_status "instalar apps flatpak"