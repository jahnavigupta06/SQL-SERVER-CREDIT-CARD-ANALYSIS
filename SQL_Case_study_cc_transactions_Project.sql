-- Take a look over credit_card_transactions table to understand the data


select *
from credit_card_transactions;

-- Explore the dataset first

select MIN(DATE) as min_transaction_date 
from credit_card_transactions;


select Max(DATE) as max_transaction_date 
from credit_card_transactions;


select card_type 
from credit_card_transactions;


select exp_type
from credit_card_transactions;

select distinct city 
from credit_card_transactions;



-- with the above exploration I get a rough idea what is dataset all about.


-- Questions :-

-- 1- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 

with cte1 as
(
select  city, sum(amount) as city_spend_amt
from credit_card_transactions
group by city ),
total_spend_amount as 
(
select SUM(cast (amount as bigint)) as total_amount  -- Here amount is hge so to make it appear I have to cast in bigint
from credit_card_transactions
) 

select top 5 cte1.* , city_spend_amt* 1.0/total_amount* 100 as percent_contri
from cte1, total_spend_amount
order by city_spend_amt desc

-- output example :-
-- city  amount   %ofcontri
-- Vita  1k       10%  


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

with cte as
(
select city, exp_type, sum(amount) as total_amount
from credit_card_transactions
group by city, exp_type
)
select city, 
max(CASE when rn_asc = 1 then exp_type end ) as lowest_expense_type, -- we can do min/ max function on string which reduces our efforts so i am using this
min(CASE when rn_desc = 1 then exp_type end ) as highest_expense_type
from(
select *, 
RANK() over (partition by city order by total_amount desc) as rn_desc  -- I am using rank here as there are very low chances that each city has same total_amount
,RANK() over (partition by city order by total_amount desc) as rn_asc  -- I want for eac city so partition by city then i need highest so use desc order, another case I want lowest so i use asc order
from cte) a 
group by city

-- output 
-- Achalpur , Grocery,Entertainment
-- Adilabad, Bills, Food


-- 6- write a query to find percentage contribution of spends by females for each expense type

select exp_type, 
sum(case when gender = 'F' then amount else 0  end ) * 1.0/ SUM(amount)* 100 as female_spend_contri
from credit_card_transactions
group by exp_type;


-- 7- which card and expense type combination saw highest month over month growth in Jan-2014

with cte as
(
select card_type, exp_type, datepart( year, date) as yt , datepart(month, date) as mt, SUM(amount) as total_spend
from credit_card_transactions
group by card_type, exp_type, datepart( year, date) , datepart(month, date)
)
select top 1 *, (total_spend - prev_mont_spend ) as mom_growth
from
(
select *, LAG(total_spend,1) over (partition by card_type, exp_type order by yt, mt) as prev_mont_spend
from cte 
) A 
where prev_mont_spend is not null 
and yt = 2014 and mt = 1
order by mom_growth desc;


-- 8- during weekends which city has highest total spend to total no of transcations ratio 

select top 1 city, SUM(amount)*1.0 / COUNT(1) as ratio
from credit_card_transactions
where DATEPART(weekday, date) in (1,7) 
group by city
order by ratio desc;

-- 9- which city took least number of days to reach its 500th transaction after the first transaction in that city

with cte as
(
select *, ROW_NUMBER() over (partition by city order by date, transaction_id) as rn -- row_number using because there may be the possiblity that each city has multiple dates , i need 500th only
from credit_card_transactions       -- why I am using id because there is only numeric column which is running number 
) 
select top 1 city, DATEDIFF(DAY,MIN(date), max(date) ) as count_of_days -- top 1 because i need only 1 city with least number of days
from cte
where rn = 1 or rn= 500     -- rn = 1, 500 because i am interested in 2 rows only
group by city
having COUNT(1) = 2        -- count = 2 becuase i need those rows whose count is 2 
order by count_of_days ;





----------------------------------- End of Project -------------------------------------------------------------------
