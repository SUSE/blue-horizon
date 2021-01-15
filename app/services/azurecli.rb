# frozen_string_literal: true

require 'open3'
require 'json'

# Class to wrap all azure cli operations
class AzureCli
  def logged_account
    Open3.popen3('az account show') do |stdin, stdout, stderr, wait_thr|

      if wait_thr.value.exitstatus.zero?
        account_data = JSON.parse(stdout.read())
        subscription = account_data['name']
        user = account_data['user']['name']
      end

      return {
        logged: wait_thr.value.exitstatus.zero?,
        subscription: subscription,
        user: user
      }
    end
  end

  def login
    stdin, stdout, stderr, wait_thr = Open3.popen3('az login --use-device-code')
    while msg = stderr.gets()
      if code = msg.match(/.*enter the code (.*) to authenticate/)
        return code.captures[0]
      end
    end
  end

  def logout
    Open3.popen3('az logout') do |stdin, stdout, stderr, wait_thr|
      return wait_thr.value.exitstatus.zero?
    end
  end
end
