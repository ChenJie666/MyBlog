---
title: 使用Docker-Swarm实现跨宿主机容器间访问
categories:
- Docker
---
 ###背景：
  在SerA服务器，运行了一个任务调度系统xxl容器ConA。
  在SerB服务器，运行了一个SpringBoot服务ConB，注册到任务调度系统中。
  在任务调度系统中，看到的调度器节点IP是SerB服务器分配给ConB容器的IP地址。 导致任务调度系统调度失败，提示ConB地址链接不上。
  分析下来，是由于ConA和ConB是跨宿主机的容器，无法通信。
  网上看到了很多方案，也试用了包括Overlay网络、OpenvSwitch、consul方案。
  最终使用Docker Swarm解决了，发现很简单，过程如下。

#####1. 初始化swarm
  在主节点运行docker swarm init，初始化swarm。
  ```
  docker swarm init
  # Swarm initialized: current node (0r4xjgtu4nd9txrsbfn1lo5gu) is now a manager.
  #
  # To add a worker to this swarm, run the following command:
  #
  #    docker swarm join \
  #    --token SWMTKN-1-0q35cj5j0va82a0t3mhkbesirqb6lqgqlkmznbwx1ojbou4u75-ejrors77ezcw25nmy9g90u9a0 \
  #    172.16.0.226:2377
  #
  # To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.
  ```
#####2. 创建Overlay网络
  在主节点，创建overlay模式网络。
  ```
  docker network create --driver=overlay --gateway 192.168.1.1 --subnet 192.168.1.0/24 --attachable my_network
  # m3k69pn88gtre361upi
  ```
  可以通过docker network ls命令，查看网络列表。
  ```
  docker network ls
  # NETWORK ID          NAME                DRIVER              SCOPE
  # acaeb6e14a1e        bridge              bridge              local
  # a8e5fdd055b9        docker_gwbridge    bridge              local
  # b50eb414bcb4        host                host                local
  # om6lst4j52go        ingress            overlay            swarm
  # m3k69pn88gtr        my_network          overlay            swarm
  # 0c76adacfcfc        none                null                local
  ```
#####3. 子节点加入集群
  复制上面初始化swarm命令结果中的语句，在子节点运行即可。
  ```
  docker swarm join \
  --token SWMTKN-1-va82a0t3mhkbesirqb6lqgqlkmznbwxu4u75-ejrors790u9a0 \
  172.16.0.226:2377
  # This node joined a swarm as a worker.
  ```
  可以在主节点，通过docker node ls命令，查看节点列表。
  ```
  docker node ls
  # ID                        HOSTNAME          STATUS  AVAILABILITY  MANAGER STATUS
  # 0r4xjgtu4nd9tsbfn1lo5gu *  ecs-01            Ready  Active        Leader
  # s67afk1e9nx0174yeqff6g2    ecs.h02          Ready  Active 
  ```
#####4. 运行容器加入网络
  在容器运行命令中，加入--network my_network --ip 192.168.1.123即可。
  ```
  docker run -it -d --network my_network --ip 192.168.1.123 ubuntu
  ```
