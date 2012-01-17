# -*- indent-tabs-mode: t -*-
# vim: noet
# makefile of pianobarfly

PREFIX:=/usr/local
BINDIR:=${PREFIX}/bin
LIBDIR:=${PREFIX}/lib
INCDIR:=${PREFIX}/include
MANDIR:=${PREFIX}/share/man
DYNLINK:=0

MD5SUM=md5sum
AWK=awk
PATCH=patch
TAR=tar
OSNAME=$(shell uname)

# Respect environment variables set by user; does not work with :=
ifeq (${CFLAGS},)
	CFLAGS=-O2 -DNDEBUG
endif
ifeq (${CC},cc)
	CC=c99
endif

ifeq ($(OSNAME), Darwin)
	CC=gcc
	CFLAGS=-std=c99 -02 -DNDEBUG
	MD5SUM=md5
endif

PIANOBAR_DIR=src
PIANOBAR_SRC=\
		${PIANOBAR_DIR}/main.c \
		${PIANOBAR_DIR}/player.c \
		${PIANOBAR_DIR}/settings.c \
		${PIANOBAR_DIR}/terminal.c \
		${PIANOBAR_DIR}/ui_act.c \
		${PIANOBAR_DIR}/ui.c \
		${PIANOBAR_DIR}/ui_readline.c \
		${PIANOBAR_DIR}/ui_dispatch.c \
		${PIANOBAR_DIR}/fly.c \
		${PIANOBAR_DIR}/fly_misc.c \
		${PIANOBAR_DIR}/fly_mp4.c
PIANOBAR_HDR=\
		${PIANOBAR_DIR}/player.h \
		${PIANOBAR_DIR}/settings.h \
		${PIANOBAR_DIR}/terminal.h \
		${PIANOBAR_DIR}/ui_act.h \
		${PIANOBAR_DIR}/ui.h \
		${PIANOBAR_DIR}/ui_readline.h \
		${PIANOBAR_DIR}/main.h \
		${PIANOBAR_DIR}/config.h \
		${PIANOBAR_DIR}/fly.h \
		${PIANOBAR_DIR}/fly_misc.h \
		${PIANOBAR_DIR}/fly_mp4.h
PIANOBAR_OBJ=${PIANOBAR_SRC:.c=.o}

LIBPIANO_DIR=src/libpiano
LIBPIANO_SRC=\
		${LIBPIANO_DIR}/crypt.c \
		${LIBPIANO_DIR}/piano.c \
		${LIBPIANO_DIR}/xml.c
LIBPIANO_HDR=\
		${LIBPIANO_DIR}/config.h \
		${LIBPIANO_DIR}/crypt_key_output.h \
		${LIBPIANO_DIR}/xml.h \
		${LIBPIANO_DIR}/crypt.h \
		${LIBPIANO_DIR}/piano.h \
		${LIBPIANO_DIR}/crypt_key_input.h \
		${LIBPIANO_DIR}/piano_private.h
LIBPIANO_OBJ=${LIBPIANO_SRC:.c=.o}
LIBPIANO_RELOBJ=${LIBPIANO_SRC:.c=.lo}
LIBPIANO_INCLUDE=${LIBPIANO_DIR}

LIBWAITRESS_DIR=src/libwaitress
LIBWAITRESS_SRC=${LIBWAITRESS_DIR}/waitress.c
LIBWAITRESS_HDR=\
		${LIBWAITRESS_DIR}/config.h \
		${LIBWAITRESS_DIR}/waitress.h
LIBWAITRESS_OBJ=${LIBWAITRESS_SRC:.c=.o}
LIBWAITRESS_RELOBJ=${LIBWAITRESS_SRC:.c=.lo}
LIBWAITRESS_INCLUDE=${LIBWAITRESS_DIR}

LIBEZXML_DIR=src/libezxml
LIBEZXML_SRC=${LIBEZXML_DIR}/ezxml.c
LIBEZXML_HDR=${LIBEZXML_DIR}/ezxml.h
LIBEZXML_OBJ=${LIBEZXML_SRC:.c=.o}
LIBEZXML_RELOBJ=${LIBEZXML_SRC:.c=.lo}
LIBEZXML_INCLUDE=${LIBEZXML_DIR}

ifneq (${DISABLE_FAAD}, 1)
	LIBFAAD_CFLAGS=-DENABLE_FAAD
	LIBFAAD_LDFLAGS=-lfaad
endif

ifneq (${DISABLE_MAD}, 1)
ifneq (${OSNAME}, Darwin)
	LIBMAD_CFLAGS=${shell pkg-config --cflags mad} -DENABLE_MAD
	LIBMAD_LDFLAGS=${shell pkg-config --libs mad}
else
	LIBMAD_CFLAGS=-DENABLE_MAD
	LIBMAD_LDFLAGS=-lmad
endif
endif

LIBGNUTLS_CFLAGS=
LIBGNUTLS_LDFLAGS=-lgnutls

ifneq (${DISABLE_ID3TAG}, 1)
#	LIBID3TAG_CFLAGS=${shell pkg-config --cflags id3tag} -DENABLE_ID3TAG
#	LIBID3TAG_LDFLAGS=${shell pkg-config --libs id3tag}
ifeq (${BUILD_ID3LIB}, 1)
	LIBID3TAG_CFLAGS=-DENABLE_ID3TAG -I id3lib-3.8.3/include
	LIBID3TAG_LDFLAGS=-L./id3lib-3.8.3/src/.libs -lid3
else
	LIBID3TAG_CFLAGS=-DENABLE_ID3TAG
	LIBID3TAG_LDFLAGS=-lid3
endif
endif

ifneq (${OSNAME}, Darwin)
	LIBAO_CFLAGS=${shell pkg-config --cflags ao}
	LIBAO_LDFLAGS=${shell pkg-config --libs ao}
else
	LIBAO_CFLAGS=
	LIBAO_LDFLAGS=-lao
endif

# build pianobarfly
ifeq (${DYNLINK},1)
ifeq (${BUILD_ID3LIB}, 1)
pianobarfly: CC=g++
pianobarfly: id3lib-3.8.3 ${PIANOBAR_OBJ} ${PIANOBAR_HDR} libpiano.so.0
else
pianobarfly: ${PIANOBAR_OBJ} ${PIANOBAR_HDR} libpiano.so.0
endif
	@echo "   LINK  $@"
	@${CC} -o $@ ${PIANOBAR_OBJ} ${LDFLAGS} ${LIBAO_LDFLAGS} -lpthread -L. \
			-lpiano ${LIBFAAD_LDFLAGS} ${LIBMAD_LDFLAGS} ${LIBGNUTLS_LDFLAGS} ${LIBID3TAG_LDFLAGS}
else
ifeq (${BUILD_ID3LIB}, 1)
pianobarfly: CC=g++
pianobarfly: id3lib-3.8.3 ${PIANOBAR_OBJ} ${PIANOBAR_HDR} ${LIBPIANO_OBJ} ${LIBWAITRESS_OBJ} \
		${LIBWAITRESS_HDR} ${LIBEZXML_OBJ} ${LIBEZXML_HDR}
else
pianobarfly: ${PIANOBAR_OBJ} ${PIANOBAR_HDR} ${LIBPIANO_OBJ} ${LIBWAITRESS_OBJ} \
		${LIBWAITRESS_HDR} ${LIBEZXML_OBJ} ${LIBEZXML_HDR}
endif
	@echo "   LINK $@ (w/ ${CC})"
	@${CC} ${CFLASG} ${LDFLAGS} ${PIANOBAR_OBJ} ${LIBPIANO_OBJ} \
			${LIBWAITRESS_OBJ} ${LIBEZXML_OBJ} ${LIBAO_LDFLAGS} -lpthread \
			${LIBFAAD_LDFLAGS} ${LIBMAD_LDFLAGS} ${LIBGNUTLS_LDFLAGS} ${LIBID3TAG_LDFLAGS} -o $@
endif

# build shared and static libpiano
libpiano.so.0: ${LIBPIANO_RELOBJ} ${LIBPIANO_HDR} ${LIBWAITRESS_RELOBJ} \
		${LIBWAITRESS_HDR} ${LIBEZXML_RELOBJ} ${LIBEZXML_HDR} \
		${LIBPIANO_OBJ} ${LIBWAITRESS_OBJ} ${LIBEZXML_OBJ}
	@echo "   LINK  $@ (w/ ${CC})"
	@${CC} -shared -Wl,-soname,libpiano.so.0 ${CFLAGS} ${LDFLAGS} \
			-o libpiano.so.0.0.0 ${LIBPIANO_RELOBJ} \
			${LIBWAITRESS_RELOBJ} ${LIBEZXML_RELOBJ}
	@ln -s libpiano.so.0.0.0 libpiano.so.0
	@ln -s libpiano.so.0 libpiano.so
	@echo "     AR  libpiano.a"
	@${AR} rcs libpiano.a ${LIBPIANO_OBJ} ${LIBWAITRESS_OBJ} ${LIBEZXML_OBJ}

%.o: CC:=${CC}
%.o: %.c
	@echo "     CC  $<"
	@${CC} ${CFLAGS} -I ${LIBPIANO_INCLUDE} -I ${LIBWAITRESS_INCLUDE} \
			-I ${LIBEZXML_INCLUDE} ${LIBFAAD_CFLAGS} \
			${LIBMAD_CFLAGS} ${LIBGNUTLS_CFLAGS} ${LIBID3TAG_CFLAGS} ${LIBAO_CFLAGS} -c -o $@ $<

# create position independent code (for shared libraries)
%.lo: %.c
	@echo "     CC  $< (PIC)"
	@${CC} ${CFLAGS} -I ${LIBPIANO_INCLUDE} -I ${LIBWAITRESS_INCLUDE} \
			-I ${LIBEZXML_INCLUDE} -c -fPIC -o $@ $<

clean:
	@echo "  CLEAN"
	@${RM} ${PIANOBAR_OBJ} ${LIBPIANO_OBJ} ${LIBWAITRESS_OBJ} ${LIBWAITRESS_OBJ}/test.o \
			${LIBEZXML_OBJ} ${LIBPIANO_RELOBJ} ${LIBWAITRESS_RELOBJ} \
			${LIBEZXML_RELOBJ} pianobarfly libpiano.so* libpiano.a waitress-test
	@${RM} -r id3lib-3.8.3 id3lib-3.8.3.tar.gz patches

all: pianobarfly

debug: pianobarfly
debug: CFLAGS=-std=c99 -Wall -pedantic -ggdb -DDEBUG

waitress-test: CFLAGS+= -DTEST
waitress-test: ${LIBWAITRESS_OBJ}
	${CC} ${LDFLAGS} ${LIBWAITRESS_OBJ} -o waitress-test

test: waitress-test
	./waitress-test

ifeq (${DYNLINK},1)
install: pianobarfly install-libpiano
else
install: pianobarfly
endif
	install -d ${DESTDIR}/${BINDIR}/
	install -m755 pianobarfly ${DESTDIR}/${BINDIR}/
	install -d ${DESTDIR}/${MANDIR}/man1/
	install -m644 contrib/pianobarfly.1 ${DESTDIR}/${MANDIR}/man1/

install-libpiano:
	install -d ${DESTDIR}/${LIBDIR}/
	install -m644 libpiano.so.0.0.0 ${DESTDIR}/${LIBDIR}/
	ln -s libpiano.so.0.0.0 ${DESTDIR}/${LIBDIR}/libpiano.so.0
	ln -s libpiano.so.0 ${DESTDIR}/${LIBDIR}/libpiano.so
	install -m644 libpiano.a ${DESTDIR}/${LIBDIR}/
	install -d ${DESTDIR}/${INCDIR}/
	install -m644 src/libpiano/piano.h ${DESTDIR}/${INCDIR}/

ifeq (${BUILD_ID3LIB}, 1)
id3lib-3.8.3: id3lib-3.8.3.tar.gz patches
	@if test `$(MD5SUM) $< | $(AWK) '{print $$1}'` = 19f27ddd2dda4b2d26a559a4f0f402a7; then \
		echo "EXTRACT $<";\
		$(TAR) zxf $< ;\
	else \
		echo "  $< check sum is wrong (Please use orignal)." ;\
		rm -rf $@ ;\
	fi

	@echo "  PATCH $@"
	@for v in `cat patches/series` ; do \
		patch -s -p1 -d $@ < patches/$$v ; \
	done
	@$(PATCH) -s -d $@ -p0 < c99_guard_globals.h.diff ;
	@$(PATCH) -s -d $@ -p0 < configure.diff ;

	@echo "  BUILD $@"
	@(cd $@ ; CFLAGS="-DNDEBUG -O3" CXXFLAGS="-DNDEBUG -O3" ./configure --disable-shared --enable-static && make ; )

id3lib-3.8.3.tar.gz:
	@echo "  FETCH $@"
	@curl -s -o $@ http://archive.ubuntu.com/ubuntu/pool/main/i/id3lib3.8.3/id3lib3.8.3_3.8.3.orig.tar.gz

patches:
	@echo "  FETCH patches"
	@curl -s http://archive.ubuntu.com/ubuntu/pool/main/i/id3lib3.8.3/id3lib3.8.3_3.8.3-13ubuntu1.debian.tar.gz | $(TAR) --strip-components=1 -zxf - debian/patches
endif

.PHONY: install install-libpiano test debug all clean
