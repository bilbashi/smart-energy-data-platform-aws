-- Weekday vs weekend energy consumption by building

WITH daily_energy AS (

    SELECT
        reading_date,
        building_id,
        total_energy_kwh,

        CASE
            WHEN DAY_OF_WEEK(reading_date) IN (6, 7)
                THEN 'Weekend'
            ELSE 'Weekday'
        END AS day_type

    FROM smart_energy_db.building_daily
)

SELECT
    building_id,

    ROUND(
        AVG(
            CASE
                WHEN day_type = 'Weekday'
                THEN total_energy_kwh
            END
        ),
        2
    ) AS avg_weekday_energy_kwh,

    ROUND(
        AVG(
            CASE
                WHEN day_type = 'Weekend'
                THEN total_energy_kwh
            END
        ),
        2
    ) AS avg_weekend_energy_kwh,

    ROUND(
        AVG(
            CASE
                WHEN day_type = 'Weekend'
                THEN total_energy_kwh
            END
        )
        -
        AVG(
            CASE
                WHEN day_type = 'Weekday'
                THEN total_energy_kwh
            END
        ),
        2
    ) AS weekend_difference_kwh,

    ROUND(
        (
            (
                AVG(
                    CASE
                        WHEN day_type = 'Weekend'
                        THEN total_energy_kwh
                    END
                )
                -
                AVG(
                    CASE
                        WHEN day_type = 'Weekday'
                        THEN total_energy_kwh
                    END
                )
            )
            /
            NULLIF(
                AVG(
                    CASE
                        WHEN day_type = 'Weekday'
                        THEN total_energy_kwh
                    END
                ),
                0
            )
        ) * 100,
        2
    ) AS weekend_difference_percent

FROM daily_energy

GROUP BY building_id

ORDER BY building_id;
