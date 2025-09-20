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
        s.sales_id,
        concat(e.first_name, ' ', e.last_name) as seller,
        sum(s.quantity * p.price) as income
    from sales as s
    left join products as p
        on s.product_id = p.product_id
    left join employees as e
        on s.sales_person_id = e.employee_id
    group by seller, s.sales_id
),

avg_inc as (
    select
        seller,
        floor(avg(income)) as avg_seller_income
    from incomes
    group by seller
),

total_income_avg as (
    select avg(avg_seller_income) as avg_total_income
    from avg_inc
)

select
    ai.seller as seller,
    avg_seller_income as average_income
from avg_inc as ai
cross join total_income_avg as ti
where ai.avg_seller_income < ti.avg_total_income
order by ai.avg_seller_income;
--- нахождение суммы выручки по дням недели
select
    seller,
    day_of_week,
    income
from (
    select
        concat(e.first_name, ' ', e.last_name) as seller,
        lower(trim(to_char(s.sale_date, 'Day'))) as day_of_week,
        case
            when extract(dow from s.sale_date) = 0 then 9
            else extract(dow from s.sale_date)
        end as numeric_day,
        floor(sum(s.quantity * p.price)) as income
    from sales as s
    left join products as p
        on s.product_id = p.product_id
    left join employees as e
        on s.sales_person_id = e.employee_id
    group by seller, day_of_week, numeric_day
) as cte
order by numeric_day, seller;

--- анализ по возрастным группам
select
    case
        when age >= 16 and age <= 25 then '16-25'
        when age >= 26 and age <= 40 then '26-40'
        else '40+'
    end as age_category,
    count(distinct customer_id) as age_count
from customers с
group by с.age_category
order by c.age_category;

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
with sales_agg as (
    select
        sales_id,
        min_order_date,
        sale_date
    from (
        select
            c.customer_id,
            s.sales_id,
            s.sale_date,
            min(s.sale_date)
                over (partition by c.customer_id)
                as min_order_date
        from sales as s
        left join customers as c
            on s.customer_id = c.customer_id
    ) as a
    where sale_date = min_order_date
)

select
    s.sale_date,
    (c.first_name || ' ' || c.last_name) as customer,
    (e.first_name || ' ' || e.last_name) as seller
from sales as s
left join customers as c
    on s.customer_id = c.customer_id
left join products as p
    on s.product_id = p.product_id
left join employees as e
    on s.sales_person_id = e.employee_id
where
    p.price = 0
    and s.sales_id in (select sales_id from sales_agg)
group by c.customer_id, customer, s.sale_date, seller
order by c.customer_id;