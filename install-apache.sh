#!/bin/bash

# Função para exibir a caixa de diálogo
show_dialog() {
    # Solicita a senha para o usuário
    MYSQL_PASSWORD=$(dialog --stdout --passwordbox "Digite a senha desejada para o usuário root do MySQL:" 10 40)
    if [[ $? -ne 0 ]]; then
        dialog --msgbox "Instalação cancelada." 10 30
        clear
        exit 0
    fi
    
    # Solicita o nome de usuário do Git
    GIT_USERNAME=$(dialog --stdout --inputbox "Digite o nome de usuário do Git:" 10 40)
    if [[ $? -ne 0 ]]; then
        dialog --msgbox "Instalação cancelada." 10 30
        clear
        exit 0
    fi
    
    # Solicita o email do Git
    GIT_EMAIL=$(dialog --stdout --inputbox "Digite o email do Git:" 10 40)
    if [[ $? -ne 0 ]]; then
        dialog --msgbox "Instalação cancelada." 10 30
        clear
        exit 0
    fi
    
    # Limpa o terminal após solicitar o email do Git
    clear
    
    # Instala o pacote dialog
    sudo apt-get update
    sudo apt-get install dialog -y
    
    # Variável para controlar o progresso da instalação
    local progress=0
    
    # Exibe o diálogo de progresso
    (
        echo "0"; sleep 1; echo "Atualizando pacotes..."; sleep 1;
        sudo apt-get update >/dev/null 2>&1
        echo "20"; sleep 1; echo "Instalando Apache..."; sleep 1;
        sudo apt-get install apache2 -y >/dev/null 2>&1
        echo "40"; sleep 1; echo "Instalando Snap e Core..."; sleep 1;
        sudo apt-get install snapd -y >/dev/null 2>&1
        sudo snap install core >/dev/null 2>&1; sudo snap refresh core >/dev/null 2>&1
        echo "60"; sleep 1; echo "Instalando PHP e MySQL..."; sleep 1;
        sudo apt-get install curl -y >/dev/null 2>&1
        sudo apt-get install mysql-server -y >/dev/null 2>&1
        sudo apt-get install php libapache2-mod-php php-mysql -y >/dev/null 2>&1
        echo "80"; sleep 1; echo "Instalando extensões do PHP..."; sleep 1;
        sudo apt-get install phpmyadmin php-zip php-gd php-json php-curl php-mbstring php-gettext phpenmod mcrypt mbstring php-openssl php-soap php-xml -y >/dev/null 2>&1
        echo "90"; sleep 1; echo "Configurando MySQL..."; sleep 1;
        echo "mysql-server mysql-server/root_password password $MYSQL_PASSWORD" | sudo debconf-set-selections
        echo "mysql-server mysql-server/root_password_again password $MYSQL_PASSWORD" | sudo debconf-set-selections
        sudo mysql_secure_installation -y >/dev/null 2>&1
        echo "95"; sleep 1; echo "Configurando Firewall..."; sleep 1;
        sudo apt-get install ufw -y >/dev/null 2>&1
        sudo ufw enable >/dev/null 2>&1
        sudo ufw allow http >/dev/null 2>&1
        sudo ufw allow ssh >/dev/null 2>&1
        echo "98"; sleep 1; echo "Configurando SSL..."; sleep 1;
        echo "Options -Indexes" | sudo tee -a /etc/apache2/apache2.conf >/dev/null 2>&1
        sudo chown -R www-data:www-data /var/www/html >/dev/null 2>&1
        sudo chmod -R 755 /var/www/html >/dev/null 2>&1
        sudo a2enmod ssl >/dev/null 2>&1
        sudo make-ssl-cert generate-default-snakeoil --force-overwrite >/dev/null 2>&1
        sudo a2ensite default-ssl >/dev/null 2>&1
        sudo service apache2 reload >/dev/null 2>&1
        echo "100"; sleep 1; echo "Concluído."; sleep 1;
    ) | dialog --title "Instalação do Wachatbot" --gauge "Por favor, aguarde..." 10 60 0
    
    # Exibe a mensagem de conclusão
    dialog --msgbox "Instalação concluída!" 10 30
}

# Chama a função para exibir a caixa de diálogo
show_dialog
