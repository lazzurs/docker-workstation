FROM debian

# Versions of apps
ARG terraform_version=1.5.7
ARG terragrunt_version=0.53.8
ARG packer_version=1.8.4
ARG golang_version=1.19

# Ensure we are fully up to date
RUN apt update && apt upgrade -y 

# Install simple tools with apt
RUN apt install -y vim curl wget nmap ncat git mtr lynx bash-completion telnet mc screen mosh build-essential file procps npm man lftp jq bind9-host whois ca-certificates gnupg lsb-release python3-full python3-pip pre-commit iputils-ping dnsutils iputils-tracepath iputils-arping

# Install gh cli
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
&& chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
&& apt update \
&& apt install gh -y

# Install OpenTofu
RUN curl -LfsS https://packagecloud.io/opentofu/tofu/gpgkey | gpg --no-tty --batch --dearmor -o /usr/share/keyrings/opentofu.gpg \
&& chmod go+r /usr/share/keyrings/opentofu.gpg \
&& echo "deb [signed-by=/usr/share/keyrings/opentofu.gpg] https://packagecloud.io/opentofu/tofu/any/ any main" | tee /etc/apt/sources.list.d/opentofu.list > /dev/null \
&& apt update \
&& apt install tofu -y

# Install Docker
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
RUN echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt update && apt install -y docker-ce docker-ce-cli containerd.io
## Change Docker gid to match current host
##RUN groupmod -g 998 docker


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
RUN if [ $(uname -m) = "x86_64" ]; then curl -L -s --output /usr/local/bin/terragrunt "https://github.com/gruntwork-io/terragrunt/releases/download/v${terragrunt_version}/terragrunt_linux_amd64"; elif [ $(uname -m) = "aarch64" ]; then curl -L -s --output /usr/local/bin/terragrunt "https://github.com/gruntwork-io/terragrunt/releases/download/v${terragrunt_version}/terragrunt_linux_arm64"; fi
RUN chmod +x /usr/local/bin/terragrunt

# Install Packer (jq for parsing manifest files)
RUN if [ $(uname -m) = "x86_64" ]; then curl "https://releases.hashicorp.com/packer/${packer_version}/packer_${packer_version}_linux_amd64.zip" -o "packer.zip"; elif [ $(uname -m) = "aarch64" ]; then curl "https://releases.hashicorp.com/packer/${packer_version}/packer_${packer_version}_linux_arm64.zip" -o "packer.zip"; fi
RUN unzip packer.zip -d /usr/local/bin/

# Install golang
RUN if [ $(uname -m) = "x86_64" ]; then curl -L "https://go.dev/dl/go${golang_version}.linux-amd64.tar.gz" -o "golang.tar.gz"; elif [ $(uname -m) = "aarch64" ]; then curl -L "https://go.dev/dl/go${golang_version}.linux-arm64.tar.gz" -o "golang.tar.gz"; fi
RUN tar -C /usr/local -xzf golang.tar.gz

# Add my own user
RUN useradd -s /bin/bash -m lazzurs
## Add my user to docker group, this has been changed due to mismatch between host and container.
RUN usermod -a -G systemd-network lazzurs

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
