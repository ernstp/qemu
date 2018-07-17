#!/bin/bash

if [ -z "$P9MAMBO_PATH" ]; then
    P9MAMBO_PATH=/opt/ibm/systemsim-p9/
fi

if [ -z "$P9MAMBO_BINARY" ]; then
    P9MAMBO_BINARY="/run/p9/power9"
fi

if [ ! -x "$P9MAMBO_PATH/$P9MAMBO_BINARY" ]; then
    echo "Could not find executable P9MAMBO_BINARY ($P9MAMBO_PATH/$P9MAMBO_BINARY). Skipping hello_world test";
    exit 0;
fi

if [ -n "$KERNEL" ]; then
    echo 'Please rebuild skiboot without KERNEL set. Skipping hello_world test';
    exit 0;
fi

if [ ! `command -v expect` ]; then
    echo 'Could not find expect binary. Skipping hello_world test';
    exit 0;
fi


export SKIBOOT_ZIMAGE=`pwd`/test/hello_world/hello_kernel/hello_kernel

# Currently getting some core dumps from mambo, so disable them!
OLD_ULIMIT_C=`ulimit -c`
ulimit -c 0

t=$(mktemp) || exit 1

trap "rm -f -- '$t'" EXIT

( cd external/mambo; 
cat <<EOF | expect
set timeout 30
spawn $P9MAMBO_PATH/$P9MAMBO_BINARY -n -f ../../test/hello_world/run_hello_world.tcl
expect {
timeout { send_user "\nTimeout waiting for hello world\n"; exit 1 }
eof { send_user "\nUnexpected EOF\n;" exit 1 }
"Machine Check Stop" { exit 1;}
"Execution stopped: Sim Support exit requested stop"
}
wait
exit 0
EOF
) 2>&1 > $t

r=$?
if [ $r != 0 ]; then
    cat $t
    exit $r
fi

ulimit -c $OLD_ULIMIT_C

rm -f -- "$t"
trap - EXIT
exit 0;