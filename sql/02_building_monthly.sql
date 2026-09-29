-- Curated monthly building-level table with month-on-month change
-- Replace <your-bucket-name> with your own S3 bucket name.

CREATE TABLE smart_energy_db.building_monthly
WITH (
    format = 'PARQUET',
    external_location = 's3://<your-bucket-name>/curated/building_monthly/',
    write_compression = 'SNAPPY'
)
AS

WITH monthly AS (

    SELECT
        building_id,
        YEAR(reading_date) AS year,
        MONTH(reading_date) AS month,
        DATE_TRUNC('month', reading_date) AS month_start,
        COUNT(*) AS days_recorded,
        SUM(sensor_readings) AS sensor_readings,
        ROUND(SUM(total_energy_kwh), 2) AS total_energy_kwh,
        ROUND(AVG(total_energy_kwh), 2) AS avg_building_daily_energy_kwh,
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

    GROUP BY
        building_id,
        YEAR(reading_date),
        MONTH(reading_date),
        DATE_TRUNC('month', reading_date)
),

monthly_previous AS (

    SELECT
        *,
        LAG(avg_building_daily_energy_kwh) OVER (
            PARTITION BY building_id
            ORDER BY year, month
        ) AS previous_month_avg_daily_energy

    FROM monthly
)

SELECT
    building_id,
    year,
    month,
    DATE_FORMAT(
        CAST(month_start AS TIMESTAMP),
        '%M'
    ) AS month_name,
    month_start,
    days_recorded,
    sensor_readings,
    total_energy_kwh,
    avg_building_daily_energy_kwh,
    avg_sensor_power_kw,
    peak_sensor_power_kw,
    avg_voltage,
    avg_power_factor,
    avg_temperature,
    previous_month_avg_daily_energy,
    ROUND(
        (
            (
                avg_building_daily_energy_kwh
                - previous_month_avg_daily_energy
            )
            /
            NULLIF(previous_month_avg_daily_energy, 0)
        ) * 100,
        2
    ) AS month_on_month_change_percent

FROM monthly_previous;
