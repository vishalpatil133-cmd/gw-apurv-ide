package com.example.antigravity_ide

object NativeExecutor {
    init {
        System.loadLibrary("native-lib")
    }

    @JvmStatic
    external fun executeBinary(libPath: String, args: Array<String>): Int
}
