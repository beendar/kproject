cd ./bin
bin -b ./boot_node.lua -p {[1]=math.randomseed(os.time()),type='client',iport=math.random(30000,50000)}