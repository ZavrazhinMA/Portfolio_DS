import Dependencies.library

ThisBuild / organization := "PET"
ThisBuild / scalaVersion := "2.12.18"
ThisBuild / version := "LATEST"
scalacOptions ++= Seq("-target:jvm-11")

lazy val root = (project in file("."))
  .settings(
    name := "vacancies-processor",
    libraryDependencies ++= Seq(
      library.sparkSql,
      library.conf
    ),
    // для собрки толстых JAR через assembly - от ошибок
    assembly / assemblyMergeStrategy := {
      case PathList("META-INF", "MANIFEST.MF") => MergeStrategy.discard
      case _                                   => MergeStrategy.first
    }
  )
