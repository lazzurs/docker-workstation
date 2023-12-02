FROM debian:stable

# Versions of apps
ARG terraform_version=1.5.7
ARG terragrunt_version=0.53.8
ARG packer_version=1.8.4
ARG golang_version=1.19
ARG hadolint_version=2.12.0
ARG bitwarden_cli_version=2023.10.0

# Set pipefail for bash
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Ensure we are fully up to date
RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/*

# Install simple tools with apt
RUN apt-get update \
&& apt-get install -y vim curl wget nmap ncat git mtr lynx bash-completion telnet mc screen mosh build-essential file procps npm man lftp jq bind9-host whois ca-certificates gnupg lsb-release python3-full python3-pip pre-commit iputils-ping dnsutils iputils-tracepath iputils-arping && rm -rf /var/lib/apt/lists/*

# Install gh cli
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
&& chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
&& apt-get update \
&& apt-get install gh -y \
&& rm -rf /var/lib/apt/lists/*

# Install OpenTofu
RUN curl -LfsS https://packagecloud.io/opentofu/tofu/gpgkey | gpg --no-tty --batch --dearmor -o /usr/share/keyrings/opentofu.gpg \
&& chmod go+r /usr/share/keyrings/opentofu.gpg \
&& echo "deb [signed-by=/usr/share/keyrings/opentofu.gpg] https://packagecloud.io/opentofu/tofu/any/ any main" | tee /etc/apt/sources.list.d/opentofu.list > /dev/null \
&& apt-get update \
&& apt-get install tofu -y \
&& rm -rf /var/lib/apt/lists/*

# Install Docker
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
RUN echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update \
&& apt-get install -y docker-ce docker-ce-cli containerd.io \
&& rm -rf /var/lib/apt/lists/*

# Install Bitwarden CLI
RUN npm install -g "@bitwarden/cli@${bitwarden_cli_version}"

# Install awscli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o "awscliv2.zip" \
&& unzip awscliv2.zip \
&& ./aws/install

# Install AWS Session Manager plugin
RUN if [ "$(uname -m)" = "x86_64" ]; then curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"; elif [ "$(uname -m)" = "aarch64" ]; then curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_arm64/session-manager-plugin.deb" -o "session-manager-plugin.deb"; fi
RUN dpkg -i session-manager-plugin.deb

# Install Terraform
RUN if [ "$(uname -m)" = "x86_64" ]; then curl "https://releases.hashicorp.com/terraform/${terraform_version}/terraform_${terraform_version}_linux_amd64.zip" -o "terraform.zip"; elif [ "$(uname -m)" = "aarch64" ]; then curl "https://releases.hashicorp.com/terraform/${terraform_version}/terraform_${terraform_version}_linux_arm64.zip" -o "terraform.zip"; fi
RUN unzip terraform.zip -d /usr/local/bin/

# Install Terragrunt
RUN if [ "$(uname -m)" = "x86_64" ]; then curl -L -s --output /usr/local/bin/terragrunt "https://github.com/gruntwork-io/terragrunt/releases/download/v${terragrunt_version}/terragrunt_linux_amd64"; elif [ "$(uname -m)" = "aarch64" ]; then curl -L -s --output /usr/local/bin/terragrunt "https://github.com/gruntwork-io/terragrunt/releases/download/v${terragrunt_version}/terragrunt_linux_arm64"; fi
RUN chmod +x /usr/local/bin/terragrunt

# Install Packer (jq for parsing manifest files)
RUN if [ "$(uname -m)" = "x86_64" ]; then curl "https://releases.hashicorp.com/packer/${packer_version}/packer_${packer_version}_linux_amd64.zip" -o "packer.zip"; elif [ "$(uname -m)" = "aarch64" ]; then curl "https://releases.hashicorp.com/packer/${packer_version}/packer_${packer_version}_linux_arm64.zip" -o "packer.zip"; fi
RUN unzip packer.zip -d /usr/local/bin/

# Install golang
RUN if [ "$(uname -m)" = "x86_64" ]; then curl -L "https://go.dev/dl/go${golang_version}.linux-amd64.tar.gz" -o "golang.tar.gz"; elif [ "$(uname -m)" = "aarch64" ]; then curl -L "https://go.dev/dl/go${golang_version}.linux-arm64.tar.gz" -o "golang.tar.gz"; fi
RUN tar -C /usr/local -xzf golang.tar.gz

# Install hadolint
RUN if [ "$(uname -m)" = "x86_64" ]; then curl -L "https://github.com/hadolint/hadolint/releases/download/v${hadolint_version}/hadolint-Linux-x86_64" -o "/usr/local/bin/hadolint"; elif [ "$(uname -m)" = "aarch64" ]; then curl -L "https://github.com/hadolint/hadolint/releases/download/v${hadolint_version}/hadolint-Linux-arm64" -o "/usr/local/bin/hadolint"; fi
RUN chmod +x /usr/local/bin/hadolint

# Add my own user and add my user to docker group, this has been changed due to mismatch between host and container.
RUN useradd -s /bin/bash -m lazzurs \
&& usermod -a -G systemd-network lazzurs

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
