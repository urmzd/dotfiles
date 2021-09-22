!/bin/bash

# Install perl
if [[! -d /usr/bin/perl ]]
then
  sudo apt install perl
fi

# Install `cpanm` for easier use.
cpan install App::cpanminus

# Add language server for vim use.
cpanm Perl::LanguageServer
