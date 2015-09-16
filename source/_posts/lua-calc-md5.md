title: 用lua计算MD5
date: 2015-09-15 20:44:52
author: revol
tags:
- lua
- MD5
---

lua生来就非常快速、轻量，并且与C结合紧密。这使其非常适合用在性能和存储空间紧缺的嵌入式设备里。这也是其标准库这么小的原因。

lua的标准库可谓是非常“简陋”，由其是对比python这种以库丰富见称的语言来说。这对我们使用lua来开发造成了很大的不便：我们得像使用C一样到处去寻找我们需要的库，如果没有还得自己写。

我在实现一个加密算法的时候就遇到了这样的问题。算法中需要计算给定字符串的MD5值，然而lua标准库中并没有提供hash库。经过一番查资料我找到了这么几种方案。

## 1.使用纯lua实现的MD5算法

纯lua最大的优势就是跨平台了，在我的笔记本上能跑起来，在嵌入式机器上就能。最开始在stackoverflow上找到了一段代码，可是运行速度奇慢。当时便放弃了这个方案。写这篇文章的时候找到一个库 [MD5.lua](https://github.com/kikito/md5.lua) 貌似没有什么性能问题。

不过在我主要加密算法只有十几行的情况下加上几百行的MD5库还是有点不爽的。

## 2.用C扩展库

lua的C扩展就有很多了，如[MD5](https://luarocks.org/modules/tomasguisasola/md5)和SSL库[luacrypto](https://luarocks.org/modules/luarocks/luacrypto)

这些库都可以很方便的使用lua的包管理工具[luarocks](https://luarocks.org)来安装。

然而C库在跨平台时需要编译，交叉编译是很麻烦的事。

## 3.使用io:popen()

考虑过以上两个方案之后，我灵机一动想到了这个方法。

md5sum隶属于GNU coreutils。作为非常常用的工具，几乎所有的linux发行版包括busybox都会自带。所以利用系统自带的工具就顺理成章了。

```lua
function md5sum(str)
  str=str:gsub("[\"\'\`]","\\%1"):sub(1)
  return io.popen('echo -n "'..str..'"|md5sum'):read("*all"):sub(1,-5)
end
```
上面这个函数不仅十分精炼而且实测速度非常快。

要知道linux系统一般还自带base64、sha1sum、sha256sum、sha512sum等一系列工具。所以将上面的函数稍加改动就可以实现很多其他的功能。
