
************************************************************************
***** converts date string to into array                              **
************************************************************************

        subroutine n2date(datestr,defdate,outdate)
                          
          character datestr*8
          integer defdate(6)
          integer outdate(6)
          dpart = datestr(1:4)
          read (dpart,fmt='(I4)') outdate(1)
          if (LEN(datestr).ge.6) then 
            dpart = (datestr(5:6))
            read (dpart,fmt='(I4)') outdate(2)
          else
            outdate(2) = defdate(2)
          end if
          if (LEN(datestr).ge.8) then 
            dpart = (datestr(7:8))
            read (dpart,fmt='(I4)') outdate(3)
          else
            outdate(3) = defdate(3)
          end if
          outdate(4) = 0
          outdate(5) = 0
          outdate(6) = 0
          return
        end

