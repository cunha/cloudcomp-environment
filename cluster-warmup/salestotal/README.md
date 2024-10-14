# $HBASE_HOME/bin/hbase shell < data/sales.hbase

mkdir sales_classes
javac -cp $JOINED_CLASSPATH -d hbase_sales_classes hbase_sales/HBaseSales.java
jar -cvf sales.jar -C sales_classes/ .
$HADOOP_HOME/bin/hadoop jar sales.jar sales.HBaseSales

echo "scan 'test2'" | $HBASE_HOME/bin/hbase shell
