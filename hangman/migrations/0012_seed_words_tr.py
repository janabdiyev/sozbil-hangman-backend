# -*- coding: utf-8 -*-
from django.db import migrations

# First-pass Turkish word pool (Can: "AI draft + your review" — treat this as a
# draft to review/edit via Django admin, not final copy). Independently curated
# (not a translation of the Turkmen list) for broadly recognizable Turkish
# vocabulary and good hangman letter variety.
#
# IMPORTANT — dotted İ vs dotless I: every word below is written pre-uppercased
# with the correct Turkish casing (İ for a dotted lowercase i, plain I for a
# dotless lowercase ı) rather than relying on HangmanWord.save()'s generic
# .upper() call, which does NOT know Turkish casing rules and would turn a
# lowercase "i" into a dotless "I" (wrong for Turkish). Since these literals are
# already correctly uppercased, .upper() is a no-op on them. The Turkish
# on-screen keyboard (turkmen_keyboard.dart) covers the full 29-letter Turkish
# alphabet including both İ and I as separate keys, so any correctly-spelled
# native Turkish word works here — no need to avoid any letters.
WORDS = [
    # Hayvanlar (Animals)
    ("ASLAN", "Ormanlar kralı olarak bilinen büyük kedi", "easy"),
    ("KAPLAN", "Turuncu-siyah çizgili büyük kedi", "easy"),
    ("FİL", "Hortumu olan kara hayvanlarının en büyüğü", "easy"),
    ("ZÜRAFA", "Boynu çok uzun olan hayvan", "easy"),
    ("YUNUS", "Zeki ve oyuncu bir deniz memelisi", "easy"),
    ("PENGUEN", "Uçamayan, soğuk bölgelerde yaşayan kuş", "easy"),
    ("KANGURU", "Zıplayarak hareket eden, yavrusunu kesesinde taşıyan hayvan", "medium"),
    ("ÇİTA", "Karada yaşayan en hızlı hayvan", "medium"),
    ("AHTAPOT", "Sekiz kollu deniz canlısı", "medium"),
    ("FLAMİNGO", "Tek ayak üzerinde duran pembe kuş", "medium"),
    ("TİMSAH", "Nehirlerde yaşayan büyük sürüngen", "medium"),
    ("SİNCAP", "Kuyruğu tüylü, fındık saklayan hayvan", "medium"),
    ("KELEBEK", "Tırtıldan dönüşen renkli kanatlı böcek", "easy"),
    ("KİRPİ", "Sırtı dikenlerle kaplı küçük memeli", "medium"),
    ("RAKUN", "Gözlerinin etrafında maske gibi lekeleri olan gece hayvanı", "medium"),
    # Doğa ve coğrafya (Nature & geography)
    ("DAĞ", "Tepeden çok daha yüksek yeryüzü şekli", "easy"),
    ("YANARDAĞ", "Lav püskürtebilen dağ", "medium"),
    ("ŞELALE", "Yüksekten dökülen su", "easy"),
    ("ÇÖL", "Yağışın çok az olduğu kurak bölge", "easy"),
    ("BUZUL", "Yavaşça hareket eden dev buz kütlesi", "medium"),
    ("GÖKKUŞAĞI", "Yağmurdan sonra gökyüzünde görülen renkli yay", "easy"),
    ("ŞİMŞEK", "Fırtınada gökyüzünde parlayan ışık", "easy"),
    ("KASIRGA", "Güçlü ve dönerek ilerleyen tropik fırtına", "medium"),
    ("ÇIĞ", "Dağdan aniden kayan kar kütlesi", "hard"),
    ("TUTULMA", "Ayın güneşi örttüğü gökyüzü olayı", "medium"),
    ("TSUNAMİ", "Deprem sonucu oluşan dev dalga", "medium"),
    ("KANYON", "Nehrin oyduğu derin vadi", "medium"),
    ("ADA", "Etrafı tamamen suyla çevrili kara parçası", "easy"),
    ("ORMAN", "Çoğunlukla ağaçlarla kaplı geniş alan", "easy"),
    ("VAHA", "Çölün ortasındaki yeşil ve sulu alan", "medium"),
    ("EVEREST", "Dünyanın en yüksek dağı", "medium"),
    ("AMAZON", "Dünyanın en büyük yağmur ormanı", "medium"),
    ("SAHRA", "Dünyanın en büyük sıcak çölü", "medium"),
    ("GALAKSİ", "Yıldızların oluşturduğu dev topluluk, örneğin Samanyolu", "medium"),
    ("KUTUP", "Dünyanın en kuzeyi veya en güneyi", "medium"),
    # Başkentler ve simgeler (Capitals & landmarks)
    ("PARİS", "Eyfel Kulesi'nin bulunduğu şehir", "easy"),
    ("LONDRA", "İngiltere'nin başkenti", "easy"),
    ("TOKYO", "Japonya'nın başkenti", "easy"),
    ("KAHİRE", "Piramitlere yakın olan Mısır'ın başkenti", "medium"),
    ("MOSKOVA", "Rusya'nın başkenti", "easy"),
    ("BERLİN", "Almanya'nın başkenti", "easy"),
    ("PİRAMİT", "Mısır'daki üçgen şeklinde antik anıt", "easy"),
    ("KOLEZYUM", "Roma'daki antik gladyatör arenası", "hard"),
    ("STONEHENGE", "İngiltere'de gizemli taş çember", "hard"),
    ("AKROPOL", "Atina'daki antik tepe kalesi", "hard"),
    ("NİYAGARA", "ABD ile Kanada arasındaki ünlü şelale", "medium"),
    ("SFENKS", "Aslan gövdeli, insan başlı heykel", "medium"),
    ("VATİKAN", "Dünyanın en küçük ülkesi", "medium"),
    ("GRÖNLAND", "Dünyanın en büyük adası", "medium"),
    ("İSTANBUL", "Hem Avrupa'da hem Asya'da yer alan tek şehir", "easy"),
    # Yiyecek (Food)
    ("MAKARNA", "İtalyan mutfağından uzun ince hamur yemeği", "easy"),
    ("KRUVASAN", "Hilal şeklinde, katmanlı hamur işi", "medium"),
    ("KREP", "Şurupla servis edilen ince kahvaltılık", "easy"),
    ("AVOKADO", "Guacamole yapımında kullanılan yeşil meyve", "easy"),
    ("ANANAS", "Dikenli kabuklu tropik meyve", "easy"),
    ("ÇİKOLATA", "Kakaodan yapılan tatlı", "easy"),
    ("SANDVİÇ", "İki dilim ekmek arasına konan yiyecek", "easy"),
    ("BAKLAVA", "Cevizli, ballı, katmanlı Türk tatlısı", "easy"),
    ("LAHMACUN", "İnce hamur üzerine kıymalı harç konan Türk yemeği", "easy"),
    ("SİMİT", "Susamlı, halka şeklinde Türk unlu mamulü", "easy"),
    ("KARAMEL", "Eritilmiş şekerden yapılan yumuşak şekerleme", "medium"),
    ("TARÇIN", "Ağaç kabuğundan elde edilen sıcak baharat", "medium"),
    ("KOMPOSTO", "Meyvelerin şekerli suda kaynatılmasıyla yapılan içecek", "medium"),
    ("BROKOLİ", "Küçük ağaçlara benzeyen yeşil sebze", "easy"),
    ("MISIR", "Patlatılınca patlamış mısıra dönüşen tahıl", "easy"),
    # Teknoloji (Technology)
    ("İNTERNET", "Bilgisayarları birbirine bağlayan küresel ağ", "easy"),
    ("TELEFON", "Sesli görüşme ve internet için kullanılan cep cihazı", "easy"),
    ("KLAVYE", "Bilgisayarda yazı yazmak için kullanılan cihaz", "easy"),
    ("ŞİFRE", "Bir hesaba giriş için kullanılan gizli kod", "easy"),
    ("ROBOT", "Görevleri kendi başına yapabilen makine", "easy"),
    ("UYDU", "Dünya'nın yörüngesinde dönen ve sinyal ileten nesne", "medium"),
    ("ALGORİTMA", "Bir bilgisayarın bir sorunu çözmek için izlediği adımlar dizisi", "hard"),
    ("YAZILIM", "Bilgisayarda çalışan programların genel adı", "medium"),
    ("TARAYICI", "İnternet sitelerini görüntülemek için kullanılan program", "medium"),
    ("PODCAST", "İnternetten dinlenebilen bölümlü ses programı", "medium"),
    ("UYGULAMA", "Telefona indirilen program", "medium"),
    ("BLUETOOTH", "Yakın cihazları kablosuz bağlayan teknoloji", "medium"),
    ("KORSAN", "Bilgisayar sistemlerine izinsiz giren kişi", "medium"),
    ("SUNUCU", "Ağdaki diğer cihazlara hizmet veren bilgisayar", "medium"),
    ("KULLANICI", "Bir sisteme giriş yaparken kullanılan hesap sahibi", "easy"),
    # Bilim ve uzay (Science & space)
    ("YERÇEKİMİ", "Cisimleri yere doğru çeken kuvvet", "medium"),
    ("OKSİJEN", "İnsanın nefes alması için gereken gaz", "easy"),
    ("MOLEKÜL", "Bir bileşiğin en küçük birimi", "medium"),
    ("BAKTERİ", "Tek hücreli çok küçük canlı", "medium"),
    ("AŞI", "Hastalıktan koruyan iğne", "easy"),
    ("ASTEROİT", "Güneşin etrafında dönen kayalık gök cismi", "medium"),
    ("DİNOZOR", "Milyonlarca yıl önce yaşamış, nesli tükenmiş sürüngen", "easy"),
    ("İSKELET", "Vücudu ayakta tutan kemikler", "easy"),
    ("MIKNATIS", "Demiri çeken cisim", "easy"),
    ("TELESKOP", "Uzak yıldızları gözlemlemek için kullanılan alet", "medium"),
    ("ASTRONOT", "Uzaya gitmek üzere eğitilen kişi", "easy"),
    ("ROKET", "Uzaya fırlatılan araç", "easy"),
    ("YILDIZ", "Gece gökyüzünde parlayan gök cismi", "easy"),
    ("GEZEGEN", "Bir yıldızın etrafında dönen büyük gök cismi", "easy"),
    ("ATMOSFER", "Bir gezegeni saran gaz katmanı", "medium"),
    # Günlük eşyalar (Everyday objects)
    ("ŞEMSİYE", "Yağmurdan korunmak için kullanılır", "easy"),
    ("ÇANTA", "Omuzda veya elde taşınan eşya", "easy"),
    ("AYNA", "Yansımanı gösteren eşya", "easy"),
    ("MUM", "Yanan fitili olan balmumu çubuk", "easy"),
    ("BATTANİYE", "Yatakta seni sıcak tutan örtü", "easy"),
    ("MAKAS", "Kağıt kesmek için kullanılan alet", "easy"),
    ("ZARF", "Mektup göndermek için kullanılan kağıt kılıf", "easy"),
    ("PUSULA", "Kuzeyi gösteren alet", "medium"),
    ("MERDİVEN", "Yüksek yerlere çıkmak için kullanılır", "easy"),
    ("DÜDÜK", "Üflenince keskin ses çıkaran alet", "easy"),
    ("BAVUL", "Seyahatte eşya taşımak için kullanılan çanta", "easy"),
    ("FENER", "Pille çalışan taşınabilir ışık kaynağı", "easy"),
    ("TERMOMETRE", "Vücut veya hava sıcaklığını ölçer", "medium"),
    ("DEFTER", "Not almak için kullanılan sayfalar", "easy"),
    ("CÜZDAN", "Para ve kartların taşındığı küçük eşya", "easy"),
    # Meslekler (Professions)
    ("DOKTOR", "Hasta insanları tedavi eder", "easy"),
    ("ÖĞRETMEN", "Öğrencilerin öğrenmesine yardım eder", "easy"),
    ("İTFAİYECİ", "Yangınları söndürür ve insanları kurtarır", "easy"),
    ("MÜHENDİS", "Yapılar veya makineler tasarlar", "medium"),
    ("TESİSATÇI", "Su borularını ve tesisatı onarır", "medium"),
    ("MİMAR", "Bina tasarlayan kişi", "medium"),
    ("CERRAH", "Ameliyat yapan doktor", "medium"),
    ("PİLOT", "Uçak kullanan kişi", "easy"),
    ("DEDEKTİF", "Suçları araştırıp gizemleri çözen kişi", "medium"),
    ("FOTOĞRAFÇI", "Fotoğraf çekmeyi meslek edinen kişi", "medium"),
    # Spor (Sports)
    ("FUTBOL", "Yuvarlak topla oynanan popüler spor", "easy"),
    ("BASKETBOL", "Topu potaya atarak oynanan spor", "easy"),
    ("MARATON", "Çok uzun mesafeli koşu yarışı", "medium"),
    ("JİMNASTİK", "Denge ve esneklik gerektiren spor", "medium"),
    ("GÜREŞ", "Rakibi yere düşürmeye dayalı spor", "medium"),
    ("OKÇULUK", "Hedefe ok atma sporu", "medium"),
    ("VOLEYBOL", "Topu file üzerinden geçirerek oynanan spor", "easy"),
    ("SATRANÇ", "Şah ve vezirin olduğu strateji oyunu", "easy"),
    ("YÜZME", "Suda hareket etmeyi gerektiren spor", "easy"),
    ("BOKS", "Yumruklarla yapılan dövüş sporu", "easy"),
    # Duygular ve soyut kavramlar (Emotions & abstract)
    ("MERAK", "Bir şeyi öğrenmek için duyulan güçlü istek", "medium"),
    ("KISKANÇLIK", "Başkasında olanı isteme duygusu", "medium"),
    ("MİNNETTARLIK", "Teşekkür duygusu", "medium"),
    ("CESARET", "Korkuya rağmen gösterilen yüreklilik", "easy"),
    ("SABIR", "Sakin bir şekilde bekleyebilme yeteneği", "medium"),
    ("DOSTLUK", "Yakın arkadaşlar arasındaki bağ", "easy"),
    ("ÖZGÜRLÜK", "İstediğin gibi davranma ve düşünme hakkı", "easy"),
    ("MUTLULUK", "Sevinç ve huzur duygusu", "easy"),
    ("SADAKAT", "Bağlılık ve güvenilirlik", "medium"),
    ("UYUM", "Barış içinde birlik hali", "medium"),
    # Çeşitli / kültür (Misc / culture)
    ("SAZ", "Türk halk müziğinde çalınan telli çalgı", "medium"),
    ("DAVUL", "Vurularak çalınan büyük Türk çalgısı", "easy"),
    ("HALI", "Yerlere serilen dokuma örtü", "easy"),
    ("ÇİNİ", "Osmanlı sanatında kullanılan süslü seramik", "medium"),
    ("TİTANİK", "1912'de batan ünlü gemi", "medium"),
    ("ORKESTRA", "Birlikte çalan büyük müzisyen topluluğu", "medium"),
    ("KARNAVAL", "Kostüm ve eğlence dolu şenlik", "easy"),
    ("SİRK", "Akrobatların ve palyaçoların olduğu gösteri yeri", "easy"),
    ("KÜTÜPHANE", "Kitapların saklandığı ve ödünç verildiği yer", "easy"),
    ("MÜZE", "Sanat ve tarih eserlerinin sergilendiği yer", "easy"),
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
            language='tr',
            defaults={'hint': hint, 'difficulty': difficulty, 'is_active': True},
        )


def unseed_words(apps, schema_editor):
    pass  # intentionally a no-op — don't delete words on rollback


class Migration(migrations.Migration):

    dependencies = [
        ('hangman', '0011_seed_words_ru'),
    ]

    operations = [
        migrations.RunPython(seed_words, reverse_code=unseed_words),
    ]
