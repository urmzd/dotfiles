#!/bin/bash

# Start CPAN configuration
perl -MCPAN -e shell

# Add LanguageServer for PERL.
cpan Perl::LanguageServer
