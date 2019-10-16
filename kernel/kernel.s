
kernel.o:     file format elf32-i386


Disassembly of section .text:

00000000 <task_switch>:
 * 1. 首先保存老任务执行ljmp的下一条指令的地址。
 *    这样当重新调度老任务执行时，就从ljmp的下一条指令开始执行了。
 * 2. 利用新任务的task_struct.tss恢复新任务的执行上下文，执行新任务。
 * 3. 由task switch触发的VM-EXIT,在执行VM-RESUME后，都会到该函数中执行真正的任务切换。
 */
void task_switch() {
       0:	55                   	push   %ebp
       1:	57                   	push   %edi
       2:	56                   	push   %esi
       3:	53                   	push   %ebx
       4:	83 ec 04             	sub    $0x4,%esp
	/* 备份老任务的内核态ksp和kip到其对应task_struct.tss的esp和eip */
	exit_reason_task_switch_struct* exit_reason_task_switch = (exit_reason_task_switch_struct*) VM_EXIT_REASON_TASK_SWITCH_INFO_ADDR;
	ulong ldt  = task[exit_reason_task_switch->old_task_nr]->tss.ldt;
       7:	a1 10 e0 09 00       	mov    0x9e010,%eax
       c:	8b 3c 85 00 00 00 00 	mov    0x0(,%eax,4),%edi
      13:	8b 97 48 03 00 00    	mov    0x348(%edi),%edx
	ulong esp0 = task[exit_reason_task_switch->old_task_nr]->tss.esp0;
      19:	8b 87 ec 02 00 00    	mov    0x2ec(%edi),%eax
	ulong cr3  = task[exit_reason_task_switch->old_task_nr]->tss.cr3;
      1f:	8b af 04 03 00 00    	mov    0x304(%edi),%ebp
	ulong eflags  = task[exit_reason_task_switch->old_task_nr]->tss.eflags;
      25:	8b 9f 0c 03 00 00    	mov    0x30c(%edi),%ebx
	ulong ss0  = task[exit_reason_task_switch->old_task_nr]->tss.ss0;
      2b:	8b b7 f0 02 00 00    	mov    0x2f0(%edi),%esi
      31:	89 34 24             	mov    %esi,(%esp)
	task[exit_reason_task_switch->old_task_nr]->tss = exit_reason_task_switch->old_task_tss;
      34:	81 c7 e8 02 00 00    	add    $0x2e8,%edi
      3a:	be 18 e0 09 00       	mov    $0x9e018,%esi
      3f:	b9 35 00 00 00       	mov    $0x35,%ecx
      44:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	task[exit_reason_task_switch->old_task_nr]->tss.ldt  = ldt;
      46:	8b 0d 10 e0 09 00    	mov    0x9e010,%ecx
      4c:	8b 0c 8d 00 00 00 00 	mov    0x0(,%ecx,4),%ecx
      53:	89 91 48 03 00 00    	mov    %edx,0x348(%ecx)
	task[exit_reason_task_switch->old_task_nr]->tss.esp0 = esp0;
      59:	8b 15 10 e0 09 00    	mov    0x9e010,%edx
      5f:	8b 14 95 00 00 00 00 	mov    0x0(,%edx,4),%edx
      66:	89 82 ec 02 00 00    	mov    %eax,0x2ec(%edx)
	task[exit_reason_task_switch->old_task_nr]->tss.cr3  = cr3;
      6c:	a1 10 e0 09 00       	mov    0x9e010,%eax
      71:	8b 04 85 00 00 00 00 	mov    0x0(,%eax,4),%eax
      78:	89 a8 04 03 00 00    	mov    %ebp,0x304(%eax)
	task[exit_reason_task_switch->old_task_nr]->tss.eflags  = eflags;
      7e:	a1 10 e0 09 00       	mov    0x9e010,%eax
      83:	8b 04 85 00 00 00 00 	mov    0x0(,%eax,4),%eax
      8a:	89 98 0c 03 00 00    	mov    %ebx,0x30c(%eax)
	task[exit_reason_task_switch->old_task_nr]->tss.ss0  = ss0;
      90:	a1 10 e0 09 00       	mov    0x9e010,%eax
      95:	8b 04 85 00 00 00 00 	mov    0x0(,%eax,4),%eax
      9c:	8b 34 24             	mov    (%esp),%esi
      9f:	89 b0 f0 02 00 00    	mov    %esi,0x2f0(%eax)

	/* 初始化新任务的context */
	unsigned long new_task_nr = exit_reason_task_switch->new_task_nr;
      a5:	8b 0d 04 e0 09 00    	mov    0x9e004,%ecx
	unsigned long new_task_eip = task[new_task_nr]->tss.eip;
      ab:	8b 2c 8d 00 00 00 00 	mov    0x0(,%ecx,4),%ebp
      b2:	8b 9d 08 03 00 00    	mov    0x308(%ebp),%ebx
	unsigned long new_task_esp = task[new_task_nr]->tss.esp;
      b8:	8b 85 20 03 00 00    	mov    0x320(%ebp),%eax
      be:	89 04 24             	mov    %eax,(%esp)
	/*
	 * 这里一定要设置新任务的tss.executed=1,因为这时新任务的guest-cr3-shadow的目录表结构肯定是初始化过了，
	 * 所以这里可以设置该标志.
     */
	task[new_task_nr]->executed = 1;
      c1:	c7 85 c8 03 00 00 01 	movl   $0x1,0x3c8(%ebp)
      c8:	00 00 00 

	ltr(new_task_nr);
      cb:	89 ca                	mov    %ecx,%edx
      cd:	c1 e2 04             	shl    $0x4,%edx
      d0:	8d 42 20             	lea    0x20(%edx),%eax
      d3:	0f 00 d8             	ltr    %ax
	lldt(new_task_nr);
      d6:	8d 42 28             	lea    0x28(%edx),%eax
      d9:	0f 00 d0             	lldt   %ax
	/* 判断新任务的状态，是在内核态还是用户态(新创建的进程其task_struct.tss.cs!=0x08) */
	if (task[new_task_nr]->tss.cs != 0x08) {
      dc:	83 bd 34 03 00 00 08 	cmpl   $0x8,0x334(%ebp)
      e3:	74 56                	je     13b <task_switch+0x13b>
		/* 手动恢复新进程的ds,es,fs,gs段寄存器和esi,edi */
		__asm__ ("movl $0x17,%%eax\n\t"   \
      e5:	8b b5 28 03 00 00    	mov    0x328(%ebp),%esi
      eb:	8b bd 2c 03 00 00    	mov    0x32c(%ebp),%edi
      f1:	b8 17 00 00 00       	mov    $0x17,%eax
      f6:	8e c0                	mov    %eax,%es
      f8:	8e e0                	mov    %eax,%fs
      fa:	8e e8                	mov    %eax,%gs
				 "movw %%ax,%%gs\n\t"     \
				 ::"S" (task[new_task_nr]->tss.esi),
				   "D" (task[new_task_nr]->tss.edi));
#if 1
		/* 手动入栈ss,esp,eflags,cs和eip寄存器，为iret返回新进程的用户态执行做准备,共享同一个eptp实现task-switch */
		__asm__ ("pushl $0x17\n\t" /* ss */      \
      fc:	8b 8d 24 03 00 00    	mov    0x324(%ebp),%ecx
     102:	8b 95 04 03 00 00    	mov    0x304(%ebp),%edx
     108:	8b 04 24             	mov    (%esp),%eax
     10b:	6a 17                	push   $0x17
     10d:	50                   	push   %eax
     10e:	9c                   	pushf  
     10f:	6a 0f                	push   $0xf
     111:	53                   	push   %ebx
     112:	51                   	push   %ecx
     113:	0f 22 da             	mov    %edx,%cr3
		/*
		 * 恢复新进程的eax,ebx,ecx,edx和ebp寄存器，调用iret指令返回新进程的用户态执行
		 * !!!这里一定要注意为什么在这时才更改ebp寄存器的值，那是因为GCC编译后,对局部变量的访问是通过ebp+-[n]或esp+-[n]进行的，
		 * 如果在此之前就改变了ebp或esp的值，那么ebp变成了要被调度进程的ebp而不是当前栈的，所以访问的局部变量就不对了.
		 */
		__asm__ ("pushl %%eax\n\t"       \
     116:	8b 85 10 03 00 00    	mov    0x310(%ebp),%eax
     11c:	8b 9d 1c 03 00 00    	mov    0x31c(%ebp),%ebx
     122:	8b 8d 14 03 00 00    	mov    0x314(%ebp),%ecx
     128:	8b 95 18 03 00 00    	mov    0x318(%ebp),%edx
     12e:	50                   	push   %eax
     12f:	b8 17 00 00 00       	mov    $0x17,%eax
     134:	8e d8                	mov    %eax,%ds
     136:	58                   	pop    %eax
     137:	5d                   	pop    %ebp
     138:	cf                   	iret   
     139:	eb 5e                	jmp    199 <task_switch+0x199>
		 * 因为是从一个任务的内核态切换到另一个任务的内核态，所以不能用iret指令一次性从当前任务的内核栈中弹出ss,esp,eflags,cs,eip
		 * 所以，通过手工的方式还原的话，一旦更改了当前任务的内核栈为被调度的内核栈后，当前任务的内核栈就不可用了，存储在其中的
		 * 被调用任务的eip也就访问不到了，这时调用ret指令弹出的是被调用任务的内核栈的栈顶数据，肯定是不对的，所以就有了这个比较tricky的方法O(∩_∩)O哈哈~
		 */

		ulong* kernel_stack = (ulong* )(task[new_task_nr]->tss.esp -= 4); /* 在被调度进程的内核栈中开辟4字节空间用于存储自己的eip,供后面的ret调用 */
     13b:	8b 34 24             	mov    (%esp),%esi
     13e:	89 f0                	mov    %esi,%eax
     140:	83 e8 04             	sub    $0x4,%eax
     143:	89 85 20 03 00 00    	mov    %eax,0x320(%ebp)
		*kernel_stack = task[new_task_nr]->tss.eip;
     149:	89 5e fc             	mov    %ebx,-0x4(%esi)

		__asm__ ("pushl %%eax\n\t"  \
				 "pushl %%ecx\n\t"  \
				 "pushl %%edx\n\t"  \
				 "movl %%ebx,%%cr3\n\t"  \
				 ::"a" (task[new_task_nr]->tss.esp),
     14c:	8b 2c 8d 00 00 00 00 	mov    0x0(,%ecx,4),%ebp
		 */

		ulong* kernel_stack = (ulong* )(task[new_task_nr]->tss.esp -= 4); /* 在被调度进程的内核栈中开辟4字节空间用于存储自己的eip,供后面的ret调用 */
		*kernel_stack = task[new_task_nr]->tss.eip;

		__asm__ ("pushl %%eax\n\t"  \
     153:	8b 85 20 03 00 00    	mov    0x320(%ebp),%eax
     159:	8b 9d 04 03 00 00    	mov    0x304(%ebp),%ebx
     15f:	8b 8d 24 03 00 00    	mov    0x324(%ebp),%ecx
     165:	8b 95 0c 03 00 00    	mov    0x30c(%ebp),%edx
     16b:	8b b5 28 03 00 00    	mov    0x328(%ebp),%esi
     171:	8b bd 2c 03 00 00    	mov    0x32c(%ebp),%edi
     177:	50                   	push   %eax
     178:	51                   	push   %ecx
     179:	52                   	push   %edx
     17a:	0f 22 db             	mov    %ebx,%cr3
				   "c" (task[new_task_nr]->tss.ebp),
				   "d" (task[new_task_nr]->tss.eflags),
				   "S" (task[new_task_nr]->tss.esi),
				   "D" (task[new_task_nr]->tss.edi));

		__asm__ ("popfl\n\t"       \
     17d:	8b 85 10 03 00 00    	mov    0x310(%ebp),%eax
     183:	8b 9d 1c 03 00 00    	mov    0x31c(%ebp),%ebx
     189:	8b 8d 14 03 00 00    	mov    0x314(%ebp),%ecx
     18f:	8b 95 18 03 00 00    	mov    0x318(%ebp),%edx
     195:	9d                   	popf   
     196:	5d                   	pop    %ebp
     197:	5c                   	pop    %esp
     198:	c3                   	ret    
				 ::"a" (task[new_task_nr]->tss.eax),
				   "b" (task[new_task_nr]->tss.ebx),
				   "c" (task[new_task_nr]->tss.ecx),
				   "d" (task[new_task_nr]->tss.edx));
	}
}
     199:	83 c4 04             	add    $0x4,%esp
     19c:	5b                   	pop    %ebx
     19d:	5e                   	pop    %esi
     19e:	5f                   	pop    %edi
     19f:	5d                   	pop    %ebp
     1a0:	c3                   	ret    

000001a1 <show_task>:

extern void task_exit_clear(void);
void task_switch();

void show_task(int nr,struct task_struct * p)
{
     1a1:	53                   	push   %ebx
     1a2:	83 ec 08             	sub    $0x8,%esp
     1a5:	8b 5c 24 14          	mov    0x14(%esp),%ebx
	int i,j = 4096-sizeof(struct task_struct);

	printk("%d: pid=%d, state=%d, ",nr,p->pid,p->state);
     1a9:	ff 33                	pushl  (%ebx)
     1ab:	ff b3 2c 02 00 00    	pushl  0x22c(%ebx)
     1b1:	ff 74 24 18          	pushl  0x18(%esp)
     1b5:	68 00 00 00 00       	push   $0x0
     1ba:	e8 fc ff ff ff       	call   1bb <show_task+0x1a>
	i=0;
	while (i<j && !((char *)(p+1))[i])
     1bf:	83 c4 10             	add    $0x10,%esp
     1c2:	b8 01 00 00 00       	mov    $0x1,%eax
     1c7:	80 bb cc 03 00 00 00 	cmpb   $0x0,0x3cc(%ebx)
     1ce:	74 11                	je     1e1 <show_task+0x40>
void show_task(int nr,struct task_struct * p)
{
	int i,j = 4096-sizeof(struct task_struct);

	printk("%d: pid=%d, state=%d, ",nr,p->pid,p->state);
	i=0;
     1d0:	b8 00 00 00 00       	mov    $0x0,%eax
     1d5:	eb 14                	jmp    1eb <show_task+0x4a>
	while (i<j && !((char *)(p+1))[i])
		i++;
     1d7:	83 c0 01             	add    $0x1,%eax
{
	int i,j = 4096-sizeof(struct task_struct);

	printk("%d: pid=%d, state=%d, ",nr,p->pid,p->state);
	i=0;
	while (i<j && !((char *)(p+1))[i])
     1da:	3d 34 0c 00 00       	cmp    $0xc34,%eax
     1df:	74 0a                	je     1eb <show_task+0x4a>
     1e1:	80 bc 03 cc 03 00 00 	cmpb   $0x0,0x3cc(%ebx,%eax,1)
     1e8:	00 
     1e9:	74 ec                	je     1d7 <show_task+0x36>
		i++;
	printk("%d (of %d) chars free in kernel stack\n\r",i,j);
     1eb:	83 ec 04             	sub    $0x4,%esp
     1ee:	68 34 0c 00 00       	push   $0xc34
     1f3:	50                   	push   %eax
     1f4:	68 00 00 00 00       	push   $0x0
     1f9:	e8 fc ff ff ff       	call   1fa <show_task+0x59>
}
     1fe:	83 c4 18             	add    $0x18,%esp
     201:	5b                   	pop    %ebx
     202:	c3                   	ret    

00000203 <show_stat>:

void show_stat(void)
{
     203:	53                   	push   %ebx
     204:	83 ec 08             	sub    $0x8,%esp
	int i;

	for (i=0;i<NR_TASKS;i++)
     207:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (task[i])
     20c:	8b 04 9d 00 00 00 00 	mov    0x0(,%ebx,4),%eax
     213:	85 c0                	test   %eax,%eax
     215:	74 0d                	je     224 <show_stat+0x21>
			show_task(i,task[i]);
     217:	83 ec 08             	sub    $0x8,%esp
     21a:	50                   	push   %eax
     21b:	53                   	push   %ebx
     21c:	e8 fc ff ff ff       	call   21d <show_stat+0x1a>
     221:	83 c4 10             	add    $0x10,%esp

void show_stat(void)
{
	int i;

	for (i=0;i<NR_TASKS;i++)
     224:	83 c3 01             	add    $0x1,%ebx
     227:	83 fb 40             	cmp    $0x40,%ebx
     22a:	75 e0                	jne    20c <show_stat+0x9>
		if (task[i])
			show_task(i,task[i]);
}
     22c:	83 c4 08             	add    $0x8,%esp
     22f:	5b                   	pop    %ebx
     230:	c3                   	ret    

00000231 <get_current_apic_id>:
	} stack_start = {&user_stack[PAGE_SIZE>>2] , 0x10};

/*
 * 获取当前processor正在运行的任务
 */
unsigned long get_current_apic_id(){
     231:	53                   	push   %ebx
     232:	83 ec 10             	sub    $0x10,%esp
	register unsigned long apic_id asm("ebx");
	unsigned char gdt_base[8] = {0,}; /* 16-bit limit stored in low two bytes, and gdt_base stored in high 4bytes. */
     235:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
     23c:	00 
     23d:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
     244:	00 
	/*
	 * 在Guest VM 环境下，执行cpuid指令会导致vm-exit，所以这里要判断当前的执行环境是否在VM环境.
	 * 实现思路：我们知道在VM环境下，已经为GDT表分配了4K空间，且GDT表的首8字节是不用的，这里利用这8个字节存储vm-entry环境下的apic_id.
	 */
	__asm__ ("sgdt %1\n\t"              \
     245:	0f 01 44 24 08       	sgdtl  0x8(%esp)
     24a:	8b 44 24 0a          	mov    0xa(%esp),%eax
     24e:	8b 18                	mov    (%eax),%ebx
     250:	83 fb 00             	cmp    $0x0,%ebx
     253:	75 0c                	jne    261 <truncate_flag>
     255:	b8 01 00 00 00       	mov    $0x1,%eax
     25a:	0f a2                	cpuid  
     25c:	c1 eb 18             	shr    $0x18,%ebx
     25f:	eb 06                	jmp    267 <output>

00000261 <truncate_flag>:
     261:	81 e3 ff 00 00 00    	and    $0xff,%ebx

00000267 <output>:
			 "truncate_flag:\n\t"       \
			 "andl $0xFF,%%ebx\n\t" /* 这里假设最多有255个processor */  \
			 "output:\n\t"              \
			 :"=b" (apic_id) :"m" (*gdt_base),"m" (*(char*)(gdt_base+2))
			);
	return apic_id;
     267:	89 d8                	mov    %ebx,%eax
}
     269:	83 c4 10             	add    $0x10,%esp
     26c:	5b                   	pop    %ebx
     26d:	c3                   	ret    

0000026e <get_apic_info>:



struct apic_info* get_apic_info(unsigned long apic_id) {
     26e:	8b 54 24 04          	mov    0x4(%esp),%edx
	for (int i=0;i<LOGICAL_PROCESSOR_NUM;i++) {
		if (apic_ids[i].apic_id == apic_id) {
     272:	3b 15 04 00 00 00    	cmp    0x4,%edx
     278:	74 32                	je     2ac <get_apic_info+0x3e>
     27a:	3b 15 20 00 00 00    	cmp    0x20,%edx
     280:	74 1c                	je     29e <get_apic_info+0x30>
     282:	3b 15 3c 00 00 00    	cmp    0x3c,%edx
     288:	74 1b                	je     2a5 <get_apic_info+0x37>
			return &apic_ids[i];
		}
	}
	return 0;
     28a:	b8 00 00 00 00       	mov    $0x0,%eax



struct apic_info* get_apic_info(unsigned long apic_id) {
	for (int i=0;i<LOGICAL_PROCESSOR_NUM;i++) {
		if (apic_ids[i].apic_id == apic_id) {
     28f:	39 15 58 00 00 00    	cmp    %edx,0x58
     295:	75 22                	jne    2b9 <get_apic_info+0x4b>
}



struct apic_info* get_apic_info(unsigned long apic_id) {
	for (int i=0;i<LOGICAL_PROCESSOR_NUM;i++) {
     297:	b8 03 00 00 00       	mov    $0x3,%eax
     29c:	eb 13                	jmp    2b1 <get_apic_info+0x43>
     29e:	b8 01 00 00 00       	mov    $0x1,%eax
     2a3:	eb 0c                	jmp    2b1 <get_apic_info+0x43>
     2a5:	b8 02 00 00 00       	mov    $0x2,%eax
     2aa:	eb 05                	jmp    2b1 <get_apic_info+0x43>
     2ac:	b8 00 00 00 00       	mov    $0x0,%eax
		if (apic_ids[i].apic_id == apic_id) {
			return &apic_ids[i];
     2b1:	6b c0 1c             	imul   $0x1c,%eax,%eax
     2b4:	05 00 00 00 00       	add    $0x0,%eax
		}
	}
	return 0;
}
     2b9:	f3 c3                	repz ret 

000002bb <get_current_task>:

struct task_struct* get_current_task(){
	return get_apic_info(get_current_apic_id())->current;
     2bb:	e8 fc ff ff ff       	call   2bc <get_current_task+0x1>
     2c0:	50                   	push   %eax
     2c1:	e8 fc ff ff ff       	call   2c2 <get_current_task+0x7>
     2c6:	83 c4 04             	add    $0x4,%esp
     2c9:	8b 40 14             	mov    0x14(%eax),%eax
}
     2cc:	c3                   	ret    

000002cd <sys_alarm>:

	schedule();
}

int sys_alarm(long seconds)
{
     2cd:	56                   	push   %esi
     2ce:	53                   	push   %ebx
     2cf:	8b 5c 24 0c          	mov    0xc(%esp),%ebx
	struct task_struct* current = get_current_task();
     2d3:	e8 fc ff ff ff       	call   2d4 <sys_alarm+0x7>
     2d8:	89 c6                	mov    %eax,%esi
	int old = current->alarm;
     2da:	8b 80 4c 02 00 00    	mov    0x24c(%eax),%eax

	if (old)
     2e0:	85 c0                	test   %eax,%eax
     2e2:	74 1b                	je     2ff <sys_alarm+0x32>
		old = (old - jiffies) / HZ;
     2e4:	8b 15 00 00 00 00    	mov    0x0,%edx
     2ea:	29 d0                	sub    %edx,%eax
     2ec:	89 c1                	mov    %eax,%ecx
     2ee:	ba 67 66 66 66       	mov    $0x66666667,%edx
     2f3:	f7 ea                	imul   %edx
     2f5:	89 d0                	mov    %edx,%eax
     2f7:	c1 f8 02             	sar    $0x2,%eax
     2fa:	c1 f9 1f             	sar    $0x1f,%ecx
     2fd:	29 c8                	sub    %ecx,%eax
	current->alarm = (seconds>0)?(jiffies+HZ*seconds):0;
     2ff:	85 db                	test   %ebx,%ebx
     301:	7e 0e                	jle    311 <sys_alarm+0x44>
     303:	8b 15 00 00 00 00    	mov    0x0,%edx
     309:	8d 0c 9b             	lea    (%ebx,%ebx,4),%ecx
     30c:	8d 14 4a             	lea    (%edx,%ecx,2),%edx
     30f:	eb 05                	jmp    316 <sys_alarm+0x49>
     311:	ba 00 00 00 00       	mov    $0x0,%edx
     316:	89 96 4c 02 00 00    	mov    %edx,0x24c(%esi)
	return (old);
}
     31c:	5b                   	pop    %ebx
     31d:	5e                   	pop    %esi
     31e:	c3                   	ret    

0000031f <sys_getpid>:

int sys_getpid(void)
{
	struct task_struct* current = get_current_task();
     31f:	e8 fc ff ff ff       	call   320 <sys_getpid+0x1>
	return current->pid;
     324:	8b 80 2c 02 00 00    	mov    0x22c(%eax),%eax
}
     32a:	c3                   	ret    

0000032b <sys_getppid>:

int sys_getppid(void)
{
	struct task_struct* current = get_current_task();
     32b:	e8 fc ff ff ff       	call   32c <sys_getppid+0x1>
	return current->father;
     330:	8b 80 30 02 00 00    	mov    0x230(%eax),%eax
}
     336:	c3                   	ret    

00000337 <sys_getuid>:

int sys_getuid(void)
{
	struct task_struct* current = get_current_task();
     337:	e8 fc ff ff ff       	call   338 <sys_getuid+0x1>
	return current->uid;
     33c:	0f b7 80 40 02 00 00 	movzwl 0x240(%eax),%eax
}
     343:	c3                   	ret    

00000344 <sys_geteuid>:

int sys_geteuid(void)
{
	struct task_struct* current = get_current_task();
     344:	e8 fc ff ff ff       	call   345 <sys_geteuid+0x1>
	return current->euid;
     349:	0f b7 80 42 02 00 00 	movzwl 0x242(%eax),%eax
}
     350:	c3                   	ret    

00000351 <sys_getgid>:

int sys_getgid(void)
{
	struct task_struct* current = get_current_task();
     351:	e8 fc ff ff ff       	call   352 <sys_getgid+0x1>
	return current->gid;
     356:	0f b7 80 46 02 00 00 	movzwl 0x246(%eax),%eax
}
     35d:	c3                   	ret    

0000035e <sys_getegid>:

int sys_getegid(void)
{
	struct task_struct* current = get_current_task();
     35e:	e8 fc ff ff ff       	call   35f <sys_getegid+0x1>
	return current->egid;
     363:	0f b7 80 48 02 00 00 	movzwl 0x248(%eax),%eax
}
     36a:	c3                   	ret    

0000036b <sys_nice>:

int sys_nice(long increment)
{
	struct task_struct* current = get_current_task();
     36b:	e8 fc ff ff ff       	call   36c <sys_nice+0x1>
	if (current->priority-increment>0)
     370:	8b 50 08             	mov    0x8(%eax),%edx
     373:	2b 54 24 04          	sub    0x4(%esp),%edx
     377:	85 d2                	test   %edx,%edx
     379:	7e 03                	jle    37e <sys_nice+0x13>
		current->priority -= increment;
     37b:	89 50 08             	mov    %edx,0x8(%eax)
	return 0;
}
     37e:	b8 00 00 00 00       	mov    $0x0,%eax
     383:	c3                   	ret    

00000384 <reset_cpu_load>:
	return get_apic_info(get_current_apic_id())->current;
}

void reset_cpu_load() {
	for (int i=0;i<LOGICAL_PROCESSOR_NUM;i++) {
		apic_ids[i].load_per_apic = 0;
     384:	c7 05 10 00 00 00 00 	movl   $0x0,0x10
     38b:	00 00 00 
     38e:	c7 05 2c 00 00 00 00 	movl   $0x0,0x2c
     395:	00 00 00 
     398:	c7 05 48 00 00 00 00 	movl   $0x0,0x48
     39f:	00 00 00 
     3a2:	c7 05 64 00 00 00 00 	movl   $0x0,0x64
     3a9:	00 00 00 
     3ac:	c3                   	ret    

000003ad <get_min_load_ap>:
	}
}

/* 计算哪个AP的负载最小，后续的task将会调度该AP执行。 */
unsigned long get_min_load_ap() {
     3ad:	53                   	push   %ebx
	unsigned long apic_index = 1;  /* BSP不参与计算 */
	int overload = 0;
	if (apic_ids[apic_index].load_per_apic == 0xFFFFFFFF) {
     3ae:	a1 2c 00 00 00       	mov    0x2c,%eax
}

/* 计算哪个AP的负载最小，后续的task将会调度该AP执行。 */
unsigned long get_min_load_ap() {
	unsigned long apic_index = 1;  /* BSP不参与计算 */
	int overload = 0;
     3b3:	83 f8 ff             	cmp    $0xffffffff,%eax
     3b6:	0f 94 c2             	sete   %dl
     3b9:	0f b6 d2             	movzbl %dl,%edx
	if (apic_ids[apic_index].load_per_apic == 0xFFFFFFFF) {
		++overload;
	}
	for (int i=2;i<LOGICAL_PROCESSOR_NUM;i++) {
		if (apic_ids[i].load_per_apic == 0xFFFFFFFF) {
     3bc:	8b 0d 48 00 00 00    	mov    0x48,%ecx
     3c2:	83 f9 ff             	cmp    $0xffffffff,%ecx
     3c5:	74 0b                	je     3d2 <get_min_load_ap+0x25>
			++overload;
			continue;
		}
		if (apic_ids[apic_index].load_per_apic > apic_ids[i].load_per_apic) {
     3c7:	39 c1                	cmp    %eax,%ecx
     3c9:	19 c0                	sbb    %eax,%eax
     3cb:	f7 d0                	not    %eax
     3cd:	83 c0 02             	add    $0x2,%eax
     3d0:	eb 08                	jmp    3da <get_min_load_ap+0x2d>
	if (apic_ids[apic_index].load_per_apic == 0xFFFFFFFF) {
		++overload;
	}
	for (int i=2;i<LOGICAL_PROCESSOR_NUM;i++) {
		if (apic_ids[i].load_per_apic == 0xFFFFFFFF) {
			++overload;
     3d2:	83 c2 01             	add    $0x1,%edx
     3d5:	b8 01 00 00 00       	mov    $0x1,%eax
	int overload = 0;
	if (apic_ids[apic_index].load_per_apic == 0xFFFFFFFF) {
		++overload;
	}
	for (int i=2;i<LOGICAL_PROCESSOR_NUM;i++) {
		if (apic_ids[i].load_per_apic == 0xFFFFFFFF) {
     3da:	8b 1d 64 00 00 00    	mov    0x64,%ebx
     3e0:	83 fb ff             	cmp    $0xffffffff,%ebx
     3e3:	75 05                	jne    3ea <get_min_load_ap+0x3d>
			++overload;
     3e5:	83 c2 01             	add    $0x1,%edx
			continue;
     3e8:	eb 14                	jmp    3fe <get_min_load_ap+0x51>
		}
		if (apic_ids[apic_index].load_per_apic > apic_ids[i].load_per_apic) {
     3ea:	6b c8 1c             	imul   $0x1c,%eax,%ecx
     3ed:	81 c1 00 00 00 00    	add    $0x0,%ecx
			apic_index = i;
     3f3:	3b 59 10             	cmp    0x10(%ecx),%ebx
     3f6:	b9 03 00 00 00       	mov    $0x3,%ecx
     3fb:	0f 42 c1             	cmovb  %ecx,%eax
		}
	}
	if (overload == LOGICAL_PROCESSOR_NUM-1) {
     3fe:	83 fa 03             	cmp    $0x3,%edx
     401:	75 0c                	jne    40f <get_min_load_ap+0x62>
		reset_cpu_load();
     403:	e8 fc ff ff ff       	call   404 <get_min_load_ap+0x57>
		return apic_ids[LOGICAL_PROCESSOR_NUM-1].apic_id;
     408:	a1 58 00 00 00       	mov    0x58,%eax
     40d:	eb 09                	jmp    418 <get_min_load_ap+0x6b>
	}

	return apic_ids[apic_index].apic_id;
     40f:	6b c0 1c             	imul   $0x1c,%eax,%eax
     412:	8b 80 04 00 00 00    	mov    0x4(%eax),%eax
}
     418:	5b                   	pop    %ebx
     419:	c3                   	ret    

0000041a <check_default_task_running_on_ap>:

int check_default_task_running_on_ap() {
	if (get_current_apic_id()) {
     41a:	e8 fc ff ff ff       	call   41b <check_default_task_running_on_ap+0x1>
		}
		else {
			return 0;
		}
	}
	return 0;
     41f:	ba 00 00 00 00       	mov    $0x0,%edx

	return apic_ids[apic_index].apic_id;
}

int check_default_task_running_on_ap() {
	if (get_current_apic_id()) {
     424:	85 c0                	test   %eax,%eax
     426:	74 10                	je     438 <check_default_task_running_on_ap+0x1e>
		if (get_current_task() == &ap_default_task.task) {
     428:	e8 fc ff ff ff       	call   429 <check_default_task_running_on_ap+0xf>
			return 1;
     42d:	3d 00 00 00 00       	cmp    $0x0,%eax
     432:	0f 94 c2             	sete   %dl
     435:	0f b6 d2             	movzbl %dl,%edx
		else {
			return 0;
		}
	}
	return 0;
}
     438:	89 d0                	mov    %edx,%eax
     43a:	c3                   	ret    

0000043b <send_IPI>:
/*
 * 向指定的AP发送IPI中断消息,要先写ICR的高32位，因为写低32位就会触发IPI了，
 * 所以要现将apic_id写到destination field,然后再触发IPI。
 */
#if EMULATOR_TYPE
void send_IPI(int apic_id, int v_num) {
     43b:	53                   	push   %ebx
__asm__ ("movl bsp_apic_default_location,%%edx\n\t" \
     43c:	8b 4c 24 08          	mov    0x8(%esp),%ecx
     440:	8b 5c 24 0c          	mov    0xc(%esp),%ebx
     444:	8b 15 00 00 00 00    	mov    0x0,%edx
     44a:	52                   	push   %edx
     44b:	e8 fc ff ff ff       	call   44c <send_IPI+0x11>
     450:	5a                   	pop    %edx
     451:	89 c2                	mov    %eax,%edx
     453:	83 c2 10             	add    $0x10,%edx
     456:	c1 e1 18             	shl    $0x18,%ecx
     459:	89 0a                	mov    %ecx,(%edx)
     45b:	89 c2                	mov    %eax,%edx
     45d:	81 c3 00 40 00 00    	add    $0x4000,%ebx
     463:	89 1a                	mov    %ebx,(%edx)
     465:	50                   	push   %eax
     466:	e8 fc ff ff ff       	call   467 <send_IPI+0x2c>
     46b:	58                   	pop    %eax

0000046c <wait_loop_ipi>:
     46c:	31 c0                	xor    %eax,%eax
     46e:	8b 02                	mov    (%edx),%eax
     470:	25 00 10 00 00       	and    $0x1000,%eax
     475:	83 f8 00             	cmp    $0x0,%eax
     478:	75 f2                	jne    46c <wait_loop_ipi>
		 "movl 0(%%edx),%%eax\n\t" \
		 "andl $0x00001000,%%eax\n\t"    /* 判断ICR低32位的delivery status field, 0: idle, 1: send pending */  \
		 "cmpl $0x00,%%eax\n\t"   \
		 "jne wait_loop_ipi\n\t"  \
		 ::"c" (apic_id),"b" (v_num));
}
     47a:	5b                   	pop    %ebx
     47b:	c3                   	ret    

0000047c <send_EOI>:

/* 发送中断处理结束信号： end of interrupt */
void send_EOI() {
     47c:	83 ec 0c             	sub    $0xc,%esp
	unsigned long apic_id = get_current_apic_id();
     47f:	e8 fc ff ff ff       	call   480 <send_EOI+0x4>
	struct apic_info* apic = get_apic_info(apic_id);
     484:	50                   	push   %eax
     485:	e8 fc ff ff ff       	call   486 <send_EOI+0xa>
     48a:	83 c4 04             	add    $0x4,%esp
	if (apic) {
     48d:	85 c0                	test   %eax,%eax
     48f:	74 21                	je     4b2 <send_EOI+0x36>
		unsigned long addr = apic->apic_regs_addr;
		addr = remap_msr_linear_addr(addr);
     491:	83 ec 0c             	sub    $0xc,%esp
     494:	ff 70 08             	pushl  0x8(%eax)
     497:	e8 fc ff ff ff       	call   498 <send_EOI+0x1c>
		__asm__("addl $0xB0,%%eax\n\t" /* EOI register offset relative with APIC_REGS_BASE is 0xB0 */ \
     49c:	05 b0 00 00 00       	add    $0xb0,%eax
     4a1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
				"movl $0x00,0(%%eax)"  /* Write EOI register */ \
				::"a" (addr)
				);
		recov_msr_swap_linear(addr);
     4a7:	89 04 24             	mov    %eax,(%esp)
     4aa:	e8 fc ff ff ff       	call   4ab <send_EOI+0x2f>
     4af:	83 c4 10             	add    $0x10,%esp
	}
}
     4b2:	83 c4 0c             	add    $0xc,%esp
     4b5:	c3                   	ret    

000004b6 <get_current_apic_index>:
}
#endif


unsigned long get_current_apic_index() {
	unsigned long apic_id = get_current_apic_id();
     4b6:	e8 fc ff ff ff       	call   4b7 <get_current_apic_index+0x1>
     4bb:	89 c2                	mov    %eax,%edx
	for (int i=0;i<LOGICAL_PROCESSOR_NUM;i++) {
		if (apic_ids[i].apic_id == apic_id) {
     4bd:	3b 05 04 00 00 00    	cmp    0x4,%eax
     4c3:	74 2f                	je     4f4 <get_current_apic_index+0x3e>
     4c5:	3b 05 20 00 00 00    	cmp    0x20,%eax
     4cb:	74 1b                	je     4e8 <get_current_apic_index+0x32>
     4cd:	3b 05 3c 00 00 00    	cmp    0x3c,%eax
     4d3:	74 19                	je     4ee <get_current_apic_index+0x38>
			return i;
		}
	}
	return 0;
     4d5:	b8 00 00 00 00       	mov    $0x0,%eax


unsigned long get_current_apic_index() {
	unsigned long apic_id = get_current_apic_id();
	for (int i=0;i<LOGICAL_PROCESSOR_NUM;i++) {
		if (apic_ids[i].apic_id == apic_id) {
     4da:	3b 15 58 00 00 00    	cmp    0x58,%edx
     4e0:	75 17                	jne    4f9 <get_current_apic_index+0x43>
#endif


unsigned long get_current_apic_index() {
	unsigned long apic_id = get_current_apic_id();
	for (int i=0;i<LOGICAL_PROCESSOR_NUM;i++) {
     4e2:	b8 03 00 00 00       	mov    $0x3,%eax
     4e7:	c3                   	ret    
     4e8:	b8 01 00 00 00       	mov    $0x1,%eax
     4ed:	c3                   	ret    
     4ee:	b8 02 00 00 00       	mov    $0x2,%eax
     4f3:	c3                   	ret    
     4f4:	b8 00 00 00 00       	mov    $0x0,%eax
		if (apic_ids[i].apic_id == apic_id) {
			return i;
		}
	}
	return 0;
}
     4f9:	f3 c3                	repz ret 

000004fb <reload_ap_ltr>:

/* 主要是为了AP初始化的时候使用，用于任务一开始切换时，将当前内核态的context信息存储到指定的位置，而不是一开始默认的0x00地址处，这样就不会覆盖内核的目录表了。 */
void reload_ap_ltr() {
	//set_tss_desc(gdt+(nr<<1)+FIRST_TSS_ENTRY, &(ap_default_task.task.tss));
	int nr = (get_current_apic_index() + AP_DEFAULT_TASK_NR);
     4fb:	e8 fc ff ff ff       	call   4fc <reload_ap_ltr+0x1>
	ltr(nr);
     500:	c1 e0 04             	shl    $0x4,%eax
     503:	8d 80 20 05 00 00    	lea    0x520(%eax),%eax
     509:	0f 00 d8             	ltr    %ax
     50c:	c3                   	ret    

0000050d <init_ap_tss>:
}

void init_ap_tss(int nr) {
	set_tss_desc(gdt+(nr<<1)+FIRST_TSS_ENTRY, &(ap_default_task.task.tss));
     50d:	8b 44 24 04          	mov    0x4(%esp),%eax
     511:	8d 54 00 04          	lea    0x4(%eax,%eax,1),%edx
     515:	b8 e8 02 00 00       	mov    $0x2e8,%eax
     51a:	66 c7 04 d5 00 00 00 	movw   $0x68,0x0(,%edx,8)
     521:	00 68 00 
     524:	66 89 04 d5 02 00 00 	mov    %ax,0x2(,%edx,8)
     52b:	00 
     52c:	c1 c8 10             	ror    $0x10,%eax
     52f:	88 04 d5 04 00 00 00 	mov    %al,0x4(,%edx,8)
     536:	c6 04 d5 05 00 00 00 	movb   $0x89,0x5(,%edx,8)
     53d:	89 
     53e:	c6 04 d5 06 00 00 00 	movb   $0x0,0x6(,%edx,8)
     545:	00 
     546:	88 24 d5 07 00 00 00 	mov    %ah,0x7(,%edx,8)
     54d:	c1 c8 10             	ror    $0x10,%eax
     550:	c3                   	ret    

00000551 <reset_ap_default_task>:
}

void reset_ap_default_task() {
	unsigned long apic_index = get_current_apic_index();
     551:	e8 fc ff ff ff       	call   552 <reset_ap_default_task+0x1>
	apic_ids[apic_index].current = &ap_default_task.task;
     556:	6b c0 1c             	imul   $0x1c,%eax,%eax
     559:	c7 80 14 00 00 00 00 	movl   $0x0,0x14(%eax)
     560:	00 00 00 
     563:	c3                   	ret    

00000564 <lock_op>:
}

void lock_op(unsigned long* sem_addr) {
	__asm__ ("lock_loop:\n\t"        \
     564:	8b 44 24 04          	mov    0x4(%esp),%eax

00000568 <lock_loop>:
     568:	83 38 00             	cmpl   $0x0,(%eax)
     56b:	75 fb                	jne    568 <lock_loop>
     56d:	ba 01 00 00 00       	mov    $0x1,%edx
     572:	f0 87 10             	lock xchg %edx,(%eax)
     575:	83 fa 00             	cmp    $0x0,%edx
     578:	75 ee                	jne    568 <lock_loop>
     57a:	c3                   	ret    

0000057b <unlock_op>:
			 ::"m" (*sem_addr)       \
		    );
}

void unlock_op(unsigned long* sem_addr) {
	__asm__ ("cmpl $0x00,%0\n\t" \
     57b:	8b 44 24 04          	mov    0x4(%esp),%eax
     57f:	83 38 00             	cmpl   $0x0,(%eax)
     582:	7e 03                	jle    587 <unlock_op+0xc>
     584:	83 28 01             	subl   $0x1,(%eax)
     587:	c3                   	ret    

00000588 <reset_ap_context>:
			 "1:\n\t" \
			 ::"m" (*sem_addr)   \
			);
}

void reset_ap_context() {
     588:	56                   	push   %esi
     589:	53                   	push   %ebx
     58a:	83 ec 04             	sub    $0x4,%esp
	unsigned long apic_index =  get_current_apic_index();
     58d:	e8 fc ff ff ff       	call   58e <reset_ap_context+0x6>
     592:	89 c3                	mov    %eax,%ebx
	int father_id = get_current_task()->father;
     594:	e8 fc ff ff ff       	call   595 <reset_ap_context+0xd>
     599:	8b b0 30 02 00 00    	mov    0x230(%eax),%esi
	/* tricky 1:
	 * 因为task运行到这,一定是处于内核态的,因此目录表的前256项(管理1G的内核线性地址空间)都是指向相同的页表的.
	 * 这里一定要将AP的CR3设置为0x00,那是因为当前进程随后会被释放掉，其对应的目录表也会被释放掉,就会被其他进程占用,
	 * 这样就会导致当前AP的CR3中的目录表基地址就无效了,所以要将CR3重置为0x00,这样随后的指令依旧可以继续运行在内核态.
	 * */
	reset_dir_base();
     59f:	e8 fc ff ff ff       	call   5a0 <reset_ap_context+0x18>
	 * 不同AP的TR寄存器加载相同的TSS会报General protection错误的.
	 * 例如AP1重置了GDT表NR=0x80 TSS描述符项,然后LTR加载了该TSS, 随后的AP2和AP3也执行AP1相同的操作,那么AP2和AP3是不会报GP错误的,
	 * 但是,AP2和AP2如果仅执行LTR指令加载NR=0x80的TSS描述符项就会报GP错误,这一点Intel手册上没有相关的描述:不同的TR加载相同的TSS.
	 * 这里为了解决这个问题就为每个AP分配一个私有TSS描述符项,NR=0x81,0x82,0x83,这样就不会有问题了,而且NR>64也不会参与schedule调度.
	 * */
	reload_ap_ltr();
     5a4:	e8 fc ff ff ff       	call   5a5 <reset_ap_context+0x1d>
	 * 从而成为真正的zombie进程了哈哈,这样就造成严重的内存泄露问题.
	 * 所以reset_ap_default_task一定要放在tell_father之后调用.
	 *  */
	//reset_ap_default_task();
	/* 重新设置AP的内核栈指针，然后跳转到ap_default_loop执行空循环，等待新的IPI/timer中断 */
	alloc_ap_kernel_stack(apic_index,task_exit_clear,father_id);
     5a9:	83 ec 04             	sub    $0x4,%esp
     5ac:	56                   	push   %esi
     5ad:	68 00 00 00 00       	push   $0x0
     5b2:	53                   	push   %ebx
     5b3:	e8 fc ff ff ff       	call   5b4 <reset_ap_context+0x2c>
}
     5b8:	83 c4 14             	add    $0x14,%esp
     5bb:	5b                   	pop    %ebx
     5bc:	5e                   	pop    %esi
     5bd:	c3                   	ret    

000005be <math_state_restore>:
 *  'math_state_restore()' saves the current math information in the
 * old math state array, and gets the new ones from the current task
 */
void math_state_restore()
{
	struct task_struct* current = get_current_task();
     5be:	e8 fc ff ff ff       	call   5bf <math_state_restore+0x1>
	if (last_task_used_math == current)
     5c3:	8b 15 00 00 00 00    	mov    0x0,%edx
     5c9:	39 d0                	cmp    %edx,%eax
     5cb:	74 2c                	je     5f9 <math_state_restore+0x3b>
		return;
	__asm__("fwait");
     5cd:	9b                   	fwait
	if (last_task_used_math) {
     5ce:	85 d2                	test   %edx,%edx
     5d0:	74 06                	je     5d8 <math_state_restore+0x1a>
		__asm__("fnsave %0"::"m" (last_task_used_math->tss.i387));
     5d2:	dd b2 50 03 00 00    	fnsave 0x350(%edx)
	}
	last_task_used_math=current;
     5d8:	a3 00 00 00 00       	mov    %eax,0x0
	if (current->used_math) {
     5dd:	66 83 b8 64 02 00 00 	cmpw   $0x0,0x264(%eax)
     5e4:	00 
     5e5:	74 07                	je     5ee <math_state_restore+0x30>
		__asm__("frstor %0"::"m" (current->tss.i387));
     5e7:	dd a0 50 03 00 00    	frstor 0x350(%eax)
     5ed:	c3                   	ret    
	} else {
		__asm__("fninit"::);
     5ee:	db e3                	fninit 
		current->used_math=1;
     5f0:	66 c7 80 64 02 00 00 	movw   $0x1,0x264(%eax)
     5f7:	01 00 
     5f9:	f3 c3                	repz ret 

000005fb <reset_exit_reason_info>:
	}
}

void reset_exit_reason_info(ulong next, struct task_struct ** current) {
     5fb:	83 ec 10             	sub    $0x10,%esp
     5fe:	8b 44 24 14          	mov    0x14(%esp),%eax
     602:	8b 54 24 18          	mov    0x18(%esp),%edx
	exit_reason_task_switch_struct* exit_reason_task_switch = (exit_reason_task_switch_struct*) VM_EXIT_REASON_TASK_SWITCH_INFO_ADDR;
	exit_reason_task_switch->new_task_nr  = task[next]->task_nr;
     606:	8b 0c 85 00 00 00 00 	mov    0x0(,%eax,4),%ecx
     60d:	8b 89 c0 03 00 00    	mov    0x3c0(%ecx),%ecx
     613:	89 0d 04 e0 09 00    	mov    %ecx,0x9e004
	exit_reason_task_switch->new_task_cr3 = task[next]->tss.cr3;
     619:	8b 0c 85 00 00 00 00 	mov    0x0(,%eax,4),%ecx
     620:	8b 89 04 03 00 00    	mov    0x304(%ecx),%ecx
     626:	89 0d 08 e0 09 00    	mov    %ecx,0x9e008
	exit_reason_task_switch->new_task_executed = task[next]->executed;
     62c:	8b 0c 85 00 00 00 00 	mov    0x0(,%eax,4),%ecx
     633:	8b 89 c8 03 00 00    	mov    0x3c8(%ecx),%ecx
     639:	89 0d 0c e0 09 00    	mov    %ecx,0x9e00c
	exit_reason_task_switch->old_task_nr  = (*current)->task_nr;
     63f:	8b 0a                	mov    (%edx),%ecx
     641:	8b 89 c0 03 00 00    	mov    0x3c0(%ecx),%ecx
     647:	89 0d 10 e0 09 00    	mov    %ecx,0x9e010
	exit_reason_task_switch->old_task_cr3 = (*current)->tss.cr3;
     64d:	8b 0a                	mov    (%edx),%ecx
     64f:	8b 89 04 03 00 00    	mov    0x304(%ecx),%ecx
     655:	89 0d 14 e0 09 00    	mov    %ecx,0x9e014
	printk("new_cr3:old_cr3(%08x:%08x)\n\r", task[next]->tss.cr3, (*current)->tss.cr3);
     65b:	8b 12                	mov    (%edx),%edx
     65d:	ff b2 04 03 00 00    	pushl  0x304(%edx)
     663:	8b 04 85 00 00 00 00 	mov    0x0(,%eax,4),%eax
     66a:	ff b0 04 03 00 00    	pushl  0x304(%eax)
     670:	68 17 00 00 00       	push   $0x17
     675:	e8 fc ff ff ff       	call   676 <reset_exit_reason_info+0x7b>
	exit_reason_task_switch->task_switch_entry = (ulong)task_switch;
     67a:	c7 05 00 e0 09 00 00 	movl   $0x0,0x9e000
     681:	00 00 00 
}
     684:	83 c4 1c             	add    $0x1c,%esp
     687:	c3                   	ret    

00000688 <schedule>:
 *   NOTE!!  Task 0 is the 'idle' task, which gets called when no other
 * tasks can run. It can not be killed, and it cannot sleep. The 'state'
 * information in task[0] is never used.
 */
void schedule(void)
{
     688:	55                   	push   %ebp
     689:	57                   	push   %edi
     68a:	56                   	push   %esi
     68b:	53                   	push   %ebx
     68c:	83 ec 1c             	sub    $0x1c,%esp
	unsigned long current_apic_id = get_current_apic_id();
     68f:	e8 fc ff ff ff       	call   690 <schedule+0x8>
     694:	89 c3                	mov    %eax,%ebx
	if (current_apic_id == 1) {
		//printk("ap1 come to schedule\n\r");
	}
	struct apic_info* apic_info = get_apic_info(current_apic_id);
     696:	50                   	push   %eax
     697:	e8 fc ff ff ff       	call   698 <schedule+0x10>
     69c:	89 c6                	mov    %eax,%esi
	struct task_struct ** current = &(apic_info->current);
	int i,next,c;
	struct task_struct ** p;
    /* check alarm, wake up any interruptible tasks that have got a signal */

	lock_op(&sched_semaphore);  /* 这里一定要加锁，否则会出现多个AP同时执行同一个task */
     69e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
     6a5:	e8 fc ff ff ff       	call   6a6 <schedule+0x1e>
     6aa:	83 c4 04             	add    $0x4,%esp
	 * 因为这里锁的释放有好几处,程序最后还会释放一次,这个临时变量就是保证每个进程对自己加的锁只释放一次,
	 * 如果不加这个临时变量判断一下,程序有可能会释放其他进程加的锁.
	 * */
	int lock_flag = 1;

	for(p = &LAST_TASK ; p > &FIRST_TASK ; --p)
     6ad:	ba fc 00 00 00       	mov    $0xfc,%edx
		if (*p) {
     6b2:	8b 02                	mov    (%edx),%eax
     6b4:	85 c0                	test   %eax,%eax
     6b6:	74 46                	je     6fe <schedule+0x76>
			if ((*p)->alarm && (*p)->alarm < jiffies) {
     6b8:	8b 88 4c 02 00 00    	mov    0x24c(%eax),%ecx
     6be:	85 c9                	test   %ecx,%ecx
     6c0:	74 1d                	je     6df <schedule+0x57>
     6c2:	8b 3d 00 00 00 00    	mov    0x0,%edi
     6c8:	39 f9                	cmp    %edi,%ecx
     6ca:	7d 13                	jge    6df <schedule+0x57>
					(*p)->signal |= (1<<(SIGALRM-1));
     6cc:	81 48 0c 00 20 00 00 	orl    $0x2000,0xc(%eax)
					(*p)->alarm = 0;
     6d3:	8b 02                	mov    (%edx),%eax
     6d5:	c7 80 4c 02 00 00 00 	movl   $0x0,0x24c(%eax)
     6dc:	00 00 00 
			}
			if (((*p)->signal & ~(_BLOCKABLE & (*p)->blocked)) &&
     6df:	8b 0a                	mov    (%edx),%ecx
     6e1:	8b 81 10 02 00 00    	mov    0x210(%ecx),%eax
     6e7:	25 ff fe fb ff       	and    $0xfffbfeff,%eax
     6ec:	f7 d0                	not    %eax
     6ee:	85 41 0c             	test   %eax,0xc(%ecx)
     6f1:	74 0b                	je     6fe <schedule+0x76>
     6f3:	83 39 01             	cmpl   $0x1,(%ecx)
     6f6:	75 06                	jne    6fe <schedule+0x76>
			(*p)->state==TASK_INTERRUPTIBLE)
				(*p)->state=TASK_RUNNING;
     6f8:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	 * 因为这里锁的释放有好几处,程序最后还会释放一次,这个临时变量就是保证每个进程对自己加的锁只释放一次,
	 * 如果不加这个临时变量判断一下,程序有可能会释放其他进程加的锁.
	 * */
	int lock_flag = 1;

	for(p = &LAST_TASK ; p > &FIRST_TASK ; --p)
     6fe:	83 ea 04             	sub    $0x4,%edx
     701:	81 fa 00 00 00 00    	cmp    $0x0,%edx
     707:	75 a9                	jne    6b2 <schedule+0x2a>
	while (1) {
		c = -1;
		next = 0;
		i = NR_TASKS;
		p = &task[NR_TASKS];
		while (--i) {
     709:	b8 3f 00 00 00       	mov    $0x3f,%eax
		}

/* this is the scheduler proper: */

	while (1) {
		c = -1;
     70e:	bd ff ff ff ff       	mov    $0xffffffff,%ebp
		next = 0;
     713:	bf 00 00 00 00       	mov    $0x0,%edi
		i = NR_TASKS;
		p = &task[NR_TASKS];
		while (--i) {
			if (!*--p)
     718:	8b 14 85 00 00 00 00 	mov    0x0(,%eax,4),%edx
     71f:	85 d2                	test   %edx,%edx
     721:	74 19                	je     73c <schedule+0xb4>
				continue;
			if ((*p)->state == TASK_RUNNING && (*p)->counter > c && (*p)->sched_on_ap == 0) {
     723:	83 3a 00             	cmpl   $0x0,(%edx)
     726:	75 14                	jne    73c <schedule+0xb4>
     728:	8b 4a 04             	mov    0x4(%edx),%ecx
     72b:	39 e9                	cmp    %ebp,%ecx
     72d:	7e 0d                	jle    73c <schedule+0xb4>
				c = (*p)->counter, next = i;
     72f:	83 ba bc 03 00 00 00 	cmpl   $0x0,0x3bc(%edx)
     736:	0f 44 e9             	cmove  %ecx,%ebp
     739:	0f 44 f8             	cmove  %eax,%edi
	while (1) {
		c = -1;
		next = 0;
		i = NR_TASKS;
		p = &task[NR_TASKS];
		while (--i) {
     73c:	83 e8 01             	sub    $0x1,%eax
     73f:	75 d7                	jne    718 <schedule+0x90>
				continue;
			if ((*p)->state == TASK_RUNNING && (*p)->counter > c && (*p)->sched_on_ap == 0) {
				c = (*p)->counter, next = i;
			}
		}
		if (c) break;
     741:	85 ed                	test   %ebp,%ebp
     743:	75 23                	jne    768 <schedule+0xe0>
     745:	b9 fc 00 00 00       	mov    $0xfc,%ecx
		for(p = &LAST_TASK ; p > &FIRST_TASK ; --p) {
			if (*p) {
     74a:	8b 11                	mov    (%ecx),%edx
     74c:	85 d2                	test   %edx,%edx
     74e:	74 0b                	je     75b <schedule+0xd3>
				/* 此时如果release其他AP执行介于这之间的话,是会有问题的.具体看release描述. */
				(*p)->counter = ((*p)->counter >> 1) + (*p)->priority;
     750:	8b 42 04             	mov    0x4(%edx),%eax
     753:	d1 f8                	sar    %eax
     755:	03 42 08             	add    0x8(%edx),%eax
     758:	89 42 04             	mov    %eax,0x4(%edx)
			if ((*p)->state == TASK_RUNNING && (*p)->counter > c && (*p)->sched_on_ap == 0) {
				c = (*p)->counter, next = i;
			}
		}
		if (c) break;
		for(p = &LAST_TASK ; p > &FIRST_TASK ; --p) {
     75b:	83 e9 04             	sub    $0x4,%ecx
     75e:	81 f9 00 00 00 00    	cmp    $0x0,%ecx
     764:	75 e4                	jne    74a <schedule+0xc2>
     766:	eb a1                	jmp    709 <schedule+0x81>
				(*p)->counter = ((*p)->counter >> 1) + (*p)->priority;
			}
		}
	}

	if (current_apic_id == apic_ids[0].apic_id) {  /* 调度任务发生在BSP上 */
     768:	3b 1d 04 00 00 00    	cmp    0x4,%ebx
     76e:	75 30                	jne    7a0 <schedule+0x118>
			}
			++apic_ids[sched_apic_id].load_per_apic;
			next = 1;   /* BSP上只运行task0和task1 */
		}
#else
		if (task[next] != task[0] && task[next] != task[1]) {
     770:	8b 14 bd 00 00 00 00 	mov    0x0(,%edi,4),%edx
     777:	3b 15 00 00 00 00    	cmp    0x0,%edx
     77d:	0f 84 ee 00 00 00    	je     871 <schedule+0x1e9>
     783:	a1 04 00 00 00       	mov    0x4,%eax
     788:	39 c2                	cmp    %eax,%edx
     78a:	0f 84 e1 00 00 00    	je     871 <schedule+0x1e9>
     790:	83 38 00             	cmpl   $0x0,(%eax)
     793:	0f 94 c0             	sete   %al
     796:	0f b6 c0             	movzbl %al,%eax
     799:	89 c7                	mov    %eax,%edi
     79b:	e9 d1 00 00 00       	jmp    871 <schedule+0x1e9>
			    (*current)->sched_on_ap = 0;  /* 只有这样，BSP之后才能继续调用该current到其他AP上运行，否则，该进程将永远不会被重新sched. */
			}
			task[next]->sched_on_ap = 1;
		}
#else
		if (task[next] == task[0] || task[next] == task[1]) {
     7a0:	8b 04 bd 00 00 00 00 	mov    0x0(,%edi,4),%eax
     7a7:	3b 05 00 00 00 00    	cmp    0x0,%eax
     7ad:	74 08                	je     7b7 <schedule+0x12f>
     7af:	3b 05 04 00 00 00    	cmp    0x4,%eax
     7b5:	75 29                	jne    7e0 <schedule+0x158>
			if (lock_flag) {
				unlock_op(&sched_semaphore);
     7b7:	68 00 00 00 00       	push   $0x0
     7bc:	e8 fc ff ff ff       	call   7bd <schedule+0x135>
				lock_flag = 0;
			}
			if (*current != 0) {
     7c1:	83 c4 04             	add    $0x4,%esp
     7c4:	83 7e 14 00          	cmpl   $0x0,0x14(%esi)
     7c8:	0f 85 b5 00 00 00    	jne    883 <schedule+0x1fb>
				return;          /* 如果AP有已经执行过的task(包括idle_loop,也就是ap_default_task任务),这时不调度，继续执行老的task. */
			}
			else {/* 执行到这个分支,说明内核是有问题的,current是不可能为0的 */
				panic("Errors occur on AP schedule\n\r");
     7ce:	83 ec 0c             	sub    $0xc,%esp
     7d1:	68 34 00 00 00       	push   $0x34
     7d6:	e8 fc ff ff ff       	call   7d7 <schedule+0x14f>
     7db:	83 c4 10             	add    $0x10,%esp
     7de:	eb 49                	jmp    829 <schedule+0x1a1>
			}
		}
		else {  /* 这时AP要调度新的task[n>1] */
			unsigned long sched_apic_id = get_min_load_ap();
     7e0:	e8 fc ff ff ff       	call   7e1 <schedule+0x159>
			if (sched_apic_id == current_apic_id) {
     7e5:	39 c3                	cmp    %eax,%ebx
     7e7:	75 2e                	jne    817 <schedule+0x18f>
				if (*current) {
     7e9:	8b 46 14             	mov    0x14(%esi),%eax
     7ec:	85 c0                	test   %eax,%eax
     7ee:	74 0a                	je     7fa <schedule+0x172>
					/* 只有这样，BSP之后才能继续调用该current到其他AP上运行，否则，该进程将永远不会被重新sched.(但ap_default_task是永远不会被调度的) */
				    (*current)->sched_on_ap = 0;
     7f0:	c7 80 bc 03 00 00 00 	movl   $0x0,0x3bc(%eax)
     7f7:	00 00 00 
				}
				task[next]->sched_on_ap = 1;      /* 设置任务占用符,这样释放锁以后,该任务是不会被其他AP调度执行的 */
     7fa:	8b 04 bd 00 00 00 00 	mov    0x0(,%edi,4),%eax
     801:	c7 80 bc 03 00 00 01 	movl   $0x1,0x3bc(%eax)
     808:	00 00 00 
				++apic_ids[sched_apic_id].load_per_apic;
     80b:	6b db 1c             	imul   $0x1c,%ebx,%ebx
     80e:	83 83 10 00 00 00 01 	addl   $0x1,0x10(%ebx)
     815:	eb 5a                	jmp    871 <schedule+0x1e9>
			}
			else {
				if (lock_flag) {
					unlock_op(&sched_semaphore);
     817:	83 ec 0c             	sub    $0xc,%esp
     81a:	68 00 00 00 00       	push   $0x0
     81f:	e8 fc ff ff ff       	call   820 <schedule+0x198>
     824:	83 c4 10             	add    $0x10,%esp
     827:	eb 5a                	jmp    883 <schedule+0x1fb>
	unsigned long current_apic_id = get_current_apic_id();
	if (current_apic_id == 1) {
		//printk("ap1 come to schedule\n\r");
	}
	struct apic_info* apic_info = get_apic_info(current_apic_id);
	struct task_struct ** current = &(apic_info->current);
     829:	8d 46 14             	lea    0x14(%esi),%eax

	/*
	 * 在进行进程切换之前要先保存新老任务的task_nr和task_switch_entry,
	 * 这样方便VMresume到GuestOS后,在task_switch中进行真正的任务切换.
	 */
	if (task[next] != *current) {
     82c:	8b 5e 14             	mov    0x14(%esi),%ebx
     82f:	39 1c bd 00 00 00 00 	cmp    %ebx,0x0(,%edi,4)
     836:	74 0d                	je     845 <schedule+0x1bd>
		reset_exit_reason_info(next, current);
     838:	83 ec 08             	sub    $0x8,%esp
     83b:	50                   	push   %eax
     83c:	57                   	push   %edi
     83d:	e8 fc ff ff ff       	call   83e <schedule+0x1b6>
     842:	83 c4 10             	add    $0x10,%esp
	}

	switch_to(next,current);
     845:	89 fa                	mov    %edi,%edx
     847:	c1 e2 04             	shl    $0x4,%edx
     84a:	83 c2 20             	add    $0x20,%edx
     84d:	8b 0c bd 00 00 00 00 	mov    0x0(,%edi,4),%ecx
     854:	39 4e 14             	cmp    %ecx,0x14(%esi)
     857:	74 16                	je     86f <schedule+0x1e7>
     859:	66 89 54 24 0c       	mov    %dx,0xc(%esp)
     85e:	87 4e 14             	xchg   %ecx,0x14(%esi)
     861:	ff 6c 24 08          	ljmp   *0x8(%esp)
     865:	39 0d 00 00 00 00    	cmp    %ecx,0x0
     86b:	75 02                	jne    86f <schedule+0x1e7>
     86d:	0f 06                	clts   
     86f:	eb 12                	jmp    883 <schedule+0x1fb>
			}
		}
#endif
	}
	if (lock_flag) {
		unlock_op(&sched_semaphore);
     871:	83 ec 0c             	sub    $0xc,%esp
     874:	68 00 00 00 00       	push   $0x0
     879:	e8 fc ff ff ff       	call   87a <schedule+0x1f2>
     87e:	83 c4 10             	add    $0x10,%esp
     881:	eb a6                	jmp    829 <schedule+0x1a1>
	if (task[next] != *current) {
		reset_exit_reason_info(next, current);
	}

	switch_to(next,current);
}
     883:	83 c4 1c             	add    $0x1c,%esp
     886:	5b                   	pop    %ebx
     887:	5e                   	pop    %esi
     888:	5f                   	pop    %edi
     889:	5d                   	pop    %ebp
     88a:	c3                   	ret    

0000088b <sys_pause>:

int sys_pause(void)
{
     88b:	83 ec 0c             	sub    $0xc,%esp
	struct task_struct* current = get_current_task();
     88e:	e8 fc ff ff ff       	call   88f <sys_pause+0x4>
	current->state = TASK_INTERRUPTIBLE;
     893:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
	schedule();
     899:	e8 fc ff ff ff       	call   89a <sys_pause+0xf>
	return 0;
}
     89e:	b8 00 00 00 00       	mov    $0x0,%eax
     8a3:	83 c4 0c             	add    $0xc,%esp
     8a6:	c3                   	ret    

000008a7 <sleep_on>:
 * 每个进程调用该方法时,通过分配在栈上的tmp局部变量来串联所有等待任务的,这个链表本身也是个栈,先进后出,
 * 所以最后调用sleep_on方法的进程,会将自己的任务指针保存在inode.i_wait,当施加lock inode操作的进程释放lock,并调用wake_up方法后
 * 会唤醒inode.i_wait任务,该任务会唤醒它保存的上一个等待任务,以此类推,直到最后一个等待任务.
 * */
void sleep_on(struct task_struct **p)
{
     8a7:	57                   	push   %edi
     8a8:	56                   	push   %esi
     8a9:	53                   	push   %ebx
     8aa:	8b 5c 24 10          	mov    0x10(%esp),%ebx
	lock_op(&sleep_on_semaphore);
     8ae:	68 00 00 00 00       	push   $0x0
     8b3:	e8 fc ff ff ff       	call   8b4 <sleep_on+0xd>

	struct task_struct* current = get_current_task();
     8b8:	e8 fc ff ff ff       	call   8b9 <sleep_on+0x12>
	struct task_struct *tmp;

	if (!p) {
     8bd:	83 c4 04             	add    $0x4,%esp
     8c0:	85 db                	test   %ebx,%ebx
     8c2:	75 0f                	jne    8d3 <sleep_on+0x2c>
		unlock_op(&sleep_on_semaphore);
     8c4:	68 00 00 00 00       	push   $0x0
     8c9:	e8 fc ff ff ff       	call   8ca <sleep_on+0x23>
		return;
     8ce:	83 c4 04             	add    $0x4,%esp
     8d1:	eb 42                	jmp    915 <sleep_on+0x6e>
     8d3:	89 c6                	mov    %eax,%esi
	}
	if (current == &(init_task.task))
     8d5:	3d 00 00 00 00       	cmp    $0x0,%eax
     8da:	75 10                	jne    8ec <sleep_on+0x45>
		panic("task[0] trying to sleep");
     8dc:	83 ec 0c             	sub    $0xc,%esp
     8df:	68 52 00 00 00       	push   $0x52
     8e4:	e8 fc ff ff ff       	call   8e5 <sleep_on+0x3e>
     8e9:	83 c4 10             	add    $0x10,%esp
	tmp = *p;        /* 将目前inode.i_wait指向的等待任务的指针保存到tmp */
     8ec:	8b 3b                	mov    (%ebx),%edi
	*p = current;    /* 将当前任务的指针，保存到inode.i_wait */
     8ee:	89 33                	mov    %esi,(%ebx)
	current->state = TASK_UNINTERRUPTIBLE;  /* 将当前任务设置为不可中断的睡眠状态(必须通过wake_up唤醒，不能通过signal方式唤醒) */
     8f0:	c7 06 02 00 00 00    	movl   $0x2,(%esi)

	unlock_op(&sleep_on_semaphore);         /* 一定要在调度操作之前把锁释放了 */
     8f6:	83 ec 0c             	sub    $0xc,%esp
     8f9:	68 00 00 00 00       	push   $0x0
     8fe:	e8 fc ff ff ff       	call   8ff <sleep_on+0x58>

	schedule();      /* 这里肯定调度其他任务执行了，不可能再是本任务了 */
     903:	e8 fc ff ff ff       	call   904 <sleep_on+0x5d>
	/*
	 * 这里最有意思了，每个等待任务用自己的局部变量tmp来保存前一个等待任务的指针，这样就形成了一个等待任务列表了。
	 * 当该任务被其他任务通过wake_up唤醒后，会紧接着执行下面的代码，把它自己维护的上一个等待任务的状态设置为running状态，
	 * 这样这个任务就被唤醒了，就有可能被下次schedule方法调度运行了，tricky吧，这里有必要解释一下。
	 * */
	if (tmp)
     908:	83 c4 10             	add    $0x10,%esp
     90b:	85 ff                	test   %edi,%edi
     90d:	74 06                	je     915 <sleep_on+0x6e>
		tmp->state=0;
     90f:	c7 07 00 00 00 00    	movl   $0x0,(%edi)
}
     915:	5b                   	pop    %ebx
     916:	5e                   	pop    %esi
     917:	5f                   	pop    %edi
     918:	c3                   	ret    

00000919 <interruptible_sleep_on>:

void interruptible_sleep_on(struct task_struct **p)
{
     919:	57                   	push   %edi
     91a:	56                   	push   %esi
     91b:	53                   	push   %ebx
     91c:	8b 74 24 10          	mov    0x10(%esp),%esi
	lock_op(&interruptible_sleep_on_semaphore);
     920:	68 00 00 00 00       	push   $0x0
     925:	e8 fc ff ff ff       	call   926 <interruptible_sleep_on+0xd>
	struct task_struct* current = get_current_task();
     92a:	e8 fc ff ff ff       	call   92b <interruptible_sleep_on+0x12>
	struct task_struct *tmp;

	if (!p) {
     92f:	83 c4 04             	add    $0x4,%esp
     932:	85 f6                	test   %esi,%esi
     934:	75 0f                	jne    945 <interruptible_sleep_on+0x2c>
		unlock_op(&interruptible_sleep_on_semaphore);
     936:	68 00 00 00 00       	push   $0x0
     93b:	e8 fc ff ff ff       	call   93c <interruptible_sleep_on+0x23>
		return;
     940:	83 c4 04             	add    $0x4,%esp
     943:	eb 56                	jmp    99b <interruptible_sleep_on+0x82>
     945:	89 c3                	mov    %eax,%ebx
	}
	if (current == &(init_task.task))
     947:	3d 00 00 00 00       	cmp    $0x0,%eax
     94c:	75 10                	jne    95e <interruptible_sleep_on+0x45>
		panic("task[0] trying to sleep");
     94e:	83 ec 0c             	sub    $0xc,%esp
     951:	68 52 00 00 00       	push   $0x52
     956:	e8 fc ff ff ff       	call   957 <interruptible_sleep_on+0x3e>
     95b:	83 c4 10             	add    $0x10,%esp
	tmp=*p;
     95e:	8b 3e                	mov    (%esi),%edi
	*p=current;
     960:	89 1e                	mov    %ebx,(%esi)
    repeat:
    current->state = TASK_INTERRUPTIBLE;
     962:	c7 03 01 00 00 00    	movl   $0x1,(%ebx)
    unlock_op(&interruptible_sleep_on_semaphore);
     968:	83 ec 0c             	sub    $0xc,%esp
     96b:	68 00 00 00 00       	push   $0x0
     970:	e8 fc ff ff ff       	call   971 <interruptible_sleep_on+0x58>
	schedule();
     975:	e8 fc ff ff ff       	call   976 <interruptible_sleep_on+0x5d>
	if (*p && *p != current) {
     97a:	8b 06                	mov    (%esi),%eax
     97c:	83 c4 10             	add    $0x10,%esp
     97f:	39 c3                	cmp    %eax,%ebx
     981:	74 0c                	je     98f <interruptible_sleep_on+0x76>
     983:	85 c0                	test   %eax,%eax
     985:	74 08                	je     98f <interruptible_sleep_on+0x76>
		(**p).state=0;
     987:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		goto repeat;
     98d:	eb d3                	jmp    962 <interruptible_sleep_on+0x49>
	}
	//*p=NULL;
	*p=tmp;
     98f:	89 3e                	mov    %edi,(%esi)
	if (tmp)
     991:	85 ff                	test   %edi,%edi
     993:	74 06                	je     99b <interruptible_sleep_on+0x82>
		tmp->state=0;
     995:	c7 07 00 00 00 00    	movl   $0x0,(%edi)
}
     99b:	5b                   	pop    %ebx
     99c:	5e                   	pop    %esi
     99d:	5f                   	pop    %edi
     99e:	c3                   	ret    

0000099f <wake_up>:

void wake_up(struct task_struct **p)
{
     99f:	8b 44 24 04          	mov    0x4(%esp),%eax
	if (p && *p) {
     9a3:	85 c0                	test   %eax,%eax
     9a5:	74 0c                	je     9b3 <wake_up+0x14>
     9a7:	8b 00                	mov    (%eax),%eax
     9a9:	85 c0                	test   %eax,%eax
     9ab:	74 06                	je     9b3 <wake_up+0x14>
		(**p).state=0; /* 将等待任务的状态设置为running状态，这样就可以被schedule方法调度了. */
     9ad:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
     9b3:	f3 c3                	repz ret 

000009b5 <ticks_to_floppy_on>:
static int  mon_timer[4]={0,0,0,0};
static int moff_timer[4]={0,0,0,0};
unsigned char current_DOR = 0x0C;

int ticks_to_floppy_on(unsigned int nr)
{
     9b5:	56                   	push   %esi
     9b6:	53                   	push   %ebx
     9b7:	83 ec 04             	sub    $0x4,%esp
     9ba:	8b 74 24 10          	mov    0x10(%esp),%esi
	extern unsigned char selected;
	unsigned char mask = 0x10 << nr;
     9be:	b8 10 00 00 00       	mov    $0x10,%eax
     9c3:	89 f1                	mov    %esi,%ecx
     9c5:	d3 e0                	shl    %cl,%eax
     9c7:	89 c3                	mov    %eax,%ebx

	if (nr>3)
     9c9:	83 fe 03             	cmp    $0x3,%esi
     9cc:	76 10                	jbe    9de <ticks_to_floppy_on+0x29>
		panic("floppy_on: nr>3");
     9ce:	83 ec 0c             	sub    $0xc,%esp
     9d1:	68 6a 00 00 00       	push   $0x6a
     9d6:	e8 fc ff ff ff       	call   9d7 <ticks_to_floppy_on+0x22>
     9db:	83 c4 10             	add    $0x10,%esp
	moff_timer[nr]=10000;		/* 100 s = very big :-) */
     9de:	c7 04 b5 20 03 00 00 	movl   $0x2710,0x320(,%esi,4)
     9e5:	10 27 00 00 
	cli();				/* use floppy_off to turn it off */
     9e9:	fa                   	cli    
	mask |= current_DOR;
     9ea:	0f b6 0d 00 00 00 00 	movzbl 0x0,%ecx
     9f1:	89 d8                	mov    %ebx,%eax
     9f3:	09 c8                	or     %ecx,%eax
	if (!selected) {
     9f5:	80 3d 00 00 00 00 00 	cmpb   $0x0,0x0
     9fc:	75 05                	jne    a03 <ticks_to_floppy_on+0x4e>
		mask &= 0xFC;
     9fe:	83 e0 fc             	and    $0xfffffffc,%eax
		mask |= nr;
     a01:	09 f0                	or     %esi,%eax
	}
	if (mask != current_DOR) {
     a03:	38 c8                	cmp    %cl,%al
     a05:	74 34                	je     a3b <ticks_to_floppy_on+0x86>
		outb(mask,FD_DOR);
     a07:	ba f2 03 00 00       	mov    $0x3f2,%edx
     a0c:	ee                   	out    %al,(%dx)
		if ((mask ^ current_DOR) & 0xf0)
     a0d:	31 c1                	xor    %eax,%ecx
     a0f:	f6 c1 f0             	test   $0xf0,%cl
     a12:	74 0d                	je     a21 <ticks_to_floppy_on+0x6c>
			mon_timer[nr] = HZ/2;
     a14:	c7 04 b5 30 03 00 00 	movl   $0x5,0x330(,%esi,4)
     a1b:	05 00 00 00 
     a1f:	eb 15                	jmp    a36 <ticks_to_floppy_on+0x81>
		else if (mon_timer[nr] < 2)
     a21:	83 3c b5 30 03 00 00 	cmpl   $0x1,0x330(,%esi,4)
     a28:	01 
     a29:	7f 0b                	jg     a36 <ticks_to_floppy_on+0x81>
			mon_timer[nr] = 2;
     a2b:	c7 04 b5 30 03 00 00 	movl   $0x2,0x330(,%esi,4)
     a32:	02 00 00 00 
		current_DOR = mask;
     a36:	a2 00 00 00 00       	mov    %al,0x0
	}
	sti();
     a3b:	fb                   	sti    
	return mon_timer[nr];
     a3c:	8b 04 b5 30 03 00 00 	mov    0x330(,%esi,4),%eax
}
     a43:	83 c4 04             	add    $0x4,%esp
     a46:	5b                   	pop    %ebx
     a47:	5e                   	pop    %esi
     a48:	c3                   	ret    

00000a49 <floppy_on>:

void floppy_on(unsigned int nr)
{
     a49:	56                   	push   %esi
     a4a:	53                   	push   %ebx
     a4b:	83 ec 04             	sub    $0x4,%esp
     a4e:	8b 5c 24 10          	mov    0x10(%esp),%ebx
	cli();
     a52:	fa                   	cli    
	while (ticks_to_floppy_on(nr))
		sleep_on(nr+wait_motor);
     a53:	8d 34 9d 40 03 00 00 	lea    0x340(,%ebx,4),%esi
}

void floppy_on(unsigned int nr)
{
	cli();
	while (ticks_to_floppy_on(nr))
     a5a:	eb 0c                	jmp    a68 <floppy_on+0x1f>
		sleep_on(nr+wait_motor);
     a5c:	83 ec 0c             	sub    $0xc,%esp
     a5f:	56                   	push   %esi
     a60:	e8 fc ff ff ff       	call   a61 <floppy_on+0x18>
     a65:	83 c4 10             	add    $0x10,%esp
}

void floppy_on(unsigned int nr)
{
	cli();
	while (ticks_to_floppy_on(nr))
     a68:	83 ec 0c             	sub    $0xc,%esp
     a6b:	53                   	push   %ebx
     a6c:	e8 fc ff ff ff       	call   a6d <floppy_on+0x24>
     a71:	83 c4 10             	add    $0x10,%esp
     a74:	85 c0                	test   %eax,%eax
     a76:	75 e4                	jne    a5c <floppy_on+0x13>
		sleep_on(nr+wait_motor);
	sti();
     a78:	fb                   	sti    
}
     a79:	83 c4 04             	add    $0x4,%esp
     a7c:	5b                   	pop    %ebx
     a7d:	5e                   	pop    %esi
     a7e:	c3                   	ret    

00000a7f <floppy_off>:

void floppy_off(unsigned int nr)
{
	moff_timer[nr]=3*HZ;
     a7f:	8b 44 24 04          	mov    0x4(%esp),%eax
     a83:	c7 04 85 20 03 00 00 	movl   $0x1e,0x320(,%eax,4)
     a8a:	1e 00 00 00 
     a8e:	c3                   	ret    

00000a8f <do_floppy_timer>:
}

void do_floppy_timer(void)
{
     a8f:	57                   	push   %edi
     a90:	56                   	push   %esi
     a91:	53                   	push   %ebx
     a92:	bb 00 00 00 00       	mov    $0x0,%ebx
	int i;
	unsigned char mask = 0x10;
     a97:	be 10 00 00 00       	mov    $0x10,%esi
		if (mon_timer[i]) {
			if (!--mon_timer[i])
				wake_up(i+wait_motor);
		} else if (!moff_timer[i]) {
			current_DOR &= ~mask;
			outb(current_DOR,FD_DOR);
     a9c:	bf f2 03 00 00       	mov    $0x3f2,%edi
{
	int i;
	unsigned char mask = 0x10;

	for (i=0 ; i<4 ; i++,mask <<= 1) {
		if (!(mask & current_DOR))
     aa1:	0f b6 05 00 00 00 00 	movzbl 0x0,%eax
     aa8:	89 f1                	mov    %esi,%ecx
     aaa:	84 c8                	test   %cl,%al
     aac:	74 4b                	je     af9 <do_floppy_timer+0x6a>
			continue;
		if (mon_timer[i]) {
     aae:	8b 93 30 03 00 00    	mov    0x330(%ebx),%edx
     ab4:	85 d2                	test   %edx,%edx
     ab6:	74 1e                	je     ad6 <do_floppy_timer+0x47>
			if (!--mon_timer[i])
     ab8:	83 ea 01             	sub    $0x1,%edx
     abb:	89 93 30 03 00 00    	mov    %edx,0x330(%ebx)
     ac1:	85 d2                	test   %edx,%edx
     ac3:	75 34                	jne    af9 <do_floppy_timer+0x6a>
				wake_up(i+wait_motor);
     ac5:	8d 83 40 03 00 00    	lea    0x340(%ebx),%eax
     acb:	50                   	push   %eax
     acc:	e8 fc ff ff ff       	call   acd <do_floppy_timer+0x3e>
     ad1:	83 c4 04             	add    $0x4,%esp
     ad4:	eb 23                	jmp    af9 <do_floppy_timer+0x6a>
		} else if (!moff_timer[i]) {
     ad6:	8b 93 20 03 00 00    	mov    0x320(%ebx),%edx
     adc:	85 d2                	test   %edx,%edx
     ade:	75 10                	jne    af0 <do_floppy_timer+0x61>
			current_DOR &= ~mask;
     ae0:	89 f2                	mov    %esi,%edx
     ae2:	f7 d2                	not    %edx
     ae4:	21 d0                	and    %edx,%eax
     ae6:	a2 00 00 00 00       	mov    %al,0x0
			outb(current_DOR,FD_DOR);
     aeb:	89 fa                	mov    %edi,%edx
     aed:	ee                   	out    %al,(%dx)
     aee:	eb 09                	jmp    af9 <do_floppy_timer+0x6a>
		} else
			moff_timer[i]--;
     af0:	83 ea 01             	sub    $0x1,%edx
     af3:	89 93 20 03 00 00    	mov    %edx,0x320(%ebx)
void do_floppy_timer(void)
{
	int i;
	unsigned char mask = 0x10;

	for (i=0 ; i<4 ; i++,mask <<= 1) {
     af9:	01 f6                	add    %esi,%esi
     afb:	83 c3 04             	add    $0x4,%ebx
     afe:	83 fb 10             	cmp    $0x10,%ebx
     b01:	75 9e                	jne    aa1 <do_floppy_timer+0x12>
			current_DOR &= ~mask;
			outb(current_DOR,FD_DOR);
		} else
			moff_timer[i]--;
	}
}
     b03:	5b                   	pop    %ebx
     b04:	5e                   	pop    %esi
     b05:	5f                   	pop    %edi
     b06:	c3                   	ret    

00000b07 <add_timer>:
	void (*fn)();
	struct timer_list * next;
} timer_list[TIME_REQUESTS], * next_timer = NULL;

void add_timer(long jiffies, void (*fn)(void))
{
     b07:	57                   	push   %edi
     b08:	56                   	push   %esi
     b09:	53                   	push   %ebx
     b0a:	8b 74 24 10          	mov    0x10(%esp),%esi
     b0e:	8b 7c 24 14          	mov    0x14(%esp),%edi
	struct timer_list * p;

	if (!fn)
     b12:	85 ff                	test   %edi,%edi
     b14:	0f 84 99 00 00 00    	je     bb3 <add_timer+0xac>
		return;
	cli();
     b1a:	fa                   	cli    
	if (jiffies <= 0)
     b1b:	85 f6                	test   %esi,%esi
     b1d:	7e 14                	jle    b33 <add_timer+0x2c>
		(fn)();
	else {
		for (p = timer_list ; p < timer_list + TIME_REQUESTS ; p++) {
			if (!p->fn)
     b1f:	83 3d 24 00 00 00 00 	cmpl   $0x0,0x24
     b26:	0f 84 80 00 00 00    	je     bac <add_timer+0xa5>
     b2c:	bb 20 00 00 00       	mov    $0x20,%ebx
     b31:	eb 0a                	jmp    b3d <add_timer+0x36>

	if (!fn)
		return;
	cli();
	if (jiffies <= 0)
		(fn)();
     b33:	ff d7                	call   *%edi
     b35:	eb 60                	jmp    b97 <add_timer+0x90>
	else {
		for (p = timer_list ; p < timer_list + TIME_REQUESTS ; p++) {
			if (!p->fn)
     b37:	83 7b 04 00          	cmpl   $0x0,0x4(%ebx)
     b3b:	74 0d                	je     b4a <add_timer+0x43>
		return;
	cli();
	if (jiffies <= 0)
		(fn)();
	else {
		for (p = timer_list ; p < timer_list + TIME_REQUESTS ; p++) {
     b3d:	83 c3 0c             	add    $0xc,%ebx
     b40:	81 fb 20 03 00 00    	cmp    $0x320,%ebx
     b46:	75 ef                	jne    b37 <add_timer+0x30>
     b48:	eb 50                	jmp    b9a <add_timer+0x93>
			if (!p->fn)
				break;
		}
		if (p >= timer_list + TIME_REQUESTS)
			panic("No more time requests free");
		p->fn = fn;
     b4a:	89 7b 04             	mov    %edi,0x4(%ebx)
		p->jiffies = jiffies;
     b4d:	89 33                	mov    %esi,(%ebx)
		p->next = next_timer;
     b4f:	8b 15 18 00 00 00    	mov    0x18,%edx
     b55:	89 53 08             	mov    %edx,0x8(%ebx)
		next_timer = p;
     b58:	89 1d 18 00 00 00    	mov    %ebx,0x18
		while (p->next && p->next->jiffies < p->jiffies) {
     b5e:	85 d2                	test   %edx,%edx
     b60:	74 35                	je     b97 <add_timer+0x90>
     b62:	8b 0a                	mov    (%edx),%ecx
     b64:	39 ce                	cmp    %ecx,%esi
     b66:	7e 2f                	jle    b97 <add_timer+0x90>
     b68:	89 f0                	mov    %esi,%eax
			p->jiffies -= p->next->jiffies;
     b6a:	29 c8                	sub    %ecx,%eax
     b6c:	89 03                	mov    %eax,(%ebx)
			fn = p->fn;
     b6e:	8b 43 04             	mov    0x4(%ebx),%eax
			p->fn = p->next->fn;
     b71:	8b 4a 04             	mov    0x4(%edx),%ecx
     b74:	89 4b 04             	mov    %ecx,0x4(%ebx)
			p->next->fn = fn;
     b77:	89 42 04             	mov    %eax,0x4(%edx)
			jiffies = p->jiffies;
     b7a:	8b 13                	mov    (%ebx),%edx
			p->jiffies = p->next->jiffies;
     b7c:	8b 43 08             	mov    0x8(%ebx),%eax
     b7f:	8b 08                	mov    (%eax),%ecx
     b81:	89 0b                	mov    %ecx,(%ebx)
			p->next->jiffies = jiffies;
     b83:	89 10                	mov    %edx,(%eax)
			p = p->next;
     b85:	8b 5b 08             	mov    0x8(%ebx),%ebx
			panic("No more time requests free");
		p->fn = fn;
		p->jiffies = jiffies;
		p->next = next_timer;
		next_timer = p;
		while (p->next && p->next->jiffies < p->jiffies) {
     b88:	8b 53 08             	mov    0x8(%ebx),%edx
     b8b:	85 d2                	test   %edx,%edx
     b8d:	74 08                	je     b97 <add_timer+0x90>
     b8f:	8b 0a                	mov    (%edx),%ecx
     b91:	8b 03                	mov    (%ebx),%eax
     b93:	39 c1                	cmp    %eax,%ecx
     b95:	7c d3                	jl     b6a <add_timer+0x63>
			p->jiffies = p->next->jiffies;
			p->next->jiffies = jiffies;
			p = p->next;
		}
	}
	sti();
     b97:	fb                   	sti    
     b98:	eb 19                	jmp    bb3 <add_timer+0xac>
		for (p = timer_list ; p < timer_list + TIME_REQUESTS ; p++) {
			if (!p->fn)
				break;
		}
		if (p >= timer_list + TIME_REQUESTS)
			panic("No more time requests free");
     b9a:	83 ec 0c             	sub    $0xc,%esp
     b9d:	68 7a 00 00 00       	push   $0x7a
     ba2:	e8 fc ff ff ff       	call   ba3 <add_timer+0x9c>
     ba7:	83 c4 10             	add    $0x10,%esp
     baa:	eb 9e                	jmp    b4a <add_timer+0x43>
	cli();
	if (jiffies <= 0)
		(fn)();
	else {
		for (p = timer_list ; p < timer_list + TIME_REQUESTS ; p++) {
			if (!p->fn)
     bac:	bb 20 00 00 00       	mov    $0x20,%ebx
     bb1:	eb 97                	jmp    b4a <add_timer+0x43>
			p->next->jiffies = jiffies;
			p = p->next;
		}
	}
	sti();
}
     bb3:	5b                   	pop    %ebx
     bb4:	5e                   	pop    %esi
     bb5:	5f                   	pop    %edi
     bb6:	c3                   	ret    

00000bb7 <do_timer>:

void do_timer(long cpl)
{
     bb7:	56                   	push   %esi
     bb8:	53                   	push   %ebx
     bb9:	83 ec 04             	sub    $0x4,%esp
     bbc:	8b 74 24 10          	mov    0x10(%esp),%esi
	if (get_current_apic_id() != 0) {
		//printk("ap execute do_timer\n\r");
	}
	struct task_struct* current = get_current_task();
     bc0:	e8 fc ff ff ff       	call   bc1 <do_timer+0xa>
     bc5:	89 c3                	mov    %eax,%ebx
	extern int beepcount;
	extern void sysbeepstop(void);

	if (beepcount)
     bc7:	a1 00 00 00 00       	mov    0x0,%eax
     bcc:	85 c0                	test   %eax,%eax
     bce:	74 11                	je     be1 <do_timer+0x2a>
		if (!--beepcount)
     bd0:	83 e8 01             	sub    $0x1,%eax
     bd3:	a3 00 00 00 00       	mov    %eax,0x0
     bd8:	85 c0                	test   %eax,%eax
     bda:	75 05                	jne    be1 <do_timer+0x2a>
			sysbeepstop();
     bdc:	e8 fc ff ff ff       	call   bdd <do_timer+0x26>

	if (cpl)
     be1:	85 f6                	test   %esi,%esi
     be3:	74 09                	je     bee <do_timer+0x37>
		current->utime++;
     be5:	83 83 50 02 00 00 01 	addl   $0x1,0x250(%ebx)
     bec:	eb 07                	jmp    bf5 <do_timer+0x3e>
	else
		current->stime++;
     bee:	83 83 54 02 00 00 01 	addl   $0x1,0x254(%ebx)

	if (next_timer) {
     bf5:	a1 18 00 00 00       	mov    0x18,%eax
     bfa:	85 c0                	test   %eax,%eax
     bfc:	74 2d                	je     c2b <do_timer+0x74>
		next_timer->jiffies--;
     bfe:	8b 08                	mov    (%eax),%ecx
     c00:	8d 51 ff             	lea    -0x1(%ecx),%edx
     c03:	89 10                	mov    %edx,(%eax)
		while (next_timer && next_timer->jiffies <= 0) {
     c05:	85 d2                	test   %edx,%edx
     c07:	7f 22                	jg     c2b <do_timer+0x74>
			void (*fn)(void);
			
			fn = next_timer->fn;
     c09:	8b 50 04             	mov    0x4(%eax),%edx
			next_timer->fn = NULL;
     c0c:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
			next_timer = next_timer->next;
     c13:	8b 40 08             	mov    0x8(%eax),%eax
     c16:	a3 18 00 00 00       	mov    %eax,0x18
			(fn)();
     c1b:	ff d2                	call   *%edx
	else
		current->stime++;

	if (next_timer) {
		next_timer->jiffies--;
		while (next_timer && next_timer->jiffies <= 0) {
     c1d:	a1 18 00 00 00       	mov    0x18,%eax
     c22:	85 c0                	test   %eax,%eax
     c24:	74 05                	je     c2b <do_timer+0x74>
     c26:	83 38 00             	cmpl   $0x0,(%eax)
     c29:	7e de                	jle    c09 <do_timer+0x52>
			next_timer->fn = NULL;
			next_timer = next_timer->next;
			(fn)();
		}
	}
	if (current_DOR & 0xf0)
     c2b:	f6 05 00 00 00 00 f0 	testb  $0xf0,0x0
     c32:	74 05                	je     c39 <do_timer+0x82>
		do_floppy_timer();
     c34:	e8 fc ff ff ff       	call   c35 <do_timer+0x7e>
	if ((--current->counter)>0) return;
     c39:	8b 43 04             	mov    0x4(%ebx),%eax
     c3c:	83 e8 01             	sub    $0x1,%eax
     c3f:	85 c0                	test   %eax,%eax
     c41:	7e 05                	jle    c48 <do_timer+0x91>
     c43:	89 43 04             	mov    %eax,0x4(%ebx)
     c46:	eb 2b                	jmp    c73 <do_timer+0xbc>
	current->counter=0;
     c48:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)

	/*
	 * 后面有时间的话,会将调度改成在内核态可以进行抢占式调度,不过难度很大,最大的问题就是同步依赖问题,很容易造成锁的死锁状态.
	 * 任务要根据优先级,时间片,锁的依赖关系(每个进程是否要维护一个锁依赖列表)等等,要考虑的因素太多了,当前任务就不展开了.
	 *  */
	if (get_current_apic_id() == 0) {
     c4f:	e8 fc ff ff ff       	call   c50 <do_timer+0x99>
     c54:	85 c0                	test   %eax,%eax
     c56:	75 06                	jne    c5e <do_timer+0xa7>
		if (!cpl) return;  /* 这里可以看出内核态是不支持timer中断进行进程调度的，其他的外部中断除外 */
     c58:	85 f6                	test   %esi,%esi
     c5a:	75 12                	jne    c6e <do_timer+0xb7>
     c5c:	eb 15                	jmp    c73 <do_timer+0xbc>
		 *    如果调度运行其他任务的话,其他任务的时间片如果>当前任务的话,那么当前任务就有可能不会被调度,但是它占用的锁如果被其它进程依赖的话,
		 *    那么这种情况就造成了死锁状态.
		 * 2. 如果AP上运行的是当前任务是ap_default_task,其肯定是运行在内核态,但是它只执行idl_loop操作,
		 *    因此不会占用锁,也就不会造成其它进程的锁依赖,所以可以在内核态进行进程的调度.
		 *    */
		if (get_current_task() != &ap_default_task.task) {
     c5e:	e8 fc ff ff ff       	call   c5f <do_timer+0xa8>
			if (!cpl) return;
     c63:	85 f6                	test   %esi,%esi
     c65:	75 07                	jne    c6e <do_timer+0xb7>
     c67:	3d 00 00 00 00       	cmp    $0x0,%eax
     c6c:	75 05                	jne    c73 <do_timer+0xbc>
		}
	}

	schedule();
     c6e:	e8 fc ff ff ff       	call   c6f <do_timer+0xb8>
}
     c73:	83 c4 04             	add    $0x4,%esp
     c76:	5b                   	pop    %ebx
     c77:	5e                   	pop    %esi
     c78:	c3                   	ret    

00000c79 <sched_init>:
	int i;
	struct desc_struct * p;

	if (sizeof(struct sigaction) != 16)
		panic("Struct sigaction MUST be 16 bytes");
	set_tss_desc(gdt+FIRST_TSS_ENTRY,&(init_task.task.tss));
     c79:	b8 e8 02 00 00       	mov    $0x2e8,%eax
     c7e:	66 c7 05 20 00 00 00 	movw   $0x68,0x20
     c85:	68 00 
     c87:	66 a3 22 00 00 00    	mov    %ax,0x22
     c8d:	c1 c8 10             	ror    $0x10,%eax
     c90:	a2 24 00 00 00       	mov    %al,0x24
     c95:	c6 05 25 00 00 00 89 	movb   $0x89,0x25
     c9c:	c6 05 26 00 00 00 00 	movb   $0x0,0x26
     ca3:	88 25 27 00 00 00    	mov    %ah,0x27
     ca9:	c1 c8 10             	ror    $0x10,%eax
	set_ldt_desc(gdt+FIRST_LDT_ENTRY,&(init_task.task.ldt));
     cac:	b8 d0 02 00 00       	mov    $0x2d0,%eax
     cb1:	66 c7 05 28 00 00 00 	movw   $0x68,0x28
     cb8:	68 00 
     cba:	66 a3 2a 00 00 00    	mov    %ax,0x2a
     cc0:	c1 c8 10             	ror    $0x10,%eax
     cc3:	a2 2c 00 00 00       	mov    %al,0x2c
     cc8:	c6 05 2d 00 00 00 82 	movb   $0x82,0x2d
     ccf:	c6 05 2e 00 00 00 00 	movb   $0x0,0x2e
     cd6:	88 25 2f 00 00 00    	mov    %ah,0x2f
     cdc:	c1 c8 10             	ror    $0x10,%eax
     cdf:	ba 04 00 00 00       	mov    $0x4,%edx
	p = gdt+2+FIRST_TSS_ENTRY;
     ce4:	b8 30 00 00 00       	mov    $0x30,%eax
	for(i=1;i<NR_TASKS;i++) {
		task[i] = NULL;
     ce9:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
		p->a=p->b=0;
     cef:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
     cf6:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		p++;
		p->a=p->b=0;
     cfc:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
     d03:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
     d0a:	83 c0 10             	add    $0x10,%eax
     d0d:	83 c2 04             	add    $0x4,%edx
	if (sizeof(struct sigaction) != 16)
		panic("Struct sigaction MUST be 16 bytes");
	set_tss_desc(gdt+FIRST_TSS_ENTRY,&(init_task.task.tss));
	set_ldt_desc(gdt+FIRST_LDT_ENTRY,&(init_task.task.ldt));
	p = gdt+2+FIRST_TSS_ENTRY;
	for(i=1;i<NR_TASKS;i++) {
     d10:	3d 20 04 00 00       	cmp    $0x420,%eax
     d15:	75 d2                	jne    ce9 <sched_init+0x70>
		p++;
		p->a=p->b=0;
		p++;
	}
/* Clear NT, so that we won't have troubles with that later on */
	__asm__("pushfl ; andl $0xffffbfff,(%esp) ; popfl");
     d17:	9c                   	pushf  
     d18:	81 24 24 ff bf ff ff 	andl   $0xffffbfff,(%esp)
     d1f:	9d                   	popf   
	ltr(0);
     d20:	b8 20 00 00 00       	mov    $0x20,%eax
     d25:	0f 00 d8             	ltr    %ax
	lldt(0);
     d28:	b8 28 00 00 00       	mov    $0x28,%eax
     d2d:	0f 00 d0             	lldt   %ax
	outb_p(LATCH & 0xff , 0x40);	/* LSB */
	outb(LATCH >> 8 , 0x40);	/* MSB */
	set_intr_gate(0x20,&timer_interrupt);
	outb(inb_p(0x21)&~0x01,0x21);   /* Not mask timer intr */
#else
	set_intr_gate(APIC_TIMER_INTR_NO,&timer_interrupt);  /* Vector value 0x83 for APIC timer */
     d30:	b8 00 00 08 00       	mov    $0x80000,%eax
     d35:	ba 00 00 00 00       	mov    $0x0,%edx
     d3a:	66 89 d0             	mov    %dx,%ax
     d3d:	66 ba 00 8e          	mov    $0x8e00,%dx
     d41:	a3 18 04 00 00       	mov    %eax,0x418
     d46:	89 15 1c 04 00 00    	mov    %edx,0x41c
#endif

	set_system_gate(0x80,&system_call);
     d4c:	ba 00 00 00 00       	mov    $0x0,%edx
     d51:	66 89 d0             	mov    %dx,%ax
     d54:	66 ba 00 ef          	mov    $0xef00,%dx
     d58:	a3 00 04 00 00       	mov    %eax,0x400
     d5d:	89 15 04 04 00 00    	mov    %edx,0x404
     d63:	c3                   	ret    

00000d64 <bad_sys_call>:
     d64:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
     d69:	cf                   	iret   
     d6a:	66 90                	xchg   %ax,%ax

00000d6c <reschedule>:
     d6c:	68 ac 0d 00 00       	push   $0xdac
     d71:	e9 fc ff ff ff       	jmp    d72 <reschedule+0x6>
     d76:	66 90                	xchg   %ax,%ax

00000d78 <system_call>:
     d78:	83 f8 47             	cmp    $0x47,%eax
     d7b:	77 e7                	ja     d64 <bad_sys_call>
     d7d:	1e                   	push   %ds
     d7e:	06                   	push   %es
     d7f:	0f a0                	push   %fs
     d81:	52                   	push   %edx
     d82:	51                   	push   %ecx
     d83:	53                   	push   %ebx
     d84:	ba 10 00 00 00       	mov    $0x10,%edx
     d89:	8e da                	mov    %edx,%ds
     d8b:	8e c2                	mov    %edx,%es
     d8d:	ba 17 00 00 00       	mov    $0x17,%edx
     d92:	8e e2                	mov    %edx,%fs
     d94:	ff 14 85 00 00 00 00 	call   *0x0(,%eax,4)
     d9b:	50                   	push   %eax
     d9c:	e8 fc ff ff ff       	call   d9d <system_call+0x25>
     da1:	83 38 00             	cmpl   $0x0,(%eax)
     da4:	75 c6                	jne    d6c <reschedule>
     da6:	83 78 04 00          	cmpl   $0x0,0x4(%eax)
     daa:	74 c0                	je     d6c <reschedule>

00000dac <ret_from_sys_call>:
     dac:	e8 fc ff ff ff       	call   dad <ret_from_sys_call+0x1>
     db1:	3b 05 00 00 00 00    	cmp    0x0,%eax
     db7:	74 30                	je     de9 <ret_from_sys_call+0x3d>
     db9:	66 83 7c 24 20 0f    	cmpw   $0xf,0x20(%esp)
     dbf:	75 28                	jne    de9 <ret_from_sys_call+0x3d>
     dc1:	66 83 7c 24 2c 17    	cmpw   $0x17,0x2c(%esp)
     dc7:	75 20                	jne    de9 <ret_from_sys_call+0x3d>
     dc9:	8b 58 0c             	mov    0xc(%eax),%ebx
     dcc:	8b 88 10 02 00 00    	mov    0x210(%eax),%ecx
     dd2:	f7 d1                	not    %ecx
     dd4:	21 d9                	and    %ebx,%ecx
     dd6:	0f bc c9             	bsf    %ecx,%ecx
     dd9:	74 0e                	je     de9 <ret_from_sys_call+0x3d>
     ddb:	0f b3 cb             	btr    %ecx,%ebx
     dde:	89 58 0c             	mov    %ebx,0xc(%eax)
     de1:	41                   	inc    %ecx
     de2:	51                   	push   %ecx
     de3:	e8 fc ff ff ff       	call   de4 <ret_from_sys_call+0x38>
     de8:	58                   	pop    %eax
     de9:	58                   	pop    %eax
     dea:	5b                   	pop    %ebx
     deb:	59                   	pop    %ecx
     dec:	5a                   	pop    %edx
     ded:	0f a1                	pop    %fs
     def:	07                   	pop    %es
     df0:	1f                   	pop    %ds
     df1:	cf                   	iret   
     df2:	66 90                	xchg   %ax,%ax

00000df4 <coprocessor_error>:
     df4:	1e                   	push   %ds
     df5:	06                   	push   %es
     df6:	0f a0                	push   %fs
     df8:	52                   	push   %edx
     df9:	51                   	push   %ecx
     dfa:	53                   	push   %ebx
     dfb:	50                   	push   %eax
     dfc:	b8 10 00 00 00       	mov    $0x10,%eax
     e01:	8e d8                	mov    %eax,%ds
     e03:	8e c0                	mov    %eax,%es
     e05:	b8 17 00 00 00       	mov    $0x17,%eax
     e0a:	8e e0                	mov    %eax,%fs
     e0c:	68 ac 0d 00 00       	push   $0xdac
     e11:	e9 fc ff ff ff       	jmp    e12 <coprocessor_error+0x1e>
     e16:	66 90                	xchg   %ax,%ax

00000e18 <device_not_available>:
     e18:	1e                   	push   %ds
     e19:	06                   	push   %es
     e1a:	0f a0                	push   %fs
     e1c:	52                   	push   %edx
     e1d:	51                   	push   %ecx
     e1e:	53                   	push   %ebx
     e1f:	50                   	push   %eax
     e20:	b8 10 00 00 00       	mov    $0x10,%eax
     e25:	8e d8                	mov    %eax,%ds
     e27:	8e c0                	mov    %eax,%es
     e29:	b8 17 00 00 00       	mov    $0x17,%eax
     e2e:	8e e0                	mov    %eax,%fs
     e30:	68 ac 0d 00 00       	push   $0xdac
     e35:	0f 06                	clts   
     e37:	0f 20 c0             	mov    %cr0,%eax
     e3a:	a9 04 00 00 00       	test   $0x4,%eax
     e3f:	0f 84 fc ff ff ff    	je     e41 <device_not_available+0x29>
     e45:	55                   	push   %ebp
     e46:	56                   	push   %esi
     e47:	57                   	push   %edi
     e48:	e8 fc ff ff ff       	call   e49 <device_not_available+0x31>
     e4d:	5f                   	pop    %edi
     e4e:	5e                   	pop    %esi
     e4f:	5d                   	pop    %ebp
     e50:	c3                   	ret    
     e51:	8d 76 00             	lea    0x0(%esi),%esi

00000e54 <timer_interrupt>:
     e54:	1e                   	push   %ds
     e55:	06                   	push   %es
     e56:	0f a0                	push   %fs
     e58:	52                   	push   %edx
     e59:	51                   	push   %ecx
     e5a:	53                   	push   %ebx
     e5b:	50                   	push   %eax
     e5c:	ba 10 00 00 00       	mov    $0x10,%edx
     e61:	8e da                	mov    %edx,%ds
     e63:	8e c2                	mov    %edx,%es
     e65:	e8 fc ff ff ff       	call   e66 <timer_interrupt+0x12>
     e6a:	83 f8 00             	cmp    $0x0,%eax
     e6d:	75 07                	jne    e76 <timer_interrupt+0x22>
     e6f:	ba 17 00 00 00       	mov    $0x17,%edx
     e74:	eb 05                	jmp    e7b <timer_interrupt+0x27>
     e76:	ba 10 00 00 00       	mov    $0x10,%edx
     e7b:	8e e2                	mov    %edx,%fs
     e7d:	ff 05 00 00 00 00    	incl   0x0
     e83:	e8 fc ff ff ff       	call   e84 <timer_interrupt+0x30>
     e88:	8b 44 24 20          	mov    0x20(%esp),%eax
     e8c:	83 e0 03             	and    $0x3,%eax
     e8f:	50                   	push   %eax
     e90:	e8 fc ff ff ff       	call   e91 <timer_interrupt+0x3d>
     e95:	83 c4 04             	add    $0x4,%esp
     e98:	e9 0f ff ff ff       	jmp    dac <ret_from_sys_call>
     e9d:	8d 76 00             	lea    0x0(%esi),%esi

00000ea0 <sys_execve>:
     ea0:	8d 44 24 1c          	lea    0x1c(%esp),%eax
     ea4:	50                   	push   %eax
     ea5:	e8 fc ff ff ff       	call   ea6 <sys_execve+0x6>
     eaa:	83 c4 04             	add    $0x4,%esp
     ead:	c3                   	ret    
     eae:	66 90                	xchg   %ax,%ax

00000eb0 <sys_fork>:
     eb0:	e8 fc ff ff ff       	call   eb1 <sys_fork+0x1>
     eb5:	85 c0                	test   %eax,%eax
     eb7:	78 0e                	js     ec7 <sys_fork+0x17>
     eb9:	0f a8                	push   %gs
     ebb:	56                   	push   %esi
     ebc:	57                   	push   %edi
     ebd:	55                   	push   %ebp
     ebe:	50                   	push   %eax
     ebf:	e8 fc ff ff ff       	call   ec0 <sys_fork+0x10>
     ec4:	83 c4 14             	add    $0x14,%esp
     ec7:	c3                   	ret    

00000ec8 <hd_interrupt>:
     ec8:	50                   	push   %eax
     ec9:	51                   	push   %ecx
     eca:	52                   	push   %edx
     ecb:	1e                   	push   %ds
     ecc:	06                   	push   %es
     ecd:	0f a0                	push   %fs
     ecf:	b8 10 00 00 00       	mov    $0x10,%eax
     ed4:	8e d8                	mov    %eax,%ds
     ed6:	8e c0                	mov    %eax,%es
     ed8:	b8 17 00 00 00       	mov    $0x17,%eax
     edd:	8e e0                	mov    %eax,%fs
     edf:	b0 20                	mov    $0x20,%al
     ee1:	e6 a0                	out    %al,$0xa0
     ee3:	eb 00                	jmp    ee5 <hd_interrupt+0x1d>
     ee5:	eb 00                	jmp    ee7 <hd_interrupt+0x1f>
     ee7:	31 d2                	xor    %edx,%edx
     ee9:	87 15 00 00 00 00    	xchg   %edx,0x0
     eef:	85 d2                	test   %edx,%edx
     ef1:	75 05                	jne    ef8 <hd_interrupt+0x30>
     ef3:	ba 00 00 00 00       	mov    $0x0,%edx
     ef8:	e6 20                	out    %al,$0x20
     efa:	ff d2                	call   *%edx
     efc:	0f a1                	pop    %fs
     efe:	07                   	pop    %es
     eff:	1f                   	pop    %ds
     f00:	5a                   	pop    %edx
     f01:	59                   	pop    %ecx
     f02:	58                   	pop    %eax
     f03:	cf                   	iret   

00000f04 <floppy_interrupt>:
     f04:	50                   	push   %eax
     f05:	51                   	push   %ecx
     f06:	52                   	push   %edx
     f07:	1e                   	push   %ds
     f08:	06                   	push   %es
     f09:	0f a0                	push   %fs
     f0b:	b8 10 00 00 00       	mov    $0x10,%eax
     f10:	8e d8                	mov    %eax,%ds
     f12:	8e c0                	mov    %eax,%es
     f14:	b8 17 00 00 00       	mov    $0x17,%eax
     f19:	8e e0                	mov    %eax,%fs
     f1b:	b0 20                	mov    $0x20,%al
     f1d:	e6 20                	out    %al,$0x20
     f1f:	31 c0                	xor    %eax,%eax
     f21:	87 05 00 00 00 00    	xchg   %eax,0x0
     f27:	85 c0                	test   %eax,%eax
     f29:	75 05                	jne    f30 <floppy_interrupt+0x2c>
     f2b:	b8 00 00 00 00       	mov    $0x0,%eax
     f30:	ff d0                	call   *%eax
     f32:	0f a1                	pop    %fs
     f34:	07                   	pop    %es
     f35:	1f                   	pop    %ds
     f36:	5a                   	pop    %edx
     f37:	59                   	pop    %ecx
     f38:	58                   	pop    %eax
     f39:	cf                   	iret   

00000f3a <parallel_interrupt>:
     f3a:	50                   	push   %eax
     f3b:	b0 20                	mov    $0x20,%al
     f3d:	e6 20                	out    %al,$0x20
     f3f:	58                   	pop    %eax
     f40:	cf                   	iret   

00000f41 <parse_cpu_topology>:
     f41:	50                   	push   %eax
     f42:	53                   	push   %ebx
     f43:	51                   	push   %ecx
     f44:	52                   	push   %edx
     f45:	b8 01 00 00 00       	mov    $0x1,%eax
     f4a:	0f a2                	cpuid  
     f4c:	5a                   	pop    %edx
     f4d:	59                   	pop    %ecx
     f4e:	5b                   	pop    %ebx
     f4f:	58                   	pop    %eax
     f50:	cf                   	iret   

00000f51 <handle_ipi_interrupt>:
     f51:	50                   	push   %eax
     f52:	53                   	push   %ebx
     f53:	51                   	push   %ecx
     f54:	52                   	push   %edx
     f55:	e8 fc ff ff ff       	call   f56 <handle_ipi_interrupt+0x5>
     f5a:	e8 fc ff ff ff       	call   f5b <handle_ipi_interrupt+0xa>
     f5f:	5a                   	pop    %edx
     f60:	59                   	pop    %ecx
     f61:	5b                   	pop    %ebx
     f62:	58                   	pop    %eax
     f63:	cf                   	iret   

00000f64 <die>:
void parallel_interrupt(void);
void handle_ipi_interrupt(void);
void irq13(void);

static void die(char * str,long esp_ptr,long nr)
{
     f64:	55                   	push   %ebp
     f65:	57                   	push   %edi
     f66:	56                   	push   %esi
     f67:	53                   	push   %ebx
     f68:	83 ec 1c             	sub    $0x1c,%esp
     f6b:	89 44 24 08          	mov    %eax,0x8(%esp)
     f6f:	89 d6                	mov    %edx,%esi
     f71:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
	struct task_struct* current = get_current_task();
     f75:	e8 fc ff ff ff       	call   f76 <die+0x12>
     f7a:	89 c5                	mov    %eax,%ebp
	long * esp = (long *) esp_ptr;
     f7c:	89 f3                	mov    %esi,%ebx
	int i;
    printk("die at apic_id: %d, nr: %d, pid: %d, task_addr: %p\n\r", get_current_apic_id(), current->task_nr, current->pid, current);
     f7e:	8b b8 2c 02 00 00    	mov    0x22c(%eax),%edi
     f84:	89 7c 24 04          	mov    %edi,0x4(%esp)
     f88:	8b b8 c0 03 00 00    	mov    0x3c0(%eax),%edi
     f8e:	e8 fc ff ff ff       	call   f8f <die+0x2b>
     f93:	83 ec 0c             	sub    $0xc,%esp
     f96:	55                   	push   %ebp
     f97:	ff 74 24 14          	pushl  0x14(%esp)
     f9b:	57                   	push   %edi
     f9c:	50                   	push   %eax
     f9d:	68 28 00 00 00       	push   $0x28
     fa2:	e8 fc ff ff ff       	call   fa3 <die+0x3f>
	printk("%s: %04x\n\r",str,nr&0xffff);
     fa7:	83 c4 1c             	add    $0x1c,%esp
     faa:	0f b7 44 24 10       	movzwl 0x10(%esp),%eax
     faf:	50                   	push   %eax
     fb0:	ff 74 24 10          	pushl  0x10(%esp)
     fb4:	68 95 00 00 00       	push   $0x95
     fb9:	e8 fc ff ff ff       	call   fba <die+0x56>
	printk("EIP:\t%04x:%p\nEFLAGS:\t%p\nESP:\t%04x:%p\n",
     fbe:	83 c4 08             	add    $0x8,%esp
     fc1:	ff 76 0c             	pushl  0xc(%esi)
     fc4:	ff 76 10             	pushl  0x10(%esi)
     fc7:	ff 76 08             	pushl  0x8(%esi)
     fca:	ff 36                	pushl  (%esi)
     fcc:	ff 76 04             	pushl  0x4(%esi)
     fcf:	68 60 00 00 00       	push   $0x60
     fd4:	e8 fc ff ff ff       	call   fd5 <die+0x71>
		esp[1],esp[0],esp[2],esp[4],esp[3]);
	printk("fs: %04x\n",_fs());
     fd9:	66 8c e0             	mov    %fs,%ax
     fdc:	83 c4 18             	add    $0x18,%esp
     fdf:	0f b7 c0             	movzwl %ax,%eax
     fe2:	50                   	push   %eax
     fe3:	68 a0 00 00 00       	push   $0xa0
     fe8:	e8 fc ff ff ff       	call   fe9 <die+0x85>
	printk("base: %p, limit: %p\n",get_base(current->ldt[1]),get_limit(0x17));
     fed:	b9 17 00 00 00       	mov    $0x17,%ecx
     ff2:	0f 03 c9             	lsl    %cx,%ecx
     ff5:	41                   	inc    %ecx
     ff6:	50                   	push   %eax
     ff7:	8d 85 d8 02 00 00    	lea    0x2d8(%ebp),%eax
     ffd:	83 c0 07             	add    $0x7,%eax
    1000:	8a 30                	mov    (%eax),%dh
    1002:	83 e8 03             	sub    $0x3,%eax
    1005:	8a 10                	mov    (%eax),%dl
    1007:	c1 e2 10             	shl    $0x10,%edx
    100a:	83 e8 02             	sub    $0x2,%eax
    100d:	66 8b 10             	mov    (%eax),%dx
    1010:	58                   	pop    %eax
    1011:	83 c4 0c             	add    $0xc,%esp
    1014:	51                   	push   %ecx
    1015:	52                   	push   %edx
    1016:	68 aa 00 00 00       	push   $0xaa
    101b:	e8 fc ff ff ff       	call   101c <die+0xb8>
	if (esp[4] == 0x17) {
    1020:	83 c4 10             	add    $0x10,%esp
    1023:	83 7e 10 17          	cmpl   $0x17,0x10(%esi)
    1027:	75 52                	jne    107b <die+0x117>
		printk("Stack: ");
    1029:	83 ec 0c             	sub    $0xc,%esp
    102c:	68 bf 00 00 00       	push   $0xbf
    1031:	e8 fc ff ff ff       	call   1032 <die+0xce>
    1036:	83 c4 10             	add    $0x10,%esp
    1039:	be 00 00 00 00       	mov    $0x0,%esi
		for (i=0;i<4;i++)
			printk("%p ",get_seg_long(0x17,i+(long *)esp[3]));
    103e:	bf 17 00 00 00       	mov    $0x17,%edi
    1043:	8b 53 0c             	mov    0xc(%ebx),%edx
    1046:	89 f8                	mov    %edi,%eax
    1048:	0f a0                	push   %fs
    104a:	8e e0                	mov    %eax,%fs
    104c:	64 8b 04 32          	mov    %fs:(%edx,%esi,1),%eax
    1050:	0f a1                	pop    %fs
    1052:	83 ec 08             	sub    $0x8,%esp
    1055:	50                   	push   %eax
    1056:	68 c7 00 00 00       	push   $0xc7
    105b:	e8 fc ff ff ff       	call   105c <die+0xf8>
    1060:	83 c6 04             	add    $0x4,%esi
		esp[1],esp[0],esp[2],esp[4],esp[3]);
	printk("fs: %04x\n",_fs());
	printk("base: %p, limit: %p\n",get_base(current->ldt[1]),get_limit(0x17));
	if (esp[4] == 0x17) {
		printk("Stack: ");
		for (i=0;i<4;i++)
    1063:	83 c4 10             	add    $0x10,%esp
    1066:	83 fe 10             	cmp    $0x10,%esi
    1069:	75 d8                	jne    1043 <die+0xdf>
			printk("%p ",get_seg_long(0x17,i+(long *)esp[3]));
		printk("\n");
    106b:	83 ec 0c             	sub    $0xc,%esp
    106e:	68 cb 00 00 00       	push   $0xcb
    1073:	e8 fc ff ff ff       	call   1074 <die+0x110>
    1078:	83 c4 10             	add    $0x10,%esp
	}
	str(i);
    107b:	b8 00 00 00 00       	mov    $0x0,%eax
    1080:	66 0f 00 c8          	str    %ax
    1084:	83 e8 20             	sub    $0x20,%eax
    1087:	c1 e8 04             	shr    $0x4,%eax
	printk("Pid: %d, process nr: %d\n\r",current->pid,0xffff & i);
    108a:	83 ec 04             	sub    $0x4,%esp
    108d:	0f b7 c0             	movzwl %ax,%eax
    1090:	50                   	push   %eax
    1091:	ff b5 2c 02 00 00    	pushl  0x22c(%ebp)
    1097:	68 cd 00 00 00       	push   $0xcd
    109c:	e8 fc ff ff ff       	call   109d <die+0x139>
    10a1:	83 c4 10             	add    $0x10,%esp
	for(i=0;i<10;i++)
    10a4:	be 00 00 00 00       	mov    $0x0,%esi
		printk("%02x ",0xff & get_seg_byte(esp[1],(i+(char *)esp[0])));
    10a9:	8b 43 04             	mov    0x4(%ebx),%eax
    10ac:	8b 13                	mov    (%ebx),%edx
    10ae:	0f a0                	push   %fs
    10b0:	8e e0                	mov    %eax,%fs
    10b2:	64 8a 04 32          	mov    %fs:(%edx,%esi,1),%al
    10b6:	0f a1                	pop    %fs
    10b8:	83 ec 08             	sub    $0x8,%esp
    10bb:	0f b6 c0             	movzbl %al,%eax
    10be:	50                   	push   %eax
    10bf:	68 e7 00 00 00       	push   $0xe7
    10c4:	e8 fc ff ff ff       	call   10c5 <die+0x161>
			printk("%p ",get_seg_long(0x17,i+(long *)esp[3]));
		printk("\n");
	}
	str(i);
	printk("Pid: %d, process nr: %d\n\r",current->pid,0xffff & i);
	for(i=0;i<10;i++)
    10c9:	83 c6 01             	add    $0x1,%esi
    10cc:	83 c4 10             	add    $0x10,%esp
    10cf:	83 fe 0a             	cmp    $0xa,%esi
    10d2:	75 d5                	jne    10a9 <die+0x145>
		printk("%02x ",0xff & get_seg_byte(esp[1],(i+(char *)esp[0])));
	printk("\n\r");
    10d4:	83 ec 0c             	sub    $0xc,%esp
    10d7:	68 ed 00 00 00       	push   $0xed
    10dc:	e8 fc ff ff ff       	call   10dd <die+0x179>
	panic("First general protection exception. \n\r");
    10e1:	c7 04 24 88 00 00 00 	movl   $0x88,(%esp)
    10e8:	e8 fc ff ff ff       	call   10e9 <die+0x185>
	do_exit(11);		/* play segment exception */
    10ed:	c7 04 24 0b 00 00 00 	movl   $0xb,(%esp)
    10f4:	e8 fc ff ff ff       	call   10f5 <die+0x191>
}
    10f9:	83 c4 2c             	add    $0x2c,%esp
    10fc:	5b                   	pop    %ebx
    10fd:	5e                   	pop    %esi
    10fe:	5f                   	pop    %edi
    10ff:	5d                   	pop    %ebp
    1100:	c3                   	ret    

00001101 <do_double_fault>:

void do_double_fault(long esp, long error_code)
{
    1101:	83 ec 0c             	sub    $0xc,%esp
	die("double fault",esp,error_code);
    1104:	8b 4c 24 14          	mov    0x14(%esp),%ecx
    1108:	8b 54 24 10          	mov    0x10(%esp),%edx
    110c:	b8 f0 00 00 00       	mov    $0xf0,%eax
    1111:	e8 4e fe ff ff       	call   f64 <die>
}
    1116:	83 c4 0c             	add    $0xc,%esp
    1119:	c3                   	ret    

0000111a <do_general_protection>:

void do_general_protection(long esp, long error_code)
{
    111a:	83 ec 0c             	sub    $0xc,%esp
	die("general protection",esp,error_code);
    111d:	8b 4c 24 14          	mov    0x14(%esp),%ecx
    1121:	8b 54 24 10          	mov    0x10(%esp),%edx
    1125:	b8 fd 00 00 00       	mov    $0xfd,%eax
    112a:	e8 35 fe ff ff       	call   f64 <die>
}
    112f:	83 c4 0c             	add    $0xc,%esp
    1132:	c3                   	ret    

00001133 <do_divide_error>:

void do_divide_error(long esp, long error_code)
{
    1133:	83 ec 0c             	sub    $0xc,%esp
	die("divide_error",esp,error_code);
    1136:	8b 4c 24 14          	mov    0x14(%esp),%ecx
    113a:	8b 54 24 10          	mov    0x10(%esp),%edx
    113e:	b8 10 01 00 00       	mov    $0x110,%eax
    1143:	e8 1c fe ff ff       	call   f64 <die>
}
    1148:	83 c4 0c             	add    $0xc,%esp
    114b:	c3                   	ret    

0000114c <do_int3>:

void do_int3(long * esp, long error_code,
		long fs,long es,long ds,
		long ebp,long esi,long edi,
		long edx,long ecx,long ebx,long eax)
{
    114c:	56                   	push   %esi
    114d:	53                   	push   %ebx
    114e:	83 ec 10             	sub    $0x10,%esp
    1151:	8b 5c 24 1c          	mov    0x1c(%esp),%ebx
	int tr;

	__asm__("str %%ax":"=a" (tr):"0" (0));
    1155:	be 00 00 00 00       	mov    $0x0,%esi
    115a:	89 f0                	mov    %esi,%eax
    115c:	66 0f 00 c8          	str    %ax
    1160:	89 c6                	mov    %eax,%esi
	printk("eax\t\tebx\t\tecx\t\tedx\n\r%8x\t%8x\t%8x\t%8x\n\r",
    1162:	ff 74 24 3c          	pushl  0x3c(%esp)
    1166:	ff 74 24 44          	pushl  0x44(%esp)
    116a:	ff 74 24 4c          	pushl  0x4c(%esp)
    116e:	ff 74 24 54          	pushl  0x54(%esp)
    1172:	68 b0 00 00 00       	push   $0xb0
    1177:	e8 fc ff ff ff       	call   1178 <do_int3+0x2c>
		eax,ebx,ecx,edx);
	printk("esi\t\tedi\t\tebp\t\tesp\n\r%8x\t%8x\t%8x\t%8x\n\r",
    117c:	83 c4 14             	add    $0x14,%esp
    117f:	53                   	push   %ebx
    1180:	ff 74 24 34          	pushl  0x34(%esp)
    1184:	ff 74 24 40          	pushl  0x40(%esp)
    1188:	ff 74 24 40          	pushl  0x40(%esp)
    118c:	68 d8 00 00 00       	push   $0xd8
    1191:	e8 fc ff ff ff       	call   1192 <do_int3+0x46>
		esi,edi,ebp,(long) esp);
	printk("\n\rds\tes\tfs\ttr\n\r%4x\t%4x\t%4x\t%4x\n\r",
    1196:	83 c4 14             	add    $0x14,%esp
    1199:	56                   	push   %esi
    119a:	ff 74 24 28          	pushl  0x28(%esp)
    119e:	ff 74 24 30          	pushl  0x30(%esp)
    11a2:	ff 74 24 38          	pushl  0x38(%esp)
    11a6:	68 00 01 00 00       	push   $0x100
    11ab:	e8 fc ff ff ff       	call   11ac <do_int3+0x60>
		ds,es,fs,tr);
	printk("EIP: %8x   CS: %4x  EFLAGS: %8x\n\r",esp[0],esp[1],esp[2]);
    11b0:	83 c4 20             	add    $0x20,%esp
    11b3:	ff 73 08             	pushl  0x8(%ebx)
    11b6:	ff 73 04             	pushl  0x4(%ebx)
    11b9:	ff 33                	pushl  (%ebx)
    11bb:	68 24 01 00 00       	push   $0x124
    11c0:	e8 fc ff ff ff       	call   11c1 <do_int3+0x75>
}
    11c5:	83 c4 14             	add    $0x14,%esp
    11c8:	5b                   	pop    %ebx
    11c9:	5e                   	pop    %esi
    11ca:	c3                   	ret    

000011cb <do_nmi>:

void do_nmi(long esp, long error_code)
{
    11cb:	83 ec 0c             	sub    $0xc,%esp
	die("nmi",esp,error_code);
    11ce:	8b 4c 24 14          	mov    0x14(%esp),%ecx
    11d2:	8b 54 24 10          	mov    0x10(%esp),%edx
    11d6:	b8 1d 01 00 00       	mov    $0x11d,%eax
    11db:	e8 84 fd ff ff       	call   f64 <die>
}
    11e0:	83 c4 0c             	add    $0xc,%esp
    11e3:	c3                   	ret    

000011e4 <do_debug>:

void do_debug(long esp, long error_code)
{
    11e4:	83 ec 0c             	sub    $0xc,%esp
	die("debug",esp,error_code);
    11e7:	8b 4c 24 14          	mov    0x14(%esp),%ecx
    11eb:	8b 54 24 10          	mov    0x10(%esp),%edx
    11ef:	b8 21 01 00 00       	mov    $0x121,%eax
    11f4:	e8 6b fd ff ff       	call   f64 <die>
}
    11f9:	83 c4 0c             	add    $0xc,%esp
    11fc:	c3                   	ret    

000011fd <do_overflow>:

void do_overflow(long esp, long error_code)
{
    11fd:	83 ec 0c             	sub    $0xc,%esp
	die("overflow",esp,error_code);
    1200:	8b 4c 24 14          	mov    0x14(%esp),%ecx
    1204:	8b 54 24 10          	mov    0x10(%esp),%edx
    1208:	b8 27 01 00 00       	mov    $0x127,%eax
    120d:	e8 52 fd ff ff       	call   f64 <die>
}
    1212:	83 c4 0c             	add    $0xc,%esp
    1215:	c3                   	ret    

00001216 <do_bounds>:

void do_bounds(long esp, long error_code)
{
    1216:	83 ec 0c             	sub    $0xc,%esp
	die("bounds",esp,error_code);
    1219:	8b 4c 24 14          	mov    0x14(%esp),%ecx
    121d:	8b 54 24 10          	mov    0x10(%esp),%edx
    1221:	b8 30 01 00 00       	mov    $0x130,%eax
    1226:	e8 39 fd ff ff       	call   f64 <die>
}
    122b:	83 c4 0c             	add    $0xc,%esp
    122e:	c3                   	ret    

0000122f <do_invalid_op>:

void do_invalid_op(long esp, long error_code)
{
    122f:	83 ec 0c             	sub    $0xc,%esp
	die("invalid operand",esp,error_code);
    1232:	8b 4c 24 14          	mov    0x14(%esp),%ecx
    1236:	8b 54 24 10          	mov    0x10(%esp),%edx
    123a:	b8 37 01 00 00       	mov    $0x137,%eax
    123f:	e8 20 fd ff ff       	call   f64 <die>
}
    1244:	83 c4 0c             	add    $0xc,%esp
    1247:	c3                   	ret    

00001248 <do_device_not_available>:

void do_device_not_available(long esp, long error_code)
{
    1248:	83 ec 0c             	sub    $0xc,%esp
	die("device not available",esp,error_code);
    124b:	8b 4c 24 14          	mov    0x14(%esp),%ecx
    124f:	8b 54 24 10          	mov    0x10(%esp),%edx
    1253:	b8 47 01 00 00       	mov    $0x147,%eax
    1258:	e8 07 fd ff ff       	call   f64 <die>
}
    125d:	83 c4 0c             	add    $0xc,%esp
    1260:	c3                   	ret    

00001261 <do_coprocessor_segment_overrun>:

void do_coprocessor_segment_overrun(long esp, long error_code)
{
    1261:	83 ec 0c             	sub    $0xc,%esp
	die("coprocessor segment overrun",esp,error_code);
    1264:	8b 4c 24 14          	mov    0x14(%esp),%ecx
    1268:	8b 54 24 10          	mov    0x10(%esp),%edx
    126c:	b8 5c 01 00 00       	mov    $0x15c,%eax
    1271:	e8 ee fc ff ff       	call   f64 <die>
}
    1276:	83 c4 0c             	add    $0xc,%esp
    1279:	c3                   	ret    

0000127a <do_invalid_TSS>:

void do_invalid_TSS(long esp,long error_code)
{
    127a:	83 ec 0c             	sub    $0xc,%esp
	die("invalid TSS",esp,error_code);
    127d:	8b 4c 24 14          	mov    0x14(%esp),%ecx
    1281:	8b 54 24 10          	mov    0x10(%esp),%edx
    1285:	b8 78 01 00 00       	mov    $0x178,%eax
    128a:	e8 d5 fc ff ff       	call   f64 <die>
}
    128f:	83 c4 0c             	add    $0xc,%esp
    1292:	c3                   	ret    

00001293 <do_segment_not_present>:

void do_segment_not_present(long esp,long error_code)
{
    1293:	83 ec 0c             	sub    $0xc,%esp
	die("segment not present",esp,error_code);
    1296:	8b 4c 24 14          	mov    0x14(%esp),%ecx
    129a:	8b 54 24 10          	mov    0x10(%esp),%edx
    129e:	b8 84 01 00 00       	mov    $0x184,%eax
    12a3:	e8 bc fc ff ff       	call   f64 <die>
}
    12a8:	83 c4 0c             	add    $0xc,%esp
    12ab:	c3                   	ret    

000012ac <do_stack_segment>:

void do_stack_segment(long esp,long error_code)
{
    12ac:	83 ec 0c             	sub    $0xc,%esp
	die("stack segment",esp,error_code);
    12af:	8b 4c 24 14          	mov    0x14(%esp),%ecx
    12b3:	8b 54 24 10          	mov    0x10(%esp),%edx
    12b7:	b8 98 01 00 00       	mov    $0x198,%eax
    12bc:	e8 a3 fc ff ff       	call   f64 <die>
}
    12c1:	83 c4 0c             	add    $0xc,%esp
    12c4:	c3                   	ret    

000012c5 <do_coprocessor_error>:

void do_coprocessor_error(long esp, long error_code)
{
    12c5:	83 ec 0c             	sub    $0xc,%esp
	if (last_task_used_math != get_current_task())
    12c8:	e8 fc ff ff ff       	call   12c9 <do_coprocessor_error+0x4>
    12cd:	39 05 00 00 00 00    	cmp    %eax,0x0
    12d3:	75 12                	jne    12e7 <do_coprocessor_error+0x22>
		return;
	die("coprocessor error",esp,error_code);
    12d5:	8b 4c 24 14          	mov    0x14(%esp),%ecx
    12d9:	8b 54 24 10          	mov    0x10(%esp),%edx
    12dd:	b8 a6 01 00 00       	mov    $0x1a6,%eax
    12e2:	e8 7d fc ff ff       	call   f64 <die>
}
    12e7:	83 c4 0c             	add    $0xc,%esp
    12ea:	c3                   	ret    

000012eb <do_reserved>:

void do_reserved(long esp, long error_code)
{
    12eb:	83 ec 0c             	sub    $0xc,%esp
	die("reserved (15,17-47) error",esp,error_code);
    12ee:	8b 4c 24 14          	mov    0x14(%esp),%ecx
    12f2:	8b 54 24 10          	mov    0x10(%esp),%edx
    12f6:	b8 b8 01 00 00       	mov    $0x1b8,%eax
    12fb:	e8 64 fc ff ff       	call   f64 <die>
}
    1300:	83 c4 0c             	add    $0xc,%esp
    1303:	c3                   	ret    

00001304 <trap_init>:

void trap_init(void)
{
    1304:	53                   	push   %ebx
	int i;

	set_trap_gate(0,&divide_error);
    1305:	b8 00 00 08 00       	mov    $0x80000,%eax
    130a:	ba 00 00 00 00       	mov    $0x0,%edx
    130f:	66 89 d0             	mov    %dx,%ax
    1312:	66 ba 00 8f          	mov    $0x8f00,%dx
    1316:	a3 00 00 00 00       	mov    %eax,0x0
    131b:	89 15 04 00 00 00    	mov    %edx,0x4
	set_trap_gate(1,&debug);
    1321:	ba 00 00 00 00       	mov    $0x0,%edx
    1326:	66 89 d0             	mov    %dx,%ax
    1329:	66 ba 00 8f          	mov    $0x8f00,%dx
    132d:	a3 08 00 00 00       	mov    %eax,0x8
    1332:	89 15 0c 00 00 00    	mov    %edx,0xc
	set_trap_gate(2,&nmi);
    1338:	ba 00 00 00 00       	mov    $0x0,%edx
    133d:	66 89 d0             	mov    %dx,%ax
    1340:	66 ba 00 8f          	mov    $0x8f00,%dx
    1344:	a3 10 00 00 00       	mov    %eax,0x10
    1349:	89 15 14 00 00 00    	mov    %edx,0x14
	set_system_gate(3,&int3);	/* int3-5 can be called from all */
    134f:	ba 00 00 00 00       	mov    $0x0,%edx
    1354:	66 89 d0             	mov    %dx,%ax
    1357:	66 ba 00 ef          	mov    $0xef00,%dx
    135b:	a3 18 00 00 00       	mov    %eax,0x18
    1360:	89 15 1c 00 00 00    	mov    %edx,0x1c
	set_system_gate(4,&overflow);
    1366:	ba 00 00 00 00       	mov    $0x0,%edx
    136b:	66 89 d0             	mov    %dx,%ax
    136e:	66 ba 00 ef          	mov    $0xef00,%dx
    1372:	a3 20 00 00 00       	mov    %eax,0x20
    1377:	89 15 24 00 00 00    	mov    %edx,0x24
	set_system_gate(5,&bounds);
    137d:	ba 00 00 00 00       	mov    $0x0,%edx
    1382:	66 89 d0             	mov    %dx,%ax
    1385:	66 ba 00 ef          	mov    $0xef00,%dx
    1389:	a3 28 00 00 00       	mov    %eax,0x28
    138e:	89 15 2c 00 00 00    	mov    %edx,0x2c
	set_trap_gate(6,&invalid_op);
    1394:	ba 00 00 00 00       	mov    $0x0,%edx
    1399:	66 89 d0             	mov    %dx,%ax
    139c:	66 ba 00 8f          	mov    $0x8f00,%dx
    13a0:	a3 30 00 00 00       	mov    %eax,0x30
    13a5:	89 15 34 00 00 00    	mov    %edx,0x34
	set_trap_gate(7,&device_not_available);
    13ab:	ba 00 00 00 00       	mov    $0x0,%edx
    13b0:	66 89 d0             	mov    %dx,%ax
    13b3:	66 ba 00 8f          	mov    $0x8f00,%dx
    13b7:	a3 38 00 00 00       	mov    %eax,0x38
    13bc:	89 15 3c 00 00 00    	mov    %edx,0x3c
	set_trap_gate(8,&double_fault);
    13c2:	ba 00 00 00 00       	mov    $0x0,%edx
    13c7:	66 89 d0             	mov    %dx,%ax
    13ca:	66 ba 00 8f          	mov    $0x8f00,%dx
    13ce:	a3 40 00 00 00       	mov    %eax,0x40
    13d3:	89 15 44 00 00 00    	mov    %edx,0x44
	set_trap_gate(9,&coprocessor_segment_overrun);
    13d9:	ba 00 00 00 00       	mov    $0x0,%edx
    13de:	66 89 d0             	mov    %dx,%ax
    13e1:	66 ba 00 8f          	mov    $0x8f00,%dx
    13e5:	a3 48 00 00 00       	mov    %eax,0x48
    13ea:	89 15 4c 00 00 00    	mov    %edx,0x4c
	set_trap_gate(10,&invalid_TSS);
    13f0:	ba 00 00 00 00       	mov    $0x0,%edx
    13f5:	66 89 d0             	mov    %dx,%ax
    13f8:	66 ba 00 8f          	mov    $0x8f00,%dx
    13fc:	a3 50 00 00 00       	mov    %eax,0x50
    1401:	89 15 54 00 00 00    	mov    %edx,0x54
	set_trap_gate(11,&segment_not_present);
    1407:	ba 00 00 00 00       	mov    $0x0,%edx
    140c:	66 89 d0             	mov    %dx,%ax
    140f:	66 ba 00 8f          	mov    $0x8f00,%dx
    1413:	a3 58 00 00 00       	mov    %eax,0x58
    1418:	89 15 5c 00 00 00    	mov    %edx,0x5c
	set_trap_gate(12,&stack_segment);
    141e:	ba 00 00 00 00       	mov    $0x0,%edx
    1423:	66 89 d0             	mov    %dx,%ax
    1426:	66 ba 00 8f          	mov    $0x8f00,%dx
    142a:	a3 60 00 00 00       	mov    %eax,0x60
    142f:	89 15 64 00 00 00    	mov    %edx,0x64
	set_trap_gate(13,&general_protection);
    1435:	ba 00 00 00 00       	mov    $0x0,%edx
    143a:	66 89 d0             	mov    %dx,%ax
    143d:	66 ba 00 8f          	mov    $0x8f00,%dx
    1441:	a3 68 00 00 00       	mov    %eax,0x68
    1446:	89 15 6c 00 00 00    	mov    %edx,0x6c
	set_trap_gate(14,&page_fault);
    144c:	ba 00 00 00 00       	mov    $0x0,%edx
    1451:	66 89 d0             	mov    %dx,%ax
    1454:	66 ba 00 8f          	mov    $0x8f00,%dx
    1458:	a3 70 00 00 00       	mov    %eax,0x70
    145d:	89 15 74 00 00 00    	mov    %edx,0x74
	set_trap_gate(15,&reserved);
    1463:	ba 00 00 00 00       	mov    $0x0,%edx
    1468:	66 89 d0             	mov    %dx,%ax
    146b:	66 ba 00 8f          	mov    $0x8f00,%dx
    146f:	a3 78 00 00 00       	mov    %eax,0x78
    1474:	89 15 7c 00 00 00    	mov    %edx,0x7c
	set_trap_gate(16,&coprocessor_error);
    147a:	ba 00 00 00 00       	mov    $0x0,%edx
    147f:	66 89 d0             	mov    %dx,%ax
    1482:	66 ba 00 8f          	mov    $0x8f00,%dx
    1486:	a3 80 00 00 00       	mov    %eax,0x80
    148b:	89 15 84 00 00 00    	mov    %edx,0x84
    1491:	b9 88 00 00 00       	mov    $0x88,%ecx
    1496:	bb 80 01 00 00       	mov    $0x180,%ebx
	for (i=17;i<48;i++)
		set_trap_gate(i,&reserved);
    149b:	ba 00 00 00 00       	mov    $0x0,%edx
    14a0:	66 89 d0             	mov    %dx,%ax
    14a3:	66 ba 00 8f          	mov    $0x8f00,%dx
    14a7:	89 01                	mov    %eax,(%ecx)
    14a9:	89 51 04             	mov    %edx,0x4(%ecx)
    14ac:	83 c1 08             	add    $0x8,%ecx
	set_trap_gate(12,&stack_segment);
	set_trap_gate(13,&general_protection);
	set_trap_gate(14,&page_fault);
	set_trap_gate(15,&reserved);
	set_trap_gate(16,&coprocessor_error);
	for (i=17;i<48;i++)
    14af:	39 d9                	cmp    %ebx,%ecx
    14b1:	75 ed                	jne    14a0 <trap_init+0x19c>
		set_trap_gate(i,&reserved);
	set_trap_gate(45,&irq13);
    14b3:	b8 00 00 08 00       	mov    $0x80000,%eax
    14b8:	ba 00 00 00 00       	mov    $0x0,%edx
    14bd:	66 89 d0             	mov    %dx,%ax
    14c0:	66 ba 00 8f          	mov    $0x8f00,%dx
    14c4:	a3 68 01 00 00       	mov    %eax,0x168
    14c9:	89 15 6c 01 00 00    	mov    %edx,0x16c
	outb_p(inb_p(0x21)&0xfb,0x21);
    14cf:	ba 21 00 00 00       	mov    $0x21,%edx
    14d4:	ec                   	in     (%dx),%al
    14d5:	eb 00                	jmp    14d7 <trap_init+0x1d3>
    14d7:	eb 00                	jmp    14d9 <trap_init+0x1d5>
    14d9:	25 fb 00 00 00       	and    $0xfb,%eax
    14de:	ee                   	out    %al,(%dx)
    14df:	eb 00                	jmp    14e1 <trap_init+0x1dd>
    14e1:	eb 00                	jmp    14e3 <trap_init+0x1df>
	outb(inb_p(0xA1)&0xdf,0xA1);
    14e3:	ba a1 00 00 00       	mov    $0xa1,%edx
    14e8:	ec                   	in     (%dx),%al
    14e9:	eb 00                	jmp    14eb <trap_init+0x1e7>
    14eb:	eb 00                	jmp    14ed <trap_init+0x1e9>
    14ed:	25 df 00 00 00       	and    $0xdf,%eax
    14f2:	ee                   	out    %al,(%dx)
	set_trap_gate(39,&parallel_interrupt);
    14f3:	b8 00 00 08 00       	mov    $0x80000,%eax
    14f8:	ba 00 00 00 00       	mov    $0x0,%edx
    14fd:	66 89 d0             	mov    %dx,%ax
    1500:	66 ba 00 8f          	mov    $0x8f00,%dx
    1504:	a3 38 01 00 00       	mov    %eax,0x138
    1509:	89 15 3c 01 00 00    	mov    %edx,0x13c
}
    150f:	5b                   	pop    %ebx
    1510:	c3                   	ret    

00001511 <ipi_intr_init>:

void parse_cpu_topology(void);
void handle_ipi_interrupt(void);
void ipi_intr_init(void)
{
	set_intr_gate(0x81,&parse_cpu_topology); /* 解析CPU的拓扑结构，例如有几个core，每个core是否支持HT */
    1511:	b8 00 00 08 00       	mov    $0x80000,%eax
    1516:	ba 00 00 00 00       	mov    $0x0,%edx
    151b:	66 89 d0             	mov    %dx,%ax
    151e:	66 ba 00 8e          	mov    $0x8e00,%dx
    1522:	a3 08 04 00 00       	mov    %eax,0x408
    1527:	89 15 0c 04 00 00    	mov    %edx,0x40c
	set_intr_gate(0x82,&handle_ipi_interrupt);
    152d:	ba 00 00 00 00       	mov    $0x0,%edx
    1532:	66 89 d0             	mov    %dx,%ax
    1535:	66 ba 00 8e          	mov    $0x8e00,%dx
    1539:	a3 10 04 00 00       	mov    %eax,0x410
    153e:	89 15 14 04 00 00    	mov    %edx,0x414
    1544:	c3                   	ret    

00001545 <divide_error>:
    1545:	68 00 00 00 00       	push   $0x0

0000154a <no_error_code>:
    154a:	87 04 24             	xchg   %eax,(%esp)
    154d:	53                   	push   %ebx
    154e:	51                   	push   %ecx
    154f:	52                   	push   %edx
    1550:	57                   	push   %edi
    1551:	56                   	push   %esi
    1552:	55                   	push   %ebp
    1553:	1e                   	push   %ds
    1554:	06                   	push   %es
    1555:	0f a0                	push   %fs
    1557:	6a 00                	push   $0x0
    1559:	8d 54 24 2c          	lea    0x2c(%esp),%edx
    155d:	52                   	push   %edx
    155e:	ba 10 00 00 00       	mov    $0x10,%edx
    1563:	8e da                	mov    %edx,%ds
    1565:	8e c2                	mov    %edx,%es
    1567:	8e e2                	mov    %edx,%fs
    1569:	ff d0                	call   *%eax
    156b:	83 c4 08             	add    $0x8,%esp
    156e:	0f a1                	pop    %fs
    1570:	07                   	pop    %es
    1571:	1f                   	pop    %ds
    1572:	5d                   	pop    %ebp
    1573:	5e                   	pop    %esi
    1574:	5f                   	pop    %edi
    1575:	5a                   	pop    %edx
    1576:	59                   	pop    %ecx
    1577:	5b                   	pop    %ebx
    1578:	58                   	pop    %eax
    1579:	cf                   	iret   

0000157a <debug>:
    157a:	68 00 00 00 00       	push   $0x0
    157f:	eb c9                	jmp    154a <no_error_code>

00001581 <nmi>:
    1581:	68 00 00 00 00       	push   $0x0
    1586:	eb c2                	jmp    154a <no_error_code>

00001588 <int3>:
    1588:	68 00 00 00 00       	push   $0x0
    158d:	eb bb                	jmp    154a <no_error_code>

0000158f <overflow>:
    158f:	68 00 00 00 00       	push   $0x0
    1594:	eb b4                	jmp    154a <no_error_code>

00001596 <bounds>:
    1596:	68 00 00 00 00       	push   $0x0
    159b:	eb ad                	jmp    154a <no_error_code>

0000159d <invalid_op>:
    159d:	68 00 00 00 00       	push   $0x0
    15a2:	eb a6                	jmp    154a <no_error_code>

000015a4 <coprocessor_segment_overrun>:
    15a4:	68 00 00 00 00       	push   $0x0
    15a9:	eb 9f                	jmp    154a <no_error_code>

000015ab <reserved>:
    15ab:	68 00 00 00 00       	push   $0x0
    15b0:	eb 98                	jmp    154a <no_error_code>

000015b2 <irq13>:
    15b2:	50                   	push   %eax
    15b3:	30 c0                	xor    %al,%al
    15b5:	e6 f0                	out    %al,$0xf0
    15b7:	b0 20                	mov    $0x20,%al
    15b9:	e6 20                	out    %al,$0x20
    15bb:	eb 00                	jmp    15bd <irq13+0xb>
    15bd:	eb 00                	jmp    15bf <irq13+0xd>
    15bf:	e6 a0                	out    %al,$0xa0
    15c1:	58                   	pop    %eax
    15c2:	e9 fc ff ff ff       	jmp    15c3 <irq13+0x11>

000015c7 <double_fault>:
    15c7:	68 00 00 00 00       	push   $0x0

000015cc <error_code>:
    15cc:	87 44 24 04          	xchg   %eax,0x4(%esp)
    15d0:	87 1c 24             	xchg   %ebx,(%esp)
    15d3:	51                   	push   %ecx
    15d4:	52                   	push   %edx
    15d5:	57                   	push   %edi
    15d6:	56                   	push   %esi
    15d7:	55                   	push   %ebp
    15d8:	1e                   	push   %ds
    15d9:	06                   	push   %es
    15da:	0f a0                	push   %fs
    15dc:	50                   	push   %eax
    15dd:	8d 44 24 2c          	lea    0x2c(%esp),%eax
    15e1:	50                   	push   %eax
    15e2:	b8 10 00 00 00       	mov    $0x10,%eax
    15e7:	8e d8                	mov    %eax,%ds
    15e9:	8e c0                	mov    %eax,%es
    15eb:	8e e0                	mov    %eax,%fs
    15ed:	ff d3                	call   *%ebx
    15ef:	83 c4 08             	add    $0x8,%esp
    15f2:	0f a1                	pop    %fs
    15f4:	07                   	pop    %es
    15f5:	1f                   	pop    %ds
    15f6:	5d                   	pop    %ebp
    15f7:	5e                   	pop    %esi
    15f8:	5f                   	pop    %edi
    15f9:	5a                   	pop    %edx
    15fa:	59                   	pop    %ecx
    15fb:	5b                   	pop    %ebx
    15fc:	58                   	pop    %eax
    15fd:	cf                   	iret   

000015fe <invalid_TSS>:
    15fe:	68 00 00 00 00       	push   $0x0
    1603:	eb c7                	jmp    15cc <error_code>

00001605 <segment_not_present>:
    1605:	68 00 00 00 00       	push   $0x0
    160a:	eb c0                	jmp    15cc <error_code>

0000160c <stack_segment>:
    160c:	68 00 00 00 00       	push   $0x0
    1611:	eb b9                	jmp    15cc <error_code>

00001613 <general_protection>:
    1613:	68 00 00 00 00       	push   $0x0
    1618:	eb b2                	jmp    15cc <error_code>

0000161a <verify_area>:


extern void write_verify(unsigned long address);
long last_pid = 0;

void verify_area(void * addr, int size) {
    161a:	56                   	push   %esi
    161b:	53                   	push   %ebx
    161c:	83 ec 04             	sub    $0x4,%esp
    161f:	8b 5c 24 10          	mov    0x10(%esp),%ebx
	struct task_struct* current = get_current_task();
    1623:	e8 fc ff ff ff       	call   1624 <verify_area+0xa>
	unsigned long start;

	start = (unsigned long) addr;
	size += start & 0xfff;               /* 计算该地址的页内offset */
    1628:	89 d9                	mov    %ebx,%ecx
    162a:	81 e1 ff 0f 00 00    	and    $0xfff,%ecx
    1630:	03 4c 24 14          	add    0x14(%esp),%ecx
	start &= 0xfffff000;                 /* 计算该地址在进程地址空间内的页帧号，其实也是个offset，4K align */
    1634:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	start += get_base(current->ldt[2]);  /* 页帧号+进程地址空间base=CPU线性地址, 4k align */
    163a:	50                   	push   %eax
    163b:	05 e0 02 00 00       	add    $0x2e0,%eax
    1640:	83 c0 07             	add    $0x7,%eax
    1643:	8a 30                	mov    (%eax),%dh
    1645:	83 e8 03             	sub    $0x3,%eax
    1648:	8a 10                	mov    (%eax),%dl
    164a:	c1 e2 10             	shl    $0x10,%edx
    164d:	83 e8 02             	sub    $0x2,%eax
    1650:	66 8b 10             	mov    (%eax),%dx
    1653:	58                   	pop    %eax
    1654:	01 d3                	add    %edx,%ebx
	while (size > 0) {
    1656:	85 c9                	test   %ecx,%ecx
    1658:	7e 26                	jle    1680 <verify_area+0x66>
    165a:	83 e9 01             	sub    $0x1,%ecx
    165d:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
    1663:	8d b4 0b 00 10 00 00 	lea    0x1000(%ebx,%ecx,1),%esi
		size -= 4096;
		write_verify(start);
    166a:	83 ec 0c             	sub    $0xc,%esp
    166d:	53                   	push   %ebx
    166e:	e8 fc ff ff ff       	call   166f <verify_area+0x55>
		start += 4096;                   /* 跳到下一页继续verify了 */
    1673:	81 c3 00 10 00 00    	add    $0x1000,%ebx

	start = (unsigned long) addr;
	size += start & 0xfff;               /* 计算该地址的页内offset */
	start &= 0xfffff000;                 /* 计算该地址在进程地址空间内的页帧号，其实也是个offset，4K align */
	start += get_base(current->ldt[2]);  /* 页帧号+进程地址空间base=CPU线性地址, 4k align */
	while (size > 0) {
    1679:	83 c4 10             	add    $0x10,%esp
    167c:	39 f3                	cmp    %esi,%ebx
    167e:	75 ea                	jne    166a <verify_area+0x50>
		size -= 4096;
		write_verify(start);
		start += 4096;                   /* 跳到下一页继续verify了 */
	}
}
    1680:	83 c4 04             	add    $0x4,%esp
    1683:	5b                   	pop    %ebx
    1684:	5e                   	pop    %esi
    1685:	c3                   	ret    

00001686 <copy_mem>:

int copy_mem(int nr, struct task_struct * p) {
    1686:	53                   	push   %ebx
    1687:	83 ec 08             	sub    $0x8,%esp
    168a:	8b 5c 24 14          	mov    0x14(%esp),%ebx

	/* 所有fork出来的进程的基地址和limit都是一样，所以到这你应该理解当所有进程都有相同的4G地址空间的时候，在GDT表中只需要一个LDT描述符即可，但进程的TSS还是每个进程私有的。 */
	new_data_base = new_code_base = USER_LINEAR_ADDR_START;
	code_limit = data_limit = USER_LINEAR_ADDR_LIMIT;

	p->start_code = new_code_base;
    168e:	c7 83 18 02 00 00 00 	movl   $0x40000000,0x218(%ebx)
    1695:	00 00 40 
	set_base(p->ldt[1], new_code_base);
    1698:	ba 00 00 00 40       	mov    $0x40000000,%edx
    169d:	66 89 93 da 02 00 00 	mov    %dx,0x2da(%ebx)
    16a4:	c1 ca 10             	ror    $0x10,%edx
    16a7:	88 93 dc 02 00 00    	mov    %dl,0x2dc(%ebx)
    16ad:	88 b3 df 02 00 00    	mov    %dh,0x2df(%ebx)
    16b3:	c1 ca 10             	ror    $0x10,%edx
	set_base(p->ldt[2], new_data_base);
    16b6:	66 89 93 e2 02 00 00 	mov    %dx,0x2e2(%ebx)
    16bd:	c1 ca 10             	ror    $0x10,%edx
    16c0:	88 93 e4 02 00 00    	mov    %dl,0x2e4(%ebx)
    16c6:	88 b3 e7 02 00 00    	mov    %dh,0x2e7(%ebx)
    16cc:	c1 ca 10             	ror    $0x10,%edx
	set_limit(p->ldt[1], data_limit);
    16cf:	ba ff ff 0b 00       	mov    $0xbffff,%edx
    16d4:	66 89 93 d8 02 00 00 	mov    %dx,0x2d8(%ebx)
    16db:	c1 ca 10             	ror    $0x10,%edx
    16de:	8a b3 de 02 00 00    	mov    0x2de(%ebx),%dh
    16e4:	80 e6 f0             	and    $0xf0,%dh
    16e7:	08 f2                	or     %dh,%dl
    16e9:	88 93 de 02 00 00    	mov    %dl,0x2de(%ebx)
    16ef:	c1 ca 10             	ror    $0x10,%edx
	set_limit(p->ldt[2], data_limit);
    16f2:	66 89 93 e0 02 00 00 	mov    %dx,0x2e0(%ebx)
    16f9:	c1 ca 10             	ror    $0x10,%edx
    16fc:	8a b3 e6 02 00 00    	mov    0x2e6(%ebx),%dh
    1702:	80 e6 f0             	and    $0xf0,%dh
    1705:	08 f2                	or     %dh,%dl
    1707:	88 93 e6 02 00 00    	mov    %dl,0x2e6(%ebx)
    170d:	c1 ca 10             	ror    $0x10,%edx
#if 1
	if (copy_page_tables(old_data_base, new_data_base, data_limit, p)) {
    1710:	53                   	push   %ebx
    1711:	68 00 00 00 c0       	push   $0xc0000000
    1716:	68 00 00 00 40       	push   $0x40000000
    171b:	6a 00                	push   $0x0
    171d:	e8 fc ff ff ff       	call   171e <copy_mem+0x98>
    1722:	83 c4 10             	add    $0x10,%esp
    1725:	85 c0                	test   %eax,%eax
    1727:	74 1b                	je     1744 <copy_mem+0xbe>
		//printk("copy_mem call free_page_tables before\n\r");
		free_page_tables(new_data_base, data_limit,p);
    1729:	83 ec 04             	sub    $0x4,%esp
    172c:	53                   	push   %ebx
    172d:	68 00 00 00 c0       	push   $0xc0000000
    1732:	68 00 00 00 40       	push   $0x40000000
    1737:	e8 fc ff ff ff       	call   1738 <copy_mem+0xb2>
		//printk("copy_mem call free_page_tables after\n\r");
		return -ENOMEM;
    173c:	83 c4 10             	add    $0x10,%esp
    173f:	b8 f4 ff ff ff       	mov    $0xfffffff4,%eax
#else
	p->tss.cr3 = get_no_init_free_page(PAGE_IN_REAL_MEM_MAP);  /* 为新进程分配一页物理内存用于存储目录表 */
	printk("new_dir=%08x\n\r",p->tss.cr3);
#endif
	return 0;
}
    1744:	83 c4 08             	add    $0x8,%esp
    1747:	5b                   	pop    %ebx
    1748:	c3                   	ret    

00001749 <copy_process>:
 * 解释一下这些参数: 它们都是用户态参数，都要保存到tss中的，这样在任务切换的时候，就执行父进程的代码了，而且是fork函数中int80的后一条指令，
 * 所以，切换到子进程执行的时候，子进程是在用户态下执行的.
 */
int copy_process(int nr, long ebp, long edi, long esi, long gs, long none,
		long ebx, long ecx, long edx, long fs, long es, long ds, long eip,
		long cs, long eflags, long esp, long ss) {
    1749:	55                   	push   %ebp
    174a:	57                   	push   %edi
    174b:	56                   	push   %esi
    174c:	53                   	push   %ebx
    174d:	83 ec 1c             	sub    $0x1c,%esp

	struct task_struct* current = get_current_task();
    1750:	e8 fc ff ff ff       	call   1751 <copy_process+0x8>
    1755:	89 c5                	mov    %eax,%ebp
	printk("current: %p, eflags: %08x, nr=%08x\n\r", current, eflags,nr);
    1757:	ff 74 24 30          	pushl  0x30(%esp)
    175b:	ff 74 24 6c          	pushl  0x6c(%esp)
    175f:	50                   	push   %eax
    1760:	68 48 01 00 00       	push   $0x148
    1765:	e8 fc ff ff ff       	call   1766 <copy_process+0x1d>
	current->tss.eflags = eflags;
    176a:	8b 44 24 78          	mov    0x78(%esp),%eax
    176e:	89 85 0c 03 00 00    	mov    %eax,0x30c(%ebp)
	struct task_struct *p = task[nr];
    1774:	8b 44 24 40          	mov    0x40(%esp),%eax
    1778:	8b 1c 85 00 00 00 00 	mov    0x0(,%eax,4),%ebx
	int i;
	struct file *f;
    /* 此版本将进程的task_struct和目录表都分配在内核实地址寻址的空间(mem>512M && mem<(512-64)M) */
	if (!p)
    177f:	83 c4 10             	add    $0x10,%esp
    1782:	85 db                	test   %ebx,%ebx
    1784:	0f 84 0b 03 00 00    	je     1a95 <copy_process+0x34c>
		return -EAGAIN;
	long pid = p->pid;   /* 现将新分配的PID保存起来 */
    178a:	8b 83 2c 02 00 00    	mov    0x22c(%ebx),%eax
    1790:	89 44 24 0c          	mov    %eax,0xc(%esp)

	lock_op(&sched_semaphore);
    1794:	83 ec 0c             	sub    $0xc,%esp
    1797:	68 00 00 00 00       	push   $0x0
    179c:	e8 fc ff ff ff       	call   179d <copy_process+0x54>
	/*
	 * 这也是个巨坑啊
	 * 这里一定要在copy操作之前先获得schedule的锁,这样确保在COPY老任务的时候,如果将新任务的state设置为running时,也不会被调度.
	 *  */
	*p = *current; /* NOTE! this doesn't copy the supervisor stack */
    17a1:	b9 f3 00 00 00       	mov    $0xf3,%ecx
    17a6:	89 df                	mov    %ebx,%edi
    17a8:	89 ee                	mov    %ebp,%esi
    17aa:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	p->state = TASK_UNINTERRUPTIBLE;
    17ac:	c7 03 02 00 00 00    	movl   $0x2,(%ebx)
    p->executed = 0;  /* 这里一定要设置为还没执行过，因为其父进程肯定都是执行过的 */
    17b2:	c7 83 c8 03 00 00 00 	movl   $0x0,0x3c8(%ebx)
    17b9:	00 00 00 
	unlock_op(&sched_semaphore);
    17bc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
    17c3:	e8 fc ff ff ff       	call   17c4 <copy_process+0x7b>

	p->task_nr = nr;
    17c8:	8b 74 24 40          	mov    0x40(%esp),%esi
    17cc:	89 b3 c0 03 00 00    	mov    %esi,0x3c0(%ebx)
	p->father_nr = current->task_nr;
    17d2:	8b 85 c0 03 00 00    	mov    0x3c0(%ebp),%eax
    17d8:	89 83 c4 03 00 00    	mov    %eax,0x3c4(%ebx)
	p->sched_on_ap = 0; /* 这里是自己埋的最后一个大坑，如果在AP上运行的task调用fork的话，其子进程的sched_on_ap肯定等于1了，这样它就永远不能被BSP调度运行 */
    17de:	c7 83 bc 03 00 00 00 	movl   $0x0,0x3bc(%ebx)
    17e5:	00 00 00 
	p->pid = pid;
    17e8:	8b 44 24 1c          	mov    0x1c(%esp),%eax
    17ec:	89 83 2c 02 00 00    	mov    %eax,0x22c(%ebx)
	p->father = current->pid;
    17f2:	8b 85 2c 02 00 00    	mov    0x22c(%ebp),%eax
    17f8:	89 83 30 02 00 00    	mov    %eax,0x230(%ebx)
	p->counter = p->priority;
    17fe:	8b 43 08             	mov    0x8(%ebx),%eax
    1801:	89 43 04             	mov    %eax,0x4(%ebx)
	p->signal = 0;
    1804:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
	p->alarm = 0;
    180b:	c7 83 4c 02 00 00 00 	movl   $0x0,0x24c(%ebx)
    1812:	00 00 00 
	p->leader = 0;                       /* process leadership doesn't inherit */
    1815:	c7 83 3c 02 00 00 00 	movl   $0x0,0x23c(%ebx)
    181c:	00 00 00 
	p->utime = p->stime = 0;
    181f:	c7 83 54 02 00 00 00 	movl   $0x0,0x254(%ebx)
    1826:	00 00 00 
    1829:	c7 83 50 02 00 00 00 	movl   $0x0,0x250(%ebx)
    1830:	00 00 00 
	p->cutime = p->cstime = 0;
    1833:	c7 83 5c 02 00 00 00 	movl   $0x0,0x25c(%ebx)
    183a:	00 00 00 
    183d:	c7 83 58 02 00 00 00 	movl   $0x0,0x258(%ebx)
    1844:	00 00 00 
	p->start_time = jiffies;
    1847:	a1 00 00 00 00       	mov    0x0,%eax
    184c:	89 83 60 02 00 00    	mov    %eax,0x260(%ebx)
	p->tss.back_link = 0;
    1852:	c7 83 e8 02 00 00 00 	movl   $0x0,0x2e8(%ebx)
    1859:	00 00 00 
	p->tss.esp0 = PAGE_SIZE + (long) p;
    185c:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
    1862:	89 83 ec 02 00 00    	mov    %eax,0x2ec(%ebx)
	p->tss.ss0 = 0x10;
    1868:	c7 83 f0 02 00 00 10 	movl   $0x10,0x2f0(%ebx)
    186f:	00 00 00 
	p->tss.eip = eip;
    1872:	8b 44 24 70          	mov    0x70(%esp),%eax
    1876:	89 83 08 03 00 00    	mov    %eax,0x308(%ebx)
	p->tss.eflags = eflags;
    187c:	8b 44 24 78          	mov    0x78(%esp),%eax
    1880:	89 83 0c 03 00 00    	mov    %eax,0x30c(%ebx)
	p->tss.eax = 0;                   /* fork返回值是0的话，代表运行的是子进程，奥秘就在这里哈哈 */
    1886:	c7 83 10 03 00 00 00 	movl   $0x0,0x310(%ebx)
    188d:	00 00 00 
	p->tss.ecx = ecx;
    1890:	8b 44 24 5c          	mov    0x5c(%esp),%eax
    1894:	89 83 14 03 00 00    	mov    %eax,0x314(%ebx)
	p->tss.edx = edx;
    189a:	8b 44 24 60          	mov    0x60(%esp),%eax
    189e:	89 83 18 03 00 00    	mov    %eax,0x318(%ebx)
	p->tss.ebx = ebx;
    18a4:	8b 44 24 58          	mov    0x58(%esp),%eax
    18a8:	89 83 1c 03 00 00    	mov    %eax,0x31c(%ebx)
	p->tss.esp = esp;
    18ae:	8b 44 24 7c          	mov    0x7c(%esp),%eax
    18b2:	89 83 20 03 00 00    	mov    %eax,0x320(%ebx)
	p->tss.ebp = ebp;
    18b8:	8b 44 24 44          	mov    0x44(%esp),%eax
    18bc:	89 83 24 03 00 00    	mov    %eax,0x324(%ebx)
	p->tss.esi = esi;
    18c2:	8b 44 24 4c          	mov    0x4c(%esp),%eax
    18c6:	89 83 28 03 00 00    	mov    %eax,0x328(%ebx)
	p->tss.edi = edi;
    18cc:	8b 44 24 48          	mov    0x48(%esp),%eax
    18d0:	89 83 2c 03 00 00    	mov    %eax,0x32c(%ebx)
	p->tss.es = es & 0xffff;
    18d6:	0f b7 44 24 68       	movzwl 0x68(%esp),%eax
    18db:	89 83 30 03 00 00    	mov    %eax,0x330(%ebx)
	p->tss.cs = cs & 0xffff;
    18e1:	0f b7 44 24 74       	movzwl 0x74(%esp),%eax
    18e6:	89 83 34 03 00 00    	mov    %eax,0x334(%ebx)
	p->tss.ss = ss & 0xffff;
    18ec:	0f b7 84 24 80 00 00 	movzwl 0x80(%esp),%eax
    18f3:	00 
    18f4:	89 83 38 03 00 00    	mov    %eax,0x338(%ebx)
	p->tss.ds = ds & 0xffff;
    18fa:	0f b7 44 24 6c       	movzwl 0x6c(%esp),%eax
    18ff:	89 83 3c 03 00 00    	mov    %eax,0x33c(%ebx)
	p->tss.fs = fs & 0xffff;
    1905:	0f b7 44 24 64       	movzwl 0x64(%esp),%eax
    190a:	89 83 40 03 00 00    	mov    %eax,0x340(%ebx)
	p->tss.gs = gs & 0xffff;
    1910:	0f b7 44 24 50       	movzwl 0x50(%esp),%eax
    1915:	89 83 44 03 00 00    	mov    %eax,0x344(%ebx)
	p->tss.ldt = _LDT(nr);             /* 注意：这里的ldt存储的是LDT表存储在GDT表中的选择符。 */
    191b:	89 f0                	mov    %esi,%eax
    191d:	c1 e0 04             	shl    $0x4,%eax
    1920:	83 c0 28             	add    $0x28,%eax
    1923:	89 83 48 03 00 00    	mov    %eax,0x348(%ebx)
	p->tss.trace_bitmap = 0x80000000;
    1929:	c7 83 4c 03 00 00 00 	movl   $0x80000000,0x34c(%ebx)
    1930:	00 00 80 
	if (last_task_used_math == current)
    1933:	83 c4 10             	add    $0x10,%esp
    1936:	3b 2d 00 00 00 00    	cmp    0x0,%ebp
    193c:	75 08                	jne    1946 <copy_process+0x1fd>
		__asm__("clts ; fnsave %0"::"m" (p->tss.i387));
    193e:	0f 06                	clts   
    1940:	dd b3 50 03 00 00    	fnsave 0x350(%ebx)
	if (copy_mem(nr, p)) {
    1946:	83 ec 08             	sub    $0x8,%esp
    1949:	53                   	push   %ebx
    194a:	ff 74 24 3c          	pushl  0x3c(%esp)
    194e:	e8 fc ff ff ff       	call   194f <copy_process+0x206>
    1953:	83 c4 10             	add    $0x10,%esp
    1956:	85 c0                	test   %eax,%eax
    1958:	74 44                	je     199e <copy_process+0x255>
		task[nr] = NULL;
    195a:	8b 44 24 30          	mov    0x30(%esp),%eax
    195e:	c7 04 85 00 00 00 00 	movl   $0x0,0x0(,%eax,4)
    1965:	00 00 00 00 
		if (!free_page((long)p))
    1969:	83 ec 0c             	sub    $0xc,%esp
    196c:	53                   	push   %ebx
    196d:	e8 fc ff ff ff       	call   196e <copy_process+0x225>
    1972:	89 c2                	mov    %eax,%edx
    1974:	83 c4 10             	add    $0x10,%esp
			panic("fork.copy_process: trying to free free page");
		return -EAGAIN;
    1977:	b8 f5 ff ff ff       	mov    $0xfffffff5,%eax
	p->tss.trace_bitmap = 0x80000000;
	if (last_task_used_math == current)
		__asm__("clts ; fnsave %0"::"m" (p->tss.i387));
	if (copy_mem(nr, p)) {
		task[nr] = NULL;
		if (!free_page((long)p))
    197c:	85 d2                	test   %edx,%edx
    197e:	0f 85 16 01 00 00    	jne    1a9a <copy_process+0x351>
			panic("fork.copy_process: trying to free free page");
    1984:	83 ec 0c             	sub    $0xc,%esp
    1987:	68 70 01 00 00       	push   $0x170
    198c:	e8 fc ff ff ff       	call   198d <copy_process+0x244>
    1991:	83 c4 10             	add    $0x10,%esp
		return -EAGAIN;
    1994:	b8 f5 ff ff ff       	mov    $0xfffffff5,%eax
    1999:	e9 fc 00 00 00       	jmp    1a9a <copy_process+0x351>
	}

	/* 共享的inode节点一定要同步 */
	lock_op(&copy_process_semaphore);
    199e:	83 ec 0c             	sub    $0xc,%esp
    19a1:	68 00 00 00 00       	push   $0x0
    19a6:	e8 fc ff ff ff       	call   19a7 <copy_process+0x25e>
    19ab:	8d 83 80 02 00 00    	lea    0x280(%ebx),%eax
    19b1:	8d 8b d0 02 00 00    	lea    0x2d0(%ebx),%ecx
    19b7:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < NR_OPEN; i++)
		if (f = p->filp[i])
    19ba:	8b 10                	mov    (%eax),%edx
    19bc:	85 d2                	test   %edx,%edx
    19be:	74 05                	je     19c5 <copy_process+0x27c>
			f->f_count++;
    19c0:	66 83 42 04 01       	addw   $0x1,0x4(%edx)
    19c5:	83 c0 04             	add    $0x4,%eax
		return -EAGAIN;
	}

	/* 共享的inode节点一定要同步 */
	lock_op(&copy_process_semaphore);
	for (i = 0; i < NR_OPEN; i++)
    19c8:	39 c8                	cmp    %ecx,%eax
    19ca:	75 ee                	jne    19ba <copy_process+0x271>
		if (f = p->filp[i])
			f->f_count++;
	if (current->pwd)
    19cc:	8b 85 70 02 00 00    	mov    0x270(%ebp),%eax
    19d2:	85 c0                	test   %eax,%eax
    19d4:	74 05                	je     19db <copy_process+0x292>
		current->pwd->i_count++;
    19d6:	66 83 40 30 01       	addw   $0x1,0x30(%eax)
	if (current->root)
    19db:	8b 85 74 02 00 00    	mov    0x274(%ebp),%eax
    19e1:	85 c0                	test   %eax,%eax
    19e3:	74 05                	je     19ea <copy_process+0x2a1>
		current->root->i_count++;
    19e5:	66 83 40 30 01       	addw   $0x1,0x30(%eax)
	if (current->executable)
    19ea:	8b 85 78 02 00 00    	mov    0x278(%ebp),%eax
    19f0:	85 c0                	test   %eax,%eax
    19f2:	74 05                	je     19f9 <copy_process+0x2b0>
		current->executable->i_count++;
    19f4:	66 83 40 30 01       	addw   $0x1,0x30(%eax)
	unlock_op(&copy_process_semaphore);
    19f9:	83 ec 0c             	sub    $0xc,%esp
    19fc:	68 00 00 00 00       	push   $0x0
    1a01:	e8 fc ff ff ff       	call   1a02 <copy_process+0x2b9>

	set_tss_desc(gdt+(nr<<1)+FIRST_TSS_ENTRY, &(p->tss));
    1a06:	8b 44 24 40          	mov    0x40(%esp),%eax
    1a0a:	8d 54 00 04          	lea    0x4(%eax,%eax,1),%edx
    1a0e:	8d 83 e8 02 00 00    	lea    0x2e8(%ebx),%eax
    1a14:	66 c7 04 d5 00 00 00 	movw   $0x68,0x0(,%edx,8)
    1a1b:	00 68 00 
    1a1e:	66 89 04 d5 02 00 00 	mov    %ax,0x2(,%edx,8)
    1a25:	00 
    1a26:	c1 c8 10             	ror    $0x10,%eax
    1a29:	88 04 d5 04 00 00 00 	mov    %al,0x4(,%edx,8)
    1a30:	c6 04 d5 05 00 00 00 	movb   $0x89,0x5(,%edx,8)
    1a37:	89 
    1a38:	c6 04 d5 06 00 00 00 	movb   $0x0,0x6(,%edx,8)
    1a3f:	00 
    1a40:	88 24 d5 07 00 00 00 	mov    %ah,0x7(,%edx,8)
    1a47:	c1 c8 10             	ror    $0x10,%eax
	set_ldt_desc(gdt+(nr<<1)+FIRST_LDT_ENTRY, &(p->ldt));
    1a4a:	8d 83 d0 02 00 00    	lea    0x2d0(%ebx),%eax
    1a50:	66 c7 04 d5 08 00 00 	movw   $0x68,0x8(,%edx,8)
    1a57:	00 68 00 
    1a5a:	66 89 04 d5 0a 00 00 	mov    %ax,0xa(,%edx,8)
    1a61:	00 
    1a62:	c1 c8 10             	ror    $0x10,%eax
    1a65:	88 04 d5 0c 00 00 00 	mov    %al,0xc(,%edx,8)
    1a6c:	c6 04 d5 0d 00 00 00 	movb   $0x82,0xd(,%edx,8)
    1a73:	82 
    1a74:	c6 04 d5 0e 00 00 00 	movb   $0x0,0xe(,%edx,8)
    1a7b:	00 
    1a7c:	88 24 d5 0f 00 00 00 	mov    %ah,0xf(,%edx,8)
    1a83:	c1 c8 10             	ror    $0x10,%eax
	p->state = TASK_RUNNING; /* do this last, just in case */
    1a86:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)

	return pid;  /* 这时的子进程ID不能用last_pid了 */
    1a8c:	83 c4 10             	add    $0x10,%esp
    1a8f:	8b 44 24 0c          	mov    0xc(%esp),%eax
    1a93:	eb 05                	jmp    1a9a <copy_process+0x351>
	struct task_struct *p = task[nr];
	int i;
	struct file *f;
    /* 此版本将进程的task_struct和目录表都分配在内核实地址寻址的空间(mem>512M && mem<(512-64)M) */
	if (!p)
		return -EAGAIN;
    1a95:	b8 f5 ff ff ff       	mov    $0xfffffff5,%eax
	set_tss_desc(gdt+(nr<<1)+FIRST_TSS_ENTRY, &(p->tss));
	set_ldt_desc(gdt+(nr<<1)+FIRST_LDT_ENTRY, &(p->ldt));
	p->state = TASK_RUNNING; /* do this last, just in case */

	return pid;  /* 这时的子进程ID不能用last_pid了 */
}
    1a9a:	83 c4 1c             	add    $0x1c,%esp
    1a9d:	5b                   	pop    %ebx
    1a9e:	5e                   	pop    %esi
    1a9f:	5f                   	pop    %edi
    1aa0:	5d                   	pop    %ebp
    1aa1:	c3                   	ret    

00001aa2 <find_empty_process>:

int find_empty_process(void) {
    1aa2:	56                   	push   %esi
    1aa3:	53                   	push   %ebx
    1aa4:	83 ec 10             	sub    $0x10,%esp
	lock_op(&find_empty_process_semaphore);
    1aa7:	68 00 00 00 00       	push   $0x0
    1aac:	e8 fc ff ff ff       	call   1aad <find_empty_process+0xb>
    1ab1:	8b 0d 00 00 00 00    	mov    0x0,%ecx
    1ab7:	83 c4 10             	add    $0x10,%esp
	int lock_flag = 1;
	int i;

	repeat: if ((++last_pid) < 0)
		last_pid = 1;
    1aba:	be 01 00 00 00       	mov    $0x1,%esi
    1abf:	bb 00 01 00 00       	mov    $0x100,%ebx
int find_empty_process(void) {
	lock_op(&find_empty_process_semaphore);
	int lock_flag = 1;
	int i;

	repeat: if ((++last_pid) < 0)
    1ac4:	83 c1 01             	add    $0x1,%ecx
		last_pid = 1;
    1ac7:	0f 48 ce             	cmovs  %esi,%ecx
    1aca:	b8 00 00 00 00       	mov    $0x0,%eax
	for (i = 0; i < NR_TASKS; i++)
		if (task[i]) {
    1acf:	8b 10                	mov    (%eax),%edx
    1ad1:	85 d2                	test   %edx,%edx
    1ad3:	74 08                	je     1add <find_empty_process+0x3b>
			if (task[i]->pid == last_pid)
    1ad5:	39 8a 2c 02 00 00    	cmp    %ecx,0x22c(%edx)
    1adb:	74 e7                	je     1ac4 <find_empty_process+0x22>
    1add:	83 c0 04             	add    $0x4,%eax
	int lock_flag = 1;
	int i;

	repeat: if ((++last_pid) < 0)
		last_pid = 1;
	for (i = 0; i < NR_TASKS; i++)
    1ae0:	39 c3                	cmp    %eax,%ebx
    1ae2:	75 eb                	jne    1acf <find_empty_process+0x2d>
    1ae4:	89 0d 00 00 00 00    	mov    %ecx,0x0
			if (task[i]->pid == last_pid)
				goto repeat;
		}

	for (i = 1; i < NR_TASKS; i++) {
		if (!task[i]) {
    1aea:	83 3d 04 00 00 00 00 	cmpl   $0x0,0x4
    1af1:	74 11                	je     1b04 <find_empty_process+0x62>
    1af3:	bb 02 00 00 00       	mov    $0x2,%ebx
    1af8:	83 3c 9d 00 00 00 00 	cmpl   $0x0,0x0(,%ebx,4)
    1aff:	00 
    1b00:	75 3d                	jne    1b3f <find_empty_process+0x9d>
    1b02:	eb 05                	jmp    1b09 <find_empty_process+0x67>
    1b04:	bb 01 00 00 00       	mov    $0x1,%ebx
			/* 多进程并发的时候,这里要先分配一页,起到站位的作用,否则会两个进程共用一个NR. */
			struct task_struct* task_page = (struct task_struct *) get_free_page(PAGE_IN_REAL_MEM_MAP);
    1b09:	83 ec 0c             	sub    $0xc,%esp
    1b0c:	6a 01                	push   $0x1
    1b0e:	e8 fc ff ff ff       	call   1b0f <find_empty_process+0x6d>
			/* 这里一定要先设置任务的状态为不可中断状态,因为默认的是running状态,一旦赋值给task[nr],schedule就能调度运行了
			 * 但是这时相应的任务状态信息还没有设置,所以会报错,这是个大坑啊
			 *  */
			task_page->state = TASK_UNINTERRUPTIBLE;
    1b13:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
			task_page->pid = last_pid;  /* 这里要设置PID,否则后面进程并发会造成多个进程共用同一个PID */
    1b19:	8b 15 00 00 00 00    	mov    0x0,%edx
    1b1f:	89 90 2c 02 00 00    	mov    %edx,0x22c(%eax)
			task[i] = task_page;        /* 这样就确保任务此时,是不会被调度的. */
    1b25:	89 04 9d 00 00 00 00 	mov    %eax,0x0(,%ebx,4)
			if (lock_flag) {
				unlock_op(&find_empty_process_semaphore);
    1b2c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
    1b33:	e8 fc ff ff ff       	call   1b34 <find_empty_process+0x92>
				lock_flag = 0;
			}
			return i;
    1b38:	83 c4 10             	add    $0x10,%esp
    1b3b:	89 d8                	mov    %ebx,%eax
    1b3d:	eb 1d                	jmp    1b5c <find_empty_process+0xba>
		if (task[i]) {
			if (task[i]->pid == last_pid)
				goto repeat;
		}

	for (i = 1; i < NR_TASKS; i++) {
    1b3f:	83 c3 01             	add    $0x1,%ebx
    1b42:	83 fb 40             	cmp    $0x40,%ebx
    1b45:	75 b1                	jne    1af8 <find_empty_process+0x56>
			}
			return i;
		}
	}
    if (lock_flag) {
    	unlock_op(&find_empty_process_semaphore);
    1b47:	83 ec 0c             	sub    $0xc,%esp
    1b4a:	68 00 00 00 00       	push   $0x0
    1b4f:	e8 fc ff ff ff       	call   1b50 <find_empty_process+0xae>
    	lock_flag = 0;
    }
	return -EAGAIN;
    1b54:	83 c4 10             	add    $0x10,%esp
    1b57:	b8 f5 ff ff ff       	mov    $0xfffffff5,%eax
}
    1b5c:	83 c4 04             	add    $0x4,%esp
    1b5f:	5b                   	pop    %ebx
    1b60:	5e                   	pop    %esi
    1b61:	c3                   	ret    

00001b62 <panic>:
#include <linux/sched.h>

void sys_sync(void);	/* it's really int */

volatile void panic(const char * s)
{
    1b62:	83 ec 14             	sub    $0x14,%esp
	printk("Kernel panic: %s\n\r",s);
    1b65:	ff 74 24 18          	pushl  0x18(%esp)
    1b69:	68 d2 01 00 00       	push   $0x1d2
    1b6e:	e8 fc ff ff ff       	call   1b6f <panic+0xd>
	if (get_current_task() == task[0])
    1b73:	e8 fc ff ff ff       	call   1b74 <panic+0x12>
    1b78:	83 c4 10             	add    $0x10,%esp
    1b7b:	39 05 00 00 00 00    	cmp    %eax,0x0
    1b81:	75 12                	jne    1b95 <panic+0x33>
		printk("In swapper task - not syncing\n\r");
    1b83:	83 ec 0c             	sub    $0xc,%esp
    1b86:	68 9c 01 00 00       	push   $0x19c
    1b8b:	e8 fc ff ff ff       	call   1b8c <panic+0x2a>
    1b90:	83 c4 10             	add    $0x10,%esp
    1b93:	eb 05                	jmp    1b9a <panic+0x38>
	else
		sys_sync();
    1b95:	e8 fc ff ff ff       	call   1b96 <panic+0x34>
    1b9a:	eb fe                	jmp    1b9a <panic+0x38>

00001b9c <printk>:

extern unsigned long tty_io_semaphore;
extern unsigned short	video_port_reg;		/* Video register select port	*/

int printk(const char *fmt, ...)
{
    1b9c:	53                   	push   %ebx
    1b9d:	83 ec 14             	sub    $0x14,%esp
	va_list args;
	int i;

	lock_op(&tty_io_semaphore);
    1ba0:	68 00 00 00 00       	push   $0x0
    1ba5:	e8 fc ff ff ff       	call   1ba6 <printk+0xa>

	va_start(args, fmt);
	i=vsprintf(print_buf,fmt,args);
    1baa:	83 c4 0c             	add    $0xc,%esp
    1bad:	8d 44 24 18          	lea    0x18(%esp),%eax
    1bb1:	50                   	push   %eax
    1bb2:	ff 74 24 18          	pushl  0x18(%esp)
    1bb6:	68 00 00 00 00       	push   $0x0
    1bbb:	e8 fc ff ff ff       	call   1bbc <printk+0x20>
    1bc0:	89 c3                	mov    %eax,%ebx
	va_end(args);

	/* Cause VM-EXIT, Using host print to instead of Guest print. */
	exit_reason_io_vedio_struct* exit_reason_io_vedio_p = (exit_reason_io_vedio_struct*) VM_EXIT_REASON_IO_INFO_ADDR;
	exit_reason_io_vedio_p->exit_reason_no = VM_EXIT_REASON_IO_INSTRUCTION;
    1bc2:	c7 05 00 f0 09 00 1e 	movl   $0x1e,0x9f000
    1bc9:	00 00 00 
	exit_reason_io_vedio_p->print_size = i;
    1bcc:	a3 04 f0 09 00       	mov    %eax,0x9f004
	exit_reason_io_vedio_p->print_buf = print_buf;
    1bd1:	c7 05 08 f0 09 00 00 	movl   $0x0,0x9f008
    1bd8:	00 00 00 
	cli();
    1bdb:	fa                   	cli    
	outb_p(14, video_port_reg);
    1bdc:	0f b7 15 00 00 00 00 	movzwl 0x0,%edx
    1be3:	b8 0e 00 00 00       	mov    $0xe,%eax
    1be8:	ee                   	out    %al,(%dx)
    1be9:	eb 00                	jmp    1beb <printk+0x4f>
    1beb:	eb 00                	jmp    1bed <printk+0x51>
	sti();
    1bed:	fb                   	sti    

	unlock_op(&tty_io_semaphore);
    1bee:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
    1bf5:	e8 fc ff ff ff       	call   1bf6 <printk+0x5a>
			"addl $8,%%esp\n\t"
			"popl %0\n\t"
			"pop %%fs"
			::"r" (i):"ax","cx","dx");
	return i;
}
    1bfa:	89 d8                	mov    %ebx,%eax
    1bfc:	83 c4 18             	add    $0x18,%esp
    1bff:	5b                   	pop    %ebx
    1c00:	c3                   	ret    

00001c01 <cpy_str_to_kernel>:

char* cpy_str_to_kernel(char * dest,const char *src)
{
    1c01:	57                   	push   %edi
    1c02:	56                   	push   %esi
    1c03:	8b 44 24 0c          	mov    0xc(%esp),%eax
__asm__(
    1c07:	8b 74 24 10          	mov    0x10(%esp),%esi
    1c0b:	89 c7                	mov    %eax,%edi
    1c0d:	1e                   	push   %ds
    1c0e:	0f a0                	push   %fs
    1c10:	1f                   	pop    %ds
    1c11:	fc                   	cld    
    1c12:	ac                   	lods   %ds:(%esi),%al
    1c13:	aa                   	stos   %al,%es:(%edi)
    1c14:	84 c0                	test   %al,%al
    1c16:	75 fa                	jne    1c12 <cpy_str_to_kernel+0x11>
    1c18:	1f                   	pop    %ds
	"testb %%al,%%al\n\t"
	"jne 1b\n\t"
	"pop %%ds"
	::"S" (src),"D" (dest));
return dest;
}
    1c19:	5e                   	pop    %esi
    1c1a:	5f                   	pop    %edi
    1c1b:	c3                   	ret    

00001c1c <number>:
int __res; \
__asm__("divl %4":"=a" (n),"=d" (__res):"0" (n),"1" (0),"r" (base)); \
__res; })

static char * number(char * str, int num, int base, int size, int precision,
		int type) {
    1c1c:	55                   	push   %ebp
    1c1d:	57                   	push   %edi
    1c1e:	56                   	push   %esi
    1c1f:	53                   	push   %ebx
    1c20:	83 ec 38             	sub    $0x38,%esp
    1c23:	89 c3                	mov    %eax,%ebx
    1c25:	89 d5                	mov    %edx,%ebp
	char c, sign, tmp[36];
	const char *digits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
	int i;

	if (type & SMALL)
    1c27:	8b 44 24 54          	mov    0x54(%esp),%eax
    1c2b:	83 e0 40             	and    $0x40,%eax
		digits = "0123456789abcdefghijklmnopqrstuvwxyz";
    1c2e:	b8 e4 01 00 00       	mov    $0x1e4,%eax
    1c33:	be bc 01 00 00       	mov    $0x1bc,%esi
    1c38:	0f 45 f0             	cmovne %eax,%esi
	if (type & LEFT)
    1c3b:	8b 54 24 54          	mov    0x54(%esp),%edx
    1c3f:	83 e2 10             	and    $0x10,%edx
		type &= ~ZEROPAD;
    1c42:	8b 44 24 54          	mov    0x54(%esp),%eax
    1c46:	83 e0 fe             	and    $0xfffffffe,%eax
    1c49:	85 d2                	test   %edx,%edx
    1c4b:	0f 44 44 24 54       	cmove  0x54(%esp),%eax
    1c50:	89 44 24 54          	mov    %eax,0x54(%esp)
	if (base < 2 || base > 36)
    1c54:	8d 41 fe             	lea    -0x2(%ecx),%eax
    1c57:	83 f8 22             	cmp    $0x22,%eax
    1c5a:	0f 87 8a 01 00 00    	ja     1dea <number+0x1ce>
    1c60:	89 cf                	mov    %ecx,%edi
		return 0;
	c = (type & ZEROPAD) ? '0' : ' ';
    1c62:	8b 44 24 54          	mov    0x54(%esp),%eax
    1c66:	83 e0 01             	and    $0x1,%eax
    1c69:	83 f8 01             	cmp    $0x1,%eax
    1c6c:	19 c0                	sbb    %eax,%eax
    1c6e:	83 e0 f0             	and    $0xfffffff0,%eax
    1c71:	83 c0 30             	add    $0x30,%eax
    1c74:	88 44 24 07          	mov    %al,0x7(%esp)
	if (type & SIGN && num < 0) {
    1c78:	f6 44 24 54 02       	testb  $0x2,0x54(%esp)
    1c7d:	74 15                	je     1c94 <number+0x78>
    1c7f:	89 e8                	mov    %ebp,%eax
    1c81:	c1 e8 1f             	shr    $0x1f,%eax
    1c84:	84 c0                	test   %al,%al
    1c86:	74 0c                	je     1c94 <number+0x78>
		sign = '-';
		num = -num;
    1c88:	f7 dd                	neg    %ebp
		type &= ~ZEROPAD;
	if (base < 2 || base > 36)
		return 0;
	c = (type & ZEROPAD) ? '0' : ' ';
	if (type & SIGN && num < 0) {
		sign = '-';
    1c8a:	c6 44 24 06 2d       	movb   $0x2d,0x6(%esp)
		num = -num;
    1c8f:	e9 6d 01 00 00       	jmp    1e01 <number+0x1e5>
	} else
		sign = (type & PLUS) ? '+' : ((type & SPACE) ? ' ' : 0);
    1c94:	f6 44 24 54 04       	testb  $0x4,0x54(%esp)
    1c99:	0f 85 56 01 00 00    	jne    1df5 <number+0x1d9>
    1c9f:	f6 44 24 54 08       	testb  $0x8,0x54(%esp)
    1ca4:	0f 85 52 01 00 00    	jne    1dfc <number+0x1e0>
    1caa:	c6 44 24 06 00       	movb   $0x0,0x6(%esp)
	if (sign)
		size--;
	if (type & SPECIAL)
    1caf:	8b 44 24 54          	mov    0x54(%esp),%eax
    1cb3:	83 e0 20             	and    $0x20,%eax
    1cb6:	89 04 24             	mov    %eax,(%esp)
    1cb9:	0f 84 4c 01 00 00    	je     1e0b <number+0x1ef>
		if (base == 16)
    1cbf:	83 ff 10             	cmp    $0x10,%edi
    1cc2:	75 07                	jne    1ccb <number+0xaf>
			size -= 2;
    1cc4:	83 6c 24 4c 02       	subl   $0x2,0x4c(%esp)
    1cc9:	eb 0d                	jmp    1cd8 <number+0xbc>
		else if (base == 8)
			size--;
    1ccb:	83 ff 08             	cmp    $0x8,%edi
    1cce:	0f 94 c0             	sete   %al
    1cd1:	0f b6 c0             	movzbl %al,%eax
    1cd4:	29 44 24 4c          	sub    %eax,0x4c(%esp)
	i = 0;
	if (num == 0)
    1cd8:	85 ed                	test   %ebp,%ebp
    1cda:	75 0c                	jne    1ce8 <number+0xcc>
		tmp[i++] = '0';
    1cdc:	c6 44 24 14 30       	movb   $0x30,0x14(%esp)
    1ce1:	b9 01 00 00 00       	mov    $0x1,%ecx
    1ce6:	eb 1f                	jmp    1d07 <number+0xeb>
	c = (type & ZEROPAD) ? '0' : ' ';
	if (type & SIGN && num < 0) {
		sign = '-';
		num = -num;
	} else
		sign = (type & PLUS) ? '+' : ((type & SPACE) ? ' ' : 0);
    1ce8:	b9 00 00 00 00       	mov    $0x0,%ecx
	i = 0;
	if (num == 0)
		tmp[i++] = '0';
	else
		while (num != 0)
			tmp[i++] = digits[do_div(num, base)];
    1ced:	83 c1 01             	add    $0x1,%ecx
    1cf0:	89 e8                	mov    %ebp,%eax
    1cf2:	ba 00 00 00 00       	mov    $0x0,%edx
    1cf7:	f7 f7                	div    %edi
    1cf9:	89 c5                	mov    %eax,%ebp
    1cfb:	0f b6 14 16          	movzbl (%esi,%edx,1),%edx
    1cff:	88 54 0c 13          	mov    %dl,0x13(%esp,%ecx,1)
			size--;
	i = 0;
	if (num == 0)
		tmp[i++] = '0';
	else
		while (num != 0)
    1d03:	85 c0                	test   %eax,%eax
    1d05:	75 e6                	jne    1ced <number+0xd1>
    1d07:	3b 4c 24 50          	cmp    0x50(%esp),%ecx
    1d0b:	89 cd                	mov    %ecx,%ebp
    1d0d:	0f 4c 6c 24 50       	cmovl  0x50(%esp),%ebp
			tmp[i++] = digits[do_div(num, base)];
	if (i > precision)
		precision = i;
	size -= precision;
    1d12:	8b 44 24 4c          	mov    0x4c(%esp),%eax
    1d16:	29 e8                	sub    %ebp,%eax
	if (!(type & (ZEROPAD + LEFT)))
    1d18:	f6 44 24 54 11       	testb  $0x11,0x54(%esp)
    1d1d:	75 20                	jne    1d3f <number+0x123>
		while (size-- > 0)
    1d1f:	8d 50 ff             	lea    -0x1(%eax),%edx
    1d22:	85 c0                	test   %eax,%eax
    1d24:	7e 17                	jle    1d3d <number+0x121>
    1d26:	8d 14 03             	lea    (%ebx,%eax,1),%edx
			*str++ = ' ';
    1d29:	83 c3 01             	add    $0x1,%ebx
    1d2c:	c6 43 ff 20          	movb   $0x20,-0x1(%ebx)
			tmp[i++] = digits[do_div(num, base)];
	if (i > precision)
		precision = i;
	size -= precision;
	if (!(type & (ZEROPAD + LEFT)))
		while (size-- > 0)
    1d30:	39 d3                	cmp    %edx,%ebx
    1d32:	75 f5                	jne    1d29 <number+0x10d>
    1d34:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
			*str++ = ' ';
    1d39:	89 d3                	mov    %edx,%ebx
    1d3b:	eb 02                	jmp    1d3f <number+0x123>
			tmp[i++] = digits[do_div(num, base)];
	if (i > precision)
		precision = i;
	size -= precision;
	if (!(type & (ZEROPAD + LEFT)))
		while (size-- > 0)
    1d3d:	89 d0                	mov    %edx,%eax
			*str++ = ' ';
	if (sign)
    1d3f:	0f b6 54 24 06       	movzbl 0x6(%esp),%edx
    1d44:	84 d2                	test   %dl,%dl
    1d46:	74 05                	je     1d4d <number+0x131>
		*str++ = sign;
    1d48:	88 13                	mov    %dl,(%ebx)
    1d4a:	8d 5b 01             	lea    0x1(%ebx),%ebx
	if (type & SPECIAL)
    1d4d:	83 3c 24 00          	cmpl   $0x0,(%esp)
    1d51:	74 1f                	je     1d72 <number+0x156>
		if (base == 8)
    1d53:	83 ff 08             	cmp    $0x8,%edi
    1d56:	75 08                	jne    1d60 <number+0x144>
			*str++ = '0';
    1d58:	c6 03 30             	movb   $0x30,(%ebx)
    1d5b:	8d 5b 01             	lea    0x1(%ebx),%ebx
    1d5e:	eb 12                	jmp    1d72 <number+0x156>
		else if (base == 16) {
    1d60:	83 ff 10             	cmp    $0x10,%edi
    1d63:	75 0d                	jne    1d72 <number+0x156>
			*str++ = '0';
    1d65:	c6 03 30             	movb   $0x30,(%ebx)
			*str++ = digits[33];
    1d68:	0f b6 56 21          	movzbl 0x21(%esi),%edx
    1d6c:	88 53 01             	mov    %dl,0x1(%ebx)
    1d6f:	8d 5b 02             	lea    0x2(%ebx),%ebx
		}
	if (!(type & LEFT))
    1d72:	f6 44 24 54 10       	testb  $0x10,0x54(%esp)
    1d77:	75 23                	jne    1d9c <number+0x180>
		while (size-- > 0)
    1d79:	8d 50 ff             	lea    -0x1(%eax),%edx
    1d7c:	85 c0                	test   %eax,%eax
    1d7e:	7e 1a                	jle    1d9a <number+0x17e>
    1d80:	01 d8                	add    %ebx,%eax
    1d82:	0f b6 54 24 07       	movzbl 0x7(%esp),%edx
			*str++ = c;
    1d87:	83 c3 01             	add    $0x1,%ebx
    1d8a:	88 53 ff             	mov    %dl,-0x1(%ebx)
		else if (base == 16) {
			*str++ = '0';
			*str++ = digits[33];
		}
	if (!(type & LEFT))
		while (size-- > 0)
    1d8d:	39 c3                	cmp    %eax,%ebx
    1d8f:	75 f6                	jne    1d87 <number+0x16b>
			*str++ = c;
    1d91:	89 c3                	mov    %eax,%ebx
		else if (base == 16) {
			*str++ = '0';
			*str++ = digits[33];
		}
	if (!(type & LEFT))
		while (size-- > 0)
    1d93:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    1d98:	eb 02                	jmp    1d9c <number+0x180>
    1d9a:	89 d0                	mov    %edx,%eax
			*str++ = c;
	while (i < precision--)
    1d9c:	39 e9                	cmp    %ebp,%ecx
    1d9e:	7d 13                	jge    1db3 <number+0x197>
    1da0:	89 ef                	mov    %ebp,%edi
    1da2:	29 cf                	sub    %ecx,%edi
    1da4:	01 df                	add    %ebx,%edi
		*str++ = '0';
    1da6:	83 c3 01             	add    $0x1,%ebx
    1da9:	c6 43 ff 30          	movb   $0x30,-0x1(%ebx)
			*str++ = digits[33];
		}
	if (!(type & LEFT))
		while (size-- > 0)
			*str++ = c;
	while (i < precision--)
    1dad:	39 df                	cmp    %ebx,%edi
    1daf:	75 f5                	jne    1da6 <number+0x18a>
    1db1:	eb 02                	jmp    1db5 <number+0x199>
    1db3:	89 df                	mov    %ebx,%edi
		*str++ = '0';
	while (i-- > 0)
    1db5:	85 c9                	test   %ecx,%ecx
    1db7:	7e 1e                	jle    1dd7 <number+0x1bb>
    1db9:	89 ce                	mov    %ecx,%esi
    1dbb:	8d 54 0c 13          	lea    0x13(%esp,%ecx,1),%edx
    1dbf:	8d 6c 24 13          	lea    0x13(%esp),%ebp
    1dc3:	89 f9                	mov    %edi,%ecx
		*str++ = tmp[i];
    1dc5:	83 c1 01             	add    $0x1,%ecx
    1dc8:	0f b6 1a             	movzbl (%edx),%ebx
    1dcb:	88 59 ff             	mov    %bl,-0x1(%ecx)
    1dce:	83 ea 01             	sub    $0x1,%edx
	if (!(type & LEFT))
		while (size-- > 0)
			*str++ = c;
	while (i < precision--)
		*str++ = '0';
	while (i-- > 0)
    1dd1:	39 d5                	cmp    %edx,%ebp
    1dd3:	75 f0                	jne    1dc5 <number+0x1a9>
    1dd5:	01 f7                	add    %esi,%edi
		*str++ = tmp[i];
	while (size-- > 0)
    1dd7:	85 c0                	test   %eax,%eax
    1dd9:	7e 16                	jle    1df1 <number+0x1d5>
    1ddb:	01 f8                	add    %edi,%eax
		*str++ = ' ';
    1ddd:	83 c7 01             	add    $0x1,%edi
    1de0:	c6 47 ff 20          	movb   $0x20,-0x1(%edi)
			*str++ = c;
	while (i < precision--)
		*str++ = '0';
	while (i-- > 0)
		*str++ = tmp[i];
	while (size-- > 0)
    1de4:	39 f8                	cmp    %edi,%eax
    1de6:	75 f5                	jne    1ddd <number+0x1c1>
    1de8:	eb 2e                	jmp    1e18 <number+0x1fc>
	if (type & SMALL)
		digits = "0123456789abcdefghijklmnopqrstuvwxyz";
	if (type & LEFT)
		type &= ~ZEROPAD;
	if (base < 2 || base > 36)
		return 0;
    1dea:	b8 00 00 00 00       	mov    $0x0,%eax
    1def:	eb 27                	jmp    1e18 <number+0x1fc>
			*str++ = c;
	while (i < precision--)
		*str++ = '0';
	while (i-- > 0)
		*str++ = tmp[i];
	while (size-- > 0)
    1df1:	89 f8                	mov    %edi,%eax
    1df3:	eb 23                	jmp    1e18 <number+0x1fc>
	c = (type & ZEROPAD) ? '0' : ' ';
	if (type & SIGN && num < 0) {
		sign = '-';
		num = -num;
	} else
		sign = (type & PLUS) ? '+' : ((type & SPACE) ? ' ' : 0);
    1df5:	c6 44 24 06 2b       	movb   $0x2b,0x6(%esp)
    1dfa:	eb 05                	jmp    1e01 <number+0x1e5>
    1dfc:	c6 44 24 06 20       	movb   $0x20,0x6(%esp)
	if (sign)
		size--;
    1e01:	83 6c 24 4c 01       	subl   $0x1,0x4c(%esp)
    1e06:	e9 a4 fe ff ff       	jmp    1caf <number+0x93>
		if (base == 16)
			size -= 2;
		else if (base == 8)
			size--;
	i = 0;
	if (num == 0)
    1e0b:	85 ed                	test   %ebp,%ebp
    1e0d:	0f 84 c9 fe ff ff    	je     1cdc <number+0xc0>
    1e13:	e9 d0 fe ff ff       	jmp    1ce8 <number+0xcc>
	while (i-- > 0)
		*str++ = tmp[i];
	while (size-- > 0)
		*str++ = ' ';
	return str;
}
    1e18:	83 c4 38             	add    $0x38,%esp
    1e1b:	5b                   	pop    %ebx
    1e1c:	5e                   	pop    %esi
    1e1d:	5f                   	pop    %edi
    1e1e:	5d                   	pop    %ebp
    1e1f:	c3                   	ret    

00001e20 <vsprintf>:

int vsprintf(char *buf, const char *fmt, va_list args) {
    1e20:	55                   	push   %ebp
    1e21:	57                   	push   %edi
    1e22:	56                   	push   %esi
    1e23:	53                   	push   %ebx
    1e24:	83 ec 08             	sub    $0x8,%esp
    1e27:	8b 44 24 20          	mov    0x20(%esp),%eax
	int field_width; /* width of output field */
	int precision; /* min. # of digits for integers; max
	 number of chars for from string */
	int qualifier; /* 'h', 'l', or 'L' for integer fields */

	for (str = buf; *fmt; ++fmt) {
    1e2b:	0f b6 10             	movzbl (%eax),%edx
    1e2e:	84 d2                	test   %dl,%dl
    1e30:	0f 84 58 03 00 00    	je     218e <vsprintf+0x36e>
    1e36:	8b 6c 24 1c          	mov    0x1c(%esp),%ebp
		if (*fmt != '%') {
    1e3a:	80 fa 25             	cmp    $0x25,%dl
    1e3d:	74 0d                	je     1e4c <vsprintf+0x2c>
			*str++ = *fmt;
    1e3f:	88 55 00             	mov    %dl,0x0(%ebp)
			continue;
    1e42:	89 c3                	mov    %eax,%ebx
	 number of chars for from string */
	int qualifier; /* 'h', 'l', or 'L' for integer fields */

	for (str = buf; *fmt; ++fmt) {
		if (*fmt != '%') {
			*str++ = *fmt;
    1e44:	8d 6d 01             	lea    0x1(%ebp),%ebp
			continue;
    1e47:	e9 31 03 00 00       	jmp    217d <vsprintf+0x35d>
    1e4c:	be 00 00 00 00       	mov    $0x0,%esi
		}

		/* process flags */
		flags = 0;
		repeat: ++fmt; /* this also skips first '%' */
    1e51:	83 c0 01             	add    $0x1,%eax
		switch (*fmt) {
    1e54:	0f b6 08             	movzbl (%eax),%ecx
    1e57:	8d 51 e0             	lea    -0x20(%ecx),%edx
    1e5a:	80 fa 10             	cmp    $0x10,%dl
    1e5d:	77 23                	ja     1e82 <vsprintf+0x62>
    1e5f:	0f b6 d2             	movzbl %dl,%edx
    1e62:	ff 24 95 00 00 00 00 	jmp    *0x0(,%edx,4)
		case '-':
			flags |= LEFT;
    1e69:	83 ce 10             	or     $0x10,%esi
			goto repeat;
    1e6c:	eb e3                	jmp    1e51 <vsprintf+0x31>
		case '+':
			flags |= PLUS;
    1e6e:	83 ce 04             	or     $0x4,%esi
			goto repeat;
    1e71:	eb de                	jmp    1e51 <vsprintf+0x31>
		case ' ':
			flags |= SPACE;
    1e73:	83 ce 08             	or     $0x8,%esi
			goto repeat;
    1e76:	eb d9                	jmp    1e51 <vsprintf+0x31>
		case '#':
			flags |= SPECIAL;
    1e78:	83 ce 20             	or     $0x20,%esi
			goto repeat;
    1e7b:	eb d4                	jmp    1e51 <vsprintf+0x31>
		case '0':
			flags |= ZEROPAD;
    1e7d:	83 ce 01             	or     $0x1,%esi
			goto repeat;
    1e80:	eb cf                	jmp    1e51 <vsprintf+0x31>
		}

		/* get field width */
		field_width = -1;
		if (is_digit(*fmt))
    1e82:	8d 51 d0             	lea    -0x30(%ecx),%edx
    1e85:	80 fa 09             	cmp    $0x9,%dl
    1e88:	77 21                	ja     1eab <vsprintf+0x8b>
    1e8a:	ba 00 00 00 00       	mov    $0x0,%edx

static int skip_atoi(const char **s) {
	int i = 0;

	while (is_digit(**s))
		i = i * 10 + *((*s)++) - '0';
    1e8f:	83 c0 01             	add    $0x1,%eax
    1e92:	8d 14 92             	lea    (%edx,%edx,4),%edx
    1e95:	0f be c9             	movsbl %cl,%ecx
    1e98:	8d 54 51 d0          	lea    -0x30(%ecx,%edx,2),%edx
#define is_digit(c)	((c) >= '0' && (c) <= '9')

static int skip_atoi(const char **s) {
	int i = 0;

	while (is_digit(**s))
    1e9c:	0f b6 08             	movzbl (%eax),%ecx
    1e9f:	8d 59 d0             	lea    -0x30(%ecx),%ebx
    1ea2:	80 fb 09             	cmp    $0x9,%bl
    1ea5:	76 e8                	jbe    1e8f <vsprintf+0x6f>
		i = i * 10 + *((*s)++) - '0';
    1ea7:	89 c3                	mov    %eax,%ebx
    1ea9:	eb 27                	jmp    1ed2 <vsprintf+0xb2>
			continue;
		}

		/* process flags */
		flags = 0;
		repeat: ++fmt; /* this also skips first '%' */
    1eab:	89 c3                	mov    %eax,%ebx
			flags |= ZEROPAD;
			goto repeat;
		}

		/* get field width */
		field_width = -1;
    1ead:	ba ff ff ff ff       	mov    $0xffffffff,%edx
		if (is_digit(*fmt))
			field_width = skip_atoi(&fmt);
		else if (*fmt == '*') {
    1eb2:	80 f9 2a             	cmp    $0x2a,%cl
    1eb5:	75 1b                	jne    1ed2 <vsprintf+0xb2>
			/* it's the next argument */
			field_width = va_arg(args, int);
    1eb7:	8b 7c 24 24          	mov    0x24(%esp),%edi
    1ebb:	8d 4f 04             	lea    0x4(%edi),%ecx
    1ebe:	8b 17                	mov    (%edi),%edx
			if (field_width < 0) {
    1ec0:	85 d2                	test   %edx,%edx
    1ec2:	0f 89 cc 02 00 00    	jns    2194 <vsprintf+0x374>
				field_width = -field_width;
    1ec8:	f7 da                	neg    %edx
				flags |= LEFT;
    1eca:	83 ce 10             	or     $0x10,%esi
    1ecd:	e9 c2 02 00 00       	jmp    2194 <vsprintf+0x374>
			}
		}

		/* get the precision */
		precision = -1;
    1ed2:	c7 04 24 ff ff ff ff 	movl   $0xffffffff,(%esp)
		if (*fmt == '.') {
    1ed9:	80 3b 2e             	cmpb   $0x2e,(%ebx)
    1edc:	75 53                	jne    1f31 <vsprintf+0x111>
			++fmt;
    1ede:	8d 7b 01             	lea    0x1(%ebx),%edi
			if (is_digit(*fmt))
    1ee1:	0f b6 43 01          	movzbl 0x1(%ebx),%eax
    1ee5:	8d 48 d0             	lea    -0x30(%eax),%ecx
    1ee8:	80 f9 09             	cmp    $0x9,%cl
    1eeb:	77 1f                	ja     1f0c <vsprintf+0xec>
    1eed:	b9 00 00 00 00       	mov    $0x0,%ecx

static int skip_atoi(const char **s) {
	int i = 0;

	while (is_digit(**s))
		i = i * 10 + *((*s)++) - '0';
    1ef2:	83 c7 01             	add    $0x1,%edi
    1ef5:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
    1ef8:	0f be c0             	movsbl %al,%eax
    1efb:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
#define is_digit(c)	((c) >= '0' && (c) <= '9')

static int skip_atoi(const char **s) {
	int i = 0;

	while (is_digit(**s))
    1eff:	0f b6 07             	movzbl (%edi),%eax
    1f02:	8d 58 d0             	lea    -0x30(%eax),%ebx
    1f05:	80 fb 09             	cmp    $0x9,%bl
    1f08:	76 e8                	jbe    1ef2 <vsprintf+0xd2>
    1f0a:	eb 16                	jmp    1f22 <vsprintf+0x102>
				flags |= LEFT;
			}
		}

		/* get the precision */
		precision = -1;
    1f0c:	b9 ff ff ff ff       	mov    $0xffffffff,%ecx
		if (*fmt == '.') {
			++fmt;
			if (is_digit(*fmt))
				precision = skip_atoi(&fmt);
			else if (*fmt == '*') {
    1f11:	3c 2a                	cmp    $0x2a,%al
    1f13:	75 0d                	jne    1f22 <vsprintf+0x102>
				/* it's the next argument */
				precision = va_arg(args, int);
    1f15:	8b 44 24 24          	mov    0x24(%esp),%eax
    1f19:	8b 08                	mov    (%eax),%ecx
    1f1b:	8d 40 04             	lea    0x4(%eax),%eax
    1f1e:	89 44 24 24          	mov    %eax,0x24(%esp)
    1f22:	85 c9                	test   %ecx,%ecx
    1f24:	b8 00 00 00 00       	mov    $0x0,%eax
    1f29:	0f 48 c8             	cmovs  %eax,%ecx
    1f2c:	89 0c 24             	mov    %ecx,(%esp)
    1f2f:	89 fb                	mov    %edi,%ebx
				precision = 0;
		}

		/* get the conversion qualifier */
		qualifier = -1;
		if (*fmt == 'h' || *fmt == 'l' || *fmt == 'L') {
    1f31:	0f b6 03             	movzbl (%ebx),%eax
    1f34:	89 c1                	mov    %eax,%ecx
    1f36:	83 e1 df             	and    $0xffffffdf,%ecx
    1f39:	80 f9 4c             	cmp    $0x4c,%cl
    1f3c:	74 04                	je     1f42 <vsprintf+0x122>
    1f3e:	3c 68                	cmp    $0x68,%al
    1f40:	75 03                	jne    1f45 <vsprintf+0x125>
			qualifier = *fmt;
			++fmt;
    1f42:	83 c3 01             	add    $0x1,%ebx
		}

		switch (*fmt) {
    1f45:	0f b6 0b             	movzbl (%ebx),%ecx
    1f48:	8d 41 a8             	lea    -0x58(%ecx),%eax
    1f4b:	3c 20                	cmp    $0x20,%al
    1f4d:	0f 87 f4 01 00 00    	ja     2147 <vsprintf+0x327>
    1f53:	0f b6 c0             	movzbl %al,%eax
    1f56:	ff 24 85 44 00 00 00 	jmp    *0x44(,%eax,4)
		case 'c':
			if (!(flags & LEFT))
    1f5d:	f7 c6 10 00 00 00    	test   $0x10,%esi
    1f63:	75 21                	jne    1f86 <vsprintf+0x166>
				while (--field_width > 0)
    1f65:	8d 42 ff             	lea    -0x1(%edx),%eax
    1f68:	85 c0                	test   %eax,%eax
    1f6a:	7e 18                	jle    1f84 <vsprintf+0x164>
    1f6c:	8d 44 15 ff          	lea    -0x1(%ebp,%edx,1),%eax
					*str++ = ' ';
    1f70:	83 c5 01             	add    $0x1,%ebp
    1f73:	c6 45 ff 20          	movb   $0x20,-0x1(%ebp)
		}

		switch (*fmt) {
		case 'c':
			if (!(flags & LEFT))
				while (--field_width > 0)
    1f77:	39 c5                	cmp    %eax,%ebp
    1f79:	75 f5                	jne    1f70 <vsprintf+0x150>
    1f7b:	ba 00 00 00 00       	mov    $0x0,%edx
					*str++ = ' ';
    1f80:	89 c5                	mov    %eax,%ebp
    1f82:	eb 02                	jmp    1f86 <vsprintf+0x166>
		}

		switch (*fmt) {
		case 'c':
			if (!(flags & LEFT))
				while (--field_width > 0)
    1f84:	89 c2                	mov    %eax,%edx
					*str++ = ' ';
			*str++ = (unsigned char) va_arg(args, int);
    1f86:	8b 44 24 24          	mov    0x24(%esp),%eax
    1f8a:	8d 70 04             	lea    0x4(%eax),%esi
    1f8d:	8d 4d 01             	lea    0x1(%ebp),%ecx
    1f90:	8b 00                	mov    (%eax),%eax
    1f92:	88 45 00             	mov    %al,0x0(%ebp)
			while (--field_width > 0)
    1f95:	8d 42 ff             	lea    -0x1(%edx),%eax
    1f98:	85 c0                	test   %eax,%eax
    1f9a:	0f 8e cb 01 00 00    	jle    216b <vsprintf+0x34b>
    1fa0:	89 d7                	mov    %edx,%edi
    1fa2:	01 ea                	add    %ebp,%edx
    1fa4:	89 c8                	mov    %ecx,%eax
				*str++ = ' ';
    1fa6:	83 c0 01             	add    $0x1,%eax
    1fa9:	c6 40 ff 20          	movb   $0x20,-0x1(%eax)
		case 'c':
			if (!(flags & LEFT))
				while (--field_width > 0)
					*str++ = ' ';
			*str++ = (unsigned char) va_arg(args, int);
			while (--field_width > 0)
    1fad:	39 d0                	cmp    %edx,%eax
    1faf:	75 f5                	jne    1fa6 <vsprintf+0x186>
    1fb1:	8d 6c 39 ff          	lea    -0x1(%ecx,%edi,1),%ebp
		switch (*fmt) {
		case 'c':
			if (!(flags & LEFT))
				while (--field_width > 0)
					*str++ = ' ';
			*str++ = (unsigned char) va_arg(args, int);
    1fb5:	89 74 24 24          	mov    %esi,0x24(%esp)
    1fb9:	e9 bf 01 00 00       	jmp    217d <vsprintf+0x35d>
			while (--field_width > 0)
				*str++ = ' ';
			break;

		case 's':
			s = va_arg(args, char *);
    1fbe:	8b 44 24 24          	mov    0x24(%esp),%eax
    1fc2:	83 c0 04             	add    $0x4,%eax
    1fc5:	89 44 24 04          	mov    %eax,0x4(%esp)
    1fc9:	8b 44 24 24          	mov    0x24(%esp),%eax
    1fcd:	8b 38                	mov    (%eax),%edi
}

static inline int strlen(const char * s)
{
register int __res __asm__("cx");
__asm__("cld\n\t"
    1fcf:	b9 ff ff ff ff       	mov    $0xffffffff,%ecx
    1fd4:	b8 00 00 00 00       	mov    $0x0,%eax
    1fd9:	fc                   	cld    
    1fda:	f2 ae                	repnz scas %es:(%edi),%al
    1fdc:	f7 d1                	not    %ecx
    1fde:	49                   	dec    %ecx
			len = strlen(s);
			s-=(len+1);
    1fdf:	89 c8                	mov    %ecx,%eax
    1fe1:	f7 d0                	not    %eax
    1fe3:	01 c7                	add    %eax,%edi
			if (precision < 0)
				precision = len;
			else if (len > precision)
    1fe5:	8b 04 24             	mov    (%esp),%eax
    1fe8:	85 c0                	test   %eax,%eax
    1fea:	78 0b                	js     1ff7 <vsprintf+0x1d7>
    1fec:	39 c8                	cmp    %ecx,%eax
    1fee:	0f 9c c0             	setl   %al
				len = precision;
    1ff1:	84 c0                	test   %al,%al
    1ff3:	0f 45 0c 24          	cmovne (%esp),%ecx

			if (!(flags & LEFT))
    1ff7:	f7 c6 10 00 00 00    	test   $0x10,%esi
    1ffd:	75 23                	jne    2022 <vsprintf+0x202>
				while (len < field_width--)
    1fff:	8d 42 ff             	lea    -0x1(%edx),%eax
    2002:	39 d1                	cmp    %edx,%ecx
    2004:	7d 1a                	jge    2020 <vsprintf+0x200>
    2006:	89 ce                	mov    %ecx,%esi
    2008:	29 ca                	sub    %ecx,%edx
    200a:	8d 44 15 00          	lea    0x0(%ebp,%edx,1),%eax
					*str++ = ' ';
    200e:	83 c5 01             	add    $0x1,%ebp
    2011:	c6 45 ff 20          	movb   $0x20,-0x1(%ebp)
				precision = len;
			else if (len > precision)
				len = precision;

			if (!(flags & LEFT))
				while (len < field_width--)
    2015:	39 c5                	cmp    %eax,%ebp
    2017:	75 f5                	jne    200e <vsprintf+0x1ee>
    2019:	8d 56 ff             	lea    -0x1(%esi),%edx
					*str++ = ' ';
    201c:	89 c5                	mov    %eax,%ebp
    201e:	eb 02                	jmp    2022 <vsprintf+0x202>
				precision = len;
			else if (len > precision)
				len = precision;

			if (!(flags & LEFT))
				while (len < field_width--)
    2020:	89 c2                	mov    %eax,%edx
					*str++ = ' ';
			for (i = 0; i < len; ++i)
    2022:	85 c9                	test   %ecx,%ecx
    2024:	7e 1e                	jle    2044 <vsprintf+0x224>
    2026:	b8 00 00 00 00       	mov    $0x0,%eax
    202b:	89 d6                	mov    %edx,%esi
				*str++ = *s++;
    202d:	0f b6 14 07          	movzbl (%edi,%eax,1),%edx
    2031:	88 54 05 00          	mov    %dl,0x0(%ebp,%eax,1)
				len = precision;

			if (!(flags & LEFT))
				while (len < field_width--)
					*str++ = ' ';
			for (i = 0; i < len; ++i)
    2035:	83 c0 01             	add    $0x1,%eax
    2038:	39 c1                	cmp    %eax,%ecx
    203a:	75 f1                	jne    202d <vsprintf+0x20d>
    203c:	89 f2                	mov    %esi,%edx
    203e:	8d 44 0d 00          	lea    0x0(%ebp,%ecx,1),%eax
    2042:	eb 02                	jmp    2046 <vsprintf+0x226>
    2044:	89 e8                	mov    %ebp,%eax
				*str++ = *s++;
			while (len < field_width--)
    2046:	39 d1                	cmp    %edx,%ecx
    2048:	0f 8d 25 01 00 00    	jge    2173 <vsprintf+0x353>
    204e:	29 ca                	sub    %ecx,%edx
    2050:	8d 2c 10             	lea    (%eax,%edx,1),%ebp
				*str++ = ' ';
    2053:	83 c0 01             	add    $0x1,%eax
    2056:	c6 40 ff 20          	movb   $0x20,-0x1(%eax)
			if (!(flags & LEFT))
				while (len < field_width--)
					*str++ = ' ';
			for (i = 0; i < len; ++i)
				*str++ = *s++;
			while (len < field_width--)
    205a:	39 c5                	cmp    %eax,%ebp
    205c:	75 f5                	jne    2053 <vsprintf+0x233>
			while (--field_width > 0)
				*str++ = ' ';
			break;

		case 's':
			s = va_arg(args, char *);
    205e:	8b 44 24 04          	mov    0x4(%esp),%eax
    2062:	89 44 24 24          	mov    %eax,0x24(%esp)
    2066:	e9 12 01 00 00       	jmp    217d <vsprintf+0x35d>
			while (len < field_width--)
				*str++ = ' ';
			break;

		case 'o':
			str = number(str, va_arg(args, unsigned long), 8, field_width,
    206b:	8b 44 24 24          	mov    0x24(%esp),%eax
    206f:	8d 78 04             	lea    0x4(%eax),%edi
    2072:	56                   	push   %esi
    2073:	ff 74 24 04          	pushl  0x4(%esp)
    2077:	52                   	push   %edx
    2078:	b9 08 00 00 00       	mov    $0x8,%ecx
    207d:	8b 44 24 30          	mov    0x30(%esp),%eax
    2081:	8b 10                	mov    (%eax),%edx
    2083:	89 e8                	mov    %ebp,%eax
    2085:	e8 92 fb ff ff       	call   1c1c <number>
    208a:	89 c5                	mov    %eax,%ebp
					precision, flags);
			break;
    208c:	83 c4 0c             	add    $0xc,%esp
			while (len < field_width--)
				*str++ = ' ';
			break;

		case 'o':
			str = number(str, va_arg(args, unsigned long), 8, field_width,
    208f:	89 7c 24 24          	mov    %edi,0x24(%esp)
					precision, flags);
			break;
    2093:	e9 e5 00 00 00       	jmp    217d <vsprintf+0x35d>

		case 'p':
			if (field_width == -1) {
    2098:	83 fa ff             	cmp    $0xffffffff,%edx
    209b:	75 08                	jne    20a5 <vsprintf+0x285>
				field_width = 8;
				flags |= ZEROPAD;
    209d:	83 ce 01             	or     $0x1,%esi
					precision, flags);
			break;

		case 'p':
			if (field_width == -1) {
				field_width = 8;
    20a0:	ba 08 00 00 00       	mov    $0x8,%edx
				flags |= ZEROPAD;
			}
			str = number(str, (unsigned long) va_arg(args, void *), 16,
    20a5:	8b 44 24 24          	mov    0x24(%esp),%eax
    20a9:	8d 78 04             	lea    0x4(%eax),%edi
    20ac:	56                   	push   %esi
    20ad:	ff 74 24 04          	pushl  0x4(%esp)
    20b1:	52                   	push   %edx
    20b2:	b9 10 00 00 00       	mov    $0x10,%ecx
    20b7:	8b 44 24 30          	mov    0x30(%esp),%eax
    20bb:	8b 10                	mov    (%eax),%edx
    20bd:	89 e8                	mov    %ebp,%eax
    20bf:	e8 58 fb ff ff       	call   1c1c <number>
    20c4:	89 c5                	mov    %eax,%ebp
					field_width, precision, flags);
			break;
    20c6:	83 c4 0c             	add    $0xc,%esp
		case 'p':
			if (field_width == -1) {
				field_width = 8;
				flags |= ZEROPAD;
			}
			str = number(str, (unsigned long) va_arg(args, void *), 16,
    20c9:	89 7c 24 24          	mov    %edi,0x24(%esp)
					field_width, precision, flags);
			break;
    20cd:	e9 ab 00 00 00       	jmp    217d <vsprintf+0x35d>

		case 'x':
			flags |= SMALL;
    20d2:	83 ce 40             	or     $0x40,%esi
		case 'X':
			str = number(str, va_arg(args, unsigned long), 16, field_width,
    20d5:	8b 44 24 24          	mov    0x24(%esp),%eax
    20d9:	8d 78 04             	lea    0x4(%eax),%edi
    20dc:	56                   	push   %esi
    20dd:	ff 74 24 04          	pushl  0x4(%esp)
    20e1:	52                   	push   %edx
    20e2:	b9 10 00 00 00       	mov    $0x10,%ecx
    20e7:	8b 44 24 30          	mov    0x30(%esp),%eax
    20eb:	8b 10                	mov    (%eax),%edx
    20ed:	89 e8                	mov    %ebp,%eax
    20ef:	e8 28 fb ff ff       	call   1c1c <number>
    20f4:	89 c5                	mov    %eax,%ebp
					precision, flags);
			break;
    20f6:	83 c4 0c             	add    $0xc,%esp
			break;

		case 'x':
			flags |= SMALL;
		case 'X':
			str = number(str, va_arg(args, unsigned long), 16, field_width,
    20f9:	89 7c 24 24          	mov    %edi,0x24(%esp)
					precision, flags);
			break;
    20fd:	eb 7e                	jmp    217d <vsprintf+0x35d>

		case 'd':
		case 'i':
			flags |= SIGN;
    20ff:	83 ce 02             	or     $0x2,%esi
		case 'u':
			str = number(str, va_arg(args, unsigned long), 10, field_width,
    2102:	8b 44 24 24          	mov    0x24(%esp),%eax
    2106:	8d 78 04             	lea    0x4(%eax),%edi
    2109:	56                   	push   %esi
    210a:	ff 74 24 04          	pushl  0x4(%esp)
    210e:	52                   	push   %edx
    210f:	b9 0a 00 00 00       	mov    $0xa,%ecx
    2114:	8b 44 24 30          	mov    0x30(%esp),%eax
    2118:	8b 10                	mov    (%eax),%edx
    211a:	89 e8                	mov    %ebp,%eax
    211c:	e8 fb fa ff ff       	call   1c1c <number>
    2121:	89 c5                	mov    %eax,%ebp
					precision, flags);
			break;
    2123:	83 c4 0c             	add    $0xc,%esp

		case 'd':
		case 'i':
			flags |= SIGN;
		case 'u':
			str = number(str, va_arg(args, unsigned long), 10, field_width,
    2126:	89 7c 24 24          	mov    %edi,0x24(%esp)
					precision, flags);
			break;
    212a:	eb 51                	jmp    217d <vsprintf+0x35d>

		case 'n':
			ip = va_arg(args, int *);
    212c:	8b 44 24 24          	mov    0x24(%esp),%eax
    2130:	8b 00                	mov    (%eax),%eax
			*ip = (str - buf);
    2132:	89 ea                	mov    %ebp,%edx
    2134:	2b 54 24 1c          	sub    0x1c(%esp),%edx
    2138:	89 10                	mov    %edx,(%eax)
			str = number(str, va_arg(args, unsigned long), 10, field_width,
					precision, flags);
			break;

		case 'n':
			ip = va_arg(args, int *);
    213a:	8b 44 24 24          	mov    0x24(%esp),%eax
    213e:	8d 40 04             	lea    0x4(%eax),%eax
    2141:	89 44 24 24          	mov    %eax,0x24(%esp)
			*ip = (str - buf);
			break;
    2145:	eb 36                	jmp    217d <vsprintf+0x35d>

		default:
			if (*fmt != '%')
    2147:	80 f9 25             	cmp    $0x25,%cl
    214a:	74 10                	je     215c <vsprintf+0x33c>
				*str++ = '%';
    214c:	8d 45 01             	lea    0x1(%ebp),%eax
    214f:	c6 45 00 25          	movb   $0x25,0x0(%ebp)
			if (*fmt)
    2153:	0f b6 0b             	movzbl (%ebx),%ecx
    2156:	84 c9                	test   %cl,%cl
    2158:	74 0a                	je     2164 <vsprintf+0x344>
			*ip = (str - buf);
			break;

		default:
			if (*fmt != '%')
				*str++ = '%';
    215a:	89 c5                	mov    %eax,%ebp
			if (*fmt)
				*str++ = *fmt;
    215c:	88 4d 00             	mov    %cl,0x0(%ebp)
    215f:	8d 6d 01             	lea    0x1(%ebp),%ebp
    2162:	eb 19                	jmp    217d <vsprintf+0x35d>
			else
				--fmt;
    2164:	83 eb 01             	sub    $0x1,%ebx
			*ip = (str - buf);
			break;

		default:
			if (*fmt != '%')
				*str++ = '%';
    2167:	89 c5                	mov    %eax,%ebp
    2169:	eb 12                	jmp    217d <vsprintf+0x35d>
		switch (*fmt) {
		case 'c':
			if (!(flags & LEFT))
				while (--field_width > 0)
					*str++ = ' ';
			*str++ = (unsigned char) va_arg(args, int);
    216b:	89 cd                	mov    %ecx,%ebp
    216d:	89 74 24 24          	mov    %esi,0x24(%esp)
    2171:	eb 0a                	jmp    217d <vsprintf+0x35d>
			if (!(flags & LEFT))
				while (len < field_width--)
					*str++ = ' ';
			for (i = 0; i < len; ++i)
				*str++ = *s++;
			while (len < field_width--)
    2173:	89 c5                	mov    %eax,%ebp
			while (--field_width > 0)
				*str++ = ' ';
			break;

		case 's':
			s = va_arg(args, char *);
    2175:	8b 44 24 04          	mov    0x4(%esp),%eax
    2179:	89 44 24 24          	mov    %eax,0x24(%esp)
	int field_width; /* width of output field */
	int precision; /* min. # of digits for integers; max
	 number of chars for from string */
	int qualifier; /* 'h', 'l', or 'L' for integer fields */

	for (str = buf; *fmt; ++fmt) {
    217d:	8d 43 01             	lea    0x1(%ebx),%eax
    2180:	0f b6 53 01          	movzbl 0x1(%ebx),%edx
    2184:	84 d2                	test   %dl,%dl
    2186:	0f 85 ae fc ff ff    	jne    1e3a <vsprintf+0x1a>
    218c:	eb 18                	jmp    21a6 <vsprintf+0x386>
    218e:	8b 6c 24 1c          	mov    0x1c(%esp),%ebp
    2192:	eb 12                	jmp    21a6 <vsprintf+0x386>
			continue;
		}

		/* process flags */
		flags = 0;
		repeat: ++fmt; /* this also skips first '%' */
    2194:	89 c3                	mov    %eax,%ebx
    2196:	89 4c 24 24          	mov    %ecx,0x24(%esp)
				flags |= LEFT;
			}
		}

		/* get the precision */
		precision = -1;
    219a:	c7 04 24 ff ff ff ff 	movl   $0xffffffff,(%esp)
    21a1:	e9 8b fd ff ff       	jmp    1f31 <vsprintf+0x111>
			else
				--fmt;
			break;
		}
	}
	*str = '\0';
    21a6:	c6 45 00 00          	movb   $0x0,0x0(%ebp)
	return str - buf;
    21aa:	89 e8                	mov    %ebp,%eax
    21ac:	2b 44 24 1c          	sub    0x1c(%esp),%eax
}
    21b0:	83 c4 08             	add    $0x8,%esp
    21b3:	5b                   	pop    %ebx
    21b4:	5e                   	pop    %esi
    21b5:	5f                   	pop    %edi
    21b6:	5d                   	pop    %ebp
    21b7:	c3                   	ret    

000021b8 <sys_ftime>:
#include <sys/utsname.h>

int sys_ftime()
{
	return -ENOSYS;
}
    21b8:	b8 da ff ff ff       	mov    $0xffffffda,%eax
    21bd:	c3                   	ret    

000021be <sys_break>:

int sys_break()
{
	return -ENOSYS;
}
    21be:	b8 da ff ff ff       	mov    $0xffffffda,%eax
    21c3:	c3                   	ret    

000021c4 <sys_ptrace>:

int sys_ptrace()
{
	return -ENOSYS;
}
    21c4:	b8 da ff ff ff       	mov    $0xffffffda,%eax
    21c9:	c3                   	ret    

000021ca <sys_stty>:

int sys_stty()
{
	return -ENOSYS;
}
    21ca:	b8 da ff ff ff       	mov    $0xffffffda,%eax
    21cf:	c3                   	ret    

000021d0 <sys_gtty>:

int sys_gtty()
{
	return -ENOSYS;
}
    21d0:	b8 da ff ff ff       	mov    $0xffffffda,%eax
    21d5:	c3                   	ret    

000021d6 <sys_rename>:

int sys_rename()
{
	return -ENOSYS;
}
    21d6:	b8 da ff ff ff       	mov    $0xffffffda,%eax
    21db:	c3                   	ret    

000021dc <sys_prof>:

int sys_prof()
{
	return -ENOSYS;
}
    21dc:	b8 da ff ff ff       	mov    $0xffffffda,%eax
    21e1:	c3                   	ret    

000021e2 <sys_setregid>:

int sys_setregid(int rgid, int egid)
{
    21e2:	57                   	push   %edi
    21e3:	56                   	push   %esi
    21e4:	53                   	push   %ebx
    21e5:	8b 7c 24 10          	mov    0x10(%esp),%edi
    21e9:	8b 74 24 14          	mov    0x14(%esp),%esi
	struct task_struct* current = get_current_task();
    21ed:	e8 fc ff ff ff       	call   21ee <sys_setregid+0xc>
    21f2:	89 c3                	mov    %eax,%ebx
	if (rgid>0) {
    21f4:	85 ff                	test   %edi,%edi
    21f6:	7e 21                	jle    2219 <sys_setregid+0x37>
		if ((current->gid == rgid) || 
    21f8:	0f b7 80 46 02 00 00 	movzwl 0x246(%eax),%eax
    21ff:	39 c7                	cmp    %eax,%edi
    2201:	74 0f                	je     2212 <sys_setregid+0x30>
		    suser())
    2203:	e8 fc ff ff ff       	call   2204 <sys_setregid+0x22>

int sys_setregid(int rgid, int egid)
{
	struct task_struct* current = get_current_task();
	if (rgid>0) {
		if ((current->gid == rgid) || 
    2208:	66 83 b8 42 02 00 00 	cmpw   $0x0,0x242(%eax)
    220f:	00 
    2210:	75 49                	jne    225b <sys_setregid+0x79>
		    suser())
			current->gid = rgid;
    2212:	66 89 bb 46 02 00 00 	mov    %di,0x246(%ebx)
		else
			return(-EPERM);
	}
	if (egid>0) {
    2219:	85 f6                	test   %esi,%esi
    221b:	7e 45                	jle    2262 <sys_setregid+0x80>
		if ((current->gid == egid) ||
    221d:	0f b7 83 46 02 00 00 	movzwl 0x246(%ebx),%eax
    2224:	39 c6                	cmp    %eax,%esi
    2226:	74 25                	je     224d <sys_setregid+0x6b>
    2228:	0f b7 83 48 02 00 00 	movzwl 0x248(%ebx),%eax
    222f:	39 c6                	cmp    %eax,%esi
    2231:	74 1a                	je     224d <sys_setregid+0x6b>
		    (current->egid == egid) ||
    2233:	0f b7 83 4a 02 00 00 	movzwl 0x24a(%ebx),%eax
    223a:	39 c6                	cmp    %eax,%esi
    223c:	74 0f                	je     224d <sys_setregid+0x6b>
		    (current->sgid == egid) ||
		    suser())
    223e:	e8 fc ff ff ff       	call   223f <sys_setregid+0x5d>
			return(-EPERM);
	}
	if (egid>0) {
		if ((current->gid == egid) ||
		    (current->egid == egid) ||
		    (current->sgid == egid) ||
    2243:	66 83 b8 42 02 00 00 	cmpw   $0x0,0x242(%eax)
    224a:	00 
    224b:	75 1c                	jne    2269 <sys_setregid+0x87>
		    suser())
			current->egid = egid;
    224d:	66 89 b3 48 02 00 00 	mov    %si,0x248(%ebx)
		else
			return(-EPERM);
	}
	return 0;
    2254:	b8 00 00 00 00       	mov    $0x0,%eax
	if (egid>0) {
		if ((current->gid == egid) ||
		    (current->egid == egid) ||
		    (current->sgid == egid) ||
		    suser())
			current->egid = egid;
    2259:	eb 13                	jmp    226e <sys_setregid+0x8c>
	if (rgid>0) {
		if ((current->gid == rgid) || 
		    suser())
			current->gid = rgid;
		else
			return(-EPERM);
    225b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    2260:	eb 0c                	jmp    226e <sys_setregid+0x8c>
		    suser())
			current->egid = egid;
		else
			return(-EPERM);
	}
	return 0;
    2262:	b8 00 00 00 00       	mov    $0x0,%eax
    2267:	eb 05                	jmp    226e <sys_setregid+0x8c>
		    (current->egid == egid) ||
		    (current->sgid == egid) ||
		    suser())
			current->egid = egid;
		else
			return(-EPERM);
    2269:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	}
	return 0;
}
    226e:	5b                   	pop    %ebx
    226f:	5e                   	pop    %esi
    2270:	5f                   	pop    %edi
    2271:	c3                   	ret    

00002272 <sys_setgid>:

int sys_setgid(int gid)
{
    2272:	83 ec 14             	sub    $0x14,%esp
    2275:	8b 44 24 18          	mov    0x18(%esp),%eax
	return(sys_setregid(gid, gid));
    2279:	50                   	push   %eax
    227a:	50                   	push   %eax
    227b:	e8 fc ff ff ff       	call   227c <sys_setgid+0xa>
}
    2280:	83 c4 1c             	add    $0x1c,%esp
    2283:	c3                   	ret    

00002284 <sys_acct>:

int sys_acct()
{
	return -ENOSYS;
}
    2284:	b8 da ff ff ff       	mov    $0xffffffda,%eax
    2289:	c3                   	ret    

0000228a <sys_phys>:

int sys_phys()
{
	return -ENOSYS;
}
    228a:	b8 da ff ff ff       	mov    $0xffffffda,%eax
    228f:	c3                   	ret    

00002290 <sys_lock>:

int sys_lock()
{
	return -ENOSYS;
}
    2290:	b8 da ff ff ff       	mov    $0xffffffda,%eax
    2295:	c3                   	ret    

00002296 <sys_mpx>:

int sys_mpx()
{
	return -ENOSYS;
}
    2296:	b8 da ff ff ff       	mov    $0xffffffda,%eax
    229b:	c3                   	ret    

0000229c <sys_ulimit>:

int sys_ulimit()
{
	return -ENOSYS;
}
    229c:	b8 da ff ff ff       	mov    $0xffffffda,%eax
    22a1:	c3                   	ret    

000022a2 <sys_time>:

int sys_time(long * tloc)
{
    22a2:	56                   	push   %esi
    22a3:	53                   	push   %ebx
    22a4:	83 ec 04             	sub    $0x4,%esp
    22a7:	8b 74 24 10          	mov    0x10(%esp),%esi
	int i;

	i = CURRENT_TIME;
    22ab:	8b 0d 00 00 00 00    	mov    0x0,%ecx
    22b1:	ba 67 66 66 66       	mov    $0x66666667,%edx
    22b6:	89 c8                	mov    %ecx,%eax
    22b8:	f7 ea                	imul   %edx
    22ba:	c1 fa 02             	sar    $0x2,%edx
    22bd:	c1 f9 1f             	sar    $0x1f,%ecx
    22c0:	29 ca                	sub    %ecx,%edx
    22c2:	89 d3                	mov    %edx,%ebx
    22c4:	03 1d 00 00 00 00    	add    0x0,%ebx
	if (tloc) {
    22ca:	85 f6                	test   %esi,%esi
    22cc:	74 11                	je     22df <sys_time+0x3d>
		verify_area(tloc,4);
    22ce:	83 ec 08             	sub    $0x8,%esp
    22d1:	6a 04                	push   $0x4
    22d3:	56                   	push   %esi
    22d4:	e8 fc ff ff ff       	call   22d5 <sys_time+0x33>
__asm__ ("movw %0,%%fs:%1"::"r" (val),"m" (*addr));
}

static inline void put_fs_long(unsigned long val,unsigned long * addr)
{
__asm__ ("movl %0,%%fs:%1"::"r" (val),"m" (*addr));
    22d9:	64 89 1e             	mov    %ebx,%fs:(%esi)
    22dc:	83 c4 10             	add    $0x10,%esp
		put_fs_long(i,(unsigned long *)tloc);
	}
	return i;
}
    22df:	89 d8                	mov    %ebx,%eax
    22e1:	83 c4 04             	add    $0x4,%esp
    22e4:	5b                   	pop    %ebx
    22e5:	5e                   	pop    %esi
    22e6:	c3                   	ret    

000022e7 <sys_setreuid>:
/*
 * Unprivileged users may change the real user id to the effective uid
 * or vice versa.
 */
int sys_setreuid(int ruid, int euid)
{
    22e7:	55                   	push   %ebp
    22e8:	57                   	push   %edi
    22e9:	56                   	push   %esi
    22ea:	53                   	push   %ebx
    22eb:	83 ec 0c             	sub    $0xc,%esp
    22ee:	8b 74 24 24          	mov    0x24(%esp),%esi
	struct task_struct* current = get_current_task();
    22f2:	e8 fc ff ff ff       	call   22f3 <sys_setreuid+0xc>
    22f7:	89 c3                	mov    %eax,%ebx
	int old_ruid = current->uid;
    22f9:	0f b7 a8 40 02 00 00 	movzwl 0x240(%eax),%ebp
    2300:	0f b7 fd             	movzwl %bp,%edi
	
	if (ruid>0) {
    2303:	83 7c 24 20 00       	cmpl   $0x0,0x20(%esp)
    2308:	7e 2e                	jle    2338 <sys_setreuid+0x51>
		if ((current->euid==ruid) ||
    230a:	0f b7 80 42 02 00 00 	movzwl 0x242(%eax),%eax
    2311:	3b 44 24 20          	cmp    0x20(%esp),%eax
    2315:	74 15                	je     232c <sys_setreuid+0x45>
    2317:	3b 7c 24 20          	cmp    0x20(%esp),%edi
    231b:	74 0f                	je     232c <sys_setreuid+0x45>
                    (old_ruid == ruid) ||
		    suser())
    231d:	e8 fc ff ff ff       	call   231e <sys_setreuid+0x37>
	struct task_struct* current = get_current_task();
	int old_ruid = current->uid;
	
	if (ruid>0) {
		if ((current->euid==ruid) ||
                    (old_ruid == ruid) ||
    2322:	66 83 b8 42 02 00 00 	cmpw   $0x0,0x242(%eax)
    2329:	00 
    232a:	75 4a                	jne    2376 <sys_setreuid+0x8f>
		    suser())
			current->uid = ruid;
    232c:	0f b7 44 24 20       	movzwl 0x20(%esp),%eax
    2331:	66 89 83 40 02 00 00 	mov    %ax,0x240(%ebx)
		else
			return(-EPERM);
	}
	if (euid>0) {
    2338:	85 f6                	test   %esi,%esi
    233a:	7e 41                	jle    237d <sys_setreuid+0x96>
		if ((old_ruid == euid) ||
    233c:	39 f7                	cmp    %esi,%edi
    233e:	74 1a                	je     235a <sys_setreuid+0x73>
    2340:	0f b7 83 42 02 00 00 	movzwl 0x242(%ebx),%eax
    2347:	39 c6                	cmp    %eax,%esi
    2349:	74 0f                	je     235a <sys_setreuid+0x73>
                    (current->euid == euid) ||
		    suser())
    234b:	e8 fc ff ff ff       	call   234c <sys_setreuid+0x65>
		else
			return(-EPERM);
	}
	if (euid>0) {
		if ((old_ruid == euid) ||
                    (current->euid == euid) ||
    2350:	66 83 b8 42 02 00 00 	cmpw   $0x0,0x242(%eax)
    2357:	00 
    2358:	75 0e                	jne    2368 <sys_setreuid+0x81>
		    suser())
			current->euid = euid;
    235a:	66 89 b3 42 02 00 00 	mov    %si,0x242(%ebx)
		else {
			current->uid = old_ruid;
			return(-EPERM);
		}
	}
	return 0;
    2361:	b8 00 00 00 00       	mov    $0x0,%eax
	}
	if (euid>0) {
		if ((old_ruid == euid) ||
                    (current->euid == euid) ||
		    suser())
			current->euid = euid;
    2366:	eb 1a                	jmp    2382 <sys_setreuid+0x9b>
		else {
			current->uid = old_ruid;
    2368:	66 89 ab 40 02 00 00 	mov    %bp,0x240(%ebx)
			return(-EPERM);
    236f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    2374:	eb 0c                	jmp    2382 <sys_setreuid+0x9b>
		if ((current->euid==ruid) ||
                    (old_ruid == ruid) ||
		    suser())
			current->uid = ruid;
		else
			return(-EPERM);
    2376:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    237b:	eb 05                	jmp    2382 <sys_setreuid+0x9b>
		else {
			current->uid = old_ruid;
			return(-EPERM);
		}
	}
	return 0;
    237d:	b8 00 00 00 00       	mov    $0x0,%eax
}
    2382:	83 c4 0c             	add    $0xc,%esp
    2385:	5b                   	pop    %ebx
    2386:	5e                   	pop    %esi
    2387:	5f                   	pop    %edi
    2388:	5d                   	pop    %ebp
    2389:	c3                   	ret    

0000238a <sys_setuid>:

int sys_setuid(int uid)
{
    238a:	83 ec 14             	sub    $0x14,%esp
    238d:	8b 44 24 18          	mov    0x18(%esp),%eax
	return(sys_setreuid(uid, uid));
    2391:	50                   	push   %eax
    2392:	50                   	push   %eax
    2393:	e8 fc ff ff ff       	call   2394 <sys_setuid+0xa>
}
    2398:	83 c4 1c             	add    $0x1c,%esp
    239b:	c3                   	ret    

0000239c <sys_stime>:

int sys_stime(long * tptr)
{
    239c:	53                   	push   %ebx
    239d:	83 ec 08             	sub    $0x8,%esp
	if (!suser())
    23a0:	e8 fc ff ff ff       	call   23a1 <sys_stime+0x5>
    23a5:	66 83 b8 42 02 00 00 	cmpw   $0x0,0x242(%eax)
    23ac:	00 
    23ad:	75 2d                	jne    23dc <sys_stime+0x40>

static inline unsigned long get_fs_long(const unsigned long *addr)
{
	unsigned long _v;

	__asm__ ("movl %%fs:%1,%0":"=r" (_v):"m" (*addr)); \
    23af:	8b 44 24 10          	mov    0x10(%esp),%eax
    23b3:	64 8b 08             	mov    %fs:(%eax),%ecx
		return -EPERM;
	startup_time = get_fs_long((unsigned long *)tptr) - jiffies/HZ;
    23b6:	8b 1d 00 00 00 00    	mov    0x0,%ebx
    23bc:	ba 67 66 66 66       	mov    $0x66666667,%edx
    23c1:	89 d8                	mov    %ebx,%eax
    23c3:	f7 ea                	imul   %edx
    23c5:	c1 fa 02             	sar    $0x2,%edx
    23c8:	c1 fb 1f             	sar    $0x1f,%ebx
    23cb:	29 da                	sub    %ebx,%edx
    23cd:	29 d1                	sub    %edx,%ecx
    23cf:	89 0d 00 00 00 00    	mov    %ecx,0x0
	return 0;
    23d5:	b8 00 00 00 00       	mov    $0x0,%eax
    23da:	eb 05                	jmp    23e1 <sys_stime+0x45>
}

int sys_stime(long * tptr)
{
	if (!suser())
		return -EPERM;
    23dc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	startup_time = get_fs_long((unsigned long *)tptr) - jiffies/HZ;
	return 0;
}
    23e1:	83 c4 08             	add    $0x8,%esp
    23e4:	5b                   	pop    %ebx
    23e5:	c3                   	ret    

000023e6 <sys_times>:

int sys_times(struct tms * tbuf)
{
    23e6:	56                   	push   %esi
    23e7:	53                   	push   %ebx
    23e8:	83 ec 04             	sub    $0x4,%esp
    23eb:	8b 5c 24 10          	mov    0x10(%esp),%ebx
	if (tbuf) {
    23ef:	85 db                	test   %ebx,%ebx
    23f1:	74 3c                	je     242f <sys_times+0x49>
		struct task_struct* current = get_current_task();
    23f3:	e8 fc ff ff ff       	call   23f4 <sys_times+0xe>
    23f8:	89 c6                	mov    %eax,%esi
		verify_area(tbuf,sizeof *tbuf);
    23fa:	83 ec 08             	sub    $0x8,%esp
    23fd:	6a 10                	push   $0x10
    23ff:	53                   	push   %ebx
    2400:	e8 fc ff ff ff       	call   2401 <sys_times+0x1b>
__asm__ ("movw %0,%%fs:%1"::"r" (val),"m" (*addr));
}

static inline void put_fs_long(unsigned long val,unsigned long * addr)
{
__asm__ ("movl %0,%%fs:%1"::"r" (val),"m" (*addr));
    2405:	8b 86 50 02 00 00    	mov    0x250(%esi),%eax
    240b:	64 89 03             	mov    %eax,%fs:(%ebx)
    240e:	8b 86 54 02 00 00    	mov    0x254(%esi),%eax
    2414:	64 89 43 04          	mov    %eax,%fs:0x4(%ebx)
    2418:	8b 86 58 02 00 00    	mov    0x258(%esi),%eax
    241e:	64 89 43 08          	mov    %eax,%fs:0x8(%ebx)
    2422:	8b 86 5c 02 00 00    	mov    0x25c(%esi),%eax
    2428:	64 89 43 0c          	mov    %eax,%fs:0xc(%ebx)
    242c:	83 c4 10             	add    $0x10,%esp
		put_fs_long(current->utime,(unsigned long *)&tbuf->tms_utime);
		put_fs_long(current->stime,(unsigned long *)&tbuf->tms_stime);
		put_fs_long(current->cutime,(unsigned long *)&tbuf->tms_cutime);
		put_fs_long(current->cstime,(unsigned long *)&tbuf->tms_cstime);
	}
	return jiffies;
    242f:	a1 00 00 00 00       	mov    0x0,%eax
}
    2434:	83 c4 04             	add    $0x4,%esp
    2437:	5b                   	pop    %ebx
    2438:	5e                   	pop    %esi
    2439:	c3                   	ret    

0000243a <sys_brk>:

int sys_brk(unsigned long end_data_seg)
{
    243a:	53                   	push   %ebx
    243b:	83 ec 08             	sub    $0x8,%esp
    243e:	8b 5c 24 10          	mov    0x10(%esp),%ebx
	struct task_struct* current = get_current_task();
    2442:	e8 fc ff ff ff       	call   2443 <sys_brk+0x9>
	if (end_data_seg >= current->end_code &&
    2447:	39 98 1c 02 00 00    	cmp    %ebx,0x21c(%eax)
    244d:	77 16                	ja     2465 <sys_brk+0x2b>
    244f:	8b 88 28 02 00 00    	mov    0x228(%eax),%ecx
    2455:	8d 91 00 c0 ff ff    	lea    -0x4000(%ecx),%edx
    245b:	39 d3                	cmp    %edx,%ebx
    245d:	73 06                	jae    2465 <sys_brk+0x2b>
	    end_data_seg < current->start_stack - 16384)
		current->brk = end_data_seg;
    245f:	89 98 24 02 00 00    	mov    %ebx,0x224(%eax)
	return current->brk;
    2465:	8b 80 24 02 00 00    	mov    0x224(%eax),%eax
}
    246b:	83 c4 08             	add    $0x8,%esp
    246e:	5b                   	pop    %ebx
    246f:	c3                   	ret    

00002470 <sys_setpgid>:
 * This needs some heave checking ...
 * I just haven't get the stomach for it. I also don't fully
 * understand sessions/pgrp etc. Let somebody who does explain it.
 */
int sys_setpgid(int pid, int pgid)
{
    2470:	57                   	push   %edi
    2471:	56                   	push   %esi
    2472:	53                   	push   %ebx
    2473:	8b 5c 24 10          	mov    0x10(%esp),%ebx
    2477:	8b 74 24 14          	mov    0x14(%esp),%esi
	struct task_struct* current = get_current_task();
    247b:	e8 fc ff ff ff       	call   247c <sys_setpgid+0xc>
	int i;

	if (!pid)
    2480:	85 db                	test   %ebx,%ebx
    2482:	75 06                	jne    248a <sys_setpgid+0x1a>
		pid = current->pid;
    2484:	8b 98 2c 02 00 00    	mov    0x22c(%eax),%ebx
	if (!pgid)
    248a:	85 f6                	test   %esi,%esi
    248c:	75 06                	jne    2494 <sys_setpgid+0x24>
		pgid = current->pid;
    248e:	8b b0 2c 02 00 00    	mov    0x22c(%eax),%esi
    2494:	ba 00 00 00 00       	mov    $0x0,%edx
    2499:	bf 00 01 00 00       	mov    $0x100,%edi
	for (i=0 ; i<NR_TASKS ; i++)
		if (task[i] && task[i]->pid==pid) {
    249e:	8b 0a                	mov    (%edx),%ecx
    24a0:	85 c9                	test   %ecx,%ecx
    24a2:	74 2c                	je     24d0 <sys_setpgid+0x60>
    24a4:	3b 99 2c 02 00 00    	cmp    0x22c(%ecx),%ebx
    24aa:	75 24                	jne    24d0 <sys_setpgid+0x60>
			if (task[i]->leader)
    24ac:	83 b9 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ecx)
    24b3:	75 29                	jne    24de <sys_setpgid+0x6e>
				return -EPERM;
			if (task[i]->session != current->session)
    24b5:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
    24bb:	39 81 38 02 00 00    	cmp    %eax,0x238(%ecx)
    24c1:	75 22                	jne    24e5 <sys_setpgid+0x75>
				return -EPERM;
			task[i]->pgrp = pgid;
    24c3:	89 b1 34 02 00 00    	mov    %esi,0x234(%ecx)
			return 0;
    24c9:	b8 00 00 00 00       	mov    $0x0,%eax
    24ce:	eb 1a                	jmp    24ea <sys_setpgid+0x7a>
    24d0:	83 c2 04             	add    $0x4,%edx

	if (!pid)
		pid = current->pid;
	if (!pgid)
		pgid = current->pid;
	for (i=0 ; i<NR_TASKS ; i++)
    24d3:	39 fa                	cmp    %edi,%edx
    24d5:	75 c7                	jne    249e <sys_setpgid+0x2e>
			if (task[i]->session != current->session)
				return -EPERM;
			task[i]->pgrp = pgid;
			return 0;
		}
	return -ESRCH;
    24d7:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
    24dc:	eb 0c                	jmp    24ea <sys_setpgid+0x7a>
	if (!pgid)
		pgid = current->pid;
	for (i=0 ; i<NR_TASKS ; i++)
		if (task[i] && task[i]->pid==pid) {
			if (task[i]->leader)
				return -EPERM;
    24de:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    24e3:	eb 05                	jmp    24ea <sys_setpgid+0x7a>
			if (task[i]->session != current->session)
				return -EPERM;
    24e5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
			task[i]->pgrp = pgid;
			return 0;
		}
	return -ESRCH;
}
    24ea:	5b                   	pop    %ebx
    24eb:	5e                   	pop    %esi
    24ec:	5f                   	pop    %edi
    24ed:	c3                   	ret    

000024ee <sys_getpgrp>:

int sys_getpgrp(void)
{
    24ee:	83 ec 0c             	sub    $0xc,%esp
	struct task_struct* current = get_current_task();
    24f1:	e8 fc ff ff ff       	call   24f2 <sys_getpgrp+0x4>
	return current->pgrp;
    24f6:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
}
    24fc:	83 c4 0c             	add    $0xc,%esp
    24ff:	c3                   	ret    

00002500 <sys_setsid>:

int sys_setsid(void)
{
    2500:	53                   	push   %ebx
    2501:	83 ec 08             	sub    $0x8,%esp
	struct task_struct* current = get_current_task();
    2504:	e8 fc ff ff ff       	call   2505 <sys_setsid+0x5>
    2509:	89 c3                	mov    %eax,%ebx
	if (current->leader && !suser())
    250b:	83 b8 3c 02 00 00 00 	cmpl   $0x0,0x23c(%eax)
    2512:	74 0f                	je     2523 <sys_setsid+0x23>
    2514:	e8 fc ff ff ff       	call   2515 <sys_setsid+0x15>
    2519:	66 83 b8 42 02 00 00 	cmpw   $0x0,0x242(%eax)
    2520:	00 
    2521:	75 28                	jne    254b <sys_setsid+0x4b>
		return -EPERM;
	current->leader = 1;
    2523:	c7 83 3c 02 00 00 01 	movl   $0x1,0x23c(%ebx)
    252a:	00 00 00 
	current->session = current->pgrp = current->pid;
    252d:	8b 83 2c 02 00 00    	mov    0x22c(%ebx),%eax
    2533:	89 83 34 02 00 00    	mov    %eax,0x234(%ebx)
    2539:	89 83 38 02 00 00    	mov    %eax,0x238(%ebx)
	current->tty = -1;
    253f:	c7 83 68 02 00 00 ff 	movl   $0xffffffff,0x268(%ebx)
    2546:	ff ff ff 
	//printk("setsid, pid: %d\n\r", current->pid);
	return current->pgrp;
    2549:	eb 05                	jmp    2550 <sys_setsid+0x50>

int sys_setsid(void)
{
	struct task_struct* current = get_current_task();
	if (current->leader && !suser())
		return -EPERM;
    254b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	current->leader = 1;
	current->session = current->pgrp = current->pid;
	current->tty = -1;
	//printk("setsid, pid: %d\n\r", current->pid);
	return current->pgrp;
}
    2550:	83 c4 08             	add    $0x8,%esp
    2553:	5b                   	pop    %ebx
    2554:	c3                   	ret    

00002555 <sys_uname>:

int sys_uname(struct utsname * name)
{
    2555:	53                   	push   %ebx
    2556:	83 ec 08             	sub    $0x8,%esp
    2559:	8b 5c 24 10          	mov    0x10(%esp),%ebx
	static struct utsname thisname = {
		"linux .0","nodename","release ","version ","machine "
	};
	int i;

	if (!name) return -ERROR;
    255d:	85 db                	test   %ebx,%ebx
    255f:	74 2d                	je     258e <sys_uname+0x39>
	verify_area(name,sizeof *name);
    2561:	83 ec 08             	sub    $0x8,%esp
    2564:	6a 2d                	push   $0x2d
    2566:	53                   	push   %ebx
    2567:	e8 fc ff ff ff       	call   2568 <sys_uname+0x13>
    256c:	83 c4 10             	add    $0x10,%esp
    256f:	b8 00 00 00 00       	mov    $0x0,%eax
	return _v;
}

static inline void put_fs_byte(char val,char *addr)
{
__asm__ ("movb %0,%%fs:%1"::"q" (val),"m" (*addr));
    2574:	0f b6 90 40 3d 00 00 	movzbl 0x3d40(%eax),%edx
    257b:	64 88 14 03          	mov    %dl,%fs:(%ebx,%eax,1)
	for(i=0;i<sizeof *name;i++)
    257f:	83 c0 01             	add    $0x1,%eax
    2582:	83 f8 2d             	cmp    $0x2d,%eax
    2585:	75 ed                	jne    2574 <sys_uname+0x1f>
		put_fs_byte(((char *) &thisname)[i],i+(char *) name);
	return 0;
    2587:	b8 00 00 00 00       	mov    $0x0,%eax
    258c:	eb 05                	jmp    2593 <sys_uname+0x3e>
	static struct utsname thisname = {
		"linux .0","nodename","release ","version ","machine "
	};
	int i;

	if (!name) return -ERROR;
    258e:	b8 9d ff ff ff       	mov    $0xffffff9d,%eax
	verify_area(name,sizeof *name);
	for(i=0;i<sizeof *name;i++)
		put_fs_byte(((char *) &thisname)[i],i+(char *) name);
	return 0;
}
    2593:	83 c4 08             	add    $0x8,%esp
    2596:	5b                   	pop    %ebx
    2597:	c3                   	ret    

00002598 <sys_umask>:

int sys_umask(int mask)
{
    2598:	83 ec 0c             	sub    $0xc,%esp
	struct task_struct* current = get_current_task();
    259b:	e8 fc ff ff ff       	call   259c <sys_umask+0x4>
    25a0:	89 c1                	mov    %eax,%ecx
	int old = current->umask;
    25a2:	0f b7 80 6c 02 00 00 	movzwl 0x26c(%eax),%eax

	current->umask = mask & 0777;
    25a9:	0f b7 54 24 10       	movzwl 0x10(%esp),%edx
    25ae:	66 81 e2 ff 01       	and    $0x1ff,%dx
    25b3:	66 89 91 6c 02 00 00 	mov    %dx,0x26c(%ecx)
	return (old);
}
    25ba:	83 c4 0c             	add    $0xc,%esp
    25bd:	c3                   	ret    

000025be <release>:
extern void ap_default_loop(void);
extern struct apic_info apic_ids[LOGICAL_PROCESSOR_NUM];
extern unsigned long sched_semaphore;

void release(struct task_struct * p)
{
    25be:	56                   	push   %esi
    25bf:	53                   	push   %ebx
    25c0:	83 ec 04             	sub    $0x4,%esp
    25c3:	8b 74 24 10          	mov    0x10(%esp),%esi
	int i;

	if (!p)
    25c7:	85 f6                	test   %esi,%esi
    25c9:	0f 84 ad 00 00 00    	je     267c <release+0xbe>
		return;
	for (i=1 ; i<NR_TASKS ; i++)
		if (task[i]==p) {
    25cf:	3b 35 04 00 00 00    	cmp    0x4,%esi
    25d5:	74 10                	je     25e7 <release+0x29>
    25d7:	bb 02 00 00 00       	mov    $0x2,%ebx
    25dc:	3b 34 9d 00 00 00 00 	cmp    0x0(,%ebx,4),%esi
    25e3:	75 7b                	jne    2660 <release+0xa2>
    25e5:	eb 05                	jmp    25ec <release+0x2e>
    25e7:	bb 01 00 00 00       	mov    $0x1,%ebx
			 *	 AP2释放完该*p,那么有可能被AP3上的进程占用了,此时AP1上在执行如下的代码,就可能会破坏AP3上进程的内存页数据,
			 *	 造成AP3上运行的进程崩溃.
			 *	(*p)->counter = ((*p)->counter >> 1) + (*p)->priority;
			 * }
			 */
			lock_op(&sched_semaphore);
    25ec:	83 ec 0c             	sub    $0xc,%esp
    25ef:	68 00 00 00 00       	push   $0x0
    25f4:	e8 fc ff ff ff       	call   25f5 <release+0x37>
			task[i]=NULL;
    25f9:	c7 04 9d 00 00 00 00 	movl   $0x0,0x0(,%ebx,4)
    2600:	00 00 00 00 
			if (!free_page((long)(p->tss.cr3)))  /* 先把该进程占用的目录表释放掉 */
    2604:	83 c4 04             	add    $0x4,%esp
    2607:	ff b6 04 03 00 00    	pushl  0x304(%esi)
    260d:	e8 fc ff ff ff       	call   260e <release+0x50>
    2612:	83 c4 10             	add    $0x10,%esp
    2615:	85 c0                	test   %eax,%eax
    2617:	75 10                	jne    2629 <release+0x6b>
				panic("exit.release dir: trying to free free page");
    2619:	83 ec 0c             	sub    $0xc,%esp
    261c:	68 0c 02 00 00       	push   $0x20c
    2621:	e8 fc ff ff ff       	call   2622 <release+0x64>
    2626:	83 c4 10             	add    $0x10,%esp
			if (!free_page((long)p))
    2629:	83 ec 0c             	sub    $0xc,%esp
    262c:	56                   	push   %esi
    262d:	e8 fc ff ff ff       	call   262e <release+0x70>
    2632:	83 c4 10             	add    $0x10,%esp
    2635:	85 c0                	test   %eax,%eax
    2637:	75 10                	jne    2649 <release+0x8b>
				panic("exit.release: trying to free free page");
    2639:	83 ec 0c             	sub    $0xc,%esp
    263c:	68 38 02 00 00       	push   $0x238
    2641:	e8 fc ff ff ff       	call   2642 <release+0x84>
    2646:	83 c4 10             	add    $0x10,%esp
			unlock_op(&sched_semaphore);
    2649:	83 ec 0c             	sub    $0xc,%esp
    264c:	68 00 00 00 00       	push   $0x0
    2651:	e8 fc ff ff ff       	call   2652 <release+0x94>
			schedule();
    2656:	e8 fc ff ff ff       	call   2657 <release+0x99>
			return;
    265b:	83 c4 10             	add    $0x10,%esp
    265e:	eb 1c                	jmp    267c <release+0xbe>
{
	int i;

	if (!p)
		return;
	for (i=1 ; i<NR_TASKS ; i++)
    2660:	83 c3 01             	add    $0x1,%ebx
    2663:	83 fb 40             	cmp    $0x40,%ebx
    2666:	0f 85 70 ff ff ff    	jne    25dc <release+0x1e>
				panic("exit.release: trying to free free page");
			unlock_op(&sched_semaphore);
			schedule();
			return;
		}
	panic("trying to release non-existent task");
    266c:	83 ec 0c             	sub    $0xc,%esp
    266f:	68 60 02 00 00       	push   $0x260
    2674:	e8 fc ff ff ff       	call   2675 <release+0xb7>
    2679:	83 c4 10             	add    $0x10,%esp
}
    267c:	83 c4 04             	add    $0x4,%esp
    267f:	5b                   	pop    %ebx
    2680:	5e                   	pop    %esi
    2681:	c3                   	ret    

00002682 <send_sig>:

int send_sig(long sig,struct task_struct * p,int priv)
{
    2682:	56                   	push   %esi
    2683:	53                   	push   %ebx
    2684:	83 ec 04             	sub    $0x4,%esp
    2687:	8b 5c 24 10          	mov    0x10(%esp),%ebx
    268b:	8b 74 24 14          	mov    0x14(%esp),%esi
	struct task_struct* current = get_current_task();
    268f:	e8 fc ff ff ff       	call   2690 <send_sig+0xe>
	if (!p || sig<1 || sig>32)
    2694:	8d 53 ff             	lea    -0x1(%ebx),%edx
    2697:	83 fa 1f             	cmp    $0x1f,%edx
    269a:	77 3e                	ja     26da <send_sig+0x58>
    269c:	85 f6                	test   %esi,%esi
    269e:	74 3a                	je     26da <send_sig+0x58>
		return -EINVAL;
	if (priv || (current->euid==p->euid) || suser())
    26a0:	83 7c 24 18 00       	cmpl   $0x0,0x18(%esp)
    26a5:	75 1f                	jne    26c6 <send_sig+0x44>
    26a7:	0f b7 8e 42 02 00 00 	movzwl 0x242(%esi),%ecx
    26ae:	66 39 88 42 02 00 00 	cmp    %cx,0x242(%eax)
    26b5:	74 0f                	je     26c6 <send_sig+0x44>
    26b7:	e8 fc ff ff ff       	call   26b8 <send_sig+0x36>
    26bc:	66 83 b8 42 02 00 00 	cmpw   $0x0,0x242(%eax)
    26c3:	00 
    26c4:	75 1b                	jne    26e1 <send_sig+0x5f>
		p->signal |= (1<<(sig-1));
    26c6:	8d 4b ff             	lea    -0x1(%ebx),%ecx
    26c9:	b8 01 00 00 00       	mov    $0x1,%eax
    26ce:	d3 e0                	shl    %cl,%eax
    26d0:	09 46 0c             	or     %eax,0xc(%esi)
	else
		return -EPERM;
	return 0;
    26d3:	b8 00 00 00 00       	mov    $0x0,%eax
    26d8:	eb 0c                	jmp    26e6 <send_sig+0x64>

int send_sig(long sig,struct task_struct * p,int priv)
{
	struct task_struct* current = get_current_task();
	if (!p || sig<1 || sig>32)
		return -EINVAL;
    26da:	b8 ea ff ff ff       	mov    $0xffffffea,%eax
    26df:	eb 05                	jmp    26e6 <send_sig+0x64>
	if (priv || (current->euid==p->euid) || suser())
		p->signal |= (1<<(sig-1));
	else
		return -EPERM;
    26e1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return 0;
}
    26e6:	83 c4 04             	add    $0x4,%esp
    26e9:	5b                   	pop    %ebx
    26ea:	5e                   	pop    %esi
    26eb:	c3                   	ret    

000026ec <kill_session>:

void kill_session(void)
{
    26ec:	53                   	push   %ebx
    26ed:	83 ec 08             	sub    $0x8,%esp
	struct task_struct* current = get_current_task();
    26f0:	e8 fc ff ff ff       	call   26f1 <kill_session+0x5>
	struct task_struct **p = NR_TASKS + task;
    26f5:	ba 00 01 00 00       	mov    $0x100,%edx
	
	while (--p > &FIRST_TASK) {
    26fa:	eb 18                	jmp    2714 <kill_session+0x28>
		if (*p && (*p)->session == current->session)
    26fc:	8b 0a                	mov    (%edx),%ecx
    26fe:	85 c9                	test   %ecx,%ecx
    2700:	74 12                	je     2714 <kill_session+0x28>
    2702:	8b 98 38 02 00 00    	mov    0x238(%eax),%ebx
    2708:	39 99 38 02 00 00    	cmp    %ebx,0x238(%ecx)
    270e:	75 04                	jne    2714 <kill_session+0x28>
			(*p)->signal |= 1<<(SIGHUP-1);
    2710:	83 49 0c 01          	orl    $0x1,0xc(%ecx)
void kill_session(void)
{
	struct task_struct* current = get_current_task();
	struct task_struct **p = NR_TASKS + task;
	
	while (--p > &FIRST_TASK) {
    2714:	83 ea 04             	sub    $0x4,%edx
    2717:	81 fa 00 00 00 00    	cmp    $0x0,%edx
    271d:	75 dd                	jne    26fc <kill_session+0x10>
		if (*p && (*p)->session == current->session)
			(*p)->signal |= 1<<(SIGHUP-1);
	}
}
    271f:	83 c4 08             	add    $0x8,%esp
    2722:	5b                   	pop    %ebx
    2723:	c3                   	ret    

00002724 <sys_kill>:
/*
 * XXX need to check permissions needed to send signals to process
 * groups, etc. etc.  kill() permissions semantics are tricky!
 */
int sys_kill(int pid,int sig)
{
    2724:	55                   	push   %ebp
    2725:	57                   	push   %edi
    2726:	56                   	push   %esi
    2727:	53                   	push   %ebx
    2728:	83 ec 0c             	sub    $0xc,%esp
    272b:	8b 5c 24 20          	mov    0x20(%esp),%ebx
    272f:	8b 6c 24 24          	mov    0x24(%esp),%ebp
	struct task_struct* current = get_current_task();
    2733:	e8 fc ff ff ff       	call   2734 <sys_kill+0x10>
	struct task_struct **p = NR_TASKS + task;
	int err, retval = 0;

	if (!pid) while (--p > &FIRST_TASK) {
    2738:	85 db                	test   %ebx,%ebx
    273a:	74 2c                	je     2768 <sys_kill+0x44>
    273c:	eb 46                	jmp    2784 <sys_kill+0x60>
		if (*p && (*p)->pgrp == current->pid) 
    273e:	8b 03                	mov    (%ebx),%eax
    2740:	85 c0                	test   %eax,%eax
    2742:	74 30                	je     2774 <sys_kill+0x50>
    2744:	8b 96 2c 02 00 00    	mov    0x22c(%esi),%edx
    274a:	39 90 34 02 00 00    	cmp    %edx,0x234(%eax)
    2750:	75 22                	jne    2774 <sys_kill+0x50>
			if (err=send_sig(sig,*p,1))
    2752:	83 ec 04             	sub    $0x4,%esp
    2755:	6a 01                	push   $0x1
    2757:	50                   	push   %eax
    2758:	55                   	push   %ebp
    2759:	e8 fc ff ff ff       	call   275a <sys_kill+0x36>
    275e:	83 c4 10             	add    $0x10,%esp
				retval = err;
    2761:	85 c0                	test   %eax,%eax
    2763:	0f 45 f8             	cmovne %eax,%edi
    2766:	eb 0c                	jmp    2774 <sys_kill+0x50>
    2768:	89 c6                	mov    %eax,%esi
    276a:	bf 00 00 00 00       	mov    $0x0,%edi
    276f:	bb 00 01 00 00       	mov    $0x100,%ebx
{
	struct task_struct* current = get_current_task();
	struct task_struct **p = NR_TASKS + task;
	int err, retval = 0;

	if (!pid) while (--p > &FIRST_TASK) {
    2774:	83 eb 04             	sub    $0x4,%ebx
    2777:	81 fb 00 00 00 00    	cmp    $0x0,%ebx
    277d:	75 bf                	jne    273e <sys_kill+0x1a>
    277f:	e9 aa 00 00 00       	jmp    282e <sys_kill+0x10a>
    2784:	bf 00 00 00 00       	mov    $0x0,%edi
    2789:	be 00 01 00 00       	mov    $0x100,%esi
		if (*p && (*p)->pgrp == current->pid) 
			if (err=send_sig(sig,*p,1))
				retval = err;
	} else if (pid>0) while (--p > &FIRST_TASK) {
    278e:	85 db                	test   %ebx,%ebx
    2790:	7f 24                	jg     27b6 <sys_kill+0x92>
    2792:	eb 2f                	jmp    27c3 <sys_kill+0x9f>
		if (*p && (*p)->pid == pid) 
    2794:	8b 06                	mov    (%esi),%eax
    2796:	85 c0                	test   %eax,%eax
    2798:	74 1c                	je     27b6 <sys_kill+0x92>
    279a:	3b 98 2c 02 00 00    	cmp    0x22c(%eax),%ebx
    27a0:	75 14                	jne    27b6 <sys_kill+0x92>
			if (err=send_sig(sig,*p,0))
    27a2:	83 ec 04             	sub    $0x4,%esp
    27a5:	6a 00                	push   $0x0
    27a7:	50                   	push   %eax
    27a8:	55                   	push   %ebp
    27a9:	e8 fc ff ff ff       	call   27aa <sys_kill+0x86>
    27ae:	83 c4 10             	add    $0x10,%esp
				retval = err;
    27b1:	85 c0                	test   %eax,%eax
    27b3:	0f 45 f8             	cmovne %eax,%edi

	if (!pid) while (--p > &FIRST_TASK) {
		if (*p && (*p)->pgrp == current->pid) 
			if (err=send_sig(sig,*p,1))
				retval = err;
	} else if (pid>0) while (--p > &FIRST_TASK) {
    27b6:	83 ee 04             	sub    $0x4,%esi
    27b9:	81 fe 00 00 00 00    	cmp    $0x0,%esi
    27bf:	75 d3                	jne    2794 <sys_kill+0x70>
    27c1:	eb 6b                	jmp    282e <sys_kill+0x10a>
 */
int sys_kill(int pid,int sig)
{
	struct task_struct* current = get_current_task();
	struct task_struct **p = NR_TASKS + task;
	int err, retval = 0;
    27c3:	bf 00 00 00 00       	mov    $0x0,%edi
				retval = err;
	} else if (pid>0) while (--p > &FIRST_TASK) {
		if (*p && (*p)->pid == pid) 
			if (err=send_sig(sig,*p,0))
				retval = err;
	} else if (pid == -1) while (--p > &FIRST_TASK)
    27c8:	83 fb ff             	cmp    $0xffffffff,%ebx
    27cb:	75 61                	jne    282e <sys_kill+0x10a>
    27cd:	eb 46                	jmp    2815 <sys_kill+0xf1>
		if (err = send_sig(sig,*p,0))
    27cf:	83 ec 04             	sub    $0x4,%esp
    27d2:	6a 00                	push   $0x0
    27d4:	ff 33                	pushl  (%ebx)
    27d6:	55                   	push   %ebp
    27d7:	e8 fc ff ff ff       	call   27d8 <sys_kill+0xb4>
    27dc:	83 c4 10             	add    $0x10,%esp
    27df:	85 c0                	test   %eax,%eax
    27e1:	75 3e                	jne    2821 <sys_kill+0xfd>
    27e3:	eb 23                	jmp    2808 <sys_kill+0xe4>
			retval = err;
	else while (--p > &FIRST_TASK)
		if (*p && (*p)->pgrp == -pid)
    27e5:	8b 03                	mov    (%ebx),%eax
    27e7:	85 c0                	test   %eax,%eax
    27e9:	74 1d                	je     2808 <sys_kill+0xe4>
    27eb:	83 b8 34 02 00 00 01 	cmpl   $0x1,0x234(%eax)
    27f2:	75 14                	jne    2808 <sys_kill+0xe4>
			if (err = send_sig(sig,*p,0))
    27f4:	83 ec 04             	sub    $0x4,%esp
    27f7:	6a 00                	push   $0x0
    27f9:	50                   	push   %eax
    27fa:	55                   	push   %ebp
    27fb:	e8 fc ff ff ff       	call   27fc <sys_kill+0xd8>
    2800:	83 c4 10             	add    $0x10,%esp
				retval = err;
    2803:	85 c0                	test   %eax,%eax
    2805:	0f 45 f8             	cmovne %eax,%edi
			if (err=send_sig(sig,*p,0))
				retval = err;
	} else if (pid == -1) while (--p > &FIRST_TASK)
		if (err = send_sig(sig,*p,0))
			retval = err;
	else while (--p > &FIRST_TASK)
    2808:	83 eb 04             	sub    $0x4,%ebx
    280b:	81 fb 00 00 00 00    	cmp    $0x0,%ebx
    2811:	77 d2                	ja     27e5 <sys_kill+0xc1>
    2813:	eb 0e                	jmp    2823 <sys_kill+0xff>
    2815:	bf 00 00 00 00       	mov    $0x0,%edi
    281a:	bb 00 01 00 00       	mov    $0x100,%ebx
    281f:	eb 02                	jmp    2823 <sys_kill+0xff>
		if (*p && (*p)->pid == pid) 
			if (err=send_sig(sig,*p,0))
				retval = err;
	} else if (pid == -1) while (--p > &FIRST_TASK)
		if (err = send_sig(sig,*p,0))
			retval = err;
    2821:	89 c7                	mov    %eax,%edi
				retval = err;
	} else if (pid>0) while (--p > &FIRST_TASK) {
		if (*p && (*p)->pid == pid) 
			if (err=send_sig(sig,*p,0))
				retval = err;
	} else if (pid == -1) while (--p > &FIRST_TASK)
    2823:	83 eb 04             	sub    $0x4,%ebx
    2826:	81 fb 00 00 00 00    	cmp    $0x0,%ebx
    282c:	77 a1                	ja     27cf <sys_kill+0xab>
	else while (--p > &FIRST_TASK)
		if (*p && (*p)->pgrp == -pid)
			if (err = send_sig(sig,*p,0))
				retval = err;
	return retval;
}
    282e:	89 f8                	mov    %edi,%eax
    2830:	83 c4 0c             	add    $0xc,%esp
    2833:	5b                   	pop    %ebx
    2834:	5e                   	pop    %esi
    2835:	5f                   	pop    %edi
    2836:	5d                   	pop    %ebp
    2837:	c3                   	ret    

00002838 <tell_father>:

void tell_father(int pid)
{
    2838:	53                   	push   %ebx
    2839:	83 ec 08             	sub    $0x8,%esp
    283c:	8b 4c 24 10          	mov    0x10(%esp),%ecx
	int i;
	//struct task_struct * current = get_current_task();
	if (pid)
    2840:	85 c9                	test   %ecx,%ecx
    2842:	74 28                	je     286c <tell_father+0x34>
    2844:	b8 00 00 00 00       	mov    $0x0,%eax
    2849:	bb 00 01 00 00       	mov    $0x100,%ebx
		for (i=0;i<NR_TASKS;i++) {
			if (!task[i])
    284e:	8b 10                	mov    (%eax),%edx
    2850:	85 d2                	test   %edx,%edx
    2852:	74 11                	je     2865 <tell_father+0x2d>
				continue;
			if (task[i]->pid != pid)
    2854:	3b 8a 2c 02 00 00    	cmp    0x22c(%edx),%ecx
    285a:	75 09                	jne    2865 <tell_father+0x2d>
				continue;
			task[i]->signal |= (1<<(SIGCHLD-1));
    285c:	81 4a 0c 00 00 01 00 	orl    $0x10000,0xc(%edx)
			return;
    2863:	eb 17                	jmp    287c <tell_father+0x44>
    2865:	83 c0 04             	add    $0x4,%eax
void tell_father(int pid)
{
	int i;
	//struct task_struct * current = get_current_task();
	if (pid)
		for (i=0;i<NR_TASKS;i++) {
    2868:	39 d8                	cmp    %ebx,%eax
    286a:	75 e2                	jne    284e <tell_father+0x16>
			task[i]->signal |= (1<<(SIGCHLD-1));
			return;
		}
/* if we don't find any fathers, we just release ourselves */
/* This is not really OK. Must change it to make father 1 */
	panic("BAD BAD - no father found\n\r");
    286c:	83 ec 0c             	sub    $0xc,%esp
    286f:	68 e5 01 00 00       	push   $0x1e5
    2874:	e8 fc ff ff ff       	call   2875 <tell_father+0x3d>
    2879:	83 c4 10             	add    $0x10,%esp
	//release(current);
}
    287c:	83 c4 08             	add    $0x8,%esp
    287f:	5b                   	pop    %ebx
    2880:	c3                   	ret    

00002881 <do_exit>:

int do_exit(long code)
{
    2881:	57                   	push   %edi
    2882:	56                   	push   %esi
    2883:	53                   	push   %ebx
	struct task_struct* current = get_current_task();
    2884:	e8 fc ff ff ff       	call   2885 <do_exit+0x4>
    2889:	89 c6                	mov    %eax,%esi
	int i;

	//printk("do_exit call free_page_tables before\n\r");
	free_page_tables(get_base(current->ldt[1]),get_limit(0x0f),current);
    288b:	b9 0f 00 00 00       	mov    $0xf,%ecx
    2890:	0f 03 c9             	lsl    %cx,%ecx
    2893:	41                   	inc    %ecx
    2894:	50                   	push   %eax
    2895:	8d 80 d8 02 00 00    	lea    0x2d8(%eax),%eax
    289b:	83 c0 07             	add    $0x7,%eax
    289e:	8a 30                	mov    (%eax),%dh
    28a0:	83 e8 03             	sub    $0x3,%eax
    28a3:	8a 10                	mov    (%eax),%dl
    28a5:	c1 e2 10             	shl    $0x10,%edx
    28a8:	83 e8 02             	sub    $0x2,%eax
    28ab:	66 8b 10             	mov    (%eax),%dx
    28ae:	58                   	pop    %eax
    28af:	83 ec 04             	sub    $0x4,%esp
    28b2:	56                   	push   %esi
    28b3:	51                   	push   %ecx
    28b4:	52                   	push   %edx
    28b5:	e8 fc ff ff ff       	call   28b6 <do_exit+0x35>
	free_page_tables(get_base(current->ldt[2]),get_limit(0x17),current);
    28ba:	b9 17 00 00 00       	mov    $0x17,%ecx
    28bf:	0f 03 c9             	lsl    %cx,%ecx
    28c2:	41                   	inc    %ecx
    28c3:	50                   	push   %eax
    28c4:	8d 86 e0 02 00 00    	lea    0x2e0(%esi),%eax
    28ca:	83 c0 07             	add    $0x7,%eax
    28cd:	8a 30                	mov    (%eax),%dh
    28cf:	83 e8 03             	sub    $0x3,%eax
    28d2:	8a 10                	mov    (%eax),%dl
    28d4:	c1 e2 10             	shl    $0x10,%edx
    28d7:	83 e8 02             	sub    $0x2,%eax
    28da:	66 8b 10             	mov    (%eax),%dx
    28dd:	58                   	pop    %eax
    28de:	83 c4 0c             	add    $0xc,%esp
    28e1:	56                   	push   %esi
    28e2:	51                   	push   %ecx
    28e3:	52                   	push   %edx
    28e4:	e8 fc ff ff ff       	call   28e5 <do_exit+0x64>
    28e9:	bb 00 00 00 00       	mov    $0x0,%ebx
    28ee:	bf 00 01 00 00       	mov    $0x100,%edi
    28f3:	83 c4 10             	add    $0x10,%esp
    //printk("do_exit call free_page_tables after\n\r");

	for (i=0 ; i<NR_TASKS ; i++)
		if (task[i] && task[i]->father == current->pid) {
    28f6:	8b 03                	mov    (%ebx),%eax
    28f8:	85 c0                	test   %eax,%eax
    28fa:	74 32                	je     292e <do_exit+0xad>
    28fc:	8b 96 2c 02 00 00    	mov    0x22c(%esi),%edx
    2902:	39 90 30 02 00 00    	cmp    %edx,0x230(%eax)
    2908:	75 24                	jne    292e <do_exit+0xad>
			task[i]->father = 1;
    290a:	c7 80 30 02 00 00 01 	movl   $0x1,0x230(%eax)
    2911:	00 00 00 
			if (task[i]->state == TASK_ZOMBIE)
    2914:	83 38 03             	cmpl   $0x3,(%eax)
    2917:	75 15                	jne    292e <do_exit+0xad>
				/* assumption task[1] is always init */
				(void) send_sig(SIGCHLD, task[1], 1);
    2919:	83 ec 04             	sub    $0x4,%esp
    291c:	6a 01                	push   $0x1
    291e:	ff 35 04 00 00 00    	pushl  0x4
    2924:	6a 11                	push   $0x11
    2926:	e8 fc ff ff ff       	call   2927 <do_exit+0xa6>
    292b:	83 c4 10             	add    $0x10,%esp
    292e:	83 c3 04             	add    $0x4,%ebx
	//printk("do_exit call free_page_tables before\n\r");
	free_page_tables(get_base(current->ldt[1]),get_limit(0x0f),current);
	free_page_tables(get_base(current->ldt[2]),get_limit(0x17),current);
    //printk("do_exit call free_page_tables after\n\r");

	for (i=0 ; i<NR_TASKS ; i++)
    2931:	39 fb                	cmp    %edi,%ebx
    2933:	75 c1                	jne    28f6 <do_exit+0x75>
    2935:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (task[i]->state == TASK_ZOMBIE)
				/* assumption task[1] is always init */
				(void) send_sig(SIGCHLD, task[1], 1);
		}
	for (i=0 ; i<NR_OPEN ; i++)
		if (current->filp[i])
    293a:	83 bc 9e 80 02 00 00 	cmpl   $0x0,0x280(%esi,%ebx,4)
    2941:	00 
    2942:	74 0c                	je     2950 <do_exit+0xcf>
			sys_close(i);
    2944:	83 ec 0c             	sub    $0xc,%esp
    2947:	53                   	push   %ebx
    2948:	e8 fc ff ff ff       	call   2949 <do_exit+0xc8>
    294d:	83 c4 10             	add    $0x10,%esp
			task[i]->father = 1;
			if (task[i]->state == TASK_ZOMBIE)
				/* assumption task[1] is always init */
				(void) send_sig(SIGCHLD, task[1], 1);
		}
	for (i=0 ; i<NR_OPEN ; i++)
    2950:	83 c3 01             	add    $0x1,%ebx
    2953:	83 fb 14             	cmp    $0x14,%ebx
    2956:	75 e2                	jne    293a <do_exit+0xb9>
		if (current->filp[i])
			sys_close(i);
	iput(current->pwd);
    2958:	83 ec 0c             	sub    $0xc,%esp
    295b:	ff b6 70 02 00 00    	pushl  0x270(%esi)
    2961:	e8 fc ff ff ff       	call   2962 <do_exit+0xe1>
	current->pwd=NULL;
    2966:	c7 86 70 02 00 00 00 	movl   $0x0,0x270(%esi)
    296d:	00 00 00 
	iput(current->root);
    2970:	83 c4 04             	add    $0x4,%esp
    2973:	ff b6 74 02 00 00    	pushl  0x274(%esi)
    2979:	e8 fc ff ff ff       	call   297a <do_exit+0xf9>
	current->root=NULL;
    297e:	c7 86 74 02 00 00 00 	movl   $0x0,0x274(%esi)
    2985:	00 00 00 
	iput(current->executable);
    2988:	83 c4 04             	add    $0x4,%esp
    298b:	ff b6 78 02 00 00    	pushl  0x278(%esi)
    2991:	e8 fc ff ff ff       	call   2992 <do_exit+0x111>
	current->executable=NULL;
    2996:	c7 86 78 02 00 00 00 	movl   $0x0,0x278(%esi)
    299d:	00 00 00 
	if (current->leader && current->tty >= 0)
    29a0:	83 c4 10             	add    $0x10,%esp
    29a3:	83 be 3c 02 00 00 00 	cmpl   $0x0,0x23c(%esi)
    29aa:	0f 84 9a 00 00 00    	je     2a4a <do_exit+0x1c9>
    29b0:	8b 86 68 02 00 00    	mov    0x268(%esi),%eax
    29b6:	85 c0                	test   %eax,%eax
    29b8:	0f 88 82 00 00 00    	js     2a40 <do_exit+0x1bf>
		tty_table[current->tty].pgrp = 0;
    29be:	69 c0 60 0c 00 00    	imul   $0xc60,%eax,%eax
    29c4:	c7 80 24 00 00 00 00 	movl   $0x0,0x24(%eax)
    29cb:	00 00 00 
	if (last_task_used_math == current)
    29ce:	3b 35 00 00 00 00    	cmp    0x0,%esi
    29d4:	75 0a                	jne    29e0 <do_exit+0x15f>
		last_task_used_math = NULL;
    29d6:	c7 05 00 00 00 00 00 	movl   $0x0,0x0
    29dd:	00 00 00 
	if (current->leader)
    29e0:	83 be 3c 02 00 00 00 	cmpl   $0x0,0x23c(%esi)
    29e7:	74 05                	je     29ee <do_exit+0x16d>
		kill_session();
    29e9:	e8 fc ff ff ff       	call   29ea <do_exit+0x169>
	current->state = TASK_ZOMBIE;
    29ee:	c7 06 03 00 00 00    	movl   $0x3,(%esi)
	current->exit_code = code;
    29f4:	8b 44 24 10          	mov    0x10(%esp),%eax
    29f8:	89 86 14 02 00 00    	mov    %eax,0x214(%esi)
	 * 一旦释放了这两个内存页,她们就有可能被其他新进程占用,以上的操作早于随后执行的reset_ap_context那么,当前进程的目录页就作废了,
	 * 内存映射就出问题了程序就崩溃了.
	 * 所以把tell_father放在task_exit_clear里就不可能会出现这个错误.
	 *  */
	//tell_father(current->father);
	if (get_current_apic_id() == apic_ids[0].apic_id) {
    29fe:	e8 fc ff ff ff       	call   29ff <do_exit+0x17e>
    2a03:	3b 05 04 00 00 00    	cmp    0x4,%eax
    2a09:	75 12                	jne    2a1d <do_exit+0x19c>
		/* 在BSP上退出一个进程后，自主调用schedule，这里是不可能的，因为BSP只运行task0和task1，但这两个进程是不可能退出的，除非系统崩溃了 */
	    panic("System encounters fatal errors, abort.");
    2a0b:	83 ec 0c             	sub    $0xc,%esp
    2a0e:	68 84 02 00 00       	push   $0x284
    2a13:	e8 fc ff ff ff       	call   2a14 <do_exit+0x193>
    2a18:	83 c4 10             	add    $0x10,%esp
    2a1b:	eb 37                	jmp    2a54 <do_exit+0x1d3>
	}
	else {
		printk("task[%d],exit at AP[%d]\n\r", current->task_nr, get_current_apic_id());
    2a1d:	e8 fc ff ff ff       	call   2a1e <do_exit+0x19d>
    2a22:	83 ec 04             	sub    $0x4,%esp
    2a25:	50                   	push   %eax
    2a26:	ff b6 c0 03 00 00    	pushl  0x3c0(%esi)
    2a2c:	68 01 02 00 00       	push   $0x201
    2a31:	e8 fc ff ff ff       	call   2a32 <do_exit+0x1b1>
		/* 进程退出后,要重置该AP的执行上下文. */
		reset_ap_context();
    2a36:	e8 fc ff ff ff       	call   2a37 <do_exit+0x1b6>
    2a3b:	83 c4 10             	add    $0x10,%esp
	}
	return (-1);	/* just to suppress warnings */
    2a3e:	eb 14                	jmp    2a54 <do_exit+0x1d3>
	current->root=NULL;
	iput(current->executable);
	current->executable=NULL;
	if (current->leader && current->tty >= 0)
		tty_table[current->tty].pgrp = 0;
	if (last_task_used_math == current)
    2a40:	3b 35 00 00 00 00    	cmp    0x0,%esi
    2a46:	75 a1                	jne    29e9 <do_exit+0x168>
    2a48:	eb 8c                	jmp    29d6 <do_exit+0x155>
    2a4a:	3b 35 00 00 00 00    	cmp    0x0,%esi
    2a50:	75 9c                	jne    29ee <do_exit+0x16d>
    2a52:	eb 82                	jmp    29d6 <do_exit+0x155>
		printk("task[%d],exit at AP[%d]\n\r", current->task_nr, get_current_apic_id());
		/* 进程退出后,要重置该AP的执行上下文. */
		reset_ap_context();
	}
	return (-1);	/* just to suppress warnings */
}
    2a54:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    2a59:	5b                   	pop    %ebx
    2a5a:	5e                   	pop    %esi
    2a5b:	5f                   	pop    %edi
    2a5c:	c3                   	ret    

00002a5d <sys_exit>:

int sys_exit(int error_code)
{
    2a5d:	83 ec 18             	sub    $0x18,%esp
	return do_exit((error_code&0xff)<<8);
    2a60:	8b 44 24 1c          	mov    0x1c(%esp),%eax
    2a64:	c1 e0 08             	shl    $0x8,%eax
    2a67:	0f b7 c0             	movzwl %ax,%eax
    2a6a:	50                   	push   %eax
    2a6b:	e8 fc ff ff ff       	call   2a6c <sys_exit+0xf>
}
    2a70:	83 c4 1c             	add    $0x1c,%esp
    2a73:	c3                   	ret    

00002a74 <sys_waitpid>:

int sys_waitpid(pid_t pid,unsigned long * stat_addr, int options)
{
    2a74:	55                   	push   %ebp
    2a75:	57                   	push   %edi
    2a76:	56                   	push   %esi
    2a77:	53                   	push   %ebx
    2a78:	83 ec 1c             	sub    $0x1c,%esp
    2a7b:	8b 74 24 30          	mov    0x30(%esp),%esi
	struct task_struct* current = get_current_task();
    2a7f:	e8 fc ff ff ff       	call   2a80 <sys_waitpid+0xc>
    2a84:	89 c3                	mov    %eax,%ebx
	int flag, code;
	struct task_struct ** p;

	verify_area(stat_addr,4);
    2a86:	83 ec 08             	sub    $0x8,%esp
    2a89:	6a 04                	push   $0x4
    2a8b:	ff 74 24 40          	pushl  0x40(%esp)
    2a8f:	e8 fc ff ff ff       	call   2a90 <sys_waitpid+0x1c>
    2a94:	83 c4 10             	add    $0x10,%esp
			if ((*p)->pgrp != -pid)
				continue;
		}
		switch ((*p)->state) {
			case TASK_STOPPED:
				if (!(options & WUNTRACED))
    2a97:	8b 7c 24 38          	mov    0x38(%esp),%edi
    2a9b:	83 e7 02             	and    $0x2,%edi
				continue;
		} else if (!pid) {
			if ((*p)->pgrp != current->pgrp)
				continue;
		} else if (pid != -1) {
			if ((*p)->pgrp != -pid)
    2a9e:	89 f5                	mov    %esi,%ebp
    2aa0:	f7 dd                	neg    %ebp
	struct task_struct ** p;

	verify_area(stat_addr,4);
repeat:
	flag=0;
	for(p = &LAST_TASK ; p > &FIRST_TASK ; --p) {
    2aa2:	b8 fc 00 00 00       	mov    $0xfc,%eax
	int flag, code;
	struct task_struct ** p;

	verify_area(stat_addr,4);
repeat:
	flag=0;
    2aa7:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
    2aae:	00 
	for(p = &LAST_TASK ; p > &FIRST_TASK ; --p) {
		if (!*p || *p == current)   /* 过滤掉自身 */
    2aaf:	8b 10                	mov    (%eax),%edx
    2ab1:	39 d3                	cmp    %edx,%ebx
    2ab3:	0f 84 bb 00 00 00    	je     2b74 <sys_waitpid+0x100>
    2ab9:	85 d2                	test   %edx,%edx
    2abb:	0f 84 b3 00 00 00    	je     2b74 <sys_waitpid+0x100>
			continue;
		if ((*p)->father != current->pid)  /* 查找当前进程的子进程 */
    2ac1:	8b 8b 2c 02 00 00    	mov    0x22c(%ebx),%ecx
    2ac7:	39 8a 30 02 00 00    	cmp    %ecx,0x230(%edx)
    2acd:	0f 85 a1 00 00 00    	jne    2b74 <sys_waitpid+0x100>
			continue;
		if (pid>0) {
    2ad3:	85 f6                	test   %esi,%esi
    2ad5:	7e 0e                	jle    2ae5 <sys_waitpid+0x71>
			if ((*p)->pid != pid)
    2ad7:	3b b2 2c 02 00 00    	cmp    0x22c(%edx),%esi
    2add:	0f 85 91 00 00 00    	jne    2b74 <sys_waitpid+0x100>
    2ae3:	eb 21                	jmp    2b06 <sys_waitpid+0x92>
				continue;
		} else if (!pid) {
    2ae5:	85 f6                	test   %esi,%esi
    2ae7:	75 10                	jne    2af9 <sys_waitpid+0x85>
			if ((*p)->pgrp != current->pgrp)
    2ae9:	8b 8b 34 02 00 00    	mov    0x234(%ebx),%ecx
    2aef:	39 8a 34 02 00 00    	cmp    %ecx,0x234(%edx)
    2af5:	75 7d                	jne    2b74 <sys_waitpid+0x100>
    2af7:	eb 0d                	jmp    2b06 <sys_waitpid+0x92>
				continue;
		} else if (pid != -1) {
    2af9:	83 fe ff             	cmp    $0xffffffff,%esi
    2afc:	74 08                	je     2b06 <sys_waitpid+0x92>
			if ((*p)->pgrp != -pid)
    2afe:	39 aa 34 02 00 00    	cmp    %ebp,0x234(%edx)
    2b04:	75 6e                	jne    2b74 <sys_waitpid+0x100>
				continue;
		}
		switch ((*p)->state) {
    2b06:	8b 0a                	mov    (%edx),%ecx
    2b08:	83 f9 03             	cmp    $0x3,%ecx
    2b0b:	74 20                	je     2b2d <sys_waitpid+0xb9>
    2b0d:	83 f9 04             	cmp    $0x4,%ecx
    2b10:	75 5a                	jne    2b6c <sys_waitpid+0xf8>
			case TASK_STOPPED:
				if (!(options & WUNTRACED))
    2b12:	85 ff                	test   %edi,%edi
    2b14:	74 5e                	je     2b74 <sys_waitpid+0x100>
__asm__ ("movw %0,%%fs:%1"::"r" (val),"m" (*addr));
}

static inline void put_fs_long(unsigned long val,unsigned long * addr)
{
__asm__ ("movl %0,%%fs:%1"::"r" (val),"m" (*addr));
    2b16:	b8 7f 00 00 00       	mov    $0x7f,%eax
    2b1b:	8b 7c 24 34          	mov    0x34(%esp),%edi
    2b1f:	64 89 07             	mov    %eax,%fs:(%edi)
					continue;
				put_fs_long(0x7f,stat_addr);
				return (*p)->pid;
    2b22:	8b 82 2c 02 00 00    	mov    0x22c(%edx),%eax
    2b28:	e9 94 00 00 00       	jmp    2bc1 <sys_waitpid+0x14d>
			case TASK_ZOMBIE:
				current->cutime += (*p)->utime;
    2b2d:	8b 92 50 02 00 00    	mov    0x250(%edx),%edx
    2b33:	01 93 58 02 00 00    	add    %edx,0x258(%ebx)
				current->cstime += (*p)->stime;
    2b39:	8b 10                	mov    (%eax),%edx
    2b3b:	8b 92 54 02 00 00    	mov    0x254(%edx),%edx
    2b41:	01 93 5c 02 00 00    	add    %edx,0x25c(%ebx)
				flag = (*p)->pid;
    2b47:	8b 00                	mov    (%eax),%eax
    2b49:	8b 98 2c 02 00 00    	mov    0x22c(%eax),%ebx
				code = (*p)->exit_code;
    2b4f:	8b b0 14 02 00 00    	mov    0x214(%eax),%esi
				//printk("pid: %d, fpid: %d, exitCode: %d\n\r", flag,(*p)->father, code);
				release(*p);
    2b55:	83 ec 0c             	sub    $0xc,%esp
    2b58:	50                   	push   %eax
    2b59:	e8 fc ff ff ff       	call   2b5a <sys_waitpid+0xe6>
    2b5e:	8b 44 24 44          	mov    0x44(%esp),%eax
    2b62:	64 89 30             	mov    %esi,%fs:(%eax)
				put_fs_long(code,stat_addr);
				return flag;
    2b65:	83 c4 10             	add    $0x10,%esp
    2b68:	89 d8                	mov    %ebx,%eax
    2b6a:	eb 55                	jmp    2bc1 <sys_waitpid+0x14d>
			default:
				flag=1;
    2b6c:	c7 44 24 0c 01 00 00 	movl   $0x1,0xc(%esp)
    2b73:	00 
	struct task_struct ** p;

	verify_area(stat_addr,4);
repeat:
	flag=0;
	for(p = &LAST_TASK ; p > &FIRST_TASK ; --p) {
    2b74:	83 e8 04             	sub    $0x4,%eax
    2b77:	3d 00 00 00 00       	cmp    $0x0,%eax
    2b7c:	0f 85 2d ff ff ff    	jne    2aaf <sys_waitpid+0x3b>
				flag=1;
				continue;
		}
	}

	if (flag) {
    2b82:	83 7c 24 0c 00       	cmpl   $0x0,0xc(%esp)
    2b87:	74 2c                	je     2bb5 <sys_waitpid+0x141>
		if (options & WNOHANG){
    2b89:	f6 44 24 38 01       	testb  $0x1,0x38(%esp)
    2b8e:	75 2c                	jne    2bbc <sys_waitpid+0x148>
			return 0;
		}

		current->state=TASK_INTERRUPTIBLE;
    2b90:	c7 03 01 00 00 00    	movl   $0x1,(%ebx)
		schedule();
    2b96:	e8 fc ff ff ff       	call   2b97 <sys_waitpid+0x123>
		/* 子进程如果调用了exit会调用tell_father将father的SIG_CHILD位置1的，这里父进程就是在等这个标志。 */
		if (!(current->signal &= ~(1<<(SIGCHLD-1))))
    2b9b:	8b 43 0c             	mov    0xc(%ebx),%eax
    2b9e:	25 ff ff fe ff       	and    $0xfffeffff,%eax
    2ba3:	89 43 0c             	mov    %eax,0xc(%ebx)
    2ba6:	85 c0                	test   %eax,%eax
    2ba8:	0f 84 f4 fe ff ff    	je     2aa2 <sys_waitpid+0x2e>
			goto repeat;
		else
			return -EINTR;
    2bae:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
    2bb3:	eb 0c                	jmp    2bc1 <sys_waitpid+0x14d>
	}
	return -ECHILD;
    2bb5:	b8 f6 ff ff ff       	mov    $0xfffffff6,%eax
    2bba:	eb 05                	jmp    2bc1 <sys_waitpid+0x14d>
		}
	}

	if (flag) {
		if (options & WNOHANG){
			return 0;
    2bbc:	b8 00 00 00 00       	mov    $0x0,%eax
			goto repeat;
		else
			return -EINTR;
	}
	return -ECHILD;
}
    2bc1:	83 c4 1c             	add    $0x1c,%esp
    2bc4:	5b                   	pop    %ebx
    2bc5:	5e                   	pop    %esi
    2bc6:	5f                   	pop    %edi
    2bc7:	5d                   	pop    %ebp
    2bc8:	c3                   	ret    

00002bc9 <sys_sgetmask>:
#include <signal.h>

volatile void do_exit(int error_code);

int sys_sgetmask()
{
    2bc9:	83 ec 0c             	sub    $0xc,%esp
	struct task_struct* current = get_current_task();
    2bcc:	e8 fc ff ff ff       	call   2bcd <sys_sgetmask+0x4>
	return current->blocked;
    2bd1:	8b 80 10 02 00 00    	mov    0x210(%eax),%eax
}
    2bd7:	83 c4 0c             	add    $0xc,%esp
    2bda:	c3                   	ret    

00002bdb <sys_ssetmask>:

int sys_ssetmask(int newmask)
{
    2bdb:	83 ec 0c             	sub    $0xc,%esp
	struct task_struct* current = get_current_task();
    2bde:	e8 fc ff ff ff       	call   2bdf <sys_ssetmask+0x4>
    2be3:	89 c1                	mov    %eax,%ecx
	int old=current->blocked;
    2be5:	8b 80 10 02 00 00    	mov    0x210(%eax),%eax

	current->blocked = newmask & ~(1<<(SIGKILL-1));
    2beb:	8b 54 24 10          	mov    0x10(%esp),%edx
    2bef:	80 e6 fe             	and    $0xfe,%dh
    2bf2:	89 91 10 02 00 00    	mov    %edx,0x210(%ecx)
	return old;
}
    2bf8:	83 c4 0c             	add    $0xc,%esp
    2bfb:	c3                   	ret    

00002bfc <sys_signal>:
	for (i=0 ; i< sizeof(struct sigaction) ; i++)
		*(to++) = get_fs_byte(from++);
}

int sys_signal(int signum, long handler, long restorer)
{
    2bfc:	53                   	push   %ebx
    2bfd:	83 ec 08             	sub    $0x8,%esp
    2c00:	8b 5c 24 10          	mov    0x10(%esp),%ebx
	struct task_struct* current = get_current_task();
    2c04:	e8 fc ff ff ff       	call   2c05 <sys_signal+0x9>
	struct sigaction tmp;

	if (signum<1 || signum>32 || signum==SIGKILL)
    2c09:	8d 4b ff             	lea    -0x1(%ebx),%ecx
    2c0c:	83 f9 1f             	cmp    $0x1f,%ecx
    2c0f:	77 2a                	ja     2c3b <sys_signal+0x3f>
    2c11:	83 fb 09             	cmp    $0x9,%ebx
    2c14:	74 25                	je     2c3b <sys_signal+0x3f>
		return -1;
	tmp.sa_handler = (void (*)(int)) handler;
	tmp.sa_mask = 0;
	tmp.sa_flags = SA_ONESHOT | SA_NOMASK;
	tmp.sa_restorer = (void (*)(void)) restorer;
	handler = (long) current->sigaction[signum-1].sa_handler;
    2c16:	c1 e3 04             	shl    $0x4,%ebx
    2c19:	8d 14 18             	lea    (%eax,%ebx,1),%edx
    2c1c:	8b 02                	mov    (%edx),%eax
	current->sigaction[signum-1] = tmp;
    2c1e:	8b 4c 24 14          	mov    0x14(%esp),%ecx
    2c22:	89 0a                	mov    %ecx,(%edx)
    2c24:	c7 42 04 00 00 00 00 	movl   $0x0,0x4(%edx)
    2c2b:	c7 42 08 00 00 00 c0 	movl   $0xc0000000,0x8(%edx)
    2c32:	8b 4c 24 18          	mov    0x18(%esp),%ecx
    2c36:	89 4a 0c             	mov    %ecx,0xc(%edx)
	return handler;
    2c39:	eb 05                	jmp    2c40 <sys_signal+0x44>
{
	struct task_struct* current = get_current_task();
	struct sigaction tmp;

	if (signum<1 || signum>32 || signum==SIGKILL)
		return -1;
    2c3b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	tmp.sa_flags = SA_ONESHOT | SA_NOMASK;
	tmp.sa_restorer = (void (*)(void)) restorer;
	handler = (long) current->sigaction[signum-1].sa_handler;
	current->sigaction[signum-1] = tmp;
	return handler;
}
    2c40:	83 c4 08             	add    $0x8,%esp
    2c43:	5b                   	pop    %ebx
    2c44:	c3                   	ret    

00002c45 <sys_sigaction>:

int sys_sigaction(int signum, const struct sigaction * action,
	struct sigaction * oldaction)
{
    2c45:	55                   	push   %ebp
    2c46:	57                   	push   %edi
    2c47:	56                   	push   %esi
    2c48:	53                   	push   %ebx
    2c49:	83 ec 2c             	sub    $0x2c,%esp
    2c4c:	8b 7c 24 40          	mov    0x40(%esp),%edi
    2c50:	8b 5c 24 44          	mov    0x44(%esp),%ebx
    2c54:	8b 74 24 48          	mov    0x48(%esp),%esi
	struct task_struct* current = get_current_task();
    2c58:	e8 fc ff ff ff       	call   2c59 <sys_sigaction+0x14>
    2c5d:	89 c5                	mov    %eax,%ebp
	struct sigaction tmp;

	if (signum<1 || signum>32 || signum==SIGKILL)
    2c5f:	8d 47 ff             	lea    -0x1(%edi),%eax
    2c62:	83 f8 1f             	cmp    $0x1f,%eax
    2c65:	0f 87 8e 00 00 00    	ja     2cf9 <sys_sigaction+0xb4>
    2c6b:	83 ff 09             	cmp    $0x9,%edi
    2c6e:	0f 84 85 00 00 00    	je     2cf9 <sys_sigaction+0xb4>
		return -1;
	tmp = current->sigaction[signum-1];
    2c74:	89 44 24 0c          	mov    %eax,0xc(%esp)
    2c78:	89 f8                	mov    %edi,%eax
    2c7a:	c1 e0 04             	shl    $0x4,%eax
    2c7d:	01 e8                	add    %ebp,%eax
    2c7f:	8b 10                	mov    (%eax),%edx
    2c81:	89 54 24 10          	mov    %edx,0x10(%esp)
    2c85:	8b 50 04             	mov    0x4(%eax),%edx
    2c88:	89 54 24 14          	mov    %edx,0x14(%esp)
    2c8c:	8b 50 08             	mov    0x8(%eax),%edx
    2c8f:	89 54 24 18          	mov    %edx,0x18(%esp)
    2c93:	8b 40 0c             	mov    0xc(%eax),%eax
    2c96:	89 44 24 1c          	mov    %eax,0x1c(%esp)
	get_new((char *) action,
    2c9a:	89 f8                	mov    %edi,%eax
    2c9c:	c1 e0 04             	shl    $0x4,%eax
    2c9f:	8d 04 28             	lea    (%eax,%ebp,1),%eax
    2ca2:	8d 48 10             	lea    0x10(%eax),%ecx
static inline void get_new(char * from,char * to)
{
	int i;

	for (i=0 ; i< sizeof(struct sigaction) ; i++)
		*(to++) = get_fs_byte(from++);
    2ca5:	83 c0 01             	add    $0x1,%eax
static inline unsigned char get_fs_byte(const char * addr)
{
	unsigned register char _v;

	__asm__ ("movb %%fs:%1,%0":"=r" (_v):"m" (*addr));
    2ca8:	64 8a 13             	mov    %fs:(%ebx),%dl
    2cab:	88 50 ff             	mov    %dl,-0x1(%eax)
    2cae:	8d 5b 01             	lea    0x1(%ebx),%ebx

static inline void get_new(char * from,char * to)
{
	int i;

	for (i=0 ; i< sizeof(struct sigaction) ; i++)
    2cb1:	39 c8                	cmp    %ecx,%eax
    2cb3:	75 f0                	jne    2ca5 <sys_sigaction+0x60>
    2cb5:	eb 5d                	jmp    2d14 <sys_sigaction+0xcf>
	return _v;
}

static inline void put_fs_byte(char val,char *addr)
{
__asm__ ("movb %0,%%fs:%1"::"q" (val),"m" (*addr));
    2cb7:	0f b6 10             	movzbl (%eax),%edx
    2cba:	64 88 16             	mov    %dl,%fs:(%esi)
	int i;

	verify_area(to, sizeof(struct sigaction));
	for (i=0 ; i< sizeof(struct sigaction) ; i++) {
		put_fs_byte(*from,to);
		from++;
    2cbd:	83 c0 01             	add    $0x1,%eax
		to++;
    2cc0:	83 c6 01             	add    $0x1,%esi
static inline void save_old(char * from,char * to)
{
	int i;

	verify_area(to, sizeof(struct sigaction));
	for (i=0 ; i< sizeof(struct sigaction) ; i++) {
    2cc3:	8d 4c 24 20          	lea    0x20(%esp),%ecx
    2cc7:	39 c8                	cmp    %ecx,%eax
    2cc9:	75 ec                	jne    2cb7 <sys_sigaction+0x72>
    2ccb:	c1 e7 04             	shl    $0x4,%edi
    2cce:	01 fd                	add    %edi,%ebp
	tmp = current->sigaction[signum-1];
	get_new((char *) action,
		(char *) (signum-1+current->sigaction));
	if (oldaction)
		save_old((char *) &tmp,(char *) oldaction);
	if (current->sigaction[signum-1].sa_flags & SA_NOMASK)
    2cd0:	8b 45 08             	mov    0x8(%ebp),%eax
    2cd3:	25 00 00 00 40       	and    $0x40000000,%eax
    2cd8:	74 0e                	je     2ce8 <sys_sigaction+0xa3>
		current->sigaction[signum-1].sa_mask = 0;
    2cda:	c7 45 04 00 00 00 00 	movl   $0x0,0x4(%ebp)
	else
		current->sigaction[signum-1].sa_mask |= (1<<(signum-1));
	return 0;
    2ce1:	b8 00 00 00 00       	mov    $0x0,%eax
    2ce6:	eb 32                	jmp    2d1a <sys_sigaction+0xd5>
	if (oldaction)
		save_old((char *) &tmp,(char *) oldaction);
	if (current->sigaction[signum-1].sa_flags & SA_NOMASK)
		current->sigaction[signum-1].sa_mask = 0;
	else
		current->sigaction[signum-1].sa_mask |= (1<<(signum-1));
    2ce8:	ba 01 00 00 00       	mov    $0x1,%edx
    2ced:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
    2cf2:	d3 e2                	shl    %cl,%edx
    2cf4:	09 55 04             	or     %edx,0x4(%ebp)
    2cf7:	eb 21                	jmp    2d1a <sys_sigaction+0xd5>
{
	struct task_struct* current = get_current_task();
	struct sigaction tmp;

	if (signum<1 || signum>32 || signum==SIGKILL)
		return -1;
    2cf9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    2cfe:	eb 1a                	jmp    2d1a <sys_sigaction+0xd5>

static inline void save_old(char * from,char * to)
{
	int i;

	verify_area(to, sizeof(struct sigaction));
    2d00:	83 ec 08             	sub    $0x8,%esp
    2d03:	6a 10                	push   $0x10
    2d05:	56                   	push   %esi
    2d06:	e8 fc ff ff ff       	call   2d07 <sys_sigaction+0xc2>
    2d0b:	83 c4 10             	add    $0x10,%esp
    2d0e:	8d 44 24 10          	lea    0x10(%esp),%eax
    2d12:	eb a3                	jmp    2cb7 <sys_sigaction+0x72>
	if (signum<1 || signum>32 || signum==SIGKILL)
		return -1;
	tmp = current->sigaction[signum-1];
	get_new((char *) action,
		(char *) (signum-1+current->sigaction));
	if (oldaction)
    2d14:	85 f6                	test   %esi,%esi
    2d16:	75 e8                	jne    2d00 <sys_sigaction+0xbb>
    2d18:	eb b1                	jmp    2ccb <sys_sigaction+0x86>
	if (current->sigaction[signum-1].sa_flags & SA_NOMASK)
		current->sigaction[signum-1].sa_mask = 0;
	else
		current->sigaction[signum-1].sa_mask |= (1<<(signum-1));
	return 0;
}
    2d1a:	83 c4 2c             	add    $0x2c,%esp
    2d1d:	5b                   	pop    %ebx
    2d1e:	5e                   	pop    %esi
    2d1f:	5f                   	pop    %edi
    2d20:	5d                   	pop    %ebp
    2d21:	c3                   	ret    

00002d22 <do_signal>:

void do_signal(long signr,long eax, long ebx, long ecx, long edx,
	long fs, long es, long ds,
	long eip, long cs, long eflags,
	unsigned long * esp, long ss)
{
    2d22:	55                   	push   %ebp
    2d23:	57                   	push   %edi
    2d24:	56                   	push   %esi
    2d25:	53                   	push   %ebx
    2d26:	83 ec 0c             	sub    $0xc,%esp
    2d29:	8b 6c 24 20          	mov    0x20(%esp),%ebp
	struct task_struct* current = get_current_task();
    2d2d:	e8 fc ff ff ff       	call   2d2e <do_signal+0xc>
    2d32:	89 c7                	mov    %eax,%edi
	unsigned long sa_handler;
	long old_eip=eip;
	struct sigaction * sa = current->sigaction + signr - 1;
    2d34:	89 e8                	mov    %ebp,%eax
    2d36:	c1 e0 04             	shl    $0x4,%eax
    2d39:	8d 34 38             	lea    (%eax,%edi,1),%esi
	int longs;
	unsigned long * tmp_esp;

	sa_handler = (unsigned long) sa->sa_handler;
    2d3c:	8b 06                	mov    (%esi),%eax
	if (sa_handler==1)
    2d3e:	83 f8 01             	cmp    $0x1,%eax
    2d41:	0f 84 a6 00 00 00    	je     2ded <do_signal+0xcb>
		return;
	if (!sa_handler) {
    2d47:	85 c0                	test   %eax,%eax
    2d49:	75 1f                	jne    2d6a <do_signal+0x48>
		if (signr==SIGCHLD)
    2d4b:	83 fd 11             	cmp    $0x11,%ebp
    2d4e:	0f 84 99 00 00 00    	je     2ded <do_signal+0xcb>
			return;
		else
			do_exit(1<<(signr-1));
    2d54:	83 ec 0c             	sub    $0xc,%esp
    2d57:	8d 4d ff             	lea    -0x1(%ebp),%ecx
    2d5a:	b8 01 00 00 00       	mov    $0x1,%eax
    2d5f:	d3 e0                	shl    %cl,%eax
    2d61:	50                   	push   %eax
    2d62:	e8 fc ff ff ff       	call   2d63 <do_signal+0x41>
    2d67:	83 c4 10             	add    $0x10,%esp
	}
	if (sa->sa_flags & SA_ONESHOT)
    2d6a:	8b 46 08             	mov    0x8(%esi),%eax
    2d6d:	85 c0                	test   %eax,%eax
    2d6f:	79 06                	jns    2d77 <do_signal+0x55>
		sa->sa_handler = NULL;
    2d71:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
	*(&eip) = sa_handler;
	longs = (sa->sa_flags & SA_NOMASK)?7:8;
    2d77:	25 00 00 00 40       	and    $0x40000000,%eax
    2d7c:	83 f8 01             	cmp    $0x1,%eax
    2d7f:	19 c0                	sbb    %eax,%eax
    2d81:	f7 d0                	not    %eax
	*(&esp) -= longs;
    2d83:	8d 04 85 20 00 00 00 	lea    0x20(,%eax,4),%eax
    2d8a:	8b 5c 24 4c          	mov    0x4c(%esp),%ebx
    2d8e:	29 c3                	sub    %eax,%ebx
	verify_area(esp,longs*4);
    2d90:	83 ec 08             	sub    $0x8,%esp
    2d93:	50                   	push   %eax
    2d94:	53                   	push   %ebx
    2d95:	e8 fc ff ff ff       	call   2d96 <do_signal+0x74>
__asm__ ("movw %0,%%fs:%1"::"r" (val),"m" (*addr));
}

static inline void put_fs_long(unsigned long val,unsigned long * addr)
{
__asm__ ("movl %0,%%fs:%1"::"r" (val),"m" (*addr));
    2d9a:	8b 46 0c             	mov    0xc(%esi),%eax
    2d9d:	64 89 03             	mov    %eax,%fs:(%ebx)
	tmp_esp=esp;
	put_fs_long((long) sa->sa_restorer,tmp_esp++);
	put_fs_long(signr,tmp_esp++);
    2da0:	8d 43 08             	lea    0x8(%ebx),%eax
    2da3:	64 89 6b 04          	mov    %ebp,%fs:0x4(%ebx)
	if (!(sa->sa_flags & SA_NOMASK))
    2da7:	83 c4 10             	add    $0x10,%esp
    2daa:	f6 46 0b 40          	testb  $0x40,0xb(%esi)
    2dae:	75 0d                	jne    2dbd <do_signal+0x9b>
		put_fs_long(current->blocked,tmp_esp++);
    2db0:	8d 43 0c             	lea    0xc(%ebx),%eax
    2db3:	8b 97 10 02 00 00    	mov    0x210(%edi),%edx
    2db9:	64 89 53 08          	mov    %edx,%fs:0x8(%ebx)
    2dbd:	8b 54 24 24          	mov    0x24(%esp),%edx
    2dc1:	64 89 10             	mov    %edx,%fs:(%eax)
    2dc4:	8b 54 24 2c          	mov    0x2c(%esp),%edx
    2dc8:	64 89 50 04          	mov    %edx,%fs:0x4(%eax)
    2dcc:	8b 54 24 30          	mov    0x30(%esp),%edx
    2dd0:	64 89 50 08          	mov    %edx,%fs:0x8(%eax)
    2dd4:	8b 54 24 48          	mov    0x48(%esp),%edx
    2dd8:	64 89 50 0c          	mov    %edx,%fs:0xc(%eax)
    2ddc:	8b 54 24 40          	mov    0x40(%esp),%edx
    2de0:	64 89 50 10          	mov    %edx,%fs:0x10(%eax)
	put_fs_long(eax,tmp_esp++);
	put_fs_long(ecx,tmp_esp++);
	put_fs_long(edx,tmp_esp++);
	put_fs_long(eflags,tmp_esp++);
	put_fs_long(old_eip,tmp_esp++);
	current->blocked |= sa->sa_mask;
    2de4:	8b 46 04             	mov    0x4(%esi),%eax
    2de7:	09 87 10 02 00 00    	or     %eax,0x210(%edi)
}
    2ded:	83 c4 0c             	add    $0xc,%esp
    2df0:	5b                   	pop    %ebx
    2df1:	5e                   	pop    %esi
    2df2:	5f                   	pop    %edi
    2df3:	5d                   	pop    %ebp
    2df4:	c3                   	ret    

00002df5 <kernel_mktime>:
	DAY*(31+29+31+30+31+30+31+31+30+31),
	DAY*(31+29+31+30+31+30+31+31+30+31+30)
};

long kernel_mktime(struct tm * tm)
{
    2df5:	53                   	push   %ebx
    2df6:	8b 4c 24 08          	mov    0x8(%esp),%ecx
	long res;
	int year;

	year = tm->tm_year - 70;
    2dfa:	8b 51 14             	mov    0x14(%ecx),%edx
/* magic offsets (y+1) needed to get leapyears right.*/
	res = YEAR*year + DAY*((year+1)/4);
    2dfd:	8d 42 be             	lea    -0x42(%edx),%eax
    2e00:	89 d3                	mov    %edx,%ebx
    2e02:	83 eb 45             	sub    $0x45,%ebx
    2e05:	0f 48 d8             	cmovs  %eax,%ebx
    2e08:	c1 fb 02             	sar    $0x2,%ebx
    2e0b:	69 db 80 51 01 00    	imul   $0x15180,%ebx,%ebx
    2e11:	8d 42 ba             	lea    -0x46(%edx),%eax
    2e14:	69 c0 80 33 e1 01    	imul   $0x1e13380,%eax,%eax
    2e1a:	01 d8                	add    %ebx,%eax
	res += month[tm->tm_mon];
    2e1c:	8b 59 10             	mov    0x10(%ecx),%ebx
    2e1f:	03 04 9d e0 00 00 00 	add    0xe0(,%ebx,4),%eax
/* and (y+2) here. If it wasn't a leap-year, we have to adjust */
	if (tm->tm_mon>1 && ((year+2)%4))
    2e26:	83 fb 01             	cmp    $0x1,%ebx
    2e29:	7e 0e                	jle    2e39 <kernel_mktime+0x44>
    2e2b:	83 e2 03             	and    $0x3,%edx
		res -= DAY;
    2e2e:	8d 98 80 ae fe ff    	lea    -0x15180(%eax),%ebx
    2e34:	85 d2                	test   %edx,%edx
    2e36:	0f 45 c3             	cmovne %ebx,%eax
	res += DAY*(tm->tm_mday-1);
    2e39:	8b 51 0c             	mov    0xc(%ecx),%edx
    2e3c:	83 ea 01             	sub    $0x1,%edx
    2e3f:	69 d2 80 51 01 00    	imul   $0x15180,%edx,%edx
    2e45:	01 d0                	add    %edx,%eax
	res += HOUR*tm->tm_hour;
    2e47:	69 51 08 10 0e 00 00 	imul   $0xe10,0x8(%ecx),%edx
    2e4e:	01 d0                	add    %edx,%eax
	res += MINUTE*tm->tm_min;
    2e50:	6b 51 04 3c          	imul   $0x3c,0x4(%ecx),%edx
    2e54:	01 d0                	add    %edx,%eax
	res += tm->tm_sec;
	return res;
    2e56:	03 01                	add    (%ecx),%eax
}
    2e58:	5b                   	pop    %ebx
    2e59:	c3                   	ret    

00002e5a <get_gdt_idt_addr>:

/*
 *  Because of current processor doesn't support vmcs_shadow, so in Guest-Env using vmread or vmwrite will cause VM-EXIT,
 *  So using sgdt and sidt to get gdt/idt base-addr instead of vmread.
 */
unsigned long get_gdt_idt_addr(unsigned long gdt_idt_identity) {
    2e5a:	83 ec 10             	sub    $0x10,%esp
	unsigned char table_base[8] = {0,}; /* 16-bit limit stored in low two bytes, and idt_base stored in high 4bytes. */
    2e5d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
    2e64:	00 
    2e65:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
    2e6c:	00 
	unsigned long base_addr = 0;
	if (gdt_idt_identity == GDT_IDENTITY_NO) {
    2e6d:	83 7c 24 14 00       	cmpl   $0x0,0x14(%esp)
    2e72:	75 0b                	jne    2e7f <get_gdt_idt_addr+0x25>
		__asm__ ("sgdt %1\n\r"   \
    2e74:	0f 01 44 24 08       	sgdtl  0x8(%esp)
    2e79:	8b 44 24 0a          	mov    0xa(%esp),%eax
    2e7d:	eb 09                	jmp    2e88 <get_gdt_idt_addr+0x2e>
				 "movl %2,%%eax\n\r" \
				 :"=a" (base_addr):"m" (*table_base),"m" (*(char*)(table_base+2)));
	} else {
		__asm__ ("sidt %1\n\r"   \
    2e7f:	0f 01 4c 24 08       	sidtl  0x8(%esp)
    2e84:	8b 44 24 0a          	mov    0xa(%esp),%eax
				 "movl %2,%%eax\n\r" \
				 :"=a" (base_addr):"m" (*table_base),"m" (*(char*)(table_base+2)));
	}

	return base_addr;
}
    2e88:	83 c4 10             	add    $0x10,%esp
    2e8b:	c3                   	ret    

00002e8c <init_ap>:
			:"=a" (apic_status):);
	printk("apic_status: %d \n\r", apic_status);
}*/

/* 初始化APs，包括让AP进入保护模式，开启中断，初始化段寄存器使其指向内核代码段等等 */
void init_ap() {
    2e8c:	83 ec 18             	sub    $0x18,%esp
	for (int i=0;i<LOGICAL_PROCESSOR_NUM;i++) {
		apic_ids[i].kernel_stack = get_free_page(PAGE_IN_REAL_MEM_MAP);
    2e8f:	6a 01                	push   $0x1
    2e91:	e8 fc ff ff ff       	call   2e92 <init_ap+0x6>
    2e96:	a3 0c 00 00 00       	mov    %eax,0xc
    2e9b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2ea2:	e8 fc ff ff ff       	call   2ea3 <init_ap+0x17>
    2ea7:	a3 28 00 00 00       	mov    %eax,0x28
		if (i > 0) {
			init_ap_tss(AP_DEFAULT_TASK_NR+i);
    2eac:	c7 04 24 51 00 00 00 	movl   $0x51,(%esp)
    2eb3:	e8 fc ff ff ff       	call   2eb4 <init_ap+0x28>
}*/

/* 初始化APs，包括让AP进入保护模式，开启中断，初始化段寄存器使其指向内核代码段等等 */
void init_ap() {
	for (int i=0;i<LOGICAL_PROCESSOR_NUM;i++) {
		apic_ids[i].kernel_stack = get_free_page(PAGE_IN_REAL_MEM_MAP);
    2eb8:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2ebf:	e8 fc ff ff ff       	call   2ec0 <init_ap+0x34>
    2ec4:	a3 44 00 00 00       	mov    %eax,0x44
		if (i > 0) {
			init_ap_tss(AP_DEFAULT_TASK_NR+i);
    2ec9:	c7 04 24 52 00 00 00 	movl   $0x52,(%esp)
    2ed0:	e8 fc ff ff ff       	call   2ed1 <init_ap+0x45>
}*/

/* 初始化APs，包括让AP进入保护模式，开启中断，初始化段寄存器使其指向内核代码段等等 */
void init_ap() {
	for (int i=0;i<LOGICAL_PROCESSOR_NUM;i++) {
		apic_ids[i].kernel_stack = get_free_page(PAGE_IN_REAL_MEM_MAP);
    2ed5:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2edc:	e8 fc ff ff ff       	call   2edd <init_ap+0x51>
    2ee1:	a3 60 00 00 00       	mov    %eax,0x60
		if (i > 0) {
			init_ap_tss(AP_DEFAULT_TASK_NR+i);
    2ee6:	c7 04 24 53 00 00 00 	movl   $0x53,(%esp)
    2eed:	e8 fc ff ff ff       	call   2eee <init_ap+0x62>
		}
	}
	apic_ids[0].bsp_flag = 1;  /* 这里的代码只有BSP能执行到，所以这里把apic_ids[0]设置为BSP。 */
    2ef2:	c7 05 00 00 00 00 01 	movl   $0x1,0x0
    2ef9:	00 00 00 

#if EMULATOR_TYPE
	__asm__(
    2efc:	b8 01 00 00 00       	mov    $0x1,%eax
    2f01:	0f a2                	cpuid  
    2f03:	c1 eb 18             	shr    $0x18,%ebx
    2f06:	53                   	push   %ebx
    2f07:	6a 00                	push   $0x0
    2f09:	e8 fc ff ff ff       	call   2f0a <init_ap+0x7e>
    2f0e:	5b                   	pop    %ebx
    2f0f:	5b                   	pop    %ebx
    2f10:	6a 00                	push   $0x0
    2f12:	e8 fc ff ff ff       	call   2f13 <init_ap+0x87>
    2f17:	58                   	pop    %eax
    2f18:	8b 15 00 00 00 00    	mov    0x0,%edx
    2f1e:	52                   	push   %edx
    2f1f:	e8 fc ff ff ff       	call   2f20 <init_ap+0x94>
    2f24:	5a                   	pop    %edx
    2f25:	05 00 03 00 00       	add    $0x300,%eax
    2f2a:	c7 00 00 45 0c 00    	movl   $0xc4500,(%eax)
    2f30:	b9 05 00 00 00       	mov    $0x5,%ecx

00002f35 <wait_loop_init>:
    2f35:	49                   	dec    %ecx
    2f36:	90                   	nop
    2f37:	83 f9 00             	cmp    $0x0,%ecx
    2f3a:	75 f9                	jne    2f35 <wait_loop_init>
    2f3c:	c7 00 91 46 0c 00    	movl   $0xc4691,(%eax)
    2f42:	50                   	push   %eax
    2f43:	e8 fc ff ff ff       	call   2f44 <wait_loop_init+0xf>
    2f48:	58                   	pop    %eax
    2f49:	b9 00 10 00 00       	mov    $0x1000,%ecx

00002f4e <wait_loop_sipi>:
    2f4e:	49                   	dec    %ecx
    2f4f:	90                   	nop
    2f50:	83 f9 00             	cmp    $0x0,%ecx
    2f53:	75 f9                	jne    2f4e <wait_loop_sipi>
	    "cmp $0x0,%%ecx\n\t" \
	    "jne wait_loop_sipi\n\t" \
		::);
	/* ============================= End Sending SIPI中断消息给APs ========================== */
#endif
}
    2f55:	83 c4 1c             	add    $0x1c,%esp
    2f58:	c3                   	ret    

00002f59 <print_eax>:

void print_eax(int eax){
    2f59:	83 ec 14             	sub    $0x14,%esp
	printk("ap eax: %d\n\r", eax);
    2f5c:	ff 74 24 18          	pushl  0x18(%esp)
    2f60:	68 1b 02 00 00       	push   $0x21b
    2f65:	e8 fc ff ff ff       	call   2f66 <print_eax+0xd>
}
    2f6a:	83 c4 1c             	add    $0x1c,%esp
    2f6d:	c3                   	ret    

00002f6e <print_ap_test>:

void print_ap_test() {
    2f6e:	83 ec 18             	sub    $0x18,%esp
	printk("come to ap clear\n\r");
    2f71:	68 28 02 00 00       	push   $0x228
    2f76:	e8 fc ff ff ff       	call   2f77 <print_ap_test+0x9>
}
    2f7b:	83 c4 1c             	add    $0x1c,%esp
    2f7e:	c3                   	ret    

00002f7f <set_apic_id>:

/* 保存每个processor的apic-id,通过apic-id就可以解析处CPU的topology */
void set_apic_id(long apic_index,long apic_id) {
	apic_ids[apic_index].apic_id = apic_id;
    2f7f:	6b 44 24 04 1c       	imul   $0x1c,0x4(%esp),%eax
    2f84:	8b 54 24 08          	mov    0x8(%esp),%edx
    2f88:	89 90 04 00 00 00    	mov    %edx,0x4(%eax)
    2f8e:	c3                   	ret    

00002f8f <alloc_ap_kernel_stack>:
}

/* 为每个AP分配一个内核栈 */
void alloc_ap_kernel_stack(long ap_index, long return_addr, int father_id) {
    2f8f:	83 ec 10             	sub    $0x10,%esp
	unsigned long stack_base = apic_ids[ap_index].kernel_stack;
    2f92:	6b 44 24 14 1c       	imul   $0x1c,0x14(%esp),%eax

	struct ap_stack_struct{
		long* stack;
		short selector;
	} ap_stack = {(long*)(stack_base+4096), 0x10};
    2f97:	8b 80 0c 00 00 00    	mov    0xc(%eax),%eax
    2f9d:	05 00 10 00 00       	add    $0x1000,%eax
    2fa2:	89 44 24 08          	mov    %eax,0x8(%esp)
    2fa6:	66 c7 44 24 0c 10 00 	movw   $0x10,0xc(%esp)
	 * 2. 调度执行了新的任务,发生了任务切换操作.
	 *    注意,当执行TSS switch时,会将当前AP的executing context保存到我们指向定义的ap_default_task.tss中.
	 *    这时因为没有执行pop fs操作是不会检查load segment的有效性的,所以是不会报load segment error的.
	 * 1.1这种情况出现的频率比较高,是个巨坑啊,搞了好长时间,调试手段太匮乏了,也是过了好几遍代码灵光乍现想到的,解决了这个问题,AP自主调度就完全搞定了mama.
	 *  */
	__asm__ ("movl $0x10,%%eax\n\t"  \
    2fad:	8b 4c 24 1c          	mov    0x1c(%esp),%ecx
    2fb1:	8b 54 24 18          	mov    0x18(%esp),%edx
    2fb5:	b8 10 00 00 00       	mov    $0x10,%eax
    2fba:	8e e0                	mov    %eax,%fs
    2fbc:	0f b2 64 24 08       	lss    0x8(%esp),%esp
    2fc1:	51                   	push   %ecx
    2fc2:	52                   	push   %edx
    2fc3:	c3                   	ret    
			 "pushl %%ecx\n\t" /* 将father_id入栈，作为后面执行ap_exit_clear代码段中的tell_father函数的入参，这里这样做有点太tricky了,不过我喜欢哈哈. */ \
			 "pushl %%edx\n\t"  \
			 "ret\n\t" \
			::"c" (father_id),"d" (return_addr),"m" (*(&ap_stack))
			);
}
    2fc4:	83 c4 10             	add    $0x10,%esp
    2fc7:	c3                   	ret    

00002fc8 <reset_dir_base>:

void reset_dir_base() {
	__asm__("xorl %%eax,%%eax\n\t" \
    2fc8:	31 c0                	xor    %eax,%eax
    2fca:	0f 22 d8             	mov    %eax,%cr3
    2fcd:	c3                   	ret    

00002fce <reloc_apic_regs_addr>:
			"movl %%eax,%%cr3\n\t" \
			::);
}

/* 对Local APIC Registers的内存映射进行relocate. */
void reloc_apic_regs_addr(unsigned long addr) {
    2fce:	53                   	push   %ebx
__asm__("xor %%eax,%%eax\n\t" \
    2fcf:	8b 5c 24 08          	mov    0x8(%esp),%ebx
    2fd3:	31 c0                	xor    %eax,%eax
    2fd5:	31 d2                	xor    %edx,%edx
    2fd7:	b9 1b 00 00 00       	mov    $0x1b,%ecx
    2fdc:	0f 32                	rdmsr  
    2fde:	25 ff 0f 00 00       	and    $0xfff,%eax
    2fe3:	01 d8                	add    %ebx,%eax
    2fe5:	0f 30                	wrmsr  
    2fe7:	31 c0                	xor    %eax,%eax
    2fe9:	31 d2                	xor    %edx,%edx
    2feb:	0f 32                	rdmsr  
		"rdmsr\n\t" \
		/*"pushl %%eax\n\t" \
		"call print_eax\n\t" \
		"popl %%eax\n\t" \*/
		::"b" (addr));
}
    2fed:	5b                   	pop    %ebx
    2fee:	c3                   	ret    

00002fef <init_apic_addr>:

void init_apic_addr(int apic_index) {
    2fef:	56                   	push   %esi
    2ff0:	53                   	push   %ebx
    2ff1:	8b 5c 24 0c          	mov    0xc(%esp),%ebx
	unsigned long addr = bsp_apic_regs_relocation + (apic_index*0x1000);  /* 为每个APIC的regs分配4K内存 */
    2ff5:	89 de                	mov    %ebx,%esi
    2ff7:	c1 e6 0c             	shl    $0xc,%esi
    2ffa:	03 35 00 00 00 00    	add    0x0,%esi
	reloc_apic_regs_addr(addr);
    3000:	56                   	push   %esi
    3001:	e8 fc ff ff ff       	call   3002 <init_apic_addr+0x13>
	apic_ids[apic_index].apic_regs_addr = addr;
    3006:	6b db 1c             	imul   $0x1c,%ebx,%ebx
    3009:	89 b3 08 00 00 00    	mov    %esi,0x8(%ebx)
}
    300f:	83 c4 04             	add    $0x4,%esp
    3012:	5b                   	pop    %ebx
    3013:	5e                   	pop    %esi
    3014:	c3                   	ret    

00003015 <init_apic_timer>:
• 重点关注这一条: !!! The mask bits for all the LVT entries are set. Attempts to reset these bits will be ignored. !!!
• (For Pentium and P6 family processors) The local APIC continues to listen to all bus messages in order to keep
its arbitration ID synchronized with the rest of the system.
 *
 *  */
void init_apic_timer(int apic_index) {
    3015:	53                   	push   %ebx
	unsigned long init_count = 1193180/HZ;
#if EMULATOR_TYPE
	unsigned long addr = BSP_APIC_REGS_DEFAULT_LOCATION; /* apic.regs base addr for QEMU, default addr: 0xFEE0 0000 */

	__asm__("pushl %%ecx\n\t"    /* 备份init_count的值，后面的call函数调用会覆盖ecx的值。 */      \
    3016:	b9 16 d2 01 00       	mov    $0x1d216,%ecx
    301b:	b8 00 00 e0 fe       	mov    $0xfee00000,%eax
    3020:	8b 5c 24 08          	mov    0x8(%esp),%ebx
    3024:	51                   	push   %ecx
    3025:	50                   	push   %eax
    3026:	e8 fc ff ff ff       	call   3027 <init_apic_timer+0x12>
    302b:	89 c2                	mov    %eax,%edx
    302d:	58                   	pop    %eax
    302e:	52                   	push   %edx
    302f:	81 c2 f0 00 00 00    	add    $0xf0,%edx
    3035:	8b 02                	mov    (%edx),%eax
    3037:	0f ba e8 08          	bts    $0x8,%eax
    303b:	89 02                	mov    %eax,(%edx)
    303d:	58                   	pop    %eax
    303e:	89 c2                	mov    %eax,%edx
    3040:	81 c2 e0 03 00 00    	add    $0x3e0,%edx
    3046:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
    304c:	83 fb 00             	cmp    $0x0,%ebx
    304f:	75 07                	jne    3058 <init_apic_timer+0x43>
    3051:	bb 83 00 02 00       	mov    $0x20083,%ebx
    3056:	eb 05                	jmp    305d <init_apic_timer+0x48>
    3058:	bb 83 00 03 00       	mov    $0x30083,%ebx
    305d:	89 c2                	mov    %eax,%edx
    305f:	81 c2 20 03 00 00    	add    $0x320,%edx
    3065:	89 1a                	mov    %ebx,(%edx)
    3067:	89 c2                	mov    %eax,%edx
    3069:	81 c2 80 03 00 00    	add    $0x380,%edx
    306f:	59                   	pop    %ecx
    3070:	89 0a                	mov    %ecx,(%edx)
    3072:	50                   	push   %eax
    3073:	e8 fc ff ff ff       	call   3074 <init_apic_timer+0x5f>
    3078:	58                   	pop    %eax
			"popl %%eax\n\t"            \*/

			::"a" (addr),"b" (apic_index), "c" (init_count));
#endif

}
    3079:	5b                   	pop    %ebx
    307a:	c3                   	ret    

0000307b <start_apic_timer>:

void start_apic_timer(int apic_index) {
    307b:	83 ec 18             	sub    $0x18,%esp
#if EMULATOR_TYPE
	unsigned long addr = remap_msr_linear_addr(BSP_APIC_REGS_DEFAULT_LOCATION);
    307e:	68 00 00 e0 fe       	push   $0xfee00000
    3083:	e8 fc ff ff ff       	call   3084 <start_apic_timer+0x9>
#else
	unsigned long addr = bsp_apic_regs_relocation + (apic_index*0x1000); /* apic.regs base addr */
#endif

	unsigned long init_count = 1193180/HZ;
	__asm__("movl %%eax,%%edx\n\t"      \
    3088:	b9 16 d2 01 00       	mov    $0x1d216,%ecx
    308d:	89 c2                	mov    %eax,%edx
    308f:	81 c2 20 03 00 00    	add    $0x320,%edx
    3095:	c7 02 83 00 02 00    	movl   $0x20083,(%edx)
            "movl $0x20083,0(%%edx)\n\t" /* LVT timer register, mode: 1(periodic,bit 17), mask: 0, vector number: 0x83=APIC_TIMER_INTR_NO  */ \

			::"a" (addr),"c" (init_count));

#if EMULATOR_TYPE
	recov_msr_swap_linear(addr);
    309b:	89 04 24             	mov    %eax,(%esp)
    309e:	e8 fc ff ff ff       	call   309f <start_apic_timer+0x24>
#endif
}
    30a3:	83 c4 1c             	add    $0x1c,%esp
    30a6:	c3                   	ret    
