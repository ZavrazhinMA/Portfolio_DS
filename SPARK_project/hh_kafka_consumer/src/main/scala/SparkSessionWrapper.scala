import org.apache.spark.sql.SparkSession

trait SparkSessionWrapper {

  lazy val spark: SparkSession = SparkSession.builder()
                                             .appName("VacancyKafka")
                                             .master("local")
                                             .getOrCreate

}