-- Creating database with name Grocery 

create database if not exists grocery;

use grocery;

-- Creating all seven tables

create table product_details(item_num int(4) primary key,
							description varchar(30),
                            cost decimal(5,2) not null,
                            unit_code smallint not null,
                            product_cat_code smallint not null,
                            location char(3) not null);
                            

create table vendor(vendor_code smallint primary key references purchases(vendor_code),
					vendor_name varchar(100) not null
                    );

create table unit(unit_code smallint primary key references product_details(unit_code),
				unit varchar(20) not null);
                
create table product_cat(product_cat_code smallint primary key 
									references product_details(product_cat_code),
						category varchar(20)
                        );
                        
create table purchases(item_num int(4) references product_details(item_num),
					updated_quantity int(3) not null,
                    purchase_date date not null,
                    vendor_code smallint not null
                    );
                    
CREATE TABLE sales (
    item_num INT(4) not null REFERENCES product_details(item_num),
    cust INT(6) NOT NULL,
    price DECIMAL(5,2) NOT NULL,
    date_sold DATE,
    quantity INT(3) NOT NULL
);


create table inventory(item_num int(4) primary key references product_details(item_num),
						quantity_in_hand int(3) not null default 0
                        );
                        
-- renaming updated_quanity column of purchases to quanitiy_purchased

alter table purchases
rename column updated_quantity to quantity_purchased;

-- Inserting Data

insert into vendor values(1,'Bennet Farms, Rt. 17 Evansville, IL 55446');
insert into vendor values(2,'Freshness, Inc., 202 E. Maple St., St. Joseph, MO 45678');
insert into vendor values(3,'Ruby Redd Produce, LLC, 1212 Milam St., Kenosha, AL, 34567');


insert into unit values(1,'Dozen');
insert into unit values(2,'Bunch');
insert into unit values(3,'12 ounce can');
insert into unit values(4,'12 oz can');
insert into unit values(5,'36 oz can');



insert into product_cat values(1, 'Dairy'),(2, 'Produce'),(3, 'Canned');




insert into purchases values(1000,29,'2022-2-1',1),
							(1100,53,'2022-2-2',2),
                            (1222,59,'2022-2-10',2),
                            (1223,12,'2022-2-10',2),
                            (1224,31,'2022-2-10',2),
                            (2000,28,'2022-2-12',3),
                            (2001,20,'2022-2-12',3),
                            (1223,17,'2022-2-15',2);
 
 
insert into product_details values(1000,'Bennet Farm free-range eggs',2.35,1,1,'D12'),
						(2000,'Ruby"s Kale',1.29,2,2,'P12'),
                        (1100,'Freshness White beans',0.69,4,3,'A2'),
                        (1222,'Freshness Green beans',0.59,4,3,'A3'),
						(1223,'Freshness Green beans',1.75,3,3,'A7'),
                        (1224,'Freshness Wax beans',0.65,3,3,'A3'),
                        (2001,'Ruby"s Organic Kale',2.19,2,2,'P02');

insert into sales values(1000,198765,5.49,'2022-02-02',2),
(1100,202900,1.49,'2022-02-02',2),
(1000,196777,5.99,'2022-02-04-',2),
(1100,198765,1.49,'2022-02-07',8),
(1000,277177,5.49,'2022-02-11',4),
(1222,111000,1.29,'2022-02-12',12),
(1223,198765,3.49,'2022-02-13',5),
(2001,100988,6.99,'2022-02-13',1),
(2001,202900,6.99,'2022-02-14',12),
(2000,111000,3.99,'2022-02-15',2)
;


insert into inventory values(1000,29),
(2000,3),
(1100,13),
(1222,59),
(1223,12),
(1224,31),
(2001,20)
;


-- Creating trigger of updating quantity whenever a purchase is made

DELIMITER $$

CREATE TRIGGER update_inventory_after_purchase
AFTER INSERT ON purchases
FOR EACH ROW
BEGIN
    UPDATE inventory
    SET quantity_in_hand = quantity_in_hand + NEW.quantity_purchased
    WHERE item_num = NEW.item_num;
END$$

DELIMITER ;


-- Creating trigger of updating quantity whenever a sale is made

DELIMITER $$

CREATE TRIGGER update_inventory_after_sale
AFTER INSERT ON sales
FOR EACH ROW
BEGIN
    UPDATE inventory
    SET quantity_in_hand = quantity_in_hand - NEW.quantity
    WHERE item_num = NEW.item_num;
END$$

DELIMITER ;


-- checking triggers are working or not 

select * from inventory where item_num=1000;

-- Currently there are 29 units of item_num 1000

-- Now we will insert a record in purchases 
-- which will increase the quanitity_in_hand in inventory table

insert into purchases values(1000,21,'2022-02-20',1);


select * from inventory where item_num=1000;

-- Quanity in inventory table gets incremented by purchased quanity.
-- Puchases trigger is working

-- Now for sales trigger

insert into sales values(1000,198765,5.49,'2022-02-20',21);


select * from inventory where item_num=1000;

-- Quanity in inventory table gets decreased by sold quanity.
-- Sales trigger is working

-- Now for simple queries

-- Which is the top 5 most selling product

select item_num,sum(quantity)
from sales
group by 1
order by 2 desc
limit 5; 

-- Most profitable products, their total quanity sold and average profit per quantity

select s.item_num,sum((quantity*price)-(cost*quantity)) as profit,
	sum(quantity) as total_quantity_sold,
    sum((quantity*price)-(cost*quantity))/sum(quantity) as avg_profit_per_quantity
from sales s
join product_details p
on s.item_num=p.item_num
group by 1;

-- Total Sales by Amount and Quantity of Each Product Category

select category,sum(price*quantity)  as sales,sum(quantity) as total_quantity_sold
from sales s
join product_details p
on s.item_num=p.item_num
join product_cat c
on p.product_cat_code=c.product_cat_code
group by 1;

-- Dairy products has most sales with $160.21 and total 29 units sold

-- Most Purchased Items and its total cost incurred

select p.item_num,sum(quantity_purchased) as total_units_purchased,
	sum(quantity_purchased)*cost as total_cost_incurred
from purchases p
join product_details pd
on p.item_num=pd.item_num
group by 1
order by 3 desc;

-- By quanity,item_num 1000 is ordered most.
-- By cost incurred, item_num 1100 is ordered most

-- We had made most purchases with which vendors?
select p.vendor_code,vendor_name,count(*) as number_of_purchase_orders
from purchases p
join vendor v
on v.vendor_code=p.vendor_code
group by 1,2
order by 3 desc;

-- We had made most (total 5) orders from Freshness Inc. with vendor_code is 2.


-- End of Project  -- 