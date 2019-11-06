#
# apiserverdaemon Docker container makefile
#
# Please ensure that Makefile environment variables are matching
# values defined inside Dockerfile
# 
# Author: Riccardo Bruno (INFN) <riccardo.bruno@ct.infn.it>
#
DOCKER_REPO = futuregateway
IMAGE_NAME = apiserverdaemon
IMAGE_TAG = 0.3
FG_NETWORK = fgnetwork_test
FG_APISRVVOLNAME = fg_apiserver_test
FG_APPSDIRVOLNAME = fg_apps_test
FG_IOSNDBXVOLNAME = fg_iosandbox_test
FGAPISRV_IOSANDBOX = /app/fgiosandbox

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

volumes:
	FGIOSBSVOL=`docker volume inspect  $(FG_IOSNDBXVOLNAME) 2>/dev/null | jq '.[].Mountpoint' | xargs echo` &&\
	[ -z "$$FGIOSBSVOL" ] &&\
	       	docker volume create $(FG_IOSNDBXVOLNAME) ||\
                echo "FG apps volume exists at: $$FGIOSBSVOL"

run: network volumes 
	FGDB_IP=`docker network inspect fgnetwork|\
		jq '.[].Containers[]|select(.Name|contains("fgdb"))|.IPv4Address'|\
		xargs echo| sed 's/\// /' | awk '{ print $$1 }'` &&\
	FGTEST_IP=`docker network inspect fgnetwork|\
	        jq '.[].Containers[]|select(.Name|contains("sshnode"))|.IPv4Address'|\
		xargs echo| sed 's/\// /' | awk '{ print $$1 }'` &&\
	FGAPISRV_IP=`docker network inspect fgnetwork|\
                jq '.[].Containers[]|select(.Name|contains("fgapiserver"))|.IPv4Address'|\
                xargs echo| sed 's/\// /' | awk '{ print $$1 }'` &&\
        [ "$$FGDB_IP" != "" -a\
          "$$FGTEST_IP" != "" -a\
	  "$$FGAPISRV_IP" != "" ] &&\
        echo "fgdb IP: $$FGDB_IP" &&\
        docker run -d\
	    -e FGDB_HOST=$(FG_RUN_NET)\
            --net $(FG_NETWORK)\
            --name $(IMAGE_NAME)_$(IMAGE_TAG)\
            -p8088:8080\
	    --add-host "fgdb:$$FGDB_IP"\
	    --add-host "fgtest:$$FGTEST_IP"\
	    --add-host "fgapiserver:$$FGAPISRV_IP"\
	    -v $(FG_IOSNDBXVOLNAME):$(FGAPISRV_IOSANDBOX)\
	    -h apiserverdaemon\
	    $(DOCKER_REPO)/$(IMAGE_NAME):$(IMAGE_TAG) ||\
        echo "Sorry, one of the nodes FGDB ($$FGDB_IP) or FGTEST ($$FGTEST_IP) or FGAPISRV ($$FGAPISRV_IP) is not running!"
