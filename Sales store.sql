-- Data cleaning
-- Step1: checking for duplicates, correcting column names and removing empty rows in Excel

-- database creation and table import through Table Data Import Wizard
create database sales_store;
use sales_store; 
select * from sales;

-- Step2: fixing the date format
set sql_safe_updates=0;
update sales
set purchase_date = replace(purchase_date, '/', '-');
update sales
set purchase_date= str_to_date(purchase_date,'%d-%m-%Y');

-- creating  a copy of the actual table
create table sales2 as
select * from sales;

-- Step3: checking datatypes
select column_name, data_type
from information_schema.columns
where table_name='sales';

-- Step4: checking for NULL values
select 
    sum(if(transaction_id is null, 1, 0)) as transaction_id_nulls,
    sum(if(customer_id is null, 1, 0)) as customer_id_nulls,
    sum(if(customer_name is null, 1, 0)) as customer_name_nulls,
    sum(if(customer_age is null, 1, 0)) as customer_age_nulls,
    sum(if(gender is null, 1, 0)) as gender_nulls,
    sum(if(product_id is null, 1, 0)) as product_id_nulls,
    sum(if(product_name is null, 1, 0)) as product_name_nulls,
    sum(if(product_category is null, 1, 0)) as product_category_nulls,
    sum(if(quantity is null, 1, 0)) as quantity_nulls,
    sum(if(price is null, 1, 0)) as price_nulls,
    sum(if(payment_mode is null, 1, 0)) as payment_mode_nulls,
    sum(if(purchase_date is null, 1, 0)) as purchase_date_nulls,
    sum(if(time_of_purchase is null, 1, 0)) as time_of_purchase_nulls,
    sum(if(`status` is null, 1, 0)) as status_nulls
from sales;

-- Step5: treating null values
select * from sales 
where customer_id is null or
customer_name is null or
customer_age is null or
gender is null;

select * from sales
where customer_id='CUST1003';
update sales
set customer_name='Mahika Saini',
customer_age=35, gender='Male'
where transaction_id='TXN432798';

select * from sales
where customer_name='Ehsaan Ram';
update sales
set customer_id='CUST9494'
where transaction_id='TXN977900';

select * from sales
where customer_name='Damini Raju';
update sales
set customer_id='CUST1401'
where transaction_id='TXN985663';

-- Step6: data cleaning
select distinct gender -- gender
from sales;
update sales
set gender='F'
where gender='Female';

update sales
set gender='M'
where gender='Male';

select distinct payment_mode -- payment mode
from sales;
update sales
set payment_mode='Credit Card'
where payment_mode='CC';


-- DATA ANALYSIS --

-- 1. What are the top 5 most selling products by quantity?

select product_name, sum(quantity) as Total_Qty_sold
from sales 
where status='delivered'
group by product_name
order by Total_Qty_sold desc
limit 5;

-- Business problem solved: We do not know which products are most in demand.

-- Business Impact: Helps prioritize stock and boost sales through targeted promotions.

-- 2. Which products are most frequently cancelled?

select product_name, count(*) as Pdcts_cancelled
from sales 
where status='cancelled'
group by product_name
order by Pdcts_cancelled desc
limit 5;

-- Business problem solved: Frequent cancellations affect revenue and customer trust.

-- Business Impact: Identify poor-performing products to improve quality or remove from catalogue.

-- 3. What time of the day has the highest number of purchases?

select
case
when hour(time_of_purchase) between 0 and 5 then 'Night'
when hour(time_of_purchase)  between 6 and 11 then 'Morning'
when hour(time_of_purchase)  between 12 and 17 then 'Afternoon'
when hour(time_of_purchase)  between 18 and 23 then 'Evening'
end as time_of_day,
count(*) as total_order
from sales 
group by time_of_day
order by total_order desc;

-- Business problem solved: Find peak sales times.
 
-- Business Impact: Optimise staffing, promotions and server loads.
 
-- 4. Who are the highest spending customers?
 
select customer_name, concat('₹ ',format(sum(quantity*price),0)) as Money_spent
from sales 
group by customer_name
order by sum(quantity*price) desc
limit 5;
 
-- Business problem solved: Identify VIP customers.

-- Business Impact: Personalised offers, loyalty rewards and retention.

-- 5. Which product category generates the highest revenue?

select product_category, concat('₹ ',format(sum(quantity*price),0)) as Total_revenue
from sales
group by product_category
order by sum(quantity*price) desc;

-- Business problem solved: Identify top performing product categories.

/* Business Impact: Refine product strategy, supply chain and promotions,
allowing the business to invest more in high-margin or high-demand categories.*/

-- 6. What is the return/cancellation rate per category?

-- Cancellation
select product_category, concat(round(count(if(status='cancelled',1,null))*100/count(*),2),' %') as Cancelletion_rate
from sales 
group by product_category
order by count(if(status='cancelled',1,null))*100/count(*) desc;

-- Return
select product_category, concat(round(count(if(status='returned',1,null))*100/count(*),2),' %') as Return_rate
from sales 
group by product_category
order by count(if(status='returned',1,null))*100/count(*) desc;

-- Business problem solved: Monitor dissatisfaction trends per category.

/* Business Impact: Reduce returns, improve product descriptions/expectations.
Helps identify and fix product or logistics issues.*/

-- 7. What is the most preferred payment mode?

select payment_mode, count(*) as Total_count
from sales
group by payment_mode
order by Total_count desc;

-- Business problem solved: Know which payment options customers prefer.

-- Business Impact: Streamline payment processing, prioritise popular modes.

-- 8. How does the age group affect purchasing behavior?

select min(customer_age), max(customer_age)
from sales;

with age_buckets as 
(select case
when customer_age between 18 and 25 then '18-25'
when customer_age between 26 and 35 then '26-35'
when customer_age between 36 and 50 then '36-50'
else '51+'
end as Ages,
(quantity*price) as amount
from sales)
select Ages, concat('₹ ', format(sum(amount), 0)) as Total_Purchase
from age_buckets
group by Ages
order by sum(amount) desc;

-- Business problem solved: Understand the customer demographics.

-- Business Impact: Targeted marketing and product recommendations by age group.

-- 9. What is the monthly sales trend?

select year(purchase_date) as Years, month(purchase_date) as Months,
concat('₹ ', format(sum(quantity*price), 0)) as Total_Purchase
from sales 
group by year(purchase_date), month(purchase_date)
order by year(purchase_date), month(purchase_date);

-- Business problem solved: Sales fluctuations go unnoticed.

-- Business Impact: Plan inventory and marketing according to seasonal trends. 

-- 10. Are certain genders buying more specific product categories?

select product_category, count(if(gender = 'F', 1, null)) as female_buyers,
count(if(gender = 'M', 1, null)) as male_buyers
from sales
group by product_category
order by product_category;

-- Business problem solved: Gender-based product preferences.

-- Business Impact: Personalised ads, gender-focused campaigns.



























 






