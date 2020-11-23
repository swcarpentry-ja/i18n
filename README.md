# Internationalisation of carpentry lessons（カーペントリーのレッスンの国際化）

## [English README](README_en.md)

小さな貢献をしたい場合は、[クイックスタートガイド](docs/quickstart.md)を読んでみてください。

資料を翻訳する前に、[翻訳者のガイドライン](docs/TranslatorGuidelines.md)と、[行動規則](docs/rules.md)を、読ん
でください

また、私たちの[Slackワークスペース](http://carpentries-ja.slack.com)に参加してください。
[#swcarpentryのSlackチャンネル](https://r-wakalang.herokuapp.com/)もあります。
ここは、翻訳を進める上で発生する疑問に関して質問するのに最適の場所です。

ツイッターで[swcarpentry-ja](https://twitter.com/swcarpentry_ja)も更新の発表をやっています。ぜひフォローし
てください。

## 目的

リポジトリは、[ソフトウェアカーペントリー](https://software-carpentry.org/)のレッスンを英語から他の言語(現在日本語に取り組
んでいます)へ翻訳するのを容易にするために必要なファイルやツールをホストするためにあります。また、英語とスペイン語のレッスンの多言語化をしてマージするためでもあります。

ソフトウェアカーペントリーのメインのウェブサイトが他の言語と一緒にホストされ互換性があり、英語のレッスンの新しいリリースに合わせて日本語のレッスンも最新に維持
するように計画しています。

私達は、ソフトウェアカーペントリーのオリジナルのレッスンを改定するのではなく、レッスを翻訳（そして最新の状態に維持）をしています。

もしあなたが、レッスン自体の問題に気づいたら、英語のレッスンに対して、issueをたてたり、プルリクエストを送ってください。

## gitについて

ここでは、あなたが、GitとGitHubについて知っているという仮定をしています。

もし、gitをインストールするのに手助けが必要ならば、[gitのインストールガイド](docs/git.md)を読んでみてください

## About PO files

各レッスンのテキストを直接翻訳するのではなく、翻訳には、[PO ファイル](https://www.gnu.org/software/gettext/manu
al/html_node/PO-Files.html)を使います。

POファイルは、複数のエントリで構成されるテキスト形式のファイルです。各エントリーは、元のテキストと、その翻訳の短い部分が含まれています。オリジナルの
レッスンごとに、１つのPOファイルがあります。例えば、
[Software Carpentry 'git novice' lesson](https://github.com/swcarpentry/git-nov
ice)は、複数の markdown形式のドキュメントで構成され、日本語の翻訳に関しては１つの `git-novice.ja.po` というPOファイルがあります。これにより、手
動ではなく、
オリジナルのテキストの追跡を行うことができ、オリジナルのレッスンが更新されたときに、変更され翻訳が必要とされる部分を正確に把握することができます。
無料のPOエディタは、いくつかあります: [PoEdit](http://www.poedit.net),[GTranslator](https://wiki
.gnome.org/Apps/Gtranslator), 
[Lokalize](https://userbase.kde.org/Lokalize). これらのいずれかを使用して、POファイルを翻訳することをお勧めし
ます。

## 初めてレッスンをインポートするとき

レッスンはサブモジュールとしてインポートされます。この作業はレッスンにつき１度だけ行われ、ほとんどの翻訳者はこれを行う必要はありません。
もし、あなたが新しいレッスンをインポートしたいときには、[インポートのガイド](docs/importing.md)を参照してください。

## 既存のレッスンの翻訳へ貢献する

**これは、翻訳者からの手助けが最も必要なタスクです!**

これは、[インポートのガイド](docs/importing.md)で説明されているように、`swcarpentry-ja/i18n`がサブモジュールとして既
に追加されていることを
前提としています。あなたは、そのレッスンの翻訳に貢献したいとします。

1. 個人のGitHubアカウントで、このリポジトリの"フォーク"を作成します。
  (`https://github.com/swcarpentry-ja/i18n`の右上の"フォーク(fork)"をクリックします。
  corner of the `https://github.com/swcarpentry-ja/i18n` webpage)

2. 個人のアカウント(GitHubUserなど)で、このリポジトリをクローンします。これは、翻訳ファイルのバージョン管理するためのローカルコピーです

```bash
cd directory
git clone git@github.com:GitHubUser/i18n.git
cd i18n
```

3. サブモジュールを使えるようにする.

```bash
git submodule init
git submodule update
```

このリポジトリはすでに、レッスンの翻訳ファイルが含まれています。翻訳に貢献したいときには、 `po` ディレクトリの中の `<レッスン名>.<言語>.po` 
、
例えば `git-novice.ja.po` に貢献することができます。

```bash
cd po
ls git-novice.ja.po
```

4. POファイルを編集します。[ガイドラインに従って](docs/rules.md), 頻繁に変更をコミットし、十分だとおもったらpull request 
を投稿してください。

5. 正確を期すために、あなたのPRについて、レビューが行われます。レビューがパスするまで、編集を続けます。そのようなときは、まずはじめに、
組織のリポジトリに対する変更を pull してください。

```bash
git checkout ja
git remote add swc-ja git@github.com:swcarpentry-ja/i18n.git
git pull swc-ja ja
```

PRがレビューをパスするまでステップ4と5を繰り返します

いくつかのメモ:

POファイルを編集しても、翻訳されたWebサイトができあがるわけではありません。[メンテナーと管理者ガイド](docs/admin.md)で述べられているよう
に、
これはメンテナーに任されています。

POファイルを編集したあと、翻訳された Markdown ファイルを見たいときには、 `bash po4gitbook/compile.sh` を実行します。
これは、
あなたの変更を含めた翻訳されたバージョンを生成します。これは、`locale/<lang>/<lesson>`, 例,
`locale/ja/git-novice`で見つけることができます。

## メインの英語のレッスンが新しくリリースされたら、レッスンを更新するのに貢献する

レッスンの(完全な)翻訳が存在しても、メインの英語のレッスンが新しくリリースされることがあります。
更新されたバージョンの英語のレッスンは、現在の翻訳されたものにマージされる必要があります。

[レッスン更新時のガイド](docs/updating.md)を見てください。

## 翻訳のためのリソース

レッスンを編集するときには[翻訳者のためのガイドライン](docs/TranslatorGuidelines.md)に従ってください。

レッスン間で用語が一貫して使われていることを確認するために 
[技術用語のリスト](https://github.com/swcarpentry-ja/i18n/wiki/Glossary-for-technical-terms)
 があります。必要に応じてこれを参照したり更新したりしてください。

一貫性を担保するために、日本語に翻訳されない概念などの標準化された取り扱いについては、 [カルチャーノート](docs/CultureNotes.md) を参
照してください。

進捗と、ゴールを記録するために[変更履歴](docs/ChangeLog.md)を持っています。

## メンテナーと管理者のガイド

[メンテナーと管理者のガイド](docs/admin.md) を見てください

ご協力いただきありがとうございます。たとえ小さな貢献であっても、大歓迎です。

# Internationalisation of carpentry lessons

## How does this work?

1. Add a submodule for the lessons that you want to translate
1. Run `po4gitbook/update.sh` - That creates/updates the `po` directory with the `.pot` files to use in translations.
1. Create a `po` file and start translating!
 - copy `<file>.pot` to `<file>.<lang>.po`. e.g.,
 ```bash
 cd po
 cp shell-novice.pot shell-novice.es.po
 ```
 - Edit the file with your favourite po editor ([PoEdit](http://www.poedit.net),
 [GTranslator](https://wiki.gnome.org/Apps/Gtranslator), [Lokalize](https://userbase.kde.org/Lokalize), ...)
   Note:
    - "`Language`" field is needed to add to the header (at least with gtranslator), the rest is put by the tool.
    - "`Language-Team:`" needs the first letter in upper case (e.g., `Es`)
 - Create `po/LINGUAS`
 - run `po4gitbook/compile.sh` - This creates a `locale/<lang>/<lesson>` tree directory


## Using Transifex

[Transifex]() is a collaborative platform for translations. We can upload the
`pot` files produced by the `update` command. However, to have a better user
experience on that platform we suggest that the `lesson_file.pot` is broken into
one per chapter. To do so you can use the helper script available in this repository

```bash
$ lesson="TheSuperLesson"
$ python helpers/splitpot.py po/${lesson}.pot
```

This, by default, will break `TheSuperLesson.pot` file and create a
`TheSuperLesson` directory under `transifex` and fill it up with one file per
chapter.

Now we will proceed to use the [transifex-client](https://docs.transifex.com/client/installing-the-client)
to push the split files.

1. Browse to the directory of the lesson and create the `<lang>` directory that
   you would like to get translating:

   ```bash
   $ cd transifex/${lesson}
   $ mkdir es
   ```
   
   We will proceed to generate the files to push to transifex. Read the [[appendix]] 
   below for more information to do it manually.
   
1. Run the transifex command to generate all the files needed.

   ```bash
   tx config mapping-bulk -p ${lesson} --source-language en --type PO -f '.pot' \
             --source-file-dir pot --expression "<lang>/{filename}.po" --execute
   ```
   
   Note that you need to create that project (lesson) manually in
   [transifex](https://www.transifex.com/carpentries-i18n/add/)

1. Next we proceed to push the sources to the website

   ```bash
   tx push -s --parallel
   ```
   
   This can take a while... 
   
1. Advertise between the translators, give access to people through the portal

1. translate, translate, translate

1. when you want to download a particular translation for building the lesson
   you need to, pull and combine:
   
   ```bash
   $ language="es"
   $ cd transifex/${lesson}
   $ tx pull -t ${language}  # This should download the `po` files in transifex/${lesson}/${language}
   $ # Then proceed to join the files into a single one
   $ cd ..
   $ python helpers/splitpot.py po/${lesson}.pot --join transifex/${lesson} --lang ${language}
   $ # Compile the repository with po4gitbook so it creates the locale for the lesson
   $ po4gitbook/compile.sh # This creates a `locale/<lang>/<lesson>` tree directory
   ```
   
# Appendix

## Transifex manual process
   
1. initialise the transifex project (if this is your first time then you may
   [set up your
   token](https://docs.transifex.com/client/init#first-tx-init-run)).

   ```bash
   $ tx init
   ```
   
   Answer the questions that follows as required. **Note** if the script hangs a
   the path expression step, is because it doesn't find the `<lang>` directory.
   Make sure to create one first (*e.g.,* `mkdir es`)

