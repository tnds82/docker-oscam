FROM lsiobase/ubuntu:bionic as buildstage
############## build stage ##############

# environment settings
ARG DEBIAN_FRONTEND="noninteractive"

RUN \
 echo "**** install build packages ****" && \
 apt-get update && \
 apt-get install -y \
	build-essential \
	bzr \
	libpcsclite-dev \
	libssl-dev \
	libusb-1.0-0-dev

RUN \
 echo "**** fetch oscam source ****" && \
 bzr branch lp:oscam /tmp/oscam-svn

RUN \
 echo "**** compile oscam ****" && \
 cd /tmp/oscam-svn && \
 ./config.sh \
	--enable all \
	--disable \
	CARDREADER_DB2COM \
	CARDREADER_INTERNAL \
	CARDREADER_STINGER \
	CARDREADER_STAPI \
	CARDREADER_STAPI5 \
	IPV6SUPPORT \
	LCDSUPPORT \
	LEDSUPPORT \
	READ_SDT_CHARSETS && \
 make \
	CONF_DIR=/config \
	DEFAULT_PCSC_FLAGS="-I/usr/include/PCSC" \
	NO_PLUS_TARGET=1 \
	OSCAM_BIN=/usr/bin/oscam \
	pcsc-libusb
############## runtime stage ##############
FROM lsiobase/ubuntu:bionic

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="saarg"

# environment settings
ARG DEBIAN_FRONTEND="noninteractive"

RUN \
 echo "**** install runtime packages ****" && \
 apt-get update && \
 apt-get install -y \
	libccid \
	libpcsclite1 \
	libusb-1.0-0 \
	pcscd \
	udev && \
 echo "**** install PCSC drivers ****" && \
 mkdir -p \
	/tmp/omnikey && \
 curl -o \
 /tmp/omnikey.tar.gz -L \
	https://www.hidglobal.com/sites/default/files/drivers/ifdokccid_linux_x86_64-v4.2.8.tar.gz && \
 tar xzf \
 /tmp/omnikey.tar.gz -C \
	/tmp/omnikey --strip-components=2 && \
 cd /tmp/omnikey && \
 ./install && \
 echo "**** cleanup ****" && \
 rm -rf \
	/tmp/* \
	/var/lib/apt/lists/* \
	/var/tmp/*

# copy buildstage and local files
COPY --from=buildstage /usr/bin/oscam /usr/bin/
COPY --from=buildstage /usr/bin/oscam.debug /usr/bin/
COPY root/ /

# Ports and volumes
EXPOSE 8888
VOLUME /config
