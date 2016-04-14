#!/bin/sh
# Author: Yu (Clara) Zhang at USTC

TARGET=$1
NPBDIR="$PWD"
HOME=$NPBDIR/../../../bin/npb/$TARGET #$HOME/super/bin/npb
BINDIR=$NPBDIR/bin/dlinux
app=$2
class=$3
spmcv=$4

mkdir -p $HOME

echo "Install $1.$2.* from $BINDIR to $PIOS_HOME"
echo "$# parameters";

if [ $# -eq 5 ]; then
	cp $BINDIR/$1.$2.$3 ${HOME}/$1$2$3; #TODO 
elif [ $# -eq 4 ]; then

case $app in
dt )
	cp $BINDIR/$app.$class.x ${HOME}/$app$class$spmcv
	;;
sp | bt)
	for nthrds in 1 4 9 16 25 49
	do
		cp  $BINDIR/$app.$class.$nthrds ${HOME}/$app$class$nthrds$spmcv;
	done
	;;
*)
	for nthrds in 1 2 4 8 16 32 64
	do
		cp $BINDIR/$app.$class.$nthrds ${HOME}/$app$class$nthrds$spmcv;
	done
esac

else
	echo "The parameters are not correct";
fi
#case $1 in
#	ft)	ln -sf ../../npb/NPB3.3-MPI/FT/input$1.data.sample ${PIOS_HOME}/fs/input$1.data;;
#esac
