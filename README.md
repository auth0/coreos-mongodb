Deploy a replicaset to coreos like a boss.
Auto-discover new members via etcd.

## Deploy

```
etcdctl set /mongo/replica/name myreplica

fleetctl destroy mongo@{1..3}.service mongo-data@{1..3}.service
fleetctl destroy mongo-replica-config.service 

fleetctl start mongo-data@{1..3}.service
fleetctl start mongo@{1..3}.service mongo-replica-config.service
```

## Connect

You can test connecting to your replica from one of your nodes as follows:

```
SITE_ROOT_PWD=$(etcdctl get /mongo/replica/siteRootAdmin/pwd)
REPLICA=$(etcdctl get /mongo/replica/name)
FIRST_NODE=$(fleetctl list-machines --no-legend | awk '{print $2}' | head -n 1)
alias mongo="docker run -it --rm mongo:2.6 mongo $REPLICA/$FIRST_NODE/admin -u siteRootAdmin -p $SITE_ROOT_PWD"

mongo

$ Welcome to the MongoDB shell.
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