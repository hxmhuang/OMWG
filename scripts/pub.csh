#!/bin/csh -f
#==================Set case information===============================
setenv CASE 100years_GIAF_ne30_g16_rx1_300
setenv RESOLUTION gx1v6
setenv YEAR0 50		#start year 
setenv YEAR1 70		#end year

#==================Set path information===============================
set CURRDIR=$cwd

setenv MSROOT /home/hxm/WORK3/CIESM/CIESM.ARCHIVE  # location of the monthly files
setenv OMWGROOT /home/hxm/WORK3/OMWG
setenv OBSDIR /home/share/cesm/ocn_obs_data

setenv DIAGROOTPATH ${OMWGROOT}/scripts
setenv NCLPATH ${DIAGROOTPATH}/ncl_lib
setenv TOOLPATH ${DIAGROOTPATH}/tool_lib
setenv HTMLPATH ${DIAGROOTPATH}/html_lib
setenv MODPATH ${DIAGROOTPATH}/sourcemods
setenv TAVGFILE tavg.$YEAR0.$YEAR1.nc
setenv PATH ${DIAGROOTPATH}:${TOOLPATH}:${PATH}
#==================Set web page information==========================
setenv DOWEB 0		# generate a web page, but we don't test this function.:(  
setenv WEBMACH localhost.edu.cn 
setenv WEBDIR1 $HOME/${USER}/${CASE}
setenv WEBDIR2 ${WEBDIR1}/pd.${YEAR0}_${YEAR1}
setenv APPEND 0	        # append new plots if web page already exists
setenv GLOSSARY 1	# append a POP glossary at the bottom of web page

#==================Set NCL information===============================
setenv NCARG_ROOT ${ESM_SOFT}/ncl
setenv NCARG_COLORMAP_PATH $NCLPATH/colormaps:$NCARG_ROOT/lib/ncarg/colormaps
setenv NCLCOLORTABLEFILE ${NCARG_COLORMAP_PATH}/colors1.tbl
setenv NCLCOLORTABLE 42		
setenv NCLMINCOLOR 1
setenv NCLMAXCOLOR 254
setenv NCLLNDCOLOR 255
