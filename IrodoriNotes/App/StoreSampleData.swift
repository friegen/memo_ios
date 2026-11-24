#if DEBUG
import Foundation

/// App Store のスクリーンショット用のサンプルデータ（9言語。Android 版のストアの画像と同じ文章）。Debug のビルドだけに入る。
/// `tools/store/make_sample_data.py` が Android 版の StoreShotTest.kt.txt から作る（手で直さない）。
enum StoreSampleData {
    struct Memo: Decodable {
        let html: String
        /// 作成日・更新日（2026年11月の日）
        let created: Int
        let updated: Int
        let pinned: Bool
    }

    struct Language: Decodable {
        let memos: [Memo]
        /// ロックしたメモ
        let locked: String
        /// フォルダタブのフォルダ（0: 仕事〔ピン留め〕、最後: 日記〔ロック〕）
        let folders: [String]
        /// 仕事の中のフォルダ・メモ
        let work: [String]
        let workMemos: [String]
        /// 趣味の中のフォルダ
        let hobby: [String]
        /// 「選んだ範囲の文字数」の画面で選ぶ段落（感想文のメモの、空行で区切った何番目か）
        let selectParagraph: Int
    }

    static func language(_ code: String) -> Language? {
        let all = try? JSONDecoder().decode([String: Language].self, from: Data(json.utf8))
        return all?[code] ?? all?["en"]
    }

    private static let json = #"""
{
 "ja": {
  "memos": [
   {
    "html": "買い物リスト<br><font color=\"red\">牛乳</font> 2本<br>卵 1パック<br><font color=\"blue\">食パン</font>（6枚切り）<br>バナナ",
    "created": 16,
    "updated": 17,
    "pinned": true
   },
   {
    "html": "<b>今週のやること</b><br><font color=\"red\"><b>■ 企画書の締め切り（水曜まで）</b></font><br><font color=\"blue\">■ 打ち合わせ：木曜 14:00〜</font><br><font color=\"green\">■ 誕生日プレゼントを買う</font><br><font color=\"orange\">■ 歯医者の予約</font><br><br><u>メモ：駅前の花屋は19時まで</u><br><font color=\"purple\">参考資料は共有フォルダに置いた</font>",
    "created": 15,
    "updated": 17,
    "pinned": false
   },
   {
    "html": "読書感想文の下書き<br><br>この本を読んで一番心に残ったのは、主人公が失敗を恐れずに新しいことに挑戦し続ける姿でした。最初は小さな町の図書館で働いていた主人公が、ある日一冊の古い日記を見つけたことから物語が始まります。<br><br>日記を書いた人を探すうちに、主人公はたくさんの人と出会い、少しずつ自分の考えを言葉にできるようになっていきます。私は人前で話すのが苦手なので、主人公の気持ちがよくわかりました。<br><br>特に印象的だったのは、主人公が「うまく言えなくても、伝えようとすることに意味がある」と気づく場面です。この言葉を読んだとき、私も完璧を目指しすぎずに、まず一歩踏み出してみようと思いました。<br><br>物語の後半では、日記を書いた人の思いが明らかになり、主人公の行動が多くの人の心を動かしていきます。読み終えたあと、自分の周りにいる人たちにもっと関心を持ちたいと感じました。<br><br>この本は、何かを始めたいけれど勇気が出ない人にこそ読んでほしい一冊です。私もこれから、自分の言葉で思いを伝えることを大切にしていきたいです。",
    "created": 10,
    "updated": 16,
    "pinned": false
   },
   {
    "html": "週末やりたいこと<br>・部屋の模様替え<br>・映画を観る<br>・新しいカフェに行く",
    "created": 13,
    "updated": 14,
    "pinned": false
   },
   {
    "html": "ブログのネタ<br>・秋のおすすめ散歩コース<br>・作り置きレシピ3選",
    "created": 9,
    "updated": 12,
    "pinned": false
   },
   {
    "html": "誕生日プレゼント候補<br>・マグカップ<br>・ハンドクリーム",
    "created": 7,
    "updated": 8,
    "pinned": false
   }
  ],
  "locked": "アカウントのメモ<br>（ロック中）",
  "folders": [
   "仕事",
   "趣味",
   "レシピ",
   "勉強",
   "家計簿",
   "日記"
  ],
  "work": [
   "会議",
   "企画"
  ],
  "workMemos": [
   "来月のスケジュール<br>・3日 定例会議",
   "取引先への連絡事項<br>・見積書を送る",
   "新サービスのアイデア<br>・使いやすさを最優先"
  ],
  "hobby": [
   "読書",
   "旅行"
  ],
  "selectParagraph": 3
 },
 "en": {
  "memos": [
   {
    "html": "Shopping list<br><font color=\"red\">Milk</font> x2<br>Eggs<br><font color=\"blue\">Bread</font> (whole wheat)<br>Bananas",
    "created": 16,
    "updated": 17,
    "pinned": true
   },
   {
    "html": "<b>This week's to-do</b><br><font color=\"red\"><b>■ Proposal due Wednesday</b></font><br><font color=\"blue\">■ Meeting: Thu 2:00 PM</font><br><font color=\"green\">■ Buy a birthday gift</font><br><font color=\"orange\">■ Book a dentist appointment</font><br><br><u>Note: the flower shop closes at 7 PM</u><br><font color=\"purple\">Reference files are in the shared folder</font>",
    "created": 15,
    "updated": 17,
    "pinned": false
   },
   {
    "html": "Book report draft<br><br>What stayed with me most about this book was how the main character kept trying new things without being afraid of failure. The story begins when she finds an old diary while working at a small-town library.<br><br>As she searches for the person who wrote the diary, she meets many people and slowly learns to put her own thoughts into words. I am not good at speaking in front of others, so I understood how she felt.<br><br>The most memorable scene is when she realizes that trying to share your feelings matters, even if you cannot say it perfectly. Reading this, I decided to stop aiming for perfect and just take the first step.<br><br>In the second half, the diary writer's story is revealed, and her actions touch the hearts of many people. After finishing the book, I wanted to pay more attention to the people around me.<br><br>I recommend this book to anyone who wants to start something new but cannot find the courage.",
    "created": 10,
    "updated": 16,
    "pinned": false
   },
   {
    "html": "Weekend plans<br>- Rearrange my room<br>- Watch a movie<br>- Try the new cafe",
    "created": 13,
    "updated": 14,
    "pinned": false
   },
   {
    "html": "Blog ideas<br>- Best autumn walking routes<br>- 3 easy make-ahead recipes",
    "created": 9,
    "updated": 12,
    "pinned": false
   },
   {
    "html": "Birthday gift ideas<br>- Mug<br>- Hand cream",
    "created": 7,
    "updated": 8,
    "pinned": false
   }
  ],
  "locked": "Account notes<br>(locked)",
  "folders": [
   "Work",
   "Hobbies",
   "Recipes",
   "Study",
   "Budget",
   "Diary"
  ],
  "work": [
   "Meetings",
   "Projects"
  ],
  "workMemos": [
   "Next month's schedule<br>- 3rd: team meeting",
   "Notes for clients<br>- Send the quote",
   "New service ideas<br>- Keep it simple"
  ],
  "hobby": [
   "Books",
   "Travel"
  ],
  "selectParagraph": 3
 },
 "es": {
  "memos": [
   {
    "html": "Lista de la compra<br><font color=\"red\">Leche x2</font><br>Huevos<br><font color=\"blue\">Pan (integral)</font><br>Plátanos",
    "created": 16,
    "updated": 17,
    "pinned": true
   },
   {
    "html": "<b>Tareas de esta semana</b><br><font color=\"red\"><b>■ Entregar la propuesta el miércoles</b></font><br><font color=\"blue\">■ Reunión: jueves 14:00</font><br><font color=\"green\">■ Comprar un regalo de cumpleaños</font><br><font color=\"orange\">■ Pedir cita con el dentista</font><br><br><u>Nota: la floristería cierra a las 19:00</u><br><font color=\"purple\">Los documentos están en la carpeta compartida</font>",
    "created": 15,
    "updated": 17,
    "pinned": false
   },
   {
    "html": "Borrador de la reseña del libro<br><br>Lo que más me impresionó de este libro fue cómo la protagonista seguía probando cosas nuevas sin miedo a equivocarse.<br><br>La escena más memorable es cuando se da cuenta de que intentar expresar lo que sientes tiene valor, aunque no lo digas perfectamente. Al leerla, decidí dejar de buscar la perfección y dar el primer paso.<br><br>La historia empieza cuando encuentra un diario antiguo en una pequeña biblioteca. Mientras busca a quien lo escribió, conoce a muchas personas y aprende a poner sus ideas en palabras.<br><br>Recomiendo este libro a cualquiera que quiera empezar algo nuevo y no encuentre el valor.",
    "created": 10,
    "updated": 16,
    "pinned": false
   },
   {
    "html": "Planes para el fin de semana<br>- Cambiar los muebles de sitio<br>- Ver una película<br>- Probar la nueva cafetería",
    "created": 13,
    "updated": 14,
    "pinned": false
   },
   {
    "html": "Ideas para el blog<br>- Rutas de otoño para pasear<br>- 3 recetas fáciles para preparar con antelación",
    "created": 9,
    "updated": 12,
    "pinned": false
   },
   {
    "html": "Ideas de regalo<br>- Taza<br>- Crema de manos",
    "created": 7,
    "updated": 8,
    "pinned": false
   }
  ],
  "locked": "Notas de cuentas<br>(bloqueada)",
  "folders": [
   "Trabajo",
   "Aficiones",
   "Recetas",
   "Estudios",
   "Presupuesto",
   "Diario"
  ],
  "work": [
   "Reuniones",
   "Proyectos"
  ],
  "workMemos": [
   "Agenda del próximo mes<br>- Día 3: reunión de equipo",
   "Notas para clientes<br>- Enviar el presupuesto",
   "Ideas para el nuevo servicio<br>- Que sea sencillo"
  ],
  "hobby": [
   "Libros",
   "Viajes"
  ],
  "selectParagraph": 2
 },
 "pt": {
  "memos": [
   {
    "html": "Lista de compras<br><font color=\"red\">Leite x2</font><br>Ovos<br><font color=\"blue\">Pão (integral)</font><br>Bananas",
    "created": 16,
    "updated": 17,
    "pinned": true
   },
   {
    "html": "<b>Tarefas da semana</b><br><font color=\"red\"><b>■ Entregar a proposta na quarta</b></font><br><font color=\"blue\">■ Reunião: quinta, 14h</font><br><font color=\"green\">■ Comprar um presente de aniversário</font><br><font color=\"orange\">■ Marcar o dentista</font><br><br><u>Obs.: a floricultura fecha às 19h</u><br><font color=\"purple\">Os arquivos estão na pasta compartilhada</font>",
    "created": 15,
    "updated": 17,
    "pinned": false
   },
   {
    "html": "Rascunho da resenha do livro<br><br>O que mais me marcou neste livro foi ver a protagonista tentar coisas novas sem medo de errar.<br><br>A cena mais marcante é quando ela percebe que tentar expressar o que sente tem valor, mesmo sem dizer tudo perfeitamente. Ao ler isso, decidi parar de buscar a perfeição e dar o primeiro passo.<br><br>A história começa quando ela encontra um diário antigo numa pequena biblioteca. Enquanto procura quem o escreveu, conhece muitas pessoas e aprende a colocar as ideias em palavras.<br><br>Recomendo este livro para quem quer começar algo novo, mas ainda não tem coragem.",
    "created": 10,
    "updated": 16,
    "pinned": false
   },
   {
    "html": "Planos para o fim de semana<br>- Reorganizar o quarto<br>- Ver um filme<br>- Conhecer o café novo",
    "created": 13,
    "updated": 14,
    "pinned": false
   },
   {
    "html": "Ideias para o blog<br>- Passeios de outono<br>- 3 receitas fáceis para congelar",
    "created": 9,
    "updated": 12,
    "pinned": false
   },
   {
    "html": "Ideias de presente<br>- Caneca<br>- Creme para as mãos",
    "created": 7,
    "updated": 8,
    "pinned": false
   }
  ],
  "locked": "Notas de contas<br>(bloqueada)",
  "folders": [
   "Trabalho",
   "Hobbies",
   "Receitas",
   "Estudos",
   "Orçamento",
   "Diário"
  ],
  "work": [
   "Reuniões",
   "Projetos"
  ],
  "workMemos": [
   "Agenda do próximo mês<br>- Dia 3: reunião da equipe",
   "Recados para clientes<br>- Enviar o orçamento",
   "Ideias para o novo serviço<br>- Manter simples"
  ],
  "hobby": [
   "Livros",
   "Viagens"
  ],
  "selectParagraph": 2
 },
 "fr": {
  "memos": [
   {
    "html": "Liste de courses<br><font color=\"red\">Lait x2</font><br>Œufs<br><font color=\"blue\">Pain (complet)</font><br>Bananes",
    "created": 16,
    "updated": 17,
    "pinned": true
   },
   {
    "html": "<b>À faire cette semaine</b><br><font color=\"red\"><b>■ Rendre la proposition mercredi</b></font><br><font color=\"blue\">■ Réunion : jeudi 14 h</font><br><font color=\"green\">■ Acheter un cadeau d’anniversaire</font><br><font color=\"orange\">■ Prendre rendez-vous chez le dentiste</font><br><br><u>Note : le fleuriste ferme à 19 h</u><br><font color=\"purple\">Les documents sont dans le dossier partagé</font>",
    "created": 15,
    "updated": 17,
    "pinned": false
   },
   {
    "html": "Brouillon de la critique du livre<br><br>Ce qui m’a le plus marqué dans ce livre, c’est l’héroïne qui essaie sans cesse de nouvelles choses, sans avoir peur d’échouer.<br><br>La scène la plus marquante est celle où elle comprend qu’essayer d’exprimer ce qu’on ressent a du sens, même si on ne le dit pas parfaitement. En la lisant, j’ai décidé d’arrêter de viser la perfection et de faire le premier pas.<br><br>L’histoire commence quand elle trouve un vieux journal intime dans une petite bibliothèque. En cherchant son auteur, elle rencontre beaucoup de gens et apprend à mettre ses idées en mots.<br><br>Je recommande ce livre à tous ceux qui veulent se lancer mais n’osent pas encore.",
    "created": 10,
    "updated": 16,
    "pinned": false
   },
   {
    "html": "Projets pour le week-end<br>- Réaménager ma chambre<br>- Regarder un film<br>- Tester le nouveau café",
    "created": 13,
    "updated": 14,
    "pinned": false
   },
   {
    "html": "Idées pour le blog<br>- Balades d’automne<br>- 3 recettes faciles à préparer à l’avance",
    "created": 9,
    "updated": 12,
    "pinned": false
   },
   {
    "html": "Idées de cadeaux<br>- Mug<br>- Crème pour les mains",
    "created": 7,
    "updated": 8,
    "pinned": false
   }
  ],
  "locked": "Notes de comptes<br>(verrouillée)",
  "folders": [
   "Travail",
   "Loisirs",
   "Recettes",
   "Études",
   "Budget",
   "Journal"
  ],
  "work": [
   "Réunions",
   "Projets"
  ],
  "workMemos": [
   "Planning du mois prochain<br>- Le 3 : réunion d’équipe",
   "Notes pour les clients<br>- Envoyer le devis",
   "Idées de nouveau service<br>- Rester simple"
  ],
  "hobby": [
   "Livres",
   "Voyages"
  ],
  "selectParagraph": 2
 },
 "de": {
  "memos": [
   {
    "html": "Einkaufsliste<br><font color=\"red\">Milch x2</font><br>Eier<br><font color=\"blue\">Brot (Vollkorn)</font><br>Bananen",
    "created": 16,
    "updated": 17,
    "pinned": true
   },
   {
    "html": "<b>Diese Woche zu erledigen</b><br><font color=\"red\"><b>■ Angebot bis Mittwoch abgeben</b></font><br><font color=\"blue\">■ Besprechung: Do. 14:00</font><br><font color=\"green\">■ Geburtstagsgeschenk kaufen</font><br><font color=\"orange\">■ Zahnarzttermin vereinbaren</font><br><br><u>Notiz: Blumenladen schließt um 19 Uhr</u><br><font color=\"purple\">Unterlagen liegen im geteilten Ordner</font>",
    "created": 15,
    "updated": 17,
    "pinned": false
   },
   {
    "html": "Entwurf: Buchbesprechung<br><br>Am meisten beeindruckt hat mich, wie die Hauptfigur immer wieder Neues ausprobiert, ohne Angst vor Fehlern.<br><br>Die schönste Szene ist, als sie erkennt, dass es sich lohnt, Gefühle mitzuteilen, auch wenn man es nicht perfekt sagt. Beim Lesen habe ich beschlossen, nicht mehr nach Perfektion zu streben und einfach den ersten Schritt zu machen.<br><br>Die Geschichte beginnt, als sie in einer kleinen Bibliothek ein altes Tagebuch findet. Auf der Suche nach dem Verfasser lernt sie viele Menschen kennen und findet Worte für ihre Gedanken.<br><br>Ich empfehle dieses Buch allen, die etwas Neues anfangen möchten, sich aber noch nicht trauen.",
    "created": 10,
    "updated": 16,
    "pinned": false
   },
   {
    "html": "Pläne fürs Wochenende<br>- Zimmer umstellen<br>- Einen Film schauen<br>- Das neue Café testen",
    "created": 13,
    "updated": 14,
    "pinned": false
   },
   {
    "html": "Blog-Ideen<br>- Herbstliche Spazierwege<br>- 3 einfache Rezepte zum Vorkochen",
    "created": 9,
    "updated": 12,
    "pinned": false
   },
   {
    "html": "Geschenkideen<br>- Tasse<br>- Handcreme",
    "created": 7,
    "updated": 8,
    "pinned": false
   }
  ],
  "locked": "Kontonotizen<br>(gesperrt)",
  "folders": [
   "Arbeit",
   "Hobbys",
   "Rezepte",
   "Lernen",
   "Haushaltsbuch",
   "Tagebuch"
  ],
  "work": [
   "Besprechungen",
   "Projekte"
  ],
  "workMemos": [
   "Plan für nächsten Monat<br>- 3.: Teambesprechung",
   "Notizen für Kunden<br>- Angebot senden",
   "Ideen für neuen Service<br>- Einfach halten"
  ],
  "hobby": [
   "Bücher",
   "Reisen"
  ],
  "selectParagraph": 2
 },
 "ko": {
  "memos": [
   {
    "html": "장보기 목록<br><font color=\"red\">우유 2개</font><br>달걀 1판<br><font color=\"blue\">식빵 (통밀)</font><br>바나나",
    "created": 16,
    "updated": 17,
    "pinned": true
   },
   {
    "html": "<b>이번 주 할 일</b><br><font color=\"red\"><b>■ 기획서 마감 (수요일까지)</b></font><br><font color=\"blue\">■ 회의: 목요일 14:00</font><br><font color=\"green\">■ 생일 선물 사기</font><br><font color=\"orange\">■ 치과 예약하기</font><br><br><u>메모: 역 앞 꽃집은 19시까지</u><br><font color=\"purple\">참고 자료는 공유 폴더에 있음</font>",
    "created": 15,
    "updated": 17,
    "pinned": false
   },
   {
    "html": "독후감 초안<br><br>이 책에서 가장 기억에 남은 것은 주인공이 실패를 두려워하지 않고 새로운 일에 계속 도전하는 모습이었다.<br><br>특히 인상 깊었던 장면은 주인공이 “잘 말하지 못해도 전하려고 하는 것에 의미가 있다”는 것을 깨닫는 부분이다. 이 문장을 읽고 나도 완벽하려고 애쓰기보다 먼저 한 걸음 내디뎌 보기로 했다.<br><br>이야기는 주인공이 작은 마을 도서관에서 오래된 일기장을 발견하면서 시작된다. 일기를 쓴 사람을 찾는 동안 많은 사람을 만나며 자기 생각을 말로 표현하게 된다.<br><br>무언가를 시작하고 싶지만 용기가 나지 않는 사람에게 이 책을 추천하고 싶다.",
    "created": 10,
    "updated": 16,
    "pinned": false
   },
   {
    "html": "주말에 하고 싶은 일<br>- 방 가구 배치 바꾸기<br>- 영화 보기<br>- 새로 생긴 카페 가기",
    "created": 13,
    "updated": 14,
    "pinned": false
   },
   {
    "html": "블로그 아이디어<br>- 가을 산책 코스 추천<br>- 간단한 밑반찬 레시피 3가지",
    "created": 9,
    "updated": 12,
    "pinned": false
   },
   {
    "html": "생일 선물 후보<br>- 머그컵<br>- 핸드크림",
    "created": 7,
    "updated": 8,
    "pinned": false
   }
  ],
  "locked": "계정 메모<br>(잠김)",
  "folders": [
   "업무",
   "취미",
   "레시피",
   "공부",
   "가계부",
   "일기"
  ],
  "work": [
   "회의",
   "기획"
  ],
  "workMemos": [
   "다음 달 일정<br>- 3일 정기 회의",
   "거래처 연락 사항<br>- 견적서 보내기",
   "새 서비스 아이디어<br>- 사용하기 쉽게"
  ],
  "hobby": [
   "독서",
   "여행"
  ],
  "selectParagraph": 2
 },
 "zh-Hant": {
  "memos": [
   {
    "html": "購物清單<br><font color=\"red\">牛奶 2 瓶</font><br>雞蛋 1 盒<br><font color=\"blue\">吐司（全麥）</font><br>香蕉",
    "created": 16,
    "updated": 17,
    "pinned": true
   },
   {
    "html": "<b>本週待辦</b><br><font color=\"red\"><b>■ 企劃書截止（星期三前）</b></font><br><font color=\"blue\">■ 開會：星期四 14:00</font><br><font color=\"green\">■ 買生日禮物</font><br><font color=\"orange\">■ 預約牙醫</font><br><br><u>備註：車站前的花店營業到 19 點</u><br><font color=\"purple\">參考資料放在共用資料夾</font>",
    "created": 15,
    "updated": 17,
    "pinned": false
   },
   {
    "html": "讀書心得草稿<br><br>這本書最讓我印象深刻的，是主角不怕失敗、不斷挑戰新事物的樣子。<br><br>最令人難忘的一幕，是主角發現「就算說得不好，努力傳達本身就有意義」。讀到這句話時，我也決定不再追求完美，先踏出第一步。<br><br>故事從主角在小鎮圖書館發現一本舊日記開始。在尋找日記主人的過程中，她遇見了許多人，也慢慢學會用自己的話表達想法。<br><br>我想把這本書推薦給想開始新事物、卻還鼓不起勇氣的人。",
    "created": 10,
    "updated": 16,
    "pinned": false
   },
   {
    "html": "週末想做的事<br>・重新布置房間<br>・看電影<br>・去新開的咖啡廳",
    "created": 13,
    "updated": 14,
    "pinned": false
   },
   {
    "html": "部落格題材<br>・秋天的散步路線<br>・3 道簡單的常備菜",
    "created": 9,
    "updated": 12,
    "pinned": false
   },
   {
    "html": "生日禮物候選<br>・馬克杯<br>・護手霜",
    "created": 7,
    "updated": 8,
    "pinned": false
   }
  ],
  "locked": "帳號記事<br>（已鎖定）",
  "folders": [
   "工作",
   "興趣",
   "食譜",
   "學習",
   "記帳",
   "日記"
  ],
  "work": [
   "會議",
   "企劃"
  ],
  "workMemos": [
   "下個月的行程<br>・3 日 例行會議",
   "給客戶的聯絡事項<br>・寄送報價單",
   "新服務的點子<br>・以好用為優先"
  ],
  "hobby": [
   "閱讀",
   "旅行"
  ],
  "selectParagraph": 2
 },
 "id": {
  "memos": [
   {
    "html": "Daftar belanja<br><font color=\"red\">Susu 2 kotak</font><br>Telur<br><font color=\"blue\">Roti (gandum)</font><br>Pisang",
    "created": 16,
    "updated": 17,
    "pinned": true
   },
   {
    "html": "<b>Tugas minggu ini</b><br><font color=\"red\"><b>■ Kumpulkan proposal hari Rabu</b></font><br><font color=\"blue\">■ Rapat: Kamis 14.00</font><br><font color=\"green\">■ Beli kado ulang tahun</font><br><font color=\"orange\">■ Buat janji ke dokter gigi</font><br><br><u>Catatan: toko bunga tutup pukul 19.00</u><br><font color=\"purple\">Bahan ada di folder bersama</font>",
    "created": 15,
    "updated": 17,
    "pinned": false
   },
   {
    "html": "Draf ulasan buku<br><br>Yang paling berkesan dari buku ini adalah tokoh utamanya yang terus mencoba hal baru tanpa takut gagal.<br><br>Adegan yang paling saya ingat adalah saat ia sadar bahwa berusaha menyampaikan perasaan itu berarti, walaupun tidak sempurna. Setelah membacanya, saya memutuskan untuk berhenti mengejar kesempurnaan dan mulai melangkah.<br><br>Cerita dimulai ketika ia menemukan buku harian lama di sebuah perpustakaan kecil. Saat mencari penulisnya, ia bertemu banyak orang dan belajar menuangkan pikirannya ke dalam kata-kata.<br><br>Saya merekomendasikan buku ini untuk siapa saja yang ingin memulai sesuatu yang baru tetapi belum berani.",
    "created": 10,
    "updated": 16,
    "pinned": false
   },
   {
    "html": "Rencana akhir pekan<br>- Menata ulang kamar<br>- Nonton film<br>- Mencoba kafe baru",
    "created": 13,
    "updated": 14,
    "pinned": false
   },
   {
    "html": "Ide blog<br>- Rute jalan-jalan sore<br>- 3 resep praktis untuk stok makanan",
    "created": 9,
    "updated": 12,
    "pinned": false
   },
   {
    "html": "Ide kado<br>- Mug<br>- Krim tangan",
    "created": 7,
    "updated": 8,
    "pinned": false
   }
  ],
  "locked": "Catatan akun<br>(terkunci)",
  "folders": [
   "Kerja",
   "Hobi",
   "Resep",
   "Belajar",
   "Anggaran",
   "Buku harian"
  ],
  "work": [
   "Rapat",
   "Proyek"
  ],
  "workMemos": [
   "Jadwal bulan depan<br>- Tgl 3: rapat tim",
   "Catatan untuk klien<br>- Kirim penawaran",
   "Ide layanan baru<br>- Buat sederhana"
  ],
  "hobby": [
   "Buku",
   "Jalan-jalan"
  ],
  "selectParagraph": 2
 }
}
"""#
}
#endif
