# game-demo
基于skynet的游戏小demo

# build
确保skynet框架能运行
```
git clone https://github.com/cloudwu/skynet.git
cd skynet
make 'PLATFORM'  # PLATFORM can be linux, macosx, freebsd now

./skynet examples/config	# Launch first skynet node  (Gate server) and a skynet-master (see config for standalone option)
./3rd/lua/lua examples/client.lua 	# Launch a client, and try to input hello.
```
将本工程放到skynet目录下
```
./skynet game-demo/config	# Launch first skynet node  (Gate server) and a skynet-master (see config for standalone option)
./3rd/lua/lua game-demo/client.lua 	# Launch a client, and try to input hello.
```
其实可以放到任意目录，只要修改config里的路径就可以了
