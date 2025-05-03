#!/bin/bash

## Personnalisation GNOME
echo -e "\033[1;34m01- Personnalisation composants GNOME\033[0m"
echo -e " - Personalisation Nautilus"
gsettings set org.gnome.nautilus.list-view default-visible-columns "['name', 'size', 'owner', 'group', 'permissions', 'date_modified', 'detailed_type']"
gsettings set org.gnome.nautilus.list-view default-column-order "['name', 'size', 'detailed_type', 'permissions', 'owner', 'group', 'date_modified', 'starred']"
gsettings set org.gnome.nautilus.preferences show-hidden-files true
gsettings set org.gnome.nautilus.preferences date-time-format 'detailed'
gsettings set org.gnome.nautilus.preferences click-policy 'double'
gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view'
gsettings set org.gtk.Settings.FileChooser sort-directories-first true
gsettings set org.gtk.gtk4.Settings.FileChooser show-hiden true
gsettings set org.gtk.gtk4.Settings.FileChooser sort-directories-first true
echo -e " - Boutons de fenêtre"
gsettings set org.gnome.desktop.wm.preferences button-layout "appmenu:minimize,maximize,close"
echo -e " - Suramplification"
gsettings set org.gnome.desktop.sound allow-volume-above-100-percent true
echo -e " - Détacher les popups des fenêtres"
gsettings set org.gnome.mutter attach-modal-dialogs false
echo -e " - Affichage du calendrier dans le panneau supérieur"
gsettings set org.gnome.desktop.calendar show-weekdate true
echo -e " - Modification du format de la date et heure"
gsettings set org.gnome.desktop.interface clock-show-date true
gsettings set org.gnome.desktop.interface clock-show-weekday true
gsettings set org.gnome.desktop.interface clock-format 24h
echo -e " - Activation du mode nuit"
gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 3500
echo -e " - Epuration des fichiers temporaires et de la corbeille de plus de 30 jours"
gsettings set org.gnome.desktop.privacy remove-old-temp-files true
gsettings set org.gnome.desktop.privacy remove-old-trash-files true
gsettings set org.gnome.desktop.privacy old-files-age "30"
echo -e "- Configuration de GNOME Logiciels"
gsettings set org.gnome.software show-ratings true
echo -e "- Configuration de GNOME Text Editor"
gsettings set org.gnome.TextEditor highlight-current-line false
gsettings set org.gnome.TextEditor restore-session false
gsettings set org.gnome.TextEditor show-line-numbers true