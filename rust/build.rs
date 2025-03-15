use cbindgen::{Config, Language};
use std::{env, path::PathBuf};

// Create C header files for Dart
fn main() {
    let crate_dir = env::var("CARGO_MANIFEST_DIR").unwrap();
    let package_name = env::var("CARGO_PKG_NAME").unwrap();

    let output_file = target_dir().join(format!("{}.h", package_name));

    let config = Config {
        language: Language::C,
        ..Default::default()
    };

    cbindgen::generate_with_config(crate_dir, config)
        .unwrap()
        .write_to_file(output_file);
}

fn target_dir() -> PathBuf {
    if let Ok(target) = env::var("CARGO_TARGET_DIR") {
        PathBuf::from(target)
    } else {
        PathBuf::from(env::var("CARGO_MANIFEST_DIR").unwrap()).join("target")
    }
}
