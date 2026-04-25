# Infrastructure

This repository will host everything related to infrastructure for my needs.
For now, this is:

## box1

A NixOS box where we deploy
- cert renewal
- (internet facing) nginx to redirect for SSL termination and redirect to the right app - port 80 / port 443
- (through nginx) rust webapp for lamarieealhonneur - port 3000