ifndef CBP_SRC
  $(error CBP_SRC is undefined. Please run ". hspf_config" first or set CBP_SRC manually)
endif

BINDIR =  /usr/local/bin
PROG1 =  wdm_insert_ALL
PROG2 =  wdm_insert_one

SRCS =	wdm_insert_ALL.f 

OBJS =	wdm_insert_ALL.o

LIBS =  ${CBP_SRC}/hspf/lib3.2/lib/utillib.a \
        ${CBP_SRC}/hspf/lib3.2/lib/wdmlib.a \
        ${CBP_SRC}/hspf/lib3.2/lib/adwdmlib.a \
        ${CBP_SRC}/lib/util_lib.a \
        date_utils.a

FC = f77
FFLAGS = -W -Wall -pedantic -Wsurprising -fbounds-check 
#FFLAGS = -W -Wall -Wsurprising -pedantic    
LDFLAGS =   
ArOpt = rv

# make file syntax is (note prerequisites are optional)
# target: prerequisites 
#   commands 

all: libs $(PROG1) one

$(PROG1): $(OBJS)
	$(FC) $(LDFLAGS) -o wdm_insert_ALL $(OBJS) $(LIBS)

libs: date_utils.a

date_utils.a:	
	$(FC) -fbounds-check -c date_utils.f
	ar $(ArOpt) $@ $?
  
one: wdm_insert_one.o
	$(FC) -fbounds-check -c date_utils.f
	$(FC) $(LDFLAGS) -o wdm_insert_one wdm_insert_one.o $(LIBS)

install:
	mv wdm_insert_one $(BINDIR)/wdm_insert_one
	mv wdm_insert_ALL $(BINDIR)/wdm_insert_ALL

clean:
	rm -f $(PROG1) $(OBJS)
	rm -f wdm_insert_one wdm_insert_one.o
