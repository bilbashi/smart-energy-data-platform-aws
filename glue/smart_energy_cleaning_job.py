import sys

from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.utils import getResolvedOptions

from pyspark.context import SparkContext
from pyspark.sql import functions as F


# --------------------------------------------------
# 1. Initialise AWS Glue / Spark
# --------------------------------------------------

# OUTPUT_PATH should be supplied as a Glue job parameter, for example:
# --OUTPUT_PATH s3://<your-bucket-name>/processed/
args = getResolvedOptions(
    sys.argv,
    ["JOB_NAME", "OUTPUT_PATH"]
)

sc = SparkContext()
glue_context = GlueContext(sc)
spark = glue_context.spark_session

job = Job(glue_context)
job.init(args["JOB_NAME"], args)


# --------------------------------------------------
# 2. Read raw data from the Glue Data Catalog
# --------------------------------------------------

raw_dynamic_frame = glue_context.create_dynamic_frame.from_catalog(
    database="smart_energy_db",
    table_name="raw"
)

df = raw_dynamic_frame.toDF()

raw_row_count = df.count()

print(f"Raw row count: {raw_row_count}")


# --------------------------------------------------
# 3. Convert columns to the correct data types
# --------------------------------------------------

df = (
    df
    .withColumn(
        "timestamp",
        F.to_timestamp(
            F.trim(F.col("timestamp")),
            "yyyy-MM-dd HH:mm:ss"
        )
    )
    .withColumn("voltage", F.col("voltage").cast("double"))
    .withColumn("current", F.col("current").cast("double"))
    .withColumn("power_factor", F.col("power_factor").cast("double"))
    .withColumn("temperature", F.col("temperature").cast("double"))
    .withColumn("power_kw", F.col("power_kw").cast("double"))
    .withColumn("energy_kwh", F.col("energy_kwh").cast("double"))
)


# --------------------------------------------------
# 4. Remove records without essential identifiers
# --------------------------------------------------

df = df.filter(
    F.col("timestamp").isNotNull()
    & F.col("sensor_id").isNotNull()
    & (F.trim(F.col("sensor_id")) != "")
)


# --------------------------------------------------
# 5. Validate sensor IDs
# --------------------------------------------------

df = df.filter(
    F.col("sensor_id").rlike(r"^S0[0-9]{2}$")
)


# --------------------------------------------------
# 6. Rebuild building ID from sensor ID
# --------------------------------------------------

sensor_number = F.regexp_extract(
    F.col("sensor_id"),
    r"(\d{3})$",
    1
).cast("int")

building_number = (
    F.floor(
        (sensor_number - F.lit(1)) / F.lit(5)
    )
    + F.lit(1)
)

df = (
    df
    .withColumn(
        "building_id",
        F.concat(
            F.lit("B"),
            F.lpad(
                building_number.cast("int").cast("string"),
                2,
                "0"
            )
        )
    )
)


# --------------------------------------------------
# 7. Remove duplicate sensor readings
# --------------------------------------------------

df = df.dropDuplicates(
    ["timestamp", "sensor_id"]
)


# --------------------------------------------------
# 8. Replace invalid measurements with NULL
# --------------------------------------------------

df = (
    df
    .withColumn(
        "voltage",
        F.when(
            F.col("voltage").between(200, 250),
            F.col("voltage")
        )
    )
    .withColumn(
        "current",
        F.when(
            F.col("current").between(0, 20),
            F.col("current")
        )
    )
    .withColumn(
        "power_factor",
        F.when(
            F.col("power_factor").between(0.7, 1.0),
            F.col("power_factor")
        )
    )
    .withColumn(
        "temperature",
        F.when(
            F.col("temperature").between(-10, 30),
            F.col("temperature")
        )
    )
)


# --------------------------------------------------
# 9. Calculate median values for each sensor
# --------------------------------------------------

measurement_columns = [
    "voltage",
    "current",
    "power_factor",
    "temperature"
]

sensor_medians = df.groupBy("sensor_id").agg(
    *[
        F.expr(
            f"percentile_approx({column}, 0.5)"
        ).alias(f"{column}_sensor_median")
        for column in measurement_columns
    ]
)

df = df.join(
    sensor_medians,
    on="sensor_id",
    how="left"
)


# --------------------------------------------------
# 10. Calculate overall median values
# --------------------------------------------------

overall_medians_row = df.agg(
    *[
        F.expr(
            f"percentile_approx({column}, 0.5)"
        ).alias(column)
        for column in measurement_columns
    ]
).first()

overall_medians = overall_medians_row.asDict()


# --------------------------------------------------
# 11. Fill missing / invalid measurements
# --------------------------------------------------

for column in measurement_columns:

    df = df.withColumn(
        column,
        F.coalesce(
            F.col(column),
            F.col(f"{column}_sensor_median"),
            F.lit(overall_medians[column])
        )
    )

    df = df.drop(
        f"{column}_sensor_median"
    )


# --------------------------------------------------
# 12. Recalculate power and energy
# --------------------------------------------------

df = (
    df
    .withColumn(
        "power_kw",
        (
            F.col("voltage")
            * F.col("current")
            * F.col("power_factor")
        ) / 1000
    )
    .withColumn(
        "energy_kwh",
        F.col("power_kw")
    )
)


# --------------------------------------------------
# 13. Select final processed schema
# --------------------------------------------------

df_clean = df.select(
    "timestamp",
    "sensor_id",
    "building_id",
    "voltage",
    "current",
    "power_factor",
    "temperature",
    "power_kw",
    "energy_kwh"
)


# --------------------------------------------------
# 14. Validate cleaned row count
# --------------------------------------------------

clean_row_count = df_clean.count()

print(f"Raw row count: {raw_row_count}")
print(f"Clean row count: {clean_row_count}")


# --------------------------------------------------
# 15. Write processed data to S3 as Parquet
# --------------------------------------------------

(
    df_clean
    .write
    .mode("overwrite")
    .parquet(args["OUTPUT_PATH"])
)


# --------------------------------------------------
# 16. Commit Glue job
# --------------------------------------------------

job.commit()
