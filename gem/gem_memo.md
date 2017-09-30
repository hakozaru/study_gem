# Rubygems・・・お前は一体なにを裏でやっているのだ
- require "gemの名前" で即使えてしまうのは凄いが、裏で何が行われているのか理解できないので気持ちが悪い
- 本質的に理解した上で使いたいので調査する

# gem install 〇〇 で gemはどこへいく？
- rbenvを使用。Ruby 2.4.0。
- ~/.rbenv/versions/(Rubyのバージョン)/lib/ruby/gems/(Rubyのバージョン)/gems/ 以下に入るっぽい
  - ほとんどgithubにあるソースと同じだけど、specディレクトリとかがないとか微妙に違う

# require "banken" で banken/lib/banken.rb が読み込まれる理由
- require は $LOAD_PATH から banken.rb を探して読み込んでいるので、絶対パスとかで指定する必要がない

# LOAD_PATH とは何者か
- ライブラリをロードする際に探索する、ディレクトリパスの配列
- 適当な .rb で p $LOAD_PATH すると(中身は `p $LOAD_PATH` のみ)結果はこんな感じ

```
["/Users/Box/.rbenv/versions/2.4.0/lib/ruby/gems/2.4.0/gems/did_you_mean-1.1.0/lib", "/Users/Box/.rbenv/versions/2.4.0/lib/ruby/site_ruby/2.4.0", "/Users/Box/.rbenv/versions/2.4.0/lib/ruby/site_ruby/2.4.0/x86_64-darwin15", "/Users/Box/.rbenv/versions/2.4.0/lib/ruby/site_ruby", "/Users/Box/.rbenv/versions/2.4.0/lib/ruby/vendor_ruby/2.4.0", "/Users/Box/.rbenv/versions/2.4.0/lib/ruby/vendor_ruby/2.4.0/x86_64-darwin15", "/Users/Box/.rbenv/versions/2.4.0/lib/ruby/vendor_ruby", "/Users/Box/.rbenv/versions/2.4.0/lib/ruby/2.4.0", "/Users/Box/.rbenv/versions/2.4.0/lib/ruby/2.4.0/x86_64-darwin15"]
```

- さらに `require "banken"` を追加すると

```
["/Users/Box/.rbenv/versions/2.4.0/lib/ruby/gems/2.4.0/gems/did_you_mean-1.1.0/lib", "/Users/Box/.rbenv/versions/2.4.0/lib/ruby/gems/2.4.0/gems/banken-1.0.2/lib", "/Users/Box/.rbenv/versions/2.4.0/lib/ruby/gems/2.4.0/gems/i18n-0.8.0/lib", "/Users/Box/.rbenv/versions/2.4.0/lib/ruby/gems/2.4.0/gems/thread_safe-0.3.5/lib", "/Users/Box/.rbenv/versions/2.4.0/lib/ruby/gems/2.4.0/gems/tzinfo-1.2.2/lib", "/Users/Box/.rbenv/versions/2.4.0/lib/ruby/gems/2.4.0/gems/minitest-5.10.1/lib", "/Users/Box/.rbenv/versions/2.4.0/lib/ruby/gems/2.4.0/gems/concurrent-ruby-1.0.4/lib", "/Users/Box/.rbenv/versions/2.4.0/lib/ruby/gems/2.4.0/gems/activesupport-5.0.2/lib", "/Users/Box/.rbenv/versions/2.4.0/lib/ruby/site_ruby/2.4.0", "/Users/Box/.rbenv/versions/2.4.0/lib/ruby/site_ruby/2.4.0/x86_64-darwin15", "/Users/Box/.rbenv/versions/2.4.0/lib/ruby/site_ruby", "/Users/Box/.rbenv/versions/2.4.0/lib/ruby/vendor_ruby/2.4.0", "/Users/Box/.rbenv/versions/2.4.0/lib/ruby/vendor_ruby/2.4.0/x86_64-darwin15", "/Users/Box/.rbenv/versions/2.4.0/lib/ruby/vendor_ruby", "/Users/Box/.rbenv/versions/2.4.0/lib/ruby/2.4.0", "/Users/Box/.rbenv/versions/2.4.0/lib/ruby/2.4.0/x86_64-darwin15"]
```

- banken大先生がしっかりと $LOAD_PATH に追加されている
  - bankenが読み込んでいるgemが依存するgemも追加されている模様
  - ちなみに見つからない場合は LoadError となる

# 結論
- $LOAD_PATH を順に辿る
- ファイルが見つかれば読み込んで終了
- 最後まで見つからなければ LoadError 例外が発生

# その他
- なぜgemをインストールすると lib/ が $LOAD_PATH に追加されるのか
  -  (gem名).gemspec というファイルの中に require_paths というメソッドがあり、この require_paths で指定されたディレクトリが $LOAD_PATH に追加される
  - ほとんどの場合、この require_paths で指定されるのは lib なので、libが追加されていた
    - Bundler が生成するgemのテンプレートも lib が初期値となっている(gitのmasterと同じ感じか)

# 番外
- Bundler を使った時はどうなるのか
  - tmp

# 参考
- http://ongaeshi.hatenablog.com/entry/20111214/1323830203
