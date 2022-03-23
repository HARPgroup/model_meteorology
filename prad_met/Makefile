ifndef CBP_SRC
  $(error CBP_SRC is undefined. Please run ". hspf_config" first or set CBP_SRC manually)
endif

PROG1 =  wdm_insert_ALL

SRCS =	wdm_insert_ALL.f 

OBJS =	wdm_insert_ALL.o

LIBS =  ${CBP_SRC}/hspf/lib3.2/lib/utillib.a \
        ${CBP_SRC}/hspf/lib3.2/lib/wdmlib.a \
        ${CBP_SRC}/hspf/lib3.2/lib/adwdmlib.a \
        ${CBP_SRC}/lib/util_lib.a

FC = f77
FFLAGS = -W -Wall -pedantic -Wsurprising -fbounds-check 
#FFLAGS = -W -Wall -Wsurprising -pedantic    
LDFLAGS =   


all: $(PROG1)
	cp $(PROG1) ../../../bin/

$(PROG1): $(OBJS)
	$(FC) $(LDFLAGS) -o wdm_insert_ALL $(OBJS) $(LIBS)

clean:
	rm -f $(PROG1) $(OBJS)
