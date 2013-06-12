#!/bin/sh
#
# convert uci configuration into daemon specific format
#

UCI=/sbin/uci

create_file() {
	echo "# -- DO NOT EDIT THIS FILE --" > $1
	echo "# automatic generated configuration file for IBR-DTN daemon" >> $1
	echo "#" >> $1
}

add_param() {
	VALUE=`$UCI -q get $2`
	
	if [ $? == 0 ]; then
		echo "$3 = $VALUE" >> $1
	fi
}

getconfig() {
	$UCI -q get ibrdtn.$1
	return $?
}

if [ "$1" == "--safe-mode" ]; then
	SAFEMODE=yes
	CONFFILE=$2
else
	SAFEMODE=no
	CONFFILE=$1
fi

# create the file and write some header info
create_file $CONFFILE

add_param $CONFFILE "ibrdtn.main.uri" "local_uri"
add_param $CONFFILE "ibrdtn.main.timezone" "timezone"
add_param $CONFFILE "ibrdtn.main.routing" "routing"

if [ "$SAFEMODE" == "yes" ]; then
	if [ -n "`getconfig safemode.forwarding`" ]; then
		add_param $CONFFILE "ibrdtn.safemode.forwarding" "routing_forwarding"
	else
		add_param $CONFFILE "ibrdtn.main.forwarding" "routing_forwarding"
	fi

	if [ -n "`getconfig safemode.maxblock`" ]; then
		add_param $CONFFILE "ibrdtn.safemode.maxblock" "limit_blocksize"
	else
		add_param $CONFFILE "ibrdtn.main.blocksize" "limit_blocksize"
	fi

	if [ -n "`getconfig safemode.storage`" ]; then
		add_param $CONFFILE "ibrdtn.safemode.storage" "limit_storage"
	else
		add_param $CONFFILE "ibrdtn.storage.limit" "limit_storage"
	fi
else
	add_param $CONFFILE "ibrdtn.main.forwarding" "routing_forwarding"
	add_param $CONFFILE "ibrdtn.main.blocksize" "limit_blocksize"
	add_param $CONFFILE "ibrdtn.storage.limit" "limit_storage"
	add_param $CONFFILE "ibrdtn.storage.blobs" "blob_path"
	add_param $CONFFILE "ibrdtn.storage.bundles" "storage_path"
	add_param $CONFFILE "ibrdtn.storage.engine" "storage"
fi

add_param $CONFFILE "ibrdtn.main.max_predated_timestamp" "limit_predated_timestamp"
add_param $CONFFILE "ibrdtn.main.limit_lifetime" "limit_lifetime"

add_param $CONFFILE "ibrdtn.discovery.address" "discovery_address"
add_param $CONFFILE "ibrdtn.discovery.timeout" "discovery_timeout"
add_param $CONFFILE "ibrdtn.discovery.version" "discovery_version"
add_param $CONFFILE "ibrdtn.discovery.crosslayer" "discovery_crosslayer"

add_param $CONFFILE "ibrdtn.tcptuning.idle_timeout" "tcp_idle_timeout"
add_param $CONFFILE "ibrdtn.tcptuning.nodelay" "tcp_nodelay"
add_param $CONFFILE "ibrdtn.tcptuning.chunksize" "tcp_chunksize"

add_param $CONFFILE "ibrdtn.security.level" "security_level"
add_param $CONFFILE "ibrdtn.security.bab_key" "security_bab_default_key"
add_param $CONFFILE "ibrdtn.security.key_path" "security_path"

add_param $CONFFILE "ibrdtn.tls.certificate" "security_certificate"
add_param $CONFFILE "ibrdtn.tls.key" "security_key"
add_param $CONFFILE "ibrdtn.tls.trustedpath" "security_trusted_ca_path"
add_param $CONFFILE "ibrdtn.tls.required" "security_tls_required"
add_param $CONFFILE "ibrdtn.tls.noencryption" "security_tls_disable_encryption"
add_param $CONFFILE "ibrdtn.tls.fallback_badclock" "security_tls_fallback_badclock"

add_param $CONFFILE "ibrdtn.timesync.reference" "time_reference"
add_param $CONFFILE "ibrdtn.timesync.synchronize" "time_synchronize"
add_param $CONFFILE "ibrdtn.timesync.discovery_announcement" "time_discovery_announcements"
add_param $CONFFILE "ibrdtn.timesync.sigma" "time_sigma"
add_param $CONFFILE "ibrdtn.timesync.psi" "time_psi"
add_param $CONFFILE "ibrdtn.timesync.sync_level" "time_sync_level"
add_param $CONFFILE "ibrdtn.timesync.time_set_clock" "time_set_clock"

add_param $CONFFILE "ibrdtn.dht.enabled" "dht_enabled"
add_param $CONFFILE "ibrdtn.dht.port" "dht_port"
add_param $CONFFILE "ibrdtn.dht.id" "dht_id"
add_param $CONFFILE "ibrdtn.dht.bootstrap" "dht_bootstrapping"
add_param $CONFFILE "ibrdtn.dht.nodesfile" "dht_nodes_file"
add_param $CONFFILE "ibrdtn.dht.enable_ipv4" "dht_enable_ipv4"
add_param $CONFFILE "ibrdtn.dht.enable_ipv6" "dht_enable_ipv6"
add_param $CONFFILE "ibrdtn.dht.bind_ipv4" "dht_bind_ipv4"
add_param $CONFFILE "ibrdtn.dht.bind_ipv6" "dht_bind_ipv6"
add_param $CONFFILE "ibrdtn.dht.ignore_neighbour_informations" "dht_ignore_neighbour_informations"
add_param $CONFFILE "ibrdtn.dht.allow_neighbours_to_announce_me" "dht_allow_neighbours_to_announce_me"
add_param $CONFFILE "ibrdtn.dht.allow_neighbour_announcement" "dht_allow_neighbour_announcement"


# iterate through all network interfaces
iter=0
netinterfaces=
while [ 1 == 1 ]; do
	$UCI -q get "ibrdtn.@network[$iter]" > /dev/null
	if [ $? == 0 ]; then
		netinterfaces="${netinterfaces} lan${iter}"
		add_param $CONFFILE "ibrdtn.@network[$iter].type" "net_lan${iter}_type"
		add_param $CONFFILE "ibrdtn.@network[$iter].interface" "net_lan${iter}_interface"
		add_param $CONFFILE "ibrdtn.@network[$iter].port" "net_lan${iter}_port"
	else
		break
	fi
	
	let iter=iter+1
done

# write list of network interfaces
echo "net_interfaces =$netinterfaces" >> $CONFFILE

# iterate through all static routes
iter=0
while [ 1 == 1 ]; do
	$UCI -q get "ibrdtn.@static-route[$iter]" > /dev/null
	if [ $? == 0 ]; then
		PATTERN=`$UCI -q get "ibrdtn.@static-route[$iter].pattern"`
		DESTINATION=`$UCI -q get "ibrdtn.@static-route[$iter].destination"`
		let NUMBER=iter+1
		echo "route$NUMBER = $PATTERN $DESTINATION" >> $CONFFILE
	else
		break
	fi
	
	let iter=iter+1
done

#iterate through all static connections
iter=0
while [ 1 == 1 ]; do
	$UCI -q get "ibrdtn.@static-connection[$iter]" > /dev/null
	if [ $? == 0 ]; then
		let NUMBER=iter+1
		add_param $CONFFILE "ibrdtn.@static-connection[$iter].uri" "static${NUMBER}_uri"
		add_param $CONFFILE "ibrdtn.@static-connection[$iter].address" "static${NUMBER}_address"
		add_param $CONFFILE "ibrdtn.@static-connection[$iter].port" "static${NUMBER}_port"
		add_param $CONFFILE "ibrdtn.@static-connection[$iter].protocol" "static${NUMBER}_proto"
		add_param $CONFFILE "ibrdtn.@static-connection[$iter].immediately" "static${NUMBER}_immediately"
	else
		break
	fi
	
	let iter=iter+1
done
