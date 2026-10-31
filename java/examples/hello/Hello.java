// 用例 hello：确认 JDK 21 可用，record 与单文件源码运行正常
public class Hello {

    record Point(int x, int y) {}

    public static void main(String[] args) {
        System.out.println("[hello] Java from devbox");
        // 只打印 feature 版本（21），不打印完整版本，避免补丁号变动导致用例不稳定
        System.out.println("java feature = " + Runtime.version().feature());

        Point p = new Point(3, 4);
        System.out.println("dist = " + (int) Math.hypot(p.x(), p.y()));

        int sum = 0;
        for (int i = 1; i <= 100; i++) {
            sum += i;
        }
        System.out.println("sum(1..100) = " + sum);
    }
}
