/// After each build, remove the "tag" file, which is used for synchronizing pre-built binaries
/// in the Lua download script.
///
/// This ensures that if the download script is run again, it will re-download the necessary
/// binaries and remove any of the built ones.
fn main() {
    let _ = std::fs::remove_file("target/release/tag");
}
