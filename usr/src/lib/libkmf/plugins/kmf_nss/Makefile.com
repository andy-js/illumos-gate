#
# CDDL HEADER START
#
# The contents of this file are subject to the terms of the
# Common Development and Distribution License (the "License").
# You may not use this file except in compliance with the License.
#
# You can obtain a copy of the license at usr/src/OPENSOLARIS.LICENSE
# or http://www.opensolaris.org/os/licensing.
# See the License for the specific language governing permissions
# and limitations under the License.
#
# When distributing Covered Code, include this CDDL HEADER in each
# file and include the License file at usr/src/OPENSOLARIS.LICENSE.
# If applicable, add the following below this CDDL HEADER, with the
# fields enclosed by brackets "[]" replaced with your own identifying
# information: Portions Copyright [yyyy] [name of copyright owner]
#
# CDDL HEADER END
#
#
# Copyright 2008 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#
# Copyright 2018 RackTop Systems.
# Copyright (c) 2018, Joyent, Inc.
#

LIBRARY=	kmf_nss.a
VERS=		.1

OBJECTS=	nss_spi.o

include	$(SRC)/lib/Makefile.lib

MPSDIR=		/usr/lib/mps
MPSDIR64=	$(MPSDIR)/64
KMFINC=		-I../../../include -I../../../ber_der/inc
NSSINC=		-I$(ADJUNCT_PROTO)/usr/include/mps
BERLIB=		-lkmf -lkmfberder
BERLIB64=	$(BERLIB)

NSSLIBS=	$(BERLIB) -R$(MPSDIR) -lnss3 -lnspr4 -lsmime3 -lc
NSSLIBS64=	$(BERLIB64) -R$(MPSDIR64) -lnss3 -lnspr4 -lsmime3 -lc

# Allow NSS libraries to be taken from outside the proto area.
$(ADJUNCT_PROTO_NOT_SET)DYNFLAGS += $(ZASSERTDEFLIB)=libnss3.so
$(ADJUNCT_PROTO_NOT_SET)DYNFLAGS += $(ZASSERTDEFLIB)=libnspr4.so
$(ADJUNCT_PROTO_NOT_SET)DYNFLAGS += $(ZASSERTDEFLIB)=libsmime3.so

# Override the default linker path so that libraries found in the host
# directories will trigger -zassert-deflib logic.
LDLIBS32	+= -YP,$(DEFLDPATH):$(MPSDIR)
LDLIBS64	+= -YP,$(DEFLDPATH64):$(MPSDIR64)

# Only add -L options for the NSS directories if ADJUNCT_PROTO is being
# used because it disables the -zassert-deflib logic.
$(ADJUNCT_PROTO_SET)LDLIBS32	+= -L$(ADJUNCT_PROTO)$(MPSDIR)
$(ADJUNCT_PROTO_SET)LDLIBS64	+= -L$(ADJUNCT_PROTO)$(MPSDIR64)

SRCDIR=		../common
INCDIR=		../../include

CFLAGS		+=	$(CCVERBOSE)
CPPFLAGS	+=	-D_REENTRANT $(KMFINC) $(NSSINC)  \
		-I$(INCDIR) -I$(ADJUNCT_PROTO)/usr/include/libxml2

PICS=	$(OBJECTS:%=pics/%)

LINTFLAGS	+=	-erroff=E_STATIC_UNUSED
LINTFLAGS64	+=	-erroff=E_STATIC_UNUSED

CERRWARN	+=	-_gcc=-Wno-unused-label
CERRWARN	+=	-_gcc=-Wno-unused-value
CERRWARN	+=	$(CNOWARN_UNINIT)

# not linted
SMATCH=off

lint:=	NSSLIBS =	$(BERLIB)
lint:=	NSSLIBS64 =	$(BERLIB64)

LDLIBS32	+=	$(NSSLIBS)

LIBS	=	$(DYNLIB)

ROOTLIBDIR=	$(ROOTFS_LIBDIR)/crypto
ROOTLIBDIR64=	$(ROOTFS_LIBDIR)/crypto/$(MACH64)

.KEEP_STATE:

all:	$(LIBS) $(LINTLIB)

lint: lintcheck

FRC:

include $(SRC)/lib/Makefile.targ
