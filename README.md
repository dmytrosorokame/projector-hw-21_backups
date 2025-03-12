# Projector HSA Home work #21: Backups

## Tasks:

1. Take/create the database from your pet project.
2. Implement all kinds of repository models (Full, Incremental, Differential, Reverse Delta, CDP).
3. Compare their parameters: size, ability to roll back at specific time point, speed of roll back, cost.

## Instructions:

### Full Backups:

1. Start MySQL container:

```shell
docker-compose -f docker-compose-full.yaml up
```

2. Login to MySQL container:

```shell
docker exec -it db_full_backup bash
```

3. Execute setup scripts:

   - Run [table creation](./data/create.sql)
   - Run data insertions: [insertion1](./data/insert1.sql), [insertion2](./data/insert2.sql), [insertion3](./data/insert3.sql)

4. Create full backup:

```shell
mysqldump -u root -padmin books --flush-logs > /backup/full.sql
```

5. Check [full backup file](./backups/full/full.sql) - Size: 5.8 MB for 300k rows

6. To restore from backup:
   - Start container (if not running)
   - Login to container
   - Restore database:

```shell
mysql -u root -padmin books < /backup/full.sql
```

Restore speed: ~2.143s

### Differential Backups:

1. Start environment:

```shell
docker-compose -f docker-compose-diff.yaml up
```

2. Initial setup:

   - Run [create table](./data/create.sql)
   - Run [insert data](./data/insert1.sql)

3. Check binary log files:

```shell
ls -lh /backup/
```

Expected output:

```
total 4.8M
-rw-r----- 1 mysql mysql  180 Sep 21 14:45 log-bin.000001
-rw-r----- 1 root  root  2.1M Sep 21 14:45 log-bin.000002
...
```

4. Create initial full backup:

```shell
mysqldump -u root -padmin books --flush-logs > /backup/full.sql
```

5. Add more data:

   - Run [insert data 2](./data/insert2.sql)
   - Run [insert data 3](./data/insert3.sql)

6. Create differential backup:

```shell
mysqlbinlog /backup/log-bin.000007 /backup/log-bin.000008 /backup/log-bin.000009 > /backup/diff-backup.sql
```

7. To restore:

```shell
# First restore full backup
mysql -u root -padmin books < /backup/full.sql  # Restores 100k rows, ~0.892s
# Then apply differential backup
mysql -u root -padmin books < /backup/diff-backup.sql  # Adds remaining data, ~0.534s
```

### Incremental Backups:

Similar to Differential, but creates separate backup for each binary log:

1. Create full backup:

```shell
mysqldump -u root -padmin books --flush-logs > /backup/full.sql
```

2. Create incremental backups:

```shell
mysqlbinlog /backup/log-bin.000007 > /backup/incr-1.sql
mysqlbinlog /backup/log-bin.000008 > /backup/incr-2.sql
```

3. To restore: apply full backup followed by each incremental backup in sequence

### Reverse Delta Backup

Implementation process:

1. Create initial full backup and binary log backup
2. When changes occur:
   - Create new full backup
   - Calculate rollback diff between backups
   - Store rollback script for reverting to previous state
3. For restoration:
   - Apply rollback backup against current full backup
   - Note: Full backup size increases over time

### CDP (Continuous Data Protection)

Implementation options:

1. Enable binary logging (as in incremental/differential)
2. Regular mysqldump execution (note: may impact performance on large DBs)

## Comparison

| Backup Type   | Storage Size | Recovery Points | Recovery Speed | Implementation Complexity |
| ------------- | ------------ | --------------- | -------------- | ------------------------- |
| Full          | Largest      | No              | Fast (2.1s)    | Simple                    |
| Differential  | Medium       | Yes             | Medium (1.4s)  | Medium                    |
| Incremental   | Smallest     | Yes             | Slow (2.3s+)   | High                      |
| Reverse Delta | Optimized    | Yes             | Medium         | Very High                 |
| CDP           | Large        | Any point       | Varies         | Complex                   |

---
