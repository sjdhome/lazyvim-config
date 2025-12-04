return {
  "yetone/avante.nvim",
  opts = {
    instructions_file = "AGENTS.md",
    provider = "openrouter",
    providers = {
      openrouter = {
        __inherited_from = "openai",
        endpoint = "https://openrouter.ai/api/v1",
        api_key_name = "OPENROUTER_API_KEY",
        model = "anthropic/claude-sonnet-4.5",
        model_names = {
          "anthropic/claude-sonnet-4.5",
          "anthropic/claude-haiku-4.5",
          "anthropic/claude-opus-4.5",
          "x-ai/grok-code-fast-1",
          "google/gemini-3-pro-preview",
        },
      },
      vertex = { hide_in_model_selector = true },
      vertex_claude = { hide_in_model_selector = true },
    },
  },
}
