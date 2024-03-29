/*
 *  linux/kernel/sched.c
 *
 *  (C) 1991  Linus Torvalds
 */

/*
 * 'sched.c' is the main kernel file. It contains scheduling primitives
 * (sleep_on, wakeup, schedule etc) as well as a number of simple system
 * call functions (type getpid(), which just extracts a field from
 * current-task
 */
#include <linux/sched.h>
#include <linux/kernel.h>
#include <linux/sys.h>
#include <linux/fdreg.h>
#include <asm/system.h>
#include <asm/io.h>
#include <asm/segment.h>

#include <signal.h>

#include <linux/head.h>

#define _S(nr) (1<<((nr)-1))
#define _BLOCKABLE (~(_S(SIGKILL) | _S(SIGSTOP)))

/************************ semaphore variable ******************************/
unsigned long sched_semaphore = 0;
unsigned long sleep_on_semaphore = 0;
unsigned long interruptible_sleep_on_semaphore = 0;
/**************************************************************************/

extern void task_exit_clear(void);
void task_switch();

void show_task(int nr,struct task_struct * p)
{
	int i,j = 4096-sizeof(struct task_struct);

	printk("%d: pid=%d, state=%d, ",nr,p->pid,p->state);
	i=0;
	while (i<j && !((char *)(p+1))[i])
		i++;
	printk("%d (of %d) chars free in kernel stack\n\r",i,j);
}

void show_stat(void)
{
	int i;

	for (i=0;i<NR_TASKS;i++)
		if (task[i])
			show_task(i,task[i]);
}

#define LATCH (1193180/HZ)

extern void mem_use(void);
extern int timer_interrupt(void);
extern int system_call(void);

union task_union init_task = {INIT_TASK,};
union task_union ap_default_task = {INIT_TASK,};
union task_union vm_defualt_task = {INIT_TASK,};
/*
 * 这里一次性分配64个processor，主要原因是这样可以使data_segment_align 4K对齐，
 * 如果设置为4的话就导致data_segment_align不能4K对齐了，导致运行有问题，
 * 至于具体的原因，没有深入研究GCC这块是怎么编译的，后面会详细研究一下。
 */

/* 所有processor的apicId存储在这里 */
struct apic_info apic_ids[LOGICAL_PROCESSOR_MAXIMUM] = {{1,0,BSP_APIC_REGS_DEFAULT_LOCATION,0,0,&(init_task.task)},
		                                                {0,1,BSP_APIC_REGS_DEFAULT_LOCATION,0,0,&(init_task.task)},
		                                                {0,2,BSP_APIC_REGS_DEFAULT_LOCATION,0,0,&(init_task.task)},
														{0,3,BSP_APIC_REGS_DEFAULT_LOCATION,0,0,&(init_task.task)},};
long volatile jiffies=0;
long startup_time=0;
struct task_struct *last_task_used_math = NULL;
struct task_struct * task[NR_TASKS] = {&(init_task.task),};
long user_stack [ PAGE_SIZE>>2 ];
struct {
	long * a;
	short b;
	} stack_start = {&user_stack[PAGE_SIZE>>2] , 0x10};

/*
 * 获取当前processor正在运行的任务
 */
unsigned long get_current_apic_id(){
	register unsigned long apic_id asm("ebx");
	unsigned char gdt_base[8] = {0,}; /* 16-bit limit stored in low two bytes, and gdt_base stored in high 4bytes. */
	/*
	 * 在Guest VM 环境下，执行cpuid指令会导致vm-exit，所以这里要判断当前的执行环境是否在VM环境.
	 * 实现思路：我们知道在VM环境下，已经为GDT表分配了4K空间，且GDT表的首8字节是不用的，这里利用这8个字节存储vm-entry环境下的apic_id.
	 */
	__asm__ ("sgdt %1\n\t"              \
			 "movl %2,%%eax\n\t"        \
			 "movl 0(%%eax),%%ebx\n\t"  \
			 "cmpl $0x00,%%ebx\n\t"     \
			 "jne truncate_flag\n\t"    \
			 "movl $0x01,%%eax\n\t"     \
			 "cpuid\n\t"                \
			 "shr $24,%%ebx\n\t"        \
			 "jmp output\n\t"           \
			 "truncate_flag:\n\t"       \
			 "andl $0xFF,%%ebx\n\t" /* 这里假设最多有255个processor */  \
			 "output:\n\t"              \
			 :"=b" (apic_id) :"m" (*gdt_base),"m" (*(char*)(gdt_base+2))
			);
	return apic_id;
}



struct apic_info* get_apic_info(unsigned long apic_id) {
	for (int i=0;i<LOGICAL_PROCESSOR_NUM;i++) {
		if (apic_ids[i].apic_id == apic_id) {
			return &apic_ids[i];
		}
	}
	return 0;
}

struct task_struct* get_current_task(){
	return get_apic_info(get_current_apic_id())->current;
}

void reset_cpu_load() {
	for (int i=0;i<LOGICAL_PROCESSOR_NUM;i++) {
		apic_ids[i].load_per_apic = 0;
	}
}

/* 计算哪个AP的负载最小，后续的task将会调度该AP执行。 */
unsigned long get_min_load_ap() {
	unsigned long apic_index = 1;  /* BSP不参与计算 */
	int overload = 0;
	if (apic_ids[apic_index].load_per_apic == 0xFFFFFFFF) {
		++overload;
	}
	for (int i=2;i<LOGICAL_PROCESSOR_NUM;i++) {
		if (apic_ids[i].load_per_apic == 0xFFFFFFFF) {
			++overload;
			continue;
		}
		if (apic_ids[apic_index].load_per_apic > apic_ids[i].load_per_apic) {
			apic_index = i;
		}
	}
	if (overload == LOGICAL_PROCESSOR_NUM-1) {
		reset_cpu_load();
		return apic_ids[LOGICAL_PROCESSOR_NUM-1].apic_id;
	}

	return apic_ids[apic_index].apic_id;
}

int check_default_task_running_on_ap() {
	if (get_current_apic_id()) {
		if (get_current_task() == &ap_default_task.task) {
			return 1;
		}
		else {
			return 0;
		}
	}
	return 0;
}



/*
 * 向指定的AP发送IPI中断消息,要先写ICR的高32位，因为写低32位就会触发IPI了，
 * 所以要现将apic_id写到destination field,然后再触发IPI。
 */
#if EMULATOR_TYPE
void send_IPI(int apic_id, int v_num) {
__asm__ ("movl bsp_apic_default_location,%%edx\n\t" \
		 "pushl %%edx\n\t" \
		 "call remap_msr_linear_addr\n\t" \
		 "popl %%edx\n\t" \
		 "movl %%eax,%%edx\n\t"          /* eax中存储映射后的linear addr */ \
		 "addl $0x10,%%edx\n\t"          /* 获得ICR的高32位地址 */ \
		 "shll $24,%%ecx\n\t" \
		 "movl %%ecx,0(%%edx)\n\t"       /* 设置ICR高32位中的destination field */  \
		 "movl %%eax,%%edx\n\t" \
		 "addl $0x00004000,%%ebx\n\t" \
		 "movl %%ebx,0(%%edx)\n\t"       /* 设置ICR低32位的vector field */   \
		 "pushl %%eax\n\t" \
		 "call recov_msr_swap_linear\n\t" \
		 "popl %%eax\n\t" \
		 "wait_loop_ipi:\n\t" \
		 "xorl %%eax,%%eax\n\t" \
		 "movl 0(%%edx),%%eax\n\t" \
		 "andl $0x00001000,%%eax\n\t"    /* 判断ICR低32位的delivery status field, 0: idle, 1: send pending */  \
		 "cmpl $0x00,%%eax\n\t"   \
		 "jne wait_loop_ipi\n\t"  \
		 ::"c" (apic_id),"b" (v_num));
}

/* 发送中断处理结束信号： end of interrupt */
void send_EOI() {
	/*
	 * 这里获得apic的基地址是0xFEE00000,但是我们知道VM的整个4G虚拟内存是由32M～128M的物理内存模拟的，所以这里有问题,
	 * 因为0xFEE00000最终会被映射到这<128M的实际物理内存空间，所以apic timer是不能正常工作的.
	 * 有两种处理方法：
	 * 1. 对这个地址在EPT中进行特殊处理，采用实地址映射.
	 * 2. 触发VM-EXIT到VMM中处理, 这里就是采用这种方法实现GuestOS发送EOI.
	 *
	 * 到这里才真正明白Virtual-APIC的真正价值和意义:
	 * 如果CPU支持该feature的话，那么GuestOS就可以在VM中通过访问apic-access-page和virtual-apic-page来完成EOI操作(由硬件完成后续映射和EOI操作)，
	 * 不用在VM-EXIT到VMM中通过remap_msr后访问apic-regs了,效率比现在这种处理方式高多了,难怪放在高端处理器上,
	 * 同时再次证明将内核空间放在最高1G地址空间是多么的英明啊，一开始是故意将内核地址空间放在开始的1G低地址空间的，现在是多么痛的领悟啊.
	 */
	ulong eoi = 0;
	vm_exit(VM_EXIT_REASON_CPUID_FOR_SEND_EOI, (cpuid_exit_info*)(&eoi));

#if 0
	unsigned long apic_id = get_current_apic_id();
	struct apic_info* apic = get_apic_info(apic_id);
	if (apic) {


		unsigned long addr = apic->apic_regs_addr;

		addr = remap_msr_linear_addr(addr);
		__asm__("addl $0xB0,%%eax\n\t" /* EOI register offset relative with APIC_REGS_BASE is 0xB0 */ \
				"movl $0x00,0(%%eax)"  /* Write EOI register */ \
				::"a" (addr)
				);
		recov_msr_swap_linear(addr);
	}
#endif

}
#else
void send_IPI(int apic_id, int v_num) {
__asm__ ("movl bsp_apic_icr_relocation,%%edx\n\t" \
		 "addl $0x10,%%edx\n\t" \
		 "shll $24,%%eax\n\t" \
		 "movl %%eax,0(%%edx)\n\t"       /* 设置ICR高32位中的destination field */  \
		 "movl bsp_apic_icr_relocation,%%edx\n\t" \
		 "addl $0x00004000,%%ebx\n\t" \
		 "movl %%ebx,0(%%edx)\n\t"       /* 设置ICR低32位的vector field */   \
		 "wait_loop_ipi:\n\t" \
		 "xorl %%eax,%%eax\n\t" \
		 "movl 0(%%edx),%%eax\n\t" \
		 "andl $0x00001000,%%eax\n\t"    /* 判断ICR低32位的delivery status field, 0: idle, 1: send pending */  \
		 "cmpl $0x00,%%eax\n\t"   \
		 "jne wait_loop_ipi\n\t"  \
		 ::"a" (apic_id),"b" (v_num));
}

/* 发送中断处理结束信号： end of interrupt */
void send_EOI() {
	unsigned long apic_id = get_current_apic_id();
	struct apic_info* apic = get_apic_info(apic_id);
	if (apic) {
		unsigned long addr = apic->apic_regs_addr;
		__asm__("addl $0xB0,%%eax\n\t" /* EOI register offset relative with APIC_REGS_BASE is 0xB0 */ \
				"movl $0x00,0(%%eax)"  /* Write EOI register */ \
				::"a" (addr)
				);
	}
}
#endif


unsigned long get_current_apic_index() {
	unsigned long apic_id = get_current_apic_id();
	for (int i=0;i<LOGICAL_PROCESSOR_NUM;i++) {
		if (apic_ids[i].apic_id == apic_id) {
			return i;
		}
	}
	return 0;
}

/* 主要是为了AP初始化的时候使用，用于任务一开始切换时，将当前内核态的context信息存储到指定的位置，而不是一开始默认的0x00地址处，这样就不会覆盖内核的目录表了。 */
void reload_ap_ltr() {
	//set_tss_desc(gdt+(nr<<1)+FIRST_TSS_ENTRY, &(ap_default_task.task.tss));
	int nr = (get_current_apic_index() + AP_DEFAULT_TASK_NR);
	ltr(nr);
}

void init_ap_tss(int nr) {
	set_tss_desc(gdt+(nr<<1)+FIRST_TSS_ENTRY, &(ap_default_task.task.tss));
}

void reset_ap_default_task() {
	unsigned long apic_index = get_current_apic_index();
	apic_ids[apic_index].current = &ap_default_task.task;
}

void lock_op(unsigned long* sem_addr) {
	__asm__ ("lock_loop:\n\t"        \
			 "cmp $0x00,%0\n\t"      \
			 "jne lock_loop\n\t"     \
			 "movl $0x01,%%edx\n\t"  \
			 "lock\n\t"    /*xchg默认会加上lock前缀的，这里显示加上lock prefix是为了统一风格*/  \
			 "xchg %%edx,%0\n\t"     \
			 "cmp $0x00,%%edx\n\t"   \
			 "jne lock_loop\n\t"     \
			 ::"m" (*sem_addr)       \
		    );
}

void unlock_op(unsigned long* sem_addr) {
	__asm__ ("cmpl $0x00,%0\n\t" \
			 "jle 1f\n\t" \
			 "subl $0x01,%0\n\t" \
			 "1:\n\t" \
			 ::"m" (*sem_addr)   \
			);
}

void reset_ap_context() {
	unsigned long apic_index =  get_current_apic_index();
	int father_id = get_current_task()->father;
	/* tricky 1:
	 * 因为task运行到这,一定是处于内核态的,因此目录表的前256项(管理1G的内核线性地址空间)都是指向相同的页表的.
	 * 这里一定要将AP的CR3设置为0x00,那是因为当前进程随后会被释放掉，其对应的目录表也会被释放掉,就会被其他进程占用,
	 * 这样就会导致当前AP的CR3中的目录表基地址就无效了,所以要将CR3重置为0x00,这样随后的指令依旧可以继续运行在内核态.
	 * */
	reset_dir_base();

	/* trick 2:
	 * 这里有必要解释下,为什么在AP上的运行的普通任务,在执行退出程序过程中,要重新设置该AP的TR寄存器,这是埋藏很深的巨坑.
	 * 因为一旦AP上的普通task退出后,要让AP运行特殊的loop程序(ap_default_loop,定义在head.s中),以等待timer中断到来.
	 * 这个任务之所以特殊,那是因为它没有设置LDT寄存器仅设置了TR寄存器,也就是只在内核态下运行内核的一段loop程序,
	 * 当timer中断到来时,在中断处理函数中调用schedule调度新的进程运行,一旦要运行新的任务时,就会导致任务切换,将当前任务的context
	 * 保存到TR寄存器中存储的TSS数据结构内存地址中.
	 * 如果不设置值TR寄存器的话,会在两种情况下导致两种致命错误:
	 * 1. AP第一次发生任务切换时
	 *    这时AP上的TR寄存器还是reset后的初始值0x00,其指向的地址是0x00,这是内核目录表的基地址啊,任务切换会覆盖它的,系统就崩溃了.
	 *    因此在AP初始化的时候就要重置TR寄存器,在head.s中已经这么做了.
	 * 2. AP上执行do_exit函数时
	 *    这意味着当前运行的是普通任务,这时TR存储的是当前普通任务的TSS内存地址,当AP执行完do_exit后,就进入特殊loop程序以等待timer中断的到来,
	 *    在这等待的过程中,这个TR指向的TSS内存地址,很有可能被新任务所占用的,这时中断到来引起新的进程切换的话,会将当前的特殊loop程序的context
	 *    复制到TR寄存器指向的TSS内存地址,这样就覆盖了其他进程的内存页内容,从而会导致其他进程的崩溃. 相当tricky啊
	 *    所以这里要重置TR寄存器指向每个AP私有的,专用于存储特殊loop程序的context的TSS内存地址,这样就不会覆盖其他进程的内存页了.
	 *
	 * 重新加载AP的LTR寄存器,使其指向GDT表中NR=0x81,0x82或0x83每个AP私有的TSS内存页,这些TSS描述符记录的基地址都是相同的(&ap_default_task.tss).
	 *
	 * 注意: 这里之前是所有的AP都共享GDT表中相同的NR=0x80的TSS,但是每次重置都要重复设置GDT表的NR=0x80表项的TSS描述符,如果不重置该TSS描述符表项的话,
	 * 不同AP的TR寄存器加载相同的TSS会报General protection错误的.
	 * 例如AP1重置了GDT表NR=0x80 TSS描述符项,然后LTR加载了该TSS, 随后的AP2和AP3也执行AP1相同的操作,那么AP2和AP3是不会报GP错误的,
	 * 但是,AP2和AP2如果仅执行LTR指令加载NR=0x80的TSS描述符项就会报GP错误,这一点Intel手册上没有相关的描述:不同的TR加载相同的TSS.
	 * 这里为了解决这个问题就为每个AP分配一个私有TSS描述符项,NR=0x81,0x82,0x83,这样就不会有问题了,而且NR>64也不会参与schedule调度.
	 * */
	reload_ap_ltr();

	/*
	 * 这里很有必要解释下: 为什么要把reset_ap_default_task函数注释掉,将它放到task_exit_clear函数里最后才调用.
	 * 因为reset_ap_default_task就是将每个AP的默认task设置为ap_default_task,这也表明AP处于运行特殊loop程序的状态,随时可以响应timer中断进行新任务调度.
	 * 如果这里就设置为ap_default_task,意味着随时会响应timer进行任务切换,注意:这时TR已经重载了指向AP default TSS了,所以这时要是发生任务切换的话,那么当前
	 * 任务的context会被保存到default TSS而不是当前普通任务自己的TSS;而且由于当前任务的state被设置为zombie和sched_on_ap=1,在任务切换时因为current已经
	 * 不指向自己了,所以不能被设置为running状态,或sched_on_ap=0,也就是说该进程以后就永远没机会被再次schedule到了,
	 * 从而成为真正的zombie进程了哈哈,这样就造成严重的内存泄露问题.
	 * 所以reset_ap_default_task一定要放在tell_father之后调用.
	 *  */
	//reset_ap_default_task();
	/* 重新设置AP的内核栈指针，然后跳转到ap_default_loop执行空循环，等待新的IPI/timer中断 */
	alloc_ap_kernel_stack(apic_index,task_exit_clear,father_id);
}

/*
 *  'math_state_restore()' saves the current math information in the
 * old math state array, and gets the new ones from the current task
 */
void math_state_restore()
{
	struct task_struct* current = get_current_task();
	if (last_task_used_math == current)
		return;
	__asm__("fwait");
	if (last_task_used_math) {
		__asm__("fnsave %0"::"m" (last_task_used_math->tss.i387));
	}
	last_task_used_math=current;
	if (current->used_math) {
		__asm__("frstor %0"::"m" (current->tss.i387));
	} else {
		__asm__("fninit"::);
		current->used_math=1;
	}
}

void reset_exit_reason_info(ulong next, struct task_struct ** current) {
	exit_reason_task_switch_struct* exit_reason_task_switch = (exit_reason_task_switch_struct*) VM_EXIT_REASON_TASK_SWITCH_INFO_ADDR;
	exit_reason_task_switch->new_task_nr  = task[next]->task_nr;
	exit_reason_task_switch->new_task_cr3 = task[next]->tss.cr3;
	exit_reason_task_switch->new_task_executed = task[next]->executed;
	exit_reason_task_switch->old_task_nr  = (*current)->task_nr;
	exit_reason_task_switch->old_task_cr3 = (*current)->tss.cr3;
	//printk("new_cr3:old_cr3(%08x:%08x)\n\r", task[next]->tss.cr3, (*current)->tss.cr3);
	exit_reason_task_switch->task_switch_entry = (ulong)task_switch;
}

/*
 *  'schedule()' is the scheduler function. This is GOOD CODE! There
 * probably won't be any reason to change this, as it should work well
 * in all circumstances (ie gives IO-bound processes good response etc).
 * The one thing you might take a look at is the signal-handler code here.
 *
 *   NOTE!!  Task 0 is the 'idle' task, which gets called when no other
 * tasks can run. It can not be killed, and it cannot sleep. The 'state'
 * information in task[0] is never used.
 */
void schedule(void)
{
	unsigned long current_apic_id = get_current_apic_id();
	if (current_apic_id == 1) {
		//printk("ap1 come to schedule\n\r");
	}
	struct apic_info* apic_info = get_apic_info(current_apic_id);
	struct task_struct ** current = &(apic_info->current);
	int i,next,c;
	struct task_struct ** p;
    /* check alarm, wake up any interruptible tasks that have got a signal */

	lock_op(&sched_semaphore);  /* 这里一定要加锁，否则会出现多个AP同时执行同一个task */
	/*
	 * 这里有必要解释下,为什么要加一个局部变量来释放锁
	 * 因为这里锁的释放有好几处,程序最后还会释放一次,这个临时变量就是保证每个进程对自己加的锁只释放一次,
	 * 如果不加这个临时变量判断一下,程序有可能会释放其他进程加的锁.
	 * */
	int lock_flag = 1;

	for(p = &LAST_TASK ; p > &FIRST_TASK ; --p)
		if (*p) {
			if ((*p)->alarm && (*p)->alarm < jiffies) {
					(*p)->signal |= (1<<(SIGALRM-1));
					(*p)->alarm = 0;
			}
			if (((*p)->signal & ~(_BLOCKABLE & (*p)->blocked)) && (*p)->state==TASK_INTERRUPTIBLE) {  /* 一旦父进程收到非阻塞信号后,就唤醒该进程. */
				(*p)->state=TASK_RUNNING;
			}
		}

/* this is the scheduler proper: */

	while (1) {
		c = -1;
		next = 0;
		i = NR_TASKS;
		p = &task[NR_TASKS];
		while (--i) {
			if (!*--p) {
				continue;
			}
			if ((*p)->state == TASK_RUNNING && (*p)->counter > c && (*p)->sched_on_ap == 0) {
				c = (*p)->counter, next = i;
			}
		}
		if (c) break; /* 当所有进程都被设置为TASK_INTERRUPTIBLE状态时,task0就开始被调度执行了这时c=-1 */
		for(p = &LAST_TASK ; p > &FIRST_TASK ; --p) {
			if (*p) {
				/* 此时如果release其他AP执行介于这之间的话,是会有问题的.具体看release描述. */
				(*p)->counter = ((*p)->counter >> 1) + (*p)->priority;
			}
		}
	}

#if 0

	if (current_apic_id == apic_ids[0].apic_id) {  /* 调度任务发生在BSP上 */
#if 0
		unsigned long sched_apic_id = get_min_load_ap();
		/* 这里禁止BSP将task[0]和task[1]调度到AP上执行 */
		if (sched_apic_id != current_apic_id && task[next] != task[0] && task[next] != task[1]) {
			/* 这里发送IPI给sched_apic_id调用该方法取执行选定的任务。 */
			//printk("Before send IPI: %d\n\r", sched_apic_id);
			//delay_op(500); /* 这个延迟函数终于可以去掉了,磁盘块和内存块之间的同步终于实现了 */
			send_IPI(sched_apic_id, SCHED_INTR_NO);

			if (lock_flag) {
				unlock_op(&sched_semaphore);
				lock_flag = 0;
			}
			++apic_ids[sched_apic_id].load_per_apic;
			next = 1;   /* BSP上只运行task0和task1 */
		}
#else
		if (task[next] != task[0] && task[next] != task[1]) {
			if (task[1]->state != 0) {
				next = 0;
			}
			else {
				next = 1;
			}
		}
#endif
	}
	else {  /* 调度任务发生在AP上，这时AP只能调度除task[0]和task[1]之外的任务，后面会开启AP的timer自主调度。 */
#if 0
		if (task[next] == task[0] || task[next] == task[1]) {
			if (lock_flag) {
				unlock_op(&sched_semaphore);
				lock_flag = 0;
			}
			if (*current != 0) {  /* 这里要注意在执行sys_exit系统调用的时候一定要遍历所有AP的current，将对应的current清空 */
				return;           /* 如果AP有已经执行过的task,这时不调度，继续执行老的task. */
			}
			else {
				/* halt等待新的调度IPI */
				__asm__("hlt"::);
			}
		}
		else {  /* 这时AP要调度新的task[n>1] */
			if (*current) {
			    (*current)->sched_on_ap = 0;  /* 只有这样，BSP之后才能继续调用该current到其他AP上运行，否则，该进程将永远不会被重新sched. */
			}
			task[next]->sched_on_ap = 1;
		}
#else
		if (task[next] == task[0] || task[next] == task[1]) {
			if (lock_flag) {
				unlock_op(&sched_semaphore);
				lock_flag = 0;
			}
			if (*current != 0) {
				return;          /* 如果AP有已经执行过的task(包括idle_loop,也就是ap_default_task任务),这时不调度，继续执行老的task. */
			}
			else {/* 执行到这个分支,说明内核是有问题的,current是不可能为0的 */
				panic("Errors occur on AP schedule\n\r");
			}
		}
		else {  /* 这时AP要调度新的task[n>1] */
			unsigned long sched_apic_id = get_min_load_ap();
			if (sched_apic_id == current_apic_id) {
				if (*current) {
					/* 只有这样，BSP之后才能继续调用该current到其他AP上运行，否则，该进程将永远不会被重新sched.(但ap_default_task是永远不会被调度的) */
				    (*current)->sched_on_ap = 0;
				}
				task[next]->sched_on_ap = 1;      /* 设置任务占用符,这样释放锁以后,该任务是不会被其他AP调度执行的 */
				++apic_ids[sched_apic_id].load_per_apic;
			}
			else {
				if (lock_flag) {
					unlock_op(&sched_semaphore);
					lock_flag = 0;
				}
				return;
			}
		}
#endif
	}

#endif

	if (lock_flag) {
		unlock_op(&sched_semaphore);
		lock_flag = 0;
	}

	/*
	 * 在进行进程切换之前要先保存新老任务的task_nr和task_switch_entry,
	 * 这样方便VMresume到GuestOS后,在task_switch中进行真正的任务切换.
	 */
	if (task[next] != *current) {
		//printk("Selected.nr====%08x\n\r", next);
		reset_exit_reason_info(next, current);
	}

	switch_to(next,current);
}

int sys_pause(void)
{
	struct task_struct* current = get_current_task();
	current->state = TASK_INTERRUPTIBLE;
	schedule();
	return 0;
}

/*
 * 该方法要加同步锁,因为当多个进程并发调用该方法时,
 * 会造成多个等待进程同时指向相同的上一个等待进程,但是该inode.i_wait是共享的,只能有一个并发进程被保存到inode.i_wait,
 * 所以其他的并发进程将丢失了,是永远不会被唤醒的.
 * 每个进程调用该方法时,通过分配在栈上的tmp局部变量来串联所有等待任务的,这个链表本身也是个栈,先进后出,
 * 所以最后调用sleep_on方法的进程,会将自己的任务指针保存在inode.i_wait,当施加lock inode操作的进程释放lock,并调用wake_up方法后
 * 会唤醒inode.i_wait任务,该任务会唤醒它保存的上一个等待任务,以此类推,直到最后一个等待任务.
 * */
void sleep_on(struct task_struct **p)
{
	lock_op(&sleep_on_semaphore);

	struct task_struct* current = get_current_task();
	struct task_struct *tmp;

	if (!p) {
		unlock_op(&sleep_on_semaphore);
		return;
	}
	if (current == &(init_task.task))
		panic("task[0] trying to sleep");
	tmp = *p;        /* 将目前inode.i_wait指向的等待任务的指针保存到tmp */
	*p = current;    /* 将当前任务的指针，保存到inode.i_wait */
	current->state = TASK_UNINTERRUPTIBLE;  /* 将当前任务设置为不可中断的睡眠状态(必须通过wake_up唤醒，不能通过signal方式唤醒) */

	unlock_op(&sleep_on_semaphore);         /* 一定要在调度操作之前把锁释放了 */

	schedule();      /* 这里肯定调度其他任务执行了，不可能再是本任务了 */
	/*
	 * 这里最有意思了，每个等待任务用自己的局部变量tmp来保存前一个等待任务的指针，这样就形成了一个等待任务列表了。
	 * 当该任务被其他任务通过wake_up唤醒后，会紧接着执行下面的代码，把它自己维护的上一个等待任务的状态设置为running状态，
	 * 这样这个任务就被唤醒了，就有可能被下次schedule方法调度运行了，tricky吧，这里有必要解释一下。
	 * */
	if (tmp)
		tmp->state=0;
}

void interruptible_sleep_on(struct task_struct **p)
{
	lock_op(&interruptible_sleep_on_semaphore);
	struct task_struct* current = get_current_task();
	struct task_struct *tmp;

	if (!p) {
		unlock_op(&interruptible_sleep_on_semaphore);
		return;
	}
	if (current == &(init_task.task))
		panic("task[0] trying to sleep");
	tmp=*p;
	*p=current;
    repeat:
    current->state = TASK_INTERRUPTIBLE;
    unlock_op(&interruptible_sleep_on_semaphore);
	schedule();
	if (*p && *p != current) {
		(**p).state=0;
		goto repeat;
	}
	//*p=NULL;
	*p=tmp;
	if (tmp)
		tmp->state=0;
}

void wake_up(struct task_struct **p)
{
	if (p && *p) {
		(**p).state=0; /* 将等待任务的状态设置为running状态，这样就可以被schedule方法调度了. */
		//*p=NULL;
	}
}

/*
 * OK, here are some floppy things that shouldn't be in the kernel
 * proper. They are here because the floppy needs a timer, and this
 * was the easiest way of doing it.
 */
static struct task_struct * wait_motor[4] = {NULL,NULL,NULL,NULL};
static int  mon_timer[4]={0,0,0,0};
static int moff_timer[4]={0,0,0,0};
unsigned char current_DOR = 0x0C;

int ticks_to_floppy_on(unsigned int nr)
{
	extern unsigned char selected;
	unsigned char mask = 0x10 << nr;

	if (nr>3)
		panic("floppy_on: nr>3");
	moff_timer[nr]=10000;		/* 100 s = very big :-) */
	cli();				/* use floppy_off to turn it off */
	mask |= current_DOR;
	if (!selected) {
		mask &= 0xFC;
		mask |= nr;
	}
	if (mask != current_DOR) {
		outb(mask,FD_DOR);
		if ((mask ^ current_DOR) & 0xf0)
			mon_timer[nr] = HZ/2;
		else if (mon_timer[nr] < 2)
			mon_timer[nr] = 2;
		current_DOR = mask;
	}
	sti();
	return mon_timer[nr];
}

void floppy_on(unsigned int nr)
{
	cli();
	while (ticks_to_floppy_on(nr))
		sleep_on(nr+wait_motor);
	sti();
}

void floppy_off(unsigned int nr)
{
	moff_timer[nr]=3*HZ;
}

void do_floppy_timer(void)
{
	int i;
	unsigned char mask = 0x10;

	for (i=0 ; i<4 ; i++,mask <<= 1) {
		if (!(mask & current_DOR))
			continue;
		if (mon_timer[i]) {
			if (!--mon_timer[i])
				wake_up(i+wait_motor);
		} else if (!moff_timer[i]) {
			current_DOR &= ~mask;
			outb(current_DOR,FD_DOR);
		} else
			moff_timer[i]--;
	}
}

#define TIME_REQUESTS 64

static struct timer_list {
	long jiffies;
	void (*fn)();
	struct timer_list * next;
} timer_list[TIME_REQUESTS], * next_timer = NULL;

void add_timer(long jiffies, void (*fn)(void))
{
	struct timer_list * p;

	if (!fn)
		return;
	cli();
	if (jiffies <= 0)
		(fn)();
	else {
		for (p = timer_list ; p < timer_list + TIME_REQUESTS ; p++) {
			if (!p->fn)
				break;
		}
		if (p >= timer_list + TIME_REQUESTS)
			panic("No more time requests free");
		p->fn = fn;
		p->jiffies = jiffies;
		p->next = next_timer;
		next_timer = p;
		while (p->next && p->next->jiffies < p->jiffies) {
			p->jiffies -= p->next->jiffies;
			fn = p->fn;
			p->fn = p->next->fn;
			p->next->fn = fn;
			jiffies = p->jiffies;
			p->jiffies = p->next->jiffies;
			p->next->jiffies = jiffies;
			p = p->next;
		}
	}
	sti();
}

void do_timer(long cpl)
{
	if (get_current_apic_id() != 0) {
		//printk("ap execute do_timer\n\r");
	}
	struct task_struct* current = get_current_task();
	extern int beepcount;
	extern void sysbeepstop(void);

	if (beepcount)
		if (!--beepcount)
			sysbeepstop();

	if (cpl)
		current->utime++;
	else
		current->stime++;

	if (next_timer) {
		next_timer->jiffies--;
		while (next_timer && next_timer->jiffies <= 0) {
			void (*fn)(void);
			
			fn = next_timer->fn;
			next_timer->fn = NULL;
			next_timer = next_timer->next;
			(fn)();
		}
	}
	if (current_DOR & 0xf0)
		do_floppy_timer();
	if ((--current->counter)>0) return;
	current->counter=0;

	/*
	 * 后面有时间的话,会将调度改成在内核态可以进行抢占式调度,不过难度很大,最大的问题就是同步依赖问题,很容易造成锁的死锁状态.
	 * 任务要根据优先级,时间片,锁的依赖关系(每个进程是否要维护一个锁依赖列表)等等,要考虑的因素太多了,当前任务就不展开了.
	 *  */
	if (get_current_apic_id() == 0) {
		if (!cpl) return;  /* 这里可以看出内核态是不支持timer中断进行进程调度的，其他的外部中断除外 */
	}
	else {
		/* 1. 如果AP上当前运行的task != ap_default_task,那么AP上运行的就是普通的task,那么这个task在内核态很可能用到了很多同步锁,
		 *    如果调度运行其他任务的话,其他任务的时间片如果>当前任务的话,那么当前任务就有可能不会被调度,但是它占用的锁如果被其它进程依赖的话,
		 *    那么这种情况就造成了死锁状态.
		 * 2. 如果AP上运行的是当前任务是ap_default_task,其肯定是运行在内核态,但是它只执行idl_loop操作,
		 *    因此不会占用锁,也就不会造成其它进程的锁依赖,所以可以在内核态进行进程的调度.
		 *    */
		if (get_current_task() != &ap_default_task.task) {
			if (!cpl) return;
		}
	}

	schedule();
}

int sys_alarm(long seconds)
{
	struct task_struct* current = get_current_task();
	int old = current->alarm;

	if (old)
		old = (old - jiffies) / HZ;
	current->alarm = (seconds>0)?(jiffies+HZ*seconds):0;
	return (old);
}

int sys_getpid(void)
{
	struct task_struct* current = get_current_task();
	return current->pid;
}

int sys_getppid(void)
{
	struct task_struct* current = get_current_task();
	return current->father;
}

int sys_getuid(void)
{
	struct task_struct* current = get_current_task();
	return current->uid;
}

int sys_geteuid(void)
{
	struct task_struct* current = get_current_task();
	return current->euid;
}

int sys_getgid(void)
{
	struct task_struct* current = get_current_task();
	return current->gid;
}

int sys_getegid(void)
{
	struct task_struct* current = get_current_task();
	return current->egid;
}

int sys_nice(long increment)
{
	struct task_struct* current = get_current_task();
	if (current->priority-increment>0)
		current->priority -= increment;
	return 0;
}

void sched_init(void)
{
	int i;
	struct desc_struct * p;

	if (sizeof(struct sigaction) != 16)
		panic("Struct sigaction MUST be 16 bytes");
	set_tss_desc(gdt+FIRST_TSS_ENTRY,&(init_task.task.tss));
	set_ldt_desc(gdt+FIRST_LDT_ENTRY,&(init_task.task.ldt));
	p = gdt+2+FIRST_TSS_ENTRY;
	for(i=1;i<NR_TASKS;i++) {
		task[i] = NULL;
		p->a=p->b=0;
		p++;
		p->a=p->b=0;
		p++;
	}
/* Clear NT, so that we won't have troubles with that later on */
	__asm__("pushfl ; andl $0xffffbfff,(%esp) ; popfl");
	ltr(0);
	lldt(0);
	/* 设置8253定时器中断 */
#if 0
	outb_p(0x36,0x43);		/* binary, mode 3, LSB/MSB, ch 0 */
	outb_p(LATCH & 0xff , 0x40);	/* LSB */
	outb(LATCH >> 8 , 0x40);	/* MSB */
	set_intr_gate(0x20,&timer_interrupt);
	outb(inb_p(0x21)&~0x01,0x21);   /* Not mask timer intr */
#else
	set_intr_gate(APIC_TIMER_INTR_NO,&timer_interrupt);  /* Vector value 0x83 for APIC timer */
#endif

	set_system_gate(0x80,&system_call);
}

/*
 * GuestOS在内核态调用该方法实现在GuestOS中进行真正的进程切换.
 * 1. 首先保存老任务执行ljmp的下一条指令的地址。
 *    这样当重新调度老任务执行时，就从ljmp的下一条指令开始执行了。
 * 2. 利用新任务的task_struct.tss恢复新任务的执行上下文，执行新任务。
 * 3. 由task switch触发的VM-EXIT,在执行VM-RESUME后，都会到该函数中执行真正的任务切换。
 */
void task_switch() {
	/*
	 *  啦啦啦BigBug*BigBug*BigBug*啦啦啦BigBug*BigBug*BigBug*啦啦啦BigBug*BigBug*BigBug*啦啦啦BigBug*BigBug*BigBug*
	 *
	 *  任务切换隐藏了一个很深的monster bug，还是与FS段的设置与备份相关，以前的在实现多核任务调度的过程中也遇到这个问题。
	 *
	 *  造成这个bug的根本原因还是任务系统调用后会将FS设置为0x17指向用户态，这样在内核态就可以访问用户态的数据了(还记得get_fs_byte吗),
	 *  当任务执行fs read/write进入内核态其FS被system_call.s设置为0x17，当要访问HD时，在发出HD_read/write后会设置状态为interruptable_state,
	 *  等待HD_intr(本版本是BSP发送IPI通知AP),然后执行schedule调度其他任务执行,这时会发生task_switch触发VM-EXIT进入VMM去进行新老任务的备份和设置，
	 *  这时老任务的FS段肯定是被设置为0x17保存在exit_reason_task_switch->old_task_tss.fs中的.
	 *  但是当再次调度老任务的时候，这里并没有还原老任的fs所以造成任务在内核太访问用户态数据时出错,
	 *  太佩服自己了，通过纯代码逻辑推理在中断和任务切换等各种导致VM-EXIT的嵌套中，最终还是被我发现了(借我借我借我一双慧眼吧O(∩_∩)O哈哈~)。
	 *  其实主要还是这种情况很少出现，出现了想debug但悲催的是老是跟不进去，在此再次吐槽下GDB在虚拟化里的调试有点太不稳定了，连hb中断有时也跟不进去。
	 */

	/* 备份老任务的内核态ksp和kip到其对应task_struct.tss的esp和eip */
	exit_reason_task_switch_struct* exit_reason_task_switch = (exit_reason_task_switch_struct*) VM_EXIT_REASON_TASK_SWITCH_INFO_ADDR;
	/*
	 * 这里有必要解释一下为什么要这么设置老任务的tss段
	 * 因为在guest_state fields没有对应的field用于保存esp0和ss0等tss字段，
	 * 当VM-EXIT到VMM中备份老任务的tss段时,这些字段就没有被设置，所以为空。
	 * 因此在将exit_reason_task_switch->old_task_tss复制到task[n]->tss之前，要先备份task[n]->tss的这些字段，
	 * 因为复制完后这些字段会被设置为0，然后利用这些备份的值再还原这些值，数据的完整性就得到了保证。
	 */

	/* 备份老任务原先的某些字段值 */
	ulong ldt  = task[exit_reason_task_switch->old_task_nr]->tss.ldt;
	ulong esp0 = task[exit_reason_task_switch->old_task_nr]->tss.esp0;
	ulong cr3  = task[exit_reason_task_switch->old_task_nr]->tss.cr3;
	ulong eflags  = task[exit_reason_task_switch->old_task_nr]->tss.eflags;
	ulong ss0  = task[exit_reason_task_switch->old_task_nr]->tss.ss0;

	task[exit_reason_task_switch->old_task_nr]->tss = exit_reason_task_switch->old_task_tss;

	/* 还原老任务的某些字段值 */
	task[exit_reason_task_switch->old_task_nr]->tss.ldt  = ldt;
	task[exit_reason_task_switch->old_task_nr]->tss.esp0 = esp0;
	task[exit_reason_task_switch->old_task_nr]->tss.cr3  = cr3;
	task[exit_reason_task_switch->old_task_nr]->tss.eflags  = eflags;
	task[exit_reason_task_switch->old_task_nr]->tss.ss0  = ss0;

	/* 初始化新任务的context */
	unsigned long new_task_nr = exit_reason_task_switch->new_task_nr;
	unsigned long new_task_eip = task[new_task_nr]->tss.eip;
	unsigned long new_task_esp = task[new_task_nr]->tss.esp;
	/*
	 * 这里一定要设置新任务的tss.executed=1,因为这时新任务的guest-cr3-shadow的目录表结构肯定是初始化过了，
	 * 所以这里可以设置该标志.
     */
	task[new_task_nr]->executed = 1;

	ltr(new_task_nr);
	lldt(new_task_nr);
	/* 判断新任务的状态，是在内核态还是用户态(新创建的进程其task_struct.tss.cs!=0x08) */
	if (task[new_task_nr]->tss.cs != 0x08) {
		/* 手动恢复新进程的ds,es,fs,gs段寄存器和esi,edi */
		__asm__ ("movl $0x17,%%eax\n\t"   \
				/* "movw %%ax,%%ds\n\t"     \ */
				 "movw %%ax,%%es\n\t"     \
				 "movw %%ax,%%fs\n\t"     \
				 "movw %%ax,%%gs\n\t"     \
				 ::"S" (task[new_task_nr]->tss.esi),
				   "D" (task[new_task_nr]->tss.edi));
#if 1
		/* 手动入栈ss,esp,eflags,cs和eip寄存器，为iret返回新进程的用户态执行做准备,共享同一个eptp实现task-switch */
		__asm__ ("pushl $0x17\n\t" /* ss */      \
				 "pushl %%eax\n\t" /* esp,注意:这时新进程的用户态esp是共享父进程的用户态esp且是只读，所以后面会报WP错误进入do_wp_page重新分配一个RW esp. */     \
				 "pushfl\n\t"      /* eflgas */  \
				 "pushl $0x0f\n\t" /* cs */      \
				 "pushl %%ebx\n\t" /* eip */     \
				 "pushl %%ecx\n\t" /* 备份ebp */  \
				 "movl %%edx,%%cr3\n\t"           \
			    ::"a" (task[new_task_nr]->tss.esp),
				  "b" (task[new_task_nr]->tss.eip),
				  "c" (task[new_task_nr]->tss.ebp),
				  "d" (task[new_task_nr]->tss.cr3));
#else
		/* 手动入栈ss,esp,eflags,cs和eip寄存器，为iret返回新进程的用户态执行做准备,通过eptp-switching实现task-switch */
		__asm__ ("pushl $0x17\n\t" /* ss */      \
				 "pushl %%eax\n\t" /* esp,注意:这时新进程的用户态esp是共享父进程的用户态esp且是只读，所以后面会报WP错误进入do_wp_page重新分配一个RW esp. */     \
				 "pushfl\n\t"      /* eflgas */  \
				 "pushl $0x0f\n\t" /* cs */      \
				 "pushl %%ebx\n\t" /* eip */     \
				 "pushl %%ecx\n\t" /* 备份ebp */  \
				 "movl $0x00,%%eax\n\t"  /* 调用VM-FUNC的eptp-switching功能 */    \
				 "movl $0x01,%%ecx\n\t"  /* 将当前的eptp指针替换为ept_list_addr的index=1的eptp */  \
				 "vmfunc\n\t"                     \
 			     "movl %%cr3,%%eax\n\t"           \
				 "movl %%eax,%%cr3\n\t"           \
			    ::"a" (task[new_task_nr]->tss.esp),
				  "b" (task[new_task_nr]->tss.eip),
				  "c" (task[new_task_nr]->tss.ebp),
				  "d" (task[new_task_nr]->tss.cr3));
#endif
		/*
		 * 恢复新进程的eax,ebx,ecx,edx和ebp寄存器，调用iret指令返回新进程的用户态执行
		 * !!!这里一定要注意为什么在这时才更改ebp寄存器的值，那是因为GCC编译后,对局部变量的访问是通过ebp+-[n]或esp+-[n]进行的，
		 * 如果在此之前就改变了ebp或esp的值，那么ebp变成了要被调度进程的ebp而不是当前栈的，所以访问的局部变量就不对了.
		 */
		__asm__ ("pushl %%eax\n\t"       \
				 "movl $0x17,%%eax\n\t"  \
				 "movw %%ax,%%ds\n\t"    \
				 "popl %%eax\n\t"        \
				 "popl %%ebp\n\t"        \
				 "iret\n\t"              \
				 ::"a" (task[new_task_nr]->tss.eax),
				   "b" (task[new_task_nr]->tss.ebx),
				   "c" (task[new_task_nr]->tss.ecx),
				   "d" (task[new_task_nr]->tss.edx));
	}
	else {
		/*
		 * 对于老进程的恢复，只需要还原老进程的内核栈,kip和eflags及eax,ebx,ecx,edx,esi,edi和ebp即可，其它的会在iret中恢复。
		 *
		 * 这里有一个比较tricky的操作，将被调度任务的第一条要运行的指令的地址入栈到自己的内核栈中，想想看为什么要这样操作?
		 * 因为要还原被调度任务的内核态上下文，就要依次还原其内核态的eflags,esi,edi,eax,ebx,ecx,edx,ebp,esp,eip
		 * 但由于是从一个任务的内核态切换到另一个任务的内核态，所以不能用iret指令一次性从当前任务的内核栈中弹出ss,esp,eflags,cs,eip,
		 * 所以，通过手工的方式还原的话，一旦更改了当前任务的内核栈为被调度任务的内核栈后，当前任务的内核栈就不可用了，存储在其中的被调用任务的eip也就访问不到了,
		 * 这时调用ret指令弹出的是被调用任务的内核栈的栈顶数据，肯定是不对的，所以就有了这个比较tricky的方法O(∩_∩)O哈哈~
		 *
		 * 这里再次强调一下: 不管3721，一定要在调用ret指令之前还原被调度任务的tss.fs到FS寄存器.
		 */

		ulong* kernel_stack = (ulong* )(task[new_task_nr]->tss.esp -= 4); /* 在被调度进程的内核栈中开辟4字节空间用于存储自己的eip,供后面的ret调用 */
		*kernel_stack = task[new_task_nr]->tss.eip;

		/*
		 * 不管3721先还原被调度任务的FS段选择子到FS寄存器，吓死宝宝了O(∩_∩)O哈哈~
		 * 现在系统已经很稳定喽，真的是太不容易，Develop a high available and robust OS is so much hard.
		 */
		__asm__ ("mov %%ax,%%fs;"::"a" (task[new_task_nr]->tss.fs));

		__asm__ ("pushl %%eax\n\t"  \
				 "pushl %%ecx\n\t"  \
				 "pushl %%edx\n\t"  \
				 "movl %%ebx,%%cr3\n\t"  \
				 ::"a" (task[new_task_nr]->tss.esp),
				   "b" (task[new_task_nr]->tss.cr3),
				   "c" (task[new_task_nr]->tss.ebp),
				   "d" (task[new_task_nr]->tss.eflags),
				   "S" (task[new_task_nr]->tss.esi),
				   "D" (task[new_task_nr]->tss.edi));

		__asm__ ("popfl\n\t"       \
				 "popl %%ebp\n\t"  \
				 "popl %%esp\n\t" /* 注意:这里一定要最后在popl esp，知道为什么了吧 */ \
				 "ret\n\t"        /* 返回执行要被调度的任务的指令,注意:这时的esp已经是被调度任务的esp了，这时的栈顶存储的就是被调度进程的eip了 */ \
				 ::"a" (task[new_task_nr]->tss.eax),
				   "b" (task[new_task_nr]->tss.ebx),
				   "c" (task[new_task_nr]->tss.ecx),
				   "d" (task[new_task_nr]->tss.edx));
	}
}
