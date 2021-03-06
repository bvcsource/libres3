#!/bin/sh

cd $HOME
. $HOME/sxsetup.conf
test -d $HOME/.sx || \
    sxinit sx://admin@$SX_CLUSTER_NAME --host-list=$FIRST_PORT_443_TCP_ADDR\
    --auth-file=$HOME/admin.key --batch-mode

get_dist() {
    DIST=`sxadm cluster --info sx://admin@$SX_CLUSTER_NAME|grep Current|cut -f2 -d:`
}

get_dist

sxadm cluster --mod\
    $DIST $SX_NODE_SIZE/$NODE_2_PORT_443_TCP_ADDR\
    sx://admin@$SX_CLUSTER_NAME

wait_sx () {
    while true; do
        sxadm cluster --info sx://admin@$SX_CLUSTER_NAME >tmp ||\
            { cat tmp; sleep 1; continue; }
        if grep 'Operations in progress' tmp >/dev/null; then
            echo
            echo "Waiting for $1"
            cat tmp
            sleep 1
            continue
        else
            break
        fi
    done
    echo "Finished $1"
}

wait_sx "rebalance"
get_dist

#DIST=`echo "$DIST" | sed -e "s/$NODE_2_PORT_443_TCP_ADDR/$NODE_3_PORT_443_TCP_ADDR/"`
DIST=`echo "$DIST" | cut -f3 -d\ |\
    sed -e "s/$NODE_2_PORT_443_TCP_ADDR/$NODE_3_PORT_443_TCP_ADDR/"`
sxadm cluster --replace-faulty $DIST sx://admin@$SX_CLUSTER_NAME
wait_sx "replace faulty"
