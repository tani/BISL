defmodule BISL.Mixfile do
  use Mix.Project

  def project do
    [app: :bisl,
     version: "0.0.1",
     elixir: "~> 1.1",
	   escript: [main_module: BISL],
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod]
  end

end
