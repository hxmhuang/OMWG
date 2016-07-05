#!/bin/csh -f

echo '==============================Start===================================='
echo '=>1_diag_timemean_seasonal.csh Running'
time ./1_diag_mean_seas.csh

echo '======================================================================='
echo '=>2_diag_timeseries.csh Running'
time ./2_diag_timeseries.csh

echo '======================================================================='
echo '=>3_diag_diff.csh Running'
time ./3_diag_diff.csh

echo '================================End===================================='
