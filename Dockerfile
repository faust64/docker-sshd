FROM debian:buster-slim

# SSHD image for OpenShift Origin

LABEL io.k8s.description="OpenSSH server." \
      io.k8s.display-name="OpenSSH server" \
      io.openshift.expose-services="2222:ssh" \
      io.openshift.tags="sshd,rsync" \
      io.openshift.non-scalable="false" \
      help="For more information visit https://github.com/faust64/docker-sshd" \
      maintainer="Samuel MARTIN MORO <faust64@gmail.com>" \
      version="1.0"

ENV DEBIAN_FRONTEND=noninteractive

RUN set -x \
    && apt-get update \
    && mkdir -p /usr/share/man/man1 \
    && apt-get -y install openssh-server rsync wget libnss-wrapper dumb-init \
    && if test "$DO_UPGRADE"; then \
	apt-get -y upgrade; \
    fi \
    && apt-get remove --purge -y wget \
    && apt-get autoremove --purge -y \
    && apt-get clean \
    && mkdir -p /var/backup /var/run/sshd /run/sshd /home \
    && chown -R root:root /etc/ssh /var/backup /run/sshd /var/run/sshd /home \
    && chmod -R g=u /var/backup /etc/ssh /var/run/sshd /home \
    && chmod 0700 /run/sshd \
    && rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man

COPY config/* /
USER 1001
ENTRYPOINT ["dumb-init","--","/run-sshd.sh"]
