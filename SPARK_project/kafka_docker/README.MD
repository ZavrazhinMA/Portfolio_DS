1) Запускаем Kafka
```
docker compose up -d
```
2) Проверяем, что сервисы работают
```
docker compose ps -a
```

3) Создаём топик "hh"
```
docker exec kafka kafka-topics --create --topic hh --bootstrap-server localhost:9092
```

4) Проверяем топики
```
docker exec kafka kafka-topics --list --bootstrap-server localhost:9092
```

5) Работаем с Kafka
Брокер Kafka доступен как localhost:9092
Удаляем топики
```
docker exec kafka kafka-topics --delete --topic hh --bootstrap-server localhost:9092
```

6) Останавливаем Kafka
```
docker compose stop
```
```
docker container prune -f
```
```
docker volume prune -f
```
