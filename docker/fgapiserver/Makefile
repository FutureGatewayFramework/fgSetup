#
# fgapiserver Docker container makefile
#
# Please ensure that Makefile environment variables are matching
# values defined inside Dockerfile
# 
# Author: Riccardo Bruno (INFN) <riccardo.bruno@ct.infn.it>
#
DOCKER_REPO = futuregateway
IMAGE_NAME = fgapiserver
IMAGE_TAG = 0.2
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
	@echo "   testrun - As above but fgAPIServer code available into volume name: $(FG_APISRVVOLNAME)"
	@echo "   publish - Publish images: $(DOCKER_REPO)/$(IMAGE_NAME):latest"
	@echo "                             $(DOCKER_REPO)/$(IMAGE_NAME):$(IMAGE:_TAG)"
	@echo "             on the Docker-hub"
	@echo ""
	#@echo "Latest image: $(IMAGE_LATEST_ID)"
	#@echo "Tagged image: $(IMAGE_TAG) - $(IMAGE_TAGGED_ID)"	

image: Dockerfile
	docker build -t $(DOCKER_REPO)/$(IMAGE_NAME):latest .
	docker tag $(DOCKER_REPO)/$(IMAGE_NAME):latest $(DOCKER_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)

publish: image 
	docker push $(DOCKER_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)
	docker push $(DOCKER_REPO)/$(IMAGE_NAME):latest

network:
	@[ "$(shell docker network list | grep $(FG_NETWORK))" = "" ]\
	       	&& docker network create $(FG_NETWORK)\
                || echo "Network $(FG_NETWORK) already running"

volumes:
	@FGAPPSVOL=`docker volume inspect  $(FG_APPSDIRVOLNAME) 2>/dev/null | jq '.[].Mountpoint' | xargs echo` &&\
	[ -z "$$FGAPPSVOL" ] &&\
	       	docker volume create $(FG_APPSDIRVOLNAME) ||\
	       	echo "FG apps volume exists at: $$FG_APPSDIRVOL" &&\
	FGIOSBSVOL=`docker volume inspect  $(FG_IOSNDBXVOLNAME) 2>/dev/null | jq '.[].Mountpoint' | xargs echo` &&\
	[ -z "$$FGIOSBSVOL" ] &&\
	       	docker volume create $(FG_IOSNDBXVOLNAME) ||\
                echo "FG apps volume exists at: $$FGIOSBSVOL"

test_volumes:
	@FGAPISRVVOL=`docker volume inspect $(FG_APISRVVOLNAME) 2>/dev/null | jq '.[].Mountpoint' | xargs echo` &&\
	[ -z "$$FGAPISRVVOL" ] &&\
                docker volume create $(FG_APISRVVOLNAME) ||\
                echo "FG apps volume exists at: $$FGAPISRVVOL" &&\
	FGIOSBSVOL=`docker volume inspect  $(FG_IOSNDBXVOLNAME) 2>/dev/null | jq '.[].Mountpoint' | xargs echo` &&\
	[ -z "$$FGIOSBSVOL" ] &&\
                docker volume create $(FG_IOSNDBXVOLNAME) ||\
                echo "FG apps volume exists at: $$FGIOSBSVOL"

run: network volumes
	@FGDB_IP=`docker network inspect fgnetwork|\
                jq '.[].Containers[]|select(.Name|contains("fgdb"))|.IPv4Address'|\
                xargs echo| sed 's/\// /' | awk '{ print $$1 }'` && echo $$FGDB_IP &&\
        [ -n "$$FGDB_IP" ] &&\
          echo "fgdb IP: $$FGDB_IP" &&\
          docker run -d\
	    -e FGDB_HOST=$(FG_RUN_NET)\
            --net $(FG_NETWORK)\
            --name $(IMAGE_NAME)_$(IMAGE_TAG)\
            -p8888:80\
            -p8889:8889\
	    --add-host "fgdb:$$FGDB_IP"\
	    -v $(FG_APPSDIRVOLNAME):/app/apps\
	    -v $(FG_IOSNDBXVOLNAME):$(FGAPISRV_IOSANDBOX)\
	    -h fgapiserver\
	    $(DOCKER_REPO)/$(IMAGE_NAME):$(IMAGE_TAG) ||\
          echo "Sorry, FGDB node is not running!"

testrun: network test_volumes
	@FGDB_IP=`docker network inspect $(FG_NETWORK)|\
                jq '.[].Containers[]|select(.Name|contains("fgdb"))|.IPv4Address'|\
                xargs echo| sed 's/\// /' | awk '{ print $$1 }'` && echo $$FGDB_IP &&\
        [ -n "$$FGDB_IP" ] &&\
          echo "fgdb IP: $$FGDB_IP" &&\
          docker run -d\
            -e FGDB_HOST=$(FG_RUN_NET)\
	    -e FLASK_APP=main.py\
	    -e FLASK_DEBUG=1\
            --net $(FG_NETWORK)\
            --name $(IMAGE_NAME)_test_$(IMAGE_TAG)\
            -p18888:80\
            -p18889:8889\
            --add-host "fgdb:$$FGDB_IP"\
            -v $(FG_APISRVVOLNAME):/app\
	    -v $(FG_IOSNDBXVOLNAME):$(FGAPISRV_IOSANDBOX)\
	    -h fgapiserver_test\
            $(DOCKER_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)\
	    bash -c "while true ; do sleep 10 ; done" &&\
	  echo "WARNING: fgapiserver in test mode is active, but no server is actually running" &&\
	  echo "         To start fgapiserver, execute the following command inside the container:" &&\
	  echo "         $$ flask run --host=0.0.0.0 --port=80" ||\
          echo "Sorry, FGDB node is not running!"
