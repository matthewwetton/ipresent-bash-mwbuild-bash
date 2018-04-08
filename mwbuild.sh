#!/bin/bash

#Version : V0.1

appname="myappc"
router="router-$appname-01"
network="net-$appname-01"
subnet="subnet-$appname-01"
port="routerport-$appname-01"
serverindex=1
ipblock="192.168.$serverindex.0/24"
servercount=3
servernameprefix="server-$appname-"
summary="\nSUMMARY\n"

function create_network {
  # Demo has max net ports 10

  # Get external gateway 'public'
  externalgateway=$(openstack network list | awk '/public/{print $2}')

  # Create Router
  openstack router create $router

  # Edit Router
  openstack router set $router --external-gateway $externalgateway --enable-snat

  # Create Network
  openstack network create $network 

  # Create Subnet
  openstack subnet create $subnet --subnet-range $ipblock --network $network --dhcp

  # Create Port
  openstack port create $port --network $network 

  # Associate Port
  openstack router add port $router $port
}

function create_server {
  # Demo has max of 3 servers. Max ram just under 8GB each server needs 2GB.

  servername="$servernameprefix$serverindex"
  
  # Create Server
  imageid=$(openstack image list | awk '/Ubuntu 16.04 LTS/{print $2}')
  openstack server create --flavor m1.small \
	                  --image $imageid \
			  --nic net-id=$network \
			  --security-group default \
			  --key-name mxkey01 $servername

  # Create IP from public pool
  # pool exceeded release first code needs to check
#  openstack floating ip create public

  # Get IP
  mynextip=$(openstack floating ip list | awk '/None/{print $4}' | head -1)

  # Get IP ID
  mynextipid=$(openstack floating ip list | awk '/None/{print $2}' | head -1)

  # Associate floating IP
  openstack server add floating ip $servername $mynextipid

  # Echo server name and IP address.
  loopsummary="Server Created : $servername IP : $mynextip"
  summary="$summary \n $loopsummary"
  echo -e $summary
}


create_network

serverindex=$((serverindex + 1))
create_server
serverindex=$((serverindex + 1))
create_server
serverindex=$((serverindex + 1))
create_server


exit 0
