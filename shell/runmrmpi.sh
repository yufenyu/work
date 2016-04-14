ROOT=$HOME/super
GITDIR=$ROOT/git
MRMPIDIR=$GITDIR/mapreduce/MR-MPI/mrmpi-11Mar13
BINDIR=$ROOT/bin/mrmpi
RESDIR=$ROOT/results/mrmpi
DATADIR=$ROOT/test/mrmpi

#type in (mpich dlinux)
type=$1
#app in (rmat crmat wordfreq cwordfreq)
app=$2
#data in (10 50 100)
data=$3
#spmcv in (eager.nb.wr2.ncores=64 eager.b.wr2.ncores=64 eager.nb.wr1.ncores=64 eager.b.wr1.ncores=64 eager.nb.nwr.ncores=64 eager.b.nwr.ncores=64)
spmc=$4

echo "$type $app $data"

######################################################
# Get arguments to run the specified application
# $1: app in (dedup ferret)   
# $2: dataset in (small large medium large)
# $3: number of threads in each parallel stage
# $4: output path 
######################################################
function get_run_args {
  local type=$1
  local app=$2
  local dataset=$3
	local nthreads=$4

  local input=$5
  local output=$6

	if [[ $app = "rmat" || $app = "crmat" ]]; then
		run_args="-n ${nthreads} $input 8 0.57 0.19 0.19 0.05 0.0 0.0 12345 >> $output"
	else
		run_args="-n ${nthreads} $input $dataset/*.txt >> $output"
	fi;
}


############################################
#                                          #
# Main                                     #
#                                          # 
############################################

res="$RESDIR/$type/$app$data"
dataset=$DATADIR/$data
if [ -z "$spmc" ]; then
	spmc="eager.nb.wr2.ncores=64"
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
	input=$BINDIR/$type-$app$spmcv	
	output=$res/$app-$nthreads$spmcv
	get_run_args $type $app $dataset $nthreads $input $output
	cmd="$mpiexec $run_args"

	for n in `seq 10`; do
		$cmd
	done
done



