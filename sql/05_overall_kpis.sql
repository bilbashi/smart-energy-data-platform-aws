-- Overall platform KPIs

SELECT
    MIN(timestamp) AS start_timestamp,
    MAX(timestamp) AS end_timestamp,
    COUNT(DISTINCT building_id) AS total_buildings,
    COUNT(DISTINCT sensor_id) AS total_sensors,
    COUNT(*) AS total_sensor_readings,
    ROUND(SUM(energy_kwh), 2) AS total_energy_kwh,
    ROUND(AVG(power_kw), 3) AS avg_sensor_power_kw,
    ROUND(MAX(power_kw), 3) AS peak_sensor_power_kw,
    ROUND(AVG(voltage), 2) AS avg_voltage,
    ROUND(AVG(power_factor), 3) AS avg_power_factor,
    ROUND(AVG(temperature), 2) AS avg_temperature
FROM smart_energy_db.processed;
