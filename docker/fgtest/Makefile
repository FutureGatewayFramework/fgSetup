#
# fgdb Docker container makefile
#
# Please ensure that Makefile environment variables are matching
# values defined inside Dockerfile
# 
# Author: Riccardo Bruno (INFN) <riccardo.bruno@ct.infn.it>
#
DOCKER_REPO = futuregateway
IMAGE_NAME = fgtest
IMAGE_TAG = 0.1

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
	docker build --no-cache  -t $(DOCKER_REPO)/$(IMAGE_NAME):latest .
	docker tag $(DOCKER_REPO)/$(IMAGE_NAME):latest $(DOCKER_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)

image-cached: Dockerfile
	docker build -t $(DOCKER_REPO)/$(IMAGE_NAME):latest .
	docker tag $(DOCKER_REPO)/$(IMAGE_NAME):latest $(DOCKER_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)

publish: image 
	docker push $(DOCKER_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)
	docker push $(DOCKER_REPO)/$(IMAGE_NAME):latest


run: 
	docker run -d\
		   --name $(IMAGE_NAME)_$(IMAGE_TAG)\
		   -h fgtest \
	   	   $(DOCKER_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)
