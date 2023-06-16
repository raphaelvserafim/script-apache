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
    clear
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
    
    update_progress "$progress" "Installing Apache..."
    sudo apt-get install apache2 -y
    sudo apt-get install git curl -y
    ((progress += 20))
    clear
    
    update_progress "$progress" "Installing Snap and Core..."
    sudo apt-get install snapd -y
    sudo snap install core
    sudo snap refresh core
    ((progress += 20))
    clear
    
    update_progress "$progress" "Installing PHP and MySQL..."
    sudo apt-get install curl -y
    sudo apt-get install mysql-server -y
    sudo apt-get install php libapache2-mod-php php-mysql -y
    ((progress += 20))
    clear
    
    update_progress "$progress" "Installing PHP extensions..."
    echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | sudo debconf-set-selections
    echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | sudo debconf-set-selections
    echo "mysql-server mysql-server/root_password password $MYSQL_PASSWORD" | sudo debconf-set-selections
    echo "mysql-server mysql-server/root_password_again password $MYSQL_PASSWORD" | sudo debconf-set-selections
    
    sudo apt-get install phpmyadmin php-zip php-gd php-json php-curl php-mbstring mcrypt php-soap php-xml -y
    ((progress += 10))
    clear
    
    update_progress "$progress" "Configuring MySQL..."
    sudo mysql_secure_installation -y
    ((progress += 5))
    clear
    
    update_progress "$progress" "Configuring Firewall..."
    sudo apt-get install ufw -y
    sudo ufw enable
    sudo ufw allow http
    sudo ufw allow ssh
    ((progress += 3))
    clear
    
    update_progress "$progress" "Configuring SSL..."
    echo "Options -Indexes" | sudo tee -a /etc/apache2/apache2.conf
    sudo chown -R www-data:www-data /var/www/html
    sudo chmod -R 755 /var/www/html
    sudo a2enmod ssl
    sudo make-ssl-cert generate-default-snakeoil --force-overwrite
    sudo a2ensite default-ssl
    sudo service apache2 reload
    ((progress += 5))
    clear
    
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
}

# Execute the show_dialog function
show_dialog
