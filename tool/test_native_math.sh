#!/bin/sh
# Runs the native sensor-math tests on this Mac, no device needed:
#   iOS:     ios/Tests/main.swift against ios/Classes/ReanimatedSensorMath.swift
#   Android: ReanimatedSensorMathTest.kt against ReanimatedSensorMath.kt, with
#            the Kotlin compiler and JUnit from the Gradle cache (run an
#            Android build once so they are there).
set -e
cd "$(dirname "$0")/.."
OUT="${TMPDIR:-/tmp}/reanimated_native_math"
rm -rf "$OUT"; mkdir -p "$OUT/kt"

echo "== iOS"
swiftc ios/Classes/ReanimatedSensorMath.swift ios/Tests/main.swift -o "$OUT/swift_test"
"$OUT/swift_test"

echo "== Android"
C="$HOME/.gradle/caches/modules-2/files-2.1"
jar() { find "$C/$1" -name "$2" ! -name '*sources*' ! -name '*javadoc*' 2>/dev/null | sort | tail -1; }
KC=$(jar org.jetbrains.kotlin/kotlin-compiler-embeddable 'kotlin-compiler-embeddable-*.jar')
STD=$(jar org.jetbrains.kotlin/kotlin-stdlib 'kotlin-stdlib-2*.jar')
SR=$(jar org.jetbrains.kotlin/kotlin-script-runtime 'kotlin-script-runtime-*.jar')
RF=$(jar org.jetbrains.kotlin/kotlin-reflect 'kotlin-reflect-*.jar')
DE=$(jar org.jetbrains.kotlin/kotlin-daemon-embeddable 'kotlin-daemon-embeddable-*.jar')
TR=$(jar org.jetbrains.intellij.deps/trove4j 'trove4j-*.jar')
CO=$(jar org.jetbrains.kotlinx/kotlinx-coroutines-core-jvm 'kotlinx-coroutines-core-jvm-*.jar')
AN=$(jar org.jetbrains/annotations 'annotations-*.jar')
JU=$(jar junit/junit 'junit-4.13*.jar')
HC=$(jar org.hamcrest/hamcrest-core 'hamcrest-core-1.3.jar')
if [ -z "$KC" ] || [ -z "$JU" ]; then
  echo "Kotlin compiler or JUnit not in the Gradle cache; run an Android build first."; exit 1
fi
java -cp "$KC:$STD:$SR:$RF:$DE:$TR:$CO:$AN" org.jetbrains.kotlin.cli.jvm.K2JVMCompiler \
  -no-stdlib -no-reflect -cp "$STD:$JU" -d "$OUT/kt" \
  android/src/main/kotlin/com/kluivert/reanimateddartnative/ReanimatedSensorMath.kt \
  android/src/test/kotlin/com/kluivert/reanimateddartnative/ReanimatedSensorMathTest.kt 2>/dev/null
java -cp "$OUT/kt:$STD:$JU:$HC" org.junit.runner.JUnitCore \
  com.kluivert.reanimateddartnative.ReanimatedSensorMathTest | tail -2
