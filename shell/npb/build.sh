#!/bin/sh
# Author: Yu (Clara) Zhang at USTC

# Optional target machines:
#   pios64 - building NPB-MPI for PIOS64-SPMC 
#   pios32 - building NPB-MPI for PIOS32-SPMC
#   mpich32 - building NPB-MPI for Linux+MPICH2-32
#   mpich64 - building NPB-MPI for Linux+MPICH2-64
#   dlinux - building NPB-MPI for Linux+DetMPI
TARGET=$1
app=$2
class=$3

if [ ! -d bin/$TARGET ];then
	mkdir -p bin/$TARGET
fi
cp config/make.$TARGET config/make.def

case $app in
dt)
	make clean;make $app CLASS=$class;
	;;
ft | mg | lu | is | ep | cg)
	for nthreads in 1 2 4 8 16 32 64
	do
		make clean;make $app NPROCS=$nthreads CLASS=$class;
	done
	;;
bt | sp)
	for nthreads in 1 4 9 16 25 49 
	do 
		make clean;make $app NPROCS=$nthreads CLASS=$class
	done
	;;
*)
	make clean;make dt CLASS=$class;
	for app in ft mg lu is ep cg;
	do
	for nthreads in 1 2 4 8 16 32 64
	do
		make clean;make $app NPROCS=$nthreads CLASS=$class;
	done
	done

	for app in bt sp;
	do
	for nthreads in 1 4 9 16 25 49
	do 
		make clean;make $app NPROCS=$nthreads CLASS=$class
	done
	done
	;;
esac
