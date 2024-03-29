-- with Time Travel
-- see https://docs.snowflake.com/en/sql-reference/constructs/at-before

use schema challenge_history.public;

-- for the CUSTOMER table --> check retention_time=1 (one day!)
-- copy also created_on LTZ timestamp (ex: '2024-01-06 07:27:41.874 -0800')
show tables;

select count(*) from customers;

-- this will fail --> increase by 1 second to succeed!
-- ("Time travel data is not available for table CUSTOMERS.
-- The requested time is either beyond the allowed time travel period
-- or before the object creation time.")
select count(*) from customers
at (timestamp => '2024-01-07 08:09:06.535 -0800'::TIMESTAMP_LTZ);

-- this will succeed --> timestamp increased by just 1 second
select count(*) from customers
at (timestamp => '2024-01-07 08:09:07.535 -0800'::TIMESTAMP_LTZ);

-- this will not fail, but nt working as expected --> time-travel requires constant parameters!
-- see https://stackoverflow.com/questions/59121146/use-dynamic-value-in-snowflake-time-travel-sql
-- see https://docs.snowflake.com/en/sql-reference/functions/generator
with gen as (
  select seq4() + 1 as step
  from table(generator(rowcount => 10))),
tots as (
  select count(*) as tot
  from customers)
select step, tot
  from gen, tots at (timestamp => dateadd('minute', step, '2024-01-07 08:15:06.535 -0800'::TIMESTAMP_LTZ))
  order by step;

-- but we can do this (SOLUTION!) --> UNION query with CTE for LAG
-- show bar chart w/ step and diff
with q(step, tot) as (
    select 1, count(*)
      from customers
      at (timestamp => '2024-01-07 08:10:06.535 -0800'::TIMESTAMP_LTZ)
    union all
    select 2, count(*)
      from customers
      at (timestamp => '2024-01-07 08:11:06.535 -0800'::TIMESTAMP_LTZ)
    union all
    select 3, count(*)
      from customers
      at (timestamp => '2024-01-07 08:12:06.535 -0800'::TIMESTAMP_LTZ)
    union all
    select 4 as step, count(*) as tot
      from customers
      at (timestamp => '2024-01-07 08:13:06.535 -0800'::TIMESTAMP_LTZ)
    union all
    select 5, count(*)
      from customers
      at (timestamp => '2024-01-07 08:14:06.535 -0800'::TIMESTAMP_LTZ)
    union all
    select 6, count(*)
      from customers
      at (timestamp => '2024-01-07 08:15:06.535 -0800'::TIMESTAMP_LTZ)
    union all
    select 7, count(*)
      from customers
      at(timestamp => '2024-01-07 08:16:06.535 -0800'::TIMESTAMP_LTZ)
    union all
    select 8, count(*)
      from customers
      at (timestamp => '2024-01-07 08:17:06.535 -0800'::TIMESTAMP_LTZ)
    union all
    select 9, count(*)
      from customers
      at (timestamp => '2024-01-07 08:18:06.535 -0800'::TIMESTAMP_LTZ)
    union all
    select 10, count(*)
      from customers
      at (timestamp => '2024-01-07 08:19:06.535 -0800'::TIMESTAMP_LTZ)
)
select step, tot, tot - LAG(tot) over (order by step) as diff
from q;

