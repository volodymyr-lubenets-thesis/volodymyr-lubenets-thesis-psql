HCLOUD_TOKEN=${HCLOUD_TOKEN:-"dummy000000"}
SERVER_IMAGE=${SERVER_IMAGE:-"ubuntu-18.04"}
NETWORK_NAME=${NETWORK_NAME:-"test_cluster_LAN"}
SSH_KEY_NAME=${SSH_KEY_NAME:-"test_cluster_ssh"}
SERVER_TYPE=${SERVER_TYPE:-"cx11"}
HETZNER_LOCATION=${HETZNER_LOCATION:-"hel1"}

SSH_KEY_PATH=$1

if [ -z $1 ]; then
  echo "Usage info:"
fi

# create LAN for the test cluster in the project and create a subnet to attach servers to

hcloud network create --ip-range 192.168.50.0/24 --name $NETWORK_NAME
hcloud network add-subnet $NETWORK_NAME --ip-range 192.168.50.0/24 --network-zone eu-central --type server

# create hash table for hostname to LAN address mapping

declare -A serverip

serverip=(
["sd001"]="192.168.50.11"
["sd002"]="192.168.50.12"
["sd003"]="192.168.50.13"
["db001"]="192.168.50.21"
["db002"]="192.168.50.22"
["db003"]="192.168.50.23"
["dr001"]="192.168.50.31"
["mon001"]="192.168.50.41"
["ansible001"]="192.168.50.51"
)

# create an ssh key to be pre-installed to the servers

hcloud ssh-key create --name $SSH_KEY_NAME --public-key-from-file $SSH_KEY_PATH.pub

# create servers in a loop with parameters, attach them to network with predefined address and start

for host in ${!serverip[@]}; do
  #echo ${serverip["$host"]}
  hcloud server create --image $SERVER_IMAGE --location $HETZNER_LOCATION --ssh-key $SSH_KEY_NAME --type $SERVER_TYPE --name $host --start-after-create="false";
  hcloud server attach-to-network --ip=${serverip["$host"]} --network=$NETWORK_NAME $host;
  hcloud server poweron $host;
done

