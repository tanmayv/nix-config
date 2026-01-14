return {
  -- Disable default cmp
  { "hrsh7th/nvim-cmp", enabled = false },

  {
    'milanglacier/minuet-ai.nvim',
    opts = {
      provider = 'gemini',
      provider_options = {
        gemini = {
          model = 'gemini-2.0-flash',
          stream = true,
          api_key = 'GEMINI_API_KEY', -- Recommended: Set this env var in your shell
          end_point = 'https://generativelanguage.googleapis.com/v1beta/models',
          optional = {
            generationConfig = {
              maxOutputTokens = 256,
              thinkingConfig = { thinkingBudget = 0 },
            },
          },
        },
      },
      -- Disable virtualtext if you want it ONLY in the blink menu
      -- Or keep it empty to prevent "ESC-only" ghost text glitches
      virtualtext = { auto_trigger_ft = {} }, 
    },
  },

  {
    "Saghen/blink.cmp",
    -- Using opts instead of config is CRITICAL in AstroVim
    opts = function(_, opts)
      -- 1. Setup Sources
      opts.sources = vim.tbl_deep_extend("force", opts.sources or {}, {
        default = { 'lsp', 'path', 'buffer', 'snippets', 'minuet' },
        providers = {
          minuet = {
            name = 'minuet',
            module = 'minuet.blink',
            score_offset = 100,
            async = true,
            timeout_ms = 5000, -- Increased for slower API responses
          },
        },
      })

      -- 2. Fix Triggering: Ensure it shows while typing
      opts.completion = opts.completion or {}
      opts.completion.trigger = {
        prefetch_on_insert = true, -- Changed to true to start LLM request early
        show_on_keyword = true,
        show_on_trigger_character = true,
      }

      -- 3. Fix Keymaps
      opts.keymap = {
        preset = 'default',
        ['<A-y>'] = { function() require('minuet').make_blink_map() end },
        ['<Tab>'] = {
          function(cmp)
            if cmp.is_visible() then return cmp.select_next() end
            -- Check if your custom AI accept logic exists
            if vim.g.ai_accept then return vim.g.ai_accept() end
          end,
          "snippet_forward",
          "fallback",
        },
      }

      return opts
    end,
  },
}

