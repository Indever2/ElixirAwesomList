# ElixirAwesomeList

### Installation:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Install Node.js dependencies with `cd assets && npm i && cd ..`

  * Specify your GitHub username and password to make API working in [config.exs](file://lib/elixir_awesome_list/config.exs)
  ```elixir
  # Scrapper config
  config :elixir_awesome_list, ElixirAwesomeList.Scrapper,
    git_hub_api_root: "https://api.github.com/",
    git_hub_api_username: "your_username",
    git_hub_api_password: "your_password"
  ```

### Usage
> Enusre all test is passed running mix test. There are 10 test and all of them should be passed.


If all tests passed you can run the phoenix server with `mix phx.server`.

Than go to [`localhost:3999`](http://localhost:3999) from your browser and enjoy the show.

> If everything installed correctly packages will appear in 20-40 seconds (according to your internet connection, power of hardware and database tuning configuration).

Created by Ivan Krivtsov, 2020, according to the [`FunBox Elixir Technical Test`](https://dl.funbox.ru/qt-elixir.pdf) 