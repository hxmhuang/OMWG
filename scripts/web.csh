#!/bin/csh -f

echo "=>Finish & transfer web page and plots"
if ($DOWEB == 1) then
    if ($GLOSSARY == 1) cat ${HTMLPATH}/glossary.html >> $1 
    cat ${HTMLPATH}/footer.html >> $1
    scp $1 ${WEBMACH}:${WEBDIR}

    if ($DOPLOTS == 1) then
	scp *.asc *.gif *.png ${WEBMACH}:${WEBDIR}
    endif
endif

