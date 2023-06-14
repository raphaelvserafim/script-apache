#!/bin/bash

# Update package list and install Apache web server
sudo apt update -y
sudo apt install apache2 -y

# Install Snap package manager and update core package
sudo apt install snapd -y 
sudo snap install core; sudo snap refresh core

# Install necessary packages for PHP and MySQL
sudo apt install curl -y
sudo apt install mysql-server -y
sudo apt install php libapache2-mod-php php-mysql -y

# Install additional PHP extensions for enhanced functionality
sudo apt-get install phpmyadmin -y
sudo apt-get install php-zip -y
sudo apt-get install php-gd  -y
sudo apt-get install php-json -y
sudo apt-get install php-curl -y
sudo apt-get install php-mbstring -y 
sudo apt-get install php-gettext -y 
sudo apt-get install phpenmod mcrypt -y 
sudo apt-get install phpenmod mbstring -y 
sudo apt-get install php-openssl  -y 
sudo apt-get install php-soap -y 
sudo apt-get install php-xml -y 

sudo apt install composer -y

sudo apt install git -y

# Secure MySQL installation
sudo mysql_secure_installation -y 

# Enable firewall and allow HTTP and SSH traffic
sudo apt-get install ufw -y
sudo ufw enable
sudo ufw allow http
sudo ufw allow ssh

# Disable directory listing in Apache configuration
echo "Options -Indexes" | sudo tee -a /etc/apache2/apache2.conf

# Set appropriate file permissions
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

# Enable SSL and configure self-signed certificate
sudo a2enmod ssl
sudo make-ssl-cert generate-default-snakeoil --force-overwrite
sudo a2ensite default-ssl
sudo service apache2 reload




# Monitor Apache logs
sudo apt-get install logwatch -y

sudo snap install core -y
sudo snap refresh core

echo "Apache web server setup complete."
