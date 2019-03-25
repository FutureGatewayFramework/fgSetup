# OS
FROM httpd 

# Maintainer
MAINTAINER Riccardo Bruno <riccardo.bruno@ct.infn.it>

# Environment for FGDB
ENV FG_USER=futuregateway\
 FG_USERPWD=futuregateway\
 FG_DIR=/home/futuregateway\
 FG_TEST=fgtest\
 FG_TESTPWD=fgtest\
 FG_TESTDIR=/home/fgtest\
 FGDB_HOST=fgdb\
 FGDB_PORT=3306\
 FGDB_USER=fgapiserver\
 FGDB_PASSWD=fgapiserver_password\
 FGDB_NAME=fgapiserver\
# Environment for scripts
 FGSETUP_GIT=https://github.com/FutureGatewayFramework/fgSetup.git\
 FGSETUP_BRANCH=v0.0.10\
# Environment for GridEngine EI
 UTDB_HOST=$FGDB_HOST\
 UTDB_PORT=3306\
 UTDB_USER=tracking_user\
 UTDB_PASSWORD=usertracking\
 UTDB_DATABASE=userstracking\
# Environment for Liferay portal
 FG_LIFERAY_PROXYPATH=/liferay\
 FG_LIFERAY_PROXY=ajp://fgliferay:8009


# SSL/HTTPS Certificates
ADD server.crt /usr/local/apache2/conf
ADD server.key /usr/local/apache2/conf

# Package Installation
RUN adduser --disabled-password --gecos "" $FG_USER &&\
    chown -R $FG_USER:$FG_USERS $FG_DIR &&\
    echo "$FG_USER:$FG_USERPWD" | /usr/sbin/chpasswd &&\
    adduser --disabled-password --gecos "" $FG_TEST &&\
    chown -R $FG_TEST:$FG_TEST $FG_TESTDIR &&\
    echo "$FG_TEST:$FG_TESTPWD" | /usr/sbin/chpasswd &&\
    apt-get update &&\
    apt-get install -y --no-install-recommends\
            curl\
            ca-certificates\
            sudo\
            git\
            mysql-client\
            mlocate\
            vim\
            locales &&\
    #sudo echo "$FG_USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers &&\
    apt-get clean &&\
    rm -rf /var/lib/apt/lists/* &&\
    locale-gen en_US.UTF-8 &&\
    sed -i 's/#LoadModule\ ssl_module\ modules\/mod_ssl.so/LoadModule\ ssl_module\ modules\/mod_ssl.so/'\
           /usr/local/apache2/conf/httpd.conf &&\
    sed -i 's/#LoadModule\ socache_shmcb_module\ modules\/mod_socache_shmcb.so/LoadModule\ socache_shmcb_module\ modules\/mod_socache_shmcb.so/' /usr/local/apache2/conf/httpd.conf &&\
    sed -i 's/#Include\ conf\/extra\/httpd-ssl.conf/Include\ conf\/extra\/httpd-ssl.conf/'\
           /usr/local/apache2/conf/httpd.conf &&\
    sed -i 's/#LoadModule\ proxy_module\ modules\/mod_proxy.so/LoadModule\ proxy_module\ modules\/mod_proxy.so/'\
           /usr/local/apache2/conf/httpd.conf &&\
    sed -i 's/#LoadModule\ proxy_balancer_module\ modules\/mod_proxy_balancer.so/LoadModule\ proxy_balancer_module\ modules\/mod_proxy_balancer.so/'\
           /usr/local/apache2/conf/httpd.conf &&\
    sed -i 's/#LoadModule\ proxy_hcheck_module\ modules\/mod_proxy_hcheck.so/LoadModule\ proxy_hcheck_module\ modules\/mod_proxy_hcheck.so/'\
           /usr/local/apache2/conf/httpd.conf &&\
    sed -i 's/#LoadModule\ slotmem_shm_module\ modules\/mod_slotmem_shm.so/LoadModule\ slotmem_shm_module\ modules\/mod_slotmem_shm.so/'\
           /usr/local/apache2/conf/httpd.conf &&\
    sed -i 's/#LoadModule\ watchdog_module\ modules\/mod_watchdog.so/LoadModule\ watchdog_module\ modules\/mod_watchdog.so/'\
           /usr/local/apache2/conf/httpd.conf &&\
    sed -i 's/#LoadModule\ proxy_http_module\ modules\/mod_proxy_http.so/LoadModule\ proxy_http_module\ modules\/mod_proxy_http.so/'\
           /usr/local/apache2/conf/httpd.conf &&\
    sed -i 's/#LoadModule\ proxy_html_module\ modules\/mod_proxy_html.so/LoadModule\ proxy_html_module\ modules\/mod_proxy_html.so/'\
           /usr/local/apache2/conf/httpd.conf &&\
    sed -i 's/#LoadModule\ xml2enc_module\ modules\/mod_xml2enc.so/LoadModule\ xml2enc_module modules\/mod_xml2enc.so/'\
           /usr/local/apache2/conf/httpd.conf &&\
    sed -i 's/#LoadModule\ proxy_ajp_module\ modules\/mod_proxy_ajp.so/LoadModule\ proxy_ajp_module\ modules\/mod_proxy_ajp.so/'\
           /usr/local/apache2/conf/httpd.conf &&\
    sed -i 's/#LoadModule\ rewrite_module\ modules\/mod_rewrite.so/LoadModule\ rewrite_module\ modules\/mod_rewrite.so/'\
           /usr/local/apache2/conf/httpd.conf &&\
    echo "ServerName fgsg.ct.infn.it" >> /usr/local/apache2/conf/extra/proxy-html.conf &&\
    echo "ProxyPreserveHost on" >> /usr/local/apache2/conf/extra/proxy-html.conf &&\
    echo "ProxyRequests off" >> /usr/local/apache2/conf/extra/proxy-html.conf &&\
    echo "ProxyPass \"$FG_LIFERAY_PROXYPATH\"  \"$FG_LIFERAY_PROXY\"" >> /usr/local/apache2/conf/extra/proxy-html.conf &&\
    echo "ProxyPassReverse \"$FG_LIFERAY_PROXYPATH\"  \"$FG_LIFERAY_PROXY\"" >> /usr/local/apache2/conf/extra/proxy-html.conf &&\
    echo "for f in \$(find $FG_DIR/.fgprofile -type f); do source \$f; done # FGLOADENV" >> /etc/profile.d/fg_profile.sh

# User and working directory
USER $FG_USER
WORKDIR $FG_DIR

# FutureGateway scripts
RUN git clone $FGSETUP_GIT -b $FGSETUP_BRANCH &&\
    mkdir -p .fgprofile &&\
    cp fgSetup/scripts/commons .fgprofile/commons &&\
    cp fgSetup/scripts/fgdb .fgprofile/fgdb &&\
    cp fgSetup/scripts/ei_gridengine .fgprofile/ei_gridengine &&\
# Configure scripts
    ESC_FG_DIR=$(echo $FG_DIR | sed 's/\//\\\//g') &&\
    sed -i "s/^export FGLOCATION.*/export FGLOCATION=$ESC_FG_DIR/" .fgprofile/fgdb &&\
    sed -i "s/^export FGDB_HOST.*/export FGDB_HOST=$FGDB_HOST/" .fgprofile/fgdb &&\
    sed -i "s/^export FGDB_PORT.*/export FGDB_PORT=$FGDB_PORT/" .fgprofile/fgdb &&\
    sed -i "s/^export FGDB_USER.*/export FGDB_USER=$FGDB_USER/" .fgprofile/fgdb &&\
    sed -i "s/^export FGDB_PASSWD.*/export FGDB_PASSWD=$FGDB_PASSWD/" .fgprofile/fgdb &&\
    sed -i "s/^export FGDB_NAME.*/export FGDB_NAME=$FGDB_NAME/" .fgprofile/fgdb &&\
    sed -i "s/^export ASDB_OPTS.*/export ASDB_OPTS=''/" .fgprofile/fgdb &&\
    sed -i "s/^export FGDB_ROOTPWD.*/export FGDB_ROOTPWD=$MYSQL_ROOT_PASSWORD/" .fgprofile/fgdb 

#
# Additional setup for Executor Interfaces
#

# Grid and Cloud Engine UsersTracking database
RUN sed -i "s/^export UTDB_HOST.*/export UTDB_HOST=$UTDB_HOST/" .fgprofile/ei_gridengine &&\
    sed -i "s/^export UTDB_PORT.*/export UTDB_PORT=$UTDB_PORT/" .fgprofile/ei_gridengine &&\
#    sed -i "s/^export UTDB_USER.*/export UTDB_USER=$UTDB_USER/" .fgprofile/ei_gridengine &&\
#    sed -i "s/^export UTDB_PASSWD.*/export UTDB_PASSWD=$UTDB_PASSWD/" .fgprofile/ei_gridengine &&\
#    sed -i "s/^export UTDB_NAME.*/export UTDB_NAME=$UTDB_NAME/" .fgprofile/ei_gridengine &&\
    sed -i "s/^export UTDB_OPTS.*/export UTDB_OPTS=''/" .fgprofile/ei_gridengine

EXPOSE 80
EXPOSE 443

# Prepare and execute sshd
USER root
WORKDIR /root

