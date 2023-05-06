---
title: 微信整合chat-gpt自动回复
categories:
- 日记本
---
通过开源项目实现 https://github.com/fuergaosi233/wechat-chatgpt

docker启动命令如下
```
docker run -d --name wechat-chatgpt \
    -e OPENAI_API_KEY="填写自己的gpt-key" \
    -e MODEL="gpt-3.5-turbo" \
    -e CHAT_PRIVATE_TRIGGER_KEYWORD="" \
    -v /root/docker/wechat-chatgpt/data:/app/data/wechat-assistant.memory-card.json \
    holegots/wechat-chatgpt:latest
```

启动后查看容器日志`docker logs wechat-chatgpt`
日志中会打印微信登录的二维码，扫码登陆即可。
