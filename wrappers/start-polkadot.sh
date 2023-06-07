#!/bin/sh
exec $SNAP/bin/polkadot $(cat $SNAP_DATA/service-args)
