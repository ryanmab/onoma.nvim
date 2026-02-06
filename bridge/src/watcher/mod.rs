use std::{path::PathBuf, sync::LazyLock};

use mlua::prelude::*;

use onoma::indexer::DatabaseBackedIndexer;
use tokio::runtime;

mod wrapper;

/// An async runtime instance (provided by Tokio) for the watcher to use when
/// Lua calls async functions.
///
/// Note that the runtime must be entered inside of the outermost async call, and
/// all guards must be dropped in reference order.
///
/// Also note that because Lua is the calling mechanism, the normal Tokio constructs
/// cannot be used to drive the futures. It is the responsibility of Lua to drive the async
/// calls to completion using coroutines.
///
/// ```rust
/// let _guard = RUNTIME.enter();
/// ````
static RUNTIME: LazyLock<runtime::Runtime> = LazyLock::new(|| {
    runtime::Builder::new_multi_thread()
        .enable_all()
        .build()
        .expect("Initializing Tokio runtime should not fail")
});

pub static DATABASE_PATH: LazyLock<PathBuf> = LazyLock::new(|| {
    xdir::state().map_or_else(
        || PathBuf::from("./onoma/indexes"),
        |home| home.join("nvim/onoma/indexes"),
    )
});

pub async fn get_watcher(
    _lua: Lua,
    directories: Vec<PathBuf>,
) -> mlua::Result<wrapper::Watcher<DatabaseBackedIndexer>> {
    let _guard = RUNTIME.enter();

    let indexer = onoma::indexer::DatabaseBackedIndexer::new(
        &DATABASE_PATH,
        directories.iter().map(PathBuf::as_path),
    )
    .await
    .map_err(|err| mlua::Error::runtime(format!("Failed to create indexer for: {err}")))?;

    log::info!(
        "Created indexer with database path at {}",
        &DATABASE_PATH.display()
    );

    let watcher = onoma::watcher::Watcher::new(indexer);

    log::info!("Created watcher for indexed directories");

    Ok(wrapper::Watcher(watcher))
}
