# WordCount MapReduce Example

In this example we will review and execute a WordCount program
implemented in the MapReduce paradigm. Study the code in
`WordCount.java`, it has extensive comments explaning how it works.

## Compiling the Code

After reviwing the code, we will create a directory to contain our
compiled classes.

```{bash}
mkdir classes
```

To compile the `WordCount.java` program, we need to provide Java with
the location where it can find the Hadoop libraries. We do this by
setting and passing a `CLASSPATH` as a parameter:

```{bash}
export HADOOP_CP=$(hadoop classpath)
javac -cp $HADOOP_CP -d classes WordCount.java
jar -cvf wordcount.jar -C classes/ .
```

## Preparing the Inputs

We provide two files as input: `lorem1.txt` and `lorem2.txt`. WordCount
Map instances will process these files from HDFS. We need to load these
files into HDFS before we execute WordCount. We will place these files
into an `input` directory, and create another `output` directory to hold
the results:

```{bash}
hdfs dfs -mkdir -p input
hdfs dfs -put lorem1.txt input/lorem1.txt
hdfs dfs -put lorem2.txt input/lorem2.txt
hdfs dfs -mkdir -p output
```

## Running WordCount

We can launch our code submitting it to Hadoop. We pass a JAR file
(`wordcount.jar`, generated in the previous step) and a class containing
the `main` method (`wordcount.WordCount`). We also pass two directories
as parameters (`input` and `output`); all files in `input` will be read
and processed by Map instances, and `output` will be written to by
Reduce instances.

```{bash}
hadoop jar wordcount.jar wordcount.WordCount input output
```

## Inspecting Results

We can verify the results by inspecting the files under the `output`
directory:

```{bash}
hdfs dfs -ls output
```

Use `hdfs dfs -cat output/filename` to see the contents of the output
file.
