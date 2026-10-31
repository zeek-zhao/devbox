#include <jni.h>
#include "NativeProbe.h"

JNIEXPORT jint JNICALL Java_NativeProbe_add(
        JNIEnv *environment, jclass type, jint left, jint right) {
    (void) environment;
    (void) type;
    return left + right;
}
