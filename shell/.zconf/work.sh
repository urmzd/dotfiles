#!/usr/bin/env zsh

# Work Jumps.
alias rdfe="$HOME/work/operations_dashboard"
alias rdbe="$HOME/work/reeldata_core_springboot"

alias rda="$HOME/work/reel-data-admin-dashboard"
alias rds="$HOME/work/scripts"
alias rdi="$HOME/work/infrastructure_provisoner"

itest() {
   mvn -Dit.test=$1 failsafe:integration-test
}
