package com.sozbil.app

import retrofit2.Call
import retrofit2.http.GET

interface ApiService {
    @GET("api/word/")
    fun getRandomWord(): Call<HangmanWord>
    
    companion object {
        const val BASE_URL = "https://sozbil-hangman-backend.onrender.com/"
    }
}