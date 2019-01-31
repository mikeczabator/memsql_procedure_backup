# memsql_procedure_backup
script runs a 'SHOW CREATE PROCEDURE' on all procedures on all databases.  Procedures are saved with proper delimiters.  
### use:
`backup_memsql_procedures.sh [memsql connection string ex. -h127.0.0.1 -uroot -pPassword -P3306]`


### example: 
```
[vagrant@localhost ~]$ ./save_procedures_v2.sh -uroot
backing up energy.get_memsql_status
backing up energy.testing_DS
backing up energy.using_test
backing up newdb.charge_account
backing up newdb.create_feature_table
backing up newdb.insert_into_bt
backing up newdb2.add_data
backing up newdb2.charge_account
backing up newdb2.downscale
backing up newdb2.insert_into_bt
backing up newdb2.interpolate
backing up newdb2.p
backing up newdb2.processOrder
backing up newdb2.proctest
backing up newdb2.record_dt_example
backing up newdb2.rec_copy_example
backing up newdb2.runproctest
backing up newdb2.stat_roll_up
backing up newdb2.tcount
backing up newdb2.testing_DS
backing up poc.add_data
backing up poc.charge_account
backing up poc.downscale
backing up poc.insert_into_bt
backing up poc.interpolate
backing up poc.p
backing up poc.processOrder
backing up poc.proctest
backing up poc.record_dt_example
backing up poc.rec_copy_example
backing up poc.runproctest
backing up poc.stat_roll_up
backing up poc.tcount
backing up poc.testing_DS

backed up 35 procedures in ./memsql_procedure_dump_20190131_101028 
```

