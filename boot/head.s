/*
 *  linux/boot/head.s
 *
 *  (C) 1991  Linus Torvalds
 */

/*
 *  head.s contains the 32-bit startup code.
 *
 * NOTE!!! Startup happens at absolute address 0x00000000, which is also where
 * the page directory will exist. The startup code will be overwritten by
 * the page directory.
 * 以上注释是linux0.11初始版本的说明
 * 现在这个版本已经不是这么玩了哈哈，这里详细介绍一下OS加载的整个过程
 * 1.实地址模式下，bootsect.s负责把OS的前32Kcode加载到0x10000处，然后跳转到setup.s处继续执行。
 * 2.实地址模式下，setup.s负责把之前加载在0x10000处的32K OS code搬运到0x0000处，
 * 然后进入保护模式，并跳转到0x0000处执行head.s（其实这里可以不搬运的，可以进入保护模式，然后直接跳到0x10000处执行head.s代码，just for practice）
 * 3.保护模式下，head.s首先会将0x0000处的32k OS-code再次搬运到5M地址处，并跳转到5M地址相应的offset处继续执行head.s后面的加载剩余OS-code.
 * 4.为什么要把OS-code放在5M地址处呢，因为0~1M用于存放内核的目录表和显存，其余的就占时不用了，1M~5M用于存放内核的页表，这么大空间说明可以管理最大4G内存。
 *
 * 5.关于让每个进程都有独立的4G寻址空间，我这里将内核的地址空间映射到0~1G地址空间，用户态映射到1G~4G的地址空间，其中内核空间是共享的。
 *   5.1  这里关于内核如何能够管理和读写整个内存（尤其是>1G的内存）有两个想法
	 * 1. 当创建一个新的进程的时候，会复制内核目录表，因为内核目录表只有0~1G的目录项是设置的，所以每个进程都是一样的指向相同的页表，所以共享内核。
	 *    当内存大于1G的时候，内核的1G地址空间要分一部分出来用作读写高地址（>1G物理地址）内存，不能都用来实地址一对一映射。
	 *    注意：内核可以管理4G内存，这里的管理指的是用一个数组mem_map，来标记每个物理页的占用情况，这个数组本身是在内核的地址空间的，所以可以管理。
	 *    如果分配的页表或目录表在1G物理地址外的话，那么如果内核要初始化(读写)这个为新进程分配的物理页的话，因为这个地址超过了内核的地址空间了，所以要用内核保留的一部分
	 *    线性地址通过散射(非实地址一对一映射)的方式来映射这个超过1G的物理地址，这样内核读写这部分保留的线性地址，最终会映射到这个超过1G的物理地址上。
	 *    CPU的眼里只有线性地址O(∩_∩)O哈哈~
	 *    尼玛想了一下午，终于理清了怎么搞了，也不知道现代的OS是怎么搞的，这么搞是不是很low啊。
	 *
	 * 2. 终于想到了另一种方式了：可以将内核的地址空间设置为4G,但还是只使用开始的1G线性空间，内核目录表的前1G还是实地址一对一映射，后面的3G内存空间先不设置。
	 *    这样就可以管理和读写整个内存了，这里可能有人会问内核的地址空间只有1G大小，如何产生超过1G的线性地址（既访问用户空间的线性地址），
	 *    还记得FS段吗，它可是一直保留了用户态的段选择符的，通过FS:offset就可以访问用户空间的任何一个地址了，当然这种方式访问>1G物理内存的前提是该进程已经存在且
	 *    用户空间线性地址已经映射了物理地址了，这时内核通过fs:offset的方式访问，在做段限长检查的时候用的是进程的limit而不是内核的，所以可以访问>1G的物理内存，
	 *    但是当内核在处理sys_fork中断创建新进程的时候，用户空间内存映射还没开始呢，这时内核要是通过mem_map找到了一页空闲物理内存且地址>1G，用作新进程的task_struct
	 *    的话，这时就是用内核的DS段去读写了，因为内核的DS和CS的limit都设置为4G了，所以段检查没问题，但是这就得要求内核的4G地址空间映射都得1:1实地址映射了，
	 *    这样的话就麻烦了，当进程从用户态切换到内核态时，要根据内核具体的操作来区分是否切换CR3，有如下几种情况：
	 *       (1)如果内核仅仅是读写用户空间的数据，这时不用切花CR3，因为用户空间的地址映射可不是实地址1:1映射的，要切换到内核目录表反而有问题，
	 *          还是用用户态的目录表，内核可以通过用户态的FS来访问用户态数据。
     *       (2)如果是处理缺页操作的话，这时说明相应的用户空间线性地址还没映射呢，这时就要将CR3切换到内核的目录表了，这样分配实际的物理地址并更新用户态的目录表。
     *       (3)如果在内核态频繁处理1,2两步操作的话，可以想想CR3就得得频繁的切换，而且还得用临时变量来存储用户空间线性地址实际映射到的物理地址，这样内核才好去访问，太烦了。
	 *
	 * 3. 开始实施的时候才发现，第二种方式有问题而且实现起来更麻烦，要在用户态和内核态频繁切花CR3才能实现，效率反而太差。

 * 5.2 内核目录表和页表的初始化
 *     5.2.1 用部分内核空间映射剩余3G用户空间
	 *     1. if total_mem_size <= 1G,那么根据total_mem_size实地址一对一初始化目录表和页表，因为内核线性空间可以cover整个内存，所以就可以读写整个内存了。
	 *     2. if total_mem_size > 1G, 那么内核线性地址空间的前(1024M-128M),可以用实地址一对一映射，最后的128M保留，不实地址一对一映射，用来散射>1G的物理内存，
	 *        进而读写所有物理内存。
	 *        这里还有个待商榷的地方，就是为进程新分配的目录表是否复制内核映射的那部分线性地址，这直接决定了进程由用户态进入内核态是否要重新加载目录表cr3寄存器。
	 *        如果复制的话：
	 *        那么就可以不用切换CR3寄存器，但是内核要自己维护保留线性地址空间已经被占用的情况，因为如果切换到其他任务的话，内核在管理其他任务时要用到
	 *        保留空间的线性地址的话，要能知道哪些是可用的，哪些已经被其他进程占用了，因为你不切换CR3的话，修改的是用户目录表的前1G内核空间中的保留空间，内核的目录表的保留空间是没有更新的.
	 *        如果不复制的话:
	 *        那么就必须要切换CR3寄存器，加载内核的目录表，但内核也还是要维护保留空间的使用情况并与各个进程绑定起来，进程切换和返回的时候可以对上。
	 *     3. 注意这里一定要和分页管理内存区分开来，分页管理内存也就是mem_map数组管理的那部分。
	 *
	 * 5.2.2 将内核limit设置为4G，可以读写整个内存
	 *     1. if total_mem_size <= 1G,那么根据total_mem_size实地址一对一初始化目录表和页表，因为内核线性空间可以cover整个内存，所以就可以读写整个内存了。
	 *     2. if total_mem_size > 1G，那么将内核的代码段和数据段的limit都设置为4G，当创建一个新的进程的时候，会为新进程分配目录表，
	 *        该目录表分配在内核空间还是用户空间，还没想好，暂且是分配在用户空间吧
	 *       （页表是一定要分配的在用户空间的，因为一个进程目录表只有一个，但页表会有很多个，放在内核空间太占内存了），
	 *        并将进程的目录表地址存储在其task_struct中，然后把内核的目录表中前1G有效的目录项复制到进程的目录表中(线性地址和物理地址是实地址1:1映射的)，
	 *        接着再在用户空间分配一个页表用来管理进程的前4M(code+data)并将页表的首地址复制到进程目录表中的相应目录项中，
	 *        最后再分配一页内存（用户空间）用于加载用户开始的4k代码，并将该页的地址复制到进程页表的相应的页表项中((address>>12)<<2),
	 *        到这进程的目录表就可以管理内核空间和用户空间了，进程在用户态和内核态切换是不需要切换cr3寄存器的。
 *
 */
EMULATOR_TYPE      = 0x01       /* 模拟器类型：0:bochs, 1:qemu */
HD_INTERRUPT_READ  = 0x20
OS_BASE_ADDR       = 0x500000
PG_DIR_BASE_ADDR   = 0x000000   /* 内核目录表基地址 */
PG_TAB_BASE_ADDR   = 0x100000   /* 内核页表起始地址,4M大小可以管理4G内存 */

/* boot实地址模式下，预加载的OS大小，这里设置为32K，可以自己调整，但最好不要超过64K，因为实地址模式的段限长是64K，
 * 如果必须要加载>64K的OS代码的话，最好是64K的倍数，这要好处理，不过目前预加载的32K OS代码足够内核初始化了。
 */
OS_PRELOAD_SIZE    = 0x8000

/*
 * 1. Bochs linux版本
 * Deprecated: 因为bochs模拟>1G的内存有问题，不是很稳定，我在linux上自己重编了bochs并将--enable-large-mem选项也加上了，但是>1G还是有问题，这里不纠结了。
 * AP: 问题找到了，是我给vmware虚拟机分配的物理内存有点小了(才2G)，vmware的内存调整为8G,设置bochs配置文件：guest=2044(注意guest设置为2048还是有问题的)，host=1024就可以。
 * 2. Bochs window版本
 * windows版本的bochs我没有加上--enable-large-mem重编过，感兴趣的朋友可以试一下。
 * 不想重编的话，设置megs=1024(4M的倍数)，然后把内核线性地址空间(KERNEL_LINEAR_ADDR_SPACE)设置为512M，这样也能验证用内核保留空间访问>512M的高地址内存。
 * 当然head.h中的6个有关内核线性地址空间的参数也要作相应的调整，将 (#if 0) 改为 (#if 1) 即可。
 */
//KERNEL_LINEAR_ADDR_SPACE = 0x20000  /* granularity 4K (512M) */
KERNEL_LINEAR_ADDR_SPACE = 0x40000    /* granularity 4K (1G)   */

AP_DEFAULT_TASK_NR = 0x50      /* 这个数字已经超出了任务的最大个数64,所以永远不会被schedule方法调度到,仅用来保存AP halt状态下的context */

.text
.globl idt,gdt,tmp_floppy_area,params_table_addr,load_os_addr,hd_read_interrupt,hd_intr_cmd,check_x87,total_memory_size,vm_exit_handler
.globl startup_32,sync_semaphore,idle_loop,ap_default_loop,task_exit_clear,globle_var_test_start,globle_var_test_end,init_pgt
startup_32:
	movl $0x10,%eax
	mov %ax,%ds
	mov %ax,%es
	mov %ax,%fs
	mov %ax,%gs
	mov %ax,%ss

/* 下面计算内存的大小统一用4K作为粒度。 */
    xor %edx,%edx
	movw %ds:0x90002,%dx          /* 这里得到的是granularity为64K的extend2的大小，所以要乘以16，前面的16M/4K=4K, 这里也是个小坑，mem长度是2字节，之前用movl是4字节有问题啊 */
	xorl %eax,%eax
	movl $EMULATOR_TYPE,%eax
	cmpl $0x00,%eax
	je bochs_emulator
	addl $0x03,%dx    /* Qemu模拟器，在取扩展内存extend2的时候，会默认少3*64K,原因还不清楚(也是个巨坑，排查好长时间)，这里默认加上+3；用bochs的话，一定要去掉这里。 */
bochs_emulator:
	shl  $0x04,%edx               /* 左移4位乘以16*/
	addl $0x1000,%edx             /* +16M得到总的内存大小，以4K为单位。 */
	movl %edx,total_memory_size   /* 将内存总大小(4K granularity)存储到全局变量total_memory_size */
    lss tmp_floppy_area,%esp      /* 设置GDT表中内核代码段和代码段的limit为实际物理内存大小,这里使用废弃的floppy数据区作为临时栈。 */

    /* 设置内核代码段的limit,因为要支持每个进程都有4G的地址空间，所以内核的地址空间是512M,当内存>512M的时候，也只能设置为512M=0x20000(4K) */
    cmp $KERNEL_LINEAR_ADDR_SPACE,%edx
    jle 1f
    movl $KERNEL_LINEAR_ADDR_SPACE,%edx  /* 如果内存>512M，那么设置内核的limit为512M */
1:  lea gdt,%ebx
    add $0x08,%ebx
    push %edx
    push %ebx
    call set_seg_limit   /* 注意这里的函数调用可不会自动帮你把参数弹出来哈哈，自己动手丰衣足食。  */
    popl %ebx
    popl %edx            /* 恢复内存的总大小，单位是4K，因为set_seg_limit函数有可能会用到edx。*/

    /* 设置内核数据段的limit */
    lea gdt,%ebx
    add $0x10,%ebx
    push %edx
    push %ebx
    call set_seg_limit
    popl %ebx
    popl %edx             /* 恢复内存的总大小，单位是4K,如果内存>512M这里的edx恒等于512M，注意:这里还没开启分页功能，所以地址的访问是实地址映射。 */

    shl $0x0C,%edx        /* 注意：这里的edx应该是<=(512M/4k) */
    /*
     * 此时将内核能实地址映射的内存的(最高地址-4)处设置为临时栈顶，注意“此时”的含义，
     * 因为如果内存>512M的话，内核实地址映射的内存是(512-64)M，因为要留64M地址空间映射>512M内存以及保留空间(64M)的物理地址。
     * 此时还没开启分页，所以整个物理内存都可以实地址访问。
     */
	subl $0x4,%edx
    /* init a temp stack in the highest addr of memory for handling HD intr.  */
init_temp_stack:
	movl %edx,temp_stack
	lss temp_stack,%esp

	call setup_gdt
	call setup_idt

	movl $0x10,%eax		# reload all the segment registers
	mov %ax,%ds		    # after changing gdt. CS was already
	mov %ax,%es		    # reloaded in 'setup_gdt'
	mov %ax,%fs
	mov %ax,%gs
	/* Move the params, such as memeory size, vedio card, hd info to the highest address of the memory, because addr bound will be erased later.  */
    call move_params_to_memend

	lss stack_start,%esp
	jmp main_entry
/*
 *  setup_idt
 *
 *  sets up a idt with 256 entries pointing to
 *  ignore_int, interrupt gates. It then loads
 *  idt. Everything that wants to install itself
 *  in the idt-table may do so themselves. Interrupts
 *  are enabled elsewhere, when we can be relatively
 *  sure everything is ok. This routine will be over-
 *  written by the page tables.
 */
setup_idt:
	lea ignore_int,%edx
	movl $0x00080000,%eax
	movw %dx,%ax		/* selector = 0x0008 = cs */
	movw $0x8E00,%dx	/* interrupt gate - dpl=0, present */

	lea idt,%edi
	mov $256,%ecx
rp_sidt:
	movl %eax,(%edi)
	movl %edx,4(%edi)
	addl $8,%edi
	dec %ecx
	jne rp_sidt
	lidt idt_descr
	ret

/*
 *  setup_gdt
 *
 *  This routines sets up a new gdt and loads it.
 *  Only two entries are currently built, the same
 *  ones that were built in init.s. The routine
 *  is VERY complicated at two whole lines, so this
 *  rather long comment is certainly needed :-).
 *  This routine will beoverwritten by the page tables.
 */
setup_gdt:
	lgdt gdt_descr
	ret
/* handle HD intr for reading per sector. */
hd_read_interrupt:
/*
 * It's strange here that when HD_INTERRUPT occurs,
 * the EIP pointer to second code relative to the beginning of this code seg,
 * so insert a redundant code here, to make sure, pushl %eax can be call.
 */
    jmp 1f
1:	pushl %eax
	pushl %ecx
	pushl %edx
	push %ds
	push %es
	push %fs
	movl $0x10,%eax
	mov %ax,%ds
	mov %ax,%es
	mov %ax,%fs
	movb $0x20,%al
	outb %al,$0xA0		# EOI to interrupt controller #1
	jmp 1f			    # give port chance to breathe
1:	jmp 1f

1:	outb %al,$0x20
    movl %ds:hd_intr_cmd,%edx
    cmpl $HD_INTERRUPT_READ,%edx
    jne omt
	call do_read_intr	# interesting way of handling intr.
omt:pop %fs
	pop %es
	pop %ds
	popl %edx
	popl %ecx
	popl %eax
	iret
/* init stack struct for lss comand to load. */
.align 4
temp_stack:
    .long 0x00
    .word 0x10
    .word 0x0

/*
 * This variable will filter all other Intrs from HD, just read intr can be work, it's used in hd_read_interrupt.
 */
.align 4
hd_intr_cmd:
    .long 0x0

/*
 * tmp_floppy_area is used by the floppy-driver when DMA cannot
 * reach to a buffer-block. It needs to be aligned, so that it isn't
 * on a 64kB border.
 * 该地址空间被用作临时堆栈了。
 */
.org 0x1000
tmp_floppy_area:
    .long main_entry
    .word 0x10
	.fill 1024-6,1,0

main_entry:
	pushl $0		# These are the parameters to main :-)
	pushl $0
	pushl $0
	pushl $L6		# return address for main, if it decides to.
	call main
L6:
	jmp L6			# main should never return here, but
				# just in case, we know what happens.

/* This is the default interrupt "handler" :-) */
int_msg:
	.asciz "Unknown interrupt\n\r"
.align 4
ignore_int:
	pushl %eax
	pushl %ecx
	pushl %edx
	push %ds
	push %es
	push %fs
	movl $0x10,%eax
	mov %ax,%ds
	mov %ax,%es
	mov %ax,%fs
	pushl $int_msg
	call printk
	popl %eax
	pop %fs
	pop %es
	pop %ds
	popl %edx
	popl %ecx
	popl %eax
	iret

.align 4
idt_descr:
	.word 256*8-1		# idt contains 256 entries
	.long idt
	.word 0

.align 4
gdt_descr:
	.word 256*8		# so does gdt (not that that's any
	.long gdt		# magic number, but it works for me :^)
	.word 0

.org 0x2000
.align 8
idt:	.fill 256,8,0		# idt is uninitialized
.org 0x3000
gdt:
	.quad 0x0000000000000000	/* NULL descriptor */
	.quad 0x00c09a0000000fff	/* Code seg, limit default size: 16Mb,it will be changed by set_limit */
	.quad 0x00c0920000000fff	/* Data seg, limit default size: 16Mb */
	.quad 0x0000000000000000	/* TEMPORARY - don't use */
	.fill 252,8,0			    /* space for LDT's and TSS's etc */
.org 0x4000
tr_tss:	.fill 256,8,0
.org 0x5000
ldt:	.fill 256,8,0

/*
 * Record the address of the params table for main func to init.
 * allocated in here to avoid erasing when setup dir_page.
 */
.align 4
params_table_addr:
    .long 0

/* 这里的内存总大小是以4K为granularity的。 */
.align 4
total_memory_size:
    .long 0

task_exit_clear:
