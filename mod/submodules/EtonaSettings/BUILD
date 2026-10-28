load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "EtonaSettings",
    module_name = "EtonaSettings",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    visibility = [
        "//visibility:public",
    ],
)
