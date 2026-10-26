' Historical probe: runs one revision's Purchases.brs implementation without SceneGraph.
sub Main()
    g = { revenueCatSDKConfig: { apiKey: "roku_probe" } }
    GetGlobalAA().isRunningRevenueCatTests = true
    GetGlobalAA().rc_purchasesConfig = { apiKey: "roku_probe" }

    ' allPurchasedProductIds for a customer with one non-subscription purchase
    try
        p = _InternalPurchases({ global: g })
        response = {
            request_date: "2026-10-26T09:00:00Z",
            subscriber: {
                entitlements: {}, first_seen: "2026-10-01T00:00:00Z", last_seen: "2026-10-26T00:00:00Z",
                management_url: invalid, original_app_user_id: "probe", original_application_version: invalid, original_purchase_date: invalid,
                non_subscriptions: { "lifetime_pro": [{ purchase_date: "2026-10-02T00:00:00Z", original_purchase_date: "2026-10-02T00:00:00Z", id: "a", store_transaction_id: "b", store: "roku", is_sandbox: true }] },
                other_purchases: {}, subscriptions: {}
            }
        }
        s = p.buildSubscriber(response)
        ids = []
        for each id in s.allPurchasedProductIds
            if type(id) = "roString" or type(id) = "String" then ids.push(id) else ids.push("<" + type(id) + ">")
        end for
        print "PROBE nonsub allPurchasedProductIds=" + FormatJson(ids)
    catch e
        print "PROBE nonsub exception=" + e.message
    end try

    ' setLogLevel after configure (Purchases().setLogLevel calls configuration.set({ logLevel }))
    try
        conf = _InternalPurchases_Configuration({ global: g, log: { error: sub(x) : end sub } })
        conf.configure({ apiKey: "roku_probe" })
        before = conf.isConfigured()
        conf.set({ logLevel: "debug" })
        print "PROBE config configuredBefore=" + before.ToStr() + " configuredAfterSetLogLevel=" + conf.isConfigured().ToStr()
    catch e
        print "PROBE config exception=" + e.message
    end try

    ' getCustomerInfo when the connection is refused
    try
        g.revenueCatSDKConfig = { apiKey: "roku_probe", proxyUrl: "http://127.0.0.1:9/" }
        GetGlobalAA().rc_purchasesConfig = { apiKey: "roku_probe", proxyUrl: "http://127.0.0.1:9/" }
        p = _InternalPurchases({ global: g })
        result = p.getCustomerInfo({})
        if result = invalid then
            print "PROBE network result=invalid"
        else
            print "PROBE network error=" + FormatJson(result.error) + " dataType=" + type(result.data)
        end if
    catch e
        print "PROBE network exception=" + e.message
    end try
end sub
