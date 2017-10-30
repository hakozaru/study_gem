# settingslogic
- Gemコードリーディング入門者向けとうわさの「settingslogic gem」を読む

# まずはsettingslogicの使い方を確認
- gem i settingslogic

```
Fetching: settingslogic-2.0.9.gem (100%)
Successfully installed settingslogic-2.0.9
1 gem installed
```

- 適当なディレクトリに `settings.rb` と `settings.yml` を作成
- settings.yml に適当な設定を追加する

```yml
test:
  text1: abcd
  text2: xyz
hoge:
  huga: 12345
```

- そして settings.rb に設定へアクセスするクラスを定義する

```ruby
require "settingslogic"
require "pry"

class Settings < Settingslogic
  source "#{File.dirname(__FILE__)}/settings.yml"
end

binding.pry
```

- ↑の `binding.pry` のところで、以下のようにアクセスすることができるようになる

```ruby
Settings.test
=> {"text1"=>"abcd", "text2"=>"xyz"}

Settings[:test]
=> {"text1"=>"abcd", "text2"=>"xyz"}

Settings.test.text2
=> "xyz"

Settings.test.class
=> Settings

Settings[:test].class
=> Hash
```

- なぜこのようなアクセスが可能なのか？

# コードを読む
- ちょっと全体構成を眺める
  - gem i settingslogic で $LOAD_PATH に追加され、 `require 'settingslogic'` で `lib/settingslogic.rb` が読み込まれる
  - `lib/settingslogic.rb` は `Hash` を継承した、 `Settingslogic` クラスが定義されている
  - `Settingslogic` クラスには `StandardError` を継承した `MissingSetting` クラスが存在している
  - `class << self 〜 end` で `name`, `get`, `source` などのクラスメソッドを定義している
    - 先ほどの `Settings` クラスで使用した `source` は、親クラスである `Settingslogic` クラスに定義されていた `source` クラスメソッド
- 全体構成を眺めたので、自分が定義した `Setting` クラスの内容から、 `Settingslogic` が何をしているのかを追う

```ruby
# クラス定義の再掲
class Settings < Settingslogic
  source "#{File.dirname(__FILE__)}/settings.yml"
end
```

- `class Settings < Settingslogic`
  - これは単に `lib/Settingslogic.rb` の `Settingslogic` クラスを継承しているだけ
- `source (ymlのパス)`
  - `Settingslogic` クラスのクラスメソッドである `source` が呼ばれている。中身は下。

```ruby
def source(value = nil)
  @source ||= value
end
```

- よく見かける `@source` が存在すれば何もせず、 `@source` が `nil(or false)` なら引数を代入する
  - この形は「メモ化」と言うらしい...
- これだけで `Setting.〇〇` でymlの内容を呼び出せるのは一体どういうことか？
- まず、 `Setting.〇〇` の `〇〇` の部分はメソッド呼び出しなので、 `Setting` クラスのクラスメソッドに `〇〇` が定義されているのかを探している
- しかし当然この `〇〇` は未定義なので、 `method_missing` が呼び出されるが、 `method_missing` は `Settingslogic` でオーバーライドされている
- `Settingslogic` ではインスタンスメソッドと、privateなクラスメソッド両方に `method_missing` が定義されているが、 `Settings.〇〇` で呼ばれるのはprivateなクラスメソッドの方(当たり前だが)
- privateなmethod_missingクラスメソッドは以下のようになっている

```ruby
def method_missing(name, *args, &block)
  instance.send(name, *args, &block)
end
```

- method_missingの引数である `name`, `*args`, `&block` はそれぞれ、「呼び出されたメソッドの名前」「メソッドに渡された引数」「メソッドに渡されたブロック」となる
- method_missingで呼ばれている `instance` メソッドは、これまたprivateなクラスメソッドで以下のようになっている

```ruby
def instance
  return @instance if @instance
  @instance = new
  create_accessors!
  @instance
end
```

- 現時点で `@instance` はnilなのでreturnはされず、インスタンスが生成される(生成されるのは `Settings` クラスのインスタンス)
- そして `create_accessors!` クラスメソッドを実行して `@instance` を返している
- まずは `@instance = new` されたときの挙動だが、 `Settingslogic` に `initialize` メソッドが定義されているので、これが実行される

```ruby
def initialize(hash_or_file = self.class.source, section = nil)
  #puts "new! #{hash_or_file}"
  case hash_or_file
  when nil
    raise Errno::ENOENT, "No file specified as Settingslogic source"
  when Hash
    self.replace hash_or_file
  else
    file_contents = open(hash_or_file).read
    hash = file_contents.empty? ? {} : YAML.load(ERB.new(file_contents).result).to_hash
    if self.class.namespace
      hash = hash[self.class.namespace] or return missing_key("Missing setting '#{self.class.namespace}' in #{hash_or_file}")
    end
    self.replace hash
  end
  @section = section || self.class.source  # so end of error says "in application.yml"
  create_accessors!
end
```

- 引数の `hash_or_file` は、生成されたインスタンスのクラスの `source` クラスメソッドの戻り値
  - すなわち `"#{File.dirname(__FILE__)}/settings.yml"`
- こいつは当然 `nil` でも `Hash` でもないので、 `else` 以降が処理される
- `open(ファイル).read` で `"test:\n  text1: abcd\n  text2: xyz\nhoge:\n  huga: 12345\n"` こんな感じの文字列が得られる
- 続いて `YAML.load(ERB.new(file_contents).result).to_hash` が実行され、hashという変数に格納される
  - `ERB.new(file_contents).result` では `"test:\n  text1: abcd\n  text2: xyz\nhoge:\n  huga: 12345\n"` が取得されている(さっきの `open(ファイル).read` と同じ内容だが...ERBを通す理由が不明)
  - 取得した文字列を `YAML.load().to_hash` することでymlの内容をハッシュ化したオブジェクトを取得
- 名前空間が設定されていた場合は、指定された名前空間配下のデータのみを取得する(`hash = hash[self.class.namespace]`)
- 最後に生成したインスタンスを、ymlから作成したハッシュで置き換えている
- `@section = section || self.class.source` ではsectionを初期化の引数として渡さない限り、ymlのパスが `@section` に格納される
- `initialize` メソッドの最後に `create_accessors!(インスタンスメソッド)` が実行される
- `create_accessors!(インスタンスメソッド)` は以下のようになっている

```ruby
def create_accessors!
  self.each do |key,val|
    create_accessor_for(key)
  end
end
```

- selfはSettingsのインスタンスで、 `initialize` を通して設定されたハッシュが記録されている。 具体的には以下のような内容

```ruby
{
  "test"=>
    {"text1"=>"abcd", "text2"=>"xyz"},
  "hoge"=>
    {"huga"=>12345}
}
```

- `create_accessor_for(key)` は下のようになっている

```ruby
def create_accessor_for(key, val=nil)
  return unless key.to_s =~ /^\w+$/  # could have "some-setting:" which blows up eval
  instance_variable_set("@#{key}", val)
  self.class.class_eval <<-EndEval
    def #{key}
      return @#{key} if @#{key}
      return missing_key("Missing setting '#{key}' in #{@section}") unless has_key? '#{key}'
      value = fetch('#{key}')
      @#{key} = if value.is_a?(Hash)
        self.class.new(value, "'#{key}' section in #{@section}")
      elsif value.is_a?(Array) && value.all?{|v| v.is_a? Hash}
        value.map{|v| self.class.new(v)}
      else
        value
      end
    end
  EndEval
end
```

- ここでは二つのことをやっている
  - 1. インスタンス変数の追加
    - `@test = {"text1"=>"abcd", "text2"=>"xyz"}`
    - `@hoge = {"huga"=>12345}`
  - 2. インスタンスのクラスのインスタンスメソッドに `test` と `hoge` を定義(ゲッター的役割のメソッド)
    - クラスをレシーバにした `class_eval` で、普通に `def 〜 end` とした場合は、インスタンスメソッドとして定義される
- 以上で `@instance` の生成が完了したので、 `instance` クラスメソッドの `create_accessors!(クラスメソッド)` の内容を確認する
- `create_accessors!` メソッド(こちらもprivateなクラスメソッド)は以下のような処理を行っている

```ruby
def create_accessors!
  instance.each do |key,val|
    create_accessor_for(key)
  end
end
```

- 最初に読んでいる `instance` は↑でも読んでいたprivateなクラスメソッドだが、既に `@instance` は `Settings` クラスのインスタンスが格納されているのでそれが返される
- `create_accessor_for` もクラスメソッドの方で↓な感じ

```ruby
def create_accessor_for(key)
  return unless key.to_s =~ /^\w+$/  # could have "some-setting:" which blows up eval
  instance_eval "def #{key}; instance.send(:#{key}); end"
end
```

- こちらはクラスをレシーバとした `instance_eval` なので、クラスメソッドとして定義される
  - インスタンス作成時の `initialize` でymlから動的に作成したインスタンスメソッドを呼んでいるだけ
- `Settings.test` でも `settings_instance.test` でも同じymlの設定を呼べているのはこれが理由

# Settings.test.text1 と呼べるのはなぜか
- tmp
