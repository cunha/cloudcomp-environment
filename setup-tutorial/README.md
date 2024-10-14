# Introduction to Hadoop, HDFS, and HBase

In this assignment we will deploy a Hadoop, HDFS, and HBase in a
pseudo-distributed configuration, that is, multiple nodes running on a
single machine. We will then run example introductory code on our
deployment.

## (Optional) Creating a virtual machine

You can run the instructions below on a Linux machine. If your machine
does not run Linux, a common approach is to use a virtual machine.
[VirtualBox][virtualbox-page] is a common user-friendly virtualization
solution for PCs running Windows. There are several good tutorials
online on how to install a Linux guest on VirtualBox. We suggest you
install [Debian Bullseye][debian-download] on your virtual machine, as
that is what the steps below were tested on.

If you have access to a *physical* machine running Linux, you may still
want to run the steps below in a virtual machine. In this case, you can
use the `Vagrantfile` in the repository to create a virtual machine
running Debian Bullseye by running `vagrant up`, and later access the VM
using `vagrant ssh lab0`.

## Setting Up Hadoop and HDFS

We will install and configure Hadoop with HDFS to run MapReduce jobs in
a pseudo-distributed deployment, i.e., a deployment with multiple
"nodes" running on a single (virtual) machine. The instructions below
are complementary to the official [how-to][hadoop-install-howto]. More
extensive configuration instructions are available from
[Hortonworks][hadoop-install-hortonworks] as well as
[TutorialsPoint][hadoop-install-tutorialspoint] and might be useful in
troubleshooting unforeseen issues.

### Getting Hadoop and Java

Download a binary distribution of Hadoop from one of the
[mirrors][hadoop-mirrors]. In developing this tutorial we used Hadoop
3.3.1. You will also need a working Java SDK. In this tutorial we used
OpenJDK 11 (the default in Debian Bullseye):

```{bash}
wget https://dlcdn.apache.org/hadoop/common/hadoop-3.3.1/hadoop-3.3.1.tar.gz
tar zxf hadoop-3.3.1.tar.gz
sudo apt-get install openjdk-11-jdk-headless
```

We suggest you create an environment file to set-up your shell for
easier operation of Hadoop and HDFS. The `env.sh` file in this
repository provides an example; such files can be loaded into a Bash of
ZSH shell using `source env.sh` on the command line. Consider creating a
file with the following variables:

```{bash}
export JAVA_HOME=/path/to/java/home
export HADOOP_HOME=/path/to/hadoop
export HADOOP_CONFIG="$HADOOP_HOME/etc/hadoop"
export PATH=$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH
```

`HADOOP_HOME` is the path where you decompressed the Hadoop `.tar.gz`
file above. On Linux, you can find where Java is installed to configure
`JAVA_HOME` running the following command:

```{bash}
$ java -XshowSettings:properties -version 2>&1 > /dev/null | grep 'java.home'
    java.home = /usr/lib/jvm/java-11-openjdk-amd64
```

### Configuring Hadoop and HDFS

Hadoop configuration is stored in the `etc/hadoop` subdirectory, which
we named `$HADOOP_CONFIG` in our `env.sh` file. We will need to edit
some files to match our deployment.

The `hadoop-env.sh` file sets the shell up for running Hadoop.  Most
variables are set automatically, but we need to set `JAVA_HOME`
manually. The `hadoop-env.sh` file has a commented-out line to `export
JAVA_HOME`; edit the file to uncomment it and configure it as in the
`env.sh` file above.

The `core-site.xml` contains configuration for the Hadoop deployment,
e.g., like resource use limits. We will add configuration to indicate
where HDFS's NameNode for the default file system can be reached.
Without this configuration, we would need to indicate which filesystem
to use on every command.

```{xml}
<configuration>
  <property>
    <name>fs.default.name</name>
    <value>hdfs://127.0.0.1:9000</value>
    <description>NameNode URI</description>
  </property>
</configuration>
```

Create directories to store HDFS's NameNode and DataNode files:

```{bash}
mkdir -p $HADOOP_HOME/hdfs/namenode
mkdir -p $HADOOP_HOME/hdfs/datanode
```

The `hdfs-site.xml` file contains HDFS's configuration. We will set the
number of replicas to `1` (no replication) in our deployment, and
configure the paths used by the NameNode and the DataNode. Adjust the
absolute paths after `file://` to the paths in your environment, which
you can find running, e.g., `echo $HADOOP_HOME/hdfs/namenode`.

```{xml}
  <property>
    <name>dfs.replication</name >
    <value>1</value>
  </property>
  <property>
    <name>dfs.namenode.name.dir</name>
    <value>file:///home/vagrant/hadoop-3.3.1/hdfs/namenode</value>
    <description>Path to NameNode dir</description>
  </property>
  <property>
    <name>dfs.datanode.data.dir</name>
    <value>file:///home/vagrant/hadoop-3.3.1/hdfs/datanode</value>
    <description>Path to DataNode dir</description>
  </property>
```

Now that Hadoop and HDFS are configured, we can bring the services up.
Start by formatting the NameNode directory. You only need to format the
NameNode directory once.

```{bash}
hdfs namenode -format
```

Then start both the NameNode and DataNode:

```{bash}
hdfs --daemon start namenode
hdfs --daemon start datanode
```

If these steps have run successfully, you should have Hadoop and HDFS
operational. You can check that both the NameNode and DataNode are
running using the `jps` command. You can also access Hadoop's Web
interface by browsing `http://ip-of-virtual-machine:50070` (if the
virtual machine is not locally accessible, you will need [port
forwarding][ssh-port-forwarding]).

### Testing and Using HDFS

The commands below will perform basic operations on HDFS:

```{bash}
# Create a directory test at the root of the filesystem:
hdfs dfs -mkdir /test
# Adding a file to the filesystem:
hdfs dfs -put $HADOOP_HOME/LICENSE.txt /test
# Listing the contents of a directory:
hdfs dfs -ls /test
# Determine the size of a file on HDFS:
hdfs dfs -du -h /test
# Get the contents of a file (then taking only the first 10 lines):
hdfs dfs -cat /test/LICENSE.txt | head
# Making a copy of a file:
hdfs dfs -cp /test/LICENSE.txt /test/LICENSE.backup
# Getting a local copy of a file on HDFS:
hdfs dfs -get /test/LICENSE.txt LICENSE.local
# Check the integrity of the filesystem:
hdfs fsck /
# Delete a file on HDFS:
hdfs dfs -rm /test/LICENSE.backup
# Recursively remove a directory on HDFS:
hdfs dfs -rm -r /test
```

## WordCount in MapReduce

WordCount is a classic MapReduce example. We provide an explanation of
how the WordCount implementation works and instructions on how to run
the code in the `wordcount` subdirectory in this repository. The [HBase
book][hbase-book] contains more detailed information that may be useful
in troubleshooting unforeseen issues.

## Setting up HBase

HBase is Hadoop's distributed database; think big tables with random
access to rows. HBase runs on top of HDFS. In the following we will
extend our deployment to include HBase.

### Getting HBase

You can download HBase from [Apache][hbase-mirrors]. We suggest you get
the binary package to avoid the need for compiling the source. In this
tutorial we used version 2.3.7:

```{bash}
wget https://www.apache.org/dyn/closer.lua/hbase/2.3.7/hbase-2.3.7-bin.tar.gz
tar zxf hbase-2.3.7-bin.tar.gz
```

Extend `env.sh` to include paths to HBase. Note that `PATH` now includes
`$HBASE_HOME/bin`. Set `HBASE_HOME` to the directory created by
decompressing the `.tar.gz` file in the previous step.

```{bash}
export HBASE_HOME=/path/to/hbase/home
export HBASE_CONF="$HBASE_HOME/conf"
export PATH=$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HBASE_HOME/bin:$PATH
```

### Configuring HBase

HBase's configuration is contained inside the `conf` subdirectory, which
we named `$HBASE_CONF` in our `env.sh` file. As with Hadoop, we will
need to edit some files to match our deployment.

The `hbase-env.sh` file is similar to `hadoop-env.sh` above and sets the
shell up for running HBase.  Most variables are set automatically, but
we need to set `JAVA_HOME` manually. The `hbase-env.sh` file has a
commented-out line to `export JAVA_HOME`; edit the file to uncomment it
and configure it as in the `env.sh`.

We will change
where ZooKeeper keeps information. By default, ZooKeeper stores
information in the machine's `/tmp` directory, which works but gets
cleared whenever the machine is rebooted. Create a directory for storing
ZooKeeper information:

```{bash}
mkdir -p $HBASE_HOME/zookeeper
```

The `hbase-site.xml` contains configuration for HBase. We will set HBase
to consider a distributed cluster, specify the root directory inside
HDFS where HBase will store data, change the WAL (write-ahead-log)
provider to the simpler `filesystem` provider, and change the location
used by ZooKeeper to store information. Add the following to
`hbase-site.xml`, adjusting ZooKeeper's data directory to the path in
the previous step (which you can get running `echo
$HBASE_HOME/zookeeper`):

```{xml}
<configuration>
  <property>
    <name>hbase.cluster.distributed</name>
    <value>true</value>
  </property>
  <property>
    <name>hbase.rootdir</name>
    <value>hdfs://localhost:9000/hbase</value>
  </property>
  <property>
    <name>hbase.wal.provider</name>
    <value>filesystem</value>
  </property>
  <property>
    <name>hbase.zookeeper.property.dataDir</name>
    <value>/path/to/zookeper</value>
  </property>
</configuration>
```

### Launching and Testing HBase

You can launch HBase by running the following:

```{bash}
start-hbase.sh
```

Wait a few seconds for startup to complete, and then you will be able to
see HBase files inside HDFS under the root directory configured in
`hbase-site.xml`:

```{bash}
hdfs dfs -ls /hbase
```

You can interact with HBase directly through its shell by running `hbase
shell`. The shell supports various [commands][hbase-shell-commands]. For
example, the following will create, describe, and add some data to a
table:

```{bash}
$ hbase shell
(...)
hbase(main):001:0> create 'sales', 'data'
hbase(main):002:0> list
hbase(main):003:0> describe 'sales'
hbase(main):004:0> put 'sales', 'shoes', 'data:count', 3
hbase(main):005:0> put 'sales', 'shoes', 'data:price', 40
hbase(main):006:0> put 'sales', 'socks', 'data:count', 10
hbase(main):007:0> put 'sales', 'socks', 'data:price', 10
hbase(main):008:0> scan 'sales'
hbase(main):009:0> get 'sales', 'shoes'
hbase(main):010:0> disable 'sales'
hbase(main):011:0> drop 'sales'
hbase(main):012:0> exit
```

## MapReduce Using HBase

The `salestotal` subdirectory in this repository contains instructions
and data for example running MapReduce using HBase.

[virtualbox-page]: https://www.virtualbox.org/
[debian-download]: https://www.debian.org/download

[hadoop-install-howto]: https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/SingleCluster.html
[hadoop-install-hortonworks]: https://docs.cloudera.com/HDPDocuments/HDP2/HDP-2.1.7/bk_installing_manually_book/content/index.html
[hadoop-install-tutorialspoint]: https://www.tutorialspoint.com/hadoop/hadoop_quick_guide.htm
[hadoop-mirrors]: https://www.apache.org/dyn/closer.cgi/hadoop/common/
[hadoop-java-versions]: https://cwiki.apache.org/confluence/display/HADOOP/Hadoop+Java+Versions
[ssh-port-forwarding]: https://www.ssh.com/academy/ssh/tunneling/example

[hbase-mirrors]: https://hbase.apache.org/downloads.html
[hbase-book]: https://hbase.apache.org/book.html
[hbase-shell-commands]: https://data-flair.training/blogs/hbase-shell-commands/
