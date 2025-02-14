# Use Ubuntu 22.04 as base image
FROM ubuntu:22.04

# Set non-interactive mode for apt
ENV DEBIAN_FRONTEND=noninteractive

# Build-time arguments for user creation
ARG USERNAME=deploy
ARG USER_UID=1000
ARG USER_GID=1000

# Pass the username to runtime environment
ENV USERNAME=${USERNAME}

# Install required packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        openssh-server \
        curl \
        sudo \
        ca-certificates && \
    # Setup NodeSource repository
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    # Install Node.js
    apt-get install -y nodejs && \
    # Verify installation
    node --version && \
    npm --version && \
    # Clean up
    rm -rf /var/lib/apt/lists/*

# Create non-root user and add to sudoers
RUN groupadd --gid ${USER_GID} ${USERNAME} && \
    useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} && \
    echo "${USERNAME} ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} && \
    chmod 0440 /etc/sudoers.d/${USERNAME}

# Configure SSH
RUN mkdir /var/run/sshd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# Create deployment directories and adjust ownership
RUN mkdir -p /home/${USERNAME}/app.git /home/${USERNAME}/app && \
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}

# Initialize bare repository
USER ${USERNAME}
WORKDIR /home/${USERNAME}
RUN git init --bare app.git

# Switch back to root
USER root

# Copy and setup post-receive hook
COPY post-receive /home/${USERNAME}/app.git/hooks/post-receive
RUN chmod +x /home/${USERNAME}/app.git/hooks/post-receive && \
    chown ${USERNAME}:${USERNAME} /home/${USERNAME}/app.git/hooks/post-receive

# Expose ports
EXPOSE 22 3000

# Copy and setup entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]