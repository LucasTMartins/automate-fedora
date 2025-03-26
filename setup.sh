#!/bin/bash

asdf_dir="$HOME/.asdf"
asdf_nodejs_dir="$HOME/.asdf/plugins/nodejs"
asdf_java_dir="$HOME/.asdf/plugins/java"

# --------------- CORES PARA OUTPUT ---------------
red='\033[0;31m'
green='\033[0;32m'
nc='\033[0m' # no color
# ---------------

# --------------- FUNÇÃO PARA IMPRIMIR MENSAGENS DE STATUS ---------------
print_status() {
    echo -e "${green}[*] $1${nc}"
}
# ---------------

# --------------- FUNÇÃO PARA VERIFICAR SE O COMANDO FOI EXECUTADO COM SUCESSO ---------------
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${green}[✓] $1${nc}"
    else
        echo -e "${red}[✗] erro ao $1${nc}"
        exit 1
    fi
}
# ---------------

# --------------- ATUALIZAR O SISTEMA ---------------
print_status "atualizando o sistema..."
sudo dnf update -y
check_status "atualizar o sistema"
# ---------------

# --------------- HABILITAR RPM FUSION ---------------
print_status "habilitando rpm fusion..."
sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -e %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -e %fedora).noarch.rpm
check_status "habilitar rpm fusion"
# ---------------

# --------------- INSTALAR GRUPO DE DESENVOLVIMENTO C ---------------
print_status "instalando ferramentas de desenvolvimento c..."
sudo dnf group install -y "c-development"
check_status "instalar ferramentas de desenvolvimento"
# ---------------

# --------------- INSTALAR APPS DE TERMINAL ---------------
print_status "instalando apps de terminal..."
sudo dnf install -y \
    micro \
    neovim \
    ranger \
    bat \
    btop \
    tmux \
    python3-devel \
    zsh
check_status "instalar apps de terminal"
# ---------------

# --------------- INSTALAR APPS DE SISTEMA ---------------
print_status "instalando apps de sistema..."
sudo dnf install -y \
    qlipper \
    flameshot \
    filezilla \
    vlc \
    timeshift \
    chromium \
    meld
check_status "instalar apps de sistema"
# ---------------

# --------------- INSTALAR DOCKER ---------------
print_status "instalando docker..."
sudo dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io
sudo systemctl start docker
sudo systemctl enable docker
check_status "instalar docker"
# ---------------

# --------------- ADICIONAR USUÁRIO AO GRUPO DOCKER ---------------
print_status "adicionando usuário ao grupo docker..."
sudo usermod -ag docker $user
check_status "adicionar usuário ao grupo docker"
# ---------------

# --------------- INSTALAR VISUAL STUDIO CODE ---------------
print_status "instalando visual studio code..."
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=visual studio code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
sudo dnf install -y code
check_status "instalar vscode"
# ---------------

# --------------- INSTALAR DISTROBOX ---------------
print_status "instalando distrobox..."
sudo dnf install -y distrobox
check_status "instalar distrobox"
# ---------------

# --------------- INSTALAR OH-MY-ZSH! ---------------
print_status "instalando Oh-my-zsh!..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
check_status "instalar Oh-my-zsh!"
# ---------------

# --------------- INSTALAR ASDF MANAGER ---------------
if [[ ! -d $asdf_dir ]]; then 
    print_status "instalando asdf manager..."
    git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.15.0
    check_status "instalar asdf manager"

    # adicionando comandos ao .bashrc
    cat >> ~/.bashrc << EOF

# asdf
. "$HOME/.asdf/asdf.sh"
. "$HOME/.asdf/completions/asdf.bash"
EOF

    source ~/.bashrc
fi

if [[ ! -d $asdf_nodejs_dir ]]; then 
    print_status "instalando plugin de nodejs do asdf..."
    asdf plugin-add nodejs
    check_status "instalar plugin de nodejs do asdf"
fi

if [[ ! -d $asdf_java_dir ]]; then 
    print_status "instalando plugin de java do asdf..."
    asdf plugin-add java
    check_status "instalar plugin de java do asdf"
fi
# ---------------

# --------------- INSTALAR FLATPAK ---------------
print_status "configurando flatpak..."
sudo dnf install -y flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
check_status "configurar flatpak"
# ---------------

# --------------- INSTALAR APPS FLATPAK ---------------
print_status "instalando apps flatpak..."
flatpak install -y flathub \
    com.github.tchx84.flatseal \
    com.obsproject.studio \
    eu.scarpetta.pdfmixtool \
    md.obsidian.obsidian \
    org.telegram.desktop \
    com.anydesk.anydesk \
    com.bitwarden.desktop \
    io.freetubeapp.FreeTube
check_status "instalar apps flatpak"
# ---------------

# --------------- CRIAR DIRETÓRIOS ---------------
print_status "criando diretórios..."
mkdir -p ~/workspace ~/gitclones
check_status "criar diretórios"
# ---------------

# --------------- EXPORTAR VARIÁVEIS E FUNÇÕES PARA CONFIGURAÇÕES ADICIONAIS ---------------
export red green nc
export -f \
        print_status \
        check_status
# ---------------

# --------------- CONFIGURAÇÃO DE AMBIENTE PESSOAL ---------------
read -p "Gostaria de executar as configurações do ambiente pessoal?(s/N) " answer

if [[ "$answer" == [yYsS] ]]; then
    additional-setup/setup-personal.sh
fi
# ---------------

# --------------- CONFIGURAÇÃO DE AMBIENTE DE TRABALHO ---------------
read -p "Gostaria de executar as configurações do ambiente de trabalho?(s/N) " answer

if [[ "$answer" == [yYsS] ]]; then
    additional-setup/setup-work.sh
fi
# ---------------

print_status "Instalação concluída! Por favor, reinicie o sistema para aplicar todas as alterações."