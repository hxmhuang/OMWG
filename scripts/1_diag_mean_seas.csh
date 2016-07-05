#!/bin/csh -f
#=====================================================================
# Script for Time-Mean & Seasonal Diagnostics
#=====================================================================
source pub.csh

#==================Set output path ===============================
setenv WORKDIR  ${OMWGROOT}/output/${CASE}_mean_seas

#==================Set plot information===============================
setenv DOPLOTS 1		# generate plots for flagged PM's
set xyrange  = (30 390 -90 90)  # x0,x1,y0,y1
set depths = (0 50 100 200 300 500 1000 1500 2000 2500 3000 3500 4000 )
setenv CNTRLVLS		std	# contour level options (gokhan, gauss)
# available plot modules
setenv PM_SFC2D 	1	# 2D surface fluxes 
setenv PM_FLD2D 	1	# all other 2D fields (HMXL, SSH, BSF, etc)
setenv PM_FLD3DZA 	1	# 3D field zonal average plots
setenv PM_MOC	 	1	# MOC, HT&FW transports
setenv PM_WBC	 	1	# WBC and DWBC diagnostics
setenv PM_SEAS	 	1	# Seasonal cycle plots
setenv PM_MLD		1	# mixed layer depth
setenv PM_TSZ	 	1	# T&S on depth surfaces, contours
setenv PM_PASSIVEZ 	1	# Passive tracers on depth surfaces, contours
setenv PM_VELZ	 	1	# UVEL,VVEL,WVEL on depth surfaces, contours
setenv PM_VELISOPZ	1	# Bolus velocities on depth surfaces, contours
setenv PM_KAPPAZ	1	# Diffusion Coeffs on depth surfaces, contours
setenv PM_UOEQ	 	1	# Upperocean T,S,PD,U @ Equator
setenv PM_VECV	 	1	# Vector Velocity w/ magnitude contours
setenv PM_POLARTS	1	# Polar Plots of T & S at depth
setenv PM_BASINAVGTS	1	# Depth Profiles of Basin-average T & S 
setenv PM_REGIONALTS	1	# Depth Profiles of regional mean T & S anom/stddev

#==================Set observation data information===================
setenv FLUXOBSDIR ${OBSDIR}/fluxes/Data/a.b27.03
setenv FLUXOBSFILE a.b27.03.mean.1984-2006.nc

setenv WINDOBSDIR $OBSDIR/fluxes/QSCAT
setenv WINDOBSFILE gx1v3.022.clim.2000-2004.nc
setenv SSHOBSDIR $OBSDIR/ssh
setenv SSHOBSFILE 1992-2002MDOT060401.${RESOLUTION}.nc
setenv SSTOBSDIR $OBSDIR/sst
setenv SSTOBSFILE roisst.nc
setenv TSOBSDIR $OBSDIR/phc
setenv TOBSFILE PHC2_TEMP_${RESOLUTION}_ann_avg.nc
setenv SOBSFILE PHC2_SALT_${RESOLUTION}_ann_avg.nc
setenv TOGATAODIR $OBSDIR/johnson_pmel
setenv TOGATAOFILE meanfit_m.nc
setenv RHOOBSDIR $OBSDIR/phc
setenv RHOOBSFILE PHC2_RHO0_${RESOLUTION}.nc

#=====================================================================
# end user defined settings 
#=====================================================================
set yr0 = `printf "%04d" $YEAR0`
set yr1 = `printf "%04d" $YEAR1`
echo "Start year="$yr0 "End year="$yr1

setenv NEED_CLIM 0
if ($PM_SEAS == 1) setenv NEED_CLIM 1
if ($PM_MLD == 1) setenv NEED_CLIM 1

if !(-d ${WORKDIR}) mkdir -p ${WORKDIR} 
cd ${WORKDIR} 
rm -rf *

if ($DOWEB == 1) then
    setenv WEBDIR ${WEBDIR2}
    ssh -n ${WEBMACH} "if !(-d ${WEBDIR1}) mkdir -p -m 0775 ${WEBDIR1}"
    ssh -n ${WEBMACH} "if !(-d ${WEBDIR}) mkdir -p -m 0775 ${WEBDIR}"
    if ($APPEND == 1) then 
	scp ${WEBMACH}:${WEBDIR}/popdiag.html . && removefooter.csh popdiag.html
    else
	svn info $DIAGROOTPATH > tmp
	setenv POPDIAGREV "`sed -n '/Revision/p' tmp`"
	echo "running popdiag $POPDIAGREV"
	sed "s/CASENAME/${CASE}/g" ${HTMLPATH}/header.html > tmp.html
	sed "s/REVISION/${POPDIAGREV}/g" tmp.html > popdiag.html && \rm tmp*
    endif
endif

# Generate needed netcdfs 
setenv SEASAVGTEMP ${CASE}.pop.h.TEMP.mavg_${yr0}-${yr1}.nc
setenv SEASAVGSALT ${CASE}.pop.h.SALT.mavg_${yr0}-${yr1}.nc
if (-e $SEASAVGTEMP && -e $SEASAVGSALT) setenv NEED_CLIM 0

setenv NEEDTAVG 0
if !(-e $TAVGFILE) setenv NEEDTAVG 1

echo "NEED_CLIM="$NEED_CLIM" NEEDTAVG="$NEEDTAVG

if ($NEED_CLIM == 1 || $NEEDTAVG == 1) then
    echo "=>Generate needed average netcdfs......"
    gen_mavg_annmean.csh $MSROOT $CASE $YEAR0 $YEAR1 $TAVGFILE TEMP SALT
endif

setenv gridfile $DIAGROOTPATH/tool_lib/zon_avg/grids/${RESOLUTION}_grid_info.nc

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
    addtowrapper.csh ncl sfcflx.ncl ncl_wrap.pro
    addtowrapper.csh ncl sfcflx_za.ncl ncl_wrap.pro 
    ln -sf ${FLUXOBSDIR}/${FLUXOBSFILE} .
    ln -sf ${FLUXOBSDIR}/za_${FLUXOBSFILE} .
    ln -sf ${WINDOBSDIR}/${WINDOBSFILE} .
    ln -sf ${WINDOBSDIR}/za_${WINDOBSFILE} .
    if !(-e za_$TAVGFILE) then
	za -O -time_const -grid_file $gridfile $TAVGFILE
    endif
endif
echo "=>Plot surface flux fields......End"

#==================Plot 2D(surface) fields===========================
echo "=>Plot 2d(surface) fields......Begin"
if ($PM_FLD2D == 1) then
    if ($DOWEB == 1) cat ${HTMLPATH}/field_2d.html >> popdiag.html
    addtowrapper.csh ncl ssh.ncl ncl_wrap.pro 
    addtowrapper.csh ncl field_2d.ncl ncl_wrap.pro 
    addtowrapper.csh ncl field_2d_za.ncl ncl_wrap.pro 
    ln -sf ${SSHOBSDIR}/${SSHOBSFILE} .
    if !(-e za_$TAVGFILE) then
	za -O -time_const -grid_file $gridfile $TAVGFILE
    endif
endif
echo "=>Plot 2d(surface) fields......end"

#==================Plot 3D fields (zonal average)=====================
echo "=>Plot 3D fields (zonal average)......Begin"
if ($PM_FLD3DZA == 1) then
    if ($DOWEB == 1) cat ${HTMLPATH}/field_3d_za.html >> popdiag.html
    addtowrapper.csh ncl field_3d_za.ncl ncl_wrap.pro
    if !(-e za_$TAVGFILE) then
	za -O -time_const -grid_file $gridfile $TAVGFILE
    endif
    if !(-e za_${TOBSFILE}) then
	cp ${TSOBSDIR}/${TOBSFILE} ${TOBSFILE}_tmp
	ncks -A -v UAREA $TAVGFILE ${TOBSFILE}_tmp
	za -O -time_const -grid_file $gridfile ${TOBSFILE}_tmp
	mv za_${TOBSFILE}_tmp za_${TOBSFILE}
	\rm -f ${TOBSFILE}_tmp
    endif
    if !(-e za_${SOBSFILE}) then
	cp ${TSOBSDIR}/${SOBSFILE} ${SOBSFILE}_tmp
	ncks -A -v UAREA $TAVGFILE ${SOBSFILE}_tmp
	za -O -time_const -grid_file $gridfile ${SOBSFILE}_tmp
	mv za_${SOBSFILE}_tmp za_${SOBSFILE}
	\rm -f ${SOBSFILE}_tmp
    endif
endif
echo "=>Plot 3D fields (zonal average)......End"

#================Plot MOC & Heat/Freshwater transport=================
echo "=>Plot MOC & Heat/Freshwater transport......Begin"
##==> MOC & Heat/Freshwater transport plots
if ($PM_MOC == 1) then
    if ($DOWEB == 1) cat ${HTMLPATH}/moc.html >> popdiag.html
    addtowrapper.csh ncl moc_netcdf.ncl ncl_wrap.pro
endif
echo "=>Plot MOC & Heat/Freshwater transport......End"

#================Plot Western Boundary Current & DWBC================ 
echo "=>Plot Western Boundary Current & DWBC......Begin"
##==> Western Boundary Current & DWBC diagnostics
if ($PM_WBC == 1) then
    if ($DOWEB == 1) cat ${HTMLPATH}/wbc.html >> popdiag.html
    addtowrapper.csh ncl dwbc.ncl ncl_wrap.pro
endif

if ($PM_SEAS == 1) then
    setenv SEASAVGFILE $SEASAVGTEMP
    if ($DOWEB == 1) cat ${HTMLPATH}/seasonal.html >> popdiag.html
    addtowrapper.csh ncl sst_eq_pac_seasonal_cycle.ncl ncl_wrap.pro
    ln -sf ${SSTOBSDIR}/${SSTOBSFILE} .
else
    setenv SEASAVGFILE "null"
endif
echo "=>Plot Western Boundary Current & DWBC......End"


#================Plot Mixed layer depth ==============================
echo "=>Plot Mixed layer depth......Begin"
##==> Mixed layer depth plots
if ($PM_MLD == 1) then
    if ($DOWEB == 1) cat ${HTMLPATH}/mld.html >> popdiag.html
    setenv SEASAVGRHO  ${CASE}.pop.h.RHO.mavg_${yr0}-${yr1}.nc
    if !(-e $SEASAVGRHO) then
	addtowrapper.csh ncl compute_rho.ncl ncl_wrap.pro
    endif
    addtowrapper.csh ncl mld.ncl ncl_wrap.pro
    ln -sf ${RHOOBSDIR}/${RHOOBSFILE} .
else
    setenv SEASAVGRHO "null"
endif
echo "=>Plot Mixed layer depth......End"

#================Plot TEMP & SALT at depth levels====================
echo "=>Plot TEMP & SALT at depth levels......Begin"
if ($PM_TSZ == 1) then
    if ($DOWEB == 1) then
        setenv MODULETITLE 'T & S at depth'
	gen_html_multivarz.csh 2 TEMP SALT 13 $depths
        cat tmp.html >> popdiag.html && \rm tmp.html
    endif
    addtowrapper.csh ncl tempz.ncl ncl_wrap.pro 
    addtowrapper.csh ncl saltz.ncl ncl_wrap.pro
    ln -sf ${TSOBSDIR}/${TOBSFILE} .
    ln -sf ${TSOBSDIR}/${SOBSFILE} .
endif
echo "=>Plot TEMP & SALT at depth levels......End"

#================Plot Passive Tracers at depth levels====================
echo "=>Plot Passive Tracers at depth levels......Begin"
if ($PM_PASSIVEZ == 1) then
    if ($DOWEB == 1) then
	setenv MODULETITLE 'Passive Tracers at depth'
	gen_html_multivarz.csh 1 IAGE 13 $depths
	cat tmp.html >> popdiag.html && \rm tmp.html
    endif
    addtowrapper.csh ncl iagez.ncl ncl_wrap.pro
endif
echo "=>Plot Passive Tracers at depth levels......End"

#================Plot Eulerian velocity at depth levels====================
echo "=>Plot Eulerian velocity at depth levels......Begin"
if ($PM_VELZ == 1) then
    if ($DOWEB == 1) then
	setenv MODULETITLE 'Eulerian Velocity Components at depth'
	gen_html_multivarz.csh 3 UVEL VVEL WVEL 13 $depths
	cat tmp.html >> popdiag.html && \rm tmp.html
    endif
    addtowrapper.csh ncl uvelz.ncl ncl_wrap.pro
    addtowrapper.csh ncl vvelz.ncl ncl_wrap.pro
    addtowrapper.csh ncl wvelz.ncl ncl_wrap.pro
endif
echo "=>Plot Eulerian velocity at depth levels......End"

#================Plot bolus velocity at depth levels==================
echo "=>Plot bolus velocity at depth levels......Begin"
if ($PM_VELISOPZ == 1) then
    if ($DOWEB == 1) then
	setenv MODULETITLE 'Bolus Velocity Components at depth'
	gen_html_multivarz.csh 3 UISOP VISOP WISOP 13 $depths
        cat tmp.html >> popdiag.html && \rm tmp.html
    endif
    addtowrapper.csh ncl uisopz.ncl ncl_wrap.pro
    addtowrapper.csh ncl visopz.ncl ncl_wrap.pro
    addtowrapper.csh ncl wisopz.ncl ncl_wrap.pro
endif
echo "=>Plot bolus velocity at depth levels......End"

#================Plot Diffusion Coefficients at depth levels=========
echo "=>Plot Diffusion Coefficients at depth levels......Begin"
if ($PM_KAPPAZ == 1) then
    if ($DOWEB == 1) then
        setenv MODULETITLE 'Diffusion Coefficients at depth'
	gen_html_multivarz.csh 2 KAPPA_ISOP KAPPA_THIC 13 $depths
        cat tmp.html >> popdiag.html && \rm tmp.html
    endif
    addtowrapper.csh ncl kappa_isopz.ncl ncl_wrap.pro
    addtowrapper.csh ncl kappa_thicz.ncl ncl_wrap.pro
endif
echo "=>Plot Diffusion Coefficients at depth levels......End"

#========Plot Upperocean at the Equator; compared to PHC2, TOGA-TAO===
echo "=>Plot Upperocean at the Equator; compared to PHC2, TOGA-TAO......Begin"
if ($PM_UOEQ == 1) then
    if ($DOWEB == 1) cat ${HTMLPATH}/eq_upperocean.html >> popdiag.html
    addtowrapper.csh ncl T_eq.ncl ncl_wrap.pro
    addtowrapper.csh ncl S_eq.ncl ncl_wrap.pro
    addtowrapper.csh ncl U_eq.ncl ncl_wrap.pro
    addtowrapper.csh ncl U_eq_meridional.ncl ncl_wrap.pro
    addtowrapper.csh ncl T_eq_meridional.ncl ncl_wrap.pro
    addtowrapper.csh ncl S_eq_meridional.ncl ncl_wrap.pro
    addtowrapper.csh ncl PD_eq_meridional.ncl ncl_wrap.pro
    ln -sf ${TOGATAODIR}/${TOGATAOFILE} .
endif
echo "=>Plot Upperocean at the Equator; compared to PHC2, TOGA-TAO......End"

#================Plot Velocity vector/magnitude at depth levels=======
echo "=>Plot Velocity vector/magnitude at depth levels......Begin"
if ($PM_VECV == 1) then
    if ($DOWEB == 1) then
        setenv MODULETITLE 'Horizontal Vector Fields at depth'
	gen_html_multivarz.csh 1 VELOCITY 13 $depths
        cat tmp.html >> popdiag.html && \rm tmp.html
    endif
    addtowrapper.csh ncl vecvelz.ncl ncl_wrap.pro
endif
echo "=>Plot Velocity vector/magnitude at depth levels......End"

#================Plot POLAR TEMP & SALT at depth levels====================
echo "=>Plot POLAR TEMP & SALT at depth levels......Begin"
if ($PM_POLARTS == 1) then
    if ($DOWEB == 1) then
        setenv MODULETITLE 'Polar T & S at depth'
	gen_html_multivarz.csh 4 Arctic_TEMP Arctic_SALT Antarctic_TEMP Antarctic_SALT 13 $depths
        cat tmp.html >> popdiag.html && \rm tmp.html
    endif
    ln -sf ${TSOBSDIR}/${TOBSFILE} .
    ln -sf ${TSOBSDIR}/${SOBSFILE} .
    addtowrapper.csh ncl tempz_arctic.ncl ncl_wrap.pro
    addtowrapper.csh ncl saltz_arctic.ncl ncl_wrap.pro
    addtowrapper.csh ncl tempz_antarctic.ncl ncl_wrap.pro
    addtowrapper.csh ncl saltz_antarctic.ncl ncl_wrap.pro
endif
echo "=>Plot POLAR TEMP & SALT at depth levels......End"

#================Plot Depth Profiles of Basin-average T & S====================
echo "=>Plot Depth Profiles of Basin-average T & S......Begin"
if ($PM_BASINAVGTS == 1) then
    if ($DOWEB == 1) cat ${HTMLPATH}/basinavg.html >> popdiag.html
	addtowrapper.csh ncl TS_basinavg_arctic.ncl ncl_wrap.pro
    if !(-e ${TOBSFILE}) ln -sf ${TSOBSDIR}/${TOBSFILE} .
    if !(-e ${SOBSFILE}) ln -sf ${TSOBSDIR}/${SOBSFILE} .
endif
echo "=>Plot Depth Profiles of Basin-average T & S......End"

#=====Plot Depth Profiles of Regional area-averaged T & S bias and stddev====
echo "=>Plot Depth Profiles of Regional area-averaged T & S bias and stddev......Begin"
if ($PM_REGIONALTS == 1) then
    if ($DOWEB == 1) cat ${HTMLPATH}/regionalts.html >> popdiag.html
    addtowrapper.csh ncl regionalTbias500m.ncl ncl_wrap.pro
    addtowrapper.csh ncl regionalSbias500m.ncl ncl_wrap.pro
    addtowrapper.csh ncl regionalTbias2000m.ncl ncl_wrap.pro
    addtowrapper.csh ncl regionalSbias2000m.ncl ncl_wrap.pro
    if !(-e ${TOBSFILE}) ln -sf ${TSOBSDIR}/${TOBSFILE} .
    if !(-e ${SOBSFILE}) ln -sf ${TSOBSDIR}/${SOBSFILE} .
endif
echo "=>Plot Depth Profiles of Regional area-averaged T & S bias and stddev......End"

#================Call analysis function in pub.csh for plotting here================
draw.csh

#================Finish & transfer web page and plots ====================
web.csh popdiag.html

echo "DONE 1_diag_timemean_seasonal.csh:  CASE = $CASE, YEAR0 = $YEAR0, YEAR1 = $YEAR1"
