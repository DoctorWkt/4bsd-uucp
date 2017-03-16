/* This program extracts tape records from a SimH TAP image

   Copyright (c) 1993-1999, Robert M. Supnik
   Copyright (c) 2017, Warren Toomey

   Permission is hereby granted, free of charge, to any person obtaining a
   copy of this software and associated documentation files (the "Software"),
   to deal in the Software without restriction, including without limitation
   the rights to use, copy, modify, merge, publish, distribute, sublicense,
   and/or sell copies of the Software, and to permit persons to whom the
   Software is furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in
   all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
   ROBERT M SUPNIK OR WARREN TOOMEY BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
   DEALINGS IN THE SOFTWARE.

   Except as contained in this notice, the name of Robert M Supnik or
   Warren Toomey shall not be used in advertising or otherwise to promote the
   sale, use or other dealings in this Software without prior written
   authorization from Robert M Supnik or Warren Toomey.
*/

#include <stddef.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#define FLPSIZ 65536

int main(int argc, char *argv[])
{
    int i, k, wc, rc;
    unsigned char bc[4] = { 0 };
    unsigned char buf[FLPSIZ];
    char *progname = argv[0];
    char *ppos, oname[256];
    FILE *ifile, *ofile;

    if (argc < 2) {
	fprintf(stderr, "Usage:  %s image.tap {file1 ...}\n", progname);
	fprintf(stderr,
		"Extract records from image.tap to file1, file2, ....\n");
	exit(0);
    }

    ifile = fopen(argv[1], "rb");
    if (ifile == NULL) {
	printf("Error opening file: %s\n", argv[1]);
	exit(0);
    }
    for (i = 2; i < argc; i++) {
	ofile = fopen(argv[i], "wb");
	if (ofile == NULL) {
	    printf("Error opening file: %s\n", argv[i]);
	    exit(0);
	}

	printf("Processing file %s ... ", argv[i]);
	rc = 0;
	for (;;) {
	    k = fread(bc, sizeof(char), 4, ifile);
	    if (k == 0) {
		break;
	    }
	    if (bc[2] | bc[3]) {
		printf
		    ("Invalid record size, record %d, size = 0x%02X%02X%02X%02X\n",
		     rc, bc[3], bc[2], bc[1], bc[0]);
		break;
	    }
	    wc = ((unsigned int) bc[1] << 8) | (unsigned int) bc[0];
	    wc = (wc + 1) & ~1;
	    if (wc) {
		k = fread(buf, sizeof(char), wc, ifile);
		for (; k < wc; k++)
		    buf[k] = 0;
		fwrite(buf, sizeof(char), wc, ofile);
		k = fread(bc, sizeof(char), 4, ifile);
		rc++;
	    } else {
		if (rc)
		    printf("end of file, record count = %d\n", rc);
		else {
		    break;
		}
		rc = 0;
	    }
	}
	fclose(ofile);
    }
    fclose(ifile);

    return 0;
}
