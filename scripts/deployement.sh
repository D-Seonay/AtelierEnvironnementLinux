#!/bin/bash
apt install sshpass -y

# Vérification que le fichier CSV est fourni en argument
if [ $# -ne 1 ]; then
    echo "Utilisation : $0 fichier.csv"
    exit 1
fi

csv_file="$1"

# Vérification de si le fichier existe
if [ ! -f "$csv_file" ]; then
    echo "Le fichier $csv_file n'existe pas."
    exit 1
fi

# Lecture du fichier CSV et attribution des valeurs aux variables
while IFS=',' read -r var value; do
    case "$var" in
        *)
            if [ -n "$var" ]; then
                eval "$var=\"$value\""
            fi
            ;;
    esac
done < "$csv_file"

# Affichage des valeurs des variables
echo "web = $web"
echo "bdd = $bdd"

#connexion à la vm web
$SUDOPASS = "root"
echo $SUDOPASS | ssh root@$web 

# Vérifie les mises à jour du système
sudo apt update && sudo apt -y upgrade
if [ $? -ne 0 ]; then
    echo "Échec de la mise à jour du système. Veuillez vérifier les erreurs."
    exit 1
fi

# Installe PHP et ses extensions
sudo apt -y install php php-common php-cli php-fpm php-json php-pdo php-mysql php-zip php-gd php-mbstring php-curl php-xml php-pear php-bcmath
if [ $? -ne 0 ]; then
    echo "Échec de l'installation de PHP et de ses extensions. Veuillez vérifier les erreurs."
    exit 1
fi

# Installe Apache
sudo apt install apache2
if [ $? -ne 0 ]; then
    echo "Échec de l'installation d'Apache. Veuillez vérifier les erreurs."
    exit 1
fi

# Donne les droits à l'utilisateur sur le dossier Apache
sudo chown -R $USER:www-data /var/www/html/
sudo chmod -R 770 /var/www/html/
if [ $? -ne 0 ]; then
    echo "Échec de la configuration des permissions sur le dossier web. Veuillez vérifier les erreurs."
    exit 1
fi

echo "Le script a terminé avec succès. Votre serveur est prêt."

#connexion au serveur distant
ssh user@$bdd <<'eof'

# Installation d'OpenSSL
sudo apt install openssl -y
if [ $? -ne 0 ]; then
    echo "Échec de l'installation d'OpenSSL. Veuillez vérifier les erreurs."
    exit 1
fi

# Installation de MariaDB
sudo apt install mariadb-server php-mysql -y
if [ $? -ne 0 ]; then
    echo "Échec de l'installation de MariaDB. Veuillez vérifier les erreurs."
    exit 1
fi

# On se connecte à MySQL
sudo mysql --user=root <<MYSQL_SCRIPT
$PASSWORD = "$(openssl rand -base64 32)"
# On change le mot de passe de l'utilisateur root
ALTER USER 'root'@'localhost' IDENTIFIED BY '$PASSWORD';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

echo "Le mot de passe root de MySQL a été modifié. Nouveau mot de passe : $PASSWORD"