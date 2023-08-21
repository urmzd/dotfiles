FROM ubuntu:latest as base
# Install build dependencies via apt

RUN apt-get update -y && \
apt-get install -y \
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
&& rm -rf /var/lib/apt/lists/* 

RUN chsh -s $(which zsh)

ENTRYPOINT ["/bin/zsh"]

FROM base

RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

ENTRYPOINT [ "/bin/zsh" ]


# install oh-my-zsh

# Install terminal emulator

# Install shell

# Install tmux

# Install editor
