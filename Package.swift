// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "GS1Parser",
    products: [
        .library(
            name: "GS1Parser",
            targets: ["GS1Parser"]
        ),
    ],
    targets: [
        .target(
            name: "CGS1SyntaxEngine",
            path: "Sources/CGS1SyntaxEngine",
            sources: [
                "ai.c",
                "dl.c",
                "gs1encoders.c",
                "scandata.c",
                "syn.c",
                "syntax/gs1syntaxdictionary.c",
                "syntax/lint__stubs.c",
                "syntax/lint_couponcode.c",
                "syntax/lint_couponposoffer.c",
                "syntax/lint_cset39.c",
                "syntax/lint_cset64.c",
                "syntax/lint_cset82.c",
                "syntax/lint_csetnumeric.c",
                "syntax/lint_csum.c",
                "syntax/lint_csumalpha.c",
                "syntax/lint_gcppos1.c",
                "syntax/lint_gcppos2.c",
                "syntax/lint_hasnondigit.c",
                "syntax/lint_hh.c",
                "syntax/lint_hhmi.c",
                "syntax/lint_hyphen.c",
                "syntax/lint_iban.c",
                "syntax/lint_importeridx.c",
                "syntax/lint_iso3166.c",
                "syntax/lint_iso3166999.c",
                "syntax/lint_iso3166alpha2.c",
                "syntax/lint_iso4217.c",
                "syntax/lint_iso5218.c",
                "syntax/lint_latitude.c",
                "syntax/lint_longitude.c",
                "syntax/lint_mediatype.c",
                "syntax/lint_mi.c",
                "syntax/lint_nonzero.c",
                "syntax/lint_nozeroprefix.c",
                "syntax/lint_packagetype.c",
                "syntax/lint_pcenc.c",
                "syntax/lint_pieceoftotal.c",
                "syntax/lint_posinseqslash.c",
                "syntax/lint_ss.c",
                "syntax/lint_winding.c",
                "syntax/lint_yesno.c",
                "syntax/lint_yymmd0.c",
                "syntax/lint_yymmdd.c",
                "syntax/lint_yyyymmd0.c",
                "syntax/lint_yyyymmdd.c",
                "syntax/lint_zero.c"
            ],
            publicHeadersPath: ".",
            cSettings: [
                .headerSearchPath("."),
                .headerSearchPath("syntax"),
                .define("GS1_LINTER_ERR_STR_EN"),
                .define("EXCLUDE_SYNTAX_DICTIONARY_LOADER")
            ]
        ),
        .target(
            name: "GS1Parser",
            dependencies: ["CGS1SyntaxEngine"]
        )
    ]
)
