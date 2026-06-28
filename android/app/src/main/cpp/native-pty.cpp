#include <jni.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdlib.h>
#include <sys/ioctl.h>
#include <termios.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <android/log.h>
#include <string.h>
#include <signal.h>

#define LOG_TAG "TermuxPTY"
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

extern "C" {

JNIEXPORT jint JNICALL
Java_com_example_antigravity_1ide_TerminalSession_createSubprocess(
        JNIEnv* env, jobject thiz,
        jstring cmd, jobjectArray args, jobjectArray envp,
        jintArray processIdArray) {

    // Open master pseudo-terminal
    int ptm = posix_openpt(O_RDWR | O_CLOEXEC);
    if (ptm < 0) {
        LOGE("Failed to open master PTY");
        return -1;
    }

    if (grantpt(ptm) != 0 || unlockpt(ptm) != 0) {
        LOGE("Failed to grant/unlock PTY");
        close(ptm);
        return -1;
    }

    char devname[64];
    if (ptsname_r(ptm, devname, sizeof(devname)) != 0) {
        LOGE("Failed to get slave PTY name");
        close(ptm);
        return -1;
    }

    // Convert cmd string
    const char* c_cmd = env->GetStringUTFChars(cmd, nullptr);

    // Convert args array
    int arg_count = env->GetArrayLength(args);
    char** c_args = (char**) malloc((arg_count + 2) * sizeof(char*));
    c_args[0] = strdup(c_cmd);
    for (int i = 0; i < arg_count; i++) {
        jstring arg = (jstring) env->GetObjectArrayElement(args, i);
        const char* c_arg = env->GetStringUTFChars(arg, nullptr);
        c_args[i + 1] = strdup(c_arg);
        env->ReleaseStringUTFChars(arg, c_arg);
    }
    c_args[arg_count + 1] = nullptr;

    // Convert envp array
    int env_count = env->GetArrayLength(envp);
    char** c_envp = (char**) malloc((env_count + 1) * sizeof(char*));
    for (int i = 0; i < env_count; i++) {
        jstring env_var = (jstring) env->GetObjectArrayElement(envp, i);
        const char* c_env = env->GetStringUTFChars(env_var, nullptr);
        c_envp[i] = strdup(c_env);
        env->ReleaseStringUTFChars(env_var, c_env);
    }
    c_envp[env_count] = nullptr;

    pid_t pid = fork();
    if (pid < 0) {
        LOGE("Fork failed");
        close(ptm);
        // Clean up memory
        for (int i = 0; i < arg_count + 1; i++) free(c_args[i]);
        free(c_args);
        for (int i = 0; i < env_count; i++) free(c_envp[i]);
        free(c_envp);
        env->ReleaseStringUTFChars(cmd, c_cmd);
        return -1;
    } else if (pid == 0) {
        // Child Process: setsid() must be called BEFORE opening the slave pts
        // to establish pts as the controlling terminal.
        setsid();

        int pts = open(devname, O_RDWR);
        if (pts < 0) exit(-1);

        // Set the controlling terminal for the new session
        ioctl(pts, TIOCSCTTY, 0);
        
        // Setup termios
        struct termios tio;
        if (tcgetattr(pts, &tio) == 0) {
            cfmakeraw(&tio);
            tcsetattr(pts, TCSANOW, &tio);
        }

        // Tie slave PTY to Standard Streams
        dup2(pts, 0); // stdin
        dup2(pts, 1); // stdout
        dup2(pts, 2); // stderr

        close(pts);
        close(ptm);

        execve(c_cmd, c_args, c_envp);
        LOGE("execve failed to run: %s", c_cmd);
        exit(-1);
    } else {
        // Parent Process
        env->ReleaseStringUTFChars(cmd, c_cmd);
        
        // Clean up memory in parent
        for (int i = 0; i < arg_count + 1; i++) free(c_args[i]);
        free(c_args);
        for (int i = 0; i < env_count; i++) free(c_envp[i]);
        free(c_envp);

        // Pass the child PID back to Kotlin
        jint* pid_arr = env->GetIntArrayElements(processIdArray, nullptr);
        pid_arr[0] = pid;
        env->ReleaseIntArrayElements(processIdArray, pid_arr, 0);

        return ptm; // Returns Master PTY File Descriptor
    }
}

JNIEXPORT void JNICALL
Java_com_example_antigravity_1ide_TerminalSession_setPtyWindowSize(
        JNIEnv* env, jobject thiz,
        jint fd, jint rows, jint cols) {
    struct winsize sz;
    sz.ws_row = rows;
    sz.ws_col = cols;
    sz.ws_xpixel = 0;
    sz.ws_ypixel = 0;
    ioctl(fd, TIOCSWINSZ, &sz);
}

JNIEXPORT jboolean JNICALL
Java_com_example_antigravity_1ide_TerminalSession_isProcessAlive(
        JNIEnv* env, jobject thiz,
        jint pid) {
    if (pid <= 0) return JNI_FALSE;
    return (kill(pid, 0) == 0) ? JNI_TRUE : JNI_FALSE;
}

}
