// E-006 anyhow 式错误上下文（手写等价）：给 Result 逐层附加上下文，
// 顶层报告完整语境，Error::source 链保留根因。纯 std，无第三方依赖。

use std::error::Error;
use std::fmt;

/// 带上下文的错误：context 是这一层「当时在做什么」，source 指向下一层。
#[derive(Debug)]
struct ContextError {
    context: String,
    source: Box<dyn Error + 'static>,
}

impl fmt::Display for ContextError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(formatter, "{}", self.context)
    }
}

impl Error for ContextError {
    fn source(&self) -> Option<&(dyn Error + 'static)> {
        Some(self.source.as_ref())
    }
}

/// anyhow::Context 的手写等价：任何 Result 都能就地附加上下文。
trait WithContext<T> {
    fn with_context<F>(self, context: F) -> Result<T, ContextError>
    where
        F: FnOnce() -> String;
}

impl<T, E> WithContext<T> for Result<T, E>
where
    E: Error + 'static,
{
    fn with_context<F>(self, context: F) -> Result<T, ContextError>
    where
        F: FnOnce() -> String,
    {
        self.map_err(|error| ContextError {
            context: context(),
            source: Box::new(error),
        })
    }
}

fn parse_document_id(raw: &str) -> Result<u32, ContextError> {
    raw.parse::<u32>()
        .with_context(|| format!("parsing document id from `{raw}`"))
}

/// ContextError 自身也实现 Error，所以还能继续叠加一层上下文。
fn load_document(raw: &str) -> Result<u32, ContextError> {
    parse_document_id(raw).with_context(|| "loading document for search index".to_string())
}

fn main() {
    match load_document("seven") {
        Ok(id) => println!("document id: {id}"),
        Err(error) => {
            let mut chain: Vec<String> = vec![error.to_string()];
            let mut source = error.source();
            while let Some(current) = source {
                chain.push(current.to_string());
                source = current.source();
            }
            println!("top context: {}", chain[0]);
            println!("next layer: {}", chain[1]);
            println!("root cause: {}", chain[2]);
            println!("context stack depth: {}", chain.len());
        }
    }

    match load_document("42") {
        Ok(id) => println!("ok path: id {id}"),
        Err(_) => println!("ok path not hit"),
    }
}
