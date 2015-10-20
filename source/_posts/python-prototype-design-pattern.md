title: 在python实现中prototype设计模式
date: 2015-10-20 13:20:42
author: zeno
tags:
- zeno
- python
- monkey patch
---

这几天在看[《松本行弘的程序世界》](http://www.ituring.com.cn/book/727)，这本书主要讲语言设计，初学编程的人看了也会加深很多对计算机语言的理解。

其中也有一笔讲到了23种设计模式，当我读到“原型模式”（prototype）时，惊讶地发现javascript在解决如何面向对象编程这个问题上就使用了这种灵巧的方案。但python并没有提供对prototype原生的支持。

我顺便搜阅了下有没有别人已经实现了python的prototype模式。百度搜到的方法大都是直接使用python自带的`clone`库中深复制与浅复制的方法对对象进行复制，而对于关键的动态绑定属性和方法的办法，却没有提到。所以作为一个python菜鸟我打算自己实现一个，也可以练练手。
<!-- more -->
---

> 引用《设计模式》一书中的解释，Prototype模式“明确一个实例作为要声称对象的种类原型，通过复制该实例来生成新的对象”。

粗略地解读，与通过类来生成实例这种传统的面向对象的实现方法不同，原型模式无需定义更加抽象的“类”，仅仅是通过已经定义好的实例，通过复制其本身的方式即可生成新的对象已达到复用的目的，较之通过类的方式实现面向对象更加灵动。

在目前最火的脚本语言javascript中，原生就仅仅是采用这种模式来实现面向对象。我觉得这是十分聪明的做法，对于javascript最经常使用的途径（页面脚本）中，需要专门的去定义一个类才能达到复用的目的无疑是臃肿的。

说这么多，让我们用另一门支持原型模式的微型脚本语言Io来实际体会一下原型模式到底是怎样的吧：
```
Dog := Object clone  // 复制原型object
Dog sit := method("i'm siiting.\n" print)  // 狗会坐，所以给狗绑定“坐”的方法
myDog := Dog clone  // 从对象“狗”复制出对象“我的狗”
myDog sit  // 我的狗也会坐
myDog run := method("i'm running\n" print) // 我的狗还会跑，绑定“跑”方法
```
由此可见这是种多么省事的面向对象的实现方法。而且可以看出真正的原型模式是只有动态语言才可以真正完成并实现的。动态地生成对象并且动态地为对象追加属性和方法，从而达到继承的目的。

初步了解了原型模式以后就可以来尝试在python下实现它。最容易联想到的方法就是直接从创建object类的实例。尝试一下：`a = object()`发现并没有报错，但是试着给a对象绑定方法时就会发现：
```python
a = object()
a.b = 1
"""
---------------------------------------------------------------------------
AttributeError                            Traceback (most recent call last)
<ipython-input-30-fc899ab026fb> in <module>()
----> 1 a.b = 1

AttributeError: 'object' object has no attribute 'b'
"""

a.__setattr__('b', 1)
"""
---------------------------------------------------------------------------
AttributeError                            Traceback (most recent call last)
<ipython-input-32-1de990c7f917> in <module>()
----> 1 a.__setattr__('b', 1)

AttributeError: 'object' object has no attribute 'b'
"""

```
直接从object实例化的对象是没有办法绑定任何属性和方法的，具体为何这样规定我还在研究当中。所以我们必须新建一个类，所有原型都应该是这个类的实例，然后我们尝试给这个实例动态的绑定方法：
```python
class Prototype(object):
    pass

a = Prototype()

a.b = 1

a.b
"""
1
"""

def c(self):
    print self.b

a.c = c

a.c()
"""
---------------------------------------------------------------------------
TypeError                                 Traceback (most recent call last)
<ipython-input-39-7109f4e3472a> in <module>()
----> 1 a.c()

TypeError: c() takes exactly 1 argument (0 given)
"""
```
属性的绑定没有任何问题，但是按照最直接的想法去绑定方法却出现问题了。检查`a.c`的类型可以发现，`a.c`是Function类型而不是Boundmethod，python把它当做函数而不是方法处理了，原因也很简单，python当中函数也是可以被赋值的，`a.c = c`这样的做法会被python当做给实例绑定属性，只不过这个属性的值是函数而已。所以我们需要把函数的类型转换成类方法，可以使用`types`这个内置的函数达到目的（接上文）：
```python
import types

a.c = types.MethodType(c, a)

a.c
"""
<bound method ?.c of <__main__.c instance at 0x7f73d87b6248>>
"""
a.c()
"""
<__main__.c instance at 0x7f73d87b6248>
"""
```
成功了，因为python的猴子补丁(monkey patch)特性，可以很轻松的就给实例打上补丁。现在我们可以尝试把这种做法包装成Protoype类的类方法，方便调用：
```python
import types
import copy


class Prototype(object):
    def copy(self):
        return copy.copy(self)

    def deepcopy(self):
        return copy.deepcopy(self)

    def add_method(self, func):
        self.__dict__[func.__name__] = types.MethodType(func, self)
        def decorator(*args, **kw):
            raise NameError("name '{0}' is not defined".format(func.__name__))
        return decorator

```
这样我们就可以这样调用来绑定方法：
```python
import Prototype


a = Prototype()

@a.add_method
def b(self):
    print self

a.b()
```
但是如果直接调用`b()`就会抛出一段错误`NameError: name 'b' is not defined`，这样可以防止意外地在外部调用被绑定的方法。

---
这样基本的原型模式就完成了，当然很粗糙，比方说装饰器目前没法支持绑定静态方法，以后会再慢慢改进。
