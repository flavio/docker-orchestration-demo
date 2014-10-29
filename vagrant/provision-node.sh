# Regenerate machine-id
rm /etc/machine-id
systemd-machine-id-setup

# Install salt minion and start it
zypper rm -y patterns-openSUSE-minimal_base-conflicts
zypper in -y salt-minion

cat <<EOF >> /etc/salt/minion
master: $1
EOF

systemctl enable salt-minion
systemctl start salt-minion

TIMEOUT=90
COUNT=0
while [ ! -f /etc/salt/pki/minion/minion_master.pub ]; do
    echo "Waiting for salt minion to start"
    if [ "$COUNT" -ge "$TIMEOUT" ]; then
        echo "minion_master.pub not detected by timeout"
        exit 1
    fi
    sleep 5
    COUNT=$((COUNT+5))
done

echo "Calling highstate"
salt-call state.highstate
