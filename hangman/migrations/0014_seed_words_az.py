# -*- coding: utf-8 -*-
from django.db import migrations

# First-pass Azerbaijani word pool (Can: "AI draft + your review" — same convention as
# the en/ru/tr pools in migrations 0010-0012 — treat this as a draft to review/edit
# via Django admin, not final copy). Independently curated (not a translation of the
# Turkmen list) for broadly recognizable Azerbaijani vocabulary and good hangman
# letter variety.
#
# Compound nouns that are normally written as two words in real Azerbaijani (e.g.
# "göy qurşağı") are combined into one token with no space, same convention the
# Turkish/English pools already use (e.g. Turkish "GÖKKUŞAĞI") — a literal space
# character isn't handled by the Jellad/Krosword engines, which treat every
# character of `word` as a single guessable letter.
#
# The on-screen keyboard (turkmen_keyboard.dart, 'az' rows) covers the full
# 32-letter Azerbaijani Latin alphabet (Ə Ğ Ç Ş Ö Ü İ I X Q J included), so any
# correctly-spelled native Azerbaijani word works here.
WORDS = [
    # Heyvanlar (Animals)
    ("ASLAN", "Meşələr kralı adlanan iri pişik", "easy"),
    ("PƏLƏNG", "Narıncı-qara zolaqlı iri pişik", "easy"),
    ("FİL", "Xortumu olan ən böyük quru heyvanı", "easy"),
    ("ZÜRAFƏ", "Boynu çox uzun olan heyvan", "easy"),
    ("DELFİN", "Ağıllı və oynaq dəniz məməlisi", "easy"),
    ("PİNQVİN", "Uça bilməyən, soyuq bölgələrdə yaşayan quş", "easy"),
    ("KENQURU", "Tullanaraq hərəkət edən, balasını kisəsində daşıyan heyvan", "medium"),
    ("ÇİTA", "Quruda ən sürətli qaçan heyvan", "medium"),
    ("AXTAPOT", "Səkkiz qollu dəniz canlısı", "medium"),
    ("FLAMİNQO", "Bir ayaq üstə duran çəhrayı quş", "medium"),
    ("TİMSAH", "Çaylarda yaşayan iri sürünən", "medium"),
    ("DOVŞAN", "Uzun qulaqlı, sıçrayan heyvan", "easy"),
    ("KİRPİ", "Kürəyi tikanlarla örtülü kiçik məməli", "medium"),
    ("QURD", "Sürü ilə yaşayan yırtıcı heyvan", "easy"),
    ("AYI", "Meşələrdə yaşayan iri, tüklü heyvan", "easy"),
    # Təbiət və coğrafiya (Nature & geography)
    ("DAĞ", "Təpədən daha hündür yer səthi forması", "easy"),
    ("YANARDAĞ", "Lava püskürə bilən dağ", "medium"),
    ("ŞƏLALƏ", "Yuxarıdan tökülən su", "easy"),
    ("SƏHRA", "Yağıntının çox az olduğu quraq bölgə", "easy"),
    ("BUZLAQ", "Yavaş hərəkət edən nəhəng buz kütləsi", "medium"),
    ("GÖYQURŞAĞI", "Yağışdan sonra göydə görünən rəngli qövs", "easy"),
    ("İLDIRIM", "Fırtınada göydə parlayan işıq", "easy"),
    ("QASIRĞA", "Güclü fırlanaraq irəliləyən tropik tufan", "medium"),
    ("ADA", "Ətrafı tamamilə su ilə əhatələnmiş quru sahə", "easy"),
    ("MEŞƏ", "Əsasən ağaclarla örtülü geniş sahə", "easy"),
    ("VAHƏ", "Səhranın ortasındakı yaşıl və sulu sahə", "medium"),
    ("EVEREST", "Dünyanın ən hündür dağı", "medium"),
    ("AMAZON", "Dünyanın ən böyük yağış meşəsi", "medium"),
    ("QALAKTİKA", "Ulduzların əmələ gətirdiyi nəhəng topa", "medium"),
    ("QÜTB", "Dünyanın ən şimalı və ya ən cənubu", "medium"),
    ("KANYON", "Çayın oyduğu dərin dərə", "medium"),
    # Paytaxtlar və abidələr (Capitals & landmarks)
    ("PARİS", "Eyfel Qülləsinin yerləşdiyi şəhər", "easy"),
    ("LONDON", "İngiltərənin paytaxtı", "easy"),
    ("TOKİO", "Yaponiyanın paytaxtı", "easy"),
    ("QAHİRƏ", "Piramidalara yaxın Misir paytaxtı", "medium"),
    ("MOSKVA", "Rusiyanın paytaxtı", "easy"),
    ("BERLİN", "Almaniyanın paytaxtı", "easy"),
    ("PİRAMİDA", "Misirdə üçbucaq şəklində qədim abidə", "easy"),
    ("KOLİZEY", "Romada qədim qladiator arenası", "hard"),
    ("AKROPOL", "Afinada qədim təpə qalası", "hard"),
    ("SFENKS", "Aslan bədənli, insan başlı heykəl", "medium"),
    ("VATİKAN", "Dünyanın ən kiçik dövləti", "medium"),
    ("İSTANBUL", "Həm Avropada, həm Asiyada yerləşən yeganə şəhər", "easy"),
    ("BAKI", "Azərbaycanın paytaxtı", "easy"),
    ("QOBUSTAN", "Qədim qaya rəsmləri ilə məşhur Azərbaycan yeri", "medium"),
    ("İÇƏRİŞƏHƏR", "Bakının qədim şəhər hissəsi", "hard"),
    # Yemək (Food)
    ("MAKARON", "İtalyan mətbəxindən uzun nazik xəmir yeməyi", "easy"),
    ("KRUASSAN", "Aypara şəklində, qatlı xəmir məmulatı", "medium"),
    ("BLİN", "Şərbətlə yeyilən nazik səhər yeməyi", "easy"),
    ("AVOKADO", "Quakamole hazırlanan yaşıl meyvə", "easy"),
    ("ANANAS", "Tikanlı qabıqlı tropik meyvə", "easy"),
    ("ŞOKOLAD", "Kakaodan hazırlanan şirniyyat", "easy"),
    ("SENDVİÇ", "İki çörək dilimi arasına qoyulan yemək", "easy"),
    ("BAKLAVA", "Qoz-fındıqlı, ballı, qatlı şirniyyat", "easy"),
    ("DOLMA", "Üzüm yarpağı və ya tərəvəzə doldurulan yemək", "easy"),
    ("PLOV", "Düyüdən hazırlanan Azərbaycan milli yeməyi", "easy"),
    ("QUTAB", "Nazik xəmirə ət və ya göyərti doldurulan yemək", "medium"),
    ("ŞƏKƏRBURA", "Qoz-fındıqla doldurulan bayram şirniyyatı", "hard"),
    ("SUMAQ", "Turşməzə dad verən qırmızı ədviyyat", "medium"),
    ("DARÇIN", "Ağac qabığından alınan isti ədviyyat", "medium"),
    ("QARPIZ", "Yayda sevilən şirin, qırmızı içli meyvə", "easy"),
    # Texnologiya (Technology)
    ("İNTERNET", "Kompüterləri bir-birinə bağlayan qlobal şəbəkə", "easy"),
    ("TELEFON", "Səsli danışıq üçün istifadə olunan cihaz", "easy"),
    ("KLAVİATURA", "Kompüterdə yazı yazmaq üçün istifadə olunan cihaz", "medium"),
    ("ŞİFRƏ", "Hesaba giriş üçün istifadə olunan gizli kod", "easy"),
    ("ROBOT", "Tapşırıqları özü yerinə yetirə bilən maşın", "easy"),
    ("PEYK", "Yer kürəsinin orbitində fırlanan siqnal ötürücü cisim", "medium"),
    ("ALQORİTM", "Kompüterin problemi həll etmək üçün izlədiyi addımlar", "hard"),
    ("PROQRAM", "Kompüterdə işləyən tətbiqlərin ümumi adı", "medium"),
    ("BRAUZER", "İnternet saytlarına baxmaq üçün istifadə olunan proqram", "medium"),
    ("TƏTBİQ", "Telefona yüklənən proqram", "medium"),
    ("ŞƏBƏKƏ", "Cihazları bir-birinə bağlayan sistem", "easy"),
    ("SERVER", "Şəbəkədəki digər cihazlara xidmət göstərən kompüter", "medium"),
    ("İSTİFADƏÇİ", "Sistemə giriş edərkən istifadə olunan hesab sahibi", "easy"),
    # Elm və kosmos (Science & space)
    ("CAZİBƏ", "Cisimləri yerə doğru çəkən qüvvə", "medium"),
    ("OKSİGEN", "İnsanın nəfəs alması üçün lazım olan qaz", "easy"),
    ("MOLEKUL", "Bir birləşmənin ən kiçik hissəsi", "medium"),
    ("BAKTERİYA", "Tək hüceyrəli çox kiçik canlı", "medium"),
    ("PEYVƏND", "Xəstəlikdən qoruyan iynə", "easy"),
    ("ASTEROİD", "Günəşin ətrafında dönən qayalı göy cismi", "medium"),
    ("DİNOZAVR", "Milyonlarla il əvvəl yaşamış, nəsli kəsilmiş sürünən", "easy"),
    ("SKELET", "Bədəni ayaqda saxlayan sümüklər", "easy"),
    ("MAQNİT", "Dəmiri özünə çəkən cisim", "easy"),
    ("TELESKOP", "Uzaq ulduzları müşahidə etmək üçün alət", "medium"),
    ("ASTRONAVT", "Kosmosa getmək üçün hazırlanan şəxs", "easy"),
    ("RAKET", "Kosmosa buraxılan vasitə", "easy"),
    ("ULDUZ", "Gecə göydə parlayan göy cismi", "easy"),
    ("PLANET", "Bir ulduzun ətrafında fırlanan böyük göy cismi", "easy"),
    ("ATMOSFER", "Bir planeti əhatə edən qaz təbəqəsi", "medium"),
    # Gündəlik əşyalar (Everyday objects)
    ("ÇƏTİR", "Yağışdan qorunmaq üçün istifadə olunur", "easy"),
    ("ÇANTA", "Çiyində və ya əldə daşınan əşya", "easy"),
    ("GÜZGÜ", "Əksini göstərən əşya", "easy"),
    ("ŞAM", "Yanan fitili olan mum çubuq", "easy"),
    ("YORĞAN", "Yataqda səni isti saxlayan örtük", "easy"),
    ("QAYÇI", "Kağız kəsmək üçün istifadə olunan alət", "easy"),
    ("ZƏRF", "Məktub göndərmək üçün istifadə olunan kağız qab", "easy"),
    ("PUSULA", "Şimalı göstərən alət", "medium"),
    ("NƏRDİVAN", "Hündür yerlərə çıxmaq üçün istifadə olunur", "easy"),
    ("FİT", "Üfürüldükdə iti səs çıxaran kiçik alət", "easy"),
    ("ÇAMADAN", "Səyahətdə əşya daşımaq üçün istifadə olunan çanta", "easy"),
    ("FƏNƏR", "Batareya ilə işləyən portativ işıq mənbəyi", "easy"),
    ("DƏFTƏR", "Qeyd almaq üçün istifadə olunan səhifələr", "easy"),
    ("PULQABI", "Pul və kartların saxlandığı kiçik əşya", "easy"),
    # Peşələr (Professions)
    ("HƏKİM", "Xəstə insanları müalicə edir", "easy"),
    ("MÜƏLLİM", "Şagirdlərin öyrənməsinə kömək edir", "easy"),
    ("İTFAİYƏÇİ", "Yanğınları söndürür və insanları xilas edir", "easy"),
    ("MÜHƏNDİS", "Tikili və ya maşınlar layihələndirir", "medium"),
    ("SANTEXNİK", "Su borularını təmir edir", "medium"),
    ("MEMAR", "Bina layihələndirən şəxs", "medium"),
    ("CƏRRAH", "Əməliyyat aparan həkim", "medium"),
    ("PİLOT", "Təyyarə idarə edən şəxs", "easy"),
    ("DETEKTİV", "Cinayətləri araşdıran şəxs", "medium"),
    ("FOTOQRAF", "Şəkil çəkməyi peşə seçən şəxs", "medium"),
    # İdman (Sports)
    ("FUTBOL", "Dəyirmi topla oynanan məşhur idman", "easy"),
    ("BASKETBOL", "Topu səbətə atmaqla oynanan idman", "easy"),
    ("MARAFON", "Çox uzun məsafəyə qaçış yarışı", "medium"),
    ("GİMNASTİKA", "Tarazlıq və çeviklik tələb edən idman", "medium"),
    ("GÜLƏŞ", "Rəqibi yerə salmağa əsaslanan idman", "medium"),
    ("OXATMA", "Hədəfə ox atma idmanı", "medium"),
    ("VOLEYBOL", "Topu tor üzərindən keçirməklə oynanan idman", "easy"),
    ("ŞAHMAT", "Şah və vəzirin olduğu strategiya oyunu", "easy"),
    ("ÜZGÜÇÜLÜK", "Suda hərəkət etməyi tələb edən idman", "easy"),
    ("BOKS", "Yumruqlarla aparılan döyüş idmanı", "easy"),
    # Hisslər və mücərrəd anlayışlar (Emotions & abstract)
    ("MARAQ", "Bir şeyi öyrənmək üçün güclü istək", "medium"),
    ("QISQANCLIQ", "Başqasında olanı istəmə hissi", "medium"),
    ("MİNNƏTDARLIQ", "Təşəkkür hissi", "medium"),
    ("CƏSARƏT", "Qorxuya baxmayaraq göstərilən igidlik", "easy"),
    ("SƏBR", "Sakit şəkildə gözləyə bilmə bacarığı", "medium"),
    ("DOSTLUQ", "Yaxın dostlar arasındakı bağ", "easy"),
    ("AZADLIQ", "İstədiyin kimi davranmaq və düşünmək hüququ", "easy"),
    ("XOŞBƏXTLİK", "Sevinc və rahatlıq hissi", "easy"),
    ("SƏDAQƏT", "Bağlılıq və etibarlılıq", "medium"),
    ("HƏMRƏYLİK", "Sülh içində birlik halı", "medium"),
    # Müxtəlif / mədəniyyət (Misc / culture)
    ("TAR", "Azərbaycan xalq musiqisində çalınan simli alət", "medium"),
    ("KAMANÇA", "Yayla çalınan Azərbaycan simli aləti", "medium"),
    ("XALÇA", "Yerlərə sərilən toxuma örtük", "easy"),
    ("ÇİNİ", "Bəzəkli keramika növü", "medium"),
    ("ORKESTR", "Birlikdə çalan böyük musiqiçi qrupu", "medium"),
    ("KARNAVAL", "Kostyum və əyləncə dolu bayram", "easy"),
    ("SİRK", "Akrobatların və məzhəkəçilərin olduğu tamaşa yeri", "easy"),
    ("KİTABXANA", "Kitabların saxlanıldığı və icarəyə verildiyi yer", "easy"),
    ("MUZEY", "İncəsənət və tarix əsərlərinin sərgiləndiyi yer", "easy"),
    ("NOVRUZ", "Azərbaycanda bahar bayramı", "easy"),
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
            language='az',
            defaults={'hint': hint, 'difficulty': difficulty, 'is_active': True},
        )


def unseed_words(apps, schema_editor):
    pass  # intentionally a no-op — don't delete words on rollback


class Migration(migrations.Migration):

    dependencies = [
        ('hangman', '0013_hangmanword_language_az_uz'),
    ]

    operations = [
        migrations.RunPython(seed_words, reverse_code=unseed_words),
    ]
