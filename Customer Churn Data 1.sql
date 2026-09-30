-- Data Cleaning: 
-- Handling Missing Values and Outliers:
-- Impute mean for the following columns, and round off to the nearest integer if required: WarehouseToHome, HourSpendOnApp, OrderAmountHikeFromlastYear,DaySinceLastOrder.
select 
round(avg(WarehouseToHome)) as avg_wh,
round(avg(HourSpendOnApp)) as avg_ha,
round(avg(OrderAmountHikeFromlastYear)) as avg_oah,
round(avg(DaySinceLastOrder)) as avg_dslo
from customer_churn;

set sql_safe_updates =0;

update customer_churn
set 
  WarehouseToHome = coalesce(WarehouseToHome,'16'),
  HourSpendOnApp = coalesce(HourSpendOnApp,'3'),
  OrderAmountHikeFromlastYear = coalesce(OrderAmountHikeFromlastYear,'16'),
  DaySinceLastOrder = coalesce(DaySinceLastOrder,'5')
where
  WarehouseToHome is null or
  HourSpendOnApp is null or
  OrderAmountHikeFromlastYear is null or
  DaySinceLastOrder is null;

select * from customer_churn;

-- Impute mode for the following columns: Tenure, CouponUsed, OrderCount.
select Tenure, count(*) as tenure_mod from customer_churn
where Tenure is not null
group by Tenure
Order by  tenure_mod desc
limit 1;

select OrderCount, count(*) as order_mode from customer_churn
where OrderCount is not null
group by OrderCount
order by order_mode desc
limit 1;

select CouponUsed, count(*) as coupon_mode from customer_churn
where CouponUsed is not null
group by CouponUsed
order by coupon_mode desc
limit 1;

update customer_churn
set
Tenure=(coalesce(Tenure,1)),
OrderCount= (coalesce(OrderCount,2)),
CouponUsed = (coalesce(CouponUsed,1))
where
Tenure is  null 
or
OrderCount is  null 
or
CouponUsed is  null;

set sql_safe_updates=0;

-- Handle outliers in the 'WarehouseToHome' column by deleting rows where the values are greater than 100.
select * from customer_churn where WarehouseToHome>100;
delete from customer_churn where WarehouseToHome>100;

-- Dealing with Inconsistencies:
-- Replace occurrences of “Phone” in the 'PreferredLoginDevice' column and “Mobile” in the 'PreferedOrderCat' column with “Mobile Phone” to ensure uniformity.

update customer_churn
set
PreferredLoginDevice = case
when PreferredLoginDevice= 'Phone'
then 'Molbile Phone'
else PreferredLoginDevice
end,
PreferedOrderCat = case
when PreferedOrderCat= 'Mobile'
then 'Molbile Phone'
else PreferedOrderCat
end;

-- Standardize payment mode values: Replace "COD" with "Cash on Delivery" and "CC" with "Credit Card" in the PreferredPaymentMode column.
update customer_churn
set 
PreferredPaymentMode = case
when PreferredPaymentMode = 'COD'
then 'Cash on Delivery'
else PreferredPaymentMode
end,
PreferredPaymentMode = case
when PreferredPaymentMode = 'CC'
then 'Credit Card'
else PreferredPaymentMode
end;

-- Data Transformation: 
-- Column Renaming:
-- Rename the column "PreferedOrderCat" to "PreferredOrderCat".
alter table customer_churn
rename column PreferedOrderCat to PreferredOrderCat;

-- Rename the column "HourSpendOnApp" to "HoursSpentOnApp".
alter table customer_churn
rename column HourSpendOnApp to HoursSpentOnApp;

-- Creating New Columns:
-- Create a new column named ‘ComplaintReceived’ with values "Yes" if the corresponding value in the ‘Complain’ is 1, and "No" otherwise.
alter table customer_churn
add ComplaintReceived varchar(3);

Update customer_churn
set ComplaintReceived = if(Complain = 1, 'Yes', 'No');

select Complain from customer_churn;

-- Create a new column named 'ChurnStatus'. Set its value to “Churned” if the corresponding value in the 'Churn' column is 1, else assign “Active”.
alter table customer_churn
add column ChurnStatus varchar(20);

update customer_churn
set ChurnStatus = if(Churn=1, "Churned", "Active");

-- Column Dropping:
-- Drop the columns "Churn" and "Complain" from the table.
alter table customer_churn
drop column Churn,
drop column Complain;

-- Data Exploration and Analysis: 
-- Retrieve the count of churned and active customers from the dataset.
select * from customer_churn;
select ChurnStatus, count(*) as customer_count from customer_churn group by ChurnStatus;

-- Display the average tenure and total cashback amount of customers who churned.
select avg(Tenure) as avg_tenure, sum(CashbackAmount) as total_cashback_amount from customer_churn where ChurnStatus ="Churned";

-- Determine the percentage of churned customers who complained.
select (count(*) * 100/
(select count(*) from customer_churn where ChurnStatus ="Churned")) as complaint_percentage
from customer_churn where
ChurnStatus ="Churned" and 
ComplaintReceived = 'Yes';

-- Identify the city tier with the highest number of churned customers whose preferred order category is Laptop & Accessory.
select CityTier, count(*) as churned_customer_count from customer_churn
where ChurnStatus='Churned'
and PreferredOrderCat='Laptop & Accessory'
group by CityTier
order by churned_customer_count desc
limit 1;

-- Identify the most preferred payment mode among active customers.
select * from customer_churn;
select PreferredPaymentMode, count(*) as customer_count from customer_churn
where ChurnStatus='Active'
group by PreferredPaymentMode
order by customer_count desc
limit 1;

-- Calculate the total order amount hike from last year for customers who are single and prefer mobile phones for ordering.
select sum(OrderAmountHikeFromlastYear) as total_hike from customer_churn where MaritalStatus = 'Single' and PreferredOrderCat ='Mobile Phone';

-- Find the average number of devices registered among customers who used UPI as their preferred payment mode.
select * from customer_churn;
select avg(NumberOfDeviceRegistered) as avg_registered_devices from customer_churn where PreferredPaymentMode='UPI';

-- Determine the city tier with the highest number of customers.
select * from customer_churn;
select CityTier, count(*) as customer_count from customer_churn
group by CityTier order by customer_count desc 
limit 1;

-- Identify the gender that utilized the highest number of coupons.
select * from customer_churn;
select Gender, sum(CouponUsed) as coupon_used from customer_churn 
group by Gender 
order by coupon_used desc 
limit 1;

-- List the number of customers and the maximum hours spent on the app in each preferred order category.
select PreferredOrderCat, count(*) as number_of_customers, max(HoursSpentOnApp) as max_hours_spent
 from customer_churn group by PreferredOrderCat;

-- Calculate the total order count for customers who prefer using credit cards and have the maximum satisfaction score.
select * from customer_churn;
select PreferredPaymentMode, sum(OrderCount) as tot_order_count from customer_churn where PreferredPaymentMode='Credit Card'
and SatisfactionScore= (select max(SatisfactionScore) from customer_churn);

-- What is the average satisfaction score of customers who have complained?
select avg(SatisfactionScore) as avg_satisfaction_score from customer_churn where ComplaintReceived = 'Yes';

-- List the preferred order category among customers who used more than 5 coupons.
select * from customer_churn;
select PreferredOrderCat from customer_churn where CouponUsed>5 group by PreferredOrderCat ;

-- List the top 3 preferred order categories with the highest average cashback amount.
select PreferredOrderCat, avg(CashbackAmount) as avg_cashback from customer_churn
group by PreferredOrderCat order by avg_cashback desc
limit 3;

-- Find the preferred payment modes of customers whose average tenure is 10 months and have placed more than 500 orders.
select PreferredPaymentMode from customer_churn 
 group by PreferredPaymentMode
 having avg(Tenure)=10 and sum(OrderCount)>500;

-- Categorize customers based on their distance from the warehouse to home such as 'Very Close Distance' for distances <=5km, 'Close Distance' for <=10km,
-- Moderate Distance' for <=15km, and 'Far Distance' for >15km. Then, display the churn status breakdown for each distance category.
select * from customer_churn;
select CustomerID, WareHouseToHome,
case
when WareHouseToHome<=5 then 'Very Close Distance'
when WareHouseToHome<=10 then ' Close Distance'
when WareHouseToHome<=15 then ' Moderate Distance'
else 'Far Distance'
end as distance_category
from customer_churn;

-- List the customer’s order details who are married, live in City Tier-1, and their order counts are more than the average number of orders placed by all customers.
select * from customer_churn where MaritalStatus = 'Married' and CityTier = 1 and OrderCount>(select avg(OrderCount) from customer_churn);

-- a) Create a ‘customer_returns’ table in the ‘ecomm’ database and insert the following data:
create table customer_returns(
ReturnID int Primary Key,
CustomerID int,
ReturnDate date,
RefundAmount int);

insert into customer_returns (ReturnID, CustomerID, ReturnDate, RefundAmount) values 
(1001, 50022, '2023-01-01', 2130),
(1002, 50316, '2023-01-23', 2000),
(1003, 51099, '2023-02-14', 2290),
(1004, 52321, '2023-03-08', 2510),
(1005, 52928, '2023-03-20', 3000),
(1006, 53749, '2023-04-17', 1740),
(1007, 54206, '2023-04-21', 3250),
(1008, 54838, '2023-04-30', 1990);

select * from customer_returns;
-- b) Display the return details along with the customer details of those who have churned and have made complaints.
select cr.*,cc.* from customer_returns cr left join customer_churn cc 
on cr.CustomerID=cc.CustomerID
where ChurnStatus='Churned' and
ComplaintReceived = 'Yes';
