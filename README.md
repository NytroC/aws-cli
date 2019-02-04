# aws-cli

## Installation

* Install ruby
* Pull Repo

then run commands:  
* gem install bundler
* bundle install


## Running  

mode options:  
`put_song`  
`put_album`  
`put_artist`  

Examples:  
`ruby aws_cli.rb put_song artist="Miley Cyrus" album="Bangers"  name="Younger Now" location="path/to/song"`

`ruby aws_cli.rb put_album artist="Miley Cyrus" album="Bangers" location="path/to/album"`

`ruby aws_cli.rb put_artist artist="Miley Cyrus" location="path/to/artist"`