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
