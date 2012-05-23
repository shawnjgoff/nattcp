VERSION := 7.1.6

CC ?= gcc
CFLAGS ?= -Wall -O

CPPFLAGS += -DUDP_FLIP
ifneq ($(NO_SSL), y)
CPPFLAGS += -DSSL_AUTH
LDFLAGS += -lpolarssl
endif

CPPFLAGS += -D UDP_FLIP

LUAC := luac
LUACFLAGS := -s

# Cygwin
#CFLAGS += -m32 -march=i486
#EXEEXT := .exe

DIST := Makefile nattcp.c udp-climber.lua nuttcp.8 LICENSE \
	xinetd.d/nattcp xinetd.d/nattcp4 upstart/nattcp.conf
ifneq ($(NO_SSL), y)
DIST += polarssl.c 
endif
ifneq ($(NO_IPV6), y)
DIST += xinetd.d/nattcp6 
endif

MANIFEST := nattcp$(EXEEXT) #udp-climber
ifeq ($(NO_IPV6), y)
CPPFLAGS += -D NO_IPV6
endif

ifneq ($(NO_LUAC), y)
MANIFEST += udp-climber
endif

all : $(MANIFEST)

OBJECTS := nattcp.o
ifneq ($(NO_SSL), y)
OBJECTS += polarssl.o
endif

nattcp$(EXEEXT) : $(OBJECTS)
	$(CC) -o $@ $^ $(LDFLAGS) $(CPPFLAGS)

udp-climber : udp-climber.lua
	echo "#!/usr/bin/lua" >$@
	$(LUAC) $(LUACFLAGS) -o - $< >>$@
	chmod +x $@

install : $(MANIFEST)
	mkdir -p $(DESTDIR)/usr/bin
	install -m 0755 nattcp $(DESTDIR)/usr/bin/
ifneq ($(NO_LUAC), y)
	install -m 0755 udp-climber $(DESTDIR)/usr/bin/
else
	install -m 0755 udp-climber.lua $(DESTDIR)/usr/bin/
endif

clean:
	rm -f *.o $(MANIFEST)

# Win32 binary release
release : $(MANIFEST) cyggcc_s-1.dll cygwin1.dll lua.exe lua5.1.dll
	rm -f nattcp-$(VERSION)-win32.zip
	zip nattcp-$(VERSION)-win32.zip $^

# automake-style source distro
dist : $(DIST)
	tar czf nattcp-$(VERSION).tar.gz --xform "s,^,nattcp-$(VERSION)/,S" $^
