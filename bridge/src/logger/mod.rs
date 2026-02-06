use std::{clone::Clone, path::PathBuf, string::ToString, sync::LazyLock};

use flexi_logger::{FileSpec, Logger, LoggerHandle, WriteMode};

mod wrapper;

/// The global Logging context shared between Rust and Lua.
static LOGGER: LazyLock<LoggerHandle> = LazyLock::new(|| {
    let pattern = "onoma_bridge=trace, onoma=trace";

    let path = xdir::state().map_or_else(
        || PathBuf::from("./onoma/logs"),
        |home| home.join("nvim/onoma/logs"),
    );

    let spec = FileSpec::default().directory(&*path).basename("bridge");

    Logger::try_with_str(pattern)
        .expect("Logging pattern should always be valid")
        .log_to_file(spec)
        .format(flexi_logger::opt_format)
        .write_mode(WriteMode::BufferAndFlush)
        .start()
        .expect("Initializing logger should not fail")
});

/// Initialize the logger so that it can be used by Rust, and Lua.
///
/// NB: This should be called _as early as possible_ in the execution so that there is no log
/// context missing from executions.
///
/// Generally speaking this should be initialized as soon as the Lua module (cross compiled from
/// Rust) is imported.
pub fn init() {
    LazyLock::force(&LOGGER);

    let default_panic = std::panic::take_hook();
    std::panic::set_hook(Box::new(move |panic_info| {
        let payload = panic_info.payload();
        let message = payload.downcast_ref::<&str>().map_or_else(
            || {
                payload
                    .downcast_ref::<String>()
                    .map_or_else(|| "Unknown panic".to_string(), Clone::clone)
            },
            ToString::to_string,
        );

        let location = panic_info.location().map_or_else(
            || "unknown".to_string(),
            |location| {
                format!(
                    "{}:{}:{}",
                    location.file(),
                    location.line(),
                    location.column()
                )
            },
        );

        log::error!("PANIC: A panic occurred in backend at {location}: {message}");

        default_panic(panic_info);
    }));
}

/// Flush the log buffer
pub fn flush() {
    LOGGER.flush();
}

/// Write a log message to the log file.
#[allow(clippy::unnecessary_wraps)]
pub fn log(_lua: &mlua::Lua, (level, message): (wrapper::Level, String)) -> mlua::Result<()> {
    log::log!(*level, "{message}");

    Ok(())
}
