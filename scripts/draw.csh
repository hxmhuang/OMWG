#!/bin/csh -f

echo "=>Call analysis tools for plotting here......Begin"
if ($DOPLOTS == 1) then
    if (-e ncl_wrap.pro) then
    foreach i (`cat ncl_wrap.pro`)
	ncl $i
    end
    #ls *.ps
    #if ($status == 0) then
    #  foreach i (*.ps)
    #    convert -trim -bordercolor white -border 5x5 -density 85 $i $i.gif
    #    rename.pl '.ps' '' $i.gif
    #  end
    #endif
  endif
endif
echo "=>Call analysis tools for plotting here......End"

exit 0
