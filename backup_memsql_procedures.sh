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
   #      UPDATED: 01.31.2019      
   #      VERSION: 2.0
   #      EUL    : 	THIS CODE IS OFFERED ON AN “AS-IS” BASIS AND NO WARRANTY, EITHER EXPRESSED OR IMPLIED, IS GIVEN. 
   #				THE AUTHOR EXPRESSLY DISCLAIMS ALL WARRANTIES OF ANY KIND, WHETHER EXPRESS OR IMPLIED.
   #				YOU ASSUME ALL RISK ASSOCIATED WITH THE QUALITY, PERFORMANCE, INSTALLATION AND USE OF THE SOFTWARE INCLUDING, 
   #				BUT NOT LIMITED TO, THE RISKS OF PROGRAM ERRORS, DAMAGE TO EQUIPMENT, LOSS OF DATA OR SOFTWARE PROGRAMS, 
   #				OR UNAVAILABILITY OR INTERRUPTION OF OPERATIONS. 
   #				YOU ARE SOLELY RESPONSIBLE FOR DETERMINING THE APPROPRIATENESS OF USE THE SOFTWARE AND ASSUME ALL RISKS ASSOCIATED WITH ITS USE.
   #
   #
   #
   #
   #
   #
   #===============================================================================================================
datetime=$(date +%Y%m%d_%H%M%S)
dir=memsql_procedure_dump_$datetime	

if [[ ! -e $dir ]]; then
    mkdir $dir
elif [[ ! -d $dir ]]; then
    echo "$dir already exists but is not a directory" 1>&2
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
         memsql $@ -D $db -ANe "show create procedure $sp_name\G" >  ./$dir/$db\.tmp
         
         # Remove Top 2 Lines
         LINECOUNT=`wc -l < ./$dir/$db\.tmp`
         (( LINECOUNT -= 2 ))
         tail -n ${LINECOUNT} < ./$dir/$db\.tmp > ./$dir/$db\.2.tmp

         # Remove Bottom 2 Lines
         LINECOUNT=`wc -l < ./$dir/$db\.2.tmp`
         (( LINECOUNT -= 2 ))
         head -n ${LINECOUNT} < ./$dir/$db\.2.tmp >> ./$dir/$db\.sql
         
         printf "//\nDELIMITER ;\n\n" >> ./$dir/$db\.sql
         count=$(($count+1))
         rm ./$dir/*.tmp
	done
	fi
done
printf  "\nbacked up $count procedures in ./$dir\n"
