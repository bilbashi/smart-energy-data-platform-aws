-- Platform monthly trend analysis

SELECT
    year,
    month,
    month_name,
    SUM(sensor_readings) AS total_sensor_readings,
    ROUND(SUM(total_energy_kwh), 2) AS total_energy_kwh,
    ROUND(AVG(avg_building_daily_energy_kwh), 2)
        AS avg_building_daily_energy_kwh,
    ROUND(
        SUM(avg_sensor_power_kw * sensor_readings)
        / NULLIF(SUM(sensor_readings), 0),
        3
    ) AS avg_sensor_power_kw,
    ROUND(
        SUM(avg_temperature * sensor_readings)
        / NULLIF(SUM(sensor_readings), 0),
        2
    ) AS avg_temperature
FROM smart_energy_db.building_monthly
GROUP BY
    year,
    month,
    month_name
ORDER BY
    year,
    month;
