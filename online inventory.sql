CREATE TABLE CATEGORIES(
    CATEGORY_ID NUMBER PRIMARY KEY,
    CATEGORY_NAME VARCHAR2(100)
);

INSERT INTO CATEGORIES VALUES (1, 'Electronics');
INSERT INTO CATEGORIES VALUES (2, 'Apparel');
INSERT INTO CATEGORIES VALUES (3, 'Home & Kitchen');
INSERT INTO CATEGORIES VALUES (4, 'Books');



CREATE TABLE SUPPLIERS(
    SUPPLIER_ID NUMBER PRIMARY KEY,
    SUPPLIER_NAME VARCHAR2(340)
);
INSERT INTO SUPPLIERS VALUES (101, 'Global Tech Distributors');
INSERT INTO SUPPLIERS VALUES (102, 'Apex Apparels Ltd.');
INSERT INTO SUPPLIERS VALUES (103, 'HomeComfort Solutions');
INSERT INTO SUPPLIERS VALUES (104, 'ReadWell Publications');

CREATE TABLE PRODUCTS(

    PRODUCT_ID NUMBER PRIMARY KEY,
    PRODUCT_NAME VARCHAR2(300),
    CATEGORY_ID NUMBER,
    SUPPLIER_ID NUMBER,
    PRICE NUMBER,
    CONSTRAINT FK_CAT FOREIGN KEY (CATEGORY_ID) REFERENCES CATEGORIES(CATEGORY_ID),
    CONSTRAINT FK_SUP FOREIGN KEY (SUPPLIER_ID) REFERENCES SUPPLIERS(SUPPLIER_ID)
);

INSERT INTO PRODUCTS VALUES (1001, 'Wireless Mouse', 1, 101, 750);
INSERT INTO PRODUCTS VALUES (1002, 'Mechanical Keyboard', 1, 101, 2500);
INSERT INTO PRODUCTS VALUES (1003, 'Bluetooth Speaker', 1, 101, 1800);
INSERT INTO PRODUCTS VALUES (1004, 'Cotton Casual Shirt', 2, 102, 1200);
INSERT INTO PRODUCTS VALUES (1005, 'Slim Fit Jeans', 2, 102, 2100);
INSERT INTO PRODUCTS VALUES (1006, 'Stainless Steel Water Bottle', 3, 103, 650);
INSERT INTO PRODUCTS VALUES (1007, 'Non-Stick Frying Pan', 3, 103, 1400);

INSERT INTO PRODUCTS VALUES (1008, 'Oracle SQL & PL/SQL Handbook', 4, 104, 850);
INSERT INTO PRODUCTS VALUES (1009, 'Data Structures Made Easy', 4, 104, 950);

CREATE TABLE STOCK(
    STOCK_ID NUMBER PRIMARY KEY,
    PRODUCT_ID NUMBER,
    QUANTITY NUMBER,
    CONSTRAINT FK_PROD FOREIGN KEY (PRODUCT_ID) REFERENCES PRODUCTS(PRODUCT_ID)

);
INSERT INTO STOCK VALUES (501, 1001, 150); 
INSERT INTO STOCK VALUES (502, 1002, 45);
INSERT INTO STOCK VALUES (503, 1003, 80);  
INSERT INTO STOCK VALUES (504, 1004, 12); 
INSERT INTO STOCK VALUES (505, 1005, 200);
INSERT INTO STOCK VALUES (506, 1006, 5);   
INSERT INTO STOCK VALUES (507, 1007, 0);  
INSERT INTO STOCK VALUES (508, 1008, 90);
INSERT INTO STOCK VALUES (509, 1009, 30);

select * from products;
select * from stock;
select * from suppliers;
select * from categories;
--product with category & supplier
select p.product_name,c.category_name,s.supplier_name,p.price from products p
join categories c on p.category_id = c.category_id
join suppliers s on p.supplier_id = s.supplier_id;

--checking the stock
select p.product_name,s.quantity from products p
join stock s on p.product_id = s.product_id;

--checking the low stock
select p.product_name,s.quantity from products p
join stock s on p.product_id = s.product_id 
where s.quantity<20;

--total invertory values 
select sum(p.price * s.quantity) as tot_value
from products p
join stock s on p.product_id = s.product_id;

--total product per category
select c.category_name,count(p.product_id) as tot_product
from products p
join categories c on p.category_id = c.category_id
group by c.category_name;

--total stock per product
select p.product_name,sum(s.quantity) as tot_stock from products p
join stock s on p.product_id = s.product_id
group by p.product_name;

--category with more than 1 product
select c.category_name,count(*) from products p
join categories c on c.category_id = p.category_id
group by c.category_name
having count(*)>2;

--product above avg price
select * from products where price>(select avg(price)from products);

--product with low stock less avg stock
select p.product_name,s.quantity from products p
join stock s on p.product_id = s.product_id
where s.quantity<(select avg(quantity)from stock);

 SELECT p.PRODUCT_ID, p.PRODUCT_NAME, c.CATEGORY_NAME, s.SUPPLIER_NAME, p.PRICE
FROM PRODUCTS p
JOIN CATEGORIES c ON p.CATEGORY_ID = c.CATEGORY_ID
JOIN SUPPLIERS  s ON p.SUPPLIER_ID = s.SUPPLIER_ID
ORDER BY c.CATEGORY_NAME, p.PRODUCT_NAME; 

select c.category_name,count(p.product_id)as tot_product from categories c
left join products p on c.category_id = p.category_id
group by c.category_name
order by tot_product DESC;

--stock and risk analysis
select p.product_name,s.quantity,
    case
        when s.quantity = 0 then 'OUT OF STOCK'
        when s.quantity < 10 then 'CRITICAL'
        when s.quantity < 20 then 'LOW STOCK'
    end as stock_status
from stock s
join products p on s.product_id = p.product_id
where s.quantity<20
order by s.quantity;
 
 SELECT DISTINCT sup.SUPPLIER_NAME, p.PRODUCT_NAME, st.QUANTITY
FROM STOCK st
JOIN PRODUCTS  p   ON st.PRODUCT_ID  = p.PRODUCT_ID
JOIN SUPPLIERS sup ON p.SUPPLIER_ID  = sup.SUPPLIER_ID
WHERE st.QUANTITY < 20
ORDER BY st.QUANTITY;

select s.supplier_name,count(p.product_id) as product_supp,
                        sum(s.quantity) as tot_units,
                        sum(p.price * s.quantity) as stock_value
from suppliers s
join products p on s.supplier_id = p.supplier_id
join stock s on p.product_id = s.product_id
group by s.supplier_name
order by stock_value DESC;

--price review
select p.product_name,c.category_name,p.price,
round(avg(p.price)over (partition by c.category_name),2) as category_avg
from products p
join categories c on p.category_id = p.category_id
order by c.category_name,p.price DESC;

--top 3 valuable product in stock
select product_name,stock_value from (select p.product_name,p.price * s.quantity as stock_value,
rank()over(order by p.price * s.quantity DESC)as rank from products p
join stock s on p.product_id = s.product_id)
where rank<=3;

--valuable product with each category
select product_name,category_name,stock_value from (select c.category_name,p.product_name,
p.price * s.quantity as stock_value,
row_number()over(partition by c.category_name
order by p.price * s.quantity DESC)as RN from products p
join categories c on p.category_id = c.category_id
join stock s on p.product_id = s.product_id)
where RN=1;


CREATE OR REPLACE VIEW VW_INVENTORY_DASHBOARD AS
SELECT p.PRODUCT_ID,
       p.PRODUCT_NAME,
       c.CATEGORY_NAME,
       sup.SUPPLIER_NAME,
       p.PRICE,
       s.QUANTITY,
       p.PRICE * s.QUANTITY AS STOCK_VALUE,
       CASE
           WHEN s.QUANTITY = 0  THEN 'OUT OF STOCK'
           WHEN s.QUANTITY < 20 THEN 'LOW'
           WHEN s.QUANTITY > 100 THEN 'OVERSTOCK'
           ELSE 'HEALTHY'
       END AS STOCK_STATUS
FROM PRODUCTS p
JOIN CATEGORIES c   ON p.CATEGORY_ID = c.CATEGORY_ID
JOIN SUPPLIERS  sup ON p.SUPPLIER_ID = sup.SUPPLIER_ID
JOIN STOCK      s   ON p.PRODUCT_ID  = s.PRODUCT_ID;
select * from VW_INVENTORY_DASHBOARD;


