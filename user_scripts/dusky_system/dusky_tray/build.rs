fn main() {
    let helper = std::path::Path::new("../click_away_to_dismiss");
    for name in [
        "dusky.c",
        "hyprland-focus-grab-v1-client-protocol.c",
        "hyprland-focus-grab-v1-client-protocol.h",
    ] {
        println!("cargo:rerun-if-changed={}", helper.join(name).display());
    }
    let mut build = cc::Build::new();
    build.file(helper.join("dusky.c"))
        .file(helper.join("hyprland-focus-grab-v1-client-protocol.c"))
        .include(helper)
        .warnings(false);
    for inc in [
        "/run/current-system/sw/include",
        "/usr/include",
    ] {
        if std::path::Path::new(inc).is_dir() {
            build.include(inc);
        }
    }
    build.compile("dusky_click_away");
    for library in ["wayland-client", "dl", "pthread"] {
        println!("cargo:rustc-link-lib={library}");
    }
    for path in [
        "/run/current-system/sw/share/nix-ld/lib",
        "/run/current-system/sw/lib",
    ] {
        if std::path::Path::new(path).is_dir() {
            println!("cargo:rustc-link-search=native={path}");
        }
    }
}
