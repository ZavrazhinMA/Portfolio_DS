# docker-hive
To run Hive with postgresql metastore:
```
    docker-compose up -d
```
## comands
```
docker cp "your_path_to_parquet" hive_docker-hive-server-1:/opt
docker-compose exec hive-server bash
hdfs dfs -put -f /opt/results /user/hive
__________________________________________________________________
hdfs dfs -rm -r /user/hive
rm -r results

```
To deploy in Docker Swarm:
```
    docker stack deploy -c docker-compose.yml hive
```

To run a PrestoDB 0.181 with Hive connector:

```
  docker-compose up -d presto-coordinator
```

This deploys a Presto server listens on port `8080`

## Testing
Load data into Hive:
```
  $ docker-compose exec hive-server bash
  # /opt/hive/bin/beeline -u jdbc:hive2://localhost:10000
  > CREATE TABLE pokes (foo INT, bar STRING);
  > LOAD DATA LOCAL INPATH '/opt/hive/examples/files/kv1.txt' OVERWRITE INTO TABLE pokes;
