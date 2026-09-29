-- Sensor-level analysis

-- Top 10 sensors by total energy consumption
SELECT
    sensor_id,
    building_id,
    total_readings,
    total_energy_kwh,
    avg_power_kw,
    peak_power_kw,
    avg_voltage,
    avg_power_factor,
    avg_temperature
FROM smart_energy_db.sensor_summary
ORDER BY total_energy_kwh DESC
LIMIT 10;

-- Top 10 sensors by peak power
SELECT
    sensor_id,
    building_id,
    total_readings,
    total_energy_kwh,
    avg_power_kw,
    peak_power_kw,
    avg_voltage,
    avg_power_factor,
    avg_temperature
FROM smart_energy_db.sensor_summary
ORDER BY peak_power_kw DESC
LIMIT 10;
