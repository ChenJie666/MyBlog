---
title: Nexus搭建
categories:
- 工具
---
启动nexus容器
```
mkdir -p /root/docker/nexus/data
chown -R 200:200 /root/docker/nexus/data
docker run -d -p 8081:8081 --name nexus -v /root/docker/nexus/data:/nexus-data sonatype/nexus3
```

访问： http://ip:8081

**推的时候需要注意一下几点**
- 是否允许匿名用户推送或用户是否有权限推送
- 仓库是否允许redeployment
- version是否和仓库要求的一致
