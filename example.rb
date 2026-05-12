# NovaPAI Ruby SDK Example
# Install: gem install ruby-openai
# Docs: https://api.novapai.ai

require "openai"

client = OpenAI::Client.new(
  access_token: "your-api-key",
  uri_base: "https://api.novapai.ai/router/v1"
)

# ── Basic Chat ──────────────────────────────────────────────
def basic_chat(client)
  response = client.chat(
    parameters: {
      model: "deepseek-v4-pro",
      messages: [
        { role: "system", content: "You are a helpful assistant." },
        { role: "user",   content: "Hello!" }
      ]
    }
  )
  puts response.dig("choices", 0, "message", "content")
end

# ── Streaming ───────────────────────────────────────────────
def stream_chat(client)
  client.chat(
    parameters: {
      model: "deepseek-v4-pro",
      messages: [{ role: "user", content: "Tell me a joke" }],
      stream: proc do |chunk, _bytesize|
        print chunk.dig("choices", 0, "delta", "content")
        $stdout.flush
      end
    }
  )
  puts
end

# ── Multi-turn Conversation ─────────────────────────────────
def multi_turn_chat(client)
  messages = [{ role: "system", content: "You are a helpful assistant." }]

  chat = lambda do |user_input|
    messages << { role: "user", content: user_input }
    response = client.chat(parameters: { model: "deepseek-v4-pro", messages: messages })
    reply = response.dig("choices", 0, "message", "content")
    messages << { role: "assistant", content: reply }
    reply
  end

  puts chat.call("What is 1+1?")
  puts chat.call("Multiply that by 10")
end

basic_chat(client)
stream_chat(client)
multi_turn_chat(client)
