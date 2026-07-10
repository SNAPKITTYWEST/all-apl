package meta_oracle

lean_format := true

@[default_target]
lean_lib MetaOracle where
  srcDir := "."
  roots := #[`MetaOracle]

lean_exe meta_oracle where
  srcDir := "."
  root := `Main
