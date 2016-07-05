
UNAMES = $(shell uname)
FC    = unknown_FC
null  =
FIXED = $(null)
FREE  = $(null)

# CISL DASG machines
#DASG = $(shell uname -n | grep -i -E -c 'mirage0|mirage1|mirage2|mirage3|mirage4|mirage5')
#ifeq ($(DASG),1)
#  FC = ifort
#  INCLUDE = -I/fs/local/include
#  FFLAGS = -c -O2
#  LIBS = -L/fs/local/lib -lnetcdf -lhdf5 -lhdf5_hl -lcurl
#   FC = gfortran
#   INCLUDE = -I/fs/local/apps/netcdf-4.1.3-beta1/include
#   FFLAGS = -c -g -O2
#   LIBS = -L/fs/local/apps/netcdf-4.1.3-beta1/lib -lnetcdff -lnetcdf
   FC = ifort 
   INCLUDE = -I/home/share/cesm/software/esm-soft/include
   FFLAGS = -c -O2
   LIBS = -L/home/share/cesm/software/esm-soft/lib  -lnetcdff -lnetcdf -lpnetcdf -lhdf5_hl -lhdf5 -lsz -lm -lcurl 
#endif

.SUFFIXES:            # Delete the default suffixes
.SUFFIXES: .F .F90 .o # Define our suffix list

.F.o:
	$(FC) $(FIXED) $(FFLAGS) $(INCLUDE) $<

.F90.o:
	$(FC) $(FREE) $(FFLAGS) $(INCLUDE) $<

OBJECTS = main.o kinds_mod.o constants.o arg_wrap.o nf_wrap.o nf_wrap_stubs.o msg_mod.o sphere_area_mod.o POP_grid_mod.o zonal_avg_mod.o

za: $(OBJECTS)
	$(FC) $(OBJECTS) $(LIBS) -o za

kinds_mod.o: kinds_mod.F90
arg_wrap.o: arg_wrap.F90 kinds_mod.o
constants.o: constants.F90 kinds_mod.o
msg_mod.o: msg_mod.F90 kinds_mod.o
nf_wrap_stubs.o: nf_wrap_stubs.F90 kinds_mod.o
sphere_area_mod.o: sphere_area_mod.F90 kinds_mod.o constants.o
nf_wrap.o: nf_wrap.F90 kinds_mod.o msg_mod.o nf_wrap_stubs.o
POP_grid_mod.o: POP_grid_mod.F90 kinds_mod.o constants.o nf_wrap.o sphere_area_mod.o
zonal_avg_mod.o: zonal_avg_mod.F90 kinds_mod.o constants.o nf_wrap.o POP_grid_mod.o sphere_area_mod.o
main.o: main.F90 kinds_mod.o constants.o msg_mod.o arg_wrap.o sphere_area_mod.o POP_grid_mod.o zonal_avg_mod.o

clean:
	rm -f *.o *.mod *.l *.lis *.lst
