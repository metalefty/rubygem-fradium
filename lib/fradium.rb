require "fradium/version"
require 'securerandom'
require 'sequel'
require 'time'

class Fradium
  class UserAlreadyExistsError < StandardError; end
  class UserNotFoundError < StandardError; end
  class UsernameEmptyError < StandardError; end
  class CorruptedUserDatabaseError < StandardError; end

  def initialize(params)
    @params = params
    @sequel = Sequel.connect(@params)
  end

  def user_exists?(username)
    find_user(username).count > 0
  end

  def all_users
    @sequel[:radcheck].where{attribute.like '%-Password'}
  end

  def create_user(username)
    raise UsernameEmptyError if username&.empty?
    raise UserAlreadyExistsError if user_exists?(username)
    password = Fradium.generate_random_password

    @sequel[:radcheck].insert(username: username,
                              attribute: 'Cleartext-Password',
                              op: ':=',
                              value: password)
  end

  def find_user(username)
    raise UsernameEmptyError if username&.empty?
    reult = @sequel[:radcheck].where(username: username).where{attribute.like '%-Password'}
  end

  def modify_user(username)
    raise UsernameEmptyError if username&.empty?
    raise UserNotFoundError unless user_exists?(username)
    password = Fradium.generate_random_password

    target = find_user(username)
    raise CorruptedUserDatabaseError if target.count > 1
    target.update(value: password, attribute: 'Cleartext-Password')
  end

  def expiry
    @sequel[:radcheck].where(attribute: 'Expiration')
  end

  def expired_users
    now = Time.now
    # a little bit redundant but for consistency
    id = @sequel[:radcheck].where(attribute: 'Expiration').collect{|e| e[:id] if Time.now > Time.parse(e[:value])}
    @sequel[:radcheck].where(id: id)
  end

  def expire_user(username)
    set_expiration(username, Time.now)
  end

  def unexpire_user(username)
    raise UsernameEmptyError if username&.empty?
    raise UserNotFoundError unless user_exists?(username)
    @sequel[:radcheck].where(username: username, attribute: 'Expiration').delete
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
      @sequel[:radcheck].insert(username: username,
                                attribute: 'Expiration',
                                op: ':=',
                                value: value)
    else # update existing entry
      expiration_info.update(value: value)
    end
  end

  def dbconsole
    case @sequel.adapter_scheme
    when :mysql2
      # I know this is not safe.
      Kernel.exec({'MYSQL_PWD' => @params['password']},
                  'mysql',
                  "--pager=less -SF",
                  "--user=#{@params['username']}",
                  "--host=#{@params['host']}" ,
                  "#{@params['database']}")
    when :postgres
      Kernel.exec({'PGPASSWORD' => @params['password']},
                  'psql',
                  "--username=#{@params['username']}",
                  "--dbname=#{@params['database']}",
                  "--host=#{@params['host']}")
    when :sqlite
      Kernel.exec('sqlite3', @params)
    end
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

    r = @sequel[:radcheck].where(username: username, attribute: 'Expiration')

    raise CorruptedUserDatabaseError if r.count > 1
    return nil if r.count == 0 # if no expiration info found
    return nil if r&.first[:value]&.empty?

    r
  end
end
