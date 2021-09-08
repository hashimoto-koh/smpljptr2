.PHONY: build tag push pullrunc runm
NAME=smpljptr2
VER=00
MNT_ROOT=/Users/koh/git/etc/smpljptr2/mnt
IMAGE=hashimotokoh/${NAME}:latest

all: runc

build:
	docker build -f ./Dockerfile -t ${NAME}:v${VER} .

tag:
	docker tag ${NAME}:v${VER} ${IMAGE}

push:
	docker push ${IMAGE}

pull:
	docker pull ${IMAGE}

runc:
	docker run --rm -it \
		--name ${NAME} \
		-p 8899:8888 \
		-v ${MNT_ROOT}/mnt:/home/jovyan/mnt  \
		-v ${MNT_ROOT}/jupyter:/home/jovyan/.jupyter \
		-v ${MNT_ROOT}/ipython:/home/jovyan/.ipython \
		${IMAGE} \
		/bin/bash -l

runm:
	docker run -it \
		--name ${NAME} \
		-p 8899:8888 \
		-v ./mnt:/home/jovyan/mnt  \
		-v ./jupyter:/home/jovyan/.jupyter \
		-v ./ipython:/home/jovyan/.ipython \
		${IMAGE} \
		/bin/bash -l
