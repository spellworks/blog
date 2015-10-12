title: WebSocket原理介绍
date: 2015-10-12 15:9:52
author: Lulus
tags:
- Lulus
- WebSocket
- 网络通信
---

# WebSocket原理介绍

>WebSocket是HTML5开始提供的一种在单个 TCP 连接上进行全双工通讯的协议。WebSocket通讯协议于2011年被IETF定为标准RFC 6455，WebSocketAPI被W3C定为标准。
>在WebSocket API中，浏览器和服务器只需要做一个握手的动作，然后，浏览器和服务器之间就形成了一条快速通道。两者之间就直接可以数据互相传送。
<!-- more -->

## **流程**：
![WebSocket的建立流程](http://img.bbs.csdn.net/upload/201310/01/1380636719_348343.png)


如果只需要了解WebSocket,上面的图应该就足够了,它包含以下信息:

WebSocket的协议须通过HTTP请求建立(请求方式必须为GET,具体的握手协议属于高级内容).
WebSocket的消息体被前缀(0x00)和后缀(0xff)包裹起来.
消息体为空,则相当于告诉服务器可以断开连接了.
接下来稍微深入一点点,以下内容纯属**个人理解**,如果有理解错误敬请指正!

## **握手协议**:

　　客户端请求建立握手协议:

>GET / HTTP/1.1                                    　　//自此可以看出WebSocket>是**建立在Http协议之上**的
>Upgrade: websocket                                　　//Upgrade头域内容:websocket;告诉服务器需要升级到什么协议
Connection: Upgrade                               　　//Connection头域内容:Upgrade;控制可选操作为Upgrade
Host: example.com    　　　　　　　　　　　　　　　　　　　//服务器主机地址
Origin: null　　　　　　　　　　　　　  　　　　　　　　　　//来源地址
Sec-WebSocket-Key: sN9cRrP/n9NdMgdcy2VJFQ==　　　　　　//连接加密字符串
Sec-WebSocket-Version: 13　　　　　　　　　　　　　　 　　//WebSocket协议版本

`注: WebSocket 协议并不是 HTTP 协议, 只是它的建立依赖于 HTTP.`

　　服务器返回结果:
>HTTP/1.1 101 Switching Protocols　　　　　　　 　  //状态码101,服务器理解了客户端升级协议的请求
Upgrade: websocket　　　　　　　　　　　　　　　　　　 　　//协议将升级到WebSocket
Connection: Upgrade　　　　　　　　　　　　　　　　　　　　//控制可选操作为Upgrade
Sec-WebSocket-Accept: fFBooB7FAkLlXgRSz0BT3v4hq5s=　　//根据客户端发送的key生成的加密值
Sec-WebSocket-Origin: null　　　　　　　　　　　　　　　　//来源地址
Sec-WebSocket-Location: ws://example.com/　　　　　　  //WebSocket通信的地址

## **消息报文格式**
感谢http://www.cnblogs.com/smark/archive/2012/11/26/2789812.html....
数据交互协议:

![WebSocket交互协议](http://pic002.cnblogs.com/images/2012/254151/2012112621310879.jpg)

这图有点难看懂...里面包括几种情况:有掩码,数据长度小于126,小于UINT16和小于UINT64等几种情况.下面会慢慢详细说明.

整个协议头大概分三部分组成:

1. 描述消息结束情况(FIN)和消息类型(opcode).
2. 描述是否存在掩码(0 or 1,对应有无掩码).
3. 扩展长度描述和掩码值.

从图中可以看到WebSocket协议数据主要通过头两个字节来描述数据包的情况

### **第一个部分:第一个字节**

1. 最高位(FIN)用于描述消息是否结束,如果为1则该消息为消息尾部,如果为零则还有后续数据包.
2. 后面3位是用于扩展定义的,如果没有扩展约定的情况则必须为0.
3. 后面4位(opcode)用于描述消息类型,消息类型暂定有15种,其中有几种是预留设置:

|Opcode|Meaning|Reference|
|:--------|:--------|:--------|
|0|Continuation Frame|RFC6455|
|1|Text Frame|RFC6455|
|2|Binary Frame|RFC6455|
|8|Connection CloseFrame|RFC6455|
|9|Ping Frame|RFC6455|
|10|Pong Frame|RFC6455|

大概是这样, 不过值得注意的是, `不同浏览器对 WebSocket 的支持状态不一样,具体的状况大家踩了坑之后就能明白. 本人因为涉入不深, 所以踩坑情况还好.`
### **第二个部分:第二个字节**

1. 最高位用0或1来描述是否有掩码处理.
2. 剩下的7位用来描述消息长度,由于7位最多只能描述127所以这个值会代表三种情况:
2.1. 消息长度少于126,此7位存储消息长度;
2.2. 消息长度少于UINT16(65535):此7位为1111110,消息长度存储到紧随后面的2位byte;
2.3. 消息长度大于等于UINT16(65535):此7位为1111111,消息长度存储到紧随后面的4位byte.

### **第三个部分:之后到末尾**

基本属于消息体部分.
1. 后续字节:
1.1 mask位为1:第四第五个字节为掩码值,之后为消息体
1.2 mask位为0:之后全部为消息体

## **消息内容解读(实战)**

### **1. 建立连接:**
建立连接的js:
```js
var ws = new WebSocket("ws://169.254.80.80:4141/chat")
```
发送的请求具体就是这个样子:

>GET /chat HTTP/1.1
>Host: 169.254.80.80:4141
>Connection: Upgrade
>Pragma: no-cache
>Cache-Control: no-cache
>Upgrade: websocket
>Origin: null
>Sec-WebSocket-Version: 13
>DNT: 1
>User-Agent: Mozilla/5.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/45.0.2454.101 Safari/537.36
>Accept-Encoding: gzip, deflate, sdch
>Accept-Language: zh-TW,zh;q=0.8,zh-CN;q=0.6,ja;q=0.4,en-US;q=0.2,en;q=0.2
>Sec-WebSocket-Key: m4f7USc2fwph0DTHm48PHg==
>Sec-WebSocket-Extensions: permessage-deflate; client_max_window_bits


### **2. 发送文字消息(以"123"为例)**
 |字节序列|    数值           | 二进制值 |解读|
 | :-------- | :--------| :-- |:--|
 |1         | 129               | 10000001  |没有后续数据包，消息类型为Text Frame|
 |2      | 131                          | 10000011  |有掩码处理，消息体长度为3个字节(11)|
 |3      | 155                      | 10011011  |掩码第一个字节
 |4      | 245              | 11110101  |掩码第二个字节
 |5      | 102                          | 01100110  |掩码第三个字节
 |6      | 193                          | 11000001  |掩码第四个字节
 |7      | 170                          | 10101010  |消息体长度为3,消息体第一个字节
 |8      | 199                          | 11000111  |消息体第二个字节
 |9      | 85                          | 01010101  |消息体第三个字节
要计算掩码加密后的消息内容,可以采用以下方式
C#:
```csharp
public byte[] Mask(byte[] data, byte[] mask)
{
	for (var i = 0; i < data.Length; i++)
	{
	    data[i] = (byte)(data[i] ^ mask[i % 4]);
	}
	return data;
}
```
python:
```python
def mask(data,mask):
	for i in xrange(0,len(data)):
		data[i] = data[i] ^ mask[i % 4]
	return data
```
用以上的方式来解码我们的消息体"123":
![消息解码结果](http://images2015.cnblogs.com/blog/646414/201510/646414-20151012153322101-1069360964.png)
再把以上的49,50,51,转为char,就得到了'1','2','3'.

#### **3. 关闭连接**
 |字节序列|    数值           | 二进制值 |解读|
 | :-------- | :--------| :-- |:--|
 |1         | 136               | 10001000  |没有后续数据包，消息类型为Connection Close Frame|
 |2      | 128                          | 10000000  |有掩码处理，消息体长度为0个字节(当然掩码这里没有意义了)|


以上~~~后面是一些关于我在过程中遇到一些问题的其他说明:

>1. 各个浏览器对 WebSocket 的支持情况不一样! 各个浏览器对 WebSocket 的支持情况不一样! 各个浏览器对 WebSocket 的支持情况不一样! 因为很重要所以要说三遍! IE浏览器下可以检测到定时的心跳包(opcode=10),而在Chrome和火狐下面则没有发现, 本人表示很奇怪.
>2.  360浏览器在断开连接之后再次连接, 一定几率出现消息头长度检测的错乱.
>3. IE9及以下版本浏览器不兼容 WebSocket 协议(貌似可以通过Flash仿制一个, 没有深入研究).
>4. WebSocket 一点都不好玩, 还是直接用现有框架的好.
>5. WebSocket 的 Mask 还真是掩耳盗铃啊, 不过貌似现在都是"防君子不防小人"的说?





 
 