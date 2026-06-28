#include <jni.h>
#include <unistd.h>
#include <sys/wait.h>
#include <android/log.h>
#include <string.h>
#include <stdlib.h>

extern "C" JNIEXPORT jint JNICALL
Java_com_example_antigravity_1ide_NativeExecutor_executeBinary(
    JNIEnv* env, jobject clazz, jstring libPath, jobjectArray argsArray) {
    
    const char* path = env->GetStringUTFChars(libPath, NULL);
    
    // Convert jobjectArray to char* argv[]
    jsize len = env->GetArrayLength(argsArray);
    char** argv = (char**)malloc((len + 2) * sizeof(char*));
    argv[0] = strdup(path);
    
    for (int i = 0; i < len; i++) {
        jstring argStr = (jstring)env->GetObjectArrayElement(argsArray, i);
        const char* arg = env->GetStringUTFChars(argStr, NULL);
        argv[i + 1] = strdup(arg);
        env->ReleaseStringUTFChars(argStr, arg);
    }
    argv[len + 1] = NULL;
    
    pid_t pid = fork();
    if (pid == 0) { // Child
        execv(path, argv);
        _exit(1);
    } else if (pid > 0) { // Parent
        int status;
        waitpid(pid, &status, 0);
        
        // Clean up
        for (int i = 0; i < len + 1; i++) {
            free(argv[i]);
        }
        free(argv);
        env->ReleaseStringUTFChars(libPath, path);
        
        return WEXITSTATUS(status);
    }
    
    free(argv);
    env->ReleaseStringUTFChars(libPath, path);
    return -1;
}
