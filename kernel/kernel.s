
kernel.o:     file format elf32-i386


Disassembly of section .text:

00000000 <show_task>:
/**************************************************************************/

extern void task_exit_clear(void);

void show_task(int nr,struct task_struct * p)
{
       0:	53                   	push   %ebx
       1:	83 ec 08             	sub    $0x8,%esp
       4:	8b 5c 24 14          	mov    0x14(%esp),%ebx
	int i,j = 4096-sizeof(struct task_struct);

	printk("%d: pid=%d, state=%d, ",nr,p->pid,p->state);
       8:	ff 33                	pushl  (%ebx)
       a:	ff b3 2c 02 00 00    	pushl  0x22c(%ebx)
      10:	ff 74 24 18          	pushl  0x18(%esp)
      14:	68 00 00 00 00       	push   $0x0
      19:	e8 fc ff ff ff       	call   1a <show_task+0x1a>
	i=0;
	while (i<j && !((char *)(p+1))[i])
      1e:	83 c4 10             	add    $0x10,%esp
      21:	b8 01 00 00 00       	mov    $0x1,%eax
      26:	80 bb c8 03 00 00 00 	cmpb   $0x0,0x3c8(%ebx)
      2d:	74 11                	je     40 <show_task+0x40>
void show_task(int nr,struct task_struct * p)
{
	int i,j = 4096-sizeof(struct task_struct);

	printk("%d: pid=%d, state=%d, ",nr,p->pid,p->state);
	i=0;
      2f:	b8 00 00 00 00       	mov    $0x0,%eax
      34:	eb 14                	jmp    4a <show_task+0x4a>
	while (i<j && !((char *)(p+1))[i])
		i++;
      36:	83 c0 01             	add    $0x1,%eax
{
	int i,j = 4096-sizeof(struct task_struct);

	printk("%d: pid=%d, state=%d, ",nr,p->pid,p->state);
	i=0;
	while (i<j && !((char *)(p+1))[i])
      39:	3d 38 0c 00 00       	cmp    $0xc38,%eax
      3e:	74 0a                	je     4a <show_task+0x4a>
      40:	80 bc 03 c8 03 00 00 	cmpb   $0x0,0x3c8(%ebx,%eax,1)
      47:	00 
      48:	74 ec                	je     36 <show_task+0x36>
		i++;
	printk("%d (of %d) chars free in kernel stack\n\r",i,j);
      4a:	83 ec 04             	sub    $0x4,%esp
      4d:	68 38 0c 00 00       	push   $0xc38
      52:	50                   	push   %eax
      53:	68 00 00 00 00       	push   $0x0
      58:	e8 fc ff ff ff       	call   59 <show_task+0x59>
}
      5d:	83 c4 18             	add    $0x18,%esp
      60:	5b                   	pop    %ebx
      61:	c3                   	ret    

00000062 <show_stat>:

void show_stat(void)
{
      62:	53                   	push   %ebx
      63:	83 ec 08             	sub    $0x8,%esp
	int i;

	for (i=0;i<NR_TASKS;i++)
      66:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (task[i])
      6b:	8b 04 9d 00 00 00 00 	mov    0x0(,%ebx,4),%eax
      72:	85 c0                	test   %eax,%eax
      74:	74 0d                	je     83 <show_stat+0x21>
			show_task(i,task[i]);
      76:	83 ec 08             	sub    $0x8,%esp
      79:	50                   	push   %eax
      7a:	53                   	push   %ebx
      7b:	e8 fc ff ff ff       	call   7c <show_stat+0x1a>
      80:	83 c4 10             	add    $0x10,%esp

void show_stat(void)
{
	int i;

	for (i=0;i<NR_TASKS;i++)
      83:	83 c3 01             	add    $0x1,%ebx
      86:	83 fb 40             	cmp    $0x40,%ebx
      89:	75 e0                	jne    6b <show_stat+0x9>
		if (task[i])
			show_task(i,task[i]);
}
      8b:	83 c4 08             	add    $0x8,%esp
      8e:	5b                   	pop    %ebx
      8f:	c3                   	ret    

00000090 <get_current_apic_id>:
	} stack_start = {&user_stack[PAGE_SIZE>>2] , 0x10};

/*
 * 获取当前processor正在运行的任务
 */
unsigned long get_current_apic_id(){
      90:	53                   	push   %ebx
      91:	83 ec 10             	sub    $0x10,%esp
	register unsigned long apic_id asm("ebx");
	unsigned char gdt_base[8] = {0,}; /* 16-bit limit stored in low two bytes, and gdt_base stored in high 4bytes. */
      94:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
      9b:	00 
      9c:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
      a3:	00 
	/*
	 * 在Guest VM 环境下，执行cpuid指令会导致vm-exit，所以这里要判断当前的执行环境是否在VM环境.
	 * 实现思路：我们知道在VM环境下，已经为GDT表分配了4K空间，且GDT表的首8字节是不用的，这里利用这8个字节存储vm-entry环境下的apic_id.
	 */
	__asm__ ("sgdt %1\n\t"              \
      a4:	0f 01 44 24 08       	sgdtl  0x8(%esp)
      a9:	8b 44 24 0a          	mov    0xa(%esp),%eax
      ad:	8b 18                	mov    (%eax),%ebx
      af:	83 fb 00             	cmp    $0x0,%ebx
      b2:	75 0c                	jne    c0 <truncate_flag>
      b4:	b8 01 00 00 00       	mov    $0x1,%eax
      b9:	0f a2                	cpuid  
      bb:	c1 eb 18             	shr    $0x18,%ebx
      be:	eb 06                	jmp    c6 <output>

000000c0 <truncate_flag>:
      c0:	81 e3 ff 00 00 00    	and    $0xff,%ebx

000000c6 <output>:
			 "truncate_flag:\n\t"       \
			 "andl $0xFF,%%ebx\n\t" /* 这里假设最多有255个processor */  \
			 "output:\n\t"              \
			 :"=b" (apic_id) :"m" (*gdt_base),"m" (*(char*)(gdt_base+2))
			);
	return apic_id;
      c6:	89 d8                	mov    %ebx,%eax
}
      c8:	83 c4 10             	add    $0x10,%esp
      cb:	5b                   	pop    %ebx
      cc:	c3                   	ret    

000000cd <get_apic_info>:



struct apic_info* get_apic_info(unsigned long apic_id) {
      cd:	8b 54 24 04          	mov    0x4(%esp),%edx
	for (int i=0;i<LOGICAL_PROCESSOR_NUM;i++) {
		if (apic_ids[i].apic_id == apic_id) {
      d1:	3b 15 04 00 00 00    	cmp    0x4,%edx
      d7:	74 32                	je     10b <get_apic_info+0x3e>
      d9:	3b 15 20 00 00 00    	cmp    0x20,%edx
      df:	74 1c                	je     fd <get_apic_info+0x30>
      e1:	3b 15 3c 00 00 00    	cmp    0x3c,%edx
      e7:	74 1b                	je     104 <get_apic_info+0x37>
			return &apic_ids[i];
		}
	}
	return 0;
      e9:	b8 00 00 00 00       	mov    $0x0,%eax



struct apic_info* get_apic_info(unsigned long apic_id) {
	for (int i=0;i<LOGICAL_PROCESSOR_NUM;i++) {
		if (apic_ids[i].apic_id == apic_id) {
      ee:	39 15 58 00 00 00    	cmp    %edx,0x58
      f4:	75 22                	jne    118 <get_apic_info+0x4b>
}



struct apic_info* get_apic_info(unsigned long apic_id) {
	for (int i=0;i<LOGICAL_PROCESSOR_NUM;i++) {
      f6:	b8 03 00 00 00       	mov    $0x3,%eax
      fb:	eb 13                	jmp    110 <get_apic_info+0x43>
      fd:	b8 01 00 00 00       	mov    $0x1,%eax
     102:	eb 0c                	jmp    110 <get_apic_info+0x43>
     104:	b8 02 00 00 00       	mov    $0x2,%eax
     109:	eb 05                	jmp    110 <get_apic_info+0x43>
     10b:	b8 00 00 00 00       	mov    $0x0,%eax
		if (apic_ids[i].apic_id == apic_id) {
			return &apic_ids[i];
     110:	6b c0 1c             	imul   $0x1c,%eax,%eax
     113:	05 00 00 00 00       	add    $0x0,%eax
		}
	}
	return 0;
}
     118:	f3 c3                	repz ret 

0000011a <get_current_task>:

struct task_struct* get_current_task(){
	return get_apic_info(get_current_apic_id())->current;
     11a:	e8 fc ff ff ff       	call   11b <get_current_task+0x1>
     11f:	50                   	push   %eax
     120:	e8 fc ff ff ff       	call   121 <get_current_task+0x7>
     125:	83 c4 04             	add    $0x4,%esp
     128:	8b 40 14             	mov    0x14(%eax),%eax
}
     12b:	c3                   	ret    

0000012c <sys_alarm>:

	schedule();
}

int sys_alarm(long seconds)
{
     12c:	56                   	push   %esi
     12d:	53                   	push   %ebx
     12e:	8b 5c 24 0c          	mov    0xc(%esp),%ebx
	struct task_struct* current = get_current_task();
     132:	e8 fc ff ff ff       	call   133 <sys_alarm+0x7>
     137:	89 c6                	mov    %eax,%esi
	int old = current->alarm;
     139:	8b 80 4c 02 00 00    	mov    0x24c(%eax),%eax

	if (old)
     13f:	85 c0                	test   %eax,%eax
     141:	74 1b                	je     15e <sys_alarm+0x32>
		old = (old - jiffies) / HZ;
     143:	8b 15 00 00 00 00    	mov    0x0,%edx
     149:	29 d0                	sub    %edx,%eax
     14b:	89 c1                	mov    %eax,%ecx
     14d:	ba 67 66 66 66       	mov    $0x66666667,%edx
     152:	f7 ea                	imul   %edx
     154:	89 d0                	mov    %edx,%eax
     156:	c1 f8 02             	sar    $0x2,%eax
     159:	c1 f9 1f             	sar    $0x1f,%ecx
     15c:	29 c8                	sub    %ecx,%eax
	current->alarm = (seconds>0)?(jiffies+HZ*seconds):0;
     15e:	85 db                	test   %ebx,%ebx
     160:	7e 0e                	jle    170 <sys_alarm+0x44>
     162:	8b 15 00 00 00 00    	mov    0x0,%edx
     168:	8d 0c 9b             	lea    (%ebx,%ebx,4),%ecx
     16b:	8d 14 4a             	lea    (%edx,%ecx,2),%edx
     16e:	eb 05                	jmp    175 <sys_alarm+0x49>
     170:	ba 00 00 00 00       	mov    $0x0,%edx
     175:	89 96 4c 02 00 00    	mov    %edx,0x24c(%esi)
	return (old);
}
     17b:	5b                   	pop    %ebx
     17c:	5e                   	pop    %esi
     17d:	c3                   	ret    

0000017e <sys_getpid>:

int sys_getpid(void)
{
	struct task_struct* current = get_current_task();
     17e:	e8 fc ff ff ff       	call   17f <sys_getpid+0x1>
	return current->pid;
     183:	8b 80 2c 02 00 00    	mov    0x22c(%eax),%eax
}
     189:	c3                   	ret    

0000018a <sys_getppid>:

int sys_getppid(void)
{
	struct task_struct* current = get_current_task();
     18a:	e8 fc ff ff ff       	call   18b <sys_getppid+0x1>
	return current->father;
     18f:	8b 80 30 02 00 00    	mov    0x230(%eax),%eax
}
     195:	c3                   	ret    

00000196 <sys_getuid>:

int sys_getuid(void)
{
	struct task_struct* current = get_current_task();
     196:	e8 fc ff ff ff       	call   197 <sys_getuid+0x1>
	return current->uid;
     19b:	0f b7 80 40 02 00 00 	movzwl 0x240(%eax),%eax
}
     1a2:	c3                   	ret    

000001a3 <sys_geteuid>:

int sys_geteuid(void)
{
	struct task_struct* current = get_current_task();
     1a3:	e8 fc ff ff ff       	call   1a4 <sys_geteuid+0x1>
	return current->euid;
     1a8:	0f b7 80 42 02 00 00 	movzwl 0x242(%eax),%eax
}
     1af:	c3                   	ret    

000001b0 <sys_getgid>:

int sys_getgid(void)
{
	struct task_struct* current = get_current_task();
     1b0:	e8 fc ff ff ff       	call   1b1 <sys_getgid+0x1>
	return current->gid;
     1b5:	0f b7 80 46 02 00 00 	movzwl 0x246(%eax),%eax
}
     1bc:	c3                   	ret    

000001bd <sys_getegid>:

int sys_getegid(void)
{
	struct task_struct* current = get_current_task();
     1bd:	e8 fc ff ff ff       	call   1be <sys_getegid+0x1>
	return current->egid;
     1c2:	0f b7 80 48 02 00 00 	movzwl 0x248(%eax),%eax
}
     1c9:	c3                   	ret    

000001ca <sys_nice>:

int sys_nice(long increment)
{
	struct task_struct* current = get_current_task();
     1ca:	e8 fc ff ff ff       	call   1cb <sys_nice+0x1>
	if (current->priority-increment>0)
     1cf:	8b 50 08             	mov    0x8(%eax),%edx
     1d2:	2b 54 24 04          	sub    0x4(%esp),%edx
     1d6:	85 d2                	test   %edx,%edx
     1d8:	7e 03                	jle    1dd <sys_nice+0x13>
		current->priority -= increment;
     1da:	89 50 08             	mov    %edx,0x8(%eax)
	return 0;
}
     1dd:	b8 00 00 00 00       	mov    $0x0,%eax
     1e2:	c3                   	ret    

000001e3 <reset_cpu_load>:
	return get_apic_info(get_current_apic_id())->current;
}

void reset_cpu_load() {
	for (int i=0;i<LOGICAL_PROCESSOR_NUM;i++) {
		apic_ids[i].load_per_apic = 0;
     1e3:	c7 05 10 00 00 00 00 	movl   $0x0,0x10
     1ea:	00 00 00 
     1ed:	c7 05 2c 00 00 00 00 	movl   $0x0,0x2c
     1f4:	00 00 00 
     1f7:	c7 05 48 00 00 00 00 	movl   $0x0,0x48
     1fe:	00 00 00 
     201:	c7 05 64 00 00 00 00 	movl   $0x0,0x64
     208:	00 00 00 
     20b:	c3                   	ret    

0000020c <get_min_load_ap>:
	}
}

/* 计算哪个AP的负载最小，后续的task将会调度该AP执行。 */
unsigned long get_min_load_ap() {
     20c:	53                   	push   %ebx
	unsigned long apic_index = 1;  /* BSP不参与计算 */
	int overload = 0;
	if (apic_ids[apic_index].load_per_apic == 0xFFFFFFFF) {
     20d:	a1 2c 00 00 00       	mov    0x2c,%eax
}

/* 计算哪个AP的负载最小，后续的task将会调度该AP执行。 */
unsigned long get_min_load_ap() {
	unsigned long apic_index = 1;  /* BSP不参与计算 */
	int overload = 0;
     212:	83 f8 ff             	cmp    $0xffffffff,%eax
     215:	0f 94 c2             	sete   %dl
     218:	0f b6 d2             	movzbl %dl,%edx
	if (apic_ids[apic_index].load_per_apic == 0xFFFFFFFF) {
		++overload;
	}
	for (int i=2;i<LOGICAL_PROCESSOR_NUM;i++) {
		if (apic_ids[i].load_per_apic == 0xFFFFFFFF) {
     21b:	8b 0d 48 00 00 00    	mov    0x48,%ecx
     221:	83 f9 ff             	cmp    $0xffffffff,%ecx
     224:	74 0b                	je     231 <get_min_load_ap+0x25>
			++overload;
			continue;
		}
		if (apic_ids[apic_index].load_per_apic > apic_ids[i].load_per_apic) {
     226:	39 c1                	cmp    %eax,%ecx
     228:	19 c0                	sbb    %eax,%eax
     22a:	f7 d0                	not    %eax
     22c:	83 c0 02             	add    $0x2,%eax
     22f:	eb 08                	jmp    239 <get_min_load_ap+0x2d>
	if (apic_ids[apic_index].load_per_apic == 0xFFFFFFFF) {
		++overload;
	}
	for (int i=2;i<LOGICAL_PROCESSOR_NUM;i++) {
		if (apic_ids[i].load_per_apic == 0xFFFFFFFF) {
			++overload;
     231:	83 c2 01             	add    $0x1,%edx
     234:	b8 01 00 00 00       	mov    $0x1,%eax
	int overload = 0;
	if (apic_ids[apic_index].load_per_apic == 0xFFFFFFFF) {
		++overload;
	}
	for (int i=2;i<LOGICAL_PROCESSOR_NUM;i++) {
		if (apic_ids[i].load_per_apic == 0xFFFFFFFF) {
     239:	8b 1d 64 00 00 00    	mov    0x64,%ebx
     23f:	83 fb ff             	cmp    $0xffffffff,%ebx
     242:	75 05                	jne    249 <get_min_load_ap+0x3d>
			++overload;
     244:	83 c2 01             	add    $0x1,%edx
			continue;
     247:	eb 14                	jmp    25d <get_min_load_ap+0x51>
		}
		if (apic_ids[apic_index].load_per_apic > apic_ids[i].load_per_apic) {
     249:	6b c8 1c             	imul   $0x1c,%eax,%ecx
     24c:	81 c1 00 00 00 00    	add    $0x0,%ecx
			apic_index = i;
     252:	3b 59 10             	cmp    0x10(%ecx),%ebx
     255:	b9 03 00 00 00       	mov    $0x3,%ecx
     25a:	0f 42 c1             	cmovb  %ecx,%eax
		}
	}
	if (overload == LOGICAL_PROCESSOR_NUM-1) {
     25d:	83 fa 03             	cmp    $0x3,%edx
     260:	75 0c                	jne    26e <get_min_load_ap+0x62>
		reset_cpu_load();
     262:	e8 fc ff ff ff       	call   263 <get_min_load_ap+0x57>
		return apic_ids[LOGICAL_PROCESSOR_NUM-1].apic_id;
     267:	a1 58 00 00 00       	mov    0x58,%eax
     26c:	eb 09                	jmp    277 <get_min_load_ap+0x6b>
	}

	return apic_ids[apic_index].apic_id;
     26e:	6b c0 1c             	imul   $0x1c,%eax,%eax
     271:	8b 80 04 00 00 00    	mov    0x4(%eax),%eax
}
     277:	5b                   	pop    %ebx
     278:	c3                   	ret    

00000279 <check_default_task_running_on_ap>:

int check_default_task_running_on_ap() {
	if (get_current_apic_id()) {
     279:	e8 fc ff ff ff       	call   27a <check_default_task_running_on_ap+0x1>
		}
		else {
			return 0;
		}
	}
	return 0;
     27e:	ba 00 00 00 00       	mov    $0x0,%edx

	return apic_ids[apic_index].apic_id;
}

int check_default_task_running_on_ap() {
	if (get_current_apic_id()) {
     283:	85 c0                	test   %eax,%eax
     285:	74 10                	je     297 <check_default_task_running_on_ap+0x1e>
		if (get_current_task() == &ap_default_task.task) {
     287:	e8 fc ff ff ff       	call   288 <check_default_task_running_on_ap+0xf>
			return 1;
     28c:	3d 00 00 00 00       	cmp    $0x0,%eax
     291:	0f 94 c2             	sete   %dl
     294:	0f b6 d2             	movzbl %dl,%edx
		else {
			return 0;
		}
	}
	return 0;
}
     297:	89 d0                	mov    %edx,%eax
     299:	c3                   	ret    

0000029a <send_IPI>:
/*
 * 向指定的AP发送IPI中断消息,要先写ICR的高32位，因为写低32位就会触发IPI了，
 * 所以要现将apic_id写到destination field,然后再触发IPI。
 */
#if EMULATOR_TYPE
void send_IPI(int apic_id, int v_num) {
     29a:	53                   	push   %ebx
__asm__ ("movl bsp_apic_default_location,%%edx\n\t" \
     29b:	8b 4c 24 08          	mov    0x8(%esp),%ecx
     29f:	8b 5c 24 0c          	mov    0xc(%esp),%ebx
     2a3:	8b 15 00 00 00 00    	mov    0x0,%edx
     2a9:	52                   	push   %edx
     2aa:	e8 fc ff ff ff       	call   2ab <send_IPI+0x11>
     2af:	5a                   	pop    %edx
     2b0:	89 c2                	mov    %eax,%edx
     2b2:	83 c2 10             	add    $0x10,%edx
     2b5:	c1 e1 18             	shl    $0x18,%ecx
     2b8:	89 0a                	mov    %ecx,(%edx)
     2ba:	89 c2                	mov    %eax,%edx
     2bc:	81 c3 00 40 00 00    	add    $0x4000,%ebx
     2c2:	89 1a                	mov    %ebx,(%edx)
     2c4:	50                   	push   %eax
     2c5:	e8 fc ff ff ff       	call   2c6 <send_IPI+0x2c>
     2ca:	58                   	pop    %eax

000002cb <wait_loop_ipi>:
     2cb:	31 c0                	xor    %eax,%eax
     2cd:	8b 02                	mov    (%edx),%eax
     2cf:	25 00 10 00 00       	and    $0x1000,%eax
     2d4:	83 f8 00             	cmp    $0x0,%eax
     2d7:	75 f2                	jne    2cb <wait_loop_ipi>
		 "movl 0(%%edx),%%eax\n\t" \
		 "andl $0x00001000,%%eax\n\t"    /* 判断ICR低32位的delivery status field, 0: idle, 1: send pending */  \
		 "cmpl $0x00,%%eax\n\t"   \
		 "jne wait_loop_ipi\n\t"  \
		 ::"c" (apic_id),"b" (v_num));
}
     2d9:	5b                   	pop    %ebx
     2da:	c3                   	ret    

000002db <send_EOI>:

/* 发送中断处理结束信号： end of interrupt */
void send_EOI() {
     2db:	83 ec 0c             	sub    $0xc,%esp
	unsigned long apic_id = get_current_apic_id();
     2de:	e8 fc ff ff ff       	call   2df <send_EOI+0x4>
	struct apic_info* apic = get_apic_info(apic_id);
     2e3:	50                   	push   %eax
     2e4:	e8 fc ff ff ff       	call   2e5 <send_EOI+0xa>
     2e9:	83 c4 04             	add    $0x4,%esp
	if (apic) {
     2ec:	85 c0                	test   %eax,%eax
     2ee:	74 21                	je     311 <send_EOI+0x36>
		unsigned long addr = apic->apic_regs_addr;
		addr = remap_msr_linear_addr(addr);
     2f0:	83 ec 0c             	sub    $0xc,%esp
     2f3:	ff 70 08             	pushl  0x8(%eax)
     2f6:	e8 fc ff ff ff       	call   2f7 <send_EOI+0x1c>
		__asm__("addl $0xB0,%%eax\n\t" /* EOI register offset relative with APIC_REGS_BASE is 0xB0 */ \
     2fb:	05 b0 00 00 00       	add    $0xb0,%eax
     300:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
				"movl $0x00,0(%%eax)"  /* Write EOI register */ \
				::"a" (addr)
				);
		recov_msr_swap_linear(addr);
     306:	89 04 24             	mov    %eax,(%esp)
     309:	e8 fc ff ff ff       	call   30a <send_EOI+0x2f>
     30e:	83 c4 10             	add    $0x10,%esp
	}
}
     311:	83 c4 0c             	add    $0xc,%esp
     314:	c3                   	ret    

00000315 <get_current_apic_index>:
}
#endif


unsigned long get_current_apic_index() {
	unsigned long apic_id = get_current_apic_id();
     315:	e8 fc ff ff ff       	call   316 <get_current_apic_index+0x1>
     31a:	89 c2                	mov    %eax,%edx
	for (int i=0;i<LOGICAL_PROCESSOR_NUM;i++) {
		if (apic_ids[i].apic_id == apic_id) {
     31c:	3b 05 04 00 00 00    	cmp    0x4,%eax
     322:	74 2f                	je     353 <get_current_apic_index+0x3e>
     324:	3b 05 20 00 00 00    	cmp    0x20,%eax
     32a:	74 1b                	je     347 <get_current_apic_index+0x32>
     32c:	3b 05 3c 00 00 00    	cmp    0x3c,%eax
     332:	74 19                	je     34d <get_current_apic_index+0x38>
			return i;
		}
	}
	return 0;
     334:	b8 00 00 00 00       	mov    $0x0,%eax


unsigned long get_current_apic_index() {
	unsigned long apic_id = get_current_apic_id();
	for (int i=0;i<LOGICAL_PROCESSOR_NUM;i++) {
		if (apic_ids[i].apic_id == apic_id) {
     339:	3b 15 58 00 00 00    	cmp    0x58,%edx
     33f:	75 17                	jne    358 <get_current_apic_index+0x43>
#endif


unsigned long get_current_apic_index() {
	unsigned long apic_id = get_current_apic_id();
	for (int i=0;i<LOGICAL_PROCESSOR_NUM;i++) {
     341:	b8 03 00 00 00       	mov    $0x3,%eax
     346:	c3                   	ret    
     347:	b8 01 00 00 00       	mov    $0x1,%eax
     34c:	c3                   	ret    
     34d:	b8 02 00 00 00       	mov    $0x2,%eax
     352:	c3                   	ret    
     353:	b8 00 00 00 00       	mov    $0x0,%eax
		if (apic_ids[i].apic_id == apic_id) {
			return i;
		}
	}
	return 0;
}
     358:	f3 c3                	repz ret 

0000035a <reload_ap_ltr>:

/* 主要是为了AP初始化的时候使用，用于任务一开始切换时，将当前内核态的context信息存储到指定的位置，而不是一开始默认的0x00地址处，这样就不会覆盖内核的目录表了。 */
void reload_ap_ltr() {
	//set_tss_desc(gdt+(nr<<1)+FIRST_TSS_ENTRY, &(ap_default_task.task.tss));
	int nr = (get_current_apic_index() + AP_DEFAULT_TASK_NR);
     35a:	e8 fc ff ff ff       	call   35b <reload_ap_ltr+0x1>
	ltr(nr);
     35f:	c1 e0 04             	shl    $0x4,%eax
     362:	8d 80 20 05 00 00    	lea    0x520(%eax),%eax
     368:	0f 00 d8             	ltr    %ax
     36b:	c3                   	ret    

0000036c <init_ap_tss>:
}

void init_ap_tss(int nr) {
	set_tss_desc(gdt+(nr<<1)+FIRST_TSS_ENTRY, &(ap_default_task.task.tss));
     36c:	8b 44 24 04          	mov    0x4(%esp),%eax
     370:	8d 54 00 04          	lea    0x4(%eax,%eax,1),%edx
     374:	b8 e8 02 00 00       	mov    $0x2e8,%eax
     379:	66 c7 04 d5 00 00 00 	movw   $0x68,0x0(,%edx,8)
     380:	00 68 00 
     383:	66 89 04 d5 02 00 00 	mov    %ax,0x2(,%edx,8)
     38a:	00 
     38b:	c1 c8 10             	ror    $0x10,%eax
     38e:	88 04 d5 04 00 00 00 	mov    %al,0x4(,%edx,8)
     395:	c6 04 d5 05 00 00 00 	movb   $0x89,0x5(,%edx,8)
     39c:	89 
     39d:	c6 04 d5 06 00 00 00 	movb   $0x0,0x6(,%edx,8)
     3a4:	00 
     3a5:	88 24 d5 07 00 00 00 	mov    %ah,0x7(,%edx,8)
     3ac:	c1 c8 10             	ror    $0x10,%eax
     3af:	c3                   	ret    

000003b0 <reset_ap_default_task>:
}

void reset_ap_default_task() {
	unsigned long apic_index = get_current_apic_index();
     3b0:	e8 fc ff ff ff       	call   3b1 <reset_ap_default_task+0x1>
	apic_ids[apic_index].current = &ap_default_task.task;
     3b5:	6b c0 1c             	imul   $0x1c,%eax,%eax
     3b8:	c7 80 14 00 00 00 00 	movl   $0x0,0x14(%eax)
     3bf:	00 00 00 
     3c2:	c3                   	ret    

000003c3 <lock_op>:
}

void lock_op(unsigned long* sem_addr) {
	__asm__ ("lock_loop:\n\t"        \
     3c3:	8b 44 24 04          	mov    0x4(%esp),%eax

000003c7 <lock_loop>:
     3c7:	83 38 00             	cmpl   $0x0,(%eax)
     3ca:	75 fb                	jne    3c7 <lock_loop>
     3cc:	ba 01 00 00 00       	mov    $0x1,%edx
     3d1:	f0 87 10             	lock xchg %edx,(%eax)
     3d4:	83 fa 00             	cmp    $0x0,%edx
     3d7:	75 ee                	jne    3c7 <lock_loop>
     3d9:	c3                   	ret    

000003da <unlock_op>:
			 ::"m" (*sem_addr)       \
		    );
}

void unlock_op(unsigned long* sem_addr) {
	__asm__ ("cmpl $0x00,%0\n\t" \
     3da:	8b 44 24 04          	mov    0x4(%esp),%eax
     3de:	83 38 00             	cmpl   $0x0,(%eax)
     3e1:	7e 03                	jle    3e6 <unlock_op+0xc>
     3e3:	83 28 01             	subl   $0x1,(%eax)
     3e6:	c3                   	ret    

000003e7 <reset_ap_context>:
			 "1:\n\t" \
			 ::"m" (*sem_addr)   \
			);
}

void reset_ap_context() {
     3e7:	56                   	push   %esi
     3e8:	53                   	push   %ebx
     3e9:	83 ec 04             	sub    $0x4,%esp
	unsigned long apic_index =  get_current_apic_index();
     3ec:	e8 fc ff ff ff       	call   3ed <reset_ap_context+0x6>
     3f1:	89 c3                	mov    %eax,%ebx
	int father_id = get_current_task()->father;
     3f3:	e8 fc ff ff ff       	call   3f4 <reset_ap_context+0xd>
     3f8:	8b b0 30 02 00 00    	mov    0x230(%eax),%esi
	/* tricky 1:
	 * 因为task运行到这,一定是处于内核态的,因此目录表的前256项(管理1G的内核线性地址空间)都是指向相同的页表的.
	 * 这里一定要将AP的CR3设置为0x00,那是因为当前进程随后会被释放掉，其对应的目录表也会被释放掉,就会被其他进程占用,
	 * 这样就会导致当前AP的CR3中的目录表基地址就无效了,所以要将CR3重置为0x00,这样随后的指令依旧可以继续运行在内核态.
	 * */
	reset_dir_base();
     3fe:	e8 fc ff ff ff       	call   3ff <reset_ap_context+0x18>
	 * 不同AP的TR寄存器加载相同的TSS会报General protection错误的.
	 * 例如AP1重置了GDT表NR=0x80 TSS描述符项,然后LTR加载了该TSS, 随后的AP2和AP3也执行AP1相同的操作,那么AP2和AP3是不会报GP错误的,
	 * 但是,AP2和AP2如果仅执行LTR指令加载NR=0x80的TSS描述符项就会报GP错误,这一点Intel手册上没有相关的描述:不同的TR加载相同的TSS.
	 * 这里为了解决这个问题就为每个AP分配一个私有TSS描述符项,NR=0x81,0x82,0x83,这样就不会有问题了,而且NR>64也不会参与schedule调度.
	 * */
	reload_ap_ltr();
     403:	e8 fc ff ff ff       	call   404 <reset_ap_context+0x1d>
	 * 从而成为真正的zombie进程了哈哈,这样就造成严重的内存泄露问题.
	 * 所以reset_ap_default_task一定要放在tell_father之后调用.
	 *  */
	//reset_ap_default_task();
	/* 重新设置AP的内核栈指针，然后跳转到ap_default_loop执行空循环，等待新的IPI/timer中断 */
	alloc_ap_kernel_stack(apic_index,task_exit_clear,father_id);
     408:	83 ec 04             	sub    $0x4,%esp
     40b:	56                   	push   %esi
     40c:	68 00 00 00 00       	push   $0x0
     411:	53                   	push   %ebx
     412:	e8 fc ff ff ff       	call   413 <reset_ap_context+0x2c>
}
     417:	83 c4 14             	add    $0x14,%esp
     41a:	5b                   	pop    %ebx
     41b:	5e                   	pop    %esi
     41c:	c3                   	ret    

0000041d <math_state_restore>:
 *  'math_state_restore()' saves the current math information in the
 * old math state array, and gets the new ones from the current task
 */
void math_state_restore()
{
	struct task_struct* current = get_current_task();
     41d:	e8 fc ff ff ff       	call   41e <math_state_restore+0x1>
	if (last_task_used_math == current)
     422:	8b 15 00 00 00 00    	mov    0x0,%edx
     428:	39 d0                	cmp    %edx,%eax
     42a:	74 2c                	je     458 <math_state_restore+0x3b>
		return;
	__asm__("fwait");
     42c:	9b                   	fwait
	if (last_task_used_math) {
     42d:	85 d2                	test   %edx,%edx
     42f:	74 06                	je     437 <math_state_restore+0x1a>
		__asm__("fnsave %0"::"m" (last_task_used_math->tss.i387));
     431:	dd b2 50 03 00 00    	fnsave 0x350(%edx)
	}
	last_task_used_math=current;
     437:	a3 00 00 00 00       	mov    %eax,0x0
	if (current->used_math) {
     43c:	66 83 b8 64 02 00 00 	cmpw   $0x0,0x264(%eax)
     443:	00 
     444:	74 07                	je     44d <math_state_restore+0x30>
		__asm__("frstor %0"::"m" (current->tss.i387));
     446:	dd a0 50 03 00 00    	frstor 0x350(%eax)
     44c:	c3                   	ret    
	} else {
		__asm__("fninit"::);
     44d:	db e3                	fninit 
		current->used_math=1;
     44f:	66 c7 80 64 02 00 00 	movw   $0x1,0x264(%eax)
     456:	01 00 
     458:	f3 c3                	repz ret 

0000045a <schedule>:
 *   NOTE!!  Task 0 is the 'idle' task, which gets called when no other
 * tasks can run. It can not be killed, and it cannot sleep. The 'state'
 * information in task[0] is never used.
 */
void schedule(void)
{
     45a:	55                   	push   %ebp
     45b:	57                   	push   %edi
     45c:	56                   	push   %esi
     45d:	53                   	push   %ebx
     45e:	83 ec 1c             	sub    $0x1c,%esp
	unsigned long current_apic_id = get_current_apic_id();
     461:	e8 fc ff ff ff       	call   462 <schedule+0x8>
     466:	89 c3                	mov    %eax,%ebx
	if (current_apic_id == 1) {
		//printk("ap1 come to schedule\n\r");
	}
	struct apic_info* apic_info = get_apic_info(current_apic_id);
     468:	50                   	push   %eax
     469:	e8 fc ff ff ff       	call   46a <schedule+0x10>
     46e:	89 c6                	mov    %eax,%esi
	struct task_struct ** current = &(apic_info->current);
	int i,next,c;
	struct task_struct ** p;
/* check alarm, wake up any interruptible tasks that have got a signal */

	lock_op(&sched_semaphore);  /* 这里一定要加锁，否则会出现多个AP同时执行同一个task */
     470:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
     477:	e8 fc ff ff ff       	call   478 <schedule+0x1e>
     47c:	83 c4 04             	add    $0x4,%esp
	 * 因为这里锁的释放有好几处,程序最后还会释放一次,这个临时变量就是保证每个进程对自己加的锁只释放一次,
	 * 如果不加这个临时变量判断一下,程序有可能会释放其他进程加的锁.
	 * */
	int lock_flag = 1;

	for(p = &LAST_TASK ; p > &FIRST_TASK ; --p)
     47f:	ba fc 00 00 00       	mov    $0xfc,%edx
		if (*p) {
     484:	8b 02                	mov    (%edx),%eax
     486:	85 c0                	test   %eax,%eax
     488:	74 46                	je     4d0 <schedule+0x76>
			if ((*p)->alarm && (*p)->alarm < jiffies) {
     48a:	8b 88 4c 02 00 00    	mov    0x24c(%eax),%ecx
     490:	85 c9                	test   %ecx,%ecx
     492:	74 1d                	je     4b1 <schedule+0x57>
     494:	8b 3d 00 00 00 00    	mov    0x0,%edi
     49a:	39 f9                	cmp    %edi,%ecx
     49c:	7d 13                	jge    4b1 <schedule+0x57>
					(*p)->signal |= (1<<(SIGALRM-1));
     49e:	81 48 0c 00 20 00 00 	orl    $0x2000,0xc(%eax)
					(*p)->alarm = 0;
     4a5:	8b 02                	mov    (%edx),%eax
     4a7:	c7 80 4c 02 00 00 00 	movl   $0x0,0x24c(%eax)
     4ae:	00 00 00 
			}
			if (((*p)->signal & ~(_BLOCKABLE & (*p)->blocked)) &&
     4b1:	8b 0a                	mov    (%edx),%ecx
     4b3:	8b 81 10 02 00 00    	mov    0x210(%ecx),%eax
     4b9:	25 ff fe fb ff       	and    $0xfffbfeff,%eax
     4be:	f7 d0                	not    %eax
     4c0:	85 41 0c             	test   %eax,0xc(%ecx)
     4c3:	74 0b                	je     4d0 <schedule+0x76>
     4c5:	83 39 01             	cmpl   $0x1,(%ecx)
     4c8:	75 06                	jne    4d0 <schedule+0x76>
			(*p)->state==TASK_INTERRUPTIBLE)
				(*p)->state=TASK_RUNNING;
     4ca:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	 * 因为这里锁的释放有好几处,程序最后还会释放一次,这个临时变量就是保证每个进程对自己加的锁只释放一次,
	 * 如果不加这个临时变量判断一下,程序有可能会释放其他进程加的锁.
	 * */
	int lock_flag = 1;

	for(p = &LAST_TASK ; p > &FIRST_TASK ; --p)
     4d0:	83 ea 04             	sub    $0x4,%edx
     4d3:	81 fa 00 00 00 00    	cmp    $0x0,%edx
     4d9:	75 a9                	jne    484 <schedule+0x2a>
	while (1) {
		c = -1;
		next = 0;
		i = NR_TASKS;
		p = &task[NR_TASKS];
		while (--i) {
     4db:	b8 3f 00 00 00       	mov    $0x3f,%eax
		}

/* this is the scheduler proper: */

	while (1) {
		c = -1;
     4e0:	bd ff ff ff ff       	mov    $0xffffffff,%ebp
		next = 0;
     4e5:	bf 00 00 00 00       	mov    $0x0,%edi
		i = NR_TASKS;
		p = &task[NR_TASKS];
		while (--i) {
			if (!*--p)
     4ea:	8b 14 85 00 00 00 00 	mov    0x0(,%eax,4),%edx
     4f1:	85 d2                	test   %edx,%edx
     4f3:	74 19                	je     50e <schedule+0xb4>
				continue;
			if ((*p)->state == TASK_RUNNING && (*p)->counter > c && (*p)->sched_on_ap == 0) {
     4f5:	83 3a 00             	cmpl   $0x0,(%edx)
     4f8:	75 14                	jne    50e <schedule+0xb4>
     4fa:	8b 4a 04             	mov    0x4(%edx),%ecx
     4fd:	39 e9                	cmp    %ebp,%ecx
     4ff:	7e 0d                	jle    50e <schedule+0xb4>
				c = (*p)->counter, next = i;
     501:	83 ba bc 03 00 00 00 	cmpl   $0x0,0x3bc(%edx)
     508:	0f 44 e9             	cmove  %ecx,%ebp
     50b:	0f 44 f8             	cmove  %eax,%edi
	while (1) {
		c = -1;
		next = 0;
		i = NR_TASKS;
		p = &task[NR_TASKS];
		while (--i) {
     50e:	83 e8 01             	sub    $0x1,%eax
     511:	75 d7                	jne    4ea <schedule+0x90>
				continue;
			if ((*p)->state == TASK_RUNNING && (*p)->counter > c && (*p)->sched_on_ap == 0) {
				c = (*p)->counter, next = i;
			}
		}
		if (c) break;
     513:	85 ed                	test   %ebp,%ebp
     515:	75 23                	jne    53a <schedule+0xe0>
     517:	b9 fc 00 00 00       	mov    $0xfc,%ecx
		for(p = &LAST_TASK ; p > &FIRST_TASK ; --p) {
			if (*p) {
     51c:	8b 11                	mov    (%ecx),%edx
     51e:	85 d2                	test   %edx,%edx
     520:	74 0b                	je     52d <schedule+0xd3>
				/* 此时如果release其他AP执行介于这之间的话,是会有问题的.具体看release描述. */
				(*p)->counter = ((*p)->counter >> 1) + (*p)->priority;
     522:	8b 42 04             	mov    0x4(%edx),%eax
     525:	d1 f8                	sar    %eax
     527:	03 42 08             	add    0x8(%edx),%eax
     52a:	89 42 04             	mov    %eax,0x4(%edx)
			if ((*p)->state == TASK_RUNNING && (*p)->counter > c && (*p)->sched_on_ap == 0) {
				c = (*p)->counter, next = i;
			}
		}
		if (c) break;
		for(p = &LAST_TASK ; p > &FIRST_TASK ; --p) {
     52d:	83 e9 04             	sub    $0x4,%ecx
     530:	81 f9 00 00 00 00    	cmp    $0x0,%ecx
     536:	75 e4                	jne    51c <schedule+0xc2>
     538:	eb a1                	jmp    4db <schedule+0x81>
				(*p)->counter = ((*p)->counter >> 1) + (*p)->priority;
			}
		}
	}

	if (current_apic_id == apic_ids[0].apic_id) {  /* 调度任务发生在BSP上 */
     53a:	3b 1d 04 00 00 00    	cmp    0x4,%ebx
     540:	75 30                	jne    572 <schedule+0x118>
			}
			++apic_ids[sched_apic_id].load_per_apic;
			next = 1;   /* BSP上只运行task0和task1 */
		}
#else
		if (task[next] != task[0] && task[next] != task[1]) {
     542:	8b 14 bd 00 00 00 00 	mov    0x0(,%edi,4),%edx
     549:	3b 15 00 00 00 00    	cmp    0x0,%edx
     54f:	0f 84 d2 00 00 00    	je     627 <schedule+0x1cd>
     555:	a1 04 00 00 00       	mov    0x4,%eax
     55a:	39 c2                	cmp    %eax,%edx
     55c:	0f 84 c5 00 00 00    	je     627 <schedule+0x1cd>
     562:	83 38 00             	cmpl   $0x0,(%eax)
     565:	0f 94 c0             	sete   %al
     568:	0f b6 c0             	movzbl %al,%eax
     56b:	89 c7                	mov    %eax,%edi
     56d:	e9 b5 00 00 00       	jmp    627 <schedule+0x1cd>
			    (*current)->sched_on_ap = 0;  /* 只有这样，BSP之后才能继续调用该current到其他AP上运行，否则，该进程将永远不会被重新sched. */
			}
			task[next]->sched_on_ap = 1;
		}
#else
		if (task[next] == task[0] || task[next] == task[1]) {
     572:	8b 04 bd 00 00 00 00 	mov    0x0(,%edi,4),%eax
     579:	3b 05 00 00 00 00    	cmp    0x0,%eax
     57f:	74 08                	je     589 <schedule+0x12f>
     581:	3b 05 04 00 00 00    	cmp    0x4,%eax
     587:	75 29                	jne    5b2 <schedule+0x158>
			if (lock_flag) {
				unlock_op(&sched_semaphore);
     589:	68 00 00 00 00       	push   $0x0
     58e:	e8 fc ff ff ff       	call   58f <schedule+0x135>
				lock_flag = 0;
			}
			if (*current != 0) {
     593:	83 c4 04             	add    $0x4,%esp
     596:	83 7e 14 00          	cmpl   $0x0,0x14(%esi)
     59a:	0f 85 99 00 00 00    	jne    639 <schedule+0x1df>
				return;          /* 如果AP有已经执行过的task(包括idle_loop,也就是ap_default_task任务),这时不调度，继续执行老的task. */
			}
			else {/* 执行到这个分支,说明内核是有问题的,current是不可能为0的 */
				panic("Errors occur on AP schedule\n\r");
     5a0:	83 ec 0c             	sub    $0xc,%esp
     5a3:	68 17 00 00 00       	push   $0x17
     5a8:	e8 fc ff ff ff       	call   5a9 <schedule+0x14f>
     5ad:	83 c4 10             	add    $0x10,%esp
     5b0:	eb 49                	jmp    5fb <schedule+0x1a1>
			}
		}
		else {  /* 这时AP要调度新的task[n>1] */
			unsigned long sched_apic_id = get_min_load_ap();
     5b2:	e8 fc ff ff ff       	call   5b3 <schedule+0x159>
			if (sched_apic_id == current_apic_id) {
     5b7:	39 c3                	cmp    %eax,%ebx
     5b9:	75 2e                	jne    5e9 <schedule+0x18f>
				if (*current) {
     5bb:	8b 46 14             	mov    0x14(%esi),%eax
     5be:	85 c0                	test   %eax,%eax
     5c0:	74 0a                	je     5cc <schedule+0x172>
					/* 只有这样，BSP之后才能继续调用该current到其他AP上运行，否则，该进程将永远不会被重新sched.(但ap_default_task是永远不会被调度的) */
				    (*current)->sched_on_ap = 0;
     5c2:	c7 80 bc 03 00 00 00 	movl   $0x0,0x3bc(%eax)
     5c9:	00 00 00 
				}
				task[next]->sched_on_ap = 1;      /* 设置任务占用符,这样释放锁以后,该任务是不会被其他AP调度执行的 */
     5cc:	8b 04 bd 00 00 00 00 	mov    0x0(,%edi,4),%eax
     5d3:	c7 80 bc 03 00 00 01 	movl   $0x1,0x3bc(%eax)
     5da:	00 00 00 
				++apic_ids[sched_apic_id].load_per_apic;
     5dd:	6b db 1c             	imul   $0x1c,%ebx,%ebx
     5e0:	83 83 10 00 00 00 01 	addl   $0x1,0x10(%ebx)
     5e7:	eb 3e                	jmp    627 <schedule+0x1cd>
			}
			else {
				if (lock_flag) {
					unlock_op(&sched_semaphore);
     5e9:	83 ec 0c             	sub    $0xc,%esp
     5ec:	68 00 00 00 00       	push   $0x0
     5f1:	e8 fc ff ff ff       	call   5f2 <schedule+0x198>
     5f6:	83 c4 10             	add    $0x10,%esp
     5f9:	eb 3e                	jmp    639 <schedule+0x1df>
	}
	if (lock_flag) {
		unlock_op(&sched_semaphore);
		lock_flag = 0;
	}
	switch_to(next,current);
     5fb:	89 fa                	mov    %edi,%edx
     5fd:	c1 e2 04             	shl    $0x4,%edx
     600:	83 c2 20             	add    $0x20,%edx
     603:	8b 0c bd 00 00 00 00 	mov    0x0(,%edi,4),%ecx
     60a:	39 4e 14             	cmp    %ecx,0x14(%esi)
     60d:	74 16                	je     625 <schedule+0x1cb>
     60f:	66 89 54 24 0c       	mov    %dx,0xc(%esp)
     614:	87 4e 14             	xchg   %ecx,0x14(%esi)
     617:	ff 6c 24 08          	ljmp   *0x8(%esp)
     61b:	39 0d 00 00 00 00    	cmp    %ecx,0x0
     621:	75 02                	jne    625 <schedule+0x1cb>
     623:	0f 06                	clts   
     625:	eb 12                	jmp    639 <schedule+0x1df>
			}
		}
#endif
	}
	if (lock_flag) {
		unlock_op(&sched_semaphore);
     627:	83 ec 0c             	sub    $0xc,%esp
     62a:	68 00 00 00 00       	push   $0x0
     62f:	e8 fc ff ff ff       	call   630 <schedule+0x1d6>
     634:	83 c4 10             	add    $0x10,%esp
     637:	eb c2                	jmp    5fb <schedule+0x1a1>
		lock_flag = 0;
	}
	switch_to(next,current);
}
     639:	83 c4 1c             	add    $0x1c,%esp
     63c:	5b                   	pop    %ebx
     63d:	5e                   	pop    %esi
     63e:	5f                   	pop    %edi
     63f:	5d                   	pop    %ebp
     640:	c3                   	ret    

00000641 <sys_pause>:

int sys_pause(void)
{
     641:	83 ec 0c             	sub    $0xc,%esp
	struct task_struct* current = get_current_task();
     644:	e8 fc ff ff ff       	call   645 <sys_pause+0x4>
	current->state = TASK_INTERRUPTIBLE;
     649:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
	schedule();
     64f:	e8 fc ff ff ff       	call   650 <sys_pause+0xf>
	return 0;
}
     654:	b8 00 00 00 00       	mov    $0x0,%eax
     659:	83 c4 0c             	add    $0xc,%esp
     65c:	c3                   	ret    

0000065d <sleep_on>:
 * 每个进程调用该方法时,通过分配在栈上的tmp局部变量来串联所有等待任务的,这个链表本身也是个栈,先进后出,
 * 所以最后调用sleep_on方法的进程,会将自己的任务指针保存在inode.i_wait,当施加lock inode操作的进程释放lock,并调用wake_up方法后
 * 会唤醒inode.i_wait任务,该任务会唤醒它保存的上一个等待任务,以此类推,直到最后一个等待任务.
 * */
void sleep_on(struct task_struct **p)
{
     65d:	57                   	push   %edi
     65e:	56                   	push   %esi
     65f:	53                   	push   %ebx
     660:	8b 5c 24 10          	mov    0x10(%esp),%ebx
	lock_op(&sleep_on_semaphore);
     664:	68 00 00 00 00       	push   $0x0
     669:	e8 fc ff ff ff       	call   66a <sleep_on+0xd>

	struct task_struct* current = get_current_task();
     66e:	e8 fc ff ff ff       	call   66f <sleep_on+0x12>
	struct task_struct *tmp;

	if (!p) {
     673:	83 c4 04             	add    $0x4,%esp
     676:	85 db                	test   %ebx,%ebx
     678:	75 0f                	jne    689 <sleep_on+0x2c>
		unlock_op(&sleep_on_semaphore);
     67a:	68 00 00 00 00       	push   $0x0
     67f:	e8 fc ff ff ff       	call   680 <sleep_on+0x23>
		return;
     684:	83 c4 04             	add    $0x4,%esp
     687:	eb 42                	jmp    6cb <sleep_on+0x6e>
     689:	89 c6                	mov    %eax,%esi
	}
	if (current == &(init_task.task))
     68b:	3d 00 00 00 00       	cmp    $0x0,%eax
     690:	75 10                	jne    6a2 <sleep_on+0x45>
		panic("task[0] trying to sleep");
     692:	83 ec 0c             	sub    $0xc,%esp
     695:	68 35 00 00 00       	push   $0x35
     69a:	e8 fc ff ff ff       	call   69b <sleep_on+0x3e>
     69f:	83 c4 10             	add    $0x10,%esp
	tmp = *p;        /* 将目前inode.i_wait指向的等待任务的指针保存到tmp */
     6a2:	8b 3b                	mov    (%ebx),%edi
	*p = current;    /* 将当前任务的指针，保存到inode.i_wait */
     6a4:	89 33                	mov    %esi,(%ebx)
	current->state = TASK_UNINTERRUPTIBLE;  /* 将当前任务设置为不可中断的睡眠状态(必须通过wake_up唤醒，不能通过signal方式唤醒) */
     6a6:	c7 06 02 00 00 00    	movl   $0x2,(%esi)

	unlock_op(&sleep_on_semaphore);         /* 一定要在调度操作之前把锁释放了 */
     6ac:	83 ec 0c             	sub    $0xc,%esp
     6af:	68 00 00 00 00       	push   $0x0
     6b4:	e8 fc ff ff ff       	call   6b5 <sleep_on+0x58>

	schedule();      /* 这里肯定调度其他任务执行了，不可能再是本任务了 */
     6b9:	e8 fc ff ff ff       	call   6ba <sleep_on+0x5d>
	/*
	 * 这里最有意思了，每个等待任务用自己的局部变量tmp来保存前一个等待任务的指针，这样就形成了一个等待任务列表了。
	 * 当该任务被其他任务通过wake_up唤醒后，会紧接着执行下面的代码，把它自己维护的上一个等待任务的状态设置为running状态，
	 * 这样这个任务就被唤醒了，就有可能被下次schedule方法调度运行了，tricky吧，这里有必要解释一下。
	 * */
	if (tmp)
     6be:	83 c4 10             	add    $0x10,%esp
     6c1:	85 ff                	test   %edi,%edi
     6c3:	74 06                	je     6cb <sleep_on+0x6e>
		tmp->state=0;
     6c5:	c7 07 00 00 00 00    	movl   $0x0,(%edi)
}
     6cb:	5b                   	pop    %ebx
     6cc:	5e                   	pop    %esi
     6cd:	5f                   	pop    %edi
     6ce:	c3                   	ret    

000006cf <interruptible_sleep_on>:

void interruptible_sleep_on(struct task_struct **p)
{
     6cf:	57                   	push   %edi
     6d0:	56                   	push   %esi
     6d1:	53                   	push   %ebx
     6d2:	8b 74 24 10          	mov    0x10(%esp),%esi
	lock_op(&interruptible_sleep_on_semaphore);
     6d6:	68 00 00 00 00       	push   $0x0
     6db:	e8 fc ff ff ff       	call   6dc <interruptible_sleep_on+0xd>
	struct task_struct* current = get_current_task();
     6e0:	e8 fc ff ff ff       	call   6e1 <interruptible_sleep_on+0x12>
	struct task_struct *tmp;

	if (!p) {
     6e5:	83 c4 04             	add    $0x4,%esp
     6e8:	85 f6                	test   %esi,%esi
     6ea:	75 0f                	jne    6fb <interruptible_sleep_on+0x2c>
		unlock_op(&interruptible_sleep_on_semaphore);
     6ec:	68 00 00 00 00       	push   $0x0
     6f1:	e8 fc ff ff ff       	call   6f2 <interruptible_sleep_on+0x23>
		return;
     6f6:	83 c4 04             	add    $0x4,%esp
     6f9:	eb 56                	jmp    751 <interruptible_sleep_on+0x82>
     6fb:	89 c3                	mov    %eax,%ebx
	}
	if (current == &(init_task.task))
     6fd:	3d 00 00 00 00       	cmp    $0x0,%eax
     702:	75 10                	jne    714 <interruptible_sleep_on+0x45>
		panic("task[0] trying to sleep");
     704:	83 ec 0c             	sub    $0xc,%esp
     707:	68 35 00 00 00       	push   $0x35
     70c:	e8 fc ff ff ff       	call   70d <interruptible_sleep_on+0x3e>
     711:	83 c4 10             	add    $0x10,%esp
	tmp=*p;
     714:	8b 3e                	mov    (%esi),%edi
	*p=current;
     716:	89 1e                	mov    %ebx,(%esi)
    repeat:
    current->state = TASK_INTERRUPTIBLE;
     718:	c7 03 01 00 00 00    	movl   $0x1,(%ebx)
    unlock_op(&interruptible_sleep_on_semaphore);
     71e:	83 ec 0c             	sub    $0xc,%esp
     721:	68 00 00 00 00       	push   $0x0
     726:	e8 fc ff ff ff       	call   727 <interruptible_sleep_on+0x58>
	schedule();
     72b:	e8 fc ff ff ff       	call   72c <interruptible_sleep_on+0x5d>
	if (*p && *p != current) {
     730:	8b 06                	mov    (%esi),%eax
     732:	83 c4 10             	add    $0x10,%esp
     735:	39 c3                	cmp    %eax,%ebx
     737:	74 0c                	je     745 <interruptible_sleep_on+0x76>
     739:	85 c0                	test   %eax,%eax
     73b:	74 08                	je     745 <interruptible_sleep_on+0x76>
		(**p).state=0;
     73d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		goto repeat;
     743:	eb d3                	jmp    718 <interruptible_sleep_on+0x49>
	}
	//*p=NULL;
	*p=tmp;
     745:	89 3e                	mov    %edi,(%esi)
	if (tmp)
     747:	85 ff                	test   %edi,%edi
     749:	74 06                	je     751 <interruptible_sleep_on+0x82>
		tmp->state=0;
     74b:	c7 07 00 00 00 00    	movl   $0x0,(%edi)
}
     751:	5b                   	pop    %ebx
     752:	5e                   	pop    %esi
     753:	5f                   	pop    %edi
     754:	c3                   	ret    

00000755 <wake_up>:

void wake_up(struct task_struct **p)
{
     755:	8b 44 24 04          	mov    0x4(%esp),%eax
	if (p && *p) {
     759:	85 c0                	test   %eax,%eax
     75b:	74 0c                	je     769 <wake_up+0x14>
     75d:	8b 00                	mov    (%eax),%eax
     75f:	85 c0                	test   %eax,%eax
     761:	74 06                	je     769 <wake_up+0x14>
		(**p).state=0; /* 将等待任务的状态设置为running状态，这样就可以被schedule方法调度了. */
     763:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
     769:	f3 c3                	repz ret 

0000076b <ticks_to_floppy_on>:
static int  mon_timer[4]={0,0,0,0};
static int moff_timer[4]={0,0,0,0};
unsigned char current_DOR = 0x0C;

int ticks_to_floppy_on(unsigned int nr)
{
     76b:	56                   	push   %esi
     76c:	53                   	push   %ebx
     76d:	83 ec 04             	sub    $0x4,%esp
     770:	8b 74 24 10          	mov    0x10(%esp),%esi
	extern unsigned char selected;
	unsigned char mask = 0x10 << nr;
     774:	b8 10 00 00 00       	mov    $0x10,%eax
     779:	89 f1                	mov    %esi,%ecx
     77b:	d3 e0                	shl    %cl,%eax
     77d:	89 c3                	mov    %eax,%ebx

	if (nr>3)
     77f:	83 fe 03             	cmp    $0x3,%esi
     782:	76 10                	jbe    794 <ticks_to_floppy_on+0x29>
		panic("floppy_on: nr>3");
     784:	83 ec 0c             	sub    $0xc,%esp
     787:	68 4d 00 00 00       	push   $0x4d
     78c:	e8 fc ff ff ff       	call   78d <ticks_to_floppy_on+0x22>
     791:	83 c4 10             	add    $0x10,%esp
	moff_timer[nr]=10000;		/* 100 s = very big :-) */
     794:	c7 04 b5 20 03 00 00 	movl   $0x2710,0x320(,%esi,4)
     79b:	10 27 00 00 
	cli();				/* use floppy_off to turn it off */
     79f:	fa                   	cli    
	mask |= current_DOR;
     7a0:	0f b6 0d 00 00 00 00 	movzbl 0x0,%ecx
     7a7:	89 d8                	mov    %ebx,%eax
     7a9:	09 c8                	or     %ecx,%eax
	if (!selected) {
     7ab:	80 3d 00 00 00 00 00 	cmpb   $0x0,0x0
     7b2:	75 05                	jne    7b9 <ticks_to_floppy_on+0x4e>
		mask &= 0xFC;
     7b4:	83 e0 fc             	and    $0xfffffffc,%eax
		mask |= nr;
     7b7:	09 f0                	or     %esi,%eax
	}
	if (mask != current_DOR) {
     7b9:	38 c8                	cmp    %cl,%al
     7bb:	74 34                	je     7f1 <ticks_to_floppy_on+0x86>
		outb(mask,FD_DOR);
     7bd:	ba f2 03 00 00       	mov    $0x3f2,%edx
     7c2:	ee                   	out    %al,(%dx)
		if ((mask ^ current_DOR) & 0xf0)
     7c3:	31 c1                	xor    %eax,%ecx
     7c5:	f6 c1 f0             	test   $0xf0,%cl
     7c8:	74 0d                	je     7d7 <ticks_to_floppy_on+0x6c>
			mon_timer[nr] = HZ/2;
     7ca:	c7 04 b5 30 03 00 00 	movl   $0x5,0x330(,%esi,4)
     7d1:	05 00 00 00 
     7d5:	eb 15                	jmp    7ec <ticks_to_floppy_on+0x81>
		else if (mon_timer[nr] < 2)
     7d7:	83 3c b5 30 03 00 00 	cmpl   $0x1,0x330(,%esi,4)
     7de:	01 
     7df:	7f 0b                	jg     7ec <ticks_to_floppy_on+0x81>
			mon_timer[nr] = 2;
     7e1:	c7 04 b5 30 03 00 00 	movl   $0x2,0x330(,%esi,4)
     7e8:	02 00 00 00 
		current_DOR = mask;
     7ec:	a2 00 00 00 00       	mov    %al,0x0
	}
	sti();
     7f1:	fb                   	sti    
	return mon_timer[nr];
     7f2:	8b 04 b5 30 03 00 00 	mov    0x330(,%esi,4),%eax
}
     7f9:	83 c4 04             	add    $0x4,%esp
     7fc:	5b                   	pop    %ebx
     7fd:	5e                   	pop    %esi
     7fe:	c3                   	ret    

000007ff <floppy_on>:

void floppy_on(unsigned int nr)
{
     7ff:	56                   	push   %esi
     800:	53                   	push   %ebx
     801:	83 ec 04             	sub    $0x4,%esp
     804:	8b 5c 24 10          	mov    0x10(%esp),%ebx
	cli();
     808:	fa                   	cli    
	while (ticks_to_floppy_on(nr))
		sleep_on(nr+wait_motor);
     809:	8d 34 9d 40 03 00 00 	lea    0x340(,%ebx,4),%esi
}

void floppy_on(unsigned int nr)
{
	cli();
	while (ticks_to_floppy_on(nr))
     810:	eb 0c                	jmp    81e <floppy_on+0x1f>
		sleep_on(nr+wait_motor);
     812:	83 ec 0c             	sub    $0xc,%esp
     815:	56                   	push   %esi
     816:	e8 fc ff ff ff       	call   817 <floppy_on+0x18>
     81b:	83 c4 10             	add    $0x10,%esp
}

void floppy_on(unsigned int nr)
{
	cli();
	while (ticks_to_floppy_on(nr))
     81e:	83 ec 0c             	sub    $0xc,%esp
     821:	53                   	push   %ebx
     822:	e8 fc ff ff ff       	call   823 <floppy_on+0x24>
     827:	83 c4 10             	add    $0x10,%esp
     82a:	85 c0                	test   %eax,%eax
     82c:	75 e4                	jne    812 <floppy_on+0x13>
		sleep_on(nr+wait_motor);
	sti();
     82e:	fb                   	sti    
}
     82f:	83 c4 04             	add    $0x4,%esp
     832:	5b                   	pop    %ebx
     833:	5e                   	pop    %esi
     834:	c3                   	ret    

00000835 <floppy_off>:

void floppy_off(unsigned int nr)
{
	moff_timer[nr]=3*HZ;
     835:	8b 44 24 04          	mov    0x4(%esp),%eax
     839:	c7 04 85 20 03 00 00 	movl   $0x1e,0x320(,%eax,4)
     840:	1e 00 00 00 
     844:	c3                   	ret    

00000845 <do_floppy_timer>:
}

void do_floppy_timer(void)
{
     845:	57                   	push   %edi
     846:	56                   	push   %esi
     847:	53                   	push   %ebx
     848:	bb 00 00 00 00       	mov    $0x0,%ebx
	int i;
	unsigned char mask = 0x10;
     84d:	be 10 00 00 00       	mov    $0x10,%esi
		if (mon_timer[i]) {
			if (!--mon_timer[i])
				wake_up(i+wait_motor);
		} else if (!moff_timer[i]) {
			current_DOR &= ~mask;
			outb(current_DOR,FD_DOR);
     852:	bf f2 03 00 00       	mov    $0x3f2,%edi
{
	int i;
	unsigned char mask = 0x10;

	for (i=0 ; i<4 ; i++,mask <<= 1) {
		if (!(mask & current_DOR))
     857:	0f b6 05 00 00 00 00 	movzbl 0x0,%eax
     85e:	89 f1                	mov    %esi,%ecx
     860:	84 c8                	test   %cl,%al
     862:	74 4b                	je     8af <do_floppy_timer+0x6a>
			continue;
		if (mon_timer[i]) {
     864:	8b 93 30 03 00 00    	mov    0x330(%ebx),%edx
     86a:	85 d2                	test   %edx,%edx
     86c:	74 1e                	je     88c <do_floppy_timer+0x47>
			if (!--mon_timer[i])
     86e:	83 ea 01             	sub    $0x1,%edx
     871:	89 93 30 03 00 00    	mov    %edx,0x330(%ebx)
     877:	85 d2                	test   %edx,%edx
     879:	75 34                	jne    8af <do_floppy_timer+0x6a>
				wake_up(i+wait_motor);
     87b:	8d 83 40 03 00 00    	lea    0x340(%ebx),%eax
     881:	50                   	push   %eax
     882:	e8 fc ff ff ff       	call   883 <do_floppy_timer+0x3e>
     887:	83 c4 04             	add    $0x4,%esp
     88a:	eb 23                	jmp    8af <do_floppy_timer+0x6a>
		} else if (!moff_timer[i]) {
     88c:	8b 93 20 03 00 00    	mov    0x320(%ebx),%edx
     892:	85 d2                	test   %edx,%edx
     894:	75 10                	jne    8a6 <do_floppy_timer+0x61>
			current_DOR &= ~mask;
     896:	89 f2                	mov    %esi,%edx
     898:	f7 d2                	not    %edx
     89a:	21 d0                	and    %edx,%eax
     89c:	a2 00 00 00 00       	mov    %al,0x0
			outb(current_DOR,FD_DOR);
     8a1:	89 fa                	mov    %edi,%edx
     8a3:	ee                   	out    %al,(%dx)
     8a4:	eb 09                	jmp    8af <do_floppy_timer+0x6a>
		} else
			moff_timer[i]--;
     8a6:	83 ea 01             	sub    $0x1,%edx
     8a9:	89 93 20 03 00 00    	mov    %edx,0x320(%ebx)
void do_floppy_timer(void)
{
	int i;
	unsigned char mask = 0x10;

	for (i=0 ; i<4 ; i++,mask <<= 1) {
     8af:	01 f6                	add    %esi,%esi
     8b1:	83 c3 04             	add    $0x4,%ebx
     8b4:	83 fb 10             	cmp    $0x10,%ebx
     8b7:	75 9e                	jne    857 <do_floppy_timer+0x12>
			current_DOR &= ~mask;
			outb(current_DOR,FD_DOR);
		} else
			moff_timer[i]--;
	}
}
     8b9:	5b                   	pop    %ebx
     8ba:	5e                   	pop    %esi
     8bb:	5f                   	pop    %edi
     8bc:	c3                   	ret    

000008bd <add_timer>:
	void (*fn)();
	struct timer_list * next;
} timer_list[TIME_REQUESTS], * next_timer = NULL;

void add_timer(long jiffies, void (*fn)(void))
{
     8bd:	57                   	push   %edi
     8be:	56                   	push   %esi
     8bf:	53                   	push   %ebx
     8c0:	8b 74 24 10          	mov    0x10(%esp),%esi
     8c4:	8b 7c 24 14          	mov    0x14(%esp),%edi
	struct timer_list * p;

	if (!fn)
     8c8:	85 ff                	test   %edi,%edi
     8ca:	0f 84 99 00 00 00    	je     969 <add_timer+0xac>
		return;
	cli();
     8d0:	fa                   	cli    
	if (jiffies <= 0)
     8d1:	85 f6                	test   %esi,%esi
     8d3:	7e 14                	jle    8e9 <add_timer+0x2c>
		(fn)();
	else {
		for (p = timer_list ; p < timer_list + TIME_REQUESTS ; p++) {
			if (!p->fn)
     8d5:	83 3d 24 00 00 00 00 	cmpl   $0x0,0x24
     8dc:	0f 84 80 00 00 00    	je     962 <add_timer+0xa5>
     8e2:	bb 20 00 00 00       	mov    $0x20,%ebx
     8e7:	eb 0a                	jmp    8f3 <add_timer+0x36>

	if (!fn)
		return;
	cli();
	if (jiffies <= 0)
		(fn)();
     8e9:	ff d7                	call   *%edi
     8eb:	eb 60                	jmp    94d <add_timer+0x90>
	else {
		for (p = timer_list ; p < timer_list + TIME_REQUESTS ; p++) {
			if (!p->fn)
     8ed:	83 7b 04 00          	cmpl   $0x0,0x4(%ebx)
     8f1:	74 0d                	je     900 <add_timer+0x43>
		return;
	cli();
	if (jiffies <= 0)
		(fn)();
	else {
		for (p = timer_list ; p < timer_list + TIME_REQUESTS ; p++) {
     8f3:	83 c3 0c             	add    $0xc,%ebx
     8f6:	81 fb 20 03 00 00    	cmp    $0x320,%ebx
     8fc:	75 ef                	jne    8ed <add_timer+0x30>
     8fe:	eb 50                	jmp    950 <add_timer+0x93>
			if (!p->fn)
				break;
		}
		if (p >= timer_list + TIME_REQUESTS)
			panic("No more time requests free");
		p->fn = fn;
     900:	89 7b 04             	mov    %edi,0x4(%ebx)
		p->jiffies = jiffies;
     903:	89 33                	mov    %esi,(%ebx)
		p->next = next_timer;
     905:	8b 15 18 00 00 00    	mov    0x18,%edx
     90b:	89 53 08             	mov    %edx,0x8(%ebx)
		next_timer = p;
     90e:	89 1d 18 00 00 00    	mov    %ebx,0x18
		while (p->next && p->next->jiffies < p->jiffies) {
     914:	85 d2                	test   %edx,%edx
     916:	74 35                	je     94d <add_timer+0x90>
     918:	8b 0a                	mov    (%edx),%ecx
     91a:	39 ce                	cmp    %ecx,%esi
     91c:	7e 2f                	jle    94d <add_timer+0x90>
     91e:	89 f0                	mov    %esi,%eax
			p->jiffies -= p->next->jiffies;
     920:	29 c8                	sub    %ecx,%eax
     922:	89 03                	mov    %eax,(%ebx)
			fn = p->fn;
     924:	8b 43 04             	mov    0x4(%ebx),%eax
			p->fn = p->next->fn;
     927:	8b 4a 04             	mov    0x4(%edx),%ecx
     92a:	89 4b 04             	mov    %ecx,0x4(%ebx)
			p->next->fn = fn;
     92d:	89 42 04             	mov    %eax,0x4(%edx)
			jiffies = p->jiffies;
     930:	8b 13                	mov    (%ebx),%edx
			p->jiffies = p->next->jiffies;
     932:	8b 43 08             	mov    0x8(%ebx),%eax
     935:	8b 08                	mov    (%eax),%ecx
     937:	89 0b                	mov    %ecx,(%ebx)
			p->next->jiffies = jiffies;
     939:	89 10                	mov    %edx,(%eax)
			p = p->next;
     93b:	8b 5b 08             	mov    0x8(%ebx),%ebx
			panic("No more time requests free");
		p->fn = fn;
		p->jiffies = jiffies;
		p->next = next_timer;
		next_timer = p;
		while (p->next && p->next->jiffies < p->jiffies) {
     93e:	8b 53 08             	mov    0x8(%ebx),%edx
     941:	85 d2                	test   %edx,%edx
     943:	74 08                	je     94d <add_timer+0x90>
     945:	8b 0a                	mov    (%edx),%ecx
     947:	8b 03                	mov    (%ebx),%eax
     949:	39 c1                	cmp    %eax,%ecx
     94b:	7c d3                	jl     920 <add_timer+0x63>
			p->jiffies = p->next->jiffies;
			p->next->jiffies = jiffies;
			p = p->next;
		}
	}
	sti();
     94d:	fb                   	sti    
     94e:	eb 19                	jmp    969 <add_timer+0xac>
		for (p = timer_list ; p < timer_list + TIME_REQUESTS ; p++) {
			if (!p->fn)
				break;
		}
		if (p >= timer_list + TIME_REQUESTS)
			panic("No more time requests free");
     950:	83 ec 0c             	sub    $0xc,%esp
     953:	68 5d 00 00 00       	push   $0x5d
     958:	e8 fc ff ff ff       	call   959 <add_timer+0x9c>
     95d:	83 c4 10             	add    $0x10,%esp
     960:	eb 9e                	jmp    900 <add_timer+0x43>
	cli();
	if (jiffies <= 0)
		(fn)();
	else {
		for (p = timer_list ; p < timer_list + TIME_REQUESTS ; p++) {
			if (!p->fn)
     962:	bb 20 00 00 00       	mov    $0x20,%ebx
     967:	eb 97                	jmp    900 <add_timer+0x43>
			p->next->jiffies = jiffies;
			p = p->next;
		}
	}
	sti();
}
     969:	5b                   	pop    %ebx
     96a:	5e                   	pop    %esi
     96b:	5f                   	pop    %edi
     96c:	c3                   	ret    

0000096d <do_timer>:

void do_timer(long cpl)
{
     96d:	56                   	push   %esi
     96e:	53                   	push   %ebx
     96f:	83 ec 04             	sub    $0x4,%esp
     972:	8b 74 24 10          	mov    0x10(%esp),%esi
	if (get_current_apic_id() != 0) {
		//printk("ap execute do_timer\n\r");
	}
	struct task_struct* current = get_current_task();
     976:	e8 fc ff ff ff       	call   977 <do_timer+0xa>
     97b:	89 c3                	mov    %eax,%ebx
	extern int beepcount;
	extern void sysbeepstop(void);

	if (beepcount)
     97d:	a1 00 00 00 00       	mov    0x0,%eax
     982:	85 c0                	test   %eax,%eax
     984:	74 11                	je     997 <do_timer+0x2a>
		if (!--beepcount)
     986:	83 e8 01             	sub    $0x1,%eax
     989:	a3 00 00 00 00       	mov    %eax,0x0
     98e:	85 c0                	test   %eax,%eax
     990:	75 05                	jne    997 <do_timer+0x2a>
			sysbeepstop();
     992:	e8 fc ff ff ff       	call   993 <do_timer+0x26>

	if (cpl)
     997:	85 f6                	test   %esi,%esi
     999:	74 09                	je     9a4 <do_timer+0x37>
		current->utime++;
     99b:	83 83 50 02 00 00 01 	addl   $0x1,0x250(%ebx)
     9a2:	eb 07                	jmp    9ab <do_timer+0x3e>
	else
		current->stime++;
     9a4:	83 83 54 02 00 00 01 	addl   $0x1,0x254(%ebx)

	if (next_timer) {
     9ab:	a1 18 00 00 00       	mov    0x18,%eax
     9b0:	85 c0                	test   %eax,%eax
     9b2:	74 2d                	je     9e1 <do_timer+0x74>
		next_timer->jiffies--;
     9b4:	8b 08                	mov    (%eax),%ecx
     9b6:	8d 51 ff             	lea    -0x1(%ecx),%edx
     9b9:	89 10                	mov    %edx,(%eax)
		while (next_timer && next_timer->jiffies <= 0) {
     9bb:	85 d2                	test   %edx,%edx
     9bd:	7f 22                	jg     9e1 <do_timer+0x74>
			void (*fn)(void);
			
			fn = next_timer->fn;
     9bf:	8b 50 04             	mov    0x4(%eax),%edx
			next_timer->fn = NULL;
     9c2:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
			next_timer = next_timer->next;
     9c9:	8b 40 08             	mov    0x8(%eax),%eax
     9cc:	a3 18 00 00 00       	mov    %eax,0x18
			(fn)();
     9d1:	ff d2                	call   *%edx
	else
		current->stime++;

	if (next_timer) {
		next_timer->jiffies--;
		while (next_timer && next_timer->jiffies <= 0) {
     9d3:	a1 18 00 00 00       	mov    0x18,%eax
     9d8:	85 c0                	test   %eax,%eax
     9da:	74 05                	je     9e1 <do_timer+0x74>
     9dc:	83 38 00             	cmpl   $0x0,(%eax)
     9df:	7e de                	jle    9bf <do_timer+0x52>
			next_timer->fn = NULL;
			next_timer = next_timer->next;
			(fn)();
		}
	}
	if (current_DOR & 0xf0)
     9e1:	f6 05 00 00 00 00 f0 	testb  $0xf0,0x0
     9e8:	74 05                	je     9ef <do_timer+0x82>
		do_floppy_timer();
     9ea:	e8 fc ff ff ff       	call   9eb <do_timer+0x7e>
	if ((--current->counter)>0) return;
     9ef:	8b 43 04             	mov    0x4(%ebx),%eax
     9f2:	83 e8 01             	sub    $0x1,%eax
     9f5:	85 c0                	test   %eax,%eax
     9f7:	7e 05                	jle    9fe <do_timer+0x91>
     9f9:	89 43 04             	mov    %eax,0x4(%ebx)
     9fc:	eb 2b                	jmp    a29 <do_timer+0xbc>
	current->counter=0;
     9fe:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)

	/*
	 * 后面有时间的话,会将调度改成在内核态可以进行抢占式调度,不过难度很大,最大的问题就是同步依赖问题,很容易造成锁的死锁状态.
	 * 任务要根据优先级,时间片,锁的依赖关系(每个进程是否要维护一个锁依赖列表)等等,要考虑的因素太多了,当前任务就不展开了.
	 *  */
	if (get_current_apic_id() == 0) {
     a05:	e8 fc ff ff ff       	call   a06 <do_timer+0x99>
     a0a:	85 c0                	test   %eax,%eax
     a0c:	75 06                	jne    a14 <do_timer+0xa7>
		if (!cpl) return;  /* 这里可以看出内核态是不支持timer中断进行进程调度的，其他的外部中断除外 */
     a0e:	85 f6                	test   %esi,%esi
     a10:	75 12                	jne    a24 <do_timer+0xb7>
     a12:	eb 15                	jmp    a29 <do_timer+0xbc>
		 *    如果调度运行其他任务的话,其他任务的时间片如果>当前任务的话,那么当前任务就有可能不会被调度,但是它占用的锁如果被其它进程依赖的话,
		 *    那么这种情况就造成了死锁状态.
		 * 2. 如果AP上运行的是当前任务是ap_default_task,其肯定是运行在内核态,但是它只执行idl_loop操作,
		 *    因此不会占用锁,也就不会造成其它进程的锁依赖,所以可以在内核态进行进程的调度.
		 *    */
		if (get_current_task() != &ap_default_task.task) {
     a14:	e8 fc ff ff ff       	call   a15 <do_timer+0xa8>
			if (!cpl) return;
     a19:	85 f6                	test   %esi,%esi
     a1b:	75 07                	jne    a24 <do_timer+0xb7>
     a1d:	3d 00 00 00 00       	cmp    $0x0,%eax
     a22:	75 05                	jne    a29 <do_timer+0xbc>
		}
	}

	schedule();
     a24:	e8 fc ff ff ff       	call   a25 <do_timer+0xb8>
}
     a29:	83 c4 04             	add    $0x4,%esp
     a2c:	5b                   	pop    %ebx
     a2d:	5e                   	pop    %esi
     a2e:	c3                   	ret    

00000a2f <sched_init>:
	int i;
	struct desc_struct * p;

	if (sizeof(struct sigaction) != 16)
		panic("Struct sigaction MUST be 16 bytes");
	set_tss_desc(gdt+FIRST_TSS_ENTRY,&(init_task.task.tss));
     a2f:	b8 e8 02 00 00       	mov    $0x2e8,%eax
     a34:	66 c7 05 20 00 00 00 	movw   $0x68,0x20
     a3b:	68 00 
     a3d:	66 a3 22 00 00 00    	mov    %ax,0x22
     a43:	c1 c8 10             	ror    $0x10,%eax
     a46:	a2 24 00 00 00       	mov    %al,0x24
     a4b:	c6 05 25 00 00 00 89 	movb   $0x89,0x25
     a52:	c6 05 26 00 00 00 00 	movb   $0x0,0x26
     a59:	88 25 27 00 00 00    	mov    %ah,0x27
     a5f:	c1 c8 10             	ror    $0x10,%eax
	set_ldt_desc(gdt+FIRST_LDT_ENTRY,&(init_task.task.ldt));
     a62:	b8 d0 02 00 00       	mov    $0x2d0,%eax
     a67:	66 c7 05 28 00 00 00 	movw   $0x68,0x28
     a6e:	68 00 
     a70:	66 a3 2a 00 00 00    	mov    %ax,0x2a
     a76:	c1 c8 10             	ror    $0x10,%eax
     a79:	a2 2c 00 00 00       	mov    %al,0x2c
     a7e:	c6 05 2d 00 00 00 82 	movb   $0x82,0x2d
     a85:	c6 05 2e 00 00 00 00 	movb   $0x0,0x2e
     a8c:	88 25 2f 00 00 00    	mov    %ah,0x2f
     a92:	c1 c8 10             	ror    $0x10,%eax
     a95:	ba 04 00 00 00       	mov    $0x4,%edx
	p = gdt+2+FIRST_TSS_ENTRY;
     a9a:	b8 30 00 00 00       	mov    $0x30,%eax
	for(i=1;i<NR_TASKS;i++) {
		task[i] = NULL;
     a9f:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
		p->a=p->b=0;
     aa5:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
     aac:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		p++;
		p->a=p->b=0;
     ab2:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
     ab9:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
     ac0:	83 c0 10             	add    $0x10,%eax
     ac3:	83 c2 04             	add    $0x4,%edx
	if (sizeof(struct sigaction) != 16)
		panic("Struct sigaction MUST be 16 bytes");
	set_tss_desc(gdt+FIRST_TSS_ENTRY,&(init_task.task.tss));
	set_ldt_desc(gdt+FIRST_LDT_ENTRY,&(init_task.task.ldt));
	p = gdt+2+FIRST_TSS_ENTRY;
	for(i=1;i<NR_TASKS;i++) {
     ac6:	3d 20 04 00 00       	cmp    $0x420,%eax
     acb:	75 d2                	jne    a9f <sched_init+0x70>
		p++;
		p->a=p->b=0;
		p++;
	}
/* Clear NT, so that we won't have troubles with that later on */
	__asm__("pushfl ; andl $0xffffbfff,(%esp) ; popfl");
     acd:	9c                   	pushf  
     ace:	81 24 24 ff bf ff ff 	andl   $0xffffbfff,(%esp)
     ad5:	9d                   	popf   
	ltr(0);
     ad6:	b8 20 00 00 00       	mov    $0x20,%eax
     adb:	0f 00 d8             	ltr    %ax
	lldt(0);
     ade:	b8 28 00 00 00       	mov    $0x28,%eax
     ae3:	0f 00 d0             	lldt   %ax
	outb_p(LATCH & 0xff , 0x40);	/* LSB */
	outb(LATCH >> 8 , 0x40);	/* MSB */
	set_intr_gate(0x20,&timer_interrupt);
	outb(inb_p(0x21)&~0x01,0x21);   /* Not mask timer intr */
#else
	set_intr_gate(APIC_TIMER_INTR_NO,&timer_interrupt);  /* Vector value 0x83 for APIC timer */
     ae6:	b8 00 00 08 00       	mov    $0x80000,%eax
     aeb:	ba 00 00 00 00       	mov    $0x0,%edx
     af0:	66 89 d0             	mov    %dx,%ax
     af3:	66 ba 00 8e          	mov    $0x8e00,%dx
     af7:	a3 18 04 00 00       	mov    %eax,0x418
     afc:	89 15 1c 04 00 00    	mov    %edx,0x41c
#endif

	set_system_gate(0x80,&system_call);
     b02:	ba 00 00 00 00       	mov    $0x0,%edx
     b07:	66 89 d0             	mov    %dx,%ax
     b0a:	66 ba 00 ef          	mov    $0xef00,%dx
     b0e:	a3 00 04 00 00       	mov    %eax,0x400
     b13:	89 15 04 04 00 00    	mov    %edx,0x404
     b19:	c3                   	ret    
     b1a:	66 90                	xchg   %ax,%ax

00000b1c <bad_sys_call>:
     b1c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
     b21:	cf                   	iret   
     b22:	66 90                	xchg   %ax,%ax

00000b24 <reschedule>:
     b24:	68 64 0b 00 00       	push   $0xb64
     b29:	e9 fc ff ff ff       	jmp    b2a <reschedule+0x6>
     b2e:	66 90                	xchg   %ax,%ax

00000b30 <system_call>:
     b30:	83 f8 47             	cmp    $0x47,%eax
     b33:	77 e7                	ja     b1c <bad_sys_call>
     b35:	1e                   	push   %ds
     b36:	06                   	push   %es
     b37:	0f a0                	push   %fs
     b39:	52                   	push   %edx
     b3a:	51                   	push   %ecx
     b3b:	53                   	push   %ebx
     b3c:	ba 10 00 00 00       	mov    $0x10,%edx
     b41:	8e da                	mov    %edx,%ds
     b43:	8e c2                	mov    %edx,%es
     b45:	ba 17 00 00 00       	mov    $0x17,%edx
     b4a:	8e e2                	mov    %edx,%fs
     b4c:	ff 14 85 00 00 00 00 	call   *0x0(,%eax,4)
     b53:	50                   	push   %eax
     b54:	e8 fc ff ff ff       	call   b55 <system_call+0x25>
     b59:	83 38 00             	cmpl   $0x0,(%eax)
     b5c:	75 c6                	jne    b24 <reschedule>
     b5e:	83 78 04 00          	cmpl   $0x0,0x4(%eax)
     b62:	74 c0                	je     b24 <reschedule>

00000b64 <ret_from_sys_call>:
     b64:	e8 fc ff ff ff       	call   b65 <ret_from_sys_call+0x1>
     b69:	3b 05 00 00 00 00    	cmp    0x0,%eax
     b6f:	74 30                	je     ba1 <ret_from_sys_call+0x3d>
     b71:	66 83 7c 24 20 0f    	cmpw   $0xf,0x20(%esp)
     b77:	75 28                	jne    ba1 <ret_from_sys_call+0x3d>
     b79:	66 83 7c 24 2c 17    	cmpw   $0x17,0x2c(%esp)
     b7f:	75 20                	jne    ba1 <ret_from_sys_call+0x3d>
     b81:	8b 58 0c             	mov    0xc(%eax),%ebx
     b84:	8b 88 10 02 00 00    	mov    0x210(%eax),%ecx
     b8a:	f7 d1                	not    %ecx
     b8c:	21 d9                	and    %ebx,%ecx
     b8e:	0f bc c9             	bsf    %ecx,%ecx
     b91:	74 0e                	je     ba1 <ret_from_sys_call+0x3d>
     b93:	0f b3 cb             	btr    %ecx,%ebx
     b96:	89 58 0c             	mov    %ebx,0xc(%eax)
     b99:	41                   	inc    %ecx
     b9a:	51                   	push   %ecx
     b9b:	e8 fc ff ff ff       	call   b9c <ret_from_sys_call+0x38>
     ba0:	58                   	pop    %eax
     ba1:	58                   	pop    %eax
     ba2:	5b                   	pop    %ebx
     ba3:	59                   	pop    %ecx
     ba4:	5a                   	pop    %edx
     ba5:	0f a1                	pop    %fs
     ba7:	07                   	pop    %es
     ba8:	1f                   	pop    %ds
     ba9:	cf                   	iret   
     baa:	66 90                	xchg   %ax,%ax

00000bac <coprocessor_error>:
     bac:	1e                   	push   %ds
     bad:	06                   	push   %es
     bae:	0f a0                	push   %fs
     bb0:	52                   	push   %edx
     bb1:	51                   	push   %ecx
     bb2:	53                   	push   %ebx
     bb3:	50                   	push   %eax
     bb4:	b8 10 00 00 00       	mov    $0x10,%eax
     bb9:	8e d8                	mov    %eax,%ds
     bbb:	8e c0                	mov    %eax,%es
     bbd:	b8 17 00 00 00       	mov    $0x17,%eax
     bc2:	8e e0                	mov    %eax,%fs
     bc4:	68 64 0b 00 00       	push   $0xb64
     bc9:	e9 fc ff ff ff       	jmp    bca <coprocessor_error+0x1e>
     bce:	66 90                	xchg   %ax,%ax

00000bd0 <device_not_available>:
     bd0:	1e                   	push   %ds
     bd1:	06                   	push   %es
     bd2:	0f a0                	push   %fs
     bd4:	52                   	push   %edx
     bd5:	51                   	push   %ecx
     bd6:	53                   	push   %ebx
     bd7:	50                   	push   %eax
     bd8:	b8 10 00 00 00       	mov    $0x10,%eax
     bdd:	8e d8                	mov    %eax,%ds
     bdf:	8e c0                	mov    %eax,%es
     be1:	b8 17 00 00 00       	mov    $0x17,%eax
     be6:	8e e0                	mov    %eax,%fs
     be8:	68 64 0b 00 00       	push   $0xb64
     bed:	0f 06                	clts   
     bef:	0f 20 c0             	mov    %cr0,%eax
     bf2:	a9 04 00 00 00       	test   $0x4,%eax
     bf7:	0f 84 fc ff ff ff    	je     bf9 <device_not_available+0x29>
     bfd:	55                   	push   %ebp
     bfe:	56                   	push   %esi
     bff:	57                   	push   %edi
     c00:	e8 fc ff ff ff       	call   c01 <device_not_available+0x31>
     c05:	5f                   	pop    %edi
     c06:	5e                   	pop    %esi
     c07:	5d                   	pop    %ebp
     c08:	c3                   	ret    
     c09:	8d 76 00             	lea    0x0(%esi),%esi

00000c0c <timer_interrupt>:
     c0c:	1e                   	push   %ds
     c0d:	06                   	push   %es
     c0e:	0f a0                	push   %fs
     c10:	52                   	push   %edx
     c11:	51                   	push   %ecx
     c12:	53                   	push   %ebx
     c13:	50                   	push   %eax
     c14:	ba 10 00 00 00       	mov    $0x10,%edx
     c19:	8e da                	mov    %edx,%ds
     c1b:	8e c2                	mov    %edx,%es
     c1d:	e8 fc ff ff ff       	call   c1e <timer_interrupt+0x12>
     c22:	83 f8 00             	cmp    $0x0,%eax
     c25:	75 07                	jne    c2e <timer_interrupt+0x22>
     c27:	ba 17 00 00 00       	mov    $0x17,%edx
     c2c:	eb 05                	jmp    c33 <timer_interrupt+0x27>
     c2e:	ba 10 00 00 00       	mov    $0x10,%edx
     c33:	8e e2                	mov    %edx,%fs
     c35:	ff 05 00 00 00 00    	incl   0x0
     c3b:	e8 fc ff ff ff       	call   c3c <timer_interrupt+0x30>
     c40:	8b 44 24 20          	mov    0x20(%esp),%eax
     c44:	83 e0 03             	and    $0x3,%eax
     c47:	50                   	push   %eax
     c48:	e8 fc ff ff ff       	call   c49 <timer_interrupt+0x3d>
     c4d:	83 c4 04             	add    $0x4,%esp
     c50:	e9 0f ff ff ff       	jmp    b64 <ret_from_sys_call>
     c55:	8d 76 00             	lea    0x0(%esi),%esi

00000c58 <sys_execve>:
     c58:	8d 44 24 1c          	lea    0x1c(%esp),%eax
     c5c:	50                   	push   %eax
     c5d:	e8 fc ff ff ff       	call   c5e <sys_execve+0x6>
     c62:	83 c4 04             	add    $0x4,%esp
     c65:	c3                   	ret    
     c66:	66 90                	xchg   %ax,%ax

00000c68 <sys_fork>:
     c68:	e8 fc ff ff ff       	call   c69 <sys_fork+0x1>
     c6d:	85 c0                	test   %eax,%eax
     c6f:	78 0e                	js     c7f <sys_fork+0x17>
     c71:	0f a8                	push   %gs
     c73:	56                   	push   %esi
     c74:	57                   	push   %edi
     c75:	55                   	push   %ebp
     c76:	50                   	push   %eax
     c77:	e8 fc ff ff ff       	call   c78 <sys_fork+0x10>
     c7c:	83 c4 14             	add    $0x14,%esp
     c7f:	c3                   	ret    

00000c80 <hd_interrupt>:
     c80:	50                   	push   %eax
     c81:	51                   	push   %ecx
     c82:	52                   	push   %edx
     c83:	1e                   	push   %ds
     c84:	06                   	push   %es
     c85:	0f a0                	push   %fs
     c87:	b8 10 00 00 00       	mov    $0x10,%eax
     c8c:	8e d8                	mov    %eax,%ds
     c8e:	8e c0                	mov    %eax,%es
     c90:	b8 17 00 00 00       	mov    $0x17,%eax
     c95:	8e e0                	mov    %eax,%fs
     c97:	b0 20                	mov    $0x20,%al
     c99:	e6 a0                	out    %al,$0xa0
     c9b:	eb 00                	jmp    c9d <hd_interrupt+0x1d>
     c9d:	eb 00                	jmp    c9f <hd_interrupt+0x1f>
     c9f:	31 d2                	xor    %edx,%edx
     ca1:	87 15 00 00 00 00    	xchg   %edx,0x0
     ca7:	85 d2                	test   %edx,%edx
     ca9:	75 05                	jne    cb0 <hd_interrupt+0x30>
     cab:	ba 00 00 00 00       	mov    $0x0,%edx
     cb0:	e6 20                	out    %al,$0x20
     cb2:	ff d2                	call   *%edx
     cb4:	0f a1                	pop    %fs
     cb6:	07                   	pop    %es
     cb7:	1f                   	pop    %ds
     cb8:	5a                   	pop    %edx
     cb9:	59                   	pop    %ecx
     cba:	58                   	pop    %eax
     cbb:	cf                   	iret   

00000cbc <floppy_interrupt>:
     cbc:	50                   	push   %eax
     cbd:	51                   	push   %ecx
     cbe:	52                   	push   %edx
     cbf:	1e                   	push   %ds
     cc0:	06                   	push   %es
     cc1:	0f a0                	push   %fs
     cc3:	b8 10 00 00 00       	mov    $0x10,%eax
     cc8:	8e d8                	mov    %eax,%ds
     cca:	8e c0                	mov    %eax,%es
     ccc:	b8 17 00 00 00       	mov    $0x17,%eax
     cd1:	8e e0                	mov    %eax,%fs
     cd3:	b0 20                	mov    $0x20,%al
     cd5:	e6 20                	out    %al,$0x20
     cd7:	31 c0                	xor    %eax,%eax
     cd9:	87 05 00 00 00 00    	xchg   %eax,0x0
     cdf:	85 c0                	test   %eax,%eax
     ce1:	75 05                	jne    ce8 <floppy_interrupt+0x2c>
     ce3:	b8 00 00 00 00       	mov    $0x0,%eax
     ce8:	ff d0                	call   *%eax
     cea:	0f a1                	pop    %fs
     cec:	07                   	pop    %es
     ced:	1f                   	pop    %ds
     cee:	5a                   	pop    %edx
     cef:	59                   	pop    %ecx
     cf0:	58                   	pop    %eax
     cf1:	cf                   	iret   

00000cf2 <parallel_interrupt>:
     cf2:	50                   	push   %eax
     cf3:	b0 20                	mov    $0x20,%al
     cf5:	e6 20                	out    %al,$0x20
     cf7:	58                   	pop    %eax
     cf8:	cf                   	iret   

00000cf9 <parse_cpu_topology>:
     cf9:	50                   	push   %eax
     cfa:	53                   	push   %ebx
     cfb:	51                   	push   %ecx
     cfc:	52                   	push   %edx
     cfd:	b8 01 00 00 00       	mov    $0x1,%eax
     d02:	0f a2                	cpuid  
     d04:	5a                   	pop    %edx
     d05:	59                   	pop    %ecx
     d06:	5b                   	pop    %ebx
     d07:	58                   	pop    %eax
     d08:	cf                   	iret   

00000d09 <handle_ipi_interrupt>:
     d09:	50                   	push   %eax
     d0a:	53                   	push   %ebx
     d0b:	51                   	push   %ecx
     d0c:	52                   	push   %edx
     d0d:	e8 fc ff ff ff       	call   d0e <handle_ipi_interrupt+0x5>
     d12:	e8 fc ff ff ff       	call   d13 <handle_ipi_interrupt+0xa>
     d17:	5a                   	pop    %edx
     d18:	59                   	pop    %ecx
     d19:	5b                   	pop    %ebx
     d1a:	58                   	pop    %eax
     d1b:	cf                   	iret   

00000d1c <die>:
void parallel_interrupt(void);
void handle_ipi_interrupt(void);
void irq13(void);

static void die(char * str,long esp_ptr,long nr)
{
     d1c:	55                   	push   %ebp
     d1d:	57                   	push   %edi
     d1e:	56                   	push   %esi
     d1f:	53                   	push   %ebx
     d20:	83 ec 1c             	sub    $0x1c,%esp
     d23:	89 44 24 08          	mov    %eax,0x8(%esp)
     d27:	89 d6                	mov    %edx,%esi
     d29:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
	struct task_struct* current = get_current_task();
     d2d:	e8 fc ff ff ff       	call   d2e <die+0x12>
     d32:	89 c5                	mov    %eax,%ebp
	long * esp = (long *) esp_ptr;
     d34:	89 f3                	mov    %esi,%ebx
	int i;
    printk("die at apic_id: %d, nr: %d, pid: %d, task_addr: %p\n\r", get_current_apic_id(), current->task_nr, current->pid, current);
     d36:	8b b8 2c 02 00 00    	mov    0x22c(%eax),%edi
     d3c:	89 7c 24 04          	mov    %edi,0x4(%esp)
     d40:	8b b8 c0 03 00 00    	mov    0x3c0(%eax),%edi
     d46:	e8 fc ff ff ff       	call   d47 <die+0x2b>
     d4b:	83 ec 0c             	sub    $0xc,%esp
     d4e:	55                   	push   %ebp
     d4f:	ff 74 24 14          	pushl  0x14(%esp)
     d53:	57                   	push   %edi
     d54:	50                   	push   %eax
     d55:	68 28 00 00 00       	push   $0x28
     d5a:	e8 fc ff ff ff       	call   d5b <die+0x3f>
	printk("%s: %04x\n\r",str,nr&0xffff);
     d5f:	83 c4 1c             	add    $0x1c,%esp
     d62:	0f b7 44 24 10       	movzwl 0x10(%esp),%eax
     d67:	50                   	push   %eax
     d68:	ff 74 24 10          	pushl  0x10(%esp)
     d6c:	68 78 00 00 00       	push   $0x78
     d71:	e8 fc ff ff ff       	call   d72 <die+0x56>
	printk("EIP:\t%04x:%p\nEFLAGS:\t%p\nESP:\t%04x:%p\n",
     d76:	83 c4 08             	add    $0x8,%esp
     d79:	ff 76 0c             	pushl  0xc(%esi)
     d7c:	ff 76 10             	pushl  0x10(%esi)
     d7f:	ff 76 08             	pushl  0x8(%esi)
     d82:	ff 36                	pushl  (%esi)
     d84:	ff 76 04             	pushl  0x4(%esi)
     d87:	68 60 00 00 00       	push   $0x60
     d8c:	e8 fc ff ff ff       	call   d8d <die+0x71>
		esp[1],esp[0],esp[2],esp[4],esp[3]);
	printk("fs: %04x\n",_fs());
     d91:	66 8c e0             	mov    %fs,%ax
     d94:	83 c4 18             	add    $0x18,%esp
     d97:	0f b7 c0             	movzwl %ax,%eax
     d9a:	50                   	push   %eax
     d9b:	68 83 00 00 00       	push   $0x83
     da0:	e8 fc ff ff ff       	call   da1 <die+0x85>
	printk("base: %p, limit: %p\n",get_base(current->ldt[1]),get_limit(0x17));
     da5:	b9 17 00 00 00       	mov    $0x17,%ecx
     daa:	0f 03 c9             	lsl    %cx,%ecx
     dad:	41                   	inc    %ecx
     dae:	50                   	push   %eax
     daf:	8d 85 d8 02 00 00    	lea    0x2d8(%ebp),%eax
     db5:	83 c0 07             	add    $0x7,%eax
     db8:	8a 30                	mov    (%eax),%dh
     dba:	83 e8 03             	sub    $0x3,%eax
     dbd:	8a 10                	mov    (%eax),%dl
     dbf:	c1 e2 10             	shl    $0x10,%edx
     dc2:	83 e8 02             	sub    $0x2,%eax
     dc5:	66 8b 10             	mov    (%eax),%dx
     dc8:	58                   	pop    %eax
     dc9:	83 c4 0c             	add    $0xc,%esp
     dcc:	51                   	push   %ecx
     dcd:	52                   	push   %edx
     dce:	68 8d 00 00 00       	push   $0x8d
     dd3:	e8 fc ff ff ff       	call   dd4 <die+0xb8>
	if (esp[4] == 0x17) {
     dd8:	83 c4 10             	add    $0x10,%esp
     ddb:	83 7e 10 17          	cmpl   $0x17,0x10(%esi)
     ddf:	75 52                	jne    e33 <die+0x117>
		printk("Stack: ");
     de1:	83 ec 0c             	sub    $0xc,%esp
     de4:	68 a2 00 00 00       	push   $0xa2
     de9:	e8 fc ff ff ff       	call   dea <die+0xce>
     dee:	83 c4 10             	add    $0x10,%esp
     df1:	be 00 00 00 00       	mov    $0x0,%esi
		for (i=0;i<4;i++)
			printk("%p ",get_seg_long(0x17,i+(long *)esp[3]));
     df6:	bf 17 00 00 00       	mov    $0x17,%edi
     dfb:	8b 53 0c             	mov    0xc(%ebx),%edx
     dfe:	89 f8                	mov    %edi,%eax
     e00:	0f a0                	push   %fs
     e02:	8e e0                	mov    %eax,%fs
     e04:	64 8b 04 32          	mov    %fs:(%edx,%esi,1),%eax
     e08:	0f a1                	pop    %fs
     e0a:	83 ec 08             	sub    $0x8,%esp
     e0d:	50                   	push   %eax
     e0e:	68 aa 00 00 00       	push   $0xaa
     e13:	e8 fc ff ff ff       	call   e14 <die+0xf8>
     e18:	83 c6 04             	add    $0x4,%esi
		esp[1],esp[0],esp[2],esp[4],esp[3]);
	printk("fs: %04x\n",_fs());
	printk("base: %p, limit: %p\n",get_base(current->ldt[1]),get_limit(0x17));
	if (esp[4] == 0x17) {
		printk("Stack: ");
		for (i=0;i<4;i++)
     e1b:	83 c4 10             	add    $0x10,%esp
     e1e:	83 fe 10             	cmp    $0x10,%esi
     e21:	75 d8                	jne    dfb <die+0xdf>
			printk("%p ",get_seg_long(0x17,i+(long *)esp[3]));
		printk("\n");
     e23:	83 ec 0c             	sub    $0xc,%esp
     e26:	68 ae 00 00 00       	push   $0xae
     e2b:	e8 fc ff ff ff       	call   e2c <die+0x110>
     e30:	83 c4 10             	add    $0x10,%esp
	}
	str(i);
     e33:	b8 00 00 00 00       	mov    $0x0,%eax
     e38:	66 0f 00 c8          	str    %ax
     e3c:	83 e8 20             	sub    $0x20,%eax
     e3f:	c1 e8 04             	shr    $0x4,%eax
	printk("Pid: %d, process nr: %d\n\r",current->pid,0xffff & i);
     e42:	83 ec 04             	sub    $0x4,%esp
     e45:	0f b7 c0             	movzwl %ax,%eax
     e48:	50                   	push   %eax
     e49:	ff b5 2c 02 00 00    	pushl  0x22c(%ebp)
     e4f:	68 b0 00 00 00       	push   $0xb0
     e54:	e8 fc ff ff ff       	call   e55 <die+0x139>
     e59:	83 c4 10             	add    $0x10,%esp
	for(i=0;i<10;i++)
     e5c:	be 00 00 00 00       	mov    $0x0,%esi
		printk("%02x ",0xff & get_seg_byte(esp[1],(i+(char *)esp[0])));
     e61:	8b 43 04             	mov    0x4(%ebx),%eax
     e64:	8b 13                	mov    (%ebx),%edx
     e66:	0f a0                	push   %fs
     e68:	8e e0                	mov    %eax,%fs
     e6a:	64 8a 04 32          	mov    %fs:(%edx,%esi,1),%al
     e6e:	0f a1                	pop    %fs
     e70:	83 ec 08             	sub    $0x8,%esp
     e73:	0f b6 c0             	movzbl %al,%eax
     e76:	50                   	push   %eax
     e77:	68 ca 00 00 00       	push   $0xca
     e7c:	e8 fc ff ff ff       	call   e7d <die+0x161>
			printk("%p ",get_seg_long(0x17,i+(long *)esp[3]));
		printk("\n");
	}
	str(i);
	printk("Pid: %d, process nr: %d\n\r",current->pid,0xffff & i);
	for(i=0;i<10;i++)
     e81:	83 c6 01             	add    $0x1,%esi
     e84:	83 c4 10             	add    $0x10,%esp
     e87:	83 fe 0a             	cmp    $0xa,%esi
     e8a:	75 d5                	jne    e61 <die+0x145>
		printk("%02x ",0xff & get_seg_byte(esp[1],(i+(char *)esp[0])));
	printk("\n\r");
     e8c:	83 ec 0c             	sub    $0xc,%esp
     e8f:	68 d0 00 00 00       	push   $0xd0
     e94:	e8 fc ff ff ff       	call   e95 <die+0x179>
	panic("First general protection exception. \n\r");
     e99:	c7 04 24 88 00 00 00 	movl   $0x88,(%esp)
     ea0:	e8 fc ff ff ff       	call   ea1 <die+0x185>
	do_exit(11);		/* play segment exception */
     ea5:	c7 04 24 0b 00 00 00 	movl   $0xb,(%esp)
     eac:	e8 fc ff ff ff       	call   ead <die+0x191>
}
     eb1:	83 c4 2c             	add    $0x2c,%esp
     eb4:	5b                   	pop    %ebx
     eb5:	5e                   	pop    %esi
     eb6:	5f                   	pop    %edi
     eb7:	5d                   	pop    %ebp
     eb8:	c3                   	ret    

00000eb9 <do_double_fault>:

void do_double_fault(long esp, long error_code)
{
     eb9:	83 ec 0c             	sub    $0xc,%esp
	die("double fault",esp,error_code);
     ebc:	8b 4c 24 14          	mov    0x14(%esp),%ecx
     ec0:	8b 54 24 10          	mov    0x10(%esp),%edx
     ec4:	b8 d3 00 00 00       	mov    $0xd3,%eax
     ec9:	e8 4e fe ff ff       	call   d1c <die>
}
     ece:	83 c4 0c             	add    $0xc,%esp
     ed1:	c3                   	ret    

00000ed2 <do_general_protection>:

void do_general_protection(long esp, long error_code)
{
     ed2:	83 ec 0c             	sub    $0xc,%esp
	die("general protection",esp,error_code);
     ed5:	8b 4c 24 14          	mov    0x14(%esp),%ecx
     ed9:	8b 54 24 10          	mov    0x10(%esp),%edx
     edd:	b8 e0 00 00 00       	mov    $0xe0,%eax
     ee2:	e8 35 fe ff ff       	call   d1c <die>
}
     ee7:	83 c4 0c             	add    $0xc,%esp
     eea:	c3                   	ret    

00000eeb <do_divide_error>:

void do_divide_error(long esp, long error_code)
{
     eeb:	83 ec 0c             	sub    $0xc,%esp
	die("divide_error",esp,error_code);
     eee:	8b 4c 24 14          	mov    0x14(%esp),%ecx
     ef2:	8b 54 24 10          	mov    0x10(%esp),%edx
     ef6:	b8 f3 00 00 00       	mov    $0xf3,%eax
     efb:	e8 1c fe ff ff       	call   d1c <die>
}
     f00:	83 c4 0c             	add    $0xc,%esp
     f03:	c3                   	ret    

00000f04 <do_int3>:

void do_int3(long * esp, long error_code,
		long fs,long es,long ds,
		long ebp,long esi,long edi,
		long edx,long ecx,long ebx,long eax)
{
     f04:	56                   	push   %esi
     f05:	53                   	push   %ebx
     f06:	83 ec 10             	sub    $0x10,%esp
     f09:	8b 5c 24 1c          	mov    0x1c(%esp),%ebx
	int tr;

	__asm__("str %%ax":"=a" (tr):"0" (0));
     f0d:	be 00 00 00 00       	mov    $0x0,%esi
     f12:	89 f0                	mov    %esi,%eax
     f14:	66 0f 00 c8          	str    %ax
     f18:	89 c6                	mov    %eax,%esi
	printk("eax\t\tebx\t\tecx\t\tedx\n\r%8x\t%8x\t%8x\t%8x\n\r",
     f1a:	ff 74 24 3c          	pushl  0x3c(%esp)
     f1e:	ff 74 24 44          	pushl  0x44(%esp)
     f22:	ff 74 24 4c          	pushl  0x4c(%esp)
     f26:	ff 74 24 54          	pushl  0x54(%esp)
     f2a:	68 b0 00 00 00       	push   $0xb0
     f2f:	e8 fc ff ff ff       	call   f30 <do_int3+0x2c>
		eax,ebx,ecx,edx);
	printk("esi\t\tedi\t\tebp\t\tesp\n\r%8x\t%8x\t%8x\t%8x\n\r",
     f34:	83 c4 14             	add    $0x14,%esp
     f37:	53                   	push   %ebx
     f38:	ff 74 24 34          	pushl  0x34(%esp)
     f3c:	ff 74 24 40          	pushl  0x40(%esp)
     f40:	ff 74 24 40          	pushl  0x40(%esp)
     f44:	68 d8 00 00 00       	push   $0xd8
     f49:	e8 fc ff ff ff       	call   f4a <do_int3+0x46>
		esi,edi,ebp,(long) esp);
	printk("\n\rds\tes\tfs\ttr\n\r%4x\t%4x\t%4x\t%4x\n\r",
     f4e:	83 c4 14             	add    $0x14,%esp
     f51:	56                   	push   %esi
     f52:	ff 74 24 28          	pushl  0x28(%esp)
     f56:	ff 74 24 30          	pushl  0x30(%esp)
     f5a:	ff 74 24 38          	pushl  0x38(%esp)
     f5e:	68 00 01 00 00       	push   $0x100
     f63:	e8 fc ff ff ff       	call   f64 <do_int3+0x60>
		ds,es,fs,tr);
	printk("EIP: %8x   CS: %4x  EFLAGS: %8x\n\r",esp[0],esp[1],esp[2]);
     f68:	83 c4 20             	add    $0x20,%esp
     f6b:	ff 73 08             	pushl  0x8(%ebx)
     f6e:	ff 73 04             	pushl  0x4(%ebx)
     f71:	ff 33                	pushl  (%ebx)
     f73:	68 24 01 00 00       	push   $0x124
     f78:	e8 fc ff ff ff       	call   f79 <do_int3+0x75>
}
     f7d:	83 c4 14             	add    $0x14,%esp
     f80:	5b                   	pop    %ebx
     f81:	5e                   	pop    %esi
     f82:	c3                   	ret    

00000f83 <do_nmi>:

void do_nmi(long esp, long error_code)
{
     f83:	83 ec 0c             	sub    $0xc,%esp
	die("nmi",esp,error_code);
     f86:	8b 4c 24 14          	mov    0x14(%esp),%ecx
     f8a:	8b 54 24 10          	mov    0x10(%esp),%edx
     f8e:	b8 00 01 00 00       	mov    $0x100,%eax
     f93:	e8 84 fd ff ff       	call   d1c <die>
}
     f98:	83 c4 0c             	add    $0xc,%esp
     f9b:	c3                   	ret    

00000f9c <do_debug>:

void do_debug(long esp, long error_code)
{
     f9c:	83 ec 0c             	sub    $0xc,%esp
	die("debug",esp,error_code);
     f9f:	8b 4c 24 14          	mov    0x14(%esp),%ecx
     fa3:	8b 54 24 10          	mov    0x10(%esp),%edx
     fa7:	b8 04 01 00 00       	mov    $0x104,%eax
     fac:	e8 6b fd ff ff       	call   d1c <die>
}
     fb1:	83 c4 0c             	add    $0xc,%esp
     fb4:	c3                   	ret    

00000fb5 <do_overflow>:

void do_overflow(long esp, long error_code)
{
     fb5:	83 ec 0c             	sub    $0xc,%esp
	die("overflow",esp,error_code);
     fb8:	8b 4c 24 14          	mov    0x14(%esp),%ecx
     fbc:	8b 54 24 10          	mov    0x10(%esp),%edx
     fc0:	b8 0a 01 00 00       	mov    $0x10a,%eax
     fc5:	e8 52 fd ff ff       	call   d1c <die>
}
     fca:	83 c4 0c             	add    $0xc,%esp
     fcd:	c3                   	ret    

00000fce <do_bounds>:

void do_bounds(long esp, long error_code)
{
     fce:	83 ec 0c             	sub    $0xc,%esp
	die("bounds",esp,error_code);
     fd1:	8b 4c 24 14          	mov    0x14(%esp),%ecx
     fd5:	8b 54 24 10          	mov    0x10(%esp),%edx
     fd9:	b8 13 01 00 00       	mov    $0x113,%eax
     fde:	e8 39 fd ff ff       	call   d1c <die>
}
     fe3:	83 c4 0c             	add    $0xc,%esp
     fe6:	c3                   	ret    

00000fe7 <do_invalid_op>:

void do_invalid_op(long esp, long error_code)
{
     fe7:	83 ec 0c             	sub    $0xc,%esp
	die("invalid operand",esp,error_code);
     fea:	8b 4c 24 14          	mov    0x14(%esp),%ecx
     fee:	8b 54 24 10          	mov    0x10(%esp),%edx
     ff2:	b8 1a 01 00 00       	mov    $0x11a,%eax
     ff7:	e8 20 fd ff ff       	call   d1c <die>
}
     ffc:	83 c4 0c             	add    $0xc,%esp
     fff:	c3                   	ret    

00001000 <do_device_not_available>:

void do_device_not_available(long esp, long error_code)
{
    1000:	83 ec 0c             	sub    $0xc,%esp
	die("device not available",esp,error_code);
    1003:	8b 4c 24 14          	mov    0x14(%esp),%ecx
    1007:	8b 54 24 10          	mov    0x10(%esp),%edx
    100b:	b8 2a 01 00 00       	mov    $0x12a,%eax
    1010:	e8 07 fd ff ff       	call   d1c <die>
}
    1015:	83 c4 0c             	add    $0xc,%esp
    1018:	c3                   	ret    

00001019 <do_coprocessor_segment_overrun>:

void do_coprocessor_segment_overrun(long esp, long error_code)
{
    1019:	83 ec 0c             	sub    $0xc,%esp
	die("coprocessor segment overrun",esp,error_code);
    101c:	8b 4c 24 14          	mov    0x14(%esp),%ecx
    1020:	8b 54 24 10          	mov    0x10(%esp),%edx
    1024:	b8 3f 01 00 00       	mov    $0x13f,%eax
    1029:	e8 ee fc ff ff       	call   d1c <die>
}
    102e:	83 c4 0c             	add    $0xc,%esp
    1031:	c3                   	ret    

00001032 <do_invalid_TSS>:

void do_invalid_TSS(long esp,long error_code)
{
    1032:	83 ec 0c             	sub    $0xc,%esp
	die("invalid TSS",esp,error_code);
    1035:	8b 4c 24 14          	mov    0x14(%esp),%ecx
    1039:	8b 54 24 10          	mov    0x10(%esp),%edx
    103d:	b8 5b 01 00 00       	mov    $0x15b,%eax
    1042:	e8 d5 fc ff ff       	call   d1c <die>
}
    1047:	83 c4 0c             	add    $0xc,%esp
    104a:	c3                   	ret    

0000104b <do_segment_not_present>:

void do_segment_not_present(long esp,long error_code)
{
    104b:	83 ec 0c             	sub    $0xc,%esp
	die("segment not present",esp,error_code);
    104e:	8b 4c 24 14          	mov    0x14(%esp),%ecx
    1052:	8b 54 24 10          	mov    0x10(%esp),%edx
    1056:	b8 67 01 00 00       	mov    $0x167,%eax
    105b:	e8 bc fc ff ff       	call   d1c <die>
}
    1060:	83 c4 0c             	add    $0xc,%esp
    1063:	c3                   	ret    

00001064 <do_stack_segment>:

void do_stack_segment(long esp,long error_code)
{
    1064:	83 ec 0c             	sub    $0xc,%esp
	die("stack segment",esp,error_code);
    1067:	8b 4c 24 14          	mov    0x14(%esp),%ecx
    106b:	8b 54 24 10          	mov    0x10(%esp),%edx
    106f:	b8 7b 01 00 00       	mov    $0x17b,%eax
    1074:	e8 a3 fc ff ff       	call   d1c <die>
}
    1079:	83 c4 0c             	add    $0xc,%esp
    107c:	c3                   	ret    

0000107d <do_coprocessor_error>:

void do_coprocessor_error(long esp, long error_code)
{
    107d:	83 ec 0c             	sub    $0xc,%esp
	if (last_task_used_math != get_current_task())
    1080:	e8 fc ff ff ff       	call   1081 <do_coprocessor_error+0x4>
    1085:	39 05 00 00 00 00    	cmp    %eax,0x0
    108b:	75 12                	jne    109f <do_coprocessor_error+0x22>
		return;
	die("coprocessor error",esp,error_code);
    108d:	8b 4c 24 14          	mov    0x14(%esp),%ecx
    1091:	8b 54 24 10          	mov    0x10(%esp),%edx
    1095:	b8 89 01 00 00       	mov    $0x189,%eax
    109a:	e8 7d fc ff ff       	call   d1c <die>
}
    109f:	83 c4 0c             	add    $0xc,%esp
    10a2:	c3                   	ret    

000010a3 <do_reserved>:

void do_reserved(long esp, long error_code)
{
    10a3:	83 ec 0c             	sub    $0xc,%esp
	die("reserved (15,17-47) error",esp,error_code);
    10a6:	8b 4c 24 14          	mov    0x14(%esp),%ecx
    10aa:	8b 54 24 10          	mov    0x10(%esp),%edx
    10ae:	b8 9b 01 00 00       	mov    $0x19b,%eax
    10b3:	e8 64 fc ff ff       	call   d1c <die>
}
    10b8:	83 c4 0c             	add    $0xc,%esp
    10bb:	c3                   	ret    

000010bc <trap_init>:

void trap_init(void)
{
    10bc:	53                   	push   %ebx
	int i;

	set_trap_gate(0,&divide_error);
    10bd:	b8 00 00 08 00       	mov    $0x80000,%eax
    10c2:	ba 00 00 00 00       	mov    $0x0,%edx
    10c7:	66 89 d0             	mov    %dx,%ax
    10ca:	66 ba 00 8f          	mov    $0x8f00,%dx
    10ce:	a3 00 00 00 00       	mov    %eax,0x0
    10d3:	89 15 04 00 00 00    	mov    %edx,0x4
	set_trap_gate(1,&debug);
    10d9:	ba 00 00 00 00       	mov    $0x0,%edx
    10de:	66 89 d0             	mov    %dx,%ax
    10e1:	66 ba 00 8f          	mov    $0x8f00,%dx
    10e5:	a3 08 00 00 00       	mov    %eax,0x8
    10ea:	89 15 0c 00 00 00    	mov    %edx,0xc
	set_trap_gate(2,&nmi);
    10f0:	ba 00 00 00 00       	mov    $0x0,%edx
    10f5:	66 89 d0             	mov    %dx,%ax
    10f8:	66 ba 00 8f          	mov    $0x8f00,%dx
    10fc:	a3 10 00 00 00       	mov    %eax,0x10
    1101:	89 15 14 00 00 00    	mov    %edx,0x14
	set_system_gate(3,&int3);	/* int3-5 can be called from all */
    1107:	ba 00 00 00 00       	mov    $0x0,%edx
    110c:	66 89 d0             	mov    %dx,%ax
    110f:	66 ba 00 ef          	mov    $0xef00,%dx
    1113:	a3 18 00 00 00       	mov    %eax,0x18
    1118:	89 15 1c 00 00 00    	mov    %edx,0x1c
	set_system_gate(4,&overflow);
    111e:	ba 00 00 00 00       	mov    $0x0,%edx
    1123:	66 89 d0             	mov    %dx,%ax
    1126:	66 ba 00 ef          	mov    $0xef00,%dx
    112a:	a3 20 00 00 00       	mov    %eax,0x20
    112f:	89 15 24 00 00 00    	mov    %edx,0x24
	set_system_gate(5,&bounds);
    1135:	ba 00 00 00 00       	mov    $0x0,%edx
    113a:	66 89 d0             	mov    %dx,%ax
    113d:	66 ba 00 ef          	mov    $0xef00,%dx
    1141:	a3 28 00 00 00       	mov    %eax,0x28
    1146:	89 15 2c 00 00 00    	mov    %edx,0x2c
	set_trap_gate(6,&invalid_op);
    114c:	ba 00 00 00 00       	mov    $0x0,%edx
    1151:	66 89 d0             	mov    %dx,%ax
    1154:	66 ba 00 8f          	mov    $0x8f00,%dx
    1158:	a3 30 00 00 00       	mov    %eax,0x30
    115d:	89 15 34 00 00 00    	mov    %edx,0x34
	set_trap_gate(7,&device_not_available);
    1163:	ba 00 00 00 00       	mov    $0x0,%edx
    1168:	66 89 d0             	mov    %dx,%ax
    116b:	66 ba 00 8f          	mov    $0x8f00,%dx
    116f:	a3 38 00 00 00       	mov    %eax,0x38
    1174:	89 15 3c 00 00 00    	mov    %edx,0x3c
	set_trap_gate(8,&double_fault);
    117a:	ba 00 00 00 00       	mov    $0x0,%edx
    117f:	66 89 d0             	mov    %dx,%ax
    1182:	66 ba 00 8f          	mov    $0x8f00,%dx
    1186:	a3 40 00 00 00       	mov    %eax,0x40
    118b:	89 15 44 00 00 00    	mov    %edx,0x44
	set_trap_gate(9,&coprocessor_segment_overrun);
    1191:	ba 00 00 00 00       	mov    $0x0,%edx
    1196:	66 89 d0             	mov    %dx,%ax
    1199:	66 ba 00 8f          	mov    $0x8f00,%dx
    119d:	a3 48 00 00 00       	mov    %eax,0x48
    11a2:	89 15 4c 00 00 00    	mov    %edx,0x4c
	set_trap_gate(10,&invalid_TSS);
    11a8:	ba 00 00 00 00       	mov    $0x0,%edx
    11ad:	66 89 d0             	mov    %dx,%ax
    11b0:	66 ba 00 8f          	mov    $0x8f00,%dx
    11b4:	a3 50 00 00 00       	mov    %eax,0x50
    11b9:	89 15 54 00 00 00    	mov    %edx,0x54
	set_trap_gate(11,&segment_not_present);
    11bf:	ba 00 00 00 00       	mov    $0x0,%edx
    11c4:	66 89 d0             	mov    %dx,%ax
    11c7:	66 ba 00 8f          	mov    $0x8f00,%dx
    11cb:	a3 58 00 00 00       	mov    %eax,0x58
    11d0:	89 15 5c 00 00 00    	mov    %edx,0x5c
	set_trap_gate(12,&stack_segment);
    11d6:	ba 00 00 00 00       	mov    $0x0,%edx
    11db:	66 89 d0             	mov    %dx,%ax
    11de:	66 ba 00 8f          	mov    $0x8f00,%dx
    11e2:	a3 60 00 00 00       	mov    %eax,0x60
    11e7:	89 15 64 00 00 00    	mov    %edx,0x64
	set_trap_gate(13,&general_protection);
    11ed:	ba 00 00 00 00       	mov    $0x0,%edx
    11f2:	66 89 d0             	mov    %dx,%ax
    11f5:	66 ba 00 8f          	mov    $0x8f00,%dx
    11f9:	a3 68 00 00 00       	mov    %eax,0x68
    11fe:	89 15 6c 00 00 00    	mov    %edx,0x6c
	set_trap_gate(14,&page_fault);
    1204:	ba 00 00 00 00       	mov    $0x0,%edx
    1209:	66 89 d0             	mov    %dx,%ax
    120c:	66 ba 00 8f          	mov    $0x8f00,%dx
    1210:	a3 70 00 00 00       	mov    %eax,0x70
    1215:	89 15 74 00 00 00    	mov    %edx,0x74
	set_trap_gate(15,&reserved);
    121b:	ba 00 00 00 00       	mov    $0x0,%edx
    1220:	66 89 d0             	mov    %dx,%ax
    1223:	66 ba 00 8f          	mov    $0x8f00,%dx
    1227:	a3 78 00 00 00       	mov    %eax,0x78
    122c:	89 15 7c 00 00 00    	mov    %edx,0x7c
	set_trap_gate(16,&coprocessor_error);
    1232:	ba 00 00 00 00       	mov    $0x0,%edx
    1237:	66 89 d0             	mov    %dx,%ax
    123a:	66 ba 00 8f          	mov    $0x8f00,%dx
    123e:	a3 80 00 00 00       	mov    %eax,0x80
    1243:	89 15 84 00 00 00    	mov    %edx,0x84
    1249:	b9 88 00 00 00       	mov    $0x88,%ecx
    124e:	bb 80 01 00 00       	mov    $0x180,%ebx
	for (i=17;i<48;i++)
		set_trap_gate(i,&reserved);
    1253:	ba 00 00 00 00       	mov    $0x0,%edx
    1258:	66 89 d0             	mov    %dx,%ax
    125b:	66 ba 00 8f          	mov    $0x8f00,%dx
    125f:	89 01                	mov    %eax,(%ecx)
    1261:	89 51 04             	mov    %edx,0x4(%ecx)
    1264:	83 c1 08             	add    $0x8,%ecx
	set_trap_gate(12,&stack_segment);
	set_trap_gate(13,&general_protection);
	set_trap_gate(14,&page_fault);
	set_trap_gate(15,&reserved);
	set_trap_gate(16,&coprocessor_error);
	for (i=17;i<48;i++)
    1267:	39 d9                	cmp    %ebx,%ecx
    1269:	75 ed                	jne    1258 <trap_init+0x19c>
		set_trap_gate(i,&reserved);
	set_trap_gate(45,&irq13);
    126b:	b8 00 00 08 00       	mov    $0x80000,%eax
    1270:	ba 00 00 00 00       	mov    $0x0,%edx
    1275:	66 89 d0             	mov    %dx,%ax
    1278:	66 ba 00 8f          	mov    $0x8f00,%dx
    127c:	a3 68 01 00 00       	mov    %eax,0x168
    1281:	89 15 6c 01 00 00    	mov    %edx,0x16c
	outb_p(inb_p(0x21)&0xfb,0x21);
    1287:	ba 21 00 00 00       	mov    $0x21,%edx
    128c:	ec                   	in     (%dx),%al
    128d:	eb 00                	jmp    128f <trap_init+0x1d3>
    128f:	eb 00                	jmp    1291 <trap_init+0x1d5>
    1291:	25 fb 00 00 00       	and    $0xfb,%eax
    1296:	ee                   	out    %al,(%dx)
    1297:	eb 00                	jmp    1299 <trap_init+0x1dd>
    1299:	eb 00                	jmp    129b <trap_init+0x1df>
	outb(inb_p(0xA1)&0xdf,0xA1);
    129b:	ba a1 00 00 00       	mov    $0xa1,%edx
    12a0:	ec                   	in     (%dx),%al
    12a1:	eb 00                	jmp    12a3 <trap_init+0x1e7>
    12a3:	eb 00                	jmp    12a5 <trap_init+0x1e9>
    12a5:	25 df 00 00 00       	and    $0xdf,%eax
    12aa:	ee                   	out    %al,(%dx)
	set_trap_gate(39,&parallel_interrupt);
    12ab:	b8 00 00 08 00       	mov    $0x80000,%eax
    12b0:	ba 00 00 00 00       	mov    $0x0,%edx
    12b5:	66 89 d0             	mov    %dx,%ax
    12b8:	66 ba 00 8f          	mov    $0x8f00,%dx
    12bc:	a3 38 01 00 00       	mov    %eax,0x138
    12c1:	89 15 3c 01 00 00    	mov    %edx,0x13c
}
    12c7:	5b                   	pop    %ebx
    12c8:	c3                   	ret    

000012c9 <ipi_intr_init>:

void parse_cpu_topology(void);
void handle_ipi_interrupt(void);
void ipi_intr_init(void)
{
	set_intr_gate(0x81,&parse_cpu_topology); /* 解析CPU的拓扑结构，例如有几个core，每个core是否支持HT */
    12c9:	b8 00 00 08 00       	mov    $0x80000,%eax
    12ce:	ba 00 00 00 00       	mov    $0x0,%edx
    12d3:	66 89 d0             	mov    %dx,%ax
    12d6:	66 ba 00 8e          	mov    $0x8e00,%dx
    12da:	a3 08 04 00 00       	mov    %eax,0x408
    12df:	89 15 0c 04 00 00    	mov    %edx,0x40c
	set_intr_gate(0x82,&handle_ipi_interrupt);
    12e5:	ba 00 00 00 00       	mov    $0x0,%edx
    12ea:	66 89 d0             	mov    %dx,%ax
    12ed:	66 ba 00 8e          	mov    $0x8e00,%dx
    12f1:	a3 10 04 00 00       	mov    %eax,0x410
    12f6:	89 15 14 04 00 00    	mov    %edx,0x414
    12fc:	c3                   	ret    

000012fd <divide_error>:
    12fd:	68 00 00 00 00       	push   $0x0

00001302 <no_error_code>:
    1302:	87 04 24             	xchg   %eax,(%esp)
    1305:	53                   	push   %ebx
    1306:	51                   	push   %ecx
    1307:	52                   	push   %edx
    1308:	57                   	push   %edi
    1309:	56                   	push   %esi
    130a:	55                   	push   %ebp
    130b:	1e                   	push   %ds
    130c:	06                   	push   %es
    130d:	0f a0                	push   %fs
    130f:	6a 00                	push   $0x0
    1311:	8d 54 24 2c          	lea    0x2c(%esp),%edx
    1315:	52                   	push   %edx
    1316:	ba 10 00 00 00       	mov    $0x10,%edx
    131b:	8e da                	mov    %edx,%ds
    131d:	8e c2                	mov    %edx,%es
    131f:	8e e2                	mov    %edx,%fs
    1321:	ff d0                	call   *%eax
    1323:	83 c4 08             	add    $0x8,%esp
    1326:	0f a1                	pop    %fs
    1328:	07                   	pop    %es
    1329:	1f                   	pop    %ds
    132a:	5d                   	pop    %ebp
    132b:	5e                   	pop    %esi
    132c:	5f                   	pop    %edi
    132d:	5a                   	pop    %edx
    132e:	59                   	pop    %ecx
    132f:	5b                   	pop    %ebx
    1330:	58                   	pop    %eax
    1331:	cf                   	iret   

00001332 <debug>:
    1332:	68 00 00 00 00       	push   $0x0
    1337:	eb c9                	jmp    1302 <no_error_code>

00001339 <nmi>:
    1339:	68 00 00 00 00       	push   $0x0
    133e:	eb c2                	jmp    1302 <no_error_code>

00001340 <int3>:
    1340:	68 00 00 00 00       	push   $0x0
    1345:	eb bb                	jmp    1302 <no_error_code>

00001347 <overflow>:
    1347:	68 00 00 00 00       	push   $0x0
    134c:	eb b4                	jmp    1302 <no_error_code>

0000134e <bounds>:
    134e:	68 00 00 00 00       	push   $0x0
    1353:	eb ad                	jmp    1302 <no_error_code>

00001355 <invalid_op>:
    1355:	68 00 00 00 00       	push   $0x0
    135a:	eb a6                	jmp    1302 <no_error_code>

0000135c <coprocessor_segment_overrun>:
    135c:	68 00 00 00 00       	push   $0x0
    1361:	eb 9f                	jmp    1302 <no_error_code>

00001363 <reserved>:
    1363:	68 00 00 00 00       	push   $0x0
    1368:	eb 98                	jmp    1302 <no_error_code>

0000136a <irq13>:
    136a:	50                   	push   %eax
    136b:	30 c0                	xor    %al,%al
    136d:	e6 f0                	out    %al,$0xf0
    136f:	b0 20                	mov    $0x20,%al
    1371:	e6 20                	out    %al,$0x20
    1373:	eb 00                	jmp    1375 <irq13+0xb>
    1375:	eb 00                	jmp    1377 <irq13+0xd>
    1377:	e6 a0                	out    %al,$0xa0
    1379:	58                   	pop    %eax
    137a:	e9 fc ff ff ff       	jmp    137b <irq13+0x11>

0000137f <double_fault>:
    137f:	68 00 00 00 00       	push   $0x0

00001384 <error_code>:
    1384:	87 44 24 04          	xchg   %eax,0x4(%esp)
    1388:	87 1c 24             	xchg   %ebx,(%esp)
    138b:	51                   	push   %ecx
    138c:	52                   	push   %edx
    138d:	57                   	push   %edi
    138e:	56                   	push   %esi
    138f:	55                   	push   %ebp
    1390:	1e                   	push   %ds
    1391:	06                   	push   %es
    1392:	0f a0                	push   %fs
    1394:	50                   	push   %eax
    1395:	8d 44 24 2c          	lea    0x2c(%esp),%eax
    1399:	50                   	push   %eax
    139a:	b8 10 00 00 00       	mov    $0x10,%eax
    139f:	8e d8                	mov    %eax,%ds
    13a1:	8e c0                	mov    %eax,%es
    13a3:	8e e0                	mov    %eax,%fs
    13a5:	ff d3                	call   *%ebx
    13a7:	83 c4 08             	add    $0x8,%esp
    13aa:	0f a1                	pop    %fs
    13ac:	07                   	pop    %es
    13ad:	1f                   	pop    %ds
    13ae:	5d                   	pop    %ebp
    13af:	5e                   	pop    %esi
    13b0:	5f                   	pop    %edi
    13b1:	5a                   	pop    %edx
    13b2:	59                   	pop    %ecx
    13b3:	5b                   	pop    %ebx
    13b4:	58                   	pop    %eax
    13b5:	cf                   	iret   

000013b6 <invalid_TSS>:
    13b6:	68 00 00 00 00       	push   $0x0
    13bb:	eb c7                	jmp    1384 <error_code>

000013bd <segment_not_present>:
    13bd:	68 00 00 00 00       	push   $0x0
    13c2:	eb c0                	jmp    1384 <error_code>

000013c4 <stack_segment>:
    13c4:	68 00 00 00 00       	push   $0x0
    13c9:	eb b9                	jmp    1384 <error_code>

000013cb <general_protection>:
    13cb:	68 00 00 00 00       	push   $0x0
    13d0:	eb b2                	jmp    1384 <error_code>

000013d2 <verify_area>:


extern void write_verify(unsigned long address);
long last_pid = 0;

void verify_area(void * addr, int size) {
    13d2:	56                   	push   %esi
    13d3:	53                   	push   %ebx
    13d4:	83 ec 04             	sub    $0x4,%esp
    13d7:	8b 5c 24 10          	mov    0x10(%esp),%ebx
	struct task_struct* current = get_current_task();
    13db:	e8 fc ff ff ff       	call   13dc <verify_area+0xa>
	unsigned long start;

	start = (unsigned long) addr;
	size += start & 0xfff;               /* 计算该地址的页内offset */
    13e0:	89 d9                	mov    %ebx,%ecx
    13e2:	81 e1 ff 0f 00 00    	and    $0xfff,%ecx
    13e8:	03 4c 24 14          	add    0x14(%esp),%ecx
	start &= 0xfffff000;                 /* 计算该地址在进程地址空间内的页帧号，其实也是个offset，4K align */
    13ec:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	start += get_base(current->ldt[2]);  /* 页帧号+进程地址空间base=CPU线性地址, 4k align */
    13f2:	50                   	push   %eax
    13f3:	05 e0 02 00 00       	add    $0x2e0,%eax
    13f8:	83 c0 07             	add    $0x7,%eax
    13fb:	8a 30                	mov    (%eax),%dh
    13fd:	83 e8 03             	sub    $0x3,%eax
    1400:	8a 10                	mov    (%eax),%dl
    1402:	c1 e2 10             	shl    $0x10,%edx
    1405:	83 e8 02             	sub    $0x2,%eax
    1408:	66 8b 10             	mov    (%eax),%dx
    140b:	58                   	pop    %eax
    140c:	01 d3                	add    %edx,%ebx
	while (size > 0) {
    140e:	85 c9                	test   %ecx,%ecx
    1410:	7e 26                	jle    1438 <verify_area+0x66>
    1412:	83 e9 01             	sub    $0x1,%ecx
    1415:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
    141b:	8d b4 0b 00 10 00 00 	lea    0x1000(%ebx,%ecx,1),%esi
		size -= 4096;
		write_verify(start);
    1422:	83 ec 0c             	sub    $0xc,%esp
    1425:	53                   	push   %ebx
    1426:	e8 fc ff ff ff       	call   1427 <verify_area+0x55>
		start += 4096;                   /* 跳到下一页继续verify了 */
    142b:	81 c3 00 10 00 00    	add    $0x1000,%ebx

	start = (unsigned long) addr;
	size += start & 0xfff;               /* 计算该地址的页内offset */
	start &= 0xfffff000;                 /* 计算该地址在进程地址空间内的页帧号，其实也是个offset，4K align */
	start += get_base(current->ldt[2]);  /* 页帧号+进程地址空间base=CPU线性地址, 4k align */
	while (size > 0) {
    1431:	83 c4 10             	add    $0x10,%esp
    1434:	39 f3                	cmp    %esi,%ebx
    1436:	75 ea                	jne    1422 <verify_area+0x50>
		size -= 4096;
		write_verify(start);
		start += 4096;                   /* 跳到下一页继续verify了 */
	}
}
    1438:	83 c4 04             	add    $0x4,%esp
    143b:	5b                   	pop    %ebx
    143c:	5e                   	pop    %esi
    143d:	c3                   	ret    

0000143e <copy_mem>:

int copy_mem(int nr, struct task_struct * p) {
    143e:	53                   	push   %ebx
    143f:	83 ec 08             	sub    $0x8,%esp
    1442:	8b 5c 24 14          	mov    0x14(%esp),%ebx

	/* 所有fork出来的进程的基地址和limit都是一样，所以到这你应该理解当所有进程都有相同的4G地址空间的时候，在GDT表中只需要一个LDT描述符即可，但进程的TSS还是每个进程私有的。 */
	new_data_base = new_code_base = USER_LINEAR_ADDR_START;
	code_limit = data_limit = USER_LINEAR_ADDR_LIMIT;

	p->start_code = new_code_base;
    1446:	c7 83 18 02 00 00 00 	movl   $0x40000000,0x218(%ebx)
    144d:	00 00 40 
	set_base(p->ldt[1], new_code_base);
    1450:	ba 00 00 00 40       	mov    $0x40000000,%edx
    1455:	66 89 93 da 02 00 00 	mov    %dx,0x2da(%ebx)
    145c:	c1 ca 10             	ror    $0x10,%edx
    145f:	88 93 dc 02 00 00    	mov    %dl,0x2dc(%ebx)
    1465:	88 b3 df 02 00 00    	mov    %dh,0x2df(%ebx)
    146b:	c1 ca 10             	ror    $0x10,%edx
	set_base(p->ldt[2], new_data_base);
    146e:	66 89 93 e2 02 00 00 	mov    %dx,0x2e2(%ebx)
    1475:	c1 ca 10             	ror    $0x10,%edx
    1478:	88 93 e4 02 00 00    	mov    %dl,0x2e4(%ebx)
    147e:	88 b3 e7 02 00 00    	mov    %dh,0x2e7(%ebx)
    1484:	c1 ca 10             	ror    $0x10,%edx
	set_limit(p->ldt[1], data_limit);
    1487:	ba ff ff 0b 00       	mov    $0xbffff,%edx
    148c:	66 89 93 d8 02 00 00 	mov    %dx,0x2d8(%ebx)
    1493:	c1 ca 10             	ror    $0x10,%edx
    1496:	8a b3 de 02 00 00    	mov    0x2de(%ebx),%dh
    149c:	80 e6 f0             	and    $0xf0,%dh
    149f:	08 f2                	or     %dh,%dl
    14a1:	88 93 de 02 00 00    	mov    %dl,0x2de(%ebx)
    14a7:	c1 ca 10             	ror    $0x10,%edx
	set_limit(p->ldt[2], data_limit);
    14aa:	66 89 93 e0 02 00 00 	mov    %dx,0x2e0(%ebx)
    14b1:	c1 ca 10             	ror    $0x10,%edx
    14b4:	8a b3 e6 02 00 00    	mov    0x2e6(%ebx),%dh
    14ba:	80 e6 f0             	and    $0xf0,%dh
    14bd:	08 f2                	or     %dh,%dl
    14bf:	88 93 e6 02 00 00    	mov    %dl,0x2e6(%ebx)
    14c5:	c1 ca 10             	ror    $0x10,%edx
	if (copy_page_tables(old_data_base, new_data_base, data_limit, p)) {
    14c8:	53                   	push   %ebx
    14c9:	68 00 00 00 c0       	push   $0xc0000000
    14ce:	68 00 00 00 40       	push   $0x40000000
    14d3:	6a 00                	push   $0x0
    14d5:	e8 fc ff ff ff       	call   14d6 <copy_mem+0x98>
    14da:	83 c4 10             	add    $0x10,%esp
    14dd:	85 c0                	test   %eax,%eax
    14df:	74 1b                	je     14fc <copy_mem+0xbe>
		//printk("copy_mem call free_page_tables before\n\r");
		free_page_tables(new_data_base, data_limit,p);
    14e1:	83 ec 04             	sub    $0x4,%esp
    14e4:	53                   	push   %ebx
    14e5:	68 00 00 00 c0       	push   $0xc0000000
    14ea:	68 00 00 00 40       	push   $0x40000000
    14ef:	e8 fc ff ff ff       	call   14f0 <copy_mem+0xb2>
		//printk("copy_mem call free_page_tables after\n\r");
		return -ENOMEM;
    14f4:	83 c4 10             	add    $0x10,%esp
    14f7:	b8 f4 ff ff ff       	mov    $0xfffffff4,%eax
	}
	return 0;
}
    14fc:	83 c4 08             	add    $0x8,%esp
    14ff:	5b                   	pop    %ebx
    1500:	c3                   	ret    

00001501 <copy_process>:
 * also copies the data segment in it's entirety.
 */
unsigned long copy_process_semaphore = 0;
int copy_process(int nr, long ebp, long edi, long esi, long gs, long none,
		long ebx, long ecx, long edx, long fs, long es, long ds, long eip,
		long cs, long eflags, long esp, long ss) {
    1501:	55                   	push   %ebp
    1502:	57                   	push   %edi
    1503:	56                   	push   %esi
    1504:	53                   	push   %ebx
    1505:	83 ec 1c             	sub    $0x1c,%esp

	struct task_struct* current = get_current_task();
    1508:	e8 fc ff ff ff       	call   1509 <copy_process+0x8>
    150d:	89 c5                	mov    %eax,%ebp
	struct task_struct *p = task[nr];
    150f:	8b 44 24 30          	mov    0x30(%esp),%eax
    1513:	8b 1c 85 00 00 00 00 	mov    0x0(,%eax,4),%ebx
	int i;
	struct file *f;
    /* 此版本将进程的task_struct和目录表都分配在内核实地址寻址的空间(mem>512M && mem<(512-64)M) */
	if (!p)
    151a:	85 db                	test   %ebx,%ebx
    151c:	0f 84 01 03 00 00    	je     1823 <copy_process+0x322>
		return -EAGAIN;
	long pid = p->pid;   /* 现将新分配的PID保存起来 */
    1522:	8b 83 2c 02 00 00    	mov    0x22c(%ebx),%eax
    1528:	89 44 24 0c          	mov    %eax,0xc(%esp)

	lock_op(&sched_semaphore);
    152c:	83 ec 0c             	sub    $0xc,%esp
    152f:	68 00 00 00 00       	push   $0x0
    1534:	e8 fc ff ff ff       	call   1535 <copy_process+0x34>
	/*
	 * 这也是个巨坑啊
	 * 这里一定要在copy操作之前先获得schedule的锁,这样确保在COPY老任务的时候,如果将新任务的state设置为running时,也不会被调度.
	 *  */
	*p = *current; /* NOTE! this doesn't copy the supervisor stack */
    1539:	b9 f2 00 00 00       	mov    $0xf2,%ecx
    153e:	89 df                	mov    %ebx,%edi
    1540:	89 ee                	mov    %ebp,%esi
    1542:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	p->state = TASK_UNINTERRUPTIBLE;
    1544:	c7 03 02 00 00 00    	movl   $0x2,(%ebx)
	unlock_op(&sched_semaphore);
    154a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
    1551:	e8 fc ff ff ff       	call   1552 <copy_process+0x51>

	p->task_nr = nr;
    1556:	8b 74 24 40          	mov    0x40(%esp),%esi
    155a:	89 b3 c0 03 00 00    	mov    %esi,0x3c0(%ebx)
	p->father_nr = current->task_nr;
    1560:	8b 85 c0 03 00 00    	mov    0x3c0(%ebp),%eax
    1566:	89 83 c4 03 00 00    	mov    %eax,0x3c4(%ebx)
	p->sched_on_ap = 0; /* 这里是自己埋的最后一个大坑，如果在AP上运行的task调用fork的话，其子进程的sched_on_ap肯定等于1了，这样它就永远不能被BSP调度运行 */
    156c:	c7 83 bc 03 00 00 00 	movl   $0x0,0x3bc(%ebx)
    1573:	00 00 00 
	p->pid = pid;
    1576:	8b 44 24 1c          	mov    0x1c(%esp),%eax
    157a:	89 83 2c 02 00 00    	mov    %eax,0x22c(%ebx)
	p->father = current->pid;
    1580:	8b 85 2c 02 00 00    	mov    0x22c(%ebp),%eax
    1586:	89 83 30 02 00 00    	mov    %eax,0x230(%ebx)
	p->counter = p->priority;
    158c:	8b 43 08             	mov    0x8(%ebx),%eax
    158f:	89 43 04             	mov    %eax,0x4(%ebx)
	p->signal = 0;
    1592:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
	p->alarm = 0;
    1599:	c7 83 4c 02 00 00 00 	movl   $0x0,0x24c(%ebx)
    15a0:	00 00 00 
	p->leader = 0;                       /* process leadership doesn't inherit */
    15a3:	c7 83 3c 02 00 00 00 	movl   $0x0,0x23c(%ebx)
    15aa:	00 00 00 
	p->utime = p->stime = 0;
    15ad:	c7 83 54 02 00 00 00 	movl   $0x0,0x254(%ebx)
    15b4:	00 00 00 
    15b7:	c7 83 50 02 00 00 00 	movl   $0x0,0x250(%ebx)
    15be:	00 00 00 
	p->cutime = p->cstime = 0;
    15c1:	c7 83 5c 02 00 00 00 	movl   $0x0,0x25c(%ebx)
    15c8:	00 00 00 
    15cb:	c7 83 58 02 00 00 00 	movl   $0x0,0x258(%ebx)
    15d2:	00 00 00 
	p->start_time = jiffies;
    15d5:	a1 00 00 00 00       	mov    0x0,%eax
    15da:	89 83 60 02 00 00    	mov    %eax,0x260(%ebx)
	p->tss.back_link = 0;
    15e0:	c7 83 e8 02 00 00 00 	movl   $0x0,0x2e8(%ebx)
    15e7:	00 00 00 
	p->tss.esp0 = PAGE_SIZE + (long) p;
    15ea:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
    15f0:	89 83 ec 02 00 00    	mov    %eax,0x2ec(%ebx)
	p->tss.ss0 = 0x10;
    15f6:	c7 83 f0 02 00 00 10 	movl   $0x10,0x2f0(%ebx)
    15fd:	00 00 00 
	p->tss.eip = eip;
    1600:	8b 44 24 70          	mov    0x70(%esp),%eax
    1604:	89 83 08 03 00 00    	mov    %eax,0x308(%ebx)
	p->tss.eflags = eflags;
    160a:	8b 44 24 78          	mov    0x78(%esp),%eax
    160e:	89 83 0c 03 00 00    	mov    %eax,0x30c(%ebx)
	p->tss.eax = 0;                   /* fork返回值是0的话，代表运行的是子进程，奥秘就在这里哈哈 */
    1614:	c7 83 10 03 00 00 00 	movl   $0x0,0x310(%ebx)
    161b:	00 00 00 
	p->tss.ecx = ecx;
    161e:	8b 44 24 5c          	mov    0x5c(%esp),%eax
    1622:	89 83 14 03 00 00    	mov    %eax,0x314(%ebx)
	p->tss.edx = edx;
    1628:	8b 44 24 60          	mov    0x60(%esp),%eax
    162c:	89 83 18 03 00 00    	mov    %eax,0x318(%ebx)
	p->tss.ebx = ebx;
    1632:	8b 44 24 58          	mov    0x58(%esp),%eax
    1636:	89 83 1c 03 00 00    	mov    %eax,0x31c(%ebx)
	p->tss.esp = esp;
    163c:	8b 44 24 7c          	mov    0x7c(%esp),%eax
    1640:	89 83 20 03 00 00    	mov    %eax,0x320(%ebx)
	p->tss.ebp = ebp;
    1646:	8b 44 24 44          	mov    0x44(%esp),%eax
    164a:	89 83 24 03 00 00    	mov    %eax,0x324(%ebx)
	p->tss.esi = esi;
    1650:	8b 44 24 4c          	mov    0x4c(%esp),%eax
    1654:	89 83 28 03 00 00    	mov    %eax,0x328(%ebx)
	p->tss.edi = edi;
    165a:	8b 44 24 48          	mov    0x48(%esp),%eax
    165e:	89 83 2c 03 00 00    	mov    %eax,0x32c(%ebx)
	p->tss.es = es & 0xffff;
    1664:	0f b7 44 24 68       	movzwl 0x68(%esp),%eax
    1669:	89 83 30 03 00 00    	mov    %eax,0x330(%ebx)
	p->tss.cs = cs & 0xffff;
    166f:	0f b7 44 24 74       	movzwl 0x74(%esp),%eax
    1674:	89 83 34 03 00 00    	mov    %eax,0x334(%ebx)
	p->tss.ss = ss & 0xffff;
    167a:	0f b7 84 24 80 00 00 	movzwl 0x80(%esp),%eax
    1681:	00 
    1682:	89 83 38 03 00 00    	mov    %eax,0x338(%ebx)
	p->tss.ds = ds & 0xffff;
    1688:	0f b7 44 24 6c       	movzwl 0x6c(%esp),%eax
    168d:	89 83 3c 03 00 00    	mov    %eax,0x33c(%ebx)
	p->tss.fs = fs & 0xffff;
    1693:	0f b7 44 24 64       	movzwl 0x64(%esp),%eax
    1698:	89 83 40 03 00 00    	mov    %eax,0x340(%ebx)
	p->tss.gs = gs & 0xffff;
    169e:	0f b7 44 24 50       	movzwl 0x50(%esp),%eax
    16a3:	89 83 44 03 00 00    	mov    %eax,0x344(%ebx)
	p->tss.ldt = _LDT(nr);             /* 注意：这里的ldt存储的是LDT表存储在GDT表中的选择符。 */
    16a9:	89 f0                	mov    %esi,%eax
    16ab:	c1 e0 04             	shl    $0x4,%eax
    16ae:	83 c0 28             	add    $0x28,%eax
    16b1:	89 83 48 03 00 00    	mov    %eax,0x348(%ebx)
	p->tss.trace_bitmap = 0x80000000;
    16b7:	c7 83 4c 03 00 00 00 	movl   $0x80000000,0x34c(%ebx)
    16be:	00 00 80 
	if (last_task_used_math == current)
    16c1:	83 c4 10             	add    $0x10,%esp
    16c4:	3b 2d 00 00 00 00    	cmp    0x0,%ebp
    16ca:	75 08                	jne    16d4 <copy_process+0x1d3>
		__asm__("clts ; fnsave %0"::"m" (p->tss.i387));
    16cc:	0f 06                	clts   
    16ce:	dd b3 50 03 00 00    	fnsave 0x350(%ebx)
	if (copy_mem(nr, p)) {
    16d4:	83 ec 08             	sub    $0x8,%esp
    16d7:	53                   	push   %ebx
    16d8:	ff 74 24 3c          	pushl  0x3c(%esp)
    16dc:	e8 fc ff ff ff       	call   16dd <copy_process+0x1dc>
    16e1:	83 c4 10             	add    $0x10,%esp
    16e4:	85 c0                	test   %eax,%eax
    16e6:	74 44                	je     172c <copy_process+0x22b>
		task[nr] = NULL;
    16e8:	8b 44 24 30          	mov    0x30(%esp),%eax
    16ec:	c7 04 85 00 00 00 00 	movl   $0x0,0x0(,%eax,4)
    16f3:	00 00 00 00 
		if (!free_page((long)p))
    16f7:	83 ec 0c             	sub    $0xc,%esp
    16fa:	53                   	push   %ebx
    16fb:	e8 fc ff ff ff       	call   16fc <copy_process+0x1fb>
    1700:	89 c2                	mov    %eax,%edx
    1702:	83 c4 10             	add    $0x10,%esp
			panic("fork.copy_process: trying to free free page");
		return -EAGAIN;
    1705:	b8 f5 ff ff ff       	mov    $0xfffffff5,%eax
	p->tss.trace_bitmap = 0x80000000;
	if (last_task_used_math == current)
		__asm__("clts ; fnsave %0"::"m" (p->tss.i387));
	if (copy_mem(nr, p)) {
		task[nr] = NULL;
		if (!free_page((long)p))
    170a:	85 d2                	test   %edx,%edx
    170c:	0f 85 16 01 00 00    	jne    1828 <copy_process+0x327>
			panic("fork.copy_process: trying to free free page");
    1712:	83 ec 0c             	sub    $0xc,%esp
    1715:	68 48 01 00 00       	push   $0x148
    171a:	e8 fc ff ff ff       	call   171b <copy_process+0x21a>
    171f:	83 c4 10             	add    $0x10,%esp
		return -EAGAIN;
    1722:	b8 f5 ff ff ff       	mov    $0xfffffff5,%eax
    1727:	e9 fc 00 00 00       	jmp    1828 <copy_process+0x327>
	}

	/* 共享的inode节点一定要同步 */
	lock_op(&copy_process_semaphore);
    172c:	83 ec 0c             	sub    $0xc,%esp
    172f:	68 00 00 00 00       	push   $0x0
    1734:	e8 fc ff ff ff       	call   1735 <copy_process+0x234>
    1739:	8d 83 80 02 00 00    	lea    0x280(%ebx),%eax
    173f:	8d 8b d0 02 00 00    	lea    0x2d0(%ebx),%ecx
    1745:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < NR_OPEN; i++)
		if (f = p->filp[i])
    1748:	8b 10                	mov    (%eax),%edx
    174a:	85 d2                	test   %edx,%edx
    174c:	74 05                	je     1753 <copy_process+0x252>
			f->f_count++;
    174e:	66 83 42 04 01       	addw   $0x1,0x4(%edx)
    1753:	83 c0 04             	add    $0x4,%eax
		return -EAGAIN;
	}

	/* 共享的inode节点一定要同步 */
	lock_op(&copy_process_semaphore);
	for (i = 0; i < NR_OPEN; i++)
    1756:	39 c8                	cmp    %ecx,%eax
    1758:	75 ee                	jne    1748 <copy_process+0x247>
		if (f = p->filp[i])
			f->f_count++;
	if (current->pwd)
    175a:	8b 85 70 02 00 00    	mov    0x270(%ebp),%eax
    1760:	85 c0                	test   %eax,%eax
    1762:	74 05                	je     1769 <copy_process+0x268>
		current->pwd->i_count++;
    1764:	66 83 40 30 01       	addw   $0x1,0x30(%eax)
	if (current->root)
    1769:	8b 85 74 02 00 00    	mov    0x274(%ebp),%eax
    176f:	85 c0                	test   %eax,%eax
    1771:	74 05                	je     1778 <copy_process+0x277>
		current->root->i_count++;
    1773:	66 83 40 30 01       	addw   $0x1,0x30(%eax)
	if (current->executable)
    1778:	8b 85 78 02 00 00    	mov    0x278(%ebp),%eax
    177e:	85 c0                	test   %eax,%eax
    1780:	74 05                	je     1787 <copy_process+0x286>
		current->executable->i_count++;
    1782:	66 83 40 30 01       	addw   $0x1,0x30(%eax)
	unlock_op(&copy_process_semaphore);
    1787:	83 ec 0c             	sub    $0xc,%esp
    178a:	68 00 00 00 00       	push   $0x0
    178f:	e8 fc ff ff ff       	call   1790 <copy_process+0x28f>

	set_tss_desc(gdt+(nr<<1)+FIRST_TSS_ENTRY, &(p->tss));
    1794:	8b 44 24 40          	mov    0x40(%esp),%eax
    1798:	8d 54 00 04          	lea    0x4(%eax,%eax,1),%edx
    179c:	8d 83 e8 02 00 00    	lea    0x2e8(%ebx),%eax
    17a2:	66 c7 04 d5 00 00 00 	movw   $0x68,0x0(,%edx,8)
    17a9:	00 68 00 
    17ac:	66 89 04 d5 02 00 00 	mov    %ax,0x2(,%edx,8)
    17b3:	00 
    17b4:	c1 c8 10             	ror    $0x10,%eax
    17b7:	88 04 d5 04 00 00 00 	mov    %al,0x4(,%edx,8)
    17be:	c6 04 d5 05 00 00 00 	movb   $0x89,0x5(,%edx,8)
    17c5:	89 
    17c6:	c6 04 d5 06 00 00 00 	movb   $0x0,0x6(,%edx,8)
    17cd:	00 
    17ce:	88 24 d5 07 00 00 00 	mov    %ah,0x7(,%edx,8)
    17d5:	c1 c8 10             	ror    $0x10,%eax
	set_ldt_desc(gdt+(nr<<1)+FIRST_LDT_ENTRY, &(p->ldt));
    17d8:	8d 83 d0 02 00 00    	lea    0x2d0(%ebx),%eax
    17de:	66 c7 04 d5 08 00 00 	movw   $0x68,0x8(,%edx,8)
    17e5:	00 68 00 
    17e8:	66 89 04 d5 0a 00 00 	mov    %ax,0xa(,%edx,8)
    17ef:	00 
    17f0:	c1 c8 10             	ror    $0x10,%eax
    17f3:	88 04 d5 0c 00 00 00 	mov    %al,0xc(,%edx,8)
    17fa:	c6 04 d5 0d 00 00 00 	movb   $0x82,0xd(,%edx,8)
    1801:	82 
    1802:	c6 04 d5 0e 00 00 00 	movb   $0x0,0xe(,%edx,8)
    1809:	00 
    180a:	88 24 d5 0f 00 00 00 	mov    %ah,0xf(,%edx,8)
    1811:	c1 c8 10             	ror    $0x10,%eax
	p->state = TASK_RUNNING; /* do this last, just in case */
    1814:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)

	return pid;  /* 这时的子进程ID不能用last_pid了 */
    181a:	83 c4 10             	add    $0x10,%esp
    181d:	8b 44 24 0c          	mov    0xc(%esp),%eax
    1821:	eb 05                	jmp    1828 <copy_process+0x327>
	struct task_struct *p = task[nr];
	int i;
	struct file *f;
    /* 此版本将进程的task_struct和目录表都分配在内核实地址寻址的空间(mem>512M && mem<(512-64)M) */
	if (!p)
		return -EAGAIN;
    1823:	b8 f5 ff ff ff       	mov    $0xfffffff5,%eax
	set_tss_desc(gdt+(nr<<1)+FIRST_TSS_ENTRY, &(p->tss));
	set_ldt_desc(gdt+(nr<<1)+FIRST_LDT_ENTRY, &(p->ldt));
	p->state = TASK_RUNNING; /* do this last, just in case */

	return pid;  /* 这时的子进程ID不能用last_pid了 */
}
    1828:	83 c4 1c             	add    $0x1c,%esp
    182b:	5b                   	pop    %ebx
    182c:	5e                   	pop    %esi
    182d:	5f                   	pop    %edi
    182e:	5d                   	pop    %ebp
    182f:	c3                   	ret    

00001830 <find_empty_process>:

int find_empty_process(void) {
    1830:	56                   	push   %esi
    1831:	53                   	push   %ebx
    1832:	83 ec 10             	sub    $0x10,%esp
	lock_op(&find_empty_process_semaphore);
    1835:	68 00 00 00 00       	push   $0x0
    183a:	e8 fc ff ff ff       	call   183b <find_empty_process+0xb>
    183f:	8b 0d 00 00 00 00    	mov    0x0,%ecx
    1845:	83 c4 10             	add    $0x10,%esp
	int lock_flag = 1;
	int i;

	repeat: if ((++last_pid) < 0)
		last_pid = 1;
    1848:	be 01 00 00 00       	mov    $0x1,%esi
    184d:	bb 00 01 00 00       	mov    $0x100,%ebx
int find_empty_process(void) {
	lock_op(&find_empty_process_semaphore);
	int lock_flag = 1;
	int i;

	repeat: if ((++last_pid) < 0)
    1852:	83 c1 01             	add    $0x1,%ecx
		last_pid = 1;
    1855:	0f 48 ce             	cmovs  %esi,%ecx
    1858:	b8 00 00 00 00       	mov    $0x0,%eax
	for (i = 0; i < NR_TASKS; i++)
		if (task[i]) {
    185d:	8b 10                	mov    (%eax),%edx
    185f:	85 d2                	test   %edx,%edx
    1861:	74 08                	je     186b <find_empty_process+0x3b>
			if (task[i]->pid == last_pid)
    1863:	39 8a 2c 02 00 00    	cmp    %ecx,0x22c(%edx)
    1869:	74 e7                	je     1852 <find_empty_process+0x22>
    186b:	83 c0 04             	add    $0x4,%eax
	int lock_flag = 1;
	int i;

	repeat: if ((++last_pid) < 0)
		last_pid = 1;
	for (i = 0; i < NR_TASKS; i++)
    186e:	39 c3                	cmp    %eax,%ebx
    1870:	75 eb                	jne    185d <find_empty_process+0x2d>
    1872:	89 0d 00 00 00 00    	mov    %ecx,0x0
			if (task[i]->pid == last_pid)
				goto repeat;
		}

	for (i = 1; i < NR_TASKS; i++) {
		if (!task[i]) {
    1878:	83 3d 04 00 00 00 00 	cmpl   $0x0,0x4
    187f:	74 11                	je     1892 <find_empty_process+0x62>
    1881:	bb 02 00 00 00       	mov    $0x2,%ebx
    1886:	83 3c 9d 00 00 00 00 	cmpl   $0x0,0x0(,%ebx,4)
    188d:	00 
    188e:	75 3d                	jne    18cd <find_empty_process+0x9d>
    1890:	eb 05                	jmp    1897 <find_empty_process+0x67>
    1892:	bb 01 00 00 00       	mov    $0x1,%ebx
			/* 多进程并发的时候,这里要先分配一页,起到站位的作用,否则会两个进程共用一个NR. */
			struct task_struct* task_page = (struct task_struct *) get_free_page(PAGE_IN_REAL_MEM_MAP);
    1897:	83 ec 0c             	sub    $0xc,%esp
    189a:	6a 01                	push   $0x1
    189c:	e8 fc ff ff ff       	call   189d <find_empty_process+0x6d>
			/* 这里一定要先设置任务的状态为不可中断状态,因为默认的是running状态,一旦赋值给task[nr],schedule就能调度运行了
			 * 但是这时相应的任务状态信息还没有设置,所以会报错,这是个大坑啊
			 *  */
			task_page->state = TASK_UNINTERRUPTIBLE;
    18a1:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
			task_page->pid = last_pid;  /* 这里要设置PID,否则后面进程并发会造成多个进程共用同一个PID */
    18a7:	8b 15 00 00 00 00    	mov    0x0,%edx
    18ad:	89 90 2c 02 00 00    	mov    %edx,0x22c(%eax)
			task[i] = task_page;  /* 这样就确保任务此时,是不会被调度的. */
    18b3:	89 04 9d 00 00 00 00 	mov    %eax,0x0(,%ebx,4)
			if (lock_flag) {
				unlock_op(&find_empty_process_semaphore);
    18ba:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
    18c1:	e8 fc ff ff ff       	call   18c2 <find_empty_process+0x92>
				lock_flag = 0;
			}
			return i;
    18c6:	83 c4 10             	add    $0x10,%esp
    18c9:	89 d8                	mov    %ebx,%eax
    18cb:	eb 1d                	jmp    18ea <find_empty_process+0xba>
		if (task[i]) {
			if (task[i]->pid == last_pid)
				goto repeat;
		}

	for (i = 1; i < NR_TASKS; i++) {
    18cd:	83 c3 01             	add    $0x1,%ebx
    18d0:	83 fb 40             	cmp    $0x40,%ebx
    18d3:	75 b1                	jne    1886 <find_empty_process+0x56>
			}
			return i;
		}
	}
    if (lock_flag) {
    	unlock_op(&find_empty_process_semaphore);
    18d5:	83 ec 0c             	sub    $0xc,%esp
    18d8:	68 00 00 00 00       	push   $0x0
    18dd:	e8 fc ff ff ff       	call   18de <find_empty_process+0xae>
    	lock_flag = 0;
    }
	return -EAGAIN;
    18e2:	83 c4 10             	add    $0x10,%esp
    18e5:	b8 f5 ff ff ff       	mov    $0xfffffff5,%eax
}
    18ea:	83 c4 04             	add    $0x4,%esp
    18ed:	5b                   	pop    %ebx
    18ee:	5e                   	pop    %esi
    18ef:	c3                   	ret    

000018f0 <panic>:
#include <linux/sched.h>

void sys_sync(void);	/* it's really int */

volatile void panic(const char * s)
{
    18f0:	83 ec 14             	sub    $0x14,%esp
	printk("Kernel panic: %s\n\r",s);
    18f3:	ff 74 24 18          	pushl  0x18(%esp)
    18f7:	68 b5 01 00 00       	push   $0x1b5
    18fc:	e8 fc ff ff ff       	call   18fd <panic+0xd>
	if (get_current_task() == task[0])
    1901:	e8 fc ff ff ff       	call   1902 <panic+0x12>
    1906:	83 c4 10             	add    $0x10,%esp
    1909:	39 05 00 00 00 00    	cmp    %eax,0x0
    190f:	75 12                	jne    1923 <panic+0x33>
		printk("In swapper task - not syncing\n\r");
    1911:	83 ec 0c             	sub    $0xc,%esp
    1914:	68 74 01 00 00       	push   $0x174
    1919:	e8 fc ff ff ff       	call   191a <panic+0x2a>
    191e:	83 c4 10             	add    $0x10,%esp
    1921:	eb 05                	jmp    1928 <panic+0x38>
	else
		sys_sync();
    1923:	e8 fc ff ff ff       	call   1924 <panic+0x34>
    1928:	eb fe                	jmp    1928 <panic+0x38>

0000192a <printk>:

extern unsigned long tty_io_semaphore;
extern unsigned short	video_port_reg;		/* Video register select port	*/

int printk(const char *fmt, ...)
{
    192a:	83 ec 18             	sub    $0x18,%esp
	va_list args;
	int i;

	lock_op(&tty_io_semaphore);
    192d:	68 00 00 00 00       	push   $0x0
    1932:	e8 fc ff ff ff       	call   1933 <printk+0x9>

	va_start(args, fmt);
	i=vsprintf(print_buf,fmt,args);
    1937:	83 c4 0c             	add    $0xc,%esp
    193a:	8d 44 24 18          	lea    0x18(%esp),%eax
    193e:	50                   	push   %eax
    193f:	ff 74 24 18          	pushl  0x18(%esp)
    1943:	68 00 00 00 00       	push   $0x0
    1948:	e8 fc ff ff ff       	call   1949 <printk+0x1f>
    194d:	89 c1                	mov    %eax,%ecx
	va_end(args);

	/* Cause VM-EXIT, Using host print to instead of Guest print. */
	exit_reason_io_vedio_struct* exit_reason_io_vedio_p = (exit_reason_io_vedio_struct*) VM_EXIT_SLEF_DEFINED_INFO_ADDR;
	exit_reason_io_vedio_p->exit_reason_no = VM_EXIT_REASON_IO_INSTRUCTION;
    194f:	c7 05 00 f0 09 00 1e 	movl   $0x1e,0x9f000
    1956:	00 00 00 
	exit_reason_io_vedio_p->print_size = i;
    1959:	a3 04 f0 09 00       	mov    %eax,0x9f004
	exit_reason_io_vedio_p->print_buf = print_buf;
    195e:	c7 05 08 f0 09 00 00 	movl   $0x0,0x9f008
    1965:	00 00 00 
	cli();
    1968:	fa                   	cli    
	outb_p(14, video_port_reg);
    1969:	0f b7 15 00 00 00 00 	movzwl 0x0,%edx
    1970:	b8 0e 00 00 00       	mov    $0xe,%eax
    1975:	ee                   	out    %al,(%dx)
    1976:	eb 00                	jmp    1978 <printk+0x4e>
    1978:	eb 00                	jmp    197a <printk+0x50>
	sti();
    197a:	fb                   	sti    
			"addl $8,%%esp\n\t"
			"popl %0\n\t"
			"pop %%fs"
			::"r" (i):"ax","cx","dx");
	return i;
}
    197b:	89 c8                	mov    %ecx,%eax
    197d:	83 c4 1c             	add    $0x1c,%esp
    1980:	c3                   	ret    

00001981 <cpy_str_to_kernel>:

char* cpy_str_to_kernel(char * dest,const char *src)
{
    1981:	57                   	push   %edi
    1982:	56                   	push   %esi
    1983:	8b 44 24 0c          	mov    0xc(%esp),%eax
__asm__(
    1987:	8b 74 24 10          	mov    0x10(%esp),%esi
    198b:	89 c7                	mov    %eax,%edi
    198d:	1e                   	push   %ds
    198e:	0f a0                	push   %fs
    1990:	1f                   	pop    %ds
    1991:	fc                   	cld    
    1992:	ac                   	lods   %ds:(%esi),%al
    1993:	aa                   	stos   %al,%es:(%edi)
    1994:	84 c0                	test   %al,%al
    1996:	75 fa                	jne    1992 <cpy_str_to_kernel+0x11>
    1998:	1f                   	pop    %ds
	"testb %%al,%%al\n\t"
	"jne 1b\n\t"
	"pop %%ds"
	::"S" (src),"D" (dest));
return dest;
}
    1999:	5e                   	pop    %esi
    199a:	5f                   	pop    %edi
    199b:	c3                   	ret    

0000199c <number>:
int __res; \
__asm__("divl %4":"=a" (n),"=d" (__res):"0" (n),"1" (0),"r" (base)); \
__res; })

static char * number(char * str, int num, int base, int size, int precision,
		int type) {
    199c:	55                   	push   %ebp
    199d:	57                   	push   %edi
    199e:	56                   	push   %esi
    199f:	53                   	push   %ebx
    19a0:	83 ec 38             	sub    $0x38,%esp
    19a3:	89 c3                	mov    %eax,%ebx
    19a5:	89 d5                	mov    %edx,%ebp
	char c, sign, tmp[36];
	const char *digits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
	int i;

	if (type & SMALL)
    19a7:	8b 44 24 54          	mov    0x54(%esp),%eax
    19ab:	83 e0 40             	and    $0x40,%eax
		digits = "0123456789abcdefghijklmnopqrstuvwxyz";
    19ae:	b8 bc 01 00 00       	mov    $0x1bc,%eax
    19b3:	be 94 01 00 00       	mov    $0x194,%esi
    19b8:	0f 45 f0             	cmovne %eax,%esi
	if (type & LEFT)
    19bb:	8b 54 24 54          	mov    0x54(%esp),%edx
    19bf:	83 e2 10             	and    $0x10,%edx
		type &= ~ZEROPAD;
    19c2:	8b 44 24 54          	mov    0x54(%esp),%eax
    19c6:	83 e0 fe             	and    $0xfffffffe,%eax
    19c9:	85 d2                	test   %edx,%edx
    19cb:	0f 44 44 24 54       	cmove  0x54(%esp),%eax
    19d0:	89 44 24 54          	mov    %eax,0x54(%esp)
	if (base < 2 || base > 36)
    19d4:	8d 41 fe             	lea    -0x2(%ecx),%eax
    19d7:	83 f8 22             	cmp    $0x22,%eax
    19da:	0f 87 8a 01 00 00    	ja     1b6a <number+0x1ce>
    19e0:	89 cf                	mov    %ecx,%edi
		return 0;
	c = (type & ZEROPAD) ? '0' : ' ';
    19e2:	8b 44 24 54          	mov    0x54(%esp),%eax
    19e6:	83 e0 01             	and    $0x1,%eax
    19e9:	83 f8 01             	cmp    $0x1,%eax
    19ec:	19 c0                	sbb    %eax,%eax
    19ee:	83 e0 f0             	and    $0xfffffff0,%eax
    19f1:	83 c0 30             	add    $0x30,%eax
    19f4:	88 44 24 07          	mov    %al,0x7(%esp)
	if (type & SIGN && num < 0) {
    19f8:	f6 44 24 54 02       	testb  $0x2,0x54(%esp)
    19fd:	74 15                	je     1a14 <number+0x78>
    19ff:	89 e8                	mov    %ebp,%eax
    1a01:	c1 e8 1f             	shr    $0x1f,%eax
    1a04:	84 c0                	test   %al,%al
    1a06:	74 0c                	je     1a14 <number+0x78>
		sign = '-';
		num = -num;
    1a08:	f7 dd                	neg    %ebp
		type &= ~ZEROPAD;
	if (base < 2 || base > 36)
		return 0;
	c = (type & ZEROPAD) ? '0' : ' ';
	if (type & SIGN && num < 0) {
		sign = '-';
    1a0a:	c6 44 24 06 2d       	movb   $0x2d,0x6(%esp)
		num = -num;
    1a0f:	e9 6d 01 00 00       	jmp    1b81 <number+0x1e5>
	} else
		sign = (type & PLUS) ? '+' : ((type & SPACE) ? ' ' : 0);
    1a14:	f6 44 24 54 04       	testb  $0x4,0x54(%esp)
    1a19:	0f 85 56 01 00 00    	jne    1b75 <number+0x1d9>
    1a1f:	f6 44 24 54 08       	testb  $0x8,0x54(%esp)
    1a24:	0f 85 52 01 00 00    	jne    1b7c <number+0x1e0>
    1a2a:	c6 44 24 06 00       	movb   $0x0,0x6(%esp)
	if (sign)
		size--;
	if (type & SPECIAL)
    1a2f:	8b 44 24 54          	mov    0x54(%esp),%eax
    1a33:	83 e0 20             	and    $0x20,%eax
    1a36:	89 04 24             	mov    %eax,(%esp)
    1a39:	0f 84 4c 01 00 00    	je     1b8b <number+0x1ef>
		if (base == 16)
    1a3f:	83 ff 10             	cmp    $0x10,%edi
    1a42:	75 07                	jne    1a4b <number+0xaf>
			size -= 2;
    1a44:	83 6c 24 4c 02       	subl   $0x2,0x4c(%esp)
    1a49:	eb 0d                	jmp    1a58 <number+0xbc>
		else if (base == 8)
			size--;
    1a4b:	83 ff 08             	cmp    $0x8,%edi
    1a4e:	0f 94 c0             	sete   %al
    1a51:	0f b6 c0             	movzbl %al,%eax
    1a54:	29 44 24 4c          	sub    %eax,0x4c(%esp)
	i = 0;
	if (num == 0)
    1a58:	85 ed                	test   %ebp,%ebp
    1a5a:	75 0c                	jne    1a68 <number+0xcc>
		tmp[i++] = '0';
    1a5c:	c6 44 24 14 30       	movb   $0x30,0x14(%esp)
    1a61:	b9 01 00 00 00       	mov    $0x1,%ecx
    1a66:	eb 1f                	jmp    1a87 <number+0xeb>
	c = (type & ZEROPAD) ? '0' : ' ';
	if (type & SIGN && num < 0) {
		sign = '-';
		num = -num;
	} else
		sign = (type & PLUS) ? '+' : ((type & SPACE) ? ' ' : 0);
    1a68:	b9 00 00 00 00       	mov    $0x0,%ecx
	i = 0;
	if (num == 0)
		tmp[i++] = '0';
	else
		while (num != 0)
			tmp[i++] = digits[do_div(num, base)];
    1a6d:	83 c1 01             	add    $0x1,%ecx
    1a70:	89 e8                	mov    %ebp,%eax
    1a72:	ba 00 00 00 00       	mov    $0x0,%edx
    1a77:	f7 f7                	div    %edi
    1a79:	89 c5                	mov    %eax,%ebp
    1a7b:	0f b6 14 16          	movzbl (%esi,%edx,1),%edx
    1a7f:	88 54 0c 13          	mov    %dl,0x13(%esp,%ecx,1)
			size--;
	i = 0;
	if (num == 0)
		tmp[i++] = '0';
	else
		while (num != 0)
    1a83:	85 c0                	test   %eax,%eax
    1a85:	75 e6                	jne    1a6d <number+0xd1>
    1a87:	3b 4c 24 50          	cmp    0x50(%esp),%ecx
    1a8b:	89 cd                	mov    %ecx,%ebp
    1a8d:	0f 4c 6c 24 50       	cmovl  0x50(%esp),%ebp
			tmp[i++] = digits[do_div(num, base)];
	if (i > precision)
		precision = i;
	size -= precision;
    1a92:	8b 44 24 4c          	mov    0x4c(%esp),%eax
    1a96:	29 e8                	sub    %ebp,%eax
	if (!(type & (ZEROPAD + LEFT)))
    1a98:	f6 44 24 54 11       	testb  $0x11,0x54(%esp)
    1a9d:	75 20                	jne    1abf <number+0x123>
		while (size-- > 0)
    1a9f:	8d 50 ff             	lea    -0x1(%eax),%edx
    1aa2:	85 c0                	test   %eax,%eax
    1aa4:	7e 17                	jle    1abd <number+0x121>
    1aa6:	8d 14 03             	lea    (%ebx,%eax,1),%edx
			*str++ = ' ';
    1aa9:	83 c3 01             	add    $0x1,%ebx
    1aac:	c6 43 ff 20          	movb   $0x20,-0x1(%ebx)
			tmp[i++] = digits[do_div(num, base)];
	if (i > precision)
		precision = i;
	size -= precision;
	if (!(type & (ZEROPAD + LEFT)))
		while (size-- > 0)
    1ab0:	39 d3                	cmp    %edx,%ebx
    1ab2:	75 f5                	jne    1aa9 <number+0x10d>
    1ab4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
			*str++ = ' ';
    1ab9:	89 d3                	mov    %edx,%ebx
    1abb:	eb 02                	jmp    1abf <number+0x123>
			tmp[i++] = digits[do_div(num, base)];
	if (i > precision)
		precision = i;
	size -= precision;
	if (!(type & (ZEROPAD + LEFT)))
		while (size-- > 0)
    1abd:	89 d0                	mov    %edx,%eax
			*str++ = ' ';
	if (sign)
    1abf:	0f b6 54 24 06       	movzbl 0x6(%esp),%edx
    1ac4:	84 d2                	test   %dl,%dl
    1ac6:	74 05                	je     1acd <number+0x131>
		*str++ = sign;
    1ac8:	88 13                	mov    %dl,(%ebx)
    1aca:	8d 5b 01             	lea    0x1(%ebx),%ebx
	if (type & SPECIAL)
    1acd:	83 3c 24 00          	cmpl   $0x0,(%esp)
    1ad1:	74 1f                	je     1af2 <number+0x156>
		if (base == 8)
    1ad3:	83 ff 08             	cmp    $0x8,%edi
    1ad6:	75 08                	jne    1ae0 <number+0x144>
			*str++ = '0';
    1ad8:	c6 03 30             	movb   $0x30,(%ebx)
    1adb:	8d 5b 01             	lea    0x1(%ebx),%ebx
    1ade:	eb 12                	jmp    1af2 <number+0x156>
		else if (base == 16) {
    1ae0:	83 ff 10             	cmp    $0x10,%edi
    1ae3:	75 0d                	jne    1af2 <number+0x156>
			*str++ = '0';
    1ae5:	c6 03 30             	movb   $0x30,(%ebx)
			*str++ = digits[33];
    1ae8:	0f b6 56 21          	movzbl 0x21(%esi),%edx
    1aec:	88 53 01             	mov    %dl,0x1(%ebx)
    1aef:	8d 5b 02             	lea    0x2(%ebx),%ebx
		}
	if (!(type & LEFT))
    1af2:	f6 44 24 54 10       	testb  $0x10,0x54(%esp)
    1af7:	75 23                	jne    1b1c <number+0x180>
		while (size-- > 0)
    1af9:	8d 50 ff             	lea    -0x1(%eax),%edx
    1afc:	85 c0                	test   %eax,%eax
    1afe:	7e 1a                	jle    1b1a <number+0x17e>
    1b00:	01 d8                	add    %ebx,%eax
    1b02:	0f b6 54 24 07       	movzbl 0x7(%esp),%edx
			*str++ = c;
    1b07:	83 c3 01             	add    $0x1,%ebx
    1b0a:	88 53 ff             	mov    %dl,-0x1(%ebx)
		else if (base == 16) {
			*str++ = '0';
			*str++ = digits[33];
		}
	if (!(type & LEFT))
		while (size-- > 0)
    1b0d:	39 c3                	cmp    %eax,%ebx
    1b0f:	75 f6                	jne    1b07 <number+0x16b>
			*str++ = c;
    1b11:	89 c3                	mov    %eax,%ebx
		else if (base == 16) {
			*str++ = '0';
			*str++ = digits[33];
		}
	if (!(type & LEFT))
		while (size-- > 0)
    1b13:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    1b18:	eb 02                	jmp    1b1c <number+0x180>
    1b1a:	89 d0                	mov    %edx,%eax
			*str++ = c;
	while (i < precision--)
    1b1c:	39 e9                	cmp    %ebp,%ecx
    1b1e:	7d 13                	jge    1b33 <number+0x197>
    1b20:	89 ef                	mov    %ebp,%edi
    1b22:	29 cf                	sub    %ecx,%edi
    1b24:	01 df                	add    %ebx,%edi
		*str++ = '0';
    1b26:	83 c3 01             	add    $0x1,%ebx
    1b29:	c6 43 ff 30          	movb   $0x30,-0x1(%ebx)
			*str++ = digits[33];
		}
	if (!(type & LEFT))
		while (size-- > 0)
			*str++ = c;
	while (i < precision--)
    1b2d:	39 df                	cmp    %ebx,%edi
    1b2f:	75 f5                	jne    1b26 <number+0x18a>
    1b31:	eb 02                	jmp    1b35 <number+0x199>
    1b33:	89 df                	mov    %ebx,%edi
		*str++ = '0';
	while (i-- > 0)
    1b35:	85 c9                	test   %ecx,%ecx
    1b37:	7e 1e                	jle    1b57 <number+0x1bb>
    1b39:	89 ce                	mov    %ecx,%esi
    1b3b:	8d 54 0c 13          	lea    0x13(%esp,%ecx,1),%edx
    1b3f:	8d 6c 24 13          	lea    0x13(%esp),%ebp
    1b43:	89 f9                	mov    %edi,%ecx
		*str++ = tmp[i];
    1b45:	83 c1 01             	add    $0x1,%ecx
    1b48:	0f b6 1a             	movzbl (%edx),%ebx
    1b4b:	88 59 ff             	mov    %bl,-0x1(%ecx)
    1b4e:	83 ea 01             	sub    $0x1,%edx
	if (!(type & LEFT))
		while (size-- > 0)
			*str++ = c;
	while (i < precision--)
		*str++ = '0';
	while (i-- > 0)
    1b51:	39 d5                	cmp    %edx,%ebp
    1b53:	75 f0                	jne    1b45 <number+0x1a9>
    1b55:	01 f7                	add    %esi,%edi
		*str++ = tmp[i];
	while (size-- > 0)
    1b57:	85 c0                	test   %eax,%eax
    1b59:	7e 16                	jle    1b71 <number+0x1d5>
    1b5b:	01 f8                	add    %edi,%eax
		*str++ = ' ';
    1b5d:	83 c7 01             	add    $0x1,%edi
    1b60:	c6 47 ff 20          	movb   $0x20,-0x1(%edi)
			*str++ = c;
	while (i < precision--)
		*str++ = '0';
	while (i-- > 0)
		*str++ = tmp[i];
	while (size-- > 0)
    1b64:	39 f8                	cmp    %edi,%eax
    1b66:	75 f5                	jne    1b5d <number+0x1c1>
    1b68:	eb 2e                	jmp    1b98 <number+0x1fc>
	if (type & SMALL)
		digits = "0123456789abcdefghijklmnopqrstuvwxyz";
	if (type & LEFT)
		type &= ~ZEROPAD;
	if (base < 2 || base > 36)
		return 0;
    1b6a:	b8 00 00 00 00       	mov    $0x0,%eax
    1b6f:	eb 27                	jmp    1b98 <number+0x1fc>
			*str++ = c;
	while (i < precision--)
		*str++ = '0';
	while (i-- > 0)
		*str++ = tmp[i];
	while (size-- > 0)
    1b71:	89 f8                	mov    %edi,%eax
    1b73:	eb 23                	jmp    1b98 <number+0x1fc>
	c = (type & ZEROPAD) ? '0' : ' ';
	if (type & SIGN && num < 0) {
		sign = '-';
		num = -num;
	} else
		sign = (type & PLUS) ? '+' : ((type & SPACE) ? ' ' : 0);
    1b75:	c6 44 24 06 2b       	movb   $0x2b,0x6(%esp)
    1b7a:	eb 05                	jmp    1b81 <number+0x1e5>
    1b7c:	c6 44 24 06 20       	movb   $0x20,0x6(%esp)
	if (sign)
		size--;
    1b81:	83 6c 24 4c 01       	subl   $0x1,0x4c(%esp)
    1b86:	e9 a4 fe ff ff       	jmp    1a2f <number+0x93>
		if (base == 16)
			size -= 2;
		else if (base == 8)
			size--;
	i = 0;
	if (num == 0)
    1b8b:	85 ed                	test   %ebp,%ebp
    1b8d:	0f 84 c9 fe ff ff    	je     1a5c <number+0xc0>
    1b93:	e9 d0 fe ff ff       	jmp    1a68 <number+0xcc>
	while (i-- > 0)
		*str++ = tmp[i];
	while (size-- > 0)
		*str++ = ' ';
	return str;
}
    1b98:	83 c4 38             	add    $0x38,%esp
    1b9b:	5b                   	pop    %ebx
    1b9c:	5e                   	pop    %esi
    1b9d:	5f                   	pop    %edi
    1b9e:	5d                   	pop    %ebp
    1b9f:	c3                   	ret    

00001ba0 <vsprintf>:

int vsprintf(char *buf, const char *fmt, va_list args) {
    1ba0:	55                   	push   %ebp
    1ba1:	57                   	push   %edi
    1ba2:	56                   	push   %esi
    1ba3:	53                   	push   %ebx
    1ba4:	83 ec 08             	sub    $0x8,%esp
    1ba7:	8b 44 24 20          	mov    0x20(%esp),%eax
	int field_width; /* width of output field */
	int precision; /* min. # of digits for integers; max
	 number of chars for from string */
	int qualifier; /* 'h', 'l', or 'L' for integer fields */

	for (str = buf; *fmt; ++fmt) {
    1bab:	0f b6 10             	movzbl (%eax),%edx
    1bae:	84 d2                	test   %dl,%dl
    1bb0:	0f 84 58 03 00 00    	je     1f0e <vsprintf+0x36e>
    1bb6:	8b 6c 24 1c          	mov    0x1c(%esp),%ebp
		if (*fmt != '%') {
    1bba:	80 fa 25             	cmp    $0x25,%dl
    1bbd:	74 0d                	je     1bcc <vsprintf+0x2c>
			*str++ = *fmt;
    1bbf:	88 55 00             	mov    %dl,0x0(%ebp)
			continue;
    1bc2:	89 c3                	mov    %eax,%ebx
	 number of chars for from string */
	int qualifier; /* 'h', 'l', or 'L' for integer fields */

	for (str = buf; *fmt; ++fmt) {
		if (*fmt != '%') {
			*str++ = *fmt;
    1bc4:	8d 6d 01             	lea    0x1(%ebp),%ebp
			continue;
    1bc7:	e9 31 03 00 00       	jmp    1efd <vsprintf+0x35d>
    1bcc:	be 00 00 00 00       	mov    $0x0,%esi
		}

		/* process flags */
		flags = 0;
		repeat: ++fmt; /* this also skips first '%' */
    1bd1:	83 c0 01             	add    $0x1,%eax
		switch (*fmt) {
    1bd4:	0f b6 08             	movzbl (%eax),%ecx
    1bd7:	8d 51 e0             	lea    -0x20(%ecx),%edx
    1bda:	80 fa 10             	cmp    $0x10,%dl
    1bdd:	77 23                	ja     1c02 <vsprintf+0x62>
    1bdf:	0f b6 d2             	movzbl %dl,%edx
    1be2:	ff 24 95 00 00 00 00 	jmp    *0x0(,%edx,4)
		case '-':
			flags |= LEFT;
    1be9:	83 ce 10             	or     $0x10,%esi
			goto repeat;
    1bec:	eb e3                	jmp    1bd1 <vsprintf+0x31>
		case '+':
			flags |= PLUS;
    1bee:	83 ce 04             	or     $0x4,%esi
			goto repeat;
    1bf1:	eb de                	jmp    1bd1 <vsprintf+0x31>
		case ' ':
			flags |= SPACE;
    1bf3:	83 ce 08             	or     $0x8,%esi
			goto repeat;
    1bf6:	eb d9                	jmp    1bd1 <vsprintf+0x31>
		case '#':
			flags |= SPECIAL;
    1bf8:	83 ce 20             	or     $0x20,%esi
			goto repeat;
    1bfb:	eb d4                	jmp    1bd1 <vsprintf+0x31>
		case '0':
			flags |= ZEROPAD;
    1bfd:	83 ce 01             	or     $0x1,%esi
			goto repeat;
    1c00:	eb cf                	jmp    1bd1 <vsprintf+0x31>
		}

		/* get field width */
		field_width = -1;
		if (is_digit(*fmt))
    1c02:	8d 51 d0             	lea    -0x30(%ecx),%edx
    1c05:	80 fa 09             	cmp    $0x9,%dl
    1c08:	77 21                	ja     1c2b <vsprintf+0x8b>
    1c0a:	ba 00 00 00 00       	mov    $0x0,%edx

static int skip_atoi(const char **s) {
	int i = 0;

	while (is_digit(**s))
		i = i * 10 + *((*s)++) - '0';
    1c0f:	83 c0 01             	add    $0x1,%eax
    1c12:	8d 14 92             	lea    (%edx,%edx,4),%edx
    1c15:	0f be c9             	movsbl %cl,%ecx
    1c18:	8d 54 51 d0          	lea    -0x30(%ecx,%edx,2),%edx
#define is_digit(c)	((c) >= '0' && (c) <= '9')

static int skip_atoi(const char **s) {
	int i = 0;

	while (is_digit(**s))
    1c1c:	0f b6 08             	movzbl (%eax),%ecx
    1c1f:	8d 59 d0             	lea    -0x30(%ecx),%ebx
    1c22:	80 fb 09             	cmp    $0x9,%bl
    1c25:	76 e8                	jbe    1c0f <vsprintf+0x6f>
		i = i * 10 + *((*s)++) - '0';
    1c27:	89 c3                	mov    %eax,%ebx
    1c29:	eb 27                	jmp    1c52 <vsprintf+0xb2>
			continue;
		}

		/* process flags */
		flags = 0;
		repeat: ++fmt; /* this also skips first '%' */
    1c2b:	89 c3                	mov    %eax,%ebx
			flags |= ZEROPAD;
			goto repeat;
		}

		/* get field width */
		field_width = -1;
    1c2d:	ba ff ff ff ff       	mov    $0xffffffff,%edx
		if (is_digit(*fmt))
			field_width = skip_atoi(&fmt);
		else if (*fmt == '*') {
    1c32:	80 f9 2a             	cmp    $0x2a,%cl
    1c35:	75 1b                	jne    1c52 <vsprintf+0xb2>
			/* it's the next argument */
			field_width = va_arg(args, int);
    1c37:	8b 7c 24 24          	mov    0x24(%esp),%edi
    1c3b:	8d 4f 04             	lea    0x4(%edi),%ecx
    1c3e:	8b 17                	mov    (%edi),%edx
			if (field_width < 0) {
    1c40:	85 d2                	test   %edx,%edx
    1c42:	0f 89 cc 02 00 00    	jns    1f14 <vsprintf+0x374>
				field_width = -field_width;
    1c48:	f7 da                	neg    %edx
				flags |= LEFT;
    1c4a:	83 ce 10             	or     $0x10,%esi
    1c4d:	e9 c2 02 00 00       	jmp    1f14 <vsprintf+0x374>
			}
		}

		/* get the precision */
		precision = -1;
    1c52:	c7 04 24 ff ff ff ff 	movl   $0xffffffff,(%esp)
		if (*fmt == '.') {
    1c59:	80 3b 2e             	cmpb   $0x2e,(%ebx)
    1c5c:	75 53                	jne    1cb1 <vsprintf+0x111>
			++fmt;
    1c5e:	8d 7b 01             	lea    0x1(%ebx),%edi
			if (is_digit(*fmt))
    1c61:	0f b6 43 01          	movzbl 0x1(%ebx),%eax
    1c65:	8d 48 d0             	lea    -0x30(%eax),%ecx
    1c68:	80 f9 09             	cmp    $0x9,%cl
    1c6b:	77 1f                	ja     1c8c <vsprintf+0xec>
    1c6d:	b9 00 00 00 00       	mov    $0x0,%ecx

static int skip_atoi(const char **s) {
	int i = 0;

	while (is_digit(**s))
		i = i * 10 + *((*s)++) - '0';
    1c72:	83 c7 01             	add    $0x1,%edi
    1c75:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
    1c78:	0f be c0             	movsbl %al,%eax
    1c7b:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
#define is_digit(c)	((c) >= '0' && (c) <= '9')

static int skip_atoi(const char **s) {
	int i = 0;

	while (is_digit(**s))
    1c7f:	0f b6 07             	movzbl (%edi),%eax
    1c82:	8d 58 d0             	lea    -0x30(%eax),%ebx
    1c85:	80 fb 09             	cmp    $0x9,%bl
    1c88:	76 e8                	jbe    1c72 <vsprintf+0xd2>
    1c8a:	eb 16                	jmp    1ca2 <vsprintf+0x102>
				flags |= LEFT;
			}
		}

		/* get the precision */
		precision = -1;
    1c8c:	b9 ff ff ff ff       	mov    $0xffffffff,%ecx
		if (*fmt == '.') {
			++fmt;
			if (is_digit(*fmt))
				precision = skip_atoi(&fmt);
			else if (*fmt == '*') {
    1c91:	3c 2a                	cmp    $0x2a,%al
    1c93:	75 0d                	jne    1ca2 <vsprintf+0x102>
				/* it's the next argument */
				precision = va_arg(args, int);
    1c95:	8b 44 24 24          	mov    0x24(%esp),%eax
    1c99:	8b 08                	mov    (%eax),%ecx
    1c9b:	8d 40 04             	lea    0x4(%eax),%eax
    1c9e:	89 44 24 24          	mov    %eax,0x24(%esp)
    1ca2:	85 c9                	test   %ecx,%ecx
    1ca4:	b8 00 00 00 00       	mov    $0x0,%eax
    1ca9:	0f 48 c8             	cmovs  %eax,%ecx
    1cac:	89 0c 24             	mov    %ecx,(%esp)
    1caf:	89 fb                	mov    %edi,%ebx
				precision = 0;
		}

		/* get the conversion qualifier */
		qualifier = -1;
		if (*fmt == 'h' || *fmt == 'l' || *fmt == 'L') {
    1cb1:	0f b6 03             	movzbl (%ebx),%eax
    1cb4:	89 c1                	mov    %eax,%ecx
    1cb6:	83 e1 df             	and    $0xffffffdf,%ecx
    1cb9:	80 f9 4c             	cmp    $0x4c,%cl
    1cbc:	74 04                	je     1cc2 <vsprintf+0x122>
    1cbe:	3c 68                	cmp    $0x68,%al
    1cc0:	75 03                	jne    1cc5 <vsprintf+0x125>
			qualifier = *fmt;
			++fmt;
    1cc2:	83 c3 01             	add    $0x1,%ebx
		}

		switch (*fmt) {
    1cc5:	0f b6 0b             	movzbl (%ebx),%ecx
    1cc8:	8d 41 a8             	lea    -0x58(%ecx),%eax
    1ccb:	3c 20                	cmp    $0x20,%al
    1ccd:	0f 87 f4 01 00 00    	ja     1ec7 <vsprintf+0x327>
    1cd3:	0f b6 c0             	movzbl %al,%eax
    1cd6:	ff 24 85 44 00 00 00 	jmp    *0x44(,%eax,4)
		case 'c':
			if (!(flags & LEFT))
    1cdd:	f7 c6 10 00 00 00    	test   $0x10,%esi
    1ce3:	75 21                	jne    1d06 <vsprintf+0x166>
				while (--field_width > 0)
    1ce5:	8d 42 ff             	lea    -0x1(%edx),%eax
    1ce8:	85 c0                	test   %eax,%eax
    1cea:	7e 18                	jle    1d04 <vsprintf+0x164>
    1cec:	8d 44 15 ff          	lea    -0x1(%ebp,%edx,1),%eax
					*str++ = ' ';
    1cf0:	83 c5 01             	add    $0x1,%ebp
    1cf3:	c6 45 ff 20          	movb   $0x20,-0x1(%ebp)
		}

		switch (*fmt) {
		case 'c':
			if (!(flags & LEFT))
				while (--field_width > 0)
    1cf7:	39 c5                	cmp    %eax,%ebp
    1cf9:	75 f5                	jne    1cf0 <vsprintf+0x150>
    1cfb:	ba 00 00 00 00       	mov    $0x0,%edx
					*str++ = ' ';
    1d00:	89 c5                	mov    %eax,%ebp
    1d02:	eb 02                	jmp    1d06 <vsprintf+0x166>
		}

		switch (*fmt) {
		case 'c':
			if (!(flags & LEFT))
				while (--field_width > 0)
    1d04:	89 c2                	mov    %eax,%edx
					*str++ = ' ';
			*str++ = (unsigned char) va_arg(args, int);
    1d06:	8b 44 24 24          	mov    0x24(%esp),%eax
    1d0a:	8d 70 04             	lea    0x4(%eax),%esi
    1d0d:	8d 4d 01             	lea    0x1(%ebp),%ecx
    1d10:	8b 00                	mov    (%eax),%eax
    1d12:	88 45 00             	mov    %al,0x0(%ebp)
			while (--field_width > 0)
    1d15:	8d 42 ff             	lea    -0x1(%edx),%eax
    1d18:	85 c0                	test   %eax,%eax
    1d1a:	0f 8e cb 01 00 00    	jle    1eeb <vsprintf+0x34b>
    1d20:	89 d7                	mov    %edx,%edi
    1d22:	01 ea                	add    %ebp,%edx
    1d24:	89 c8                	mov    %ecx,%eax
				*str++ = ' ';
    1d26:	83 c0 01             	add    $0x1,%eax
    1d29:	c6 40 ff 20          	movb   $0x20,-0x1(%eax)
		case 'c':
			if (!(flags & LEFT))
				while (--field_width > 0)
					*str++ = ' ';
			*str++ = (unsigned char) va_arg(args, int);
			while (--field_width > 0)
    1d2d:	39 d0                	cmp    %edx,%eax
    1d2f:	75 f5                	jne    1d26 <vsprintf+0x186>
    1d31:	8d 6c 39 ff          	lea    -0x1(%ecx,%edi,1),%ebp
		switch (*fmt) {
		case 'c':
			if (!(flags & LEFT))
				while (--field_width > 0)
					*str++ = ' ';
			*str++ = (unsigned char) va_arg(args, int);
    1d35:	89 74 24 24          	mov    %esi,0x24(%esp)
    1d39:	e9 bf 01 00 00       	jmp    1efd <vsprintf+0x35d>
			while (--field_width > 0)
				*str++ = ' ';
			break;

		case 's':
			s = va_arg(args, char *);
    1d3e:	8b 44 24 24          	mov    0x24(%esp),%eax
    1d42:	83 c0 04             	add    $0x4,%eax
    1d45:	89 44 24 04          	mov    %eax,0x4(%esp)
    1d49:	8b 44 24 24          	mov    0x24(%esp),%eax
    1d4d:	8b 38                	mov    (%eax),%edi
}

static inline int strlen(const char * s)
{
register int __res __asm__("cx");
__asm__("cld\n\t"
    1d4f:	b9 ff ff ff ff       	mov    $0xffffffff,%ecx
    1d54:	b8 00 00 00 00       	mov    $0x0,%eax
    1d59:	fc                   	cld    
    1d5a:	f2 ae                	repnz scas %es:(%edi),%al
    1d5c:	f7 d1                	not    %ecx
    1d5e:	49                   	dec    %ecx
			len = strlen(s);
			s-=(len+1);
    1d5f:	89 c8                	mov    %ecx,%eax
    1d61:	f7 d0                	not    %eax
    1d63:	01 c7                	add    %eax,%edi
			if (precision < 0)
				precision = len;
			else if (len > precision)
    1d65:	8b 04 24             	mov    (%esp),%eax
    1d68:	85 c0                	test   %eax,%eax
    1d6a:	78 0b                	js     1d77 <vsprintf+0x1d7>
    1d6c:	39 c8                	cmp    %ecx,%eax
    1d6e:	0f 9c c0             	setl   %al
				len = precision;
    1d71:	84 c0                	test   %al,%al
    1d73:	0f 45 0c 24          	cmovne (%esp),%ecx

			if (!(flags & LEFT))
    1d77:	f7 c6 10 00 00 00    	test   $0x10,%esi
    1d7d:	75 23                	jne    1da2 <vsprintf+0x202>
				while (len < field_width--)
    1d7f:	8d 42 ff             	lea    -0x1(%edx),%eax
    1d82:	39 d1                	cmp    %edx,%ecx
    1d84:	7d 1a                	jge    1da0 <vsprintf+0x200>
    1d86:	89 ce                	mov    %ecx,%esi
    1d88:	29 ca                	sub    %ecx,%edx
    1d8a:	8d 44 15 00          	lea    0x0(%ebp,%edx,1),%eax
					*str++ = ' ';
    1d8e:	83 c5 01             	add    $0x1,%ebp
    1d91:	c6 45 ff 20          	movb   $0x20,-0x1(%ebp)
				precision = len;
			else if (len > precision)
				len = precision;

			if (!(flags & LEFT))
				while (len < field_width--)
    1d95:	39 c5                	cmp    %eax,%ebp
    1d97:	75 f5                	jne    1d8e <vsprintf+0x1ee>
    1d99:	8d 56 ff             	lea    -0x1(%esi),%edx
					*str++ = ' ';
    1d9c:	89 c5                	mov    %eax,%ebp
    1d9e:	eb 02                	jmp    1da2 <vsprintf+0x202>
				precision = len;
			else if (len > precision)
				len = precision;

			if (!(flags & LEFT))
				while (len < field_width--)
    1da0:	89 c2                	mov    %eax,%edx
					*str++ = ' ';
			for (i = 0; i < len; ++i)
    1da2:	85 c9                	test   %ecx,%ecx
    1da4:	7e 1e                	jle    1dc4 <vsprintf+0x224>
    1da6:	b8 00 00 00 00       	mov    $0x0,%eax
    1dab:	89 d6                	mov    %edx,%esi
				*str++ = *s++;
    1dad:	0f b6 14 07          	movzbl (%edi,%eax,1),%edx
    1db1:	88 54 05 00          	mov    %dl,0x0(%ebp,%eax,1)
				len = precision;

			if (!(flags & LEFT))
				while (len < field_width--)
					*str++ = ' ';
			for (i = 0; i < len; ++i)
    1db5:	83 c0 01             	add    $0x1,%eax
    1db8:	39 c1                	cmp    %eax,%ecx
    1dba:	75 f1                	jne    1dad <vsprintf+0x20d>
    1dbc:	89 f2                	mov    %esi,%edx
    1dbe:	8d 44 0d 00          	lea    0x0(%ebp,%ecx,1),%eax
    1dc2:	eb 02                	jmp    1dc6 <vsprintf+0x226>
    1dc4:	89 e8                	mov    %ebp,%eax
				*str++ = *s++;
			while (len < field_width--)
    1dc6:	39 d1                	cmp    %edx,%ecx
    1dc8:	0f 8d 25 01 00 00    	jge    1ef3 <vsprintf+0x353>
    1dce:	29 ca                	sub    %ecx,%edx
    1dd0:	8d 2c 10             	lea    (%eax,%edx,1),%ebp
				*str++ = ' ';
    1dd3:	83 c0 01             	add    $0x1,%eax
    1dd6:	c6 40 ff 20          	movb   $0x20,-0x1(%eax)
			if (!(flags & LEFT))
				while (len < field_width--)
					*str++ = ' ';
			for (i = 0; i < len; ++i)
				*str++ = *s++;
			while (len < field_width--)
    1dda:	39 c5                	cmp    %eax,%ebp
    1ddc:	75 f5                	jne    1dd3 <vsprintf+0x233>
			while (--field_width > 0)
				*str++ = ' ';
			break;

		case 's':
			s = va_arg(args, char *);
    1dde:	8b 44 24 04          	mov    0x4(%esp),%eax
    1de2:	89 44 24 24          	mov    %eax,0x24(%esp)
    1de6:	e9 12 01 00 00       	jmp    1efd <vsprintf+0x35d>
			while (len < field_width--)
				*str++ = ' ';
			break;

		case 'o':
			str = number(str, va_arg(args, unsigned long), 8, field_width,
    1deb:	8b 44 24 24          	mov    0x24(%esp),%eax
    1def:	8d 78 04             	lea    0x4(%eax),%edi
    1df2:	56                   	push   %esi
    1df3:	ff 74 24 04          	pushl  0x4(%esp)
    1df7:	52                   	push   %edx
    1df8:	b9 08 00 00 00       	mov    $0x8,%ecx
    1dfd:	8b 44 24 30          	mov    0x30(%esp),%eax
    1e01:	8b 10                	mov    (%eax),%edx
    1e03:	89 e8                	mov    %ebp,%eax
    1e05:	e8 92 fb ff ff       	call   199c <number>
    1e0a:	89 c5                	mov    %eax,%ebp
					precision, flags);
			break;
    1e0c:	83 c4 0c             	add    $0xc,%esp
			while (len < field_width--)
				*str++ = ' ';
			break;

		case 'o':
			str = number(str, va_arg(args, unsigned long), 8, field_width,
    1e0f:	89 7c 24 24          	mov    %edi,0x24(%esp)
					precision, flags);
			break;
    1e13:	e9 e5 00 00 00       	jmp    1efd <vsprintf+0x35d>

		case 'p':
			if (field_width == -1) {
    1e18:	83 fa ff             	cmp    $0xffffffff,%edx
    1e1b:	75 08                	jne    1e25 <vsprintf+0x285>
				field_width = 8;
				flags |= ZEROPAD;
    1e1d:	83 ce 01             	or     $0x1,%esi
					precision, flags);
			break;

		case 'p':
			if (field_width == -1) {
				field_width = 8;
    1e20:	ba 08 00 00 00       	mov    $0x8,%edx
				flags |= ZEROPAD;
			}
			str = number(str, (unsigned long) va_arg(args, void *), 16,
    1e25:	8b 44 24 24          	mov    0x24(%esp),%eax
    1e29:	8d 78 04             	lea    0x4(%eax),%edi
    1e2c:	56                   	push   %esi
    1e2d:	ff 74 24 04          	pushl  0x4(%esp)
    1e31:	52                   	push   %edx
    1e32:	b9 10 00 00 00       	mov    $0x10,%ecx
    1e37:	8b 44 24 30          	mov    0x30(%esp),%eax
    1e3b:	8b 10                	mov    (%eax),%edx
    1e3d:	89 e8                	mov    %ebp,%eax
    1e3f:	e8 58 fb ff ff       	call   199c <number>
    1e44:	89 c5                	mov    %eax,%ebp
					field_width, precision, flags);
			break;
    1e46:	83 c4 0c             	add    $0xc,%esp
		case 'p':
			if (field_width == -1) {
				field_width = 8;
				flags |= ZEROPAD;
			}
			str = number(str, (unsigned long) va_arg(args, void *), 16,
    1e49:	89 7c 24 24          	mov    %edi,0x24(%esp)
					field_width, precision, flags);
			break;
    1e4d:	e9 ab 00 00 00       	jmp    1efd <vsprintf+0x35d>

		case 'x':
			flags |= SMALL;
    1e52:	83 ce 40             	or     $0x40,%esi
		case 'X':
			str = number(str, va_arg(args, unsigned long), 16, field_width,
    1e55:	8b 44 24 24          	mov    0x24(%esp),%eax
    1e59:	8d 78 04             	lea    0x4(%eax),%edi
    1e5c:	56                   	push   %esi
    1e5d:	ff 74 24 04          	pushl  0x4(%esp)
    1e61:	52                   	push   %edx
    1e62:	b9 10 00 00 00       	mov    $0x10,%ecx
    1e67:	8b 44 24 30          	mov    0x30(%esp),%eax
    1e6b:	8b 10                	mov    (%eax),%edx
    1e6d:	89 e8                	mov    %ebp,%eax
    1e6f:	e8 28 fb ff ff       	call   199c <number>
    1e74:	89 c5                	mov    %eax,%ebp
					precision, flags);
			break;
    1e76:	83 c4 0c             	add    $0xc,%esp
			break;

		case 'x':
			flags |= SMALL;
		case 'X':
			str = number(str, va_arg(args, unsigned long), 16, field_width,
    1e79:	89 7c 24 24          	mov    %edi,0x24(%esp)
					precision, flags);
			break;
    1e7d:	eb 7e                	jmp    1efd <vsprintf+0x35d>

		case 'd':
		case 'i':
			flags |= SIGN;
    1e7f:	83 ce 02             	or     $0x2,%esi
		case 'u':
			str = number(str, va_arg(args, unsigned long), 10, field_width,
    1e82:	8b 44 24 24          	mov    0x24(%esp),%eax
    1e86:	8d 78 04             	lea    0x4(%eax),%edi
    1e89:	56                   	push   %esi
    1e8a:	ff 74 24 04          	pushl  0x4(%esp)
    1e8e:	52                   	push   %edx
    1e8f:	b9 0a 00 00 00       	mov    $0xa,%ecx
    1e94:	8b 44 24 30          	mov    0x30(%esp),%eax
    1e98:	8b 10                	mov    (%eax),%edx
    1e9a:	89 e8                	mov    %ebp,%eax
    1e9c:	e8 fb fa ff ff       	call   199c <number>
    1ea1:	89 c5                	mov    %eax,%ebp
					precision, flags);
			break;
    1ea3:	83 c4 0c             	add    $0xc,%esp

		case 'd':
		case 'i':
			flags |= SIGN;
		case 'u':
			str = number(str, va_arg(args, unsigned long), 10, field_width,
    1ea6:	89 7c 24 24          	mov    %edi,0x24(%esp)
					precision, flags);
			break;
    1eaa:	eb 51                	jmp    1efd <vsprintf+0x35d>

		case 'n':
			ip = va_arg(args, int *);
    1eac:	8b 44 24 24          	mov    0x24(%esp),%eax
    1eb0:	8b 00                	mov    (%eax),%eax
			*ip = (str - buf);
    1eb2:	89 ea                	mov    %ebp,%edx
    1eb4:	2b 54 24 1c          	sub    0x1c(%esp),%edx
    1eb8:	89 10                	mov    %edx,(%eax)
			str = number(str, va_arg(args, unsigned long), 10, field_width,
					precision, flags);
			break;

		case 'n':
			ip = va_arg(args, int *);
    1eba:	8b 44 24 24          	mov    0x24(%esp),%eax
    1ebe:	8d 40 04             	lea    0x4(%eax),%eax
    1ec1:	89 44 24 24          	mov    %eax,0x24(%esp)
			*ip = (str - buf);
			break;
    1ec5:	eb 36                	jmp    1efd <vsprintf+0x35d>

		default:
			if (*fmt != '%')
    1ec7:	80 f9 25             	cmp    $0x25,%cl
    1eca:	74 10                	je     1edc <vsprintf+0x33c>
				*str++ = '%';
    1ecc:	8d 45 01             	lea    0x1(%ebp),%eax
    1ecf:	c6 45 00 25          	movb   $0x25,0x0(%ebp)
			if (*fmt)
    1ed3:	0f b6 0b             	movzbl (%ebx),%ecx
    1ed6:	84 c9                	test   %cl,%cl
    1ed8:	74 0a                	je     1ee4 <vsprintf+0x344>
			*ip = (str - buf);
			break;

		default:
			if (*fmt != '%')
				*str++ = '%';
    1eda:	89 c5                	mov    %eax,%ebp
			if (*fmt)
				*str++ = *fmt;
    1edc:	88 4d 00             	mov    %cl,0x0(%ebp)
    1edf:	8d 6d 01             	lea    0x1(%ebp),%ebp
    1ee2:	eb 19                	jmp    1efd <vsprintf+0x35d>
			else
				--fmt;
    1ee4:	83 eb 01             	sub    $0x1,%ebx
			*ip = (str - buf);
			break;

		default:
			if (*fmt != '%')
				*str++ = '%';
    1ee7:	89 c5                	mov    %eax,%ebp
    1ee9:	eb 12                	jmp    1efd <vsprintf+0x35d>
		switch (*fmt) {
		case 'c':
			if (!(flags & LEFT))
				while (--field_width > 0)
					*str++ = ' ';
			*str++ = (unsigned char) va_arg(args, int);
    1eeb:	89 cd                	mov    %ecx,%ebp
    1eed:	89 74 24 24          	mov    %esi,0x24(%esp)
    1ef1:	eb 0a                	jmp    1efd <vsprintf+0x35d>
			if (!(flags & LEFT))
				while (len < field_width--)
					*str++ = ' ';
			for (i = 0; i < len; ++i)
				*str++ = *s++;
			while (len < field_width--)
    1ef3:	89 c5                	mov    %eax,%ebp
			while (--field_width > 0)
				*str++ = ' ';
			break;

		case 's':
			s = va_arg(args, char *);
    1ef5:	8b 44 24 04          	mov    0x4(%esp),%eax
    1ef9:	89 44 24 24          	mov    %eax,0x24(%esp)
	int field_width; /* width of output field */
	int precision; /* min. # of digits for integers; max
	 number of chars for from string */
	int qualifier; /* 'h', 'l', or 'L' for integer fields */

	for (str = buf; *fmt; ++fmt) {
    1efd:	8d 43 01             	lea    0x1(%ebx),%eax
    1f00:	0f b6 53 01          	movzbl 0x1(%ebx),%edx
    1f04:	84 d2                	test   %dl,%dl
    1f06:	0f 85 ae fc ff ff    	jne    1bba <vsprintf+0x1a>
    1f0c:	eb 18                	jmp    1f26 <vsprintf+0x386>
    1f0e:	8b 6c 24 1c          	mov    0x1c(%esp),%ebp
    1f12:	eb 12                	jmp    1f26 <vsprintf+0x386>
			continue;
		}

		/* process flags */
		flags = 0;
		repeat: ++fmt; /* this also skips first '%' */
    1f14:	89 c3                	mov    %eax,%ebx
    1f16:	89 4c 24 24          	mov    %ecx,0x24(%esp)
				flags |= LEFT;
			}
		}

		/* get the precision */
		precision = -1;
    1f1a:	c7 04 24 ff ff ff ff 	movl   $0xffffffff,(%esp)
    1f21:	e9 8b fd ff ff       	jmp    1cb1 <vsprintf+0x111>
			else
				--fmt;
			break;
		}
	}
	*str = '\0';
    1f26:	c6 45 00 00          	movb   $0x0,0x0(%ebp)
	return str - buf;
    1f2a:	89 e8                	mov    %ebp,%eax
    1f2c:	2b 44 24 1c          	sub    0x1c(%esp),%eax
}
    1f30:	83 c4 08             	add    $0x8,%esp
    1f33:	5b                   	pop    %ebx
    1f34:	5e                   	pop    %esi
    1f35:	5f                   	pop    %edi
    1f36:	5d                   	pop    %ebp
    1f37:	c3                   	ret    

00001f38 <sys_ftime>:
#include <sys/utsname.h>

int sys_ftime()
{
	return -ENOSYS;
}
    1f38:	b8 da ff ff ff       	mov    $0xffffffda,%eax
    1f3d:	c3                   	ret    

00001f3e <sys_break>:

int sys_break()
{
	return -ENOSYS;
}
    1f3e:	b8 da ff ff ff       	mov    $0xffffffda,%eax
    1f43:	c3                   	ret    

00001f44 <sys_ptrace>:

int sys_ptrace()
{
	return -ENOSYS;
}
    1f44:	b8 da ff ff ff       	mov    $0xffffffda,%eax
    1f49:	c3                   	ret    

00001f4a <sys_stty>:

int sys_stty()
{
	return -ENOSYS;
}
    1f4a:	b8 da ff ff ff       	mov    $0xffffffda,%eax
    1f4f:	c3                   	ret    

00001f50 <sys_gtty>:

int sys_gtty()
{
	return -ENOSYS;
}
    1f50:	b8 da ff ff ff       	mov    $0xffffffda,%eax
    1f55:	c3                   	ret    

00001f56 <sys_rename>:

int sys_rename()
{
	return -ENOSYS;
}
    1f56:	b8 da ff ff ff       	mov    $0xffffffda,%eax
    1f5b:	c3                   	ret    

00001f5c <sys_prof>:

int sys_prof()
{
	return -ENOSYS;
}
    1f5c:	b8 da ff ff ff       	mov    $0xffffffda,%eax
    1f61:	c3                   	ret    

00001f62 <sys_setregid>:

int sys_setregid(int rgid, int egid)
{
    1f62:	57                   	push   %edi
    1f63:	56                   	push   %esi
    1f64:	53                   	push   %ebx
    1f65:	8b 7c 24 10          	mov    0x10(%esp),%edi
    1f69:	8b 74 24 14          	mov    0x14(%esp),%esi
	struct task_struct* current = get_current_task();
    1f6d:	e8 fc ff ff ff       	call   1f6e <sys_setregid+0xc>
    1f72:	89 c3                	mov    %eax,%ebx
	if (rgid>0) {
    1f74:	85 ff                	test   %edi,%edi
    1f76:	7e 21                	jle    1f99 <sys_setregid+0x37>
		if ((current->gid == rgid) || 
    1f78:	0f b7 80 46 02 00 00 	movzwl 0x246(%eax),%eax
    1f7f:	39 c7                	cmp    %eax,%edi
    1f81:	74 0f                	je     1f92 <sys_setregid+0x30>
		    suser())
    1f83:	e8 fc ff ff ff       	call   1f84 <sys_setregid+0x22>

int sys_setregid(int rgid, int egid)
{
	struct task_struct* current = get_current_task();
	if (rgid>0) {
		if ((current->gid == rgid) || 
    1f88:	66 83 b8 42 02 00 00 	cmpw   $0x0,0x242(%eax)
    1f8f:	00 
    1f90:	75 49                	jne    1fdb <sys_setregid+0x79>
		    suser())
			current->gid = rgid;
    1f92:	66 89 bb 46 02 00 00 	mov    %di,0x246(%ebx)
		else
			return(-EPERM);
	}
	if (egid>0) {
    1f99:	85 f6                	test   %esi,%esi
    1f9b:	7e 45                	jle    1fe2 <sys_setregid+0x80>
		if ((current->gid == egid) ||
    1f9d:	0f b7 83 46 02 00 00 	movzwl 0x246(%ebx),%eax
    1fa4:	39 c6                	cmp    %eax,%esi
    1fa6:	74 25                	je     1fcd <sys_setregid+0x6b>
    1fa8:	0f b7 83 48 02 00 00 	movzwl 0x248(%ebx),%eax
    1faf:	39 c6                	cmp    %eax,%esi
    1fb1:	74 1a                	je     1fcd <sys_setregid+0x6b>
		    (current->egid == egid) ||
    1fb3:	0f b7 83 4a 02 00 00 	movzwl 0x24a(%ebx),%eax
    1fba:	39 c6                	cmp    %eax,%esi
    1fbc:	74 0f                	je     1fcd <sys_setregid+0x6b>
		    (current->sgid == egid) ||
		    suser())
    1fbe:	e8 fc ff ff ff       	call   1fbf <sys_setregid+0x5d>
			return(-EPERM);
	}
	if (egid>0) {
		if ((current->gid == egid) ||
		    (current->egid == egid) ||
		    (current->sgid == egid) ||
    1fc3:	66 83 b8 42 02 00 00 	cmpw   $0x0,0x242(%eax)
    1fca:	00 
    1fcb:	75 1c                	jne    1fe9 <sys_setregid+0x87>
		    suser())
			current->egid = egid;
    1fcd:	66 89 b3 48 02 00 00 	mov    %si,0x248(%ebx)
		else
			return(-EPERM);
	}
	return 0;
    1fd4:	b8 00 00 00 00       	mov    $0x0,%eax
	if (egid>0) {
		if ((current->gid == egid) ||
		    (current->egid == egid) ||
		    (current->sgid == egid) ||
		    suser())
			current->egid = egid;
    1fd9:	eb 13                	jmp    1fee <sys_setregid+0x8c>
	if (rgid>0) {
		if ((current->gid == rgid) || 
		    suser())
			current->gid = rgid;
		else
			return(-EPERM);
    1fdb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    1fe0:	eb 0c                	jmp    1fee <sys_setregid+0x8c>
		    suser())
			current->egid = egid;
		else
			return(-EPERM);
	}
	return 0;
    1fe2:	b8 00 00 00 00       	mov    $0x0,%eax
    1fe7:	eb 05                	jmp    1fee <sys_setregid+0x8c>
		    (current->egid == egid) ||
		    (current->sgid == egid) ||
		    suser())
			current->egid = egid;
		else
			return(-EPERM);
    1fe9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	}
	return 0;
}
    1fee:	5b                   	pop    %ebx
    1fef:	5e                   	pop    %esi
    1ff0:	5f                   	pop    %edi
    1ff1:	c3                   	ret    

00001ff2 <sys_setgid>:

int sys_setgid(int gid)
{
    1ff2:	83 ec 14             	sub    $0x14,%esp
    1ff5:	8b 44 24 18          	mov    0x18(%esp),%eax
	return(sys_setregid(gid, gid));
    1ff9:	50                   	push   %eax
    1ffa:	50                   	push   %eax
    1ffb:	e8 fc ff ff ff       	call   1ffc <sys_setgid+0xa>
}
    2000:	83 c4 1c             	add    $0x1c,%esp
    2003:	c3                   	ret    

00002004 <sys_acct>:

int sys_acct()
{
	return -ENOSYS;
}
    2004:	b8 da ff ff ff       	mov    $0xffffffda,%eax
    2009:	c3                   	ret    

0000200a <sys_phys>:

int sys_phys()
{
	return -ENOSYS;
}
    200a:	b8 da ff ff ff       	mov    $0xffffffda,%eax
    200f:	c3                   	ret    

00002010 <sys_lock>:

int sys_lock()
{
	return -ENOSYS;
}
    2010:	b8 da ff ff ff       	mov    $0xffffffda,%eax
    2015:	c3                   	ret    

00002016 <sys_mpx>:

int sys_mpx()
{
	return -ENOSYS;
}
    2016:	b8 da ff ff ff       	mov    $0xffffffda,%eax
    201b:	c3                   	ret    

0000201c <sys_ulimit>:

int sys_ulimit()
{
	return -ENOSYS;
}
    201c:	b8 da ff ff ff       	mov    $0xffffffda,%eax
    2021:	c3                   	ret    

00002022 <sys_time>:

int sys_time(long * tloc)
{
    2022:	56                   	push   %esi
    2023:	53                   	push   %ebx
    2024:	83 ec 04             	sub    $0x4,%esp
    2027:	8b 74 24 10          	mov    0x10(%esp),%esi
	int i;

	i = CURRENT_TIME;
    202b:	8b 0d 00 00 00 00    	mov    0x0,%ecx
    2031:	ba 67 66 66 66       	mov    $0x66666667,%edx
    2036:	89 c8                	mov    %ecx,%eax
    2038:	f7 ea                	imul   %edx
    203a:	c1 fa 02             	sar    $0x2,%edx
    203d:	c1 f9 1f             	sar    $0x1f,%ecx
    2040:	29 ca                	sub    %ecx,%edx
    2042:	89 d3                	mov    %edx,%ebx
    2044:	03 1d 00 00 00 00    	add    0x0,%ebx
	if (tloc) {
    204a:	85 f6                	test   %esi,%esi
    204c:	74 11                	je     205f <sys_time+0x3d>
		verify_area(tloc,4);
    204e:	83 ec 08             	sub    $0x8,%esp
    2051:	6a 04                	push   $0x4
    2053:	56                   	push   %esi
    2054:	e8 fc ff ff ff       	call   2055 <sys_time+0x33>
__asm__ ("movw %0,%%fs:%1"::"r" (val),"m" (*addr));
}

static inline void put_fs_long(unsigned long val,unsigned long * addr)
{
__asm__ ("movl %0,%%fs:%1"::"r" (val),"m" (*addr));
    2059:	64 89 1e             	mov    %ebx,%fs:(%esi)
    205c:	83 c4 10             	add    $0x10,%esp
		put_fs_long(i,(unsigned long *)tloc);
	}
	return i;
}
    205f:	89 d8                	mov    %ebx,%eax
    2061:	83 c4 04             	add    $0x4,%esp
    2064:	5b                   	pop    %ebx
    2065:	5e                   	pop    %esi
    2066:	c3                   	ret    

00002067 <sys_setreuid>:
/*
 * Unprivileged users may change the real user id to the effective uid
 * or vice versa.
 */
int sys_setreuid(int ruid, int euid)
{
    2067:	55                   	push   %ebp
    2068:	57                   	push   %edi
    2069:	56                   	push   %esi
    206a:	53                   	push   %ebx
    206b:	83 ec 0c             	sub    $0xc,%esp
    206e:	8b 74 24 24          	mov    0x24(%esp),%esi
	struct task_struct* current = get_current_task();
    2072:	e8 fc ff ff ff       	call   2073 <sys_setreuid+0xc>
    2077:	89 c3                	mov    %eax,%ebx
	int old_ruid = current->uid;
    2079:	0f b7 a8 40 02 00 00 	movzwl 0x240(%eax),%ebp
    2080:	0f b7 fd             	movzwl %bp,%edi
	
	if (ruid>0) {
    2083:	83 7c 24 20 00       	cmpl   $0x0,0x20(%esp)
    2088:	7e 2e                	jle    20b8 <sys_setreuid+0x51>
		if ((current->euid==ruid) ||
    208a:	0f b7 80 42 02 00 00 	movzwl 0x242(%eax),%eax
    2091:	3b 44 24 20          	cmp    0x20(%esp),%eax
    2095:	74 15                	je     20ac <sys_setreuid+0x45>
    2097:	3b 7c 24 20          	cmp    0x20(%esp),%edi
    209b:	74 0f                	je     20ac <sys_setreuid+0x45>
                    (old_ruid == ruid) ||
		    suser())
    209d:	e8 fc ff ff ff       	call   209e <sys_setreuid+0x37>
	struct task_struct* current = get_current_task();
	int old_ruid = current->uid;
	
	if (ruid>0) {
		if ((current->euid==ruid) ||
                    (old_ruid == ruid) ||
    20a2:	66 83 b8 42 02 00 00 	cmpw   $0x0,0x242(%eax)
    20a9:	00 
    20aa:	75 4a                	jne    20f6 <sys_setreuid+0x8f>
		    suser())
			current->uid = ruid;
    20ac:	0f b7 44 24 20       	movzwl 0x20(%esp),%eax
    20b1:	66 89 83 40 02 00 00 	mov    %ax,0x240(%ebx)
		else
			return(-EPERM);
	}
	if (euid>0) {
    20b8:	85 f6                	test   %esi,%esi
    20ba:	7e 41                	jle    20fd <sys_setreuid+0x96>
		if ((old_ruid == euid) ||
    20bc:	39 f7                	cmp    %esi,%edi
    20be:	74 1a                	je     20da <sys_setreuid+0x73>
    20c0:	0f b7 83 42 02 00 00 	movzwl 0x242(%ebx),%eax
    20c7:	39 c6                	cmp    %eax,%esi
    20c9:	74 0f                	je     20da <sys_setreuid+0x73>
                    (current->euid == euid) ||
		    suser())
    20cb:	e8 fc ff ff ff       	call   20cc <sys_setreuid+0x65>
		else
			return(-EPERM);
	}
	if (euid>0) {
		if ((old_ruid == euid) ||
                    (current->euid == euid) ||
    20d0:	66 83 b8 42 02 00 00 	cmpw   $0x0,0x242(%eax)
    20d7:	00 
    20d8:	75 0e                	jne    20e8 <sys_setreuid+0x81>
		    suser())
			current->euid = euid;
    20da:	66 89 b3 42 02 00 00 	mov    %si,0x242(%ebx)
		else {
			current->uid = old_ruid;
			return(-EPERM);
		}
	}
	return 0;
    20e1:	b8 00 00 00 00       	mov    $0x0,%eax
	}
	if (euid>0) {
		if ((old_ruid == euid) ||
                    (current->euid == euid) ||
		    suser())
			current->euid = euid;
    20e6:	eb 1a                	jmp    2102 <sys_setreuid+0x9b>
		else {
			current->uid = old_ruid;
    20e8:	66 89 ab 40 02 00 00 	mov    %bp,0x240(%ebx)
			return(-EPERM);
    20ef:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    20f4:	eb 0c                	jmp    2102 <sys_setreuid+0x9b>
		if ((current->euid==ruid) ||
                    (old_ruid == ruid) ||
		    suser())
			current->uid = ruid;
		else
			return(-EPERM);
    20f6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    20fb:	eb 05                	jmp    2102 <sys_setreuid+0x9b>
		else {
			current->uid = old_ruid;
			return(-EPERM);
		}
	}
	return 0;
    20fd:	b8 00 00 00 00       	mov    $0x0,%eax
}
    2102:	83 c4 0c             	add    $0xc,%esp
    2105:	5b                   	pop    %ebx
    2106:	5e                   	pop    %esi
    2107:	5f                   	pop    %edi
    2108:	5d                   	pop    %ebp
    2109:	c3                   	ret    

0000210a <sys_setuid>:

int sys_setuid(int uid)
{
    210a:	83 ec 14             	sub    $0x14,%esp
    210d:	8b 44 24 18          	mov    0x18(%esp),%eax
	return(sys_setreuid(uid, uid));
    2111:	50                   	push   %eax
    2112:	50                   	push   %eax
    2113:	e8 fc ff ff ff       	call   2114 <sys_setuid+0xa>
}
    2118:	83 c4 1c             	add    $0x1c,%esp
    211b:	c3                   	ret    

0000211c <sys_stime>:

int sys_stime(long * tptr)
{
    211c:	53                   	push   %ebx
    211d:	83 ec 08             	sub    $0x8,%esp
	if (!suser())
    2120:	e8 fc ff ff ff       	call   2121 <sys_stime+0x5>
    2125:	66 83 b8 42 02 00 00 	cmpw   $0x0,0x242(%eax)
    212c:	00 
    212d:	75 2d                	jne    215c <sys_stime+0x40>

static inline unsigned long get_fs_long(const unsigned long *addr)
{
	unsigned long _v;

	__asm__ ("movl %%fs:%1,%0":"=r" (_v):"m" (*addr)); \
    212f:	8b 44 24 10          	mov    0x10(%esp),%eax
    2133:	64 8b 08             	mov    %fs:(%eax),%ecx
		return -EPERM;
	startup_time = get_fs_long((unsigned long *)tptr) - jiffies/HZ;
    2136:	8b 1d 00 00 00 00    	mov    0x0,%ebx
    213c:	ba 67 66 66 66       	mov    $0x66666667,%edx
    2141:	89 d8                	mov    %ebx,%eax
    2143:	f7 ea                	imul   %edx
    2145:	c1 fa 02             	sar    $0x2,%edx
    2148:	c1 fb 1f             	sar    $0x1f,%ebx
    214b:	29 da                	sub    %ebx,%edx
    214d:	29 d1                	sub    %edx,%ecx
    214f:	89 0d 00 00 00 00    	mov    %ecx,0x0
	return 0;
    2155:	b8 00 00 00 00       	mov    $0x0,%eax
    215a:	eb 05                	jmp    2161 <sys_stime+0x45>
}

int sys_stime(long * tptr)
{
	if (!suser())
		return -EPERM;
    215c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	startup_time = get_fs_long((unsigned long *)tptr) - jiffies/HZ;
	return 0;
}
    2161:	83 c4 08             	add    $0x8,%esp
    2164:	5b                   	pop    %ebx
    2165:	c3                   	ret    

00002166 <sys_times>:

int sys_times(struct tms * tbuf)
{
    2166:	56                   	push   %esi
    2167:	53                   	push   %ebx
    2168:	83 ec 04             	sub    $0x4,%esp
    216b:	8b 5c 24 10          	mov    0x10(%esp),%ebx
	if (tbuf) {
    216f:	85 db                	test   %ebx,%ebx
    2171:	74 3c                	je     21af <sys_times+0x49>
		struct task_struct* current = get_current_task();
    2173:	e8 fc ff ff ff       	call   2174 <sys_times+0xe>
    2178:	89 c6                	mov    %eax,%esi
		verify_area(tbuf,sizeof *tbuf);
    217a:	83 ec 08             	sub    $0x8,%esp
    217d:	6a 10                	push   $0x10
    217f:	53                   	push   %ebx
    2180:	e8 fc ff ff ff       	call   2181 <sys_times+0x1b>
__asm__ ("movw %0,%%fs:%1"::"r" (val),"m" (*addr));
}

static inline void put_fs_long(unsigned long val,unsigned long * addr)
{
__asm__ ("movl %0,%%fs:%1"::"r" (val),"m" (*addr));
    2185:	8b 86 50 02 00 00    	mov    0x250(%esi),%eax
    218b:	64 89 03             	mov    %eax,%fs:(%ebx)
    218e:	8b 86 54 02 00 00    	mov    0x254(%esi),%eax
    2194:	64 89 43 04          	mov    %eax,%fs:0x4(%ebx)
    2198:	8b 86 58 02 00 00    	mov    0x258(%esi),%eax
    219e:	64 89 43 08          	mov    %eax,%fs:0x8(%ebx)
    21a2:	8b 86 5c 02 00 00    	mov    0x25c(%esi),%eax
    21a8:	64 89 43 0c          	mov    %eax,%fs:0xc(%ebx)
    21ac:	83 c4 10             	add    $0x10,%esp
		put_fs_long(current->utime,(unsigned long *)&tbuf->tms_utime);
		put_fs_long(current->stime,(unsigned long *)&tbuf->tms_stime);
		put_fs_long(current->cutime,(unsigned long *)&tbuf->tms_cutime);
		put_fs_long(current->cstime,(unsigned long *)&tbuf->tms_cstime);
	}
	return jiffies;
    21af:	a1 00 00 00 00       	mov    0x0,%eax
}
    21b4:	83 c4 04             	add    $0x4,%esp
    21b7:	5b                   	pop    %ebx
    21b8:	5e                   	pop    %esi
    21b9:	c3                   	ret    

000021ba <sys_brk>:

int sys_brk(unsigned long end_data_seg)
{
    21ba:	53                   	push   %ebx
    21bb:	83 ec 08             	sub    $0x8,%esp
    21be:	8b 5c 24 10          	mov    0x10(%esp),%ebx
	struct task_struct* current = get_current_task();
    21c2:	e8 fc ff ff ff       	call   21c3 <sys_brk+0x9>
	if (end_data_seg >= current->end_code &&
    21c7:	39 98 1c 02 00 00    	cmp    %ebx,0x21c(%eax)
    21cd:	77 16                	ja     21e5 <sys_brk+0x2b>
    21cf:	8b 88 28 02 00 00    	mov    0x228(%eax),%ecx
    21d5:	8d 91 00 c0 ff ff    	lea    -0x4000(%ecx),%edx
    21db:	39 d3                	cmp    %edx,%ebx
    21dd:	73 06                	jae    21e5 <sys_brk+0x2b>
	    end_data_seg < current->start_stack - 16384)
		current->brk = end_data_seg;
    21df:	89 98 24 02 00 00    	mov    %ebx,0x224(%eax)
	return current->brk;
    21e5:	8b 80 24 02 00 00    	mov    0x224(%eax),%eax
}
    21eb:	83 c4 08             	add    $0x8,%esp
    21ee:	5b                   	pop    %ebx
    21ef:	c3                   	ret    

000021f0 <sys_setpgid>:
 * This needs some heave checking ...
 * I just haven't get the stomach for it. I also don't fully
 * understand sessions/pgrp etc. Let somebody who does explain it.
 */
int sys_setpgid(int pid, int pgid)
{
    21f0:	57                   	push   %edi
    21f1:	56                   	push   %esi
    21f2:	53                   	push   %ebx
    21f3:	8b 5c 24 10          	mov    0x10(%esp),%ebx
    21f7:	8b 74 24 14          	mov    0x14(%esp),%esi
	struct task_struct* current = get_current_task();
    21fb:	e8 fc ff ff ff       	call   21fc <sys_setpgid+0xc>
	int i;

	if (!pid)
    2200:	85 db                	test   %ebx,%ebx
    2202:	75 06                	jne    220a <sys_setpgid+0x1a>
		pid = current->pid;
    2204:	8b 98 2c 02 00 00    	mov    0x22c(%eax),%ebx
	if (!pgid)
    220a:	85 f6                	test   %esi,%esi
    220c:	75 06                	jne    2214 <sys_setpgid+0x24>
		pgid = current->pid;
    220e:	8b b0 2c 02 00 00    	mov    0x22c(%eax),%esi
    2214:	ba 00 00 00 00       	mov    $0x0,%edx
    2219:	bf 00 01 00 00       	mov    $0x100,%edi
	for (i=0 ; i<NR_TASKS ; i++)
		if (task[i] && task[i]->pid==pid) {
    221e:	8b 0a                	mov    (%edx),%ecx
    2220:	85 c9                	test   %ecx,%ecx
    2222:	74 2c                	je     2250 <sys_setpgid+0x60>
    2224:	3b 99 2c 02 00 00    	cmp    0x22c(%ecx),%ebx
    222a:	75 24                	jne    2250 <sys_setpgid+0x60>
			if (task[i]->leader)
    222c:	83 b9 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ecx)
    2233:	75 29                	jne    225e <sys_setpgid+0x6e>
				return -EPERM;
			if (task[i]->session != current->session)
    2235:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
    223b:	39 81 38 02 00 00    	cmp    %eax,0x238(%ecx)
    2241:	75 22                	jne    2265 <sys_setpgid+0x75>
				return -EPERM;
			task[i]->pgrp = pgid;
    2243:	89 b1 34 02 00 00    	mov    %esi,0x234(%ecx)
			return 0;
    2249:	b8 00 00 00 00       	mov    $0x0,%eax
    224e:	eb 1a                	jmp    226a <sys_setpgid+0x7a>
    2250:	83 c2 04             	add    $0x4,%edx

	if (!pid)
		pid = current->pid;
	if (!pgid)
		pgid = current->pid;
	for (i=0 ; i<NR_TASKS ; i++)
    2253:	39 fa                	cmp    %edi,%edx
    2255:	75 c7                	jne    221e <sys_setpgid+0x2e>
			if (task[i]->session != current->session)
				return -EPERM;
			task[i]->pgrp = pgid;
			return 0;
		}
	return -ESRCH;
    2257:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
    225c:	eb 0c                	jmp    226a <sys_setpgid+0x7a>
	if (!pgid)
		pgid = current->pid;
	for (i=0 ; i<NR_TASKS ; i++)
		if (task[i] && task[i]->pid==pid) {
			if (task[i]->leader)
				return -EPERM;
    225e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    2263:	eb 05                	jmp    226a <sys_setpgid+0x7a>
			if (task[i]->session != current->session)
				return -EPERM;
    2265:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
			task[i]->pgrp = pgid;
			return 0;
		}
	return -ESRCH;
}
    226a:	5b                   	pop    %ebx
    226b:	5e                   	pop    %esi
    226c:	5f                   	pop    %edi
    226d:	c3                   	ret    

0000226e <sys_getpgrp>:

int sys_getpgrp(void)
{
    226e:	83 ec 0c             	sub    $0xc,%esp
	struct task_struct* current = get_current_task();
    2271:	e8 fc ff ff ff       	call   2272 <sys_getpgrp+0x4>
	return current->pgrp;
    2276:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
}
    227c:	83 c4 0c             	add    $0xc,%esp
    227f:	c3                   	ret    

00002280 <sys_setsid>:

int sys_setsid(void)
{
    2280:	53                   	push   %ebx
    2281:	83 ec 08             	sub    $0x8,%esp
	struct task_struct* current = get_current_task();
    2284:	e8 fc ff ff ff       	call   2285 <sys_setsid+0x5>
    2289:	89 c3                	mov    %eax,%ebx
	if (current->leader && !suser())
    228b:	83 b8 3c 02 00 00 00 	cmpl   $0x0,0x23c(%eax)
    2292:	74 0f                	je     22a3 <sys_setsid+0x23>
    2294:	e8 fc ff ff ff       	call   2295 <sys_setsid+0x15>
    2299:	66 83 b8 42 02 00 00 	cmpw   $0x0,0x242(%eax)
    22a0:	00 
    22a1:	75 28                	jne    22cb <sys_setsid+0x4b>
		return -EPERM;
	current->leader = 1;
    22a3:	c7 83 3c 02 00 00 01 	movl   $0x1,0x23c(%ebx)
    22aa:	00 00 00 
	current->session = current->pgrp = current->pid;
    22ad:	8b 83 2c 02 00 00    	mov    0x22c(%ebx),%eax
    22b3:	89 83 34 02 00 00    	mov    %eax,0x234(%ebx)
    22b9:	89 83 38 02 00 00    	mov    %eax,0x238(%ebx)
	current->tty = -1;
    22bf:	c7 83 68 02 00 00 ff 	movl   $0xffffffff,0x268(%ebx)
    22c6:	ff ff ff 
	//printk("setsid, pid: %d\n\r", current->pid);
	return current->pgrp;
    22c9:	eb 05                	jmp    22d0 <sys_setsid+0x50>

int sys_setsid(void)
{
	struct task_struct* current = get_current_task();
	if (current->leader && !suser())
		return -EPERM;
    22cb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	current->leader = 1;
	current->session = current->pgrp = current->pid;
	current->tty = -1;
	//printk("setsid, pid: %d\n\r", current->pid);
	return current->pgrp;
}
    22d0:	83 c4 08             	add    $0x8,%esp
    22d3:	5b                   	pop    %ebx
    22d4:	c3                   	ret    

000022d5 <sys_uname>:

int sys_uname(struct utsname * name)
{
    22d5:	53                   	push   %ebx
    22d6:	83 ec 08             	sub    $0x8,%esp
    22d9:	8b 5c 24 10          	mov    0x10(%esp),%ebx
	static struct utsname thisname = {
		"linux .0","nodename","release ","version ","machine "
	};
	int i;

	if (!name) return -ERROR;
    22dd:	85 db                	test   %ebx,%ebx
    22df:	74 2d                	je     230e <sys_uname+0x39>
	verify_area(name,sizeof *name);
    22e1:	83 ec 08             	sub    $0x8,%esp
    22e4:	6a 2d                	push   $0x2d
    22e6:	53                   	push   %ebx
    22e7:	e8 fc ff ff ff       	call   22e8 <sys_uname+0x13>
    22ec:	83 c4 10             	add    $0x10,%esp
    22ef:	b8 00 00 00 00       	mov    $0x0,%eax
	return _v;
}

static inline void put_fs_byte(char val,char *addr)
{
__asm__ ("movb %0,%%fs:%1"::"q" (val),"m" (*addr));
    22f4:	0f b6 90 40 3d 00 00 	movzbl 0x3d40(%eax),%edx
    22fb:	64 88 14 03          	mov    %dl,%fs:(%ebx,%eax,1)
	for(i=0;i<sizeof *name;i++)
    22ff:	83 c0 01             	add    $0x1,%eax
    2302:	83 f8 2d             	cmp    $0x2d,%eax
    2305:	75 ed                	jne    22f4 <sys_uname+0x1f>
		put_fs_byte(((char *) &thisname)[i],i+(char *) name);
	return 0;
    2307:	b8 00 00 00 00       	mov    $0x0,%eax
    230c:	eb 05                	jmp    2313 <sys_uname+0x3e>
	static struct utsname thisname = {
		"linux .0","nodename","release ","version ","machine "
	};
	int i;

	if (!name) return -ERROR;
    230e:	b8 9d ff ff ff       	mov    $0xffffff9d,%eax
	verify_area(name,sizeof *name);
	for(i=0;i<sizeof *name;i++)
		put_fs_byte(((char *) &thisname)[i],i+(char *) name);
	return 0;
}
    2313:	83 c4 08             	add    $0x8,%esp
    2316:	5b                   	pop    %ebx
    2317:	c3                   	ret    

00002318 <sys_umask>:

int sys_umask(int mask)
{
    2318:	83 ec 0c             	sub    $0xc,%esp
	struct task_struct* current = get_current_task();
    231b:	e8 fc ff ff ff       	call   231c <sys_umask+0x4>
    2320:	89 c1                	mov    %eax,%ecx
	int old = current->umask;
    2322:	0f b7 80 6c 02 00 00 	movzwl 0x26c(%eax),%eax

	current->umask = mask & 0777;
    2329:	0f b7 54 24 10       	movzwl 0x10(%esp),%edx
    232e:	66 81 e2 ff 01       	and    $0x1ff,%dx
    2333:	66 89 91 6c 02 00 00 	mov    %dx,0x26c(%ecx)
	return (old);
}
    233a:	83 c4 0c             	add    $0xc,%esp
    233d:	c3                   	ret    

0000233e <release>:
extern void ap_default_loop(void);
extern struct apic_info apic_ids[LOGICAL_PROCESSOR_NUM];
extern unsigned long sched_semaphore;

void release(struct task_struct * p)
{
    233e:	56                   	push   %esi
    233f:	53                   	push   %ebx
    2340:	83 ec 04             	sub    $0x4,%esp
    2343:	8b 74 24 10          	mov    0x10(%esp),%esi
	int i;

	if (!p)
    2347:	85 f6                	test   %esi,%esi
    2349:	0f 84 ad 00 00 00    	je     23fc <release+0xbe>
		return;
	for (i=1 ; i<NR_TASKS ; i++)
		if (task[i]==p) {
    234f:	3b 35 04 00 00 00    	cmp    0x4,%esi
    2355:	74 10                	je     2367 <release+0x29>
    2357:	bb 02 00 00 00       	mov    $0x2,%ebx
    235c:	3b 34 9d 00 00 00 00 	cmp    0x0(,%ebx,4),%esi
    2363:	75 7b                	jne    23e0 <release+0xa2>
    2365:	eb 05                	jmp    236c <release+0x2e>
    2367:	bb 01 00 00 00       	mov    $0x1,%ebx
			 *	 AP2释放完该*p,那么有可能被AP3上的进程占用了,此时AP1上在执行如下的代码,就可能会破坏AP3上进程的内存页数据,
			 *	 造成AP3上运行的进程崩溃.
			 *	(*p)->counter = ((*p)->counter >> 1) + (*p)->priority;
			 * }
			 */
			lock_op(&sched_semaphore);
    236c:	83 ec 0c             	sub    $0xc,%esp
    236f:	68 00 00 00 00       	push   $0x0
    2374:	e8 fc ff ff ff       	call   2375 <release+0x37>
			task[i]=NULL;
    2379:	c7 04 9d 00 00 00 00 	movl   $0x0,0x0(,%ebx,4)
    2380:	00 00 00 00 
			if (!free_page((long)(p->tss.cr3)))  /* 先把该进程占用的目录表释放掉 */
    2384:	83 c4 04             	add    $0x4,%esp
    2387:	ff b6 04 03 00 00    	pushl  0x304(%esi)
    238d:	e8 fc ff ff ff       	call   238e <release+0x50>
    2392:	83 c4 10             	add    $0x10,%esp
    2395:	85 c0                	test   %eax,%eax
    2397:	75 10                	jne    23a9 <release+0x6b>
				panic("exit.release dir: trying to free free page");
    2399:	83 ec 0c             	sub    $0xc,%esp
    239c:	68 e4 01 00 00       	push   $0x1e4
    23a1:	e8 fc ff ff ff       	call   23a2 <release+0x64>
    23a6:	83 c4 10             	add    $0x10,%esp
			if (!free_page((long)p))
    23a9:	83 ec 0c             	sub    $0xc,%esp
    23ac:	56                   	push   %esi
    23ad:	e8 fc ff ff ff       	call   23ae <release+0x70>
    23b2:	83 c4 10             	add    $0x10,%esp
    23b5:	85 c0                	test   %eax,%eax
    23b7:	75 10                	jne    23c9 <release+0x8b>
				panic("exit.release: trying to free free page");
    23b9:	83 ec 0c             	sub    $0xc,%esp
    23bc:	68 10 02 00 00       	push   $0x210
    23c1:	e8 fc ff ff ff       	call   23c2 <release+0x84>
    23c6:	83 c4 10             	add    $0x10,%esp
			unlock_op(&sched_semaphore);
    23c9:	83 ec 0c             	sub    $0xc,%esp
    23cc:	68 00 00 00 00       	push   $0x0
    23d1:	e8 fc ff ff ff       	call   23d2 <release+0x94>
			schedule();
    23d6:	e8 fc ff ff ff       	call   23d7 <release+0x99>
			return;
    23db:	83 c4 10             	add    $0x10,%esp
    23de:	eb 1c                	jmp    23fc <release+0xbe>
{
	int i;

	if (!p)
		return;
	for (i=1 ; i<NR_TASKS ; i++)
    23e0:	83 c3 01             	add    $0x1,%ebx
    23e3:	83 fb 40             	cmp    $0x40,%ebx
    23e6:	0f 85 70 ff ff ff    	jne    235c <release+0x1e>
				panic("exit.release: trying to free free page");
			unlock_op(&sched_semaphore);
			schedule();
			return;
		}
	panic("trying to release non-existent task");
    23ec:	83 ec 0c             	sub    $0xc,%esp
    23ef:	68 38 02 00 00       	push   $0x238
    23f4:	e8 fc ff ff ff       	call   23f5 <release+0xb7>
    23f9:	83 c4 10             	add    $0x10,%esp
}
    23fc:	83 c4 04             	add    $0x4,%esp
    23ff:	5b                   	pop    %ebx
    2400:	5e                   	pop    %esi
    2401:	c3                   	ret    

00002402 <send_sig>:

int send_sig(long sig,struct task_struct * p,int priv)
{
    2402:	56                   	push   %esi
    2403:	53                   	push   %ebx
    2404:	83 ec 04             	sub    $0x4,%esp
    2407:	8b 5c 24 10          	mov    0x10(%esp),%ebx
    240b:	8b 74 24 14          	mov    0x14(%esp),%esi
	struct task_struct* current = get_current_task();
    240f:	e8 fc ff ff ff       	call   2410 <send_sig+0xe>
	if (!p || sig<1 || sig>32)
    2414:	8d 53 ff             	lea    -0x1(%ebx),%edx
    2417:	83 fa 1f             	cmp    $0x1f,%edx
    241a:	77 3e                	ja     245a <send_sig+0x58>
    241c:	85 f6                	test   %esi,%esi
    241e:	74 3a                	je     245a <send_sig+0x58>
		return -EINVAL;
	if (priv || (current->euid==p->euid) || suser())
    2420:	83 7c 24 18 00       	cmpl   $0x0,0x18(%esp)
    2425:	75 1f                	jne    2446 <send_sig+0x44>
    2427:	0f b7 8e 42 02 00 00 	movzwl 0x242(%esi),%ecx
    242e:	66 39 88 42 02 00 00 	cmp    %cx,0x242(%eax)
    2435:	74 0f                	je     2446 <send_sig+0x44>
    2437:	e8 fc ff ff ff       	call   2438 <send_sig+0x36>
    243c:	66 83 b8 42 02 00 00 	cmpw   $0x0,0x242(%eax)
    2443:	00 
    2444:	75 1b                	jne    2461 <send_sig+0x5f>
		p->signal |= (1<<(sig-1));
    2446:	8d 4b ff             	lea    -0x1(%ebx),%ecx
    2449:	b8 01 00 00 00       	mov    $0x1,%eax
    244e:	d3 e0                	shl    %cl,%eax
    2450:	09 46 0c             	or     %eax,0xc(%esi)
	else
		return -EPERM;
	return 0;
    2453:	b8 00 00 00 00       	mov    $0x0,%eax
    2458:	eb 0c                	jmp    2466 <send_sig+0x64>

int send_sig(long sig,struct task_struct * p,int priv)
{
	struct task_struct* current = get_current_task();
	if (!p || sig<1 || sig>32)
		return -EINVAL;
    245a:	b8 ea ff ff ff       	mov    $0xffffffea,%eax
    245f:	eb 05                	jmp    2466 <send_sig+0x64>
	if (priv || (current->euid==p->euid) || suser())
		p->signal |= (1<<(sig-1));
	else
		return -EPERM;
    2461:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return 0;
}
    2466:	83 c4 04             	add    $0x4,%esp
    2469:	5b                   	pop    %ebx
    246a:	5e                   	pop    %esi
    246b:	c3                   	ret    

0000246c <kill_session>:

void kill_session(void)
{
    246c:	53                   	push   %ebx
    246d:	83 ec 08             	sub    $0x8,%esp
	struct task_struct* current = get_current_task();
    2470:	e8 fc ff ff ff       	call   2471 <kill_session+0x5>
	struct task_struct **p = NR_TASKS + task;
    2475:	ba 00 01 00 00       	mov    $0x100,%edx
	
	while (--p > &FIRST_TASK) {
    247a:	eb 18                	jmp    2494 <kill_session+0x28>
		if (*p && (*p)->session == current->session)
    247c:	8b 0a                	mov    (%edx),%ecx
    247e:	85 c9                	test   %ecx,%ecx
    2480:	74 12                	je     2494 <kill_session+0x28>
    2482:	8b 98 38 02 00 00    	mov    0x238(%eax),%ebx
    2488:	39 99 38 02 00 00    	cmp    %ebx,0x238(%ecx)
    248e:	75 04                	jne    2494 <kill_session+0x28>
			(*p)->signal |= 1<<(SIGHUP-1);
    2490:	83 49 0c 01          	orl    $0x1,0xc(%ecx)
void kill_session(void)
{
	struct task_struct* current = get_current_task();
	struct task_struct **p = NR_TASKS + task;
	
	while (--p > &FIRST_TASK) {
    2494:	83 ea 04             	sub    $0x4,%edx
    2497:	81 fa 00 00 00 00    	cmp    $0x0,%edx
    249d:	75 dd                	jne    247c <kill_session+0x10>
		if (*p && (*p)->session == current->session)
			(*p)->signal |= 1<<(SIGHUP-1);
	}
}
    249f:	83 c4 08             	add    $0x8,%esp
    24a2:	5b                   	pop    %ebx
    24a3:	c3                   	ret    

000024a4 <sys_kill>:
/*
 * XXX need to check permissions needed to send signals to process
 * groups, etc. etc.  kill() permissions semantics are tricky!
 */
int sys_kill(int pid,int sig)
{
    24a4:	55                   	push   %ebp
    24a5:	57                   	push   %edi
    24a6:	56                   	push   %esi
    24a7:	53                   	push   %ebx
    24a8:	83 ec 0c             	sub    $0xc,%esp
    24ab:	8b 5c 24 20          	mov    0x20(%esp),%ebx
    24af:	8b 6c 24 24          	mov    0x24(%esp),%ebp
	struct task_struct* current = get_current_task();
    24b3:	e8 fc ff ff ff       	call   24b4 <sys_kill+0x10>
	struct task_struct **p = NR_TASKS + task;
	int err, retval = 0;

	if (!pid) while (--p > &FIRST_TASK) {
    24b8:	85 db                	test   %ebx,%ebx
    24ba:	74 2c                	je     24e8 <sys_kill+0x44>
    24bc:	eb 46                	jmp    2504 <sys_kill+0x60>
		if (*p && (*p)->pgrp == current->pid) 
    24be:	8b 03                	mov    (%ebx),%eax
    24c0:	85 c0                	test   %eax,%eax
    24c2:	74 30                	je     24f4 <sys_kill+0x50>
    24c4:	8b 96 2c 02 00 00    	mov    0x22c(%esi),%edx
    24ca:	39 90 34 02 00 00    	cmp    %edx,0x234(%eax)
    24d0:	75 22                	jne    24f4 <sys_kill+0x50>
			if (err=send_sig(sig,*p,1))
    24d2:	83 ec 04             	sub    $0x4,%esp
    24d5:	6a 01                	push   $0x1
    24d7:	50                   	push   %eax
    24d8:	55                   	push   %ebp
    24d9:	e8 fc ff ff ff       	call   24da <sys_kill+0x36>
    24de:	83 c4 10             	add    $0x10,%esp
				retval = err;
    24e1:	85 c0                	test   %eax,%eax
    24e3:	0f 45 f8             	cmovne %eax,%edi
    24e6:	eb 0c                	jmp    24f4 <sys_kill+0x50>
    24e8:	89 c6                	mov    %eax,%esi
    24ea:	bf 00 00 00 00       	mov    $0x0,%edi
    24ef:	bb 00 01 00 00       	mov    $0x100,%ebx
{
	struct task_struct* current = get_current_task();
	struct task_struct **p = NR_TASKS + task;
	int err, retval = 0;

	if (!pid) while (--p > &FIRST_TASK) {
    24f4:	83 eb 04             	sub    $0x4,%ebx
    24f7:	81 fb 00 00 00 00    	cmp    $0x0,%ebx
    24fd:	75 bf                	jne    24be <sys_kill+0x1a>
    24ff:	e9 aa 00 00 00       	jmp    25ae <sys_kill+0x10a>
    2504:	bf 00 00 00 00       	mov    $0x0,%edi
    2509:	be 00 01 00 00       	mov    $0x100,%esi
		if (*p && (*p)->pgrp == current->pid) 
			if (err=send_sig(sig,*p,1))
				retval = err;
	} else if (pid>0) while (--p > &FIRST_TASK) {
    250e:	85 db                	test   %ebx,%ebx
    2510:	7f 24                	jg     2536 <sys_kill+0x92>
    2512:	eb 2f                	jmp    2543 <sys_kill+0x9f>
		if (*p && (*p)->pid == pid) 
    2514:	8b 06                	mov    (%esi),%eax
    2516:	85 c0                	test   %eax,%eax
    2518:	74 1c                	je     2536 <sys_kill+0x92>
    251a:	3b 98 2c 02 00 00    	cmp    0x22c(%eax),%ebx
    2520:	75 14                	jne    2536 <sys_kill+0x92>
			if (err=send_sig(sig,*p,0))
    2522:	83 ec 04             	sub    $0x4,%esp
    2525:	6a 00                	push   $0x0
    2527:	50                   	push   %eax
    2528:	55                   	push   %ebp
    2529:	e8 fc ff ff ff       	call   252a <sys_kill+0x86>
    252e:	83 c4 10             	add    $0x10,%esp
				retval = err;
    2531:	85 c0                	test   %eax,%eax
    2533:	0f 45 f8             	cmovne %eax,%edi

	if (!pid) while (--p > &FIRST_TASK) {
		if (*p && (*p)->pgrp == current->pid) 
			if (err=send_sig(sig,*p,1))
				retval = err;
	} else if (pid>0) while (--p > &FIRST_TASK) {
    2536:	83 ee 04             	sub    $0x4,%esi
    2539:	81 fe 00 00 00 00    	cmp    $0x0,%esi
    253f:	75 d3                	jne    2514 <sys_kill+0x70>
    2541:	eb 6b                	jmp    25ae <sys_kill+0x10a>
 */
int sys_kill(int pid,int sig)
{
	struct task_struct* current = get_current_task();
	struct task_struct **p = NR_TASKS + task;
	int err, retval = 0;
    2543:	bf 00 00 00 00       	mov    $0x0,%edi
				retval = err;
	} else if (pid>0) while (--p > &FIRST_TASK) {
		if (*p && (*p)->pid == pid) 
			if (err=send_sig(sig,*p,0))
				retval = err;
	} else if (pid == -1) while (--p > &FIRST_TASK)
    2548:	83 fb ff             	cmp    $0xffffffff,%ebx
    254b:	75 61                	jne    25ae <sys_kill+0x10a>
    254d:	eb 46                	jmp    2595 <sys_kill+0xf1>
		if (err = send_sig(sig,*p,0))
    254f:	83 ec 04             	sub    $0x4,%esp
    2552:	6a 00                	push   $0x0
    2554:	ff 33                	pushl  (%ebx)
    2556:	55                   	push   %ebp
    2557:	e8 fc ff ff ff       	call   2558 <sys_kill+0xb4>
    255c:	83 c4 10             	add    $0x10,%esp
    255f:	85 c0                	test   %eax,%eax
    2561:	75 3e                	jne    25a1 <sys_kill+0xfd>
    2563:	eb 23                	jmp    2588 <sys_kill+0xe4>
			retval = err;
	else while (--p > &FIRST_TASK)
		if (*p && (*p)->pgrp == -pid)
    2565:	8b 03                	mov    (%ebx),%eax
    2567:	85 c0                	test   %eax,%eax
    2569:	74 1d                	je     2588 <sys_kill+0xe4>
    256b:	83 b8 34 02 00 00 01 	cmpl   $0x1,0x234(%eax)
    2572:	75 14                	jne    2588 <sys_kill+0xe4>
			if (err = send_sig(sig,*p,0))
    2574:	83 ec 04             	sub    $0x4,%esp
    2577:	6a 00                	push   $0x0
    2579:	50                   	push   %eax
    257a:	55                   	push   %ebp
    257b:	e8 fc ff ff ff       	call   257c <sys_kill+0xd8>
    2580:	83 c4 10             	add    $0x10,%esp
				retval = err;
    2583:	85 c0                	test   %eax,%eax
    2585:	0f 45 f8             	cmovne %eax,%edi
			if (err=send_sig(sig,*p,0))
				retval = err;
	} else if (pid == -1) while (--p > &FIRST_TASK)
		if (err = send_sig(sig,*p,0))
			retval = err;
	else while (--p > &FIRST_TASK)
    2588:	83 eb 04             	sub    $0x4,%ebx
    258b:	81 fb 00 00 00 00    	cmp    $0x0,%ebx
    2591:	77 d2                	ja     2565 <sys_kill+0xc1>
    2593:	eb 0e                	jmp    25a3 <sys_kill+0xff>
    2595:	bf 00 00 00 00       	mov    $0x0,%edi
    259a:	bb 00 01 00 00       	mov    $0x100,%ebx
    259f:	eb 02                	jmp    25a3 <sys_kill+0xff>
		if (*p && (*p)->pid == pid) 
			if (err=send_sig(sig,*p,0))
				retval = err;
	} else if (pid == -1) while (--p > &FIRST_TASK)
		if (err = send_sig(sig,*p,0))
			retval = err;
    25a1:	89 c7                	mov    %eax,%edi
				retval = err;
	} else if (pid>0) while (--p > &FIRST_TASK) {
		if (*p && (*p)->pid == pid) 
			if (err=send_sig(sig,*p,0))
				retval = err;
	} else if (pid == -1) while (--p > &FIRST_TASK)
    25a3:	83 eb 04             	sub    $0x4,%ebx
    25a6:	81 fb 00 00 00 00    	cmp    $0x0,%ebx
    25ac:	77 a1                	ja     254f <sys_kill+0xab>
	else while (--p > &FIRST_TASK)
		if (*p && (*p)->pgrp == -pid)
			if (err = send_sig(sig,*p,0))
				retval = err;
	return retval;
}
    25ae:	89 f8                	mov    %edi,%eax
    25b0:	83 c4 0c             	add    $0xc,%esp
    25b3:	5b                   	pop    %ebx
    25b4:	5e                   	pop    %esi
    25b5:	5f                   	pop    %edi
    25b6:	5d                   	pop    %ebp
    25b7:	c3                   	ret    

000025b8 <tell_father>:

void tell_father(int pid)
{
    25b8:	53                   	push   %ebx
    25b9:	83 ec 08             	sub    $0x8,%esp
    25bc:	8b 4c 24 10          	mov    0x10(%esp),%ecx
	int i;
	//struct task_struct * current = get_current_task();
	if (pid)
    25c0:	85 c9                	test   %ecx,%ecx
    25c2:	74 28                	je     25ec <tell_father+0x34>
    25c4:	b8 00 00 00 00       	mov    $0x0,%eax
    25c9:	bb 00 01 00 00       	mov    $0x100,%ebx
		for (i=0;i<NR_TASKS;i++) {
			if (!task[i])
    25ce:	8b 10                	mov    (%eax),%edx
    25d0:	85 d2                	test   %edx,%edx
    25d2:	74 11                	je     25e5 <tell_father+0x2d>
				continue;
			if (task[i]->pid != pid)
    25d4:	3b 8a 2c 02 00 00    	cmp    0x22c(%edx),%ecx
    25da:	75 09                	jne    25e5 <tell_father+0x2d>
				continue;
			task[i]->signal |= (1<<(SIGCHLD-1));
    25dc:	81 4a 0c 00 00 01 00 	orl    $0x10000,0xc(%edx)
			return;
    25e3:	eb 17                	jmp    25fc <tell_father+0x44>
    25e5:	83 c0 04             	add    $0x4,%eax
void tell_father(int pid)
{
	int i;
	//struct task_struct * current = get_current_task();
	if (pid)
		for (i=0;i<NR_TASKS;i++) {
    25e8:	39 d8                	cmp    %ebx,%eax
    25ea:	75 e2                	jne    25ce <tell_father+0x16>
			task[i]->signal |= (1<<(SIGCHLD-1));
			return;
		}
/* if we don't find any fathers, we just release ourselves */
/* This is not really OK. Must change it to make father 1 */
	panic("BAD BAD - no father found\n\r");
    25ec:	83 ec 0c             	sub    $0xc,%esp
    25ef:	68 c8 01 00 00       	push   $0x1c8
    25f4:	e8 fc ff ff ff       	call   25f5 <tell_father+0x3d>
    25f9:	83 c4 10             	add    $0x10,%esp
	//release(current);
}
    25fc:	83 c4 08             	add    $0x8,%esp
    25ff:	5b                   	pop    %ebx
    2600:	c3                   	ret    

00002601 <do_exit>:

int do_exit(long code)
{
    2601:	57                   	push   %edi
    2602:	56                   	push   %esi
    2603:	53                   	push   %ebx
	struct task_struct* current = get_current_task();
    2604:	e8 fc ff ff ff       	call   2605 <do_exit+0x4>
    2609:	89 c6                	mov    %eax,%esi
	int i;

	//printk("do_exit call free_page_tables before\n\r");
	free_page_tables(get_base(current->ldt[1]),get_limit(0x0f),current);
    260b:	b9 0f 00 00 00       	mov    $0xf,%ecx
    2610:	0f 03 c9             	lsl    %cx,%ecx
    2613:	41                   	inc    %ecx
    2614:	50                   	push   %eax
    2615:	8d 80 d8 02 00 00    	lea    0x2d8(%eax),%eax
    261b:	83 c0 07             	add    $0x7,%eax
    261e:	8a 30                	mov    (%eax),%dh
    2620:	83 e8 03             	sub    $0x3,%eax
    2623:	8a 10                	mov    (%eax),%dl
    2625:	c1 e2 10             	shl    $0x10,%edx
    2628:	83 e8 02             	sub    $0x2,%eax
    262b:	66 8b 10             	mov    (%eax),%dx
    262e:	58                   	pop    %eax
    262f:	83 ec 04             	sub    $0x4,%esp
    2632:	56                   	push   %esi
    2633:	51                   	push   %ecx
    2634:	52                   	push   %edx
    2635:	e8 fc ff ff ff       	call   2636 <do_exit+0x35>
	free_page_tables(get_base(current->ldt[2]),get_limit(0x17),current);
    263a:	b9 17 00 00 00       	mov    $0x17,%ecx
    263f:	0f 03 c9             	lsl    %cx,%ecx
    2642:	41                   	inc    %ecx
    2643:	50                   	push   %eax
    2644:	8d 86 e0 02 00 00    	lea    0x2e0(%esi),%eax
    264a:	83 c0 07             	add    $0x7,%eax
    264d:	8a 30                	mov    (%eax),%dh
    264f:	83 e8 03             	sub    $0x3,%eax
    2652:	8a 10                	mov    (%eax),%dl
    2654:	c1 e2 10             	shl    $0x10,%edx
    2657:	83 e8 02             	sub    $0x2,%eax
    265a:	66 8b 10             	mov    (%eax),%dx
    265d:	58                   	pop    %eax
    265e:	83 c4 0c             	add    $0xc,%esp
    2661:	56                   	push   %esi
    2662:	51                   	push   %ecx
    2663:	52                   	push   %edx
    2664:	e8 fc ff ff ff       	call   2665 <do_exit+0x64>
    2669:	bb 00 00 00 00       	mov    $0x0,%ebx
    266e:	bf 00 01 00 00       	mov    $0x100,%edi
    2673:	83 c4 10             	add    $0x10,%esp
    //printk("do_exit call free_page_tables after\n\r");

	for (i=0 ; i<NR_TASKS ; i++)
		if (task[i] && task[i]->father == current->pid) {
    2676:	8b 03                	mov    (%ebx),%eax
    2678:	85 c0                	test   %eax,%eax
    267a:	74 32                	je     26ae <do_exit+0xad>
    267c:	8b 96 2c 02 00 00    	mov    0x22c(%esi),%edx
    2682:	39 90 30 02 00 00    	cmp    %edx,0x230(%eax)
    2688:	75 24                	jne    26ae <do_exit+0xad>
			task[i]->father = 1;
    268a:	c7 80 30 02 00 00 01 	movl   $0x1,0x230(%eax)
    2691:	00 00 00 
			if (task[i]->state == TASK_ZOMBIE)
    2694:	83 38 03             	cmpl   $0x3,(%eax)
    2697:	75 15                	jne    26ae <do_exit+0xad>
				/* assumption task[1] is always init */
				(void) send_sig(SIGCHLD, task[1], 1);
    2699:	83 ec 04             	sub    $0x4,%esp
    269c:	6a 01                	push   $0x1
    269e:	ff 35 04 00 00 00    	pushl  0x4
    26a4:	6a 11                	push   $0x11
    26a6:	e8 fc ff ff ff       	call   26a7 <do_exit+0xa6>
    26ab:	83 c4 10             	add    $0x10,%esp
    26ae:	83 c3 04             	add    $0x4,%ebx
	//printk("do_exit call free_page_tables before\n\r");
	free_page_tables(get_base(current->ldt[1]),get_limit(0x0f),current);
	free_page_tables(get_base(current->ldt[2]),get_limit(0x17),current);
    //printk("do_exit call free_page_tables after\n\r");

	for (i=0 ; i<NR_TASKS ; i++)
    26b1:	39 fb                	cmp    %edi,%ebx
    26b3:	75 c1                	jne    2676 <do_exit+0x75>
    26b5:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (task[i]->state == TASK_ZOMBIE)
				/* assumption task[1] is always init */
				(void) send_sig(SIGCHLD, task[1], 1);
		}
	for (i=0 ; i<NR_OPEN ; i++)
		if (current->filp[i])
    26ba:	83 bc 9e 80 02 00 00 	cmpl   $0x0,0x280(%esi,%ebx,4)
    26c1:	00 
    26c2:	74 0c                	je     26d0 <do_exit+0xcf>
			sys_close(i);
    26c4:	83 ec 0c             	sub    $0xc,%esp
    26c7:	53                   	push   %ebx
    26c8:	e8 fc ff ff ff       	call   26c9 <do_exit+0xc8>
    26cd:	83 c4 10             	add    $0x10,%esp
			task[i]->father = 1;
			if (task[i]->state == TASK_ZOMBIE)
				/* assumption task[1] is always init */
				(void) send_sig(SIGCHLD, task[1], 1);
		}
	for (i=0 ; i<NR_OPEN ; i++)
    26d0:	83 c3 01             	add    $0x1,%ebx
    26d3:	83 fb 14             	cmp    $0x14,%ebx
    26d6:	75 e2                	jne    26ba <do_exit+0xb9>
		if (current->filp[i])
			sys_close(i);
	iput(current->pwd);
    26d8:	83 ec 0c             	sub    $0xc,%esp
    26db:	ff b6 70 02 00 00    	pushl  0x270(%esi)
    26e1:	e8 fc ff ff ff       	call   26e2 <do_exit+0xe1>
	current->pwd=NULL;
    26e6:	c7 86 70 02 00 00 00 	movl   $0x0,0x270(%esi)
    26ed:	00 00 00 
	iput(current->root);
    26f0:	83 c4 04             	add    $0x4,%esp
    26f3:	ff b6 74 02 00 00    	pushl  0x274(%esi)
    26f9:	e8 fc ff ff ff       	call   26fa <do_exit+0xf9>
	current->root=NULL;
    26fe:	c7 86 74 02 00 00 00 	movl   $0x0,0x274(%esi)
    2705:	00 00 00 
	iput(current->executable);
    2708:	83 c4 04             	add    $0x4,%esp
    270b:	ff b6 78 02 00 00    	pushl  0x278(%esi)
    2711:	e8 fc ff ff ff       	call   2712 <do_exit+0x111>
	current->executable=NULL;
    2716:	c7 86 78 02 00 00 00 	movl   $0x0,0x278(%esi)
    271d:	00 00 00 
	if (current->leader && current->tty >= 0)
    2720:	83 c4 10             	add    $0x10,%esp
    2723:	83 be 3c 02 00 00 00 	cmpl   $0x0,0x23c(%esi)
    272a:	0f 84 9a 00 00 00    	je     27ca <do_exit+0x1c9>
    2730:	8b 86 68 02 00 00    	mov    0x268(%esi),%eax
    2736:	85 c0                	test   %eax,%eax
    2738:	0f 88 82 00 00 00    	js     27c0 <do_exit+0x1bf>
		tty_table[current->tty].pgrp = 0;
    273e:	69 c0 60 0c 00 00    	imul   $0xc60,%eax,%eax
    2744:	c7 80 24 00 00 00 00 	movl   $0x0,0x24(%eax)
    274b:	00 00 00 
	if (last_task_used_math == current)
    274e:	3b 35 00 00 00 00    	cmp    0x0,%esi
    2754:	75 0a                	jne    2760 <do_exit+0x15f>
		last_task_used_math = NULL;
    2756:	c7 05 00 00 00 00 00 	movl   $0x0,0x0
    275d:	00 00 00 
	if (current->leader)
    2760:	83 be 3c 02 00 00 00 	cmpl   $0x0,0x23c(%esi)
    2767:	74 05                	je     276e <do_exit+0x16d>
		kill_session();
    2769:	e8 fc ff ff ff       	call   276a <do_exit+0x169>
	current->state = TASK_ZOMBIE;
    276e:	c7 06 03 00 00 00    	movl   $0x3,(%esi)
	current->exit_code = code;
    2774:	8b 44 24 10          	mov    0x10(%esp),%eax
    2778:	89 86 14 02 00 00    	mov    %eax,0x214(%esi)
	 * 一旦释放了这两个内存页,她们就有可能被其他新进程占用,以上的操作早于随后执行的reset_ap_context那么,当前进程的目录页就作废了,
	 * 内存映射就出问题了程序就崩溃了.
	 * 所以把tell_father放在task_exit_clear里就不可能会出现这个错误.
	 *  */
	//tell_father(current->father);
	if (get_current_apic_id() == apic_ids[0].apic_id) {
    277e:	e8 fc ff ff ff       	call   277f <do_exit+0x17e>
    2783:	3b 05 04 00 00 00    	cmp    0x4,%eax
    2789:	75 12                	jne    279d <do_exit+0x19c>
		/* 在BSP上退出一个进程后，自主调用schedule，这里是不可能的，因为BSP只运行task0和task1，但这两个进程是不可能退出的，除非系统崩溃了 */
	    panic("System encounters fatal errors, abort.");
    278b:	83 ec 0c             	sub    $0xc,%esp
    278e:	68 5c 02 00 00       	push   $0x25c
    2793:	e8 fc ff ff ff       	call   2794 <do_exit+0x193>
    2798:	83 c4 10             	add    $0x10,%esp
    279b:	eb 37                	jmp    27d4 <do_exit+0x1d3>
	}
	else {
		printk("task[%d],exit at AP[%d]\n\r", current->task_nr, get_current_apic_id());
    279d:	e8 fc ff ff ff       	call   279e <do_exit+0x19d>
    27a2:	83 ec 04             	sub    $0x4,%esp
    27a5:	50                   	push   %eax
    27a6:	ff b6 c0 03 00 00    	pushl  0x3c0(%esi)
    27ac:	68 e4 01 00 00       	push   $0x1e4
    27b1:	e8 fc ff ff ff       	call   27b2 <do_exit+0x1b1>
		/* 进程退出后,要重置该AP的执行上下文. */
		reset_ap_context();
    27b6:	e8 fc ff ff ff       	call   27b7 <do_exit+0x1b6>
    27bb:	83 c4 10             	add    $0x10,%esp
	}
	return (-1);	/* just to suppress warnings */
    27be:	eb 14                	jmp    27d4 <do_exit+0x1d3>
	current->root=NULL;
	iput(current->executable);
	current->executable=NULL;
	if (current->leader && current->tty >= 0)
		tty_table[current->tty].pgrp = 0;
	if (last_task_used_math == current)
    27c0:	3b 35 00 00 00 00    	cmp    0x0,%esi
    27c6:	75 a1                	jne    2769 <do_exit+0x168>
    27c8:	eb 8c                	jmp    2756 <do_exit+0x155>
    27ca:	3b 35 00 00 00 00    	cmp    0x0,%esi
    27d0:	75 9c                	jne    276e <do_exit+0x16d>
    27d2:	eb 82                	jmp    2756 <do_exit+0x155>
		printk("task[%d],exit at AP[%d]\n\r", current->task_nr, get_current_apic_id());
		/* 进程退出后,要重置该AP的执行上下文. */
		reset_ap_context();
	}
	return (-1);	/* just to suppress warnings */
}
    27d4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    27d9:	5b                   	pop    %ebx
    27da:	5e                   	pop    %esi
    27db:	5f                   	pop    %edi
    27dc:	c3                   	ret    

000027dd <sys_exit>:

int sys_exit(int error_code)
{
    27dd:	83 ec 18             	sub    $0x18,%esp
	return do_exit((error_code&0xff)<<8);
    27e0:	8b 44 24 1c          	mov    0x1c(%esp),%eax
    27e4:	c1 e0 08             	shl    $0x8,%eax
    27e7:	0f b7 c0             	movzwl %ax,%eax
    27ea:	50                   	push   %eax
    27eb:	e8 fc ff ff ff       	call   27ec <sys_exit+0xf>
}
    27f0:	83 c4 1c             	add    $0x1c,%esp
    27f3:	c3                   	ret    

000027f4 <sys_waitpid>:

int sys_waitpid(pid_t pid,unsigned long * stat_addr, int options)
{
    27f4:	55                   	push   %ebp
    27f5:	57                   	push   %edi
    27f6:	56                   	push   %esi
    27f7:	53                   	push   %ebx
    27f8:	83 ec 1c             	sub    $0x1c,%esp
    27fb:	8b 74 24 30          	mov    0x30(%esp),%esi
	struct task_struct* current = get_current_task();
    27ff:	e8 fc ff ff ff       	call   2800 <sys_waitpid+0xc>
    2804:	89 c3                	mov    %eax,%ebx
	int flag, code;
	struct task_struct ** p;

	verify_area(stat_addr,4);
    2806:	83 ec 08             	sub    $0x8,%esp
    2809:	6a 04                	push   $0x4
    280b:	ff 74 24 40          	pushl  0x40(%esp)
    280f:	e8 fc ff ff ff       	call   2810 <sys_waitpid+0x1c>
    2814:	83 c4 10             	add    $0x10,%esp
			if ((*p)->pgrp != -pid)
				continue;
		}
		switch ((*p)->state) {
			case TASK_STOPPED:
				if (!(options & WUNTRACED))
    2817:	8b 7c 24 38          	mov    0x38(%esp),%edi
    281b:	83 e7 02             	and    $0x2,%edi
				continue;
		} else if (!pid) {
			if ((*p)->pgrp != current->pgrp)
				continue;
		} else if (pid != -1) {
			if ((*p)->pgrp != -pid)
    281e:	89 f5                	mov    %esi,%ebp
    2820:	f7 dd                	neg    %ebp
	struct task_struct ** p;

	verify_area(stat_addr,4);
repeat:
	flag=0;
	for(p = &LAST_TASK ; p > &FIRST_TASK ; --p) {
    2822:	b8 fc 00 00 00       	mov    $0xfc,%eax
	int flag, code;
	struct task_struct ** p;

	verify_area(stat_addr,4);
repeat:
	flag=0;
    2827:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
    282e:	00 
	for(p = &LAST_TASK ; p > &FIRST_TASK ; --p) {
		if (!*p || *p == current)   /* 过滤掉自身 */
    282f:	8b 10                	mov    (%eax),%edx
    2831:	39 d3                	cmp    %edx,%ebx
    2833:	0f 84 bb 00 00 00    	je     28f4 <sys_waitpid+0x100>
    2839:	85 d2                	test   %edx,%edx
    283b:	0f 84 b3 00 00 00    	je     28f4 <sys_waitpid+0x100>
			continue;
		if ((*p)->father != current->pid)  /* 查找当前进程的子进程 */
    2841:	8b 8b 2c 02 00 00    	mov    0x22c(%ebx),%ecx
    2847:	39 8a 30 02 00 00    	cmp    %ecx,0x230(%edx)
    284d:	0f 85 a1 00 00 00    	jne    28f4 <sys_waitpid+0x100>
			continue;
		if (pid>0) {
    2853:	85 f6                	test   %esi,%esi
    2855:	7e 0e                	jle    2865 <sys_waitpid+0x71>
			if ((*p)->pid != pid)
    2857:	3b b2 2c 02 00 00    	cmp    0x22c(%edx),%esi
    285d:	0f 85 91 00 00 00    	jne    28f4 <sys_waitpid+0x100>
    2863:	eb 21                	jmp    2886 <sys_waitpid+0x92>
				continue;
		} else if (!pid) {
    2865:	85 f6                	test   %esi,%esi
    2867:	75 10                	jne    2879 <sys_waitpid+0x85>
			if ((*p)->pgrp != current->pgrp)
    2869:	8b 8b 34 02 00 00    	mov    0x234(%ebx),%ecx
    286f:	39 8a 34 02 00 00    	cmp    %ecx,0x234(%edx)
    2875:	75 7d                	jne    28f4 <sys_waitpid+0x100>
    2877:	eb 0d                	jmp    2886 <sys_waitpid+0x92>
				continue;
		} else if (pid != -1) {
    2879:	83 fe ff             	cmp    $0xffffffff,%esi
    287c:	74 08                	je     2886 <sys_waitpid+0x92>
			if ((*p)->pgrp != -pid)
    287e:	39 aa 34 02 00 00    	cmp    %ebp,0x234(%edx)
    2884:	75 6e                	jne    28f4 <sys_waitpid+0x100>
				continue;
		}
		switch ((*p)->state) {
    2886:	8b 0a                	mov    (%edx),%ecx
    2888:	83 f9 03             	cmp    $0x3,%ecx
    288b:	74 20                	je     28ad <sys_waitpid+0xb9>
    288d:	83 f9 04             	cmp    $0x4,%ecx
    2890:	75 5a                	jne    28ec <sys_waitpid+0xf8>
			case TASK_STOPPED:
				if (!(options & WUNTRACED))
    2892:	85 ff                	test   %edi,%edi
    2894:	74 5e                	je     28f4 <sys_waitpid+0x100>
__asm__ ("movw %0,%%fs:%1"::"r" (val),"m" (*addr));
}

static inline void put_fs_long(unsigned long val,unsigned long * addr)
{
__asm__ ("movl %0,%%fs:%1"::"r" (val),"m" (*addr));
    2896:	b8 7f 00 00 00       	mov    $0x7f,%eax
    289b:	8b 7c 24 34          	mov    0x34(%esp),%edi
    289f:	64 89 07             	mov    %eax,%fs:(%edi)
					continue;
				put_fs_long(0x7f,stat_addr);
				return (*p)->pid;
    28a2:	8b 82 2c 02 00 00    	mov    0x22c(%edx),%eax
    28a8:	e9 94 00 00 00       	jmp    2941 <sys_waitpid+0x14d>
			case TASK_ZOMBIE:
				current->cutime += (*p)->utime;
    28ad:	8b 92 50 02 00 00    	mov    0x250(%edx),%edx
    28b3:	01 93 58 02 00 00    	add    %edx,0x258(%ebx)
				current->cstime += (*p)->stime;
    28b9:	8b 10                	mov    (%eax),%edx
    28bb:	8b 92 54 02 00 00    	mov    0x254(%edx),%edx
    28c1:	01 93 5c 02 00 00    	add    %edx,0x25c(%ebx)
				flag = (*p)->pid;
    28c7:	8b 00                	mov    (%eax),%eax
    28c9:	8b 98 2c 02 00 00    	mov    0x22c(%eax),%ebx
				code = (*p)->exit_code;
    28cf:	8b b0 14 02 00 00    	mov    0x214(%eax),%esi
				//printk("pid: %d, fpid: %d, exitCode: %d\n\r", flag,(*p)->father, code);
				release(*p);
    28d5:	83 ec 0c             	sub    $0xc,%esp
    28d8:	50                   	push   %eax
    28d9:	e8 fc ff ff ff       	call   28da <sys_waitpid+0xe6>
    28de:	8b 44 24 44          	mov    0x44(%esp),%eax
    28e2:	64 89 30             	mov    %esi,%fs:(%eax)
				put_fs_long(code,stat_addr);
				return flag;
    28e5:	83 c4 10             	add    $0x10,%esp
    28e8:	89 d8                	mov    %ebx,%eax
    28ea:	eb 55                	jmp    2941 <sys_waitpid+0x14d>
			default:
				flag=1;
    28ec:	c7 44 24 0c 01 00 00 	movl   $0x1,0xc(%esp)
    28f3:	00 
	struct task_struct ** p;

	verify_area(stat_addr,4);
repeat:
	flag=0;
	for(p = &LAST_TASK ; p > &FIRST_TASK ; --p) {
    28f4:	83 e8 04             	sub    $0x4,%eax
    28f7:	3d 00 00 00 00       	cmp    $0x0,%eax
    28fc:	0f 85 2d ff ff ff    	jne    282f <sys_waitpid+0x3b>
				flag=1;
				continue;
		}
	}

	if (flag) {
    2902:	83 7c 24 0c 00       	cmpl   $0x0,0xc(%esp)
    2907:	74 2c                	je     2935 <sys_waitpid+0x141>
		if (options & WNOHANG){
    2909:	f6 44 24 38 01       	testb  $0x1,0x38(%esp)
    290e:	75 2c                	jne    293c <sys_waitpid+0x148>
			return 0;
		}

		current->state=TASK_INTERRUPTIBLE;
    2910:	c7 03 01 00 00 00    	movl   $0x1,(%ebx)
		schedule();
    2916:	e8 fc ff ff ff       	call   2917 <sys_waitpid+0x123>
		/* 子进程如果调用了exit会调用tell_father将father的SIG_CHILD位置1的，这里父进程就是在等这个标志。 */
		if (!(current->signal &= ~(1<<(SIGCHLD-1))))
    291b:	8b 43 0c             	mov    0xc(%ebx),%eax
    291e:	25 ff ff fe ff       	and    $0xfffeffff,%eax
    2923:	89 43 0c             	mov    %eax,0xc(%ebx)
    2926:	85 c0                	test   %eax,%eax
    2928:	0f 84 f4 fe ff ff    	je     2822 <sys_waitpid+0x2e>
			goto repeat;
		else
			return -EINTR;
    292e:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
    2933:	eb 0c                	jmp    2941 <sys_waitpid+0x14d>
	}
	return -ECHILD;
    2935:	b8 f6 ff ff ff       	mov    $0xfffffff6,%eax
    293a:	eb 05                	jmp    2941 <sys_waitpid+0x14d>
		}
	}

	if (flag) {
		if (options & WNOHANG){
			return 0;
    293c:	b8 00 00 00 00       	mov    $0x0,%eax
			goto repeat;
		else
			return -EINTR;
	}
	return -ECHILD;
}
    2941:	83 c4 1c             	add    $0x1c,%esp
    2944:	5b                   	pop    %ebx
    2945:	5e                   	pop    %esi
    2946:	5f                   	pop    %edi
    2947:	5d                   	pop    %ebp
    2948:	c3                   	ret    

00002949 <sys_sgetmask>:
#include <signal.h>

volatile void do_exit(int error_code);

int sys_sgetmask()
{
    2949:	83 ec 0c             	sub    $0xc,%esp
	struct task_struct* current = get_current_task();
    294c:	e8 fc ff ff ff       	call   294d <sys_sgetmask+0x4>
	return current->blocked;
    2951:	8b 80 10 02 00 00    	mov    0x210(%eax),%eax
}
    2957:	83 c4 0c             	add    $0xc,%esp
    295a:	c3                   	ret    

0000295b <sys_ssetmask>:

int sys_ssetmask(int newmask)
{
    295b:	83 ec 0c             	sub    $0xc,%esp
	struct task_struct* current = get_current_task();
    295e:	e8 fc ff ff ff       	call   295f <sys_ssetmask+0x4>
    2963:	89 c1                	mov    %eax,%ecx
	int old=current->blocked;
    2965:	8b 80 10 02 00 00    	mov    0x210(%eax),%eax

	current->blocked = newmask & ~(1<<(SIGKILL-1));
    296b:	8b 54 24 10          	mov    0x10(%esp),%edx
    296f:	80 e6 fe             	and    $0xfe,%dh
    2972:	89 91 10 02 00 00    	mov    %edx,0x210(%ecx)
	return old;
}
    2978:	83 c4 0c             	add    $0xc,%esp
    297b:	c3                   	ret    

0000297c <sys_signal>:
	for (i=0 ; i< sizeof(struct sigaction) ; i++)
		*(to++) = get_fs_byte(from++);
}

int sys_signal(int signum, long handler, long restorer)
{
    297c:	53                   	push   %ebx
    297d:	83 ec 08             	sub    $0x8,%esp
    2980:	8b 5c 24 10          	mov    0x10(%esp),%ebx
	struct task_struct* current = get_current_task();
    2984:	e8 fc ff ff ff       	call   2985 <sys_signal+0x9>
	struct sigaction tmp;

	if (signum<1 || signum>32 || signum==SIGKILL)
    2989:	8d 4b ff             	lea    -0x1(%ebx),%ecx
    298c:	83 f9 1f             	cmp    $0x1f,%ecx
    298f:	77 2a                	ja     29bb <sys_signal+0x3f>
    2991:	83 fb 09             	cmp    $0x9,%ebx
    2994:	74 25                	je     29bb <sys_signal+0x3f>
		return -1;
	tmp.sa_handler = (void (*)(int)) handler;
	tmp.sa_mask = 0;
	tmp.sa_flags = SA_ONESHOT | SA_NOMASK;
	tmp.sa_restorer = (void (*)(void)) restorer;
	handler = (long) current->sigaction[signum-1].sa_handler;
    2996:	c1 e3 04             	shl    $0x4,%ebx
    2999:	8d 14 18             	lea    (%eax,%ebx,1),%edx
    299c:	8b 02                	mov    (%edx),%eax
	current->sigaction[signum-1] = tmp;
    299e:	8b 4c 24 14          	mov    0x14(%esp),%ecx
    29a2:	89 0a                	mov    %ecx,(%edx)
    29a4:	c7 42 04 00 00 00 00 	movl   $0x0,0x4(%edx)
    29ab:	c7 42 08 00 00 00 c0 	movl   $0xc0000000,0x8(%edx)
    29b2:	8b 4c 24 18          	mov    0x18(%esp),%ecx
    29b6:	89 4a 0c             	mov    %ecx,0xc(%edx)
	return handler;
    29b9:	eb 05                	jmp    29c0 <sys_signal+0x44>
{
	struct task_struct* current = get_current_task();
	struct sigaction tmp;

	if (signum<1 || signum>32 || signum==SIGKILL)
		return -1;
    29bb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	tmp.sa_flags = SA_ONESHOT | SA_NOMASK;
	tmp.sa_restorer = (void (*)(void)) restorer;
	handler = (long) current->sigaction[signum-1].sa_handler;
	current->sigaction[signum-1] = tmp;
	return handler;
}
    29c0:	83 c4 08             	add    $0x8,%esp
    29c3:	5b                   	pop    %ebx
    29c4:	c3                   	ret    

000029c5 <sys_sigaction>:

int sys_sigaction(int signum, const struct sigaction * action,
	struct sigaction * oldaction)
{
    29c5:	55                   	push   %ebp
    29c6:	57                   	push   %edi
    29c7:	56                   	push   %esi
    29c8:	53                   	push   %ebx
    29c9:	83 ec 2c             	sub    $0x2c,%esp
    29cc:	8b 7c 24 40          	mov    0x40(%esp),%edi
    29d0:	8b 5c 24 44          	mov    0x44(%esp),%ebx
    29d4:	8b 74 24 48          	mov    0x48(%esp),%esi
	struct task_struct* current = get_current_task();
    29d8:	e8 fc ff ff ff       	call   29d9 <sys_sigaction+0x14>
    29dd:	89 c5                	mov    %eax,%ebp
	struct sigaction tmp;

	if (signum<1 || signum>32 || signum==SIGKILL)
    29df:	8d 47 ff             	lea    -0x1(%edi),%eax
    29e2:	83 f8 1f             	cmp    $0x1f,%eax
    29e5:	0f 87 8e 00 00 00    	ja     2a79 <sys_sigaction+0xb4>
    29eb:	83 ff 09             	cmp    $0x9,%edi
    29ee:	0f 84 85 00 00 00    	je     2a79 <sys_sigaction+0xb4>
		return -1;
	tmp = current->sigaction[signum-1];
    29f4:	89 44 24 0c          	mov    %eax,0xc(%esp)
    29f8:	89 f8                	mov    %edi,%eax
    29fa:	c1 e0 04             	shl    $0x4,%eax
    29fd:	01 e8                	add    %ebp,%eax
    29ff:	8b 10                	mov    (%eax),%edx
    2a01:	89 54 24 10          	mov    %edx,0x10(%esp)
    2a05:	8b 50 04             	mov    0x4(%eax),%edx
    2a08:	89 54 24 14          	mov    %edx,0x14(%esp)
    2a0c:	8b 50 08             	mov    0x8(%eax),%edx
    2a0f:	89 54 24 18          	mov    %edx,0x18(%esp)
    2a13:	8b 40 0c             	mov    0xc(%eax),%eax
    2a16:	89 44 24 1c          	mov    %eax,0x1c(%esp)
	get_new((char *) action,
    2a1a:	89 f8                	mov    %edi,%eax
    2a1c:	c1 e0 04             	shl    $0x4,%eax
    2a1f:	8d 04 28             	lea    (%eax,%ebp,1),%eax
    2a22:	8d 48 10             	lea    0x10(%eax),%ecx
static inline void get_new(char * from,char * to)
{
	int i;

	for (i=0 ; i< sizeof(struct sigaction) ; i++)
		*(to++) = get_fs_byte(from++);
    2a25:	83 c0 01             	add    $0x1,%eax
static inline unsigned char get_fs_byte(const char * addr)
{
	unsigned register char _v;

	__asm__ ("movb %%fs:%1,%0":"=r" (_v):"m" (*addr));
    2a28:	64 8a 13             	mov    %fs:(%ebx),%dl
    2a2b:	88 50 ff             	mov    %dl,-0x1(%eax)
    2a2e:	8d 5b 01             	lea    0x1(%ebx),%ebx

static inline void get_new(char * from,char * to)
{
	int i;

	for (i=0 ; i< sizeof(struct sigaction) ; i++)
    2a31:	39 c8                	cmp    %ecx,%eax
    2a33:	75 f0                	jne    2a25 <sys_sigaction+0x60>
    2a35:	eb 5d                	jmp    2a94 <sys_sigaction+0xcf>
	return _v;
}

static inline void put_fs_byte(char val,char *addr)
{
__asm__ ("movb %0,%%fs:%1"::"q" (val),"m" (*addr));
    2a37:	0f b6 10             	movzbl (%eax),%edx
    2a3a:	64 88 16             	mov    %dl,%fs:(%esi)
	int i;

	verify_area(to, sizeof(struct sigaction));
	for (i=0 ; i< sizeof(struct sigaction) ; i++) {
		put_fs_byte(*from,to);
		from++;
    2a3d:	83 c0 01             	add    $0x1,%eax
		to++;
    2a40:	83 c6 01             	add    $0x1,%esi
static inline void save_old(char * from,char * to)
{
	int i;

	verify_area(to, sizeof(struct sigaction));
	for (i=0 ; i< sizeof(struct sigaction) ; i++) {
    2a43:	8d 4c 24 20          	lea    0x20(%esp),%ecx
    2a47:	39 c8                	cmp    %ecx,%eax
    2a49:	75 ec                	jne    2a37 <sys_sigaction+0x72>
    2a4b:	c1 e7 04             	shl    $0x4,%edi
    2a4e:	01 fd                	add    %edi,%ebp
	tmp = current->sigaction[signum-1];
	get_new((char *) action,
		(char *) (signum-1+current->sigaction));
	if (oldaction)
		save_old((char *) &tmp,(char *) oldaction);
	if (current->sigaction[signum-1].sa_flags & SA_NOMASK)
    2a50:	8b 45 08             	mov    0x8(%ebp),%eax
    2a53:	25 00 00 00 40       	and    $0x40000000,%eax
    2a58:	74 0e                	je     2a68 <sys_sigaction+0xa3>
		current->sigaction[signum-1].sa_mask = 0;
    2a5a:	c7 45 04 00 00 00 00 	movl   $0x0,0x4(%ebp)
	else
		current->sigaction[signum-1].sa_mask |= (1<<(signum-1));
	return 0;
    2a61:	b8 00 00 00 00       	mov    $0x0,%eax
    2a66:	eb 32                	jmp    2a9a <sys_sigaction+0xd5>
	if (oldaction)
		save_old((char *) &tmp,(char *) oldaction);
	if (current->sigaction[signum-1].sa_flags & SA_NOMASK)
		current->sigaction[signum-1].sa_mask = 0;
	else
		current->sigaction[signum-1].sa_mask |= (1<<(signum-1));
    2a68:	ba 01 00 00 00       	mov    $0x1,%edx
    2a6d:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
    2a72:	d3 e2                	shl    %cl,%edx
    2a74:	09 55 04             	or     %edx,0x4(%ebp)
    2a77:	eb 21                	jmp    2a9a <sys_sigaction+0xd5>
{
	struct task_struct* current = get_current_task();
	struct sigaction tmp;

	if (signum<1 || signum>32 || signum==SIGKILL)
		return -1;
    2a79:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    2a7e:	eb 1a                	jmp    2a9a <sys_sigaction+0xd5>

static inline void save_old(char * from,char * to)
{
	int i;

	verify_area(to, sizeof(struct sigaction));
    2a80:	83 ec 08             	sub    $0x8,%esp
    2a83:	6a 10                	push   $0x10
    2a85:	56                   	push   %esi
    2a86:	e8 fc ff ff ff       	call   2a87 <sys_sigaction+0xc2>
    2a8b:	83 c4 10             	add    $0x10,%esp
    2a8e:	8d 44 24 10          	lea    0x10(%esp),%eax
    2a92:	eb a3                	jmp    2a37 <sys_sigaction+0x72>
	if (signum<1 || signum>32 || signum==SIGKILL)
		return -1;
	tmp = current->sigaction[signum-1];
	get_new((char *) action,
		(char *) (signum-1+current->sigaction));
	if (oldaction)
    2a94:	85 f6                	test   %esi,%esi
    2a96:	75 e8                	jne    2a80 <sys_sigaction+0xbb>
    2a98:	eb b1                	jmp    2a4b <sys_sigaction+0x86>
	if (current->sigaction[signum-1].sa_flags & SA_NOMASK)
		current->sigaction[signum-1].sa_mask = 0;
	else
		current->sigaction[signum-1].sa_mask |= (1<<(signum-1));
	return 0;
}
    2a9a:	83 c4 2c             	add    $0x2c,%esp
    2a9d:	5b                   	pop    %ebx
    2a9e:	5e                   	pop    %esi
    2a9f:	5f                   	pop    %edi
    2aa0:	5d                   	pop    %ebp
    2aa1:	c3                   	ret    

00002aa2 <do_signal>:

void do_signal(long signr,long eax, long ebx, long ecx, long edx,
	long fs, long es, long ds,
	long eip, long cs, long eflags,
	unsigned long * esp, long ss)
{
    2aa2:	55                   	push   %ebp
    2aa3:	57                   	push   %edi
    2aa4:	56                   	push   %esi
    2aa5:	53                   	push   %ebx
    2aa6:	83 ec 0c             	sub    $0xc,%esp
    2aa9:	8b 6c 24 20          	mov    0x20(%esp),%ebp
	struct task_struct* current = get_current_task();
    2aad:	e8 fc ff ff ff       	call   2aae <do_signal+0xc>
    2ab2:	89 c7                	mov    %eax,%edi
	unsigned long sa_handler;
	long old_eip=eip;
	struct sigaction * sa = current->sigaction + signr - 1;
    2ab4:	89 e8                	mov    %ebp,%eax
    2ab6:	c1 e0 04             	shl    $0x4,%eax
    2ab9:	8d 34 38             	lea    (%eax,%edi,1),%esi
	int longs;
	unsigned long * tmp_esp;

	sa_handler = (unsigned long) sa->sa_handler;
    2abc:	8b 06                	mov    (%esi),%eax
	if (sa_handler==1)
    2abe:	83 f8 01             	cmp    $0x1,%eax
    2ac1:	0f 84 a6 00 00 00    	je     2b6d <do_signal+0xcb>
		return;
	if (!sa_handler) {
    2ac7:	85 c0                	test   %eax,%eax
    2ac9:	75 1f                	jne    2aea <do_signal+0x48>
		if (signr==SIGCHLD)
    2acb:	83 fd 11             	cmp    $0x11,%ebp
    2ace:	0f 84 99 00 00 00    	je     2b6d <do_signal+0xcb>
			return;
		else
			do_exit(1<<(signr-1));
    2ad4:	83 ec 0c             	sub    $0xc,%esp
    2ad7:	8d 4d ff             	lea    -0x1(%ebp),%ecx
    2ada:	b8 01 00 00 00       	mov    $0x1,%eax
    2adf:	d3 e0                	shl    %cl,%eax
    2ae1:	50                   	push   %eax
    2ae2:	e8 fc ff ff ff       	call   2ae3 <do_signal+0x41>
    2ae7:	83 c4 10             	add    $0x10,%esp
	}
	if (sa->sa_flags & SA_ONESHOT)
    2aea:	8b 46 08             	mov    0x8(%esi),%eax
    2aed:	85 c0                	test   %eax,%eax
    2aef:	79 06                	jns    2af7 <do_signal+0x55>
		sa->sa_handler = NULL;
    2af1:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
	*(&eip) = sa_handler;
	longs = (sa->sa_flags & SA_NOMASK)?7:8;
    2af7:	25 00 00 00 40       	and    $0x40000000,%eax
    2afc:	83 f8 01             	cmp    $0x1,%eax
    2aff:	19 c0                	sbb    %eax,%eax
    2b01:	f7 d0                	not    %eax
	*(&esp) -= longs;
    2b03:	8d 04 85 20 00 00 00 	lea    0x20(,%eax,4),%eax
    2b0a:	8b 5c 24 4c          	mov    0x4c(%esp),%ebx
    2b0e:	29 c3                	sub    %eax,%ebx
	verify_area(esp,longs*4);
    2b10:	83 ec 08             	sub    $0x8,%esp
    2b13:	50                   	push   %eax
    2b14:	53                   	push   %ebx
    2b15:	e8 fc ff ff ff       	call   2b16 <do_signal+0x74>
__asm__ ("movw %0,%%fs:%1"::"r" (val),"m" (*addr));
}

static inline void put_fs_long(unsigned long val,unsigned long * addr)
{
__asm__ ("movl %0,%%fs:%1"::"r" (val),"m" (*addr));
    2b1a:	8b 46 0c             	mov    0xc(%esi),%eax
    2b1d:	64 89 03             	mov    %eax,%fs:(%ebx)
	tmp_esp=esp;
	put_fs_long((long) sa->sa_restorer,tmp_esp++);
	put_fs_long(signr,tmp_esp++);
    2b20:	8d 43 08             	lea    0x8(%ebx),%eax
    2b23:	64 89 6b 04          	mov    %ebp,%fs:0x4(%ebx)
	if (!(sa->sa_flags & SA_NOMASK))
    2b27:	83 c4 10             	add    $0x10,%esp
    2b2a:	f6 46 0b 40          	testb  $0x40,0xb(%esi)
    2b2e:	75 0d                	jne    2b3d <do_signal+0x9b>
		put_fs_long(current->blocked,tmp_esp++);
    2b30:	8d 43 0c             	lea    0xc(%ebx),%eax
    2b33:	8b 97 10 02 00 00    	mov    0x210(%edi),%edx
    2b39:	64 89 53 08          	mov    %edx,%fs:0x8(%ebx)
    2b3d:	8b 54 24 24          	mov    0x24(%esp),%edx
    2b41:	64 89 10             	mov    %edx,%fs:(%eax)
    2b44:	8b 54 24 2c          	mov    0x2c(%esp),%edx
    2b48:	64 89 50 04          	mov    %edx,%fs:0x4(%eax)
    2b4c:	8b 54 24 30          	mov    0x30(%esp),%edx
    2b50:	64 89 50 08          	mov    %edx,%fs:0x8(%eax)
    2b54:	8b 54 24 48          	mov    0x48(%esp),%edx
    2b58:	64 89 50 0c          	mov    %edx,%fs:0xc(%eax)
    2b5c:	8b 54 24 40          	mov    0x40(%esp),%edx
    2b60:	64 89 50 10          	mov    %edx,%fs:0x10(%eax)
	put_fs_long(eax,tmp_esp++);
	put_fs_long(ecx,tmp_esp++);
	put_fs_long(edx,tmp_esp++);
	put_fs_long(eflags,tmp_esp++);
	put_fs_long(old_eip,tmp_esp++);
	current->blocked |= sa->sa_mask;
    2b64:	8b 46 04             	mov    0x4(%esi),%eax
    2b67:	09 87 10 02 00 00    	or     %eax,0x210(%edi)
}
    2b6d:	83 c4 0c             	add    $0xc,%esp
    2b70:	5b                   	pop    %ebx
    2b71:	5e                   	pop    %esi
    2b72:	5f                   	pop    %edi
    2b73:	5d                   	pop    %ebp
    2b74:	c3                   	ret    

00002b75 <kernel_mktime>:
	DAY*(31+29+31+30+31+30+31+31+30+31),
	DAY*(31+29+31+30+31+30+31+31+30+31+30)
};

long kernel_mktime(struct tm * tm)
{
    2b75:	53                   	push   %ebx
    2b76:	8b 4c 24 08          	mov    0x8(%esp),%ecx
	long res;
	int year;

	year = tm->tm_year - 70;
    2b7a:	8b 51 14             	mov    0x14(%ecx),%edx
/* magic offsets (y+1) needed to get leapyears right.*/
	res = YEAR*year + DAY*((year+1)/4);
    2b7d:	8d 42 be             	lea    -0x42(%edx),%eax
    2b80:	89 d3                	mov    %edx,%ebx
    2b82:	83 eb 45             	sub    $0x45,%ebx
    2b85:	0f 48 d8             	cmovs  %eax,%ebx
    2b88:	c1 fb 02             	sar    $0x2,%ebx
    2b8b:	69 db 80 51 01 00    	imul   $0x15180,%ebx,%ebx
    2b91:	8d 42 ba             	lea    -0x46(%edx),%eax
    2b94:	69 c0 80 33 e1 01    	imul   $0x1e13380,%eax,%eax
    2b9a:	01 d8                	add    %ebx,%eax
	res += month[tm->tm_mon];
    2b9c:	8b 59 10             	mov    0x10(%ecx),%ebx
    2b9f:	03 04 9d e0 00 00 00 	add    0xe0(,%ebx,4),%eax
/* and (y+2) here. If it wasn't a leap-year, we have to adjust */
	if (tm->tm_mon>1 && ((year+2)%4))
    2ba6:	83 fb 01             	cmp    $0x1,%ebx
    2ba9:	7e 0e                	jle    2bb9 <kernel_mktime+0x44>
    2bab:	83 e2 03             	and    $0x3,%edx
		res -= DAY;
    2bae:	8d 98 80 ae fe ff    	lea    -0x15180(%eax),%ebx
    2bb4:	85 d2                	test   %edx,%edx
    2bb6:	0f 45 c3             	cmovne %ebx,%eax
	res += DAY*(tm->tm_mday-1);
    2bb9:	8b 51 0c             	mov    0xc(%ecx),%edx
    2bbc:	83 ea 01             	sub    $0x1,%edx
    2bbf:	69 d2 80 51 01 00    	imul   $0x15180,%edx,%edx
    2bc5:	01 d0                	add    %edx,%eax
	res += HOUR*tm->tm_hour;
    2bc7:	69 51 08 10 0e 00 00 	imul   $0xe10,0x8(%ecx),%edx
    2bce:	01 d0                	add    %edx,%eax
	res += MINUTE*tm->tm_min;
    2bd0:	6b 51 04 3c          	imul   $0x3c,0x4(%ecx),%edx
    2bd4:	01 d0                	add    %edx,%eax
	res += tm->tm_sec;
	return res;
    2bd6:	03 01                	add    (%ecx),%eax
}
    2bd8:	5b                   	pop    %ebx
    2bd9:	c3                   	ret    

00002bda <get_gdt_idt_addr>:

/*
 *  Because of current processor doesn't support vmcs_shadow, so in Guest-Env using vmread or vmwrite will cause VM-EXIT,
 *  So using sgdt and sidt to get gdt/idt base-addr instead of vmread.
 */
unsigned long get_gdt_idt_addr(unsigned long gdt_idt_identity) {
    2bda:	83 ec 10             	sub    $0x10,%esp
	unsigned char table_base[8] = {0,}; /* 16-bit limit stored in low two bytes, and idt_base stored in high 4bytes. */
    2bdd:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
    2be4:	00 
    2be5:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
    2bec:	00 
	unsigned long base_addr = 0;
	if (gdt_idt_identity == GDT_IDENTITY_NO) {
    2bed:	83 7c 24 14 00       	cmpl   $0x0,0x14(%esp)
    2bf2:	75 0b                	jne    2bff <get_gdt_idt_addr+0x25>
		__asm__ ("sgdt %1\n\r"   \
    2bf4:	0f 01 44 24 08       	sgdtl  0x8(%esp)
    2bf9:	8b 44 24 0a          	mov    0xa(%esp),%eax
    2bfd:	eb 09                	jmp    2c08 <get_gdt_idt_addr+0x2e>
				 "movl %2,%%eax\n\r" \
				 :"=a" (base_addr):"m" (*table_base),"m" (*(char*)(table_base+2)));
	} else {
		__asm__ ("sidt %1\n\r"   \
    2bff:	0f 01 4c 24 08       	sidtl  0x8(%esp)
    2c04:	8b 44 24 0a          	mov    0xa(%esp),%eax
				 "movl %2,%%eax\n\r" \
				 :"=a" (base_addr):"m" (*table_base),"m" (*(char*)(table_base+2)));
	}

	return base_addr;
}
    2c08:	83 c4 10             	add    $0x10,%esp
    2c0b:	c3                   	ret    
