#!/bin/csh -f
#=====================================================================
# Script for Timeseries Diagnostics
#=====================================================================
source pub.csh

#==================Set output path ===============================
setenv WORKDIR  ${OMWGROOT}/output/${CASE}_timeseries
setenv MSLOGREAD 1
setenv MOC0 10.	    # y-bounds for MOC timeseries plots
setenv MOC1 35.

#==================Set plot information===============================
setenv DOPLOTS 1		# generate plots for flagged PM's
setenv BASEDATE       0000-01-01
setenv NINO_MON_SKIP  0
## available plot modules
setenv PM_CPLLOG 	0	# CPL log energy budget line plots
setenv PM_YPOPLOG	1	# Yeager's log file line plots (new and improved)
setenv PM_HORZMN 	1	# Regional Mean T,S(z,t) w/ diff&rms from obs
setenv PM_ENSOWVLT	1	# ENSO wavelet plots
setenv PM_MOCANN 	1	# Annual mean max MOC time series
setenv PM_MOCMON  	1	# Monthly mean max MOC time series
setenv PM_GENANN 	1	# Generate annual means

#==================Set observation data information===================
setenv NINOOBSDIR $OBSDIR/nino
setenv NINOOBSFILE ANOMS_1950-2000.nc
setenv TSCLIMDIR  $OBSDIR/phc/POP_format
setenv TCLIMFILE PHC2_TEMP_${RESOLUTION}_ann_avg.nc
setenv SCLIMFILE PHC2_SALT_${RESOLUTION}_ann_avg.nc

#=====================================================================
# end user defined settings 
#=====================================================================
set yr0 = `printf "%04d" $YEAR0`
set yr1 = `printf "%04d" $YEAR1`
echo "Start year="$yr0 "End year="$yr1

if !(-d ${WORKDIR}) mkdir -p ${WORKDIR} 
cd ${WORKDIR} 
rm -rf *

if ($DOWEB == 1) then
    ssh -n ${WEBMACH} "if !(-d ${WEBDIR1}) mkdir -p -m 0775 ${WEBDIR1}"
    ssh -n ${WEBMACH} "if !(-d ${WEBDIR2}) mkdir -p -m 0775 ${WEBDIR2}"
    if ($APPEND == 1) then 
	scp ${WEBMACH}:${WEBDIR2}/popdiagts.html . && removefooter.csh popdiagts.html
    else
	svn info $DIAGROOTPATH > tmp
    setenv POPDIAGREV "`sed -n '/Revision/p' tmp`"
    echo "running popdiagts $POPDIAGREV"
    sed "s/CASENAME/${CASE}/g" ${HTMLPATH}/tsheader.html > tmp.html
    sed "s/REVISION/${POPDIAGREV}/g" tmp.html > popdiagts.html && \rm tmp*
    endif
endif

##==> generate a plot data file
##   which contains general plot information available
##   to any of the plot module routines via ascii read.
echo 0. 360. -90. 90. >! plot.dat
echo 1 >> plot.dat
echo 0. >> plot.dat

#==================Plot modules=======================================

#==============Plot CPL log annual mean energy budget time series=====
echo "=>Plot CPL log annual mean energy budget time series......Begin"
if ($PM_CPLLOG == 1) then
    if ($DOWEB == 1) cat ${HTMLPATH}/cpllog_timeseries.html >> popdiagts.html
    if ($DOPLOTS == 1) then
	if ($MSLOGREAD == 1) then 
	    echo "reading cpl log files"
	    \rm -f cpl.log.*
	    cp /$MSROOT/$CASE/cpl/logs/cpl.log* .
	    gunzip -f cpl.log*.gz
	endif
	#if ($CPL == 7b) then 
	    setenv ntailht 22
	    setenv ntailfw 16
	    ${TOOLPATH}/process_cpl7b_logfiles_heat.awk y0=$YEAR0 y1=$YEAR1 cpl.log* > cplheatbudget.txt
	    ${TOOLPATH}/process_cpl7b_logfiles_fw.awk y0=$YEAR0 y1=$YEAR1 cpl.log* > cplfwbudget.txt
	#else
	#    if ($CPL == 7) then 
	#	setenv ntailht 21
	#	setenv ntailfw 16
	#	${TOOLPATH}/process_cpl7_logfiles_heat.awk y0=$YEAR0 y1=$YEAR1 cpl.log* >! cplheatbudget.txt
	#	${TOOLPATH}/process_cpl7_logfiles_fw.awk y0=$YEAR0 y1=$YEAR1 cpl.log* >! cplfwbudget.txt
	#    else
	#	setenv ntailht 16
	#	setenv ntailfw 16
	#	${TOOLPATH}/process_cpl6_logfiles_heat.awk y0=$YEAR0 y1=$YEAR1 cpl.log* >! cplheatbudget.txt
	#	${TOOLPATH}/process_cpl6_logfiles_fw.awk y0=$YEAR0 y1=$YEAR1 cpl.log* >! cplfwbudget.txt
	#    endif
	#endif
	tail -${ntailfw} cplfwbudget.txt > cplfwbudget.asc
	tail -${ntailht} cplheatbudget.txt > cplheatbudget.asc
    endif
    addtowrapper.csh ncl cpl6_log_timeseries_heat.ncl ncl_wrap.pro 
    addtowrapper.csh ncl cpl6_log_timeseries_fw.ncl ncl_wrap.pro
endif
echo "=>Plot CPL log annual mean energy budget time series ......End"

#==================Plot log & dt file time series plots===============
echo "=>Plot log & dt file time series plots......Begin"
if ($PM_YPOPLOG == 1) then
    if ($DOWEB == 1) then 
	cat ${HTMLPATH}/poplog_timeseries_yeager.html >> popdiagts.html
    endif
    if ($DOPLOTS == 1) then
	if ($MSLOGREAD == 1) then 
	    echo "reading log files"
	    \rm -f ocn.log.*     
	    cp $MSROOT/$CASE/ocn/logs/ocn.log* .
	    cp $MSROOT/$CASE/ocn/hist/*.dt.* .
	    gunzip -f ocn.log*.gz
	endif
	${TOOLPATH}/process_pop2_logfiles.globaldiag.awk ocn.log.* 
	${TOOLPATH}/process_pop2_dtfiles.awk *.dt.* 
    endif
    addtowrapper.csh ncl pop_log_diagts_3d.monthly.ncl ncl_wrap.pro
    addtowrapper.csh ncl pop_log_diagts_hflux.monthly.ncl ncl_wrap.pro
    addtowrapper.csh ncl pop_log_diagts_fwflux.monthly.ncl ncl_wrap.pro
    addtowrapper.csh ncl pop_log_diagts_cfc.monthly.ncl ncl_wrap.pro
    addtowrapper.csh ncl pop_log_diagts_nino.monthly.ncl ncl_wrap.pro
    addtowrapper.csh ncl pop_log_diagts_transports.ncl ncl_wrap.pro
    if (-e diagts_precfactor.asc) addtowrapper.csh ncl pop_log_diagts_precf.ncl ncl_wrap.pro
endif
echo "=>Plot log & dt file time series plots......End"

#==================Plot TS meandiffrms timeseries====================
echo "=>Plot TS meandiffrms timeseries......Begin"
if ($PM_HORZMN == 1) then
    if ($DOWEB == 1) cat ${HTMLPATH}/horz_mean_timeseries.html >> popdiagts.html
    if ($DOPLOTS == 1) then
	ln -sf ${TSCLIMDIR}/${TCLIMFILE} .
	ln -sf ${TSCLIMDIR}/${SCLIMFILE} .
	if (! -e Sou_hor_mean_$CASE.$yr0-$yr1.nc) then
	gen_TS_meandiffrms_timeseries.csh $MSROOT $CASE $YEAR0 $YEAR1
    endif
    addtowrapper.csh ncl TS_profiles_diff_plot.ncl ncl_wrap.pro
  endif
endif
echo "=>Plot TS meandiffrms timeseries......End"

#==================Plot ENSO wavelet asc==============================
echo "=>Plot ENSO wavelet asc......Begin"
if ($PM_ENSOWVLT == 1) then
    if ($DOWEB == 1) cat ${HTMLPATH}/enso_wavelet.html >> popdiagts.html
    if ($DOPLOTS == 1) then
	if (! -e diagts_nino.asc) echo "need to run log diagnostics"
	setenv FILE_IN diagts_nino.asc
	addtowrapper.csh ncl enso_wavelet_asc.ncl ncl_wrap.pro
    endif
else
    setenv FILE_IN "null"
endif
echo "=>Plot ENSO wavelet asc......End"

#==================Plot MOC annual timeseries=========================
echo "=>Plot MOC annual timeseries......Begin"
if ($PM_MOCANN == 1) then
    if ($DOWEB == 1) cat ${HTMLPATH}/maxmoc.html >> popdiagts.html
    if ($DOPLOTS == 1) then
	set fields = (MOC N_HEAT N_SALT transport_regions transport_components moc_components)
	setenv MOCTSANNFILE $CASE.pop.h.MOC.${yr0}_cat_${yr1}.nc
	if !(-e ${MOCTSANNFILE}) then
	    gen_pop_annual_timeseries.csh $MOCTSANNFILE $MSROOT $CASE $YEAR0 $YEAR1 $fields
	endif
	addtowrapper.csh ncl moc_annual_timeseries.ncl ncl_wrap.pro
    endif
else
    setenv MOCTSANNFILE "null"
endif
echo "=>Plot MOC annual timeseries......End"

#==================Plot MOC monthly timeseries =======================
echo "=>Plot MOC monthly timeseries......Begin"
if ($PM_MOCMON == 1) then
    if ($DOWEB == 1) cat ${HTMLPATH}/maxmoc_monthly.html >> popdiagts.html
    if ($DOPLOTS == 1) then
	set fields = (MOC N_HEAT N_SALT transport_regions transport_components moc_components)
	setenv MOCTSMONFILE $CASE.pop.h.MOC.${yr0}-01_cat_${yr1}-12.nc
	if !(-e ${MOCTSMONFILE}) then
	    gen_pop_monthly_timeseries.csh $MOCTSMONFILE $MSROOT $CASE $YEAR0 $YEAR1 $fields
	endif
	addtowrapper.csh ncl moc_monthly_timeseries.ncl ncl_wrap.pro
    endif
else
    setenv MOCTSMONFILE "null"
endif
echo "=>Plot MOC monthly timeseries......End"

#==================Plot annul mean ===================================
echo "=>Plot annul mean......Begin"
if ($PM_GENANN == 1) then
    gen_pop_annmean.csh $MSROOT $CASE $YEAR0 $YEAR1
endif
echo "=>Plot annul mean......End"

#================Call analysis tools for plotting here================
draw.csh

#================Finish & transfer web page and plots ================
web.csh popdiagts.html

echo "DONE 2_diag_timeseries.csh:  CASE = $CASE, YEAR0 = $YEAR0, YEAR1 = $YEAR1"
