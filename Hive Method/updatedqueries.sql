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


---------------------- ITERATION ------------------------------

-- USE EITHER ONE
INSERT OVERWRITE TABLE cost
select l2.node, 
case when new_cost is null then l2.cost_val when new_cost < l2.cost_val then new_cost else l2.cost_val end as new_new, 
case when previous is null and temp.from_node is null then null when new_cost < l2.cost_val then temp.from_node else previous end  as new_previous from
(select * from cost) l2
left join
(select l.to_node ,l.weight + r.cost_val as new_cost, l.from_node from 
(select * from cost) r
inner join
(select data.from_node, data.to_node, data.weight from data join 
(select node, order_path from path order by order_path desc limit 1) t
on (t.node = data.from_node))l
on (l.from_node = r.node)) temp
on (l2.node = temp.to_node);



-- get nodes that are not in the path already
INSERT OVERWRITE table path
select node, previous_node, order_path, total_cost from path
UNION ALL
select t.node as node, t.previous as previous_node, max_path + 1 as order_path, t.cost_val as total_cost from 
(select cost.node, cost.cost_val, cost.previous from cost join 
(select min(cost_val) min_val from cost c left outer join path p on p.node = c.node where p.order_path is NULL) temp
where cost.cost_val = temp.min_val) t
join
(select max(order_path) max_path from path) j;



-- Results from the path update with the lowest cost val
--c	2
--a	1
--Time taken: 51.56 seconds, Fetched: 2 row(s)


-- this checks to see if we have hit the final destination
select case when count_target >= 1 then 'TRUE' else 'FALSE' end as check from
(select sum(is_target) count_target from
(select case when node == '${hiveconf:target}' then 1 else 0 end as is_target from path) find_target) final_check;



