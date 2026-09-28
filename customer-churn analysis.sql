use ecomm;
show tables;
desc customer_churn;


SET SQL_SAFE_UPDATES =0;

/*
➢ Impute mean for the following columns, and round off to the nearest integer if
required: WarehouseToHome, HourSpendOnApp, OrderAmountHikeFromlastYear,
DaySinceLastOrder.

*/
with impute_mean as
(
select round(avg(WarehouseToHome)) as avg_dist,
round(avg(HourSpendOnApp)) as avg_hours,
round(avg(OrderAmountHikeFromlastYear)) as avg_amt,
round(avg(DaySinceLastOrder)) as avg_lastorder
from customer_churn 
)

update customer_churn
set
    WarehouseToHome = COALESCE(WarehouseToHome, (SELECT avg_dist FROM impute_mean)),
    HourSpendOnApp = COALESCE(HourSpendOnApp, (SELECT avg_hours FROM impute_mean)),
    OrderAmountHikeFromlastYear = COALESCE(OrderAmountHikeFromlastYear, (SELECT avg_amt FROM impute_mean)),
    DaySinceLastOrder = COALESCE(DaySinceLastOrder, (SELECT avg_lastorder FROM impute_mean)); 
    
/*
➢ Impute mode for the following columns: Tenure, CouponUsed, OrderCount
*/

UPDATE customer_churn
SET
    Tenure = (
        SELECT Tenure
        FROM (
            SELECT Tenure, COUNT(*) AS freq
            FROM customer_churn
            WHERE Tenure IS NOT NULL
            GROUP BY Tenure
            ORDER BY freq DESC
            LIMIT 1
        ) AS t1
    ),

    CouponUsed = (
        SELECT CouponUsed
        FROM (
            SELECT CouponUsed, COUNT(*) AS freq
            FROM customer_churn
            WHERE CouponUsed IS NOT NULL
            GROUP BY CouponUsed
            ORDER BY freq DESC
            LIMIT 1
        ) AS t2
    ),

    OrderCount = (
        SELECT OrderCount
        FROM (
            SELECT OrderCount, COUNT(*) AS freq
            FROM customer_churn
            WHERE OrderCount IS NOT NULL
            GROUP BY OrderCount
            ORDER BY freq DESC
            LIMIT 1
        ) AS t3
    )
WHERE Tenure IS NULL
   OR CouponUsed IS NULL
   OR OrderCount IS NULL;

/*
Handle outliers in the 'WarehouseToHome' column by deleting rows where the
values are greater than 100
*/
delete from customer_churn where WarehouseToHome > 100;

/*Replace occurrences of “Phone” in the 'PreferredLoginDevice' column and “Mobile” in the 'PreferedOrderCat' column with “Mobile Phone” to ensure 
uniformity.*/

update customer_churn set PreferredLoginDevice='Mobile Phone' where PreferredLoginDevice='Phone';
update customer_churn set PreferedOrderCat='Mobile Phone' where PreferedOrderCat='Mobile';

/*Standardize payment mode values: Replace "COD" with "Cash on Delivery" and "CC" with "Credit Card" in the PreferredPaymentMode column.*/

update customer_churn set PreferredPaymentMode='Cash on Delivery' where PreferredPaymentMode='COD';
update customer_churn set PreferredPaymentMode='Credit Card' where PreferredPaymentMode='CC';


# ===============================================================================
# ============================ DATA TRANSFORMATION ==============================
# ===============================================================================

/*
Column Renaming: 
➢ Rename the column "PreferedOrderCat" to "PreferredOrderCat". 
➢ Rename the column "HourSpendOnApp" to "HoursSpentOnApp".
*/
alter table customer_churn 
rename column PreferedOrderCat to PreferredOrderCat , 
rename column HourSpendOnApp to HoursSpendOnApp;

/*
Creating New Columns: 
➢ Create a new column named ‘ComplaintReceived’ with values "Yes" if the 
corresponding value in the ‘Complain’ is 1, and "No" otherwise. 
➢ Create a new column named 'ChurnStatus'. Set its value to “Churned” if the 
corresponding value in the 'Churn' column is 1, else assign “Active”.
*/
alter table customer_churn add column ComplaintReceived varchar(20);
update customer_churn set ComplaintReceived =
case when Complain = 1 then 'Yes' else 'No' 
end;

alter table customer_churn add column ChurnStatus varchar(20);
update customer_churn  set ChurnStatus =
case when Churn=1 then 'Churned'else 'Active'
end;

/*
Column Dropping: 
➢ Drop the columns "Churn" and "Complain" from the table.
*/
alter table customer_churn drop column Churn,drop column Complain; 


# ================================================================================
# ========================= DATA EXPLORATION AND ANALYSIS ========================
# ================================================================================

/*Retrieve the count of churned and active customers from the dataset.*/
select count(CustomerID), ChurnStatus from customer_churn group by ChurnStatus;

/*Display the average tenure and total cashback amount of customers who churned.*/
select avg(tenure) , sum(CashbackAmount) from customer_churn where ChurnStatus = 'Churned';

/*Determine the percentage of churned customers who complained. */

select count(case when ComplaintReceived = 'Yes' then 1 end) * 100.0 / count(*) as complaint_percentage
from customer_churn
where ChurnStatus = 'Churned';

# OR 

with churned as (
select  CustomerID, ComplaintReceived from customer_churn where ChurnStatus = 'Churned'
),
 complain_churned as(
select count(CustomerID) as churned_complaint from churned where ComplaintReceived = 'Yes'
)
select churned_complaint * 100  /  (SELECT COUNT(*) FROM churned) as complaint_percentage
 from complain_churned;

/*Identify the city tier with the highest number of churned customers whose 
preferred order category is Laptop & Accessory.*/

select count(CustomerID) as cust_count, CityTier
 from customer_churn
 where PreferredOrderCat = 'Laptop & Accessory' AND ChurnStatus = 'Churned'
 group by CityTier 
 order by cust_count desc
 limit 1;

/*Identify the most preferred payment mode among active customers.*/
desc customer_churn;
select count(CustomerID) as paymentmode_count, PreferredPaymentMode
from customer_churn
where ChurnStatus = 'Active'
group by PreferredPaymentMode
order by paymentmode_count desc
limit 1;

/*Calculate the total order amount hike from last year for customers who are single 
and prefer mobile phones for ordering.*/

select sum(OrderAmountHikeFromlastyear) as Total_Amt_Hike
from customer_churn 
where MaritalStatus = 'Single' and PreferredOrderCat ='Mobile Phone';
 
 
/*Find the average number of devices registered among customers who used UPI as 
their preferred payment mode.*/

select avg(NumberOfDeviceRegistered) as avg_devices 
from customer_churn where PreferredPaymentMode='UPI';

/*Determine the city tier with the highest number of customers.*/
select CityTier,count(*) as total_customers 
from customer_churn
 group by CityTier
 order by customernumber desc limit 1;


/*Identify the gender that utilized the highest number of coupons.*/
select Gender,count(CouponUsed) as couponnumber
from customer_churn 
group by Gender 
order by couponnumber desc limit 1;


/*List the number of customers and the maximum hours spent on the app in each 
preferred order category.*/
select PreferredOrderCat,count(*) as customernumber,max(HoursSpentOnApp) as maxhours 
from customer_churn group by PreferredOrderCat;


/*Calculate the total order count for customers who prefer using credit cards and 
have the maximum satisfaction score.*/

select count(OrderCount) as totalcount 
from customer_churn 
where PreferredPaymentMode='Credit Card'
AND SatisfactionScore = (select max(SatisfactionScore) from customer_churn);


/*What is the average satisfaction score of customers who have complained?*/
select avg(SatisfactionScore) as avgscore from customer_churn where ComplaintReceived='Yes';

/*List the preferred order category among customers who used more than 5 coupons.*/
select PreferredOrderCat from customer_churn where CouponUsed >= 5;


/*List the top 3 preferred order categories with the highest average cashback amount. */
select PreferredOrderCat,avg(CashbackAmount) as avgcashback from customer_churn 
group by PreferredOrderCat order by avgcashback desc limit 3;

select PreferredPaymentMode from customer_churn group by PreferredPaymentMode having avg(tenure)=10 and sum(OrderCount)>500;

/*Categorize customers based on their distance from the warehouse to home such 
as 'Very Close Distance' for distances <=5km, 'Close Distance' for <=10km, 
'Moderate Distance' for <=15km, and 'Far Distance' for >15km. Then, display the 
churn status breakdown for each distance category. */
select case
when WarehouseTohome<=5 then 'Very Close Distance'
when WarehouseTohome<=10 then 'Close Distance'
when WarehouseTohome<=15 then 'Moderate Distance'
else 'Far Distance'
end as distance_status,
ChurnStatus, count(*) as totalcustomers
from customer_churn group by distance_status , ChurnStatus
order by distance_status ;

/*List the customer’s order details who are married, live in City Tier-1, and their 
order counts are more than the average number of orders placed by all 
customers.*/

select CustomerID,MaritalStatus,CityTier,OrderCount 
from customer_churn 
where MaritalStatus='Married' and CityTier=1 
and OrderCount>(select avg(OrderCount) from customer_churn);

/* a) Create a ‘customer_returns’ table in the ‘ecomm’ database and insert the 
following data:*/
create table customer_returns( 
ReturnID INT PRIMARY KEY,
CustomerID INT,
ReturnDate DATE,
RefundAmount DECIMAL(10, 2)
);
insert into customer_returns (ReturnID, CustomerID, ReturnDate, RefundAmount) values
(1001, 50022, '2023-01-01', 2130),
(1002, 50316, '2023-01-23', 2000),
(1003, 51099, '2023-02-14', 2290),
(1004, 52321, '2023-03-08', 2510),
(1005, 52928, '2023-03-20', 3000),
(1006, 53749, '2023-04-17', 1740),
(1007, 54206, '2023-04-21', 3250),
(1008, 54838, '2023-04-30', 1990);

/*Display the return details along with the customer details of those who have 
churned and have made complaints. */

select c.*,d.*
from customer_returns cr
join customer_churn cc
on cr.CustomerID=cc.CustomerID
where cc.ChurnStatus='Churned' and cc.ComplaintReceived='Yes';
