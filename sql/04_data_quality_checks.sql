-- Raw and processed data-quality validation

-- Raw row count
SELECT COUNT(*) AS total_rows
FROM smart_energy_db.raw;

-- Raw missing values
SELECT
    COUNT(*) AS total_rows,
    COUNT_IF(timestamp IS NULL OR TRIM(timestamp) = '') AS missing_timestamps,
    COUNT_IF(energy_kwh IS NULL) AS missing_energy
FROM smart_energy_db.raw;

-- Genuine duplicate timestamp/sensor groups in raw data
WITH duplicate_groups AS (
    SELECT
        timestamp,
        sensor_id,
        COUNT(*) AS record_count
    FROM smart_energy_db.raw
    WHERE timestamp IS NOT NULL
      AND TRIM(timestamp) <> ''
    GROUP BY
        timestamp,
        sensor_id
    HAVING COUNT(*) > 1
)
SELECT COUNT(*) AS duplicate_groups
FROM duplicate_groups;

-- Raw invalid/extreme measurements
SELECT
    COUNT_IF(energy_kwh < 0) AS negative_energy,
    COUNT_IF(energy_kwh > 5) AS extreme_energy,
    COUNT_IF(voltage < 200 OR voltage > 250) AS invalid_voltage
FROM smart_energy_db.raw;

-- Processed-layer validation
WITH duplicate_groups AS (
    SELECT
        timestamp,
        sensor_id,
        COUNT(*) AS record_count
    FROM smart_energy_db.processed
    GROUP BY
        timestamp,
        sensor_id
    HAVING COUNT(*) > 1
),

duplicate_summary AS (
    SELECT COUNT(*) AS duplicate_groups
    FROM duplicate_groups
)

SELECT
    COUNT(*) AS total_rows,
    COUNT_IF(timestamp IS NULL) AS missing_timestamps,
    COUNT_IF(energy_kwh IS NULL) AS missing_energy,
    COUNT_IF(voltage IS NULL OR voltage < 200 OR voltage > 250)
        AS invalid_voltage,
    COUNT_IF(energy_kwh < 0 OR energy_kwh > 5)
        AS invalid_energy,
    COUNT_IF(
        temperature IS NULL
        OR temperature < -10
        OR temperature > 30
    ) AS invalid_temperature,
    MAX(duplicate_summary.duplicate_groups) AS duplicate_groups
FROM smart_energy_db.processed
CROSS JOIN duplicate_summary;
