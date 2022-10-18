#!/bin/sh

CHALLENGE=aoc-2016-day01-c02

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
    expected="${1}"
    str="${2}"
    if [ "${3}" != "" ]
    then
        str="${str} ${3}"
    fi
    value=$(./${CHALLENGE} "${str}")
    error_code=$?

    if [ $error_code -ne 0 ]
    then
        echo "KO: '${str}'"
        echo "program error code: $error_code"
        exit 1
    fi

    if [ "$expected" = "$value" ]
    then
        echo "OK: '${str}'"
    else
        echo "KO: '${str}'"
        echo "expected: ${expected}, got: ${value}"
        exit 1
    fi
}

do_test_batch()
{
    do_test "00000000000000004" "R8, R4, R4, R8"
    do_test "00000000000000004" "L8, L4, L4, L8"
    do_test "00000000000000143" "L3, R1, L4, L1, L2, R4, L3, L3, R2, R3, L5, R1, R3, L4, L1, L2, R2, R1, L4, L4, R2, L5, R3, R2, R1, L1, L2, R2, R2, L1, L1, R2, R1, L3, L5, R4, L3, R3, R3, L5, L190, L4, R4, R51, L4, R5, R5, R2, L1, L3, R1, R4, L3, R1, R3, L5, L4, R2, R5, R2, L1, L5, L1, L1, R78, L3, R2, L3, R5, L2, R2, R4, L1, L4, R1, R185, R3, L4, L1, L1, L3, R4, L4, L1, R5, L5, L1, R5, L1, R2, L5, L2, R4, R3, L2, R3, R1, L3, L5, L4, R3, L2, L4, L5, L4, R1, L1, R5, L2, R4, R2, R3, L1, L1, L4, L3, R4, L3, L5, R2, L5, L1, L1, R2, R3, L5, L3, L2, L1, L4, R4, R4, L2, R3, R1, L2, R1, L2, L2, R3, R3, L1, R4, L5, L3, R4, R4, R1, L2, L5, L3, R1, R4, L2, R5, R4, R2, L5, L3, R4, R1, L1, R5, L3, R1, R5, L2, R1, L5, L2, R2, L2, L3, R3, R3, R1"
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
