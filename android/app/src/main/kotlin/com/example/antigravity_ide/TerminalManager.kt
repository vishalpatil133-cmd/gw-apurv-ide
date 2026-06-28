package com.example.antigravity_ide

import android.content.Context
import android.util.Log
import java.io.File
import java.io.FileOutputStream
import java.util.zip.ZipInputStream

class TerminalManager(private val context: Context) {

    private val filesDir = context.filesDir.absolutePath
    val prefixDir = "$filesDir/usr"
    val homeDir = "$filesDir/home"
    
    companion object {
        private const val TAG = "TerminalManager"
    }

    fun setupEnvironment(): Array<String> {
        val envList = ArrayList<String>()

        // Ensure directories exist
        File(prefixDir).mkdirs()
        File(homeDir).mkdirs()

        // Set Termux environment variables matching the custom package name
        envList.add("PATH=$prefixDir/bin:$prefixDir/bin/applets")
        envList.add("LD_LIBRARY_PATH=$prefixDir/lib")
        envList.add("PREFIX=$prefixDir")
        envList.add("HOME=$homeDir")
        envList.add("TERM=xterm-256color")
        envList.add("LANG=en_US.UTF-8")

        // LD_PRELOAD redirection hook if compiled and available
        val termuxExecPath = "$prefixDir/lib/libtermux-exec.so"
        if (File(termuxExecPath).exists()) {
            envList.add("LD_PRELOAD=$termuxExecPath")
        }

        return envList.toTypedArray()
    }

    fun extractBootstrapIfNeeded(): Boolean {
        val markerFile = File(prefixDir, "bootstrap_extracted.marker")
        val readlineSymlink = File(prefixDir, "lib/libreadline.so.8")
        if (markerFile.exists() && readlineSymlink.exists()) {
            Log.d(TAG, "Bootstrap already extracted and verified.")
            return true // Already extracted and verified
        }

        Log.d(TAG, "Starting extraction of bootstrap environment...")
        try {
            // Create PREFIX and HOME
            File(prefixDir).mkdirs()
            File(homeDir).mkdirs()

            // Check if bootstrap file is located inside flutter_assets directory
            val assetPath = try {
                context.assets.open("flutter_assets/assets/bootstrap-aarch64.zip").close()
                "flutter_assets/assets/bootstrap-aarch64.zip"
            } catch (e: Exception) {
                "bootstrap-aarch64.zip"
            }
            context.assets.open(assetPath).use { inputStream ->
                ZipInputStream(inputStream).use { zipStream ->
                    var entry = zipStream.nextEntry
                    while (entry != null) {
                        val destFile = File(prefixDir, entry.name)
                        if (entry.isDirectory) {
                            destFile.mkdirs()
                        } else {
                            destFile.parentFile?.mkdirs()
                            FileOutputStream(destFile).use { fos ->
                                zipStream.copyTo(fos)
                            }
                            
                            // Apply executable permissions for bin files
                            if (entry.name.startsWith("bin/") || 
                                entry.name.contains("/bin/") || 
                                entry.name.startsWith("libexec/") ||
                                entry.name.contains("/libexec/")) {
                                destFile.setExecutable(true, false)
                                destFile.setReadable(true, false)
                            }
                        }
                        zipStream.closeEntry()
                        entry = zipStream.nextEntry
                    }
                }
            }

            // Parse and create symlinks from SYMLINKS.txt
            val symlinksFile = File(prefixDir, "SYMLINKS.txt")
            if (symlinksFile.exists()) {
                Log.d(TAG, "Creating symbolic links from SYMLINKS.txt...")
                symlinksFile.forEachLine { line ->
                    if (line.contains("←")) {
                        val parts = line.split("←")
                        if (parts.size == 2) {
                            val target = parts[0].trim()
                            val linkRelPath = parts[1].trim()
                            
                            val linkFile = File(prefixDir, linkRelPath)
                            if (linkFile.exists()) {
                                linkFile.delete()
                            }
                            linkFile.parentFile?.mkdirs()
                            
                            try {
                                android.system.Os.symlink(target, linkFile.absolutePath)
                            } catch (e: Exception) {
                                Log.e(TAG, "Failed to create symlink: ${linkFile.absolutePath} -> $target", e)
                            }
                        }
                    }
                }
            }

            // Create marker file on successful extraction
            markerFile.createNewFile()
            Log.d(TAG, "Bootstrap extraction completed successfully.")
            return true
        } catch (e: Exception) {
            Log.e(TAG, "Error extracting bootstrap assets", e)
            return false
        }
    }
}
