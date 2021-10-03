#!/bin/bash

# Install perl.
if [[ ! -d /usr/bin/perl ]]
then
  sudo apt install perl
fi && 

if [[ ! -d /usr/bin/libperl-dev ]]
then
  sudo apt install libperl-dev
fi &&

# Install `cpanm` for easier use.
cpan install App::cpanminus &&

# Add language server for vim use.
cpanm -n Perl::LanguageServer &&


# Install perl-doc to access documentation for modules.
if [[ ! -d /usr/bin/perl-doc ]]
then
  sudo apt install perl-doc
fi