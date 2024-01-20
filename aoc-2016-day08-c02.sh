#!/bin/sh

CHALLENGE=`basename "$(realpath $0)" .sh`

do_build()
{
    exe_filename=${CHALLENGE}
    source_filename=${exe_filename}.S
    build_command="gcc -O0 -no-pie -Wall -nostdlib ${source_filename} -o ${exe_filename}"
    error_code=0
    if [ ! -e ${exe_filename} ]
    then
        echo ${build_command}
        ${build_command}
        error_code=$?
    else
        source_timestamp=$(stat --printf=%Y ${source_filename})
        exe_timestamp=$(stat --printf=%Y ${exe_filename})
        if [ ${exe_timestamp} -lt ${source_timestamp} ]
        then
            echo ${build_command}
            ${build_command}
            error_code=$?
        fi
    fi

    if [ $error_code -ne 0 ]
    then
        echo "failed to build"
        exit 1
    fi
}

do_clean()
{
    if [ -e ${CHALLENGE} ]
    then
        rm -v ${CHALLENGE}
    fi
}

do_run()
{
    ./${CHALLENGE} "${1}"
}

do_test()
{
    input="${1}"
    value=$(./${CHALLENGE} "${input}")
    error_code=$?

    if [ $error_code -ne 0 ]
    then
        echo "KO: '${input}'"
        echo "program error code: $error_code"
        echo "program output: ${value}"
        exit 1
    fi

    echo "${value}"
}

do_test_batch()
{
    do_test "$(echo -e rect 1x1\\nrotate row y=0 by 10\\nrect 1x1\\nrotate row y=0 by 10\\nrect 1x1\\nrotate row y=0 by 5\\nrect 1x1\\nrotate row y=0 by 3\\nrect 2x1\\nrotate row y=0 by 4\\nrect 1x1\\nrotate row y=0 by 3\\nrect 1x1\\nrotate row y=0 by 2\\nrect 1x1\\nrotate row y=0 by 3\\nrect 2x1\\nrotate row y=0 by 2\\nrect 1x1\\nrotate row y=0 by 3\\nrect 2x1\\nrotate row y=0 by 5\\nrotate column x=0 by 1\\nrect 4x1\\nrotate row y=1 by 12\\nrotate row y=0 by 10\\nrotate column x=0 by 1\\nrect 9x1\\nrotate column x=7 by 1\\nrotate row y=1 by 3\\nrotate row y=0 by 2\\nrect 1x2\\nrotate row y=1 by 3\\nrotate row y=0 by 1\\nrect 1x3\\nrotate column x=35 by 1\\nrotate column x=5 by 2\\nrotate row y=2 by 5\\nrotate row y=1 by 5\\nrotate row y=0 by 2\\nrect 1x3\\nrotate row y=2 by 8\\nrotate row y=1 by 10\\nrotate row y=0 by 5\\nrotate column x=5 by 1\\nrotate column x=0 by 1\\nrect 6x1\\nrotate row y=2 by 7\\nrotate row y=0 by 5\\nrotate column x=0 by 1\\nrect 4x1\\nrotate column x=40 by 2\\nrotate row y=2 by 10\\nrotate row y=0 by 12\\nrotate column x=5 by 1\\nrotate column x=0 by 1\\nrect 9x1\\nrotate column x=43 by 1\\nrotate column x=40 by 2\\nrotate column x=38 by 1\\nrotate column x=15 by 1\\nrotate row y=3 by 35\\nrotate row y=2 by 35\\nrotate row y=1 by 32\\nrotate row y=0 by 40\\nrotate column x=32 by 1\\nrotate column x=29 by 1\\nrotate column x=27 by 1\\nrotate column x=25 by 1\\nrotate column x=23 by 2\\nrotate column x=22 by 1\\nrotate column x=21 by 3\\nrotate column x=20 by 1\\nrotate column x=18 by 3\\nrotate column x=17 by 1\\nrotate column x=15 by 1\\nrotate column x=14 by 1\\nrotate column x=12 by 1\\nrotate column x=11 by 3\\nrotate column x=10 by 1\\nrotate column x=9 by 1\\nrotate column x=8 by 2\\nrotate column x=7 by 1\\nrotate column x=4 by 1\\nrotate column x=3 by 1\\nrotate column x=2 by 1\\nrotate column x=0 by 1\\nrect 34x1\\nrotate column x=44 by 1\\nrotate column x=24 by 1\\nrotate column x=19 by 1\\nrotate row y=1 by 8\\nrotate row y=0 by 10\\nrotate column x=8 by 1\\nrotate column x=7 by 1\\nrotate column x=6 by 1\\nrotate column x=5 by 2\\nrotate column x=3 by 1\\nrotate column x=2 by 1\\nrotate column x=1 by 1\\nrotate column x=0 by 1\\nrect 9x1\\nrotate row y=0 by 40\\nrotate column x=43 by 1\\nrotate row y=4 by 10\\nrotate row y=3 by 10\\nrotate row y=2 by 5\\nrotate row y=1 by 10\\nrotate row y=0 by 15\\nrotate column x=7 by 2\\nrotate column x=6 by 3\\nrotate column x=5 by 2\\nrotate column x=3 by 2\\nrotate column x=2 by 4\\nrotate column x=0 by 2\\nrect 9x2\\nrotate row y=3 by 47\\nrotate row y=0 by 10\\nrotate column x=42 by 3\\nrotate column x=39 by 4\\nrotate column x=34 by 3\\nrotate column x=32 by 3\\nrotate column x=29 by 3\\nrotate column x=22 by 3\\nrotate column x=19 by 3\\nrotate column x=14 by 4\\nrotate column x=4 by 3\\nrotate row y=4 by 3\\nrotate row y=3 by 8\\nrotate row y=1 by 5\\nrotate column x=2 by 3\\nrotate column x=1 by 3\\nrotate column x=0 by 2\\nrect 3x2\\nrotate row y=4 by 8\\nrotate column x=45 by 1\\nrotate column x=40 by 5\\nrotate column x=26 by 3\\nrotate column x=25 by 5\\nrotate column x=15 by 5\\nrotate column x=10 by 5\\nrotate column x=7 by 5\\nrotate row y=5 by 35\\nrotate row y=4 by 42\\nrotate row y=2 by 5\\nrotate row y=1 by 20\\nrotate row y=0 by 45\\nrotate column x=48 by 5\\nrotate column x=47 by 5\\nrotate column x=46 by 5\\nrotate column x=43 by 5\\nrotate column x=41 by 5\\nrotate column x=38 by 5\\nrotate column x=37 by 5\\nrotate column x=36 by 5\\nrotate column x=33 by 1\\nrotate column x=32 by 5\\nrotate column x=31 by 5\\nrotate column x=30 by 1\\nrotate column x=28 by 5\\nrotate column x=27 by 5\\nrotate column x=26 by 5\\nrotate column x=23 by 1\\nrotate column x=22 by 5\\nrotate column x=21 by 5\\nrotate column x=20 by 1\\nrotate column x=17 by 5\\nrotate column x=16 by 5\\nrotate column x=13 by 1\\nrotate column x=12 by 3\\nrotate column x=7 by 5\\nrotate column x=6 by 5\\nrotate column x=3 by 1\\nrotate column x=2 by 3)"
}

if [ $# -eq 0 ]
then
    do_build
    do_test_batch
elif [ "$1" = "clean" ]
then
    do_clean
else
    do_build
    for i in "$@"
    do
        do_run "$i"
    done
fi
