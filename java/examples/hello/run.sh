#!/usr/bin/env bash
# 用例 hello —— 验证 JDK 21 可用（单文件源码模式，无需先 javac）
set -euo pipefail

java Hello.java
