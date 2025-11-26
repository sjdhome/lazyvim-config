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
      },
    }
  },
}
