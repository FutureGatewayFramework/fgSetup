# OS
FROM tomcat:7

# Maintainer
MAINTAINER Riccardo Bruno <riccardo.bruno@ct.infn.it>

# Environment
ENV FG_USER=futuregateway\
    FG_DIR=/home/futuregateway\
    MYSQL_HOST=fgdb\
    MYSQL_PORT=3306\
    MYSQL_USER=fgapiserver\
    MYSQL_PASSWORD=fgapiserver_password\
    MYSQL_DATABASE=fgapiserver\
    FGASD_GIT=https://github.com/FutureGatewayFramework/APIServerDaemon.git\
    FGASD_BRANCH=py2py3\
    TOMCAT_USER=tomcat\
    TOMCAT_PASSWORD=tomcat__pass\
    FGAPISRV_IOSANDBOX=/app/fgiosandbox\
# Environment for scripts
    FGSETUP_GIT=https://github.com/FutureGatewayFramework/fgSetup.git\
    FGSETUP_BRANCH=py2py3\
# Environment for fgdb
    MYSQL_ROOT_PASSWORD=rpass\
    FGDB_HOST=fgdb\
    FGDB_PORT=3306\
    FGDB_USER=fgapiserver\
    FGDB_PASSWD=fgapiserver_password\
    FGDB_NAME=fgapiserver\
# Executor Interfaces environment
    UTDB_HOST=fgdb\
    UTDB_PORT=3306\
    UTDB_USER=tracking_user\
    UTDB_PASSWORD=usertracking\
    UTDB_DATABASE=userstracking\
    GNCENG_ADP_ROCCI=https://github.com/csgf/jsaga-adaptor-rocci.git\
    GNCENG_ADP_ROCCI_BRANCH=master\
    GNCENG=https://github.com/csgf/grid-and-cloud-engine.git\
    GNCENG_BRANCH=FutureGateway\
    PTV_HSTPRT=fgapiserver:8889

# FG User creation and packages installation
RUN adduser --disabled-password --gecos "" $FG_USER &&\
    chown -R $FG_USER:$FG_USER $FG_DIR &&\
    apt-get update &&\
    apt-get install\
            -y\
            --no-install-recommends\
            openssh-client\
            openjdk-7-jdk\
            ant\
            mysql-client\
            libmysql-java\
            procps\
            sudo\
            git\
            mlocate\
            vim\
            locales &&\
    locale-gen en_US.UTF-8 &&\
    echo "$FG_USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers &&\
    apt-get clean &&\
    rm -rf /var/lib/apt/lists/* &&\
    mkdir -p $FGAPISRV_IOSANDBOX &&\
    chown -R root:futuregateway $FGAPISRV_IOSANDBOX &&\ 
    chown -R root:futuregateway $CATALINA_HOME &&\
    chmod -R g+r+w $CATALINA_HOME &&\
    echo "for f in \$(find $FG_DIR/.fgprofile -type f); do source \$f; done # FGLOADENV" >> /etc/profile.d/fg_profile.sh

# Setup Tomcat mgr user and roles
RUN mv $CATALINA_HOME/conf/tomcat-users.xml $CATALINA_HOME/conf/tomcat-users.xml_orig &&\
    LN=$(cat $CATALINA_HOME/conf/tomcat-users.xml_orig | grep -n "</tomcat-users>" | awk -F":" '{ print $1 }') &&\
    ALN=$(cat $CATALINA_HOME/conf/tomcat-users.xml_orig | wc -l) &&\
    cat $CATALINA_HOME/conf/tomcat-users.xml_orig | head -n $((LN-1)) > $CATALINA_HOME/conf/tomcat-users.xml &&\
    echo "                 <role rolename=\"manager-gui\"/>" >> $CATALINA_HOME/conf/tomcat-users.xml &&\
    echo "                 <role rolename=\"manager-script\"/>" >> $CATALINA_HOME/conf/tomcat-users.xml &&\
    echo "                 <role rolename=\"tomcat\"/>" >> $CATALINA_HOME/conf/tomcat-users.xml &&\
    echo "                 <role rolename=\"liferay\"/>" >> $CATALINA_HOME/conf/tomcat-users.xml &&\
    echo "                 <user username=\"$TOMCAT_USER\" password=\"$TOMCAT_PASSWORD\" roles=\"tomcat,liferay,manager-gui,manager-script\"/>" >> $CATALINA_HOME/conf/tomcat-users.xml &&\
    cat $CATALINA_HOME/conf/tomcat-users.xml_orig | tail -n $((ALN-LN+1)) >> $CATALINA_HOME/conf/tomcat-users.xml &&\
    echo "tomcat-users.xml" &&\
    cat $CATALINA_HOME/conf/tomcat-users.xml

# mysql-connector library
RUN updatedb && MYSQL_CONNECTOR=$(locate mysql-connector-java.jar) &&\
    cd $CATALINA_HOME/lib && ln -s $MYSQL_CONNECTOR mysql-connector-java.jar

# User and working directory
USER $FG_USER
WORKDIR $FG_DIR

# Getting FG repo and setup properties files
RUN git clone $FGASD_GIT -b $FGASD_BRANCH &&\
    sed -i "s/apisrv_dbhost\ =\ localhost/apisrv_dbhost\ =\ $FGDB_HOST/"\
        APIServerDaemon/web/WEB-INF/classes/it/infn/ct/APIServerDaemon.properties &&\
    sed -i "s/utdb_host\ =\ localhost/utdb_host\ =\ $FGDB_HOST/"\
         APIServerDaemon/web/WEB-INF/classes/it/infn/ct/APIServerDaemon.properties &&\
    sed -i "s/apisrv_dbhost\ =\ localhost/apisrv_dbhost\ =\ $FGDB_HOST/"\
        APIServerDaemon/web/WEB-INF/classes/it/infn/ct/GridEngineDaemon.properties &&\
    sed -i "s/utdb_host\ =\ localhost/utdb_host\ =\ $FGDB_HOST/"\
         APIServerDaemon/web/WEB-INF/classes/it/infn/ct/GridEngineDaemon.properties &&\
    sed -i "s/localhost:8888/$PTV_HSTPRT/"\
        APIServerDaemon/web/WEB-INF/classes/it/infn/ct/ToscaIDC.properties &&\
    sed -i "s/localhost:8889\\/get-token/$PTV_HSTPRT\\/get-token/"\
         APIServerDaemon/web/WEB-INF/classes/it/infn/ct/ToscaIDC.properties &&\
	 sed -i "s/localhost:/$FGDB_HOST:/"\
           APIServerDaemon/web/META-INF/context.xml &&\
    mkdir -p APIServerDaemon/work/WEB-INF/classes/it/infn/ct

#
# Executor Interfaces
#

# GridnCloud Engine Executor Interface
RUN sudo apt-get update &&\
    sudo apt-get install -y --no-install-recommends maven &&\
    sudo apt-get clean
# JSAGA rOCCI adaptor
RUN git clone $GNCENG_ADP_ROCCI -b $GNCENG_ADP_ROCCI_BRANCH
RUN cd jsaga-adaptor-rocci && ant all &&\
    mkdir -p ../APIServerDaemon/lib &&\
    cp dist/jsaga-adaptor-rocci.jar \
       ../APIServerDaemon/lib/jsaga-adaptor-rocci.jar
# GridnCloud Engine
RUN git clone $GNCENG -b $GNCENG_BRANCH &&\
    cd grid-and-cloud-engine/grid-and-cloud-engine_M &&\
    sed -i "s/localhost/$FGDB_HOST:$FGDB_PORT/"\
           src/main/resources/hibernateStandAlone.cfg.xml &&\
#    sed -i "s/jdbc:mysql:\/\/localhost/jdbc:mysql:\/\/$FGDB_HOST/g"\
#           src/main/resources/hibernate.cfg.xml &&\
#    sed -i "s/jdbc:mysql:\/\/localhost/jdbc:mysql:\/\/$FGDB_HOST/g"\
#           src/main/java/it/infn/ct/GridEngine/JobCollection/JobCollectionSubmission.java &&\
#    sed -i "s/jdbc:mysql:\/\/localhost/jdbc:mysql:\/\/$FGDB_HOST/g"\
#           src/main/java/it/infn/ct/GridEngine/Job/MultiInfrastructureJobSubmission.java &&\
#    sed -i "s/jdbc:mysql:\/\/localhost/jdbc:mysql:\/\/$FGDB_HOST/g"\
#           src/main/java/it/infn/ct/GridEngine/Job/JSagaJobSubmission.java &&\
#    sed -i "s/jdbc:mysql:\/\/localhost/jdbc:mysql:\/\/$FGDB_HOST/g"\
#           src/main/java/it/infn/ct/GridEngine/UsersTracking/UsersTrackingDBInterface.java &&\
    cd -

RUN cd grid-and-cloud-engine/grid-and-cloud-engine-threadpool &&\
    #mvn clean install -Dmaven.compiler.source=1.6 -Dmaven.compiler.target=1.6 &&\
    mvn install &&\
    cp target/grid-and-cloud-engine-threadpool-0.0.1-SNAPSHOT.jar \
       ../../APIServerDaemon/lib/grid-and-cloud-engine-threadpool-0.0.1-SNAPSHOT.jar &&\
    cp target/lib/*.jar ../../APIServerDaemon/lib/
RUN cd grid-and-cloud-engine/grid-and-cloud-engine_M &&\
    #mvn clean install -Dmaven.compiler.source=1.6 -Dmaven.compiler.target=1.6 &&\
    mvn install &&\
    cp target/grid-and-cloud-engine_M-0.0.1-SNAPSHOT.jar \
       ../../APIServerDaemon/lib/grid-and-cloud-engine_M-0.0.1-SNAPSHOT.jar &&\
    cp target/lib/*.jar ../../APIServerDaemon/lib/

# Setup Tomcat' connection pools for UsersTracking
RUN sudo chmod 644 $CATALINA_HOME/conf/server.xml &&\
    sudo chmod g+x /usr/local/tomcat/conf &&\
    mv $CATALINA_HOME/conf/server.xml $CATALINA_HOME/conf/server.xml_orig &&\
    LN=$(cat $CATALINA_HOME/conf/server.xml_orig | grep -n "</GlobalNamingResources>" | awk -F":" '{ print $1 }') &&\
    ALN=$(cat $CATALINA_HOME/conf/server.xml_orig | wc -l) &&\
    cat $CATALINA_HOME/conf/server.xml_orig | head -n $((LN-1)) > $CATALINA_HOME/conf/server.xml &&\
    echo "               <Resource name=\"jdbc/UserTrackingPool\"" >> $CATALINA_HOME/conf/server.xml &&\
    echo "                           auth=\"Container\"" >> $CATALINA_HOME/conf/server.xml &&\
    echo "                           type=\"javax.sql.DataSource\"" >> $CATALINA_HOME/conf/server.xml &&\
    echo "                           username=\"$UTDB_USER\"" >> $CATALINA_HOME/conf/server.xml &&\
    echo "                           password=\"$UTDB_PASSWORD\"" >> $CATALINA_HOME/conf/server.xml &&\
    echo "                           driverClassName=\"com.mysql.jdbc.Driver\"" >> $CATALINA_HOME/conf/server.xml &&\
    echo "                           url=\"jdbc:mysql://$UTDB_HOST:$UTDB_PORT/$UTDB_DATABASE\"" >> $CATALINA_HOME/conf/server.xml &&\
    echo "                           testOnBorrow=\"true\"" >> $CATALINA_HOME/conf/server.xml &&\
    echo "                           testWhileIdle=\"true\"" >> $CATALINA_HOME/conf/server.xml &&\
    echo "                           validationInterval=\"0\"" >> $CATALINA_HOME/conf/server.xml &&\
    echo "                           initialSize=\"3\"" >> $CATALINA_HOME/conf/server.xml &&\
    echo "                           maxTotal=\"100\"" >> $CATALINA_HOME/conf/server.xml &&\
    echo "                           maxIdle=\"30\"" >> $CATALINA_HOME/conf/server.xml &&\
    echo "                           maxWaitMillis=\"10000\"" >> $CATALINA_HOME/conf/server.xml &&\
    echo "                           validationQuery=\"select 1 as connection_test\"/>" >> $CATALINA_HOME/conf/server.xml &&\
    echo "                 <Resource name=\"jdbc/gehibernatepool\"" >> $CATALINA_HOME/conf/server.xml &&\
    echo "                           auth=\"Container\"" >> $CATALINA_HOME/conf/server.xml &&\
    echo "                           type=\"javax.sql.DataSource\"" >> $CATALINA_HOME/conf/server.xml &&\
    echo "                           username=\"$UTDB_USER\"" >> $CATALINA_HOME/conf/server.xml &&\
    echo "                           password=\"$UTDB_PASSWORD\"" >> $CATALINA_HOME/conf/server.xml &&\
    echo "                           driverClassName=\"com.mysql.jdbc.Driver\"" >> $CATALINA_HOME/conf/server.xml &&\
    echo "                           url=\"jdbc:mysql://$UTDB_HOST:$UTDB_PORT/$UTDB_DATABASE\"" >> $CATALINA_HOME/conf/server.xml &&\
    echo "                           testOnBorrow=\"true\"" >> $CATALINA_HOME/conf/server.xml &&\
    echo "                           testWhileIdle=\"true\"" >> $CATALINA_HOME/conf/server.xml &&\
    echo "                           validationInterval=\"0\"" >> $CATALINA_HOME/conf/server.xml &&\
    echo "                           initialSize=\"3\"" >> $CATALINA_HOME/conf/server.xml &&\
    echo "                           maxTotal=\"100\"" >> $CATALINA_HOME/conf/server.xml &&\
    echo "                           maxIdle=\"30\"" >> $CATALINA_HOME/conf/server.xml &&\
    echo "                           maxWaitMillis=\"10000\"" >> $CATALINA_HOME/conf/server.xml &&\
    echo "                           validationQuery=\"select 1 as connection_test\"/>" >> $CATALINA_HOME/conf/server.xml &&\
    cat $CATALINA_HOME/conf/server.xml_orig | tail -n $((ALN-LN+1)) >> $CATALINA_HOME/conf/server.xml &&\
    echo "server.xml" &&\
    cat $CATALINA_HOME/conf/server.xml

# FutureGateway scripts
RUN git clone $FGSETUP_GIT -b $FGSETUP_BRANCH &&\
    mkdir -p .fgprofile &&\
    cp fgSetup/scripts/commons .fgprofile/commons &&\
    cp fgSetup/scripts/fgdb .fgprofile/fgdb &&\
    cp fgSetup/scripts/fgapiserver .fgprofile/fgapiserver &&\
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
    sed -i "s/^export FGDB_ROOTPWD.*/export FGDB_ROOTPWD=$MYSQL_ROOT_PASSWORD/" .fgprofile/fgdb &&\
# Configuring scripts ei_gridengine
    sed -i "s/^export UTDB_HOST.*/export UTDB_HOST=$UTDB_HOST/" .fgprofile/ei_gridengine &&\
    sed -i "s/^export UTDB_PORT.*/export UTDB_PORT=$UTDB_PORT/" .fgprofile/ei_gridengine &&\
#    sed -i "s/^export UTDB_USER.*/export UTDB_USER=$UTDB_USER/" .fgprofile/ei_gridengine &&\
#    sed -i "s/^export UTDB_PASSWD.*/export UTDB_PASSWD=$UTDB_PASSWD/" .fgprofile/ei_gridengine &&\
#    sed -i "s/^export UTDB_NAME.*/export UTDB_NAME=$UTDB_NAME/" .fgprofile/ei_gridengine &&\
    sed -i "s/^export UTDB_OPTS.*/export UTDB_OPTS=''/" .fgprofile/ei_gridengine &&\
    cat .fgprofile/fgdb && cat .fgprofile/ei_gridengine

#
# Build APIServerDaemon WAR
#
RUN cd APIServerDaemon &&\
    mvn install &&\
    cp target/APIServerDaemon.war $CATALINA_HOME/webapps

# nginx port 80 available to the world outside this container
EXPOSE 8080

# Back to the root user, load the environment and place  APIServerDaemon webapp
#USER root 
#RUN cp /home/$FG_USER/APIServerDaemon/dist/APIServerDaemon.war $CATALINA_HOME/webapps/

