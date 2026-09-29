-- Curated daily building-level table
-- Replace <your-bucket-name> with your own S3 bucket name.

CREATE TABLE smart_energy_db.building_daily
WITH (
    format = 'PARQUET',
    external_location = 's3://<your-bucket-name>/curated/building_daily/',
    write_compression = 'SNAPPY'
)
AS
SELECT
    CAST(timestamp AS DATE) AS reading_date,
    building_id,
    COUNT(*) AS sensor_readings,
    ROUND(SUM(energy_kwh), 2) AS total_energy_kwh,
    ROUND(AVG(power_kw), 3) AS avg_sensor_power_kw,
    ROUND(MAX(power_kw), 3) AS peak_sensor_power_kw,
    ROUND(AVG(voltage), 2) AS avg_voltage,
    ROUND(AVG(power_factor), 3) AS avg_power_factor,
    ROUND(AVG(temperature), 2) AS avg_temperature
FROM smart_energy_db.processed
GROUP BY
    CAST(timestamp AS DATE),
    building_id;
