#!/bin/csh -f
#
#  Generates the following time series netcdfs from POP annual
#  mean netcdfs (which it will generate if needed):
#	${region}_hor_mean_${CASE}.${YEAR0}-${YEAR1}.nc
#
#  The above contain global and regional horizontal 
#  mean/diff/rms TEMP & SALT (compared to PHC obs).
#
#  Based on Gokhan's TS_diff_rms_profiles_ts.script
#
#  Usage:
#   gen_TS_meandiffrms_timeseries.csh MSROOT CASE YEAR0 YEAR1
#

set MSROOT     = $1
set CASE       = $2
@ yr0 = $3
@ yr1 = $4

setenv MSP /${MSROOT}/${CASE}/ocn/hist
setenv MSPY /${MSROOT}/${CASE}/ocn/proc/tavg/annual
setenv MSPTSY /${MSROOT}/${CASE}/ocn/proc/tseries/annual
set max_msread_cnt  = 10
set region = ( Sou Pac Ind Atl Lab Gin Arc Hud Glo ) 
set reg_num  = (   1   2   3   6   8   9  10  11   0 ) 
set nr    = $#region

## check MSS for pre-existing time series files covering
#	specified years
set year0 = `printf "%04d" $yr0`
set year1 = `printf "%04d" $yr1`
set foundall = 1
@ in = 1
while ( $in <= $nr )
  set newfile = ${region[$in]}_hor_mean_${CASE}.${year0}-${year1}.nc
  if (! -e $newfile) then
    ls ${MSPTSY}/${newfile}
    if ($status == 0) then
       cp ${MSPTSY}/${newfile} .
    else
       set foundall = 0
    endif
  endif
  @ in++
end
wait

if ($foundall == 0) then

## first, read in a year and process observed T & S climatology 
set year = `printf "%04d" $yr0`
#if (! -e ${CASE}.pop.h.${year}.nc) then
#  ls ${MSPY}/${CASE}.pop.h.${year}.nc
#  if ($status == 0) then
#    cp ${MSPY}/${CASE}.pop.h.${year}.nc .
#  else
#    cp ${MSP}/${CASE}.pop.h.${year}.nc .
#     if ($status == 0) then
#       cp ${MSP}/${CASE}.pop.h.${year}.nc .
#     else
#       gen_pop_annmean.csh ${MSROOT} ${CASE} $yr0 $yr0
#     endif
#  endif
#endif
if (! -e ${CASE}.pop.h.${year}.nc) then
    if(! -e ${MSPY}/${CASE}.pop.h.${year}.nc) then
	if(! -e ${MSP}/${CASE}.pop.h.${year}.nc) then
	    gen_pop_annmean.csh ${MSROOT} ${CASE} $yr0 $yr0
	else
	    ln -sf ${MSP}/${CASE}.pop.h.${year}.nc ${CASE}.pop.h.${year}.nc
	endif
    else
	ln -sf ${MSPY}/${CASE}.pop.h.${year}.nc ${CASE}.pop.h.${year}.nc
    endif
endif
cp ${TCLIMFILE} obs.nc
cp ${SCLIMFILE} SALT_obs.nc
ncks -A -v SALT SALT_obs.nc obs.nc 
ncks -A -v TAREA,REGION_MASK,time_bound ${CASE}.pop.h.${year}.nc obs.nc

ncatted -a missing_value,TLAT,d,, obs.nc
ncatted -a missing_value,TLONG,d,, obs.nc
ncatted -a _FillValue,TLAT,d,, obs.nc
ncatted -a _FillValue,TLONG,d,, obs.nc

@ in = 1
while ( $in <= $nr )
  if ( ${region[$in]} == 'Glo' ) then
    ncwa -m REGION_MASK -T gt -M ${reg_num[$in]} -w TAREA -a nlon,nlat \
         -v TEMP,SALT obs.nc ${region[$in]}_hor_mean_obs.nc &
  else
    ncwa -m REGION_MASK -T eq -M ${reg_num[$in]} -w TAREA -a nlon,nlat \
         -v TEMP,SALT obs.nc ${region[$in]}_hor_mean_obs.nc &
  endif
  @ in++
end
wait

## read in any processed timeseries files which may already exist on mss
## 	with format ???_hor_mean_${CASE}.YYYY-YYYY.nc
ls ${MSPTSY}/Glo_hor_mean_${CASE}.????-????.nc
if ($status == 0) then
  cp ${MSPTSY}/*_hor_mean_${CASE}.????-????.nc . &
  wait
  set oldfile = `ls Glo_hor_mean_${CASE}.????-????.nc`
  if ($#oldfile > 1) then
    echo "found more than one old time series on mass store"
    exit 1
  endif
   
  # extract firstyear from file name and parse to integer
  set d1 = `echo $oldfile | awk '{ print substr($1,length($1)-11,1) }'`
  echo "d1 = " $d1
  if ($d1 == 0) then
     echo "firstyear first digit = 0"
     set d2  = `echo $oldfile | awk '{ print substr($1,length($1)-10,1) }'`
     if ($d2 == 0) then
                echo "d2 = " $d2
                set d3  = `echo $oldfile | awk '{ print substr($1,length($1)-9,1) }'`
                echo "d3 = " $d3
                if ($d3 == 0) then      #---- 1 digit number
  			set firstyear = `echo $oldfile | awk '{ print substr($1,length($1)-8,1) }'`
                else                    # ----2 digit number
  			set firstyear = `echo $oldfile | awk '{ print substr($1,length($1)-9,2) }'`
                endif
     else                               # ----3 digit number
  			set firstyear = `echo $oldfile | awk '{ print substr($1,length($1)-10,3) }'`
     endif
  else                                  # ----4 digit number
  			set firstyear = `echo $oldfile | awk '{ print substr($1,length($1)-11,4) }'`
  endif 
   
  # extract lastyear from file name and parse to integer
  set d1  = `echo $oldfile | awk '{ print substr($1,length($1)-6,1) }'`
  echo "d1 = " $d1
  if ($d1 == 0) then
     echo "First digit = 0"
     set d2  = `echo $oldfile | awk '{ print substr($1,length($1)-5,1) }'`
     if ($d2 == 0) then
                echo "d2 = " $d2
                set d3  = `echo $oldfile | awk '{ print substr($1,length($1)-4,1) }'`
                echo "d3 = " $d3
                if ($d3 == 0) then      #---- 1 digit number
                        set lastyear  = `echo $oldfile | awk '{ print substr($1,length($1)-3,1) }'`
                else                    # ----2 digit number
                        set lastyear  = `echo $oldfile | awk '{ print substr($1,length($1)-4,2) }'`
                endif
     else                               # ----3 digit number
                        set lastyear  = `echo $oldfile | awk '{ print substr($1,length($1)-5,3) }'`
     endif
  else                                  # ----4 digit number
                        set lastyear  = `echo $oldfile | awk '{ print substr($1,length($1)-6,4) }'`
  endif
  # set firstyear = `echo $oldfile | awk '{ print substr($1,length($1)-11,4) }'`
  # set lastyear  = `echo $oldfile | awk '{ print substr($1,length($1)-6,4) }'`
  # set firstyear = `echo $oldfile | awk '{ print substr($1,length($1)-11,4) }'`
  echo "last  year 1 for hor_means: " $lastyear
  echo "First year 1 for hor_means: " $firstyear 

  
#  echo $oldfile | awk '{ print substr($1,length($1)-6,4) }'
#  echo $oldfile | awk '{ print substr($1,length($1)-11,4) }'
#  set last = `echo $oldfile | awk '{ print substr($1,length($1)-6,4) }'`
#  set first = `echo $oldfile | awk '{ print substr($1,length($1)-11,4) }'`
#  @ lastyear = $last
#  @ firstyear = $first
endif

## now, process any needed years
@ yr = $yr0
if (${?lastyear}) then
  if ($yr1 < $lastyear) then 
    echo "longer time series files already exist: ${oldfile}, etc"
    exit 1
  endif
  if ($yr0 < $lastyear) then 
    @ yr = $lastyear + 1
  endif
  if ($yr0 > ($lastyear + 1)) then 
    unset lastyear
  endif
endif

@ msread_cnt = 0
while ($yr <= $yr1)
  set year = `printf "%04d" $yr`
    if (! -e ${CASE}.pop.h.${year}.nc) then
      ls ${MSPY}/${CASE}.pop.h.${year}.nc
      if ($status == 0) then
        ln -sf ${MSPY}/${CASE}.pop.h.${year}.nc ${CASE}.pop.h.${year}.nc 
      else
        gen_pop_annmean.csh ${MSROOT} ${CASE} $yr $yr
      endif
    endif
    echo ${CASE}.pop.h.${year}.nc >> files_read
    @ msread_cnt++
    if ($msread_cnt >= $max_msread_cnt || $yr == $yr1 ) then
      wait
      foreach i (`less files_read`)
        @ in = 1
        while ( $in <= $nr )
          if ( ${region[$in]} == 'Glo' ) then
            ncwa -m REGION_MASK -T gt -M ${reg_num[$in]} -w TAREA -a nlon,nlat \
               -v TEMP,SALT $i ${region[$in]}_hor_mean_${i} &
          else
            ncwa -m REGION_MASK -T eq -M ${reg_num[$in]} -w TAREA -a nlon,nlat \
               -v TEMP,SALT $i ${region[$in]}_hor_mean_${i} &
          endif
          @ in++
        end
        wait
        @ in = 1
        while ( $in <= $nr )
          ncdiff -C ${region[$in]}_hor_mean_${i} \
               ${region[$in]}_hor_mean_obs.nc hor_mean_diff.nc
          ncrename -v TEMP,TEMP_DIFF -v SALT,SALT_DIFF hor_mean_diff.nc
          ncks -A -v TEMP_DIFF,SALT_DIFF hor_mean_diff.nc \
             ${region[$in]}_hor_mean_${i}
          \rm -f hor_mean_diff.nc
          @ in++
        end
        ncdiff -C -v TEMP,SALT ${i} obs.nc diff.nc
        ncks -A -v REGION_MASK,TAREA ${i} diff.nc
        @ in = 1
        while ( $in <= $nr )
          if ( ${region[$in]} == 'Glo' ) then
            ncwa -m REGION_MASK -T gt -M ${reg_num[$in]}  -w TAREA -a nlon,nlat \
               -y rms -v TEMP,SALT diff.nc ${region[$in]}_rms.nc &
          else
            ncwa -m REGION_MASK -T eq -M ${reg_num[$in]}  -w TAREA -a nlon,nlat \
               -y rms -v TEMP,SALT diff.nc ${region[$in]}_rms.nc &
          endif
          @ in++
        end
        wait
        @ in = 1
        while ( $in <= $nr )
          ncrename -v TEMP,TEMP_RMS -v SALT,SALT_RMS ${region[$in]}_rms.nc
          ncks -A -v TEMP_RMS,SALT_RMS ${region[$in]}_rms.nc \
             ${region[$in]}_hor_mean_${i}
          \rm -f ${region[$in]}_rms.nc
          @ in++
        end
        \rm -f ${i} diff.nc
      end
      \rm -f files_read
      @ msread_cnt = 0
    endif
  @ yr++
end

## concatenate all years into time series file
@ in = 1
set year1 = `printf "%04d" $yr1`
while ( $in <= $nr )
  if (${?lastyear}) then
     set year0 = `printf "%04d" $firstyear`
     set oldfile = `ls ${region[$in]}_hor_mean_${CASE}.????-????.nc`
     if ($#oldfile > 1) then
       echo "found more than one old time series on mass store"
       exit 1
     endif
     set newfile = ${region[$in]}_hor_mean_${CASE}.${year0}-${year1}.nc
     ncrcat ${oldfile} ${region[$in]}_hor_mean_${CASE}.pop.h.????.nc ${newfile}
     rm ${MSPTSY}/${oldfile}
  else
     set year0 = `printf "%04d" $yr0`
     set newfile = ${region[$in]}_hor_mean_${CASE}.${year0}-${year1}.nc
     ncrcat ${region[$in]}_hor_mean_${CASE}.pop.h.????.nc ${newfile}
  endif
  mkdir -p $MSPTSY 
  cp ${newfile} ${MSPTSY}/${newfile}
  \rm -f ${region[$in]}_hor_mean_${CASE}.pop.h.????.nc
   @ in++
end
wait

\rm -f obs.nc
\rm -f SALT_obs.nc
\rm -f *_hor_mean_obs.nc

endif

exit 0
