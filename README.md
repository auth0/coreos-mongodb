Deploy a replicaset to coreos like a boss.
Auto-discover new members via etcd.

## Deploy

```
etcdctl set /mongo/replica/name myreplica

fleetctl destroy mongo@1.service
fleetctl destroy mongo@{1..3}.service mongo-data@{1..3}.service
fleetctl destroy mongo-replica-config.service 

fleetctl start mongo-data@{1..3}.service mongo@{1..3}.service mongo-replica-config.service
```

## Connect

You can test connecting to your replica from one of your nodes as follows:

```
fleetctl-ssh

COREOS_PRIVATE_IPV4=xx.xx.xx.xxx; echo $COREOS_PRIVATE_IPV4

SITE_USR_ADMIN_PWD=$(etcdctl get /mongo/replica/siteUserAdmin/pwd); echo $SITE_USR_ADMIN_PWD

SITE_ROOT_PWD=$(etcdctl get /mongo/replica/siteRootAdmin/pwd); echo $SITE_ROOT_PWD

docker run -it --rm mongo:2.6 mongo $COREOS_PRIVATE_IPV4/admin  -u siteRootAdmin -p $SITE_ROOT_PWD


$ Welcome to the MongoDB shell.
```


### Trouble shooting

In my shell rc file (~/.zsh_aliases)
```
fleetctl-switch(){
  ssh-add ~/.docker/certs/key.pem
  DOCKER_HOST=tcp://$1:2376
  export FLEETCTL_TUNNEL=$1:22
  alias etcdctl="ssh -A core@$1 'etcdctl'"
  alias fleetctl-ssh="fleetctl ssh $(fleetctl list-machines | cut -c1-8 | sed -n 2p)"
  RPROMPT="%{$fg[magenta]%}[fleetctl:$1]%{$reset_color%}"
}
destroy_mongo_replica() {
  export FLEETCTL_TUNNEL=$1:22
  fleetctl destroy mongo@{1..3}.service
  fleetctl destroy mongo@.service
  fleetctl destroy mongo-replica-config.service
  fleetctl destroy mongo-data@{1..3}.service
  etcdctl rm /mongo/replica/siteRootAdmin --recursive
  etcdctl rm /mongo/replica/siteUserAdmin --recursive
  etcdctl rm /mongo/replica --recursive
  etcdctl set /mongo/replica/name myreplica

  echo 'Listing etcd /mongo dirs...'
  ssh -A core@$1 'etcdctl ls /mongo --recursive';

  echo Listing $1 /var/mongo
  ssh -A core@$1 'sudo rm -rf /var/mongo/*'
  ssh -A core@$1 'ls /var/mongo/'

  echo Listing $2 /var/mongo
  ssh -A core@$2 'sudo rm -rf /var/mongo/*'
  ssh -A core@$2 'ls /var/mongo/'

  echo Listing $3 /var/mongo
  ssh -A core@$3 'sudo rm -rf /var/mongo/*'
  ssh -A core@$3 'ls /var/mongo/'
}
```

To start,
```
fleetctl-switch xx.xx.xx.xx
fleetctl start mongo@{1..3}.service mongo-replica-config.service
```

To see what's going on in a server,
```
fleetctl-ssh
```

To delete all mongodb files,
```
destroy_mongo_replica <cluser ip 1> <cluser ip 2> <cluser ip 3>
```

## How it works?

The units follow the process explained in this [tutorial](http://docs.mongodb.org/manual/tutorial/deploy-replica-set-with-auth/).

I've split the process in 3 different phases.

### Phase 1

During the initial phase, mongo needs to be run without the authentication option and without the keyFile.

We just run the first node of the replicaset while the other are waiting the key file in etcd.

-  The `siteUserAdmin` and `siteRootAdmin` are created on the first node with random passwords stored in etcd.
-  The keyfile is generated and added to etcd.
-  All mongodb are started.

### Phase 2

During the second phase, we have all the nodes of the replica running and ready to bind each other.

-  `rs.initiate` is run in the first node.
-  `rs.add` is run for every node except the fisrt one which is automatically added.

### Phase 3

The third phase is the final state, we keep watching etcd for new nodes and these new nodes.

## Destroy and revert everything

```
# remove all units
$ fleetctl destroy mongo@{1..3}.service
$ fleetctl destroy mongo-replica-config.service
# or
$ fleetctl list-units --no-legend | awk '{print $1}' | xargs -I{} fleetctl destroy {}

# clean directories
$ fleetctl list-machines --fields="machine" --full --no-legend | xargs -I{} fleetctl ssh {} "sudo rm -rf /var/mongo/*"

(from inside one of the nodes)
$ etcdctl rm /mongo/replica/key
$ etcdctl rm --recursive /mongo/replica/siteRootAdmin
$ etcdctl rm --recursive /mongo/replica/siteUserAdmin
$ etcdctl rm --recursive /mongo/replica/nodes
```

## License

MIT - Copyright (c) 2014 AUTH0 INC.