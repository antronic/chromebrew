#chromebrew directories
OWNER="skycocker"
REPO="chromebrew"
BRANCH="master"
URL="https://raw.githubusercontent.com/$OWNER/$REPO/$BRANCH"
CREW_PREFIX=/usr/local
CREW_LIB_PATH=$CREW_PREFIX/lib/crew/
CREW_CONFIG_PATH=$CREW_PREFIX/etc/crew/
CREW_BREW_DIR=$CREW_PREFIX/tmp/crew/
CREW_DEST_DIR=$CREW_BREW_DIR/dest
CREW_PACKAGES_PATH=$CREW_LIB_PATH/packages

architecture=$(uname -m)

case "$architecture" in
"i686"|"x86_64"|"armv7l"|"aarch64")
  ;;
*)
  echo 'Your device is not supported by Chromebrew yet.'
  exit 1;;
esac

#This will allow things to work without sudo
sudo chown -R `id -u`:`id -g` /usr/local

#prepare directories
for dir in $CREW_LIB_PATH $CREW_CONFIG_PATH $CREW_CONFIG_PATH/meta $CREW_BREW_DIR $CREW_DEST_DIR $CREW_PACKAGES_PATH; do
  mkdir -p $dir
done

#prepare url and sha256
#  install only ruby, git and libssh2
urls=()
sha256s=()
case "$architecture" in
"aarch64")
  urls+=('https://github.com/jam7/chrome-cross/releases/download/v1.8/ruby-2.4.1-chromeos-armv7l.tar.xz')
  sha256s+=('6c0ef23447d4591739dc00fa9b021a4d83291acbc37330e659d257efed474caf')
  urls+=('https://github.com/jam7/chrome-cross/releases/download/v1.8/git-2.13.0-chromeos-armv7l.tar.xz')
  sha256s+=('d66cedbf908e39275db149407fe631f497ee82bf3ae3ea433b1e8c31c40a6c25')
  urls+=('https://github.com/jam7/chrome-cross/releases/download/v1.8/libssh2-1.8.0-chromeos-armv7l.tar.xz')
  sha256s+=('94662756e545c73d76c37b2b83dd9852ebe71f4a17fc80d85db0fbaef72d4ca3')
  ;;
"armv7l")
  urls+=('https://github.com/jam7/chrome-cross/releases/download/v1.8/ruby-2.4.1-chromeos-armv7l.tar.xz')
  sha256s+=('6c0ef23447d4591739dc00fa9b021a4d83291acbc37330e659d257efed474caf')
  urls+=('https://github.com/jam7/chrome-cross/releases/download/v1.8/git-2.13.0-chromeos-armv7l.tar.xz')
  sha256s+=('d66cedbf908e39275db149407fe631f497ee82bf3ae3ea433b1e8c31c40a6c25')
  urls+=('https://github.com/jam7/chrome-cross/releases/download/v1.8/libssh2-1.8.0-chromeos-armv7l.tar.xz')
  sha256s+=('94662756e545c73d76c37b2b83dd9852ebe71f4a17fc80d85db0fbaef72d4ca3')
  ;;
"i686")
  urls+=('https://github.com/jam7/chrome-cross/releases/download/v1.8/ruby-2.4.1-chromeos-i686.tar.xz')
  sha256s+=('851a40ca3860eadfe21a1b77422f8769497a73fd1f275d370e3874948ddb64bd')
  urls+=('https://github.com/jam7/chrome-cross/releases/download/v1.8/git-2.13.0-chromeos-i686.tar.xz')
  sha256s+=('922142616e26a25551a206e1681c20c23da43eb7b83a63cfafca9297f260f987')
  urls+=('https://github.com/jam7/chrome-cross/releases/download/v1.8/libssh2-1.8.0-chromeos-i686.tar.xz')
  sha256s+=('7d6086f80abd3905a82bd34ffd2b811658c1eaf9ac0e63ad73df39d4ce7c3d9d')
  ;;
"x86_64")
  urls+=('https://github.com/jam7/chrome-cross/releases/download/v1.8/ruby-2.4.1-chromeos-x86_64.tar.xz')
  sha256s+=('fb15f0d6b8d02acf525ae5efe59fc7b9bc19908123c47d39559bc6e86fe1d655')
  urls+=('https://github.com/jam7/chrome-cross/releases/download/v1.8/git-2.13.0-chromeos-x86_64.tar.xz')
  sha256s+=('0f9d9b57a5f2bfd5e20cc2dcf4682993734d40f4db3879e60ea57e7b0fb23989')
  urls+=('https://github.com/jam7/chrome-cross/releases/download/v1.8/libssh2-1.8.0-chromeos-x86_64.tar.xz')
  sha256s+=('a5ebeb68c8e04e6587621a09cc43d0a3d7baf0cdb4dd945fd22253a6e0a11846')
  ;;
esac

#functions to maintain packages
function download_check () {
    cd $CREW_BREW_DIR

    #download
    echo "Downloading $1..."
    wget -c $2 -O $3

    #verify
    echo "Verifying $1..."
    echo $4 $3 | sha256sum -c -
    case $? in
    0) ;;
    *)
      echo "Verification failed, something may be wrong with the $1 download."
      exit 1;;
    esac
}

function extract_install () {
    cd $CREW_BREW_DIR

    #extract and install
    echo "Extracting $1 (this may take a while)..."
    rm -rf ./usr
    tar -xf $2
    echo "Installing $1 (this may take a while)..."
    tar cf - ./usr/* | (cd /; tar xp --keep-directory-symlink -f -)
    mv ./dlist $CREW_CONFIG_PATH/meta/$1.directorylist
    mv ./filelist $CREW_CONFIG_PATH/meta/$1.filelist
}

function update_device_json () {
  cd $CREW_CONFIG_PATH

  if grep '"name": "'$1'"' device.json > /dev/null; then
    echo "Updating version number of existing $1 information in device.json..."
    sed -i device.json -e '/"name": "'$1'"/N;//s/"version": ".*"/"version": "'$2'"/'
  elif grep '^    }$' device.json > /dev/null; then
    echo "Adding new $1 information to device.json..."
    sed -i device.json -e '/^    }$/s/$/,\
    {\
      "name": "'$1'",\
      "version": "'$2'"\
    }/'
  else
    echo "Adding new $1 information to device.json..."
    sed -i device.json -e '/^  "installed_packages": \[$/s/$/\
    {\
      "name": "'$1'",\
      "version": "'$2'"\
    }/'
  fi
}

#create the device.json file if it doesn't exist
cd $CREW_CONFIG_PATH
if [ ! -f device.json ]; then
  echo "Creating new device.json..."
  echo '{' > device.json
  echo '  "architecture": "'$architecture'",' >> device.json
  echo '  "installed_packages": [' >> device.json
  echo '  ]' >> device.json
  echo '}' >> device.json
fi

#extract, install and register packages
for i in `seq 0 $((${#urls[@]} - 1))`; do
  url=${urls[$i]}
  sha256=${sha256s[$i]}
  tarfile=`basename $url`
  name=${tarfile%%-*}   # extract string before first '-'
  rest=${tarfile#*-}    # extract string after first '-'
  version=`echo $rest | sed -e 's/-chromeos.*$//'`
                        # extract string between first '-' and "-chromeos"

  download_check $name $url $tarfile $sha256
  extract_install $name $tarfile
  update_device_json $name $version
done

#download, prepare and install chromebrew
cd $CREW_LIB_PATH
rm -rf crew lib packages
wget -N $URL/crew
chmod +x crew
rm -f $CREW_PREFIX/bin/crew
ln -s `pwd`/crew $CREW_PREFIX/bin
#install crew library
mkdir -p $CREW_LIB_PATH/lib
cd $CREW_LIB_PATH/lib
wget -N $URL/lib/package.rb
wget -N $URL/lib/package_helpers.rb

#Making GCC act like CC (For some npm packages out there)
rm -f /usr/local/bin/cc
ln -s /usr/local/bin/gcc /usr/local/bin/cc

#prepare sparse checkout .rb packages directory and do it
cd $CREW_LIB_PATH
rm -rf .git
git init
git remote add -f origin https://github.com/$OWNER/$REPO.git
git config core.sparsecheckout true
echo packages >> .git/info/sparse-checkout
echo lib >> .git/info/sparse-checkout
echo crew >> .git/info/sparse-checkout
git fetch origin master
git reset --hard origin/master
echo "Chromebrew installed successfully and package lists updated."
