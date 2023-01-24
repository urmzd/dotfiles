#!/usr/bin/env bash

mkdir -p ~/.fonts

# Meslo
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf -P ~/.fonts
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf -P ~/.fonts
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf -P ~/.fonts
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf -P ~/.fonts

# Adobe Garmond
wget "https://use.typekit.net/af/af619f/00000000000000003b9b00c5/27/a?primer=7cdcb44be4a7db8877ffa5c0007b8dd865b3bbc383831fe2ea177f62257a9191&fvd=n7&v=3" -O AdobeGarmondProBold.otf
wget "https://use.typekit.net/af/6c275f/00000000000000003b9b00c6/27/a?primer=7cdcb44be4a7db8877ffa5c0007b8dd865b3bbc383831fe2ea177f62257a9191&fvd=i7&v=3" -O AdobeGarmondProBoldItalic.otf
wget "https://use.typekit.net/af/5cace6/00000000000000003b9b00c2/27/a?primer=7cdcb44be4a7db8877ffa5c0007b8dd865b3bbc383831fe2ea177f62257a9191&fvd=i4&v=3" -O AdobeGarmondProItalic.otf
wget "https://use.typekit.net/af/2011b6/00000000000000003b9b00c1/27/a?primer=7cdcb44be4a7db8877ffa5c0007b8dd865b3bbc383831fe2ea177f62257a9191&fvd=n4&v=3" -O AdobeGarmondProRegular.otf
