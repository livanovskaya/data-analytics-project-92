-- считается кол-во уникальных айди пользователей в таблице с клиентами
select count(distinct customer_id) as customers_count
from customers;


--- запрос для топ 10 продавцов по выручке
select concat(first_name, ' ', last_name) as seller,
            count(distinct sales_id)           as operations,
            FLOOR(sum(quantity * price))       as income
from sales s
         left join products p on p.product_id = s.product_id
         left join employees e on e.employee_id = s.sales_person_id
group by seller;


-- запрос для продавцов у кого выручка ниже среднего по сделкам
with incomes as
         (select concat(first_name, ' ', last_name) as seller,
                 sales_id,
                 sum(quantity * price)              as income
          from sales s
                   left join products p on p.product_id = s.product_id
                   left join employees e on e.employee_id = s.sales_person_id
          group by seller, sales_id),

     avg_inc as (select seller,
                        floor(avg(income)) as avg_seller_income
                 from incomes
                 group by seller),

     total_income_avg as (select avg(avg_seller_income) as avg_total_income from avg_inc)

select seller, avg_seller_income as average_income
from avg_inc
         cross join total_income_avg
where avg_seller_income < avg_total_income
order by avg_seller_income;

--- нахождение суммы выручки по дням недели
select seller, day_of_week, income
from (select concat(first_name, ' ', last_name)                                                    as seller,
             lower(trim(TO_CHAR(sale_date, 'Day')))                                                as day_of_week,
             case when extract(DOW from sale_date) = 0 then 9 else extract(DOW from sale_date) end as numeric_day, -- исправление, чтобы нумерация шла с пн
             FLOOR(sum(quantity * price))                                                          as income
      from sales s
               left join products p on p.product_id = s.product_id
               left join employees e on e.employee_id = s.sales_person_id
      group by seller, day_of_week, numeric_day) as cte
order by numeric_day, seller;


--- анализ по возрастным группам
select case
           when age >= 16 and age <= 25 then '16-25'
           when age >= 26 and age <= 40 then '26-40'
           else '40+' end             age_category,
       count(distinct customer_id) as age_count
from customers
group by age_category
order by age_category;


---- кол-во покупателей и выручка по месяцам
select TO_CHAR(sale_date, 'YYYY-MM') as selling_month,
       count(distinct s.customer_id) as total_customers,
       floor(sum(price * quantity))        as income
from sales s
         left join customers c on c.customer_id = s.customer_id
         left join products p on p.product_id = s.product_id
group by selling_month
order by selling_month;

--- выгрузка по первой акционной покупке
with sales_agg as (select sales_id, min_order_date, sale_date
                   from (select c.customer_id,
                                sales_id,
                                min(sale_date) over (partition by c.customer_id) as min_order_date,
                                sale_date
                         from sales s
                                  left join customers c on c.customer_id = s.customer_id) as a
                   where sale_date = min_order_date)

select (c.first_name || ' ' || c.last_name) as customer,
                sale_date,
                (e.first_name || ' ' || e.last_name) as seller
from sales s
         left join customers c on c.customer_id = s.customer_id
         left join products p on p.product_id = s.product_id
         left join employees e on e.employee_id = s.sales_person_id
where price = 0
  and sales_id in (select sales_id from sales_agg)
group by c.customer_id, customer, sale_date, seller
order by c.customer_id;


