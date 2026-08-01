# -*- coding: utf-8 -*-
from django.db import migrations

# First-pass Uzbek word pool (Can: "AI draft + your review" — same convention as
# the en/ru/tr/az pools in migrations 0010-0014 — treat this as a draft to
# review/edit via Django admin, not final copy). Written in the modern official
# Uzbek Latin script.
#
# IMPORTANT — the Oʻ/Gʻ modifier character: words below use U+02BB MODIFIER
# LETTER TURNED COMMA (ʻ) for oʻ/gʻ, e.g. "TOGʻ" (mountain), "BOʻRI" (wolf) —
# the same character the on-screen keyboard's extra key uses (see
# turkmen_keyboard.dart, 'uz' rows). This is a real, separate Unicode
# character, not a straight apostrophe ('); using the wrong one would make a
# word's oʻ/gʻ un-guessable since the keyboard key and the stored word would
# no longer match character-for-character.
#
# Sh/Ch are NOT combined into single keyboard keys — they're two ordinary
# Latin letters in sequence (S+H, C+H), exactly like every other Latin-script
# language in this app, so no special digraph handling was needed in the
# Jellad/Krosword engines for this language.
WORDS = [
    # Hayvonlar (Animals)
    ("SHER", "Oʻrmonlar qiroli hisoblangan yirik mushuk", "easy"),
    ("YOʻLBARS", "Sariq-qora chiziqli yirik mushuk", "easy"),
    ("FIL", "Eng katta quruqlik hayvoni, xartumli", "easy"),
    ("JIRAFA", "Boʻyni juda uzun hayvon", "easy"),
    ("DELFIN", "Aqlli va oʻynoqi dengiz sut emizuvchisi", "easy"),
    ("PINGVIN", "Ucha olmaydigan, sovuq mintaqada yashaydigan qush", "easy"),
    ("KENGURU", "Sakrab yuradigan, bolasini xaltachada tashiydigan hayvon", "medium"),
    ("TOSHBAQA", "Qattiq qobiqli sekin hayvon", "easy"),
    ("AHTAPOT", "Sakkiz oyoqli dengiz jonivori", "medium"),
    ("QUYON", "Uzun quloqli sakrovchi hayvon", "easy"),
    ("TIMSOH", "Daryolarda yashaydigan yirik sudralib yuruvchi", "medium"),
    ("KIRPI", "Tanasi ignalar bilan qoplangan mayda sut emizuvchi", "medium"),
    ("BOʻRI", "Suruv boʻlib yashaydigan yirtqich hayvon", "easy"),
    ("AYIQ", "Oʻrmonlarda yashaydigan yirik junli hayvon", "easy"),
    ("TOVUS", "Rangdor patli chiroyli qush", "medium"),
    # Tabiat va geografiya (Nature & geography)
    ("TOGʻ", "Tepalikdan balandroq yer sathi", "easy"),
    ("SHARSHARA", "Yuqoridan quyilib tushadigan suv", "easy"),
    ("CHOʻL", "Yogʻingarchilik kam boʻlgan quruq hudud", "easy"),
    ("MUZLIK", "Sekin harakatlanadigan katta muz massasi", "medium"),
    ("KAMALAK", "Yomgʻirdan keyin osmonda koʻrinadigan rangli yoy", "easy"),
    ("CHAQMOQ", "Boʻronda osmonda yaltiraydigan yorugʻlik", "easy"),
    ("BOʻRON", "Kuchli aylanma tropik shamol", "medium"),
    ("OROL", "Atrofi butunlay suv bilan oʻralgan quruqlik", "easy"),
    ("OʻRMON", "Asosan daraxtlar bilan qoplangan katta maydon", "easy"),
    ("VOHA", "Choʻl oʻrtasidagi yashil va suvli joy", "medium"),
    ("EVEREST", "Dunyodagi eng baland togʻ", "medium"),
    ("AMAZONKA", "Dunyodagi eng katta yomgʻir ormoni", "medium"),
    ("GALAKTIKA", "Yulduzlardan tashkil topgan ulkan toʻplam", "medium"),
    ("QUTB", "Yer sharining eng shimoli yoki eng janubi", "medium"),
    ("KANYON", "Daryo oʻyib yasagan chuqur jarlik", "medium"),
    # Poytaxtlar va diqqatga sazovor joylar (Capitals & landmarks)
    ("PARIJ", "Eyfel minorasi joylashgan shahar", "easy"),
    ("LONDON", "Angliyaning poytaxti", "easy"),
    ("TOKIO", "Yaponiyaning poytaxti", "easy"),
    ("QOHIRA", "Ehromlarga yaqin Misr poytaxti", "medium"),
    ("MOSKVA", "Rossiyaning poytaxti", "easy"),
    ("BERLIN", "Germaniyaning poytaxti", "easy"),
    ("EHROM", "Misrdagi uchburchak shaklidagi qadimiy yodgorlik", "easy"),
    ("KOLIZEY", "Rimdagi qadimiy gladiator arenasi", "hard"),
    ("VATIKAN", "Dunyodagi eng kichik davlat", "medium"),
    ("ISTANBUL", "Ham Yevropada, ham Osiyoda joylashgan yagona shahar", "easy"),
    ("TOSHKENT", "Oʻzbekistonning poytaxti", "easy"),
    ("SAMARQAND", "Qadimiy Ipak yoʻli shahri", "medium"),
    ("BUXORO", "Qadimiy meʼmoriyati bilan mashhur oʻzbek shahri", "medium"),
    ("XIVA", "Tarixiy devorlari bilan mashhur shahar", "medium"),
    # Ovqat (Food)
    ("MAKARON", "Italyan oshxonasidan uzun ingichka xamir taomi", "easy"),
    ("KRUASSAN", "Yarim oy shaklidagi qatlamli xamir mahsuloti", "medium"),
    ("SHOKOLAD", "Kakaodan tayyorlangan shirinlik", "easy"),
    ("SENDVICH", "Ikki non boʻlagi orasiga qoʻyilgan taom", "easy"),
    ("ANANAS", "Tikanli poʻstli tropik meva", "easy"),
    ("AVOKADO", "Guakamole tayyorlashda ishlatiladigan yashil meva", "easy"),
    ("PALOV", "Guruchdan tayyorlanadigan oʻzbek milliy taomi", "easy"),
    ("SOMSA", "Tandirda pishiriladigan goʻshtli xamir taomi", "easy"),
    ("LAGMON", "Choʻzilgan xamir va goʻshtdan tayyorlanadigan taom", "medium"),
    ("MANTI", "Bugʻda pishiriladigan goʻshtli xamir taomi", "easy"),
    ("NON", "Oʻzbek tandir noni", "easy"),
    ("QOVUN", "Shirin, sariq ichli yozgi meva", "easy"),
    ("TARVUZ", "Yozda sevilgan shirin, qizil ichli meva", "easy"),
    ("QAYMOQ", "Sut mahsulotlaridan tayyorlanadigan yogʻli krem", "medium"),
    ("HALVA", "Yongʻoq va shakardan tayyorlangan shirinlik", "easy"),
    # Texnologiya (Technology)
    ("INTERNET", "Kompyuterlarni bir-biriga bogʻlaydigan global tarmoq", "easy"),
    ("TELEFON", "Ovozli muloqot uchun ishlatiladigan qurilma", "easy"),
    ("KLAVIATURA", "Kompyuterda yozish uchun ishlatiladigan qurilma", "medium"),
    ("PAROL", "Hisobga kirish uchun ishlatiladigan maxfiy kod", "easy"),
    ("ROBOT", "Vazifalarni oʻzi bajara oladigan mashina", "easy"),
    ("SPUTNIK", "Yer orbitasida aylanadigan signal uzatuvchi jism", "medium"),
    ("ALGORITM", "Kompyuterning masalani yechish uchun bosqichlar ketma-ketligi", "hard"),
    ("DASTUR", "Kompyuterda ishlaydigan ilovalarning umumiy nomi", "medium"),
    ("BRAUZER", "Internet saytlarini koʻrish uchun ishlatiladigan dastur", "medium"),
    ("ILOVA", "Telefonga yuklab olinadigan dastur", "medium"),
    ("TARMOQ", "Qurilmalarni bir-biriga bogʻlaydigan tizim", "easy"),
    ("FOYDALANUVCHI", "Tizimga kirishda ishlatiladigan hisob egasi", "easy"),
    # Fan va koinot (Science & space)
    ("OGʻIRLIK", "Jismlarni yerga tortadigan kuch", "medium"),
    ("KISLOROD", "Inson nafas olishi uchun zarur gaz", "easy"),
    ("BAKTERIYA", "Bir hujayrali juda mayda jonzot", "medium"),
    ("EMLASH", "Kasallikdan himoya qiluvchi igna", "easy"),
    ("ASTEROID", "Quyosh atrofida aylanadigan qoyali osmon jismi", "medium"),
    ("DINOZAVR", "Millionlab yil oldin yashagan, nasli qurigan sudralib yuruvchi", "easy"),
    ("SKELET", "Tanani tik tutib turadigan suyaklar", "easy"),
    ("MAGNIT", "Temirni oʻziga tortadigan jism", "easy"),
    ("TELESKOP", "Uzoq yulduzlarni kuzatish uchun asbob", "medium"),
    ("KOSMONAVT", "Kosmosga uchish uchun tayyorlangan shaxs", "easy"),
    ("RAKETA", "Kosmosga uchiriladigan qurilma", "easy"),
    ("YULDUZ", "Kechasi osmonda yaltiraydigan jism", "easy"),
    ("SAYYORA", "Yulduz atrofida aylanadigan katta osmon jismi", "easy"),
    ("ATMOSFERA", "Sayyorani oʻrab turgan gaz qatlami", "medium"),
    # Kundalik buyumlar (Everyday objects)
    ("SOYABON", "Yomgʻirdan himoya qilish uchun ishlatiladi", "easy"),
    ("SUMKA", "Yelkada yoki qoʻlda olib yuriladigan buyum", "easy"),
    ("OYNA", "Aksingizni koʻrsatadigan buyum", "easy"),
    ("SHAM", "Yonuvchi piligi boʻlgan mum tayoqcha", "easy"),
    ("KOʻRPA", "Yotoqda seni issiq tutadigan buyum", "easy"),
    ("QAYCHI", "Qogʻoz kesish uchun ishlatiladigan asbob", "easy"),
    ("ZARF", "Xat joʻnatish uchun ishlatiladigan qogʻoz qob", "easy"),
    ("KOMPAS", "Shimolni koʻrsatadigan asbob", "medium"),
    ("NARVON", "Baland joylarga chiqish uchun ishlatiladi", "easy"),
    ("HUSHTAK", "Puflaganda keskin tovush chiqaradigan asbob", "easy"),
    ("CHAMADON", "Sayohatda buyum olib yurish uchun sumka", "easy"),
    ("FONAR", "Batareyada ishlaydigan koʻchma yorugʻlik manbai", "easy"),
    ("DAFTAR", "Yozib olish uchun ishlatiladigan varaqlar", "easy"),
    ("HAMYON", "Pul va kartalar saqlanadigan kichik buyum", "easy"),
    # Kasblar (Professions)
    ("SHIFOKOR", "Kasal odamlarni davolaydi", "easy"),
    ("OʻQITUVCHI", "Oʻquvchilarning bilim olishiga yordam beradi", "easy"),
    ("MUHANDIS", "Inshootlar yoki mashinalarni loyihalaydi", "medium"),
    ("ARXITEKTOR", "Bino loyihalaydigan shaxs", "medium"),
    ("JARROH", "Operatsiya qiladigan shifokor", "medium"),
    ("UCHUVCHI", "Samolyot boshqaradigan shaxs", "easy"),
    ("DETEKTIV", "Jinoyatlarni tergov qiladigan shaxs", "medium"),
    ("FOTOGRAF", "Surat olishni kasb qilgan shaxs", "medium"),
    ("OSHPAZ", "Taom tayyorlaydigan shaxs", "easy"),
    # Sport (Sports)
    ("FUTBOL", "Dumaloq toʻp bilan oʻynaladigan mashhur sport", "easy"),
    ("BASKETBOL", "Toʻpni savatga tashlab oʻynaladigan sport", "easy"),
    ("MARAFON", "Juda uzoq masofaga yugurish musobaqasi", "medium"),
    ("GIMNASTIKA", "Muvozanat va egiluvchanlik talab qiladigan sport", "medium"),
    ("KURASH", "Raqibni yerga yiqitishga asoslangan sport", "medium"),
    ("VOLEYBOL", "Toʻpni tarmoq ustidan oʻtkazib oʻynaladigan sport", "easy"),
    ("SHAXMAT", "Shoh va farzin boʻlgan strategik oʻyin", "easy"),
    ("SUZISH", "Suvda harakatlanishni talab qiladigan sport", "easy"),
    ("BOKS", "Musht bilan olib boriladigan jang sporti", "easy"),
    # His-tuygʻular va mavhum tushunchalar (Emotions & abstract)
    ("QIZIQISH", "Biror narsani oʻrganishga boʻlgan kuchli istak", "medium"),
    ("HASAD", "Boshqada borini xohlash tuygʻusi", "medium"),
    ("MINNATDORLIK", "Rahmat tuygʻusi", "medium"),
    ("JASORAT", "Qoʻrquvga qaramay koʻrsatilgan mardlik", "easy"),
    ("SABR", "Xotirjam kutish qobiliyati", "medium"),
    ("DOʻSTLIK", "Yaqin doʻstlar orasidagi bogʻ", "easy"),
    ("ERKINLIK", "Istaganingdek harakat qilish va fikrlash huquqi", "easy"),
    ("BAXT", "Shodlik va xotirjamlik tuygʻusi", "easy"),
    ("SODIQLIK", "Bogʻlanish va ishonchlilik", "medium"),
    ("TOTUVLIK", "Tinchlik ichida birlik holati", "medium"),
    # Turli / madaniyat (Misc / culture)
    ("DUTOR", "Ikki torli oʻzbek xalq cholgʻu asbobi", "medium"),
    ("SURNAY", "Puflab chalinadigan oʻzbek xalq cholgʻu asbobi", "medium"),
    ("GILAM", "Yerlarga toʻshaladigan toʻqima buyum", "easy"),
    ("ORKESTR", "Birgalikda chaladigan katta musiqachilar guruhi", "medium"),
    ("KARNAVAL", "Kostyum va oʻyin-kulgiga toʻla bayram", "easy"),
    ("SIRK", "Akrobatlar va masxarabozlar boʻlgan tomosha joyi", "easy"),
    ("KUTUBXONA", "Kitoblar saqlanadigan va ijaraga beriladigan joy", "easy"),
    ("MUZEY", "Sanʼat va tarix asarlari namoyish etiladigan joy", "easy"),
    ("NAVROʻZ", "Bahor bayrami", "easy"),
    ("ATLAS", "Oʻzbek anʼanaviy ipak matosi", "medium"),
]


def seed_words(apps, schema_editor):
    HangmanWord = apps.get_model('hangman', 'HangmanWord')
    seen = set()
    for word, hint, difficulty in WORDS:
        if word in seen:
            continue
        seen.add(word)
        HangmanWord.objects.get_or_create(
            word=word,
            language='uz',
            defaults={'hint': hint, 'difficulty': difficulty, 'is_active': True},
        )


def unseed_words(apps, schema_editor):
    pass  # intentionally a no-op — don't delete words on rollback


class Migration(migrations.Migration):

    dependencies = [
        ('hangman', '0014_seed_words_az'),
    ]

    operations = [
        migrations.RunPython(seed_words, reverse_code=unseed_words),
    ]
