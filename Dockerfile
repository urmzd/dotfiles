FROM ubuntu:latest as base

# Step 1
RUN apt update -y && \
    apt install -y \
    jq \
    tldr \
    software-properties-common \
    ninja-build \
    gettext \
    libtool \
    libtool-bin \
    autoconf \
    automake \
    cmake \
    g++ \
    pkg-config \
    unzip \
    curl \
    doxygen \
    git \
    build-essential \
    zip \
    zsh \
    wget \
    && rm -rf /var/lib/apt/lists/* 

RUN chsh -s $(which zsh)

ENTRYPOINT ["/bin/zsh"]

FROM base as zsh-base

# Step 2
RUN mkdir -p "$HOME/.fonts"

# Meslo
RUN wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf -P ~/.fonts
RUN wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf -P ~/.fonts
RUN wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf -P ~/.fonts
RUN wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf -P ~/.fonts

# Adobe Garmond
RUN wget "https://use.typekit.net/af/af619f/00000000000000003b9b00c5/27/a?primer=7cdcb44be4a7db8877ffa5c0007b8dd865b3bbc383831fe2ea177f62257a9191&fvd=n7&v=3" -O AdobeGarmondProBold.otf
RUN wget "https://use.typekit.net/af/6c275f/00000000000000003b9b00c6/27/a?primer=7cdcb44be4a7db8877ffa5c0007b8dd865b3bbc383831fe2ea177f62257a9191&fvd=i7&v=3" -O AdobeGarmondProBoldItalic.otf
RUN wget "https://use.typekit.net/af/5cace6/00000000000000003b9b00c2/27/a?primer=7cdcb44be4a7db8877ffa5c0007b8dd865b3bbc383831fe2ea177f62257a9191&fvd=i4&v=3" -O AdobeGarmondProItalic.otf
RUN wget "https://use.typekit.net/af/2011b6/00000000000000003b9b00c1/27/a?primer=7cdcb44be4a7db8877ffa5c0007b8dd865b3bbc383831fe2ea177f62257a9191&fvd=n4&v=3" -O AdobeGarmondProRegular.otf

RUN mv *.otf "$HOME/.fonts"

RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

ENTRYPOINT [ "/usr/bin/zsh" ]

FROM zsh-base

RUN apt update -y && apt upgrade -y && apt install -y neovim
RUN update-alternatives --install /usr/bin/vi vi /usr/bin/nvim 60
RUN update-alternatives --config vi
RUN update-alternatives --install /usr/bin/vim vim /usr/bin/nvim 60
RUN update-alternatives --config vim
RUN update-alternatives --install /usr/bin/editor editor /usr/bin/nvim 60
RUN update-alternatives --config editor

RUN git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

RUN export ZSH_THEME="powerlevel10k/powerlevel10k"

ENTRYPOINT [ "/usr/bin/zsh" ]



# install oh-my-zsh

# Install terminal emulator

# Install shell

# Install tmux

# Install editor
