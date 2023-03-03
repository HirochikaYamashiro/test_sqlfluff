with referral_data as (
select
  referred_user_id AS zap_id
  ,referral_code
  ,COUNT(*) AS uu
FROM
  `hgym-340203.dl_service_app_main.chocozap_referral_code_histories` AS i
left JOIN
  `hgym-340203.dl_service_app_main.chocozap_referral_codes` AS j
ON
  i.referral_code_id=j.id
GROUP BY
  1,2
)
select
  base.*
  ,referral_data.referral_code
from
  `hgym-340203.dl_service_app_main.users` as base
left outer join
  referral_data
on
  base.id = referral_data.zap_id
where
  referral_code is not null
