#!/bin/bash
   #===============================================================================================================
   #                                                                                                                                              
   #         FILE: backup_memsql_procedures.sh [memsql connection string ex. -h127.0.0.1 -uroot -pPassword -P3306]
   #
   #        USAGE: 1) Run it. 
   #               2) VERIFY ACCURACY OF EXPORT!
   #
   #  DESCRIPTION: Exports all MemSQL stored procedures 
   #      OPTIONS:  
   # REQUIREMENTS: MemSQL
   #       AUTHOR: Mike Czabator (mczabator@memsql.com)
   #      CREATED: 09.18.2018
   #      UPDATED: 04.29.2020      
   #      VERSION: 2.3
   #    CHANGELOG: 2019-04-18  :  v2.2   : added perl regex to change CREATE PROCEDURE to CREATE OR REPLACE PROCEDURE
   #               2020-04-29  :  v2.3   : changed the way the perl regex looked for CREATE PROCEDURE to make sure it doesn't change other strings.
   #                                     : MemSQL 7.0 added SQL_MODE to the SHOW PROCEDURE output.  added support to remove that line.
   # 
   #      EUL    :   THIS CODE IS OFFERED ON AN “AS-IS” BASIS AND NO WARRANTY, EITHER EXPRESSED OR IMPLIED, IS GIVEN. 
   #           THE AUTHOR EXPRESSLY DISCLAIMS ALL WARRANTIES OF ANY KIND, WHETHER EXPRESS OR IMPLIED.
   #           YOU ASSUME ALL RISK ASSOCIATED WITH THE QUALITY, PERFORMANCE, INSTALLATION AND USE OF THE SOFTWARE INCLUDING, 
   #           BUT NOT LIMITED TO, THE RISKS OF PROGRAM ERRORS, DAMAGE TO EQUIPMENT, LOSS OF DATA OR SOFTWARE PROGRAMS, 
   #           OR UNAVAILABILITY OR INTERRUPTION OF OPERATIONS. 
   #           YOU ARE SOLELY RESPONSIBLE FOR DETERMINING THE APPROPRIATENESS OF USE THE SOFTWARE AND ASSUME ALL RISKS ASSOCIATED WITH ITS USE.
   #
   #
   #===============================================================================================================

## set this for for singular procedure files, or database files:
#  SINGLE   : single file for each procedure
#  DB       : procedures in files for each database
unset $filetype
clear

# Added functions to prompt for backup type
function BACKUP_TYPE()
{  
   if [ -z "$filetype" ];
   then 
      echo "Please set the backup type you would like."
      echo "Enter SINGLE to backup procedures in single file for each procedure"
      echo "-or-"
      echo "enter DB to backup procedures in a file per database"
      read filetype
      export filetype=$filetype
   fi
}

# Added function to encapsulate backup work
function BACKITUP()
{
datetime=$(date +%Y%m%d_%H%M%S)
dir=memsql_procedure_dump_$datetime 

memsql_version=`memsql -s -N -e "SELECT @@MEMSQL_VERSION"`
echo MemSQL version $memsql_version found.

for db in `memsql -N $@ -e "show databases"` 
do
   if [[ ! -e $dir ]] ; then
    mkdir $dir
   elif [[ ! -d $dir ]] ; then
       echo "$dir already exists but is not a directory" 1>&2
       exit
   fi

   if [[ $db = "memsql" ]] || [[ $db = "cluster" ]] ; then 
      continue
   else
      for sp_name in `memsql -N $@ $db -Bse "show procedures" 2>&1 | grep -v "Using a password on the command line interface can be insecure." | awk '{print $1}'`
      do
         if [[ $filetype = "DB" ]] ; then
            fn=$db
         elif [[ $filetype = "SINGLE" ]]; then
            fn=$db\.$sp_name
         else  
            echo "incorrect file type value!  use SINGLE or DB"
            rmdir $dir
            exit
         fi
         printf "backing up $db.$sp_name\n"
         printf "/*\ndatabase : $db\nprocedure: $sp_name\nretrieved: $datetime\n*/\nDELIMITER //\n" >> ./$dir/$fn\.sql
         memsql $@ -D $db -ANe "show create procedure $sp_name\G" 2>&1 | grep -v "Using a password on the command line interface can be insecure." >  ./$dir/$fn\.tmp
         
         if [ ${memsql_version:0:1} -le 6 ]
         then 
            # Remove Top 2 Lines for MemSQL version 6.8 and lower
            LINECOUNT=`wc -l < ./$dir/$fn\.tmp`
            (( LINECOUNT -= 2 ))
            tail -n ${LINECOUNT} < ./$dir/$fn\.tmp > ./$dir/$fn\.2.tmp

         elif [[ ${memsql_version:0:1} -ge 9 ]]; then
            # Remove Top 3 Lines for MemSQL version 7.0 and higher
            # MemSQL 7.0+ started adding the SQL_MODE to the SHOW CREATE PROCEDURE output, so we have to remove that from the output
            LINECOUNT=`wc -l < ./$dir/$fn\.tmp`
            (( LINECOUNT -= 3 ))
            tail -n ${LINECOUNT} < ./$dir/$fn\.tmp > ./$dir/$fn\.2.tmp

         else
            printf "unsupported version of MemSQL found.  Test outputted procedures to make sure they work.\n"
            #this could occur with betas.  remove top 3 lines assuming SQL_MODE will be there
            LINECOUNT=`wc -l < ./$dir/$fn\.tmp`
            (( LINECOUNT -= 3 ))
            tail -n ${LINECOUNT} < ./$dir/$fn\.tmp > ./$dir/$fn\.2.tmp
         fi

         # Remove Bottom 2 Lines
         LINECOUNT=`wc -l < ./$dir/$fn\.2.tmp`
         (( LINECOUNT -= 2 ))
         head -n ${LINECOUNT} < ./$dir/$fn\.2.tmp >> ./$dir/$fn\.sql

         # use perl regex to change CREATE PROCEDURE to CREATE OR REPLACE PROCEDURE        
         perl -i -p -e "s/^CREATE PROCEDURE \`$sp_name\`/CREATE OR REPLACE PROCEDURE \`$sp_name\`/;" ./$dir/$fn\.sql

         
         printf "//\nDELIMITER ;\n\n" >> ./$dir/$fn\.sql
         count=$(($count+1))
         rm ./$dir/*.tmp
   done
   fi
done

if [[ $count > 0 ]]; then
   printf  "\nbacked up $count procedures in ./$dir\n"
fi 
}

# Call to the functions
function RUN()
{
   BACKUP_TYPE
   BACKITUP
}

# let's go!
RUN
