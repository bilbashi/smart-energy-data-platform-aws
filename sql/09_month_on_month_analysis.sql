-- Building month-on-month analysis

-- All month-on-month comparisons
SELECT
    building_id,
    year,
    month,
    month_name,
    avg_building_daily_energy_kwh,
    previous_month_avg_daily_energy,
    month_on_month_change_percent
FROM smart_energy_db.building_monthly
WHERE previous_month_avg_daily_energy IS NOT NULL
ORDER BY
    building_id,
    year,
    month;

-- 10 largest absolute month-on-month changes
SELECT
    building_id,
    year,
    month,
    month_name,
    avg_building_daily_energy_kwh,
    previous_month_avg_daily_energy,
    month_on_month_change_percent
FROM smart_energy_db.building_monthly
WHERE previous_month_avg_daily_energy IS NOT NULL
ORDER BY ABS(month_on_month_change_percent) DESC
LIMIT 10;
