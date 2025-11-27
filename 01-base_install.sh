#!/bin/bash
#

set -e

# standard packages
#
sudo apt-get update
DEBIAN_FRONTEND=noninteractive sudo apt-get install -y \
   tzdata gnupg software-properties-common wget less \
   git jq yq wget curl vim fontconfig make bind9-dnsutils \
   unzip sudo groff bash-completion pipx python3-venv \
   docker.io

sudo usermod --append -G docker $USER
newgrp docker

### Jinja2
#
pipx install jinja2-cli 
pipx ensurepath

    
### Terraform
#
wget -O- https://apt.releases.hashicorp.com/gpg |  \
        gpg --dearmor | \
        sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update
sudo apt-get install terraform -y 


### AWS CLI
#
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm awscliv2.zip
rm -rf ./aws


### nerdfonts
#
sudo mkdir -p /usr/share/fonts/truetype/liberation 
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/LiberationMono.zip
sudo unzip -d /usr/share/fonts/truetype/liberation LiberationMono.zip
rm LiberationMono.zip
sudo fc-cache -f


### kubectl
#
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" 
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm -rf kubectl


### Helm
#
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | sudo bash


### Starship
#
mkdir ~/.config || echo ".config directory exists"
cp starship.toml ~/.config 
curl -sS https://starship.rs/install.sh > /tmp/install.sh
sudo sh /tmp/install.sh --yes
echo 'eval "$(starship init bash)"' > ~/.bashrc 


### Other .bashrc setup
#
echo 'export PATH="$PATH:/home/ubuntu/.local/bin"' >> ~/.bashrc && \
echo '. /usr/share/bash-completion/bash_completion' >> ~/.bashrc && \
echo 'source <(kubectl completion bash)' >> ~/.bashrc
 

### ArgoCD CLI
#
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

### Homebrew
#
NONINTERACTIVE=true /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo >> ~/.bashrc
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

echo "base install completed successfully"
