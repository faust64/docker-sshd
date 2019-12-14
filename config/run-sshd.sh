#!/bin/sh

if test "$DEBUG"; then
    set -x
fi

HOSTKEY_SOURCE=${HOSTKEY_SOURCE:-/etc/ssh}
HOSTKEY_TARGET=${HOSTKEY_TARGET:-/var/backup/sshd}
MY_HOME="${MY_HOME:-/home/backup}"
SSHD_PORT=${SSHD_PORT:-2222}
SSHD_TMPDIR=${SSHD_TMPDIR:-/var/backup/tmp}
SSH_USERNAME=${SSH_USERNAME:-backup}

if test "`id -u`" -ne 0; then
    echo Setting up nsswrapper mapping `id -u` to $SSH_USERNAME
    pwentry="$SSH_USERNAME:x:`id -u`:`id -g`:$SSH_USERNAME:$MY_HOME:/bin/bash"
    ( grep -v ^$SSH_USERNAME: /etc/passwd ; echo "$pwentry" ) >/tmp/$SSH_USERNAME-passwd
    export NSS_WRAPPER_PASSWD=/tmp/$SSH_USERNAME-passwd
    export NSS_WRAPPER_GROUP=/etc/group
    export LD_PRELOAD=/usr/lib/libnss_wrapper.so
fi
export HOME="$MY_HOME"

test -d "$HOME/.ssh" || mkdir -p "$HOME/.ssh"
chown -R $SSH_USERNAME:root "$HOME"
chmod -R g=u "$HOME"
chmod 0750 $HOME

cpt=0
echo -n "Waiting for sshd host keys to become available: "
while :
do
    if test -s $HOSTKEY_SOURCE/ssh_host_ecdsa_key; then
	echo OK
	break
    elif test $cpt -gt 20; then
	echo ' timeout exceeded' >&2
	exit 1
    fi
    cpt=`expr $cpt + 1`
    echo -n .
    sleep 2
done

mkdir -p $HOSTKEY_TARGET $SSHD_TMPDIR
for key in rsa ecdsa ed25519
do
    cat $HOSTKEY_SOURCE/ssh_host_${key}_key \
	>$HOSTKEY_TARGET/ssh_host_${key}_key
    cat $HOSTKEY_SOURCE/ssh_host_${key}_key.pub \
	>$HOSTKEY_TARGET/ssh_host_${key}_key.pub
done
chown -R $SSH_USERNAME:root $HOSTKEY_TARGET
chmod 0600 $HOSTKEY_TARGET/*
chmod 0700 $HOSTKEY_TARGET $SSHD_TMPDIR
if test -s /.ssh/id_rsa.pub; then
    cat /.ssh/id_rsa.pub >$HOME/.ssh/authorized_keys
    chmod 0600 $HOME/.ssh/authorized_keys
fi
chmod 0700 $HOME/.ssh
echo "" >$HOME/.ssh/authorized_keys2
chmod 0600 $HOME/.ssh/authorized_keys2

sed -i -e "s|#PidFile.*$|PidFile $SSHD_TMPDIR/sshd.pid|" \
	-e "s/#PasswordAuthentication .*$/PasswordAuthentication no/" \
	-e 's/#UsePrivilegeSeparation.*$/UsePrivilegeSeparation no/' \
	-e "s|#HostKey /etc/ssh/ssh_host_rsa_key.*|HostKey $HOSTKEY_TARGET/ssh_host_rsa_key|" \
	-e "s|#HostKey /etc/ssh/ssh_host_ecdsa_key.*|HostKey $HOSTKEY_TARGET/ssh_host_ecdsa_key|" \
	-e "s|#HostKey /etc/ssh/ssh_host_ed25519_key.*|HostKey $HOSTKEY_TARGET/ssh_host_ed25519_key|" \
	-e 's/StrictModes yes/StrictModes no/' \
	-e "s|UsePAM yes|UsePAM no|" \
	-e "s/#Port.*$/Port $SSHD_PORT/" /etc/ssh/sshd_config

echo Starting SSHD
if test "$DEBUG"; then
    exec /usr/sbin/sshd -D -d -e
else
    exec /usr/sbin/sshd -D -e
fi
