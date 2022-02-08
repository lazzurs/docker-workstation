FROM debian

# Ensure we are fully up to date
RUN apt update && apt upgrade -y 

# Install simple tools with apt
RUN apt install -y vim curl wget nmap ncat git mtr lynx bash-completion telnet mc screen mosh build-essential file procps npm

# Install Bitwarden CLI
RUN npm install -g @bitwarden/cli

# TODO: AWS CLI
# TODO: AWS SSM
# TODO: chezmoi

# Add my own user
RUN useradd -s /bin/bash -m lazzurs

# Switch to my user
USER lazzurs

# Switch to my homedir
WORKDIR /home/lazzurs


# Favourite shell time
ENTRYPOINT ["/bin/bash"]
