************************************************************************
*** Program to read data time series data from csv files generated by***
*** Lauren Hay's xyz model and insert these new values into a        ***
*** wdm.  This uses wdm subroutines located in lib3.2/src/wdtms1.f   ***
*** It will be used for met wdms                                     ***
*** Created by: Mike Barnes 4/29/11                                  ***
*** Adopted and Edited by: Gopal Bhatt 1/31/12                       ***
************************************************************************
      implicit none
C     ERROR CODES       
      integer err, retcod
C     FILE AND INPUT NAMES
      character*6 lseg
      character*64 wdmpname,mesname
      character*200 dfnam
      character*200 sfnam
      character*100 datasource, version, year
C     SIZE OF INPUT NAMES
      integer lendatasource, lenversion, lenyear
C     SIZE OF DATE ARRAYS
      integer ndate
      parameter (ndate=6)
C     START AND END DATES IN WDM FORMAT         
      integer sdate(ndate), edate(ndate)
      integer insdate(ndate), inedate(ndate)
      integer tmpsdate(ndate), tmpedate(ndate)  
C     WDM IO PARAMS
      integer tcode, tstep, dtran, qualfg, dtovwr
      parameter (tcode=3, tstep=1, dtran=0, qualfg=0, dtovwr=1)
C     FILE UNIT NUMBERS      
      integer datafile, wdmput, mesfile, statfile
      parameter (datafile=13, wdmput=12,mesfile=9)
C     INTEGER COUNTER AND DATA SET NUMBER
      integer i, dsn
C     VARIABLES FOR CHECKING CLIMATE INSERT DATA
      integer oldyear
      real dacc
C     ARRAY SIZES AND NUMBER OF VALUES IN TIMESERIES 
      integer nvals, delnvals,tmpnvals1,tmpnvals2, ndaymax
      parameter (ndaymax=12500)
      real hval(ndaymax*24)
C     INPUT BUFFER FOR CLIMATE INSERT      
      real csvdata(ndaymax*24)
      integer counter, totalcount, expectedcount
      parameter(expectedcount=87672) ! 1991-2000
C      parameter(expectedcount=78888) ! 2005-2013
      integer time(expectedcount+1,4)

      integer syear, eyear
******************** END SPECIFICATIONS ********************************

      read(*,*) lseg, datasource, version, year, syear, eyear
      call lencl(datasource,lendatasource)
      call lencl(version,lenversion)
      call lencl(year, lenyear)
      print*, lseg

**********start and end dates for entire timeseries*********************
      sdate(1) = 1984
      sdate(2) = 1
      sdate(3) = 1
      sdate(4) = 0
      sdate(5) = 0
      sdate(6) = 0
      
      edate(1) = 2014
      edate(2) = 12
      edate(3) = 31
      edate(4) = 24
      edate(5) = 0
      edate(6) = 0

**********start and end dates for climate modified insert***************

      insdate(1) = syear
      insdate(2) = 1
      insdate(3) = 1
      insdate(4) = 0
      insdate(5) = 0
      insdate(6) = 0

      inedate(1) = eyear
      inedate(2) = 12
      inedate(3) = 31
      inedate(4) = 24
      inedate(5) = 0
      inedate(6) = 0
**********start and end dates for modified Jan 96 temperature data******
      tmpsdate(1) = 1996 
      tmpsdate(2) = 1
      tmpsdate(3) = 18
      tmpsdate(4) = 0
      tmpsdate(5) = 0
      tmpsdate(6) = 0

      tmpedate(1) = 1996
      tmpedate(2) = 1
      tmpedate(3) = 21
      tmpedate(4) = 24
      tmpedate(5) = 0
      tmpedate(6) = 0

*********** Open WDM and Data file *************************************
C      mesname= './message.wdm'
C      call wdbopn(mesfile,mesname,1,retcod)  ! open mesfile read only
C      if (retcod.ne.0) stop 'error opening message wdm' 
      wdmpname = 'met_'//lseg//'.wdm'
      call wdbopn(wdmput,wdmpname,0,retcod)  ! open read/write 
      if (retcod.ne.0) then
             print*, 'retcod = ', retcod 
             stop 'error opening wdm'
      end if
*********** ATMP *******************************************************
      dfnam = '../../../'//
     .        'input/unformatted/././'//
     .       datasource(:lendatasource)//'/'//version(:lenversion)//
     .       '/'//year(:lenyear)//'/'//lseg//'.TMP'
C      dfnam = lseg//'.TMP'
      print*,dfnam
      open(datafile,file=dfnam,status='old',iostat=err)

      if (err.ne.0) stop 'error opening .TMP file '
*************read in the data to local variables************************
      counter = 1
      do
           read(datafile,111,end=222)
     .     time(counter,1),time(counter,2),
     .     time(counter,3),time(counter,4),
     .     csvdata(counter) 
           counter=counter+1
      end do
 111  FORMAT(I4,2X,I2,2X,I2,2X,I2,2X,F11.4)
 222  continue
      close (datafile)
      totalcount = counter-1
      print*,totalcount,' ', expectedcount, ' << '
      if(totalcount.ne.expectedcount) stop 'check input file length'
*************convert climate insert from C degrees to F*****************
      do i = 1, totalcount
           csvdata(i) = csvdata(i)*9.0/5.0+32.0
      end do
*************read in the old wdm timeseries and insert new data*********
      dsn = 1004
      print*,lseg,' ',dsn,' ATMP'

      call timdif(
     I            sdate,edate,tcode,tstep,
     O            nvals)

      call wdtget(
     I            wdmput,dsn,tstep,sdate,nvals,
     I            dtran, qualfg, tcode,
     O            hval, retcod)

      if (retcod.ne.0) stop 'error getting wdm timeseries'

************find spot in timeseries to insert new data******************
      call timdif(
     I            sdate,insdate,tcode,tstep,
     O            delnvals)
************insert climate modified temperature data********************
      do i = 1, totalcount
           hval(delnvals+i)=csvdata(i)
      end do 
************increase tmp by 10 degrees F for 4 days Jan 96**************
      call timdif(
     I            sdate,tmpsdate,tcode,tstep,
     O            tmpnvals1)      

      call timdif(
     I            tmpsdate,tmpedate,tcode,tstep,
     O            tmpnvals2)
      
      do i = 1, tmpnvals2
           hval(tmpnvals1+i) = hval(tmpnvals1+i) + 10.0
      end do
************check that the end date is the expected end date************
      do i = 1, 4
           if (time(totalcount,i).ne.inedate(i)) stop 'wrong end date' 
      end do
************check for valid temperature range in data*******************
      do i = 1, nvals
           if(hval(i).lt.-50.0.or.hval(i).gt.130.0) then
                 print*,hval(i)
                 stop 'data in climate insert outside valid temp. range'
           end if
      end do
************write back to the wdm file**********************************
      print*,'writing to ', wdmpname
      call wdtput(
     I            wdmput,dsn,tstep,sdate,nvals,
     I            dtovwr, qualfg, tcode,hval,
     O            retcod)
      if (retcod.ne.0) then
            print*, 'retcod = ', retcod
            stop 'error writing wdm'
      end if 

************ PET *******************************************************
      dfnam = '../../../'//
     .        'input/unformatted/././'//
     .       datasource(:lendatasource)//'/'//version(:lenversion)//
     .       '/'//year(:lenyear)//'/'//lseg//'.PET'
C      dfnam = lseg//'.PET'
      open(datafile,file=dfnam,status='old',iostat=err)

      if (err.ne.0) stop 'error opening .PET file'
      sfnam    = 'annual_stats.txt'
      open(statfile,file=sfnam,access='APPEND',status='UNKNOWN',
     . iostat=err)
      if (err.ne.0) stop 'error opening STAT file '
************read PET csv climate insert*********************************
      counter = 1
      do
           read(datafile,112,end=333)
     .     time(counter,1),time(counter,2),
     .     time(counter,3),time(counter,4),
     .     csvdata(counter) 
           counter=counter+1
      end do
 112  FORMAT(I4,1X,I2,1X,I2,1X,I2,1X,F16.14)
 333  continue
      close (datafile)
      totalcount = counter-1
      if(totalcount.ne.expectedcount) stop 'check input file length'
*************read in the old wdm timeseries and insert new data*********
      dsn = 1000
      print*, lseg,' ',dsn,' PET'

      call timdif(
     I            sdate,edate,tcode,tstep,
     O            nvals)

      call wdtget(
     I            wdmput,dsn,tstep,sdate,nvals,
     I            dtran, qualfg, tcode,
     O            hval, retcod)


      if (retcod.ne.0) stop 'error getting wdm timeseries'

************find spot in timeseries to insert new data******************
      call timdif(
     I            sdate,insdate,tcode,tstep,
     O            delnvals)
************insert climate modified temperature data********************
      do i = 1, totalcount
           hval(delnvals+i)=csvdata(i)
      end do  
************check for valid PET range in all data***********************
      do i = 1, nvals
           if(hval(i).lt.0.or.hval(i).gt.1) then
                 print*,i,hval(i)
                 stop 'data outside valid PET range'
           end if
      end do
************check for valid range using annual sum and print************
      write(statfile,*) lseg
      oldyear = time(1,1)
      dacc = 0.0
      do i = 1,totalcount
           if(oldyear.ne.time(i,1)) then
                   print*,'a',lseg,',',oldyear,',',dacc
                   write(statfile,*) lseg,',',oldyear,',',dacc
                   if(dacc.lt.20.or.dacc.gt.60) then
                           stop 'PET out of range'
                   end if
                   oldyear = time(i,1)
                   dacc = 0.0
           end if
           dacc = dacc + csvdata(i)
      end do
      print*,'b',lseg,',',oldyear,',',dacc
      write(statfile,*) lseg,',',oldyear,',',dacc
************check that the end date is the expected end date************
      do i = 1, 4
           if (time(totalcount,i).ne.inedate(i)) stop 'wrong end date' 
      end do
************write back to the wdm file**********************************
      print*,'writing to ', wdmpname

      call wdtput(
     I            wdmput,dsn,tstep,sdate,nvals,
     I            dtovwr, qualfg, tcode,hval,
     O            retcod)
      if (retcod.ne.0) then
            print*, 'retcod = ', retcod
            stop 'error writing wdm'
      end if

      call wdflcl(
     I            wdmput,
     O            retcod)
c bhatt      if (retcod.ne.0) stop 'error closing wdm'

      close (mesfile)

      end
