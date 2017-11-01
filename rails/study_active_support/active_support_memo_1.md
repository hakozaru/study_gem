# active_support
- `nil.blank?` とかの便利メソッドを提供してくれるライブラリ

# 読む
- まずは大本の `lib/active_support.rb` から
- `ActiveSupport::Autoload` は `active_support/dependencies/autoload` に定義されているモジュールで、 `extend` で読み込み特異メソッドとして使えるようにしている
- `autoload` は↑で読み込んだモジュールに定義されているメソッドで、中身はこんな感じ

```ruby
def autoload(const_name, path = @_at_path)
  unless path
    full = [name, @_under_path, const_name.to_s].compact.join("::")
    path = Inflector.underscore(full)
  end

  if @_eager_autoload
    @_autoloads[const_name] = path
  end

  super const_name, path
end
```

- `autoload :Concern` と呼ばれた場合は
  - `const_name` は `Concern` で、 pathはnil
  - name は標準モジュールのメソッドで、モジュールの名前を文字列で返す。 ここでは `"ActiveSupport"` となる
  - 変数 full には `"ActiveSupport::Concern"` が格納される
  - `Inflector` は `ActiveSupport::Autoload` で `require` されている `"active_support/inflector/methods"` で定義されているメソッドだが、 `Inflector` モジュールは `extend self` しているため、これらのメソッドも特異メソッドとして使用可能となっており、 `Inflector.underscore(full)` と呼出せている。
  - `underscore` メソッドは渡されたキャメルケースの文字列をアンダースコア化して返すメソッド
    - 例： `Inflector.underscore("HakoZaru::Test") => "hako_zaru/test"`
    - ここでは `"ActiveSupport::Concern"` が渡されるので、 `"active_support/concern"` が変数 path に格納される
  - `@_eager_autoload` には `false` が格納されているので、 `@_autoloads` に変更はない
  - `super const_name, path` はオーバーライドしていたRuby標準モジュールの `autoload` メソッドを呼び出している
    - ちなみに `autoload` の働きは `ネストされたクラスやモジュールが必要になったときにRubyファイルを自動的に読み込む（requireする）ことができます` といった感じ
    - `require` は実行された瞬間に必ずファイルが読み込まれるが、 `autoload` は読み込みの予約だけをしておき、実際にモジュールなどが呼び出された(参照された)らファイルを読み込む。 もし呼ばれなければファイルは読み込まれない。
    - 使うかどうかわからない場合は `autoload` の方が無駄な処理がないのでエコ。
  - 要するにここでは `ActiveSupport::Concern` や `ActiveSupport::Dependencies` を使えるようにファイルを読み込んでいる
- `eager_autoload do 〜 end` の部分
  - これも `Autoload` モジュールに定義されているメソッドで、内容は以下のとおり

```ruby
def eager_autoload
  old_eager, @_eager_autoload = @_eager_autoload, true
  yield
ensure
  @_eager_autoload = old_eager
end
```

- 現在の `@_eager_autoload` の設定を `old_eager` 変数に保存してから `autoload` を実行している
  - 例外が発生してもしなくても設定を戻している
  - ちなみに例外が発生したら `rescue` はないので `ensure` の処理が行われた後に停止する
- この `eager_autoload` ブロック内でロードされたモジュールは、 `@_autoloads` に定数名をキー、パスをvalueにしたハッシュで格納したのちに読み込まれる
- あとはいくつか特異メソッドが定義されているのと、 `cattr_accessor :test_order` が定義されているのみ
  - `cattr_accessor` は `lib/active_support/core_ext/module/attribute_accessors.rb` に `mattr_accessor` のエイリアスとして定義されている
  - `attribute_accessors.rb` では `Module` クラスをオープンしており、ここで定義したメソッドは `attr_accessor` と同じノリで使うことができる
- `mattr_reader` について

```ruby
def mattr_reader(*syms)
  options = syms.extract_options!
  syms.each do |sym|
    raise NameError.new("invalid attribute name: #{sym}") unless /\A[_A-Za-z]\w*\z/.match?(sym)
    class_eval(<<-EOS, __FILE__, __LINE__ + 1)
      @@#{sym} = nil unless defined? @@#{sym}

      def self.#{sym}
        @@#{sym}
      end
    EOS

    unless options[:instance_reader] == false || options[:instance_accessor] == false
      class_eval(<<-EOS, __FILE__, __LINE__ + 1)
        def #{sym}
          @@#{sym}
        end
      EOS
    end
    class_variable_set("@@#{sym}", yield) if block_given?
  end
end
```

- 可変長引数を受け取り `extract_options!` というメソッドを通している
- これは `lib/active_support/core_ext/array/extract_options.rb` で `Array` のメソッドとして定義されており、中身は以下のとおり

```ruby
class Array
  def extract_options!
    if last.is_a?(Hash) && last.extractable_options?
      pop
    else
      {}
    end
  end
end

class Hash
  def extractable_options?
    instance_of?(Hash)
  end
end
```

- やっていることは単純で、配列の最後の要素が Hash かつ extractable_options? が true (ハッシュのインスタンスである)なら、配列の最後の要素（Hash）を取り出す、そうでなければ空の Hash を返す
- `mattr_〇〇` メソッドで行われていることは、渡された引数の名前のクラス変数の読み書きができるメソッドを定義しているだけ
  - `mattr_accessor :hakozaru` なら `@@hakozaru` というメソッドのアクセサが定義される（ `クラス.hakozaru` と `クラス.hakozaru = "hoge"` と `インスタンス.hakozaru` と `インスタンス.hakozaru = "hoge"` の4つ）
  - そして、 `mattr_accessor :hakozaru, instance_accessor: true` とすれば、インスタンスからもアクセスできるアクセサが同時に定義される
  - `mattr_accessor :hakozaru, instance_accessor: false` と明示的に指定しなければ基本的にクラス、インスタンスメソッドが定義される
- ということで、 `require "active_support"` をするだけでは特に何かできるようになるわけではなさそう
- 次に続く
