-- Update cost table as we iterate over graph nodes
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



-- adds most updated node in Dijkstra’s path
INSERT OVERWRITE table path
select node, previous_node, order_path, total_cost from path
UNION ALL
select t.node as node, t.previous as previous_node, max_path + 1 as order_path, t.cost_val as total_cost from 
(select cost.node, cost.cost_val, cost.previous from cost join 
(select min(cost_val) min_val from cost c left outer join path p on p.node = c.node where p.order_path is NULL) temp
where cost.cost_val = temp.min_val) t
join
(select max(order_path) max_path from path) j;


-- this checks to see if we have hit the final destination
select case when count_target >= 1 then 'TRUE' else 'FALSE' end as check from
(select sum(is_target) count_target from
(select case when node == '${hiveconf:target}' then 1 else 0 end as is_target from path) find_target) final_check;



