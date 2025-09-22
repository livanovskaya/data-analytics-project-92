-- считается кол-во уникальных айди пользователей в таблице с клиентами
select count(distinct customer_id) as customers_count
from customers;

--- запрос для топ 10 продавцов по выручке
select
    concat(e.first_name, ' ', e.last_name) as seller,
    count(distinct s.sales_id) as operations,
    floor(sum(s.quantity * p.price)) as income
from sales as s
left join products as p
    on s.product_id = p.product_id
left join employees as e
    on s.sales_person_id = e.employee_id
group by seller;

-- запрос для продавцов у кого выручка ниже среднего по сделкам
with incomes as (
    select
        concat(e.first_name, ' ', e.last_name) as seller,
        s.quantity * p.price as income,
        avg(s.quantity * p.price) over () as total_avg_income
    from sales as s
    left join products as p on s.product_id = p.product_id
    left join employees as e on s.sales_person_id = e.employee_id
)

select
    seller,
    floor(avg(income)) as average_income
from incomes
group by seller, total_avg_income
having floor(avg(income)) < floor(total_avg_income)
order by average_income;

--- нахождение суммы выручки по дням недели
select
    concat(e.first_name, ' ', e.last_name) as seller,
    lower(to_char(s.sale_date, 'day')) as day_of_week,
    floor(sum(s.quantity * p.price)) as income
from sales as s
left join products as p on s.product_id = p.product_id
left join employees as e on s.sales_person_id = e.employee_id
group by seller, day_of_week, extract(isodow from s.sale_date)
order by extract(isodow from s.sale_date), seller;

--- анализ по возрастным группам
select
    case
        when age >= 16 and age <= 25 then '16-25'
        when age >= 26 and age <= 40 then '26-40'
        else '40+'
    end as age_category,
    count(distinct customer_id) as age_count
from customers
group by age_category
order by age_category;

---- кол-во покупателей и выручка по месяцам
select
    to_char(s.sale_date, 'YYYY-MM') as selling_month,
    count(distinct s.customer_id) as total_customers,
    floor(sum(p.price * s.quantity)) as income
from sales as s
left join customers as c
    on s.customer_id = c.customer_id
left join products as p
    on s.product_id = p.product_id
group by selling_month
order by selling_month;

--- выгрузка по первой акционной покупке
with first_orders as (
    select
        s.sales_id,
        s.sale_date,
        c.customer_id,
        row_number() over (
            partition by c.customer_id
            order by s.sale_date
        ) as rn
    from sales as s
    left join customers as c on s.customer_id = c.customer_id
)

select
    s.sale_date,
    (c.first_name || ' ' || c.last_name) as customer,
    (e.first_name || ' ' || e.last_name) as seller
from sales as s
left join customers as c on s.customer_id = c.customer_id
left join products as p on s.product_id = p.product_id
left join employees as e on s.sales_person_id = e.employee_id
inner join first_orders as fo on s.sales_id = fo.sales_id and fo.rn = 1
where p.price = 0
order by c.customer_id;
