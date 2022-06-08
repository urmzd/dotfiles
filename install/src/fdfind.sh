OUTPUT="fd-v8.3.2-x86_64-unknown-linux-gnu"
FILE="$OUTPUT.tar.gz"
LINK="https://github.com/sharkdp/fd/releases/download/v8.3.2/$FILE" 

curl -L $LINK --output $FILE
tar -xzf $FILE
sudo mv $FILE /usr/local/bin/fdfind
rm -rf $FILE
