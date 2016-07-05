#!/bin/csh -f
#
#  Reads annual POP netcdfs (generates these if needed) 
#  and creates a concatenated
#  time series netcdf containing specified variables.
#
#  Usage:  
#    gen_pop_annual_timeseries.csh OUTFILE MSROOT CASE YEAR0 YEAR1 variables
#

set TSFILE = $1
set MSROOT = $2
set CASENAME = $3
@ yr0 = $4
@ yr1 = $5

if ($#argv > 5) then
 @ doall = 0
 set vars = ($argv[6-$#argv])
 set nvar = $#vars
 set varstr = $argv[6]
 if ($nvar > 1) then
  foreach i ($argv[7-$#argv])
    set varstr = ${varstr},${i}
  end
 endif
else
 echo "gen_pop_annual_timeseries.csh:  must specify which variables!"
 exit 1
endif

set year0 = `printf "%04d" $yr0`
set year1 = `printf "%04d" $yr1`

setenv MSP /${MSROOT}/${CASENAME}/ocn/hist
setenv MSPY /${MSROOT}/${CASENAME}/ocn/proc/tavg/annual
setenv MSPTSY /${MSROOT}/${CASENAME}/ocn/proc/tseries/annual

set max_msread_cnt  = 15

if (! -e ${TSFILE}) then
ls ${MSPTSY}/${TSFILE}
if ($status == 0) then
 echo "reading ${TSFILE} from archive"
 ln -sf ${MSPTSY}/${TSFILE} ${TSFILE}
else
  echo "generating annual time series netcdf from $year0 to $year1 of $CASENAME"
  @ yr = $yr0
  @ msread_cnt = 0
  @ nt = 0
  while ($yr <= $yr1)
    @ nt++
    set year = `printf "%04d" $yr`
    setenv NAME ${CASENAME}.pop.h.${year}.nc.ts
    if (! -e ${NAME}) then
    if (! -e ${CASENAME}.pop.h.${year}.nc) then
     ls ${MSPY}/${CASENAME}.pop.h.${year}.nc
       if ($status == 0) then
        ln -sf ${MSPY}/${CASENAME}.pop.h.${year}.nc ${CASENAME}.pop.h.${year}.nc
       else
         ls ${MSP}/${CASENAME}.pop.h.${year}.nc
         if ($status == 0 ) then
          ln -sf ${MSP}/${CASENAME}.pop.h.${year}.nc ${CASENAME}.pop.h.${year}.nc
         else
          gen_pop_annmean.csh ${MSROOT} ${CASENAME} $yr $yr
         endif
       endif
    endif
    touch files_read
    echo ${CASENAME}.pop.h.${year}.nc >> files_read
    @ msread_cnt++
    if ($msread_cnt >= $max_msread_cnt || $yr == $yr1 ) then
      wait
      @ msread_cnt = 0
      foreach i (`less files_read`)
        ncks -O -v ${varstr} $i $i.ts
      end
      foreach i (`less files_read`)
        \rm -f $i
      end
      \rm -f files_read
    endif
    endif
    @ yr++
  end
  set files = `ls -l *.ts | awk '{print $5}'`
  if ( $#files == $nt ) then
    ncrcat ${CASENAME}*.ts ${TSFILE} && \rm -f ${CASENAME}*.ts
    mkdir -p $MSPTSY 
    mv ${TSFILE} ${MSPTSY}/${TSFILE}
    ln -sf ${MSPTSY}/${TSFILE} ${TSFILE} 
  else
    echo "DID NOT CREATE ALL .ts FILES" && exit 1
  endif
endif

endif

exit 0
