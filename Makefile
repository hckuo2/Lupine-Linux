build-env-image:
	cd docker && \
		docker build . -t linuxbuild:latest -f build-env.Dockerfile


patch-linux:
	cd linux && \
		git apply ../kml_4.0_001.diff

build-linux:
	docker run -it -v "$(PWD)/linux":/linux-volume --rm linuxbuild:latest	\
		bash -c "make -j 8 -C /linux-volume"

