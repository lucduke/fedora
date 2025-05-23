#!/bin/bash

#################
### VARIABLES ###
#################
GNOMECOMPADD="gnome-extensions-app gnome-shell-extension-appindicator gnome-shell-extension-dash-to-dock gnome-shell-extension-blur-my-shell qgnomeplatform-qt5"
GNOMECOMPDEL="gnome-2048 gnome-klotski gnome-mahjongg gnome-mines gnome-nibbles gnome-robots gnome-sudoku gnome-taquin gnome-games gnome-music totem five-or-more hitori iagno four-in-a-row quadrapassel lightsoff tali gnome-tetravex swell-foop rhythmbox"
ICI=$(dirname "$0")


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

# Vérifie si un paquet Debian est installé
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

# Télécharge le paquet .deb depuis une URL et l'installe
add_deb_pkg() {
    wget -O /tmp/tmp.deb "$1"
    dpkg -i /tmp/tmp.deb
    apt install -f -y
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
	wget -O /tmp/naps2.rpm https://github.com/cyanfish/naps2/releases/download/v8.1.4/naps2-8.1.4-linux-x64.rpm
	dnf install -y /tmp/naps2.rpm
	rm -f /tmp/naps2.rpm
fi

## ajoout de sshs
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
