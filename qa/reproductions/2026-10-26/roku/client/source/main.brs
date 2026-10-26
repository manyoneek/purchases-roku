' Minimal Roku client for the RevenueCat Roku SDK.
' The SDK normally runs requests in its PurchasesTask; this client uses the SDK's
' synchronous main-thread mode so it can run in the brs-engine simulator.
sub Main(args as dynamic)
    m.launch = {}
    for each key in ["scenario", "apiKey", "userId", "proxyUrl", "sdk"]
        value = invalid
        if args <> invalid then value = args[key]
        if value = invalid then value = ""
        m.launch[key] = value
    end for
    m.screen = CreateObject("roScreen", true, 1280, 720)
    m.port = CreateObject("roMessagePort")
    m.screen.SetMessagePort(m.port)
    fonts = CreateObject("roFontRegistry")
    m.titleFont = fonts.GetDefaultFont(34, true, false)
    m.font = fonts.GetDefaultFont(24, false, false)
    m.smallFont = fonts.GetDefaultFont(20, false, false)
    m.lines = []
    m.statusColor = &h374151FF
    m.title = ""

    GetGlobalAA().isRunningRevenueCatTests = true
    GetGlobalAA().rc_internalTestPurchases = _InternalPurchases()

    scenario = m.launch.scenario
    if scenario = "network" then
        runNetworkFailure()
    else if scenario = "lifetime" then
        runLifetimePurchase()
    else if scenario = "loglevel" then
        runSetLogLevel()
    else
        m.title = "Unknown scenario: " + scenario
        draw()
    end if
    deadline = CreateObject("roTimespan")
    while deadline.TotalSeconds() < 4
        wait(250, m.port)
    end while
end sub

sub draw()
    globalAA = GetGlobalAA()
    screen = globalAA.screen
    screen.Clear(&h101828FF)
    screen.DrawRect(0, 0, 1280, 10, globalAA.statusColor)
    screen.DrawText(globalAA.title, 60, 36, &hFFFFFFFF, globalAA.titleFont)
    screen.DrawText("purchases-roku " + globalAA.launch.sdk + "   |   user " + globalAA.launch.userId, 60, 86, &h9CA3AFFF, globalAA.smallFont)
    y = 140
    for each line in globalAA.lines
        color = &hE5E7EBFF
        if line.Left(7) = "RESULT:" then color = &hFFFFFFFF
        screen.DrawText(line, 60, y, color, globalAA.font)
        y = y + 40
    end for
    screen.SwapBuffers()
end sub

sub addLine(text as string)
    GetGlobalAA().lines.push(text)
    print "[repro] " + text
    draw()
end sub

sub finish(passed as boolean, text as string)
    if passed then
        GetGlobalAA().statusColor = &h16A34AFF
        addLine("RESULT: PASS - " + text)
    else
        GetGlobalAA().statusColor = &hDC2626FF
        addLine("RESULT: FAIL - " + text)
    end if
end sub

sub pause(ms as integer)
    wait(ms, GetGlobalAA().port)
end sub

function describeValue(value as dynamic) as string
    valueType = type(value)
    if valueType = "roString" or valueType = "String" then return Chr(34) + value + Chr(34)
    if valueType = "<uninitialized>" then return "<uninitialized>"
    if value = invalid then return "invalid"
    return valueType
end function

function describeIds(values as object) as string
    parts = []
    for each value in values
        parts.push(describeValue(value))
    end for
    return "[" + parts.Join(", ") + "]"
end function

sub configureSdk()
    launch = GetGlobalAA().launch
    Purchases().configure({ apiKey: launch.apiKey, userId: launch.userId, proxyUrl: launch.proxyUrl })
end sub

sub runNetworkFailure()
    m.title = "getCustomerInfo while the connection fails"
    addLine("1. Purchases().configure({ apiKey, userId, proxyUrl })")
    configureSdk()
    pause(700)
    addLine("2. The connection to RevenueCat drops (endpoint closes every connection)")
    pause(700)
    addLine("3. Purchases().getCustomerInfo(callback)")
    addLine("Expected: callback(invalid, error) with an error code")
    addLine("Waiting for the callback...")
    pause(1000)
    Purchases().getCustomerInfo(sub(subscriber, error)
        addLine("Callback: subscriber=" + describeValue(subscriber) + ", error=" + describeValue(error))
        if error <> invalid then
            addLine("error.code=" + error.code.ToStr() + "  codeName=" + describeValue(error.codeName))
            finish(subscriber = invalid, "the app gets an error it can handle")
        else
            finish(false, "the callback reported success without an error")
        end if
    end sub)
end sub

sub runLifetimePurchase()
    m.title = "allPurchasedProductIds for a lifetime purchase"
    addLine("Customer owns one Test Store non-consumable (bug_reporter_lifetime), no subscriptions")
    addLine("1. Purchases().configure({ apiKey, userId, proxyUrl })")
    configureSdk()
    pause(700)
    addLine("2. Purchases().getCustomerInfo(callback)")
    addLine("Expected: allPurchasedProductIds contains " + Chr(34) + "bug_reporter_lifetime" + Chr(34))
    pause(1000)
    Purchases().getCustomerInfo(sub(subscriber, error)
        if error <> invalid then
            finish(false, "unexpected error " + FormatJson(error))
            return
        end if
        transactionIds = []
        for each transaction in subscriber.nonSubscriptionTransactions
            transactionIds.push(transaction.productIdentifier)
        end for
        addLine("nonSubscriptionTransactions[].productIdentifier = " + describeIds(transactionIds))
        addLine("allPurchasedProductIds = " + describeIds(subscriber.allPurchasedProductIds))
        found = false
        for each value in subscriber.allPurchasedProductIds
            valueType = type(value)
            if (valueType = "roString" or valueType = "String") and value = "bug_reporter_lifetime" then found = true
        end for
        if found then
            finish(true, "the lifetime product is listed")
        else
            finish(false, "the lifetime product is missing")
        end if
    end sub)
end sub

sub runSetLogLevel()
    m.title = "setLogLevel after configure"
    addLine("1. Purchases().configure({ apiKey, userId, proxyUrl })")
    configureSdk()
    addLine("   isConfigured() = " + Purchases().isConfigured().ToStr())
    pause(700)
    addLine("2. Purchases().setLogLevel(" + Chr(34) + "debug" + Chr(34) + ")")
    Purchases().setLogLevel("debug")
    addLine("   isConfigured() = " + Purchases().isConfigured().ToStr() + "   proxyURL() = " + describeValue(Purchases().proxyURL()))
    pause(700)
    addLine("3. Purchases().getCustomerInfo(callback)")
    addLine("Expected: the configured SDK fetches this customer")
    pause(1000)
    Purchases().getCustomerInfo(sub(subscriber, error)
        if error <> invalid then
            finish(false, "unexpected error " + FormatJson(error))
            return
        end if
        addLine("Callback: originalAppUserId = " + describeValue(subscriber.originalAppUserId))
        finish(true, "getCustomerInfo returned the configured customer")
    end sub)
end sub
