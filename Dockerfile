FROM debian

# Versions of apps
ARG terraform_version=1.1.6
ARG terragrunt_version=0.36.1
ARG packer_version=1.7.10
ARG golang_version=1.17.7

# Ensure we are fully up to date
RUN apt update && apt upgrade -y 

# Install simple tools with apt
RUN apt install -y vim curl wget nmap ncat git mtr lynx bash-completion telnet mc screen mosh build-essential file procps npm man lftp jq

# Install Bitwarden CLI
RUN npm install -g @bitwarden/cli

# Install awscli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install

# Install AWS Session Manager plugin
RUN if [ $(uname -m) = "x86_64" ]; then curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"; elif [ $(uname -m) = "aarch64" ]; then curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_arm64/session-manager-plugin.deb" -o "session-manager-plugin.deb"; fi
RUN dpkg -i session-manager-plugin.deb

# Install Terraform
RUN if [ $(uname -m) = "x86_64" ]; then curl "https://releases.hashicorp.com/terraform/${terraform_version}/terraform_${terraform_version}_linux_amd64.zip" -o "terraform.zip"; elif [ $(uname -m) = "aarch64" ]; then curl "https://releases.hashicorp.com/terraform/${terraform_version}/terraform_${terraform_version}_linux_arm64.zip" -o "terraform.zip"; fi
RUN unzip terraform.zip -d /usr/local/bin/

# Install Terragrunt
RUN if [ $(uname -m) = "x86_64" ]; then curl -L -s --output /usr/local/bin/terragrunt "https://github.com/gruntwork-io/terragrunt/releases/download/${terragrunt_version}/terragrunt_linux_amd64"; elif [ $(uname -m) = "aarch64" ]; then curl -L -s --output /usr/local/bin/terragrunt "https://github.com/gruntwork-io/terragrunt/releases/download/${terragrunt_version}/terragrunt_linux_arm64"; fi
RUN chmod +x /usr/local/bin/terragrunt

# Install Packer (jq for parsing manifest files)
RUN if [ $(uname -m) = "x86_64" ]; then curl "https://releases.hashicorp.com/packer/${packer_version}/packer_${packer_version}_linux_amd64.zip" -o "packer.zip"; elif [ $(uname -m) = "aarch64" ]; then curl "https://releases.hashicorp.com/packer/${packer_version}/packer_${packer_version}_linux_arm64.zip" -o "packer.zip"; fi
RUN unzip packer.zip -d /usr/local/bin/

# Install golang
RUN if [ $(uname -m) = "x86_64" ]; then curl -L "https://go.dev/dl/go${golang_version}.linux-amd64.tar.gz" -o "golang.tar.gz"; elif [ $(uname -m) = "aarch64" ]; then curl -L "https://go.dev/dl/go${golang_version}.linux-arm64.tar.gz" -o "golang.tar.gz"; fi
RUN tar -C /usr/local -xzf golang.tar.gz

# Add my own user
RUN useradd -s /bin/bash -m lazzurs

# Switch to my user
USER lazzurs

# Switch to my homedir
WORKDIR /home/lazzurs

# Install bash git prompt
RUN git clone https://github.com/magicmonty/bash-git-prompt.git ~/.bash-git-prompt --depth=1

# Install chezmoi
RUN sh -c "$(curl -fsLS chezmoi.io/get)" -- init --apply lazzurs

# Favourite shell time
ENTRYPOINT ["/bin/bash"]
