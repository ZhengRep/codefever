FROM node:20-slim

EXPOSE 80 22
ENV GO111MODULE=off

RUN apt-get update -y \
&& apt-get install libyaml-dev git golang-go zip sendmail mailutils mariadb-client vim -y \
&& pecl install yaml \
&& docker-php-ext-enable yaml

# Nodejs
RUN apt install nodejs npm

# SSH
RUN docker-service enable ssh && docker-service enable cron

# Codefever repo
RUN mkdir -p ~\Desktop \
&& cd ~\Desktop \
&& git clone https://github.com/ZhengRep/codefever.git codefever-community \
&& cd codefever-community \
&& git checkout feature/dev

# Nginx
RUN apt install nginx
COPY ./misc/docker/vhost.conf-template /etc/nginx/modules-enabled/codefever.vhost.conf

# Go
RUN cd ~/Desktop/codefever-community/http-gateway \
&& go get gopkg.in/yaml.v2 \
&& go build main.go \
&& cd ~/Desktop/codefever-community/ssh-gateway/shell \
&& go get gopkg.in/yaml.v2 \
&& go build main.go

# Codefever worker
RUN apt install supervisor
COPY misc/docker/supervisor-codefever-modify-authorized-keys.conf /etc/conf.d/codefever-modify-authorized-keys.conf
COPY misc/docker/supervisor-codefever-http-gateway.conf /etc/conf.d/codefever-http-gateway.conf

# Configs
RUN useradd -rm git \
    && cd ~/Desktop/codefever-community/misc \
    && cp ./codefever-service-template /etc/init.d/codefever \
    && cp ../config.template.yaml ../config.yaml \
    && cp ../env.template.yaml ../env.yaml \
    && chmod 0777 ../config.yaml ../env.yaml \
    && mkdir ../application/logs \
    && chown -R git:git ../application/logs \
    && chmod -R 0777 ../application/logs  \
    && chmod -R 0777 ../git-storage \
    && mkdir ../file-storage \
    && chown -R git:git ../file-storage \
    && chown -R git:git ../misc \
    && chmod +x /etc/supervisor.d/codefever-modify-authorized-keys.conf \
    && chmod +x /etc/supervisor.d/codefever-http-gateway.conf \
    && cd ../application/libraries/composerlib/ \
    && php ./composer.phar install

# Cron
RUN docker-cronjob '* * * * *  sh ~/Desktop/codefever-community/application/backend/codefever_schedule.sh'

# Entrypoint
ENTRYPOINT misc/docker/docker-entrypoint.sh

