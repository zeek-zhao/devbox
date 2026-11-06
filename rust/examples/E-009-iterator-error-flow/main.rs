// E-009 迭代器与错误流：collect 把 Vec<Result> 收敛成 Result<Vec>（首错
// 短路）；try_fold 在首个错误处停止并携带累积值；filter_map(Result::ok)
// 只留成功项；fold 计数完成分区统计。

use std::num::ParseIntError;

fn double_parsed(raw: &str) -> Result<u64, ParseIntError> {
    Ok(raw.trim().parse::<u64>()? * 2)
}

fn main() {
    let inputs = ["1", " 2 ", "x", "4"];

    // 1) collect：任一 Err 则整体 Err（首错短路）。
    let all: Result<Vec<u64>, ParseIntError> =
        inputs.iter().map(|raw| double_parsed(raw)).collect();
    println!("collect all: {}", all.is_err());

    // 2) try_fold：首错即停，还能携带累积值。
    let folded: Result<u64, ParseIntError> = inputs
        .iter()
        .try_fold(0u64, |sum, raw| Ok(sum + double_parsed(raw)?));
    println!(
        "try_fold: {}",
        match folded {
            Ok(sum) => format!("sum {sum}"),
            Err(_) => "short-circuited".to_string(),
        }
    );

    // 3) 只要成功项：filter_map(Result::ok)，失败被静默丢弃。
    let successes: Vec<u64> = inputs
        .iter()
        .filter_map(|raw| double_parsed(raw).ok())
        .collect();
    println!("ok-only: {successes:?}");

    // 4) 分区计数：成功/失败各多少（要全部原因时用 E-007 的聚合模式）。
    let (oks, errs) = inputs.iter().fold((0usize, 0usize), |(o, e), raw| {
        if double_parsed(raw).is_ok() {
            (o + 1, e)
        } else {
            (o, e + 1)
        }
    });
    println!("partition: {oks} ok, {errs} err");
}
