#
# Copyright 2004 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#
# lib/libldap5/sparc/Makefile
#

PR_MDUSOBJS = os_SunOS.o

include ../Makefile.com

DYNFLAGS +=	-R$(NSS_LDPATH)


all: $(LIBS)

install: all $(ROOTLIBS) $(ROOTLINKS) $(ROOTLINT)
