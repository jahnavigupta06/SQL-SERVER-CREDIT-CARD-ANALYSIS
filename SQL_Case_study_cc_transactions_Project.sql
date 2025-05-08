select *
from credit_card_transactions


-- 1- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 

with cte as 
(
select city, sum(amount) as total_spend
from credit_card_transactions
group by city
)
, total_spent as 
(select SUM(cast(amount as bigint)) as total_amount 
from credit_card_transactions
)
select top 5 cte.*,round((total_spend*1.0/total_amount)*100,2) as percent_contribution
from cte,total_spent
order by total_spend desc




-- 2- write a query to print highest spend month and amount spent in that month for each card type

with cte as 
(
select card_type, DATEPART(YEAR,date) as date_year,DATEPART(month,date) as date_month, SUM(amount) as spent_amount
from credit_card_transactions
group by card_type,DATEPART(YEAR,date),DATEPART(month,date)
),
cte1 as 
(
select *, rank() over (partition by card_type order by spent_amount desc) as rn
from cte
)
select *
from cte1
where rn = 1
;


-- 3- write a query to print the transaction details(all columns from the table) for each card type when
--    it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)

with cte as (
select *,SUM(amount) over (partition by card_type order by date,transaction_id) as total_spent
from credit_card_transactions
)
select * from 
(select * , RANK() over (partition by card_type order by total_spent asc) as rn
from cte
where total_spent >= 1000000) a 
where rn =1




-- 4- write a query to find city which had lowest percentage spend for gold card type

with cte as
(
select city, card_type, SUM(amount) as amount,
SUM(case when card_type = 'gold' then amount end) as gold_amount
from credit_card_transactions
group by city, card_type)
select top 1 city, sum(gold_amount)*1.0/sum(amount) as gold_ratio 
from cte
group by city
having sum(gold_amount) is not null
order by gold_ratio


-- 5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type 
--   (example format : Delhi , bills, Fuel)
-----------incorrect-----------------
with cte as
(
select city, exp_type, sum(amount) as total_amount
from credit_card_transactions
group by city, exp_type
)
select city, 
max(CASE when rn_asc = 1 then exp_type end ) as lowest_expense_type,
min(CASE when rn_desc = 1 then exp_type end ) as highest_expense_type
from(
select *, 
RANK() over (partition by city order by total_amount desc) as rn_desc
,RANK() over (partition by city order by total_amount desc) as rn_asc
from cte) a 
group by city

-- output 
-- Achalpur , Grocery,Entertainment
-- Adilabad, Bills, Food




























