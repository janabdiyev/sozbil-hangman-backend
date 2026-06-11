package com.sozbil.app

import android.app.AlertDialog
import android.os.Bundle
import android.util.Log
import android.view.SoundEffectConstants
import android.view.View
import android.view.ViewGroup
import android.view.animation.OvershootInterpolator
import android.widget.Button
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.core.view.ViewCompat
import androidx.gridlayout.widget.GridLayout
import com.google.android.gms.ads.AdListener
import com.google.android.gms.ads.AdRequest
import com.google.android.gms.ads.AdView
import com.google.android.gms.ads.LoadAdError
import com.google.android.gms.ads.MobileAds
import com.google.android.gms.ads.rewarded.RewardedAd
import com.google.android.gms.ads.rewarded.RewardedAdLoadCallback
import retrofit2.Call
import retrofit2.Callback
import retrofit2.Response
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.util.Calendar

class MainActivity : AppCompatActivity() {

    private lateinit var hangmanView: HangmanView
    private lateinit var wordDisplay: TextView
    private lateinit var hintText: TextView
    private lateinit var attemptsText: TextView
    private lateinit var playAgainButton: Button
    private lateinit var gameOverText: TextView
    private lateinit var bannerAd: AdView
    private lateinit var gamesRemainingText: TextView

    private var currentWord: HangmanWord? = null
    private val guessedLetters = mutableSetOf<Char>()
    private var wrongGuesses = 0
    private val maxWrongGuesses = 6
    private var gameOver = false

    private var rewardedAd: RewardedAd? = null
    private lateinit var billingManager: BillingManager

    // Game limits
    private val dailyGamesLimit = 5
    private val rewardAdGames = 3
    private val maxRewardAds = 5

    private val prefs by lazy { getSharedPreferences("hangman_prefs", MODE_PRIVATE) }
    private val usedWordsKey = "used_words"
    private val maxRetry = 40

    private val apiService: ApiService by lazy {
        Retrofit.Builder()
            .baseUrl(ApiService.BASE_URL)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
            .create(ApiService::class.java)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        MobileAds.initialize(this)

        hangmanView = findViewById(R.id.hangmanView)
        wordDisplay = findViewById(R.id.wordDisplay)
        hintText = findViewById(R.id.hintText)
        attemptsText = findViewById(R.id.attemptsText)
        playAgainButton = findViewById(R.id.playAgainButton)
        gameOverText = findViewById(R.id.gameOverText)
        bannerAd = findViewById(R.id.bannerAd)
        gamesRemainingText = findViewById(R.id.gamesRemainingText)

        setupKeyboard()

        playAgainButton.setOnClickListener { loadNewWord() }

        // Billing init
        billingManager = BillingManager(this) { isSubscribed ->
            updateUIForSubscription(isSubscribed)
        }
        billingManager.initialize()

        checkAndResetDailyGames()
        updateGamesDisplay()
        loadBannerAd()
        loadNewWord()
        loadRewardedAd()
    }

    // ------------------------------
    // DAILY LIMITS
    // ------------------------------
    private fun checkAndResetDailyGames() {
        val today = getCurrentDayString()
        val lastPlayDate = prefs.getString("last_play_date", "")

        if (lastPlayDate != today) {
            prefs.edit()
                .putInt("daily_games_played", 0)
                .putInt("reward_ads_watched", 0)
                .putInt("reward_games_remaining", 0)
                .putString("last_play_date", today)
                .apply()
        }
    }

    private fun getCurrentDayString(): String {
        val calendar = Calendar.getInstance()
        return "${calendar.get(Calendar.YEAR)}-${calendar.get(Calendar.DAY_OF_YEAR)}"
    }

    private fun getRemainingGames(): Int {
        if (billingManager.isUserSubscribed()) return Int.MAX_VALUE

        val dailyPlayed = prefs.getInt("daily_games_played", 0)
        val rewardGames = prefs.getInt("reward_games_remaining", 0)
        val dailyRemaining = (dailyGamesLimit - dailyPlayed).coerceAtLeast(0)

        return dailyRemaining + rewardGames
    }

    private fun canPlayGame(): Boolean = getRemainingGames() > 0

    private fun consumeGame() {
        if (billingManager.isUserSubscribed()) return

        val rewardGames = prefs.getInt("reward_games_remaining", 0)
        if (rewardGames > 0) {
            prefs.edit().putInt("reward_games_remaining", rewardGames - 1).apply()
        } else {
            val dailyPlayed = prefs.getInt("daily_games_played", 0)
            prefs.edit().putInt("daily_games_played", dailyPlayed + 1).apply()
        }

        updateGamesDisplay()
    }

    private fun updateGamesDisplay() {
        val remaining = getRemainingGames()

        if (billingManager.isUserSubscribed()) {
            gamesRemainingText.text = "🌟 Çäksiz oýun"
            gamesRemainingText.setTextColor(
                ContextCompat.getColor(this, android.R.color.holo_green_dark)
            )
        } else {
            gamesRemainingText.text = "Oýun galdy: $remaining"
            gamesRemainingText.setTextColor(
                if (remaining > 0) ContextCompat.getColor(this, android.R.color.black)
                else ContextCompat.getColor(this, android.R.color.holo_red_dark)
            )
        }
    }

    private fun updateUIForSubscription(isSubscribed: Boolean) {
        if (isSubscribed) {
            bannerAd.visibility = View.GONE
        } else {
            if (gameOver) bannerAd.visibility = View.VISIBLE
        }
        updateGamesDisplay()
    }

    // ------------------------------
    // SUBSCRIPTION + REWARD AD FLOW
    // ------------------------------
    private fun showSubscriptionDialog() {
        val rewardAdsWatched = prefs.getInt("reward_ads_watched", 0)
        val canWatchRewardAd = rewardAdsWatched < maxRewardAds && rewardedAd != null

        val message = buildString {
            append("Oýunlar gutardy!\n\n")
            if (canWatchRewardAd) {
                append("🎬 Reklama gör we +$rewardAdGames oýun al\n")
                append("   (${maxRewardAds - rewardAdsWatched} Reklama galdy)\n\n")
            }
            append("🌟 Premium satyn alyň:\n")
            append("• Çäksiz oýunlar\n")
            append("• Reklamasyz\n\n")
            append("Aýlyk: \$1.99\n")
            append("Ýyllyk: \$7.99 (60% arzanladyş)")
        }

        AlertDialog.Builder(this)
            .setTitle("Oýun haky gutardy")
            .setMessage(message)
            .setCancelable(false)
            .apply {
                if (canWatchRewardAd) {
                    setPositiveButton("Reklama gör") { _, _ ->
                        showRewardedAdForGames()
                    }
                    setNeutralButton("Aýlyk (\$1.99)") { _, _ ->
                        billingManager.launchSubscriptionFlow(BillingManager.MONTHLY_SUB_ID)
                    }
                    setNegativeButton("Ýyllyk (\$7.99)") { _, _ ->
                        billingManager.launchSubscriptionFlow(BillingManager.YEARLY_SUB_ID)
                    }
                } else {
                    setPositiveButton("Aýlyk (\$1.99)") { _, _ ->
                        billingManager.launchSubscriptionFlow(BillingManager.MONTHLY_SUB_ID)
                    }
                    setNegativeButton("Ýyllyk (\$7.99)") { _, _ ->
                        billingManager.launchSubscriptionFlow(BillingManager.YEARLY_SUB_ID)
                    }
                }
            }
            .show()
    }

    private fun showRewardedAdForGames() {
        if (rewardedAd != null) {
            rewardedAd?.show(this) { _ ->
                val rewardAdsWatched = prefs.getInt("reward_ads_watched", 0)
                val rewardGames = prefs.getInt("reward_games_remaining", 0)

                prefs.edit()
                    .putInt("reward_ads_watched", rewardAdsWatched + 1)
                    .putInt("reward_games_remaining", rewardGames + rewardAdGames)
                    .apply()

                updateGamesDisplay()
                Toast.makeText(this, "+$rewardAdGames oýun goşuldy!", Toast.LENGTH_SHORT).show()
                loadRewardedAd()
            }
        }
    }

    // ------------------------------
    // KEYBOARD (CENTERED WITHOUT SPACERS)
    // IMPORTANT: GridLayout must have android:columnCount="10" in XML!
    // ------------------------------
    private fun setupKeyboard() {
        val keyboard = findViewById<GridLayout>(R.id.keyboard)
        keyboard.removeAllViews()

        val rows = listOf(
            "ÄWERTYUIOP",
            "ÖASDFGHJKL",
            "ŇŞZÜÇÝBNMŽ",
            "CV-XQ"
        )

        val maxCols = 10
        keyboard.columnCount = maxCols
        keyboard.alignmentMode = GridLayout.ALIGN_MARGINS

        rows.forEachIndexed { rowIndex, row ->
            val chars = row.toList()
            val startCol = ((maxCols - chars.size) / 2).coerceAtLeast(0)

            chars.forEachIndexed { i, ch ->
                val button = makeKeyButton(ch)

                val params = GridLayout.LayoutParams().apply {
                    width = 0
                    height = GridLayout.LayoutParams.WRAP_CONTENT
                    rowSpec = GridLayout.spec(rowIndex)
                    columnSpec = GridLayout.spec(startCol + i, 1, 1f)
                    setMargins(6, 6, 6, 6)
                }
                button.layoutParams = params

                keyboard.addView(button)
            }
        }
    }

    private fun makeKeyButton(letter: Char): Button {
        return Button(this).apply {
            text = when (letter) {
                '\'' -> "'"
                else -> letter.toString()
            }

            id = View.generateViewId()
            tag = letter

            isAllCaps = true
            textSize = 14f
            setPadding(0, 12, 0, 12)

            setBackgroundResource(R.drawable.key_bg)
            ViewCompat.setElevation(this, 2f)

            setOnClickListener { v ->
                v.playSoundEffect(SoundEffectConstants.CLICK)
                bounce(v)
                guessLetter(letter, this)
            }
        }
    }

    private fun bounce(v: View) {
        v.animate().cancel()
        v.scaleX = 0.96f
        v.scaleY = 0.96f
        v.animate()
            .scaleX(1f)
            .scaleY(1f)
            .setDuration(140)
            .setInterpolator(OvershootInterpolator(1.2f))
            .start()
    }

    // ✅ WIN/LOSE SOUND EFFECTS (BUILT-IN, NO FILES)
    private fun playGameOverSound(won: Boolean) {
        val root = window?.decorView ?: return
        if (won) {
            root.playSoundEffect(SoundEffectConstants.CLICK) // happy-ish
        } else {
            root.playSoundEffect(SoundEffectConstants.NAVIGATION_DOWN) // sad-ish
        }
    }

    private fun showWinAnimation() {
        val parent = findViewById<View>(R.id.hangmanCard) as? ViewGroup ?: return
        if (parent.width <= 0 || parent.height <= 0) return

        val emojis = listOf("🎉", "✨", "🌟", "🎊")

        repeat(8) {
            val emojiView = TextView(this).apply {
                text = emojis.random()
                textSize = 24f
                x = (0..parent.width).random().toFloat()
                y = (0..parent.height).random().toFloat()
                alpha = 0f
            }

            parent.addView(emojiView)

            emojiView.animate()
                .alpha(1f)
                .y(emojiView.y + 100f)
                .rotation(360f)
                .setDuration(800)
                .withEndAction {
                    emojiView.animate()
                        .alpha(0f)
                        .y(emojiView.y + 50f)
                        .setDuration(400)
                        .withEndAction { parent.removeView(emojiView) }
                        .start()
                }
                .start()
        }
    }

    // ------------------------------
    // NO REPEAT WORDS
    // ------------------------------
    private fun getUsedWords(): MutableSet<String> {
        return prefs.getStringSet(usedWordsKey, mutableSetOf())?.toMutableSet() ?: mutableSetOf()
    }

    private fun saveUsedWords(words: Set<String>) {
        prefs.edit().putStringSet(usedWordsKey, words).apply()
    }

    private fun normalizeWord(w: String): String = w.trim().lowercase()

    // ------------------------------
    // GAME FLOW
    // ------------------------------
    private fun loadNewWord() {
        if (!canPlayGame()) {
            showSubscriptionDialog()
            return
        }

        guessedLetters.clear()
        wrongGuesses = 0
        gameOver = false
        hangmanView.wrongGuesses = 0

        wordDisplay.text = "Loading..."
        wordDisplay.setTextColor(ContextCompat.getColor(this, android.R.color.black))
        hintText.text = ""
        gameOverText.visibility = View.GONE
        playAgainButton.visibility = View.GONE

        if (!billingManager.isUserSubscribed()) bannerAd.visibility = View.GONE

        val keyboard = findViewById<GridLayout>(R.id.keyboard)
        for (i in 0 until keyboard.childCount) {
            val child = keyboard.getChildAt(i)
            if (child is Button) {
                child.isEnabled = true
                child.setTextColor(ContextCompat.getColor(this, android.R.color.black))
                child.setBackgroundResource(R.drawable.key_bg)
            }
        }

        fetchNonRepeatedWord()
    }

    private fun fetchNonRepeatedWord(retry: Int = 0) {
        if (retry > maxRetry) {
            saveUsedWords(emptySet())
        }

        val usedWords = getUsedWords()

        apiService.getRandomWord().enqueue(object : Callback<HangmanWord> {
            override fun onResponse(call: Call<HangmanWord>, response: Response<HangmanWord>) {
                if (response.isSuccessful && response.body() != null) {
                    val newWord = response.body()!!
                    val wordKey = normalizeWord(newWord.word)

                    if (usedWords.contains(wordKey)) {
                        fetchNonRepeatedWord(retry + 1)
                        return
                    }

                    usedWords.add(wordKey)
                    saveUsedWords(usedWords)

                    currentWord = newWord
                    consumeGame()
                    updateWordDisplay()
                    hintText.text = "Ýardam: ${currentWord?.hint}"
                    updateAttemptsDisplay()
                } else {
                    Toast.makeText(this@MainActivity, "Failed to load word", Toast.LENGTH_SHORT).show()
                }
            }

            override fun onFailure(call: Call<HangmanWord>, t: Throwable) {
                Toast.makeText(this@MainActivity, "Error: ${t.message}", Toast.LENGTH_SHORT).show()
            }
        })
    }

    private fun guessLetter(letter: Char, button: Button) {
        if (gameOver) return

        guessedLetters.add(letter.uppercaseChar())
        button.isEnabled = false

        val word = currentWord?.word ?: return

        if (!word.contains(letter, ignoreCase = true)) {
            wrongGuesses++
            hangmanView.wrongGuesses = wrongGuesses
            button.setBackgroundResource(R.drawable.key_bg_wrong)
        } else {
            button.setBackgroundResource(R.drawable.key_bg_correct)
        }

        updateWordDisplay()
        updateAttemptsDisplay()
        checkGameOver()
    }

    private fun updateWordDisplay() {
        val word = currentWord?.word ?: return
        val display = word.map { char ->
            when {
                char == ' ' -> "  "
                char == '-' -> "-"
                char == '\'' -> "'"
                guessedLetters.contains(char.uppercaseChar()) || gameOver -> char.toString()
                else -> "_"
            }
        }.joinToString(" ")

        wordDisplay.text = display
    }

    private fun updateAttemptsDisplay() {
        attemptsText.text = "${maxWrongGuesses - wrongGuesses}/$maxWrongGuesses harp galdy"
    }

    private fun checkGameOver() {
        val word = currentWord?.word ?: return

        val won = word.all {
            it == ' ' || it == '-' || it == '\'' || guessedLetters.contains(it.uppercaseChar())
        }
        val lost = wrongGuesses >= maxWrongGuesses

        if (won || lost) {
            gameOver = true

            if (won) {
                gameOverText.text = "🎉 Bildiň!\nBerekella!"
                gameOverText.setTextColor(ContextCompat.getColor(this, android.R.color.holo_green_dark))
                gameOverText.setBackgroundColor(0xDDCCFFDD.toInt())
                wordDisplay.setTextColor(ContextCompat.getColor(this, android.R.color.holo_green_dark))

                playGameOverSound(true)
                showWinAnimation()
            } else {
                gameOverText.text = "☠️ Bilmediň!\n\nSöz: ${word.uppercase()}"
                gameOverText.setTextColor(ContextCompat.getColor(this, android.R.color.holo_red_dark))
                gameOverText.setBackgroundColor(0xDDFFCCCC.toInt())
                wordDisplay.setTextColor(ContextCompat.getColor(this, android.R.color.holo_red_dark))

                playGameOverSound(false)
            }

            gameOverText.visibility = View.VISIBLE
            playAgainButton.visibility = View.VISIBLE

            if (!billingManager.isUserSubscribed()) bannerAd.visibility = View.VISIBLE

            val keyboard = findViewById<GridLayout>(R.id.keyboard)
            for (i in 0 until keyboard.childCount) {
                val child = keyboard.getChildAt(i)
                if (child is Button) child.isEnabled = false
            }
        }
    }

    // ------------------------------
    // ADS
    // ------------------------------
    private fun loadBannerAd() {
        if (billingManager.isUserSubscribed()) return

        // For testing, use Google Test Banner ad unit id:
        // ca-app-pub-3940256099942544/6300978111
        val adRequest = AdRequest.Builder().build()

        bannerAd.adListener = object : AdListener() {
            override fun onAdLoaded() {
                Log.d("ADS", "Banner loaded")
            }

            override fun onAdFailedToLoad(error: LoadAdError) {
                Log.e("ADS", "Banner failed: ${error.message} (${error.code})")
            }
        }

        bannerAd.loadAd(adRequest)
    }

    private fun loadRewardedAd() {
        val adRequest = AdRequest.Builder().build()

        // For testing use Google Test Rewarded ad unit id:
        // ca-app-pub-3940256099942544/5224354917
        RewardedAd.load(
            this,
            "ca-app-pub-7668467791782601/5377390036",
            adRequest,
            object : RewardedAdLoadCallback() {
                override fun onAdLoaded(ad: RewardedAd) {
                    rewardedAd = ad
                    Log.d("ADS", "Rewarded loaded")
                }

                override fun onAdFailedToLoad(error: LoadAdError) {
                    rewardedAd = null
                    Log.e("ADS", "Rewarded failed: ${error.message} (${error.code})")
                }
            }
        )
    }

    override fun onDestroy() {
        super.onDestroy()
        billingManager.endConnection()
    }
}
