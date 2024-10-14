package wordcount;
import java.io.IOException;
import java.util.StringTokenizer;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

public class WordCount {
    /* A MapReduce job is composed of a Mapper and a Reducer. The
       WordCount class contains two public classes to implement these
       functionalities. */

    /* A Mapper<IK, IV, OK, OT> specifies the input key (IK), the input
       value (IV), the output key (OK), and output value (OV) types. The
       values received by TokenizerMapper class are lines of text (Text
       type), and the input key is the offset of the line of text in the
       input file (Object type). The output key of the TokenizerMapper
       class is a word (Text type) and the value 1 (IntWritable type). */
    public static class TokenizerMapper
            extends Mapper<Object, Text, Text, IntWritable> {
        // Field @one is the value in all outputs.
        private final static IntWritable one = new IntWritable(1);
        // Field @word stores the key in each output. It contains a word
        // found in a line and is initialized by converting String into
        // Text.
        private Text word = new Text();

        /* The map() function breaks down the line of text into words using
           Java's StringTokenizer class, and then outputs a pair (word, one)
           for each work in the line. */
        public void map(Object key, Text value, Context context)
                throws IOException, InterruptedException {
            StringTokenizer itr = new StringTokenizer(value.toString());
            while (itr.hasMoreTokens()) {
                // Iterate through each word in the line.
                word.set(itr.nextToken());
                context.write(word, one);
            }
        }
    }

    /* A Reducer<IK, IV, OK, OV> specifies the input key (IK), input
       value (IV), output key (OK), and output value (OV) types. The
       IntSumReducer receives words as input keys (Text type), and the
       value 1 as input values (IntWritable type). IntSumReducer output
       keys are words (Text type) and a count of how many times they
       appeared in the input (IntWritable type). */
    public static class IntSumReducer
            extends Reducer<Text, IntWritable, Text, IntWritable> {

        // Field @result stores how many times a word has appeared.
        private IntWritable result = new IntWritable();

        /* The reduce() function receives a key and an iterable over all
           values for that key. We add up the values of all counters and
           output a pair (word, count). */
        public void reduce(Text key, Iterable<IntWritable> values, Context ctx)
                throws IOException, InterruptedException {
            int sum = 0;
            for (IntWritable val : values) {
                sum += val.get();
            }
            result.set(sum);
            ctx.write(key, result);
        }
    }

    public static void main(String[] args) throws Exception {
        Configuration conf = new Configuration();
        /* We generate a job; specify the Mapper, Combiner, and Reducer
           classes; specify the output key and value types. The
           directories where the inputs are read from and outputs
           written to are received from the command line. */
        Job job = Job.getInstance(conf, "word count");
        job.setJarByClass(WordCount.class);
        job.setMapperClass(TokenizerMapper.class);
        job.setReducerClass(IntSumReducer.class);
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(IntWritable.class);
        FileInputFormat.addInputPath(job, new Path(args[0]));
        FileOutputFormat.setOutputPath(job, new Path(args[1]));
        System.exit(job.waitForCompletion(true) ? 0 : 1);
    }
}
