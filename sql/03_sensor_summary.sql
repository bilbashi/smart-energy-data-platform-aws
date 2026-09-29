-- Curated sensor-level summary table
-- Replace <your-bucket-name> with your own S3 bucket name.

CREATE TABLE smart_energy_db.sensor_summary
WITH (
    format = 'PARQUET',
    external_location = 's3://<your-bucket-name>/curated/sensor_summary/',
    write_compression = 'SNAPPY'
)
AS
SELECT
    sensor_id,
    building_id,
    MIN(timestamp) AS first_reading,
    MAX(timestamp) AS last_reading,
    COUNT(*) AS total_readings,
    ROUND(SUM(energy_kwh), 2) AS total_energy_kwh,
    ROUND(AVG(power_kw), 3) AS avg_power_kw,
    ROUND(MAX(power_kw), 3) AS peak_power_kw,
    ROUND(AVG(voltage), 2) AS avg_voltage,
    ROUND(AVG(power_factor), 3) AS avg_power_factor,
    ROUND(AVG(temperature), 2) AS avg_temperature
FROM smart_energy_db.processed
GROUP BY
    sensor_id,
    building_id;
