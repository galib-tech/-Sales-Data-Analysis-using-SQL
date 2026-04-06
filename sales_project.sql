create database sales_project;

set sql_safe_updates= 0 ;

update calendar
set date = str_to_date(date, '%m/%d/%Y');

alter table calendar 
modify column date date ;

update customer_lookup 
set BirthDate = str_to_date(BirthDate, '%m/%d/%Y');

alter table customer_lookup
modify column BirthDate date ;

update fact_sales_data
set OrderDate = str_to_date(OrderDate, '%m/%d/%Y');

alter table fact_sales_data
modify column OrderDate date ;

update fact_sales_data
set StockDate = str_to_date(StockDate, '%m/%d/%Y');

alter table fact_sales_data
modify column StockDate date;

alter table returns_data
modify column ReturnDate date;

-- 1. Retrieve all sales records.
select * from fact_sales_data;

-- 2. Get all distinct product names.

select distinct ProductName from product;

-- 3. Find all orders placed on a specific date.

select * from fact_sales_data
where OrderDate = '2020-01-02' ;

-- 4. Retrieve all customers from a specific city.
select * from customer_lookup
where HomeOwner = 'Y';

-- 5. Find customers with a specific occupation.

select * from customer_lookup
where Occupation = 'Skilled Manual';

-- 6. Count total number of products.

select count(ProductKey) from product ;

-- 7. Find the total number of orders.

select count(*) total_orders from fact_sales_data;

-- 8. Show products that cost more than $50.

select * from product 
where ProductPrice < 50 ;

-- 9. Find customers who earn more than $75,000 annually.

select * from customer_lookup 
where AnnualIncome > 75000 ;

--  10. Show customers born before 1980.

select * from customer_lookup
where year(BirthDate) < '1980';

-- 11. Find the oldest customer.

select * from customer_lookup
order by BirthDate asc
limit 1 ;

-- 12. Get the most recent sales order

select * from fact_sales_data
order by OrderDate desc
limit 1;

-- 13. Find the highest-priced product.

select * from product
order by ProductPrice desc
limit 1; 

-- 14. Find the number of products in each category.

select pc.CategoryName, 
       count(p.ProductKey) total_product
from product p join product_subcategories ps 
on p.ProductSubcategoryKey = ps.ProductSubcategoryKey
join product_categories pc
on pc.ProductCategoryKey = ps.ProductCategoryKey
group by pc.CategoryName
order by total_product desc;


-- 15.	Get all products with their categories
select 
      p.ProductName,
      pc.CategoryName
from product as p
join product_subcategories as ps on p.ProductSubcategoryKey = ps.ProductSubcategoryKey
join product_categories as pc on ps.ProductCategoryKey = pc.ProductCategoryKey;




-- 16.	Show total sales revenue per region.
select 
      t.region,
      round(sum(s.OrderQuantity * p.ProductPrice),1) as totalrevene
from fact_sales_data as s
join product as p on s.ProductKey = p.ProductKey
join territory as t on s.TerritoryKey = t.SalesTerritoryKey
group by  t.region;



-- 17.	Find total sales quantity per product.
select p.ProductName,
       sum(s.OrderQuantity) as totalquantity
from fact_sales_data as s
join product as p on s.ProductKey = p.ProductKey
group by p.ProductName
order by totalquantity desc;



-- 18.	Get total revenue per product category.
select 
	  pc.CategoryName,
      round(sum(s.OrderQuantity * p.ProductPrice),2) as totalrevenue
from fact_sales_data as s
join product as p on s.ProductKey = p.ProductKey
join product_subcategories as ps on p.ProductSubcategoryKey = ps.ProductSubcategoryKey
join product_categories as pc on ps.ProductCategoryKey = pc.ProductCategoryKey
group by pc.CategoryName
order by totalrevenue desc;




-- 19.	Find customers who have spent the most.
select 
      c.Full_name,
      sum(s.OrderQuantity) as totalpurchased
from fact_sales_data as s
join customer as c on s.CustomerKey = c.CustomerKey
group by c.Full_name
order by totalpurchased desc;




-- 20.	Get total orders by region.
select t.region,
       count(s.OrderNumber) as totalorders
from fact_sales_data as s
join territory as t on s.TerritoryKey = t.SalesTerritoryKey
group by t.region
order by totalorders desc;



-- 21.	Find products that have been returned
select 
      p.ProductName,
      sum(r.ReturnQuantity) as totalreturns
from returns_data as r
join product as p on r.ProductKey = p.ProductKey
group by p.ProductName
order by totalreturns desc;



-- 22.	Find sales trends over time
select 
      month(s.OrderDate) as months,
      monthname(s.OrderDate) as month_name,
      sum(s.OrderQuantity) as totalquantity
from fact_sales_data as s
group by months,month_name
order by totalquantity desc;



-- 23.	Find the most popular product in each category
select 
      pc.CategoryName,
      p.ProductName,
      sum(s.OrderQuantity) as total_sold
from fact_sales_data as s
join product as p on s.ProductKey = p.ProductKey
join product_subcategories as ps on p.ProductSubcategoryKey = ps.ProductSubcategoryKey
join product_categories as pc on ps.ProductCategoryKey = pc.ProductCategoryKey
group by pc.CategoryName,p.ProductName
order by total_sold desc;



-- 24.	Find top 5 highest revenue-generating products
select 
      p.ProductName,
      round(sum(s.OrderQuantity * p.ProductPrice),2) as revenue
from fact_sales_data as s
join product as p on s.ProductKey = p.ProductKey
group by p.ProductName
order by revenue desc
limit 5;


-- 25.	Find percentage of returned products
select 
      (sum(r.ReturnQuantity) / sum(s.OrderQuantity)) * 100 as returnpercentage
from fact_sales_data as s
join returns_data as r on r.ProductKey = s.ProductKey;

-- 26. Find repeat customers

select cl.CustomerKey, count(distinct fsd.OrderNumber) total_order 
from customer_lookup cl join fact_sales_data fsd
on cl.CustomerKey = fsd.CustomerKey
group by cl.CustomerKey
having total_order > 1 
order by total_order desc;

-- 27. Rank products by sales in each category

with a as (
select pc.CategoryName,p.ProductName, round(sum(f.OrderQuantity * p.ProductPrice),2) as total_sales
from fact_sales_data f join product p
on f.ProductKey = p.ProductKey
join product_subcategories ps
on p.ProductSubcategoryKey = ps.ProductSubcategoryKey
join product_categories pc 
on ps.ProductCategoryKey = pc.ProductCategoryKey
group by pc.CategoryName, p.ProductName
)

select *, rank() over(partition by CategoryName order by total_sales desc) rnk from a ;

-- 28. Rank products by total revenue using RANK()
with a as (
select p.ProductName,p.ProductKey, round(sum(f.OrderQuantity * p.ProductPrice),2) revenue
from product p join fact_sales_data f
on p.ProductKey = f.ProductKey
group by p.ProductName,p.ProductKey 
)
select *, rank() over(order by revenue desc) rnk from a ;

-- 29. Find monthly total sales quantity

select year(OrderDate) year, month(OrderDate) month, sum(OrderQuantity) total_sales 
from fact_sales_data 
group by year(OrderDate) , month(OrderDate)
order by year ,month  ;

-- 30. Get top 3 products by sales in 2020

with a as ( 
select year(OrderDate) year, p.ProductName, sum(f.OrderQuantity) total_sales 
from product p join fact_sales_data f 
on p.ProductKey = f.ProductKey
where year(OrderDate) = 2022
group by year(OrderDate), p.ProductName 
   ),
b as (
select *, row_number() over(order by total_sales desc) rnk
from a)
select * from b 
where rnk <= 3 ;
