#!/bin/bash
   #===============================================================================================================
   #                                                                                                                                              
   #         FILE: backup_memsql_procedures.sh [memsql connection string ex. -h127.0.0.1 -uroot -pPassword -P3306]
   #
   #        USAGE: Run it
   #
   #  DESCRIPTION: Exports all MemSQL stored procedures 
   #      OPTIONS:  
   # REQUIREMENTS: MemSQL
   #       AUTHOR: Mike Czabator (mczabator@memsql.com)
   #      CREATED: 09.18.2018
   #      VERSION: 1.0
   #      EUL    : 	THIS CODE IS OFFERED ON AN “AS-IS” BASIS AND NO WARRANTY, EITHER EXPRESSED OR IMPLIED, IS GIVEN. 
   #				THE AUTHOR EXPRESSLY DISCLAIMS ALL WARRANTIES OF ANY KIND, WHETHER EXPRESS OR IMPLIED.
   #				YOU ASSUME ALL RISK ASSOCIATED WITH THE QUALITY, PERFORMANCE, INSTALLATION AND USE OF THE SOFTWARE INCLUDING, 
   #				BUT NOT LIMITED TO, THE RISKS OF PROGRAM ERRORS, DAMAGE TO EQUIPMENT, LOSS OF DATA OR SOFTWARE PROGRAMS, 
   #				OR UNAVAILABILITY OR INTERRUPTION OF OPERATIONS. 
   #				YOU ARE SOLELY RESPONSIBLE FOR DETERMINING THE APPROPRIATENESS OF USE THE SOFTWARE AND ASSUME ALL RISKS ASSOCIATED WITH ITS USE.
   #
   #
   #===============================================================================================================

datetime=$(date +%Y%m%d_%H%M%S)
dir=memsql_procedure_dump_$datetime	

count=0

if [[ ! -e $dir ]]; then
    mkdir $dir
    printf "\ncreated directory: $dir\n\n"
fi

for db in `memsql -N $@ -e "show databases"` 
do
	if [ $db = "memsql" ] || [ $db = "cluster" ] ; then 
		continue
	else

	for sp_name in `memsql -N $@ $db -Bse "show procedures" | awk '{print $1}'`
	do
			printf "backing up $db.$sp_name\n"
         printf "/*\ndatabase : $db\nprocedure: $sp_name\n*/\nDELIMITER //\n" >> ./$dir/$db\.sql
			memsql -N $@ -D $db -Bse "show create procedure $sp_name" | sed $'s/\t/\\/\\//g' | awk -F "//" -v RS="" '{print $2}' | awk '{gsub(/\\n/,"\n")}1' | awk '{gsub(/\\t/,"\t")}1'  >>  ./$dir/$db\.sql
			printf "//\nDELIMITER ;\n\n" >> ./$dir/$db\.sql
         count=$(($count+1))

	done
	fi
done
printf  "\nbacked up $count procedures in ./$dir\n"
