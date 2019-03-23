#
# fgliferay Docker container makefile
#
# Please ensure that Makefile environment variables are matching
# values defined inside Dockerfile
#
# Author: Riccardo Bruno (INFN) <riccardo.bruno@ct.infn.it>
#
DOCKER_REPO = futuregateway
IMAGE_NAME = fgliferay
IMAGE_TAG = 0.1
FG_NETWORK = fgnetwork
FG_LIFERAYVOLNAME = fg_liferay
LFRY_DBNAME = lportal
LFRY_DBUSER = lportal
LFRY_DBPASS = lportal
LPORTAL_SQL = lportal.sql
MYSQL_ROOT_PASSWORD = rpass
LIFERAY_PLUGINS_REL = https://github.com/indigo-dc/LiferayPlugIns/releases/download/2.2.1/LiferayPlugins-binary-2.2.1.tgz
FG_DIR = /home/futuregateway

default:
	@echo "Usage: make <image|pubimg>"
	@echo "     image - Build the image: $(DOCKER_REPO)/$(IMAGE_NAME):latest"
	@echo "       run - Create container from image : $(DOCKER_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)"
	@echo "             having name: $(IMAGE_NAME)_$(IMAGE_TAG)" 
	@echo "     rerun - Same as above, to be used in case the container has been already started"
	@echo "             and recycle both volumes and database."
	@echo "   publish - Publish images: $(DOCKER_REPO)/$(IMAGE_NAME):latest"
	@echo "                             $(DOCKER_REPO)/$(IMAGE_NAME):$(IMAGE:_TAG)"
	@echo "             on the Docker-hub"
	@echo ""

image: Dockerfile
ifdef nocache
	docker build --no-cache -t $(DOCKER_REPO)/$(IMAGE_NAME):latest .
else
	docker build -t $(DOCKER_REPO)/$(IMAGE_NAME):latest .
endif
	docker tag $(DOCKER_REPO)/$(IMAGE_NAME):latest $(DOCKER_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)

cache_image: Dockerfile
	@docker build -t $(DOCKER_REPO)/$(IMAGE_NAME):latest . &&\
	docker tag $(DOCKER_REPO)/$(IMAGE_NAME):latest $(DOCKER_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)

publish: image 
	@docker push $(DOCKER_REPO)/$(IMAGE_NAME):$(IMAGE_TAG) &&\
	docker push $(DOCKER_REPO)/$(IMAGE_NAME):latest

network:
	@[ "$(shell docker network list | grep $(FG_NETWORK))" = "" ]\
                && docker network create $(FG_NETWORK)\
                || echo "Network $(FG_NETWORK) already running"

volumes:
	@FGLFRYVOL=`docker volume inspect $(FG_LIFERAYVOLNAME) 2>/dev/null | jq '.[].Mountpoint' | xargs echo` &&\
        [ -z "$$FGLFRYVOL" ] &&\
                docker volume create $(FG_LIFERAYVOLNAME) ||\
                echo "FG liferay volume exists at: $$FGLFRYVOL"

liferay_plugins:
	@FGLR_ID=`docker ps -a | grep fgliferay | awk '{ print $$1 }'|xargs echo` &&\
        [ -n "$$FGLR_ID" ] &&\
            echo "fgliferay Id: $$FGLR_ID" &&\
            TMP=`mktemp` &&\
            echo "#!/bin/bash" > $$TMP &&\
            echo "#" >> $$TMP &&\
            echo "# Liferay Plugin installation" >> $$TMP &&\
            echo "#" >> $$TMP &&\
            echo "LIFERAY_PLUGINS_TGZ=LiferayPlugins-binary-2.2.1.tgz &&\\" >> $$TMP &&\
            echo "LIFERAY_PLUGINS_REL=$(LIFERAY_PLUGINS_REL) &&\\" >> $$TMP &&\
            echo "wget \$$LIFERAY_PLUGINS_REL -O \$$LIFERAY_PLUGINS_TGZ &&\\" >> $$TMP &&\
            echo "tar xvfz \$$LIFERAY_PLUGINS_TGZ &&\\" >> $$TMP &&\
            echo "rm -f \$$LIFERAY_PLUGINS_TGZ &&\\" >> $$TMP &&\
            echo "cp com.liferay.* /opt/liferay/home/osgi/modules &&\\" >> $$TMP &&\
            echo "echo \"Liferay Plugins installation successfully done\" ||\\" >> $$TMP &&\
            echo "echo \"An error occurred while installing LiferayPlugins\"" >> $$TMP &&\
            chmod +x $$TMP &&\
            docker cp $$TMP $$FGLR_ID:$(FG_DIR)/liferay_plugins.sh &&\
            rm -f $$TMP &&\
            docker exec $$FGLR_ID /bin/bash -c "chmod +x $(FG_DIR)/liferay_plugins.sh" &&\
            docker exec $$FGLR_ID /bin/bash -c "liferay_plugins.sh" &&\
            echo "Done" ||\
            echo "ERROR: No fgliferay node found"


run: network volumes
	@FGDB_IP=`docker network inspect fgnetwork|\
		jq '.[].Containers[]|select(.Name|contains("fgdb"))|.IPv4Address'|\
		xargs echo| sed 's/\// /' | awk '{ print $$1 }'` &&\
	FGAPISRV_IP=`docker network inspect fgnetwork|\
                jq '.[].Containers[]|select(.Name|contains("fgapiserver"))|.IPv4Address'|\
                xargs echo| sed 's/\// /' | awk '{ print $$1 }'` &&\
        [ "$$FGDB_IP" != "" -a "$$FGAPISRV_IP" != "" ] &&\
        echo "fgdb IP: $$FGDB_IP" &&\
	echo "fgapiserver IP: $$FGAPISRV_IP" &&\
	cp $(LPORTAL_SQL) run_$(LPORTAL_SQL) &&\
        sed -i "s/LFRY_DBNAME/$(LFRY_DBNAME)/g" run_$(LPORTAL_SQL) &&\
	sed -i "s/LFRY_DBUSER/$(LFRY_DBNAME)/g" run_$(LPORTAL_SQL) &&\
	sed -i "s/LFRY_DBPASS/$(LFRY_DBNAME)/g" run_$(LPORTAL_SQL) &&\
	mysql -u root -prpass -h $$FGDB_IP < run_$(LPORTAL_SQL) &&\
	rm -f run_$(LPORTAL_SQL) &&\
        docker run -d\
	    -e FGDB_HOST=$(FG_RUN_NET)\
            --net $(FG_NETWORK)\
            --name $(IMAGE_NAME)_$(IMAGE_TAG)\
            -p18080:8080\
	    -v $(FG_LIFERAYVOLNAME):/opt/liferay/home/data\
	    --add-host "fgdb:$$FGDB_IP"\
	    --add-host "fgapiserver:$$FGAPISRV_IP"\
	    -h $(IMAGE_NAME)\
	    $(DOCKER_REPO)/$(IMAGE_NAME):$(IMAGE_TAG) ||\
        echo "Sorry, one of the nodes FGDB ($$FGDB_IP) or FGAPISRV ($$FGAPISRV_IP) is not running!"

rerun: network volumes
	@FGDB_IP=`docker network inspect fgnetwork|\
                jq '.[].Containers[]|select(.Name|contains("fgdb"))|.IPv4Address'|\
                xargs echo| sed 's/\// /' | awk '{ print $$1 }'` &&\
        FGAPISRV_IP=`docker network inspect fgnetwork|\
                jq '.[].Containers[]|select(.Name|contains("fgapiserver"))|.IPv4Address'|\
                xargs echo| sed 's/\// /' | awk '{ print $$1 }'` &&\
        [ "$$FGDB_IP" != "" -a "$$FGAPISRV_IP" != "" ] &&\
        echo "fgdb IP: $$FGDB_IP" &&\
        echo "fgapiserver IP: $$FGAPISRV_IP" &&\
        docker run -d\
            -e FGDB_HOST=$(FG_RUN_NET)\
            --net $(FG_NETWORK)\
            --name $(IMAGE_NAME)_$(IMAGE_TAG)\
            -p18080:8080\
            -v $(FG_LIFERAYVOLNAME):/opt/liferay/home/data\
            --add-host "fgdb:$$FGDB_IP"\
            --add-host "fgapiserver:$$FGAPISRV_IP"\
            -h $(IMAGE_NAME)\
            $(DOCKER_REPO)/$(IMAGE_NAME):$(IMAGE_TAG) ||\
        echo "Sorry, one of the nodes FGDB ($$FGDB_IP) or FGAPISRV ($$FGAPISRV_IP) is not running!"
