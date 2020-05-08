#
# FG test  Docker container makefile
#
# Please ensure that Makefile environment variables are matching
# values defined inside Dockerfile
# 
# Author: Riccardo Bruno (INFN) <riccardo.bruno@ct.infn.it>
#
DOCKER_REPO = futuregateway
IMAGE_NAME = fgtest
IMAGE_TAG = 0.2
WSGI_PORT = 80
APISRV_PORT = 8888
PTV_PORT = 8889
MYSQL_PORT = 3306
LIFERAY_IMAGE = esystemstech/liferay:7.1.2-ga3
LIFERAY_DEVUSER = liferaydev
FGLIFERAY_VOLUME = fgliferay_volume
FGNETWORK=fgtest_network

default:
	@echo "Usage: make <recipe>"
	@echo "         image - Build the image: $(DOCKER_REPO)/$(IMAGE_NAME):latest"
	@echo "           run - Create container from image : $(DOCKER_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)"
	@echo "                 having name: $(IMAGE_NAME)_$(IMAGE_TAG)"
	@echo "          test - Start the test procedure"
	@echo "       publish - Publish images: $(DOCKER_REPO)/$(IMAGE_NAME):latest"
	@echo "                                  $(DOCKER_REPO)/$(IMAGE_NAME):$(IMAGE:_TAG)"
	@echo "                  on the Docker-hub"
	@echo "          conn  - Open a terminal into the server"
	@echo "          list  - Show the docker id of the running server"
	@echo "          start - Starts the container and its services after a container stop"
	@echo "          logs  - Show the server logs"
	@echo "          kill  - Terminate the server execution keeping the volume"
	@echo "GUI testing:"
	@echo "        liferay - Create the liferay instance for GUI testing"
	@echo "   liferay_logs - Show liferay logs"
	@echo " liferay_srvlog - Show Liferay server logs (until rotating)"
	@echo "   kill_liferay - Remove liferay instance"
	@echo "  start_liferay - Start the liferay intance after a container stop"
	@echo "     liferaydev - Prepares the Liferay SDK environment, it requires SDKPATH var"
	@echo "     liferaysdk - Execute the SKD isntallation"
	@echo "liferaydev_conn - Enter the liferay development environment"
	@echo ""
	@echo "Options:"
	@echo "        nocache - When set builds the image not using cached images"
	@echo "  noprompt - Do not prompt for confirmation on dangerous targets"
	@echo ""

image: Dockerfile
ifdef nocache
	docker build --no-cache -t $(DOCKER_REPO)/$(IMAGE_NAME):latest .
else
	docker build -t $(DOCKER_REPO)/$(IMAGE_NAME):latest .
endif
	docker tag $(DOCKER_REPO)/$(IMAGE_NAME):latest $(DOCKER_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)

publish: image 
	docker push $(DOCKER_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)
	docker push $(DOCKER_REPO)/$(IMAGE_NAME):latest

network:
	docker network create $(FGNETWORK)

run: network
	docker run -d\
                --net=$(FGNETWORK)\
                --name $(IMAGE_NAME)_$(IMAGE_TAG)\
                -h $(IMAGE_NAME) \
                -p80:$(WSGI_PORT)\
                -p8888:$(APISRV_PORT)\
                -p8889:$(PTV_PORT)\
                -p3306:$(MYSQL_PORT)\
                $(DOCKER_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)

test:
	CNT=`docker ps -a | grep $(IMAGE_NAME)_$(IMAGE_TAG) | awk '{ print $$1 }'` &&\
  [ "$$CNT" != "" ] &&\
    docker exec -ti $(IMAGE_NAME)_$(IMAGE_TAG) /bin/bash ./do_tests.sh ||\
    echo "Unable to start tests, the container $(IMAGE_NAME)_$(IMAGE_TAG) is not running"

liferaydb:
	@[ ! -f fgliferay.sql ] &&\
      echo "drop user if exists liferay;" > fgliferay.sql &&\
      echo "drop database if exists lportal;" >> fgliferay.sql &&\
      echo "create user \"liferay\" identified by \"liferay\";" >> fgliferay.sql &&\
      echo "create database lportal character set UTF8mb4 collate utf8mb4_bin;" >> fgliferay.sql &&\
      echo "grant all privileges on lportal.* TO \"liferay\"@\"localhost\" IDENTIFIED BY \"liferay\";" >> fgliferay.sql &&\
      echo "grant all privileges on lportal.* TO \"liferay\"@\"%\" IDENTIFIED BY \"liferay\";" >> fgliferay.sql &&\
      echo "flush privileges" >> fgliferay.sql ||\
      echo "fgliferay.sql file already exits"


liferay: liferaydb
	CNT=`docker ps -a | grep $(IMAGE_NAME)_$(IMAGE_TAG) | awk '{ print $$1 }'` &&\
  LIFERAY_CNT=`docker ps -a | grep fgliferay | awk '{ print $$1 }'` &&\
  [ "$$LIFERAY_CNT" == "" -a\
    "$$CNT" != "" ] &&\
    docker cp fgliferay.sql $(IMAGE_NAME)_$(IMAGE_TAG):/home/fgtest/fgliferay.sql &&\
    docker exec -ti  $(IMAGE_NAME)_$(IMAGE_TAG) /bin/bash --login -c "asdbr < fgliferay.sql" &&\
    rm fgliferay.sql &&\
    docker volume create $(FGLIFERAY_VOLUME) &&\
    docker run -d\
               --net=$(FGNETWORK)\
               --name fgliferay\
               -h fgliferay\
               -p 8080:8080\
               -e DB_HOST=$(IMAGE_NAME)_$(IMAGE_TAG)\
               -e DB_SCHEMA=lportal\
               -e DB_USER=liferay\
               -e DB_PASSWORD=liferay\
               -e JAVA_OPTS="$$JAVA_OPTS\
                             -XX:+UseG1GC\
                             -Xms1024m\
                             -Xmx1024m"\
               -e JDK_JAVA_OPTIONS="$$JDK_JAVA_OPTIONS\
                                   --add-opens=java.base/java.io=ALL-UNNAMED\
                                   --add-opens=java.base/java.lang=ALL-UNNAMED\
                                   --add-opens=java.base/java.lang.reflect=ALL-UNNAMED\
                                   --add-opens=java.base/java.net=ALL-UNNAMED\
                                   --add-opens=java.base/java.nio=ALL-UNNAMED\
                                   --add-opens=java.base/java.text=ALL-UNNAMED\
                                   --add-opens=java.base/java.util=ALL-UNNAMED\
                                   --add-opens=java.base/sun.nio.ch=ALL-UNNAMED\
                                   --add-opens=java.rmi/sun.rmi.transport=ALL-UNNAMED"\
               -v $(FGLIFERAY_VOLUME)/opt/liferay/home/data\
               $(LIFERAY_IMAGE) ||\
    echo "Cannot start liferay instance (LIFERAY_CNT=\"$$LIFERAY_CNT\" must be empty) (CNT=\"$$CNT\" must be not empty)"

liferay_logs:
	CNT=`docker ps -a | grep fgliferay | awk '{ print $$1 }'` &&\
  [ "$$CNT" != "" ] &&\
    docker logs --follow $$CNT ||\
    echo "Unable get logs for container fgliferay"

liferay_conn:
	CNT=`docker ps -a | grep fgliferay | awk '{ print $$1 }'` &&\
  [ "$$CNT" != "" ] &&\
    docker exec -ti fgliferay /bin/bash --login ||\
    echo "Container fgliferay is not running"

liferay_start:
	CNT=`docker ps -a | grep fgliferay | awk '{ print $$1 }'` &&\
  [ "$$CNT" != "" ] &&\
    docker start fgliferay ||\
    echo "Container fgliferay does not exists"

liferay_srvlog:
	CNT=`docker ps -a | grep fgliferay | awk '{ print $$1 }'` &&\
  [ "$$CNT" != "" ] &&\
    docker exec -ti fgliferay /bin/bash --login -c "tail -f \$$(ls -1rt /opt/liferay/home/logs/localhost.*.log | tail -n 1)" ||\
    echo "Container fgliferay is not running"

liferaydev:
	[ -f $$SDKPATH ] &&\
      (CNT=`docker ps -a | grep fgliferay | awk '{ print $$1 }'` &&\
       [ "$$CNT" != "" ] &&\
        (DEVUSER=$(LIFERAY_DEVUSER) &&\
         SDKFILE=`basename $$SDKPATH` &&\
         docker cp $$SDKPATH fgliferay:/opt/liferay/home/ &&\
         docker exec -ti fgliferay /bin/bash --login -c "apt update; apt install -y vim gradle git iputils-ping" &&\
         docker exec -ti fgliferay chmod +x /opt/liferay/home/$$SDKFILE &&\
         docker exec -ti fgliferay useradd $$DEVUSER -m -s /bin/bash &&\
         docker exec -ti fgliferay usermod -aG tomcat $$DEVUSER &&\
         docker exec -ti fgliferay chmod -R g+w /opt/liferay &&\
         docker exec -ti fgliferay mv $$SDKFILE /home/$$DEVUSER &&\
         docker exec -ti fgliferay chown $$DEVUSER:$$DEVUSER /home/$$DEVUSER/$$SDKFILE &&\
         docker exec -ti $(IMAGE_NAME)_$(IMAGE_TAG) /bin/bash --login -c "asdb delete from fg_user_group where user_id=2;" &&\
         docker exec -ti $(IMAGE_NAME)_$(IMAGE_TAG) /bin/bash --login -c "asdb delete from fg_user where id=2;" &&\
         docker exec -ti $(IMAGE_NAME)_$(IMAGE_TAG) /bin/bash --login -c "asdb update srv_config set value=False where name='fgapisrv_lnkptvflag';" &&\
         docker exec -ti fgliferay /bin/bash --login -c "echo \"\$(ping -c 1 \$DB_HOST | head -n 1 | awk '{ print substr(\$3,2,length(\$3)-2); }') fgtest\" >> /etc/hosts"||\
         echo "Unable prepare liferay development environment";) ||\
       echo "Container fgliferay does not exists";) ||\
    echo "No SDKPATH variable specified"

liferaysdk:
	[ -f $$SDKPATH ] &&\
      (SDKFILE=`basename $$SDKPATH` &&\
       CNT=`docker ps -a | grep fgliferay | awk '{ print $$1 }'` &&\
       [ "$$CNT" != "" ] &&\
         (DEVUSER=$(LIFERAY_DEVUSER) &&\
          docker exec -ti fgliferay su - $$DEVUSER -c "./$$SDKFILE" ||\
          echo "Unable to start the Liferay SDK setup";) ||\
       echo "Container fgliferay is not running";) ||\
    echo "No SDKPATH variable specified"

liferaydev_conn:
	CNT=`docker ps -a | grep fgliferay | awk '{ print $$1 }'` &&\
  [ "$$CNT" != "" ] &&\
    DEVUSER=$(LIFERAY_DEVUSER) &&\
    docker exec -ti fgliferay /bin/bash --login -c "su - $$DEVUSER; exit" ||\
    echo "Container fgliferay is not running"

conn:
	CNT=`docker ps -a | grep $(IMAGE_NAME)_$(IMAGE_TAG) | awk '{ print $$1 }'` &&\
  [ "$$CNT" != "" ] &&\
    docker exec -ti $(IMAGE_NAME)_$(IMAGE_TAG) /bin/bash --login ||\
    echo "Container $(IMAGE_NAME)_$(IMAGE_TAG) is not running"

logs:
	CNT=`docker ps -a | grep $(IMAGE_NAME)_$(IMAGE_TAG) | awk '{ print $$1 }'` &&\
  [ "$$CNT" != "" ] &&\
    docker logs --follow $$CNT ||\
    echo "Unable get logs for container $(IMAGE_NAME)_$(IMAGE_TAG)"

start:
	CNT=`docker ps -a | grep $(IMAGE_NAME)_$(IMAGE_TAG) | awk '{ print $$1 }'` &&\
    [ "$$CNT" != "" ] &&\
      docker start $(IMAGE_NAME)_$(IMAGE_TAG) &&\
      docker exec -ti $(IMAGE_NAME)_$(IMAGE_TAG) --login -c "sudo service mysql start" &&\
      docker exec -ti $(IMAGE_NAME)_$(IMAGE_TAG) --login -c "sudo service apache2 start" &&\
      docker exec -ti $(IMAGE_NAME)_$(IMAGE_TAG) --login -c "sudo /usr/share/tomcat9/bin/catalina.sh start" ||\
      echo "Container $(IMAGE_NAME)_$(IMAGE_TAG) does not exists"

confirm:
ifdef noprompt
	echo "Operation forced by noprompt option"
else
	@read -r -p "Are you sure? [y/N] " RES &&\
  [ "$$RES" = "y" -o "$$RES" = "Y" ] ||\
    { echo "Operation cancelled"; exit 1; }
endif

kill_fgtest: confirm
	CNT=`docker ps -a | grep $(IMAGE_NAME)_$(IMAGE_TAG) | awk '{ print $$1 }'` &&\
    [ "$$CNT" != "" ] &&\
      docker stop $$CNT &&\
      docker rm $$CNT ||\
      echo "Error killing container: $(IMAGE_NAME)_$(IMAGE_TAG)"

kill_liferay: confirm
	CNT=`docker ps -a | grep fgliferay | awk '{ print $$1 }'` &&\
    [ "$$CNT" != "" ] &&\
      docker stop $$CNT &&\
      docker rm $$CNT &&\
      docker volume rm $(FGLIFERAY_VOLUME) ||\
      echo "Error killing container: fgliferay"

kill_all: kill_liferay kill_fgtest
	@echo "Overall kill operation finished"

list:
	CNTINFO=`docker ps -a | grep $(IMAGE_NAME)_$(IMAGE_TAG)` &&\
    [ "$CNTINFO" != "" ] &&\
      echo "$$CNTINFO" ||\
      echo "Container $(IMAGE_NAME)_$(IMAGE_TAG) does not exists"

