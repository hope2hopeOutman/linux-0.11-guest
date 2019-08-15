/*
 *  linux/tools/build.c
 *
 *  (C) 1991  Linus Torvalds
 */

/*
 * This file builds a disk-image from three different files:
 *
 * - bootsect: max 510 bytes of 8086 machine code, loads the rest
 * - setup: max 4 sectors of 8086 machine code, sets up system parm
 * - system: 80386 code for actual system
 *
 * It does some checking that all files are of the correct type, and
 * just writes the result to stdout, removing headers and padding to
 * the right amount. It also writes some system data to stderr.
 */

/*
 * Changes by tytso to allow root device specification
 */

#include <stdio.h>	/* fprintf */
#include <string.h>
#include <stdlib.h>	/* contains exit */
#include <sys/types.h>	/* unistd.h needs this */
#include <sys/stat.h>
#include <linux/fs.h>
#include <unistd.h>	/* contains read/write */
#include <fcntl.h>

#define MINIX_HEADER 32
#define GCC_HEADER 1024

#define SYS_SIZE 0x8000

#define DEFAULT_MAJOR_ROOT 3
#define DEFAULT_MINOR_ROOT 2

/* max nr of sectors of setup: don't change unless you also change
 * bootsect etc */
#define SETUP_SECTS 8

#define STRINGIFY(x) #x

void die(char * str) {
	fprintf(stderr, "%s\n", str);
	exit(1);
}

void usage(void) {
	die("Usage: build (system) [> image]");
}

int main(int argc, char ** argv) {
	int i, c, id;
	char buf[1024];

	if ((argc != 2) && (argc != 3))
		usage();

	for (i = 0; i < sizeof buf; i++)
		buf[i] = 0;


	if ((id = open(argv[1], O_RDONLY, 0)) < 0)
		die("Unable to open 'system'");

	/*if (read(id, buf, GCC_HEADER) != GCC_HEADER)
	 die("Unable to read header of 'system'");*/
	/* Now for latest GCC, the elf file is 4K aligned */
	for (int j = 0; j < 4; j++) {
		if (read(id, buf, GCC_HEADER) != GCC_HEADER)
			die("Unable to read header of 'system'");
	}

	/*if (((long *) buf)[5] != 0)
	 die("Non-GCC header of 'system'");*/
	for (i = 0; (c = read(id, buf, sizeof buf)) > 0; i += c)
		if (write(1, buf, c) != c)
			die("Write call failed");
	close(id);
	fprintf(stderr, "System is %d bytes.\n", i);
	if (i > SYS_SIZE * 16)
		die("System is too big");

	return (0);
}
