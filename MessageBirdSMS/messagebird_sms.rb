#!/usr/bin/env ruby
# encoding: UTF-8
# messagebird_sms.rb
#
# DESCRIPTION:
#   Sensu handler for Messagebird SMS
#
#   This handler will send sms alerts trough Messagebird.
#   The handler requires the messagebird-rest gem
#
# OUTPUT:
#   No output unless there is an error.
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-handler
#   gem: messagebird-rest
#   gem: timeout
#
# USAGE:
#   You need to install the messagebird-rest gem on the server
#   run the following command on the server to install the gem:
#     gem install messagebird-rest
#
#
#   Configure your recipients in messagebird_sms.json
#
# NOTES:
#   Make sure you configure your accesskey!
#   For the MessageBird REST API docs see:
#     https://www.messagebird.com/developers/ruby .
#
# LICENSE:
#   Author Ronald de Gunst   <rdegunst@gmail.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-handler'
require 'messagebird'
require 'timeout'

##
# This class handles Sensu alerts through MessageBird SMS messaging
#
class MessageBirdSMS < Sensu::Handler
  # Combine the name of the client with the name of the check
  def short_name
    @event['client']['name'] + '/' + @event['check']['name']
  end

  # Generate a status string
  def status_to_string
    case @event['check']['status']
    when 0
      'RESOLVED'
    when 1
      'WARNING'
    when 2
      'CRITICAL'
    else
      'UNKNOWN'
    end
  end

  def handle
    message = "#{status_to_string} - #{short_name}: " +
              "#{@event['check']['notification']}"
    accesskey = settings['messagebird_sms']['accesskey']
    smsclient =  MessageBird::Client.new(accesskey)
    sender = settings['messagebird_sms']['sender'] || 'Sensu'
    begin
      timeout(10) do
        settings['messagebird_sms']['recipients'].each do |recipient|
          number = recipient['number']
          smsclient.message_create(sender, number, message)
        end
      end
    rescue Timeout::Error
      puts 'MessageBirdSMS -- timed out while attempting to ' + @event['action']
    end
  end
end
