defmodule OverrideWithPath.NoConflict.Mixfile do
  use Mix.Project

  def project do
    [ app: :override_with_git,
      version: "0.1.0",
      deps: [ {:postgrex, nil},
              {:ex_doc, path: "../ex_doc", override: true}] ]
  end
end
