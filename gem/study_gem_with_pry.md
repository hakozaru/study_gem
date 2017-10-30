# gemのソースをpryを使って学習する
- gemをローカルにインストールして、pryで止められるようにしつつ学習する

# 手順
- 適当な学習用ディレクトリを作成し、移動する
- `bundle init` でGemfileを生成する
- 生成したGemfileに学習したいgem(+ pry)を追記する
- `bundle install --path=vendor/bundle` を実行する
- するとディレクトリに `vendor` ディレクトリが作成され、 `vendor/bundle/ruby/(version)/gems` 配下に目的のgemがダウンロードされる(依存のgemも入る)
- あとは `vendor` ディレクトリと同じところに `test.rb` を作成して、 `require 目的のgem` と `require pry` を追記して、 `bundle exec test.rb` で実行すればOK

# サンプル
- exampleディレクトリにあるファイルは、 `settigslogic` をローカルで動くようにしたサンプルです
