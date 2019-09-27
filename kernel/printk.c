/*
 *  linux/kernel/printk.c
 *
 *  (C) 1991  Linus Torvalds
 */

/*
 * When in kernel-mode, we cannot use printf, as fs is liable to
 * point to 'interesting' things. Make a printf with fs-saving, and
 * all is well.
 */
#include <stdarg.h>
#include <stddef.h>
#include <asm/system.h>
#include <linux/head.h>
#include <linux/kernel.h>
#include <asm/io.h>
#include <linux/sched.h>

char print_buf[1024];

extern int vsprintf(char * buf, const char * fmt, va_list args);

extern unsigned long tty_io_semaphore;
extern unsigned short	video_port_reg;		/* Video register select port	*/

int printk(const char *fmt, ...)
{
	va_list args;
	int i;

	lock_op(&tty_io_semaphore);

	va_start(args, fmt);
	i=vsprintf(print_buf,fmt,args);
	va_end(args);

	/* Cause VM-EXIT, Using host print to instead of Guest print. */
	exit_reason_io_vedio_struct* exit_reason_io_vedio_p = (exit_reason_io_vedio_struct*) VM_EXIT_REASON_IO_INFO_ADDR;
	exit_reason_io_vedio_p->exit_reason_no = VM_EXIT_REASON_IO_INSTRUCTION;
	exit_reason_io_vedio_p->print_size = i;
	exit_reason_io_vedio_p->print_buf = print_buf + get_base(gdt[2]);  /* 这里要加上内核的ds.base=cs.base形成完整的linear-addr(如果内核base不为0的话) */
	cli();
	outb_p(14, video_port_reg);
	sti();

	unlock_op(&tty_io_semaphore);
	return i;

	__asm__("push %%fs\n\t"
			"push %%ds\n\t"
			"pop %%fs\n\t"
			"pushl %0\n\t"
			"pushl $print_buf\n\t"
			"pushl $0\n\t"
			"call tty_write\n\t"
			"addl $8,%%esp\n\t"
			"popl %0\n\t"
			"pop %%fs"
			::"r" (i):"ax","cx","dx");
	return i;
}

char* cpy_str_to_kernel(char * dest,const char *src)
{
__asm__(
	"push %%ds\n"
	"push %%fs\n\t"
	"pop  %%ds\n\t"
	"cld\n\t"
	"1:\tlodsb\n\t"
	"stosb\n\t"
	"testb %%al,%%al\n\t"
	"jne 1b\n\t"
	"pop %%ds"
	::"S" (src),"D" (dest));
return dest;
}
