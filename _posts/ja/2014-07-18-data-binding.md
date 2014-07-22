---
layout: post
title: JavaScript フレームワークがデータバインディングを実現する４通りの手法
tags: JavaScript
lang: ja
seealso:
- ja/2014-06-30-vue-js-hook
- ja/2013-06-27-node-yield
- ja/2013-02-27-livereloadx
- ja/2013-02-19-node-source-map
- ja/2011-03-24-jQuery-extend-mania
- ja/2008-12-11-jquery-fast-css
---
最近流行りの JavaScript MV* フレームワークは、どれもデータバインディングをサポートしているが、実現方法はフレームワークによって異なる。

この記事では、各種フレームワークが**どのようにモデルの変更を検知しているか**を次の 4 つのパターンに分類して紹介する。

1. モデル クラス方式 (Ember.js、Backbone.js、Ractive.js、Knockout.js など)
2. 力ずく方式 (AngualrJS)
3. モデル書き換え方式 (Vue.js)
4. Object.observe 方式 (Polymer)

パターン名は私が勝手に名づけたものだけど、このへんの雰囲気が理解できれば、フレームワークごとの個性が分かるだろうし、利用イメージもわきやすいんじゃないかと思っている。


1. モデル クラス方式
============================

「モデルとして扱えるのはフレームワークが用意したモデル クラスのインスタンスだけ」という制約を課すのがこの方式。

たとえば、Ember.js では `{title: "てっく煮"}` という情報をデータバインディングで利用しようと思ったら、次のようにしてモデル クラスのインスタンスを作る必要がある。

```javascript
var a = Ember.Object.create({title: "てっく煮"})
console.log(a.get('title')); // てっく煮
```

モデルを変更するには `set()` メソッドを使う。

```javascript
a.set('title', '!!!!');
console.log(a.get('title')); // !!!!
```

当然、フレームワーク側はモデルの値が変更されたことを検知できる。検知したら、あとはフレームワークは新しい値に応じて DOM を書き換えればよい。とてもシンプルな構造だ。

使う側の視点でみると、`get()` や `set()` を呼ぶのが面倒だし、ラッパーの API は JavaScript の `Object` や `Array` と扱い方が違うし、さらに、既存のモデルがある場合は流用できない (作成・取得・変更処理を全部置き換える必要がある) し・・・、と不便な印象がある。

これ以降の方式は、ネイティブな `Object` や `Array` などをモデルとして扱えるように工夫している。


この方式を採用するフレームワークが多い
--------------------------------------

現時点においては、この方式を採用するフレームワークが多数派である。

[Backbone.jsなどのライブラリのgetter, setterがダサい理由と、その解消方法 - Qiita](http://qiita.com/tekkoc/items/eb5ab65524c3e5b4a11c) によると、Backbone.js、Knockout.js、Ractive.js も同じ方式を採用しているらしい。

> Backbone.js と Ractive.js は `get("hoge")` や `set("hoge", value)` という形式。
> Knockout.js は少しマシで `hoge()` で取得し `hoge(value)` で設定する形式。


2. 力ずく方式
=============

お次は [AngularJS] が採用しているヤツを説明しよう。英語では "dirty check" と呼んでいる。

AngularJS はネイティブな `Object` や `Array` をモデルとして渡せるし、独自クラスのオブジェクトだって渡せる。

たとえば、モデルが `{title: 'てっく煮'}` だったとしよう。モデルはネイティブなオブジェクトなので、変更をプッシュ通知で受け取るのは諦めている。

そんな前提なので、AngularJS は **何かあるごとに** `title` の値が変化したかどうかを自力でチェックする。変化してれば DOM を書き換える。オブジェクトの参照が変わってしまうこともあるので、「前回の値」はディープコピーして覚えている。

とても力技なので処理にはオーバーヘッドがある。ソースコードも複雑になっている。


「何かあるごとに」はいつか？
----------------------------

さて、さきほど「何かあるごとに」と書いたが、前回の値と今の値を比較するタイミングはいつだろうか。

正解は「AngularJS 経由で JavaScript のコードを実行したとき」である。

たとえば、ボタンのクリックイベントに関しては `<button ng-click="foo()">` のように書くと、AngularJS 経由で `foo()` が呼ばれる。`setTimeout()` の処理であれば、`$timeout` を使えば AngularJS 経由でコールバックが呼ばれる。

コールバックを読んだとき、モデルの値は変更されるかもしれないし、実際には変更されないかもしれない。変更されたか調べるために、呼び終わったあとに、力ずくで調べるのだ。

直接 DOM イベントを監視するようなときには AngularJS を経由させるのは難しい。そういうときには `$scope.$apply()` に関数を渡すと、関数を呼んだあとに力ずくの比較処理をやってくれる。

AngularJS を使う側の視点からすると、モデルへの変更を HTML に確実に反映させるには、`ng-click` や `$timeout`、`$scope.$apply()` など使って AngularJS 経由でモデルを変更する必要がある。


力ずく方式のまとめ
------------------

* `Object` や `Array` や独自クラスのインスタンスをモデルにできる
* 比較処理がトリガーされるかどうかを意識する必要がある
* 比較処理のオーバーヘッドがある


3. モデル書き換え方式
=====================

こちらは [Vue.js] が採用している方式である。

Vue.js もネイティブな `Object` や `Array` をモデルとして渡せる。

たとえば、オブジェクトのキーの変更を検知するために、キーを (ECMAScript 5 的な) プロパティーに書き換える。配列の変更を検知するために、`Array.prototype` を書き換えて `push()` メソッドなどを置き換える。

AngularJS のように力ずくの比較は行わないので動作は速いのが利点。Vue.js のサイトでも [他のフレームワークより速いこと](http://vuejs.org/perf/) を自慢している。

一方の弱点は、次の通り。

  * モデルとして受け取ったオブジェクトを書き換えてしまう
  * 完全に変更を検知できない (完全に検知できないので、一部の変更処理については、`$set()` や `$add()` といったメソッドを使う必要がある。ラッパー オブジェクト的な要素が残っているといえる)。

詳しくは {% post_link 2014-06-30-vue-js-hook %} に書いたので見てほしい。


4. Object.observe() 方式
========================

現在、ECMAScript には「オブジェクトの変更を検知する」という機能を持つ `Object.observe()` というメソッドが提案されていて、仕様決定に先立って [Google Chrome 36 ではデフォルトで有効](http://www.chromestatus.com/features/6147094632988672) になっている。

ためしに Google Chrome 36 の JavaScript コンソールで使ってみる。

```javascript
> a = {foo: 1}
> Object.observe(a, function(changes) { console.log(changes); })
> a.foo = 3
  [Object]
      0: Object
          name: "foo"
          object: Object
              foo: 3
          oldValue: 1
          type: "update"
> a.bar = 10
  [Object]
      0: Object
          name: "bar"
          object: Object
              bar: 10
              foo: 3
          type: "add"
```

まさにデータバインディングで使ってくれといっているようなメソッドである。

[Polymer] は `Object.observe()` を前提としている。さらに、先ほどから紹介していた各種ライブラリーについても、AngularJS は 2.0 での対応を[検討している](http://blog.angularjs.org/2014/03/angular-20.html) し、Vue.js は v0.11.x で[対応予定](https://github.com/yyx990803/vue/issues/78) となっている。

ECMAScript に `Object.observe()` が取り込まれれば、ここまで紹介したようなややこしいデータバインディングの仕組みは不要となる。まさに、データバインディングのための API であるが、ECMAScript 6 にも入っておらず、すべてのブラウザーで使えるようになるには時間がかかりそうだ。
`Object.observe()` については以下のページが詳しかった。

* [次世代JavaScriptでデータバインディング： Object.observe() を試す - ぼちぼち日記](http://d.hatena.ne.jp/jovi0608/20121206/1354762082)
* [Data-binding Revolutions with Object.observe() - HTML5 Rocks](http://www.html5rocks.com/en/tutorials/es7/observe/)


まとめ
======

MV* フレームワークが「どのようにモデルの変更を検知しているか」を 4 通り紹介した。

* オブジェクト指向的なモデル クラスを使う方式が主流。
* [AngularJS] や [Vue.js] はネイティブな値をモデルとして扱うために頑張っている。
* `Object.observe()` が使えるようになれば、フレームワークの苦しみが減る。[Polymer] はそこを見据えている。


[AngularJS]: (https://angularjs.org/)
[Vue.js]: http://vuejs.org/
[Polymer]: (http://www.polymer-project.org/)