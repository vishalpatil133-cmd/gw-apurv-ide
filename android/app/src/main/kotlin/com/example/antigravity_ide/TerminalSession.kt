package com.example.antigravity_ide

import android.os.ParcelFileDescriptor
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.InputStream
import java.io.OutputStream
import java.lang.Exception

class TerminalSession(
    private val command: String,
    private val arguments: Array<String>,
    private val environment: Array<String>
) {
    companion object {
        init {
            System.loadLibrary("native-lib") // We compile native-pty.cpp inside native-lib
        }
    }

    private external fun createSubprocess(
        cmd: String,
        args: Array<String>,
        envp: Array<String>,
        processIdArray: IntArray
    ): Int

    private external fun setPtyWindowSize(fd: Int, rows: Int, cols: Int)
    private external fun isProcessAlive(pid: Int): Boolean

    private var masterFd: Int = -1
    private var childPid: Int = -1
    
    lateinit var inputStream: InputStream
        private set
    lateinit var outputStream: OutputStream
        private set

    fun start() {
        val pidArray = IntArray(1)
        masterFd = createSubprocess(command, arguments, environment, pidArray)
        if (masterFd < 0) {
            throw Exception("Failed to launch shell subprocess")
        }
        childPid = pidArray[0]

        val pfd = ParcelFileDescriptor.adoptFd(masterFd)
        inputStream = FileInputStream(pfd.fileDescriptor)
        outputStream = FileOutputStream(pfd.fileDescriptor)
    }

    fun resize(rows: Int, cols: Int) {
        if (masterFd >= 0) {
            setPtyWindowSize(masterFd, rows, cols)
        }
    }

    fun isAlive(): Boolean {
        if (childPid <= 0) return false
        return isProcessAlive(childPid)
    }
}
