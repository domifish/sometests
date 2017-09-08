leaders="leader1"
workers="worker1 worker2"


for leader in $leaders; do
  # Creating leader
  docker-machine create \
  --driver virtualbox \
  $leader

  docker-machine start $leader
  ip_leader=$(docker-machine ip $leader)

  # initializing swarm cluster
  eval "$(docker-machine env $leader)"

  docker swarm init \
  --listen-addr $ip_leader \
  --advertise-addr $ip_leader

  token=$(docker swarm join-token worker -q)
done


for worker in $workers; do
  # Creating all workers needed
  docker-machine create \
  --driver virtualbox \
  $worker

  docker-machine start $worker

  # joining swarm cluster
  eval "$(docker-machine env $worker)"

  docker swarm join \
    --token $token \
    $ip_leader:2377
done

eval "$(docker-machine env $leader)"

docker network create \
  -d overlay --subnet 10.1.9.0/24 \
  multi-host-net

eval "$(docker-machine env $leader)"

docker service create \
  --name=viz \
  --publish=5051:8080/tcp \
  --mount=type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
  --constraint=node.role==manager \
  dockersamples/visualizer
