require "fradium/version"
require 'mysql2'
require 'securerandom'
require 'time'

class Fradium
	class UserAlreadyExistsError < StandardError; end
	class UserNotFoundError < StandardError; end
	class UsernameEmptyError < StandardError; end
  class CorruptedUserDatabaseError < StandardError; end
=begin
        showactive            # show active (enabled) users
        showinactive          # show inactive (disabled) users
        modify username       # generate new password for username
        modifyguest username  # generate new guest password for username
        disable username      # disable the user
=end

	def initialize(params={host: 'localhost', username: 'root', database: 'radius'})
		@mysql_host ||= ENV['FRADIUM_MYSQL_HOST']
		@mysql_database ||= ENV['FRADIUM_MYSQL_DATABASE']
		@mysql_user ||=  ENV['FRADIUM_MYSQL_USER']
		@mysql_pass ||=  ENV['FRADIUM_MYSQL_PASS']
		@params = params
		@client = Mysql2::Client.new(params)
	end

  def user_exists?(username)
		st = @client.prepare(%{SELECT username FROM radcheck WHERE username=? and attribute like '%-Password'})
		r = st.execute(username)
		r.count > 0
	end

	def all_users
		st = @client.prepare(%{SELECT username from radcheck WHERE attribute like '%-Password'})
		r = st.execute
		r.map{|h| h['username']}
	end

	def create_user(username)
		raise UsernameEmptyError if username&.empty?
		raise UserAlreadyExistsError if user_exists?(username)
		password = Fradium.generate_random_password

		st = @client.prepare(%{INSERT INTO radcheck (username,attribute,op,value) VALUES(?,?,?,?)})
		r = st.execute(username, 'Cleartext-Password', ':=', password)
	end

  def find_user(username)
		raise UsernameEmptyError if username&.empty?
		raise UserNotFoundError unless user_exists?(username)

    st = @client.prepare(%{SELECT * FROM radcheck WHERE attribute like '%-Password' and username=?})
    r = st.execute(username)
  end

	def modify_user(username)
		raise UsernameEmptyError if username&.empty?
		raise UserNotFoundError unless user_exists?(username)
		password = Fradium.generate_random_password

		st = @client.prepare(%{SELECT id FROM radcheck WHERE username=? and attribute like '%-Password'})
		r = st.execute(username)
    raise CorruptedUserDatabaseError if r.count > 1
    id = r.first['id']

    st  = @client.prepare(%{UPDATE radcheck SET value=?,attribute='Cleartext-Password' WHERE id=?})
    r = st.execute(password, id)
	end

  def expire_user(username)
    set_expiration(username, Time.now)
  end

  def is_expired?(username)
    expiration_date = query_expiration(username)&.fetch('value')
    return false if expiration_date.nil? || expiration_date.empty? # if expiration info not found, not expired yet
    Time.now > Time.parse(expiration_date)
  end

  def set_expiration(username, expiration_date)
    expiration_info = query_expiration(username)

    value = ''
    if expiration_date.instance_of?(Time)
      value = expiration_date.strftime("%d %b %Y %H:%M:%S")
    else
      value = Time.parse(expiration_date).strftime("%d %b %Y %H:%M:%S")
    end

    if expiration_info.nil? # add new entry
      st = @client.prepare(%{INSERT INTO radcheck (username,attribute,op,value) VALUES (?,?,?,?)})
      r = st.execute(username, 'Expiration', ':=', value)
    else # update existing entry
      st = @client.prepare(%{UPDATE radcheck SET value=? where id=?})
      r = st.execute(value, expiration_info.fetch('id'))
    end
  end

	def dbconsole
		Kernel.exec('mysql',
								"--pager=less -SF",
								"--user=#{@params[:username]}",
								"--password=#{@params[:password]}",
								"--host=#{@params[:host]}" ,
								"#{@params[:database]}")
	end

	def self.generate_random_password(length=10)
		r = SecureRandom.urlsafe_base64.delete('-_')
		while r.length < length
			r << SecureRandom.urlsafe_base64.delete('-_')
		end
		r[0..length-1]
	end

  #private

  def query_expiration(username)
		raise UsernameEmptyError if username&.empty?
		raise UserNotFoundError unless user_exists?(username)

    st = @client.prepare(%{SELECT * from  radcheck WHERE username=? and attribute='Expiration'})
    r = st.execute(username)
    raise CorruptedUserDatabaseError if r.count > 1
    return nil if r.count == 0 # if expiration information not found
    return nil if r&.first['value']&.empty?

    r.first
  end
end
