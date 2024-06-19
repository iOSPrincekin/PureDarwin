PureDarwin [![Join the chat at https://gitter.im/PureDarwin/](https://img.shields.io/badge/gitter-join%20chat-brightgreen.svg)](https://gitter.im/PureDarwin/?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
==========

![](https://raw.github.com/wiki/PureDarwin/PureDarwin/images/PD-Opennow.jpg)

PureDarwin moved from https://code.google.com/p/puredarwin/

Darwin is the Open Source operating system from Apple that forms the basis for Mac OS X and PureDarwin. PureDarwin is a community project that aims to make Darwin more usable (some people think of it as the informal successor to OpenDarwin).

One current goal of this project is to provide a useful bootable ISO/VM of some recent version of Darwin.

See the [Wiki](https://github.com/PureDarwin/PureDarwin/wiki) for more information.

## Building PureDarwin

To build PureDarwin, you will need OpenSSL installed, which is used by xar and ld64.
PureDarwin builds only on macOS. It is currently tested with Xcode 14, but should work
with any other modern Xcode.

You will also need zlib, which is used by the DTrace CTF tools used in building the kernel.



# iOSPrincekin

## boot.efi


## kernel

### src/Kernel/xnu/osfmk/x86_64/start.s

#### 1.section __HIB, __data 的作用是将 数据放在 __HIB, __data 的段中

#### 2.反汇编第一个函数

__text:FFFFFF8000100000
__text:FFFFFF8000100000 ; Attributes: bp-based frame
__text:FFFFFF8000100000
__text:FFFFFF8000100000 sub_FFFFFF8000100000 proc near          ; CODE XREF: _waitq_bootstrap+1B8↓p
__text:FFFFFF8000100000                                         ; _waitq_init+5A↓p ...
__text:FFFFFF8000100000                 push    rbp
__text:FFFFFF8000100001                 mov     rbp, rsp
__text:FFFFFF8000100004                 mov     qword ptr [rdi], 0
__text:FFFFFF800010000B                 pop     rbp
__text:FFFFFF800010000C                 retn
__text:FFFFFF800010000C sub_FFFFFF8000100000 endp

的原型是：

#define PRIORITY_QUEUE_MAKE(pqueue_t, pqelem_t) \
__pqueue_overloadable                                                           \
static inline void                                                              \
priority_queue_init(pqueue_t que)                                               \
{                                                                               \
	__builtin_bzero(que, sizeof(*que));                                     \
}                                                                               \
        
#### 3.//src/Kernel/xnu/osfmk/x86_64/start.s:101:	.globl	EXT(mc_task_stack) 对应 

.//src/Kernel/xnu/osfmk/i386/seg.h:208:extern char                     mc_task_stack[];


#### 4.在 asm.h 中， EXT 为连词符
#ifndef __NO_UNDERSCORES__
#define	LCL(x)	L ## x
#define EXT(x) _ ## x
#define LEXT(x) _ ## x ## :
#else
#define	LCL(x)	.L ## x
#define EXT(x) x
#define LEXT(x) x ## :
#endif


#### 5.    .space	INTSTACK_SIZE


.//src/Kernel/xnu/osfmk/mach/i386/vm_param.h:254:# define INTSTACK_SIZE (I386_PGBYTES*4*4)

#define I386_PGBYTES            4096            /* bytes per 80386 page */

#### 6. kernel mach-o 的链接处理 .//src/Kernel/xnu/cmake/MakeInc.def.in

# KASLR static slide config:
ifndef SLIDE
SLIDE=0x00
endif
KERNEL_MIN_ADDRESS      = 0xffffff8000000000
KERNEL_BASE_OFFSET      = 0x100000
KERNEL_STATIC_SLIDE     = $(shell printf "0x%016x" \
			  $$[ $(SLIDE) << 21 ])
KERNEL_STATIC_BASE      = $(shell printf "0x%016x" \
			  $$[ $(KERNEL_MIN_ADDRESS) + $(KERNEL_BASE_OFFSET) ])
KERNEL_HIB_SECTION_BASE = $(shell printf "0x%016x" \
			  $$[ $(KERNEL_STATIC_BASE) + $(KERNEL_STATIC_SLIDE) ])
KERNEL_TEXT_BASE        = $(shell printf "0x%016x" \
			  $$[ $(KERNEL_HIB_SECTION_BASE) + 0x100000 ])

LDFLAGS_KERNEL_RELEASEX86_64 = \
	-Wl,-pie \
	-Wl,-segaddr,__HIB,$(KERNEL_HIB_SECTION_BASE) \
	-Wl,-image_base,$(KERNEL_TEXT_BASE) \
	-Wl,-seg_page_size,__TEXT,0x200000 \
	-Wl,-sectalign,__HIB,__bootPT,0x1000 \
	-Wl,-sectalign,__HIB,__desc,0x1000 \
	-Wl,-sectalign,__HIB,__data,0x1000 \
	-Wl,-sectalign,__HIB,__text,0x1000 \
	-Wl,-sectalign,__HIB,__const,0x1000 \
	-Wl,-sectalign,__HIB,__bss,0x1000 \
	-Wl,-sectalign,__HIB,__common,0x1000 \
	-Wl,-sectalign,__HIB,__llvm_prf_cnts,0x1000 \
	-Wl,-sectalign,__HIB,__llvm_prf_names,0x1000 \
	-Wl,-sectalign,__HIB,__llvm_prf_data,0x1000 \
	-Wl,-sectalign,__HIB,__textcoal_nt,0x1000 \
	-Wl,-sectalign,__HIB,__cstring,0x1000 \
	-Wl,-rename_section,__DATA,__const,__DATA_CONST,__const \
	-Wl,-segprot,__DATA_CONST,r--,r-- \
	-Wl,-no_zero_fill_sections \
	$(LDFLAGS_NOSTRIP_FLAG)

KERNEL_HIB_SECTION_BASE = 0xffffff8000000000 + 0x100000 = FFFFFF8000100000





#### 7. kernel的 entry 方法为，在 __HIB, __text 段中
.code32
	.text
	.section __HIB, __text
	.align	ALIGN
	.globl	EXT(_start)
	.globl	EXT(pstart)
LEXT(_start)
LEXT(pstart)

汇编表现为：

__text:FFFFFF800010006C                 align 1000h
__text:FFFFFF8000101000
__text:FFFFFF8000101000                 public _pstart
__text:FFFFFF8000101000 _pstart:                                ; __start
__text:FFFFFF8000101000                 mov     edi, eax
__text:FFFFFF8000101002                 mov     esp, 19B000h
__text:FFFFFF8000101007                 mov     eax, 102040h
__text:FFFFFF800010100C                 lgdt    fword ptr [rax]
__text:FFFFFF800010100F                 mov     eax, 106000h
__text:FFFFFF8000101014                 add     [rax], eax
__text:FFFFFF8000101016                 add     [rax+0FF8h], eax
__text:FFFFFF800010101C                 mov     edx, 107000h
__text:FFFFFF8000101021                 add     [rdx], eax
__text:FFFFFF8000101023                 add     [rdx+8], eax
__text:FFFFFF8000101026                 add     [rdx+10h], eax
__text:FFFFFF8000101029                 add     [rdx+18h], eax
__text:FFFFFF800010102C ; START OF FUNCTION CHUNK FOR _slave_pstart


#### 8. POSTCODE 和 PSTART_ENTRY

	POSTCODE(PSTART_ENTRY)


#define PSTART_ENTRY                    0xFF


DEBUG_POSTCODE 模式下

#define POSTCODE(XX)                    \
	mov	$(XX), %al;             \
	POSTCODE_AL

#define POSTCODE_AL                     \
	outb    %al,$(POSTPORT);        \
	movl	$(SPINCOUNT), %eax;     \

#define POSTPORT 0x80
#define SPINCOUNT       300000000

非 DEBUG_POSTCODE 模式下


#else   /* DEBUG_POSTCODE */
#define POSTCODE_AL
#define POSTCODE_AX
#define POSTCODE(X)
#define POSTCODE2(X)
#define POSTCODE_SAVE_EAX(X)
#define POSTCODE32_EBX
#endif  /* DEBUG_POSTCODE */


#### 9.预编译 start.s

clang -I../kern/ -I../ -I/Users/lee/Desktop/Computer_Systems/Macos/PureDarwin/build/src/Kernel/xnu/xnu_build/src/xnu-build/RELEASE_X86_64/osfmk/RELEASE -E start.s -o start_e.s


#### 10.页表 

#define PML4_PROT (INTEL_PTE_VALID | INTEL_PTE_WRITE)
pml4_entry_t    BootPML4[PTE_PER_PAGE]
__attribute__((section("__HIB, __bootPT"))) = {
	[0]                     = ((uint64_t)(PAGE_SIZE) | PML4_PROT),
	[KERNEL_PML4_INDEX]     = ((uint64_t)(PAGE_SIZE) | PML4_PROT),
};

#define PDPT_PROT (INTEL_PTE_VALID | INTEL_PTE_WRITE)
pdpt_entry_t    BootPDPT[PTE_PER_PAGE]
__attribute__((section("__HIB, __bootPT"))) = {
	[0]     = ((uint64_t)(2 * PAGE_SIZE) | PDPT_PROT),
	[1]     = ((uint64_t)(3 * PAGE_SIZE) | PDPT_PROT),
	[2]     = ((uint64_t)(4 * PAGE_SIZE) | PDPT_PROT),
	[3]     = ((uint64_t)(5 * PAGE_SIZE) | PDPT_PROT),
};

.//src/Kernel/xnu/osfmk/i386/pmap.h:216:#define KERNEL_PML4_INDEX               511

.//src/Kernel/xnu/osfmk/i386/pmap.h:217:#define KERNEL_KEXTS_INDEX              (KERNEL_PML4_INDEX - 1)         /* 510: Home of KEXTs - the basement */

_BootPML4 数组大小为 0x1000，为512 个8字节的 uint64_t

__bootPT:FFFFFF8000106000 _BootPML4       db    3                 ; DATA XREF: __text:FFFFFF800010100F↑o
__bootPT:FFFFFF8000106000                                         ; __text:FFFFFF800010101C↑o ...
__bootPT:FFFFFF8000106001                 db  10h


__bootPT:FFFFFF8000107000                 public _BootPDPT
__bootPT:FFFFFF8000107000 _BootPDPT       db    3
__bootPT:FFFFFF8000107001                 db  20h

__bootPT:FFFFFF8000108000                 public _BootPTD
__bootPT:FFFFFF8000108000 _BootPTD        db  83h                 ; DATA XREF: _hibernate_restore_phys_page+4B↑o
__bootPT:FFFFFF8000108000                                         ; _pal_hib_map+4C↑o


#### 11.获取 start.s 的编译选项

1.在 PureDarwin/src/Kernel/xnu/makedefs/MakeInc.rule 文件中添加 S_RULE_2=@echo "$(LOG_AS) $(_v)${S_KCC} -c ${SFLAGS} -MD -MF $(@:o=d) -MP ${$@_SFLAGS_ADD} ${INCFLAGS} ${$@_INCFLAGS} $(<F)"

2.编译时输出log如下：

/bin/sh: -c: line 0: `echo "printf "%15s %s\n" "AS" @clang -c -D__ASSEMBLER__ -DASSEMBLER   -arch x86_64 -Dx86_64 -DX86_64 -D__X86_64__ -DLP64 -DPAGE_SIZE_FIXED -mkernel -msoft-float -DKERNEL_BASE_OFFSET=0x100000  -mmacosx-version-min=11.0 -DXNU_TARGET_OS_OSX -DPLATFORM_MacOSX -DAPPLE -DKERNEL -DKERNEL_PRIVATE -DXNU_KERNEL_PRIVATE -DPRIVATE -D__MACHO__=1 -Dvolatile=__volatile -DXNU_KERN_EVENT_DATA_IS_VLA -DINET -DMACH -DMACH_COMPAT -DMACH_FASTLINK -DNO_DIRECT_RPC -DVLAN -DBOND -DIF_FAKE -DAH_ALL_CRYPTO -DPF -DPFLOG -DDUMMYNET -DTRAFFIC_MGT -DMULTICAST -DICMP_BANDLIM -DIFNET_INPUT_SANITY_CHK -DMULTIPATH -DMPTCP -DSYSV_SEM -DSYSV_MSG -DSYSV_SHM -DPSYNCH -DFLOW_DIVERT -DNECP -DCONTENT_FILTER -DOLD_SEMWAIT_SIGNAL -DSOCKETS -DSENDFILE -DNETWORKING -DCONFIG_FSE -DCONFIG_IMAGEBOOT -DCONFIG_MBUF_JUMBO -DCONFIG_IMAGEBOOT_CHUNKLIST -DCONFIG_WORKQUEUE -DFIFO -DFDESC -DDEVFS -DNULLFS -DBINDFS -DFS_COMPRESSION -DCONFIG_DEV_KMEM -DQUOTA -DNAMEDSTREAMS -DCONFIG_APPLEDOUBLE -DCONFIG_VOLFS -DCONFIG_IMGSRC_ACCESS -DCONFIG_TRIGGERS -DCONFIG_EXT_RESOLVER -DCONFIG_SEARCHFS -DCONFIG_MNT_SUID -DCONFIG_MNT_ROOTSNAP -DCONFIG_ROSV_STARTUP -DCONFIG_FIRMLINKS -DCONFIG_MOUNT_VM -DCONFIG_MOUNT_PREBOOTRECOVERY -DCONFIG_DATALESS_FILES -DCONFIG_BASESYSTEMROOT -DNFSCLIENT -DNFSSERVER -DCONFIG_NFS_GSS -DCONFIG_NFS4 -DCONFIG_NETBOOT -DIPSEC -DIPSEC_ESP -DCRYPTO_SHA2 -DCONFIG_IMG4 -DZLIB -DIF_BRIDGE -DCONFIG_KN_HASHSIZE="64" -DCONFIG_VNODES="263168" -DCONFIG_NC_HASH="4096" -DCONFIG_VFS_NAMES="4096" -DCONFIG_MAX_CLUSTERS="8" -DCONFIG_MIN_NBUF="256" -DCONFIG_MIN_NIOBUF="128" -DCONFIG_NMBCLUSTERS="((1024 * 512) / MCLBYTES)" -DCONFIG_TCBHASHSIZE="4096" -DCONFIG_ICMP_BANDLIM="250" -DCONFIG_AIO_MAX="90" -DCONFIG_AIO_PROCESS_MAX="16" -DCONFIG_AIO_THREAD_COUNT="4" -DCONFIG_MAXVIFS="32" -DCONFIG_MFCTBLSIZ="256" -DCONFIG_MSG_BSIZE_REL="131072" -DCONFIG_MSG_BSIZE_DEV="131072" -DCONFIG_MSG_BSIZE="CONFIG_MSG_BSIZE_REL" -DCONFIG_IPC_TABLE_ENTRIES_STEPS="256" -DCONFIG_IPC_KERNEL_MAP_SIZE="64" -DCONFIG_VSPRINTF -DCONFIG_DYNAMIC_CODE_SIGNING -DCONFIG_CODE_DECRYPTION -DCONFIG_PROTECT -DCONFIG_KEYPAGE_WP -DCONFIG_MEMORYSTATUS -DCONFIG_DIRTYSTATUS_TRACKING -DCONFIG_PHYS_WRITE_ACCT -DVM_PRESSURE_EVENTS -DCONFIG_BACKGROUND_QUEUE -DCONFIG_IOSCHED -DCONFIG_TELEMETRY -DCONFIG_PROC_UUID_POLICY -DCONFIG_COREDUMP -DIOKITCPP -DIOKITSTATS -DCONFIG_SLEEP -DCONFIG_MAX_THREADS="500" -DLIBKERNCPP -DCONFIG_BLOCKS -DCONFIG_KEC_FIPS -DCONFIG_KEXT_BASEMENT -DCONFIG_PERSONAS -DCONFIG_MACF -DCONFIG_MACF_SOCKET_SUBSET -DCONFIG_AUDIT -DCONFIG_ARCADE -DCONFIG_SETUID -DCONFIG_KAS_INFO -DCONFIG_ZLEAKS -DKPERF -DKPC -DPGO -DMACH_BSD -DIOKIT -DCONFIG_THREAD_MAX="2560" -DCONFIG_TASK_MAX="1024" -DCONFIG_ZONE_MAP_MIN="120586240" -DCONFIG_ZLEAK_ALLOCATION_MAP_NUM="16384" -DCONFIG_ZLEAK_TRACE_MAP_NUM="8192" -DCONFIG_SCHED_TRADITIONAL -DCONFIG_SCHED_MULTIQ -DCONFIG_SCHED_TIMESHARE_CORE -DCONFIG_SCHED_SFI -DCONFIG_GZALLOC -DCONFIG_KDP_INTERACTIVE_DEBUGGING -DCONFIG_TASKWATCH -DCONFIG_USER_NOTIFICATION -DCONFIG_ATM -DCONFIG_COALITIONS -DCONFIG_SYSDIAGNOSE -DCONFIG_CSR -DSERIAL_CONSOLE -DVIDEO_CONSOLE -DCONFIG_REQUIRES_U32_MUNGING -DCOPYOUT_SHIM -DCONFIG_MACH_BRIDGE_SEND_TIME -DCONFIG_32BIT_TELEMETRY -DCONFIG_DELAY_IDLE_SLEEP -DCONFIG_PROC_UDATA_STORAGE -DPAL_I386 -DCONFIG_MCA -DCONFIG_VMX -DCONFIG_MTRR -DCONFIG_MACF_LAZY_VNODE_LABELS -DHYPERVISOR -DCONFIG_MACH_APPROXIMATE_TIME -URC_ENABLE_XNU_PRODUCT_INFO_FILTER -include meta_features.h -MD -MF start.d -MP  -I. -I/Users/lee/Desktop/Computer_Systems/Macos/PureDarwin/src/Kernel/xnu/osfmk -I/Users/lee/Desktop/Computer_Systems/Macos/PureDarwin/build/src/Kernel/xnu/xnu_build/src/xnu-build/EXPORT_HDRS/osfmk  -I/Users/lee/Desktop/Computer_Systems/Macos/PureDarwin/build/src/Kernel/xnu/xnu_build/src/xnu-build/EXPORT_HDRS/bsd  -I/Users/lee/Desktop/Computer_Systems/Macos/PureDarwin/build/src/Kernel/xnu/xnu_build/src/xnu-build/EXPORT_HDRS/libkern  -I/Users/lee/Desktop/Computer_Systems/Macos/PureDarwin/build/src/Kernel/xnu/xnu_build/src/xnu-build/EXPORT_HDRS/iokit  -I/Users/lee/Desktop/Computer_Systems/Macos/PureDarwin/build/src/Kernel/xnu/xnu_build/src/xnu-build/EXPORT_HDRS/pexpert  -I/Users/lee/Desktop/Computer_Systems/Macos/PureDarwin/build/src/Kernel/xnu/xnu_build/src/xnu-build/EXPORT_HDRS/libsa  -I/Users/lee/Desktop/Computer_Systems/Macos/PureDarwin/build/src/Kernel/xnu/xnu_build/src/xnu-build/EXPORT_HDRS/security  -I/Users/lee/Desktop/Computer_Systems/Macos/PureDarwin/build/src/Kernel/xnu/xnu_build/src/xnu-build/EXPORT_HDRS/san -I/Users/lee/Desktop/Computer_Systems/Macos/PureDarwin/src/Kernel/xnu/EXTERNAL_HEADERS -I/Users/lee/Desktop/Computer_Systems/Macos/PureDarwin/src/Libraries/libSystem/pthread/include -I/Users/lee/Desktop/Computer_Systems/Macos/PureDarwin/src/Kernel/xnu/osfmk/libsa -I/Users/lee/Desktop/Computer_Systems/Macos/PureDarwin/src/Kernel/libfirehose_kernel/include  start.s"'


3.makefile 设计


-# Makefile

-# 编译器
CC = gcc

-# 汇编器
AS = clang

-# 编译选项
CFLAGS = -g -Wall

-# 汇编选项
ASFLAGS = -c -D__ASSEMBLER__ -DASSEMBLER   -arch x86_64 -Dx86_64 -DX86_64 -D__X86_64__ -DLP64 -DPAGE_SIZE_FIXED -mkernel -msoft-float -DKERNEL_BASE_OFFSET=0x100000  -mmacosx-version-min=11.0 -DXNU_TARGET_OS_OSX -DPLATFORM_MacOSX -DAPPLE -DKERNEL -DKERNEL_PRIVATE -DXNU_KERNEL_PRIVATE -DPRIVATE -D__MACHO__=1 -Dvolatile=__volatile -DXNU_KERN_EVENT_DATA_IS_VLA -DINET -DMACH -DMACH_COMPAT -DMACH_FASTLINK -DNO_DIRECT_RPC -DVLAN -DBOND -DIF_FAKE -DAH_ALL_CRYPTO -DPF -DPFLOG -DDUMMYNET -DTRAFFIC_MGT -DMULTICAST -DICMP_BANDLIM -DIFNET_INPUT_SANITY_CHK -DMULTIPATH -DMPTCP -DSYSV_SEM -DSYSV_MSG -DSYSV_SHM -DPSYNCH -DFLOW_DIVERT -DNECP -DCONTENT_FILTER -DOLD_SEMWAIT_SIGNAL -DSOCKETS -DSENDFILE -DNETWORKING -DCONFIG_FSE -DCONFIG_IMAGEBOOT -DCONFIG_MBUF_JUMBO -DCONFIG_IMAGEBOOT_CHUNKLIST -DCONFIG_WORKQUEUE -DFIFO -DFDESC -DDEVFS -DNULLFS -DBINDFS -DFS_COMPRESSION -DCONFIG_DEV_KMEM -DQUOTA -DNAMEDSTREAMS -DCONFIG_APPLEDOUBLE -DCONFIG_VOLFS -DCONFIG_IMGSRC_ACCESS -DCONFIG_TRIGGERS -DCONFIG_EXT_RESOLVER -DCONFIG_SEARCHFS -DCONFIG_MNT_SUID -DCONFIG_MNT_ROOTSNAP -DCONFIG_ROSV_STARTUP -DCONFIG_FIRMLINKS -DCONFIG_MOUNT_VM -DCONFIG_MOUNT_PREBOOTRECOVERY -DCONFIG_DATALESS_FILES -DCONFIG_BASESYSTEMROOT -DNFSCLIENT -DNFSSERVER -DCONFIG_NFS_GSS -DCONFIG_NFS4 -DCONFIG_NETBOOT -DIPSEC -DIPSEC_ESP -DCRYPTO_SHA2 -DCONFIG_IMG4 -DZLIB -DIF_BRIDGE -DCONFIG_KN_HASHSIZE="64" -DCONFIG_VNODES="263168" -DCONFIG_NC_HASH="4096" -DCONFIG_VFS_NAMES="4096" -DCONFIG_MAX_CLUSTERS="8" -DCONFIG_MIN_NBUF="256" -DCONFIG_MIN_NIOBUF="128" -DCONFIG_NMBCLUSTERS="((1024 * 512) / MCLBYTES)" -DCONFIG_TCBHASHSIZE="4096" -DCONFIG_ICMP_BANDLIM="250" -DCONFIG_AIO_MAX="90" -DCONFIG_AIO_PROCESS_MAX="16" -DCONFIG_AIO_THREAD_COUNT="4" -DCONFIG_MAXVIFS="32" -DCONFIG_MFCTBLSIZ="256" -DCONFIG_MSG_BSIZE_REL="131072" -DCONFIG_MSG_BSIZE_DEV="131072" -DCONFIG_MSG_BSIZE="CONFIG_MSG_BSIZE_REL" -DCONFIG_IPC_TABLE_ENTRIES_STEPS="256" -DCONFIG_IPC_KERNEL_MAP_SIZE="64" -DCONFIG_VSPRINTF -DCONFIG_DYNAMIC_CODE_SIGNING -DCONFIG_CODE_DECRYPTION -DCONFIG_PROTECT -DCONFIG_KEYPAGE_WP -DCONFIG_MEMORYSTATUS -DCONFIG_DIRTYSTATUS_TRACKING -DCONFIG_PHYS_WRITE_ACCT -DVM_PRESSURE_EVENTS -DCONFIG_BACKGROUND_QUEUE -DCONFIG_IOSCHED -DCONFIG_TELEMETRY -DCONFIG_PROC_UUID_POLICY -DCONFIG_COREDUMP -DIOKITCPP -DIOKITSTATS -DCONFIG_SLEEP -DCONFIG_MAX_THREADS="500" -DLIBKERNCPP -DCONFIG_BLOCKS -DCONFIG_KEC_FIPS -DCONFIG_KEXT_BASEMENT -DCONFIG_PERSONAS -DCONFIG_MACF -DCONFIG_MACF_SOCKET_SUBSET -DCONFIG_AUDIT -DCONFIG_ARCADE -DCONFIG_SETUID -DCONFIG_KAS_INFO -DCONFIG_ZLEAKS -DKPERF -DKPC -DPGO -DMACH_BSD -DIOKIT -DCONFIG_THREAD_MAX="2560" -DCONFIG_TASK_MAX="1024" -DCONFIG_ZONE_MAP_MIN="120586240" -DCONFIG_ZLEAK_ALLOCATION_MAP_NUM="16384" -DCONFIG_ZLEAK_TRACE_MAP_NUM="8192" -DCONFIG_SCHED_TRADITIONAL -DCONFIG_SCHED_MULTIQ -DCONFIG_SCHED_TIMESHARE_CORE -DCONFIG_SCHED_SFI -DCONFIG_GZALLOC -DCONFIG_KDP_INTERACTIVE_DEBUGGING -DCONFIG_TASKWATCH -DCONFIG_USER_NOTIFICATION -DCONFIG_ATM -DCONFIG_COALITIONS -DCONFIG_SYSDIAGNOSE -DCONFIG_CSR -DSERIAL_CONSOLE -DVIDEO_CONSOLE -DCONFIG_REQUIRES_U32_MUNGING -DCOPYOUT_SHIM -DCONFIG_MACH_BRIDGE_SEND_TIME -DCONFIG_32BIT_TELEMETRY -DCONFIG_DELAY_IDLE_SLEEP -DCONFIG_PROC_UDATA_STORAGE -DPAL_I386 -DCONFIG_MCA -DCONFIG_VMX -DCONFIG_MTRR -DCONFIG_MACF_LAZY_VNODE_LABELS -DHYPERVISOR -DCONFIG_MACH_APPROXIMATE_TIME -URC_ENABLE_XNU_PRODUCT_INFO_FILTER -include meta_features.h -MD -MF start.d -MP  -I. -I/Users/lee/Desktop/Computer_Systems/Macos/PureDarwin/src/Kernel/xnu/osfmk -I/Users/lee/Desktop/Computer_Systems/Macos/PureDarwin/build/src/Kernel/xnu/xnu_build/src/xnu-build/EXPORT_HDRS/osfmk  -I/Users/lee/Desktop/Computer_Systems/Macos/PureDarwin/build/src/Kernel/xnu/xnu_build/src/xnu-build/EXPORT_HDRS/bsd  -I/Users/lee/Desktop/Computer_Systems/Macos/PureDarwin/build/src/Kernel/xnu/xnu_build/src/xnu-build/EXPORT_HDRS/libkern  -I/Users/lee/Desktop/Computer_Systems/Macos/PureDarwin/build/src/Kernel/xnu/xnu_build/src/xnu-build/EXPORT_HDRS/iokit  -I/Users/lee/Desktop/Computer_Systems/Macos/PureDarwin/build/src/Kernel/xnu/xnu_build/src/xnu-build/EXPORT_HDRS/pexpert  -I/Users/lee/Desktop/Computer_Systems/Macos/PureDarwin/build/src/Kernel/xnu/xnu_build/src/xnu-build/EXPORT_HDRS/libsa  -I/Users/lee/Desktop/Computer_Systems/Macos/PureDarwin/build/src/Kernel/xnu/xnu_build/src/xnu-build/EXPORT_HDRS/security  -I/Users/lee/Desktop/Computer_Systems/Macos/PureDarwin/build/src/Kernel/xnu/xnu_build/src/xnu-build/EXPORT_HDRS/san -I/Users/lee/Desktop/Computer_Systems/Macos/PureDarwin/src/Kernel/xnu/EXTERNAL_HEADERS -I/Users/lee/Desktop/Computer_Systems/Macos/PureDarwin/src/Libraries/libSystem/pthread/include -I/Users/lee/Desktop/Computer_Systems/Macos/PureDarwin/src/Kernel/xnu/osfmk/libsa -I/Users/lee/Desktop/Computer_Systems/Macos/PureDarwin/src/Kernel/libfirehose_kernel/include -I/Users/lee/Desktop/Computer_Systems/Macos/PureDarwin/src/Kernel/xnu/ -I/Users/lee/Desktop/Computer_Systems/Macos/PureDarwin/src/Kernel/xnu/kern/ -I/Users/lee/Desktop/Computer_Systems/Macos/PureDarwin/build/src/Kernel/xnu/xnu_build/src/xnu-build/RELEASE_X86_64/osfmk/RELEASE/

-# 目标文件
OBJS = start.o

-# 默认目标
all: main

-# 生成可执行文件
main: $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^

-# 生成目标文件
%.o: %.s
	$(AS) $(ASFLAGS) -o $@ $<

-# 清理生成的文件
clean:
	rm -f main $(OBJS)




#### 12.SWITCH_TO_64BIT_MODE


	/* Must not clobber EDI */
#define SWITCH_TO_64BIT_MODE					 \
    /** #define CR4_PAE         0x00000020 == 1 << 5，CR4.pae 位置为1 */ \
	movl	$(CR4_PAE),%eax		/* enable PAE */	;\
    /** 将eax赋值给cr4，CR4.pae 位置为1，开启cr4.pae的位，即开启分页模式 */   \
	movl	%eax,%cr4					;\
    /** :#define MSR_IA32_EFER  0xC0000080，赋值给 ecx寄存器 */ \
	movl    $MSR_IA32_EFER,%ecx				;\
    /** 读取 MSR 寄存器的值到 EDX:EAX 中*/     \
	rdmsr							;\
	/* enable long mode, NX */				;\
    /** 设置 MSR_IA32_EFER_LME 0x00000100 = 1 << 8 ,MSR_IA32_EFER_NXE                       0x00000800 = 1 << 11,将 %eax 中的第9、12位置为1 */    \
	orl	$(MSR_IA32_EFER_LME | MSR_IA32_EFER_NXE),%eax	;\
    /** 重新将 修改后的 EDX:EAX 写入 MSR 寄存器 ，开启长模式 */   \
	wrmsr							;\
    /** 获取 BootPML4 页目录的地址，赋值给 eax寄存器 */  \
	movl	$EXT(BootPML4),%eax				;\
    /** 将 eax 寄存器的值赋值给 cr3 */   \
	movl	%eax,%cr3					;\
    /** 将 cr0 寄存器的值赋值给 eax寄存器 */ \
	movl	%cr0,%eax					;\
    /** #define CR0_PG  0x80000000  #define CR0_WP  0x00010000 ,将 eax 对应位置为1，开启分页  */ \
	orl	$(CR0_PG|CR0_WP),%eax	/* enable paging */	;\
    /** 把 eax值回写给 cr0，开启分页*/  \
	movl	%eax,%cr0					;\
    /** 长跳转64位代码，正式进入64，#define KERNEL64_CS     0x08  , KERNEL64_CS 代表64位代码段选择子在gdt的位置，64f代表下面的64:,即跳转到下面的 64位代码段 */ \
	ljmpl	$KERNEL64_CS,$64f				;\
64:								;\
    /** .code64 表示下面的代码是 64 代码 */ \
	.code64
