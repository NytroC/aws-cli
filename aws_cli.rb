require 'aws-sdk-s3'

mode = ARGV[0]
puts mode
args= {}
ARGV.map{|argument| args[argument.split('=')[0].to_sym] = argument.split('=')[1]}

puts args.compact
file_path = args[:location]
album_name = args[:album]
artist = args[:artist]
song_name = args[:name]
path = [artist, album_name, song_name].compact.join("/")

role_credentials = Aws::AssumeRoleCredentials.new(
    client: Aws::STS::Client.new(),
    role_arn: "arn:aws:iam::096015776245:role/s3admin",
    role_session_name: "Ruby-CLI"
  )

s3 = Aws::S3::Client.new(credentials: role_credentials)
# resp = s3.list_buckets

# resp = s3.list_objects({
#   bucket: "do-not-kick", 
# })
case mode 
when "put_song"
  file = File.open(file_path, 'rb')
  resp = s3.put_object({
    body: file, 
    bucket: "do-not-kick", 
    key: path, 
  }) 
  file.close
when "put_album"
  Dir.foreach(file_path) do |song|
    begin
      puts song
      file = File.open("#{file_path}/#{song}", 'rb')
      resp = s3.put_object({
        body: file, 
        bucket: "do-not-kick", 
        key: "#{path}/#{song}", 
      }) 
      file.close
    rescue
      next
    end
  end
when "put_artist"
  Dir.foreach(file_path) do |album|
    begin 
      Dir.foreach("#{file_path}/#{album}") do |song|
        begin
          puts song
          file = File.open("#{file_path}/#{album}/#{song}", 'rb')
          resp = s3.put_object({
            body: file, 
            bucket: "do-not-kick", 
            key: "#{path}/#{song}", 
          }) 
          file.close
        rescue
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

# puts resp.to_h