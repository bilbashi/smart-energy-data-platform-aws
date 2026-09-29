-- Building-level comparison using the curated daily table

SELECT
    building_id,
    SUM(sensor_readings) AS total_sensor_readings,
    ROUND(SUM(total_energy_kwh), 2) AS total_energy_kwh,
    ROUND(AVG(total_energy_kwh), 2) AS avg_daily_energy_kwh,
    ROUND(
        SUM(avg_sensor_power_kw * sensor_readings)
        / NULLIF(SUM(sensor_readings), 0),
        3
    ) AS avg_sensor_power_kw,
    ROUND(MAX(peak_sensor_power_kw), 3) AS peak_sensor_power_kw,
    ROUND(
        SUM(avg_voltage * sensor_readings)
        / NULLIF(SUM(sensor_readings), 0),
        2
    ) AS avg_voltage,
    ROUND(
        SUM(avg_power_factor * sensor_readings)
        / NULLIF(SUM(sensor_readings), 0),
        3
    ) AS avg_power_factor,
    ROUND(
        SUM(avg_temperature * sensor_readings)
        / NULLIF(SUM(sensor_readings), 0),
        2
    ) AS avg_temperature
FROM smart_energy_db.building_daily
GROUP BY building_id
ORDER BY total_energy_kwh DESC;
