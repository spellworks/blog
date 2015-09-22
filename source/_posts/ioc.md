title: 面向对象设计中的控制反转
date: 2015-09-23 01:14:52
author: Lulus
tags:
- Lulus
- 依赖注入
- 控制反转
- 依赖查找
- 面向对象编程
---

> &#160; &#160; &#160; &#160; 控制反转（Inversion of Control，缩写为IoC），是面向对象编程中的一种设计原则，可以用来减低计算机代码之间的耦合度。其中最常见的方式叫做依赖注入（Dependency Injection，简称DI），还有一种方式叫“依赖查找”（Dependency Lookup）。通过控制反转，对象在被创建的时候，由一个调控系统内所有对象的外界实体，将其所依赖的对象的引用传递给它。也可以说，依赖被注入到对象中。
<!--more-->

------
###依赖注入:

即在类的外部传入类所需要的依赖。
举个通俗的栗子吧：有这么一辆车，开动需要轮子，可以用抓地好的，也可以用极速高的。

那么轮子(比如两种):

```c#
C#
public class HighSpeedTire : Tire
{
    //..........
    public override void Spin()
    {
        //Do something.
    }
}
```
        
```c#
C#:
public class HighGripTire : Tire
{
    //..........
    public override void Spin()
    {
        //Do something.
    }
}
```
但是我们事先不知道用什么轮子?


```c#
C#
public class Car
{
    public void Drive() 
    {
        Tire tire = ???
        tire.Spin();
    }
}
```
　　　　“？？？”该写什么呢？那么重载一下？万一之后又新增10种轮胎怎么办？

所以这个时候，依赖注入则可以解决这个问题:

```
C#
public class Car
{
    private Tire tire;
    public Car(Tire tire)//由外部控制所使用的轮子,此处为基于构造函数的依赖注入
    {
        this.tire = tire;
    }
    public void Drive() 
    {
        tire.Spin();
    }
}
```
之后，不管什么 tire 装上来都可以轻松应对！

------
###依赖查找

&#160; &#160; &#160; &#160; 相比依赖注入，依赖查找更加强调类主动获取自己所需要的属性，传统配置文件的实现，说白了也就是依赖查找。当然，这样解释也许并不能完全体现依赖查找的优势，接下来我将用WPF中的[依赖属性](https://msdn.microsoft.com/zh-cn/library/windows/apps/Hh700353.aspx)来说明：
####依赖属性的特点
1. 静态:静态意味着该属性可以被很多类实例共享,于是可以实现多个同类控件的数据联动。
2. 字典类型:外部调用类属性的时候,通过字典（or Hash？）查询获得依赖属性值。
3. 注册机制:依赖属性需要通过`DependencyProperty.Register([属性名],[属性类型],[属性所有者类型],[元数据信息])`方法进行注册才能使用（此处采用的静态构造函数注册）。

&#160; &#160; &#160; &#160; 在WPF中,大部分控件的大部分基本属性(~~请原谅我用了含糊的词汇，因为我没有统计过~~)都是依赖属性，这意味着WPF中大部分**相同类型**的控件的大部分属性**`引用`相同的属性值**，当你拥有很多没有修改过属性值的控件的时候，这种方式可以极大地节省内存开销，对于一些复杂的动画效果尤是如此。更为特殊的是，通过依赖属性，我们可以实现[MVVM](https://en.wikipedia.org/wiki/Model_View_ViewModel)，达到前台View中显示值和后台代码ViewModel中数值的绑定。
以下是一个数据绑定的流程
  1.声明Model。
```C#
public class CheckState
{
    public bool IsChecked { get; set; }
    public CheckState(bool isChecked)
    {
        this.IsChecked = isChecked;
    }
}


public class Model
{
    public bool[] CheckStates { get; set; }
}
```
  2.声明ViewModel.
```C#
public class ViewModel : INotifyPropertyChanged //这个继承接口表示这个ViewModel能够为属性值变更做出响应
{
    
    public event PropertyChangedEventHandler PropertyChanged;
    public void RaisePropertyChanged(string propertyName)
    {
        if (PropertyChanged != null)
        {
            PropertyChanged(this, new PropertyChangedEventArgs(propertyName));
        }
    }

    private Model model;
    public List<CheckState> checkStates = new List<CheckState>();
    public List<CheckState> CheckStates
    {
        get { return checkStates; }
        set
        {
            checkStates = value;
            RaisePropertyChanged("CheckStates"); //告诉前台,属性值变更了,需要重新render
        }
    }

    public ViewModel()
    {
        InitializeModel();
    }

    private void InitializeModel()
    {
        // 通常这里负责从数据库抓取数据
        model = new Model
                    {
                        CheckStates = new[] { true, false, true, false }
                    };
        foreach(var stateItem in model.CheckStates)
        {
            this.checkStates.Add(new CheckState(stateItem));
        }
    }
}
```
3.绑定数据上下文（DataContext）.
```C#
public partial class MainWindow : Window
{
    public MainWindow()
    {
        DataContext = new ViewModel(); //这里的DataContext就是一个依赖属性，WPF通过依赖属性实现数据绑定
        InitializeComponent();
    }
}
```
4.然后这里是前端的XAML
```C#
<Menu ItemsSource="{Binding CheckStates}">
    <Menu.ItemTemplate>
        <DataTemplate>
        <!--这里的Binding可以实现前台和后台数据的联动,按照DataContext(即ViewModel)->CheckState->IsChecked的顺序,可绑定到深层次的数据-->
            <CheckBox IsChecked="{Binding IsChecked}"></CheckBox>
        </DataTemplate>
    </Menu.ItemTemplate>
</Menu>
```
&#160; &#160; &#160; &#160; 这样就是一个基本实现MVVM的过程，不难看出，通过依赖属性，我们几乎可以实现前台和后台的完全分离，后台代码只需要大吼一声“XX属性值变了”，前台自然会做出响应，再也不用在CodeBehind里面写`this.Children.Find`类似的操作控制前台的现实的，这一切可以全部交给另外一个人啦.