#
# fghttpd Docker container makefile
#
# Please ensure that Makefile environment variables are matching
# values defined inside Dockerfile
# 
# Author: Riccardo Bruno (INFN) <riccardo.bruno@ct.infn.it>
#
DOCKER_REPO = futuregateway
IMAGE_NAME = fghttpd
IMAGE_TAG = 0.1
FG_NETWORK = fgnetwork
FG_VOLUMESDIR = $$HOME/fgVolumes
#IMAGE_LATEST_ID = $(shell docker image list | grep $(DOCKER_REPO)/$(IMAGE_NAME) | grep latest | awk '{ print $3 }')
#IMAGE_TAGGED_ID = $(shell docker image list | grep $(DOCKER_REPO)/$(IMAGE_NAME) | grep $(IMAGE_TAG) | awk '{ print $3 }')

default:
	@echo "Usage: make <image|pubimg>"
	@echo "     image - Build the image: $(DOCKER_REPO)/$(IMAGE_NAME):latest"
	@echo "       run - Create container from image : $(DOCKER_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)"
	@echo "             having name: $(IMAGE_NAME)_$(IMAGE_TAG)" 
	@echo "   publish - Publish images: $(DOCKER_REPO)/$(IMAGE_NAME):latest"
	@echo "                             $(DOCKER_REPO)/$(IMAGE_NAME):$(IMAGE:_TAG)"
	@echo "             on the Docker-hub"
	@echo ""
	#@echo "Latest image: $(IMAGE_LATEST_ID)"
	#@echo "Tagged image: $(IMAGE_TAG) - $(IMAGE_TAGGED_ID)"	

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
	@[ "$(shell docker network list | grep $(FG_NETWORK))" = "" ]\
                && docker network create $(FG_NETWORK)\
                || echo "Network $(FG_NETWORK) already running"

shdir:
	@[ -d fgVolumes/apps ] && echo "fgapiserver' apps directory exists"\
                                  || mkdir -p $(FG_VOLUMESDIR)/apps
	@[ -d fgVolumes/iosandbox ] && echo "fgapiserver' iosandbox directory exists"\
                                  || mkdir -p $(FG_VOLUMESDIR)/iosandbox

run: network shdir
	FGDB_IP=`docker network inspect fgnetwork|\
		jq '.[].Containers[]|select(.Name|contains("fgdb"))|.IPv4Address'|\
		xargs echo| sed 's/\// /' | awk '{ print $$1 }'` &&\
	FGTEST_IP=`docker network inspect fgnetwork|\
	        jq '.[].Containers[]|select(.Name|contains("sshnode"))|.IPv4Address'|\
		xargs echo| sed 's/\// /' | awk '{ print $$1 }'` &&\
	FGAPISRV_IP=`docker network inspect fgnetwork|\
                jq '.[].Containers[]|select(.Name|contains("fgapiserver"))|.IPv4Address'|\
                xargs echo| sed 's/\// /' | awk '{ print $$1 }'` &&\
	FGLIFERAY_IP=`docker network inspect fgnetwork|\
                jq '.[].Containers[]|select(.Name|contains("fgliferay"))|.IPv4Address'|\
                xargs echo| sed 's/\// /' | awk '{ print $$1 }'` &&\
        [ "$$FGDB_IP" != "" -a "$$FGAPISRV_IP" != "" ] &&\
        echo "fgdb IP: $$FGDB_IP" &&\
        echo "fgapiserver IP: $$FGAPISRV_IP" &&\
        echo "fgtest IP: $$FGTEST_IP" &&\
        echo "fgliferay IP: $$FGLIFERAY_IP" &&\
        docker run -d\
	    -e FGDB_HOST=$(FG_RUN_NET)\
            --net $(FG_NETWORK)\
            --name $(IMAGE_NAME)_$(IMAGE_TAG)\
            -p80:80\
	    -p443:443\
	    --add-host "fgdb:$$FGDB_IP"\
	    --add-host "fgtest:$$FGTEST_IP"\
	    --add-host "fgapiserver:$$FGAPISRV_IP"\
	    --add-host "fgliferay:$$FGLIFERAY_IP"\
	    -v $$HOME/fgVolumes/apps:/app/apps\
	    -v $$HOME/fgVolumes/iosandbox:/tmp/fgiosandbox\
	    -h httpd\
	    $(DOCKER_REPO)/$(IMAGE_NAME):$(IMAGE_TAG) ||\
        echo "Sorry, one of the nodes FGDB ($$FGDB_IP) or FGAPISRV ($$FGAPISRV_IP) is not running!"
