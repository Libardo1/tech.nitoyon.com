---
layout: post
title: GitHub で clone するときは SSH じゃなく HTTP を使ったほうが高速
tags: Git
lang: ja
seealso:
- 2012-12-21-text-hatena-js-github
- 2012-09-20-moved-completed
- 2012-04-12-msysgit-utf8-2
- 2012-02-21-msysgit-utf8
- 2008-01-07-pageant-security
---
{% image http://farm9.staticflickr.com/8082/8367926710_8530642335_o.png, 571, 221 %}

GitHub には clone するための URL として [HTTP]、[SSH]、[Git Read-Only] の 3 つが用意されている。

いままで、SSH に慣れているという理由だけで [SSH] を利用していたのだけど、「**SSH は転送速度が遅い**」という問題がある。


SSH だとこんなに遅い…
======================

さっき、[SSH] で clone してみたら 20～60 KiB/s 程度の速度しか出なかった。

```
$ git clone git@github.com:nitoyon/tech.nitoyon.com.git
Cloning into 'tech.nitoyon.com'...
remote: Counting objects: 8856, done.
remote: Compressing objects: 100% (2125/2125), done.
remote: Total 8856 (delta 3251), reused 8731 (delta 3126)
Receiving objects: 100% (8856/8856), 7.04 MiB | 26 KiB/s, done.
Resolving deltas: 100% (3251/3251), done.
```

↑最終的に `26 KiB/s` しか出ていない。

これでは、巨大なリポジトリを clone すると、長大な時間を要することになる。


HTTP は高速！
=============

そんなときは、 [HTTP] で clone すればよい。

さっき試したら、300～600 KiB/s 出た。

```
$ git clone https://github.com/nitoyon/tech.nitoyon.com.git
Cloning into 'tech.nitoyon.com'...
remote: Counting objects: 8856, done.
remote: Compressing objects: 100% (2125/2125), done.
remote: Total 8856 (delta 3251), reused 8731 (delta 3126)
Receiving objects: 100% (8856/8856), 7.04 MiB | 604 KiB/s, done.
Resolving deltas: 100% (3251/3251), done.
```

↑`604 KiB/s` も出ている

[Git Read-Only] も試してみたら、こちらは 1 MiB/s ぐらいでたので一番高速だった。

<s>つまり、[HTTP] が最強！　他の 10 倍速い。</s>

つまり、速さは [Git Read-Only] > [HTTP] >> [SSH] となった。

(訂正) 当初、[HTTP] が最強としていましたが、再度調べてみたところ、[Git Read-Only] が最強でした。お詫びして訂正します。


push が面倒なら clone 後に SSH にすればよい
===========================================

[SSH] で clone したときのメリットは、push のときには ssh-agent なり pageant なりが、パスフレーズの入力を代行してくれる点にある。`git push` と入力するだけで push を開始できてお手軽だ。

一方、[HTTP] で clone してしまうと、push するたびにユーザー名とパスワードを要求されて面倒だ。[credential helper](https://help.github.com/articles/set-up-git#platform-windows) を導入すればキャッシュしてくれるらしいが、これも面倒だ。

[Git Read-Only] だと Read-Only という名前の通り、push できない。

それが理由で、いままで [SSH] でちんたら clone していた。

けども、よく考えたら [HTTP] や [Git Read-Only] で clone したあとでも、[SSH] で push するように設定を変更できる。

```
$ git remote set-url origin git@github.com:user/repo.git
```

`git remote` で `origin` の URL を変えるだけ。この手順は [GitHub のヘルプ](https://help.github.com/articles/why-is-git-always-asking-for-my-password)にも書いてある。

これ以降の push / pull は [SSH] でやるようになる。[HTTP] に比べて転送速度は遅いけど、1度 clone したあとなら、差分のみの送受信なので、あまり速度は気にしなくてもよいはずだ。(もし大量に送受信する必要が出たなら、同じようにして再度 [HTTP] に切り替えてもよいだろう)


(追記) SSH も設定を変えれば速くなる
===================================

`~/.ssh/config` に次の設定をすれば、SSH でも十分速くなるようです。

```
Host github.com
  Compression yes
  Ciphers arcfour256
```

はてなブックマークで id:y-kawaz さんに[指摘していだきました](http://b.hatena.ne.jp/y-kawaz/20130111#bookmark-127926818)。ありがとうございます。

まとめ
======

次のような戦略が考えられる。

* push する必要がないなら [Git Read-Only] で clone すると高速。
* [SSH] の clone は `~/.ssh/config` を設定すると速度が劇的に改善する。
* clone したあとに、`git remote set-url` で URL を変更すれば、push するプロトコルを変更できる

快適な GitHub 生活を。
