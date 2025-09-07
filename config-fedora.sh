#!/bin/bash

#################
### VARIABLES ###
#################
GNOMECOMPADD="gnome-extensions-app gnome-shell-extension-appindicator gnome-shell-extension-dash-to-dock gnome-shell-extension-blur-my-shell qgnomeplatform-qt5"
GNOMECOMPDEL="gnome-2048 gnome-klotski gnome-mahjongg gnome-mines gnome-nibbles gnome-robots gnome-sudoku gnome-taquin gnome-games gnome-music totem five-or-more hitori iagno four-in-a-row quadrapassel lightsoff tali gnome-tetravex swell-foop rhythmbox"
ICI=$(dirname "$0")

# Variables pour les téléchargements RPM
NAPS2_VERSION="8.1.4"
NAPS2_URL="https://github.com/cyanfish/naps2/releases/download/v${NAPS2_VERSION}/naps2-${NAPS2_VERSION}-linux-x64.rpm"
NAPS2_TEMP_RPM="/tmp/naps2.rpm"
HEROIC_VERSION="2.18.0"
HEROIC_URL="https://github.com/Heroic-Games-Launcher/HeroicGamesLauncher/releases/download/v${HEROIC_VERSION}/Heroic-${HEROIC_VERSION}-linux-x86_64.rpm"
HEROIC_TEMP_RPM="/tmp/heroic.rpm"
RUSTDESK_VERSION="1.4.1"
RUSTDESK_URL="https://github.com/rustdesk/rustdesk/releases/download/${RUSTDESK_VERSION}/rustdesk-${RUSTDESK_VERSION}-0.x86_64.rpm"
RUSTDESK_TEMP_RPM="/tmp/rustdesk.rpm"

#################
### FONCTIONS ###
#################
check_cmd()
{
if [[ $? -eq 0 ]]
then
    	echo -e "\033[32mOK\033[0m"
else
    	echo -e "\033[31mERREUR\033[0m"
fi
}

# Vérifie si un paquet Fedora est installé
check_pkg() {
	rpm -q "$1" > /dev/null
}

add_pkg()
{
	dnf install -y "$1"
}

del_pkg()
{
	dnf remove -y "$1"
}

add_gnome_pkg()
{
	for p in $GNOMECOMPADD
	do
		if ! check_pkg "$p"
		then
			echo -n "- - - Installation composant GNOME $p : "
			add_pkg "$p"
			check_cmd
		fi
	done
}

del_gnome_pkg()
{
	for p in $GNOMECOMPDEL
	do
		if check_pkg "$p"
		then
			echo -n "- - - Suppression composant GNOME $p : "
			del_pkg "$p"
			check_cmd
		fi
	done
}

check_flatpak()
{
	flatpak info "$1"
}

add_flatpak()
{
	flatpak install flathub --noninteractive -y "$1"
}

del_flatpak()
{
	flatpak uninstall --noninteractive -y "$1" && flatpak uninstall --unused  --noninteractive -y
}

upgrade_dnf()
{
	dnf upgrade -y
}

update_flatpak()
{
	flatpak update --noninteractive
}

####################
### DEBUT SCRIPT ###
####################
# Tester si root
if [ "$(id -u)" -ne 0 ]
then
 	echo -e "\033[31mERREUR\033[0m Lancer le script avec les droits root"
	exit 1;
fi 

# Cas CHECK-UPDATES
if [[ "$1" = "check" ]]
then

	echo -e "01 - Mises à jour DNF : "
	upgrade_dnf
	check_cmd

	echo -e "02 - Mises à jour FLATPAK : "
	update_flatpak
	check_cmd

	exit;
fi

# Autres cas
## Ajout du dépôt Fedora Copr adriend
dnf copr enable adriend/fedora-apps

## Update du système
echo -e "\033[1;34m00- - Update du système : \033[0m"
upgrade_dnf
check_cmd

## Activer flathub
echo -e "\033[1;34m01- - Activation du dépôt Flathub : \033[0m"
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
check_cmd

## MAJ FLATPACK
echo -e "\033[1;34m02- - Mises à jour FLATPAK : \033[0m"
update_flatpak
check_cmd

## Installation de rpm fusion
echo -e "\033[1;34m03- - Installation de RPM Fusion : \033[0m"
dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
check_cmd

## Installation du depot vsCode
echo -e "\033[1;34m04- Installation du depot VsCode\033[0m"
### Import de la clef GPG
rpm --import https://packages.microsoft.com/keys/microsoft.asc
### Creation du fichier vscode.repo
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | tee /etc/yum.repos.d/vscode.repo > /dev/null

## Install/Suppr RPM selon liste
echo -e "\033[1;34m05- Gestion des paquets via RPM\033[0m"
while read -r line
do
	if [[ "$line" == add:* ]]
	then
		p=${line#add:}
		if ! check_pkg "$p"
		then
			echo -n "- - - Installation paquet $p : "
			add_pkg "$p"
			check_cmd
		fi
	fi

	if [[ "$line" == del:* ]]
	then
		p=${line#del:}
		if check_pkg "$p"
		then
			echo -n "- - - Suppression paquet $p : "
			del_pkg "$p"
			check_cmd
		fi
	fi
done < "$ICI/rpm.list"

## Install/Suppr FLATPAK selon liste
echo -e "\033[1;34m06- Gestion des paquets via FLATPAK\033[0m"
while read -r line
do
	if [[ "$line" == add:* ]]
	then
		p=${line#add:}
		if ! check_flatpak "$p"
		then
			echo -n "- - - Installation paquet $p : "
			add_flatpak "$p"
			check_cmd
		fi
	fi

	if [[ "$line" == del:* ]]
	then
		p=${line#del:}
		if check_flatpak "$p"
		then
			echo -n "- - - Suppression paquet $p : "
			del_flatpak "$p"
			check_cmd
		fi
	fi
done < "$ICI/flatpak.list"

## Personnalisation GNOME
echo -e "\033[1;34m07- Personnalisation composants GNOME\033[0m"
del_gnome_pkg
add_gnome_pkg 
gnome-extensions enable dash-to-dock@micxgx.gmail.com
gnome-extensions enable appindicatorsupport@rgcjonas.gmail.com
echo -e "Instaler manuellement l'extension Dash2Doc, ArcMenu et Blurmyshell"

## Ajout Twingate
echo -e "\033[1;34m08- Installation de Twingate\033[0m"
if ! check_pkg twingate
then
	dnf install -y 'dnf-command(config-manager)'
    dnf config-manager addrepo --set=baseurl="https://packages.twingate.com/rpm/"
    dnf config-manager setopt "packages.twingate.com_rpm_.gpgcheck=0"
    dnf install -y twingate  # or twingate-latest
    # After installation, configure the client by running: sudo twingate setup
fi

## Ajout naps2
echo -e "\033[1;34m09- Installation de NAPS2\033[0m"
if ! check_pkg naps2
then
    echo "- - - Téléchargement de NAPS2 v${NAPS2_VERSION}..."
    
    # Nettoyage préventif du fichier temporaire
    rm -f "${NAPS2_TEMP_RPM}"

    # Téléchargement avec gestion d'erreurs et timeout
    if wget --timeout=30 --tries=3 -O "${NAPS2_TEMP_RPM}" "${NAPS2_URL}"; then
        echo "- - - Téléchargement réussi, vérification du fichier..."
        
        # Vérification que le fichier existe et n'est pas vide
        if [[ -f "${NAPS2_TEMP_RPM}" && -s "${NAPS2_TEMP_RPM}" ]]; then
            echo "- - - Fichier valide, installation en cours..."
            
            # Installation avec gestion d'erreurs
            if dnf install -y "${NAPS2_TEMP_RPM}"; then
                echo "- - - Installation de NAPS2 réussie"
                rm -f "${NAPS2_TEMP_RPM}"
            else
                echo -e "\033[31mERREUR\033[0m Installation de NAPS2 échouée"
                rm -f "${NAPS2_TEMP_RPM}"
                exit 1
            fi
        else
            echo -e "\033[31mERREUR\033[0m Fichier téléchargé invalide ou vide"
            rm -f "${NAPS2_TEMP_RPM}"
            exit 1
        fi
    else
        echo -e "\033[31mERREUR\033[0m Échec du téléchargement de NAPS2"
        rm -f "${NAPS2_TEMP_RPM}"
        exit 1
    fi
fi

## Ajout Heroic Games Launcher
echo -e "\033[1;34m08- Installation de Heroic Games Launcher\033[0m"
if ! check_pkg heroic
then
	echo "- - - Téléchargement de Heroic Games Launcher v${HEROIC_VERSION}..."
    rm -f "${HEROIC_TEMP_RPM}"
    if wget --timeout=30 --tries=3 -O "${HEROIC_TEMP_RPM}" "${HEROIC_URL}"; then
        echo "- - - Téléchargement réussi, vérification du fichier..."
        if [[ -f "${HEROIC_TEMP_RPM}" && -s "${HEROIC_TEMP_RPM}" ]]; then
            echo "- - - Fichier valide, installation en cours..."
            if dnf install -y "${HEROIC_TEMP_RPM}"; then
                echo "- - - Installation de Heroic Games Launcher réussie"
                rm -f "${HEROIC_TEMP_RPM}"
            else
                echo -e "\033[31mERREUR\033[0m Installation de Heroic Games Launcher échouée"
                rm -f "${HEROIC_TEMP_RPM}"
                exit 1
            fi
        else
            echo -e "\033[31mERREUR\033[0m Fichier téléchargé invalide ou vide"
            rm -f "${HEROIC_TEMP_RPM}"
            exit 1
        fi
    else
        echo -e "\033[31mERREUR\033[0m Échec du téléchargement de Heroic Games Launcher"
        rm -f "${HEROIC_TEMP_RPM}"
        exit 1
    fi
fi

## Ajout de Rustdesk
echo -e "\033[1;34m09- Installation de Rustdesk\033[0m"
if ! check_pkg rustdesk
then
	echo "- - - Téléchargement de Rustdesk v${RUSTDESK_VERSION}..."
    rm -f "${RUSTDESK_TEMP_RPM}"
    if wget --timeout=30 --tries=3 -O "${RUSTDESK_TEMP_RPM}" "${RUSTDESK_URL}"; then
        echo "- - - Téléchargement réussi, vérification du fichier..."
        if [[ -f "${RUSTDESK_TEMP_RPM}" && -s "${RUSTDESK_TEMP_RPM}" ]]; then
            echo "- - - Fichier valide, installation en cours..."
            if dnf install -y "${RUSTDESK_TEMP_RPM}"; then
                echo "- - - Installation de Rustdesk réussie"
                rm -f "${RUSTDESK_TEMP_RPM}"
            else
                echo -e "\033[31mERREUR\033[0m Installation de Rustdesk échouée"
                rm -f "${RUSTDESK_TEMP_RPM}"
                exit 1
            fi
        else
            echo -e "\033[31mERREUR\033[0m Fichier téléchargé invalide ou vide"
            rm -f "${RUSTDESK_TEMP_RPM}"
            exit 1
        fi
    else
        echo -e "\033[31mERREUR\033[0m Échec du téléchargement de Rustdesk"
        rm -f "${RUSTDESK_TEMP_RPM}"
        exit 1
    fi
fi

## ajout de sshs
echo -e "\033[1;34m10- Installation de SSHS\033[0m"
### On teste l'existence du binaire sshs dans /usr/local/bin
if [ ! -f /usr/local/bin/sshs ]
then
	### On le télécharge
	wget -O /usr/local/bin/sshs https://github.com/quantumsheep/sshs/releases/download/4.7.2/sshs-linux-amd64
	### On le rend exécutable
	chmod +x /usr/local/bin/sshs
fi

## Ajout de points de montage CIFS
echo -e "\033[1;34m11- Ajout de points de montage CIFS\033[0m"
### On teste si le fichier de credentials existe
if [ ! -f /etc/cifs-credentials ]
then
	### On le crée
	echo -e "username=user\npassword=pwd" > /etc/cifs-credentials
	chmod 600 /etc/cifs-credentials
fi
### On teste si le répertoire media existe
if [ ! -d /mnt/media ]
then
	### On le crée
	mkdir -p /mnt/media
	### On ajoute le point de montage dans le fstab
	echo -e "\n# Point de montage media pour le NAS" >> /etc/fstab
	echo -e "//nas.lan/media /mnt/media cifs _netdev,nofail,credentials=/etc/cifs-credentials,uid=1000,gid=1000,vers=3.0,noperm 0 0" >> /etc/fstab
fi
### On teste si le répertoire documents existe
if [ ! -d /mnt/documents ]
then
	### On le crée
	mkdir -p /mnt/documents
	### On ajoute le point de montage dans le fstab
	echo -e "\n# Point de montage documents pour le NAS" >> /etc/fstab
	echo -e "//nas.lan/documents /mnt/documents cifs _netdev,nofail,credentials=/etc/cifs-credentials,uid=1000,gid=1000,vers=3.0,noperm 0 0" >> /etc/fstab
fi
### On teste si le répertoire software existe
if [ ! -d /mnt/software ]
then
	### On le crée
	mkdir -p /mnt/software
	### On ajoute le point de montage dans le fstab
	echo -e "\n# Point de montage software pour le NAS" >> /etc/fstab
	echo -e "//nas.lan/software /mnt/software cifs _netdev,nofail,credentials=/etc/cifs-credentials,uid=1000,gid=1000,vers=3.0,noperm 0 0" >> /etc/fstab
fi

## Ajout de points de montage NFS
echo -e "\033[1;34m12- Ajout de points de montage NFS\033[0m"
### On teste si le répertoire nfs_photoview existe
if [ ! -d /mnt/nfs_photoview ]
then
	### On le crée
	mkdir -p /mnt/nfs_photoview
	### On ajoute le point de montage dans le fstab
	echo -e "\n# Point de montage photoview pour le NAS" >> /etc/fstab
	echo -e "nas.lan:/srv/no-raid/nfs1/docker/photoview_nfs_photos /mnt/nfs_photoview nfs defaults,intr,_netdev,nofail 0 0" >> /etc/fstab
fi
### On teste si le répertoire nfs_deemix existe
if [ ! -d /mnt/nfs_deemix ]
then
	### On le crée
	mkdir -p /mnt/nfs_deemix
	### On ajoute le point de montage dans le fstab
	echo -e "\n# Point de montage deemix pour le NAS" >> /etc/fstab
	echo -e "nas.lan:/srv/raid/nfs/docker/deemix_nfs_downloads /mnt/nfs_deemix nfs rw,intr,_netdev,nofail 0 0" >> /etc/fstab
fi

## Ajout d'alias dans .bashrc
echo -e "\033[1;34m13- Ajout d'alias dans .bashrc\033[0m"
if [ -n "$SUDO_USER" ]; then
    BASHRC_PATH="/home/$SUDO_USER/.bashrc"
    if [ -f "$BASHRC_PATH" ]; then
        ALIASES_ADDED=false
        if ! grep -q "alias meteo" "$BASHRC_PATH"; then
            echo "alias meteo=\"curl wttr.in\"" >> "$BASHRC_PATH"
            ALIASES_ADDED=true
        fi
        if ! grep -q "alias cat" "$BASHRC_PATH"; then
            echo "alias cat=\"bat\"" >> "$BASHRC_PATH"
            ALIASES_ADDED=true
        fi
        if ! grep -q "alias duf" "$BASHRC_PATH"; then
            echo "alias duf=\"duf --hide special\"" >> "$BASHRC_PATH"
            ALIASES_ADDED=true
        fi
        if ! grep -q "alias trouve" "$BASHRC_PATH"; then
            echo "alias trouve=\"fd\"" >> "$BASHRC_PATH"
            ALIASES_ADDED=true
        fi
        if ! grep -q "alias download" "$BASHRC_PATH"; then
            echo "alias download=\"http --download\"" >> "$BASHRC_PATH"
            ALIASES_ADDED=true
        fi
        if ! grep -q "alias python" "$BASHRC_PATH"; then
            echo "alias python=\"uv run python\"" >> "$BASHRC_PATH"
            ALIASES_ADDED=true
        fi
        if $ALIASES_ADDED; then
            echo -e "\033[32mAlias ajoutés à $BASHRC_PATH\033[0m"
        else
            echo -e "\033[32mTous les alias sont déjà présents dans $BASHRC_PATH\033[0m"
        fi
    else
        echo -e "\033[31mERREUR\033[0m Fichier .bashrc non trouvé pour l'utilisateur $SUDO_USER"
    fi
else
    echo -e "\033[31mERREUR\033[0m Impossible de déterminer l'utilisateur (SUDO_USER non défini). Lancez le script avec sudo."
fi
