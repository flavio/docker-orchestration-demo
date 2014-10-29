require 'etcd'
require 'json'
require 'mongo'
require 'sinatra'

configure do
  set :server, :puma
  set :bind, '0.0.0.0'
  set :port, 4567

  etcd_peers = ENV['ETCDCTL_PEERS'].gsub('http://', '').split(',')
  etcd_host, etcd_port = etcd_peers.first.split(":", 2)
  etcd_client = Etcd.client(:host => etcd_host, :port => etcd_port)
  mongo_settings = JSON.parse(etcd_client.get('/services/mongodb').value)

  conn = Mongo::MongoClient.new(mongo_settings['host'], mongo_settings['port'])

  set :mongo_connection, conn
  set :mongo_db, conn.db('guestbook')
end

get '/' do
  messages = settings.mongo_db['messages'].find({}, {:sort => ['_id', -1]}).to_a
  erb :index,
      :locals => { :messages => messages }
end

post "/add_message/?" do
  settings.mongo_db['messages'].insert({:message => params['message']})
  redirect back
end
