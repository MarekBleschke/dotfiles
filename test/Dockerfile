FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    zsh \
    git \
    curl \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Create test user with sudo access
RUN useradd -m -s /bin/zsh testuser && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch to test user
USER testuser
WORKDIR /home/testuser

# Entry point
CMD ["/bin/zsh"]
