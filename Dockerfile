FROM php:8.1.2-apache

RUN ln -fs /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime && dpkg-reconfigure --frontend noninteractive tzdata

RUN apt-get update && apt-get install -y tzdata vim

RUN apt-get update && apt-get install -y \
    build-essential \
    libnghttp2-dev \
    apache2

# Habilitar os módulos http2 e mpm_event, desabilitar os módulos php e mpm_prefork
RUN a2enmod http2 \
    && a2dismod php \
    && a2dismod mpm_prefork \
    && a2enmod mpm_event

# Adicionar "LoadModule http2_module modules/mod_http2.so" no final do arquivo apache2.conf
RUN echo "LoadModule http2_module modules/mod_http2.so" >> /etc/apache2/apache2.conf

# Adicionar "Protocols h2 h2c http/1.1" no final do arquivo apache2.conf
RUN echo "Protocols h2 h2c http/1.1" >> /etc/apache2/apache2.conf

# Alterar a linha que contém o ServerName para "ServerName localhost" no apache2.conf
RUN sed -i 's/ServerName .*/ServerName localhost/' /etc/apache2/apache2.conf

COPY ./app/ /var/www/html/
COPY ./deploy/cert /srv/cert
COPY ./deploy/default.conf /etc/apache2/sites-available/default.conf

# Reiniciar Apache
RUN a2ensite default.conf \
    && a2enmod rewrite \
    && a2enmod ssl \
    && a2enmod socache_shmcb \
    && service apache2 restart

# Expor a porta 80 e 443
EXPOSE 80 443

# COMPILAR A IMAGEM E CONTAINER E RODAR A APLICAÇÃO:
# clear && docker rm --force http2 && docker rmi --force http2
# clear && docker build -t http2 . && docker compose up -d --force-recreate http2 && docker run -d -p 80:80 -p 443:443 --name http2 http2

# VERIFICAR O PROTOCOLO QUE ESTÁ SENDO UTILIZADO:
# clear && curl -I --http2 https://localhost

# CONFIGURAR CERTIFICADO SSL:
# sudo apt install libnss3-tools
# curl -JLO "https://dl.filippo.io/mkcert/latest?for=linux/amd64"
# chmod +x mkcert-v*-linux-amd64
# sudo cp mkcert-v*-linux-amd64 /usr/local/bin/mkcert
# mkcert -install
# mkcert localhost
