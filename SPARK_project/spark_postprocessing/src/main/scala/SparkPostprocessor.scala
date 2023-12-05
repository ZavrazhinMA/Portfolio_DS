import org.apache.spark.sql.functions._
import java.io.File
import com.typesafe.config.ConfigFactory

object SparkPostprocessor extends App with SparkSessionWrapper {

  val config = ConfigFactory.parseFile(new File("paths.conf"))
  val StreamedDf = spark.read.parquet(config.getString("read_dir"))
  StreamedDf
    .coalesce(1)
    .dropDuplicates()
    .where(col("_id").isNotNull)
    .write
    .mode("overwrite")
    .parquet(config.getString("write_dir"))
}
