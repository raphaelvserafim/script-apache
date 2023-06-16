#!/bin/bash

# Function to generate a strong password
generate_password() {
    local password=$(date +%s%N | sha256sum | head -c 16)
    echo "$password"
}

# Function to display the dialog box
show_dialog() {
    # Install the dialog, Git, and cURL packages
    sudo apt-get update
    sudo apt-get install dialog -y

    # Prompt for the MySQL root user password
    MYSQL_PASSWORD=$(generate_password)

    # Clear the terminal after prompting for Git email
    clear

    # Variable to track installation progress
    local progress=0

    # Function to update the progress bar
    update_progress() {
        echo "$1"
        echo "$2"
        sleep 1
    }

    # Display the progress dialog
    (
        update_progress "$progress" "Updating packages..."
        sudo apt-get update >/dev/null 2>&1 || { dialog --msgbox "Failed to update packages. Aborting installation." 10 30; clear; exit 1; }
        ((progress += 20))

        update_progress "$progress" "Installing Apache..."
        sudo apt-get install apache2 -y >/dev/null 2>&1 || { dialog --msgbox "Failed to install Apache. Aborting installation." 10 30; clear; exit 1; }
        sudo apt-get install git curl -y >/dev/null 2>&1 || { dialog --msgbox "Failed to install Git and cURL. Aborting installation." 10 30; clear; exit 1; }
        ((progress += 20))

        update_progress "$progress" "Installing Snap and Core..."
        sudo apt-get install snapd -y >/dev/null 2>&1 || { dialog --msgbox "Failed to install Snap and Core. Aborting installation." 10 30; clear; exit 1; }
        sudo snap install core >/dev/null 2>&1 || { dialog --msgbox "Failed to install Snap Core. Aborting installation." 10 30; clear; exit 1; }
        sudo snap refresh core >/dev/null 2>&1 || { dialog --msgbox "Failed to refresh Snap Core. Aborting installation." 10 30; clear; exit 1; }
        ((progress += 20))

        update_progress "$progress" "Installing PHP and MySQL..."
        sudo apt-get install curl -y >/dev/null 2>&1 || { dialog --msgbox "Failed to install cURL. Aborting installation." 10 30; clear; exit 1; }
        sudo apt-get install mysql-server -y >/dev/null 2>&1 || { dialog --msgbox "Failed to install MySQL Server. Aborting installation." 10 30; clear; exit 1; }
        sudo apt-get install php libapache2-mod-php php-mysql -y >/dev/null 2>&1 || { dialog --msgbox "Failed to install PHP and PHP-MySQL. Aborting installation." 10 30; clear; exit 1; }
        ((progress += 20))

        update_progress "$progress" "Installing PHP extensions..."
        sudo apt-get install phpmyadmin php-zip php-gd php-json php-curl php-mbstring php-gettext phpenmod mcrypt mbstring php-openssl php-soap php-xml -y >/dev/null 2>&1 || { dialog --msgbox "Failed to install PHP extensions. Aborting installation." 10 30; clear; exit 1; }
        ((progress += 10))

        update_progress "$progress" "Configuring MySQL..."
        sudo mysql_secure_installation -y >/dev/null 2>&1 || { dialog --msgbox "Failed to configure MySQL. Aborting installation." 10 30; clear; exit 1; }
        ((progress += 5))

        update_progress "$progress" "Configuring Firewall..."
        sudo apt-get install ufw -y >/dev/null 2>&1 || { dialog --msgbox "Failed to install UFW. Aborting installation." 10 30; clear; exit 1; }
        sudo ufw enable >/dev/null 2>&1 || { dialog --msgbox "Failed to enable UFW. Aborting installation." 10 30; clear; exit 1; }
        sudo ufw allow http >/dev/null 2>&1 || { dialog --msgbox "Failed to allow HTTP traffic in the firewall. Aborting installation." 10 30; clear; exit 1; }
        sudo ufw allow ssh >/dev/null 2>&1 || { dialog --msgbox "Failed to allow SSH traffic in the firewall. Aborting installation." 10 30; clear; exit 1; }
        ((progress += 3))

        update_progress "$progress" "Configuring SSL..."
        echo "Options -Indexes" | sudo tee -a /etc/apache2/apache2.conf >/dev/null 2>&1 || { dialog --msgbox "Failed to configure Apache. Aborting installation." 10 30; clear; exit 1; }
        sudo chown -R www-data:www-data /var/www/html >/dev/null 2>&1 || { dialog --msgbox "Failed to change ownership of /var/www/html. Aborting installation." 10 30; clear; exit 1; }
        sudo chmod -R 755 /var/www/html >/dev/null 2>&1 || { dialog --msgbox "Failed to set permissions for /var/www/html. Aborting installation." 10 30; clear; exit 1; }
        sudo a2enmod ssl >/dev/null 2>&1 || { dialog --msgbox "Failed to enable SSL module. Aborting installation." 10 30; clear; exit 1; }
        sudo make-ssl-cert generate-default-snakeoil --force-overwrite >/dev/null 2>&1 || { dialog --msgbox "Failed to generate SSL certificate. Aborting installation." 10 30; clear; exit 1; }
        sudo a2ensite default-ssl >/dev/null 2>&1 || { dialog --msgbox "Failed to enable default-ssl site. Aborting installation." 10 30; clear; exit 1; }
        sudo service apache2 reload >/dev/null 2>&1 || { dialog --msgbox "Failed to reload Apache service. Aborting installation." 10 30; clear; exit 1; }
        ((progress += 5))

        update_progress "$progress" "Completed."
        sleep 1

        dialog --msgbox "Installation completed!" 10 30

        MYSQL_USERNAME=$(dialog --stdout --inputbox "Enter the username for the new MySQL user:" 10 40 "${MYSQL_USERNAME}")
        if [[ $? -ne 0 ]]; then
            dialog --msgbox "Installation canceled." 10 30
            clear
            exit 0
        fi

        MYSQL_USER_PASSWORD=$MYSQL_PASSWORD

        sudo mysql -uroot -p$MYSQL_PASSWORD -e "CREATE USER '$MYSQL_USERNAME'@'localhost' IDENTIFIED BY '$MYSQL_USER_PASSWORD'; GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_USERNAME'@'localhost' WITH GRANT OPTION;"

        echo "MySQL Username: $MYSQL_USERNAME"
        echo "MySQL Password: $MYSQL_USER_PASSWORD"
        sleep 2
    ) |
        dialog --title "LAMP Stack Installation" --gauge "Installing components..." 10 70 0
}

# Execute the show_dialog function
show_dialog
