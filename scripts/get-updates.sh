#!/usr/bin/env bash

ORANGE='\033[0;33m'
NOCOLOR='\033[0m'

echo -e "${ORANGE}Udating Applications...${NOCOLOR}"
	sudo pacman -Syu
	yay -Syu

echo " "
echo -e "${ORANGE}Cleaning caches & directories...${NOCOLOR}"
	pacman -Sc
	yay -Sc

echo " "
echo -e "${ORANGE}Updating Complete!${NOCOLOR}"
