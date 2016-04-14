ROOT=$HOME/super
GITDIR=$ROOT/git
BINDIR=$ROOT/bin/npb
RESDIR=$ROOT/results/npb

#type in (mpich64 dlinux)
type=$1
#app in (is mg cg ep ft lu sp bt)
app=$2
#spmc in (eager.nb.wr2.ncores=64 eager.b.wr2.ncores=64 eager.nb.wr1.ncores=64 eager.b.wr1.ncores=64 eager.nb.nwr.ncores=64 eager.b.nwr.ncores=64)
class=$3
spmc=$4


echo "$type $app"


############################################
#                                          #
# Main                                     #
#                                          # 
############################################

res="$RESDIR/$type"
if [ -z "$spmc" ]; then
	spmc="eager.nb.wr2.ncores=64"
fi

if [ -z "$class" ]; then
	class="A"
fi

mkdir -p $res
thread_nums="1 2 4 8 16 32 64"
for nthreads in $thread_nums; do
	case "$type" in
		"mpich" )
			mpiexec="/opt/mpich-3.1.1/bin/mpiexec"
			spmcv=""
			;;
		"dlinux" )
			mpiexec="$GITDIR/dlinux/src/bin/mpiexec"	
			spmcv=".$spmc"
			;;
	esac
	input=$BINDIR/$type/$app$nthreads$class$spmcv	
	output=$res/$app$nthreads-$class$spmcv

	cmd="$mpiexec -n ${nthreads} $input 2>&1 >> $output" 

	for n in `seq 10`; do
		$cmd
	done
done



