

    README file of JRF_Semaphore

    (Created: 2014-02-27 +0900, Time-stamp: <2020-01-24T03:04:39Z>)



■ About the "JRF_Semaphore"

JRF_Semaphore はある意味、広く普及した LLVM (Low Level Virtual Machine：
低水準仮想機械)であるファミコン(NES)のエミュレータを対象として作られた
手旗信号によるテキスト入力プログラムと、その周辺ツールからなるライブラ
リである。



■ About this distribution

メインの jrf_semaphore.nes は、カセット RAM などを使えばファミコン実機
でも動くはずだが、私は試す環境を手に入れたくも金銭的・時間的に今すぐに
は難しいので、誰か試していただけると助かる。

jrf_semaphore.html は、JavaScript による NES エミュレータ実装 JSNES を
対象とした UI (ユーザーインターフェース)である。私のホームページ上で公
開するためのものだが、こちらのアーカイブに含んでる。動かすためには、
JSNES の GitHub を grunt (Make に相当)して得た jsnes.min.js が必要だが、
このアーカイブには含まれていない。もちろん、公開中の私のサイトではそれ
を使ってる。

jrf_semaphore.pl は、得たテキストを日本語カナ等に直すためのもので、「本
気」で JRF_Semaphore の方式で手旗を使おうとするなら、必要なものだろう。
が、今のところ私は、あくまでコンセプトの呈示が目的の「お遊び」で作って
いるつもりで、「本気」で使うような事態になって欲しいとは思わないことも
あり、作る優先度は最後で、完成度は高くない。ただ、要素技術としては作り
たかったものなので、機会を見て機能を足している。

はじめの公開は、先に片づけねばならない別件の開発事案があるため、できて
いるものの公開を暫定的に公開することになった。直後に、私の「持病」であ
る統合失調症が再発してしまい、入院するなどした。入院中、PC やネットに近
づくことができな中で、特別に一時帰宅が許された際のリリースなどもやった
のが今となっては良い思い出である。退院しているが、キツめの投薬を受けて
いたところから、現在はかなり回復しているが、それでもぶりかえしを恐れる
日々が続いている。

2017年に quail-naggy.el のアップデートに合わせて、このプロジェクトも少
しいじることにした。機能の追加としては日本語変換を行う -T naggy がある
が、これまで通り、ドキュメント化していないため、今後、使う人が出てくる
のは考えにくいのが淋しいところ。機能追化はそれぐらいだが、Perl のファ
イルが実質一つであったのを、モジュールに分けたりして、内部では大きな変
更をしている。

ソースのコメントや(broken 英語のも含め)ドキュメントを充実させたいが、
機能が複雑になって、全部書いていられない。ソースを読んでくれというのは
暴論だとはわかっているが、それを願うしかない状況だ。ドキュメントの充実
はあいかわらず他日を期すことにしたい。


■ The contents of this distribution

今のアプリケーションは、あいかわらず「暫定公開」でコンセプトの呈示が主
目的となるため、インストール用のキットは含んでいない。その辺りは、もう
期待しないでいただきたい。

  00_README.ja.txt
	-- このファイル。
  00_URI.txt
	-- 配布物の「ID」が入ったファイル。今回はたぶん書かれた URL か
           らこのアーカイブが手に入る。
  01_LOG.ja.txt
	-- 私の「グチ」とともに開発履歴を、今回はサービスサービスッっ
	   てことで付けた。ちょっと死亡フラグくさいが、なんとか乗り切っ
	   てみせる！
  jrf_semaphore.nes
	-- ファミコン(NES) 用 ROM ファイル。本作のメイン。
  jrf_semaphore.asm
	-- 上のソース。NES の CPU の 6502 アセンブラである NESASM 用。
  jrf_semaphore*.chr
	-- キャラクタテーブル。アセンブルに必要。
  make_chr16.pl
	-- 8x16 キャラクタテーブルを作るのに使ったスクリプト。
  jrf_semaphore.dat
	-- テキストやロゴのパレット情報。アセンブルに必要。
  sailor_pal.dat
	-- キャラのパレット情報。アセンブルに必要。
  jrf_semaphore.html
	-- JSNES を使った UI。動かすにはこのアーカイブとは別に JSNES
	   が必要。
  jsnes_test.html
	-- JSNES を使った UI のテスト用。SSI を使った例で、ネットのどこ
	   かのサイト上でないと動かないと思う。
  pseudo_dynamicaudio.js
	-- jrf_semaphore.html で使う。
  jsnes_fc_ui.js
	-- jrf_semaphore.html で使う。
  jrf_semaphore.pl
	-- 完成度低め。信号交換に付随する Transliteration とかを行うた
           めのプログラム。上のASM と NES ROM からプロトコルのデータを
           読む。
  lib/*
	-- jrf_semaphore.pl で使う Perl モジュール。
  ngb_lib/*
	-- jrf_semaphore.pl で使う Perl モジュール。quail-naggy.el と
	   共通のもの。
  trl/*
	-- jrf_semaphore.pl で Transliteration のために使う。quail-naggy.el と
	   共通のもの。
  nginit/*
	-- jrf_semaphore.pl で Transliteration のために使う。quail-naggy.el と
	   共通のもの。
  *.wav *.png *.gif
	-- html などで使う。
  psg_test.nes
	-- オマケ。ファミコンで出せる音を知るために作った。
  psg_test.asm
	-- 上のソース。

あとは make 用の NESASM のパッチとか Perl のライブラリとか、今回は使わ
なくてもあとあと必要かもしれないものが入っている。


■ References

今回は、基本的なところだけ。Wikipedia には、今回特にモールス信号や手旗
のプロトコルをはじめ、いろいろお世話になっている。当然、プログラムの際
にはネットのリソースをいろいろ参考にしている。MDN (Mozilla Developer
Network) のリソースを特に目にすることが多く役に立つ情報が多かったのは特
筆しておく。ファミコンや船舶通信の本を読んだりもした。病院での生活から
得るものもあって、その後も、その他の実生活からいろんな気付きを得ること
がもちろん多い。いつもながらのことではあっても、改めて感謝します。あり
がとうございます。


《JSNES: A JavaScript NES emulator - Ben Firshman》
http://fir.sh/projects/jsnes/

《MagicKit Homepage - NESASM》
http://www.magicengine.com/mkit/

《NES研究室》
http://hp.vector.co.jp/authors/VA042397/nes/index.html

《ｷﾞｺ猫でもわかるファミコンプログラミング》
http://gikofami.fc2web.com/

《わいわいの巣 / Yy's Utilities - YY-CHR.NET》
http://www.geocities.co.jp/Playtown-Denei/4503/yychr/index.html

《quail-naggy.el: 単漢字変換 Input Method for Emacs.》
http://jrf.cocolog-nifty.com/software/2015/10/post.html

今回のプロジェクトのメインページは↓。

《JRF Flag Semaphore for NES Emulators》
http://jrf.cocolog-nifty.com/archive/nes_semaphore/jrf_semaphore.html



■ Author's link:

http://jrf.cocolog-nifty.com/software/
(The page is written in Japanese.)


■ License

The author is a Japanese.

I intended this program to be public-domain, but you can treat
this program under the (new) BSD-License or under the Artistic
License, if it is convenient for you.

Within three months after the release of this program, I
especially admit responsibility of efforts for rational requests
of correction to this program.

I often have bouts of schizophrenia, but I believe that my
intention is legitimately fulfilled.


まぁ、要は「パブリックドメイン」で私は公開しているつもりで、NES 研究室
の言葉を借りれば「基本的に」著作権は放棄していますということ。あと、特
例やけど、３ヶ月は弟子とかじゃなく本人改修しまっせ、その努力はしまっせ、
ということ。(大目に見て欲しい「暫定公開」でも、セキュリティ的・法的緊急
性があればもちろん対応しますけど…、けったいなこというのは知らんで。)

さらに、２０１４年４月以降、精神病で入院後の療養中ということもあり、
ちょっと直す程度のことならよいが、それ以上となると個人開発のため、対応
が難しいことは、先にご容赦願いたい。

あと、２０１７年に License も少し書きかえたが、著作権は国ごとに違うから、
著者が日本人であることをいちおう最初に断るようにした。以前は書いてなかっ
た自分に統合失調症の持病があることも書き加えた。


■ Log

  2020-01-24 -- J で convert する際に、先頭が大文字の場合の処理を元の
                tankanji に戻した。内部的に、先頭が大文字の単漢字変換を
                SKK にするかどうかを default-init.nginit 内で指定するよ
                うにした。

  2020-01-23 -- J で convert する際も、先頭が大文字の場合は、tankanji
                ではなく skk 辞書が選択されるようにした。j で convert
                する際は、以前のまま。

  2017-11-13 -- バージョン 0.11。ローマ字カナ変換で、FYA = フャ、FYU =
                フュ、FYO = フョ に対応。

  2017-07-13 -- バージョン 0.10。quail-naggy.el のバージョンアップに合
                わせて、日本語変換の部分が変更になっている。

  2017-06-08 -- バージョン 0.09。quail-naggy.el のバージョンアップに合
                わせて、日本語変換の部分が変更になっている。ローマ字変
                換が少し変更されている。

  2017-04-29 -- バージョン 0.08。jrf_semaphore.pl に日本語変換の naggy
                モードを実装するなど大きな変更を加えた。以前のバージョ
                ンにあったバグを直したりもしたが、大きな変更により、ま
                た別のバグがまぎれこんだ可能性も大きい。

  2014-06-07 -- バージョン 0.07。少しの改善で済まそうとしたら、前のバー
  	     	ジョンでセーブができなくなってる等致命的なバグがあった
  	     	ため、そこだけ早く直して緊急リリース。あと、latin-1 の
  	     	実装が中途半端なままの申し訳なさから、昔試験的に作った
  	     	アラビア文字の trl をおまけにつけた。

  2014-05-24 -- バージョン 0.06。精神病でキツイ。最終バージョンにしちゃ
  	     	うかも。

  2014-04-24 -- バージョン 0.05。本来は 0.10 と呼べるぐらい一新するつ
  	     	もりだったが、一時帰宅でとりあえず形が整ったところで、
  	     	道なかばの 0.05 という数字にした。

  2014-04-10 -- 「流れ星」風に自分では実現できそうにないアイデアを書き
  	     	散らしていこうとしたところ、重度の統合失調症的症状にな
  	     	り、入院。

  2014-03-25 -- 全男子の憧れ「スケスケ眼鏡(X (Ray) Glasses)」機能追加。
		誰だ「コレジャナイ」とかいう奴は！

  2014-03-21 -- バージョン 0.03。暫定バージョンはこれが最後の予定。細か
                な改良のみだが、これから大きくいじるため、その前に一旦、
                公開しておくことにした。

  2014-03-18 -- バージョン 0.02。更新。jrf_semaphore.pl の parse_int で
  	     	明らかなミスがあってその修正がメイン。とはいえ、他の作
  	     	業のあいまにいろいろいじってる。これも暫定バージョン。

  2014-03-11 -- バージョン 0.01。初公開。他の急ぎの開発を優先するため、
  	        できたところまでの暫定バージョンとして公開。

  2014-03-06 -- jsnes_fc_ui.js がだいたい完成。

  2014-02-23 -- とりあえず jrf_semaphore.nes がおかしなことにならずに
  	        一連の動作を完了するところまでくる。

  2014-02-16 -- 《JRF のひとこと》で NES に関する「何か」の開発をはじ
  	     	めたことを報告。

  2014-02-12 -- 下調べをしながら、まずキャラクタを作りはじめる。

  2014-02-11 -- 電子金融がらみのアイデアとして「印鑑」のメタファで ROM
  	     	カードリッジに注目。簡単そうなものとしてかつての手旗の
  	     	妄想を recollect。

  199?-??-?? -- モンティ・パイソンの sketch をヒントに手旗のウェブウェ
  	       	ジェットを作りたいと妄想するも、大学の研究等、他が忙し
  	       	くて手に付かず。


(This file was written in Japanese/UTF8.)
