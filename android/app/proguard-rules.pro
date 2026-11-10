# Pertahankan simbol JNI dan kelas TensorFlow Lite pada mode rilis (R8)
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**
-dontwarn org.tensorflow.lite.gpu.**

