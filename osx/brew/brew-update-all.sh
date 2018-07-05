#!/usr/bin/env bash
#
# brew-update-all.sh
# Copyright (C) 2018 hoomandb <hoomand@gmail.com>
# Courtesy of Mike Porelli
#
# Distributed under terms of the MIT license.
# 
#

# Ctrl-C trap. Catches INT signal. This is necessary to ensure that we kill all the children
trap "kill ${$}" INT

red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

echo "Updating brew database..."
brew update

echo "Upgrading brew apps..."
brew upgrade

echo "Cleaning brew cache..."
brew cleanup

echo "Upgrading brew cask apps..."
casks=( $(brew cask outdated | awk '{ print $1 }') )

if [ -z "${casks}" ] ; then
  echo "Yay! No casks to upgrade!"
else
  echo -n "The following casks are going to be upgraded: "
  echo ${casks[*]} | sed -e "s/[[:space:]]/, /g" # Replace spaces and newlines with comma space

  problematic=()
  successful=()

  for cask in ${casks[@]}
  do
      echo "${red}${cask}${reset} requires ${red}update${reset}."
      brew cask fetch ${cask}
      exit_status=${?}
      # If we can't download the new release (hash problems, website unavailibility, aliens...) we don't want to uninstall the current version!
      if [ ${exit_status} -eq 0 ] ; then
        brew cask uninstall ${cask}
        exit_status=${?}
        if [ ${exit_status} -ne 0 ] ; then
          echo "${red}${cask}${reset} encountered an error during the uninstallation (${exit_status}). ${red}PLEASE CHECK THE LOGS.${reset}"
          problematic+=("${cask}")
          # Skip to the next application to upgrade
          continue
        fi
        brew cask install ${cask}
        exit_status=${?}
        if [ ${exit_status} -eq 0 ] ; then
          successful+=("${cask}")
          echo "now ${red}${cask}${reset} is ${green}up-to-date!${reset}"
        else
          echo "${red}${cask}${reset} encountered an error during the installation (${exit_status}). ${red}PLEASE CHECK THE LOGS.${reset}"
          problematic+=("${cask}")
        fi
      else
        echo "${red}${cask}${reset} encountered an error during the download (${exit_status}). ${red}PLEASE CHECK THE LOGS.${reset}"
        problematic+=("${cask}")
        # Skip to the next application to upgrade
        continue
      fi
  done

  if [ ${#problematic[@]} -eq 0 ] ; then
    echo "Cleaning brew cask cache..."
    brew cask cleanup
    if [ ${#successful[@]} -eq 0 ] ; then echo "${green}${successful[*]}${reset}have been successfully upgraded." ; fi;
    echo "${green}Congratulations, your system is clean and up-to-date!${reset}"
  else
    echo "We encountered problems upgrading the following packages: ${red}${problematic[*]}${reset}. Some of these packages could be ${red}UNINSTALLED FROM YOUR SYSTEM${reset}, please check the logs. Not proceeding with the cask cleanup process."
  fi
fi
