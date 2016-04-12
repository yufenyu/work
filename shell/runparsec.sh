#
#  Script to test various versions of dedup, ferret from PARSEC
#
#  Primary author: Yu Zhang (clarazhang@gmail.com)
#
PARSECDIR=$HOME/test/benchmarks/parsec
BINDIR=bin
runmode=$1
#type in (detmp pthreads threads-jemalloc dthreads)
type=$2
app=$3
data=$4 #(hamlet small medium large)
ncpus=($5)
res=results/hotplug/$type
echo "$runmode $app $type $data (${ncpus[@]})"
#echo "$runmode $app $type $data ${ncpus[0]}"

#rm -rf $res
TIMEFORMAT=$'real %6R/tuser %6U/tsys %6S'

# import common functions for testing
source runcommon.sh

# import config file to run parsec programs
source parsecruncfg.sh

############################################
#                                          #
# Main                                     #
#                                          # 
############################################

if [ "$runmode" != "perfreport" ]; then
  # Disable all CPU cores
  disableCPUs

  # Set cpu_nums and thrd_nums of $app
  set_nthrds $app $type
fi

last=1
for ncpu in ${ncpus[*]}; do
  if [ "$runmode" != "perfreport" ]; then
    # Find corresponding number of threads
    locate_elem "${cpu_nums[*]}" "$ncpu";
    nt=${thrd_nums[$?]}

    # Enable CPU cores
    enableCPUs $last $ncpu
    last=$ncpu
    # Get $run_args
    get_run_args $app $type $data $nt $PWD
  fi

  case $runmode in 
    "perfrecord"   )
      nreps=1
      mkdir -p perf_res
      kptr=`cat /proc/sys/kernel/kptr_restrict`
      echo "/proc/sys/kernel/kptr_restrict is $kptr now"
      if [ "$kptr" == "1" ]; then
        echo "You shoud set it 0 in root mode"
        echo "$ su"
        echo "$ echo 0 > /proc/sys/kernel/kptr_restrict"
        exit 1
      fi
      cmd="perf record -g $BINDIR/$app-$type $run_args >perf_res/$app-$type-$data-$ncpu.record 2>&1 && mv perf.data perf_res/$app-$type-$data-$ncpu.data";;
    "perfstat"   )
      nreps=1
      mkdir -p perf_res
      kptr=`cat /proc/sys/kernel/kptr_restrict`
      echo "/proc/sys/kernel/kptr_restrict is $kptr now"
      if [ "$kptr" == "1" ]; then
        echo "You shoud set it 0 in root mode"
        echo "$ su"
        echo "$ echo 0 > /proc/sys/kernel/kptr_restrict"
        exit 1
      fi
      cmd="perf stat -d -r 3 -o perf_res/$app-$type-$data-$ncpu.stat $BINDIR/$app-$type $run_args >perf_res/$app-$type-$data-$ncpu.stat 2>&1";;
    "perfreport"   )
      nreps=1
      cmd="perf report -i perf_res/$app-$type-$data-$ncpu.data --stdio --sort dso -g flat 2>&1 | tee -a perf_res/$app-$type-$data-$ncpu.report";;
    "test"    )
      nreps=1
      mkdir -p $res
      resfile=$res/$app-$type-${data}.$ncpu
      touch $resfile
      echo 'dataset='${data}', ncpu='$ncpu', nt='$nt		
      echo 'dataset='${data}', ncpu='$ncpu', nt='$nt, $n >> $resfile
      cmd="(eval time $BINDIR/$app-$type $run_args 2>&1) 2>&1| tee -a $resfile";;
  esac

  for n in `seq $nreps`
  do
	echo $cmd
    echo $cmd|awk '{run=$0; system(run)}'
  done
done
