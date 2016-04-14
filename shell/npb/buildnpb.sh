ROOT=$HOME/super
GITDIR=$ROOT/git
LIBDIR=$GITDIR/dlinux/src/lib
DLINUX_LIB_DIR=$ROOT/lib
NPBDIR=$GITDIR/npb/NPB3.3-MPI
INSTDIR=$ROOT/bin/npb

function process_args {
	# Default configuration to use
	default_spmc='eager.b.nwr.ncores=64'
	default_apps=(is mg cg ep ft lu sp bt)
	
	#Usage
  usage="\

Usage: $me [OPTION]...

Manage the compilation of various versions of the MRMPI benchmark suite.

Options:
    -v VERSION   Which version to be built.
    -spmc SPMCVER Which SPMC version to be linked.
    -h           Displays this help message.

VERSION:
    mpich64:    	 Depends on libmpi.a
    dlinux:       Depends on libspmc.a, libmpi.a

Examples:
    - Build the complete test suite:
        $me
    - Build all apps only using specified configuration:  
        $me -v mpich64 
      The type of versions include: mpich64, dlinux
    - Build specified application only using specified configuration:  
        $me -v dlinux -spmc eager.b.nwr 
	 Note: MPI benchmarks can't use:
		eager.nb.wr2.ncores=64
		eager.b.wr2.ncores=64
		eager.nb.wr1.ncores=64
		eager.b.wr1.ncores=64
		eager.nb.nwr.ncores=64
		eager.b.nwr.ncores=64 
"
	# Define valid versions
	valid_versions="mpich64 dlinux"
	valid_spmcs="eager.nb.wr2.ncores=64 eager.b.wr2.ncores=64 eager.nb.wr1.ncores=64 eager.b.wr1.ncores=64 eager.nb.nwr.ncores=64 eager.b.nwr.ncores=64"
	valid_apps="is mg cg ep ft lu sp bt"
	
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
				parsemode="APP"
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
        if [ ${arg:0:1} == "-" ]; then
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
					"APP" )
						parsemode="node"
						is_valid=""
						for valid_app in $valid_apps; do
							if [ "$arg" = "$valid_app" ]; then
								is_valid="TRUE"
							fi
						done
						if [ -z "$is_valiad" ]; then
							echo "Error: Unknown app '$srg'."
							echo "$usage"
							exit 1
						fi
						i=0;
						for app in $default_apps; do
							if [ "$arg" = "$app" ]; then
								break
							fi
							let i++
						done
						apps=($arg);;
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
          * )
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
	
	if [ ! -z "$apps" ]; then
		apps=(${default_apps[*]})
	fi

  if [ -z "$spmc" ]; then
    spmc=$default_spmc
  fi
  if [ ! -z "$version" ]; then
    i=0
    nver=${#versions[@]}
    while [ $i -lt $nver ]; do
      if [ "$version" = "${versions[$i]}" ]; then
        break;
      fi
      let i++
    done
    versions=($version)
  fi
}

# $1:version
function build_version {
	# Applications
	napp=${#apps[@]} # number of applications
	j=0
	version="$1"
	#Get SPMC library
	if [ $version = "dlinux" ]; then
		spmcfile=${DLINUX_LIB_DIR}/libspmc.a.$spmc
		mpifile=${DLINUX_LIB_DIR}/libmpi.a.$spmc
		echo "spmcfile: $spmcfile\n"
		if [[ ! -f "$spmcfile" || ! -f "$mpifile" ]]; then
      echo "Error: Cannot find spmc library '$spmcfile'."
      echo "Build $spmcfile"
      exit 1
    fi
    echo "ln -sf $spmcfile $LIBDIR/libspmc.a"
    ln -sf $spmcfile $LIBDIR/libspmc.a
    echo "ln -sf $mpifile $LIBDIR/libmpi.a"
		ln -sf $mpifile $LIBDIR/libmpi.a
    spmcv=".$spmc"
	else
		spmcv=""
	fi
	
	while [ $j -lt $napp ]
	do
		app=${apps[$j]}
		$NPBDIR/build.sh $version $app A						#build
		$NPBDIR/install.sh $version $app A $spmcv		#install
	done
}

####################################
#                                  #
#               MAIN               #
#                                  #
####################################
# Determine script name
BASENAME="basename"
eval me=$(${BASENAME} $0)
# Setup environment
process_args "$@"

# Build all versions
nver=${#versions[@]} # number of versions


#echo on
echo "ROOT: $ROOT"
echo "Install directory: $INSTDIR"
mkdir -p $INSTDIR
echo "Build $nver versions ..."
cd $NPBDIR
i=0
while [ $i -lt $nver ] 
do
  echo "Build $i:${versions[$i]}..."
  build_version ${versions[$i]}
  let i++
done



