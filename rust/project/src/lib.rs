//! A standard-library-only command-line utility. // L2-005-doctests
//!
//! ```
//! use devbox_rust_project::{AppError, parse_args, run};
//! let args = vec!["bench".to_owned()];
//! run(parse_args(&args)?, &mut std::io::stdout())?;
//! # Ok::<(), AppError>(())
//! ```

use std::collections::BTreeMap;
use std::error::Error;
use std::fmt;
use std::fs;
use std::io::{self, Write};
use std::path::PathBuf;
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::{Arc, Mutex, mpsc};
use std::thread;
use std::time::Instant;

#[derive(Debug)] // L1-010-custom-errors
pub enum AppError {
    Io(Box<io::Error>), // L1-024-box-ownership
    InvalidArguments(String),
    WorkerPanicked,
    WorkerChannelClosed,
    WorkerStatePoisoned,
    CountOverflow,
}

impl fmt::Display for AppError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Io(error) => write!(formatter, "I/O error: {error}"),
            Self::InvalidArguments(message) => write!(formatter, "{message}"),
            Self::WorkerPanicked => write!(formatter, "a worker thread panicked"),
            Self::WorkerChannelClosed => write!(formatter, "a worker result channel closed"),
            Self::WorkerStatePoisoned => write!(formatter, "worker state lock was poisoned"),
            Self::CountOverflow => write!(formatter, "count overflow"),
        }
    }
}

impl Error for AppError {
    // L1-014-trait-implementations
    fn source(&self) -> Option<&(dyn Error + 'static)> {
        match self {
            Self::Io(error) => Some(error.as_ref()), // L1-017-static-dynamic-dispatch
            _ => None,
        }
    }
}

impl From<io::Error> for AppError {
    fn from(error: io::Error) -> Self {
        Self::Io(Box::new(error))
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)] // L1-002-copy-types
pub enum Operation {
    // L1-011-data-enums
    Count,
    Dupe,
    Bench,
    Help,
    SelfCheck,
}

#[derive(Debug)]
pub struct CliOptions {
    pub operation: Operation,
    pub paths: Vec<PathBuf>,
    pub workers: usize,
}

/// Keeps the input slice borrowed while parsing rather than copying the argument list.
struct Arguments<'a> {
    // L1-007-struct-lifetimes
    values: &'a [String],
}

impl<'a> Arguments<'a> {
    fn command(&self) -> Option<&'a str> {
        // L1-006-return-lifetimes
        self.values.first().map(String::as_str)
    }
}

pub fn parse_args(args: &[String]) -> Result<CliOptions, AppError> {
    let borrowed = Arguments { values: args }; // L1-003-shared-borrows
    let command = borrowed.command().unwrap_or("--help"); // L1-008-option-values
    let operation = match command {
        // L1-012-exhaustive-match
        "count" => Operation::Count,
        "dupe" => Operation::Dupe,
        "bench" => Operation::Bench,
        "--help" | "-h" => Operation::Help,
        "--self-check" => Operation::SelfCheck,
        other => {
            // L1-013-pattern-bindings
            return Err(AppError::InvalidArguments(format!(
                "unknown command: {other}"
            )));
        }
    };

    let mut paths = Vec::new();
    let mut workers = thread::available_parallelism().map_or(1, usize::from);
    let mut index = 1usize;
    while index < args.len() {
        let argument = args[index].as_str();
        if argument == "--help" || argument == "-h" {
            return Ok(CliOptions {
                operation: Operation::Help,
                paths: Vec::new(),
                workers,
            });
        } else if let Some(value) = argument.strip_prefix("--threads=") {
            workers = parse_workers(value)?;
        } else if argument == "--threads" {
            index += 1;
            let value = args.get(index).ok_or_else(|| {
                AppError::InvalidArguments("--threads requires a value".to_owned())
            })?;
            workers = parse_workers(value)?;
        } else if argument.starts_with("--") {
            return Err(AppError::InvalidArguments(format!(
                "unknown option: {argument}"
            )));
        } else if operation == Operation::Count || operation == Operation::Dupe {
            paths.push(PathBuf::from(argument));
        } else {
            return Err(AppError::InvalidArguments(format!(
                "{command} does not accept positional arguments"
            )));
        }
        index += 1;
    }

    #[cfg(feature = "strict-args")]
    if matches!(operation, Operation::Count | Operation::Dupe) && paths.is_empty() {
        return Err(AppError::InvalidArguments(
            "strict-args requires at least one path".to_owned(),
        ));
    }
    #[cfg(not(feature = "strict-args"))]
    if matches!(operation, Operation::Count | Operation::Dupe) && paths.is_empty() {
        paths.push(PathBuf::from("."));
    }

    Ok(CliOptions {
        operation,
        paths,
        workers,
    })
}

fn parse_workers(value: &str) -> Result<usize, AppError> {
    let workers = value
        .parse::<usize>()
        .map_err(|_| AppError::InvalidArguments(format!("invalid worker count: {value}")))?;
    if workers == 0 {
        return Err(AppError::InvalidArguments(
            "worker count must be greater than zero".to_owned(),
        ));
    }
    Ok(workers)
}

pub fn run<W: Write>(options: CliOptions, output: &mut W) -> Result<(), AppError> {
    // L1-015-generic-bounds
    match options.operation {
        Operation::Count | Operation::Dupe => {
            let mut files = collect_files(&options.paths)?; // L1-009-result-propagation
            files.sort();
            let mut lines = Vec::new();
            for path in files {
                lines.extend(fs::read_to_string(path)?.lines().map(str::to_owned)); // L1-019-iterator-adaptors
            }
            let kind = options.operation;
            let counts = process_lines(lines, kind, options.workers)?;
            write_results(output, &counts, kind)?;
        }
        Operation::Bench => run_benchmark(output)?,
        Operation::Help => writeln!(
            output,
            "Usage: devbox-rust-project <count|dupe|bench|--self-check> [--threads=N] [PATH...]"
        )?,
        Operation::SelfCheck => run_self_check(output)?,
    }
    Ok(())
}

fn collect_files(paths: &[PathBuf]) -> Result<Vec<PathBuf>, AppError> {
    let mut pending = paths.to_vec();
    let mut files = Vec::new();
    while let Some(path) = pending.pop() {
        let metadata = fs::symlink_metadata(&path)?;
        if metadata.is_file() {
            files.push(path);
        } else if metadata.is_dir() {
            let mut children = fs::read_dir(path)?
                .map(|entry| entry.map(|entry| entry.path()))
                .collect::<Result<Vec<_>, _>>()?;
            children.sort_by(|left, right| right.cmp(left)); // L1-022-closure-traits
            pending.extend(children);
        }
    }
    Ok(files)
}

// L2-002-cargo-modules
mod words {
    pub(super) struct Words<'a> {
        // L1-030-modules-visibility
        remaining: &'a str,
    }

    impl<'a> Words<'a> {
        pub(super) fn new(line: &'a str) -> Self {
            Self { remaining: line }
        }
    }

    impl<'a> Iterator for Words<'a> {
        // L1-021-custom-iterator
        type Item = &'a str; // L3-002-zero-copy-parser

        fn next(&mut self) -> Option<Self::Item> {
            let start = self.remaining.find(char::is_alphanumeric)?; // L1-018-lazy-iterators
            let tail = &self.remaining[start..];
            let end = tail
                .char_indices() // L1-028-utf8-chars-bytes
                .find_map(|(offset, character)| (!character.is_alphanumeric()).then_some(offset))
                .unwrap_or(tail.len());
            let (word, rest) = tail.split_at(end);
            self.remaining = rest;
            Some(word)
        }
    }
}
use words::Words;

fn process_lines(
    lines: Vec<String>,
    operation: Operation,
    worker_count: usize,
) -> Result<BTreeMap<String, usize>, AppError> {
    if lines.is_empty() {
        return Ok(BTreeMap::new());
    }
    let workers = worker_count.min(lines.len()).max(1);
    let shard_size = lines.len().div_ceil(workers);
    let completed = Arc::new(Mutex::new(0usize));

    thread::scope(|scope| {
        let (sender, receiver) = mpsc::channel(); // L3-003-scoped-thread-channel
        let mut handles = Vec::new();
        for shard in lines.chunks(shard_size) {
            // L1-032-slices-bounds
            let sender = sender.clone();
            let owned_shard = shard.to_vec();
            let completed = Arc::clone(&completed);
            // L1-001-string-move
            handles.push(scope.spawn(move || {
                // L1-023-move-closures
                let mut local = BTreeMap::<String, usize>::new();
                for line in owned_shard {
                    // L1-020-iterator-ownership
                    if operation == Operation::Count {
                        for word in Words::new(&line) {
                            let word = word.to_lowercase(); // L1-027-str-string
                            let count = local.entry(word).or_default();
                            *count = count.checked_add(1).ok_or(AppError::CountOverflow)?; // L1-004-mutable-borrows
                        }
                    } else {
                        let count = local.entry(line).or_default();
                        *count = count.checked_add(1).ok_or(AppError::CountOverflow)?;
                    }
                    let mut total = completed // L1-026-arc-mutex
                        .lock()
                        .map_err(|_| AppError::WorkerStatePoisoned)?;
                    *total = total.checked_add(1).ok_or(AppError::CountOverflow)?;
                }
                sender
                    .send(local)
                    .map_err(|_| AppError::WorkerChannelClosed)
            }));
        }
        drop(sender);

        let mut merged = BTreeMap::<String, usize>::new();
        for partial in receiver {
            for (key, value) in partial {
                let total = merged.entry(key).or_default();
                *total = total.checked_add(value).ok_or(AppError::CountOverflow)?; // L1-033-integer-overflow
            }
        }
        for handle in handles {
            handle.join().map_err(|_| AppError::WorkerPanicked)??;
        }

        let processed = *completed
            .lock()
            .map_err(|_| AppError::WorkerStatePoisoned)?;
        if processed != lines.len() {
            return Err(AppError::WorkerChannelClosed);
        }
        if operation == Operation::Dupe {
            merged.retain(|_, count| *count > 1);
        }
        Ok(merged)
    })
}

fn write_results<W: Write>(
    // L1-017-static-dynamic-dispatch
    output: &mut W,
    counts: &BTreeMap<String, usize>,
    operation: Operation,
) -> Result<(), AppError> {
    for (value, count) in counts {
        match operation {
            Operation::Count => writeln!(output, "{value}: {count}")?,
            Operation::Dupe => writeln!(output, "{value}")?,
            _ => unreachable!("only count and dupe produce result maps"),
        }
    }
    Ok(())
}

trait SectionWriter: Write {
    // L1-016-trait-default-methods
    fn write_section(&mut self, name: &str) -> io::Result<()> {
        writeln!(self, "{name}:")
    }
}

impl<T: Write + ?Sized> SectionWriter for T {}

fn run_self_check<W: Write>(output: &mut W) -> Result<(), AppError> {
    let fixed_lines = vec![
        "alpha beta".to_owned(),
        "gamma alpha".to_owned(),
        "repeat".to_owned(),
        "repeat".to_owned(),
    ];
    output.write_section("count")?;
    let counts = process_lines(fixed_lines.clone(), Operation::Count, 2)?;
    write_results(output, &counts, Operation::Count)?;
    output.write_section("dupe")?;
    let duplicates = process_lines(fixed_lines, Operation::Dupe, 2)?;
    write_results(output, &duplicates, Operation::Dupe)?;
    output.write_section("bench")?;
    run_benchmark(output)
}

fn run_benchmark<W: Write>(output: &mut W) -> Result<(), AppError> {
    const OPERATIONS: usize = 1_000;
    const WORKERS: usize = 4;
    let started = Instant::now(); // L3-005-std-benchmark
    let operations = AtomicUsize::new(0); // L3-006-atomics-ordering
    thread::scope(|scope| {
        let mut handles = Vec::new();
        for _ in 0..WORKERS {
            let operations = &operations;
            handles.push(scope.spawn(move || {
                let mut checksum = 0usize;
                for value in 0..(OPERATIONS / WORKERS) {
                    checksum = checksum.wrapping_add(value);
                    operations.fetch_add(1, Ordering::Relaxed);
                }
                checksum
            }));
        }
        for handle in handles {
            handle.join().map_err(|_| AppError::WorkerPanicked)?;
        }
        Ok::<(), AppError>(())
    })?;
    let _elapsed = started.elapsed();
    let operation_count = operations.load(Ordering::Relaxed);
    writeln!(output, "operations: {operation_count}")?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::cell::RefCell;
    use std::rc::Rc;

    // L2-003-unit-tests
    #[test]
    fn parses_equal_and_separate_worker_flags() {
        let equal = vec![
            "count".to_owned(),
            "--threads=2".to_owned(),
            "alpha.txt".to_owned(),
        ];
        assert_eq!(parse_args(&equal).unwrap().workers, 2);
        let separate = vec![
            "dupe".to_owned(),
            "--threads".to_owned(),
            "3".to_owned(),
            "beta.txt".to_owned(),
        ];
        assert_eq!(parse_args(&separate).unwrap().workers, 3);
    }

    #[test]
    fn self_check_is_stable() {
        let options = CliOptions {
            operation: Operation::SelfCheck,
            paths: Vec::new(),
            workers: 1,
        };
        let mut output = Vec::new();
        run(options, &mut output).unwrap();
        assert_eq!(
            String::from_utf8(output).unwrap(),
            "count:\nalpha: 2\nbeta: 1\ngamma: 1\nrepeat: 2\ndupe:\nrepeat\nbench:\noperations: 1000\n"
        );
    }

    #[test]
    fn shared_capture_can_be_inspected_after_writing() {
        struct SharedWriter(Rc<RefCell<Vec<u8>>>);
        impl Write for SharedWriter {
            fn write(&mut self, bytes: &[u8]) -> io::Result<usize> {
                self.0.borrow_mut().extend_from_slice(bytes);
                Ok(bytes.len())
            }
            fn flush(&mut self) -> io::Result<()> {
                Ok(())
            }
        }

        let capture = Rc::new(RefCell::new(Vec::new())); // L1-025-rc-refcell
        let reader = Rc::clone(&capture);
        let mut writer = SharedWriter(capture);
        writeln!(writer, "captured").unwrap();
        assert_eq!(&*reader.borrow(), b"captured\n");
    }

    #[test]
    fn command_name_borrows_the_argument_string() {
        let args = vec!["count".to_owned()];
        let borrowed = Arguments { values: &args };
        let command = borrowed.command().unwrap();
        assert_eq!(command, "count");
        assert!(std::ptr::eq(command.as_ptr(), args[0].as_ptr()));
    }

    #[test]
    fn words_preserve_utf8_boundaries() {
        let input = "猫 café";
        let words = Words::new(input).collect::<Vec<_>>();
        assert_eq!(words, ["猫", "café"]);
        assert_eq!(input.get(0..3), Some("猫")); // L1-029-string-slice-boundaries
        assert_eq!(input.as_bytes()[0..3], [0xe7, 0x8c, 0xab]);
    }

    #[test]
    fn checked_counts_and_duplicate_lines_are_deterministic() {
        let lines = vec!["same".to_owned(), "other".to_owned(), "same".to_owned()];
        assert_eq!(
            process_lines(lines, Operation::Dupe, 8).unwrap(),
            BTreeMap::from([("same".to_owned(), 2)])
        );
    }

    #[test]
    fn strict_feature_documents_explicit_input() {
        #[cfg(feature = "strict-args")]
        assert!(parse_args(&["count".to_owned()]).is_err());
        #[cfg(not(feature = "strict-args"))]
        assert_eq!(
            parse_args(&["count".to_owned()]).unwrap().paths,
            [PathBuf::from(".")]
        );
    }

    #[test]
    fn binary_record_round_trips_a_count() {
        fn encode_count(count: u64) -> [u8; 8] {
            count.to_le_bytes()
        }
        fn decode_count(record: [u8; 8]) -> u64 {
            u64::from_le_bytes(record)
        }
        assert_eq!(
            decode_count(encode_count(0x1020_3040_5060_7080)),
            0x1020_3040_5060_7080
        ); // L3-001-binary-format
    }

    #[test]
    fn c_abi_function_pointer_keeps_a_stable_signature() {
        extern "C" fn count_bytes(length: usize) -> usize {
            length
        }
        let function: extern "C" fn(usize) -> usize = count_bytes; // L3-004-c-abi-ffi
        assert_eq!(function(7), 7);
    }

    #[test]
    fn a_borrow_ends_before_the_owned_string_is_reused() {
        let text = String::from("scope");
        let length = {
            let slice = text.as_str();
            slice.len()
        }; // L1-005-borrow-scope
        assert_eq!(text, "scope");
        assert_eq!(length, 5);
    }

    #[test]
    fn local_values_drop_in_reverse_declaration_order() {
        struct DropRecord<'a> {
            name: &'a str,
            events: &'a RefCell<Vec<&'a str>>,
        }
        impl Drop for DropRecord<'_> {
            fn drop(&mut self) {
                self.events.borrow_mut().push(self.name);
            }
        }

        let events = RefCell::new(Vec::new());
        {
            let _first = DropRecord {
                name: "first",
                events: &events,
            };
            let _second = DropRecord {
                name: "second",
                events: &events,
            };
        } // L1-031-drop-order
        assert_eq!(&*events.borrow(), &["second", "first"]);
    }
}
