FROM alpine:3.19

# Install dependencies
RUN apk add --no-cache \
    zsh \
    git \
    curl \
    sudo \
    bash

# Create test user with sudo access
RUN adduser -D -s /bin/zsh testuser && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch to test user
USER testuser
WORKDIR /home/testuser

# Entry point
CMD ["/bin/zsh"]
