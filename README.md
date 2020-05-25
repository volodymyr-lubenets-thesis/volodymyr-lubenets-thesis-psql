# Automated deployment of a reliable PostgreSQL cluster

## Testing environment guide

Here is the algorithm to deploy test environment on Hetzner cloud infrastructure.
This guide implies that user has already created a Hetzner cloud project and has API key for it and AWS IAM credentials authorized to write to AWS bucket.

### Generating keys and credentials

1. Create the folder "authdata"
1. In there, create the files `.env` and `ansible_vault_key`
1. In `ansible_vault_key`, supply a random alphanumeric string
1. In `.env`, supply the following:

    ```bash
    export HCLOUD_TOKEN=<hetzner API key string>
    export ANSIBLE_VAULT_PASSWORD_FILE=authdata/ansible_vault_key
    ```

1. Execute `ssh-keygen` and supply `./ssh/test_cluster` as a path for keypair generation.
1. In the file `i_postgres_cluster/group_vars/postgres-nodes.yml` find the line `postgres_pitr_credentials_aws_key_id` and `postgres_pitr_credentials_aws_access_key`.
1. Execute `. ./authdata/.env`
1. Execute the following, put in the key ID and secret:

    ```bash
    ansible-vault encrypt_string --stdin-name postgres_pitr_credentials_aws_key_id
    ansible-vault encrypt_string --stdin-name postgres_pitr_credentials_aws_access_key
    ```

1. Copy produced encrypted values to YAML file mentioned before.
1. Export your preferred GPG key for backup encryption in armored form along with its ownertrust file and paste them to `postgres_pitr_gpg_pubkey` and `postgres_pitr_gpg_ownertrust` respectively.

Now the setup is done.

### Provisioning the test environment

1. Execute the `./hetzner_init/init_test_cluster.sh` script.
1. Create the root session on your machine, execute `. ./authdata/.env`
1. Run `./ssh_vpn_preconfig.sh`
1. Run `./ssh_vpn_start.sh` and let it be running for the whole time of the setup
1. Create one more root session with `. ./authdata/.env` and run `./ssh_vpn_postconfig.sh`

### Setting up the consul cluster

1. Preconfigure the nodes, setup the firewall and consul. Run the following:

    ```bash
    ansible-playbook -i i_consul_cluster t_preconfig/preconfig.yml
    ansible-playbook -i i_consul_cluster t_firewall/firewall.yml
    ansible-playbook -i i_consul_cluster t_consul/consul-server.yml
    ansible-playbook -i i_consul_cluster t_consul/consul-agent.yml
    ```

1. Optionally check that you are able to ping `db001.node.postgres.cluster.test`

### Setting up the postgreSQL cluster

1. Run the following:

    ```bash
    ansible-playbook -i i_postgres_cluster t_postgres/postgres-installation.yml
    ansible-playbook -i i_postgres_cluster t_postgres/postgres-replication.yml
    ansible-playbook -i i_postgres_cluster t_postgres/postgres-pitr.yml
    ```

1. Check that you are able to execute `repmgr daemon status` as user postgres on db001.node.postgres.cluster.test and repmgrd is running on all cluster machines.

### Setting up monitoring

1. Run the following:

    ```bash
    ansible-playbook -i i_postgres_cluster t_monitoring/node-exporter.yml
    ansible-playbook -i i_postgres_cluster t_monitoring/postgres-telegraf.yml
    ansible-playbook -i i_postgres_cluster t_monitoring/prometheus-setup.yml
    ansible-playbook -i i_postgres_cluster t_monitoring/grafana-setup.yml
    ```

1. Now prometheus is accessible at mon001.node.postgres.cluster.test:9090 and grafana on mon001.node.postgres.cluster.test:3000. Verify both grafana dashboards work.

## Testing the failover

Install `apt install postgresql-9.6-client` if you have not done that on your machine.

Now you can test the database connection with the script `./db_tester.sh` and killing the master server. The default behavior will be expressed in losing connection for 2 minutes and automatically restoring it after this time, as automatic failover will be activated.
