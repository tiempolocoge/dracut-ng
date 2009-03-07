/*
 * switchroot.c - switch to new root directory and start init.
 *
 * Copyright 2002-2008 Red Hat, Inc.  All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors:
 * 	Peter Jones <pjones@redhat.com>
 *	Jeremy Katz <katzj@redhat.com>
 */

#define _GNU_SOURCE 1

#include <sys/mount.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/param.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <ctype.h>

#ifndef MS_MOVE
#define MS_MOVE 8192
#endif

#ifndef MNT_DETACH
#define MNT_DETACH 0x2
#endif

enum {
	ok,
	err_no_directory,
	err_usage,
};

static int switchroot(const char *newroot)
{
	/*  Don't try to unmount the old "/", there's no way to do it. */
	const char *umounts[] = { "/dev", "/proc", "/sys", NULL };
	int errnum;
	int i;

	for (i = 0; umounts[i] != NULL; i++) {
		char newmount[PATH_MAX];
		strcpy(newmount, newroot);
		strcat(newmount, umounts[i]);
		if (mount(umounts[i], newmount, NULL, MS_MOVE, NULL) < 0) {
			fprintf(stderr, "Error mount moving old %s %s %m\n",
				umounts[i], newmount);
			fprintf(stderr, "Forcing unmount of %s\n", umounts[i]);
			umount2(umounts[i], MNT_FORCE);
		}
	}

	if (chdir(newroot) < 0) {
	  errnum=errno;
	  fprintf(stderr, "switchroot: chdir failed: %m\n");
	  errno=errnum;
	  return -1;
	}

	if (mount(newroot, "/", NULL, MS_MOVE, NULL) < 0) {
		errnum = errno;
		fprintf(stderr, "switchroot: mount failed: %m\n");
		errno = errnum;
		return -1;
	}

	if (chroot(".")) {
		errnum = errno;
		fprintf(stderr, "switchroot: chroot failed: %m\n");
		errno = errnum;
		return -2;
	}
	return 1;
}

static void usage(FILE *output)
{
	fprintf(output, "usage: switchroot <newrootdir> <init> <args to init>\n");
	if (output == stderr)
		exit(err_usage);
	exit(ok);
}

int main(int argc, char *argv[])
{
	char *newroot = argv[1];
	char *init = argv[2];
	char **initargs = &argv[2];
      
	if (newroot == NULL || newroot[0] == '\0' ||
	    init == NULL || init[0] == '\0' ) {
		usage(stderr);
	}

	if (switchroot(newroot) < 0) {
	  fprintf(stderr, "switchroot has failed.  Sorry.\n");
	  return 1;
	}
	if (access(initargs[0], X_OK))
	  fprintf(stderr, "WARNING: can't access %s\n", initargs[0]);
	execv(initargs[0], initargs);
}

/*
 * vim:noet:ts=8:sw=8:sts=8
 */
