import Dependencies.library

ThisBuild / organization := "project"
ThisBuild / scalaVersion := "2.12.18"
ThisBuild / version := "LATEST"
scalacOptions ++= Seq("-target:jvm-11")

lazy val root = (project in file("."))
  .settings(
    name := "kafka_consumer_hh",
    libraryDependencies ++= Seq(
      library.sparkSql,
      library.sparkStreaming,
      library.sparkKafka,
      library.conf
    ),
    // для собрки толстых JAR через assembly - от ошибок
    assembly / assemblyMergeStrategy := {
      case PathList("META-INF", "MANIFEST.MF") => MergeStrategy.discard
      case _                                   => MergeStrategy.first
    }
  )
