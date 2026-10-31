mod format;
mod records;

pub fn public_summary() -> String {
    format::render(records::label())
}
