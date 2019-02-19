# OS
FROM esystemstech/liferay:7.0.5-ga6 

# Maintainer
MAINTAINER Riccardo Bruno <riccardo.bruno@ct.infn.it>

# Configure liferay container
ENV DB_HOST=fgdb\
    DB_PORT=3306\
    DB_SCHEMA=lportal\
    DB_USER=lportal\
    DB_PASSWORD=lportal\
# Environment for FGDB
    FG_USER=futuregateway\
    FG_USERPWD=futuregateway\
    MYSQL_ROOT_PASSWORD=rpass\
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
    FGSETUP_BRANCH=v0.0.9\
# Environment for GridEngine EI
    UTDB_HOST=$FGDB_HOST\ 
    UTDB_PORT=3306\
    UTDB_USER=tracking_user\
    UTDB_PASSWORD=usertracking\
    UTDB_DATABASE=userstracking\
# JAVA settings
    JAVA_OPTS="$JAVA_OPTS -XX:NewSize=700m -XX:MaxNewSize=700m -Xms2048m \
-Xmx2048m -XX:MaxPermSize=128m -XX:+UseParNewGC -XX:+UseConcMarkSweepGC \
-XX:+CMSParallelRemarkEnabled -XX:SurvivorRatio=20 \
-XX:ParallelGCThreads=8"\
# Liferay settings
    FG_LIFERAY_PROXYPATH="/liferay"

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
            wget\
            ca-certificates\
            sudo\
            git\
            mysql-client\
            mlocate\
            vim\
            gnupg\
            build-essential\
            locales\
            jq &&\
   #sudo echo "$FG_USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers &&\
    apt-get clean &&\
    rm -rf /var/lib/apt/lists/* &&\
    locale-gen en_US.UTF-8 &&\
    curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash - &&\
    apt-get install -y nodejs &&\
    npm install -g yo gulp &&\
    echo "portal.proxy.path=$FG_LIFERAY_PROXYPATH" >> /opt/liferay/etc/portal.properties &&\
    echo "default.logout.page.path=$FG_LIFERAY_PROXYPATH/web/guest/home" >> /var/lib/tomcat8/webapps/ROOT/WEB-INF/classes/portal-ext.properties &&\
    echo "default.landing.page.path=$FG_LIFERAY_PROXYPATH/web/guest/home" >> /var/lib/tomcat8/webapps/ROOT/WEB-INF/classes/portal-ext.properties &&\
   #echo "company.default.home.url=$FG_LIFERAY_PROXYPATH/web/guest/home" >> /var/lib/tomcat8/webapps/ROOT/WEB-INF/classes/portal-ext.properties &&\
    sed -i 's/<Service\ name=\"Catalina\">/<Service\ name=\"Catalina\">\n<Connector\ URIEncoding=\"UTF-8\"\ enableLookups=\"false\"\ port=\"8009\"\ protocol=\"AJP\/1.3\"\ redirectPort=\"8443\"\/>/' /etc/tomcat8/server.xml &&\
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
    cp fgSetup/scripts/fgliferay .fgprofile/fgliferay &&\
# Configure scripts fgdb
    ESC_FG_DIR=$(echo $FG_DIR | sed 's/\//\\\//g') &&\
    sed -i "s/^export FGLOCATION.*/export FGLOCATION=$ESC_FG_DIR/" .fgprofile/fgdb &&\
    sed -i "s/.*FGDB_HOST.*/export FGDB_HOST=$FGDB_HOST/" .fgprofile/fgdb &&\
    sed -i "s/.*FGDB_PORT.*/export FGDB_PORT=$FGDB_PORT/" .fgprofile/fgdb &&\
    sed -i "s/.*FGDB_USER.*/export FGDB_USER=$FGDB_USER/" .fgprofile/fgdb &&\
    sed -i "s/.*FGDB_PASSWD.*/export FGDB_PASSWD=$FGDB_PASSWD/" .fgprofile/fgdb &&\
    sed -i "s/.*FGDB_NAME.*/export FGDB_NAME=$FGDB_NAME/" .fgprofile/fgdb &&\
    sed -i "s/.*ASDB_OPTS.*/export ASDB_OPTS=''/" .fgprofile/fgdb &&\
    sed -i "s/.*FGDB_ROOTPWD.*/export FGDB_ROOTPWD=$MYSQL_ROOT_PASSWORD/" .fgprofile/fgdb &&\
# Configure scripts fgliferay
    sed -i "s/^export FGLOCATION.*/export FGLOCATION=$ESC_FG_DIR/" .fgprofile/fgliferay &&\
    sed -i "s/^export LRDB_HOST.*/export LRDB_HOST=$DB_HOST/" .fgprofile/fgliferay &&\
    sed -i "s/^export LRDB_PORT.*/export LRDB_PORT=$DB_PORT/" .fgprofile/fgliferay &&\
    sed -i "s/^export LRDB_USER.*/export LRDB_USER=$DB_USER/" .fgprofile/fgliferay &&\
    sed -i "s/^export LRDB_PASSWD.*/export LRDB_PASSWD=$DB_PASSWORD/" .fgprofile/fgliferay &&\
    sed -i "s/^export LRDB_NAME.*/export LRDB_NAME=$DB_SCHEMA/" .fgprofile/fgliferay &&\
    sed -i "s/^export LRDB_OPTS.*/export LRDB_OPTS=''/" .fgprofile/fgliferay &&\
    sed -i "s/^export LRDB_ROOTPWD.*/export LRDB_ROOTPWD=$MYSQL_ROOT_PASSWORD/" .fgprofile/fgliferay &&\
    cat .fgprofile/fgliferay

#
# Additional setup for Executor Interfaces
#

# Grid and Cloud Engine UsersTracking database
RUN sed -i "s/.*UTDB_HOST.*/export UTDB_HOST=$UTDB_HOST/" .fgprofile/ei_gridengine &&\
    sed -i "s/.*UTDB_PORT.*/export UTDB_PORT=$UTDB_PORT/" .fgprofile/ei_gridengine &&\
#    sed -i "s/.*UTDB_USER.*/export UTDB_USER=$UTDB_USER/" .fgprofile/ei_gridengine &&\
#    sed -i "s/.*UTDB_PASSWD.*/export UTDB_PASSWD=$UTDB_PASSWD/" .fgprofile/ei_gridengine &&\
#    sed -i "s/.*UTDB_NAME.*/export UTDB_NAME=$UTDB_NAME/" .fgprofile/ei_gridengine &&\
    sed -i "s/.*UTDB_OPTS.*/export UTDB_OPTS=''/" .fgprofile/ei_gridengine

# Expose liferay 8080 and 11311 ports
EXPOSE 8080

# Prepare for final execution 
USER root
WORKDIR $FG_DIR

