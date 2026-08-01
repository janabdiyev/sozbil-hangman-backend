from django.db import migrations

# First-pass English word pool (Can: "AI draft + your review" — treat this as a
# draft to be reviewed/edited via Django admin, not final copy). Mirrors the shape
# of the Turkmen pool in 0004_seed_words.py (word, hint, difficulty) but is an
# independently-curated list rather than a translation — words are chosen to be
# broadly recognizable English vocabulary, good hangman length/letter variety.
WORDS = [
    # Animals
    ("LION", "King of the savanna", "easy"),
    ("TIGER", "Big cat with orange and black stripes", "easy"),
    ("ELEPHANT", "Largest land animal, has a trunk", "easy"),
    ("GIRAFFE", "Tallest animal, with a very long neck", "easy"),
    ("DOLPHIN", "Smart, playful sea mammal", "easy"),
    ("PENGUIN", "Flightless bird that lives in cold climates", "easy"),
    ("KANGAROO", "Hops around and carries its baby in a pouch", "medium"),
    ("CHEETAH", "Fastest land animal", "medium"),
    ("OCTOPUS", "Sea creature with eight arms", "medium"),
    ("FLAMINGO", "Pink wading bird that stands on one leg", "medium"),
    ("HEDGEHOG", "Small mammal covered in spines", "medium"),
    ("CHAMELEON", "Lizard famous for changing color", "hard"),
    ("CROCODILE", "Large reptile that lurks in rivers", "medium"),
    ("SQUIRREL", "Bushy-tailed animal that hides nuts", "medium"),
    ("BUTTERFLY", "Insect that starts life as a caterpillar", "easy"),
    ("PEACOCK", "Bird famous for its colorful tail feathers", "medium"),
    ("RACCOON", "Masked nocturnal animal that raids trash cans", "medium"),
    ("ANTELOPE", "Fast-running horned grazing animal", "hard"),
    ("JELLYFISH", "Sea creature with stinging tentacles", "medium"),
    ("SEAHORSE", "Tiny fish shaped like a chess piece", "medium"),
    # Nature & geography
    ("MOUNTAIN", "Very tall landform, higher than a hill", "easy"),
    ("VOLCANO", "Mountain that can erupt with lava", "medium"),
    ("WATERFALL", "Water falling from a high cliff", "easy"),
    ("DESERT", "Dry, sandy region with very little rainfall", "easy"),
    ("GLACIER", "Huge, slow-moving mass of ice", "medium"),
    ("RAINBOW", "Colorful arc that appears after rain", "easy"),
    ("THUNDER", "Loud sound that follows lightning", "easy"),
    ("HURRICANE", "Powerful, spinning tropical storm", "medium"),
    ("AVALANCHE", "Sudden fall of snow down a mountainside", "hard"),
    ("ECLIPSE", "When the moon blocks the sun", "medium"),
    ("TSUNAMI", "Giant wave caused by an earthquake", "medium"),
    ("CANYON", "Deep valley carved out by a river", "medium"),
    ("ISLAND", "Land completely surrounded by water", "easy"),
    ("FOREST", "Large area covered mostly with trees", "easy"),
    ("OASIS", "Green, fertile spot in the middle of a desert", "medium"),
    ("SAHARA", "World's largest hot desert", "medium"),
    ("AMAZON", "World's largest rainforest", "medium"),
    ("EVEREST", "Tallest mountain on Earth", "medium"),
    ("ANTARCTICA", "Frozen continent at the South Pole", "medium"),
    ("GALAXY", "Huge collection of stars, like the Milky Way", "medium"),
    # Capitals & landmarks
    ("PARIS", "City with the Eiffel Tower", "easy"),
    ("LONDON", "Capital of England, home to Big Ben", "easy"),
    ("TOKYO", "Capital of Japan", "easy"),
    ("CAIRO", "Capital of Egypt, near the pyramids", "medium"),
    ("MOSCOW", "Capital of Russia", "easy"),
    ("BERLIN", "Capital of Germany", "easy"),
    ("OTTAWA", "Capital of Canada", "medium"),
    ("PYRAMID", "Ancient triangular stone monument in Egypt", "easy"),
    ("COLOSSEUM", "Ancient Roman arena for gladiators", "hard"),
    ("STONEHENGE", "Mysterious circle of standing stones in England", "hard"),
    ("ACROPOLIS", "Ancient hilltop citadel in Athens", "hard"),
    ("NIAGARA", "Famous waterfall between the US and Canada", "medium"),
    ("SPHINX", "Statue with a lion's body and a human head", "medium"),
    ("VATICAN", "Smallest country in the world", "medium"),
    ("GREENLAND", "World's largest island", "medium"),
    # Food & drink
    ("SPAGHETTI", "Long, thin Italian pasta", "easy"),
    ("CROISSANT", "Buttery, flaky crescent-shaped pastry", "medium"),
    ("PANCAKE", "Flat breakfast food served with syrup", "easy"),
    ("AVOCADO", "Green fruit used to make guacamole", "easy"),
    ("PINEAPPLE", "Spiky tropical fruit", "easy"),
    ("CHOCOLATE", "Sweet treat made from cacao", "easy"),
    ("SANDWICH", "Filling placed between two slices of bread", "easy"),
    ("BURRITO", "Mexican dish wrapped in a tortilla", "easy"),
    ("LASAGNA", "Layered Italian pasta dish", "medium"),
    ("PRETZEL", "Salty, twisted baked snack", "medium"),
    ("CARAMEL", "Chewy candy made from melted sugar", "medium"),
    ("CINNAMON", "Warm spice made from tree bark", "medium"),
    ("BROCCOLI", "Green vegetable that looks like tiny trees", "easy"),
    ("SMOOTHIE", "Blended drink made from fruit", "easy"),
    ("POPCORN", "Snack made from exploded corn kernels", "easy"),
    # Technology & internet
    ("INTERNET", "Global network connecting computers", "easy"),
    ("SMARTPHONE", "Pocket device for calls, apps, and the internet", "easy"),
    ("BLUETOOTH", "Wireless technology for connecting nearby devices", "medium"),
    ("ALGORITHM", "Set of steps a computer follows to solve a problem", "hard"),
    ("KEYBOARD", "Device used to type on a computer", "easy"),
    ("SATELLITE", "Object orbiting Earth that relays signals", "medium"),
    ("HOLOGRAM", "Three-dimensional image made of light", "medium"),
    ("ROBOT", "Machine that can perform tasks automatically", "easy"),
    ("PASSWORD", "Secret code used to log in", "easy"),
    ("YOUTUBE", "Popular video-sharing platform", "easy"),
    ("PODCAST", "Episodic audio show you can stream", "medium"),
    ("SOFTWARE", "Programs that run on a computer", "medium"),
    ("FIREWALL", "Security barrier that blocks unwanted network traffic", "medium"),
    ("CHATBOT", "Program that chats with users like a person", "medium"),
    ("USERNAME", "Name you choose to log in with", "easy"),
    # Science & space
    ("GRAVITY", "Force that pulls objects toward the earth", "easy"),
    ("OXYGEN", "Gas humans need to breathe", "easy"),
    ("MOLECULE", "Smallest unit of a chemical compound", "medium"),
    ("BACTERIA", "Tiny single-celled organisms", "medium"),
    ("VACCINE", "Shot that protects against a disease", "easy"),
    ("ASTEROID", "Rocky object that orbits the sun", "medium"),
    ("DINOSAUR", "Ancient reptile that went extinct", "easy"),
    ("SKELETON", "The bones that support your body", "easy"),
    ("MAGNET", "Object that attracts iron and steel", "easy"),
    ("TELESCOPE", "Instrument used to view distant stars", "medium"),
    ("ASTRONAUT", "Person trained to travel into space", "easy"),
    ("ROCKET", "Vehicle that launches into space", "easy"),
    ("COMET", "Icy space object with a glowing tail", "medium"),
    ("PLANET", "Large body that orbits a star", "easy"),
    ("ATMOSPHERE", "Layer of gases surrounding a planet", "medium"),
    # Everyday objects
    ("UMBRELLA", "Keeps you dry in the rain", "easy"),
    ("BACKPACK", "Bag carried on your shoulders", "easy"),
    ("MIRROR", "Shows your reflection", "easy"),
    ("CANDLE", "Wax stick with a burning wick", "easy"),
    ("BLANKET", "Keeps you warm in bed", "easy"),
    ("SCISSORS", "Tool used for cutting paper", "easy"),
    ("ENVELOPE", "Paper cover for mailing a letter", "easy"),
    ("COMPASS", "Tool that always points north", "medium"),
    ("LADDER", "Used to climb up to high places", "easy"),
    ("WHISTLE", "Makes a sharp sound when you blow it", "easy"),
    ("SUITCASE", "Bag used for packing clothes when traveling", "easy"),
    ("FLASHLIGHT", "Portable light powered by batteries", "easy"),
    ("THERMOMETER", "Measures body or air temperature", "medium"),
    ("NOTEBOOK", "Bound pages used for writing notes", "easy"),
    ("WALLET", "Small case for carrying money and cards", "easy"),
    # Professions
    ("DOCTOR", "Treats sick people", "easy"),
    ("TEACHER", "Helps students learn", "easy"),
    ("FIREFIGHTER", "Puts out fires and rescues people", "easy"),
    ("ENGINEER", "Designs and builds structures or machines", "medium"),
    ("PLUMBER", "Fixes pipes and leaks", "medium"),
    ("ARCHITECT", "Designs buildings", "medium"),
    ("SURGEON", "Doctor who performs operations", "medium"),
    ("PILOT", "Flies an airplane", "easy"),
    ("DETECTIVE", "Investigates crimes and solves mysteries", "medium"),
    ("PHOTOGRAPHER", "Takes pictures for a living", "medium"),
    # Sports & games
    ("FOOTBALL", "Popular sport played with a round or oval ball", "easy"),
    ("BASKETBALL", "Sport where you shoot a ball through a hoop", "easy"),
    ("MARATHON", "Long-distance running race", "medium"),
    ("GYMNASTICS", "Sport involving flips, balance, and flexibility", "medium"),
    ("WRESTLING", "Combat sport of grappling opponents", "medium"),
    ("ARCHERY", "Sport of shooting arrows at a target", "medium"),
    ("SNOWBOARD", "Board used to slide down snowy slopes", "medium"),
    ("VOLLEYBALL", "Sport played by hitting a ball over a net", "easy"),
    ("CHESS", "Strategy board game with a king and queen", "easy"),
    ("PUZZLE", "Game where pieces fit together to form a picture", "easy"),
    # Emotions & abstract
    ("CURIOSITY", "Strong desire to learn or know something", "medium"),
    ("JEALOUSY", "Feeling envious of someone else", "medium"),
    ("GRATITUDE", "Feeling thankful", "medium"),
    ("COURAGE", "Bravery in the face of fear", "easy"),
    ("PATIENCE", "Ability to wait calmly", "medium"),
    ("HARMONY", "State of peaceful agreement", "medium"),
    ("FRIENDSHIP", "Bond between close companions", "easy"),
    ("FREEDOM", "Being free to act or think as you choose", "easy"),
    ("HAPPINESS", "Feeling of joy and contentment", "easy"),
    ("LOYALTY", "Being faithful and devoted", "medium"),
    # Pop culture & misc
    ("AVATAR", "Blue-skinned characters from a famous sci-fi movie", "medium"),
    ("TITANIC", "Famous ship that sank in 1912", "medium"),
    ("SUPERMAN", "Superhero who can fly and has super strength", "easy"),
    ("ORCHESTRA", "Large group of musicians playing together", "medium"),
    ("CARNIVAL", "Festive event with rides, games, and costumes", "easy"),
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
            language='en',
            defaults={'hint': hint, 'difficulty': difficulty, 'is_active': True},
        )


def unseed_words(apps, schema_editor):
    pass  # intentionally a no-op — don't delete words on rollback


class Migration(migrations.Migration):

    dependencies = [
        ('hangman', '0009_hangmanword_language'),
    ]

    operations = [
        migrations.RunPython(seed_words, reverse_code=unseed_words),
    ]
