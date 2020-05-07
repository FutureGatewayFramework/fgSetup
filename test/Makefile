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
LIFERAY_IMAGE = esystemstech/liferay:7.1.2-ga3-9-openjdk-11-jdk-buster-slim
FGLIFERAY_VOLUME = fgliferay_volume
FGNETWORK=fgtest_network

default:
	@echo "Usage: make <recipe>"
	@echo "         image - Build the image: $(DOCKER_REPO)/$(IMAGE_NAME):latest"
	@echo "           run - Create container from image : $(DOCKER_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)"
	@echo "                 having name: $(IMAGE_NAME)_$(IMAGE_TAG)"
	@echo "          test - Start the test procedure"
	@echo "       publish - Publish images: $(DOCKER_REPO)/$(IMAGE_NAME):latest"
	@echo "                                 $(DOCKER_REPO)/$(IMAGE_NAME):$(IMAGE:_TAG)"
	@echo "                 on the Docker-hub"
	@echo "         conn  - Open a terminal into the server"
	@echo "         list  - Show the docker id of the running server"
	@echo "         logs  - Show the server logs"
	@echo "         kill  - Terminate the server execution keeping the volume"
	@echo " GUI testing:"
	@echo "      liferay - Create the liferay instance for GUI testing"
	@echo " liferay_logs - Show liferay logs"
	@echo " kill_liferay - Remove liferay instance"
	@echo ""
	@echo "Options:"
	@echo "   nocache - When set builds the image not using cached images"
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
  [ "$$CNT" != "" ] &&\
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
               $(LIFERAY_IMAGE)

liferay_logs:
	CNT=`docker ps -a | grep fgliferay | awk '{ print $$1 }'` &&\
  [ "$$CNT" != "" ] &&\
    docker logs --follow $$CNT ||\
    echo "Unable get logs for container $(IMAGE_NAME)_$(IMAGE_TAG)"

conn:
	docker exec -ti $(IMAGE_NAME)_$(IMAGE_TAG) /bin/bash --login

logs:
	CNT=`docker ps -a | grep $(IMAGE_NAME)_$(IMAGE_TAG) | awk '{ print $$1 }'` &&\
  [ "$$CNT" != "" ] &&\
    docker logs --follow $$CNT ||\
    echo "Unable get logs for container $(IMAGE_NAME)_$(IMAGE_TAG)"

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

kill_all: confirm
	kill_liferay
	kill_fgtest

list:
	CNTINFO=`docker ps -a | grep $(IMAGE_NAME)_$(IMAGE_TAG)` &&\
    [ "$CNTINFO" != "" ] &&\
      echo "$$CNTINFO" ||\
      echo "Container $(IMAGE_NAME)_$(IMAGE_TAG) does not exists"







