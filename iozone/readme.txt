
# Modified            Date           Comments
# Li Gang             2017-08-25     modify usage
# Li Gang             2017-08-23     modify usage
# Li Gang             2017-08-17     modify usage of shell script
# Li Gang             2017-06-28     last update 


1.配置好测试机之间的ssh无密访问(客户端到各个测试机主机都需要建立无密访问)
2.配置好主机名
3.所有测试机器均挂载同一导出目录到同一位置
4.按需求执行iozone_cluster.sh

5. 如果想一次测试所有定义好的iozone 测试场景，编辑alliozone.sh,修改
测试目录和主机名，如下:
#集群测试
./iozone_cluster.sh WooStor 32G 256KB "0 1" 8 /mnt/yfs/iozone_test "192.168.11.80 192.168.11.81 192.168.11.79"
#单节点测试
./iozone_cluster.sh YeeOS 32G 64KB "0 1" 16 /mnt/yfs/iozone_test "192.168.11.80"

参数说明:
第1个参数是产品类型的缩写，目前只支持 YeeStor,YeeSAN, YeeFS, WooStor,YeeOS五种类型;
第2个参数: 生成的文件总大小，根据线程数的不同，单个文件的大小也不同;
第3个参数: 文件的io粒度;
第4个参数: iozone的io测试类型,0为顺序写(创建文件),1为顺序读;
第5个参数: 线程数，建议设置成线性增长的数值，例如1,2,4,8,16,32,64等;

第6个参数: AP的挂载目录,每台测试主机都必须使用相同的挂载目录;
第7个参数:
如果运行集群测试, 指定3个主机的ip,用空格分隔,运行集群测试时需要一次输入全部主机的ip;
如果运行单机测试, 输入测试主机的ip。


最新脚本运行说明: add on 2017-08-23
为了保证测试数据集大小的精确性，修改了测试脚本，确保在不同的线程数环境下，生成的
测试文件总大小都是一致的。例如，测试集大小为96G

单线程: 生成1个96G大小的文件
2线程:  生成2个48G大小的文件
4线程:  生成4个24G大小的文件
8线程:  生成8个12G大小的文件
16线程: 生成16个6G大小的文件
32线程: 生成32个3G大小的文件
64线程: 生成64个1.5G大小的文件
128线程: 只适用于单机模式，生成128个0.75G大小的文件

注意:
1) 如果运行在集群模式，会在AP的挂载目录下每个主机(以ip命名)的子目录下生成
thread1,thread2等开头的最底层目录, 最终的测试文件生成在这些目录;

2) 如果运行在单机模式，会在AP的挂载目录下指定的单个主机(以ip命名)的子目录下 生成测试文件。


6. 为了方便 测试结果的收集，新增脚本get_result.sh
Usage: get_result.sh [file_prefix] [xfersize] [client_num]
Example: get_result.sh 64k_seq_3client 64k 3

参数说明:
file_prefix: 测试结果文件的前缀，建议设置成 通俗易懂的名字,
例如:
64k_seq_3client,表示 3客户端 64k粒度的顺序读写
4k_rand_3client,表示 1客户端 4k粒度的随机读写

xfersize: I/O粒度,脚本根据这个输入值去匹配符合条件的日志目录,
再对日志文件中的关键字进行过滤

client_num: 客户端个数，脚本根据这个输入值 去匹配符合条件的日志目录


测试结果输出内容如下:
[root@host16136 ssh_iozone_cluster]# vim 4k_rand_rw_3client.log

Test scenario: cluster_iozone_th1_4KB_3client
Random read/write values:(kbs} 20680.13/38993.73
---------------------------------------------------------------------------
Test scenario: cluster_iozone_th16_4KB_3client
Random read/write values:(kbs} 361487.86/304645.91
---------------------------------------------------------------------------
Test scenario: cluster_iozone_th32_4KB_3client
Random read/write values:(kbs} 645206.92/314622.21
---------------------------------------------------------------------------
Test scenario: cluster_iozone_th4_4KB_3client
Random read/write values:(kbs} 111570.54/141448.78
---------------------------------------------------------------------------
Test scenario: cluster_iozone_th64_4KB_3client
Random read/write values:(kbs} 907906.23/267607.01
---------------------------------------------------------------------------
Test scenario: cluster_iozone_th8_4KB_3client
Random read/write values:(kbs} 216465.39/231886.83
---------------------------------------------------------------------------
