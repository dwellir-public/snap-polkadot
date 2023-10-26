#!/bin/sh

. "$SNAP/utils/utils.sh"

set_endure()
{
    snapctl set endure="$1"
    set_previous_endure "$1"
}

get_endure()
{
    endure="$(snapctl get endure)"
    if [ -z "$endure" ]; then
        log "Setting endure to false as default"
        # Don't use set_endure() since it will not work when using snap unset
        snapctl set endure="false"
    fi
    echo "$endure"
}

endure()
{
    [ "$(get_endure)" = "true" ]
}

set_previous_endure()
{
    snapctl set private.endure="$1"
}

get_previous_endure()
{
    snapctl get private.endure
}

endure_has_changed()
{
	[ "$(get_endure)" != "$(get_previous_endure)" ]
}
