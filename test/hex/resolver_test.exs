defmodule Hex.ResolverTest do
  use HexTest.Case

  defp resolve(reqs, locked \\ []) do
    case Hex.Resolver.resolve(reqs(reqs), deps(reqs), locked(locked)) do
      {:ok, dict} -> dict
      {:error, _} -> nil
    end
  end

  defp deps(reqs) do
    Enum.map(reqs, fn {app, _req} ->
      %Mix.Dep{app: app, opts: [hex: app]}
    end)
    end

  defp reqs(reqs) do
    Enum.map(reqs, fn {app, req} ->
      name = Atom.to_string(app)
      {name, name, req, "mix.exs"}
    end)
  end

  defp locked(locked) do
    Enum.map(locked, fn {app, req} ->
      name = Atom.to_string(app)
      {name, name, req}
    end)
  end

  setup do
    Hex.Registry.start!(registry_path: tmp_path("registry.ets"))
  end

  test "simple" do
    deps = [foo: nil, bar: nil]
    assert Dict.equal? locked([foo: "0.2.1", bar: "0.2.0"]), resolve(deps)

    deps = [foo: "0.2.1", bar: "0.2.0"]
    assert Dict.equal? locked([foo: "0.2.1", bar: "0.2.0"]), resolve(deps)

    deps = [foo: "0.2.0", bar: "0.2.0"]
    assert Dict.equal? locked([foo: "0.2.0", bar: "0.2.0"]), resolve(deps)

    deps = [foo: "~> 0.3.0", bar: nil]
    assert nil = resolve(deps)

    deps = [foo: nil, bar: "~> 0.3.0"]
    assert nil = resolve(deps)
  end

  test "backtrack" do
    deps = [decimal: "0.2.0", ex_plex: "0.2.0"]
    assert Dict.equal? locked([decimal: "0.2.0", ex_plex: "0.2.0"]), resolve(deps)

    deps = [decimal: "0.1.0", ex_plex: ">= 0.1.0"]
    assert Dict.equal? locked([decimal: "0.1.0", ex_plex: "0.1.2"]), resolve(deps)

    deps = [decimal: nil, ex_plex: "< 0.1.0"]
    assert Dict.equal? locked([decimal: "0.2.1", ex_plex: "0.0.1"]), resolve(deps)

    deps = [decimal: "0.1.0", ex_plex: "< 0.1.0"]
    assert Dict.equal? locked([decimal: "0.1.0", ex_plex: "0.0.1"]), resolve(deps)

    deps = [decimal: "0.1.0", ex_plex: "~> 0.0.2"]
    assert nil = resolve(deps)

    deps = [decimal: nil, ex_plex: "0.0.2"]
    assert nil = resolve(deps)
  end

  test "complete backtrack" do
    deps = [jose: nil, eric: nil]
    assert Dict.equal? locked([jose: "0.2.1", eric: "0.0.2"]), resolve(deps)
  end

  test "locked" do
    locked = [decimal: "0.2.0"]
    deps = [decimal: nil, ex_plex: nil]
    assert Dict.equal? locked([decimal: "0.2.0", ex_plex: "0.2.0"]), resolve(deps, locked)

    locked = [decimal: "0.1.0"]
    deps = [decimal: nil, ex_plex: nil]
    assert Dict.equal? locked([decimal: "0.1.0", ex_plex: "0.1.2"]), resolve(deps, locked)

    locked = [decimal: "0.0.1"]
    deps = [decimal: nil, ex_plex: nil]
    assert Dict.equal? locked([decimal: "0.0.1", ex_plex: "0.0.1"]), resolve(deps, locked)

    locked = [ex_plex: "0.1.0"]
    deps = [decimal: "0.1.0", ex_plex: nil]
    assert Dict.equal? locked([decimal: "0.1.0", ex_plex: "0.1.0"]), resolve(deps, locked)

    locked = [ex_plex: "0.1.0", decimal: "0.1.0"]
    deps = [decimal: "0.1.0", ex_plex: nil]
    assert Dict.equal? locked([decimal: "0.1.0", ex_plex: "0.1.0"]), resolve(deps, locked)

    locked = [ex_plex: "0.1.0", decimal: "0.1.0"]
    deps = [decimal: nil, ex_plex: nil]
    assert Dict.equal? locked([decimal: "0.1.0", ex_plex: "0.1.0"]), resolve(deps, locked)

    locked = [ex_plex: "0.1.0", decimal: "0.1.0"]
    deps = []
    assert Dict.equal? [], resolve(deps, locked)
  end
end
