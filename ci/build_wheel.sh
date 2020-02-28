######################################################################
#    Install prerequisites, download toolchain and set the paths    #
#    ------------------------------------------------------------    #
######################################################################

apt install python3-dev libssl-dev libncurses5-dev libsqlite3-dev libreadline-dev libtk8.5 libgdm-dev libdb4o-cil-dev libpcap-dev wget sudo
mkdir -p $HOME/packages/toolchain
cd $HOME/packages/toolchain
wget https://developer.arm.com/-/media/Files/downloads/gnu-a/8.3-2019.03/binrel/gcc-arm-8.3-2019.03-x86_64-aarch64-linux-gnu.tar.xz
tar -xf gcc-arm-8.3-2019.03-x86_64-aarch64-linux-gnu.tar.xz
export PATH=$PATH:$HOME/packages/toolchain/gcc-arm-8.3-2019.03-x86_64-aarch64-linux-gnu/bin

######################################
#    Setup crossenv prerequisites    #
#    ----------------------------    #
######################################

#compile python for build machine
#--------------------------------
mkdir -p $HOME/packages/builds
cd $HOME/packages/builds
wget https://www.python.org/ftp/python/3.6.10/Python-3.6.10.tgz
tar xzf Python-3.6.10.tgz
mv Python-3.6.10 Python-3.6.10-build
cd Python-3.6.10-build
./configure
make -j32 python Parser/pgen
sudo make -j32 install
mkdir -p $HOME/packages/builds/python-build
cp python $HOME/packages/builds/python-build
cp Parser/pgen $HOME/packages/builds/python-build
cd ..

#Cross compile for aarch64
#-------------------------
tar xzf Python-3.6.10.tgz
mv Python-3.6.10 Python-3.6.10-host
cd Python-3.6.10-host

CC=aarch64-linux-gnu-gcc CXX=aarch64-linux-gnu-g++ AR=aarch64-linux-gnu-ar RANLIB=aarch64-linux-gnu-ranlib ./configure --host=aarch64-linux-gnu --target=aarch64-linux-gnu --build=x86_64-linux-gnu --prefix=$HOME/packages/builds/python-host --disable-ipv6 ac_cv_file__dev_ptmx=no ac_cv_file__dev_ptc=no ac_cv_have_long_long_format=yes --enable-shared

make -j32 HOSTPYTHON=$HOME/packages/builds/python-build/python HOSTPGEN=$HOME/packages/builds/python-build/pgen BLDSHARED="aarch64-linux-gnu-gcc -shared" CROSS-COMPILE=aarch64-linux-gnu- CROSS_COMPILE_TARGET=yes HOSTARCH=aarch64-linux-gnu BUILDARCH=aarch64-linux-gnu

mv /usr/bin/lsb_release /usr/bin/lsb_release_bkp
make -j32 install
mv /usr/bin/lsb_release_bkp /usr/bin/lsb_release
ln -s $HOME/packages/builds/python-host/bin/python3 $HOME/packages/builds/python-host/bin/python
cd ..


#########################
#    Building wheels    #
#    ---------------    #
#########################
#Follow the steps in crossenv

pip3 install crossenv
#/path/to/build-python3 -m crossenv /path/to/host-python3 venv
$HOME/packages/builds/python-build/python -m crossenv $HOME/packages/builds/python-host/bin/python venv
. venv/bin/activate
build-pip install cython
build-pip install numpy
build-pip install wheel
pip install cython
pip install numpy
pip install wheel
git clone https://github.com/pandas-dev/pandas
cd pandas/
python setup.py bdist_wheel
