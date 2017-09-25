# includedメソッド
- https://qiita.com/castaneai/items/6dc121ce6ff100614f42
- ActiveSupport::Concernが提供している便利メソッド
- モジュールに included メソッドを定義しておくと、モジュールが include された時に呼び出される
  - http://www.techscore.com/blog/2013/03/01/rails-include%E3%81%95%E3%82%8C%E3%81%9F%E6%99%82%E3%81%AB%E3%82%AF%E3%83%A9%E3%82%B9%E3%83%A1%E3%82%BD%E3%83%83%E3%83%89%E3%81%A8%E3%82%A4%E3%83%B3%E3%82%B9%E3%82%BF%E3%83%B3%E3%82%B9%E3%83%A1/

# respond_to? メソッド
- レシーバのオブジェクトに対してメソッドを呼び出せるかどうかを調べるメソッド

# hide_actionメソッド
- アクションを隠すらしい
- 具体的には「コントローラ中にアクションでないpublicメソッドがあり、publicのままで、でも、アクションとして使いたくない場合にhide_actionで指定する」
- hide_action :new みたいに
- ただ、コントローラ中にアクションでないpublicメソッドがある場合は、リファクタリングを検討した方が良さそうとのこと

# class << self の部分

```
class << self
  def loyalty!(controller_name, user, record=nil)
    LoyaltyFinder.new(controller_name).loyalty!.new(user, record)
  end
end
```

  - これは Banken.loyalty! と呼ぶための定義
  - Bankenモジュールを自分のクラスでincludeしたりextendしたりしても loyalty! は使えるようにならない
  - Bankenをクラスでincludeすれば、include先のクラスのインスタンスメソッドに、authorize!、permitted_attributes、loyalty、banken_user、skip_authorization、verify_authorized、banken_loyalty_authorized? が追加される
  - Bankenをクラスでextendすれば、extend先のクラスのクラスメソッドに、authorize!、permitted_attributes、loyalty、banken_user、skip_authorization、verify_authorized、banken_loyalty_authorized? が追加される
  - https://qiita.com/ionis_h/items/5f26248ea4e154cce424

# generatorsとは
- rails g model 〜とかのこと。 自分で好きなgeneratorを作ることができる
- Rails::Generators::NamedBaseを継承する(NamedBase は Rails::Generators::Baseを継承している)
- Rails::Generators::NamedBase は引数を1つ取り、それは name でアクセスが可能になる
  - rails g banken:loyalty posts なら posts が name でアクセスできるようになる
- source_root File.expand_path(File.join(File.dirname(__FILE__), 'templates')) とは
  - そのgeneratorで使うtemplatesディレクトリのパスを取得し、そこを参照のrootに設定している
  - Bankenの banken/lib/generators/banken/loyalty/loyalty_generator.rb では /Bankenまでのフルパス/banken/lib/generators/banken/loyalty/templates となる
  - 従って、template メソッドの引数にはtemplatesディレクトリにある ファイル名.rb のみで参照することができる
- LoyaltyGenerator の class_path やら file_name はどこから来ている？
  - RailsのRails::Generators::NamedBaseのソースを見ると、
    - class_path は引数で渡されたクラス名を/や::で分割した配列
      - 引数が "tes/posts" なら -> ["tes", "posts"]
      - 引数が "tes::posts" なら -> ["tes", "posts"]
      - class_pathで返ってきた配列を File.join するので正しいパスが得られる
    - file_name は class_path で作った ["tes", "posts"] などの配列の最後の要素を取得している(["tes", "posts"].pop されているだけ)
    - https://github.com/rails/rails/blob/5ccdd0bb6d1262a670645ddf3a9e334be4545dac/railties/lib/rails/generators/named_base.rb#L155
- template メソッドとは何か
  - 実はthorのメソッド( https://github.com/erikhuda/thor/blob/067f6638f95bd000b0a92cfb45b668bca5b0efe3/lib/thor/actions/file_manipulation.rb#L108 )
  - 第一引数のファイルを、第二引数のディレクトリへ複製する
    - File.expand_path は絶対パスにした文字列を返す
- hook_for メソッドとは何か
  - Rails::Generators::Base にあるメソッド( https://github.com/rails/rails/blob/5ccdd0bb6d1262a670645ddf3a9e334be4545dac/railties/lib/rails/generators/base.rb#L168 )
  - 指定した値に基づいてジェネレータを呼び出すらしい
  - ここでは :test_framework を呼び出している
  - 実際にrails g banken:loyalty posts を実行すると、minitestのファイルを生成しているので、現在使用されているテストのファイルを作成するっぽい
- class_name とは何か
  - こいつは NamedBase に定義されているメソッド( https://github.com/rails/rails/blob/5ccdd0bb6d1262a670645ddf3a9e334be4545dac/railties/lib/rails/generators/named_base.rb#L75 )
  - class_path と file_name から名前の通りクラス名を作成している
  - (class_path + [file_name]).map!(&:camelize).join("::") こんな感じ
    - class_path は↑で書いた通り、["tes", "posts"]こんな配列が入っている
    - file_name も同じく↑で書いた通り "posts" が入っている
      - (class_path は file_name の取得時にpopされているので、["tes"]のみが入っている)
    - そんなこんなで (class_path + [file_name]) は -> ["tes", "posts"]となる
    - あとは普通にクラス名っぽく変換して結合しているだけなので、"Tes::Posts" こんな文字列が返る
- module_namespacing とは何か
  - こいつも NamedBase のメソッド( https://github.com/rails/rails/blob/5ccdd0bb6d1262a670645ddf3a9e334be4545dac/railties/lib/rails/generators/base.rb#L281 )
  - もし名前空間が与えられていた場合は、ブロックを現在のアプリケーションの名前空間でラップする
  - やってみた
    - rails g banken:loyalty test/aaa/posts
    - class Test::Aaa::PostsLoyalty < ApplicationLoyalty; end
      - イメージとしては module Test module Aaa みたいにラップされると思ったのだがラップされない? これが正しい出力なのか?
      - もうちょい調査する

# Banken使用で何が行われるか
- チュートリアルの順にBanken gemのどのコードが実行されて、何が行われるのか検証

## Bankenを飼う
- https://github.com/kyuden/banken/wiki/Tutorial-(japanese)#banken%E3%82%92%E9%A3%BC%E3%81%86
  - Banken モジュールを includeする
    - クラス(Appコントローラ)にBankenモジュールのメソッド(loyalty!とprivateメソッド以外)をインスタンスメソッドとして取り込む
  - rails g banken:install
    - banken/lib/generators/banken/install/install_generator.rb の InstallGeneratorクラスのインスタンスメソッドが全て実行される
    - 要するに copy_application_loyalty メソッドが実行される
      - やっていることは banken/lib/generators/banken/install/templates/application_loyalty.rb を、Railsの app/loyalties/application_loyalty.rb に作成(複製)しているだけ
      - これがBankenを飼うのステップ2で紹介されているコード

## Loyaltyクラスの作成
- https://github.com/kyuden/banken/wiki/Tutorial-(japanese)#loyalty%E3%82%AF%E3%83%A9%E3%82%B9%E3%81%AE%E4%BD%9C%E6%88%90
  - rails g banken:loyalty posts
    - これも同じく banken/lib/generators/banken/loyalty/loyalty_generator.rb の LoyaltyGeneratorクラスのインスタンスメソッドを全て実行している
    - 要するに create_loyalty メソッドが実行される
      - やっていることは banken/lib/generators/banken/loyalty/templates/loyalty.rb を元に〇〇loyaltyクラス(rails g banken:loyalty の引数で与えられた文字、ここでは posts )を作成し、app/loyalties配下に配置する(ここではapp/loyalties/posts_loyalty.rb)

## アクションの制御
- https://github.com/kyuden/banken/wiki/Tutorial-(japanese)#%E3%82%A2%E3%82%AF%E3%82%B7%E3%83%A7%E3%83%B3%E3%81%AE%E5%88%B6%E5%BE%A1
