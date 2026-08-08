import '../logic/role_overrides_store.dart';
import '../models/role.dart';
import '../models/role_type.dart';
import '../models/team.dart';
import 'app_colors.dart';

/// Single source of truth for every built-in role: its bilingual name and
/// description, icon, team, and color.
///
/// To add a new built-in role: add a [RoleType] value in `role_type.dart`,
/// then add its entry here. Custom (game-master-authored) roles are NOT
/// listed here - they are built on the fly at setup time.
class RoleData {
  RoleData._();

  static const Map<RoleType, Role> all = {
    // ---------------------------------------------------------------
    // Citizen team
    // ---------------------------------------------------------------
    RoleType.citizen: Role(
      type: RoleType.citizen,
      team: Team.citizen,
      name: 'Citizen',
      description: 'No special ability.',
      nameFa: 'شهروند',
      descriptionFa: 'توانایی خاصی ندارد.',
      iconAsset: 'assets/icons/citizen.svg',
      emoji: '👤',
      color: AppColors.citizenTeam,
      shortDescription: 'No special ability.',
      shortDescriptionFa: 'توانایی خاصی ندارد.',
    ),
    RoleType.doctor: Role(
      type: RoleType.doctor,
      team: Team.citizen,
      name: 'Doctor',
      description:
          'Each night, can save one player.\nMay save himself only once during the game.',
      nameFa: 'دکتر',
      descriptionFa:
          'هر شب می‌تواند یک بازیکن را نجات دهد.\n'
          'فقط یک‌بار می‌تواند خودش را نجات دهد.',
      iconAsset: 'assets/icons/doctor.svg',
      emoji: '💉',
      color: AppColors.citizenTeam,
      shortDescription: 'Can save one player each night.',
      shortDescriptionFa: 'هر شب می‌تواند یک بازیکن را نجات دهد.',
    ),
    RoleType.sniper: Role(
      type: RoleType.sniper,
      team: Team.citizen,
      name: 'Sniper',
      description:
          'Has two bullets for the entire game. If he shoots a citizen,\n'
          'he is eliminated instead - the citizen is safe.\n'
          '(In games of 12+ players: usually 3-4 bullets, and a misfire on a\n'
          'citizen eliminates only the citizen - the Sniper stays in the game.)',
      nameFa: 'اسنایپر',
      descriptionFa:
          'در طول کل بازی دو گلوله دارد. اگر به یک شهروند شلیک کند،\n'
          'خودش از بازی خارج می‌شود - شهروند صدمه‌ای نمی‌بیند.\n'
          '(در بازی‌های 12 نفر به بالا: معمولاً 3 تا 4 گلوله دارد، و اگر به '
          'شهروند شلیک کند، فقط خود شهروند خارج می‌شود و اسنایپر در بازی می‌ماند.)',
      iconAsset: 'assets/icons/sniper.svg',
      emoji: '🎯',
      color: AppColors.citizenTeam,
      shortDescription: 'Has bullets to shoot suspected mafia at night.',
      shortDescriptionFa: 'برای شلیک شبانه به مافیای مشکوک، گلوله دارد.',
    ),
    RoleType.bartender: Role(
      type: RoleType.bartender,
      team: Team.citizen,
      name: 'Bartender',
      description: "Every night, can disable (miss) one role-holder's ability.",
      nameFa: 'ساقی (بارمن)',
      descriptionFa: 'هر شب می‌تواند توانایی یک بازیکن نقش‌دار را غیرفعال (میس) کند.',
      iconAsset: 'assets/icons/bartender.svg',
      emoji: '🍸',
      color: AppColors.citizenTeam,
      shortDescription: "Can disable one role-holder's ability each night.",
      shortDescriptionFa: 'هر شب می‌تواند توانایی یک نقش‌دار را غیرفعال کند.',
    ),
    RoleType.priest: Role(
      type: RoleType.priest,
      team: Team.citizen,
      name: 'Priest',
      description: 'Removes the silence effect (from Natasha) from one player.',
      nameFa: 'کشیش',
      descriptionFa: 'اثر سکوت (ناتاشا) را از یک بازیکن خنثی می‌کند.',
      iconAsset: 'assets/icons/priest.svg',
      emoji: '✝️',
      color: AppColors.citizenTeam,
      shortDescription: "Can remove Natasha's silence effect from a player.",
      shortDescriptionFa: 'می‌تواند اثر سکوت ناتاشا را از یک بازیکن حذف کند.',
    ),
    RoleType.detective: Role(
      type: RoleType.detective,
      team: Team.citizen,
      name: 'Detective',
      description:
          "Investigates one player each night.\nThe Godfather's check always comes back as 'Citizen'.",
      nameFa: 'کارآگاه',
      descriptionFa:
          'هر شب یک استعلام می‌گیرد.\n'
          'استعلام پدرخوانده به‌عنوان «شهروند» نشان داده می‌شود.',
      iconAsset: 'assets/icons/detective.svg',
      emoji: '🔍',
      color: AppColors.citizenTeam,
      shortDescription: "Investigates one player's role each night.",
      shortDescriptionFa: 'هر شب نقش یک بازیکن را استعلام می‌گیرد.',
    ),
    RoleType.investigator: Role(
      type: RoleType.investigator,
      team: Team.citizen,
      name: 'Investigator',
      description:
          'Can bring two suspects to defend themselves (may include himself\n'
          'as one of the two); after hearing them, votes to eliminate one.',
      nameFa: 'بازپرس',
      descriptionFa:
          'می‌تواند دو بازیکن مشکوک را به دفاعیه بیاورد (می‌تواند خودش را هم\n'
          'یکی از آن دو نفر بگذارد)؛ بعد از شنیدن دفاع هرکدام، به خروج یکی '
          'رأی می‌دهد.',
      iconAsset: 'assets/icons/investigator.svg',
      emoji: '⚖️',
      color: AppColors.citizenTeam,
      shortDescription: 'Brings two suspects to defend, then votes one out.',
      shortDescriptionFa: 'دو مشکوک را به دفاعیه می‌آورد و به خروج یکی رأی می‌دهد.',
    ),
    RoleType.cowboy: Role(
      type: RoleType.cowboy,
      team: Team.citizen,
      name: 'Cowboy',
      description:
          'From day two onward, can point at a suspect mid-game -\n'
          'both the Cowboy and that player are eliminated together.\n'
          'Night begins immediately after this action.',
      nameFa: 'کابوی',
      descriptionFa:
          'از روز دوم به بعد می‌تواند با اشاره به یک فرد مشکوک، خودش\n'
          'و آن فرد را با هم از بازی خارج کند. بلافاصله بعد از این اقدام، شب می‌شود.',
      iconAsset: 'assets/icons/cowboy.svg',
      emoji: '🤠',
      color: AppColors.citizenTeam,
      shortDescription: 'From day two, can duel a suspect - both are eliminated.',
      shortDescriptionFa: 'از روز دوم، با یک مشکوک دوئل می‌کند؛ هر دو خارج می‌شوند.',
    ),
    RoleType.bomber: Role(
      type: RoleType.bomber,
      team: Team.citizen,
      name: 'Bomber',
      description:
          'A citizen who sits between two players he suspects.\n'
          'All three - the Bomber and both of them - are eliminated,\n'
          'regardless of which side they were actually on. Typically used\n'
          'on day two in larger games. If silenced, he cannot detonate.',
      nameFa: 'بمبر',
      descriptionFa:
          'شهروندی که بین دو بازیکنی که به آن‌ها مشکوک است می‌نشیند.\n'
          'هر سه نفر - خود بمبر و آن دو نفر - از بازی خارج می‌شوند،\n'
          'فارغ از اینکه واقعاً چه سایدی بودند. معمولاً در بازی‌های با تعداد '
          'بالا، روز دوم اجرا می‌شود. اگر سکوت روی او باشد، منفجر نمی‌شود.',
      iconAsset: 'assets/icons/bomber.svg',
      emoji: '💣',
      color: AppColors.citizenTeam,
      shortDescription: 'Sits between two suspects; all three are eliminated.',
      shortDescriptionFa: 'بین دو مشکوک می‌نشیند؛ هر سه با هم خارج می‌شوند.',
    ),
    RoleType.gunman: Role(
      type: RoleType.gunman,
      team: Team.citizen,
      name: 'Gunman',
      description:
          'Can give out two guns to two players - one blank, one real.\n'
          "Neither player knows which gun they actually received. Usually "
          'used in games of 12 or fewer. Whoever fires the real gun causes '
          "the target's role to be announced as they're eliminated.",
      nameFa: 'تفنگدار',
      descriptionFa:
          'می‌تواند به دو بازیکن تفنگ بدهد؛ یکی مشقی و یکی اصلی.\n'
          'هیچ‌کدام از آن‌ها نمی‌دانند کدام تفنگ واقعی به آن‌ها رسیده است. '
          'معمولاً در بازی‌های 12 نفر و پایین‌تر اجرا می‌شود. کسی که تفنگ '
          'اصلی را شلیک کند، نقش فرد شات‌شده هنگام خروج اعلام می‌شود.',
      iconAsset: 'assets/icons/gunman.svg',
      emoji: '🔫',
      color: AppColors.citizenTeam,
      shortDescription: 'Hands out one real and one blank gun to two players.',
      shortDescriptionFa: 'به دو بازیکن یک تفنگ اصلی و یک مشقی می‌دهد.',
    ),
    RoleType.invincible: Role(
      type: RoleType.invincible,
      team: Team.citizen,
      name: 'Invincible',
      description:
          "A strong citizen, immune to the mafia's night shot.\n"
          "The Sniper's shot still kills him normally, and so does a day "
          "vote. The mafia's Strongman can also override his immunity.",
      nameFa: 'رویین‌تن',
      descriptionFa:
          'شهروندی قدرتمند که با تیر شب مافیا از بازی خارج نمی‌شود.\n'
          'اما تیر اسنایپر و رأی روز، عادی روی او اثر می‌کند. «مرد قوی» '
          'مافیا هم می‌تواند مصونیتش را خنثی کند.',
      iconAsset: 'assets/icons/invincible.svg',
      emoji: '🛡️',
      color: AppColors.citizenTeam,
      shortDescription: "Immune to the mafia's shot, but not the Sniper's.",
      shortDescriptionFa: 'در برابر شات مافیا مصونه، اما نه شات اسنایپر.',
    ),
    RoleType.commander: Role(
      type: RoleType.commander,
      team: Team.citizen,
      name: 'Commander',
      description:
          "Wakes right after the Sniper and reviews their shot,\n"
          'approving or vetoing it before it takes effect.',
      nameFa: 'فرمانده',
      descriptionFa:
          'درست بعد از اسنایپر بیدار می‌شود و شات او را بررسی می‌کند؛\n'
          'می‌تواند شات را تأیید یا رد کند.',
      iconAsset: 'assets/icons/commander.svg',
      emoji: '🎖️',
      color: AppColors.citizenTeam,
      shortDescription: 'Wakes after the Sniper to approve or reject his shot.',
      shortDescriptionFa: 'بعد از اسنایپر بیدار می‌شود و شاتش را تأیید یا رد می‌کند.',
    ),
    RoleType.guard: Role(
      type: RoleType.guard,
      team: Team.citizen,
      name: 'Guard',
      description:
          'If the Thief targets him at night, the Thief is caught.\n'
          'The next day, the Thief is publicly eliminated with his role revealed.\n'
          'If the Guard himself is voted out (in a 12-player game), his role\n'
          'is announced, and the game continues as if a plain Citizen left.',
      nameFa: 'نگهبان',
      descriptionFa:
          'اگر دزد در شب او را هدف بگیرد، دزد دستگیر می‌شود.\n'
          'فردای آن شب، دزد با اعلام نقش از بازی خارج می‌شود.\n'
          'اگر خودِ نگهبان با رأی‌گیری خارج شود (در بازی 12 نفره)، نقشش\n'
          'اعلام می‌شود و بازی مثل خروج یک شهروند ساده ادامه پیدا می‌کند.',
      iconAsset: 'assets/icons/guard.svg',
      emoji: '💂',
      color: AppColors.citizenTeam,
      shortDescription: 'Catches the Thief if targeted by him at night.',
      shortDescriptionFa: 'اگر دزد شب به او بزند، دزد را دستگیر می‌کند.',
    ),
    RoleType.freemason: Role(
      type: RoleType.freemason,
      team: Team.citizen,
      name: 'Freemason',
      description:
          'Each night, wakes one player he trusts. If that player is a '
          'citizen (or the mafia\'s Spy in disguise), the link survives and '
          'they consult together from then on. If he instead wakes any '
          'other mafia member or an independent player, the whole link '
          '(including the Freemason) is eliminated - but that player '
          'stays in the game.',
      nameFa: 'سرماسون',
      descriptionFa:
          'هر شب یک بازیکن مورد اعتمادش را بیدار می‌کند. اگر او شهروند باشد '
          '(یا جاسوس مافیا که خودش را جا زده)، لینک سالم می‌ماند و از آن پس '
          'با هم مشورت می‌کنند. اگر به‌جای آن، یک مافیای دیگر یا یک بازیکن '
          'مستقل را بیدار کند، کل زنجیره (از جمله خود سرماسون) از بازی خارج '
          'می‌شود، اما آن بازیکن در بازی می‌ماند.',
      iconAsset: 'assets/icons/freemason.svg',
      emoji: '🤝',
      color: AppColors.citizenTeam,
      shortDescription: 'Wakes trusted citizens to form a consulting link.',
      shortDescriptionFa: 'شهروندان مورد اعتماد را برای مشورت بیدار می‌کند.',
    ),
    RoleType.tyler: Role(
      type: RoleType.tyler,
      team: Team.citizen,
      name: 'Tyler',
      description:
          "A citizen - the Freemason's deputy. From night two, can wake "
          "with the Freemason's permission to help form a trustworthy citizen link.",
      nameFa: 'تایلر',
      descriptionFa:
          'شهروند - نایب سرماسون. از شب دوم می‌تواند با اجازه‌ی سرماسون '
          'بیدار شود و به شکل‌گیری یک لینک شهروندی مطمئن کمک کند.',
      iconAsset: 'assets/icons/tyler.svg',
      emoji: '🗝️',
      color: AppColors.citizenTeam,
      shortDescription: "Deputy Freemason; helps form the citizen link.",
      shortDescriptionFa: 'نایب سرماسون؛ به شکل‌گیری لینک شهروندی کمک می‌کند.',
    ),
    RoleType.snowman: Role(
      type: RoleType.snowman,
      team: Team.citizen,
      name: 'Snowman',
      description:
          'A citizen with a snowball. At night, throws it at a player: if '
          'they are a citizen, the snowball reaches them and can be thrown '
          'again the next night. If thrown at a mafia member, the snowball '
          '"melts" - revealing to the Snowman that the target is mafia.',
      nameFa: 'آدم برفی',
      descriptionFa:
          'شهروندی با یک گلوله برفی. شب آن را به یک بازیکن پرتاب می‌کند: اگر '
          'شهروند باشد، گلوله به او می‌رسد و شب بعد دوباره قابل پرتاب است. '
          'اگر به مافیا زده شود، گلوله «آب می‌شود» و آدم برفی می‌فهمد که او مافیاست.',
      iconAsset: 'assets/icons/snowman.svg',
      emoji: '⛄',
      color: AppColors.citizenTeam,
      shortDescription: 'Throws a snowball; it melts if it hits mafia.',
      shortDescriptionFa: 'گلوله برفی پرتاب می‌کند؛ روی مافیا آب می‌شود.',
    ),
    RoleType.veteran: Role(
      type: RoleType.veteran,
      team: Team.citizen,
      name: 'Veteran',
      description:
          'A citizen who can go on high alert some nights; anyone who '
          'targets him that night is eliminated instead of him.',
      nameFa: 'کهنه‌سرباز',
      descriptionFa:
          'شهروندی که برخی شب‌ها می‌تواند در حالت آماده‌باش کامل قرار '
          'بگیرد؛ هرکس آن شب او را هدف بگیرد، به‌جای او از بازی خارج می‌شود.',
      iconAsset: 'assets/icons/veteran.svg',
      emoji: '🪖',
      color: AppColors.citizenTeam,
      shortDescription: 'On alert nights, eliminates anyone who targets him.',
      shortDescriptionFa: 'در شب‌های آماده‌باش، هدف‌گیرنده‌اش را حذف می‌کند.',
    ),
    RoleType.mayor: Role(
      type: RoleType.mayor,
      team: Team.citizen,
      name: 'Mayor',
      description:
          'A citizen who can reveal himself; once revealed, his vote '
          'counts as three instead of one.',
      nameFa: 'شهردار',
      descriptionFa:
          'شهروندی که می‌تواند خودش را آشکار کند؛ بعد از آشکار شدن، '
          'رأیش به‌جای یک، سه رأی حساب می‌شود.',
      iconAsset: 'assets/icons/mayor.svg',
      emoji: '🏛️',
      color: AppColors.citizenTeam,
      shortDescription: 'Once revealed, his vote counts as three.',
      shortDescriptionFa: 'بعد از آشکار شدن، رأیش سه‌برابر حساب می‌شود.',
    ),

    // ---------------------------------------------------------------
    // Mafia team
    // ---------------------------------------------------------------
    RoleType.mafia: Role(
      type: RoleType.mafia,
      team: Team.mafia,
      name: 'Mafia',
      description: 'Regular member of the mafia team.',
      nameFa: 'مافیای ساده',
      descriptionFa: 'عضو عادی تیم مافیاست.',
      iconAsset: 'assets/icons/mafia.svg',
      emoji: '👤',
      color: AppColors.mafiaTeam,
      shortDescription: 'Regular member of the mafia team.',
      shortDescriptionFa: 'عضو عادی تیم مافیاست.',
    ),
    RoleType.godfather: Role(
      type: RoleType.godfather,
      team: Team.mafia,
      name: 'Godfather',
      description:
          "Has one shield. The mafia's primary shooter.\nIf eliminated, shooting priority passes to: "
          '1) Natasha 2) Yakuza 3) Terrorist 4) Joker 5) Thief 6) Regular Mafia.',
      nameFa: 'پدرخوانده',
      descriptionFa:
          'یک شیلد دارد. شات‌زننده‌ی اصلی مافیاست.\n'
          'اگر او خارج شود، شات‌زنی به ترتیب می‌رسد به: '
          '1) ناتاشا 2) یاکوزا 3) تروریست 4) جوکر 5) دزد 6) مافیای ساده.',
      iconAsset: 'assets/icons/godfather.svg',
      emoji: '🎩',
      color: AppColors.mafiaTeam,
      shortDescription: "Has a shield; the mafia's primary shooter.",
      shortDescriptionFa: 'شیلد دارد؛ شات‌زننده‌ی اصلی مافیاست.',
    ),
    RoleType.terrorist: Role(
      type: RoleType.terrorist,
      team: Team.mafia,
      name: 'Terrorist',
      description:
          'Only through voting: if eliminated by vote,\nmay take one other player down with him.',
      nameFa: 'تروریست',
      descriptionFa:
          'فقط در رأی‌گیری؛ اگر با رأی از بازی خارج شود،\n'
          'می‌تواند یک بازیکن دیگر را با خود ببرد.',
      iconAsset: 'assets/icons/terrorist.svg',
      emoji: '💥',
      color: AppColors.mafiaTeam,
      shortDescription: 'If voted out, can take one other player with him.',
      shortDescriptionFa: 'اگر با رأی خارج شود، یک نفر دیگر را هم با خود می‌برد.',
    ),
    RoleType.thief: Role(
      type: RoleType.thief,
      team: Team.mafia,
      name: 'Thief',
      description:
          "A mafia member who doesn't know who the other mafia are. Each "
          "night, steals another role-holder's ability for that night. If "
          "he happens to target the Guard, he's caught and eliminated "
          "instead.",
      nameFa: 'دزد',
      descriptionFa:
          'عضو مافیاست ولی اعضای دیگر مافیا را نمی‌شناسد. هر شب توانایی یکی '
          'از بازیکنان نقش‌دار را برای همان شب می‌دزدد. اگر اتفاقاً نگهبان '
          'را هدف بگیرد، توسط او دستگیر شده و از بازی خارج می‌شود.',
      iconAsset: 'assets/icons/thief.svg',
      emoji: '🥷',
      color: AppColors.mafiaTeam,
      shortDescription: "Steals a role-holder's ability for one night.",
      shortDescriptionFa: 'برای یک شب، توانایی یک نقش‌دار را می‌دزدد.',
    ),
    RoleType.natasha: Role(
      type: RoleType.natasha,
      team: Team.mafia,
      name: 'Natasha',
      description:
          "A mafia member. Each night, can silence one player for the "
          "following day - that player has no right to speak, but keeps "
          "their right to vote. Cannot silence the same player a second "
          "time.",
      nameFa: 'ناتاشا',
      descriptionFa:
          'عضو مافیاست. هر شب می‌تواند یک بازیکن را برای روز بعد سکوت دهد؛ '
          'آن بازیکن حق صحبت ندارد اما حق رأی دادن را همچنان دارد. '
          'نمی‌تواند یک بازیکن را دوبار سکوت بدهد.',
      iconAsset: 'assets/icons/natasha.svg',
      emoji: '🤐',
      color: AppColors.mafiaTeam,
      shortDescription: 'Can silence one player each night.',
      shortDescriptionFa: 'هر شب می‌تواند یک بازیکن را ساکت کند.',
    ),
    RoleType.joker: Role(
      type: RoleType.joker,
      team: Team.mafia,
      name: 'Joker',
      description: "A mafia member. Reverses the result of the Detective's investigation.",
      nameFa: 'جوکر',
      descriptionFa: 'عضو مافیاست. نتیجه‌ی استعلام کارآگاه را برعکس نشان می‌دهد.',
      iconAsset: 'assets/icons/joker.svg',
      emoji: '🃏',
      color: AppColors.mafiaTeam,
      shortDescription: "Reverses the Detective's investigation result.",
      shortDescriptionFa: 'نتیجه‌ی استعلام کارآگاه را برعکس می‌کند.',
    ),
    RoleType.enchanter: Role(
      type: RoleType.enchanter,
      team: Team.mafia,
      name: 'Enchanter',
      description: "A mafia member. Disables a role-holder's ability for one night.",
      nameFa: 'افسونگر',
      descriptionFa: 'عضو مافیاست. برای یک شب، توانایی یک بازیکن نقش‌دار را غیرفعال می‌کند.',
      iconAsset: 'assets/icons/enchanter.svg',
      emoji: '✨',
      color: AppColors.mafiaTeam,
      shortDescription: "Disables a role-holder's ability for one night.",
      shortDescriptionFa: 'برای یک شب، توانایی یک نقش‌دار را غیرفعال می‌کند.',
    ),
    RoleType.yakuza: Role(
      type: RoleType.yakuza,
      team: Team.mafia,
      name: 'Yakuza',
      description:
          "A mafia member. May choose to exit the game instead of the mafia's shot,\n"
          'and in exchange identify and convert a plain Citizen into a mafia member.',
      nameFa: 'یاکوزا',
      descriptionFa:
          'عضو مافیاست. در صورت انتخاب خودش، می‌تواند به‌جای شات مافیا از بازی خارج شود\n'
          'و در عوض یک شهروند ساده را شناسایی و به مافیا تبدیل کند.',
      iconAsset: 'assets/icons/yakuza.svg',
      emoji: '🐉',
      color: AppColors.mafiaTeam,
      shortDescription: 'Can turn a citizen into mafia instead of shooting.',
      shortDescriptionFa: 'می‌تواند به‌جای شات، یک شهروند را به مافیا تبدیل کند.',
    ),
    RoleType.strongman: Role(
      type: RoleType.strongman,
      team: Team.mafia,
      name: 'Strongman',
      description:
          "A mafia member. Can confirm the Godfather's shot to break the "
          "Invincible's immunity - when he does, the target dies even if "
          "they're the Invincible, and even ignoring the Doctor's save.",
      nameFa: 'مرد قوی',
      descriptionFa:
          'عضو مافیاست. می‌تواند شات پدرخوانده را تأیید کند تا زره «رویین‌تن» '
          'خنثی شود - در این حالت، حتی اگر هدف رویین‌تن باشد و دکتر هم سیو '
          'داده باشد، از بازی خارج می‌شود.',
      iconAsset: 'assets/icons/strongman.svg',
      emoji: '💪',
      color: AppColors.mafiaTeam,
      shortDescription: "Can override the Invincible's immunity.",
      shortDescriptionFa: 'می‌تواند مصونیت رویین‌تن را خنثی کند.',
    ),
    RoleType.psycho: Role(
      type: RoleType.psycho,
      team: Team.mafia,
      name: 'Psycho',
      description:
          'A "silent" mafia member - does not wake with the mafia group, and '
          "the group doesn't necessarily know him. Called right after the "
          "mafia group; only gives a private 'like' to the game master, so "
          'the game master can identify him. His action: each night he '
          "points at a player, but the actual elimination falls on whoever "
          "THAT player gives their own 'like' to that same night - not the "
          'player he pointed at.',
      nameFa: 'روانی',
      descriptionFa:
          'یک مافیای «خاموش» است - با گروه مافیا بیدار نمی‌شود و لزوماً '
          'گروه هم او را نمی‌شناسد. بلافاصله بعد از گروه مافیا صدا زده '
          'می‌شود؛ فقط یک «لایک» خصوصی به گرداننده می‌دهد تا گرداننده بتواند '
          'شناسایی‌اش کند. اقدامش: هر شب به یک بازیکن اشاره می‌کند، اما '
          'خروجِ واقعی به کسی می‌رسد که آن بازیکن، همان شب، به او «لایک» '
          'داده - نه به خودِ فردی که روانی اشاره کرده.',
      iconAsset: 'assets/icons/psycho.svg',
      emoji: '🤪',
      color: AppColors.mafiaTeam,
      shortDescription: "Silent mafia; his target's own 'like' recipient is eliminated.",
      shortDescriptionFa: 'مافیای خاموش؛ کسی که هدفش لایک بدهد خارج می‌شود.',
    ),
    RoleType.spy: Role(
      type: RoleType.spy,
      team: Team.mafia,
      name: 'Spy',
      description:
          "A mafia member. If the Freemasons' citizen link mistakenly wakes "
          'him, the link does not break - the Spy stays inside it, and '
          'misleads the citizens with false advice during consultation.',
      nameFa: 'جاسوس',
      descriptionFa:
          'عضو مافیاست. اگر لینک شهروندی سرماسون‌ها اشتباهاً او را بیدار '
          'کند، زنجیره نمی‌سوزد - جاسوس داخل لینک می‌ماند و شهروندان را با '
          'مشورت اشتباه گمراه می‌کند.',
      iconAsset: 'assets/icons/spy.svg',
      emoji: '🕵️',
      color: AppColors.mafiaTeam,
      shortDescription: "Hides inside the citizen link, misleading it from within.",
      shortDescriptionFa: 'داخل لینک شهروندی پنهان می‌شود و آن‌ها را گمراه می‌کند.',
    ),
    RoleType.consigliere: Role(
      type: RoleType.consigliere,
      team: Team.mafia,
      name: 'Consigliere',
      description:
          'A mafia member. Investigates a player each night and learns '
          "their exact role - stronger than the Detective's check.",
      nameFa: 'مشاور',
      descriptionFa:
          'عضو مافیاست. هر شب یک بازیکن را استعلام می‌گیرد و نقش دقیقش را '
          'می‌فهمد - قوی‌تر از استعلام کارآگاه.',
      iconAsset: 'assets/icons/consigliere.svg',
      emoji: '🧠',
      color: AppColors.mafiaTeam,
      shortDescription: "Investigates a player and learns their exact role.",
      shortDescriptionFa: 'استعلام می‌گیرد و نقش دقیق فرد را می‌فهمد.',
    ),
    RoleType.blackmailer: Role(
      type: RoleType.blackmailer,
      team: Team.mafia,
      name: 'Blackmailer',
      description:
          'A mafia member. Can silence a player during the day - they '
          'cannot speak or vote that round.',
      nameFa: 'باج‌گیر',
      descriptionFa:
          'عضو مافیاست. می‌تواند یک بازیکن را در طول روز ساکت کند - آن '
          'بازیکن در آن دور نمی‌تواند صحبت یا رأی بدهد.',
      iconAsset: 'assets/icons/blackmailer.svg',
      emoji: '🤫',
      color: AppColors.mafiaTeam,
      shortDescription: 'Silences a player during the day.',
      shortDescriptionFa: 'یک بازیکن را در طول روز ساکت می‌کند.',
    ),

    // ---------------------------------------------------------------
    // Independent
    // ---------------------------------------------------------------
    RoleType.nostradamus: Role(
      type: RoleType.nostradamus,
      team: Team.independent,
      name: 'Nostradamus',
      description:
          'Independent side. Starting night 2, has shooting rights every\n'
          'other night. Has a shield lasting the whole game - can only be\n'
          "eliminated by voting, or by the Terrorist's or Cowboy's day action.\n"
          "The mafia's Strongman can neutralize this shield. On the nights\n"
          'he does not shoot, he instead has the "no-shot" slaughter ability.',
      nameFa: 'نوستراداموس',
      descriptionFa:
          'ساید مستقل. از شب دوم به بعد، یک شب در میان حق شات دارد.\n'
          'یک شیلد دارد که تا آخر بازی پابرجاست - فقط با رأی‌گیری، یا با اکت\n'
          'تروریست یا کابوی در روز، از بازی خارج می‌شود. «مرد قوی» مافیا\n'
          'می‌تواند این شیلد را خنثی کند. در شب‌هایی که شات نمی‌زند، به‌جای\n'
          'آن توانایی «ناتویی»/سلاخی دارد.',
      iconAsset: 'assets/icons/nostradamus.svg',
      emoji: '🔮',
      color: AppColors.independentTeam,
      shortDescription: 'Independent; shoots every other night, with a shield.',
      shortDescriptionFa: 'مستقل؛ یک شب در میان شات دارد و شیلد هم دارد.',
    ),
    RoleType.killer: Role(
      type: RoleType.killer,
      team: Team.independent,
      name: 'Killer',
      description:
          'Independent side. Always has a shield at night - except the '
          "mafia's Strongman can override it and eliminate him. Shoots "
          'every night.',
      nameFa: 'کیلر',
      descriptionFa:
          'ساید مستقل. همیشه در شب شیلد دارد - مگر اینکه «مرد قوی» مافیا '
          'شیلدش را خنثی کند و او را حذف کند. هر شب شات می‌زند.',
      iconAsset: 'assets/icons/killer.svg',
      emoji: '☠️',
      color: AppColors.independentTeam,
      shortDescription: 'Independent; always shielded except vs. the Strongman.',
      shortDescriptionFa: 'مستقل؛ همیشه شیلد دارد مگر در برابر مرد قوی.',
    ),
    RoleType.president: Role(
      type: RoleType.president,
      team: Team.independent,
      name: 'President',
      description:
          'Independent side, used in Advanced Mafia (15+ players) when the '
          "setup has at least 4-5 plain Mafia. Has no active ability of his "
          "own - his only power is voting during the day, like anyone else. "
          "At night he wakes together with the plain Mafia group and they "
          "recognize each other, but he is NOT counted as Mafia for any win "
          "condition. If the Freemason's link mistakenly wakes him, the "
          "link does not break - he is treated like a plain citizen for "
          "that purpose. The Mafia Spy, who doesn't wake with his own team, "
          "has no way of recognizing him either. He wins the instant the "
          "Mafia and Citizen counts become equal (or Mafia exceeds "
          "Citizens) while he is still alive - he doesn't need to survive "
          "to the end of the game, only for that moment to occur. If a "
          "Yakuza converts him, he stops being Independent and becomes "
          "Mafia. In the roster, a plain-Mafia icon is always shown next "
          "to his for reference - it's informational only and never "
          "counted toward the Mafia total.",
      nameFa: 'پرزیدنت',
      descriptionFa:
          'ساید مستقل، مخصوص بازی‌های Advanced Mafia (۱۵ نفر به بالا) که '
          'حداقل ۴ تا ۵ مافیای ساده در ترکیبشان باشد. هیچ اکت اختصاصی '
          'ندارد - تنها قدرتش رأی دادن در روز است، مثل بقیه بازیکنان. '
          'شب‌ها همراه گروه مافیای ساده بیدار می‌شود و همدیگر را '
          'می‌شناسند، اما برای هیچ شرط بردی جزو مافیا محاسبه نمی‌شود. '
          'اگر لینک سرماسون به‌اشتباه او را بیدار کند، لینک نمی‌سوزد - '
          'از این نظر مثل یک شهروند ساده در نظر گرفته می‌شود. جاسوس '
          'مافیا هم چون با تیم خودش بیدار نمی‌شود، او را نمی‌شناسد. '
          'پرزیدنت همان لحظه‌ای که تعداد مافیا و شهروند برابر شود (یا '
          'مافیا بیشتر شود) و او هنوز زنده باشد برنده می‌شود - لازم '
          'نیست تا پایان بازی زنده بماند، فقط باید همان لحظه رخ بدهد. '
          'اگر یاکوزایی او را تبدیل کند، دیگر مستقل نیست و مافیا '
          'می‌شود. در لیست بازیکنان، همیشه یک آیکون مافیای ساده کنار '
          'آیکون او نمایش داده می‌شود - فقط جنبه اطلاعاتی دارد و هرگز '
          'در شمارش مافیا حساب نمی‌شود.',
      iconAsset: 'assets/icons/mayor.svg',
      emoji: '🎩',
      color: AppColors.independentTeam,
      shortDescription: 'Independent; no ability, wins when Mafia >= Citizens.',
      shortDescriptionFa: 'مستقل؛ بدون اکت، وقتی مافیا ≥ شهروند شود برنده می‌شود.',
    ),
  };

  static Role of(RoleType type) => _withOverride(all[type]!);

  /// All built-in (non-custom) roles belonging to a given [team], in a
  /// stable display order (plain role first, then specials).
  static List<Role> forTeam(Team team) =>
      all.values.where((r) => r.team == team).map(_withOverride).toList();

  /// If the game master has renamed/re-described this role, returns a
  /// copy with the saved text; otherwise returns [base] unchanged. The
  /// role's mechanic, team, icon, and color are never overridden - only
  /// the displayed name/description text.
  static Role _withOverride(Role base) {
    final override = RoleOverridesStore.overrideFor(base.type.name);
    if (override == null) return base;
    return Role(
      type: base.type,
      team: base.team,
      name: override['name'] ?? base.name,
      description: override['description'] ?? base.description,
      nameFa: override['nameFa'] ?? base.nameFa,
      descriptionFa: override['descriptionFa'] ?? base.descriptionFa,
      iconAsset: base.iconAsset,
      color: base.color,
      emoji: override['emoji'] ?? base.emoji,
      shortDescription: base.shortDescription,
      shortDescriptionFa: base.shortDescriptionFa,
    );
  }
}
