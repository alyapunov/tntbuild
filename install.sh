#!/bin/bash

pth=`pwd`

echo "#!/bin/bash" > ~/bin/tntbuild.sh

echo "" >> ~/bin/tntbuild.sh
echo "if [ ! -f '../CMakeLists.txt' ]; then" >> ~/bin/tntbuild.sh
echo "    echo 'Should be run from subfolder of tarantool!'" >> ~/bin/tntbuild.sh
echo "    exit 0" >> ~/bin/tntbuild.sh
echo "fi" >> ~/bin/tntbuild.sh

echo "" >> ~/bin/tntbuild.sh
echo "if ! grep -i 'project(tarantool' ../CMakeLists.txt > /dev/null; then" >> ~/bin/tntbuild.sh
echo "    echo 'Should be run from subfolder of tarantool!'" >> ~/bin/tntbuild.sh
echo "    exit 0" >> ~/bin/tntbuild.sh
echo "fi" >> ~/bin/tntbuild.sh

echo "" >> ~/bin/tntbuild.sh
echo "mkdir vshard" >> ~/bin/tntbuild.sh
echo "ln -s \"$pth/so\"" >> ~/bin/tntbuild.sh

echo "" >> ~/bin/tntbuild.sh
echo "ln -s \"$pth/test-run.sh\"" >> ~/bin/tntbuild.sh
echo "ln -s \"$pth/luatest_auto.sh\"" >> ~/bin/tntbuild.sh
echo "ln -s \"$pth/sorebuild.sh\"" >> ~/bin/tntbuild.sh
echo "ln -s \"$pth/cmake_options.txt\"" >> ~/bin/tntbuild.sh
echo "ln -s \"$pth/install_symlinks.sh\"" >> ~/bin/tntbuild.sh

echo "ln -s \"$pth/sub.sh\"" >> ~/bin/tntbuild.sh
echo "ln -s \"$pth/patch-test-run.sh\"" >> ~/bin/tntbuild.sh
echo "ln -s \"$pth/test-run.patch\"" >> ~/bin/tntbuild.sh
echo "ln -s \"$pth/luatest.patch\"" >> ~/bin/tntbuild.sh

echo "" >> ~/bin/tntbuild.sh
echo "ln -s \"$pth/my.lua\"" >> ~/bin/tntbuild.sh
echo "ln -s \"$pth/test_run.lua\"" >> ~/bin/tntbuild.sh
echo "ln -s \"$pth/txn_proxy.lua\"" >> ~/bin/tntbuild.sh
echo "ln -s \"$pth/luatest.lua\"" >> ~/bin/tntbuild.sh
echo "ln -s \"$pth/run.lua\"" >> ~/bin/tntbuild.sh
echo "ln -s \"$pth/reprun.lua\"" >> ~/bin/tntbuild.sh
echo "ln -s \"$pth/rep.lua\"" >> ~/bin/tntbuild.sh

echo "" >> ~/bin/tntbuild.sh
echo "echo \"Also it could be a good idea to run 'install_symlinks.sh':\"" >> ~/bin/tntbuild.sh

chmod 755 ~/bin/tntbuild.sh
