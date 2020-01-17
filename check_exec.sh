#! /bin/bash

BIN=./archetype.exe
BIN_LIGO=ligo
NB_ERR=0

process_ligo_storage() {
    FILE=$1
    OUT_LIGO=$FILE.ligo
    OUT_STORAGE_LIGO=$FILE.storage.ligo
    TZ=out.storage.tz
    rm -fr $OUT_STORAGE_LIGO
    $BIN -t ligo-storage $FILE >$OUT_STORAGE_LIGO 2>/dev/null
    RET=$(echo $?)
    #STO=$(cat $OUT_STORAGE_LIGO)
    if [ ${RET} -eq 0 ]; then
        $BIN_LIGO compile-storage $OUT_LIGO main "`cat $OUT_STORAGE_LIGO`" 2>/dev/null > $TZ
        RET=$(echo $?)
        if [ ${RET} -eq 0 ]; then
            echo -ne "\033[32m OK \033[0m"
        else
            echo -ne "\033[31m KO \033[0m"
            NB_ERR=$((${NB_ERR} + 1))
        fi
    else
        echo -ne "\033[31m KO \033[0m"
        NB_ERR=$((${NB_ERR} + 2))
    fi

    rm -fr $OUT_STORAGE_LIGO *.pp.ligo
}

process_ligo() {
    FILE=$1
    OUT_LIGO=$FILE.ligo
    TZ=out.tz
    rm -fr $OUT_LIGO
    $BIN -t ligo $FILE >$OUT_LIGO 2>/dev/null
    RET=$(echo $?)
    if [ ${RET} -eq 0 ]; then
        echo -ne "\033[32m OK \033[0m"

        if [ -x "$(command -v $BIN_LIGO)" ]; then
            $BIN_LIGO compile-contract $OUT_LIGO main >$TZ 2>/dev/null
            RET=$(echo $?)
            if [ ${RET} -eq 0 ]; then
                echo -ne "\033[32m OK \033[0m"
                process_ligo_storage $1
            else
                echo -ne "\033[31m KO \033[0m"
                NB_ERR=$((${NB_ERR} + 1))
            fi
        else
            echo -ne "\033[30m -- \033[0m"
        fi
    else
        echo -ne "\033[31m KO \033[0m"
        echo -ne "\033[31m KO \033[0m"
        NB_ERR=$((${NB_ERR} + 2))
    fi

    rm -fr $OUT_LIGO *.pp.ligo $TZ
}

process_file() {
    printf '%-60s' $1
    $BIN $i >/dev/null 2>/dev/null
    RET=$?
    if [ $RET -eq 0 ]; then
        echo -ne "\033[32m OK \033[0m"

        if [ $? -eq 0 ]; then
            process_ligo $i
        else
            echo -ne "\033[31m KO \033[0m"
            NB_ERR=$((${NB_ERR} + 1))
        fi

    else
        echo -ne "\033[31m KO \033[0m"
        NB_ERR=$((${NB_ERR} + 1))
    fi
    echo ""
}

process_files() {
    for i in $1/*.arl; do
        FIRST_CHAR=$(basename $i | cut -c 1)
        if [ ${FIRST_CHAR} != "_" ]; then
            process_file $i
        fi
    done
    echo ""
}

printf '%-60s%s\n' '' ' RET GEN PRS STO'

process_files "./tests/passed"
process_files "./contracts"

RET=0
if [ ${NB_ERR} -eq 0 ]; then
    echo "passed."
else
    echo -e "\033[31merrors: ${NB_ERR} \033[0m"
    RET=1
fi

if [ ${RET} -ne 0 ]; then
    exit ${RET}
fi