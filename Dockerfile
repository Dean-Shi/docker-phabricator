FROM debian:jessie

MAINTAINER Yvonnick Esnault <yvonnick@esnau.lt>

ENV DEBIAN_FRONTEND noninteractive 
ENV DEBCONF_NONINTERACTIVE_SEEN true

RUN apt-get update

# Get Utils
RUN apt-get install -y ssh wget vim less zip cron lsof sudo screen
RUN mkdir /var/run/sshd
RUN useradd -d /home/admin -m -s /bin/bash admin
RUN echo 'admin:docker' | chpasswd
RUN echo 'root:docker' | chpasswd
RUN echo 'admin ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/admin
RUN chmod 0440 /etc/sudoers.d/admin

# Get Supervisor
RUN apt-get install -y supervisor
RUN mkdir -p /var/log/supervisor

# Clean packages
RUN apt-get clean

# Install MySQL
RUN apt-get install -y mysql-server mysql-client libmysqlclient-dev
# Install Apache
RUN apt-get install -y apache2
# Install php
RUN apt-get install -y php5 libapache2-mod-php5 php5-mcrypt php5-mysql php5-gd php5-dev php5-curl php-apc php5-cli php5-json php5-ldap
# Install VCS binaries (git, mercurial, subversion) to pull sources and for phabricator use
RUN apt-get install -y git subversion mercurial

 # Install postfix
RUN apt-get install -y postfix

# Supervisor
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Enabled mod rewrite for phabricator
RUN a2enmod rewrite
RUN sed -i -e"s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/my.cnf
RUN sed -i 's/\[mysqld\]/[mysqld]\nsql_mode=STRICT_ALL_TABLES\nft_min_word_len=3\nft_stopword_file=/opt/phabricator/resources/sql/stopwords.txt/' /etc/mysql/my.cnf
ADD ./startup.sh /opt/startup.sh
RUN chmod +x /opt/startup.sh

ADD phabricator.conf /etc/apache2/sites-available/phabricator.conf
RUN ln -s /etc/apache2/sites-available/phabricator.conf /etc/apache2/sites-enabled/phabricator.conf
RUN rm -f /etc/apache2/sites-enabled/000-default.conf

RUN cd /opt/ && git clone https://github.com/facebook/libphutil.git
RUN cd /opt/ && git clone https://github.com/facebook/arcanist.git
RUN cd /opt/ && git clone https://github.com/facebook/phabricator.git

RUN mkdir -p '/var/repo/'

RUN ulimit -c 10000

# Clean packages
RUN apt-get clean

VOLUME /opt/phabricator/conf/local
EXPOSE 3306 80 22

CMD ["/usr/bin/supervisord"]
