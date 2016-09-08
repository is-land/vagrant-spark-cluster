# Apache Spark standalone cluster

### Summary

VirtualBox + Vagrant + Ansible

自動化建立 Apache Spark standalone cluster

### 必須安裝的工具

* VirtualBox: https://www.virtualbox.org/
    * 支援 Windows, Linux, Mac OS X
* Vagrant: https://www.vagrantup.com/
    * 支援 Windows, Linux, Mac OS X

### 相關資訊

* http://spark.apache.org/docs/1.6.2/spark-standalone.html

### 叢集資訊

定義在 nodes.yml.template

```
---
- name: spark-m1
  node_type: master
  vm_box: ubuntu/trusty64
  ram: 2048
  network:
    identifier: private_network
    ip: 172.16.1.10

- name: spark-s1
  node_type: slave
  vm_box: ubuntu/trusty64
  ram: 2048
  network:
    identifier: private_network
    ip: 172.16.1.20

- name: spark-s2
  node_type: slave
  vm_box: ubuntu/trusty64
  ram: 2048
  network:
    identifier: private_network
    ip: 172.16.1.30
```

### 進行步驟

* 先使用 git clone, 下載 vagrant-spark-cluster.git

```
$ git clone https://github.com/is-land/vagrant-spark-cluster.git
$ cd vagrant-spark-cluster
```

節點的定義資訊須寫在 `nodes.yml`, 可參考 `nodes.yml.template`
記憶體請設定在 2G 以上, 這裡使用 nodes.yml.template 的預設值

```
$ cd vagrant-spark-cluster
[vagrant-spark-cluster]$ cp nodes.yml.template node.yml
```

使用 `vagrant status` 若顯示三台 VMs 的資訊表示正確讀取 nodes.yml 

```
[vagrant-spark-cluster]$ vagrant status
[ Apache Spark standalone cluster ]
Nodes definition: nodes.yml
Ansible inventory-file not exist. New file created: ansible/nodes
============================================================
Ansible control host: spark-m1
Current machine states:

spark-m1                  not created (virtualbox)
spark-s1                  not created (virtualbox)
spark-s2                  not created (virtualbox)

This environment represents multiple VMs. The VMs are all listed
above with their current state. For more information about a specific
VM, run `vagrant status NAME`.
```

接著使用 `vagrant up` 建立並啟動三台 VMs, 若是初次使用 vagrant, 則會先進行 download Virtualbox Ubuntu image 的動作

```
[vagrant-spark-cluster]$ vagrant up
[ Apache Spark standalone cluster ]
Nodes definition: nodes.yml
Ansible inventory-file found: ansible/nodes
============================================================
Ansible control host: spark-m1
Bringing machine 'spark-m1' up with 'virtualbox' provider...
Bringing machine 'spark-s1' up with 'virtualbox' provider...
Bringing machine 'spark-s2' up with 'virtualbox' provider...
==> spark-m1: Importing base box 'ubuntu/trusty64'...
:       :       :       :       :
:       :       :       :       :
==> spark-s2: Checking for guest additions in VM...
==> spark-s2: Setting hostname...
==> spark-s2: Configuring and enabling network interfaces...
==> spark-s2: Mounting shared folders...
    spark-s2: /vagrant => /home/user1/vagrant-spark-cluster
==> spark-s2: Running provisioner: shell...
    spark-s2: Running: inline script
[vagrant-spark-cluster]$    
```

到最後就可以觀察到三台 VMs 最後建立起來了:
spark-m1, spark-s1, spark-s2

使用 vagrant ssh 免密碼登入 `spark-m1`
接下來在 spark-m1(control host) 使用 ansible 進行安裝

```
[vagrant-spark-cluster]$ vagrant ssh spark-m1
vagrant@spark-m1:~$ cd /vagrant/ansible
vagrant@spark-m1:/vagrant/ansible$ ansible-galaxy install -r requirements.yml
- downloading role 'oracle-java', owned by williamyeh
- downloading role from https://github.com/William-Yeh/ansible-oracle-java/archive/2.10.0.tar.gz
- extracting williamyeh.oracle-java to /home/vagrant/.ansible/roles/williamyeh.oracle-java
- williamyeh.oracle-java was installed successfully
vagrant@spark-m1:/vagrant/ansible$
vagrant@spark-m1:/vagrant/ansible$ ansible-playbook -i nodes spark-cluster.yml

PLAY [masters, slaves] *********************************************************

TASK [setup] *******************************************************************
ok: [spark-m1]
ok: [spark-s1]
ok: [spark-s2]

:       :       :       :       :
:       :       :       :       :
PLAY RECAP *********************************************************************
spark-m1                   : ok=42   changed=25   unreachable=0    failed=0
spark-s1                   : ok=38   changed=22   unreachable=0    failed=0
spark-s2                   : ok=38   changed=22   unreachable=0    failed=0
vagrant@spark-m1:/vagrant/ansible$
```

ansible 安裝完成後, 退出 spark-m1
重新 ssh 登入:

```
vagrant@spark-m1:/vagrant/ansible$ exit
logout
Connection to 127.0.0.1 closed.
[vagrant-spark-cluster]$ vagrant ssh spark-m1
vagrant@spark-m1:~$
```

啟動 spark cluster 所有節點

```
vagrant@spark-m1:~$ cd ~/spark-1.6.2-bin-hadoop2.6/
vagrant@spark-m1:~/spark-1.6.2-bin-hadoop2.6$ sbin/start-all.sh
starting org.apache.spark.deploy.master.Master, logging to /home/vagrant/spark-1.6.2-bin-hadoop2.6/logs/spark-vagrant-org.apache.spark.deploy.master.Master-1-spark-m1.out
spark-s2: Warning: Permanently added 'spark-s2' (ECDSA) to the list of known hosts.
spark-s1: Warning: Permanently added 'spark-s1' (ECDSA) to the list of known hosts.
spark-s2: starting org.apache.spark.deploy.worker.Worker, logging to /home/vagrant/spark-1.6.2-bin-hadoop2.6/logs/spark-vagrant-org.apache.spark.deploy.worker.Worker-1-spark-s2.out
spark-s1: starting org.apache.spark.deploy.worker.Worker, logging to /home/vagrant/spark-1.6.2-bin-hadoop2.6/logs/spark-vagrant-org.apache.spark.deploy.worker.Worker-1-spark-s1.out
vagrant@spark-m1:~/spark-1.6.2-bin-hadoop2.6$
```

由於 spark 的設定將 eventLog 設為 true, 因此請先建資料夾: `/tmp/spark-events`
接著執行 spark-shell 測試看看

```
vagrant@spark-m1:~/spark-1.6.2-bin-hadoop2.6$ mkdir /tmp/spark-events
vagrant@spark-m1:~/spark-1.6.2-bin-hadoop2.6$ bin/spark-shell
16/09/08 14:36:33 WARN NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
16/09/08 14:36:33 INFO SecurityManager: Changing view acls to: vagrant
16/09/08 14:36:33 INFO SecurityManager: Changing modify acls to: vagrant
16/09/08 14:36:33 INFO SecurityManager: SecurityManager: authentication disabled; ui acls disabled; users with view permissions: Set(vagrant); users with modify permissions: Set(vagrant)
16/09/08 14:36:34 INFO HttpServer: Starting HTTP Server
16/09/08 14:36:34 INFO Utils: Successfully started service 'HTTP class server' on port 42099.
Welcome to
      ____              __
     / __/__  ___ _____/ /__
    _\ \/ _ \/ _ `/ __/  '_/
   /___/ .__/\_,_/_/ /_/\_\   version 1.6.2
      /_/

Using Scala version 2.10.5 (Java HotSpot(TM) 64-Bit Server VM, Java 1.8.0_102)
Type in expressions to have them evaluated.
Type :help for more information.
16/09/08 14:36:42 INFO SparkContext: Running Spark version 1.6.2
:       :       :       :       :
:       :       :       :       :
16/09/08 14:37:10 INFO SparkILoop: Created sql context (with Hive support)..
SQL context available as sqlContext.

scala>
```

應該會發現產生的 log 資訊非常多, 此時可以修改 conf/log4j.properties:
將 `log4j.rootCategory=INFO, console` 改為 `log4j.rootCategory=WARN, console` 即可減少 log 資訊

```
vagrant@spark-m1:~/spark-1.6.2-bin-hadoop2.6$ bin/spark-shell
16/09/08 14:41:11 WARN NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
Welcome to
      ____              __
     / __/__  ___ _____/ /__
    _\ \/ _ \/ _ `/ __/  '_/
   /___/ .__/\_,_/_/ /_/\_\   version 1.6.2
      /_/

Using Scala version 2.10.5 (Java HotSpot(TM) 64-Bit Server VM, Java 1.8.0_102)
Type in expressions to have them evaluated.
Type :help for more information.
Spark context available as sc.
16/09/08 14:41:27 WARN Connection: BoneCP specified but not present in CLASSPATH (or one of dependencies)
16/09/08 14:41:28 WARN Connection: BoneCP specified but not present in CLASSPATH (or one of dependencies)
16/09/08 14:41:36 WARN ObjectStore: Version information not found in metastore. hive.metastore.schema.verification is not enabled so recording the schema version 1.2.0
16/09/08 14:41:36 WARN ObjectStore: Failed to get database default, returning NoSuchObjectException
16/09/08 14:41:39 WARN Connection: BoneCP specified but not present in CLASSPATH (or one of dependencies)
16/09/08 14:41:40 WARN Connection: BoneCP specified but not present in CLASSPATH (or one of dependencies)
SQL context available as sqlContext.

scala>
```

使用瀏覽器開啟: `http://172.16.1.10:8080/`
即可看到 Spark Web UI
