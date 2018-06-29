COSBench - Cloud Object Storage Benchmark
=========================================

COSBench is a benchmarking tool to measure the performance of Cloud Object Storage services. Object storage is an 
emerging technology that is different from traditional file systems (e.g., NFS) or block device systems (e.g., iSCSI).
Amazon S3 and Openstack* swift are well-known object storage solutions.

COSBench now supports OpenStack* Swift and Amplidata v2.3, 2.5 and 3.1, as well as custom adaptors.


## Installation
1\. Download cosbench zip package from git
2\. Add 6 drivers to start-all.sh, and add 6 driver sh
```
bash start-driver1.sh
bash start-driver2.sh
bash start-driver3.sh
bash start-driver4.sh
bash start-driver5.sh
bash start-driver6.sh
```
3\. Add 6 drivers conf to conf\controller.conf
```
[controller]
drivers = 6
log_level = INFO
log_file = log/system.log
archive_dir = archive

[driver1]
name = driver1
url = http://127.0.0.1:28100/driver

[driver2]
name = driver2
url = http://127.0.0.1:28200/driver

[driver3]
name = driver3
url = http://127.0.0.1:28300/driver

[driver4]
name = driver4
url = http://127.0.0.1:28400/driver

[driver5]
name = driver5
url = http://127.0.0.1:28500/driver


[driver6]
name = driver6
url = http://127.0.0.1:28600/driver
```
4\. Disable S3 MD5 validate check in cosbench-start.sh with "-Dcom.amazonaws.services.s3.disableGetObjectMD5Validation=true",
this is to avoid high failure raito for read operation
```
/usr/bin/nohup java -Dcosbench.tomcat.config=$TOMCAT_CONFIG -Dcom.amazonaws.services.s3.disableGetObjectMD5Validation=true
```

5\. Notice don't user 127.0.0.1 for read/write test

6\. for ssd, check if osd restart is needed before test

## User Guide
1\. Write config xml file in s3testcase or swifttestcase follow the example
2\. Submit one test
```
sh cli.sh submit s3testcase/s3write4k.xml 
``` 
3\. Cancel one test
```
sh cli.sh cancel w1 //w1 is the work id created by submit operation
```
4\. Check the report in the web
http://<ip>:19088/controller/