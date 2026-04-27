package com.controlbituwb.app_uwb.uwb

import android.content.Context
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import androidx.core.uwb.RangingParameters
import androidx.core.uwb.RangingResult
import androidx.core.uwb.UwbAddress
import androidx.core.uwb.UwbComplexChannel
import androidx.core.uwb.UwbControleeSessionScope
import androidx.core.uwb.UwbDevice
import androidx.core.uwb.UwbManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch

/**
 * Bridges AndroidX Core UWB (Jetpack) controlee API to Flutter.
 *
 * MethodChannel: com.controlbit.app_uwb/uwb
 * EventChannel : com.controlbit.app_uwb/uwb/ranging
 *
 * Expected dependency: androidx.core.uwb:uwb:1.0.0-rc01.
 * If a field name (e.g. RangingParameters constructor parameters) has shifted,
 * adjust the [buildRangingParameters] function only.
 */
class UwbBridge(
    private val ctx: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private val methodChannel = MethodChannel(messenger, METHOD_CHANNEL)
    private val eventChannel = EventChannel(messenger, EVENT_CHANNEL)
    private val mainHandler = Handler(Looper.getMainLooper())

    private val scope = CoroutineScope(Dispatchers.Default + SupervisorJob())
    private var sessionScope: UwbControleeSessionScope? = null
    private var rangingJob: Job? = null
    private var sink: EventChannel.EventSink? = null

    init {
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
    }

    fun dispose() {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        scope.cancel()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isUwbAvailable" -> result.success(isUwbAvailable())
            "getRangingCapabilities" -> scope.launch {
                runCatchingResult(result) { capabilitiesAsMap() }
            }
            "getLocalAddress" -> scope.launch {
                runCatchingResult(result) { localAddressBytes() }
            }
            "startRanging" -> scope.launch {
                @Suppress("UNCHECKED_CAST")
                val args = call.arguments as Map<String, Any>
                runCatchingResult(result) { startRanging(args); null }
            }
            "stopRanging" -> scope.launch {
                runCatchingResult(result) { stopRanging(); null }
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    private fun isUwbAvailable(): Boolean =
        ctx.packageManager.hasSystemFeature(PackageManager.FEATURE_UWB)

    private suspend fun ensureScope(): UwbControleeSessionScope {
        sessionScope?.let { return it }
        val mgr = UwbManager.createInstance(ctx)
        val s = mgr.controleeSessionScope()
        sessionScope = s
        return s
    }

    private suspend fun capabilitiesAsMap(): Map<String, Any?> {
        val caps = ensureScope().rangingCapabilities
        return mapOf(
            "isDistanceSupported" to caps.isDistanceSupported,
            "isAzimuthalAngleSupported" to caps.isAzimuthalAngleSupported,
            "isElevationAngleSupported" to caps.isElevationAngleSupported,
            "minRangingInterval" to caps.minRangingInterval,
            "supportedChannels" to caps.supportedChannels.toList(),
            "supportedNtfConfigs" to caps.supportedNtfConfigs.toList(),
            "supportedConfigIds" to caps.supportedConfigIds.toList(),
            "supportedSlotDurations" to caps.supportedSlotDurations.toList(),
            "supportedRangingUpdateRates" to caps.supportedRangingUpdateRates.toList(),
            "isRangingIntervalReconfigureSupported" to caps.isRangingIntervalReconfigureSupported,
            "isBackgroundRangingSupported" to caps.isBackgroundRangingSupported,
        )
    }

    private suspend fun localAddressBytes(): ByteArray =
        ensureScope().localAddress.address

    private suspend fun startRanging(args: Map<String, Any>) {
        stopRanging()

        val controllerAddress = args["controllerAddress"] as ByteArray
        val sessionId = (args["sessionId"] as Number).toInt()
        val sessionKeyInfo = args["sessionKeyInfo"] as ByteArray
        val channel = (args["channel"] as Number).toInt()
        val preambleIndex = (args["preambleIndex"] as Number).toInt()
        val configId = (args["uwbConfigId"] as? Number)?.toInt()
            ?: RangingParameters.CONFIG_UNICAST_DS_TWR
        val rate = mapUpdateRate(args["rangingUpdateRate"] as? String)
        val slotMs = (args["slotDurationMs"] as? Number)?.toLong()

        val client = ensureScope()

        val params = buildRangingParameters(
            configId = configId,
            sessionId = sessionId,
            sessionKeyInfo = sessionKeyInfo,
            channel = channel,
            preambleIndex = preambleIndex,
            controllerAddress = controllerAddress,
            updateRate = rate,
            slotDurationMillis = slotMs,
        )

        post(mapOf("type" to "STARTED", "timestamp" to now()))

        rangingJob = scope.launch {
            try {
                client.prepareSession(params).collect { res ->
                    post(rangingResultToMap(res))
                }
                post(mapOf("type" to "STOPPED", "timestamp" to now()))
            } catch (t: Throwable) {
                post(
                    mapOf(
                        "type" to "ERROR",
                        "timestamp" to now(),
                        "errorCode" to (t.javaClass.simpleName),
                        "message" to (t.message ?: ""),
                    )
                )
            }
        }
    }

    private suspend fun stopRanging() {
        rangingJob?.cancelAndJoin()
        rangingJob = null
    }

    private fun buildRangingParameters(
        configId: Int,
        sessionId: Int,
        sessionKeyInfo: ByteArray,
        channel: Int,
        preambleIndex: Int,
        controllerAddress: ByteArray,
        updateRate: Int,
        slotDurationMillis: Long?,
    ): RangingParameters {
        val complex = UwbComplexChannel(channel = channel, preambleIndex = preambleIndex)
        val peer = UwbDevice(UwbAddress(controllerAddress))
        // Use the canonical RangingParameters constructor for 1.0.0-rc01.
        // If field names differ in your artifact version, adjust here only.
        return RangingParameters(
            uwbConfigType = configId,
            sessionId = sessionId,
            subSessionId = 0,
            sessionKeyInfo = sessionKeyInfo,
            subSessionKeyInfo = null,
            complexChannel = complex,
            peerDevices = listOf(peer),
            updateRateType = updateRate,
            uwbRangeDataNtfConfig = null,
            slotDurationMillis = slotDurationMillis ?: 0L,
            isAoaDisabled = false,
        )
    }

    private fun mapUpdateRate(s: String?): Int = when (s?.uppercase()) {
        "INFREQUENT" -> RangingParameters.RANGING_UPDATE_RATE_INFREQUENT
        "FAST" -> RangingParameters.RANGING_UPDATE_RATE_FREQUENT
        else -> RangingParameters.RANGING_UPDATE_RATE_AUTOMATIC
    }

    private fun rangingResultToMap(res: RangingResult): Map<String, Any?> = when (res) {
        is RangingResult.RangingResultPosition -> {
            val pos = res.position
            mapOf(
                "type" to "RESULT",
                "timestamp" to now(),
                "distanceM" to pos.distance?.value?.toDouble(),
                "azimuthDeg" to pos.azimuth?.value?.toDouble(),
                "elevationDeg" to pos.elevation?.value?.toDouble(),
                "rssiDbm" to null,
                "status" to 0,
            )
        }
        is RangingResult.RangingResultPeerDisconnected -> mapOf(
            "type" to "PEER_DISCONNECTED",
            "timestamp" to now(),
        )
        else -> mapOf(
            "type" to "OTHER",
            "timestamp" to now(),
            "kind" to res.javaClass.simpleName,
        )
    }

    private fun post(payload: Map<String, Any?>) {
        mainHandler.post { sink?.success(payload) }
    }

    private fun now(): Long = System.currentTimeMillis()

    private inline fun runCatchingResult(
        result: MethodChannel.Result,
        block: () -> Any?,
    ) {
        try {
            val value = block()
            mainHandler.post { result.success(value) }
        } catch (t: Throwable) {
            mainHandler.post {
                result.error(t.javaClass.simpleName, t.message, null)
            }
        }
    }

    companion object {
        private const val METHOD_CHANNEL = "com.controlbit.app_uwb/uwb"
        private const val EVENT_CHANNEL = "com.controlbit.app_uwb/uwb/ranging"
    }
}
