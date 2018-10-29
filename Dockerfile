FROM lsiobase/ubuntu:bionic

# environment settings
ARG DEBIAN_FRONTEND="noninteractive"

# copy patches
COPY patches/ /tmp/patches/
COPY root/ /

RUN \
# echo "**** install build packages ****" && \
 apt-get update && \
 apt-get install -y \
	build-essential \
	git \
	libpcsclite-dev \
	libssl-dev \
	libusb-1.0-0-dev \
        libccid \
        libpcsclite1 \
        libusb-1.0-0 \
        pcscd \
        udev \
        curl

RUN \
# echo "**** fetch oscam source ****" && \
 git clone http://repo.or.cz/oscam.git /tmp/oscam

RUN \
 echo "**** compile oscam ****" && \
 cd /tmp/oscam && \
 patch -p0 < /tmp/patches/descrambler.patch && \
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


RUN \
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


# Ports and volumes
EXPOSE 8888
EXPOSE 9002
EXPOSE 14000
VOLUME /config
