require 'aws-sdk-s3'

mode = ARGV[0]

args= {}
ARGV.map{|argument| args[argument.split('=')[0].to_sym] = argument.split('=')[1]}

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
case mode 
when "put_song"
  file = File.open(file_path, 'rb')
  resp = s3.put_object({
    body: file, 
    bucket: "do-not-kick", 
    key: path, 
  }) 
  file.close
  puts "uploaded #{song_name}" 
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
        next if album.match(/^\./) || album.match(".DS_Store")
        begin
          file = File.open("#{file_path}/#{album}/#{song}", 'rb')
          resp = s3.put_object({
            body: file, 
            bucket: "do-not-kick", 
            key: "#{path}/#{song}", 
          }) 
          file.close
          puts "uploaded #{song}" 
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