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
    
    # Prompt for the username to create a new MySQL user
    MYSQL_USERNAME=$(dialog --stdout --inputbox "Enter the username for the new MySQL user:" 10 40)
    if [[ $? -ne 0 ]]; then
        dialog --msgbox "Installation canceled." 10 30
        clear
        exit 0
    fi
    
    # Generate a strong password for the new MySQL user
    MYSQL_USER_PASSWORD=$MYSQL_PASSWORD
    
    # Clear the terminal after prompting for Git email
    clear
    
    sudo apt-get install git curl -y
    
    # Variable to track installation progress
    local progress=0
    
    # Display the progress dialog
    (
        echo "0"; sleep 1; echo "Updating packages..."; sleep 1;
        sudo apt-get update >/dev/null 2>&1
        echo "20"; sleep 1; echo "Installing Apache..."; sleep 1;
        sudo apt-get install apache2 -y >/dev/null 2>&1
        echo "40"; sleep 1; echo "Installing Snap and Core..."; sleep 1;
        sudo apt-get install snapd -y >/dev/null 2>&1
        sudo snap install core >/dev/null 2>&1; sudo snap refresh core >/dev/null 2>&1
        echo "60"; sleep 1; echo "Installing PHP and MySQL..."; sleep 1;
        sudo apt-get install curl -y >/dev/null 2>&1
        sudo apt-get install mysql-server -y >/dev/null 2>&1
        sudo apt-get install php libapache2-mod-php php-mysql -y >/dev/null 2>&1
        echo "80"; sleep 1; echo "Installing PHP extensions..."; sleep 1;
        sudo apt-get install phpmyadmin php-zip php-gd php-json php-curl php-mbstring php-gettext phpenmod mcrypt mbstring php-openssl php-soap php-xml -y >/dev/null 2>&1
        echo "90"; sleep 1; echo "Configuring MySQL..."; sleep 1;
        echo "mysql-server mysql-server/root_password password $MYSQL_PASSWORD" | sudo debconf-set-selections
        echo "mysql-server mysql-server/root_password_again password $MYSQL_PASSWORD" | sudo debconf-set-selections
        sudo mysql_secure_installation -y >/dev/null 2>&1
        
        # Create a new MySQL user with a strong password
        sudo mysql -uroot -p$MYSQL_PASSWORD -e "CREATE USER '$MYSQL_USERNAME'@'localhost' IDENTIFIED BY '$MYSQL_USER_PASSWORD'; GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_USERNAME'@'localhost' WITH GRANT OPTION;"
        
        echo "95"; sleep 1; echo "Configuring Firewall..."; sleep 1;
        sudo apt-get install ufw -y >/dev/null 2>&1
        sudo ufw enable >/dev/null 2>&1
        sudo ufw allow http >/dev/null 2>&1
        sudo ufw allow ssh >/dev/null 2>&1
        echo "98"; sleep 1; echo "Configuring SSL..."; sleep 1;
        echo "Options -Indexes" | sudo tee -a /etc/apache2/apache2.conf >/dev/null 2>&1
        sudo chown -R www-data:www-data /var/www/html >/dev/null 2>&1
        sudo chmod -R 755 /var/www/html >/dev/null 2>&1
        sudo a2enmod ssl >/dev/null 2>&1
        sudo make-ssl-cert generate-default-snakeoil --force-overwrite >/dev/null 2>&1
        sudo a2ensite default-ssl >/dev/null 2>&1
        sudo service apache2 reload >/dev/null 2>&1
        echo "100"; sleep 1; echo "Completed."; sleep 1;
        
        echo "Installing Composer..."; sleep 1;
        sudo apt-get install curl -y >/dev/null 2>&1
        EXPECTED_SIGNATURE="$(curl -sS https://composer.github.io/installer.sig)"
        curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer >/dev/null 2>&1
        sudo chmod +x /usr/local/bin/composer >/dev/null 2>&1
        echo "Composer installed."; sleep 1;
        
        echo "MySQL Username: $MYSQL_USERNAME" >/tmp/mysql_credentials.txt
        echo "MySQL Password: $MYSQL_USER_PASSWORD" >>/tmp/mysql_credentials.txt
        
    ) | dialog --title "Installation Server" --gauge "Please wait..." 10 60 0
    
    # Display the completion message
    dialog --msgbox "Installation completed!" 10 30
}

# Call the function to display the dialog box
show_dialog

# Display MySQL credentials
dialog --title "MySQL Credentials" --textbox /tmp/mysql_credentials.txt 10 40
rm /tmp/mysql_credentials.txt
