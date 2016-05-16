--1237277400 to 2404284708

CREATE EXTERNAL TABLE data (from_node string, to_node string, weight double)
row format delimited
fields terminated by ','
lines terminated by '\n'
stored as textfile
location 's3://distcompfinaljcn/finaldata/';

--Time taken: 1.107 seconds, Fetched: 18 row(s)

SET hive.exec.dynamic.partition = true;
SET hive.exec.dynamic.partition.mode = nonstrict;
SET hive.exec.max.dynamic.partitions=100000;
SET hive.exec.max.dynamic.partitions.pernode=100000;
SET mapred.max.split.size=1000000;

CREATE TABLE cost (node string, cost_val double, previous string);
INSERT OVERWRITE TABLE cost select distinct from_node, 100000.0, NULL from data;


-- setting the starting node to a
set start = 1237277400;
set current = 1237277400;
set target = 2404284708;

--${hiveconf:current} is how you retrieve INSERT TRIAL TO SEE IF IT WORKS
-- select * from graph where from_node = '${hiveconf:current}';

-- create a path NEED TO DO STILL
CREATE TABLE path (node string, previous_node string, order_path int, total_cost float);
INSERT OVERWRITE TABLE path select node,'${hiveconf:start}', 1, 0 from cost where node = '${hiveconf:start}';


-- initializing
-- setting starting node to 0 and everything else to large value
INSERT OVERWRITE TABLE cost select node, case when node = '${hiveconf:current}' then 0 else cost_val end, case when node = '${hiveconf:current}' then '${hiveconf:start}' else NULL end from cost;
