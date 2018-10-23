#
#  sshnode Docker container makefile
#
# Please ensure that Makefile environment variables are matching
# values defined inside Dockerfile
# 
# Author: Riccardo Bruno (INFN) <riccardo.bruno@ct.infn.it>
#
DOCKER_REPO = futuregateway
IMAGE_NAME = sshnode
IMAGE_TAG = 0.1
FG_NETWORK = fgnetwork

default:
	@echo "Usage: make <image|pubimg>"
	@echo "     image - Build the image: $(DOCKER_REPO)/$(IMAGE_NAME):latest"
	@echo "       run - Create container from image : $(DOCKER_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)"
	@echo "             having name: $(IMAGE_NAME)_$(IMAGE_TAG)" 
	@echo "   publish - Publish images: $(DOCKER_REPO)/$(IMAGE_NAME):latest"
	@echo "                             $(DOCKER_REPO)/$(IMAGE_NAME):$(IMAGE:_TAG)"
	@echo "             on the Docker-hub"
	@echo ""

image: Dockerfile
	docker build --no-cache  -t $(DOCKER_REPO)/$(IMAGE_NAME):latest .
	docker tag $(DOCKER_REPO)/$(IMAGE_NAME):latest $(DOCKER_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)

publish: image 
	docker push $(DOCKER_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)
	docker push $(DOCKER_REPO)/$(IMAGE_NAME):latest

network:
	@[ "$(shell docker network list | grep $(FG_NETWORK))" = "" ]\
                && docker network create $(FG_NETWORK)\
                || echo "Network $(FG_NETWORK) already running"

apiserverdaemon:
	@ASD_CONTAINER=`docker ps -aqf name=apiserverdaemon` &&\
	echo $$ASD_CONTAINER &&\
	[ "`docker ps -aqf name=apiserverdaemon`" != "" ] &&\
            docker exec  $$ASD_CONTAINER\
	    /bin/bash -c 'echo "Host $(IMAGE_NAME)">>/etc/ssh/ssh_config &&\
	                  echo "    StrictHostKeyChecking no">>/etc/ssh/ssh_config &&\
			  echo "    UserKnownHostsFile=/dev/null">>/etc/ssh/ssh_config'\
	|| echo "APIServerDaemon is not running"

run: network apiserverdaemon
	@FGDB_IP=`docker network inspect fgnetwork|\
                jq '.[].Containers[]|select(.Name|contains("fgdb"))|.IPv4Address'|\
                xargs echo| sed 's/\// /' | awk '{ print $$1 }'` &&\
        [ "$$FGDB_IP" != "" ] &&\
          echo "fgdb IP: $$FGDB_IP" &&\
	  docker run -d\
               --net $(FG_NETWORK)\
               --name $(IMAGE_NAME)_$(IMAGE_TAG)\
               -h $(IMAGE_NAME) \
               --add-host "fgdb:$$FGDB_IP"\
               $(DOCKER_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)||\
        echo "Sorry, FGDB node is not running!"

