package com.sozbil.app

import android.app.Activity
import android.util.Log
import com.android.billingclient.api.*

class BillingManager(
    private val activity: Activity,
    private val onSubscriptionStatusChanged: (Boolean) -> Unit
) {
    private var billingClient: BillingClient? = null
    private var isSubscribed = false

    companion object {
        private const val TAG = "BillingManager"
        const val MONTHLY_SUB_ID = "sozbil-monthly"
        const val YEARLY_SUB_ID = "sozbil-yearly"
    }

    fun initialize() {
        billingClient = BillingClient.newBuilder(activity)
            .setListener { billingResult, purchases ->
                if (billingResult.responseCode == BillingClient.BillingResponseCode.OK && purchases != null) {
                    handlePurchases(purchases)
                }
            }
            .enablePendingPurchases()
            .build()

        billingClient?.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(billingResult: BillingResult) {
                if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                    Log.d(TAG, "Billing setup finished")
                    checkSubscriptionStatus()
                }
            }

            override fun onBillingServiceDisconnected() {
                Log.d(TAG, "Billing service disconnected")
            }
        })
    }

    fun checkSubscriptionStatus() {
        billingClient?.queryPurchasesAsync(
            QueryPurchasesParams.newBuilder()
                .setProductType(BillingClient.ProductType.SUBS)
                .build()
        ) { billingResult, purchases ->
            if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                val hasActiveSubscription = purchases.any { purchase ->
                    (purchase.products.contains(MONTHLY_SUB_ID) || purchase.products.contains(YEARLY_SUB_ID)) &&
                    purchase.purchaseState == Purchase.PurchaseState.PURCHASED
                }
                isSubscribed = hasActiveSubscription
                onSubscriptionStatusChanged(isSubscribed)
                Log.d(TAG, "Subscription status: $isSubscribed")
            }
        }
    }

    fun launchSubscriptionFlow(productId: String) {
        val productList = listOf(
            QueryProductDetailsParams.Product.newBuilder()
                .setProductId(productId)
                .setProductType(BillingClient.ProductType.SUBS)
                .build()
        )

        billingClient?.queryProductDetailsAsync(
            QueryProductDetailsParams.newBuilder()
                .setProductList(productList)
                .build()
        ) { billingResult, productDetailsList ->
            if (billingResult.responseCode == BillingClient.BillingResponseCode.OK && productDetailsList.isNotEmpty()) {
                val productDetails = productDetailsList[0]
                val offerToken = productDetails.subscriptionOfferDetails?.get(0)?.offerToken

                if (offerToken != null) {
                    val productDetailsParamsList = listOf(
                        BillingFlowParams.ProductDetailsParams.newBuilder()
                            .setProductDetails(productDetails)
                            .setOfferToken(offerToken)
                            .build()
                    )

                    val billingFlowParams = BillingFlowParams.newBuilder()
                        .setProductDetailsParamsList(productDetailsParamsList)
                        .build()

                    billingClient?.launchBillingFlow(activity, billingFlowParams)
                }
            }
        }
    }

    private fun handlePurchases(purchases: List<Purchase>) {
        for (purchase in purchases) {
            if (purchase.purchaseState == Purchase.PurchaseState.PURCHASED) {
                if (!purchase.isAcknowledged) {
                    acknowledgePurchase(purchase)
                }
                isSubscribed = true
                onSubscriptionStatusChanged(true)
            }
        }
    }

    private fun acknowledgePurchase(purchase: Purchase) {
        val acknowledgePurchaseParams = AcknowledgePurchaseParams.newBuilder()
            .setPurchaseToken(purchase.purchaseToken)
            .build()

        billingClient?.acknowledgePurchase(acknowledgePurchaseParams) { billingResult ->
            if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                Log.d(TAG, "Purchase acknowledged")
            }
        }
    }

    fun isUserSubscribed(): Boolean = isSubscribed

    fun endConnection() {
        billingClient?.endConnection()
    }
}
