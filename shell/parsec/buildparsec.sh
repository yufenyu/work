#!/bin/sh
# Script to build various versions of dedup, ferret in PARSEC
#
# Primary author: Yu Zhang (clarazhang@gmail.com)
#

ROOT=$HOME
GITDIR=$ROOT/git/
PARSECDIR=$GITDIR/parsec
INSTDIR=$PWD/bin
PLAT=amd64-linux

function process_args {
  # Default configuration to use
  default_vfile=versions.txt
  default_spmc=eager.b.nwr
  default_apps=(dedup ferret)
  default_appdirs=(kernels apps)

  # Usage
  usage="\

Usage: $me [OPTION]...

Manage the compilation of various versions of the PARSEC benchmark suite.

Options:
    -f FILE      A file which includes all versions to be built.	
                 Default: versions.txt.
    -p APP       Which application to be built.
    -v VERSION   Which version to be built.
    -spmc SPMCVER Which SPMC version to be linked.
    -h           Displays this help message.

VERSION:
    pthreads:    Depends on libpthread.so
    pthreads-jemalloc: Depends on libjemalloc.so
    dthreads:    Depends on libdthread.so
    detmp:       Depends on libspmc.a
    detmp-pthreads: Depends on libspmcpthread.a
    tbb-funcobj: Depends on libtbb.so and libpthread.so
    dstream:     Depends on libspmc.a

    Note: You should set DLINUX_LIB_DIR in your environment
          by modifying ~/.bashrc or /etc/profile.
          The value of DLINUX_LIB_DIR should be the directory
          to store required static libraries.
          For dynamic libraries, you may set LD_LIBRARY_DIR
          to specify where to locate them.

Examples:
    - Build the complete test suite:
        $me
    - Build dedup and ferret only using specified configuration:  
        $me -v detmp
      The type of versions include: 
    - Build specified application only using specified configuration:  
        $me -v detmp -p ferret
      Note: there are two versions of detmp ferret, ferret-detmp and
            ferret-detmp-pack, and the latter packs the middle 4 
            pipeline stages into one stage.
"

  # Define valid versions
  valid_versions="pthreads pthreads-jemalloc dthreads detmp detmp-pthreads dstream tbb-funcobj pthreads-partition pthreads-partition1 pthreads-partition-jemalloc pthreads-partition1-jemalloc"
  valid_apps="dedup ferret"
  valid_spmcs="lazy.nb.wr2 eager.nb.wr2 lazy.b.wr2 eager.b.wr2 lazy.nb.wr1 eager.nb.wr1 lazy.b.wr1 eager.b.wr1 lazy.nb.nwr eager.nb.nwr lazy.b.nwr eager.b.nwr"

  # Parse arguments
  need_arg=""
  parsemode="none"
  version=""
  spmc=""
  apps=""
  vfile=""
  while [ ! -z "$1" ]; do # there is argument
    arg="$1"
    case "${arg}" in
      "-f" )
        if [ ! -z "${need_arg}" ]; then
          echo "Error: ${parsemode} expected between '${need_arg}' and '-f'"
          echo "$usage"
          exit 1
        fi
        need_arg="-f"
        parsemode="FILE";;
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
        if [ ${arg:0:1} == "-" ]; then
          echo "Error: Unknown argument '$arg'"
          echo "$usage"
          exit 1
        fi
        need_arg=""
        case "$parsemode" in 
          "FILE"    )
            parsemode="none"
            if [ ! -f "$arg" ]; then
              echo "Error: Cannot find versions configuration file '$arg'."
              exit 1
            fi
            vfile="$arg";;
          "VERSION" )
            parsemode="none"
            is_valid=""
            for valid_version in $valid_versions; do
              if [ "$arg" == "$valid_version" ]; then
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
              if [ "$arg" == "$valid_spmc" ]; then
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
        esac;;
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
  if [ -z "$vfile" ]; then
    vfile=$default_vfile
    if [ ! -f "$vfile" ]; then
      echo "Error: Cannot find versions configuration file '$vfile'."
      exit 1
    fi
  fi
  versions=(`awk '{print $1}' $vfile`)
  bldconfs=(`awk '{print $2}' $vfile`)
  branches=(`awk '{print $3}' $vfile`)
  commits=(`awk '{print $4}' $vfile`)
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
  napp=${#apps[@]} # number of applications
  j=0
  version="$1"
  bldconf="$2"
  branch="$3"
  commit="$4"

  # Get SPMC library
  if [[ $version == detmp* ]]; then
    spmcfile=$DLINUX_LIB_DIR/libspmc.a.$spmc
    if [ ! -f "$spmcfile" ]; then
      echo "Error: Cannot find spmc library '$spmcfile'."
      echo "Build $spmcfile"
      exit 1
    fi
    echo "ln -sf libspmc.a.$spmc $DLINUX_LIB_DIR/libspmc.a"
    ln -sf libspmc.a.$spmc $DLINUX_LIB_DIR/libspmc.a
    spmcv=".$spmc"
  else
    spmcv=""
  fi
  echo "git checkout $branch"
  git checkout $branch
  echo "git pull -f"
  git pull -f 
#  git reset --hard $commit
  curcommit=`cat $PARSECDIR/.git/refs/heads/$branch`
  echo "$curcommit $commit"
  if [[ "${curcommit:0:6}" != "${commit:0:6}" ]]; then
    echo "git checkout $commit ."
    git checkout $commit .
  fi
  while [ $j -lt $napp ]
  do
    app=${apps[$j]}
    appdir=${appdirs[$j]}
    if [ $version == *partition* ] && [ "$app" == "ferret" ]; then
      continue
    fi 
echo "build $j: $app $bldconf ..."
    $PARSECDIR/bin/parsecmgmt -a uninstall -c gcc-$bldconf -p $app
    $PARSECDIR/bin/parsecmgmt -a build -c gcc-$bldconf -p $app
    cp $PARSECDIR/pkgs/$appdir/$app/inst/$PLAT.gcc-$bldconf/bin/$app $INSTDIR/$app-$version$spmcv
    if [ "$app" == "ferret" ] &&  [[ $version == detmp* ]]; then
      $PARSECDIR/bin/parsecmgmt -a build -c gcc-$bldconf-pack -p $app
      cp $PARSECDIR/pkgs/$appdir/$app/inst/$PLAT.gcc-$bldconf-pack/bin/$app $INSTDIR/$app-$version-pack$spmcv
    fi
    let j++
  done
  if [[ "${curcommit:0:6}" != "${commit:0:6}" ]]; then
    git reset --hard;
  fi
  echo off
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
echo "Install directory: $INSTDIR"
mkdir -p $INSTDIR
echo "Build $nver versions ..."
cd $PARSECDIR
i=0
while [ $i -lt $nver ] 
do
  echo "Build $i:${versions[$i]}, gcc-${bldconfs[$i]} ${branches[$i]}(${commits[$i]}) ..."
  build_version ${versions[$i]} ${bldconfs[$i]} ${branches[$i]} ${commits[$i]}
  let i++
done
