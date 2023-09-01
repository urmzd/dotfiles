# Use a smaller base image
FROM alpine:latest as zsh-base

# Combine RUN instructions and use apk package manager
RUN apk update && \
    apk add --no-cache \
        jq \
        bash \
        ninja-build \
        gettext \
        autoconf \
        automake \
        cmake \
        g++ \
        pkgconf \
        unzip \
        curl \
        doxygen \
        git \
        build-base \
        shadow \
        zip \
        zsh \
        wget \
    && rm -rf /var/cache/apk/*

SHELL ["/bin/zsh", "-c"]

# Download fonts using a loop
RUN mkdir -p "$HOME/.fonts" \
    && for font in MesloLGS%20NF%20Regular MesloLGS%20NF%20Bold MesloLGS%20NF%20Italic MesloLGS%20NF%20Bold%20Italic; do \
        wget -q -P ~/.fonts "https://github.com/romkatv/powerlevel10k-media/raw/master/$font.ttf"; \
    done

# Install Oh My Zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install Powerlevel10k theme
RUN git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# Create a new stage for Neovim and reuse the zsh-base
FROM zsh-base as nvim-base

# Install Neovim
RUN apk add --no-cache neovim

# Create a new stage for Go and reuse the nvim-base
FROM nvim-base as go-base

RUN apk add --no-cache bison

# Install Go Version Manager (gvm)
RUN zsh < <(curl -s -S -L https://raw.githubusercontent.com/urmzd/gvm/master/binscripts/gvm-installer)

# Install Go versions
RUN source ~/.zshrc && gvm install go1.4 -B \
    && gvm use go1.4 \
    && export GOROOT_BOOTSTRAP=$GOROOT \
    && gvm install go1.21.0 -B \
    && gvm use go1.21.0 --default

# Create a new stage for Tmux and reuse the go-base
FROM go-base as tmux-base

# Install Tmux dependencies
RUN apk add --no-cache libressl libevent-dev ncurses-dev

# Build and install Tmux from source
WORKDIR /tmp
RUN git clone https://github.com/tmux/tmux.git \
    && cd tmux \
    && sh autogen.sh \
    && ./configure \
    && make \
    && make install \
    && rm -rf /tmp/tmux

# Set the working directory back to root
WORKDIR /root

# Define the entry point for the final image
ENTRYPOINT [ "/bin/zsh" ]
