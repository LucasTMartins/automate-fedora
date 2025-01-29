#!/bin/bash

# --------------- INSTALAR APPS FLATPAK ---------------
print_status "instalando apps flatpak..."
flatpak install -y flathub \
    io.dbeaver.dbeavercommunity
check_status "instalar apps flatpak"
# ---------------