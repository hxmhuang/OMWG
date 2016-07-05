#!/bin/csh -f
#
#  Computes annual means from monthly POP history files, with
#    mass store read checks.  Must inherit the
#    following environment variables from parent
#    shell:  MSPROJ, MSRPD
#
#  Invoke as
#	pop_ann_mean.csh MSROOT CASENAME startyear endyear
#

set MSROOT = $1
set CASENAME = $2
@ yr0 = $3
@ yr1 = $4

setenv MSP /${MSROOT}/${CASENAME}/ocn/hist
setenv MSPY /${MSROOT}/${CASENAME}/ocn/proc/tavg/annual

@ yr = $yr0
while ($yr <= $yr1)

    set year = `printf "%04d" $yr`
    ls ${MSPY}/${CASENAME}.pop.h.${year}.nc
    if ($status == 0) then
      echo "linking:${MSPY}/${CASENAME}.pop.h.${year}.nc"
      ln -sf ${MSPY}/${CASENAME}.pop.h.${year}.nc ${CASENAME}.pop.h.${year}.nc
    else
      ls ${MSP}/${CASENAME}.pop.h.${year}.nc
      
      if ($status == 0 ) then
	echo "linking:${MSP}/${CASENAME}.pop.h.${year}.nc"
	ln -sf ${MSP}/${CASENAME}.pop.h.${year}.nc ${CASENAME}.pop.h.${year}.nc
      else
         echo "creating annual mean: ${CASENAME}.pop.h.${year}.nc"
	 ls ${MSP}/${CASENAME}.pop.h.${year}-01.nc
         if ($status == 0) then
	  set filesize = `ls -l ${MSP}/${CASENAME}.pop.h.${year}-01.nc | awk '$5 ~ /^[0-9]+$/{print $5}'`
	  #cp ${MSP}/${CASENAME}.pop.h.${year}-??.nc . & 
	  #wait
         else
           mssuntar.csh ${MSROOT} ${CASENAME} $yr $yr
	   wait
           set filesize =  `ls -l ${CASENAME}.pop.h.${year}-01.nc | awk '{print $5}'`
         endif
         set sizes = `ls -l ${CASENAME}.pop.h.${year}-??.nc | awk '{print $5}'`
         if ( $#sizes == 12 && \
           $sizes[1] == $filesize && \
           $sizes[2] == $filesize && \
           $sizes[3] == $filesize && \
           $sizes[4] == $filesize && \
           $sizes[5] == $filesize && \
           $sizes[6] == $filesize && \
           $sizes[7] == $filesize && \
           $sizes[8] == $filesize && \
           $sizes[9] == $filesize && \
           $sizes[10] == $filesize && \
           $sizes[11] == $filesize && \
           $sizes[12] == $filesize ) then

	   mkdir -p $MSPY 
           ncra ${MSP}/${CASENAME}.pop.h.${year}-??.nc ${MSPY}/${CASENAME}.pop.h.${year}.nc
	   ln -sf ${MSPY}/${CASENAME}.pop.h.${year}.nc ${CASENAME}.pop.h.${year}.nc 
          
	  else

            echo "CANNOT CREATE ${CASENAME}.pop.h.${year}.nc" && exit 1

          endif
         \rm -f ${CASENAME}.pop.h.${year}-??.nc
      endif
    endif
  @ yr++
end

#  check that all files were created successfully
set allgood = 1
@ yr = $yr0
while ($yr <= $yr1)
  set year = `printf "%04d" $yr`
  if (! -e ${CASENAME}.pop.h.${year}.nc) set allgood = 0
  @ yr++
end
if ($allgood == 1) then
  exit 0
else
  echo "ERROR in gen_pop_annmean.csh"
  exit 1
endif
