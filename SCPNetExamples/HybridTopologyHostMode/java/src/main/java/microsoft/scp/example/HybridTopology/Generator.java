package microsoft.scp.example.HybridTopology;

import backtype.storm.spout.SpoutOutputCollector;
import backtype.storm.task.TopologyContext;
import backtype.storm.topology.OutputFieldsDeclarer;
import backtype.storm.topology.base.BaseRichSpout;
import backtype.storm.tuple.Fields;
import backtype.storm.tuple.Values;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Map;
import java.util.Random;

/**
 * Created by tqin on 9/11/2014.
 */
public class Generator extends BaseRichSpout {
    public static final Logger LOG = LoggerFactory.getLogger(Generator.class);

    SpoutOutputCollector _collector;
    Random _rand;

    Person[] persons = new Person[] {
            new Person("Tom", 20),
            new Person("Marry", 18),
            new Person("David", 25)
    };

    // input parameters are only used to test serialization/deserialization of constructor parameters between C# and Java
    public Generator(int param1, String param2, String param3) {
        LOG.info("Generator's constructor is called");
        LOG.info("param1: " + param1);

        if (param2 != null) {
            LOG.info("param2: " + param2);
        } else {
            LOG.info("param2: NULL");
        }

        if (param3 != null) {
            LOG.info("param3: " + param3);
        } else {
            LOG.info("param3: NULL");
        }
    }

    // input parameters are only used to test serialization/deserialization of constructor parameters between C# and Java
    public Generator(GeneratorConfig conf) {
        LOG.info("Generator's constructor is called");
        LOG.info("conf: " + conf);
    }

    @Override
    public void open(Map map, TopologyContext topologyContext, SpoutOutputCollector spoutOutputCollector) {
        _collector = spoutOutputCollector;
        _rand = new Random();
    }

    @Override
    public void nextTuple() {
        Person person = persons[_rand.nextInt(persons.length)];
        LOG.info("person: " + person.toString());
        _collector.emit("default", new Values(person));
    }

    @Override
    public void declareOutputFields(OutputFieldsDeclarer outputFieldsDeclarer) {
        outputFieldsDeclarer.declareStream("default", new Fields("person"));
    }

}
