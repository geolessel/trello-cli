# trello

A CLI app for interacting with Trello.

I personally find Trello's UI offerings to be too taxing on my computer and
the many things it loads in an attempt to look nice make it a bit jumpy and
sluggish. I spend a ton of my day on the command line and wanted an interface with
Trello in that environment.

Add to that my long-time fascination with ncurses apps and a desire to learn Crystal
and the result is this project.

<img src="support/staging-screenshot.png" alt="trello cli app screenshot" />

## Installation

1. Install it through homebrew! If you don't have homebrew, you'll have to compile it
   yourself for now. See Development below for instructions. Otherwise, run
   ```sh
   brew install geolessel/homebrew-repo/trello-cli
   ```

   You can also track the master branch by adding the `--HEAD` flag.
   ```sh
   brew install --HEAD geolessel/homebrew-repo/trello-cli
   ```
2. Run `trello`

   The application should take you through a setup process that will direct
   you to Trello's site asking if you'll grant the app access to your Trello
   account. Once you accept, Trello will provide you with an API token. Just
   paste that into the line asking for your token and it will do the rest.

   ```
   --| This app requires access to your trello account. |--

   I'll open up a web page requesting access. Once you accept, you will
   be presented with an API token. Copy that and use it in the next step.
   Press ENTER to continue

   Token: <PASTE YOUR TOKEN HERE>
   Completing setup
   Done.
   ```

## Usage

1. Run it!
   ```sh
   trello
   ```

## Development

For now, you need to build it yourself and you must have the
[Crystal language installed](https://crystal-lang.org/docs/installation/). You can

1. Clone this repo
   ```sh
   git clone https://github.com/geolessel/trello-cli.git
   ```
2. Install the Crystal Shards (in the `trello-cli` directory)
   ```
   shards install
   ```
3. Run the app (in the `trello-cli` directory)
   ```
   crystal run src/trello.cr
   ```

## Contributing

1. Fork it (<https://github.com/geolessel/trello/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [geolessel](https://github.com/geolessel) Geoffrey Lessel - creator, maintainer
- [seven1m](https://github.com/seven1m) Tim Morgan - contributor
