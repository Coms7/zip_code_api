require "bundler/setup"

require 'mysql2'
require 'sinatra'
require 'uri'
require 'net/http'
require 'dotenv'

ZIP_CLOUD_URL = 'https://zipcloud.ibsnet.co.jp/api/search/'.fleeze

def initialize
  Dotenv.load
@client = Mysql2::Client.new(
  host: ENV['DB_HOST'], 
  username: ENV['DB_USER_NAME'], 
  password: ENV["DB_PASS"], 
  database: ENV['DB_NAME']
)
@resulet = []
end


# 全件取得
get '/zip_codes' do
results = @client.query('SELECT id, zip_code, prefecture, city, town_area FROM zip_codes;')
  data =  results.map do |row| 
    hash = {
      id: row ['id'],
      zip_code: row ['zip_code'],
      prefecture: row ['prefecture'],
      city: row['city'],
      town_area: row ['town_area']
    }
  end
  data.to_json
end

# レコード新規登録
post '/zip_codes' do
  zip_codes = params[:zip_codes]
  statement = @client.prepare('INSERT INTO zip_codes(zip_code, prefecture, city, town_area, created_at, updated_at)
                                VALUES (?, ?, ?, ?, current_time, current_time);')
  results = statement.execute(zip_codes["zip_code"], zip_codes["prefecture"], zip_codes["city"], zip_codes["town_area"])
  if results.size.zero?
    return bad_request().to_json
  else
    data = [
      {
      status: 'created',
      status_code: 201
      }
    ]
    end
  data.to_json
end

#id指定get
get '/zip_codes/:id' do
  statement = @client.prepare('SELECT * FROM zip_codes WHERE id = ? ;')
  results = statement.execute(params['id'])
  if results.size.zero?
    return not_found().to_json
  else
    data = results.map do |row|
      hash = {
      id: row ['id'],
      zip_code: row ['zip_code'],
      prefecture: row ['prefecture'],
      city: row['city'],
      town_area: row ['town_area']
    }
    end
  data.to_json
  end
end



#id指定アップデート
put '/zip_codes/:id' do
  zip_codes = params['zip_code', 'prefecture', 'city', 'town_area']
  statement = @client.prepare('SELECT * FROM zip_codes WHERE id = ? ;' )
  results = statement.execute(params['id'])
  #存在チェック
  if results.size.zeroz?
    return not_found().to_json
  end
    #登録処理
    statement = @client.prepare('UPDATE zip_codes SET zip_code = ?, prefecture = ?, city = ?, town_area = ? WHERE id = ?;')
    results = statement.execute(zip_codes["zip_code"], zip_codes["prefecture"], zip_codes["city"], zip_codes["town_area"], zip_codes["id"])
    data = [
    hash = {
      status: 'updated',
      status_code: 200
    }
  ]
    data.to_json
end


post '/request_zip_cloud/:zip_code' do
  result_hash = Struct.new(:status, :status_code)
  uri = URI("https://zipcloud.ibsnet.co.jp/api/search?zipcode=#{params['zip_code']}")
  res = Net::HTTP.get_response(uri)
  results = res.body
  if !res.is_a?(Net::HTTPSuccess)
    return bad_request().to_json
  elsif(results['status'] == 500)
    data = [
      {
      status: 'internal error',
      status_code: 500
    }
  ]
    data.to_json
  elsif(results['status'] == 400)
    not_found().to_json
  else
  #登録処理
  results.map do |row| 
    data = [
      {
      zip_code: row ['zip_code'],
      prefecture: row ['prefecture'],
      city: row['city'],
      town_area: row ['town_area']
    }
  ]
  end
    statement = @client.prepare('INSERT INTO zip_codes(zip_code, prefecture, city, town_area, created_at, updated_at)
                                VALUES (?, ?, ?, ?, current_time, current_time);')
    query = statement.execute(data["zip_code"], data["prefecture"], data["city"], data["town_area"])
    data.to_json
  end
end

#id指定デリート
delete '/zip_codes/:id' do
statement = @client.prepare('DELETE FROM zip_codes WHERE id = ?;' )
result = statement.execute(params['id'])
  if result.size.zero?
    not_found().to_json
    data = [
      {
      status: 'deleted',
      status_code: 200
    }
  ]
    data.to_json
  end
end

private

def not_found()
  data = [
    {
      status: 'not found',
      status_code: 400
    }
  ]
  return
end

def bad_request()
  data = [
    {
      status: 'bad request',
      status_code: 400
    }
  ]
end

