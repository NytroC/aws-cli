require 'aws-sdk'

mode = ARGV[0]

args= {}
ARGV.map{|argument| args[argument.split('=')[0].to_sym] = argument.split('=')[1]}

file_path = args[:location]
album_name = args[:album]
artist = args[:artist]
song_name = args[:name]
genre = args[:genre]
path = [artist, album_name, song_name].compact.join("/")

role_credentials = Aws::AssumeRoleCredentials.new(
    client: Aws::STS::Client.new(),
    role_arn: "arn:aws:iam::170621239995:role/s3admin",
    role_session_name: "Ruby-CLI"
  )

s3 = Aws::S3::Client.new(credentials: role_credentials)
dynamodb = Aws::DynamoDB::Client.new(
  credentials: role_credentials,
  region: "us-east-1"
)

case mode 
when "put_song"
  file = File.open(file_path, 'rb')
  resp = s3.put_object({
    body: file, 
    bucket: "do-not-kick", 
    key: path, 
  }) 
  file.close
  dynamo_resp = dynamodb.put_item({
    table_name: "music", # required
    item: { # required
      "genre" => genre,
      "artist" => artist,
      "album" => album_name,
      "song" => song_name,
      "artist_album_song" => path,
      "s3_location" => path
    }
  })
  puts "uploaded #{song_name}" 
  puts dynamo_resp
when "put_album"
  Dir.foreach(file_path) do |song|
    next if song.match(/^\./)
    begin
      file = File.open("#{file_path}/#{song}", 'rb')
      resp = s3.put_object({
        body: file, 
        bucket: "do-not-kick", 
        key: "#{path}/#{song}", 
      }) 
      file.close
      dynamo_resp = dynamodb.put_item({
        table_name: "music", # required
        item: { # required
          "genre" => genre,
          "artist" => artist,
          "album" => album_name,
          "song" => song,
          "artist_album_song" => "#{path}/#{song}",
          "s3_location" => "#{path}/#{song}"
        }
      })
      puts "uploaded #{song}" 
    rescue
      next
    end
  end
when "put_artist"
  Dir.foreach(file_path) do |album|
    next if album.match(/^\./)
    puts "uploading #{album}"
    begin 
      Dir.foreach("#{file_path}/#{album}") do |song|
        next if song.match(/^\./) || song.match(".DS_Store")
        begin
          file = File.open("#{file_path}/#{album}/#{song}", 'rb')
          resp = s3.put_object({
            body: file, 
            bucket: "do-not-kick", 
            key: "#{path}/#{album}/#{song}", 
          }) 
          file.close
          dynamo_resp = dynamodb.put_item({
            table_name: "music", # required
            item: { # required
              "genre" => genre,
              "artist" => artist,
              "album" => album,
              "song" => song,
              "artist_album_song" => "#{path}/#{album}/#{song}",
              "s3_location" => "#{path}/#{album}/#{song}"
            }
          })
          puts "uploaded #{song}" 
        rescue StandardError => e
          puts e.message
          next
        end
      end
    rescue
      next
    end
  end
else
  puts "unknown command"
end