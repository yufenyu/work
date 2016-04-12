SCRIPTHOME="`pwd`"
ROOT="$SCRIPTHOME/../.."
GITDIR=$ROOT/git
DLINUXDIR=$GITDIR/dlinux
MRMPIDIR=$GITDIR/mapreduce/MR-MPI/mrmpi-11Mar13
BINDIR=$ROOT/bin/
type=$1

function process_args {
	# Default configuration to use
	default_vfile=versions.txt
	default_spmc=eager.b.nwr
	default_apps=(crmat rmat wordfreq cwordfreq)
	
	#Usage
  usage="\

Usage: $me [OPTION]...

Manage the compilation of various versions of the MRMPI benchmark suite.

Options:
    -p APP       Which application to be built.
    -v VERSION   Which version to be built.
    -spmc SPMCVER Which SPMC version to be linked.
    -h           Displays this help message.

VERSION:
    mpich:    	 Depends on libmpi.a
    detmp:       Depends on libspmc.a, libmpi.a

    Note: You should set DLINUX_LIB_DIR in your environment
          by modifying ~/.bashrc or /etc/profile.
          The value of DLINUX_LIB_DIR should be the directory
          to store required static libraries.
          For dynamic libraries, you may set LD_LIBRARY_DIR
          to specify where to locate them.

Examples:
    - Build the complete test suite:
        $me
    - Build all apps only using specified configuration:  
        $me -v detmp
      The type of versions include: mpich, detmp
    - Build specified application only using specified configuration:  
        $me -v detmp -p wordfreq 
	 Note: MPI benchmarks can't use lazy spmc version
"
	# Define valid versions
	valid_versions="mpich detmp"
	valid_apps="crmat rmat wordfreq cwordfreq"
	valid_spmcs="eager.nb.wr2.ncores=64 eager.b.wr2.ncores=64 eager.nb.wr1.ncores=64 eager.b.wr1.ncores=64 eager.nb.nwr.ncores=64 eager.b.nwr.ncores=64"
	
	# Parse arguments
	need_arg=""
  parsemode="none"
  version=""
  spmc=""
 	apps=""
	while [ ! -z "$1" ]; do #there is argument
		arg="$1"
		case "${arg}" in
			"-v" )
				if [ ! -z "${need_arg}" ]; then
        	echo "Error: ${parsemode} expected between '${need_arg}' and '-v'"
        	echo "$usage"
       		exit 1
        fi
				need_arg="-v"
        parsemode="VERSION";;
      "-p" )
        if [ ! -z "${need_arg}" ]; then
          echo "Error: ${parsemode} expected between '${need_arg}' and '-p'"
          echo "$usage"
          exit 1
        fi
        need_arg="-p"
        parsemode="APP";;
      "-spmc" )
        if [ ! -z "${need_arg}" ]; then
          echo "Error: ${parsemode} expected between '${need_arg}' and '-spmc'"
          echo "$usage"
          exit 1
        fi
        need_arg="-spmc"
        parsemode="SPMC";;
      "-h" )
        echo "$usage"
        exit 0;;
      *    )
        if [ ${arg:0:1} != "-" ]; then
          echo "Error: Unknown argument '$arg'"
          echo "$usage"
          exit 1
        fi
        need_arg=""
        case "$parsemode" in
          "VERSION" )
            parsemode="none"
            is_valid=""
            for valid_version in $valid_versions; do
              if [ "$arg" = "$valid_version" ]; then
                is_valid="TRUE"
                break
              fi
            done
            if [ -z "$is_valid" ]; then
              echo "Error: Unknown version '$arg'."
              echo "$usage"
              exit 1
            fi
            version="$arg";;
          "SPMC" )
            parsemode="none"
            is_valid=""
            for valid_spmc in $valid_spmcs; do
              if [ "$arg" = "$valid_spmc" ]; then
                is_valid="TRUE"
                break
              fi
            done
            if [ -z "$is_valid" ]; then
              echo "Error: Unknown SPMC version '$arg'."
              echo "$usage"
              exit 1
            fi
            spmc="$arg";;
          "APP"     )
            parsemode="none"
            is_valid=""
            for valid_app in $valid_apps; do
              if [ "$arg" == "$valid_app" ]; then
                is_valid="TRUE"
                break
              fi
            done
            if [ -z "$is_valid" ]; then
              echo "Error: Unknown app '$srg'."
              echo "$usage"
              exit 1
            fi
            i=0
            for app in $default_apps; do
              if [ "$arg" == "$app" ]; then
                break
              fi
              let i++
            done
            apps=($arg)
            appdirs=(${default_appdirs[$i]});;
          *         )
            echo "Error: Unknown argument '$arg'."
            echo "$usage"
            exit 1;;
				esac
		esac
		shift
	done
  if [ ! -z "$need_arg" ]; then
    echo "Error: $parsemode expected after '$need_arg'."
    echo "$usage"
    exit 1
  fi

  if [ -z "$apps" ]; then
    apps=(${default_apps[*]})
    appdirs=(${default_appdirs[*]})
  fi
  if [ -z "$spmc" ]; then
    spmc=$default_spmc
  fi
  if [ ! -z "$version" ]; then
    i=0
    nver=${#versions[@]}
    while [ $i -lt $nver ]; do
      if [ "$version" == "${versions[$i]}" ]; then
        break;
      fi
      let i++
    done
    versions=($version)
    bldconfs=(${bldconfs[$i]})
    branches=(${branches[$i]})
    commits=(${commits[$i]})
  fi
}

# $1:version, $2:bldconf, $3:branch, $4:commit
function build_version {
	# Applications
	napp={#apps[@]} #number of applications
}





valid_versions="eager.nb.wr2.ncores=64 eager.b.wr2.ncores=64 eager.nb.wr1.ncores=64 eager.b.wr1.ncores=64 eager.nb.nwr.ncores=64 eager.b.nwr.ncores=64"

for version in $valid_versions
do
	spmc=$ROOT/lib/libspmc.a.$version
	ln -sf $spmc $DLINUXDIR/src/lib/libspmc.a 

	mpi=$ROOT/lib/libmpi.a.$version
	ln -sf $mpi $DLINUXDIR/src/lib/libmpi.a 

	cd $MRMPIDIR/src
	make clean-dlinux && make dlinux
	cd $MRMPIDIR/examples
	rm *.o && make -f Makefile.dlinux
	mkdir -p $ROOT/bin/mrmpi/dlinux
	dlinux_benchs=`ls dlinux-*`
	for bench in $dlinux_benchs
	do
		cp $bench $ROOT/bin/mrmpi/dlinux/$bench.$version
	done
done

    cd $MRMPIDIR/src
    make clean-mpich2 && make mpich2
    cd $MRMPIDIR/examples
    rm *.o && make -f Makefile.mpich2
    mkdir -p $ROOT/bin/mrmpi/mpich
    mpich_benchs=`ls mpich2-*`
    for bench in $mpich_benchs
    do      
        cp $bench $ROOT/bin/mrmpi/mpich/$bench
    done 
