import sbt._
object Dependencies {
  val library: Object {
    val sparkSql: ModuleID
    val conf: ModuleID

  } = new {
    object Version {
      lazy val spark = "3.5.0"
    }

    val sparkSql =
      "org.apache.spark" %% "spark-sql" % Version.spark
    val conf = "com.typesafe" % "config" % "1.4.3"
  }
}
