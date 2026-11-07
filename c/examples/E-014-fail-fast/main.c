#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* 不可恢复与快速失败：程序前提（不变量）被破坏时，继续跑只会放大破坏。
 * 与可重试/可处理的错误不同，这类 INTERNAL 错误的处置是——
 * 打一条可定位的诊断（文件、行、不变量内容），立刻以固定非零码退出。
 * 教学实现把 fatal 路径做成子命令：run.sh 捕获其退出码再打印，
 * 本例整体退出码保持 0（用例 PASS），而 fatal 的非零码成为被断言的业务输出。 */
enum { EXIT_INVARIANT = 70 }; /* 70 = EX_SOFTWARE（sysexits 惯例） */

typedef struct {
    int left;
    int right;
} node_t;

static node_t* build_tree(void) {
    node_t* n = malloc(sizeof *n);
    if (n == NULL) {
        return NULL;
    }
    n->left = 1;
    n->right = 0;
    return n;
}

static void fail_fast(const char* file, int line, const char* expr) {
    /* 真实项目里这里还应冲刷日志、按需生成 core；教学实现只打印诊断行 */
    printf("FATAL invariant violated: %s:%d (%s)\n", file, line, expr);
    exit(EXIT_INVARIANT);
}

#define CHECK_INVARIANT(expr) ((expr) ? (void)0 : fail_fast(__FILE__, __LINE__, #expr))

int main(int argc, char** argv) {
    if (argc < 2) {
        return 2;
    }
    node_t* root = build_tree();
    CHECK_INVARIANT(root != NULL);

    if (strcmp(argv[1], "fatal") == 0) {
        /* 模拟不变量在运行中被破坏（如越界写踩坏了字段） */
        root->left = 0;
        CHECK_INVARIANT(root->left > 0);
        printf("unreachable\n");
    } else {
        printf("ok path: invariant holds\n");
    }
    free(root);
    return 0;
}
