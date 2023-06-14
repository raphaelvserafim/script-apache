#!/bin/bash

# Função para exibir a caixa de diálogo
show_dialog() {
    # Solicita a senha para o usuário
    MYSQL_PASSWORD=$(dialog --stdout --passwordbox "Digite a senha desejada para o usuário root do MySQL:" 10 40)
    if [[ $? -ne 0 ]]; then
        dialog --msgbox "Instalação cancelada." 10 30
        exit 0
    fi
    
    # Solicita o nome de usuário do Git
    GIT_USERNAME=$(dialog --stdout --inputbox "Digite o nome de usuário do Git:" 10 40)
    if [[ $? -ne 0 ]]; then
        dialog --msgbox "Instalação cancelada." 10 30
        exit 0
    fi
    
    # Solicita o email do Git
    GIT_EMAIL=$(dialog --stdout --inputbox "Digite o email do Git:" 10 40)
    if [[ $? -ne 0 ]]; then
        dialog --msgbox "Instalação cancelada." 10 30
        exit 0
    fi

    # Instala o pacote dialog
    sudo apt-get update
    sudo apt-get install dialog -y
    
    # Variável para controlar o progresso da instalação
    local progress=0
    
    # Atualiza a lista de pacotes e instala o Apache
    sudo apt-get update
    sudo apt-get install apache2 -y
    progress=20
    
    # Instala o Snap package manager e atualiza o pacote core
    sudo apt-get install snapd -y
    sudo snap install core; sudo snap refresh core
    progress=40
    
    # Instala as dependências necessárias para o PHP e o MySQL
    sudo apt-get install curl -y
    sudo apt-get install mysql-server -y
    sudo apt-get install php libapache2-mod-php php-mysql -y
    progress=60
    
    # Define a senha fornecida pelo usuário para o MySQL
    echo "mysql-server mysql-server/root_password password $MYSQL_PASSWORD" | sudo debconf-set-selections
    echo "mysql-server mysql-server/root_password_again password $MYSQL_PASSWORD" | sudo debconf-set-selections
    
    # Instala as extensões adicionais do PHP para funcionalidades aprimoradas
    sudo apt-get install phpmyadmin -y
    sudo apt-get install php-zip -y
    sudo apt-get install php-gd -y
    sudo apt-get install php-json -y
    sudo apt-get install php-curl -y
    sudo apt-get install php-mbstring -y
    sudo apt-get install php-gettext -y
    sudo apt-get install phpenmod mcrypt -y
    sudo apt-get install phpenmod mbstring -y
    sudo apt-get install php-openssl -y
    sudo apt-get install php-soap -y
    sudo apt-get install php-xml -y
    progress=80
    
    sudo apt-get install composer -y
    sudo apt-get install git -y
    
    # Configura as informações do usuário do Git
    git config --global user.name "$GIT_USERNAME"
    git config --global user.email "$GIT_EMAIL"
    
    # Executa o processo de instalação segura do MySQL
    sudo mysql_secure_installation -y
    progress=90
    
    # Habilita o firewall e permite tráfego HTTP e SSH
    sudo apt-get install ufw -y
    sudo ufw enable
    sudo ufw allow http
    sudo ufw allow ssh
    progress=95
    
    # Desativa a listagem de diretórios na configuração do Apache
    echo "Options -Indexes" | sudo tee -a /etc/apache2/apache2.conf
    
    # Define as permissões de arquivo apropriadas
    sudo chown -R www-data:www-data /var/www/html
    sudo chmod -R 755 /var/www/html
    
    # Habilita o SSL e configura o certificado autoassinado
    sudo a2enmod ssl
    sudo make-ssl-cert generate-default-snakeoil --force-overwrite
    sudo a2ensite default-ssl
    sudo service apache2 reload
    
    # Instala o monitor de logs do Apache
    sudo apt-get install logwatch -y
    
    sudo snap install core -y
    sudo snap refresh core
    
    progress=98
    
    # Gera a chave SSH
    ssh-keygen -t rsa -b 4096 -C "$GIT_EMAIL" -q -N ""
    
    # Exibe a chave pública e oferece opção de copiá-la
    echo "A chave SSH foi gerada com sucesso!"
    echo "Copie e cole a chave pública abaixo para configurar sua conta Git:"
    echo
    cat ~/.ssh/id_rsa.pub
    echo
    echo "Você deseja copiar a chave para a área de transferência? (s/n)"
    
    read -n 1 answer
    echo
    
    if [[ $answer =~ ^[Ss]$ ]]; then
        cat ~/.ssh/id_rsa.pub | xclip -selection clipboard
        echo "A chave SSH foi copiada para a área de transferência."
    fi
    
    # Exibe um alerta para o usuário continuar
    dialog --msgbox "Copie a chave SSH e clique em OK para continuar." 10 30
    if [[ $? -ne 0 ]]; then
        dialog --msgbox "Instalação cancelada." 10 30
        exit 0
    fi
    
    # Clona o repositório Git na pasta wachatbot
    cd /var/www/html
    git clone https://github.com/codejays-com/wachatbot.ai wachatbot
    
    progress=100
    
    # Exibe uma mensagem ao finalizar a instalação
    dialog --msgbox "Instalação concluída!" 10 30
}

# Chama a função para exibir a caixa de diálogo
show_dialog
