#
# fgdb Docker container makefile
#
# Please ensure that Makefile environment variables are matching
# values defined inside Dockerfile
# 
# Author: Riccardo Bruno (INFN) <riccardo.bruno@ct.infn.it>
#
DOCKER_REPO = futuregateway
IMAGE_NAME = fgdb
IMAGE_TAG = 0.3
FG_NETWORK = fgnetwork_test
FG_MYSQLDIRVOLNAME = fg_mysql_test

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
	@[ "$(shell docker network list | grep $(FG_NETWORK))" = "" ] &&\
            docker network create $(FG_NETWORK) ||\
	    echo "Network $(FG_NETWORK) already running"

volumes:
	@FGMYSQLVOL=`docker volume inspect $(FG_MYSQLDIRVOLNAME) 2>/dev/null | jq '.[].Mountpoint' | xargs echo` &&\
	[ -z "$$FGMYSQLVOL" ] &&\
     	    docker volume create $(FG_MYSQLDIRVOLNAME) ||\
       	    echo "FG apps volume exists at: $$FGMYSQLVOL"

run: network volumes 
	docker run -d\
		   --net $(FG_NETWORK)\
		   --name $(IMAGE_NAME)_$(IMAGE_TAG)\
	           -p 3306:3306\
		   -h fgdb \
		   -v $(FG_MYSQLDIRVOLNAME):/var/lib/mysql\
	   	   $(DOCKER_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)
