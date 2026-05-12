# NovaPAI Ruby SDK Example
# Install: gem install ruby-openai
# Docs: https://novapai.ai

require "openai"
require "json"

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

# ── Function Calling ────────────────────────────────────────
def function_calling(client)
  response = client.chat(
    parameters: {
      model: "deepseek-v4-pro",
      messages: [{ role: "user", content: "What's the weather in Tokyo?" }],
      tools: [{
        type: "function",
        function: {
          name: "get_weather",
          description: "Get current weather for a city",
          parameters: {
            type: "object",
            properties: {
              city: { type: "string", description: "City name" }
            },
            required: ["city"]
          }
        }
      }]
    }
  )

  tool_call = response.dig("choices", 0, "message", "tool_calls", 0)
  puts "Function: #{tool_call.dig("function", "name")}"
  puts "Args: #{tool_call.dig("function", "arguments")}"

  # Continue with tool result
  result = { city: "Tokyo", temperature: 22, condition: "sunny" }.to_json
  final = client.chat(
    parameters: {
      model: "deepseek-v4-pro",
      messages: [
        { role: "user", content: "What's the weather in Tokyo?" },
        { role: "assistant", tool_calls: [tool_call] },
        { role: "tool", tool_call_id: tool_call["id"], content: result }
      ]
    }
  )
  puts final.dig("choices", 0, "message", "content")
end

# ── JSON Mode (Structured Output) ───────────────────────────
def json_mode(client)
  response = client.chat(
    parameters: {
      model: "deepseek-v4-pro",
      messages: [
        { role: "system", content: "Extract company info as JSON." },
        { role: "user", content: "Apple Inc. is based in Cupertino, founded in 1976." }
      ],
      response_format: { type: "json_object" }
    }
  )

  data = JSON.parse(response.dig("choices", 0, "message", "content"))
  puts JSON.pretty_generate(data)
end

basic_chat(client)
stream_chat(client)
multi_turn_chat(client)
function_calling(client)
json_mode(client)
