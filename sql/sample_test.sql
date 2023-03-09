with 
load_ec_order as (
  select distinct
    order_id
    , customer_id
    , created_at
    , total_price
  from
    `chocozap-ec.dl_shopify.order`
)
, load_customer as (
  select 
    *
  from `chocozap-ec.dl_shopify.customer_*`
  where num_orders <> 0
)
, join_customers as (
  SELECT 
    ec_order.total_price
    , cast(extract(month from ec_order.created_at) as string) as month
    , cast(extract(year from ec_order.created_at) as string) as year
    , case gender
        when 1 then '男性'
        when 2 then '女性' 
        else 'その他'
      end as gender
    , IF(round_age >= 70, '70以上', cast(round_age as string)) AS round_age
  FROM 
    load_ec_order as ec_order
  INNER join (select email, customer_id from load_customer) as ec_customer 
    using(customer_id)
  inner join (
      select 
        mail_address 
        , gender
        , round(FLOOR(DATE_DIFF(CURRENT_DATE('Asia/Tokyo'), birthday, DAY)/3650))*10 as round_age
      from `hgym-340203.hacomono_chocozap.会員`
    ) as choco_customer
    on ec_customer.email = choco_customer.mail_address
)
, calc_price as (
  select 
    year
    , month
    , gender
    , round_age
    , sum(total_price) as price
    , count(total_price) as num_order
  from join_customers
  where gender <> 'その他'
  group by year, month, gender, round_age
)
, calc_gender_total as (
  select 
    year
    , month
    , '小計' as gender
    , round_age
    , sum(total_price) as price
    , count(total_price) as num_order
  from join_customers
  where gender <> 'その他'
  group by year, month, round_age
)
, calc_age_total as (
  select 
    year
    , month
    , gender
    , '小計' as round_age
    , sum(total_price) as price
    , count(total_price) as num_order
  from join_customers
  where gender <> 'その他'
  group by year, month, gender
)
, calc_month_total as (
  select
    '小計' as year
    , '小計' as month
    , gender
    , round_age
    , sum(total_price) as price
    , count(total_price) as num_order
  from join_customers
  where gender <> 'その他'
  group by gender, round_age
)
, calc_month_age_total as (
  select
    '小計' as year
    , '小計' as month
    , gender
    , '小計' as round_age
    , sum(total_price) as price
    , count(total_price) as num_order
  from join_customers
  where gender <> 'その他'
  group by gender
)

-- choco ECの売り上げを元に年代、性別でそれぞれいくら(金額)注文したのか集計してほしい
select * from calc_price
union all
select * from calc_gender_total
union all
select * from calc_age_total
union all
select * from calc_month_total
union all
select * from calc_month_age_total
order by gender, year, month, round_age

-- select 
--   *
-- from 
--   join_customers 
--     pivot(sum(amount_spent) as amount for round_age IN ('10', '20', '30', '40', '50', '60', '70', '80', '90', '100'))
-- order by gender