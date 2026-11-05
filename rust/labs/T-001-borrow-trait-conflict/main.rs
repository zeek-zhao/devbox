// T-001-borrow-trait-conflict 练习现场（有缺陷代码，勿模仿）。
// 缺陷 1（E0502，借用检查）：scores 还被 first 不可变借用着，又对它 push（可变借用）；
// 缺陷 2（E0119，特征冲突）：Describe 既有 blanket impl<T: Debug> Describe for T，
//          又有 impl Describe for String——后者被前者覆盖，coherence 检查拒绝编译。

trait Describe {
    fn describe(&self) -> String;
}

impl<T: std::fmt::Debug> Describe for T {
    fn describe(&self) -> String {
        format!("{:?}", self)
    }
}

impl Describe for String {
    fn describe(&self) -> String {
        format!("字符串: {}", self)
    }
}

fn main() {
    println!("run: start"); // 执行标记：证明二进制真的被跑过（素材 S-06）
    let mut scores = vec![90_i32, 85, 77];
    let first = &scores[0]; // 不可变借用在此诞生
    scores.push(88); // 缺陷 1：可变借用撞上存活中的 first
    println!("first={} total={}", first, scores.len());
    println!("{}", scores[0].describe());
    println!("{}", String::from("你好").describe());
}
