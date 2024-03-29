/*
 *  linux/kernel/tty_io.c
 *
 *  (C) 1991  Linus Torvalds
 */

/*
 * 'tty_io.c' gives an orthogonal feeling to tty's, be they consoles
 * or rs-channels. It also implements echoing, cooked mode etc.
 *
 * Kill-line thanks to John T Kohl.
 */
#include <ctype.h>
#include <errno.h>
#include <signal.h>
#include <linux/head.h>
#include <linux/sched.h>
#include <linux/tty.h>
#include <asm/segment.h>
#include <asm/system.h>
#include <asm/io.h>

#define ALRMMASK (1<<(SIGALRM-1))
#define KILLMASK (1<<(SIGKILL-1))
#define INTMASK (1<<(SIGINT-1))
#define QUITMASK (1<<(SIGQUIT-1))
#define TSTPMASK (1<<(SIGTSTP-1))

#define _L_FLAG(tty,f)	((tty)->termios.c_lflag & f)
#define _I_FLAG(tty,f)	((tty)->termios.c_iflag & f)
#define _O_FLAG(tty,f)	((tty)->termios.c_oflag & f)

#define L_CANON(tty)	_L_FLAG((tty),ICANON)
#define L_ISIG(tty)  	_L_FLAG((tty),ISIG)
#define L_ECHO(tty) 	_L_FLAG((tty),ECHO)
#define L_ECHOE(tty)	_L_FLAG((tty),ECHOE)
#define L_ECHOK(tty)	_L_FLAG((tty),ECHOK)
#define L_ECHOCTL(tty)	_L_FLAG((tty),ECHOCTL)
#define L_ECHOKE(tty)	_L_FLAG((tty),ECHOKE)

#define I_UCLC(tty)	_I_FLAG((tty),IUCLC)
#define I_NLCR(tty)	_I_FLAG((tty),INLCR)
#define I_CRNL(tty)	_I_FLAG((tty),ICRNL)
#define I_NOCR(tty)	_I_FLAG((tty),IGNCR)

#define O_POST(tty)	    _O_FLAG((tty),OPOST)
#define O_NLCR(tty)	    _O_FLAG((tty),ONLCR)
#define O_CRNL(tty)	    _O_FLAG((tty),OCRNL)
#define O_NLRET(tty)	_O_FLAG((tty),ONLRET)
#define O_LCUC(tty)	    _O_FLAG((tty),OLCUC)

unsigned long tty_io_semaphore = 0;
extern unsigned short	video_port_reg;		/* Video register select port	*/

struct tty_struct tty_table[] = {
	{
		{ICRNL,		/* change incoming CR to NL */
		OPOST|ONLCR,	/* change outgoing NL to CRNL */
		0,
		ISIG | ICANON | ECHO | ECHOCTL | ECHOKE,
		0,		/* console termio */
		INIT_C_CC},
		0,			/* initial pgrp */
		0,			/* initial stopped */
		con_write,
		{0,0,0,0,""},		/* console read-queue */
		{0,0,0,0,""},		/* console write-queue */
		{0,0,0,0,""}		/* console secondary queue */
	},{
		{0, /* no translation */
		0,  /* no translation */
		B2400 | CS8,
		0,
		0,
		INIT_C_CC},
		0,
		0,
		rs_write,
		{0x3f8,0,0,0,""},		/* rs 1 */
		{0x3f8,0,0,0,""},
		{0,0,0,0,""}
	},{
		{0, /* no translation */
		0,  /* no translation */
		B2400 | CS8,
		0,
		0,
		INIT_C_CC},
		0,
		0,
		rs_write,
		{0x2f8,0,0,0,""},		/* rs 2 */
		{0x2f8,0,0,0,""},
		{0,0,0,0,""}
	}
};

/*
 * these are the tables used by the machine code handlers.
 * you can implement pseudo-tty's or something by changing
 * them. Currently not done.
 */
struct tty_queue * table_list[]={
	&tty_table[0].read_q, &tty_table[0].write_q,
	&tty_table[1].read_q, &tty_table[1].write_q,
	&tty_table[2].read_q, &tty_table[2].write_q
	};

void tty_init(void)
{
	rs_init();
	con_init();
}

void tty_intr(struct tty_struct * tty, int mask)
{
	int i;

	if (tty->pgrp <= 0)
		return;
	for (i=0;i<NR_TASKS;i++)
		if (task[i] && task[i]->pgrp==tty->pgrp)
			task[i]->signal |= mask;
}

static void sleep_if_empty(struct tty_queue * queue)
{
	struct task_struct* current = get_current_task();
	cli();
	while (!current->signal && EMPTY(*queue))
		interruptible_sleep_on(&queue->proc_list);
	sti();
}

static void sleep_if_full(struct tty_queue * queue)
{
	struct task_struct* current = get_current_task();
	if (!FULL(*queue))
		return;
	cli();
	while (!current->signal && LEFT(*queue)<128)
		interruptible_sleep_on(&queue->proc_list);
	sti();
}

void wait_for_keypress(void)
{
	sleep_if_empty(&tty_table[0].secondary);
}

void copy_to_cooked(struct tty_struct * tty)
{
	signed char c;

	while (!EMPTY(tty->read_q) && !FULL(tty->secondary)) {
		GETCH(tty->read_q,c);
		if (c==13)
			if (I_CRNL(tty))
				c=10;
			else if (I_NOCR(tty))
				continue;
			else ;
		else if (c==10 && I_NLCR(tty))
			c=13;
		if (I_UCLC(tty))
			c=tolower(c);
		if (L_CANON(tty)) {
			if (c==KILL_CHAR(tty)) {
				/* deal with killing the input line */
				while(!(EMPTY(tty->secondary) ||
				        (c=LAST(tty->secondary))==10 ||
				        c==EOF_CHAR(tty))) {
					if (L_ECHO(tty)) {
						if (c<32)
							PUTCH(127,tty->write_q);
						PUTCH(127,tty->write_q);
						tty->write(tty);
					}
					DEC(tty->secondary.head);
				}
				continue;
			}
			if (c==ERASE_CHAR(tty)) {
				if (EMPTY(tty->secondary) ||
				   (c=LAST(tty->secondary))==10 ||
				   c==EOF_CHAR(tty))
					continue;
				if (L_ECHO(tty)) {
					if (c<32)
						PUTCH(127,tty->write_q);
					PUTCH(127,tty->write_q);
					tty->write(tty);
				}
				DEC(tty->secondary.head);
				continue;
			}
			if (c==STOP_CHAR(tty)) {
				tty->stopped=1;
				continue;
			}
			if (c==START_CHAR(tty)) {
				tty->stopped=0;
				continue;
			}
		}
		if (L_ISIG(tty)) {
			if (c==INTR_CHAR(tty)) {
				tty_intr(tty,INTMASK);
				continue;
			}
			if (c==QUIT_CHAR(tty)) {
				tty_intr(tty,QUITMASK);
				continue;
			}
		}
		if (c==10 || c==EOF_CHAR(tty))
			tty->secondary.data++;
		if (L_ECHO(tty)) {
			if (c==10) {
				PUTCH(10,tty->write_q);
				PUTCH(13,tty->write_q);
			} else if (c<32) {
				if (L_ECHOCTL(tty)) {
					PUTCH('^',tty->write_q);
					PUTCH(c+64,tty->write_q);
				}
			} else
				PUTCH(c,tty->write_q);
			tty->write(tty);
		}
		PUTCH(c,tty->secondary);
	}
	wake_up(&tty->secondary.proc_list);
}

int tty_read(unsigned channel, char * buf, int nr)
{
	struct task_struct* current = get_current_task();
	struct tty_struct * tty;
	char c, * b=buf;
	int minimum,time,flag=0;
	long oldalarm;

	if (channel>2 || nr<0) return -1;
	tty = &tty_table[channel];
	oldalarm = current->alarm;
	time = 10L*tty->termios.c_cc[VTIME];
	minimum = tty->termios.c_cc[VMIN];
	if (time && !minimum) {
		minimum=1;
		if (flag=(!oldalarm || time+jiffies<oldalarm))
			current->alarm = time+jiffies;
	}
	if (minimum>nr)
		minimum=nr;
	while (nr>0) {
		if (flag && (current->signal & ALRMMASK)) {
			current->signal &= ~ALRMMASK;
			break;
		}
		if (current->signal)
			break;
		if (EMPTY(tty->secondary) || (L_CANON(tty) &&
		!tty->secondary.data && LEFT(tty->secondary)>20)) {
			sleep_if_empty(&tty->secondary);
			continue;
		}
		do {
			GETCH(tty->secondary,c);
			if (c==EOF_CHAR(tty) || c==10)
				tty->secondary.data--;
			if (c==EOF_CHAR(tty) && L_CANON(tty))
				return (b-buf);
			else {
				put_fs_byte(c,b++);
				if (!--nr)
					break;
			}
		} while (nr>0 && !EMPTY(tty->secondary));
		if (time && !L_CANON(tty))
			if (flag=(!oldalarm || time+jiffies<oldalarm))
				current->alarm = time+jiffies;
			else
				current->alarm = oldalarm;
		if (L_CANON(tty)) {
			if (b-buf)
				break;
		} else if (b-buf >= minimum)
			break;
	}
	current->alarm = oldalarm;
	if (current->signal && !(b-buf))
		return -EINTR;
	return (b-buf);
}

int tty_write(unsigned channel, char * buf, int nr)
{
	/* 用户态执行printf系统调用到该方法，执行打印功能，这时要触发VM-EXIT,到host中打印.
	 * Cause VM-EXIT, Using host print to instead of Guest print.
	 * printk方法是走不到这里的，能执行到这里一定是在内核态执行了printf方法
	 *
	 * 我们知道在fork新进程的时候，是将内核代码和数据区都设置为RO状态了，所以printf中对user_print_buf写操作会触发WP,
	 * 进而为它分配一个新的物理页，所以这里user_print_buf的地址必须加上用户态DS的基地址，形成完整的linear-addr传给VMM,
	 * VMM通过EPT表得到其实际映射的物理地址，才能打印处正确的数据，尼玛巨坑啊，又是排查了一天。
	 *
	 * 举例说明最清楚了：
	 * user_print_buf base_addr=0xc80040，将该值赋值给exit_reason_io_vedio_p->print_buf = buf，VMM直接取该地址处的值为空。
	 * 所以要加上DS(user_mode) base: 0x40000000 + 0xc80040
	 * CR2=40c80040(linear-addr)  0100000011 0010000000 000001000000
     *   1. 通过CR3中存储guest-phy-add,经过EPT-page-structure转换可以得到，该40c80000(linear-addr page)所在的页表的guest-phy-addr = 0x7fffc000
     *   2. guest-phy-addr = 0x7fffc000 再经过EPT-page-structure转换可以得到其实际物理地址phy-addr=0x08add000
     *   3. 取该地址处(0x08add000+0010000000b*4)的值，就得到了40c80000该线性页对应的guest-phy-addr地址了(guest-page-addr=0x7fff9000)
     *   4. guest-page-addr=0x7fff9000还要再次经过经过EPT-page-structure转化就得到实际的物理页:0x08ada000
     *
     *   (gdb) x /32wx 0x08ada000
				0x8ada000:      0x00000000      0x00000000      0x00000000      0x00000000
				0x8ada010:      0x00000000      0x00000000      0x00000000      0x00000000
				0x8ada020:      0x7fffffff      0x01400000      0x0007ec00      0x00001400
				0x8ada030:      0x00001000      0x00080000      0x00000000      0x00000000
                页内offset=000001000000=0x40处才是在用户态实际要打印的数据啊，尼玛我容易吗哈哈
				0x8ada040:      0x73657547      0x3a534f74      0x32343220      0x75622039
				0x8ada050:      0x72656666      0x203d2073      0x37383432      0x20363932
				0x8ada060:      0x65747962      0x75622073      0x72656666      0x61707320
				0x8ada070:      0x0d0a6563      0x00000000      0x00000000      0x00000000
	 */
	struct task_struct* current = get_current_task();
	exit_reason_io_vedio_struct* exit_reason_io_vedio_p = (exit_reason_io_vedio_struct*) VM_EXIT_REASON_IO_INFO_ADDR;
	exit_reason_io_vedio_p->exit_reason_no = VM_EXIT_REASON_IO_INSTRUCTION;
	exit_reason_io_vedio_p->print_size = nr;
	exit_reason_io_vedio_p->print_buf = buf + get_base(current->ldt[2]); /* 这了一定要加上ds.base */
	cli();
	outb_p(14, video_port_reg);  /* 触发VM-EXIT */
	sti();
	return nr;

	int lock_flag = 1;  /* 加锁成功了，设置为1 */
	static cr_flag=0;
	struct tty_struct * tty;
	char c, *b=buf;

	if (channel>2 || nr<0) {
		if (lock_flag) {
			lock_flag = 0;
			unlock_op(&tty_io_semaphore);
		}
		return -1;
	}
	tty = channel + tty_table;
	while (nr>0) {
		sleep_if_full(&tty->write_q);
		/* 这个bug埋的好深啊，因为AP初始化的时候都没有指定default task，所以AP在执行ljmp tss之前的current=0，所以这里要判断下。 */
		if (current && current->signal)
			break;
		while (nr>0 && !FULL(tty->write_q)) {
			/*
			 * 这里还是有必要解释一下的:
			 * 对于printf方法：因为要打印的内容来源于用户态，所以这时fs指向的是用户态的选择子.
			 * 对于printk方法: 因为要打印的内容来源于内核态，所以这时fs指向的是内核态的选择子.
			 * 这样就是为什么上面的exit_reason_io_vedio_p一定要加上用户态的ds.base才能正确访问用户态的数据.
			 */
			c=get_fs_byte(b);
			if (O_POST(tty)) {
				if (c=='\r' && O_CRNL(tty))
					c='\n';
				else if (c=='\n' && O_NLRET(tty))
					c='\r';
				if (c=='\n' && !cr_flag && O_NLCR(tty)) {
					cr_flag = 1;
					PUTCH(13,tty->write_q);
					continue;
				}
				if (O_LCUC(tty))
					c=toupper(c);
			}
			b++; nr--;
			cr_flag = 0;
			PUTCH(c,tty->write_q);
		}
		tty->write(tty);
		if (lock_flag) {
			lock_flag = 0;
			unlock_op(&tty_io_semaphore);
		}
		if (nr>0) {
			schedule();
		}
	}
	if (lock_flag) {
		lock_flag = 0;
		unlock_op(&tty_io_semaphore);
	}
	return (b-buf);
}

/*
 * Jeh, sometimes I really like the 386.
 * This routine is called from an interrupt,
 * and there should be absolutely no problem
 * with sleeping even in an interrupt (I hope).
 * Of course, if somebody proves me wrong, I'll
 * hate intel for all time :-). We'll have to
 * be careful and see to reinstating the interrupt
 * chips before calling this, though.
 *
 * I don't think we sleep here under normal circumstances
 * anyway, which is good, as the task sleeping might be
 * totally innocent.
 */
void do_tty_interrupt(int tty)
{
	copy_to_cooked(tty_table+tty);
}

void chr_dev_init(void)
{
}
