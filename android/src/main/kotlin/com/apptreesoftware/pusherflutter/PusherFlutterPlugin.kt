package com.apptreesoftware.pusherflutter

import android.app.Activity
import com.pusher.client.Pusher
import com.pusher.client.channel.Channel
import com.pusher.client.channel.SubscriptionEventListener
import com.pusher.client.connection.ConnectionEventListener
import com.pusher.client.connection.ConnectionState
import com.pusher.client.connection.ConnectionStateChange
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import org.json.JSONObject
import java.lang.Exception
import org.json.JSONArray



class PusherFlutterPlugin() : MethodCallHandler, ConnectionEventListener {

    var pusher: Pusher? = null
    val messageStreamHandler = MessageStreamHandler()
    val connectionStreamHandler = ConnectionStreamHandler()

    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar): Unit {
            val instance = PusherFlutterPlugin()
            val channel = MethodChannel(registrar.messenger(), "plugins.apptreesoftware.com/pusher")
            channel.setMethodCallHandler(instance)
            val connectionEventChannel = EventChannel(registrar.messenger(),
                                                      "plugins.apptreesoftware.com/pusher_connection")
            connectionEventChannel.setStreamHandler(instance.connectionStreamHandler)
            val messageEventChannel = EventChannel(registrar.messenger(),
                                                   "plugins.apptreesoftware.com/pusher_message")
            messageEventChannel.setStreamHandler(instance.messageStreamHandler)
        }
    }

    override fun onConnectionStateChange(state: ConnectionStateChange) {
        connectionStreamHandler.sendState(state.currentState)
    }

    override fun onError(p0: String?, p1: String?, p2: Exception?) {
        p2?.printStackTrace()
    }

    override fun onMethodCall(call: MethodCall, result: Result): Unit {
        when (call.method) {
            "create" -> pusher = Pusher(call.arguments as String?)
            "connect" -> pusher?.connect(this, ConnectionState.ALL)
            "disconnect" -> pusher?.disconnect()
            "subscribe" -> {
                val pusher = this.pusher ?: return
                val event = call.argument<String>("event")
                val channelName = call.argument<String>("channel")
                var channel = pusher.getChannel(channelName)
                if (channel == null) {
                    channel = pusher.subscribe(channelName)
                }
                listenToChannel(channel, event)
                result.success(null)
            }
            "unsubscribe" -> {
                val pusher = this.pusher ?: return
                val channelName = call.argument<String>("channel")
                pusher.unsubscribe(channelName)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun listenToChannel(channel: Channel, event: String) {
        val asyncDataListener = SubscriptionEventListener { _, eventName, data ->
            messageStreamHandler.send(channel.name, eventName, data)
        }
        channel.bind(event, asyncDataListener)
    }
}

class MessageStreamHandler : EventChannel.StreamHandler {
    private var eventSink: EventChannel.EventSink? = null
    override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
        eventSink = sink
    }

    fun send(channel: String, event: String, data: Any) {
        val json = JSONObject(data as String)
        val map = jsonToMap(json)
        eventSink?.success(mapOf("channel" to channel,
                                 "event" to event,
                                 "body" to map))
    }

    override fun onCancel(p0: Any?) {
        eventSink = null
    }
}

class ConnectionStreamHandler : EventChannel.StreamHandler {
    private var eventSink: EventChannel.EventSink? = null
    override fun onListen(argunents: Any?, sink: EventChannel.EventSink) {
        eventSink = sink
    }

    fun sendState(state: ConnectionState) {
        eventSink?.success(state.toString().toLowerCase())
    }

    override fun onCancel(p0: Any?) {
        eventSink = null
    }
}

fun jsonToMap(json: JSONObject?): Map<String, Any> {
    var retMap: Map<String, Any> = HashMap()

    if (json != null) {
        retMap = toMap(json)
    }
    return retMap
}

fun toMap(`object`: JSONObject): Map<String, Any> {
    val map = HashMap<String, Any>()

    val keysItr = `object`.keys().iterator()
    while (keysItr.hasNext()) {
        val key = keysItr.next()
        var value = `object`.get(key)

        if (value is JSONArray) {
            value = toList(value)
        } else if (value is JSONObject) {
            value = toMap(value)
        }
        map.put(key, value)
    }
    return map
}

fun toList(array: JSONArray): List<Any> {
    val list = ArrayList<Any>()
    for (i in 0..array.length() - 1) {
        var value = array.get(i)
        if (value is JSONArray) {
            value = toList(value)
        } else if (value is JSONObject) {
            value = toMap(value)
        }
        list.add(value)
    }
    return list
}