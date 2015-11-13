#!/bin/sh

#export p_file="/root/conf/principals.csv"

##########################################
#		            Functions
##########################################

function create_principals {

   echo "Please enter CSV file name with absolute path: "
   read p_file
  
   while read cur_p
   do

     node=`echo "$cur_p" | cut -d"," -f1`
     principal=`echo \"$cur_p\" | cut -d',' -f3`
     kt_path=`echo "$cur_p" | cut -d"," -f6`
     dir=`echo "$kt_path" | sed 's/\/[^/]*$//'`
     kt_file=`echo "$kt_path" | sed 's/.*\///'`
     owner=`echo "$cur_p" | cut -d"," -f7`
     group=`echo "$cur_p" | cut -d"," -f9`
     perm=`echo "$cur_p" | cut -d"," -f11`

     if [[ "$node" == "host" || "$node" == "" ]] ; then
       continue
     fi

     echo "$perm $owner:$group $kt_file -- $node -- $principal"


     ssh -o StrictHostKeyChecking=no -f root@$node mkdir -p $dir
     ssh -o StrictHostKeyChecking=no -f root@$node chown root:hadoop $dir
     ssh -o StrictHostKeyChecking=no -f root@$node chmod 755 $dir


     echo "-------------------------------------"
     echo "creating principal: $principal"
     echo ""
  
     mkdir -p p_output/$node
     /usr/sbin/kadmin.local -q "addprinc -randkey $principal"
     /usr/sbin/kadmin.local -q "xst -norandkey -k p_output/$node/$kt_file $principal"           
 
     scp p_output/$node/$kt_file root@$node:$kt_path

     ssh -o StrictHostKeyChecking=no -f root@$node chown $owner:$group $kt_path
     ssh -o StrictHostKeyChecking=no -f root@$node chmod $perm $kt_path
 
  done < $p_file

  rm -rf p_output
}

##########################################
#		            MAIN
##########################################

create_principals

