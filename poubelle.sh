# !/bin/bash
# ce script "simule une corbeille" en ligne de commande
# par DENIAUD Brendan
# alias pb
# version béta


version="béta"
nomficversion=".initpoubelle"
chemin="/var/tmp/poubelle"
erreurinsta="le logiciel doit s'installer dans /var/tmp"

#initialise la poubelle si aucun lancement n'a été fait
# 1 si erreur dans l'installation sinon 0
function installation() {
	echo -n "installation de poubelle $version... "
	if [ -d "/var" ]; then
		if [ -d "/var/tmp" ]; then
			if [ ! -d "$chemin" ]; then
				mkdir $chemin
			fi 
			echo $version>$chemin/$nomficversion
			echo "1">$chemin/.numaction
			mkdir $chemin/racine
			cp $0 /usr/local/sbin/pb 2>/dev/null
			chmod u+x /usr/local/sbin/pb
			echo "OK"
			return 0
		else
			echo "/var/tmp n'existe pas "
		fi
	else 
		echo "/var n'existe pas "
	fi
	echo $erreurinsta
}

#desinstallation du logiciel
function desinstallation() {
	echo "La désinstallation entraine la suppression de la poubelle et de son contenu"
	echo -n "Souhaitez-vous vraiment désintaller poubelle $version ? [o/n] "
	read rep
	if [ "$rep" == "o" ] ; then 
		echo -n "desinstallation de poubelle $version... "
		rm -Rf /usr/local/sbin/pb
		rm -Rf /var/tmp/poubelle
		echo "OK"
	fi
	exit 0
}

# test si le logiciel a été déjà installer
# 1 si non installé sinon 0
function dejaInstalle(){
	if [ -d $chemin ]; then	
		if [ -f $chemin/$nomficversion ] ;then
			versiontrouvee=$(cat $chemin/$nomficversion)
			# cat $chemin/$nomficversion
			if [ "$versiontrouvee" != "$version" ] ;then
				echo "le logiciel a déjà été installé mais les versions ne correspondent pas"
			fi
			return 0
		fi
	fi
	return 1
} 

function deplacement {
	chrel=$(dirname $1 2>/dev/null)
	if [ "$?" != "0" ]; then
		echo "fichier non géré ou introuvable"
		exit 1
	fi
	nomelt=$(echo $1 | awk -F/ '{print $NF}')

	cd $chrel
	chabs=$(pwd)
	
	# cas avec un / à la fin (dossier)
	if [ "$nomelt" = "" ]; then 
		nomelt=$(echo $1 | awk -F/ '{print $(NF-1)}')
	fi
	
	cd $chemin/racine
	for dossier in $(echo $chabs | tr '/' '\n' | sed '1d'); do
		if [ ! -d $dossier ] ;then
			mkdir $dossier
		fi
		cd $dossier
	done
	
	
	mv $chabs/$nomelt $chemin/racine$chabs
	timestamp=$(date)
	if [ "$?" = "0" ] ; then
		numaction=$(cat $chemin/.numaction)
		echo "$numaction | $timestamp | mv $chabs/$nomelt $chemin/racine$chabs" >>$chemin/poubelle.log
		numaction=$(($numaction+1))
		echo "$numaction">$chemin/.numaction
	fi

}

function voirlog {
	fic=$(cat $chemin/poubelle.log)
	if [ -n "$fic" ] ;then
		more $chemin/poubelle.log
	else
		echo "Pas d'actions à annuler"
	fi
}

function annuler {

	numligne=$(cat /var/tmp/poubelle/poubelle.log | cut -d'|' -f1 | grep -n $1 | cut -d':' -f1)
	action=$(sed -n "${numligne}p" /var/tmp/poubelle/poubelle.log | cut -d'|' -f3)
	nouvelledest=$(echo $action | cut -d' ' -f3)
	nouvellescr=$(echo $action | cut -d' ' -f4)
	nomelt=$(echo $nouvelledest | awk -F/ '{print $NF}')
	
	# on ne récupère que le répertoire
	ndtravaillee=$(echo $nouvelledest | awk -F'/' '{ for (i=1 ; i< NF ;i++) {printf $i"/"}}')

	mv $nouvellescr/$nomelt $ndtravaillee
	
	# on doit supprimer la ligne du log utilisé
	if [ "$?" == "0" ] ;then
		sed -i "${numligne}d" $chemin/poubelle.log
		echo "$nouvellescr/$nomelt a été restauré dans $ndtravaillee"
	else
		echo "une erreur s'est produite lors de la restauration" 
	fi
}

function aide {
	echo 
	echo "----------------------------------------------------------------------------------"
	echo "| Ce script simule une corbeille pour les utilisateurs de la ligne de commande   |"
	echo "----------------------------------------------------------------------------------"
	echo "|                              Utilisation                                       |"
	echo "| pb element : met à la poubelle l'élément (dossier ou fichier)                  |"
	echo "| pb -l|-lister : affiche les actions de mise à la poubelle                      |"
	echo "| pb -a|-annuler numaction : annule l'action de numéro numaction, ce numéro est  |"
	echo "| complètement à gauche lors de l'affichage des actions                          |"
	echo "| pb -v|-vider : supprime tous les éléments de la poubelle                       |"
	echo "| pb -desinstaller : désinstalle (supression de l'alias) et supprime la poubelle |"
	echo "| pb -h : affiche cette aide                                                     |"   
	echo "|                                                                                |" 
	echo "| Note : à la première utilisation, le script installe l'alias pb                |"
	echo "----------------------------------------------------------------------------------"
	echo
}

function vider {
	nbelt=$(cat $chemin/poubelle.log | wc -l)
	echo -n "êtes-vous sûr de vouloir vider la poubelle ($nbelt éléments )? [o/n] : "
	read rep
	if [ "$rep" == "o" ] ; then 
		echo -n "Suppression de tous les éléments de la poubelle ... "
		rm -Rf /var/tmp/poubelle/racine/*
		echo "1">$chemin/.numaction
		>$chemin/poubelle.log
		echo "OK"
	fi
}

if [ "$#" = "0" ]; then
	echo "Pour une aide, utilisez $0 -h"
	exit 2
fi

# test pour voir si la poubelle a été déjà installé sinon installation (dossier+alias)
if [ "$1" != "-desinstaller" ] ; then
	dejaInstalle
	if [ "$?" != "0" ] ;then installation ;fi
fi


case $1 in
	"-desinstaller") desinstallation;;
	"-lister"|"-l") voirlog;;
	"-annuler"|"-a") annuler $2;;
	"-vider"|"-v") vider ;;
	"-h") aide;;
	*) deplacement $1;;
esac