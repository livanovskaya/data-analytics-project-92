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
group by 1;


-- запрос для продавцов у кого выручка ниже среднего по сделкам
with incomes as
         (select concat(first_name, ' ', last_name) as seller,
                 sales_id,
                 sum(quantity * price)              as income
          from sales s
                   left join products p on p.product_id = s.product_id
                   left join employees e on e.employee_id = s.sales_person_id
          group by 1, 2),

     avg_inc as (select seller,
                        floor(avg(income)) as avg_seller_income
                 from incomes
                 group by 1),

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
      group by 1, 2, 3) as cte
order by numeric_day, seller;



