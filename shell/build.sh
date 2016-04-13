version=$1
spmcv=$2
apps="crmat rmat cwordfreq wordfreq"
ROOT=$PWD
if [ $version = "mpich" ]; then
	cd $ROOT/src
	make clean-mpich2 && make mpich2
	cd $ROOT/examples
	rm *.o && make -f Makefile.mpich2
	
	for app in $apps; do
		mv mpich2-$app $version-$app$spmcv	
	done
fi

if [ $version = "detmp" ]; then
	cd $ROOT/src
	make clean-dlinux && make dlinux
	cd $ROOT/examples
	rm *.o && make -f Makefile.dlinux 
	
	for app in $apps; do
		mv dlinux-${app} $version-$app$spmcv 	
	done
fi
	
	
	
