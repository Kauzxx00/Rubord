# Rubord

Rubord is a modern Ruby library for building Discord bots.

It provides:
- Gateway (WebSocket)
- REST API
- Interactions (Buttons, Modals, Select Menus)
- Components v2 support

## Installation

```bash
gem install rubord
```

Or in your Gemfile:

```rb
gem "rubord"
```

## Basic Example

```rb
client = Rubord::Client.new(intents: 3276799)

client.on(:ready) do |client|
  puts "Logged in: " + client.username
end

client.on(:message_create) do |message|
  if message.content == "!hello"
    message.reply("Hello!")
  end
end

client.login("Your discord bot token")
```