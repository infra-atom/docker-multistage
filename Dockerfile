FROM ubuntu:22.04 as FIRST
ARG STEND_ENV_DIR
ARG SM_VER
ARG SM_VER_PATCH
ARG SM_VER_PATCH_UNZIP
RUN apt-get update && apt-get install -y unzip
RUN groupadd --gid 1000 ubuntu \
  && useradd --uid 1000 --gid ubuntu --shell /bin/bash --create-home ubuntu && mkdir -p /opt/${STEND_ENV_DIR}/
WORKDIR /tmp
COPY ./${SM_VER} /tmp/
RUN tar -xf /tmp/${SM_VER} -C /opt/${STEND_ENV_DIR}/ && rm -rf /tmp/${SM_VER} && rm /opt/${STEND_ENV_DIR}/S2X/config/UploadsLock.txt \
&& chown -R ubuntu:ubuntu /opt/${STEND_ENV_DIR} && ls -lah /opt/${STEND_ENV_DIR}/

###
###BLOCK FOR COPY SSL AND SERVER.XML
###
COPY files/config/server.xml /opt/${STEND_ENV_DIR}/S2X/config/
COPY files/extensions/ /opt/${STEND_ENV_DIR}/S2X/extensions/
COPY files/zones/Dr3cZoneExtension.zone.xml /opt/${STEND_ENV_DIR}/S2X/zones/
RUN rm /opt/${STEND_ENV_DIR}/S2X/zones/BasicExamples.zone.xml && ls -lah /opt/${STEND_ENV_DIR}/S2X/
COPY files/extensions/ /opt/${STEND_ENV_DIR}/S2X/extensions/
COPY files/zones/Dr3cZoneExtension.zone.xml /opt/${STEND_ENV_DIR}/S2X/zones/
RUN chown -R ubuntu:ubuntu /opt/${STEND_ENV_DIR}/ && ls -lah /opt/${STEND_ENV_DIR}/


###
###BLOCK FOR PATCH VERSION
###
COPY ./${SM_VER_PATCH} /tmp/
RUN ls -alh /tmp/
RUN unzip -q /tmp/${SM_VER_PATCH} && rm -rf /tmp/${SM_VER_PATCH} && echo 'after uzip' && ls -alh \
&& ls -alh /tmp/ && ls -alh /opt/${STEND_ENV_DIR}/ && mv ${SM_VER_PATCH_UNZIP} /opt/${STEND_ENV_DIR}/
WORKDIR /opt/${STEND_ENV_DIR}/${SM_VER_PATCH_UNZIP}
RUN ./install-linux.sh


###
### FINISH BUILD
###
FROM ubuntu:22.04 as SECOND
ARG STEND_ENV_DIR
RUN groupadd --gid 1000 ubuntu \
  && useradd --uid 1000 --gid ubuntu --shell /bin/bash --create-home ubuntu && mkdir -p /opt/${STEND_ENV_DIR}/S2X/
WORKDIR /opt/${STEND_ENV_DIR}/S2X/
COPY --from=FIRST /opt/${STEND_ENV_DIR}/ /opt/${STEND_ENV_DIR}/S2X/
RUN chown -R ubuntu:ubuntu /opt/${STEND_ENV_DIR}/
USER 1000
EXPOSE 9933 9934/udp 8081 8443 8180
WORKDIR /opt/${STEND_ENV_DIR}/S2X
CMD ./s2x.sh
