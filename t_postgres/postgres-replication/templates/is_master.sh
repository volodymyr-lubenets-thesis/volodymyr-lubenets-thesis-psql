#!/bin/bash

# In this script we are getting the quorum of the pg nodes on how they see the requesting node.
# Before that, we exclude such exceptional cases as being slave itself (cannot be master by design)
# Then we iterate over all the nodes in cluster checking how they see us.
# If half of the cluster plus one machine (kind of 51%) thinks of us as "primary|t" (active master)
# Then we are most probably master, so we say exit 0 to consul agent and he exposes our address as active master. 
# IMPORTANT! repmgr_required_quorum_score variable should generally be set to (cluster_size/2)+1

result="$(psql -U postgres -c "select pg_is_in_recovery();" -At)" # Excluding node from possible masters by checking that it is slave.
if [ $result = "t" ]; then
        exit 2; # code 2 means hard error (failure) for consul. Code 1 means warning, so we don't use it here.
fi

my_primary_score=0
my_node_id=$(repmgr node status --csv | grep "Node ID" | cut -d, -f 2 | sed 's/"//g') # Getting node id in repmgr cluster
for host in {{ repmgr_master }}{% for slave in repmgr_slaves %} {{slave}}{% endfor %}{% for witness in repmgr_witnesses %} {{witness}}{% endfor %};
do
        resp=$(PGCONNECT_TIMEOUT=2 psql -h $host -U repmgr -d repmgr -c "select type,active from nodes where node_id = $my_node_id" -At;)
        if [ -z $resp ]; then # Making magic with repmgr database to query this and other nodes' view
                continue; # If no response 
        fi
        if [ $resp = "primary|t" ]; then # if our query returns active master state
                my_primary_score=$((my_primary_score+1)) # add up the score
        fi
done
if [ $my_primary_score -ge {{ repmgr_required_quorum_score }} ]; then
        exit 0;
else
        exit 2;
fi
