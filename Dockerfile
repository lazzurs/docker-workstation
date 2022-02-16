FROM debian

# Ensure we are fully up to date
RUN apt update && apt upgrade -y 

# Install simple tools with apt
RUN apt install -y vim curl wget nmap ncat git mtr lynx bash-completion telnet mc screen mosh build-essential file procps npm man

# Install Bitwarden CLI
RUN npm install -g @bitwarden/cli

# Install awscli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install

# Install AWS Session Manager plugin

RUN if [ $(uname -m) = "x86_64" ]; then curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"; elif [ $(uname -m) = "aarch64" ]; then curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_arm64/session-manager-plugin.deb" -o "session-manager-plugin.deb"; fi
RUN dpkg -i session-manager-plugin.deb

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
