---
layout: post
title: Ruby の Liquid でテンプレートに値を渡すパターン４つ
tags: Ruby
lang: ja
---
今日は Ruby のテンプレート エンジン Liquid において、コードとテンプレートの間でデータをやり取りする方法についてまとめておく。

Liquid のバージョンは 2.3.0 で確認しているが、執筆時点で最新の 2.4.1 でも変わってないようにみえる。


Hash を渡すパターン
===================

まずは、Liquid のサイトにも載ってる一番単純なハッシュを渡すパターン。

{% highlight ruby %}
require 'liquid'

template = Liquid::Template.parse("hi {%raw%}{{name}}{%endraw%}")
puts template.render( 'name' => 'nitoyon' ) # => hi nitoyon
{% endhighlight %}

分かりやすい。そのまま。


to_liquid を実装するパターン
============================

自分で作ったクラスのインスタンスを Liquid に渡したい場合もあるだろう。この場合、`to_liquid` メソッドを実装してやる必要がある。

{% highlight ruby %}
require 'liquid'

class Person
  def initialize
    @name = "nitoyon"
  end

  def to_liquid
    { 'name' => @name }
  end
end

template = Liquid::Template.parse("hi {%raw%}{{person.name}}{%endraw%}")
puts template.render( 'person' => Person.new ) # => hi nitoyon
{% endhighlight %}

Liquid はオブジェクトを表示するときには、必ず `to_liquid` メソッドを呼んでいる。`to_liquid` メソッドが定義されていない状態で表示しようとすると、

    hi Liquid error: undefined method `to_liquid' for 
    #<Person:0x46a400 @name="nitoyon">

のようなエラーになってしまう。

この制約は `String` についても例外ではない。Liquid を `require` すると、裏側では `liquid/extensions.rb` によって `String#to_liquid` や `Hash#to_liquid` などのメソッドが定義されている。

`to_liquid` を独自実装するパターンを使うと、テンプレート側から `Person` のメソッドを呼ぶことはできない。それをやりたいなら、次に説明する `Liquid::Drop` を使うとよい。


Drop を使うパターン
===================

`Liquid::Drop` を継承してやることで、テンプレート側からメソッドを呼べるようになる。

{% highlight ruby %}
class Person < Liquid::Drop
  attr_accessor :name
  def initialize
    @name = "nitoyon"
  end
  def NAME
    @name.upcase
  end
end

template = Liquid::Template.parse("hi {%raw%}{{person.name}}{%endraw%}")
puts template.render({'person' => Person.new })  # => hi nitoyon

template = Liquid::Template.parse("hi {%raw%}{{person.NAME}}{%endraw%}")
puts template.render({'person' => Person.new })  # => hi NITOYON
{% endhighlight %}

これはとても便利だが、いくつか注意すべき点がある。

まず、引数付きのメソッドを呼ぶことはできない。引数に対処したかったら、テンプレートから `name_param1_param2` のようにして参照しておいて、後述の `before_method` でがんばってパースしろ、というポリシーのようだ。

もう１つ。別ライブラリが提供するオブジェクトを Liquid に渡したいことがある。このとき、`Liquid::Drop` を継承させるのは不可能だ。かといって、`to_liquid` で内部構造をいちいちハッシュに変換するのも面倒だ。

そんなケースに対処するために Drop 化させるクラス `ToDrop` を作ってみたので、次のパターンとして紹介する。


Drop 化させるパターン
=====================

gem かなんかで、こんなクラスが提供されているものと仮定する。

{% highlight ruby %}
module Foo
  class Person
    attr_accessor :name
    def initialize
      @name = "nitoyon"
    end
    def NAME
      @name.upcase
    end
  end
end
{% endhighlight %}

外部ライブラリーのクラスなのでいじりたくないけど、このクラスのインスタンスをテンプレートに渡して、 `name` や `NAME` メソッドを叩きたいものとする。

そういうときは、次のような `ToDrop` クラスを定義しておけばよい。

{% highlight ruby %}
class ToDrop < Liquid::Drop
  def initialize(obj)
    @obj = obj
  end
  def before_method(method)
    if method && method != '' && @obj.class.public_method_defined?(method.to_s.to_sym)
      @obj.send(method.to_s.to_sym)
    end
  end
end
{% endhighlight %}

使い方は簡単。`to_liquid` で `ToDrop.new(self)` を返す処理を実装してやるだけだ。これだけで期待の動作となっている。

{% highlight ruby %}
module Foo
  class Person
    def to_liquid
      ToDrop.new(self)
    end
  end
end

template = Liquid::Template.parse("hi {%raw%}{{person.name}}{%endraw%}")
puts template.render({'person' => Foo::Person.new }) # => hi nitoyon

template = Liquid::Template.parse("hi {%raw%}{{person.NAME}}{%endraw%}")
puts template.render({'person' => Foo::Person.new }) # => hi NITOYON
{% endhighlight %}

この `ToDrop` が今回、わたしが作成した魔法のクラスで、任意のオブジェクトを `Liquid::Drop` を継承したときと同じ動作にしてくれる。

`ToLiquid` クラスでは `Liquid::Drop#before_method` メソッドを実装している。このメソッドは `Drop` のメソッドミッシングのような役割を担っている。`ToDrop#before_method` では、ラップ対象のオブジェクトに public メソッドがあるかどうか調べて、あるならばそれを呼ぶよう実装している。

言葉で説明しても分かりにくいのだけど、`Liquid::Drop` クラスのソース [drop.rb](https://github.com/Shopify/liquid/blob/master/lib/liquid/drop.rb) と見比べてもらうとイメージは沸きやすいと思う。`Liquid::Drop` のソースをよく見ると Liquid と密接に関わっているわけではなく、`alias :[] :invoke_drop` とすることで、`[]` を使った参照をメソッド呼び出しに置き換えているだけ、というヘルパークラスなのが興味深い。


まとめ
======

Liquid に値を渡すためのパターンを 4 つ紹介した。`Liquid::Drop` を継承すればテンプレート側からメソッドを呼べるし、継承関係に手が出しにくいときには拙作の `ToDrop` クラスを使えば便利だよ、という話をした。