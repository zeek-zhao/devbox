#include "devbox_tests_NativeChecksum.h"

JNIEXPORT jlong JNICALL Java_devbox_tests_NativeChecksum_sum
  (JNIEnv *env, jclass type, jintArray ids) {
    (void) type;
    if (ids == NULL) {
        jclass error = (*env)->FindClass(env, "java/lang/NullPointerException");
        if (error != NULL) (*env)->ThrowNew(env, error, "ids");
        return 0;
    }
    jsize length = (*env)->GetArrayLength(env, ids);
    jint *values = (*env)->GetIntArrayElements(env, ids, NULL);
    if (values == NULL) return 0; /* JVM has already raised an allocation error. */
    jlong sum = 0;
    for (jsize i = 0; i < length; ++i) sum += values[i];
    (*env)->ReleaseIntArrayElements(env, ids, values, JNI_ABORT);
    return sum;
}
