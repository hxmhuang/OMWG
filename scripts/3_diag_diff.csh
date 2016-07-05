#!/bin/csh -f
#=====================================================================
#   Script for Time-Mean & Seasonal Diagnostics
#   including differences relative to a control case
#=====================================================================
source pub.csh

#==================Set control case information===============================
setenv CNTRLCASE ${CASE} 
setenv CNTRLRESOLUTION $RESOLUTION 
setenv CNTRLYEAR0 $YEAR0 
setenv CNTRLYEAR1 $YEAR1 

#==================Set path information===============================
setenv WORKDIR  ${OMWGROOT}/output/${CASE}_${CNTRLCASE}_diff
setenv CNTRLFILE tavg.$CNTRLYEAR0.$CNTRLYEAR1.cntrl.nc
setenv CNTRLMSROOT ${MSROOT}

#==================Set plot information===============================
setenv DOPLOTS 1		# generate plots for flagged PM's
set xyrange  = (30 390 -90 90)  # x0,x1,y0,y1
set depths = (0 50 100 200 300 500 1000 1500 2000 2500 3000 3500 4000 )
setenv CNTRLVLS		std	# contour level options (std, gauss)
## available plot modules
setenv PM_SFC2D 	1	# 2D surface fluxes 
setenv PM_FLD2D 	1	# all other 2D fields (HMXL, SSH, BSF, etc)
setenv PM_FLD3DZA 	1	# 3D field zonal average plots
setenv PM_UOEQ	 	1	# Upperocean T,S,PD,U @ Equator
setenv PM_MOC	 	1	# MOC, HT&FW transports
setenv PM_SEAS		1	# Seasonal cycle plots
setenv PM_MLD		1   # mixed layer depth
setenv PM_TSZ	 	1	# T&S on depth surfaces, contours
setenv PM_PASSIVEZ 	1	# Passive tracers on depth surfaces, contours
setenv PM_VELZ	 	1	# UVEL,VVEL,WVEL on depth surfaces, contours
setenv PM_VELISOPZ	1	# Bolus velocities on depth surfaces, contours
setenv PM_KAPPAZ	1	# Diffusion Coeffs on depth surfaces, contours

#==================Set observation data information===================
setenv FLUXOBSDIR $OBSDIR/fluxes/Data/a.b27.03
setenv FLUXOBSFILE a.b27.03.mean.1984-2006.nc
setenv WINDOBSDIR $OBSDIR/fluxes/QSCAT
setenv WINDOBSFILE gx1v3.022.clim.2000-2004.nc
setenv SSTOBSDIR $OBSDIR/sst 
setenv SSTOBSFILE roisst.nc
setenv TSOBSDIR $OBSDIR/phc
setenv TOBSFILE PHC2_TEMP_${RESOLUTION}_ann_avg.nc
setenv SOBSFILE PHC2_SALT_${RESOLUTION}_ann_avg.nc
setenv TOGATAODIR  $OBSDIR/johnson_pmel 
setenv TOGATAOFILE meanfit_m.nc

#=====================================================================
# end user defined settings 
#=====================================================================
set yr0 = `printf "%04d" $YEAR0`
set yr1 = `printf "%04d" $YEAR1`
echo "Start year="$yr0 "End year="$yr1

set cntrlyr0 = `printf "%04d" $CNTRLYEAR0`
set cntrlyr1 = `printf "%04d" $CNTRLYEAR1`
echo "Control Start year="$cntrlyr0 "Control End year="$cntrlyr1

setenv NEED_CLIM 0
if ($PM_SEAS == 1) setenv NEED_CLIM 1
if ($PM_MLD == 1) setenv NEED_CLIM 1


if !(-d ${WORKDIR}) mkdir -p ${WORKDIR} 
cd ${WORKDIR} 
rm -rf *

if ($DOWEB == 1) then
    @ dlon = ($xyrange[2] - $xyrange[1])
    @ dlat = ($xyrange[4] - $xyrange[3])
    if ($dlon == 360 && $dlat == 180) then
	set tail = global
    else
	set tail = ${xyrange[1]}to${xyrange[2]}E.${xyrange[3]}to${xyrange[4]}N
    endif
    setenv WEBDIR ${WEBDIR2}.${tail}
    ssh -n ${WEBMACH} "if !(-d ${WEBDIR1}) mkdir -p -m 0775 ${WEBDIR1}"
    ssh -n ${WEBMACH} "if !(-d ${WEBDIR}) mkdir -p -m 0775 ${WEBDIR}"
    if ($APPEND == 1) then 
	scp ${WEBMACH}:${WEBDIR}/popdiag.html . && removefooter.csh popdiag.html
    else
	svn info $DIAGROOTPATH > tmp
	setenv POPDIAGREV "`sed -n '/Revision/p' tmp`" && \rm -f tmp
	echo "running diag $POPDIAGREV"
	sed "s/CASENAME/${CASE}/g" ${HTMLPATH}/diffheader.html > tmp.html
	sed "s/CNTRLCASE/${CNTRLCASE}/g" tmp.html > popdiag.html
	sed "s/REVISION/${POPDIAGREV}/g" popdiag.html > tmp.html 
	mv -f tmp.html popdiag.html
    endif
endif

####################  Generate needed netcdfs 
setenv SEASAVGTEMP ${CASE}.pop.h.TEMP.mavg_${yr0}-${yr1}.nc
setenv SEASAVGSALT ${CASE}.pop.h.SALT.mavg_${yr0}-${yr1}.nc
setenv CNTRLSEASAVGTEMP ${CNTRLCASE}.pop.h.TEMP.mavg_${cntrlyr0}-${cntrlyr1}.nc
setenv CNTRLSEASAVGSALT ${CNTRLCASE}.pop.h.SALT.mavg_${cntrlyr0}-${cntrlyr1}.nc

setenv NEED_CLIM_EXP 0
setenv NEED_CLIM_CNTRL 0
if ($NEED_CLIM == 1) then
    if !(-e $SEASAVGTEMP && -e $SEASAVGSALT) setenv NEED_CLIM_EXP 1
    if !(-e $CNTRLSEASAVGTEMP && -e $CNTRLSEASAVGSALT) setenv NEED_CLIM_CNTRL 1
endif

setenv NEEDTAVG 0
if !(-e $TAVGFILE) setenv NEEDTAVG 1
echo "NEED_CLIM_EXP="$NEED_CLIM_EXP" NEEDTAVG="$NEEDTAVG

###setenv $NEED_CLIM $NEED_CLIM_EXP
setenv NEED_CLIM $NEED_CLIM_EXP
if ($NEED_CLIM_EXP == 1 || $NEEDTAVG == 1) then
    gen_mavg_annmean.csh $MSROOT $CASE $YEAR0 $YEAR1 $TAVGFILE TEMP SALT
endif

setenv NEEDTAVG 0
if !(-e $CNTRLFILE) setenv NEEDTAVG 1
echo "NEED_CLIM_CNTRL="$NEED_CLIM_CNTRL" NEEDTAVG="$NEEDTAVG

###setenv $NEED_CLIM $NEED_CLIM_CNTRL
setenv NEED_CLIM $NEED_CLIM_CNTRL
if ($NEED_CLIM_CNTRL == 1 || $NEEDTAVG == 1) then
  gen_mavg_annmean.csh $CNTRLMSROOT $CNTRLCASE $CNTRLYEAR0 $CNTRLYEAR1 $CNTRLFILE TEMP SALT
endif

# NEEDZAVG variables are used for Swift version
setenv NEEDZAVG_EXP 0
setenv NEEDZAVG_CNTRL 0
setenv gridfile $DIAGROOTPATH/tool_lib/zon_avg/grids/$RESOLUTION*_grid_info.nc
setenv gridfilecntrl $DIAGROOTPATH/tool_lib/zon_avg/grids/$CNTRLRESOLUTION*_grid_info.nc

##==> generate a plot data file 
##   which contains general plot information available
##   to any of the plot module routines via ascii read.
echo $xyrange >! plot.dat
echo $#depths >> plot.dat
echo $depths >> plot.dat

#==================Plot modules=======================================

#==================Plot surface flux fields===========================
echo "=>Plot surface flux fields......Begin"
if ($PM_SFC2D == 1) then
    if ($DOWEB == 1) cat ${HTMLPATH}/sfcflx.html >> popdiag.html
    addtowrapper.csh ncl sfcflx_diff.ncl ncl_wrap.pro 
    addtowrapper.csh ncl sfcflx_za_diff.ncl ncl_wrap.pro 
    if !(-e za_$TAVGFILE) then
	za -O -time_const -grid_file $gridfile $TAVGFILE
    endif
    if !(-e za_$CNTRLFILE) then
	za -O -time_const -grid_file $gridfilecntrl $CNTRLFILE
    endif
endif
echo "=>Plot surface flux fields......End"

#==================Plot 2D (surface) fields===========================
echo "=>Plot 2D (surface) fields......Begin"
if ($PM_FLD2D == 1) then
    if ($DOWEB == 1) cat ${HTMLPATH}/field_2d.html >> popdiag.html
    addtowrapper.csh ncl field_2d_diff.ncl ncl_wrap.pro 
    addtowrapper.csh ncl field_2d_za_diff.ncl ncl_wrap.pro 
    if !(-e za_$TAVGFILE) then
	za -O -time_const -grid_file $gridfile $TAVGFILE
    endif
endif
echo "=>Plot 2D (surface) fields......End"

#==================Plot 3D fields (zonal average)===========================
echo "=>Plot 3D fields (zonal average)......Begin"
if ($PM_FLD3DZA == 1) then
    if ($DOWEB == 1) cat ${HTMLPATH}/field_3d_za.html >> popdiag.html
    addtowrapper.csh ncl field_3d_za_diff.ncl ncl_wrap.pro
endif
echo "=>Plot 3D fields (zonal average)......End"

#==================Plot MOC & Heat/Freshwater transport plots===========================
echo "=>Plot MOC & Heat/Freshwater transport plots......Begin"
if ($PM_MOC == 1) then
    if ($DOWEB == 1) cat ${HTMLPATH}/moc.html >> popdiag.html
    addtowrapper.csh ncl moc_netcdf_diff.ncl ncl_wrap.pro
endif
echo "=>Plot MOC & Heat/Freshwater transport plots......End"

#==================Plot All seasonal===========================
echo "=>Plot All seasonal......Begin"
if ($PM_SEAS == 1) then
    setenv SEASAVGFILE ${SEASAVGTEMP}
    setenv CNTRLSEASAVGFILE ${CNTRLSEASAVGTEMP}
    if ($DOWEB == 1) cat ${HTMLPATH}/seasonal.html >> popdiag.html
    addtowrapper.csh ncl sst_eq_pac_seasonal_cycle_diff.ncl ncl_wrap.pro
    ln -sf ${SSTOBSDIR}/${SSTOBSFILE} .
else
    setenv SEASAVGFILE "null"
    setenv CNTRLSEASAVGFILE "null"
endif

echo "=>Plot All seasonal......End"

#==================Plot mixed layer depth difference===========================
echo "=>Plot mixed layer depth difference......Begin"
if ($PM_MLD == 1) then
    if ($DOWEB == 1) cat ${HTMLPATH}/mld.html >> popdiag.html
    setenv SEASAVGRHO  ${CASE}.pop.h.RHO.mavg_${yr0}-${yr1}.nc
    setenv CNTRLSEASAVGRHO  ${CNTRLCASE}.pop.h.RHO.mavg_${cntrlyr0}-${cntrlyr1}.nc
    if !(-e $SEASAVGRHO) then
	addtowrapper.csh ncl compute_rho.ncl ncl_wrap.pro
    endif
    if !(-e $CNTRLSEASAVGRHO) then
	addtowrapper.csh ncl compute_rho_cntl.ncl ncl_wrap.pro
    endif
    addtowrapper.csh ncl mld_diff.ncl ncl_wrap.pro
else
    setenv SEASAVGRHO "null"
    setenv CNTRLSEASAVGRHO "null"
endif
echo "=>Plot mixed layer depth difference......End"

#==================Plot TEMP & SALT at depth levels===========================
echo "=>Plot TEMP & SALT at depth levels......Begin"
if ($PM_TSZ == 1) then
    if ($DOWEB == 1) then
        setenv MODULETITLE 'T & S at depth'
	gen_html_multivarz.csh 2 TEMP SALT 13 $depths
        cat tmp.html >> popdiag.html && \rm tmp.html
    endif
    addtowrapper.csh ncl tempz_diff.ncl ncl_wrap.pro 
    addtowrapper.csh ncl saltz_diff.ncl ncl_wrap.pro
endif
echo "=>Plot TEMP & SALT at depth levels......End"

#==================Plot Passive Tracers at depth levels===========================
echo "=>Plot Passive Tracers at depth levels......Begin"
if ($PM_PASSIVEZ == 1) then
    if ($DOWEB == 1) then
	setenv MODULETITLE 'Passive Tracers at depth'
	gen_html_multivarz.csh 1 IAGE 13 $depths
        cat tmp.html >> popdiag.html && \rm tmp.html
    endif
    addtowrapper.csh ncl iagez_diff.ncl ncl_wrap.pro
endif
echo "=>Plot Passive Tracers at depth levels......End"

#==================Plot velocity===========================
echo "=>Plot velocity......Begin"
if ($PM_VELZ == 1) then
    if ($DOWEB == 1) then
        setenv MODULETITLE 'Eulerian Velocity Components at depth'
	gen_html_multivarz.csh 3 UVEL VVEL WVEL 13 $depths
        cat tmp.html >> popdiag.html && \rm tmp.html
    endif
    addtowrapper.csh ncl uvelz_diff.ncl ncl_wrap.pro
    addtowrapper.csh ncl vvelz_diff.ncl ncl_wrap.pro
    addtowrapper.csh ncl wvelz_diff.ncl ncl_wrap.pro
endif
echo "=>Plot velocity......End"

#==================Plot isopz===========================
echo "=>Plot isopz......Begin"
if ($PM_VELISOPZ == 1) then
    if ($DOWEB == 1) then
        setenv MODULETITLE 'Bolus Velocity Components at depth'
	gen_html_multivarz.csh 3 UISOP VISOP WISOP 13 $depths
        cat tmp.html >> popdiag.html && \rm tmp.html
    endif
    addtowrapper.csh ncl uisopz_diff.ncl ncl_wrap.pro
    addtowrapper.csh ncl visopz_diff.ncl ncl_wrap.pro
    addtowrapper.csh ncl wisopz_diff.ncl ncl_wrap.pro
endif
echo "=>Plot isopz......End"

#==================Plot Diffusion Coefficients at depth levels===========================
echo "=>Plot Diffusion Coefficients at depth levels......Begin"
if ($PM_KAPPAZ == 1) then
    if ($DOWEB == 1) then
        setenv MODULETITLE 'Diffusion Coefficients at depth'
	gen_html_multivarz.csh 2 KAPPA_ISOP KAPPA_THIC 13 $depths
        cat tmp.html >> popdiag.html && \rm tmp.html
    endif
    addtowrapper.csh ncl kappa_isopz_diff.ncl ncl_wrap.pro
    addtowrapper.csh ncl kappa_thicz_diff.ncl ncl_wrap.pro
endif
echo "=>Plot Diffusion Coefficients at depth levels......End"

#==================Plot Upperocean at the Equator; compared to PHC2, TOGA-TAO===========================
echo "=>Plot Upperocean at the Equator; compared to PHC2, TOGA-TAO......Begin"
if ($PM_UOEQ == 1) then
    if ($DOWEB == 1) cat ${HTMLPATH}/eq_upperocean.html >> popdiag.html
    addtowrapper.csh ncl T_eq_diff.ncl ncl_wrap.pro
    addtowrapper.csh ncl S_eq_diff.ncl ncl_wrap.pro
    addtowrapper.csh ncl U_eq_diff.ncl ncl_wrap.pro
    addtowrapper.csh ncl U_eq_meridional_diff.ncl ncl_wrap.pro
    addtowrapper.csh ncl T_eq_meridional_diff.ncl ncl_wrap.pro
    addtowrapper.csh ncl S_eq_meridional_diff.ncl ncl_wrap.pro
    addtowrapper.csh ncl PD_eq_meridional_diff.ncl ncl_wrap.pro
    ln -sf ${TOGATAODIR}/${TOGATAOFILE} .
endif
echo "=>Plot Upperocean at the Equator; compared to PHC2, TOGA-TAO......End"

#================Call analysis tools for plotting here================
draw.csh

#================Finish & transfer web page and plots ================
web.csh popdiag.html

echo "DONE 3_diag_diff.csh:  CASE = $CASE, CNTRLCASE= $CNTRLCASE"
