************************************************************************
***   Program reads any CSV time series data and writes WDMs         ***
***   Author: Robert Burgholzer from wd_insert_ALL by Gopal Bhatt    ***
***   Takes any CSV file in format year,month,day,hour,data          ***
***   Use:  wdm_insert_one csvpath wdmpath DSN hasheader (0/1)       ***
************************************************************************

      implicit none
C     ERROR CODES       
      integer err, retcod
C     FILE AND INPUT NAMES
      character     lseg*12
      character     wdmfname*256,msgfname*256
      character     csvfname*200
      character     datasource*100, version*100, period*100
      character     longline*300
      integer last, hasheader
C     IMPORT SETTINGS
      character     mode*1 ! w=overwrite, a=add
C     SIZE OF INPUT NAMES
      integer lendatasource, lenversion, lenperiod, lenlseg
C     SIZE OF DATE ARRAYS
      integer ndate
      parameter (ndate=6)
C     START AND END DATES IN WDM FORMAT         
      integer sdate(ndate), edate(ndate)
C     WDM IO PARAMS
      integer HCODE, DCODE, code ! Hourly, Daily
      parameter (HCODE=3, DCODE=4)
      integer TSTEP, dtran, qualfg, dtovwr
      parameter (dtran=0, qualfg=0, dtovwr=1)
C     FILE UNIT NUMBERS      
      integer csvfile, wdmfile, msgfile
      parameter (csvfile=13, wdmfile=12,msgfile=9)
C     INTEGER COUNTER AND DATA SET NUMBER
      integer i, j, dsn
      integer tIMM, tIDD, tIHH
      real    tRData
C     VARIABLES FOR CHECKING CLIMATE INSERT DATA
      integer oldyear
      real    dacc
      integer ndacc
C     ARRAY SIZES AND NUMBER OF VALUES IN TIMESERIES 
      integer   NDAYSMAX
      parameter (NDAYSMAX=16836) !(2025-1980+1)*366
      real      csvdata(NDAYSMAX*24,5),hval(NDAYSMAX*24)
      real      RNMAX(12,31,24), PRECIP(NDAYSMAX*24)
      integer   csvndata, nvals
      real      hmin,hmax,ymin,ymax
      integer   YEAR1, YEAR2
      integer   HPRC, HTMP, HPET, HRAD, HWND, DDPT, DCLC
C MISCELLANEOUS
      character arg1*32,helpmessage*128
      helpmessage = "Use: echo 'dest.wdm source.csv dsn"
     .              //" timestep mode(w,a) msgwdm' | wdm_insert_one"
******************** END SPECIFICATIONS ********************************
      if (command_argument_count().gt.0) then
         call get_command_argument(1,arg1)
         print*,"argument:", arg1
         if (arg1.eq.'--help') then
            print*, helpmessage
            stop 'Done.'
         end if
      end if
      read(*,*) wdmfname, csvfname, 
     .          dsn, TSTEP, mode, msgfname
      if (TSTEP.eq.1) then
          code = HCODE
      else
          code = DCODE
      end if
      print*, "Reading CSV ",csvfname

*********** Open WDM and Data file *************************************
      call wdbopn(msgfile,msgfname,1,retcod)  ! open msgfile read only
      if (retcod.ne.0) then
              print*, 'Error opening Message: ', msgfname
              stop 'halting'
      end if


************************************************************************
************************ ##### Write START ##### ************************
************************************************************************
      call wdbopn(wdmfile,wdmfname,0,retcod)  ! open read/write 
      if (retcod.ne.0) then
             print*, 'retcod = ', retcod 
             print*, wdmfname
             stop 'ERROR opening wdm'
      end if
      
      print*,csvfname
      open(csvfile,file=csvfname,status='old',iostat=err)

      if (err.ne.0) stop 'ERROR opening csv '
*************read in the data to local variables************************
      csvndata = 0
      do
           read (csvfile,'(a300)',end=2000) longline
           call d2x(longline,last)
           csvndata = csvndata + 1
           read(longline,*,end=994,err=994)
     .     csvdata(csvndata,1),csvdata(csvndata,2),
     .     csvdata(csvndata,3),csvdata(csvndata,4),
     .     csvdata(csvndata,5)

      end do
 2000 continue
      close (csvfile)
      sdate(1) = INT(csvdata(1,1))
      sdate(2) = INT(csvdata(1,2))
      sdate(3) = INT(csvdata(1,3))
      sdate(4) = INT(csvdata(1,4))
      sdate(5) = 0
      sdate(6) = 0
      !print*,csvdata(csvndata,1),csvdata(csvndata,2)
      edate(1) = INT(csvdata(csvndata,1))
      edate(2) = INT(csvdata(csvndata,2))
      edate(3) = INT(csvdata(csvndata,3))
      edate(4) = INT(csvdata(csvndata,4))
      edate(5) = 0
      edate(6) = 0
      print*,'Read',' ',csvndata,' lines from',csvfile
      print*,'First yr=',' ',csvdata(1,1)
      print*,'First yr=',' ',sdate(1)
      print*,'Last yr=',' ',edate(1)
      print*,'Last val=',csvdata(csvndata,5)
*************check if data needed is there, calculates nvals*********
      call timdif(
     I            sdate,edate,code,TSTEP,
     O            nvals)
************open wdm and read existing data*****************************
      print*,wdmfname,' DSN:',dsn
      print*,'from: ', sdate(1),sdate(2),sdate(3),sdate(4)
      print*,'Calling wdtget(',wdmfile,dsn,TSTEP,sdate(1),nvals
      print*,'    ',dtran, qualfg,code,')'
      call wdtget(
     I            wdmfile,dsn,TSTEP,sdate,nvals,
     I            dtran, qualfg, code,
     O            hval, retcod)
      if (retcod.ne.0) then
             print*, 'retcod = ', retcod 
             print*, wdmfname
             stop 'PROBLEM ERROR getting wdm timeseries'
      end if
      print*,'Rertrieved existing data from', wdmfname
************copy climate data from csv array to insert hval ************
C WRITE/REPLACE MODE
      if (mode.eq.'w') then
        do i = 1, nvals
          hval(i)=csvdata(i,5)
        end do
      end if
C ADDITIVE MODE
      if (mode.eq.'a') then
        do i = 1, nvals
          hval(i)=csvdata(i,5) + hval(i)
        end do
      end if
************write back to the wdm file**********************************
      print*,'writing to ', wdmfname
      call wdtput(
     I            wdmfile,dsn,TSTEP,sdate,nvals,
     I            dtovwr, qualfg, code,hval,
     O            retcod)
      if (retcod.ne.0) then
            print*, 'retcod = ', retcod
            stop 'ERROR writing wdm'
      end if 
************write back to the wdm file**********************************
      call wdflcl(
     I            wdmfile,
     O            retcod)

      if (retcod.ne.0) then 
            print*, 'retcod = ', retcod
            stop 'ERROR closing wdm'
      end if
************************************************************************
************************ ##### Write FINISH ##### ***********************
************************************************************************
C      stop 'STOP'

      close (msgfile)
      return

994   print*,'Problem reading file:',csvfname
      goto 999

999   continue

      end

