#!/bin/csh -f
#
#  Reads monthly POP netcdfs and creates a concatenated
#  time series netcdf containing specified variables.
#
#  Usage:  
#    gen_pop_monthly_timeseries.csh OUTFILE MSROOT CASE YEAR0 YEAR1 variables
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
 echo "gen_pop_monthly_timeseries.csh:  must specify which variables!"
 exit 1
endif

set year0 = `printf "%04d" $yr0`
set year1 = `printf "%04d" $yr1`

setenv MSP /${MSROOT}/${CASENAME}/ocn/hist
setenv MSPTSM /${MSROOT}/${CASENAME}/ocn/proc/tseries/monthly

set max_msread_cnt  = 15

if (! -e ${TSFILE}) then
ls ${MSPTSM}/${TSFILE}
if ($status == 0) then
 echo "reading ${TSFILE} from archive"
 ln -sf ${MSPTSM}/${TSFILE} ${TSFILE} 
else
  echo "generating monthly time series netcdf from $year0 to $year1 of $CASENAME"
  @ yr = $yr0
  @ msread_cnt = 0
  while ($yr <= $yr1)

    set year = `printf "%04d" $yr`
    ls ${MSP}/${CASENAME}.pop.h.${year}-01.nc
    if ($status == 0) then
      foreach mon (01 02 03 04 05 06 07 08 09 10 11 12)
        if !(-e ${CASENAME}.pop.h.${year}-${mon}.nc) then
	ln -sf ${MSP}/${CASENAME}.pop.h.${year}-${mon}.nc ${CASENAME}.pop.h.${year}-${mon}.nc 
        endif
      end
    else
      mssuntar.csh ${MSROOT} ${CASENAME} $yr $yr
    endif
    wait
    foreach mon (01 02 03 04 05 06 07 08 09 10 11 12)
        ncks -O -v ${varstr} ${CASENAME}.pop.h.${year}-${mon}.nc  \
                ${CASENAME}.pop.h.${year}-${mon}.nc
    end
    ncrcat ${CASENAME}.pop.h.${year}-??.nc ${CASENAME}.pop.h.${year}.nc.ts
    \rm -f ${CASENAME}.pop.h.${year}-??.nc
  @ yr++
  end
  ncrcat ${CASENAME}*.ts ${TSFILE} && \rm -f ${CASENAME}*.ts
  mkdir -p $MSPTSM
  mv ${TSFILE} ${MSPTSM}/${TSFILE}
  ln -sf ${MSPTSM}/${TSFILE} ${TSFILE}
endif

endif

exit 0
