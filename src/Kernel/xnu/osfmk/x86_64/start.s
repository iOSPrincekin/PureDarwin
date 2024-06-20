/*
 * Copyright (c) 2007 Apple Inc. All rights reserved.
 *
 * @APPLE_OSREFERENCE_LICENSE_HEADER_START@
 * 
 * This file contains Original Code and/or Modifications of Original Code
 * as defined in and that are subject to the Apple Public Source License
 * Version 2.0 (the 'License'). You may not use this file except in
 * compliance with the License. The rights granted to you under the License
 * may not be used to create, or enable the creation or redistribution of,
 * unlawful or unlicensed copies of an Apple operating system, or to
 * circumvent, violate, or enable the circumvention or violation of, any
 * terms of an Apple operating system software license agreement.
 * 
 * Please obtain a copy of the License at
 * http://www.opensource.apple.com/apsl/ and read it before using this file.
 * 
 * The Original Code and all software distributed under the License are
 * distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR NON-INFRINGEMENT.
 * Please see the License for the specific language governing rights and
 * limitations under the License.
 * 
 * @APPLE_OSREFERENCE_LICENSE_HEADER_END@
 */
/*
 * @OSF_COPYRIGHT@
 */
/* 
 * Mach Operating System
 * Copyright (c) 1991,1990 Carnegie Mellon University
 * All Rights Reserved.
 * 
 * Permission to use, copy, modify and distribute this software and its
 * documentation is hereby granted, provided that both the copyright
 * notice and this permission notice appear in all copies of the
 * software, derivative works or modified versions, and any portions
 * thereof, and that both notices appear in supporting documentation.
 * 
 * CARNEGIE MELLON ALLOWS FREE USE OF THIS SOFTWARE IN ITS "AS IS"
 * CONDITION.  CARNEGIE MELLON DISCLAIMS ANY LIABILITY OF ANY KIND FOR
 * ANY DAMAGES WHATSOEVER RESULTING FROM THE USE OF THIS SOFTWARE.
 * 
 * Carnegie Mellon requests users of this software to return to
 * 
 *  Software Distribution Coordinator  or  Software.Distribution@CS.CMU.EDU
 *  School of Computer Science
 *  Carnegie Mellon University
 *  Pittsburgh PA 15213-3890
 * 
 * any improvements or extensions that they make and grant Carnegie Mellon
 * the rights to redistribute these changes.
 */
/*
 */

#include <debug.h>

#include <i386/asm.h>
#include <i386/proc_reg.h>
#include <i386/postcode.h>
#include <assym.s>

#include <i386/cpuid.h>
#include <i386/acpi.h>

.code32


/*
 * Interrupt and bootup stack for initial processor.
 * Note: we switch to a dynamically allocated interrupt stack once VM is up.
 */

/* in the __HIB section since the hibernate restore code uses this stack. */
	.section __HIB, __data
	.align	12

	.globl	EXT(low_intstack)
EXT(low_intstack):
	.globl  EXT(gIOHibernateRestoreStack)
EXT(gIOHibernateRestoreStack):

	.space	INTSTACK_SIZE

	.globl	EXT(low_eintstack)
EXT(low_eintstack:)
	.globl  EXT(gIOHibernateRestoreStackEnd)
EXT(gIOHibernateRestoreStackEnd):

	/* back to the regular __DATA section. */

	.section __DATA, __data

/*
 * Stack for machine-check handler.
 */
	.align	12
	.globl	EXT(mc_task_stack)
EXT(mc_task_stack):
	.space	INTSTACK_SIZE
	.globl	EXT(mc_task_stack_end)
EXT(mc_task_stack_end):

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
64:								;\
    /** .code64 表示下面的代码是 64 代码 */ \
	.code64

/*
 * BSP CPU start here.
 *	eax points to kernbootstruct
 *
 * Environment:
 *	protected mode, no paging, flat 32-bit address space.
 *	(Code/data/stack segments have base == 0, limit == 4G)
 */
	
.code32
	.text
	.section __HIB, __text
	.align	ALIGN
	.globl	EXT(_start)
	.globl	EXT(pstart)
LEXT(_start)
LEXT(pstart)

/*
 * Here we do the minimal setup to switch from 32 bit mode to 64 bit long mode.
 *
 * Initial memory layout:
 *
 *	-------------------------
 *	|			|
 *	| Kernel text/data	|
 *	|			|
 *	|-----------------------| Kernel text base addr - 2MB-aligned
 *	| padding		|
 *	|-----------------------|
 *	| __HIB section		|
 *	|-----------------------| Page-aligned
 *	|			|
 *	| padding		|
 *	|			|
 *	------------------------- 0
 *
 */	
    /** 1.保存 kernbootstruct */
	mov	%eax, %edi	/* save kernbootstruct */

    /** 2.使用低32位栈，大小为 I386_PGBYTES*4*4，#define I386_PGBYTES            4096  */
	/* Use low 32-bits of address as 32-bit stack */
	movl	$EXT(low_eintstack), %esp
	/** 3.非debug 模式，不产生任何代码 */
	POSTCODE(PSTART_ENTRY)

	/*
	 * Set up segmentation
	 */
    /** 4.获取保护模式的全局描述符地址 */
	movl	$EXT(protected_mode_gdtr), %eax
    /** 5.lgdt 指令为其指定全局描述符表的地址及偏移 量 */
	lgdtl	(%eax)

	/*
	 * Rebase Boot page tables to kernel base address.
	 */
    /** 6.获取页表数组地址 BootPML4 数组大小为 0x1000，为512 个8字节的 uint64_t */
	movl	$EXT(BootPML4), %eax			// Level 4:
    /** 7.BootPML4 页表的地址存入第1个元素 */
	add	%eax, 0*8+0(%eax)			//  - 1:1
    /** 8.BootPML4 页表的地址存入最后1个元素 */
	add	%eax, KERNEL_PML4_INDEX*8+0(%eax)	//  - kernel space
    
    /** 9.获取页表数组地址 BootPDPT 数组大小为 0x1000，为512 个8字节的 uint64_t */
	movl	$EXT(BootPDPT), %edx			// Level 3:
    /** 10.BootPML4 页表的地址存入BootPDPT第1个元素 */
	add	%eax, 0*8+0(%edx)
    /** 11.BootPML4 页表的地址存入BootPDPT第2个元素 */
	add	%eax, 1*8+0(%edx)
    /** 12.BootPML4 页表的地址存入BootPDPT第3个元素 */
	add	%eax, 2*8+0(%edx)
    /** 13.BootPML4 页表的地址存入BootPDPT第4个元素 */
	add	%eax, 3*8+0(%edx)

    /** 非debug 模式，忽略*/
	POSTCODE(PSTART_REBASE)

/* the following code is shared by the master CPU and all slave CPUs */
L_pstart_common:
    /** 切换到 64位 模式 */
	/*
	 * switch to 64 bit mode
	 */
	SWITCH_TO_64BIT_MODE

	/* Flush data segment selectors */
    /** 刷新段寄存器，全部设置为 0 */
	xor	%eax, %eax
	mov	%ax, %ss
	mov	%ax, %ds
	mov	%ax, %es
	mov	%ax, %fs
	mov	%ax, %gs

    /** 这个指令对 %edi 寄存器与自身进行按位与（AND）操作 */
    /** stack canaries 又稱為 stack protector, 此方法會在程式中加入 “canary value". 之所以會稱之為金絲雀 (canary) 是因為早期煤礦工人常會在工作時發生急性一氧化碳(煤氣)中毒事件. 但以前沒有先進裝備來偵測一氧化碳(煤氣), 所以煤礦工人都會帶金絲雀 (canary) 進去礦坑工作. 原因是金絲雀對一氧化碳(煤氣)非常敏感, 些許煤氣就會讓金絲雀啼叫甚至死亡. 因此礦工會將金絲雀放在礦坑中作為是否需要逃生的依據.
     
     同理可知, 若我們先在程式中加入 “canary value", 若 buffer overflow 異常情況發生, 則會修改 “canary value". 所以我們可透過檢查 “canary value" 是否遭修改來決定程式是否繼續往下執行或者中止結束.*/
    /** "BSP" 是 "Bootstrap Processor" 的缩写，可以理解为引导处理器。在多处理器系统中，引导处理器是系统启动时负责初始化和引导操作系统的主要处理器。
        如果一切正常，CPU就开始运行了。在一个多处理器或多核处理器的系统中，会有一个CPU被动态的指派为引导处理器（bootstrap processor，简写为BSP），用于执行全部的BIOS和内核初始化代码。其余的处理器，此时被称为应用处理器（application processor，简写为AP），一直保持停机状态直到内核明确激活他们为止。*/
	test	%edi, %edi /* Populate stack canary on BSP */
    /** 如果 test    %edi, %edi 结果为0 即 edi为 0，则跳转到 Lvstartshim */
	jz	Lvstartshim
    
    /** 将1赋值给 eax,作为 cpuid的参数 */
	mov	$1, %eax
    /** 将 eax中的 1 传给 cpuid，获取cpu版本信息：Type, Family, Model, and Stepping ID */
	cpuid
    /** 测试 ecx的 第31位是否为1 即 ECX.RDRAND[bit 30] = 1.
     RDRAND指令返回一个随机数。所有支持RDRAND指令的英特尔处理器通过报告CPUID.01H:ECX.RDRAND[bit 30] = 1来指示RDRAND指令的可用性。 */
	test	$(1 << 30), %ecx
    /** 如果 ECX.RDRAND[bit 30] == 0，则跳转到 Lnon_rdrand，即不支持 RDRAND */
	jz	Lnon_rdrand
    /** 随机生成 确定性（伪随机）数产生器（Deterministic Random Bit Generators (DRBG)） 的熵 ，
      存储到 rax寄存器中 */
	rdrand	%rax		/* RAX := 64 bits of DRBG entropy */
    /** 如果RDRAND指令没有执行成功（发生溢出），则跳转到 Lnon_rdrand  */
	jnc	Lnon_rdrand	/* TODO: complain if DRBG fails at this stage */

Lstore_random_guard:
    /** ah 寄存器置为 0 */
	xor	%ah, %ah	/* Security: zero second byte of stack canary */
    /** long __stack_chk_guard[GUARD_MAX] = {0, 0, 0, 0, 0, 0, 0, 0};  把rax的值写入 __stack_chk_guard*/
    /** %rip-relative addressing for global variables
     x86-64 code often refers to globals using %rip-relative addressing: a global variable named a is referenced as a(%rip). This style of reference supports position-independent code (PIC), a security feature. It specifically supports position-independent executables (PIEs), which are programs that work independently of where their code is loaded into memory.

     When the operating system loads a PIE, it picks a random starting point and loads all instructions and globals relative to that starting point. The PIE's instructions never refer to global variables using direct addressing: there is no movl global_int, %eax. Globals are referenced relatively instead, using deltas relative to the next %rip: to load a global variable into a register, the compiler emits movl global_int(%rip), %eax. These relative addresses work independent of the starting point! For instance, consider an instruction located at (starting-point + 0x80) that loads a variable g located at (starting-point + 0x1000) into %rax. In a non-PIE, the instruction might be written as movq g, %rax; but this relies on g having a fixed address. In a PIE, the instruction might be written movq g(%rip), %rax, which works out without having to know the starting address of the program's code in memory at compile time (instead, %rip contains a number some known number of bytes apart from the starting point, so any address relative to %rip is also relative to the starting point). ===> https://cs.brown.edu/courses/csci1310/2020/notes/l08.html */
    /** Note that symbol_name(%rip) calculates the offset required to reach symbol_name from here, rather than adding the absolute address of symbol_name to RIP as an offset.
     
     But yes, for numeric offsets like mov 4(%rip), %rax, that will load 8 bytes starting at 4 bytes past the end of this instruction. ===> https://stackoverflow.com/questions/29421766/what-does-mov-offsetrip-rax-do */
	movq	%rax, ___stack_chk_guard(%rip)
	/* %edi = boot_args_start if BSP */
Lvstartshim:	
    /** 非debug 模式，忽略*/
	POSTCODE(PSTART_VSTART)

	/* %edi = boot_args_start */
	/** 加载 _vstart 地址到 rcx 寄存器 */
	leaq	_vstart(%rip), %rcx
    /** #define PML4SHIFT  39 ; #define NBPML4  (1ULL << PML4SHIFT) ;
     #define KERNEL_PML4_COUNT  1; #define KERNEL_BASE (0ULL - (NBPML4 * KERNEL_PML4_COUNT))
     将 KERNEL_BASE 地址 即 -0x8000000000 = 0xffffff80 00000000 传给 寄存器 rax */
	movq	$(KERNEL_BASE), %rax		/* adjust pointer up high */
    /** 将 rsp 与 rax 寄存器进行或 运算，即  rsp = 0xffffff8000000000 + rsp */
	or	%rax, %rsp			/* and stack pointer up there */
    /** 将 rax 与 rcx 寄存器进行或 运算，即  rax = 0xffffff8000000000 + rcx，为 _vstart 方法的地址  */
	or	%rcx, %rax
    /** 对齐 rsp */
	andq	$0xfffffffffffffff0, %rsp	/* align stack */
    /** 将 rbp 置为 0 */
	xorq	%rbp, %rbp			/* zero frame pointer */
    /** 调用 vstart 方法 */
	callq	*%rax

Lnon_rdrand:
	rdtsc /* EDX:EAX := TSC */
	/* Distribute low order bits */
	mov	%eax, %ecx
	xor	%al, %ah
	shl	$16, %rcx
	xor	%rcx, %rax
	xor	%eax, %edx

	/* Incorporate ASLR entropy, if any */
	lea	(%rip), %rcx
	shr	$21, %rcx
	movzbl	%cl, %ecx
	shl	$16, %ecx
	xor	%ecx, %edx

	mov	%ah, %cl
	ror	%cl, %edx /* Right rotate EDX (TSC&0xFF ^ (TSC>>8 & 0xFF))&1F */
	shl	$32, %rdx
	xor	%rdx, %rax
	mov	%cl, %al
	jmp	Lstore_random_guard
/*
 * AP (slave) CPUs enter here.
 *
 * Environment:
 *	protected mode, no paging, flat 32-bit address space.
 *	(Code/data/stack segments have base == 0, limit == 4G)
 */
	.align	ALIGN
	.globl	EXT(slave_pstart)
LEXT(slave_pstart)
	.code32
	cli				/* disable interrupts, so we don`t */
					/* need IDT for a while */
	POSTCODE(SLAVE_PSTART)

	movl	$EXT(mp_slave_stack) + PAGE_SIZE, %esp

	xor 	%edi, %edi		/* AP, no "kernbootstruct" */

	jmp	L_pstart_common		/* hop a ride to vstart() */


/* BEGIN HIBERNATE CODE */

.section __HIB, __text
/*
 * This code is linked into the kernel but part of the "__HIB" section,
 * which means it's used by code running in the special context of restoring
 * the kernel text and data from the hibernation image read by the booter.
 * hibernate_kernel_entrypoint() and everything it calls or references
 * (ie. hibernate_restore_phys_page()) needs to be careful to only touch
 * memory also in the "__HIB" section.
 */

	.align	ALIGN
	.globl	EXT(hibernate_machine_entrypoint)
.code32
LEXT(hibernate_machine_entrypoint)
	movl    %eax, %edi /* regparm(1) calling convention */

	/* Use low 32-bits of address as 32-bit stack */
	movl $EXT(low_eintstack), %esp
	
	/*
	 * Set up GDT
	 */
	movl	$EXT(master_gdtr), %eax
	lgdtl	(%eax)

	/* Switch to 64-bit on the Boot PTs */
	SWITCH_TO_64BIT_MODE

	leaq	EXT(hibernate_kernel_entrypoint)(%rip),%rcx

	/* adjust the pointers to be up high */
	movq	$(KERNEL_BASE), %rax
	orq	%rax, %rsp
	orq	%rcx, %rax

	/* %edi is already filled with header pointer */
	xorl	%esi, %esi			/* zero 2nd arg */
	xorl	%edx, %edx			/* zero 3rd arg */
	xorl	%ecx, %ecx			/* zero 4th arg */
	andq	$0xfffffffffffffff0, %rsp	/* align stack */

	/* call instead of jmp to keep the required stack alignment */
	xorq	%rbp, %rbp			/* zero frame pointer */
	call	*%rax

	/* NOTREACHED */
	hlt

/* END HIBERNATE CODE */

#if CONFIG_SLEEP
/* BEGIN ACPI WAKEUP CODE */

#include <i386/acpi.h>


/*
 * acpi_wake_start
 */

.section __TEXT,__text
.code64

/*
 * acpi_sleep_cpu(acpi_sleep_callback func, void * refcon)
 *
 * Save CPU state before platform sleep. Restore CPU state
 * following wake up.
 */

ENTRY(acpi_sleep_cpu)
	push	%rbp
	mov	%rsp, %rbp

	/* save flags */
	pushf

	/* save general purpose registers */
	push %rax
	push %rbx
	push %rcx
	push %rdx
	push %rbp
	push %rsi
	push %rdi
	push %r8
	push %r9
	push %r10
	push %r11
	push %r12
	push %r13
	push %r14
	push %r15

	mov	%rsp, saved_rsp(%rip)

	/* make sure tlb is flushed */
	mov	%cr3,%rax
	mov	%rax,%cr3
	
	/* save control registers */
	mov	%cr0, %rax
	mov	%rax, saved_cr0(%rip)
	mov	%cr2, %rax
	mov	%rax, saved_cr2(%rip)
	mov	%cr3, %rax
	mov	%rax, saved_cr3(%rip)
	mov	%cr4, %rax
	mov	%rax, saved_cr4(%rip)

	/* save segment registers */
	movw	%es, saved_es(%rip)
	movw	%fs, saved_fs(%rip)
	movw	%gs, saved_gs(%rip)
	movw	%ss, saved_ss(%rip)	

	/* save the 64bit user and kernel gs base */
	/* note: user's curently swapped into kernel base MSR */
	mov	$MSR_IA32_KERNEL_GS_BASE, %rcx
	rdmsr
	movl	%eax, saved_ugs_base(%rip)
	movl	%edx, saved_ugs_base+4(%rip)
	swapgs
	rdmsr
	movl	%eax, saved_kgs_base(%rip)
	movl	%edx, saved_kgs_base+4(%rip)
	swapgs

	/* save descriptor table registers */
	sgdt	saved_gdt(%rip)
	sldt	saved_ldt(%rip)
	sidt	saved_idt(%rip)
	str	saved_tr(%rip)

	/*
	 * Call ACPI function provided by the caller to sleep the platform.
	 * This call will not return on success.
	 */

	xchgq %rdi, %rsi
	call	*%rsi

	/* sleep failed, no cpu context lost */
	jmp	wake_restore

.section __HIB, __text
.code32
.globl EXT(acpi_wake_prot)
EXT(acpi_wake_prot):
	/* protected mode, paging disabled */
	movl	$EXT(low_eintstack), %esp

	SWITCH_TO_64BIT_MODE

	jmp	Lwake_64

.section __TEXT,__text
.code64

.globl EXT(acpi_wake_prot_entry)
EXT(acpi_wake_prot_entry):
	POSTCODE(ACPI_WAKE_PROT_ENTRY)
	/* Return from hibernate code in iokit/Kernel/IOHibernateRestoreKernel.c
	 */
Lwake_64:
	/*
	 * restore cr4, PAE and NXE states in an orderly fashion
	 */
	mov	saved_cr4(%rip), %rcx
	mov	%rcx, %cr4

	mov	$(MSR_IA32_EFER), %ecx		/* MSR number in ecx */
	rdmsr					/* MSR value in edx:eax */
	or	$(MSR_IA32_EFER_NXE), %eax	/* Set NXE bit in low 32-bits */
	wrmsr					/* Update */

	movq	saved_cr2(%rip), %rax
	mov	%rax, %cr2

	/* restore CR0, paging enabled */
	mov	saved_cr0(%rip), %rax
	mov	%rax, %cr0

	/* restore the page tables */
	mov	saved_cr3(%rip), %rax
	mov	%rax, %cr3

	/* protected mode, paging enabled */
	POSTCODE(ACPI_WAKE_PAGED_ENTRY)

	/* load null segment selectors */
	xor	%eax, %eax
	movw	%ax, %ss
	movw	%ax, %ds

	/* restore descriptor tables */
	lgdt	saved_gdt(%rip)
	lldt	saved_ldt(%rip)
	lidt	saved_idt(%rip)

	/* restore segment registers */
	movw	saved_es(%rip), %es
	movw	saved_fs(%rip), %fs
	movw	saved_gs(%rip), %gs
	movw	saved_ss(%rip), %ss

	/* restore the 64bit kernel and user gs base */
	mov	$MSR_IA32_KERNEL_GS_BASE, %rcx
	movl	saved_kgs_base(%rip),   %eax 
	movl	saved_kgs_base+4(%rip), %edx 
	wrmsr
	swapgs
	movl	saved_ugs_base(%rip),   %eax 
	movl	saved_ugs_base+4(%rip), %edx 
	wrmsr

	/*
	 * Restore task register. Before doing this, clear the busy flag
	 * in the TSS descriptor set by the CPU.
	 */
	lea	saved_gdt(%rip), %rax
	movq	2(%rax), %rdx			/* GDT base, skip limit word */
	movl	$(KERNEL_TSS), %eax		/* TSS segment selector */
	movb	$(K_TSS), 5(%rdx, %rax)		/* clear busy flag */

	ltr	saved_tr(%rip)			/* restore TR */

wake_restore:
	mov	saved_rsp(%rip), %rsp 

	/* restore general purpose registers */
	pop %r15
	pop %r14
	pop %r13
	pop %r12
	pop %r11
	pop %r10
	pop %r9
	pop %r8
	pop %rdi
	pop %rsi
	pop %rbp
	pop %rdx
	pop %rcx
	pop %rbx
	pop %rax

	/* restore flags */
	popf

	leave
	ret

/* END ACPI WAKEUP CODE */
#endif /* CONFIG_SLEEP */

/* Code to get from real mode to protected mode */

#define	operand_size_prefix	.byte 0x66
#define	address_size_prefix	.byte 0x67
#define	cs_base_prefix		.byte 0x2e

#define	LJMP(segment,address)			\
	operand_size_prefix			;\
	.byte	0xea				;\
	.long	address-EXT(real_mode_bootstrap_base)	;\
	.word	segment

#define	LGDT(address)				\
	cs_base_prefix				;\
	address_size_prefix			;\
	operand_size_prefix			;\
	.word	0x010f				;\
	.byte	0x15				;\
	.long	address-EXT(real_mode_bootstrap_base)

.section __HIB, __text
.align	12	/* Page align for single bcopy_phys() */
.code32
Entry(real_mode_bootstrap_base)
	cli

	LGDT(EXT(protected_mode_gdtr))

	/* set the PE bit of CR0 */
	mov	%cr0, %eax
	inc %eax
	mov	%eax, %cr0 

	/* reload CS register */
	LJMP(KERNEL32_CS, 1f + REAL_MODE_BOOTSTRAP_OFFSET)
1:
	
	/* we are in protected mode now */
	/* set up the segment registers */
	mov	$KERNEL_DS, %eax
	movw	%ax, %ds
	movw	%ax, %es
	movw	%ax, %ss
	xor	%eax,%eax
	movw	%ax, %fs
	movw	%ax, %gs

	POSTCODE(SLAVE_STARTPROG_ENTRY);

	mov	PROT_MODE_START+REAL_MODE_BOOTSTRAP_OFFSET, %ecx
	jmp 	*%ecx

Entry(protected_mode_gdtr)
	.short	160		/* limit (8*20 segs) */
	.quad	EXT(master_gdt)

Entry(real_mode_bootstrap_end)

/* Save area used across sleep/wake */
.section __HIB, __data
.align	2

/* gdtr for real address of master_gdt in HIB (not the aliased address) */
Entry(master_gdtr)			
		.word 160		/* limit (8*20 segs) */
		.quad EXT(master_gdt)

saved_gdt:	.word 0
		.quad 0
saved_rsp:	.quad 0
saved_es:	.word 0
saved_fs:	.word 0
saved_gs:	.word 0
saved_ss:	.word 0
saved_cr0:	.quad 0
saved_cr2:	.quad 0
saved_cr3:	.quad 0
saved_cr4:	.quad 0
saved_idt:	.word 0
		.quad 0
saved_ldt:	.word 0
saved_tr:	.word 0
saved_kgs_base:	.quad 0
saved_ugs_base:	.quad 0

