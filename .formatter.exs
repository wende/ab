# Used by "mix format"
[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  import_deps: [:stream_data],
  export: [
    locals_without_parens: [
      property_test: 2,
      property_test: 3,
      compare_test: 2,
      compare_test: 3,
      benchmark_test: 2,
      benchmark_test: 3,
      validate_struct_consistency: 1,
      robust_test: 2,
      robust_test: 3
    ]
  ]
]
