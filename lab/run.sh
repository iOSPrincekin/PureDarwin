#!/bin/bash

OP=$1
echo "OP-::${OP}"

# 路径
BASEDIR=$(dirname "$0")
cd ${BASEDIR}
BASEDIR=`pwd`

ROOT_DIR=${BASEDIR}/../
# 加载环境

HOST_PSW=lh1992524

ovmf_dbg_dir=${BASEDIR}/_ovmf_dbg
echo "mkdir _ovmf_dbg"
mkdir _ovmf_dbg
cd _ovmf_dbg

hda_contents_dir=${ovmf_dbg_dir}/hda-contents

BOOT_EFI_DIR=${ROOT_DIR}/build/src/Kernel/boot.efi/boot.efi/

TARGET=boot.efi

mkdir hda-contents

rm -rf ./hda-contents/${TARGET}

cp ${BOOT_EFI_DIR}/${TARGET} ./hda-contents

QEMU=qemu-system-x86_64
QEMU_OPTION=" -s -pflash OVMF.fd -hda fat:rw:hda-contents/ -net none -debugcon file:debug.log -global isa-debugcon.iobase=0x402 "
SUDO_QEMU="echo lh1992524 | sudo -S ${QEMU}"

if  ( [[ $OP == "debug" ]] );then
    osascript -e "tell application \"Terminal\" to quit"
    osascript -e "tell application \"Terminal\" to do script \"cd ${hda_contents_dir}\\nlldb ${TARGET} \\n file ${TARGET} \\n target modules load --file ${TARGET} --slide 0x00005D42000 \\n b EfiMain \\n gdb-remote localhost:1234\"" \
    -e "tell application \"Terminal\" to activate" \
    -e "tell application \"System Events\" to tell process \"Terminal\" to keystroke \"t\" using command down" \
    -e "tell application \"Terminal\" to set background color of window 1 to {0,0,0,1}" \
    -e "tell application \"Terminal\" to do script \"cd ${ovmf_dbg_dir}\\n sleep 0.3\\n echo lh1992524 | sudo -S ${QEMU} -S ${QEMU_OPTION}\" in window 1"
else
    echo "echo lh1992524 | sudo -S ${QEMU} ${QEMU_OPTION}"
    echo lh1992524 | sudo -S ${QEMU} ${QEMU_OPTION}
fi
