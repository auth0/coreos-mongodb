Running without using fleet unit files.

```
docker pull jaigouk/data-only-container

docker run -d --name mongo-data jaigouk/data-only-container

docker run --rm -p 27017:27017 --name mongodb \
    --volumes-from mongo-data \
        jaigouk/mongodb-container:latest


docker run -t --rm --volumes-from mongo-data1 \
--entrypoint="mongo" jaigouk/mongodb-container $COREOS_PRIVATE_IPV4/admin \
--eval "db.createUser({user:'siteUserAdmin', pwd:'$SITE_USR_ADMIN_PWD', roles: [{role:'userAdminAnyDatabase', db:'admin'}]});"

```




docker run -t --rm --volumes-from mongo-data1 \
--entrypoint="mongo" jaigouk/mongodb-container $COREOS_PRIVATE_IPV4/admin  -u siteRootAdmin -p $SITE_ROOT_PWD

