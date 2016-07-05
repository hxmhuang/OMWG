How to use this omwg package:

(1) Modify your own case information in 'pub.sh'
####################################
setenv CASE $your_case_name # this name should be same with the case name in gen_newcase.csh. 
setenv RESOLUTION gx1v6
setenv YEAR0 1		#start year 
setenv YEAR1 10		#end year

setenv MSROOT /home/hxm/WORK3/CIESM/CIESM.ARCHIVE  # location of the monthly files
setenv OMWGROOT /home/hxm/WORK3/OMWG
setenv OBSDIR /home/share/cesm/ocn_obs_data

(2) Execute doall.csh to generate all figures, or use individual script one by one.
1_diag_mean_seas.csh: script for time-mean & seasonal diagnostics
2_diag_timeseries.csh: script for timeseries diagnostics
3_diag_diff.csh: script for time-mean & seasonal diagnostics, including differences relative to a control case

(3) All figures will output to 'OMWG/output' directory
