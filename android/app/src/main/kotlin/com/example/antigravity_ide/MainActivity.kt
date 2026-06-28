package com.example.antigravity_ide

import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.lang.Exception

class MainActivity : FlutterActivity() {
    companion object {
        var hasShownSplash = false
        private const val TAG = "MainActivity"
    }

    private val CHANNEL = "com.example.antigravity_ide/storage_permission"
    private val SPLASH_CHANNEL = "com.example.antigravity_ide/splash_state"
    private val TERMUX_CHANNEL = "com.example.antigravity_ide/termux_service"
    private val TERMINAL_METHOD_CHANNEL = "com.example.antigravity_ide/terminal_method"
    private val TERMINAL_EVENT_CHANNEL = "com.example.antigravity_ide/terminal_event"

    private var activeSession: TerminalSession? = null
    private var eventSink: EventChannel.EventSink? = null
    private var readerThread: Thread? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPermission" -> {
                    result.success(hasAllFilesPermission())
                }
                "requestPermission" -> {
                    requestAllFilesPermission()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SPLASH_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkSplash" -> {
                    result.success(hasShownSplash)
                }
                "setSplashShown" -> {
                    hasShownSplash = true
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TERMUX_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startTermuxBridge" -> {
                    val success = startTermuxBridge()
                    result.success(success)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.antigravity_ide/native_executor").setMethodCallHandler { call, result ->
            when (call.method) {
                "execute" -> {
                    val libPath = call.argument<String>("libPath")
                    val argsList = call.argument<List<String>>("args")
                    if (libPath != null && argsList != null) {
                        val exitCode = NativeExecutor.executeBinary(libPath, argsList.toTypedArray())
                        result.success(exitCode)
                    } else {
                        result.error("BAD_ARGS", "Missing libPath or args", null)
                    }
                }
                "getNativeLibDir" -> {
                    result.success(applicationContext.applicationInfo.nativeLibraryDir)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // New Termux-like native terminal method channel handler
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TERMINAL_METHOD_CHANNEL).setMethodCallHandler { call, result ->
            val manager = TerminalManager(applicationContext)
            when (call.method) {
                "extractBootstrap" -> {
                    Thread {
                        val success = manager.extractBootstrapIfNeeded()
                        runOnUiThread {
                            result.success(success)
                        }
                    }.start()
                }
                "createSession" -> {
                    var cmd = call.argument<String>("command") ?: "/system/bin/sh"
                    var args = call.argument<List<String>>("arguments")?.toTypedArray() ?: emptyArray()
                    val envs = call.argument<List<String>>("environment")?.toTypedArray() ?: manager.setupEnvironment()

                    // Ensure target binary exists and can be executed, fallback to system shell otherwise
                    val cmdFile = File(cmd)
                    if (!cmdFile.exists() || !cmdFile.canExecute()) {
                        Log.w(TAG, "Terminal command binary $cmd not found or not executable. Falling back to /system/bin/sh.")
                        cmd = "/system/bin/sh"
                        args = emptyArray()
                    }

                    try {
                        activeSession?.inputStream?.close()
                        activeSession?.outputStream?.close()
                    } catch (e: Exception) {}

                    try {
                        val session = TerminalSession(cmd, args, envs)
                        session.start()
                        activeSession = session
                        
                        // Restart reader loop if an event listener is already active
                        startReaderThread(session, eventSink)
                        
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("CREATE_FAILED", e.message, null)
                    }
                }
                "write" -> {
                    val data = call.argument<String>("data")
                    if (data != null && activeSession != null) {
                        Thread {
                            try {
                                activeSession?.outputStream?.write(data.toByteArray())
                                activeSession?.outputStream?.flush()
                            } catch (e: Exception) {
                                Log.e(TAG, "Write stdout error", e)
                            }
                        }.start()
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                "resize" -> {
                    val rows = call.argument<Int>("rows") ?: 24
                    val cols = call.argument<Int>("cols") ?: 80
                    activeSession?.resize(rows, cols)
                    result.success(true)
                }
                "isAlive" -> {
                    result.success(activeSession?.isAlive() ?: false)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // New Termux-like native terminal event channel handler to stream data back to Dart
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, TERMINAL_EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                    eventSink = sink
                    activeSession?.let { session ->
                        startReaderThread(session, sink)
                    }
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    readerThread?.interrupt()
                    readerThread = null
                }
            }
        )
    }

    private fun startReaderThread(session: TerminalSession, sink: EventChannel.EventSink?) {
        readerThread?.interrupt()
        readerThread = Thread {
            val buffer = ByteArray(4096)
            try {
                val input = session.inputStream
                while (!Thread.currentThread().isInterrupted && session.isAlive()) {
                    val read = input.read(buffer)
                    if (read > 0) {
                        val chunk = buffer.copyOf(read)
                        runOnUiThread {
                            sink?.success(chunk)
                        }
                    } else if (read == -1) {
                        break
                    }
                }
            } catch (e: Exception) {
                // Stream closed or thread interrupted
            } finally {
                runOnUiThread {
                    try {
                        sink?.endOfStream()
                    } catch (e: Exception) {}
                }
            }
        }
        readerThread?.start()
    }

    private fun startTermuxBridge(): Boolean {
        val intent = Intent()
        intent.component = ComponentName("com.termux", "com.termux.app.RunCommandService")
        intent.action = "com.termux.RUN_COMMAND"
        intent.putExtra("com.termux.RUN_COMMAND_PATH", "/data/data/com.termux/files/usr/bin/python3")
        intent.putExtra(
            "com.termux.RUN_COMMAND_ARGUMENTS",
            arrayOf(
                "-c",
                "import socket,subprocess,os,pty,select;s=socket.socket();s.setsockopt(socket.SOL_SOCKET,socket.SO_REUSEADDR,1);s.bind(('127.0.0.1',9090));s.listen(1);\ntry:\n c,a=s.accept();m,sl=pty.openpty();p=subprocess.Popen(['/data/data/com.termux/files/usr/bin/bash','-i'],stdin=sl,stdout=sl,stderr=sl,preexec_fn=os.setsid);os.close(sl);c.setblocking(False);\n while p.poll() is None:\n  r,w,x=select.select([c,m],[],[],0.05)\n  if c in r:\n   d=c.recv(1024)\n   if not d:break\n   os.write(m,d)\n  if m in r:\n   d=os.read(m,1024)\n   if not d:break\n   c.sendall(d)\nexcept Exception:\n pass"
            )
        )
        intent.putExtra("com.termux.RUN_COMMAND_WORKDIR", "/data/data/com.termux/files/home")
        intent.putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
        
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun hasAllFilesPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Environment.isExternalStorageManager()
        } else {
            true
        }
    }

    private fun requestAllFilesPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            try {
                val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION)
                intent.addCategory("android.intent.category.DEFAULT")
                intent.data = Uri.parse(String.format("package:%s", packageName))
                startActivity(intent)
            } catch (e: Exception) {
                val intent = Intent()
                intent.action = Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION
                startActivity(intent)
            }
        }
    }
}
